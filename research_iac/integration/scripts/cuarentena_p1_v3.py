#!/usr/bin/env python3
"""
cuarentena_p1_v3.py — Aparta los scripts P1 generados con el prompt equivocado
==============================================================================

Contexto (issue #9)
-------------------
`pipeline_v3.py` corrió un tiempo con un `SYSTEM_PROMPT_P1` que difería en seis
caracteres del que generó los datos de `outputs_v2`. Como el diseño por oleadas
reutiliza los escenarios de v2 en la misma tabla que los nuevos, esos scripts no
son agregables: hay que rehacerlos con el prompt correcto.

Afecta SOLO a P1 y SOLO a lo que generó v3:

  * P0 es idéntico byte a byte entre v2 y v3 -> intacto.
  * Los registros P1 con `source: "v2"` los generó pipeline_v2 con el prompt
    bueno -> intactos.
  * Los registros P1 con `source: "v3"` -> a cuarentena.

Por qué cuarentena y no borrado
-------------------------------
Esto es cirugía sobre tres JSON compartidos con cientos de registros que tienen
que sobrevivir intactos. Si el filtro por `source` falla, un borrado no tiene
vuelta atrás. Aquí:

  [S1] Los .tf se MUEVEN a quarantine_v3_p1/, no se borran. Revertir es un mv.
  [S2] Los tres JSON se copian ANTES de tocarlos.
  [S3] Se cuenta antes y después, y si los números no cuadran EXACTAMENTE el
       script aborta sin escribir nada.
  [S4] Se escribe un manifiesto con todo lo movido, para poder deshacerlo.
  [S5] Sin --aplicar no toca nada: solo informa.

Además comprueba que el prompt ya esté revertido: si no, apartar y regenerar
volvería a producir los mismos scripts malos.

Uso
---
  python cuarentena_p1_v3.py              # simulacro, no toca nada
  python cuarentena_p1_v3.py --aplicar    # ejecuta
  python cuarentena_p1_v3.py --deshacer   # devuelve todo desde la cuarentena
"""

import argparse
import json
import shutil
import sys
from collections import defaultdict
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

INTEGRATION = SCRIPT_DIR.parent
OUTPUT_BASE = INTEGRATION / "outputs_v3"
QUARANTINE = INTEGRATION / "quarantine_v3_p1"
MANIFIESTO = QUARANTINE / "manifiesto.json"

MODELOS = ["codegemma_7b", "codellama_7b", "granite-code_8b", "llama3_1_8b"]
JSONS = ("iac_eval_results.json", "iac_eval_attempts.json", "secllm_results.json")


def cargar(path: Path) -> list:
    if not path.exists():
        return []
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return []


def escribir(path: Path, datos) -> None:
    path.write_text(json.dumps(datos, indent=2), encoding="utf-8")


def comprobar_prompt_revertido() -> None:
    """
    Sin el prompt revertido, apartar y regenerar produce los mismos scripts
    malos: se aborta antes de mover nada.
    """
    import hashlib
    import importlib.util

    spec = importlib.util.spec_from_file_location(
        "pipeline_v3", SCRIPT_DIR / "pipeline_v3.py")
    mod = importlib.util.module_from_spec(spec)
    sys.modules["pipeline_v3"] = mod
    spec.loader.exec_module(mod)

    real = hashlib.sha256(mod.SYSTEM_PROMPT_P1.encode("utf-8")).hexdigest()
    esperado = mod.PROMPT_SHA256["P1"]
    if real != esperado:
        raise SystemExit(
            "[ABORTADA] pipeline_v3.py todavía NO tiene el prompt P1 revertido.\n"
            f"  esperado: {esperado}\n  actual:   {real}\n"
            "Revierte el prompt antes de apartar nada: si no, lo que se "
            "regenere saldrá igual de mal.")
    print("Prompt P1 verificado: coincide con el que generó los datos de v2.")


def inventario() -> tuple[dict, dict]:
    """Devuelve (conteos por celda, archivos a apartar por celda)."""
    conteos, afectados = {}, {}
    for m in MODELOS:
        for c in ("P0", "P1"):
            celda = OUTPUT_BASE / m / c
            recs = cargar(celda / "iac_eval_results.json")
            por_fuente = defaultdict(int)
            for r in recs:
                por_fuente[r.get("source", "?")] += 1
            conteos[(m, c)] = dict(por_fuente, total=len(recs))

            if c != "P1":
                continue
            indices = [r["scenario_index"] for r in recs
                       if r.get("source") == "v3" and "scenario_index" in r]
            archivos = []
            tf_dir = celda / "terraform"
            for idx in indices:
                archivos.append(tf_dir / f"question_{idx:04d}.tf")
                archivos += sorted(tf_dir.glob(f"question_{idx:04d}.a*.tf"))
            afectados[(m, c)] = {
                "indices": sorted(indices),
                "archivos": [f for f in archivos if f.exists()],
            }
    return conteos, afectados


def informe(conteos: dict, afectados: dict) -> tuple[int, int, int]:
    print()
    print(f"{'celda':22s} {'total':>6s} {'de v2':>6s} {'de v3':>6s} {'a apartar':>10s}")
    p0_total = p1_v2 = p1_v3 = 0
    for m in MODELOS:
        for c in ("P0", "P1"):
            k = (m, c)
            cn = conteos[k]
            n_apartar = len(afectados.get(k, {}).get("indices", []))
            print(f"{m + ' ' + c:22s} {cn['total']:6d} {cn.get('v2', 0):6d} "
                  f"{cn.get('v3', 0):6d} {n_apartar:10d}")
            if c == "P0":
                p0_total += cn["total"]
            else:
                p1_v2 += cn.get("v2", 0)
                p1_v3 += cn.get("v3", 0)
    print()
    print(f"P0 (no se toca):            {p0_total} registros")
    print(f"P1 heredados de v2 (quedan): {p1_v2} registros")
    print(f"P1 generados por v3 (fuera): {p1_v3} registros")
    n_arch = sum(len(v["archivos"]) for v in afectados.values())
    print(f"Archivos .tf/.aN.tf a mover: {n_arch}")
    return p0_total, p1_v2, p1_v3


def aplicar(conteos: dict, afectados: dict) -> None:
    p0_antes, p1_v2_antes, p1_v3_antes = informe(conteos, afectados)

    QUARANTINE.mkdir(parents=True, exist_ok=True)
    manifiesto = {"celdas": {}, "backups": {}}

    # [S2] copia de los tres JSON antes de tocarlos.
    for m in MODELOS:
        for c in ("P0", "P1"):
            for nombre in JSONS:
                src = OUTPUT_BASE / m / c / nombre
                if not src.exists():
                    continue
                dst = QUARANTINE / "backup" / m / c / nombre
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)
                manifiesto["backups"][f"{m}/{c}/{nombre}"] = str(dst)
    print(f"\nCopia de seguridad de los JSON en {QUARANTINE / 'backup'}")

    for (m, c), info in afectados.items():
        if not info["indices"]:
            continue
        celda = OUTPUT_BASE / m / c
        fuera_idx = set(info["indices"])
        fuera_nombres = {f.name for f in info["archivos"]}

        # [S1] mover los .tf
        destino = QUARANTINE / m / c / "terraform"
        destino.mkdir(parents=True, exist_ok=True)
        movidos = []
        for f in info["archivos"]:
            shutil.move(str(f), str(destino / f.name))
            movidos.append(f.name)

        # Registros funcionales: fuera los de v3.
        res_path = celda / "iac_eval_results.json"
        res = [r for r in cargar(res_path)
               if not (r.get("source") == "v3"
                       and r.get("scenario_index") in fuera_idx)]
        escribir(res_path, res)

        # Intentos: se identifican por el nombre de archivo.
        att_path = celda / "iac_eval_attempts.json"
        att = [r for r in cargar(att_path) if r.get("file") not in fuera_nombres]
        escribir(att_path, att)

        # Auditoría: fuera las filas de los archivos apartados.
        aud_path = celda / "secllm_results.json"
        aud = [r for r in cargar(aud_path) if r.get("PATH") not in fuera_nombres]
        escribir(aud_path, aud)

        manifiesto["celdas"][f"{m}/{c}"] = {
            "indices": sorted(fuera_idx), "archivos": sorted(movidos)}
        print(f"  {m} [{c}]: {len(movidos)} archivos movidos, "
              f"{len(fuera_idx)} registros retirados")

    escribir(MANIFIESTO, manifiesto)

    # [S3] verificación posterior: los números tienen que salir exactos.
    conteos2, afectados2 = inventario()
    p0_desp = sum(conteos2[(m, "P0")]["total"] for m in MODELOS)
    p1_desp = sum(conteos2[(m, "P1")]["total"] for m in MODELOS)
    p1_v3_desp = sum(conteos2[(m, "P1")].get("v3", 0) for m in MODELOS)

    print()
    print("VERIFICACIÓN")
    print(f"  P0 antes={p0_antes}  después={p0_desp}  "
          f"{'OK' if p0_desp == p0_antes else 'FALLO'}")
    print(f"  P1 quedan={p1_desp}  esperado={p1_v2_antes}  "
          f"{'OK' if p1_desp == p1_v2_antes else 'FALLO'}")
    print(f"  P1 con source=v3 restantes={p1_v3_desp}  esperado=0  "
          f"{'OK' if p1_v3_desp == 0 else 'FALLO'}")

    if p0_desp != p0_antes or p1_desp != p1_v2_antes or p1_v3_desp:
        raise SystemExit(
            "\n[FALLO] Los conteos no cuadran. NO relances el pipeline.\n"
            f"Restaura con: python {Path(__file__).name} --deshacer")
    print("\nTodo cuadra. Ya se puede relanzar el pipeline.")


def deshacer() -> None:
    if not MANIFIESTO.exists():
        raise SystemExit(f"No hay manifiesto en {MANIFIESTO}: nada que deshacer.")
    manifiesto = json.loads(MANIFIESTO.read_text(encoding="utf-8"))

    for rel, backup in manifiesto["backups"].items():
        shutil.copy2(backup, OUTPUT_BASE / rel)
    print(f"{len(manifiesto['backups'])} JSON restaurados desde la copia.")

    devueltos = 0
    for celda, info in manifiesto["celdas"].items():
        origen = QUARANTINE / celda / "terraform"
        destino = OUTPUT_BASE / celda / "terraform"
        destino.mkdir(parents=True, exist_ok=True)
        for nombre in info["archivos"]:
            f = origen / nombre
            if f.exists():
                shutil.move(str(f), str(destino / nombre))
                devueltos += 1
    print(f"{devueltos} archivos devueltos a outputs_v3.")
    print("Revisa y borra la cuarentena a mano cuando estés seguro.")


def main():
    p = argparse.ArgumentParser(description="Cuarentena de los P1 de v3 (issue #9)")
    p.add_argument("--aplicar", action="store_true", help="ejecuta los cambios")
    p.add_argument("--deshacer", action="store_true",
                   help="devuelve todo desde la cuarentena")
    args = p.parse_args()

    if args.deshacer:
        deshacer()
        return

    comprobar_prompt_revertido()
    conteos, afectados = inventario()

    if not args.aplicar:
        informe(conteos, afectados)
        print("\nSIMULACRO: no se ha tocado nada. Repite con --aplicar.")
        return

    aplicar(conteos, afectados)


if __name__ == "__main__":
    main()
