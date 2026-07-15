# Reporte Estadístico v2 — IaC-Eval + SecLLM

_Generado por generate_report_v2.py. Auditor externo común. Muestreo estratificado. Effect sizes reportados. Correcciones múltiples separadas por familia._


## RQ1 — Correlación entre Fc y Sc (condición P0)

Corrección múltiple: **Holm-Bonferroni** (familia confirmatoria).

| Muestra | N | Spearman ρ | p (raw) | p (Holm) | Kendall τ | p (raw) | p (Holm) |
|---------|---|-----------|---------|----------|-----------|---------|----------|
| codegemma_7b | 40 | 0.3344 | 0.0349 | 0.3494 | 0.3183 | 0.0368 | 0.3494 |
| codellama_7b | 40 | -0.0268 | 0.8698 | 1.0000 | -0.0253 | 0.8673 | 1.0000 |
| granite-code_8b | 40 | -0.0971 | 0.5511 | 1.0000 | -0.0926 | 0.5442 | 1.0000 |
| llama3_1_8b | 40 | nan | nan | 1.0000 | nan | nan | 1.0000 |
| Pooled | 160 | 0.0291 | 0.7145 | 1.0000 | 0.0273 | 0.7133 | 1.0000 |

## RQ2 — Efecto del prompting P0 vs P1 (Wilcoxon signed-rank pareado)

Effect size: rank-biserial r. Corrección: **Holm-Bonferroni** (confirmatoria).

| Modelo | N pareado | Sc̄ P0 | Sc̄ P1 | W(Sc) | p(Sc) | p_Holm(Sc) | r(Sc) | Fc P0 | Fc P1 | W(Fc) | p(Fc) | p_Holm(Fc) | r(Fc) |
|--------|-----------|-------|-------|-------|-------|-----------|-------|-------|-------|-------|-------|-----------|-------|
| codegemma_7b | 40 | 0.675 | 0.25 | 22.0 | 0.0457 | 0.1371 | 0.2095 | 0.025 | 0.025 | — | — | — | — |
| codellama_7b | 40 | 0.925 | 0.725 | 40.5 | 0.4450 | 0.8594 | 0.3857 | 0.1 | 0.15 | — | — | — | — |
| granite-code_8b | 40 | 0.6 | 0.425 | 19.0 | 0.4297 | 0.8594 | 0.3455 | 0.025 | 0.025 | — | — | — | — |
| llama3_1_8b | 40 | 1.75 | 0.7 | 57.0 | 0.0229 | 0.0917 | 0.2253 | 0.0 | 0.0 | — | — | — | — |

## Análisis exploratorio — Comparación entre modelos (condición P0)

Corrección: **Benjamini-Hochberg FDR** (familia exploratoria).

**Kruskal-Wallis**: H=4.1436, p=0.2464, η²=0.0073 (k=4, N=160)

| Comparación | U | p (raw) | p (BH) | r (rank-biserial) |
|-------------|---|---------|--------|-------------------|
| codegemma_7b vs codellama_7b | 781.5 | 0.8305 | 0.8516 | 0.0231 |
| codegemma_7b vs granite-code_8b | 816.0 | 0.8516 | 0.8516 | -0.02 |
| codegemma_7b vs llama3_1_8b | 656.0 | 0.1082 | 0.3245 | 0.18 |
| codellama_7b vs granite-code_8b | 834.5 | 0.6818 | 0.8516 | -0.0431 |
| codellama_7b vs llama3_1_8b | 680.5 | 0.1830 | 0.3660 | 0.1494 |
| granite-code_8b vs llama3_1_8b | 643.0 | 0.0767 | 0.3245 | 0.1963 |

## RQ3 — Security smells en scripts con Fc=1 (descriptivo, P0)

Scripts con Fc=1: **6**  ·  Detecciones totales: **11**

| Smell type | Detecciones en Fc=1 |
|------------|---------------------|
| admin_by_default | 9 |
| hard_coded_secret | 1 |
| suspicious_comment | 1 |

_Análisis descriptivo — muestra de scripts Fc=1 típicamente pequeña. Se omiten tests de hipótesis si n<10 en cualquier celda._

