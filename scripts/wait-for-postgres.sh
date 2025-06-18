#!/bin/bash
# wait-for-postgres.sh - Script de espera e configuração do PostgreSQL
# Versão: 1.0.0
# Data: 2025-06-04
# Descrição: Aguarda o PostgreSQL ficar disponível e configura usuários/banco se necessário

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Função de log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} ⚠️  $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} ❌ $1"
}

# Variáveis de ambiente com valores padrão
POSTGRES_HOST=${POSTGRES_HOST}
POSTGRES_PORT=${POSTGRES_PORT}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=${POSTGRES_DB}

# Variáveis para usuários da aplicação
NOTIONIAUSER_PASSWORD=${NOTIONIAUSER_PASSWORD}
APPUSER_PASSWORD=${APPUSER_PASSWORD}

# Extrair informações do DATABASE_URL se disponível
if [ ! -z "$DATABASE_URL" ]; then
    # Parse DATABASE_URL: postgresql+asyncpg://user:pass@host:port/dbname
    DB_USER=$(echo $DATABASE_URL | sed -n 's/.*:\/\/\([^:]*\):.*/\1/p')
    DB_PASS=$(echo $DATABASE_URL | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p')
    DB_HOST=$(echo $DATABASE_URL | sed -n 's/.*@\([^:]*\):.*/\1/p')
    DB_PORT=$(echo $DATABASE_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
    DB_NAME=$(echo $DATABASE_URL | sed -n 's/.*\/\([^?]*\).*/\1/p')
    
    # Usar valores do DATABASE_URL se disponíveis
    POSTGRES_HOST=${DB_HOST:-$POSTGRES_HOST}
    POSTGRES_PORT=${DB_PORT:-$POSTGRES_PORT}
    POSTGRES_DB=${DB_NAME:-$POSTGRES_DB}
    
    log "DATABASE_URL detectado. Usando configurações extraídas."
fi

log "🚀 Iniciando wait-for-postgres.sh"
log "📍 Host: $POSTGRES_HOST:$POSTGRES_PORT"
log "👤 Usuário: $POSTGRES_USER"
log "📊 Banco: $POSTGRES_DB"

# Aguardar PostgreSQL ficar disponível
log "⏳ Aguardando PostgreSQL ficar disponível..."
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" >/dev/null 2>&1; then
        log "✅ PostgreSQL está pronto!"
        break
    fi
    
    attempt=$((attempt + 1))
    log_warn "PostgreSQL não está pronto ainda... (tentativa $attempt/$max_attempts)"
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    log_error "PostgreSQL não ficou disponível após $max_attempts tentativas!"
    exit 1
fi

# Função para executar comandos SQL
execute_sql() {
    local sql="$1"
    local db="${2:-postgres}"
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$db" -c "$sql" 2>&1
}

# Função para verificar se um usuário existe
user_exists() {
    local username="$1"
    local result=$(execute_sql "SELECT 1 FROM pg_roles WHERE rolname='$username';")
    echo "$result" | grep -q "(1 row)"
}

# Função para verificar se um banco existe
database_exists() {
    local dbname="$1"
    local result=$(execute_sql "SELECT 1 FROM pg_database WHERE datname='$dbname';")
    echo "$result" | grep -q "(1 row)"
}

# Verificar conexão inicial
log "🔍 Verificando conexão com PostgreSQL..."
if ! execute_sql "SELECT 1;" >/dev/null; then
    log_error "Não foi possível conectar ao PostgreSQL com o usuário $POSTGRES_USER"
    exit 1
fi
log "✅ Conexão estabelecida com sucesso!"

# Criar usuário notioniauser se não existir
if user_exists "notioniauser"; then
    log "✅ Usuário 'notioniauser' já existe"
else
    log "📝 Criando usuário 'notioniauser'..."
    if execute_sql "CREATE ROLE notioniauser WITH LOGIN PASSWORD '$NOTIONIAUSER_PASSWORD' CREATEDB;" >/dev/null; then
        log "✅ Usuário 'notioniauser' criado com sucesso!"
    else
        log_error "Falha ao criar usuário 'notioniauser'"
    fi
fi

# Criar usuário appuser se não existir
if user_exists "appuser"; then
    log "✅ Usuário 'appuser' já existe"
else
    log "📝 Criando usuário 'appuser'..."
    if execute_sql "CREATE ROLE appuser WITH LOGIN PASSWORD '$APPUSER_PASSWORD' CREATEDB;" >/dev/null; then
        log "✅ Usuário 'appuser' criado com sucesso!"
    else
        log_error "Falha ao criar usuário 'appuser'"
    fi
fi

# Criar banco de dados se não existir
if database_exists "$POSTGRES_DB"; then
    log "✅ Banco de dados '$POSTGRES_DB' já existe"
else
    log "📝 Criando banco de dados '$POSTGRES_DB'..."
    if execute_sql "CREATE DATABASE $POSTGRES_DB WITH OWNER notioniauser;" >/dev/null; then
        log "✅ Banco de dados '$POSTGRES_DB' criado com sucesso!"
    else
        log_error "Falha ao criar banco de dados '$POSTGRES_DB'"
    fi
fi

# Configurar permissões
log "🔐 Configurando permissões..."
execute_sql "GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO notioniauser;" >/dev/null
execute_sql "GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO appuser;" >/dev/null

# Conectar ao banco específico para configurar permissões de schema
execute_sql "GRANT ALL ON SCHEMA public TO notioniauser;" "$POSTGRES_DB" >/dev/null
execute_sql "GRANT ALL ON SCHEMA public TO appuser;" "$POSTGRES_DB" >/dev/null

# Configurar privilégios padrão
execute_sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO notioniauser;" "$POSTGRES_DB" >/dev/null
execute_sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO notioniauser;" "$POSTGRES_DB" >/dev/null
execute_sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO notioniauser;" "$POSTGRES_DB" >/dev/null

log "✅ Permissões configuradas com sucesso!"

# Criar extensões úteis se não existirem
log "🔧 Configurando extensões PostgreSQL..."
execute_sql "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";" "$POSTGRES_DB" >/dev/null
execute_sql "CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";" "$POSTGRES_DB" >/dev/null
log "✅ Extensões configuradas!"

# Verificar se a aplicação deve usar um usuário específico
if [ ! -z "$DB_USER" ] && [ "$DB_USER" != "$POSTGRES_USER" ]; then
    log_warn "DATABASE_URL especifica usuário '$DB_USER', verificando..."
    if ! user_exists "$DB_USER"; then
        log_error "Usuário '$DB_USER' especificado no DATABASE_URL não existe!"
        log "Criando usuário '$DB_USER'..."
        execute_sql "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS' CREATEDB;" >/dev/null
        execute_sql "GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $DB_USER;" >/dev/null
    fi
fi

log "🎉 Configuração do PostgreSQL concluída com sucesso!"
log "🚀 Iniciando aplicação..."

# Executar o comando original
exec "$@"