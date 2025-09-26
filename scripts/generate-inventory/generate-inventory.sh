#!/bin/bash

set -e

ENV_DIR="$(dirname "$0")"
ENV_FILE="$ENV_DIR/.env"
ENV_EXAMPLE_FILE="$ENV_DIR/.env.example"

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TEMPLATE_FILE="$PROJECT_ROOT/ansible/inventories/inventory.template"
OUTPUT_FILE="$PROJECT_ROOT/ansible/inventories/inventory.ini"

# Verifica se o .env existe; se não, sugere copiar o exemplo
if [ ! -f "$ENV_FILE" ]; then
  echo "[✗] Arquivo .env não encontrado em $ENV_FILE"
  echo "→ Você pode criar um com base em:"
  echo "  cp $ENV_EXAMPLE_FILE $ENV_FILE"
  exit 1
fi

source "$ENV_FILE"

# Verifica se variáveis obrigatórias estão definidas
REQUIRED_VARS=(ANSIBLE_GROUP ANSIBLE_HOST ANSIBLE_USER ANSIBLE_SSH_KEY ANSIBLE_REMOTE_TMP)

for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "[✗] Variável $var não está definida no .env"
    exit 1
  fi
done

# Verifica se template existe
if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "[✗] Arquivo de template $TEMPLATE_FILE não encontrado."
  exit 1
fi

# Sanitize variáveis para evitar quebras de linha ou espaços extras
ANSIBLE_GROUP=$(echo "$ANSIBLE_GROUP" | tr -d '\r' | tr -d '\n' | xargs)
ANSIBLE_HOST=$(echo "$ANSIBLE_HOST" | tr -d '\r' | tr -d '\n' | xargs)
ANSIBLE_USER=$(echo "$ANSIBLE_USER" | tr -d '\r' | tr -d '\n' | xargs)
ANSIBLE_SSH_KEY=$(echo "$ANSIBLE_SSH_KEY" | tr -d '\r' | tr -d '\n' | xargs)
ANSIBLE_REMOTE_TMP=$(echo "$ANSIBLE_REMOTE_TMP" | tr -d '\r' | tr -d '\n' | xargs)

# Substitui as variáveis no template e gera o arquivo de inventário
sed \
  -e "s|{{ANSIBLE_GROUP}}|$ANSIBLE_GROUP|g" \
  -e "s|{{ANSIBLE_HOST}}|$ANSIBLE_HOST|g" \
  -e "s|{{ANSIBLE_USER}}|$ANSIBLE_USER|g" \
  -e "s|{{ANSIBLE_SSH_KEY}}|$ANSIBLE_SSH_KEY|g" \
  -e "s|{{ANSIBLE_REMOTE_TMP}}|$ANSIBLE_REMOTE_TMP|g" \
  "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "[✓] Inventory gerado com sucesso em: $OUTPUT_FILE"
cat "$OUTPUT_FILE"
