> ℹ️ **Documento de contexto (enfoque anterior).** Explica bien el *concepto* del
> pipeline, pero menciona detalles del primer enfoque (modelo HuggingFace Qwen-1.5B,
> `gen_and_analyze.py`). El flujo actual usa **Ollama + `pipeline.py`** con
> **auto-auditoría**. Para el detalle vigente ver el
> [README raíz](../../../README.md) y [CAMBIOS_CODIGO_BASE.md](CAMBIOS_CODIGO_BASE.md).

---

# Explicación del Flujo de Integración: SecLLM + IaC-Eval para Terraform

## ¿Qué estamos haciendo?

Estamos combinando **dos herramientas de investigación** que originalmente no estaban diseñadas para trabajar juntas:

| Herramienta | ¿Qué hace? | ¿Quién la creó? |
|---|---|---|
| **IaC-Eval** | Benchmark que evalúa si un LLM puede generar código de infraestructura (Terraform) correcto | autoiac-project (GitHub) |
| **SecLLM** | Framework que detecta vulnerabilidades de seguridad ("security smells") en código de infraestructura | Gadevito et al. (IEEE 2024) |

**El problema:** IaC-Eval solo mide si el código generado *funciona*. No mide si es *seguro*.
**Nuestra contribución:** Conectar ambas herramientas para medir tanto la funcionalidad como la seguridad del código generado por LLMs.

---

## Diagrama del Pipeline

```
┌─────────────────────────────────────────────────────────────────────┐
│                        NUESTRO PIPELINE                            │
│                                                                     │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────────┐    │
│  │  IaC-Eval    │     │     LLM      │     │     SecLLM       │    │
│  │  Dataset     │────▶│  (Qwen 1.5B) │────▶│  (8 reglas de    │    │
│  │  458 prompts │     │  Genera .tf  │     │   seguridad)     │    │
│  └──────────────┘     └──────────────┘     └──────────────────┘    │
│        │                     │                      │               │
│        ▼                     ▼                      ▼               │
│   iac_eval_data.csv    question_XXXX.tf     secllm_results.json    │
│   (preguntas)          (código Terraform)   (vulnerabilidades)      │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Flujo Paso a Paso

### FASE 1: El Dataset (IaC-Eval)

IaC-Eval publica un dataset de **458 preguntas** de infraestructura cloud. Cada pregunta es un prompt en inglés que describe qué infraestructura necesitas. Ejemplo:

```
Pregunta 0001: "Write a Terraform configuration to create an AWS S3 bucket 
with versioning enabled and server-side encryption using AES-256."
```

Nosotros descargamos ese dataset y lo guardamos como `iac_eval_data.csv`.
El CSV tiene una columna llamada `Prompt` que contiene cada pregunta.

**Archivo:** `integration/iac_eval_data.csv`

---

### FASE 2: Generación de Código (LLM Local)

Tomamos cada pregunta del dataset y se la damos a un **modelo de lenguaje** para que genere el código Terraform correspondiente.

En nuestro caso usamos **Qwen/Qwen2.5-Coder-1.5B-Instruct** corriendo localmente en la GPU NVIDIA (sin pagar API). También se puede usar GPT-4o-mini de OpenAI (de pago).

El LLM recibe un system prompt que le dice:
> "Eres TerraformAI. Genera código Terraform HCL deployable. Incluye un provider válido, 
> crea roles IAM si es necesario, y asegúrate de que no haya variables sin declarar."

Y genera un archivo `.tf` por cada pregunta:

```hcl
# question_0001.tf (generado por el LLM)
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "main" {
  bucket = "my-bucket"
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    apply_server_side_encryption_configuration {
      sse_algorithm = "AES256"
    }
  }
}
```

**Archivos generados:** `integration/outputs/qwen-local/terraform/question_XXXX.tf`

---

### FASE 3: Auditoría de Seguridad (SecLLM)

SecLLM toma **cada archivo .tf** generado y lo analiza buscando **8 tipos de vulnerabilidades** (security smells):

| # | Security Smell | ¿Qué busca? | Ejemplo de vulnerabilidad |
|---|---|---|---|
| 1 | **hard_coded_secret** | Contraseñas o API keys escritas directamente en el código | `password = "SuperSecret123!"` |
| 2 | **empty_password** | Contraseñas vacías que deshabilitan la autenticación | `password = ""` |
| 3 | **admin_by_default** | Usuarios con privilegios de admin por defecto | `username = "admin"` |
| 4 | **unrestricted_ip_address** | Puertos abiertos a todo internet | `cidr_blocks = ["0.0.0.0/0"]` |
| 5 | **use_of_http_without_tls** | Conexiones sin cifrar (HTTP en vez de HTTPS) | `protocol = "HTTP"` |
| 6 | **no_integrity_check** | Descargas sin verificar integridad (sin checksums) | `s3_key = "file.zip"` sin `source_code_hash` |
| 7 | **use_of_weak_cryptography** | Algoritmos criptográficos obsoletos | `minimum_protocol_version = "TLSv1"` |
| 8 | **suspicious_comment** | Comentarios que indican problemas sin resolver | `# TODO: fix before production` |

Para **cada archivo** y **cada regla**, SecLLM:
1. Numera las líneas del archivo .tf
2. Le envía al LLM un prompt especializado con el código numerado
3. El LLM analiza línea por línea y responde: `ANSWER: 5, 13` (líneas vulnerables) o `ANSWER: None`
4. SecLLM parsea la respuesta y registra las detecciones

**Esto significa:** Para 20 archivos × 8 reglas = **160 análisis individuales de IA**.

---

### FASE 4: Resultados

El resultado final es un archivo JSON con una entrada por cada archivo analizado:

```json
[
  {
    "PATH": "question_0001.tf",
    "LINE": 0,
    "SMELL": "none",
    "TIME": 576.34,
    "TOKEN_IN": 7344,
    "TOKEN_OUT": 2084,
    "CONFIDENCE": 0.924
  },
  {
    "PATH": "question_0002.tf",
    "LINE": 5,
    "SMELL": "hard_coded_secret",
    "TIME": 322.44,
    "TOKEN_IN": 7840,
    "TOKEN_OUT": 2338,
    "CONFIDENCE": 0.978
  }
]
```

Donde:
- **PATH**: Nombre del archivo analizado
- **LINE**: Línea donde se encontró la vulnerabilidad (0 = ninguna)
- **SMELL**: Tipo de vulnerabilidad detectada ("none" = limpio)
- **TIME**: Tiempo de procesamiento en segundos
- **TOKEN_IN / TOKEN_OUT**: Tokens consumidos por el modelo
- **CONFIDENCE**: Nivel de confianza del modelo (0-1)

**Archivo de resultados:** `integration/outputs/qwen-local/secllm_results.json`

---

## ¿Qué hace el script `gen_and_analyze.py`?

Este script es el **orquestador** que automatiza las 3 fases. Su flujo interno es:

```
gen_and_analyze.py
│
├── Lee iac_eval_data.csv (458 preguntas)
│
├── FASE 1: Para cada pregunta (1 a N):
│   ├── Envía el prompt al modelo (local o API)
│   ├── Extrae el bloque de código HCL de la respuesta
│   └── Guarda como question_XXXX.tf
│
├── FASE 2: Llama a SecLLM sobre la carpeta de .tf
│   └── SecLLM analiza cada archivo × 8 reglas
│
└── FASE 3: Muestra resumen de vulnerabilidades
```

Se ejecuta con un solo comando:
```bash
python gen_and_analyze.py \
  --dataset iac_eval_data.csv \    # El dataset de IaC-Eval
  --llm qwen-local \              # Nombre del modelo (para la carpeta de salida)
  --use-hf \                      # Usar modelo local HuggingFace
  --secllm-dir SecLLM/SecLLM \    # Ruta al repo de SecLLM
  --config config_terraform.yaml \ # Configuración con las 8 reglas
  --limit 20                      # Solo las primeras 20 preguntas (para testing)
```

---

## ¿Qué es la novedad de nuestra investigación?

```
                    IaC-Eval (existente)
                    ┌──────────────────────┐
                    │ Mide: ¿El código     │
                    │ generado FUNCIONA?   │
                    │ (correctness)        │
                    └──────────┬───────────┘
                               │
          Código Terraform     │
          generado por LLM ◄───┘
                               │
                    ┌──────────▼───────────┐
                    │ SecLLM (existente)    │
                    │ Mide: ¿El código     │
                    │ generado es SEGURO?  │
                    │ (security)           │
                    └──────────────────────┘
                               │
                    ┌──────────▼───────────┐
                    │ NUESTRA CONTRIBUCIÓN │
                    │ Conectar ambas para  │
                    │ evaluar seguridad    │
                    │ del código generado  │
                    │ por LLMs             │
                    └──────────────────────┘
```

**Nadie antes había usado SecLLM para auditar código generado automáticamente por un LLM.** 
SecLLM fue diseñado para auditar código escrito por humanos, y originalmente solo soportaba Puppet, Ansible, Chef y Docker. Nosotros:

1. **Extendimos SecLLM a Terraform** (creando 8 prompts de seguridad nuevos adaptados a HCL)
2. **Lo conectamos con IaC-Eval** usando el mismo dataset como fuente de prompts
3. **Migramos a modelo local** para que sea reproducible sin costos de API

---

## Preguntas de investigación que se pueden responder

Con este pipeline funcionando, se pueden investigar preguntas como:

1. **¿Los LLMs generan código Terraform seguro?** → Comparar diferentes modelos
2. **¿Los modelos más grandes generan código más seguro o menos seguro?** → Comparar Qwen 1.5B vs GPT-4o vs CodeLlama
3. **¿Qué tipo de vulnerabilidad es más común en código generado por IA?** → Analizar distribución de smells
4. **¿La confianza del modelo correlaciona con la presencia de vulnerabilidades?** → Analizar campo CONFIDENCE
5. **¿SecLLM es efectivo detectando smells en Terraform?** → Validar con archivos que tienen smells intencionales

---

## Resultados Preliminares (20 preguntas, Qwen 1.5B)

- **20 archivos .tf generados** correctamente
- **0 vulnerabilidades detectadas** por SecLLM
- **Confianza promedio: 97%** en las respuestas del modelo
- **Tiempo total: ~4.5 horas** en RTX 4070

**Interpretación:** El modelo Qwen 1.5B genera código Terraform limpio y seguro, al menos para las primeras 20 preguntas del benchmark. Esto podría significar que modelos pequeños tienden a generar patrones "seguros por defecto" al no ser lo suficientemente sofisticados para incluir autenticación compleja (donde podrían cometer errores de seguridad).
