#!/usr/bin/env python3
"""
pipeline_v3.py — Experimento IaC-Eval + SecLLM (N ampliable + auto-reparación)
==============================================================================

Motivación
----------
El experimento v2 dejó solo 14 scripts con Fc=1 sobre 320 generaciones (4.4 %).
Con esa n, RQ1 tiene 34-62 % de potencia y el IC 95 % de cualquier proporción de
RQ3 mide 67 puntos de ancho. Este pipeline ataca las dos causas:

  [V1] N AMPLIABLE POR OLEADAS. La muestra estratificada puede crecer (40 -> 120)
       PRESERVANDO los índices ya evaluados. Las 320 generaciones de v2 siguen
       siendo válidas y se reutilizan; solo se genera lo nuevo.

  [V2] AUTO-REPARACIÓN DE K RONDAS. Si `terraform plan` falla, se devuelve el
       stderr al modelo y se le pide corregir. Produce dos métricas distintas:
         Fc@1 — corrección funcional a la primera (comparable con v2, es la
                métrica que usa generate_report_v2.py sin cambios).
         Fc@k — corrección funcional tras hasta k rondas de reparación.
       Fc@k eleva la n de scripts funcionalmente correctos sin inflar Fc@1, y
       la diferencia Fc@k - Fc@1 es en sí misma un resultado reportable.

Correcciones de robustez respecto a pipeline_v2.py
--------------------------------------------------
  [B1] Fuga de disco: en v2, si el plan fallaba había un `return` que saltaba el
       `shutil.rmtree` (pipeline_v2.py:317-320 vs :354). Como falla ~85 % de los
       casos, cada fallo dejaba su `.terraform/` con los providers descargados.
       Aquí la limpieza va SIEMPRE en un `finally`.
  [B2] Versión del provider AWS fijada (`required_providers`). Sin pin, cada
       `terraform init` baja la última versión y lo que hoy es "Unsupported
       argument" mañana puede compilar: las corridas no eran reproducibles.
  [B3] El returncode de `terraform init` se comprueba y se registra. En v2 se
       ignoraba y un fallo de init aparecía disfrazado de fallo de plan.
  [B4] Se distingue TIMEOUT de plan de un fallo real de plan.

Compatibilidad con v2
---------------------
`iac_eval_results.json` conserva las claves de v2 reflejando SIEMPRE el intento 0,
por lo que `generate_report_v2.py` corre sin modificarse y devuelve exactamente
Fc@1. Las métricas nuevas van en claves añadidas (`fc_at_1`, `fc_at_k`,
`attempts_used`, ...) y el detalle por intento en `iac_eval_attempts.json`.

Estructura de salida
--------------------
  outputs_v3/
    experiment_sample.json          <- índices + registro de oleadas
    pipeline_v3_log.txt
    <model_slug>/<P0|P1>/
      terraform/question_XXXX.tf        <- intento 0 (idéntico en formato a v2)
      terraform/question_XXXX.a1.tf     <- intento 1 (tras reparación), si hubo
      iac_eval_results.json             <- 1 registro por archivo (v2-compatible)
      iac_eval_attempts.json            <- 1 registro por intento (detalle)
      secllm_results.json               <- auditoría del auditor externo común

Uso
---
  python pipeline_v3.py                        # N=120, 1 ronda de reparación
  PIPELINE_N=120 REPAIR_ROUNDS=1 python pipeline_v3.py
  python pipeline_v3.py --n 120 --repair-rounds 1
  python pipeline_v3.py --models qwen2.5-coder:7b,llama3.1:8b
  python pipeline_v3.py --no-seed-from-v2      # empezar de cero, sin reutilizar v2
  python pipeline_v3.py --skip-audit           # solo generación + evaluación
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
import uuid
from datetime import datetime
from pathlib import Path

import pandas as pd
import requests

# ============================================================================
# CONFIGURACIÓN PRINCIPAL
# ============================================================================

# Modelos EVALUADOS (generadores). Son los realmente ejecutados en v2, no los
# que estaban por defecto en pipeline_v2.py (ese default no coincidía con los
# outputs y rompía la reproducibilidad desde el repo).
MODELS = [
    "codegemma:7b",
    "codellama:7b",
    "granite-code:8b",
    "llama3.1:8b",
]

# Escenarios por modelo y condición. v2 usó 40; el análisis de potencia pide
# ~120 para llevar RQ1 a 90 % y RQ3 a un IC de ±17 pp.
NUM_SAMPLES = int(os.environ.get("PIPELINE_N", "120"))

# Rondas de auto-reparación tras un fallo de `terraform plan`. 0 = comportamiento
# de v2. 1 = una corrección (recomendado: la mayor ganancia está en la 1ª ronda).
REPAIR_ROUNDS = int(os.environ.get("REPAIR_ROUNDS", "1"))

# Semilla del muestreo estratificado. NO CAMBIAR entre oleadas del mismo
# experimento: al ampliar N se preservan los índices ya evaluados.
RANDOM_SEED = 42

# Auditor externo común (debe NO estar en MODELS para evitar el confound de
# auto-auditoría).
COMMON_AUDITOR = os.environ.get("COMMON_AUDITOR", "devstral-small-2:latest")

# Auditor con el que se produjeron las auditorías heredadas de outputs_v2
# (según INSTRUCCIONES_EXPERIMENTO_V2.md y el default de pipeline_v2.py).
# Medido en esta máquina: devstral-small-2 pesa 15 GB, no cabe en 8 GB de VRAM
# y tarda ~220 s por archivo; un auditor de 7B que sí quepa tarda ~48 s.
V2_AUDITOR = "devstral-small-2:latest"

CONDITIONS = ["P0", "P1"]

OLLAMA_OPENAI_URL = "http://localhost:11434/v1"
OLLAMA_NATIVE_URL = "http://localhost:11434/api/generate"

GEN_TIMEOUT = 1800
INIT_TIMEOUT = 300
PLAN_TIMEOUT = 120
OPA_TIMEOUT = 120
AUDIT_FILE_TIMEOUT = 3600

# Reglas de seguridad evaluadas en paralelo por archivo. SecLLM ya las despacha
# con un ThreadPoolExecutor (secllm.py:111); v2 lo anulaba pasando -t 1.
# Medido en esta máquina con devstral: 161 s/archivo con -t 1, 115 s con -t 8
# (1.4x). El modelo no cabe en la VRAM y el cuello es el trasiego de pesos, así
# que la concurrencia ayuda menos de lo habitual. Las detecciones no cambian
# entre configuraciones, así que el cambio es gratis.
# Requiere que el servidor Ollama corra con OLLAMA_NUM_PARALLEL >= este valor
# (lo lee el SERVIDOR al arrancar, no el cliente).
AUDIT_THREADS = int(os.environ.get("AUDIT_THREADS", "8"))

# Versión del provider AWS. Fijarla es lo que hace reproducibles los resultados
# funcionales entre oleadas separadas en el tiempo [B2].
AWS_PROVIDER_VERSION = os.environ.get("AWS_PROVIDER_VERSION", "5.31.0")

# ============================================================================
# PROMPTS
# ============================================================================

# P0 — Baseline: HCL válido, sin guía de seguridad. Idéntico a v2 (las
# generaciones de v2 deben seguir siendo comparables con las nuevas).
SYSTEM_PROMPT_P0 = (
    "You are an expert Terraform engineer. "
    "Generate valid, deployable Terraform HCL code based on the user request. "
    "Create IAM roles and provider/region config as needed, and make sure there "
    "are no undeclared variables. Do NOT include explanations. Output ONLY the "
    "Terraform code inside a single ```hcl ... ``` block."
)

# P1 — Security-oriented: cubre los 8 security smells del taxonomy adaptado.
# Idéntico a v2, por la misma razón.
SYSTEM_PROMPT_P1 = (
    "You are an expert Terraform security engineer. "
    "Generate valid, deployable Terraform HCL code based on the user request. "
    "Create IAM roles and provider/region config as needed. "
    "Apply ALL of the following security best practices: "
    "(1) Never hardcode credentials, passwords, API keys, or tokens as literal "
    "strings-always reference them via var.*, data sources, or AWS Secrets Manager; "
    "(2) Use least-privilege IAM policies-never use '*' in actions or resources "
    "unless the task strictly requires it, and prefer specific ARNs; "
    "(3) Set minimum required permissions for all IAM roles and instance profiles; "
    "(4) Restrict network exposure-set explicit CIDR blocks in security group ingress "
    "rules; avoid 0.0.0.0/0 unless explicitly required by the task; "
    "(5) Enforce encryption in transit-use HTTPS/TLS endpoints and avoid plain HTTP; "
    "(6) Use strong encryption algorithms-prefer AES-256 and TLS 1.2+; "
    "(7) Add integrity checks (checksums) for any downloaded resources or "
    "provisioner scripts; "
    "(8) Do not leave TODO, FIXME, or placeholder security comments in the code-"
    "either implement the security control or omit the comment. "
    "Do NOT include explanations. Output ONLY the Terraform code inside a single "
    "```hcl ... ``` block."
)

PROMPTS = {"P0": SYSTEM_PROMPT_P0, "P1": SYSTEM_PROMPT_P1}

# Prompt de reparación. Deliberadamente NO añade guía de seguridad: repara solo
# el error funcional, para no contaminar la condición P0 con contenido de P1.
REPAIR_PROMPT = (
    "You are an expert Terraform engineer. The following Terraform code failed "
    "`terraform plan` with the error shown below. Fix the code so that it plans "
    "successfully, while still fulfilling the original request. Keep the same "
    "resources and intent; change only what is needed to make it valid. "
    "Do NOT include explanations. Output ONLY the corrected Terraform code inside "
    "a single ```hcl ... ``` block.\n\n"
    "ORIGINAL REQUEST:\n{request}\n\n"
    "CURRENT CODE:\n```hcl\n{code}\n```\n\n"
    "TERRAFORM ERROR:\n{error}\n"
)

# Recorte del stderr que se le devuelve al modelo (los errores de Terraform
# pueden ser larguísimos y desplazarían al código del contexto).
MAX_ERROR_CHARS = 2500

# --- Topes contra generaciones desbocadas -----------------------------------
# Medido sobre los 320 .tf de v2: mediana 911 B, p90 2.9 KB, máximo 6.5 KB.
# En una prueba, llama3.1:8b entró en bucle y devolvió 113 KB (17x el máximo
# legítimo) tras 6 minutos de GPU; después la reparación recibió esos 113 KB,
# desbordó el contexto y contestó 17 caracteres. Sin topes, un puñado de casos
# así se come horas de cómputo y contamina los resultados.
MAX_GEN_TOKENS = int(os.environ.get("MAX_GEN_TOKENS", "4096"))   # ~16 KB
MAX_CODE_CHARS = int(os.environ.get("MAX_CODE_CHARS", "40000"))  # 6x el máximo de v2
MAX_REPAIR_CODE_CHARS = 24000  # lo que se le puede reenviar al modelo al reparar

# ============================================================================
# RUTAS
# ============================================================================

SCRIPT_DIR = Path(__file__).resolve().parent
INTEGRATION_DIR = SCRIPT_DIR.parent
BASE_DIR = INTEGRATION_DIR.parent

DATASET = INTEGRATION_DIR / "iac_eval_data.csv"
OUTPUT_BASE = INTEGRATION_DIR / "outputs_v3"
OUTPUT_V2 = INTEGRATION_DIR / "outputs_v2"
SAMPLE_FILE = OUTPUT_BASE / "experiment_sample.json"
SAMPLE_FILE_V2 = OUTPUT_V2 / "experiment_sample.json"
SECLLM_TF_CONFIG = INTEGRATION_DIR / "config_terraform.yaml"

IAC_EVAL_DIR = BASE_DIR / "iac-eval" / "evaluation"
SECLLM_DIR = BASE_DIR / "SecLLM" / "SecLLM"
SECLLM_SCRIPT = SECLLM_DIR / "secllm" / "secllm.py"

LOG_FILE = OUTPUT_BASE / "pipeline_v3_log.txt"

os.environ["PATH"] += os.pathsep + str(BASE_DIR)
os.environ.setdefault("TF_PLUGIN_CACHE_DIR", str(BASE_DIR / ".tf_plugin_cache"))
Path(os.environ["TF_PLUGIN_CACHE_DIR"]).mkdir(parents=True, exist_ok=True)
os.environ.setdefault("AWS_ACCESS_KEY_ID", "test")
os.environ.setdefault("AWS_SECRET_ACCESS_KEY", "test")
os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")
os.environ.setdefault("AWS_REGION", "us-east-1")

# Provider con credenciales dummy y validaciones desactivadas: valida
# sintaxis/esquema sin contactar AWS.
AWS_PROVIDER_BLOCK = '''\
provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}
'''

# Pin de la versión del provider [B2]. Se añade SOLO si el código generado no
# declara ya su propio `required_providers`: dos bloques en el mismo módulo
# producen "Duplicate required providers configuration" y convertirían en fallo
# archivos que antes compilaban. Hoy 0/320 lo declaran, pero un modelo nuevo sí
# podría hacerlo.
AWS_REQUIRED_PROVIDERS = f'''\
terraform {{
  required_providers {{
    aws = {{
      source  = "hashicorp/aws"
      version = "{AWS_PROVIDER_VERSION}"
    }}
  }}
}}

'''


def build_override(code: str) -> str:
    if "required_providers" in code:
        return AWS_PROVIDER_BLOCK
    return AWS_REQUIRED_PROVIDERS + AWS_PROVIDER_BLOCK


# ============================================================================
# UTILIDADES
# ============================================================================

def log(msg: str) -> None:
    line = f"[{datetime.now():%Y-%m-%d %H:%M:%S}] {msg}"
    print(line, flush=True)
    OUTPUT_BASE.mkdir(parents=True, exist_ok=True)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(line + "\n")


def model_slug(model: str) -> str:
    return model.replace(":", "_").replace(".", "_")


def attempt_filename(idx: int, attempt: int) -> str:
    """question_0132.tf para el intento 0; question_0132.a1.tf para el 1, etc.

    El intento 0 conserva el nombre de v2 a propósito: así los .tf ya generados
    se reutilizan tal cual y las rutas siguen siendo las que audita SecLLM.
    """
    return f"question_{idx:04d}.tf" if attempt == 0 else f"question_{idx:04d}.a{attempt}.tf"


# ============================================================================
# MUESTREO ESTRATIFICADO AMPLIABLE POR OLEADAS [V1]
# ============================================================================

def get_or_extend_sample(df: pd.DataFrame, n_total: int, seed: int) -> pd.DataFrame:
    """
    Devuelve una muestra estratificada por dificultad de tamaño >= n_total.

    Si ya existe una muestra previa (de v3 o heredada de v2), PRESERVA todos sus
    índices y solo añade los que falten, muestreando el complemento dentro de
    cada estrato. Esto es lo que permite subir de N=40 a N=120 sin desperdiciar
    las 320 generaciones ya hechas.

    Cada ampliación queda registrada en la lista `waves` del JSON, de modo que
    siempre se puede reconstruir qué se evaluó en cada oleada.
    """
    prev_indices: list[int] = []
    waves: list[dict] = []

    if SAMPLE_FILE.exists():
        meta = json.loads(SAMPLE_FILE.read_text(encoding="utf-8"))
        prev_indices = meta.get("indices", [])
        waves = meta.get("waves", [])
    elif SAMPLE_FILE_V2.exists():
        # Primera corrida de v3: heredar la muestra de v2 para que los índices
        # ya evaluados formen parte del nuevo diseño.
        meta_v2 = json.loads(SAMPLE_FILE_V2.read_text(encoding="utf-8"))
        prev_indices = meta_v2.get("indices", [])
        waves = [{"wave": 1, "source": "outputs_v2", "n_added": len(prev_indices),
                  "n_cumulative": len(prev_indices), "seed": meta_v2.get("seed", seed)}]
        log(f"Heredando la muestra de v2: {len(prev_indices)} escenarios ya evaluados.")

    if len(prev_indices) >= n_total:
        log(f"Muestra existente ({len(prev_indices)}) ya cubre N={n_total}; no se amplía.")
        sample = df.loc[prev_indices].sort_index()
        _write_sample_meta(sample, n_total, seed, waves)
        return sample

    # Ampliación estratificada sobre el complemento.
    n_needed = n_total - len(prev_indices)
    remaining = df.drop(index=prev_indices, errors="ignore")
    added: list[int] = []
    for diff, group in remaining.groupby("Difficulty"):
        # Reparto proporcional al peso del estrato en el dataset completo.
        n_stratum = round(n_needed * len(df[df["Difficulty"] == diff]) / len(df))
        n_stratum = min(max(n_stratum, 0), len(group))
        if n_stratum:
            added += group.sample(n=n_stratum, random_state=seed).index.tolist()

    # Ajuste por redondeo: completar o recortar hasta n_needed exacto.
    leftovers = remaining.drop(index=added, errors="ignore")
    while len(added) < n_needed and len(leftovers) > 0:
        extra = leftovers.sample(n=min(n_needed - len(added), len(leftovers)),
                                 random_state=seed).index.tolist()
        added += extra
        leftovers = leftovers.drop(index=extra, errors="ignore")
    added = added[:n_needed]

    indices = sorted(prev_indices + added)
    sample = df.loc[indices].sort_index()
    waves.append({
        "wave": len(waves) + 1,
        "source": "pipeline_v3",
        "n_added": len(added),
        "n_cumulative": len(indices),
        "seed": seed,
        "indices_added": sorted(added),
    })
    _write_sample_meta(sample, n_total, seed, waves)
    log(f"Muestra ampliada: +{len(added)} escenarios nuevos -> N={len(sample)} "
        f"(dist={sample['Difficulty'].value_counts().sort_index().to_dict()}).")
    return sample


def _write_sample_meta(sample: pd.DataFrame, n_total: int, seed: int,
                       waves: list[dict]) -> None:
    OUTPUT_BASE.mkdir(parents=True, exist_ok=True)
    SAMPLE_FILE.write_text(json.dumps({
        "n_total_requested": n_total,
        "n_actual": len(sample),
        "seed": seed,
        "difficulty_distribution":
            sample["Difficulty"].value_counts().sort_index().to_dict(),
        "waves": waves,
        "indices": sorted(sample.index.tolist()),
    }, indent=2), encoding="utf-8")


# ============================================================================
# REUTILIZACIÓN DE LAS GENERACIONES DE v2
# ============================================================================

def seed_from_v2(model: str, condition: str, reeval: bool = False,
                 auditor: str = V2_AUDITOR) -> int:
    """
    Copia a outputs_v3 los .tf y los resultados funcionales ya obtenidos en v2
    para este modelo/condición. No modifica outputs_v2 (v2 queda intacto como
    experimento cerrado y citable).

    OJO con `reeval`: v2 corrió sin fijar la versión del provider AWS, así que
    sus resultados funcionales se obtuvieron con la versión que estuviera
    vigente ese día, mientras que v3 fija 5.31.0 [B2]. Mezclar ambos en un mismo
    análisis significa que 40 de los 120 escenarios se evaluaron contra un
    esquema de provider distinto. `reeval=True` descarta los resultados
    funcionales importados (NO los .tf, que se reutilizan tal cual) para que
    todo se vuelva a evaluar bajo el provider fijado. Cuesta ~30 s por archivo
    y es lo correcto si los 120 escenarios van a ir en la misma tabla.

    Devuelve cuántos archivos se importaron.
    """
    src = OUTPUT_V2 / model_slug(model) / condition
    dst = OUTPUT_BASE / model_slug(model) / condition
    if not (src / "terraform").is_dir():
        return 0

    (dst / "terraform").mkdir(parents=True, exist_ok=True)
    imported = 0
    for tf in sorted((src / "terraform").glob("question_*.tf")):
        target = dst / "terraform" / tf.name
        if not target.exists():
            shutil.copy2(tf, target)
            imported += 1

    # Resultados funcionales: los registros de v2 son, por construcción, del
    # intento 0. Se normalizan al esquema de v3.
    src_json = src / "iac_eval_results.json"
    dst_json = dst / "iac_eval_results.json"
    if reeval:
        # Se borran solo los resultados; los .tf ya copiados se conservan, así
        # que no se regenera nada: únicamente se repite plan + OPA.
        dst_json.unlink(missing_ok=True)
        (dst / "iac_eval_attempts.json").unlink(missing_ok=True)
    elif src_json.exists() and not dst_json.exists():
        records = json.loads(src_json.read_text(encoding="utf-8"))
        for r in records:
            r.setdefault("init_success", True)
            r["attempts_used"] = 1
            r["fc_at_1"] = 1 if r.get("opa_evaluation_result") == "Success" else 0
            r["fc_at_k"] = r["fc_at_1"]
            r["plan_success_at_k"] = bool(r.get("terraform_plan_success"))
            r["source"] = "v2"
        dst_json.write_text(json.dumps(records, indent=2), encoding="utf-8")

    # Auditoría: reutilizable tal cual, es el mismo archivo .tf auditado por el
    # mismo auditor externo.
    # La auditoría de v2 solo es reutilizable si esta corrida usa EL MISMO
    # auditor. Con otro auditor, importarla mezclaría dos detectores distintos
    # en el mismo archivo de resultados: se omite y se audita todo de nuevo.
    src_audit = src / "secllm_results.json"
    dst_audit = dst / "secllm_results.json"
    if auditor != V2_AUDITOR:
        return imported
    if src_audit.exists() and not dst_audit.exists():
        shutil.copy2(src_audit, dst_audit)

    # Las filas heredadas las produjo el auditor de v2. Sin dejarlo anotado, una
    # corrida de v3 con otro auditor las mezclaría en silencio. Se escribe
    # siempre que falte el marcador, no solo al copiar: si el marcador se
    # pierde, la celda quedaría desprotegida.
    marker = dst / "auditor.json"
    if dst_audit.exists() and not marker.exists():
        marker.write_text(
            json.dumps({"auditor": V2_AUDITOR, "origen": "outputs_v2"}, indent=2),
            encoding="utf-8")

    return imported


# ============================================================================
# FASE 1 — GENERACIÓN
# ============================================================================

def extract_hcl(text: str) -> str:
    if not text:
        return ""
    low = text.lower()
    for tag in ("```hcl", "```terraform"):
        if tag in low:
            return text[low.index(tag) + len(tag):].split("```")[0].strip()
    if "```" in text:
        parts = text.split("```")
        if len(parts) >= 3:
            return parts[1].strip()
    return text.strip()


def ollama_generate(prompt: str, model: str) -> str:
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False,
        # num_predict acota la salida: un modelo en bucle puede generar durante
        # minutos sin producir nada útil.
        "options": {"temperature": 0.2, "num_predict": MAX_GEN_TOKENS},
        "keep_alive": "10m",
    }
    for attempt in range(3):
        try:
            r = requests.post(OLLAMA_NATIVE_URL, json=payload, timeout=GEN_TIMEOUT)
            r.raise_for_status()
            return r.json().get("response", "")
        except Exception as e:
            log(f"    ERROR generando (intento {attempt + 1}/3): {e}")
            time.sleep(5)
    return ""


def generate_terraform(request: str, model: str, system_prompt: str) -> str:
    return ollama_generate(f"{system_prompt}\n\nUser request: {request}", model)


def repair_terraform(request: str, code: str, error: str, model: str) -> str:
    """
    Pide al modelo que corrija su propio código a partir del error de plan.

    Devuelve "" si el código es tan grande que reenviarlo desbordaría el
    contexto: en ese caso la reparación no puede funcionar y solo gastaría GPU.
    """
    if len(code) > MAX_REPAIR_CODE_CHARS:
        return ""
    return ollama_generate(
        REPAIR_PROMPT.format(request=request, code=code,
                             error=(error or "")[:MAX_ERROR_CHARS]),
        model,
    )


# ============================================================================
# FASE 2 — EVALUACIÓN FUNCIONAL (terraform plan + OPA)
# ============================================================================

def _walk_values(node):
    if isinstance(node, dict):
        for v in node.values():
            yield from _walk_values(v)
    elif isinstance(node, (list, tuple)):
        for v in node:
            yield from _walk_values(v)
    else:
        yield node


# --- Workspace persistente -------------------------------------------------
# v2 creaba un directorio por evaluación y lo borraba al final. En Windows eso
# significa que `terraform init` COPIA los ~358 MB del binario del provider en
# cada archivo evaluado (no hay symlinks), y el borrado con ignore_errors=True
# falla en silencio si el .exe sigue bloqueado: medido, deja 358 MB por
# evaluación. Con 960 evaluaciones serían ~340 GB.
#
# Aquí se reutiliza UN solo workspace por proceso: init se ejecuta una vez y
# entre archivos solo se intercambia main.tf. Además de no acumular disco, baja
# el coste por evaluación de ~20 s a ~5 s.
_WS_DIR = Path("./tmp/tf_ws_v3")
_ws_ready = False
_ws_override = None


def _clean_workspace(ws: Path) -> None:
    """Borra los .tf y los artefactos de plan, conservando .terraform/."""
    for f in list(ws.glob("*.tf")) + list(ws.glob("plan.out")) + list(ws.glob("plan.json")):
        try:
            f.unlink()
        except OSError:
            pass


def _needs_init(stderr: str) -> bool:
    marcas = ("terraform init", "Missing required provider",
              "required plugins are not installed",
              "Inconsistent dependency lock file",
              "provider requirements cannot be satisfied")
    return any(m.lower() in (stderr or "").lower() for m in marcas)


def cleanup_workspace() -> None:
    """
    Limpieza final del workspace, con reintentos.

    Dos motivos por los que un borrado directo falla en Windows: el .exe del
    provider (~358 MB) puede seguir bloqueado unos instantes tras el último
    plan, y la ruta del binario dentro de .terraform/providers/... supera los
    260 caracteres de MAX_PATH. El prefijo \\?\ evita lo segundo y los
    reintentos lo primero. Un fallo aquí solo desperdicia disco, así que nunca
    propaga: se reporta y sigue.
    """
    for base in (Path("./tmp/tf_ws_v3"), Path("./tmp/terraform_config_v3"),
                 Path("./tmp/rego_config_v3")):
        for intento in range(4):
            if not base.exists():
                break
            objetivo = str(base.resolve())
            if os.name == "nt" and not objetivo.startswith("\\\\?\\"):
                objetivo = "\\\\?\\" + objetivo
            shutil.rmtree(objetivo, ignore_errors=True)
            if base.exists():
                time.sleep(1.5)
        if base.exists():
            log(f"[AVISO] no se pudo borrar {base}; bórralo a mano para "
                f"liberar disco.")


def functional_eval(code: str, policy_rego: str, run_uuid: str) -> dict:
    """
    Ejecuta `terraform init` + `terraform plan` y, si el plan pasa, evalúa la
    política Rego del dataset con OPA.

    El fallo de init se registra por separado del fallo de plan [B3] y el
    timeout se distingue de un fallo real [B4].
    """
    global _ws_ready, _ws_override

    result = {
        "init_success": False,
        "terraform_plan_success": False,
        "opa_evaluation_result": "No opa_result",
        "terraform_plan_error": "No error",
        "opa_evaluation_error": "None",
    }

    ws = _WS_DIR
    rego_dir = Path("./tmp/rego_config_v3") / run_uuid
    cwd = os.getcwd()

    try:
        ws.mkdir(parents=True, exist_ok=True)
        _clean_workspace(ws)

        override = build_override(code)
        (ws / "main.tf").write_text(code, encoding="utf-8", errors="ignore")
        (ws / "zz_provider_override.tf").write_text(override, encoding="utf-8")

        # Si cambia el bloque de providers respecto al archivo anterior, hay que
        # reinicializar (el conjunto de plugins requerido puede ser otro).
        if override != _ws_override:
            _ws_ready = False
            _ws_override = override

        os.chdir(ws)
        try:
            def _init() -> subprocess.CompletedProcess:
                return subprocess.run(
                    ["terraform", "init", "-backend=false", "-no-color"],
                    capture_output=True, text=True, timeout=INIT_TIMEOUT)

            if not _ws_ready:
                init = _init()
                result["init_success"] = init.returncode == 0
                if init.returncode != 0:
                    result["terraform_plan_error"] = (
                        f"terraform init failed: {init.stderr}")
                    return result
                _ws_ready = True
            else:
                result["init_success"] = True

            plan = subprocess.run(["terraform", "plan", "-out", "plan.out", "-no-color"],
                                  capture_output=True, text=True, timeout=PLAN_TIMEOUT)

            # El código puede necesitar un provider que el workspace no tiene
            # todavía (random, tls, null...): reinicializar y reintentar UNA vez.
            if plan.returncode != 0 and _needs_init(plan.stderr):
                init = _init()
                result["init_success"] = init.returncode == 0
                if init.returncode == 0:
                    _ws_ready = True
                    plan = subprocess.run(
                        ["terraform", "plan", "-out", "plan.out", "-no-color"],
                        capture_output=True, text=True, timeout=PLAN_TIMEOUT)
                else:
                    _ws_ready = False

        except subprocess.TimeoutExpired:
            result["terraform_plan_error"] = "TIMEOUT: terraform init/plan"  # [B4]
            return result
        except Exception as e:
            result["terraform_plan_error"] = f"terraform exception: {e}"
            return result
        finally:
            os.chdir(cwd)

        result["terraform_plan_success"] = plan.returncode == 0
        if plan.returncode != 0:
            result["terraform_plan_error"] = plan.stderr
            return result

        # --- plan -> json ---
        os.chdir(ws)
        try:
            with open("plan.json", "w") as f:
                subprocess.run(["terraform", "show", "-json", "plan.out"],
                               stdout=f, text=True, timeout=PLAN_TIMEOUT)
        finally:
            os.chdir(cwd)

        # --- OPA ---
        rego_dir.mkdir(parents=True, exist_ok=True)
        (rego_dir / "policy.rego").write_text(policy_rego, encoding="utf-8")
        try:
            policy_text = (rego_dir / "policy.rego").read_text(
                encoding="utf-8", errors="ignore")
            opa_cmd = ["opa", "eval"]
            if "import rego.v1" not in policy_text:
                opa_cmd.append("--v0-compatible")
            opa_cmd += ["-i", str(ws / "plan.json"),
                        "-d", str(rego_dir / "policy.rego"), "data"]
            opa = subprocess.run(opa_cmd, capture_output=True, text=True,
                                 timeout=OPA_TIMEOUT)
            values = list(_walk_values(
                json.loads(opa.stdout)["result"][0]["expressions"][0]["value"]))
            success = False not in values
            result["opa_evaluation_result"] = "Success" if success else "Failure"
            result["opa_evaluation_error"] = ("No error" if success
                                              else "Rule violation found.")
        except Exception as e:
            result["opa_evaluation_result"] = "Failure"
            result["opa_evaluation_error"] = f"OPA exception: {e}"

        return result

    finally:
        os.chdir(cwd)
        shutil.rmtree(rego_dir, ignore_errors=True)


# ============================================================================
# FASE 1+2 — GENERACIÓN, EVALUACIÓN Y AUTO-REPARACIÓN [V2]
# ============================================================================

def run_generation_and_eval(model: str, condition: str, samples: pd.DataFrame,
                            repair_rounds: int) -> None:
    cond_dir = OUTPUT_BASE / model_slug(model) / condition
    tf_dir = cond_dir / "terraform"
    tf_dir.mkdir(parents=True, exist_ok=True)

    func_json = cond_dir / "iac_eval_results.json"
    attempts_json = cond_dir / "iac_eval_attempts.json"

    results = _load_json_list(func_json)
    attempts = _load_json_list(attempts_json)
    by_file = {r["file"]: r for r in results}

    system_prompt = PROMPTS[condition]
    log(f"--- {model} [{condition}]: generación + evaluación "
        f"(reparación: {repair_rounds} ronda(s)) ---")

    for idx, row in samples.iterrows():
        base_name = attempt_filename(idx, 0)
        record = by_file.get(base_name)

        # ¿Ya está cerrado? Cerrado = evaluado y, o bien pasó, o bien agotó las
        # rondas de reparación pedidas.
        if record and (record.get("fc_at_k") == 1
                       or record.get("attempts_used", 1) >= repair_rounds + 1):
            continue

        # ---------- Intento 0 ----------
        tf_file = tf_dir / base_name
        if not tf_file.exists() or tf_file.stat().st_size == 0:
            log(f"  [{idx}] generando {base_name} ...")
            code = extract_hcl(generate_terraform(row["Prompt"], model, system_prompt))
            if not code.strip():
                log(f"  [{idx}] generación VACÍA; se reintenta en la próxima corrida.")
                tf_file.unlink(missing_ok=True)
                continue
            if len(code) > MAX_CODE_CHARS:
                # Se guarda igual: descartarla sesgaría Fc al alza (es una salida
                # real del modelo y su fallo cuenta). Solo se deja constancia,
                # porque la reparación no podrá con ella.
                log(f"  [{idx}] generación DESBOCADA ({len(code)} chars, "
                    f"máx legítimo en v2: 6537); se registra como fallo.")
            tf_file.write_text(code, encoding="utf-8")
        else:
            code = tf_file.read_text(encoding="utf-8", errors="ignore")

        if record is None:
            log(f"  [{idx}] evaluación funcional {base_name} ...")
            res = _safe_eval(code, row["Rego intent"])
            record = {
                "file": base_name,
                "scenario_index": int(idx),
                # Claves v2-compatibles: SIEMPRE reflejan el intento 0, de modo
                # que generate_report_v2.py siga midiendo exactamente Fc@1.
                **res,
                "fc_at_1": 1 if res["opa_evaluation_result"] == "Success" else 0,
                "fc_at_k": 1 if res["opa_evaluation_result"] == "Success" else 0,
                "plan_success_at_k": bool(res["terraform_plan_success"]),
                "attempts_used": 1,
                "source": "v3",
            }
            results.append(record)
            by_file[base_name] = record
            attempts.append({"file": base_name, "scenario_index": int(idx),
                             "attempt": 0, **res})
            _dump(func_json, results)
            _dump(attempts_json, attempts)

        # ---------- Rondas de reparación ----------
        # Solo si el plan del último intento falló. Si el plan pasa pero OPA
        # falla, NO se repara: eso sería optimizar contra la política de
        # evaluación y contaminaría la métrica.
        last_code = code
        last_error = record.get("terraform_plan_error", "")
        while (not record["plan_success_at_k"]
               and record["attempts_used"] <= repair_rounds):
            k = record["attempts_used"]  # nº del intento de reparación (1, 2, ...)
            rep_name = attempt_filename(idx, k)
            rep_file = tf_dir / rep_name

            if not rep_file.exists() or rep_file.stat().st_size == 0:
                log(f"  [{idx}] reparando (ronda {k}) -> {rep_name} ...")
                fixed = extract_hcl(
                    repair_terraform(row["Prompt"], last_code, last_error, model))
                if not fixed.strip():
                    log(f"  [{idx}] reparación VACÍA; se corta aquí.")
                    break
                rep_file.write_text(fixed, encoding="utf-8")
            else:
                fixed = rep_file.read_text(encoding="utf-8", errors="ignore")

            res = _safe_eval(fixed, row["Rego intent"])
            attempts.append({"file": rep_name, "scenario_index": int(idx),
                             "attempt": k, **res})
            record["attempts_used"] = k + 1
            record["plan_success_at_k"] = bool(res["terraform_plan_success"])
            if res["opa_evaluation_result"] == "Success":
                record["fc_at_k"] = 1
            last_code, last_error = fixed, res.get("terraform_plan_error", "")

            _dump(func_json, results)
            _dump(attempts_json, attempts)

            if record["fc_at_k"] == 1:
                log(f"  [{idx}] RECUPERADO por reparación en la ronda {k}.")
                break


def _safe_eval(code: str, rego: str) -> dict:
    cwd = os.getcwd()
    os.chdir(IAC_EVAL_DIR)
    try:
        return functional_eval(code, rego, str(uuid.uuid4()))
    except Exception as e:
        return {
            "init_success": False,
            "terraform_plan_success": False,
            "opa_evaluation_result": "No opa_result",
            "terraform_plan_error": f"eval exception: {e}",
            "opa_evaluation_error": "None",
        }
    finally:
        os.chdir(cwd)


def cleanup_all_temp() -> None:
    """Borra el workspace de Terraform (las rutas son relativas a IAC_EVAL_DIR)."""
    cwd = os.getcwd()
    try:
        os.chdir(IAC_EVAL_DIR)
        cleanup_workspace()
    except Exception as e:
        log(f"[AVISO] no se pudo limpiar el workspace temporal: {e}")
    finally:
        os.chdir(cwd)


def _load_json_list(path: Path) -> list:
    if not path.exists():
        return []
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return []


def _dump(path: Path, data) -> None:
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


# ============================================================================
# FASE 3 — AUDITORÍA CON AUDITOR EXTERNO COMÚN
# ============================================================================

def write_audit_config(auditor_model: str) -> Path:
    import yaml
    with open(SECLLM_TF_CONFIG, encoding="utf-8") as f:
        cfg = yaml.safe_load(f)
    c = cfg["config"][0]
    c["model"] = auditor_model
    c["url"] = OLLAMA_OPENAI_URL
    c["use_huggingface"] = False
    c["temperature"] = 0
    temp = SECLLM_DIR / f"temp_audit_{model_slug(auditor_model)}.yaml"
    with open(temp, "w", encoding="utf-8") as f:
        yaml.dump(cfg, f, allow_unicode=True)
    return temp


def load_done_paths(results_json: Path) -> set:
    return {item.get("PATH") for item in _load_json_list(results_json)}


def audit_file(tf_file: Path, results_json: Path, config_path: Path) -> None:
    subprocess.run(
        [sys.executable, str(SECLLM_SCRIPT),
         "-f", str(tf_file), "-o", str(results_json), "-c", str(config_path),
         "-t", str(AUDIT_THREADS), "-a", "-j"],
        cwd=str(SECLLM_DIR), timeout=AUDIT_FILE_TIMEOUT,
    )


def run_security_audit(model: str, condition: str, samples: pd.DataFrame,
                       auditor_model: str, audit_config: Path,
                       audit_repairs: bool) -> None:
    """
    Audita el intento 0 de cada escenario (comparable con v2). Si
    `audit_repairs` está activo, audita además las versiones reparadas: hace
    falta para poder analizar los smells del código que SOLO llega a Fc=1
    después de repararse.
    """
    cond_dir = OUTPUT_BASE / model_slug(model) / condition
    tf_dir = cond_dir / "terraform"
    audit_json = cond_dir / "secllm_results.json"

    # SecLLM no escribe qué modelo produjo cada fila, así que dos auditores
    # distintos sobre el mismo directorio quedan mezclados sin dejar rastro: el
    # resultado ya no mide "lo que ve un auditor", sino una mezcla. Se registra
    # el auditor usado y se aborta la celda si cambia.
    marker = cond_dir / "auditor.json"
    previo = None
    if marker.exists():
        try:
            previo = json.loads(marker.read_text(encoding="utf-8")).get("auditor")
        except (json.JSONDecodeError, OSError):
            previo = None

    if previo and previo != auditor_model and audit_json.exists():
        log(f"[ABORTADA] {model} [{condition}]: ya fue auditado por '{previo}' y "
            f"ahora se pide '{auditor_model}'. Mezclar auditores invalida la "
            f"comparación. Borra secllm_results.json y auditor.json de esa "
            f"carpeta para re-auditar desde cero.")
        return

    cond_dir.mkdir(parents=True, exist_ok=True)
    marker.write_text(json.dumps({"auditor": auditor_model}, indent=2),
                      encoding="utf-8")

    log(f"--- {model} [{condition}]: auditoría con '{auditor_model}' ---")
    done = load_done_paths(audit_json)

    targets: list[Path] = []
    for idx in samples.index:
        targets.append(tf_dir / attempt_filename(idx, 0))
        if audit_repairs:
            targets += sorted(tf_dir.glob(f"question_{idx:04d}.a*.tf"))

    for tf_file in targets:
        if not tf_file.exists() or tf_file.stat().st_size == 0:
            continue
        if tf_file.name in done:
            continue
        log(f"  auditando {tf_file.name} ...")
        try:
            audit_file(tf_file, audit_json, audit_config)
        except subprocess.TimeoutExpired:
            log(f"  TIMEOUT auditando {tf_file.name}; se continúa.")
        except Exception as e:
            log(f"  ERROR auditando {tf_file.name}: {e}")


# ============================================================================
# RESUMEN
# ============================================================================

def summarize(models: list[str], conditions: list[str]) -> None:
    log("=" * 72)
    log("RESUMEN  (Fc@1 = a la primera · Fc@k = tras reparación)")
    log(f"{'modelo':20s} {'cond':5s} {'n':>4s} {'plan@1':>7s} {'plan@k':>7s} "
        f"{'Fc@1':>5s} {'Fc@k':>5s}")
    tot = {"n": 0, "p1": 0, "pk": 0, "f1": 0, "fk": 0}
    for m in models:
        for c in conditions:
            recs = _load_json_list(
                OUTPUT_BASE / model_slug(m) / c / "iac_eval_results.json")
            if not recs:
                continue
            n = len(recs)
            p1 = sum(1 for r in recs if r.get("terraform_plan_success"))
            pk = sum(1 for r in recs if r.get("plan_success_at_k"))
            f1 = sum(r.get("fc_at_1", 0) for r in recs)
            fk = sum(r.get("fc_at_k", 0) for r in recs)
            for k, v in zip(tot, (n, p1, pk, f1, fk)):
                tot[k] += v
            log(f"{model_slug(m):20s} {c:5s} {n:4d} {p1:7d} {pk:7d} {f1:5d} {fk:5d}")
    log(f"{'TOTAL':20s} {'':5s} {tot['n']:4d} {tot['p1']:7d} {tot['pk']:7d} "
        f"{tot['f1']:5d} {tot['fk']:5d}")
    log("=" * 72)


# ============================================================================
# MAIN
# ============================================================================

def parse_args():
    p = argparse.ArgumentParser(description="Pipeline v3 (N ampliable + auto-reparación)")
    p.add_argument("--models", help="lista separada por comas")
    p.add_argument("--n", type=int, help="escenarios por modelo/condición")
    p.add_argument("--repair-rounds", type=int, help="rondas de auto-reparación")
    p.add_argument("--conditions", help="P0, P1 o P0,P1")
    p.add_argument("--auditor", help="modelo auditor externo común")
    p.add_argument("--no-seed-from-v2", action="store_true",
                   help="no reutilizar las generaciones de outputs_v2")
    p.add_argument("--reeval-imported", action="store_true",
                   help="re-evaluar los .tf importados de v2 bajo el provider "
                        "fijado (no regenera código; ~30 s por archivo)")
    p.add_argument("--skip-audit", action="store_true",
                   help="solo generación + evaluación funcional")
    p.add_argument("--audit-repairs", action="store_true",
                   help="auditar también las versiones reparadas")
    p.add_argument("--summary-only", action="store_true",
                   help="solo imprimir el resumen de lo ya hecho")
    p.add_argument("--limit", type=int,
                   help="procesar solo los primeros N escenarios de la muestra "
                        "(para validar una corrida antes de lanzarla entera; el "
                        "trabajo hecho cuenta para la corrida final)")
    p.add_argument("--indices-file",
                   help="archivo de turno generado por split_remaining.py: "
                        "procesa SOLO esos escenarios. Es lo que permite repartir "
                        "el experimento entre varias máquinas sin solaparse")
    return p.parse_args()


def main():
    args = parse_args()

    models = MODELS
    if os.environ.get("PIPELINE_MODELS"):
        models = [m.strip() for m in os.environ["PIPELINE_MODELS"].split(",") if m.strip()]
    if args.models:
        models = [m.strip() for m in args.models.split(",") if m.strip()]

    conditions = CONDITIONS
    if args.conditions:
        conditions = [c.strip() for c in args.conditions.split(",") if c.strip()]

    n_samples = args.n or NUM_SAMPLES
    repair_rounds = REPAIR_ROUNDS if args.repair_rounds is None else args.repair_rounds
    auditor = args.auditor or COMMON_AUDITOR

    OUTPUT_BASE.mkdir(parents=True, exist_ok=True)
    log("=" * 72)
    log("PIPELINE v3 — N ampliable por oleadas + auto-reparación")
    log(f"  Modelos            : {models}")
    log(f"  Auditor externo    : {auditor}")
    log(f"  Condiciones        : {conditions}")
    log(f"  N por modelo/cond  : {n_samples} (estratificado, seed={RANDOM_SEED})")
    log(f"  Rondas reparación  : {repair_rounds}")
    log(f"  Provider AWS       : {AWS_PROVIDER_VERSION} (fijado)")
    log("=" * 72)

    if auditor in models:
        log("[ADVERTENCIA] El auditor está en MODELS: reintroduce el confound de "
            "auto-auditoría para ese modelo.")

    df = pd.read_csv(DATASET)
    samples = get_or_extend_sample(df, n_samples, RANDOM_SEED)

    if args.indices_file:
        turno = json.loads(Path(args.indices_file).read_text(encoding="utf-8"))
        idx_turno = turno["indices"] if isinstance(turno, dict) else turno
        # Un turno con índices ajenos a la muestra evaluaría escenarios fuera del
        # diseño y su Fc no sería agregable con el del resto: se aborta en vez de
        # recortar en silencio.
        ajenos = sorted(set(idx_turno) - set(samples.index))
        if ajenos:
            raise SystemExit(
                f"El turno {args.indices_file} incluye {len(ajenos)} índices que "
                f"no están en la muestra de 120 (p. ej. {ajenos[:5]}). Regenera "
                f"los turnos con split_remaining.py sobre este experiment_sample.json.")
        samples = samples.loc[sorted(idx_turno)]
        log(f"[--indices-file] Turno '{turno.get('turno', '?')}': "
            f"{len(samples)} escenarios "
            f"(dist={samples['Difficulty'].value_counts().sort_index().to_dict()}).")

    if args.limit:
        samples = samples.head(args.limit)
        log(f"[--limit] Solo se procesarán los primeros {len(samples)} escenarios.")

    if args.summary_only:
        summarize(models, conditions)
        return

    # Reutilizar todo lo que v2 ya produjo (no toca outputs_v2).
    if not args.no_seed_from_v2:
        if args.reeval_imported:
            log("Re-evaluación de lo importado ACTIVA: los .tf de v2 se "
                "conservan pero su plan+OPA se repite bajo el provider fijado.")
        for m in models:
            for c in conditions:
                imported = seed_from_v2(m, c, reeval=args.reeval_imported,
                                        auditor=auditor)
                if imported:
                    log(f"Importados de v2: {imported} archivos para {m} [{c}].")

    # --- Fases 1 + 2 ---
    try:
        for m in models:
            for c in conditions:
                try:
                    run_generation_and_eval(m, c, samples, repair_rounds)
                except Exception as e:
                    log(f"ERROR fatal en generación {m}[{c}]: {e}")
    finally:
        # Se limpia aunque se interrumpa con Ctrl-C: el workspace pesa ~360 MB.
        cleanup_all_temp()

    # --- Fase 3 ---
    if not args.skip_audit:
        log("=" * 72)
        log(f"FASE 3 — auditoría externa con '{auditor}'")
        log("=" * 72)
        audit_config = write_audit_config(auditor)
        try:
            for m in models:
                for c in conditions:
                    try:
                        run_security_audit(m, c, samples, auditor, audit_config,
                                           args.audit_repairs)
                    except Exception as e:
                        log(f"ERROR fatal en auditoría {m}[{c}]: {e}")
        finally:
            audit_config.unlink(missing_ok=True)

    summarize(models, conditions)
    log("PIPELINE v3 COMPLETADO. Siguiente: python scripts/generate_report_v2.py "
        "(apuntando a outputs_v3) para Fc@1, y el análisis de Fc@k con "
        "iac_eval_attempts.json.")


if __name__ == "__main__":
    main()
