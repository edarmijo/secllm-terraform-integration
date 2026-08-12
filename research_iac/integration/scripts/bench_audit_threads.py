#!/usr/bin/env python3
"""
bench_audit_threads.py — ¿Paralelizar la auditoría (-t) acelera de verdad?
=========================================================================

Motivación
----------
`pipeline_v3.py:135` sube AUDIT_THREADS de 1 (lo que usaba v2, y lo que
GUIA_INSTALACION.md:356 declara "obligatorio" con modelos locales) a 8, apoyado
en una medición anotada en el comentario: 161 s/archivo con -t 1 frente a 115 s
con -t 8. Esa medición no dejó ningún artefacto en el repo, así que no es
auditable ni reproducible. Este script la reproduce como es debido.

Diseño de la medición
---------------------
  [D1] PAREADO POR ARCHIVO. El tiempo de auditar un .tf depende sobre todo de su
       tamaño, y los .tf del corpus van de 0.3 KB a 6.5 KB. Comparar medias de
       dos conjuntos distintos de archivos mide el corpus, no los hilos: aquí
       cada archivo se audita con TODAS las configuraciones.

  [D2] ORDEN ALTERNADO (ABBA). Las corridas largas derivan: la GPU se calienta,
       el modelo entra y sale de VRAM, el SO cachea. Si todas las corridas de
       -t 1 van primero, la deriva se confunde con el efecto. Las repeticiones
       pares recorren las configuraciones en orden inverso.

  [D3] CALENTAMIENTO. La primera llamada carga el modelo en memoria (decenas de
       segundos con un modelo que no cabe en VRAM). Sin descartarla, se le
       atribuye a la configuración que tocara ir primero.

  [D4] DOS RELOJES. El propio SecLLM cronometra el barrido de smells y lo emite
       como TIME en su JSON (secllm.py:109-140); el script mide además el
       tiempo de pared del subproceso, que incluye el arranque del intérprete y
       la carga de config. El primero mide la paralelización; el segundo, lo que
       de verdad cuesta la fase 3 del pipeline.

  [D5] CONTROL DE CONCURRENCIA REAL. `-t N` solo abre N hilos en el CLIENTE. Si
       el servidor Ollama corre con OLLAMA_NUM_PARALLEL=1, las N peticiones se
       encolan y el efecto es cero por construcción. El preflight lo mide
       empíricamente antes de gastar horas de GPU.

  [D6] EQUIVALENCIA DE DETECCIONES. El comentario de pipeline_v3 afirma que "las
       detecciones no cambian entre configuraciones". Se comprueba: si cambian,
       la comparación de tiempos es lo de menos, porque -t estaría alterando el
       resultado científico.

Nada de esto toca outputs_v2 ni outputs_v3: todo va a un directorio de trabajo
aparte.

Uso
---
  python bench_audit_threads.py --auditor qwen25-coder-audit
  python bench_audit_threads.py --auditor devstral-small-2:latest \
      --threads 1,8 --files 6 --reps 3
  python bench_audit_threads.py --preflight-only     # solo el test [D5]
"""

import argparse
import json
import os
import statistics
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from pathlib import Path

import requests

SCRIPT_DIR = Path(__file__).resolve().parent
INTEGRATION_DIR = SCRIPT_DIR.parent
BASE_DIR = INTEGRATION_DIR.parent

SECLLM_DIR = BASE_DIR / "SecLLM" / "SecLLM"
SECLLM_SCRIPT = SECLLM_DIR / "secllm" / "secllm.py"
SECLLM_TF_CONFIG = INTEGRATION_DIR / "config_terraform.yaml"

BENCH_DIR = INTEGRATION_DIR / "bench_audit_threads"
LOG_FILE = BENCH_DIR / "bench_log.txt"
RESULT_FILE = BENCH_DIR / "bench_results.json"

OLLAMA_OPENAI_URL = "http://localhost:11434/v1"
OLLAMA_NATIVE_URL = "http://localhost:11434/api/generate"

# Corpus por defecto: los .tf ya generados en v2 (no se modifican, solo se leen).
DEFAULT_CORPUS = INTEGRATION_DIR / "outputs_v2"

AUDIT_TIMEOUT = 3600


def log(msg: str) -> None:
    line = f"[{datetime.now():%H:%M:%S}] {msg}"
    print(line, flush=True)
    BENCH_DIR.mkdir(parents=True, exist_ok=True)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(line + "\n")


def model_slug(model: str) -> str:
    return model.replace(":", "_").replace(".", "_").replace("/", "_")


# ============================================================================
# PREFLIGHT — ¿el servidor atiende peticiones en paralelo? [D5]
# ============================================================================

def preflight_concurrency(model: str, n: int) -> dict:
    """
    Mide el paralelismo EFECTIVO del servidor, que es el techo de cualquier
    ganancia por -t.

    Lanza n peticiones cortas concurrentes y las mismas n en serie. Si el
    servidor las serializa (OLLAMA_NUM_PARALLEL=1), ambos tiempos coinciden y el
    speedup efectivo es 1.0: subir -t no puede ayudar, y este script puede
    pararse aquí sin gastar horas de GPU.

    Los prompts se hacen distintos entre sí a propósito: con el mismo prompt,
    la caché de prompt del servidor devolvería las repeticiones al instante y el
    test mediría la caché, no la concurrencia.
    """
    def one(i: int) -> float:
        t0 = time.perf_counter()
        requests.post(OLLAMA_NATIVE_URL, timeout=600, json={
            "model": model,
            "prompt": f"Count from {i} to {i + 12}, numbers only.",
            "stream": False,
            "options": {"temperature": 0, "num_predict": 48},
            "keep_alive": "10m",
        }).raise_for_status()
        return time.perf_counter() - t0

    log(f"Preflight: calentando '{model}' ...")
    one(0)

    log(f"Preflight: {n} peticiones EN SERIE ...")
    t0 = time.perf_counter()
    for i in range(n):
        one(100 + i)
    serie = time.perf_counter() - t0

    log(f"Preflight: {n} peticiones CONCURRENTES ...")
    t0 = time.perf_counter()
    with ThreadPoolExecutor(max_workers=n) as ex:
        list(ex.map(one, range(200, 200 + n)))
    concurrente = time.perf_counter() - t0

    speedup = serie / concurrente if concurrente else float("nan")
    log(f"Preflight: serie={serie:.1f}s  concurrente={concurrente:.1f}s  "
        f"speedup efectivo={speedup:.2f}x (techo teórico {n}x)")
    if speedup < 1.15:
        log("Preflight: el servidor NO está sirviendo en paralelo. Arráncalo con "
            f"OLLAMA_NUM_PARALLEL={n} (lo lee el SERVIDOR al arrancar, no el "
            "cliente) o -t no puede dar ninguna ganancia.")
    return {"n": n, "serie_s": serie, "concurrente_s": concurrente,
            "speedup_efectivo": speedup}


# ============================================================================
# CONFIGURACIÓN DE SECLLM
# ============================================================================

def write_audit_config(auditor_model: str) -> Path:
    """Config de SecLLM apuntando al auditor vía la API OpenAI de Ollama."""
    import yaml
    with open(SECLLM_TF_CONFIG, encoding="utf-8") as f:
        cfg = yaml.safe_load(f)
    c = cfg["config"][0]
    c["model"] = auditor_model
    c["url"] = OLLAMA_OPENAI_URL
    c["use_huggingface"] = False
    c["temperature"] = 0
    temp = SECLLM_DIR / f"temp_bench_{model_slug(auditor_model)}.yaml"
    with open(temp, "w", encoding="utf-8") as f:
        yaml.dump(cfg, f, allow_unicode=True)
    return temp


def pick_files(corpus: Path, k: int) -> list[Path]:
    """
    k archivos que cubran el rango de tamaños del corpus.

    El tiempo de auditoría crece con el tamaño del script, así que una muestra
    concentrada en archivos pequeños subestimaría cualquier efecto. Se ordena por
    tamaño y se toman k posiciones equiespaciadas: el más pequeño, el más grande
    y el rango intermedio.
    """
    todos = sorted((p for p in corpus.rglob("question_*.tf") if p.stat().st_size > 0),
                   key=lambda p: p.stat().st_size)
    if not todos:
        raise SystemExit(f"No se encontraron .tf en {corpus}")
    if k >= len(todos):
        return todos
    paso = (len(todos) - 1) / (k - 1) if k > 1 else 0
    return [todos[round(i * paso)] for i in range(k)]


# ============================================================================
# UNA MEDICIÓN
# ============================================================================

def run_once(tf_file: Path, threads: int, config_path: Path,
             out_json: Path) -> dict:
    """
    Audita un archivo con -t `threads` y devuelve ambos relojes [D4].

    Cada medición escribe su propio JSON (sin -a): así los tiempos y las
    detecciones de cada configuración quedan separados y comparables.
    """
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.unlink(missing_ok=True)

    t0 = time.perf_counter()
    proc = subprocess.run(
        [sys.executable, str(SECLLM_SCRIPT),
         "-f", str(tf_file), "-o", str(out_json), "-c", str(config_path),
         "-t", str(threads), "-j"],
        cwd=str(SECLLM_DIR), timeout=AUDIT_TIMEOUT,
        capture_output=True, text=True,
    )
    pared = time.perf_counter() - t0

    filas = []
    if out_json.exists():
        try:
            filas = json.loads(out_json.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            filas = []

    # TIME es idéntico en todas las filas del mismo archivo (secllm.py:140).
    secllm_time = filas[0]["TIME"] if filas else None
    # Firma de detecciones para [D6]. LINE llega a veces con espacios (" 36").
    detecciones = sorted({(str(r["LINE"]).strip(), r["SMELL"]) for r in filas})

    return {
        "file": tf_file.name,
        "size_bytes": tf_file.stat().st_size,
        "threads": threads,
        "wall_s": pared,
        "secllm_time_s": secllm_time,
        "tokens_in": filas[0]["TOKEN_IN"] if filas else None,
        "tokens_out": filas[0]["TOKEN_OUT"] if filas else None,
        "detecciones": detecciones,
        "n_filas": len(filas),
        "returncode": proc.returncode,
        "stderr_tail": (proc.stderr or "")[-400:],
    }


# ============================================================================
# INFORME
# ============================================================================

def resumir(mediciones: list[dict], configs: list[int], baseline: int) -> None:
    log("=" * 72)
    log("RESULTADOS")
    log("=" * 72)

    validas = [m for m in mediciones if m["secllm_time_s"] is not None]
    fallidas = len(mediciones) - len(validas)
    if fallidas:
        log(f"[AVISO] {fallidas} mediciones sin resultado (auditoría fallida); "
            f"quedan fuera del resumen.")

    # --- Tiempos por configuración ---
    log(f"{'hilos':>5} {'n':>4} {'mediana TIME':>13} {'media TIME':>11} "
        f"{'mediana pared':>14}")
    for t in configs:
        sub = [m for m in validas if m["threads"] == t]
        if not sub:
            continue
        log(f"{t:5d} {len(sub):4d} "
            f"{statistics.median(m['secllm_time_s'] for m in sub):12.1f}s "
            f"{statistics.mean(m['secllm_time_s'] for m in sub):10.1f}s "
            f"{statistics.median(m['wall_s'] for m in sub):13.1f}s")

    # --- Speedup pareado por archivo [D1] ---
    # Se comparan las medianas por archivo (no las globales): así un archivo
    # grande no arrastra el resultado y cada par comparte el mismo contenido.
    por_archivo: dict[str, dict[int, list[float]]] = {}
    for m in validas:
        por_archivo.setdefault(m["file"], {}).setdefault(m["threads"], []) \
            .append(m["secllm_time_s"])

    for t in configs:
        if t == baseline:
            continue
        ratios = []
        for archivo, porhilo in por_archivo.items():
            if baseline in porhilo and t in porhilo:
                ratios.append(statistics.median(porhilo[baseline])
                              / statistics.median(porhilo[t]))
        if not ratios:
            continue
        log("")
        log(f"Speedup pareado -t {baseline} -> -t {t}  (n={len(ratios)} archivos)")
        log(f"  mediana {statistics.median(ratios):.2f}x · "
            f"min {min(ratios):.2f}x · max {max(ratios):.2f}x")
        mejores = sum(1 for r in ratios if r > 1)
        log(f"  archivos más rápidos con -t {t}: {mejores}/{len(ratios)}")
        # Test de signos: sin supuestos de normalidad y legible sin scipy.
        # Con todos a favor y n>=6, p < 0.05 a dos colas.
        if mejores == len(ratios) and len(ratios) >= 6:
            log(f"  todos a favor de -t {t} (test de signos: p<0.05)")
        elif mejores == 0 and len(ratios) >= 6:
            log(f"  todos a favor de -t {baseline} (test de signos: p<0.05)")
        else:
            log("  resultado mixto: no hay evidencia de una diferencia "
                "consistente entre configuraciones.")

    # --- Equivalencia de detecciones [D6] ---
    log("")
    discrepantes = []
    for archivo, _ in por_archivo.items():
        firmas = {}
        for m in validas:
            if m["file"] != archivo:
                continue
            firmas.setdefault(m["threads"], set()).add(
                tuple(tuple(d) for d in m["detecciones"]))
        # Inestable dentro de una misma configuración -> el modelo no es
        # determinista y la comparación entre configuraciones no significa nada.
        inestable = any(len(v) > 1 for v in firmas.values())
        distintas = {next(iter(v)) for v in firmas.values() if len(v) == 1}
        if inestable:
            discrepantes.append((archivo, "no determinista dentro de la misma -t"))
        elif len(distintas) > 1:
            discrepantes.append((archivo, "difiere entre configuraciones de -t"))

    if not discrepantes:
        log("Detecciones: idénticas en todas las configuraciones y repeticiones.")
    else:
        log(f"Detecciones: {len(discrepantes)} archivo(s) con discrepancias — "
            f"'las detecciones no cambian' NO se sostiene:")
        for archivo, motivo in discrepantes:
            log(f"  {archivo}: {motivo}")

    log("=" * 72)


# ============================================================================
# MAIN
# ============================================================================

def parse_args():
    p = argparse.ArgumentParser(
        description="Mide si -t (hilos de SecLLM) acelera la auditoría")
    p.add_argument("--auditor", default="qwen25-coder-audit",
                   help="modelo auditor en Ollama (el que se vaya a usar de "
                        "verdad; el resultado NO se transfiere entre modelos)")
    p.add_argument("--threads", default="1,8",
                   help="configuraciones de -t a comparar, separadas por comas")
    p.add_argument("--files", type=int, default=6,
                   help="archivos .tf del corpus, equiespaciados por tamaño")
    p.add_argument("--reps", type=int, default=3,
                   help="repeticiones por (archivo, configuración)")
    p.add_argument("--corpus", type=Path, default=DEFAULT_CORPUS,
                   help="directorio con los question_*.tf a auditar")
    p.add_argument("--preflight-only", action="store_true",
                   help="solo medir el paralelismo efectivo del servidor")
    p.add_argument("--skip-preflight", action="store_true")
    return p.parse_args()


def main():
    args = parse_args()
    configs = [int(t) for t in args.threads.split(",") if t.strip()]
    baseline = min(configs)
    maxt = max(configs)

    BENCH_DIR.mkdir(parents=True, exist_ok=True)
    log("=" * 72)
    log("BENCHMARK — ¿acelera paralelizar la auditoría?")
    log(f"  Auditor      : {args.auditor}")
    log(f"  Configs -t   : {configs}")
    log(f"  Archivos     : {args.files} · repeticiones: {args.reps}")
    log("=" * 72)

    pre = None
    if not args.skip_preflight:
        pre = preflight_concurrency(args.auditor, maxt)
        if args.preflight_only:
            RESULT_FILE.write_text(json.dumps({"preflight": pre}, indent=2),
                                   encoding="utf-8")
            return
        if pre["speedup_efectivo"] < 1.15:
            log("Se continúa igualmente para dejar la medición registrada, pero "
                "el resultado esperado es 'sin ganancia'.")

    archivos = pick_files(args.corpus, args.files)
    log("Corpus:")
    for f in archivos:
        log(f"  {f.name:24s} {f.stat().st_size:6d} B  ({f.parent.parent.name})")

    config_path = write_audit_config(args.auditor)
    mediciones: list[dict] = []
    try:
        # Calentamiento [D3]: el coste de cargar el modelo no es de ninguna
        # configuración en particular.
        log("Calentamiento (se descarta) ...")
        run_once(archivos[0], baseline, config_path,
                 BENCH_DIR / "tmp" / "warmup.json")

        total = len(archivos) * args.reps * len(configs)
        hecho = 0
        for rep in range(args.reps):
            # ABBA [D2]: en las repeticiones impares se invierte el orden para
            # que la deriva térmica no se sume siempre a la misma configuración.
            orden = configs if rep % 2 == 0 else list(reversed(configs))
            for tf_file in archivos:
                for t in orden:
                    hecho += 1
                    log(f"[{hecho}/{total}] rep{rep} · {tf_file.name} · -t {t} ...")
                    m = run_once(
                        tf_file, t, config_path,
                        BENCH_DIR / "tmp" / f"r{rep}_t{t}_{tf_file.stem}.json")
                    m["rep"] = rep
                    m["corpus_cell"] = tf_file.parent.parent.name
                    mediciones.append(m)
                    estado = (f"{m['secllm_time_s']:.1f}s"
                              if m["secllm_time_s"] is not None else "FALLÓ")
                    log(f"    TIME={estado}  pared={m['wall_s']:.1f}s  "
                        f"filas={m['n_filas']}")
                    RESULT_FILE.write_text(json.dumps(
                        {"preflight": pre, "auditor": args.auditor,
                         "mediciones": mediciones}, indent=2), encoding="utf-8")
    finally:
        config_path.unlink(missing_ok=True)

    resumir(mediciones, configs, baseline)
    log(f"Mediciones crudas en {RESULT_FILE}")


if __name__ == "__main__":
    main()
