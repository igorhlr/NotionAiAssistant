#!/bin/bash
# Script de deploy para NotionIA com suporte a Docker Secrets

set -e

# Caminhos
APP_DIR="/home/user0/open-source-projects/NotionAiAssistant"
CONFIG_DIR="$APP_DIR/config"
SECRETS_DIR="$CONFIG_DIR/secrets"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Função para exibir mensagens
log() {
    echo -e "${GREEN}[DEPLOY]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[DEPLOY]${NC} $1"
}

error() {
    echo -e "${RED}[DEPLOY]${NC} $1"
    exit 1
}

# Banner inicial
log "==== Iniciando deployment automatizado com Docker Secrets ===="
log "Data e hora: $(date)"

# Verificar se o arquivo .env existe
if [ ! -f "/home/user0/docker-secrets/open-source-secrets/.env" ]; then
    error "Arquivo .env não encontrado. Crie o arquivo em /home/user0/docker-secrets/open-source-secrets/.env"
fi

# Limpando containers existentes
log "Limpando containers existentes..."
cd "$APP_DIR"
docker-compose down -v || true
log "✅ Containers removidos ou não existiam"

# Configurando diretórios
log "Configurando diretórios..."
mkdir -p "$APP_DIR/logs" "$SECRETS_DIR/production"
log "✅ Diretórios configurados"

# Backup do banco de dados
log "Tentando fazer backup do banco de dados..."
if docker ps -a | grep -q "notionia_postgres"; then
    backup_file="/home/user0/docker-data/notion-assistant/backups/backup_$(date +%Y%m%d%H%M%S).sql"
    docker exec notionia_postgres pg_dump -U notionai notionai_db > "$backup_file"
    log "✅ Backup do banco de dados realizado: $backup_file"
else
    warn "⚠️ Container PostgreSQL não encontrado, pulando backup"
fi

# Gerar Docker Secrets
log "Gerando Docker Secrets..."
bash "$SECRETS_DIR/create-docker-secrets.sh" production --force

# Verificar se todos os secrets necessários foram criados
required_secrets=(
    "postgres_password"
    "notioniauser_password"
    "appuser_password"
    "jwt_secret"
    "openai_api_key"
    "notion_api_key"
    "admin_password"
    "anthropic_api_key"
    "deepseek_api_key"
)

missing_secrets=0
for secret in "${required_secrets[@]}"; do
    if [ ! -f "$SECRETS_DIR/production/$secret" ]; then
        warn "⚠️ Secret não encontrado: $secret"
        missing_secrets=$((missing_secrets + 1))
    fi
done

if [ $missing_secrets -gt 0 ]; then
    error "Existem $missing_secrets secrets faltando. Verifique o arquivo .env e execute novamente."
fi

# Pull das imagens mais recentes (para dependências)
log "Atualizando imagens base..."
docker pull postgres:14-alpine

# Construir e iniciar containers
log "Construindo e iniciando containers..."
docker-compose up -d --build

# Verificar se os containers estão rodando
log "Verificando containers..."
sleep 10
if docker ps | grep -q "notionia_app" && docker ps | grep -q "notionia_postgres"; then
    log "✅ Aplicação iniciada com sucesso!"
else
    error "❌ Falha ao iniciar aplicação. Verifique os logs: docker-compose logs"
fi

log "✅ Deployment concluído com sucesso!"
