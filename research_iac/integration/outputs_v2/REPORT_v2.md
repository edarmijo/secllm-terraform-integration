# Reporte Estadístico v2 — IaC-Eval + SecLLM

_Generado por generate_report_v2.py. Auditor externo común. Muestreo estratificado. Effect sizes reportados. Correcciones múltiples separadas por familia._


## RQ1 — Correlación entre Fc y Sc (condición P0)

Corrección múltiple: **Holm-Bonferroni** (familia confirmatoria).

| Muestra | N | Spearman ρ | p (raw) | p (Holm) | Kendall τ | p (raw) | p (Holm) |
|---------|---|-----------|---------|----------|-----------|---------|----------|
| codegemma_7b | 80 | 0.118 | 0.2974 | 1.0000 | 0.1124 | 0.2945 | 1.0000 |
| codellama_7b | 80 | -0.1519 | 0.1786 | 1.0000 | -0.142 | 0.1770 | 1.0000 |
| granite-code_8b | 80 | -0.1233 | 0.2760 | 1.0000 | -0.1173 | 0.2733 | 1.0000 |
| llama3_1_8b | 80 | -0.1342 | 0.2352 | 1.0000 | -0.1235 | 0.2329 | 1.0000 |
| Pooled | 320 | -0.0831 | 0.1382 | 1.0000 | -0.0779 | 0.1379 | 1.0000 |

## RQ2 — Efecto del prompting P0 vs P1 (Wilcoxon signed-rank pareado)

Effect size: rank-biserial r. Corrección: **Holm-Bonferroni** (confirmatoria).

| Modelo | N pareado | Sc̄ P0 | Sc̄ P1 | W(Sc) | p(Sc) | p_Holm(Sc) | r(Sc) | Fc P0 | Fc P1 | W(Fc) | p(Fc) | p_Holm(Fc) | r(Fc) |
|--------|-----------|-------|-------|-------|-------|-----------|-------|-------|-------|-------|-------|-----------|-------|
| codegemma_7b | 80 | 0.613 | 0.312 | 97.0 | 0.0225 | 0.0450 | 0.2566 | 0.025 | 0.025 | — | — | — | — |
| codellama_7b | 80 | 0.9 | 0.512 | 82.5 | 0.0093 | 0.0278 | 0.2183 | 0.1 | 0.125 | — | — | — | — |
| granite-code_8b | 80 | 0.637 | 0.45 | 154.0 | 0.2533 | 0.2533 | 0.3793 | 0.037 | 0.025 | — | — | — | — |
| llama3_1_8b | 80 | 1.425 | 0.7 | 174.0 | 0.0040 | 0.0159 | 0.2348 | 0.025 | 0.0 | — | — | — | — |

## Análisis exploratorio — Comparación entre modelos (condición P0)

Corrección: **Benjamini-Hochberg FDR** (familia exploratoria).

**Kruskal-Wallis**: H=7.4488, p=0.0589, η²=0.0141 (k=4, N=320)

| Comparación | U | p (raw) | p (BH) | r (rank-biserial) |
|-------------|---|---------|--------|-------------------|
| codegemma_7b vs codellama_7b | 2903.5 | 0.2291 | 0.3086 | 0.0927 |
| codegemma_7b vs granite-code_8b | 3206.5 | 0.9797 | 0.9797 | -0.002 |
| codegemma_7b vs llama3_1_8b | 2622.5 | 0.0225 | 0.0702 | 0.1805 |
| codellama_7b vs granite-code_8b | 3494.0 | 0.2306 | 0.3086 | -0.0919 |
| codellama_7b vs llama3_1_8b | 2905.0 | 0.2572 | 0.3086 | 0.0922 |
| granite-code_8b vs llama3_1_8b | 2629.0 | 0.0234 | 0.0702 | 0.1784 |

## RQ3 — Security smells en scripts con Fc=1 (descriptivo, P0)

Scripts con Fc=1: **15**  ·  Detecciones totales: **11**

| Smell type | Detecciones en Fc=1 |
|------------|---------------------|
| admin_by_default | 9 |
| hard_coded_secret | 1 |
| suspicious_comment | 1 |

_Análisis descriptivo — muestra de scripts Fc=1 típicamente pequeña. Se omiten tests de hipótesis si n<10 en cualquier celda._
