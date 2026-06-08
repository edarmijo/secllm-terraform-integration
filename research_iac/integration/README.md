# Integración IaC-Eval + SecLLM

Pipeline que conecta dos herramientas de investigación para medir, sobre código
Terraform generado por LLMs, **tanto si funciona como si es seguro**:

- **IaC-Eval** — evalúa si el código Terraform generado *funciona*
  (`terraform plan` + política de seguridad Rego con OPA).
- **SecLLM** — detecta *security smells* (vulnerabilidades) en el código.

## Enfoque: auto-auditoría

Para **cada modelo** LLM local (servido por Ollama):

1. **Genera** código Terraform para N preguntas del dataset IaC-Eval.
2. **Evalúa funcionalmente** cada `.tf` (compila el plan y, si compila, corre OPA).
3. **Se auto-audita**: el *mismo* modelo que generó el código lo audita con las
   8 reglas de seguridad de SecLLM, para ver si encuentra sus propios errores.

## Cómo ejecutar

```bat
run_overnight.bat
```

Hace las 3 fases para todos los modelos y al final genera
`outputs/REPORTE_COMPARATIVO.md`. **Es resumible**: si se interrumpe, vuelve a
ejecutarlo y continúa donde quedó (omite `.tf`, evaluaciones y auditorías ya hechas).

## Configuración

Edita la sección `CONFIGURACION` en [scripts/pipeline.py](scripts/pipeline.py):

- `MODELS` — lista de modelos (deben aparecer en `ollama list`).
- `NUM_SAMPLES` — preguntas por modelo. Ver nota de rendimiento abajo.

### Rendimiento (importante)

En esta máquina (RTX 4070 Laptop, **8 GB de VRAM**) los modelos (15–31 GB) **no
caben en la GPU** y corren en gran parte en CPU. Cada llamada de auditoría tarda
~3–4 min. Estimación aproximada para los 4 modelos:

| `NUM_SAMPLES` | Tiempo total aprox. |
|---|---|
| 5  | ~10–12 h (una noche) |
| 20 | varios días |

Por eso el valor por defecto es `5`. Como el pipeline es resumible, puedes subirlo
y acumular cobertura en varias noches. Para terminar mucho más rápido, usa modelos
que quepan en 8 GB (p. ej. `qwen2.5-coder:7b`, `llama3.1:8b`, `qwen2.5:3b`).

## Estructura

```
integration/
├── run_overnight.bat          Lanza el pipeline + reporte
├── config_terraform.yaml      Las 8 reglas de seguridad de SecLLM para Terraform
├── iac_eval_data.csv          Dataset IaC-Eval (458 preguntas)
├── scripts/
│   ├── pipeline.py            Orquestador (genera → evalúa → audita), resumible
│   ├── generate_report.py     Construye REPORTE_COMPARATIVO.md
│   └── validate_terraform.py  Utilidad: validación estructural + chequeo regex
├── docs/
│   ├── CAMBIOS_CODIGO_BASE.md Todos los cambios hechos a SecLLM e IaC-Eval
│   ├── RESULTADOS.md          Tablas de resultados de la corrida
│   ├── EXPLICACION_FLUJO.md   Explicación del pipeline
│   ├── GUIA_INSTALACION.md    Guía de instalación
│   └── HALLAZGOS_PRELIMINARES.md
└── outputs/<modelo>/
    ├── terraform/question_XXXX.tf
    ├── iac_eval_results.json   Resultado funcional (plan + OPA)
    └── secllm_results.json     Resultado de la auto-auditoría
```

## Documentación

- **[docs/CAMBIOS_CODIGO_BASE.md](docs/CAMBIOS_CODIGO_BASE.md)** — qué se modificó del código original de SecLLM e IaC-Eval para que funcione.
- **[docs/RESULTADOS.md](docs/RESULTADOS.md)** — tablas con todos los resultados obtenidos.

## Requisitos

- Python con: `pandas`, `requests`, `pyyaml`, `openai`, `rich`, `tqdm`.
- `ollama` con los modelos descargados (`ollama list`).
- `terraform` en el PATH.
- `opa` — el binario está en `research_iac/opa.exe` (se añade al PATH solo).
