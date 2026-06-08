#!/usr/bin/env python3
"""
generate_report.py - Reporte comparativo del pipeline (funcional + seguridad)
=============================================================================

Lee las salidas de cada modelo en outputs/<modelo>/ y produce una tabla
Markdown comparativa en outputs/REPORTE_COMPARATIVO.md con:

  1. Evaluacion funcional (IaC-Eval): cuantos .tf compilan (terraform plan) y
     cuantos pasan la politica de seguridad Rego (OPA).
  2. Auto-auditoria (SecLLM): cuantas vulnerabilidades detecto el propio modelo
     en el codigo que el mismo genero, desglosadas por tipo de smell.
"""

import json
from pathlib import Path

import pandas as pd

INTEGRATION_DIR = Path(__file__).resolve().parent.parent
OUTPUT_BASE = INTEGRATION_DIR / "outputs"


def _load_json(path):
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return None


def _pct(num, den):
    return f"{num}/{den} ({num / den * 100:.0f}%)" if den else "0/0"


def collect():
    func_rows, sec_rows = [], []

    for model_dir in sorted(p for p in OUTPUT_BASE.iterdir() if p.is_dir()):
        model = model_dir.name

        # --- Funcional ---
        func = _load_json(model_dir / "iac_eval_results.json")
        if func:
            total = len(func)
            plan_ok = sum(1 for r in func if r.get("terraform_plan_success"))
            opa_ok = sum(1 for r in func if r.get("opa_evaluation_result") == "Success")
            func_rows.append({
                "Modelo": model,
                "Archivos": total,
                "Compila (plan)": _pct(plan_ok, total),
                "Pasa politica (OPA)": _pct(opa_ok, total),
            })

        # --- Seguridad (auto-auditoria) ---
        sec = _load_json(model_dir / "secllm_results.json")
        if sec:
            files = {r.get("PATH") for r in sec}
            by_type = {}
            for r in sec:
                smell = r.get("SMELL", "none")
                if smell != "none":
                    by_type[smell] = by_type.get(smell, 0) + 1
            total_smells = sum(by_type.values())
            detail = ", ".join(f"{k}: {v}" for k, v in sorted(by_type.items()))
            sec_rows.append({
                "Modelo": model,
                "Archivos auditados": len(files),
                "Vulnerabilidades": total_smells,
                "Detalle": detail or "0 (el modelo reporto todo limpio)",
            })

    return func_rows, sec_rows


def main():
    func_rows, sec_rows = collect()

    lines = [
        "# Reporte Comparativo - Pipeline IaC-Eval + SecLLM\n",
        "_Generado automaticamente. Cada modelo genera su propio Terraform, se "
        "evalua funcionalmente (terraform plan + OPA) y se AUTO-audita con SecLLM._\n",
        "\n## 1. Evaluacion funcional (IaC-Eval)\n",
        pd.DataFrame(func_rows).to_markdown(index=False) if func_rows
        else "_Sin datos funcionales todavia._",
        "\n\n## 2. Auto-auditoria de seguridad (SecLLM)\n",
        "_¿Encuentra cada modelo vulnerabilidades en el codigo que el mismo genero?_\n",
        pd.DataFrame(sec_rows).to_markdown(index=False) if sec_rows
        else "_Sin datos de seguridad todavia._",
        "\n",
    ]

    report = OUTPUT_BASE / "REPORTE_COMPARATIVO.md"
    report.write_text("\n".join(lines), encoding="utf-8")
    print(f"Reporte generado en: {report}")


if __name__ == "__main__":
    main()
