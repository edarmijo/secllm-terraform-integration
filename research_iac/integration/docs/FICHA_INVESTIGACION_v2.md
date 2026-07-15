# Ficha de Investigación — Segundo Borrador

**Título propuesto:** Funcionalidad versus seguridad en la Infraestructura como Código (Terraform) generada por modelos de lenguaje de gran escala: una evaluación integrada mediante IaC-Eval y SecLLM con auto-auditoría.

**Línea de investigación:** Ingeniería de Software Segura · Modelos de Lenguaje (LLM) · Seguridad en la nube (Infraestructura como Código).

**Institución:** Escuela Superior Politécnica del Litoral (ESPOL).

> Nota de versión: este borrador integra los resultados experimentales reales obtenidos hasta el **2026-06-09** (corridas con `devstral-small-2`, `llama3.1:8b`, `qwen2.5-coder:7b` y la comparativa inicial de 4 modelos). Las cifras citadas en la Justificación provenientes de literatura externa están marcadas para verificación final de la cita.

---

## 1. Justificación

La **Infraestructura como Código (IaC)** se ha convertido en el estándar para aprovisionar recursos en la nube: en lugar de configurar servidores manualmente, los equipos describen la infraestructura en archivos de texto versionables. **Terraform (lenguaje HCL)** es la herramienta dominante de este paradigma y se utiliza para desplegar, de forma automatizada y repetible, miles de recursos en proveedores como AWS, Azure y GCP. El problema es que un error en una sola línea de IaC no afecta a un servidor: se replica en **toda** la infraestructura que ese código despliega.

Esto convierte a las **configuraciones inseguras (misconfigurations)** en una de las principales causas de incidentes de seguridad en la nube. Gartner ha señalado que, hasta 2025, prácticamente la totalidad de las fallas de seguridad en la nube serán responsabilidad del propio cliente —no del proveedor— y se originan mayoritariamente en configuraciones incorrectas *(cita a verificar: Gartner, predicción sobre fallas de seguridad en la nube)*. Buckets de almacenamiento expuestos, puertos abiertos a `0.0.0.0/0`, credenciales escritas directamente en el código y usuarios con privilegios de administrador por defecto son patrones recurrentes en filtraciones reales.

Paralelamente, los **modelos de lenguaje de gran escala (LLM)** —asistentes como GitHub Copilot, ChatGPT o modelos de código abierto— se han incorporado masivamente al flujo de trabajo de los desarrolladores para **generar** código, incluido código de infraestructura. Esto introduce un riesgo nuevo: el código inseguro ya no solo lo escribe un humano distraído, sino que un modelo puede **producirlo y replicarlo a escala**. La evidencia académica es preocupante: el estudio de Pearce et al. (*"Asleep at the Keyboard? Assessing the Security of GitHub Copilot's Code Contributions"*, IEEE S&P 2022) encontró que cerca del **40 % del código sugerido** por Copilot en escenarios relevantes para seguridad contenía vulnerabilidades *(cita a verificar)*. Sin embargo, esos estudios se centran en lenguajes de aplicación (C, Python), no en **IaC**, donde el impacto de una vulnerabilidad es estructural.

Existen dos herramientas de investigación que abordan, **por separado**, las dos mitades del problema:

- **IaC-Eval** (benchmark de generación de IaC; 458 preguntas de infraestructura cloud) mide únicamente si el código generado por un LLM **funciona**: se valida con `terraform plan` y con una política de seguridad declarativa escrita en **Rego/OPA**. Es revelador que, incluso para los mejores modelos comerciales, las tasas de acierto reportadas en este benchmark son bajas (del orden de ~20 %), lo que demuestra que generar IaC *correcta* ya es difícil de por sí *(cita a verificar: paper de IaC-Eval)*.
- **SecLLM** (Gadevito et al., IEEE 2024) usa un LLM para detectar *security smells* (vulnerabilidades) en código de infraestructura, pero originalmente **solo soporta Ansible, Puppet y Chef**, fue diseñado para auditar **código escrito por humanos** y depende de **APIs de pago** (OpenAI/Anthropic).

**El vacío que esta investigación llena:** nadie ha medido, sobre un **mismo** conjunto de código IaC generado por LLMs, **a la vez** su funcionalidad (IaC-Eval) y su seguridad (SecLLM); y nadie ha usado SecLLM para auditar código **producido automáticamente por un modelo**, en lugar de por un humano. Para hacerlo posible, este trabajo **(a)** extiende SecLLM a Terraform/HCL con 8 reglas de seguridad nuevas, **(b)** lo conecta con IaC-Eval en un único pipeline reproducible, y **(c)** lo migra a **modelos locales gratuitos (Ollama)**, eliminando el costo de API y permitiendo la reproducibilidad.

Nuestros **resultados preliminares ya validan la pertinencia del problema** y aportan un hallazgo no trivial: *aprobar el benchmark funcional no garantiza seguridad*. En la corrida extensa con `devstral-small-2` (45 preguntas), solo el **40 % del código compiló** y apenas el **9 % aprobó la política de seguridad de OPA**, pero aun así se detectaron **47 vulnerabilidades en 16 archivos**; uno de los pocos archivos que compilaba *y* aprobaba la política seguía conteniendo un *smell* (`use_of_http_without_tls`). El patrón se repite en los modelos de 7–8 B: `llama3.1:8b` (40 preguntas) generó código que compiló solo en el 20 % de los casos y acumuló **87 vulnerabilidades**, dominadas por `admin_by_default` (25) y `hard_coded_secret` (22); `qwen2.5-coder:7b` produjo **80 vulnerabilidades** con un patrón equivalente. En todos los modelos, **secretos hardcodeados** y **usuarios administradores por defecto** concentran la mayoría de los hallazgos. Estos datos justifican empíricamente la necesidad de una auditoría de seguridad específica sobre el código que los LLM generan.

---

## 2. Objetivos

### 2.1 Objetivo general

Evaluar, de manera integrada y reproducible, la **funcionalidad** y la **seguridad** del código Terraform generado por distintos modelos de lenguaje locales, integrando los benchmarks IaC-Eval y SecLLM en un pipeline de auto-auditoría, para caracterizar la relación entre que el código *funcione* y que sea *seguro*.

### 2.2 Objetivos específicos (hitos)

1. **Extender SecLLM al lenguaje Terraform/HCL**, diseñando y validando 8 reglas de detección de *security smells* (mediante prompts con el framework COSTAR) adaptadas a recursos de infraestructura en la nube.
2. **Construir un pipeline reproducible y resumible** que, para cada modelo, (i) genere código Terraform a partir del dataset de IaC-Eval, (ii) lo evalúe funcionalmente (`terraform plan` + política Rego/OPA) y (iii) lo audite con SecLLM, sin depender de APIs de pago ni de credenciales de nube reales.
3. **Migrar la ejecución a modelos locales servidos por Ollama**, resolviendo las incompatibilidades técnicas necesarias (codificación, *timeouts*, ausencia de *logprobs*, compatibilidad de OPA con Rego v0) para que el experimento sea ejecutable en hardware de consumo.
4. **Evaluar comparativamente un conjunto de modelos** de distintos tamaños (de 7–8 B hasta 32 B parámetros) en su doble rol de **generador** y **auditor** de su propio código.
5. **Medir y caracterizar la relación entre corrección funcional y seguridad**, cuantificando cuántos archivos que compilan y/o aprueban la política de seguridad contienen, aun así, vulnerabilidades.
6. **Caracterizar la distribución de vulnerabilidades** que los LLM inyectan en IaC (qué tipos de *smell* predominan y en qué recursos).
7. **Analizar la capacidad de auto-auditoría en función del tamaño del modelo**, documentando la tasa de **falsos negativos** mediante una verificación manual de referencia (*ground truth*).
8. **Documentar limitaciones y recomendaciones** para usar LLM como generadores y/o auditores de IaC de forma segura.

---

## 3. Preguntas de investigación

Cada pregunta esclarece uno o más objetivos específicos.

- **PI-1 (→ Obj. 1, 3):** ¿Es posible extender SecLLM, originalmente limitado a Ansible/Puppet/Chef y a APIs de pago, para auditar código Terraform/HCL usando modelos de lenguaje locales sin pérdida de funcionalidad?
- **PI-2 (→ Obj. 2, 5):** ¿En qué medida el código Terraform generado por LLM que es **funcionalmente correcto** (compila y aprueba la política de seguridad de IaC-Eval) es también **seguro** según las reglas de SecLLM?
- **PI-3 (→ Obj. 4):** ¿Cómo difieren los modelos de lenguaje, según su tamaño y especialización, en su capacidad de **generar** código Terraform desplegable?
- **PI-4 (→ Obj. 6):** ¿Qué tipos de *security smells* inyectan con mayor frecuencia los LLM al generar Infraestructura como Código, y existe un patrón dominante?
- **PI-5 (→ Obj. 4, 7):** ¿Es un mismo modelo un **auditor** fiable de su propio código, y cómo depende esa fiabilidad del tamaño del modelo? Es decir, ¿con qué frecuencia incurre en **falsos negativos** (no detecta vulnerabilidades reales)?
- **PI-6 (→ Obj. 8):** ¿Qué tan viable es, en términos de tiempo y recursos de cómputo, ejecutar este tipo de auditoría de seguridad con LLM locales en hardware de consumo?

---

## 4. Importancia de la investigación, metodología, valor teórico e implicación práctica

### 4.1 Importancia de la investigación

El problema es concreto y creciente: cada vez más equipos de desarrollo delegan en LLM la escritura de infraestructura, y un error de seguridad en IaC **se despliega y replica automáticamente** sobre la infraestructura productiva. Comprender *cuándo* y *cómo* falla la seguridad del código generado por IA —y si los propios modelos pueden detectar esos fallos— es indispensable para incorporar estas herramientas de forma responsable.

**¿Quiénes se benefician y cómo?**

- **Ingenieros DevOps / SRE y desarrolladores de plataforma:** obtienen evidencia empírica de que el código IaC sugerido por un LLM debe pasar por una auditoría de seguridad antes de desplegarse, y un pipeline concreto y gratuito para hacerlo. *Beneficio directo:* menos configuraciones inseguras llegando a producción.
- **Equipos de seguridad (AppSec / Cloud Security):** disponen de un marco reproducible para medir el riesgo que introduce la adopción de asistentes de IA y para comparar modelos antes de aprobarlos internamente.
- **Organizaciones que operan en la nube (y, de forma indirecta, sus usuarios finales):** una infraestructura mejor configurada significa menos exposición de datos personales y menos brechas; el beneficio último recae en las personas cuyos datos quedan protegidos.
- **La comunidad académica y los estudiantes:** se entrega un pipeline abierto, reproducible y documentado que extiende dos herramientas previas y habilita nuevas líneas de trabajo (matriz cruzada generador≠auditor, nuevos lenguajes IaC, nuevas reglas).

### 4.2 Metodología

Investigación **cuantitativa, experimental y comparativa**, de tipo *benchmarking*. El procedimiento es:

1. **Fuente de tareas:** se usa el dataset de IaC-Eval (458 prompts de infraestructura cloud) como conjunto de tareas; se procesa un subconjunto de N preguntas por modelo (configurable).
2. **Fase de generación:** cada modelo LLM local (servido por Ollama) recibe el prompt y produce un archivo `.tf`.
3. **Fase de evaluación funcional (IaC-Eval):** sobre cada `.tf` se ejecuta `terraform plan` (con credenciales *dummy* y un *override* del provider para validar la sintaxis/estructura sin contactar AWS) y, si compila, se evalúa la política de seguridad **Rego** del dataset con **OPA**.
4. **Fase de auto-auditoría (SecLLM):** el **mismo** modelo audita su código con las 8 reglas de seguridad, reportando, por archivo y por regla, las líneas vulnerables.
5. **Verificación de referencia (*ground truth*):** sobre una muestra, revisión manual de los `.tf` para identificar falsos negativos del auditor.
6. **Análisis:** se consolidan métricas funcionales y de seguridad por modelo y se construye un reporte comparativo.

El pipeline es **resumible** (tolerante a interrupciones) y está implementado en `scripts/pipeline.py`; los resultados crudos se guardan por modelo (`iac_eval_results.json`, `secllm_results.json`) y se agregan en `REPORTE_COMPARATIVO.md`.

### 4.3 Valor teórico

- Aporta **evidencia empírica** sobre una hipótesis poco estudiada: la **disociación entre corrección funcional y seguridad** en código IaC generado por IA (un código puede "funcionar" y ser inseguro a la vez).
- Caracteriza la **capacidad de los LLM como auditores de sí mismos** y su dependencia del tamaño del modelo, contribuyendo al debate sobre el uso de LLM como evaluadores (*LLM-as-a-judge*) en contextos de seguridad.
- Demuestra la **transferibilidad de un detector de *security smells*** (SecLLM) a un lenguaje nuevo (HCL) mediante ingeniería de prompts (COSTAR), aportando un método replicable a otros lenguajes IaC.

### 4.4 Implicación práctica

- Un **pipeline abierto, reproducible y gratuito** (sin costos de API) que cualquier equipo puede correr para auditar el IaC que genera un LLM antes de desplegarlo.
- **Criterios de selección de modelos:** evidencia comparativa de qué modelos generan código más desplegable y cuáles auditan mejor, útil para decisiones de adopción.
- Una **alerta accionable** para la industria: integrar el escaneo de seguridad de IaC en el flujo de CI/CD cuando se usen asistentes de IA, y no asumir que "compila" equivale a "es seguro".

---

## 5. Viabilidad de la investigación

| Recurso | Disponibilidad y detalle |
|---|---|
| **Recursos humanos** | Equipo de estudiantes de ESPOL con apoyo del tutor de la materia. Competencias presentes: programación en Python, manejo de Git, fundamentos de seguridad y de cómputo en la nube. *(Detallar integrantes y roles en la Sección 6.)* |
| **Recursos económicos** | **Costo cercano a cero.** La migración a modelos locales (Ollama) elimina el gasto en APIs de pago. Todo el software es de código abierto (Terraform CLI, OPA, SecLLM, IaC-Eval, Python). No se requieren licencias. |
| **Capacidad de procesamiento** | Hardware de consumo: laptop con GPU **NVIDIA RTX 4070 (8 GB VRAM)**, Windows 11, Python. Los modelos de 7–8 B caben en la GPU (~1–2 min por archivo); los de 32 B corren con descarga a CPU (más lentos). El diseño **resumible** permite acumular cobertura en varias sesiones nocturnas sin perder progreso. |
| **Datasets / datos** | **IaC-Eval** (`iac_eval_data.csv`, 458 preguntas de infraestructura cloud) como fuente de tareas, ya incluido en el repositorio. No se requieren datos de personas ni datos sensibles; **no hay implicaciones éticas de privacidad**. El código auditado lo generan los propios modelos. |
| **Datos generados** | Salidas reproducibles por modelo: archivos `.tf`, resultados funcionales y de auditoría en JSON, y reportes comparativos en Markdown, versionados en el repositorio. |
| **Espacio físico** | No se requiere laboratorio ni espacio especializado; el trabajo es íntegramente computacional y puede realizarse de forma remota. *(Consideración operativa: `terraform plan` genera grandes volúmenes de archivos temporales —~108 GB en una corrida— que se purgan automáticamente; conviene reservar espacio en disco.)* |
| **Herramientas externas** | Repositorios originales de SecLLM e IaC-Eval (abiertos), Ollama (gratuito) y los pesos de los modelos LLM de código abierto descargables localmente. |

**Conclusión de viabilidad:** el proyecto es **altamente viable**. El principal limitante no es económico sino de **tiempo de cómputo** en hardware de 8 GB, mitigado por el diseño resumible del pipeline y por el uso de modelos de 7–8 B.

---

## 6. Deficiencias en el conocimiento del tema

> *Esta sección debe declarar, por cada integrante, qué se conoce y qué se desconoce del tema, y las acciones para mejorar. A continuación se entrega la estructura y ejemplos basados en los conocimientos que el proyecto ya evidencia; complétese con los nombres y particularidades reales del equipo.*

**Conocimientos que el equipo ya domina (evidenciados por el avance):** programación en Python; integración de herramientas de terceros; uso de Git; conceptos de Infraestructura como Código y Terraform/HCL; ejecución de LLM locales con Ollama; fundamentos de seguridad (*security smells*).

**Deficiencias / brechas de conocimiento identificadas y plan de acción:**

| Área de desconocimiento | Acción para mejorar |
|---|---|
| **Políticas Rego / OPA** a profundidad (escritura y depuración de políticas de seguridad). | Estudiar la documentación oficial de OPA y los ejemplos de políticas del propio dataset IaC-Eval. |
| **Métricas de evaluación de detectores** (precisión, *recall*, F1, *false negative rate*) y su aplicación rigurosa. | Revisar literatura de evaluación de clasificadores y formalizar la verificación manual como *ground truth*. |
| **Interpretabilidad de LLM** (por qué un modelo no detecta una vulnerabilidad: ausencia de *logprobs* en Ollama, límites de razonamiento). | Leer el paper original de SecLLM y trabajos de *LLM-as-a-judge*; documentar el caso de falsos negativos. |
| **Diseño experimental estadístico** (tamaño de muestra, significancia). | Aumentar N de preguntas en próximas corridas y consultar al tutor sobre validez estadística. |

**Plantilla por integrante (completar):**

- **Integrante 1 — [Nombre]:** *Conoce:* … *Desconoce:* … *Acción:* …
- **Integrante 2 — [Nombre]:** *Conoce:* … *Desconoce:* … *Acción:* …
- **Integrante N — [Nombre]:** *Conoce:* … *Desconoce:* … *Acción:* …

---

## 7. Variables

### 7.1 Variables independientes (lo que se manipula/varía)

| Variable | Definición operacional |
|---|---|
| **Modelo LLM generador** | Modelo de lenguaje que produce el código Terraform, identificado por su nombre y etiqueta en Ollama (p. ej. `qwen2.5-coder:7b`, `llama3.1:8b`, `devstral-small-2`). Variable categórica. |
| **Tamaño del modelo (número de parámetros)** | Cantidad de parámetros del modelo expresada en miles de millones (B): 7 B, 8 B, 32 B. Variable cuantitativa discreta, usada para analizar el efecto del tamaño en la generación y en la auditoría. |
| **Configuración de auditoría** | Relación entre el modelo que genera y el que audita. En este estudio: **auto-auditoría** (generador = auditor). Variable categórica (auto vs. cruzada), prevista para extensión futura. |
| **Tarea / recurso de infraestructura** | Prompt del dataset IaC-Eval que describe el recurso a generar (p. ej. `aws_s3_bucket`, `aws_iam_policy`, `aws_vpc`), identificado por su índice `question_XXXX`. Variable categórica de control. |
| **Regla de seguridad evaluada** | Cada uno de los 8 *security smells* aplicados por SecLLM: `hard_coded_secret`, `empty_password`, `admin_by_default`, `unrestricted_ip_address`, `use_of_http_without_tls`, `no_integrity_check`, `use_of_weak_cryptography`, `suspicious_comment`. |

### 7.2 Variables dependientes (lo que se mide)

| Variable | Definición operacional |
|---|---|
| **Corrección funcional (compila)** | Variable binaria por archivo: vale 1 si `terraform plan` finaliza sin error (`terraform_plan_success = true`), 0 en caso contrario. Se reporta como tasa de compilación (%) por modelo. |
| **Conformidad de seguridad funcional (OPA)** | Variable binaria por archivo: vale 1 si el código compila **y** aprueba la política de seguridad Rego del dataset (`opa_evaluation_result = "Success"`), 0 en caso contrario. Se reporta como % por modelo. |
| **Número de vulnerabilidades detectadas** | Conteo de *security smells* reportados por SecLLM por archivo y agregado por modelo (variable cuantitativa discreta). |
| **Distribución de vulnerabilidades por tipo** | Frecuencia de cada uno de los 8 tipos de *smell* sobre el total detectado (vector de conteos). Permite identificar el patrón dominante. |
| **Tasa de falsos negativos del auditor** | Proporción de vulnerabilidades presentes en el código (según verificación manual de referencia) que el modelo auditor **no** detectó. Mide la fiabilidad del modelo como auditor. |
| **Rendimiento / costo computacional** | Tiempo de auditoría por archivo (segundos) y tokens consumidos (entrada/salida). Variable cuantitativa continua, usada para evaluar viabilidad. |

> **Relación entre variables (hipótesis operativa):** se espera que las variables independientes (modelo, tamaño) influyan en las dependientes, y que exista **disociación** entre la corrección funcional y la seguridad —es decir, que un archivo pueda puntuar alto en compilación/OPA y aun así presentar vulnerabilidades—, hipótesis ya respaldada por los resultados preliminares.

---

## Anexo A — Síntesis de resultados experimentales (evidencia de avance)

**Prueba extensa — `devstral-small-2` (45 preguntas, 2026-06-07):**
- Compila (`terraform plan`): **18/45 (40 %)**.
- Aprueba política de seguridad (OPA): **4/45 (9 %)**.
- Vulnerabilidades detectadas en auto-auditoría: **47** en 16 archivos.
- Patrón dominante: `admin_by_default` (16) + `hard_coded_secret` (15) = **66 %** del total.
- Hallazgo clave: `question_0002` compila **y** aprueba OPA, pero contiene un `use_of_http_without_tls` → *funcional ≠ seguro*.

**Modelos de 7–8 B (40 preguntas c/u):**

| Modelo | Compila | Aprueba OPA | Vulns totales | Tipos dominantes |
|---|---|---|---|---|
| `llama3.1:8b` | 8/40 (20 %) | 1/40 | **87** | admin_by_default (25), hard_coded_secret (22), empty_password (16) |
| `qwen2.5-coder:7b` | 5/40 (12,5 %) | 0/40 | **80** | hard_coded_secret (20), admin_by_default (20), suspicious_comment (20) |

**Comparativa inicial (4 modelos × 5 preguntas, 2026-06-07):**
- Mejor **generador**: `devstral-small-2` (4/5 compila; único con un archivo funcional + conforme a política).
- Mejor **auditor**: `qwen2.5-coder:32b` (9 detecciones).
- `glm-4.7-flash:q8_0`: auditor inefectivo (0 detecciones pese a ser verboso).
- `deepseek-r1:32b` (modelo de razonamiento): peor caso práctico (0/5 compila y el auditor más lento).

**Limitaciones reconocidas:** muestra aún pequeña (validación de tendencias, no inferencia estadística definitiva); la auto-auditoría mezcla capacidad de detección con "honestidad" del modelo sobre su propio código; Ollama no entrega *logprobs* (el campo de confianza no es informativo); el hardware de 8 GB limita los tiempos.

---

## Anexo B — Referencias (a completar y formatear según norma APA/IEEE)

- Gadevito et al. (2024). *SecLLM: ...* IEEE. *(completar título y datos exactos)*.
- *IaC-Eval: A Code Generation Benchmark for Cloud Infrastructure-as-Code Programs.* *(completar autores, venue y año — verificar NeurIPS 2024 Datasets & Benchmarks)*.
- Pearce, H., Ahmad, B., Tan, B., Dolan-Gavitt, B., & Karri, R. (2022). *Asleep at the Keyboard? Assessing the Security of GitHub Copilot's Code Contributions.* IEEE S&P.
- Gartner. *Predicción sobre fallas de seguridad en la nube atribuibles al cliente.* *(verificar referencia y año exactos)*.
- Documentación de Terraform (HashiCorp), Open Policy Agent (OPA) y Ollama.

> **Pendiente:** validar y formatear todas las citas marcadas *(a verificar)* antes de la entrega final.
