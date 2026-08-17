#!/usr/bin/env bash
# setup_experimento_v3.sh — Turno B del Experimento v3
# CachyOS / Arch Linux
# Uso: bash setup_experimento_v3.sh
#
# Lo que hace:
#   1. Instala Terraform (via yay)
#   2. Instala OPA binary desde GitHub
#   3. Instala Ollama e inicia el servidor
#   4. Descarga los 4 modelos del experimento + crea el auditor custom
#   5. Lanza pipeline_v3.py con shard_B.json (es resumible)
# ────────────────────────────────────────────────────────────────────
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC}  $*"; }
fail() { echo -e "${RED}✗${NC} $*"; exit 1; }
step() {
  echo ""
  echo -e "${YELLOW}══════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}  $*${NC}"
  echo -e "${YELLOW}══════════════════════════════════════════════${NC}"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESEARCH_DIR="$SCRIPT_DIR/research_iac"
INTEGRATION_DIR="$RESEARCH_DIR/integration"

# ─────────────────────────────────────────────
# 1. TERRAFORM
# ─────────────────────────────────────────────
step "1/4 — Terraform"
if command -v terraform &>/dev/null; then
  ok "Terraform ya instalado: $(terraform version | head -1)"
else
  echo "Instalando terraform via yay..."
  yay -S --noconfirm terraform
  ok "Terraform instalado: $(terraform version | head -1)"
fi

# ─────────────────────────────────────────────
# 2. OPA (Open Policy Agent)
# ─────────────────────────────────────────────
step "2/4 — OPA (Open Policy Agent)"
if command -v opa &>/dev/null; then
  ok "OPA ya instalado: $(opa version | head -1)"
else
  echo "Descargando OPA v1.4.2 desde GitHub releases..."
  curl -sL "https://github.com/open-policy-agent/opa/releases/download/v1.4.2/opa_linux_amd64_static" \
    -o /tmp/opa
  chmod +x /tmp/opa
  sudo mv /tmp/opa /usr/local/bin/opa
  ok "OPA instalado: $(opa version | head -1)"
fi

# ─────────────────────────────────────────────
# 3. OLLAMA
# ─────────────────────────────────────────────
step "3/4 — Ollama"
if command -v ollama &>/dev/null; then
  ok "Ollama ya instalado: $(ollama --version)"
else
  echo "Instalando Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh
  ok "Ollama instalado"
fi

# Iniciar servidor ollama si no está corriendo
if curl -s http://localhost:11434/api/tags &>/dev/null; then
  ok "Ollama server ya está corriendo"
else
  echo "Iniciando ollama serve en background..."
  nohup ollama serve > /tmp/ollama_serve.log 2>&1 &
  OLLAMA_PID=$!
  echo "  PID: $OLLAMA_PID — log: /tmp/ollama_serve.log"
  sleep 5
  if curl -s http://localhost:11434/api/tags &>/dev/null; then
    ok "Ollama server iniciado (PID=$OLLAMA_PID)"
  else
    fail "No se pudo iniciar ollama serve. Revisar /tmp/ollama_serve.log"
  fi
fi

# ─────────────────────────────────────────────
# 4. MODELOS
# ─────────────────────────────────────────────
step "4/4 — Modelos LLM"

# Los 4 modelos generadores del experimento
for model in "codegemma:7b" "codellama:7b" "granite-code:8b" "llama3.1:8b"; do
  slug="${model%%:*}"
  if ollama list 2>/dev/null | grep -q "^$slug"; then
    ok "$model ya disponible"
  else
    echo "Descargando $model..."
    ollama pull "$model"
    ok "$model descargado"
  fi
done

# Auditor: el log de la corrida anterior confirmó "qwen25-coder-audit"
# basado en codellama:7b (Modelfile.audit: FROM codellama:7b, num_ctx 6144, temp 0)
MODELFILE_AUDIT="$RESEARCH_DIR/Modelfile.audit"
AUDITOR_NAME="qwen25-coder-audit"

if ollama list 2>/dev/null | grep -q "^$AUDITOR_NAME"; then
  ok "Auditor '$AUDITOR_NAME' ya disponible"
else
  echo "Creando modelo auditor '$AUDITOR_NAME' desde $MODELFILE_AUDIT..."
  if [ ! -f "$MODELFILE_AUDIT" ]; then
    fail "No se encontró $MODELFILE_AUDIT"
  fi
  # La base ya está descargada (codellama:7b), crear el custom
  ollama create "$AUDITOR_NAME" -f "$MODELFILE_AUDIT"
  ok "Auditor '$AUDITOR_NAME' creado"
fi

# ─────────────────────────────────────────────
# VERIFICACIÓN FINAL
# ─────────────────────────────────────────────
step "VERIFICACIÓN DE DEPENDENCIAS"
echo ""
ALL_OK=true

check() {
  local name="$1" cmd="$2"
  if eval "$cmd" &>/dev/null; then
    printf "  ${GREEN}✓${NC} %-22s %s\n" "$name:" "$(eval "$cmd" 2>/dev/null | head -1)"
  else
    printf "  ${RED}✗${NC} %-22s NO DISPONIBLE\n" "$name:"
    ALL_OK=false
  fi
}

check "terraform"    "terraform version"
check "opa"          "opa version"
check "ollama"       "ollama --version"
check "ollama server" "curl -s http://localhost:11434/api/tags && echo 'OK'"

echo ""
echo "Modelos disponibles:"
ollama list 2>/dev/null | sed 's/^/  /' || echo "  (ollama no responde)"

if [ "$ALL_OK" = false ]; then
  fail "Hay dependencias faltantes. Revisa los errores arriba."
fi

# ─────────────────────────────────────────────
# LANZAR EL PIPELINE
# ─────────────────────────────────────────────
step "LANZANDO PIPELINE v3 — Turno B (30 escenarios)"
echo ""
echo "  Shard:     shard_B.json"
echo "  Auditor:   $AUDITOR_NAME  (codellama:7b, num_ctx=6144, temp=0)"
echo "  Modelos:   codegemma:7b · codellama:7b · granite-code:8b · llama3.1:8b"
echo "  Celdas:    4 modelos × 2 condiciones (P0/P1) = 8"
echo ""
echo "  Ya procesados (11/30): 18 20 51 153 186 215 231 289 336 342 422"
echo "  Pendientes   (19/30): 25 48 88 111 121 154 156 170 197 205 221"
echo "                         292 341 345 364 390 420 423 429"
echo ""
echo "  El pipeline es RESUMIBLE — si se corta, vuelve a lanzar este script."
echo "  Estimado restante: ~3.6h (19 escenarios × 8 celdas × ~34s/auditoría)"
echo ""

cd "$INTEGRATION_DIR"

# Activar virtualenv del proyecto si existe
if [ -f "$SCRIPT_DIR/.venv/bin/activate" ]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/.venv/bin/activate"
  ok "Virtualenv activado: $SCRIPT_DIR/.venv"
fi

# Configurar paralelismo del auditor (medido: 8 hilos = 1.4x speedup)
export OLLAMA_NUM_PARALLEL=8

echo ""
echo "Lanzando pipeline..."
echo "Output también en: outputs_v3/pipeline_v3_log.txt"
echo ""

python scripts/pipeline_v3.py \
  --indices-file outputs_v3/shards/shard_B.json \
  --repair-rounds 1 \
  --no-seed-from-v2 \
  --auditor "$AUDITOR_NAME" \
  2>&1 | tee -a outputs_v3/pipeline_v3_log.txt
