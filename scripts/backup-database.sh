#!/bin/bash
# Script para backup do banco de dados
# Realiza backup do PostgreSQL de forma segura

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log() {
    echo -e "${BLUE}[BACKUP]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

success() {
    echo -e "${GREEN}[SUCESSO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1"
    exit 1
}

# Verificar argumentos
ENVIRONMENT=${1:-"production"}
if [[ "$ENVIRONMENT" != "production" && "$ENVIRONMENT" != "development" ]]; then
    error "Ambiente inválido. Use 'production' ou 'development'"
fi

log "📦 Iniciando backup do banco de dados para ambiente: $ENVIRONMENT"

# Verificar diretório do projeto
if [ ! -f "docker-compose.yml" ]; then
    error "Execute este script a partir da raiz do projeto NotionAiAssistant"
fi

# Determinar qual arquivo docker-compose usar
COMPOSE_FILE="docker-compose.yml"
CONTAINER_NAME="notionia_postgres"
if [ "$ENVIRONMENT" == "development" ]; then
    COMPOSE_FILE="docker-compose.dev.yml"
    CONTAINER_NAME="notionia_postgres_dev"
fi

# Verificar se o container do banco está rodando
log "🔍 Verificando status do banco de dados..."
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    error "Container do banco de dados não está rodando"
fi

# Obter informações do banco de dados
log "🔍 Obtendo informações do banco de dados..."
if [ "$ENVIRONMENT" == "development" ]; then
    # Para desenvolvimento, pegar do arquivo de compose
    DB_USER=$(grep -A 10 'POSTGRES_USER' docker-compose.dev.yml | head -n1 | sed 's/.*POSTGRES_USER: *//' | tr -d '\r')
    DB_NAME=$(grep -A 10 'POSTGRES_DB' docker-compose.dev.yml | head -n1 | sed 's/.*POSTGRES_DB: *//' | tr -d '\r')
else
    # Para produção, pegar das variáveis de ambiente
    source /home/user0/docker-secrets/open-source-secrets/.env
    DB_USER=$POSTGRES_USER
    DB_NAME=$POSTGRES_DB
fi

# Criar diretório de backup se não existir
BACKUP_DIR="/Users/user0/Documents/VPS/home/user0/docker-data/notion-assistant/backups"
BACKUP_FILE="$BACKUP_DIR/backup_${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql"

log "📂 Diretório de backup: $BACKUP_DIR"
log "📄 Arquivo de backup: $(basename "$BACKUP_FILE")"

mkdir -p "$BACKUP_DIR"

# Realizar o backup
log "💾 Executando backup do banco de dados $DB_NAME..."
if ! docker exec -t "$CONTAINER_NAME" pg_dump -U "$DB_USER" -d "$DB_NAME" -F p > "$BACKUP_FILE"; then
    error "Falha ao executar backup do banco de dados"
fi

# Comprimir o backup
log "🗜️ Comprimindo backup..."
gzip "$BACKUP_FILE"
BACKUP_FILE="${BACKUP_FILE}.gz"

# Verificar se o backup foi criado
if [ -f "$BACKUP_FILE" ]; then
    # Obter tamanho do backup
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    success "Backup concluído com sucesso!"
    log "📊 Detalhes do backup:"
    log "   📄 Arquivo: $(basename "$BACKUP_FILE")"
    log "   📦 Tamanho: $BACKUP_SIZE"
    log "   📅 Data: $(date)"
    log "   🔐 Banco: $DB_NAME"
else
    error "Backup não foi criado corretamente"
fi

# Política de retenção de backups (manter apenas os últimos 7 para desenvolvimento, 30 para produção)
RETENTION_DAYS=30
if [ "$ENVIRONMENT" == "development" ]; then
    RETENTION_DAYS=7
fi

log "🧹 Aplicando política de retenção de backups (manter últimos $RETENTION_DAYS dias)..."
find "$BACKUP_DIR" -name "backup_${DB_NAME}_*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete
success "Política de retenção aplicada. Backups com mais de $RETENTION_DAYS dias foram removidos."

# Registrar backup no log
log "📝 Registrando backup no log..."
{
    echo "# Backup do Banco de Dados"
    echo "Data: $(date)"
    echo "Ambiente: $ENVIRONMENT"
    echo "Banco: $DB_NAME"
    echo "Arquivo: $(basename "$BACKUP_FILE")"
    echo "Tamanho: $BACKUP_SIZE"
    echo "---"
} >> ./logs/database-backups.log

success "🎉 Backup do banco de dados concluído com sucesso!"
