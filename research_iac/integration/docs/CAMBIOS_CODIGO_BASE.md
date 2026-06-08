# Cambios al código base (SecLLM + IaC-Eval) para la integración Terraform

Este documento registra **todas las modificaciones** hechas al código original de
las dos herramientas para que la integración funcione en este entorno
(Windows 11, Python 3.14, Ollama con modelos locales, GPU de 8 GB).

Repositorios originales de referencia:
- **SecLLM** — https://github.com/Shashi-SecLLM/SecLLM (Gadevito et al.)
- **IaC-Eval** — autoiac-project (benchmark de generación de Terraform)

El objetivo de la integración: SecLLM solo soportaba **Ansible/Puppet/Chef** y
estaba pensado para APIs en la nube (OpenAI/Anthropic). Lo adaptamos para
**auditar Terraform/HCL** generado por **LLMs locales (Ollama)** y conectarlo con
la evaluación funcional de **IaC-Eval** (terraform plan + OPA).

---

## Resumen de archivos tocados

| Archivo | Tipo de cambio |
|---|---|
| `SecLLM/SecLLM/secllm/configurator.py` | 3 correcciones (encoding, timeout, reintentos) |
| `SecLLM/SecLLM/secllm/preprocessor.py` | 1 corrección (encoding) |
| `SecLLM/SecLLM/secllm/secllm.py` | 1 corrección (confidence None) |
| `integration/config_terraform.yaml` | Config nueva: 8 reglas de seguridad para Terraform (COSTAR) |
| `integration/scripts/pipeline.py` | **Nuevo** orquestador (reemplaza el flujo manual) |
| `integration/scripts/generate_report.py` | **Nuevo** generador de reporte |
| `integration/run_overnight.bat` | **Nuevo** lanzador |
| `research_iac/opa.exe` | Binario OPA instalado (no existía) |

---

## 1. Correcciones al núcleo de SecLLM

Sin estos cambios SecLLM **se caía o se colgaba** al usarlo con Ollama en Windows.

### 1.1 `configurator.py` — Encoding UTF-8 al leer la config
**Problema:** en Windows `open()` usa cp1252 por defecto y reventaba al leer los
prompts COSTAR de Terraform, que contienen caracteres UTF-8 (p. ej. el guion «—»).
Error: `UnicodeDecodeError: 'charmap' codec can't decode byte 0x9d`.

```python
# función load_smells_config()
# ANTES
with open(config_file, 'r') as file:
# DESPUÉS
with open(config_file, 'r', encoding='utf-8') as file:
```

### 1.2 `configurator.py` — Timeout de la llamada al modelo (120 s → 600 s)
**Problema:** cargar un modelo de 19–31 GB en una GPU de 8 GB (con descarga a CPU)
tarda **más de 100 s** en la primera llamada. Con el timeout original de 120 s la
auditoría fallaba con `Max retries exceeded` antes de que el modelo respondiera.

```python
# función llm_call(), llamada a chat.completions.create(...)
# ANTES
timeout=120.0,
# DESPUÉS
timeout=600.0,
```

### 1.3 `configurator.py` — Reintentos reales (1 → 3)
**Problema:** el bucle de reintentos era `range(1)`, es decir **nunca reintentaba**.
Un fallo transitorio de Ollama mataba la regla.

```python
# función llm_call()
# ANTES
for attempt in range(1):
# DESPUÉS
for attempt in range(3):
```

### 1.4 `preprocessor.py` — Encoding UTF-8 al leer los .tf
**Problema:** mismo problema de cp1252 al leer los archivos Terraform generados.

```python
# función _loadScript()
# ANTES
with open(file_path, 'r') as file:
# DESPUÉS
with open(file_path, 'r', encoding='utf-8', errors='replace') as file:
```

### 1.5 `secllm.py` — Manejo de `confidence = None` (Ollama)
**Problema:** SecLLM calcula la "confianza" a partir de los *logprobs*, que solo
devuelven los modelos de OpenAI. Ollama no los devuelve → `confidence = None` →
`max(0.0, None)` lanzaba `TypeError` y **no se guardaba ningún resultado**.

```python
# función writeResultsToJSON()
# ANTES
confidence = smell.get('confidence', 1.0)
max_confidence = max(max_confidence, confidence)
# DESPUÉS
confidence = smell.get('confidence')
if confidence is None:        # backends locales no dan logprobs
    confidence = 1.0
max_confidence = max(max_confidence, confidence)
```

### 1.6 `configurator.py` — `torch` y `anthropic` opcionales
**Problema:** el núcleo importaba `torch` y `anthropic` de forma obligatoria al
inicio. `torch` pesa ~2 GB y **no se necesita** para la ruta de Ollama (solo lo usan
los backends HuggingFace/llama_cpp; `anthropic` solo para Claude). Esto obligaba a
todos a instalar PyTorch.

```python
# ANTES
import anthropic
import torch
# DESPUÉS (import opcional; quedan en None si no están instalados)
try:
    import torch
    HAS_TORCH = True
except ImportError:
    torch = None
    HAS_TORCH = False
try:
    import anthropic
    HAS_ANTHROPIC = True
except ImportError:
    anthropic = None
    HAS_ANTHROPIC = False
```

---

## 2. Adaptación de la evaluación funcional de IaC-Eval

El motor original (`iac-eval/evaluation/eval.py`) **no se modificó**; su lógica de
`terraform plan` + OPA se **reimplementó dentro de `pipeline.py`** adaptada para
correr **offline** y con la versión moderna de OPA. Diferencias clave frente al
comportamiento original:

### 2.1 `terraform plan` sin credenciales AWS reales
**Problema:** el `eval.py` original **pide credenciales AWS reales** (`input()`),
porque hace el plan contra AWS. Sin ellas, el provider falla
(`No valid credential sources` / `InvalidClientTokenId 403`).

**Solución (en `pipeline.py`):** credenciales dummy por variables de entorno
**+** un archivo *override* de Terraform que desactiva toda llamada a AWS:

```python
os.environ.setdefault("AWS_ACCESS_KEY_ID", "test")
os.environ.setdefault("AWS_SECRET_ACCESS_KEY", "test")
os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")
```
```hcl
# zz_provider_override.tf (se añade a cada config antes del plan)
provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}
```
Así `terraform plan` valida la **sintaxis/estructura** del código (que es lo que
mide IaC-Eval) sin contactar AWS.

### 2.2 OPA: compatibilidad con políticas Rego v0
**Problema:** las políticas del dataset usan **sintaxis Rego v0** (sin
`import rego.v1`). El `eval.py` original se escribió para **OPA 0.x** (v0 por
defecto). Instalamos **OPA 1.17**, que usa **v1 por defecto** y por tanto **no
parsea** esas políticas → la salida no traía `result` → `KeyError: 'result'`.

**Solución (en `pipeline.py`):** detectar la versión y pasar el flag correcto.

```python
if "import rego.v1" not in policy_text:
    opa_cmd.append("--v0-compatible")
```

### 2.3 Caché del provider de AWS
Para no re-descargar el provider de AWS en cada `terraform init` se fija
`TF_PLUGIN_CACHE_DIR`.

### 2.4 Binario OPA
OPA no estaba instalado en la máquina. Se descargó `research_iac/opa.exe`
(v1.17) y `pipeline.py` lo añade al `PATH` automáticamente.

---

## 3. Capa de integración (código nuevo)

No es código base modificado, sino el "pegamento" que conecta todo:

- **`scripts/pipeline.py`** — orquestador único y **resumible**. Para cada modelo:
  genera Terraform (Ollama) → evalúa funcionalmente (plan + OPA) → el mismo modelo
  se auto-audita con SecLLM. Guarda incrementalmente y omite lo ya hecho.
- **`scripts/generate_report.py`** — arma `outputs/REPORTE_COMPARATIVO.md`.
- **`run_overnight.bat`** — lanza el pipeline y el reporte.
- **`config_terraform.yaml`** — las **8 reglas de seguridad** para Terraform/HCL
  (prompts con el framework COSTAR), que extienden SecLLM más allá de
  Ansible/Puppet/Chef.

### Decisión de diseño: no reiniciar Ollama
Un enfoque previo mataba y relanzaba `ollama.exe` entre modelos para "liberar
VRAM". En Windows eso choca con la app de escritorio de Ollama y provoca
`ConnectionReset`. Se desactivó: Ollama ya descarga el modelo anterior al cargar
uno nuevo (no caben dos en 8 GB), así que el reinicio era innecesario y dañino.

---

## 4. Scripts obsoletos eliminados

Se eliminaron 6 scripts duplicados/superados por `pipeline.py`:
`run_secllm_crossexam.py`, `run_secllm_only.py`, `run_overnight.py`,
`gen_and_analyze.py`, `smoke_test.py`, `generate_comparison_report.py`,
además del `.bat` viejo y todos los `config`/`cache` temporales.

---

## 5. Limpieza de disco

- `iac-eval/evaluation/tmp/` (≈**108 GB** de scratch de `terraform plan`) — borrado
  (se regenera solo; el provider queda cacheado aparte).
- `OllamaSetup.exe` (1.3 GB), archivos `.DS_Store` (macOS), `__pycache__`, y el
  folder duplicado `secllm_terraform_integration/` (sus docs se movieron a
  `integration/docs/`).
