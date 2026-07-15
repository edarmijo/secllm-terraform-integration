# Instrucciones para ejecutar el experimento corregido

## Prerrequisitos

```bash
pip install pandas requests pyyaml scipy pyyaml tabulate --break-system-packages
```
Además: Ollama corriendo, Terraform CLI, OPA v1.17 en el PATH.

## Paso 1 — Descargar los modelos necesarios

```bash
ollama pull qwen2.5-coder:7b
ollama pull llama3.1:8b
ollama pull codellama:7b
ollama pull codegemma:7b
ollama pull devstral-small-2:latest   # auditor externo común
```

## Paso 2 — Ejecutar el pipeline corregido

```bash
cd research_iac/integration
python scripts/pipeline_v2.py
```

El script:
- Crea una muestra estratificada de 40 escenarios (seed=42) y la guarda en
  `outputs_v2/experiment_sample.json`. Todos los modelos usan la MISMA muestra.
- Ejecuta AMBAS condiciones: P0 (baseline) y P1 (security-oriented).
- Usa `devstral-small-2:latest` como auditor externo común para TODOS los modelos.
- Guarda resultados en `outputs_v2/<model>/P0/` y `outputs_v2/<model>/P1/`.
- Es RESUMIBLE: si se interrumpe, relanzar continúa donde se quedó.

### Variables de entorno opcionales

```bash
# Cambiar modelos:
PIPELINE_MODELS=qwen2.5-coder:7b,llama3.1:8b python scripts/pipeline_v2.py

# Cambiar N por modelo/condición (mínimo recomendado: 30):
PIPELINE_N=30 python scripts/pipeline_v2.py

# Cambiar el auditor externo:
COMMON_AUDITOR=codellama:7b python scripts/pipeline_v2.py
```

## Paso 3 — Generar el reporte estadístico

```bash
python scripts/generate_report_v2.py
```

Genera en `outputs_v2/`:
- `stats_rq1.json` — correlación Fc vs Sc (RQ1)
- `stats_rq2.json` — efecto del prompting P0 vs P1 (RQ2)
- `stats_models.json` — comparación exploratoria entre modelos
- `stats_rq3.json` — distribución de smells en Fc=1 (RQ3)
- `REPORT_v2.md` — resumen completo con tablas LaTeX-ready

## Correcciones implementadas

| ID | Corrección |
|----|-----------|
| C1 | Diseño reformulado como two-factor (M×P), ambas condiciones ejecutadas |
| C2 | P1 implementado y ejecutado con instrucciones de seguridad explícitas |
| C3 | Auditor externo común (devstral) en lugar de self-audit |
| C4 | Muestreo aleatorio estratificado por dificultad (seed=42) |
| C5 | Mismos 40 escenarios para todos los modelos y condiciones |
| A1 | RQ1 usa Sc (smell count) como variable continua, no Sp (binaria) |
| A2 | RQ2 usa Wilcoxon signed-rank pareado (P0 vs P1), no Mann-Whitney |
| A3 | Effect sizes reportados: ρ, rank-biserial r, η² |
| A4 | Holm-Bonferroni para confirmatorias; BH-FDR para exploratorias |
| A5 | Sd renombrado a Sc (Smell Count) en todo el pipeline |
| A6 | RQ3 filtra exclusivamente a scripts con Fc=1 |
| M1 | Afirmación absoluta reemplazada por delimitación precisa del gap |
| M2 | "semantic security policy" → "semantic intent specification" |
| M3 | Sp y Sc definidos formalmente con dominio explícito |
| M4 | 9 vs 8 smells resuelto con justificación (Missing Default Case excluido) |
| E1 | Resultados eliminados de Methodology (van a §IV Results) |
| E2 | N=40 por modelo/condición (estratificado, estadísticamente defendible) |
