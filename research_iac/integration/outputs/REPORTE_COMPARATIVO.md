# Reporte Comparativo - Pipeline IaC-Eval + SecLLM

_Generado automaticamente. Cada modelo genera su propio Terraform, se evalua funcionalmente (terraform plan + OPA) y se AUTO-audita con SecLLM._


## 1. Evaluacion funcional (IaC-Eval)

| Modelo                  |   Archivos | Compila (plan)   | Pasa politica (OPA)   |
|:------------------------|-----------:|:-----------------|:----------------------|
| deepseek-r1_32b         |          5 | 0/5 (0%)         | 0/5 (0%)              |
| devstral-small-2_latest |         45 | 18/45 (40%)      | 4/45 (9%)             |
| glm-4_7-flash_q8_0      |          5 | 2/5 (40%)        | 0/5 (0%)              |
| qwen2_5-coder_32b       |          5 | 2/5 (40%)        | 0/5 (0%)              |


## 2. Auto-auditoria de seguridad (SecLLM)

_¿Encuentra cada modelo vulnerabilidades en el codigo que el mismo genero?_

| Modelo                  |   Archivos auditados |   Vulnerabilidades | Detalle                                                                                                                                           |
|:------------------------|---------------------:|-------------------:|:--------------------------------------------------------------------------------------------------------------------------------------------------|
| deepseek-r1_32b         |                    5 |                  4 | suspicious_comment: 2, unrestricted_ip_address: 2                                                                                                 |
| devstral-small-2_latest |                   45 |                 47 | admin_by_default: 16, hard_coded_secret: 15, no_integrity_check: 1, suspicious_comment: 9, unrestricted_ip_address: 2, use_of_http_without_tls: 4 |
| glm-4_7-flash_q8_0      |                    5 |                  0 | 0 (el modelo reporto todo limpio)                                                                                                                 |
| qwen2_5-coder_32b       |                    5 |                  9 | admin_by_default: 4, hard_coded_secret: 4, unrestricted_ip_address: 1                                                                             |

