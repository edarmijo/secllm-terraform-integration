#!/usr/bin/env python3
"""
pipeline.py - Pipeline nocturno IaC-Eval + SecLLM (auto-auditoria)
==================================================================

Para CADA modelo LLM local (servido por Ollama) ejecuta 3 fases:

  Fase 1 - GENERACION
      Toma N preguntas del dataset IaC-Eval y le pide al modelo que genere
      el codigo Terraform (HCL) correspondiente.

  Fase 2 - EVALUACION FUNCIONAL (IaC-Eval)
      Para cada .tf corre `terraform plan` y, si compila, evalua la politica
      de seguridad Rego del dataset con OPA. Mide si el codigo FUNCIONA.

  Fase 3 - AUTO-AUDITORIA DE SEGURIDAD (SecLLM)
      El MISMO modelo que genero el codigo lo audita con las 8 reglas de
      seguridad de SecLLM (config_terraform.yaml). Mide si el modelo es capaz
      de encontrar sus propias vulnerabilidades.

El script es RESUMIBLE: si se interrumpe, al relanzarlo omite lo ya hecho
(archivos .tf existentes, evaluaciones y auditorias ya guardadas) y continua
donde quedo. Asi, aunque no termine en una noche, nunca se pierde el progreso.

Salidas por modelo en outputs/<modelo>/:
    terraform/question_XXXX.tf   -> codigo generado
    iac_eval_results.json        -> resultado funcional (plan + OPA)
    secllm_results.json          -> resultado de la auto-auditoria

Configurable mas abajo en la seccion CONFIGURACION.
"""

import os
import sys
import json
import time
import uuid
import shutil
import subprocess
from pathlib import Path
from datetime import datetime

import requests
import pandas as pd

# ============================================================================
# CONFIGURACION
# ============================================================================

# Modelos a evaluar (deben existir en `ollama list`).
# Se puede sobrescribir sin editar el archivo con la variable de entorno
# PIPELINE_MODELS (lista separada por comas).
MODELS = [
    "qwen2.5-coder:32b",
    "deepseek-r1:32b",
    "devstral-small-2:latest",
    "glm-4.7-flash:q8_0",
]
if os.environ.get("PIPELINE_MODELS"):
    MODELS = [m.strip() for m in os.environ["PIPELINE_MODELS"].split(",") if m.strip()]

# Cuantas preguntas del dataset procesar por modelo.
#
# IMPORTANTE - rendimiento en este hardware (RTX 4070 Laptop, 8 GB VRAM):
# los modelos (15-31 GB) NO caben en la GPU y corren en gran parte en CPU,
# por lo que cada llamada de auditoria tarda ~3-4 min. Estimacion aproximada:
#
#     por modelo  = N generaciones + N planes + (N * 8 reglas) auditorias
#     5 archivos  ~  2-3 h  por modelo  ->  ~10-12 h los 4 modelos (1 noche)
#    20 archivos  ~  9-10 h por modelo  ->  varios dias los 4 modelos
#
# Con 5 obtienes una tabla comparativa completa en una noche. Si quieres mas
# cobertura, sube el numero: es resumible, asi que puedes acumularlo en varias
# noches sin perder lo ya hecho.
# Tambien se puede fijar con la variable de entorno PIPELINE_NUM_SAMPLES.
NUM_SAMPLES = int(os.environ.get("PIPELINE_NUM_SAMPLES", "5"))

# Endpoint de Ollama (API compatible con OpenAI).
OLLAMA_OPENAI_URL = "http://localhost:11434/v1"
OLLAMA_NATIVE_URL = "http://localhost:11434/api/generate"

# Reiniciar Ollama (taskkill + serve) antes de cada modelo.
# Por defecto DESACTIVADO: en Windows, matar ollama.exe y lanzar `ollama serve`
# a mano choca con la app de escritorio de Ollama y provoca ConnectionReset.
# Ademas Ollama ya descarga el modelo anterior automaticamente al pedir uno
# nuevo (no caben dos a la vez en 8 GB), asi que el reinicio es innecesario.
RESTART_OLLAMA_BETWEEN_MODELS = False

# Timeouts (segundos).
GEN_TIMEOUT = 1800          # generacion de un .tf
PLAN_TIMEOUT = 120          # terraform plan
AUDIT_FILE_TIMEOUT = 3600   # auditoria SecLLM de un archivo (8 reglas)

# ============================================================================
# RUTAS (derivadas de la ubicacion de este archivo: no hay rutas hardcodeadas)
# ============================================================================

SCRIPT_DIR = Path(__file__).resolve().parent          # .../integration/scripts
INTEGRATION_DIR = SCRIPT_DIR.parent                   # .../integration
BASE_DIR = INTEGRATION_DIR.parent                     # .../research_iac

DATASET = INTEGRATION_DIR / "iac_eval_data.csv"
OUTPUT_BASE = INTEGRATION_DIR / "outputs"
SECLLM_TF_CONFIG = INTEGRATION_DIR / "config_terraform.yaml"   # las 8 reglas

IAC_EVAL_DIR = BASE_DIR / "iac-eval" / "evaluation"
SECLLM_DIR = BASE_DIR / "SecLLM" / "SecLLM"
SECLLM_SCRIPT = SECLLM_DIR / "secllm" / "secllm.py"

LOG_FILE = OUTPUT_BASE / "pipeline_log.txt"

# Que `terraform` y `opa` esten en el PATH para la fase funcional, y cachear
# el provider de AWS para no re-descargarlo en cada `terraform init`.
os.environ["PATH"] += os.pathsep + str(BASE_DIR)
os.environ.setdefault("TF_PLUGIN_CACHE_DIR", str(BASE_DIR / ".tf_plugin_cache"))
Path(os.environ["TF_PLUGIN_CACHE_DIR"]).mkdir(parents=True, exist_ok=True)

# Credenciales AWS dummy: el provider de AWS las exige para inicializar. Con
# valores falsos, `terraform plan` corre OFFLINE (no autentica contra AWS real)
# y evalua la sintaxis/estructura del codigo, que es lo que mide IaC-Eval.
os.environ.setdefault("AWS_ACCESS_KEY_ID", "test")
os.environ.setdefault("AWS_SECRET_ACCESS_KEY", "test")
os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")
os.environ.setdefault("AWS_REGION", "us-east-1")

# Override que se añade a cada config para que el provider AWS no contacte AWS.
AWS_PROVIDER_OVERRIDE = '''provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}
'''

SYSTEM_PROMPT_GEN = (
    "You are an expert Terraform engineer. "
    "Generate valid, deployable Terraform HCL code based on the user request. "
    "Create IAM roles and provider/region config as needed, and make sure there "
    "are no undeclared variables. Do NOT include explanations. Output ONLY the "
    "Terraform code inside a single ```hcl ... ``` block."
)


# ============================================================================
# UTILIDADES
# ============================================================================

def log(msg):
    line = f"[{datetime.now():%Y-%m-%d %H:%M:%S}] {msg}"
    print(line, flush=True)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(line + "\n")


def model_dir_name(model):
    """qwen2.5-coder:32b -> qwen2_5-coder_32b (mismo esquema que ya se usaba)."""
    return model.replace(":", "_").replace(".", "_")


def restart_ollama():
    log(">>> Reiniciando Ollama para liberar VRAM...")
    subprocess.run("taskkill /F /IM ollama.exe /T", shell=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(3)
    try:
        subprocess.Popen(["ollama", "serve"], creationflags=subprocess.CREATE_NO_WINDOW,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        log(f"    (no se pudo lanzar 'ollama serve': {e}; se asume servicio activo)")
    # Esperar a que el servidor responda.
    for _ in range(30):
        try:
            requests.get("http://localhost:11434/api/tags", timeout=2)
            log(">>> Ollama listo.")
            return
        except Exception:
            time.sleep(2)
    log(">>> Aviso: Ollama no respondio el health-check; se continua igualmente.")


def load_done_paths(results_json):
    """Devuelve el set de archivos (PATH) ya presentes en un JSON de SecLLM."""
    if not results_json.exists():
        return set()
    try:
        with open(results_json, encoding="utf-8") as f:
            return {item.get("PATH") for item in json.load(f)}
    except (json.JSONDecodeError, OSError):
        return set()


# ============================================================================
# FASE 1 - GENERACION
# ============================================================================

def extract_hcl(text):
    """Extrae el bloque HCL de la respuesta del modelo."""
    if not text:
        return ""
    low = text.lower()
    if "```hcl" in low:
        return text[low.index("```hcl") + 6:].split("```")[0].strip()
    if "```terraform" in low:
        return text[low.index("```terraform") + 12:].split("```")[0].strip()
    if "```" in text:
        parts = text.split("```")
        if len(parts) >= 3:
            return parts[1].strip()
    return text.strip()


def generate_terraform(prompt, model):
    """Pide a Ollama el codigo Terraform para una pregunta (con reintentos)."""
    payload = {
        "model": model,
        "prompt": f"{SYSTEM_PROMPT_GEN}\n\nUser request: {prompt}",
        "stream": False,
        "options": {"temperature": 0.2},
        "keep_alive": "10m",   # mantener el modelo cargado para la auditoria
    }
    for attempt in range(3):
        try:
            r = requests.post(OLLAMA_NATIVE_URL, json=payload, timeout=GEN_TIMEOUT)
            r.raise_for_status()
            return r.json().get("response", "")
        except Exception as e:
            log(f"    ERROR generando con {model} (intento {attempt + 1}/3): {e}")
            time.sleep(5)
    return ""


# ============================================================================
# FASE 2 - EVALUACION FUNCIONAL (IaC-Eval: terraform plan + OPA)
# ============================================================================

def functional_eval(code, policy_rego, run_uuid):
    """Corre `terraform plan` y, si compila, evalua la politica Rego con OPA.

    Replica el motor original de IaC-Eval. Devuelve un dict con el resultado.
    """
    result = {
        "terraform_plan_success": False,
        "opa_evaluation_result": "No opa_result",
        "terraform_plan_error": "No error",
        "opa_evaluation_error": "None",
    }

    tf_dir = Path("./tmp/terraform_config") / run_uuid
    if tf_dir.exists():
        shutil.rmtree(tf_dir, ignore_errors=True)
    tf_dir.mkdir(parents=True, exist_ok=True)
    (tf_dir / "main.tf").write_text(code, encoding="utf-8", errors="ignore")
    # Override de Terraform: fuerza al provider AWS a inicializar OFFLINE (sin
    # llamar a IMDS ni a STS), para validar el codigo sin credenciales reales.
    (tf_dir / "zz_provider_override.tf").write_text(AWS_PROVIDER_OVERRIDE, encoding="utf-8")

    cwd = os.getcwd()
    os.chdir(tf_dir)
    try:
        subprocess.run(["terraform", "init", "-backend=false"],
                       capture_output=True, text=True, timeout=300)
        plan = subprocess.run(["terraform", "plan", "-out", "plan.out", "-no-color"],
                              capture_output=True, text=True, timeout=PLAN_TIMEOUT)
    except Exception as e:
        os.chdir(cwd)
        result["terraform_plan_error"] = f"terraform exception: {e}"
        return result
    finally:
        os.chdir(cwd)

    result["terraform_plan_success"] = plan.returncode == 0
    if plan.returncode != 0:
        result["terraform_plan_error"] = plan.stderr
        return result

    # El plan compilo -> evaluar la politica de seguridad con OPA.
    rego_dir = Path("./tmp/rego_config") / run_uuid
    rego_dir.mkdir(parents=True, exist_ok=True)
    (rego_dir / "policy.rego").write_text(policy_rego, encoding="utf-8")

    os.chdir(tf_dir)
    try:
        with open("plan.json", "w") as f:
            subprocess.run(["terraform", "show", "-json", "plan.out"],
                           stdout=f, text=True, timeout=PLAN_TIMEOUT)
    finally:
        os.chdir(cwd)

    try:
        # Las politicas del dataset usan sintaxis Rego v0 (sin "import rego.v1").
        # OPA 1.x usa v1 por defecto, asi que hay que pedir --v0-compatible para
        # esas; si la politica declara rego.v1 se usa el modo v1 (por defecto).
        policy_text = (rego_dir / "policy.rego").read_text(encoding="utf-8", errors="ignore")
        opa_cmd = ["opa", "eval"]
        if "import rego.v1" not in policy_text:
            opa_cmd.append("--v0-compatible")
        opa_cmd += ["-i", str(tf_dir / "plan.json"),
                    "-d", str(rego_dir / "policy.rego"), "data"]
        opa = subprocess.run(opa_cmd, capture_output=True, text=True, timeout=120)
        values = list(_walk_values(json.loads(opa.stdout)["result"][0]["expressions"][0]["value"]))
        success = False not in values
        result["opa_evaluation_result"] = "Success" if success else "Failure"
        result["opa_evaluation_error"] = "No error" if success else "Rule violation found."
    except Exception as e:
        result["opa_evaluation_result"] = "Failure"
        result["opa_evaluation_error"] = f"OPA exception: {e}"

    return result


def _walk_values(node):
    """Recorre recursivamente la salida de OPA y emite todos los valores hoja."""
    if isinstance(node, dict):
        for v in node.values():
            yield from _walk_values(v)
    elif isinstance(node, (list, tuple)):
        for v in node:
            yield from _walk_values(v)
    else:
        yield node


# ============================================================================
# FASE 3 - AUTO-AUDITORIA DE SEGURIDAD (SecLLM)
# ============================================================================

def write_audit_config(model):
    """Crea un config temporal de SecLLM con las 8 reglas de Terraform,
    apuntando al `model` indicado servido por Ollama."""
    import yaml
    with open(SECLLM_TF_CONFIG, encoding="utf-8") as f:
        cfg = yaml.safe_load(f)
    c = cfg["config"][0]
    c["model"] = model
    c["url"] = OLLAMA_OPENAI_URL
    c["use_huggingface"] = False
    c["temperature"] = 0
    temp = SECLLM_DIR / f"temp_audit_{model_dir_name(model)}.yaml"
    with open(temp, "w", encoding="utf-8") as f:
        yaml.dump(cfg, f, allow_unicode=True)
    return temp


def audit_file(model, tf_file, results_json, config_path):
    """Audita un solo .tf con SecLLM (las 8 reglas) y lo agrega al JSON."""
    cmd = [
        sys.executable, str(SECLLM_SCRIPT),
        "-f", str(tf_file),
        "-o", str(results_json),
        "-c", str(config_path),
        "-t", "1",   # secuencial: 1 sola GPU/CPU
        "-a",        # append: guarda incrementalmente (resumible)
        "-j",
    ]
    subprocess.run(cmd, cwd=str(SECLLM_DIR), timeout=AUDIT_FILE_TIMEOUT)


# ============================================================================
# ORQUESTADOR
# ============================================================================

def process_model(model, samples):
    out_dir = OUTPUT_BASE / model_dir_name(model)
    tf_dir = out_dir / "terraform"
    tf_dir.mkdir(parents=True, exist_ok=True)

    func_json = out_dir / "iac_eval_results.json"
    audit_json = out_dir / "secllm_results.json"

    if RESTART_OLLAMA_BETWEEN_MODELS:
        restart_ollama()

    # ---- Fases 1 + 2: generacion y evaluacion funcional ----
    func_results = []
    if func_json.exists():
        try:
            func_results = json.loads(func_json.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            func_results = []
    func_done = {r["file"] for r in func_results}

    log(f"--- {model}: Fase 1+2 (generacion + evaluacion funcional) ---")
    for idx, row in samples.iterrows():
        filename = f"question_{idx:04d}.tf"
        tf_file = tf_dir / filename

        # Generacion (omitir si ya existe con contenido).
        if not tf_file.exists() or tf_file.stat().st_size == 0:
            log(f"  [{idx + 1}] generando {filename} ...")
            code = extract_hcl(generate_terraform(row["Prompt"], model))
            if not code.strip():
                # Generacion fallida: no escribir archivo vacio ni evaluar.
                # Asi el proximo run lo reintenta (resumible).
                log(f"  [{idx + 1}] generacion VACIA, se reintentara luego.")
                tf_file.unlink(missing_ok=True)
                continue
            tf_file.write_text(code, encoding="utf-8")
        else:
            code = tf_file.read_text(encoding="utf-8", errors="ignore")

        # Evaluacion funcional (omitir si ya esta registrada).
        if filename in func_done:
            continue
        log(f"  [{idx + 1}] evaluando funcionalmente {filename} ...")
        cwd = os.getcwd()
        os.chdir(IAC_EVAL_DIR)
        try:
            res = functional_eval(code, row["Rego intent"], str(uuid.uuid4()))
        except Exception as e:
            res = {"terraform_plan_success": False,
                   "opa_evaluation_result": "No opa_result",
                   "terraform_plan_error": f"eval exception: {e}",
                   "opa_evaluation_error": "None"}
        finally:
            os.chdir(cwd)

        func_results.append({"file": filename, **res})
        func_json.write_text(json.dumps(func_results, indent=2), encoding="utf-8")

    # ---- Fase 3: auto-auditoria con SecLLM ----
    log(f"--- {model}: Fase 3 (auto-auditoria SecLLM, 8 reglas) ---")
    audit_done = load_done_paths(audit_json)
    config_path = write_audit_config(model)
    try:
        for idx in samples.index:
            filename = f"question_{idx:04d}.tf"
            tf_file = tf_dir / filename
            if not tf_file.exists() or tf_file.stat().st_size == 0:
                continue
            if filename in audit_done:
                log(f"  {filename}: ya auditado, se omite.")
                continue
            log(f"  auditando {filename} ...")
            try:
                audit_file(model, tf_file, audit_json, config_path)
            except subprocess.TimeoutExpired:
                log(f"  TIMEOUT auditando {filename}; se continua con el siguiente.")
            except Exception as e:
                log(f"  ERROR auditando {filename}: {e}")
    finally:
        config_path.unlink(missing_ok=True)

    log(f"=== {model}: COMPLETADO ===")


def main():
    OUTPUT_BASE.mkdir(parents=True, exist_ok=True)
    log("=" * 60)
    log("PIPELINE NOCTURNO IaC-Eval + SecLLM (auto-auditoria)")
    log(f"Modelos: {MODELS}")
    log(f"Preguntas por modelo: {NUM_SAMPLES}")
    log("=" * 60)

    df = pd.read_csv(DATASET)
    samples = df.head(NUM_SAMPLES)

    for model in MODELS:
        try:
            process_model(model, samples)
        except Exception as e:
            log(f"ERROR fatal procesando {model}: {e}")

    log("=" * 60)
    log("PIPELINE FINALIZADO. Genera el reporte con: python scripts/generate_report.py")
    log("=" * 60)


if __name__ == "__main__":
    main()
