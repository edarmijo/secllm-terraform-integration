#!/usr/bin/env python3
"""
split_remaining.py — Reparte el trabajo PENDIENTE del experimento v3 entre N personas
=====================================================================================

Qué hace
--------
Inventaría, celda por celda (modelo x condición) y escenario por escenario, qué
falta de verdad: generar, evaluar, reparar y auditar. Con eso reparte los 120
escenarios en N turnos equilibrados y escribe un archivo de índices por persona,
que se le pasa a `pipeline_v3.py --indices-file`.

Por qué se reparte POR ESCENARIO y no por modelo
------------------------------------------------
Si cada persona corre un modelo distinto, cualquier diferencia entre sus máquinas
(versión de terraform, de opa, build del modelo en Ollama) queda pegada a la
comparación entre modelos y ya no se puede separar de ella. Repartiendo
escenarios, los 4 modelos y las 2 condiciones pasan por las N máquinas, así que
ese efecto se distribuye por igual: deja de ser sesgo y pasa a ser ruido.

Además, las dos condiciones del mismo escenario caen siempre en la misma máquina,
que es lo que mantiene limpia la comparación pareada P0 vs P1.

Equilibrio en dos ejes
----------------------
  [E1] COSTE. Los escenarios no cuestan lo mismo: uno ya generado y auditado no
       cuesta nada, y uno virgen cuesta 8 generaciones + 8 auditorías. Repartir
       40 y 40 y 40 escenarios a ciegas puede dejar a alguien con el doble de
       trabajo. Se reparte por coste estimado, no por conteo.

  [E2] DIFICULTAD. El dataset está estratificado en 6 niveles y la dificultad
       influye en Fc. Si a una persona le tocan los escenarios difíciles y a otra
       los fáciles, un fallo de máquina en la primera se confunde con el efecto de
       la dificultad. El reparto se hace dentro de cada estrato.

Uso
---
  python split_remaining.py                       # inventario + reparto en 3
  python split_remaining.py --personas 3 --auditor-cost 280
  python split_remaining.py --solo-inventario
"""

import argparse
import json
from collections import defaultdict
from pathlib import Path

import pandas as pd

SCRIPT_DIR = Path(__file__).resolve().parent
INTEGRATION_DIR = SCRIPT_DIR.parent

DATASET = INTEGRATION_DIR / "iac_eval_data.csv"
OUTPUT_BASE = INTEGRATION_DIR / "outputs_v3"
SAMPLE_FILE = OUTPUT_BASE / "experiment_sample.json"
SHARD_DIR = OUTPUT_BASE / "shards"

MODELS = ["codegemma:7b", "codellama:7b", "granite-code:8b", "llama3.1:8b"]
CONDITIONS = ["P0", "P1"]

# --- Costes por unidad de trabajo, en segundos ------------------------------
# Medidos en esta máquina, no inventados:
#   COSTE_GEN     mediana de los tramos "generando ..." del log de v3
#   COSTE_EVAL    tramos "evaluación funcional ..." (plan que falla es rapidísimo)
#   COSTE_REPAIR  tramos "reparando (ronda k) ..." — incluye su propia evaluación
#   COSTE_AUDIT   mediana de pared del benchmark con un auditor 7B (34 s).
#                 Con devstral son ~280 s: pásalo con --auditor-cost 280.
COSTE_GEN = 20
COSTE_EVAL = 5
COSTE_REPAIR = 35
COSTE_AUDIT_7B = 34


def model_slug(model: str) -> str:
    return model.replace(":", "_").replace(".", "_")


def load_json(path: Path):
    if not path.exists():
        return []
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return []


# ============================================================================
# INVENTARIO
# ============================================================================

def inventariar(indices: list[int], repair_rounds: int) -> dict:
    """
    Estado real de cada (modelo, condición, escenario).

    Devuelve, por celda, los conjuntos de escenarios que necesitan cada fase, y
    de qué auditor provienen las auditorías ya hechas.
    """
    inv = {}
    for m in MODELS:
        for c in CONDITIONS:
            cell = OUTPUT_BASE / model_slug(m) / c
            tf_dir = cell / "terraform"

            gen_ok, evaluado, cerrado = set(), set(), set()
            for idx in indices:
                f = tf_dir / f"question_{idx:04d}.tf"
                if f.exists() and f.stat().st_size > 0:
                    gen_ok.add(idx)

            for r in load_json(cell / "iac_eval_results.json"):
                idx = r.get("scenario_index")
                if idx is None:
                    continue
                evaluado.add(idx)
                # Cerrado = pasó, o ya gastó las rondas de reparación pedidas.
                # Misma condición que usa run_generation_and_eval para saltarse
                # un escenario (pipeline_v3.py:751-753).
                if r.get("fc_at_k") == 1 or r.get("attempts_used", 1) >= repair_rounds + 1:
                    cerrado.add(idx)

            auditado = set()
            for row in load_json(cell / "secllm_results.json"):
                path = row.get("PATH", "")
                if path.startswith("question_") and path.endswith(".tf"):
                    base = path.split(".")[0]          # ignora los .aN de reparación
                    try:
                        auditado.add(int(base.split("_")[1]))
                    except (IndexError, ValueError):
                        pass

            marker = load_json(cell / "auditor.json")
            auditor = marker.get("auditor") if isinstance(marker, dict) else None

            inv[(m, c)] = {
                "generado": gen_ok & set(indices),
                "evaluado": evaluado & set(indices),
                "cerrado": cerrado & set(indices),
                "auditado": auditado & set(indices),
                "auditor": auditor,
            }
    return inv


def pendiente_por_escenario(inv: dict, indices: list[int],
                            reauditar_todo: bool) -> dict:
    """
    Para cada escenario, qué falta sumando las 8 celdas.

    `reauditar_todo` descarta las auditorías heredadas: es lo correcto si el
    auditor final no es EXACTAMENTE el mismo build que produjo las de v2, porque
    mezclar dos detectores en la misma tabla invalida la métrica de seguridad.
    """
    pend = {}
    for idx in indices:
        p = {"gen": 0, "eval": 0, "repair": 0, "audit": 0}
        for (m, c), st in inv.items():
            if idx not in st["generado"]:
                p["gen"] += 1
                p["eval"] += 1
                p["repair"] += 1          # lo más probable: 85 % falla el plan
                p["audit"] += 1
                continue
            if idx not in st["evaluado"]:
                p["eval"] += 1
                p["repair"] += 1
            elif idx not in st["cerrado"]:
                p["repair"] += 1
            if reauditar_todo or idx not in st["auditado"]:
                p["audit"] += 1
        pend[idx] = p
    return pend


def coste(p: dict, coste_audit: int) -> int:
    return (p["gen"] * COSTE_GEN + p["eval"] * COSTE_EVAL
            + p["repair"] * COSTE_REPAIR + p["audit"] * coste_audit)


# ============================================================================
# REPARTO
# ============================================================================

def repartir(indices: list[int], pend: dict, dificultad: dict,
             n_personas: int, coste_audit: int) -> list[list[int]]:
    """
    Reparto greedy estratificado por dificultad [E2] y equilibrado por coste [E1].

    Dentro de cada estrato, los escenarios se ordenan de más caro a más barato y
    cada uno va al turno que menos escenarios tenga DE ESE ESTRATO, desempatando
    por el coste acumulado. Ordenar de mayor a menor es lo que evita que los
    escenarios caros caigan todos al final y descuadren el reparto.
    """
    turnos: list[list[int]] = [[] for _ in range(n_personas)]
    carga = [0] * n_personas
    por_estrato = [defaultdict(int) for _ in range(n_personas)]

    estratos = defaultdict(list)
    for idx in indices:
        estratos[dificultad[idx]].append(idx)

    for dif in sorted(estratos):
        for idx in sorted(estratos[dif], key=lambda i: -coste(pend[i], coste_audit)):
            elegido = min(range(n_personas),
                          key=lambda t: (por_estrato[t][dif], carga[t]))
            turnos[elegido].append(idx)
            carga[elegido] += coste(pend[idx], coste_audit)
            por_estrato[elegido][dif] += 1

    return [sorted(t) for t in turnos]


# ============================================================================
# INFORME
# ============================================================================

def h(segundos: float) -> str:
    return f"{segundos / 3600:.1f} h"


def informe_inventario(inv: dict, indices: list[int]) -> None:
    n = len(indices)
    print("=" * 78)
    print("INVENTARIO — qué hay hecho de los 120 escenarios en cada celda")
    print("=" * 78)
    print(f"{'modelo':17s} {'cond':5s} {'generado':>9s} {'evaluado':>9s} "
          f"{'cerrado':>8s} {'auditado':>9s}  auditor")
    for m in MODELS:
        for c in CONDITIONS:
            st = inv[(m, c)]
            print(f"{model_slug(m):17s} {c:5s} {len(st['generado']):6d}/{n:<3d}"
                  f"{len(st['evaluado']):6d}/{n:<3d}{len(st['cerrado']):5d}/{n:<3d}"
                  f"{len(st['auditado']):6d}/{n:<3d}  {st['auditor'] or '—'}")
    print()


def informe_reparto(turnos: list[list[int]], pend: dict, dificultad: dict,
                    coste_audit: int, etiqueta: str) -> None:
    print("=" * 78)
    print(f"REPARTO EN {len(turnos)}  (coste de auditoría: {coste_audit} s/archivo — {etiqueta})")
    print("=" * 78)
    print(f"{'turno':6s} {'esc':>4s} {'gen':>5s} {'eval':>5s} {'rep':>5s} "
          f"{'audit':>6s} {'estimado':>9s}  dificultad")
    total = 0
    for i, t in enumerate(turnos):
        agg = {k: sum(pend[idx][k] for idx in t)
               for k in ("gen", "eval", "repair", "audit")}
        seg = sum(coste(pend[idx], coste_audit) for idx in t)
        total += seg
        dist = defaultdict(int)
        for idx in t:
            dist[dificultad[idx]] += 1
        dist_s = " ".join(f"{d}:{dist[d]}" for d in sorted(dist))
        print(f"{chr(65 + i):6s} {len(t):4d} {agg['gen']:5d} {agg['eval']:5d} "
              f"{agg['repair']:5d} {agg['audit']:6d} {h(seg):>9s}  {dist_s}")
    peor = max(sum(coste(pend[idx], coste_audit) for idx in t) for t in turnos)
    print(f"{'TOTAL':6s} {sum(len(t) for t in turnos):4d} "
          f"{'':5s}{'':5s}{'':5s}{'':6s} {h(total):>9s}")
    print(f"En paralelo, el experimento termina en ~{h(peor)} "
          f"(lo que tarde el turno más cargado).")
    print()


def parse_args():
    p = argparse.ArgumentParser(description="Reparte el trabajo pendiente de v3")
    p.add_argument("--personas", type=int, default=3)
    p.add_argument("--repair-rounds", type=int, default=1,
                   help="las mismas rondas con las que se vaya a correr el pipeline")
    p.add_argument("--auditor-cost", type=int, default=COSTE_AUDIT_7B,
                   help=f"segundos por archivo auditado (7B ~{COSTE_AUDIT_7B}, "
                        f"devstral ~280)")
    p.add_argument("--reusar-auditorias-v2", action="store_true",
                   help="contar como hechas las auditorías heredadas de v2. Solo "
                        "es válido si el auditor final es el MISMO build que las "
                        "produjo (qwen25-coder-audit), que ya no existe en Ollama")
    p.add_argument("--solo-inventario", action="store_true")
    return p.parse_args()


def main():
    args = parse_args()

    if not SAMPLE_FILE.exists():
        raise SystemExit(f"No existe {SAMPLE_FILE}: corre antes el pipeline una vez.")
    meta = json.loads(SAMPLE_FILE.read_text(encoding="utf-8"))
    indices = meta["indices"]

    df = pd.read_csv(DATASET)
    dificultad = {idx: int(df.loc[idx, "Difficulty"]) for idx in indices}

    inv = inventariar(indices, args.repair_rounds)
    informe_inventario(inv, indices)

    reauditar = not args.reusar_auditorias_v2
    pend = pendiente_por_escenario(inv, indices, reauditar)
    etiqueta = ("re-auditando todo" if reauditar
                else "reusando las auditorías de v2")

    faltantes = {k: sum(p[k] for p in pend.values())
                 for k in ("gen", "eval", "repair", "audit")}
    print(f"PENDIENTE TOTAL ({etiqueta}): {faltantes['gen']} generaciones, "
          f"{faltantes['eval']} evaluaciones, hasta {faltantes['repair']} "
          f"reparaciones, {faltantes['audit']} auditorías.")
    print()

    if args.solo_inventario:
        return

    turnos = repartir(indices, pend, dificultad, args.personas, args.auditor_cost)
    informe_reparto(turnos, pend, dificultad, args.auditor_cost, etiqueta)

    SHARD_DIR.mkdir(parents=True, exist_ok=True)
    for i, t in enumerate(turnos):
        nombre = chr(65 + i)
        destino = SHARD_DIR / f"shard_{nombre}.json"
        segundos = sum(coste(pend[idx], args.auditor_cost) for idx in t)
        destino.write_text(json.dumps({
            "turno": nombre,
            "n_escenarios": len(t),
            "dificultades": {str(d): sum(1 for idx in t if dificultad[idx] == d)
                             for d in sorted(set(dificultad.values()))},
            # El desglose viaja dentro del turno para que no haya que recalcularlo
            # a mano al redactar el reparto (y no se desincronice de los índices).
            "pendiente": {k: sum(pend[idx][k] for idx in t)
                          for k in ("gen", "eval", "repair", "audit")},
            "estimado_horas": round(segundos / 3600, 2),
            "coste_auditoria_s": args.auditor_cost,
            "supuesto_auditoria": etiqueta,
            "indices": t,
        }, indent=2), encoding="utf-8")
        print(f"  {destino}")

    print()
    print("Cada persona corre SOLO su turno:")
    print("  python pipeline_v3.py --indices-file outputs_v3/shards/shard_A.json")
    print(f"Y al terminar se juntan los outputs_v3 de las {len(turnos)} máquinas.")


if __name__ == "__main__":
    main()
