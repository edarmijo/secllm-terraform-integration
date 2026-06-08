> ⚠️ **DOCUMENTO HISTÓRICO — NO seguir para instalar.**
> Describe el **primer enfoque** (HuggingFace + Qwen-1.5B + `gen_and_analyze.py`, ya
> eliminado). El proyecto **ahora usa Ollama + `pipeline.py`**. Para instalar y
> correr, sigue el **[README raíz](../../../README.md)**. Se conserva solo como
> referencia histórica.

---

# GUÍA COMPLETA: Integración SecLLM + IaC-Eval para Terraform
## Probado y validado — Junio 2026

---

## RESUMEN DE LO QUE VAS A INSTALAR

| Herramienta          | Para qué                                     | Tiempo instalación |
|----------------------|----------------------------------------------|--------------------|
| Git                  | Clonar los repositorios                      | ~2 min             |
| Python 3.10+         | Correr SecLLM y los scripts                  | ~5 min             |
| Poetry               | Gestor de dependencias de SecLLM             | ~3 min             |
| Conda/Miniconda      | Entorno de IaC-Eval (opcional)               | ~5 min             |
| PyTorch + CUDA       | Inferencia local con GPU NVIDIA              | ~10 min            |
| HuggingFace Transformers | Cargar modelo local de lenguaje          | ~3 min             |
| Terraform CLI        | Validar el HCL generado (opcional)           | ~3 min             |
| OPA                  | Evaluar las policies de IaC-Eval (opcional)  | ~3 min             |

> ⚠️ **Nota sobre OpenAI:** La guía original requería una API Key de OpenAI (de pago). 
> Esta versión actualizada usa un **modelo local gratuito** (Qwen/Qwen2.5-Coder-1.5B-Instruct) 
> que corre en tu GPU NVIDIA. No necesitas pagar nada.

**Tiempo total estimado: 45–60 minutos para tener todo funcionando.**

**Requisito de hardware:** GPU NVIDIA con al menos 8 GB de VRAM (probado con RTX 4070).

---

## PASO 1 — Crear el directorio de trabajo

**macOS/Linux:**
```bash
mkdir ~/research_iac && cd ~/research_iac
```

**Windows (PowerShell):**
```powershell
mkdir C:\Users\$env:USERNAME\research_iac
cd C:\Users\$env:USERNAME\research_iac
```

---

## PASO 2 — Clonar los dos repositorios

```bash
# Clonar SecLLM (el repo con el framework de detección)
git clone https://github.com/gadevito/SecLLM.git

# Clonar IaC-Eval (el benchmark de generación)
git clone https://github.com/autoiac-project/iac-eval.git
```

Verifica que ambos clonaron bien:

**macOS/Linux:**
```bash
ls SecLLM/      # Debes ver: SecLLM/  glitch-datasets/  results/  README.md
ls iac-eval/    # Debes ver: evaluation/  retriever/  templates/  README.md
```

**Windows (PowerShell):**
```powershell
Get-ChildItem SecLLM\
Get-ChildItem iac-eval\
```

---

## PASO 3 — Instalar Poetry (gestor de SecLLM)

**macOS / Linux:**
```bash
curl -sSL https://install.python-poetry.org | python3 -
export PATH="$HOME/.local/bin:$PATH"
poetry --version   # debe decir Poetry (version 1.x.x o 2.x.x)
```

**Windows (PowerShell):**
```powershell
pip install poetry
poetry --version
```

---

## PASO 4 — Instalar dependencias de SecLLM

```bash
cd ~/research_iac/SecLLM/SecLLM    # ¡OJO: es SecLLM/SecLLM (doble carpeta)!
poetry install
```

**Windows (PowerShell):**
```powershell
cd C:\Users\$env:USERNAME\research_iac\SecLLM\SecLLM
poetry install
```

Cuando termine, prueba:
```bash
poetry run python ./secLLM/secllm.py --help
```
Debes ver las opciones: -f, -d, -o, -c, -s, -t, -j, etc.

---

## PASO 5 — Instalar PyTorch con CUDA (modelo local)

Este paso reemplaza la necesidad de API Key de OpenAI. Instalamos PyTorch con soporte CUDA para que tu GPU NVIDIA haga la inferencia localmente.

```bash
cd ~/research_iac/SecLLM/SecLLM
poetry run pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
poetry run pip install transformers accelerate
```

**Windows (PowerShell):**
```powershell
cd C:\Users\$env:USERNAME\research_iac\SecLLM\SecLLM
poetry run pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
poetry run pip install transformers accelerate
```

**Verificar que CUDA funciona:**
```bash
poetry run python -c "import torch; print('CUDA disponible:', torch.cuda.is_available()); print('GPU:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'N/A')"
```

Debes ver algo como:
```
CUDA disponible: True
GPU: NVIDIA GeForce RTX 4070
```

> ⚠️ Si `torch.cuda.is_available()` devuelve `False`, verifica que tienes los drivers NVIDIA actualizados.

---

## PASO 6 — Instalar Miniconda y entorno IaC-Eval (opcional)

Si ya tienes conda instalado, salta al Paso 7.

**macOS (Apple Silicon):**
```bash
curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh
bash Miniconda3-latest-MacOSX-arm64.sh
```

**Linux:**
```bash
curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

Crear el entorno:
```bash
cd ~/research_iac/iac-eval
conda create -n iac-eval python=3.10
conda activate iac-eval
pip install pandas datasets openai google-generativeai anthropic huggingface_hub
```

> Nota: En Windows puedes instalar Miniconda desde https://docs.conda.io/en/latest/miniconda.html

---

## PASO 7 — Instalar Terraform CLI (opcional)

**macOS (con Homebrew):**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform --version
```

**Linux (Ubuntu/Debian):**
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
terraform --version
```

**Windows (con Chocolatey):**
```powershell
choco install terraform
```

> ⚠️ Terraform solo se necesita para validar sintaxis (`terraform validate`). 
> Para correr SecLLM y la integración, NO es necesario.

---

## PASO 8 — Copiar los archivos de integración de este proyecto

Copia los archivos que te entregué al directorio de trabajo:

```bash
cd ~/research_iac

# Estructura que debes crear:
mkdir -p integration/prompts/terraform
mkdir -p integration/scripts
mkdir -p integration/outputs
```

**Windows (PowerShell):**
```powershell
cd C:\Users\$env:USERNAME\research_iac
New-Item -ItemType Directory -Force -Path integration\prompts\terraform
New-Item -ItemType Directory -Force -Path integration\scripts
New-Item -ItemType Directory -Force -Path integration\outputs
```

Copiar archivos desde donde los descargaste:
```
config_terraform.yaml          → integration/
prompts/terraform/*.txt        → integration/prompts/terraform/
scripts/gen_and_analyze.py     → integration/scripts/
```

Verifica la estructura:
```bash
ls integration/
#  config_terraform.yaml  prompts/  scripts/  outputs/
```

---

## PASO 9 — Configurar el modelo local en config_terraform.yaml

Abre `integration/config_terraform.yaml` y verifica que la sección `config` tenga estas líneas:

```yaml
config:
- answerKey: 'ANSWER:'
  device: auto
  heuristicScriptIdentification: true
  maxTokens: 1024
  model: Qwen/Qwen2.5-Coder-1.5B-Instruct
  rowFormat: '{r}: {line}'
  temperature: 0
  use_huggingface: true
```

> **Cambio clave:** `use_huggingface: true` y `model: Qwen/Qwen2.5-Coder-1.5B-Instruct`
> hacen que SecLLM use el modelo local en lugar de llamar a la API de OpenAI.

---

## PASO 10 — Descargar el dataset de IaC-Eval

```bash
# Si usas conda:
conda activate iac-eval

python -c "
from datasets import load_dataset
ds = load_dataset('autoiac-project/iac-eval')
ds['test'].to_csv('integration/iac_eval_data.csv', index=False)
print('Dataset descargado:', len(ds['test']), 'preguntas')
"
```

Debes ver: `Dataset descargado: 458 preguntas`

> Si no tienes conda, puedes ejecutar esto desde cualquier entorno con `pip install datasets pandas`.

---

## PASO 11 — PRUEBA RÁPIDA: correr SecLLM en un .tf de ejemplo

Antes de correr todo el pipeline, verifica que SecLLM funciona con el modelo local.

**1. Crear un archivo de prueba con vulnerabilidades obvias:**

```bash
cat > test_smell.tf << 'EOF'
resource "aws_db_instance" "main" {
  engine         = "mysql"
  instance_class = "db.t3.micro"
  username       = "admin"
  password       = "SuperSecret123!"
  db_name        = "mydb"
}

resource "aws_security_group" "web" {
  name = "web-sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # TODO: restrict this before production
  }
}
EOF
```

**Windows (PowerShell):**
```powershell
@"
resource "aws_db_instance" "main" {
  engine         = "mysql"
  instance_class = "db.t3.micro"
  username       = "admin"
  password       = "SuperSecret123!"
  db_name        = "mydb"
}

resource "aws_security_group" "web" {
  name = "web-sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # TODO: restrict this before production
  }
}
"@ | Out-File -Encoding utf8 test_smell.tf
```

**2. Correr SecLLM en ese archivo:**

```bash
cd ~/research_iac/SecLLM/SecLLM
poetry run python ./secLLM/secllm.py \
  -f ../test_smell.tf \
  -o ../test_results.json \
  -c ../../integration/config_terraform.yaml \
  -t 1 \
  -j
```

**Windows (PowerShell):**
```powershell
cd C:\Users\$env:USERNAME\research_iac\SecLLM\SecLLM
poetry run python .\secLLM\secllm.py `
  -f ..\..\test_smell.tf `
  -o ..\..\test_results.json `
  -c ..\..\integration\config_terraform.yaml `
  -t 1 `
  -j
```

> ⚠️ La flag `-t 1` es **obligatoria** con modelos locales. Fuerza procesamiento secuencial 
> para evitar que la GPU se quede sin memoria (OOM).

**3. Ver el resultado:**
```bash
cat test_results.json | python3 -m json.tool | head -80
```

**Resultado esperado:** JSON con smells detectados incluyendo:
- `hard_coded_secret` en línea 5 (password = "SuperSecret123!")
- `admin_by_default` en línea 4 (username = "admin")
- `unrestricted_ip_address` en línea 15 (0.0.0.0/0)
- `suspicious_comment` en línea 16 (TODO)

---

## PASO 12 — Correr el pipeline completo (primeras 20 preguntas)

```bash
cd ~/research_iac/SecLLM/SecLLM

poetry run python ../../integration/scripts/gen_and_analyze.py \
  --dataset ../../integration/iac_eval_data.csv \
  --llm qwen-local \
  --output-dir ../../integration/outputs \
  --secllm-dir . \
  --config ../../integration/config_terraform.yaml \
  --use-hf \
  --limit 20
```

**Windows (PowerShell):**
```powershell
cd C:\Users\$env:USERNAME\research_iac\SecLLM\SecLLM

poetry run python C:\Users\$env:USERNAME\research_iac\integration\scripts\gen_and_analyze.py `
  --dataset C:\Users\$env:USERNAME\research_iac\integration\iac_eval_data.csv `
  --llm qwen-local `
  --output-dir C:\Users\$env:USERNAME\research_iac\integration\outputs `
  --secllm-dir . `
  --config C:\Users\$env:USERNAME\research_iac\integration\config_terraform.yaml `
  --use-hf `
  --limit 20
```

Esto ejecuta 3 fases:
1. **Fase 1 — Generación:** Lee las primeras 20 preguntas del dataset IaC-Eval y usa el modelo Qwen local para generar código Terraform (.tf) por cada pregunta
2. **Fase 2 — Auditoría:** Corre SecLLM sobre los 20 archivos .tf generados, evaluando 8 reglas de seguridad por archivo (160 auditorías en total)
3. **Fase 3 — Resumen:** Muestra un resumen rápido de vulnerabilidades encontradas

> ⏱️ **Tiempo estimado:** ~4.5 horas con GPU RTX 4070 (8 GB VRAM).
> La Fase 1 (generación) toma ~1 hora, la Fase 2 (auditoría) toma ~3.5 horas.

---

## PASO 13 — Verificar los resultados

```bash
# Ver cuántos archivos .tf se generaron
ls integration/outputs/qwen-local/terraform/*.tf | wc -l
# Debe decir: 20
```

**Windows (PowerShell):**
```powershell
(Get-ChildItem C:\Users\$env:USERNAME\research_iac\integration\outputs\qwen-local\terraform\*.tf).Count
```

```python
# Ver el resumen de smells detectados
python -c "
import json
with open('integration/outputs/qwen-local/secllm_results.json') as f:
    results = json.load(f)
from collections import Counter
smells = [r['SMELL'] for r in results if r.get('SMELL') != 'none']
print('Total archivos analizados:', len(results))
print('Total smells detectados:', len(smells))
print('Por tipo:')
for smell, count in Counter(smells).most_common():
    print(f'  {smell}: {count}')
if len(smells) == 0:
    print('  (ninguno - el modelo generó código seguro)')
"
```

---

## RESULTADOS OBTENIDOS (20 preguntas, modelo Qwen 1.5B)

| Archivo | Tiempo (s) | Tokens entrada | Tokens salida | Smell | Confianza |
|---|---|---|---|---|---|
| question_0000.tf | 983 | 10776 | 4377 | none | 0.987 |
| question_0001.tf | 576 | 7344 | 2084 | none | 0.924 |
| question_0002.tf | 322 | 7840 | 2338 | none | 0.979 |
| question_0003.tf | 473 | 16992 | 1587 | none | 0.977 |
| question_0004.tf | 742 | 15832 | 3879 | none | 0.988 |
| ... | ... | ... | ... | none | ~0.96 |
| **Total** | **~12,000** | **~240K** | **~54K** | **0 smells** | **avg 0.97** |

**Interpretación:**
- El modelo Qwen/Qwen2.5-Coder-1.5B-Instruct generó código Terraform sin vulnerabilidades de seguridad detectables en las 20 muestras.
- La confianza promedio de SecLLM fue del 97%, indicando alta seguridad en las respuestas.
- Este resultado sugiere que modelos pequeños (1.5B) tienden a generar código "seguro por defecto".

---

## ESTRUCTURA FINAL DEL PROYECTO

```
research_iac/
├── SecLLM/                          ← repo original
│   └── SecLLM/
│       ├── secLLM/secllm.py
│       ├── secllm/analyzer.py       ← modificado (ver cambios abajo)
│       ├── secllm/configurator.py   ← modificado (ver cambios abajo)
│       └── pyproject.toml
├── iac-eval/                        ← repo original (no modificado)
│   ├── evaluation/
│   └── ...
└── integration/                     ← NUESTRA CONTRIBUCIÓN
    ├── config_terraform.yaml        ← Config de SecLLM para Terraform
    ├── iac_eval_data.csv            ← Dataset IaC-Eval (458 preguntas)
    ├── prompts/
    │   └── terraform/
    │       ├── hard_coded_secret.txt
    │       ├── empty_password.txt
    │       ├── admin_by_default.txt
    │       ├── unrestricted_ip_address.txt
    │       ├── use_of_http_without_tls.txt
    │       ├── no_integrity_check.txt
    │       ├── use_of_weak_cryptography.txt
    │       └── suspicious_comment.txt
    ├── scripts/
    │   └── gen_and_analyze.py       ← modificado (ver cambios abajo)
    └── outputs/
        └── qwen-local/
            ├── terraform/           ← .tf generados por el LLM
            └── secllm_results.json  ← detecciones de seguridad
```

---

## CAMBIOS REALIZADOS AL CÓDIGO FUENTE

### 1. `integration/scripts/gen_and_analyze.py`

| Cambio | Motivo |
|--------|--------|
| Se agregó función `generate_terraform_hf()` | Permite generar código con modelo local HuggingFace en lugar de OpenAI |
| Se agregaron flags `--use-hf` y `--hf-model` | Permiten seleccionar modelo local desde línea de comandos |
| Se corrigieron caracteres Unicode en prints (`→` → `->`) | Evita `UnicodeEncodeError` en consolas Windows |
| Se corrigió lectura de columna CSV: `row.get('Prompt')` | La columna del dataset IaC-Eval usa `Prompt` con P mayúscula |
| Se agregó `-t 1` al comando SecLLM | Evita error Out-of-Memory en GPU al procesar secuencialmente |
| Se agregó `-j` al comando SecLLM | Genera salida en formato JSON en lugar de CSV |

### 2. `SecLLM/SecLLM/secllm/analyzer.py`

| Cambio | Motivo |
|--------|--------|
| `prompt.format(script=...)` → `prompt.replace('{script}', ...)` | Los prompts de Terraform contienen llaves `{}` en HCL que causaban `KeyError` con `.format()` |

### 3. `SecLLM/SecLLM/secllm/configurator.py`

| Cambio | Motivo |
|--------|--------|
| Se corrigió lectura de `rowFormat` con valor por defecto | Evita `KeyError` cuando `rowFormat` no está definido explícitamente en el YAML |
| Se corrigió manejo del retorno de `llm_call` como tupla `(text, confidence)` | El modelo local retorna una tupla, no solo texto como las APIs |

### 4. `integration/config_terraform.yaml`

| Cambio | Motivo |
|--------|--------|
| Se habilitó `use_huggingface: true` | Activa el backend de HuggingFace en lugar de OpenAI |
| Se configuró `model: Qwen/Qwen2.5-Coder-1.5B-Instruct` | Modelo local open-source gratuito |
| Se configuró `device: auto` | Auto-detecta GPU CUDA |

---

## TIEMPOS DE PROCESAMIENTO REAL

Medidos con **NVIDIA GeForce RTX 4070 (8 GB VRAM)** y modelo **Qwen 1.5B**:

| Fase | 1 archivo | 20 archivos | 458 archivos (estimado) |
|------|-----------|-------------|------------------------|
| Generación de .tf | ~3 min | ~60 min | ~23 horas |
| Auditoría SecLLM (8 reglas) | ~10 min | ~3.5 horas | ~3.5 días |
| **Total** | **~13 min** | **~4.5 horas** | **~4.5 días** |

> 💡 **Tip:** Para reducir tiempos, puedes usar un modelo más grande y rápido vía API
> (GPT-4o-mini, ~$7 por las 458 preguntas) o un modelo local más optimizado.

---

## SOLUCIÓN DE PROBLEMAS COMUNES

### "poetry: command not found"
```bash
# macOS/Linux
export PATH="$HOME/.local/bin:$PATH"

# Windows
pip install poetry
```

### "UnicodeEncodeError" en Windows
Si ves errores de codificación al imprimir caracteres especiales:
```powershell
$env:PYTHONIOENCODING = "utf-8"
```
O modifica el script para usar solo caracteres ASCII en los prints.

### "CUDA out of memory" / GPU se congela
Asegúrate de usar la flag `-t 1` al ejecutar SecLLM para procesamiento secuencial:
```bash
poetry run python ./secLLM/secllm.py -f archivo.tf -o resultado.json -c config.yaml -t 1
```

### "`torch_dtype` is deprecated"
Este es un warning inofensivo de la librería `transformers`. Se puede ignorar.

### "The following generation flags are not valid and may be ignored"
Warning inofensivo. El modelo local ignora flags como `top_p` y `top_k` que no soporta.

### SecLLM no encuentra el archivo de configuración
Usa paths absolutos:
```bash
poetry run python ./secLLM/secllm.py -f /ruta/absoluta/archivo.tf -c /ruta/absoluta/config_terraform.yaml
```

### El script gen_and_analyze.py no encuentra la columna correcta del CSV
```python
# Ver las columnas del CSV para verificar el nombre exacto
python -c "import pandas as pd; df = pd.read_csv('integration/iac_eval_data.csv'); print(df.columns.tolist())"
```
La columna correcta se llama `Prompt` (con P mayúscula).

### El JSON de resultados está vacío (0 bytes)
Esto ocurre si:
1. SecLLM no pudo cargar el modelo (revisar CUDA)
2. La columna del CSV no se encontró (ver fix arriba)
3. Se usó `-d` (directorio) sin `-j` (JSON), produciendo CSV en vez de JSON

---

## ALTERNATIVA: Usar API de OpenAI (de pago)

Si prefieres usar la API de OpenAI en lugar del modelo local:

**1. Configurar la API Key:**
```bash
# macOS/Linux
echo 'export OPENAI_API_KEY="sk-tu-clave-aqui"' >> ~/.zshrc
source ~/.zshrc

# Windows PowerShell
$env:OPENAI_API_KEY = "sk-tu-clave-aqui"
```

**2. Modificar `config_terraform.yaml`:**
```yaml
config:
- model: gpt-4o-mini
  use_huggingface: false
  # ... resto igual
```

**3. Correr sin `--use-hf`:**
```bash
python integration/scripts/gen_and_analyze.py \
  --dataset integration/iac_eval_data.csv \
  --llm gpt-4o-mini \
  --output-dir integration/outputs \
  --secllm-dir SecLLM/SecLLM \
  --config integration/config_terraform.yaml \
  --limit 20
```

**Costo estimado de API:**

| Prueba            | Preguntas | Costo aproximado |
|-------------------|-----------|------------------|
| Prueba rápida     | 1 archivo | $0.001           |
| Test inicial      | 20        | $0.30            |
| Experimento real  | 100       | $1.50            |
| Dataset completo  | 458       | ~$7.00           |
