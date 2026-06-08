# SecLLM + IaC-Eval — Auditoría de seguridad de Terraform generado por LLMs

Pipeline de investigación que mide, sobre código **Terraform generado por un LLM**,
**tanto si funciona como si es seguro**:

- **IaC-Eval** evalúa si el código *funciona* (`terraform plan` + política de seguridad Rego con OPA).
- **SecLLM** detecta *security smells* (vulnerabilidades) en el código.

**Enfoque (auto-auditoría):** para cada modelo LLM local (vía **Ollama**) →
genera Terraform → se evalúa con IaC-Eval → el **mismo modelo** se auto-audita con
SecLLM (8 reglas), para ver si encuentra sus propios errores.

> Adaptamos SecLLM (que solo soportaba Ansible/Puppet/Chef y APIs de pago) para
> **auditar Terraform/HCL** con **modelos locales gratuitos**. Todos los cambios al
> código base están documentados en
> [research_iac/integration/docs/CAMBIOS_CODIGO_BASE.md](research_iac/integration/docs/CAMBIOS_CODIGO_BASE.md).

---

## Requisitos

| Herramienta | Para qué | Notas |
|---|---|---|
| **Python 3.10+** | Pipeline y SecLLM | `pip install -r requirements.txt` |
| **Ollama** | Servir los modelos LLM localmente | https://ollama.com |
| **Terraform CLI** | `terraform plan` (evaluación funcional) | En el PATH |
| **OPA** | Evaluar políticas Rego | Ver paso 4 (no se sube a git) |
| **GPU** (recomendado) | Acelerar inferencia | Funciona en CPU, pero lento |

> ⚠️ Los modelos grandes (15–31 GB) **no caben** en una GPU de 8 GB y corren en CPU
> (lento). Para pruebas rápidas usa modelos que quepan en tu GPU (p. ej.
> `qwen2.5-coder:7b`, `llama3.1:8b`, `qwen2.5:3b`).

---

## Instalación (paso a paso)

```bash
# 1. Clonar el repo
git clone <URL-del-repo>
cd secllm_terraform_integration

# 2. Crear un entorno virtual (AISLA las dependencias: no toca tu Python global
#    ni otros proyectos) e instalar las dependencias dentro de él
python -m venv .venv
# Windows:        .venv\Scripts\activate
# Linux/macOS:    source .venv/bin/activate
pip install -r requirements.txt

# 3. Instalar Ollama y descargar los modelos que quieras evaluar
#    (deben coincidir con la lista MODELS de pipeline.py)
ollama pull qwen2.5-coder:32b
ollama pull devstral-small-2:latest
#    ...los que tengas. Verifica con:  ollama list
```

**4. Instalar OPA** (el binario no se versiona por su tamaño). Descárgalo en
`research_iac/opa.exe` (el pipeline lo añade al PATH solo), o instálalo en el
PATH del sistema:

```powershell
# Windows (PowerShell), desde la raíz del repo:
curl -L -o research_iac/opa.exe https://openpolicyagent.org/downloads/latest/opa_windows_amd64.exe
```
```bash
# Linux/macOS: instalar 'opa' y dejarlo en el PATH
#   https://www.openpolicyagent.org/docs/latest/#running-opa
```

---

## Cómo ejecutar

```bat
research_iac\integration\run_overnight.bat
```

Hace las 3 fases para todos los modelos y genera
`research_iac/integration/outputs/REPORTE_COMPARATIVO.md`.
**Es resumible**: si se corta, vuelve a ejecutarlo y continúa donde quedó.

O directamente:
```bash
cd research_iac/integration
python scripts/pipeline.py
python scripts/generate_report.py
```

### Configuración

Edita la sección `CONFIGURACION` de
[research_iac/integration/scripts/pipeline.py](research_iac/integration/scripts/pipeline.py):

- **`MODELS`** — lista de modelos (deben aparecer en tu `ollama list`).
- **`NUM_SAMPLES`** — cuántas preguntas del dataset procesar por modelo.

También se pueden fijar sin editar el archivo, por variables de entorno:
```bash
# Ejemplo: 1 modelo, 10 preguntas
PIPELINE_MODELS="devstral-small-2:latest" PIPELINE_NUM_SAMPLES=10 python scripts/pipeline.py
```

---

## Estructura

```
secllm_terraform_integration/
├── README.md                  ← este archivo (empieza aquí)
├── requirements.txt
├── .gitignore
└── research_iac/
    ├── opa.exe                ← (descargar; no se versiona)
    ├── iac-eval/              ← benchmark IaC-Eval (motor de evaluación funcional)
    ├── SecLLM/SecLLM/         ← framework SecLLM (con nuestras correcciones)
    └── integration/           ← NUESTRA capa de integración
        ├── run_overnight.bat
        ├── config_terraform.yaml     8 reglas de seguridad para Terraform
        ├── iac_eval_data.csv         dataset (458 preguntas)
        ├── scripts/
        │   ├── pipeline.py           orquestador (genera → evalúa → audita)
        │   ├── generate_report.py
        │   └── validate_terraform.py
        ├── docs/
        │   ├── CAMBIOS_CODIGO_BASE.md  ← qué se modificó del código original
        │   ├── RESULTADOS.md          ← resultados obtenidos
        │   └── (docs históricos del enfoque anterior)
        └── outputs/<modelo>/         resultados por modelo
```

## Documentación

- **[Cambios al código base](research_iac/integration/docs/CAMBIOS_CODIGO_BASE.md)** — todo lo modificado de SecLLM e IaC-Eval.
- **[Resultados](research_iac/integration/docs/RESULTADOS.md)** — tablas de las corridas.
- **[README de la integración](research_iac/integration/README.md)** — detalle del pipeline.
