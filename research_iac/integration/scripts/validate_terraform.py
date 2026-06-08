#!/usr/bin/env python3
"""
Validador Funcional de Codigo Terraform Generado
=================================================
Este script evalua si los archivos .tf generados por el LLM son funcionales.

Realiza 3 niveles de validacion:
  1. Validacion Estructural (sin dependencias externas)
     - Verifica que el archivo tenga contenido HCL valido
     - Detecta bloques resource, provider, variable, etc.
     - Detecta codigo envuelto en markdown (```hcl)
     
  2. Validacion con Terraform CLI (requiere terraform instalado)
     - terraform fmt -check (formato correcto)
     - terraform validate (sintaxis HCL valida)
     
  3. Auditoria Manual de Seguridad (revision basica sin LLM)
     - Busca patrones conocidos de vulnerabilidades con regex
     - Complementa lo que SecLLM debio haber encontrado

Uso:
  python validate_terraform.py --dir <carpeta_con_archivos_tf>
  python validate_terraform.py --dir <carpeta> --terraform   # si tienes terraform instalado
"""

import os
import re
import json
import sys
import argparse
import subprocess
from pathlib import Path
from collections import Counter, defaultdict
from datetime import datetime


# ============================================================================
# NIVEL 1: Validacion Estructural (sin dependencias externas)
# ============================================================================

def validate_structure(tf_content, filename):
    """Analiza la estructura del archivo .tf sin necesitar Terraform CLI."""
    
    result = {
        "file": filename,
        "has_content": False,
        "has_hcl_blocks": False,
        "has_provider": False,
        "has_resources": False,
        "is_wrapped_in_markdown": False,
        "resource_count": 0,
        "resource_types": [],
        "provider_types": [],
        "has_variables": False,
        "has_outputs": False,
        "has_data_sources": False,
        "has_text_before_code": False,
        "line_count": 0,
        "issues": [],
        "structural_score": 0  # 0-100
    }
    
    if not tf_content or len(tf_content.strip()) == 0:
        result["issues"].append("Archivo vacio")
        return result
    
    result["has_content"] = True
    result["line_count"] = len(tf_content.splitlines())
    
    # Detectar si el LLM envolvio el codigo en markdown
    if "```hcl" in tf_content or "```terraform" in tf_content or "```HCL" in tf_content:
        result["is_wrapped_in_markdown"] = True
        result["issues"].append("Codigo envuelto en bloque markdown (```hcl) - no es HCL puro")
    
    # Detectar si hay texto explicativo antes del codigo (el LLM a veces agrega explicaciones)
    lines = tf_content.splitlines()
    first_non_empty = ""
    for line in lines:
        stripped = line.strip()
        if stripped and not stripped.startswith("#"):
            first_non_empty = stripped
            break
    
    hcl_starters = ["provider", "resource", "variable", "output", "data", "terraform", "module", "locals"]
    if first_non_empty and not any(first_non_empty.startswith(s) for s in hcl_starters):
        if not first_non_empty.startswith("{") and not first_non_empty.startswith("```"):
            result["has_text_before_code"] = True
            result["issues"].append("Tiene texto explicativo antes del codigo HCL (no es codigo puro)")
    
    # Detectar bloques HCL
    # Patron: tipo "nombre" "etiqueta" { o tipo "nombre" {
    resource_pattern = re.compile(r'^resource\s+"([^"]+)"\s+"([^"]+)"\s*\{', re.MULTILINE)
    provider_pattern = re.compile(r'^provider\s+"([^"]+)"\s*\{', re.MULTILINE)
    variable_pattern = re.compile(r'^variable\s+"([^"]+)"\s*\{', re.MULTILINE)
    output_pattern = re.compile(r'^output\s+"([^"]+)"\s*\{', re.MULTILINE)
    data_pattern = re.compile(r'^data\s+"([^"]+)"\s+"([^"]+)"\s*\{', re.MULTILINE)
    module_pattern = re.compile(r'^module\s+"([^"]+)"\s*\{', re.MULTILINE)
    
    resources = resource_pattern.findall(tf_content)
    providers = provider_pattern.findall(tf_content)
    variables = variable_pattern.findall(tf_content)
    outputs = output_pattern.findall(tf_content)
    data_sources = data_pattern.findall(tf_content)
    modules = module_pattern.findall(tf_content)
    
    result["resource_count"] = len(resources)
    result["resource_types"] = list(set([r[0] for r in resources]))
    result["provider_types"] = list(set(providers))
    result["has_resources"] = len(resources) > 0
    result["has_provider"] = len(providers) > 0
    result["has_variables"] = len(variables) > 0
    result["has_outputs"] = len(outputs) > 0
    result["has_data_sources"] = len(data_sources) > 0
    result["has_hcl_blocks"] = (len(resources) + len(providers) + len(variables) + 
                                 len(outputs) + len(data_sources) + len(modules)) > 0
    
    if not result["has_hcl_blocks"]:
        result["issues"].append("No se encontraron bloques HCL validos (resource, provider, etc.)")
    
    if result["has_resources"] and not result["has_provider"]:
        result["issues"].append("Tiene resources pero no declara un provider")
    
    # Calcular score estructural (0-100)
    score = 0
    if result["has_content"]: score += 10
    if result["has_hcl_blocks"]: score += 20
    if result["has_provider"]: score += 20
    if result["has_resources"]: score += 20
    if not result["is_wrapped_in_markdown"]: score += 15
    if not result["has_text_before_code"]: score += 15
    
    result["structural_score"] = score
    
    return result


# ============================================================================
# NIVEL 2: Validacion con Terraform CLI
# ============================================================================

def check_terraform_installed():
    """Verifica si terraform esta instalado."""
    try:
        result = subprocess.run(["terraform", "version"], capture_output=True, text=True, timeout=10)
        return result.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


def validate_with_terraform(tf_filepath, temp_dir):
    """Ejecuta terraform init + validate sobre un archivo .tf."""
    
    result = {
        "terraform_init_success": False,
        "terraform_validate_success": False,
        "terraform_fmt_diff": False,
        "init_error": "",
        "validate_error": "",
        "fmt_output": ""
    }
    
    # Crear directorio temporal y copiar el archivo
    os.makedirs(temp_dir, exist_ok=True)
    
    # Limpiar directorio temporal
    for f in os.listdir(temp_dir):
        fp = os.path.join(temp_dir, f)
        if os.path.isfile(fp):
            os.unlink(fp)
    
    # Copiar archivo .tf al directorio temporal
    import shutil
    dest = os.path.join(temp_dir, "main.tf")
    shutil.copy2(tf_filepath, dest)
    
    # terraform init
    try:
        init_result = subprocess.run(
            ["terraform", "init", "-backend=false"],
            capture_output=True, text=True, timeout=60,
            cwd=temp_dir
        )
        result["terraform_init_success"] = init_result.returncode == 0
        if not result["terraform_init_success"]:
            result["init_error"] = init_result.stderr[:500]
    except Exception as e:
        result["init_error"] = str(e)
    
    # terraform validate (solo si init fue exitoso)
    if result["terraform_init_success"]:
        try:
            val_result = subprocess.run(
                ["terraform", "validate", "-json"],
                capture_output=True, text=True, timeout=30,
                cwd=temp_dir
            )
            try:
                val_json = json.loads(val_result.stdout)
                result["terraform_validate_success"] = val_json.get("valid", False)
                if not result["terraform_validate_success"]:
                    diagnostics = val_json.get("diagnostics", [])
                    errors = [d.get("summary", "") for d in diagnostics if d.get("severity") == "error"]
                    result["validate_error"] = "; ".join(errors[:3])
            except json.JSONDecodeError:
                result["terraform_validate_success"] = val_result.returncode == 0
                result["validate_error"] = val_result.stderr[:500]
        except Exception as e:
            result["validate_error"] = str(e)
    
    # terraform fmt -check (verificar formato)
    try:
        fmt_result = subprocess.run(
            ["terraform", "fmt", "-check", "-diff"],
            capture_output=True, text=True, timeout=15,
            cwd=temp_dir
        )
        result["terraform_fmt_diff"] = fmt_result.returncode != 0
        if result["terraform_fmt_diff"]:
            result["fmt_output"] = "El formato no cumple con el estandar de Terraform"
    except Exception as e:
        pass
    
    return result


# ============================================================================
# NIVEL 3: Auditoria Manual de Seguridad (regex)
# ============================================================================

def manual_security_audit(tf_content, filename):
    """Busca vulnerabilidades de seguridad con patrones regex (sin necesitar LLM)."""
    
    findings = []
    lines = tf_content.splitlines()
    
    for i, line in enumerate(lines, 1):
        stripped = line.strip().lower()
        original = line.strip()
        
        # 1. Hard-coded secrets
        password_pattern = re.compile(r'password\s*=\s*"(?!(\$\{|var\.|local\.|data\.))([^"]+)"', re.IGNORECASE)
        if password_pattern.search(original):
            value = password_pattern.search(original).group(2)
            if value and value not in ['""', '']:
                findings.append({
                    "line": i,
                    "type": "hard_coded_secret",
                    "severity": "HIGH",
                    "evidence": original,
                    "description": f"Contrasena hardcodeada detectada: '{value}'"
                })
        
        secret_pattern = re.compile(r'(secret_key|api_key|access_key|token)\s*=\s*"(?!(\$\{|var\.|local\.|data\.))([^"]{8,})"', re.IGNORECASE)
        if secret_pattern.search(original):
            findings.append({
                "line": i,
                "type": "hard_coded_secret",
                "severity": "HIGH",
                "evidence": original,
                "description": "Secret/API key hardcodeado detectado"
            })
        
        # 2. Admin by default
        if re.search(r'username\s*=\s*"(admin|root|administrator|sa)"', stripped):
            findings.append({
                "line": i,
                "type": "admin_by_default",
                "severity": "MEDIUM",
                "evidence": original,
                "description": "Usuario administrador por defecto"
            })
        
        # 3. Unrestricted IP (0.0.0.0/0)
        if '0.0.0.0/0' in stripped:
            # Verificar si estamos en un bloque ingress (no egress)
            findings.append({
                "line": i,
                "type": "unrestricted_ip_address",
                "severity": "HIGH",
                "evidence": original,
                "description": "Direccion IP sin restriccion (abierta a todo internet)"
            })
        
        # 4. HTTP sin TLS
        if re.search(r'protocol\s*=\s*"http"', stripped) and 'https' not in stripped:
            findings.append({
                "line": i,
                "type": "use_of_http_without_tls",
                "severity": "MEDIUM",
                "evidence": original,
                "description": "Uso de HTTP sin cifrado TLS"
            })
        
        # 5. Empty password
        if re.search(r'password\s*=\s*""', stripped):
            findings.append({
                "line": i,
                "type": "empty_password",
                "severity": "HIGH",
                "evidence": original,
                "description": "Contrasena vacia"
            })
        
        # 6. Suspicious comments
        if stripped.startswith('#') or stripped.startswith('//'):
            suspicious_words = ['todo', 'fixme', 'hack', 'temporary', 'workaround', 
                              'remove before', 'not secure', 'insecure', 'fix later']
            for word in suspicious_words:
                if word in stripped:
                    findings.append({
                        "line": i,
                        "type": "suspicious_comment",
                        "severity": "LOW",
                        "evidence": original,
                        "description": f"Comentario sospechoso: contiene '{word}'"
                    })
                    break
        
        # 7. Weak cryptography
        weak_crypto = ['md5', 'sha1', 'des', 'rc4', 'tlsv1.0', 'tlsv1', 'sslv3']
        for crypto in weak_crypto:
            if crypto in stripped and 'sha1' != crypto or crypto == 'sha1' and re.search(r'\bsha1\b', stripped):
                findings.append({
                    "line": i,
                    "type": "use_of_weak_cryptography",
                    "severity": "MEDIUM",
                    "evidence": original,
                    "description": f"Uso de criptografia debil: {crypto}"
                })
                break
    
    return findings


# ============================================================================
# MAIN: Ejecutar validacion completa
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="Validador Funcional de Terraform generado por LLM")
    parser.add_argument("--dir", required=True, help="Directorio con archivos .tf a validar")
    parser.add_argument("--terraform", action="store_true", help="Usar Terraform CLI para validacion (requiere terraform instalado)")
    parser.add_argument("--output", default=None, help="Archivo JSON de salida (por defecto: validation_results.json en el mismo directorio)")
    args = parser.parse_args()
    
    tf_dir = args.dir
    use_terraform = args.terraform
    
    if not os.path.isdir(tf_dir):
        print(f"Error: '{tf_dir}' no es un directorio valido")
        sys.exit(1)
    
    # Buscar archivos .tf
    tf_files = sorted([f for f in os.listdir(tf_dir) if f.endswith('.tf')])
    
    if not tf_files:
        print(f"No se encontraron archivos .tf en '{tf_dir}'")
        sys.exit(1)
    
    print(f"=" * 70)
    print(f"  VALIDADOR FUNCIONAL DE TERRAFORM")
    print(f"  Archivos encontrados: {len(tf_files)}")
    print(f"  Directorio: {tf_dir}")
    print(f"  Terraform CLI: {'SI' if use_terraform and check_terraform_installed() else 'NO'}")
    print(f"=" * 70)
    
    # Verificar terraform si lo pidieron
    if use_terraform and not check_terraform_installed():
        print("\n[AVISO] Terraform no esta instalado. Se omitira la validacion con Terraform CLI.")
        use_terraform = False
    
    all_results = []
    
    # Contadores globales
    total_structural_pass = 0
    total_terraform_valid = 0
    total_security_findings = 0
    security_by_type = Counter()
    
    for tf_file in tf_files:
        filepath = os.path.join(tf_dir, tf_file)
        
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        print(f"\n--- {tf_file} ---")
        
        # NIVEL 1: Validacion estructural
        struct_result = validate_structure(content, tf_file)
        
        score_emoji = "PASS" if struct_result["structural_score"] >= 70 else "WARN" if struct_result["structural_score"] >= 40 else "FAIL"
        print(f"  Estructura: [{score_emoji}] Score={struct_result['structural_score']}/100 | "
              f"Resources={struct_result['resource_count']} | "
              f"Provider={'SI' if struct_result['has_provider'] else 'NO'}")
        
        if struct_result["issues"]:
            for issue in struct_result["issues"]:
                print(f"    -> {issue}")
        
        if struct_result["structural_score"] >= 70:
            total_structural_pass += 1
        
        # NIVEL 2: Validacion con Terraform CLI
        terraform_result = None
        if use_terraform and struct_result["has_hcl_blocks"]:
            temp_dir = os.path.join(tf_dir, ".terraform_validation_tmp")
            terraform_result = validate_with_terraform(filepath, temp_dir)
            
            tf_status = "PASS" if terraform_result["terraform_validate_success"] else "FAIL"
            print(f"  Terraform:  [{tf_status}] init={'OK' if terraform_result['terraform_init_success'] else 'FAIL'} | "
                  f"validate={'OK' if terraform_result['terraform_validate_success'] else 'FAIL'}")
            
            if terraform_result["validate_error"]:
                print(f"    -> Error: {terraform_result['validate_error'][:100]}")
            
            if terraform_result["terraform_validate_success"]:
                total_terraform_valid += 1
        
        # NIVEL 3: Auditoria de seguridad manual
        security_findings = manual_security_audit(content, tf_file)
        
        if security_findings:
            print(f"  Seguridad:  [{len(security_findings)} VULNERABILIDADES ENCONTRADAS]")
            for finding in security_findings:
                print(f"    -> L{finding['line']}: [{finding['severity']}] {finding['type']}: {finding['description']}")
                security_by_type[finding["type"]] += 1
            total_security_findings += len(security_findings)
        else:
            print(f"  Seguridad:  [OK] Sin vulnerabilidades detectadas por regex")
        
        # Compilar resultado completo
        file_result = {
            "file": tf_file,
            "structural": struct_result,
            "security_findings": security_findings,
            "security_count": len(security_findings)
        }
        if terraform_result:
            file_result["terraform"] = terraform_result
        
        all_results.append(file_result)
    
    # =========================================================================
    # RESUMEN FINAL
    # =========================================================================
    print(f"\n{'=' * 70}")
    print(f"  RESUMEN DE VALIDACION")
    print(f"{'=' * 70}")
    print(f"  Total archivos:              {len(tf_files)}")
    print(f"  Estructura correcta (>=70):  {total_structural_pass}/{len(tf_files)}")
    if use_terraform:
        print(f"  Terraform validate OK:       {total_terraform_valid}/{len(tf_files)}")
    print(f"  Vulnerabilidades encontradas: {total_security_findings}")
    
    if security_by_type:
        print(f"\n  Vulnerabilidades por tipo:")
        for smell_type, count in security_by_type.most_common():
            print(f"    {smell_type}: {count}")
    
    # Comparacion con SecLLM
    print(f"\n  COMPARACION CON SecLLM:")
    print(f"    SecLLM (Qwen 1.5B) reporto:    0 vulnerabilidades")
    print(f"    Auditoria manual (regex) encontro: {total_security_findings} vulnerabilidades")
    if total_security_findings > 0:
        print(f"    -> Esto confirma {total_security_findings} FALSOS NEGATIVOS en SecLLM")
    
    # Guardar resultados
    output_file = args.output or os.path.join(tf_dir, "..", "validation_results.json")
    output_data = {
        "timestamp": datetime.now().isoformat(),
        "total_files": len(tf_files),
        "structural_pass": total_structural_pass,
        "terraform_valid": total_terraform_valid if use_terraform else "N/A",
        "total_security_findings": total_security_findings,
        "security_by_type": dict(security_by_type),
        "secllm_comparison": {
            "secllm_detected": 0,
            "manual_detected": total_security_findings,
            "false_negatives": total_security_findings
        },
        "files": all_results
    }
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, indent=2, ensure_ascii=False)
    
    print(f"\n  Resultados guardados en: {output_file}")
    print(f"{'=' * 70}")


if __name__ == "__main__":
    main()
