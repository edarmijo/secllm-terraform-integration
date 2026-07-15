#!/usr/bin/env python3
"""
generate_report_v2.py  —  Análisis estadístico corregido (pipeline_v2)
=======================================================================

Correcciones respecto a generate_report.py (v1):
  [A1]  RQ1 usa Sc (smell count, antes "density") como variable continua.
  [A2]  RQ2 usa Wilcoxon signed-rank PAREADO (P0 vs P1, mismos escenarios),
        en lugar de Mann-Whitney (no pareado entre modelos).
  [A3]  Reporta effect sizes: ρ de Spearman (=effect size para RQ1),
        rank-biserial r para Wilcoxon (RQ2), η² para Kruskal-Wallis.
  [A4]  Holm-Bonferroni para hipótesis CONFIRMATORIAS (RQ1, RQ2).
        Benjamini-Hochberg FDR para comparaciones EXPLORATORIAS (modelos).
  [A5]  Variable renombrada: Sd → Sc (Smell Count).
  [A6]  RQ3 filtra únicamente a scripts con Fc=1 (funcionalmente correctos).
  [M3]  Sp definida como binaria (0/1) por script.

Salidas:
  outputs_v2/
    stats_rq1.json      <- correlación Fc vs Sc
    stats_rq2.json      <- efecto del prompting P0 vs P1
    stats_models.json   <- comparación exploratoria entre modelos
    stats_rq3.json      <- distribución de smells en Fc=1
    REPORT_v2.md        <- resumen Markdown con todas las tablas
"""

import json
import math
import warnings
from collections import defaultdict
from pathlib import Path

import pandas as pd
from scipy import stats
from scipy.stats import (spearmanr, kendalltau, wilcoxon,
                         kruskal, mannwhitneyu, fisher_exact)

warnings.filterwarnings("ignore")

# ============================================================================
# RUTAS
# ============================================================================

SCRIPT_DIR   = Path(__file__).resolve().parent
INTEGRATION  = SCRIPT_DIR.parent
OUTPUT_BASE  = INTEGRATION / "outputs_v2"
REPORT_FILE  = OUTPUT_BASE / "REPORT_v2.md"

# ============================================================================
# CARGA DE DATOS
# ============================================================================

def load_model_condition(model_slug: str, condition: str) -> dict:
    """
    Carga iac_eval_results.json y secllm_results.json para un modelo/condición.
    Devuelve dict {filename -> {Fc, Sc, Sp, smells: [str]}}.
    """
    cond_dir = OUTPUT_BASE / model_slug / condition
    func_path  = cond_dir / "iac_eval_results.json"
    audit_path = cond_dir / "secllm_results.json"

    if not func_path.exists():
        return {}

    func_data = json.loads(func_path.read_text(encoding="utf-8"))

    # Auditoría: agrupar detecciones por archivo.
    smells_by_file: dict[str, list[str]] = defaultdict(list)
    if audit_path.exists():
        for rec in json.loads(audit_path.read_text(encoding="utf-8")):
            smell = rec.get("SMELL", "none")
            if smell != "none":
                smells_by_file[rec["PATH"]].append(smell)

    records = {}
    for r in func_data:
        fname = r["file"]
        fc = 1 if r.get("opa_evaluation_result") == "Success" else 0
        smells = smells_by_file.get(fname, [])
        sc = len(smells)           # Smell Count (variable continua discreta)
        sp = 1 if sc == 0 else 0   # Smell Prevalence: 1 = sin smells, 0 = con smells
        records[fname] = {
            "Fc": fc,
            "Sc": sc,
            "Sp": sp,
            "smells": smells,
            "scenario_index": r.get("scenario_index"),
        }
    return records


def discover_models() -> list[str]:
    """Devuelve los slugs de modelos con datos disponibles en outputs_v2/."""
    return sorted(
        d.name for d in OUTPUT_BASE.iterdir()
        if d.is_dir() and not d.name.startswith(".")
        and (d / "P0" / "iac_eval_results.json").exists()
    )


# ============================================================================
# CORRECCIÓN MÚLTIPLE
# ============================================================================

def holm_bonferroni(p_values: list[float]) -> list[float]:
    """
    Corrección Holm-Bonferroni para hipótesis confirmatorias (FWER).
    Devuelve p-values ajustados (p_adj) en el mismo orden que la entrada.
    """
    n = len(p_values)
    indexed = sorted(enumerate(p_values), key=lambda x: x[1])
    adjusted = [None] * n
    running_max = 0.0
    for rank, (orig_idx, p) in enumerate(indexed):
        adjusted_p = min(1.0, p * (n - rank))
        running_max = max(running_max, adjusted_p)
        adjusted[orig_idx] = running_max
    return adjusted


def benjamini_hochberg(p_values: list[float]) -> list[float]:
    """
    Corrección Benjamini-Hochberg para comparaciones exploratorias (FDR).
    Devuelve p-values ajustados en el mismo orden que la entrada.
    """
    n = len(p_values)
    indexed = sorted(enumerate(p_values), key=lambda x: x[1], reverse=True)
    adjusted = [None] * n
    running_min = 1.0
    for rank, (orig_idx, p) in enumerate(indexed):
        adjusted_p = p * n / (n - rank)
        running_min = min(running_min, adjusted_p)
        adjusted[orig_idx] = running_min
    return adjusted


def rank_biserial_r(u_stat: float, n1: int, n2: int) -> float:
    """
    Effect size para Mann-Whitney U: rank-biserial correlation.
    r = 1 - 2U / (n1 * n2)
    Interpretación: |r| ≈ 0.1 small, 0.3 medium, 0.5 large (Cohen).
    """
    return 1.0 - (2.0 * u_stat) / (n1 * n2) if n1 * n2 > 0 else 0.0


def wilcoxon_r(w_stat: float, n: int) -> float:
    """
    Effect size para Wilcoxon signed-rank: r = W / (n*(n+1)/2).
    Equivalente a rank-biserial para el test pareado.
    """
    denom = n * (n + 1) / 2.0
    return w_stat / denom if denom > 0 else 0.0


def eta_squared_kruskal(h_stat: float, k: int, n: int) -> float:
    """
    η² (eta-squared) para Kruskal-Wallis.
    η² = (H - k + 1) / (n - k)
    Interpretación: 0.01 small, 0.06 medium, 0.14 large.
    """
    return (h_stat - k + 1) / (n - k) if n > k else 0.0


# ============================================================================
# RQ1 — CORRELACIÓN Fc vs Sc  [A1, A3]
# ============================================================================

def analyze_rq1(models: list[str]) -> dict:
    """
    RQ1: ¿En qué medida Fc (corrección funcional) y Sc (smell count)
    están correlacionados en el código IaC generado (condición P0)?

    Usa Spearman ρ y Kendall τ sobre todos los scripts de la condición P0.
    Para cada modelo individualmente y sobre la muestra combinada.
    Corrección: Holm-Bonferroni (hipótesis confirmatorias).
    """
    results = {}
    all_fc, all_sc = [], []
    raw_tests = []

    for slug in models:
        data = load_model_condition(slug, "P0")
        if not data:
            continue
        fc_vals = [v["Fc"] for v in data.values()]
        sc_vals = [v["Sc"] for v in data.values()]
        n = len(fc_vals)
        if n < 4:
            continue

        rho, p_rho = spearmanr(fc_vals, sc_vals)
        tau, p_tau = kendalltau(fc_vals, sc_vals)

        results[slug] = {
            "n": n,
            "spearman_rho": round(rho, 4),
            "spearman_p": round(p_rho, 4),
            "kendall_tau": round(tau, 4),
            "kendall_p": round(p_tau, 4),
        }
        all_fc.extend(fc_vals)
        all_sc.extend(sc_vals)
        raw_tests.append(("spearman", slug, p_rho))
        raw_tests.append(("kendall", slug, p_tau))

    # Muestra combinada (todos los modelos en P0).
    if len(all_fc) >= 4:
        rho, p_rho = spearmanr(all_fc, all_sc)
        tau, p_tau = kendalltau(all_fc, all_sc)
        results["_pooled"] = {
            "n": len(all_fc),
            "spearman_rho": round(rho, 4),
            "spearman_p": round(p_rho, 4),
            "kendall_tau": round(tau, 4),
            "kendall_p": round(p_tau, 4),
        }
        raw_tests.append(("spearman", "_pooled", p_rho))
        raw_tests.append(("kendall", "_pooled", p_tau))

    # Corrección Holm-Bonferroni (confirmatorias).
    p_list = [t[2] for t in raw_tests]
    adj_p = holm_bonferroni(p_list)
    for i, (test_type, slug, _) in enumerate(raw_tests):
        key = f"{test_type}_p_adj_holm"
        if slug in results:
            results[slug][key] = round(adj_p[i], 4)

    return results


# ============================================================================
# RQ2 — EFECTO DEL PROMPTING P0 vs P1  [A2, A3, A4]
# ============================================================================

def analyze_rq2(models: list[str]) -> dict:
    """
    RQ2: ¿La condición P1 (security-oriented) mejora Sc y Sp sin degradar Fc?

    Test: Wilcoxon signed-rank pareado (mismos escenarios, P0 vs P1).
    Effect size: rank-biserial r.
    Corrección: Holm-Bonferroni (hipótesis confirmatorias: 2 variables × N modelos).
    """
    results = {}
    raw_tests = []  # (metric, slug, p_val, w_stat, n_pairs)

    for slug in models:
        p0 = load_model_condition(slug, "P0")
        p1 = load_model_condition(slug, "P1")
        if not p0 or not p1:
            continue

        # Solo escenarios evaluados en AMBAS condiciones.
        common = sorted(set(p0.keys()) & set(p1.keys()))
        n = len(common)
        if n < 6:
            results[slug] = {"n_paired": n, "note": "muestra insuficiente para Wilcoxon"}
            continue

        sc_p0 = [p0[f]["Sc"] for f in common]
        sc_p1 = [p1[f]["Sc"] for f in common]
        fc_p0 = [p0[f]["Fc"] for f in common]
        fc_p1 = [p1[f]["Fc"] for f in common]

        # Diferencias.
        diff_sc = [a - b for a, b in zip(sc_p0, sc_p1)]   # P0-P1 > 0 → P1 mejora
        diff_fc = [b - a for a, b in zip(fc_p0, fc_p1)]   # P1-P0 > 0 → P1 mejora

        def safe_wilcoxon(diffs, label):
            nonzero = [d for d in diffs if d != 0]
            if len(nonzero) < 6:
                return None, None, None
            try:
                w, p = wilcoxon(nonzero, alternative="two-sided")
                return w, p, len(nonzero)
            except Exception:
                return None, None, None

        w_sc, p_sc, n_sc = safe_wilcoxon(diff_sc, "Sc")
        w_fc, p_fc, n_fc = safe_wilcoxon(diff_fc, "Fc")

        entry = {"n_paired": n}
        entry["Sc_mean_P0"]  = round(sum(sc_p0) / n, 3)
        entry["Sc_mean_P1"]  = round(sum(sc_p1) / n, 3)
        entry["Fc_rate_P0"]  = round(sum(fc_p0) / n, 3)
        entry["Fc_rate_P1"]  = round(sum(fc_p1) / n, 3)

        if w_sc is not None:
            r_sc = wilcoxon_r(w_sc, n_sc)
            entry["Sc_W"]      = round(w_sc, 3)
            entry["Sc_p"]      = round(p_sc, 4)
            entry["Sc_r"]      = round(r_sc, 4)  # effect size
            raw_tests.append(("Sc", slug, p_sc, w_sc, n_sc))
        else:
            entry["Sc_note"] = "diferencias insuficientes para Wilcoxon"

        if w_fc is not None:
            r_fc = wilcoxon_r(w_fc, n_fc)
            entry["Fc_W"]      = round(w_fc, 3)
            entry["Fc_p"]      = round(p_fc, 4)
            entry["Fc_r"]      = round(r_fc, 4)  # effect size
            raw_tests.append(("Fc", slug, p_fc, w_fc, n_fc))
        else:
            entry["Fc_note"] = "diferencias insuficientes para Wilcoxon"

        results[slug] = entry

    # Corrección Holm-Bonferroni (familia confirmatoria: RQ2).
    p_list = [t[2] for t in raw_tests]
    if p_list:
        adj_p = holm_bonferroni(p_list)
        for i, (metric, slug, *_) in enumerate(raw_tests):
            if slug in results:
                results[slug][f"{metric}_p_adj_holm"] = round(adj_p[i], 4)

    return results


# ============================================================================
# COMPARACIÓN EXPLORATORIA ENTRE MODELOS  [A3, A4]
# ============================================================================

def analyze_models_exploratory(models: list[str]) -> dict:
    """
    Comparación exploratoria de Sc entre modelos (condición P0).
    NO es una hipótesis confirmatoria; usa BH-FDR para control de FDR.

    Tests: Kruskal-Wallis global + pairwise Mann-Whitney U.
    Effect sizes: η² (global), rank-biserial r (pares).
    """
    data_per_model = {}
    for slug in models:
        d = load_model_condition(slug, "P0")
        if d:
            data_per_model[slug] = [v["Sc"] for v in d.values()]

    if len(data_per_model) < 2:
        return {"note": "insufficient models"}

    slugs = sorted(data_per_model.keys())
    groups = [data_per_model[s] for s in slugs]
    n_total = sum(len(g) for g in groups)
    k = len(groups)

    # Kruskal-Wallis global.
    try:
        h_stat, p_kw = kruskal(*groups)
        eta2 = eta_squared_kruskal(h_stat, k, n_total)
    except Exception:
        h_stat, p_kw, eta2 = 0.0, 1.0, 0.0

    results = {
        "kruskal_wallis": {
            "H": round(h_stat, 4),
            "p": round(p_kw, 4),
            "eta_squared": round(eta2, 4),
            "k": k,
            "n_total": n_total,
        }
    }

    # Pairwise Mann-Whitney con BH-FDR (exploratorio).
    pairwise = []
    raw_p = []
    for i in range(len(slugs)):
        for j in range(i + 1, len(slugs)):
            g1, g2 = groups[i], groups[j]
            try:
                u, p = mannwhitneyu(g1, g2, alternative="two-sided")
                r = rank_biserial_r(u, len(g1), len(g2))
            except Exception:
                u, p, r = 0.0, 1.0, 0.0
            pairwise.append({
                "comparison": f"{slugs[i]} vs {slugs[j]}",
                "U": round(u, 3),
                "p": round(p, 4),
                "r": round(r, 4),
                "n1": len(g1),
                "n2": len(g2),
            })
            raw_p.append(p)

    # Aplicar BH-FDR.
    if raw_p:
        adj = benjamini_hochberg(raw_p)
        for entry, p_adj in zip(pairwise, adj):
            entry["p_adj_bh"] = round(p_adj, 4)

    results["pairwise"] = pairwise
    return results


# ============================================================================
# RQ3 — DISTRIBUCIÓN DE SMELLS EN SCRIPTS CON Fc=1  [A6]
# ============================================================================

def analyze_rq3(models: list[str]) -> dict:
    """
    RQ3: ¿Qué tipos de security smells predominan en código con Fc=1?

    Filtra EXCLUSIVAMENTE a scripts con Fc=1 (funcionalmente correctos).
    Análisis DESCRIPTIVO (n Fc=1 es generalmente pequeño → solo descriptivos).
    BH-FDR si hay suficientes observaciones para Fisher's Exact.
    """
    smell_counts: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    fc1_counts: dict[str, int] = {}
    total_fc1 = 0

    for slug in models:
        for condition in ["P0"]:    # RQ3 se analiza solo sobre P0 (baseline)
            d = load_model_condition(slug, condition)
            fc1 = [v for v in d.values() if v["Fc"] == 1]
            key = f"{slug}[{condition}]"
            fc1_counts[key] = len(fc1)
            total_fc1 += len(fc1)
            for v in fc1:
                for smell in v["smells"]:
                    smell_counts[key][smell] += 1

    # Distribución global de smells en Fc=1.
    global_counts: dict[str, int] = defaultdict(int)
    for model_counts in smell_counts.values():
        for smell, cnt in model_counts.items():
            global_counts[smell] += cnt

    total_detections = sum(global_counts.values())

    return {
        "total_fc1_scripts": total_fc1,
        "total_smell_detections_in_fc1": total_detections,
        "smell_distribution_fc1": dict(
            sorted(global_counts.items(), key=lambda x: -x[1])
        ),
        "per_model": {
            k: {"fc1_scripts": fc1_counts[k], "smells": dict(smell_counts[k])}
            for k in fc1_counts
        },
        "note": (
            "Análisis descriptivo — muestra de scripts Fc=1 típicamente pequeña. "
            "Se omiten tests de hipótesis si n<10 en cualquier celda."
        ),
    }


# ============================================================================
# GENERACIÓN DEL REPORTE MARKDOWN
# ============================================================================

def fmt_p(p: float) -> str:
    if p < 0.001:
        return "<0.001"
    return f"{p:.4f}"


def generate_markdown(models, rq1, rq2, exploratory, rq3) -> str:
    lines = [
        "# Reporte Estadístico v2 — IaC-Eval + SecLLM\n",
        "_Generado por generate_report_v2.py. "
        "Auditor externo común. Muestreo estratificado. "
        "Effect sizes reportados. Correcciones múltiples separadas por familia._\n",
    ]

    # ---- RQ1 ----
    lines += ["\n## RQ1 — Correlación entre Fc y Sc (condición P0)\n",
              "Corrección múltiple: **Holm-Bonferroni** (familia confirmatoria).\n",
              "| Muestra | N | Spearman ρ | p (raw) | p (Holm) | Kendall τ | p (raw) | p (Holm) |",
              "|---------|---|-----------|---------|----------|-----------|---------|----------|"]
    for slug, r in rq1.items():
        label = "Pooled" if slug == "_pooled" else slug
        lines.append(
            f"| {label} | {r['n']} | {r['spearman_rho']} | {fmt_p(r['spearman_p'])} | "
            f"{fmt_p(r.get('spearman_p_adj_holm', r['spearman_p']))} | "
            f"{r['kendall_tau']} | {fmt_p(r['kendall_p'])} | "
            f"{fmt_p(r.get('kendall_p_adj_holm', r['kendall_p']))} |"
        )

    # ---- RQ2 ----
    lines += ["\n## RQ2 — Efecto del prompting P0 vs P1 (Wilcoxon signed-rank pareado)\n",
              "Effect size: rank-biserial r. Corrección: **Holm-Bonferroni** (confirmatoria).\n",
              "| Modelo | N pareado | Sc̄ P0 | Sc̄ P1 | W(Sc) | p(Sc) | p_Holm(Sc) | r(Sc) | Fc P0 | Fc P1 | W(Fc) | p(Fc) | p_Holm(Fc) | r(Fc) |",
              "|--------|-----------|-------|-------|-------|-------|-----------|-------|-------|-------|-------|-------|-----------|-------|"]
    for slug, r in rq2.items():
        if "note" in r:
            lines.append(f"| {slug} | {r.get('n_paired','?')} | — | — | — | — | — | — | — | — | — | — | — | — |")
            continue
        lines.append(
            f"| {slug} | {r['n_paired']} | {r.get('Sc_mean_P0','?')} | "
            f"{r.get('Sc_mean_P1','?')} | "
            f"{r.get('Sc_W','—')} | {fmt_p(r['Sc_p']) if 'Sc_p' in r else '—'} | "
            f"{fmt_p(r.get('Sc_p_adj_holm', r.get('Sc_p', 1.0))) if 'Sc_p' in r else '—'} | "
            f"{r.get('Sc_r','—')} | "
            f"{r.get('Fc_rate_P0','?')} | {r.get('Fc_rate_P1','?')} | "
            f"{r.get('Fc_W','—')} | {fmt_p(r['Fc_p']) if 'Fc_p' in r else '—'} | "
            f"{fmt_p(r.get('Fc_p_adj_holm', r.get('Fc_p', 1.0))) if 'Fc_p' in r else '—'} | "
            f"{r.get('Fc_r','—')} |"
        )

    # ---- Exploratorio: modelos ----
    lines += ["\n## Análisis exploratorio — Comparación entre modelos (condición P0)\n",
              "Corrección: **Benjamini-Hochberg FDR** (familia exploratoria).\n"]
    kw = exploratory.get("kruskal_wallis", {})
    lines.append(
        f"**Kruskal-Wallis**: H={kw.get('H','?')}, p={fmt_p(kw.get('p',1.0))}, "
        f"η²={kw.get('eta_squared','?')} (k={kw.get('k','?')}, N={kw.get('n_total','?')})\n"
    )
    lines += ["| Comparación | U | p (raw) | p (BH) | r (rank-biserial) |",
              "|-------------|---|---------|--------|-------------------|"]
    for pair in exploratory.get("pairwise", []):
        lines.append(
            f"| {pair['comparison']} | {pair['U']} | {fmt_p(pair['p'])} | "
            f"{fmt_p(pair.get('p_adj_bh', pair['p']))} | {pair['r']} |"
        )

    # ---- RQ3 ----
    lines += ["\n## RQ3 — Security smells en scripts con Fc=1 (descriptivo, P0)\n",
              f"Scripts con Fc=1: **{rq3['total_fc1_scripts']}**  ·  "
              f"Detecciones totales: **{rq3['total_smell_detections_in_fc1']}**\n",
              "| Smell type | Detecciones en Fc=1 |",
              "|------------|---------------------|"]
    for smell, cnt in rq3["smell_distribution_fc1"].items():
        lines.append(f"| {smell} | {cnt} |")
    if not rq3["smell_distribution_fc1"]:
        lines.append("| — | 0 (ningún smell en scripts Fc=1) |")

    lines.append(f"\n_{rq3['note']}_\n")
    return "\n".join(lines)


# ============================================================================
# MAIN
# ============================================================================

def main():
    models = discover_models()
    if not models:
        print(f"[ERROR] No se encontraron datos en {OUTPUT_BASE}.")
        print("        Ejecuta primero: python scripts/pipeline_v2.py")
        return

    print(f"Modelos encontrados: {models}")

    rq1         = analyze_rq1(models)
    rq2         = analyze_rq2(models)
    exploratory = analyze_models_exploratory(models)
    rq3         = analyze_rq3(models)

    # Guardar JSONs individuales.
    (OUTPUT_BASE / "stats_rq1.json").write_text(
        json.dumps(rq1, indent=2), encoding="utf-8")
    (OUTPUT_BASE / "stats_rq2.json").write_text(
        json.dumps(rq2, indent=2), encoding="utf-8")
    (OUTPUT_BASE / "stats_models.json").write_text(
        json.dumps(exploratory, indent=2), encoding="utf-8")
    (OUTPUT_BASE / "stats_rq3.json").write_text(
        json.dumps(rq3, indent=2), encoding="utf-8")

    # Reporte Markdown.
    report = generate_markdown(models, rq1, rq2, exploratory, rq3)
    REPORT_FILE.write_text(report, encoding="utf-8")
    print(f"\nReporte generado en: {REPORT_FILE}")
    print("\n--- Resumen RQ1 (Pooled) ---")
    if "_pooled" in rq1:
        p = rq1["_pooled"]
        print(f"  Spearman ρ = {p['spearman_rho']}, p = {fmt_p(p['spearman_p'])}")
        print(f"  Kendall  τ = {p['kendall_tau']}, p = {fmt_p(p['kendall_p'])}")


if __name__ == "__main__":
    main()
