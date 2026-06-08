> ℹ️ **Hallazgos del enfoque anterior** (modelo HuggingFace Qwen-1.5B, 20 archivos).
> Los **resultados vigentes** (Ollama, 4 modelos + prueba extensa con devstral) están
> en **[RESULTADOS.md](RESULTADOS.md)**. Se conserva por su valor de discusión.

---

# Hallazgos Preliminares de la Integración (Prueba 20 archivos)

Durante la validación técnica del pipeline **IaC-Eval → LLM Generador → SecLLM Auditor**, se realizó una prueba inicial procesando las primeras 20 preguntas del dataset utilizando un modelo local pequeño (`Qwen/Qwen2.5-Coder-1.5B-Instruct`).

El archivo final `secllm_results.json` arrojó **0 vulnerabilidades detectadas**. Para comprender el porqué de este resultado, se realizó una auditoría manual de los archivos `.tf` generados, revelando información crucial para la investigación.

---

## 1. Falsos Negativos (El modelo auditor falló)

Una revisión manual de los archivos generados demostró que **el código SÍ contenía vulnerabilidades de seguridad graves**, pero el modelo utilizado para auditar (Qwen 1.5B) no fue capaz de detectarlas.

### Evidencia 1: Archivo `question_0005.tf`
El modelo generador incluyó explícitamente:
```hcl
  # Líneas 16-17
  username = "admin"
  password = "securepassword123"

  # Línea 74
  protocol = "HTTP"
```

**Lo que SecLLM debió reportar:**
- `admin_by_default` (línea 16)
- `hard_coded_secret` (línea 17)
- `use_of_http_without_tls` (línea 74)

**Lo que SecLLM reportó:** `none` (Falso Negativo)

### Evidencia 2: Archivo `question_0003.tf`
El modelo generador incluyó explícitamente reglas de seguridad que exponen el puerto de base de datos al mundo:
```hcl
  # Línea 40 (Security Group Ingress)
  cidr_blocks = ["0.0.0.0/0"]
```

**Lo que SecLLM debió reportar:**
- `unrestricted_ip_address` (línea 40)

**Lo que SecLLM reportó:** `none` (Falso Negativo)

---

## 2. Conclusiones para la Investigación

Este hallazgo no invalida la investigación, sino que **aporta un punto de discusión de alto valor científico**:

1. **La capacidad de auditoría depende fuertemente del tamaño del modelo:** Un modelo de 1.5 Billones de parámetros puede ser suficiente para *generar* sintaxis de infraestructura básica, pero **carece del razonamiento necesario** para auditar código y aplicar reglas de seguridad (detectar "smells") línea por línea.
2. **Los LLMs sí inyectan código inseguro:** Al contrario de lo que sugería el JSON inicial (0 detecciones), la revisión manual comprobó que el modelo generador inyectó contraseñas hardcodeadas, usuarios por defecto y reglas de red abiertas, validando la premisa de que **el código IaC generado por IA es un riesgo real de seguridad**.

---

## 3. Próximos Pasos Recomendados

Para obtener una tabla de resultados publicable (verdadera), el equipo debe considerar los siguientes escenarios:

### Escenario A: Cambiar el modelo auditor (Recomendado)
Mantener la generación de código con el modelo pequeño, pero cambiar el modelo dentro de SecLLM (el auditor) a uno más grande y capaz de razonar lógicamente:
- **Local:** Llama-3-8B-Instruct o Qwen-2.5-7B-Instruct (requiere ~8-12GB VRAM).
- **Nube:** Usar la API de OpenAI con `gpt-4o-mini`.

### Escenario B: Cambiar ambos modelos
Evaluar y auditar con un modelo estado del arte (`gpt-4o-mini`) para comparar si los modelos más avanzados inyectan menos vulnerabilidades y a su vez las detectan mejor.

> **Nota para la exposición:** Este hallazgo es excelente para mencionarlo en la presentación. Pueden mostrar la captura de código vulnerable de `question_0005.tf` y explicar cómo la elección del modelo LLM como "evaluador de seguridad" introduce un riesgo crítico de Falsos Negativos si el modelo no tiene la capacidad de razonamiento adecuada.
