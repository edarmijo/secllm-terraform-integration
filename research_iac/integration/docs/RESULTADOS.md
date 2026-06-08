# Resultados — Pipeline IaC-Eval + SecLLM (auto-auditoría)

> 📌 Este documento tiene **dos partes**:
> 1. **[Prueba extensa](#prueba-extensa--devstral-small-2-45-preguntas)** — devstral-small-2 sobre **45 preguntas** (el resultado principal).
> 2. **[Comparativa inicial](#comparativa-inicial-4-modelos--5-preguntas)** — los 4 modelos sobre 5 preguntas (validación).

---

# Prueba extensa — devstral-small-2 (45 preguntas)

Corrida del **2026-06-07** con el **mejor modelo** (devstral-small-2), sobre
**45 preguntas** del dataset IaC-Eval (las 5 iniciales + 40 nuevas), pasando por
el pipeline completo: generación → IaC-Eval (plan + OPA) → auto-auditoría SecLLM.

## Resumen

| Métrica | Resultado |
|---|---|
| Preguntas procesadas | 45 |
| **Compila (terraform plan)** | **18/45 (40%)** |
| **Pasa política de seguridad (OPA)** | **4/45 (9%)** |
| Archivos con ≥1 vulnerabilidad (auto-auditoría) | 16/45 |
| **Total vulnerabilidades detectadas** | **47** |
| Tiempo de auditoría | ~3.2 h (≈259 s/archivo) |
| Tokens auditoría (in / out) | 1,065,168 / 64,705 |

## Vulnerabilidades por tipo (47 en total)

| Security smell | Cantidad |
|---|---|
| admin_by_default | 16 |
| hard_coded_secret | 15 |
| suspicious_comment | 9 |
| use_of_http_without_tls | 4 |
| unrestricted_ip_address | 2 |
| no_integrity_check | 1 |
| empty_password | 0 |
| use_of_weak_cryptography | 0 |

## Archivos funcionalmente correctos Y conformes a la política (4/45)

`question_0002`, `question_0006`, `question_0033`, `question_0034` compilan **y**
pasan OPA. De ellos, **`question_0002` aún tiene un smell** (`use_of_http_without_tls`)
→ confirma a mayor escala que **pasar el benchmark funcional no garantiza seguridad**.

## Hallazgos de la prueba extensa

1. **Tasa de compilación realista: 40%** (18/45). El 80% del sondeo inicial (4/5)
   era optimista por la muestra pequeña; a escala, devstral genera código
   desplegable menos de la mitad de las veces.
2. **Solo 9% pasa la política de seguridad de IaC-Eval.** Generar Terraform
   *funcional y conforme* es difícil.
3. **Patrón dominante de inseguridad:** `admin_by_default` (16) + `hard_coded_secret`
   (15) = **66%** de todas las vulnerabilidades. devstral mete sistemáticamente
   usuarios admin y credenciales hardcodeadas.
4. **devstral es buen auto-auditor:** detectó 47 smells en 16 archivos, cubriendo
   6 de los 8 tipos de reglas (solo faltaron `empty_password` y
   `use_of_weak_cryptography`, probablemente ausentes en el código).

## Detalle de archivos con vulnerabilidades (16)

| Archivo | Vulnerabilidades |
|---|---|
| question_0002 | use_of_http_without_tls ×1 |
| question_0003 | hard_coded_secret ×1, admin_by_default ×1 |
| question_0004 | admin_by_default ×2, unrestricted_ip_address ×1 |
| question_0005 | hard_coded_secret ×1, admin_by_default ×1 |
| question_0014 | hard_coded_secret ×1, admin_by_default ×1 |
| question_0015 | hard_coded_secret ×2, admin_by_default ×2 |
| question_0016 | hard_coded_secret ×2, admin_by_default ×2 |
| question_0017 | hard_coded_secret ×1, admin_by_default ×1 |
| question_0018 | hard_coded_secret ×1, admin_by_default ×1 |
| question_0019 | hard_coded_secret ×1, admin_by_default ×1, unrestricted_ip_address ×1, suspicious_comment ×1 |
| question_0022 | suspicious_comment ×1 |
| question_0023 | hard_coded_secret ×1 |
| question_0024 | hard_coded_secret ×1, admin_by_default ×1 |
| question_0025 | hard_coded_secret ×2, admin_by_default ×2, suspicious_comment ×3 |
| question_0026 | hard_coded_secret ×1, admin_by_default ×1, use_of_http_without_tls ×2 |
| question_0030 | use_of_http_without_tls ×1, no_integrity_check ×1, suspicious_comment ×4 |

---

# Comparativa inicial (4 modelos × 5 preguntas)

Corrida del **2026-06-07** (07:43 → 13:59, ~6 h 15 min).

## Configuración del experimento

| Parámetro | Valor |
|---|---|
| Dataset | IaC-Eval (`iac_eval_data.csv`) |
| Preguntas por modelo | 5 (`question_0000`–`question_0004`) |
| Modelos evaluados | 4 (Ollama, local) |
| Reglas de seguridad | 8 (SecLLM adaptado a Terraform/HCL) |
| Hardware | RTX 4070 Laptop, 8 GB VRAM (modelos corren con descarga a CPU) |
| Enfoque | Cada modelo **genera** su Terraform y **se auto-audita** |

**Métricas:**
- **Compila (plan):** el `terraform plan` se ejecuta sin errores (código válido).
- **Pasa OPA:** además, cumple la política de seguridad Rego del dataset.
- **Vulnerabilidades:** *security smells* que el propio modelo detectó en su código.

---

## Tabla 1 — Evaluación funcional (¿el código FUNCIONA?)

| Modelo | Compila (plan) | Pasa política (OPA) |
|---|---|---|
| **devstral-small-2** | **4/5 (80%)** | **1/5 (20%)** |
| qwen2.5-coder:32b | 2/5 (40%) | 0/5 |
| glm-4.7-flash:q8_0 | 2/5 (40%) | 0/5 |
| deepseek-r1:32b | 0/5 (0%) | 0/5 |

> La mayoría de los "0 en OPA" se deben a que **el código ni siquiera compila**;
> solo los planes válidos llegan a evaluarse con OPA. **devstral** fue el único que
> produjo un archivo **plannable Y conforme a la política** (`question_0002`).

---

## Tabla 2 — Auto-auditoría de seguridad (¿el modelo encuentra sus propios fallos?)

| Modelo | Total | hard_coded_secret | admin_by_default | unrestricted_ip | http_without_tls | suspicious_comment |
|---|---|---|---|---|---|---|
| **qwen2.5-coder:32b** | **9** | 4 | 4 | 1 | 0 | 0 |
| devstral-small-2 | 6 | 1 | 3 | 1 | 1 | 0 |
| deepseek-r1:32b | 4 | 0 | 0 | 2 | 0 | 2 |
| glm-4.7-flash:q8_0 | **0** | 0 | 0 | 0 | 0 | 0 |

> No se detectó ningún `empty_password`, `no_integrity_check` ni
> `use_of_weak_cryptography` en estas 5 preguntas.

---

## Tabla 3 — Resumen combinado + rendimiento

| Modelo | Generador (plan ok) | Auditor (vulns) | Tiempo auditoría | Tokens in/out |
|---|---|---|---|---|
| qwen2.5-coder:32b | 2/5 | 🥇 9 | 24.9 min | 152.9k / 11.8k |
| devstral-small-2 | 🥇 4/5 | 6 | ⚡ 21.5 min | 102.1k / 6.6k |
| deepseek-r1:32b | 0/5 | 4 | 🐌 138 min | 79.5k / 29.3k |
| glm-4.7-flash:q8_0 | 2/5 | 0 | 99.2 min | 58.4k / 38.1k |

---

## Tabla 4 — Detalle por archivo

| Modelo | Archivo | Compila | OPA | Vulnerabilidades detectadas |
|---|---|---|---|---|
| qwen2.5-coder:32b | question_0000 | ❌ | — | — |
| qwen2.5-coder:32b | question_0001 | ✅ | Failure | — |
| qwen2.5-coder:32b | question_0002 | ✅ | Failure | — |
| qwen2.5-coder:32b | question_0003 | ❌ | — | **4× hard_coded_secret, 4× admin_by_default** |
| qwen2.5-coder:32b | question_0004 | ❌ | — | 1× unrestricted_ip_address |
| deepseek-r1:32b | question_0000 | ❌ | — | 1× unrestricted_ip_address |
| deepseek-r1:32b | question_0001 | ❌ | — | — |
| deepseek-r1:32b | question_0002 | ❌ | — | — |
| deepseek-r1:32b | question_0003 | ❌ | — | — |
| deepseek-r1:32b | question_0004 | ❌ | — | 2× suspicious_comment, 1× unrestricted_ip_address |
| devstral-small-2 | question_0000 | ✅ | Failure | — |
| devstral-small-2 | question_0001 | ✅ | Failure | — |
| devstral-small-2 | question_0002 | ✅ | **Success** | 1× use_of_http_without_tls |
| devstral-small-2 | question_0003 | ❌ | — | 1× hard_coded_secret, 1× admin_by_default |
| devstral-small-2 | question_0004 | ✅ | Failure | 1× admin_by_default, 1× unrestricted_ip_address |
| glm-4.7-flash:q8_0 | question_0000 | ❌ | — | — |
| glm-4.7-flash:q8_0 | question_0001 | ✅ | Failure | — |
| glm-4.7-flash:q8_0 | question_0002 | ✅ | Failure | — |
| glm-4.7-flash:q8_0 | question_0003 | ❌ | — | — |
| glm-4.7-flash:q8_0 | question_0004 | ❌ | — | — |

---

## Hallazgos principales

1. **Generar ≠ asegurar.** El caso `devstral / question_0002` **compila y pasa la
   política OPA**, pero SecLLM **igual encontró** un `use_of_http_without_tls`.
   Cumplir el benchmark funcional **no garantiza** código seguro.

2. **Los LLMs sí inyectan vulnerabilidades.** Predominan **secretos hardcodeados**
   y **usuarios admin por defecto** (qwen, solo en `question_0003`, metió 4 + 4).

3. **Mejor generador: devstral-small-2** (4/5 compila; único con un archivo
   funcional + conforme a política).

4. **Mejor auditor: qwen2.5-coder:32b** (9 detecciones), seguido de devstral (6).

5. **glm-4.7-flash: auditor inefectivo.** Detectó **0** pese a generar la mayor
   cantidad de tokens de salida (38k) — verboso pero sin hallazgos.

6. **deepseek-r1:32b (modelo de razonamiento): el peor caso práctico.** Generó
   código **no desplegable** (0/5 compila) y fue el auditor **más lento** (138 min,
   ~2.5× el resto) por sus largas cadenas de razonamiento. En este hardware no es
   rentable.

---

## Limitaciones (importante para la interpretación)

- **Muestra pequeña (N=5 por modelo).** Sirve para validar el pipeline y mostrar
  tendencias, no para conclusiones estadísticas. El pipeline es resumible: subir
  `NUM_SAMPLES` amplía la cobertura en próximas corridas.
- **Auto-auditoría.** El mismo modelo genera y audita; la capacidad de detección se
  mezcla con la "honestidad" del modelo sobre su propio código. Una matriz cruzada
  (auditor ≠ generador) daría una visión más limpia, pero es inviable en este
  hardware (días de cómputo).
- **Confianza no disponible.** Ollama no devuelve *logprobs*, así que el campo
  CONFIDENCE no es informativo (queda en 1.0 por defecto).
- **Hardware limitante.** Con 8 GB de VRAM los modelos corren en CPU; los tiempos
  reflejan eso, no la calidad de los modelos.

---

## Archivos de datos crudos

```
outputs/<modelo>/
├── terraform/question_000X.tf   código generado
├── iac_eval_results.json        resultado funcional (plan + OPA)
└── secllm_results.json          resultado de la auto-auditoría
outputs/REPORTE_COMPARATIVO.md   reporte resumen (auto-generado)
outputs/pipeline_log.txt         log con tiempos
```
