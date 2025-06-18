#!/bin/bash
set -e

# Função para logging
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Iniciando script wait-for-postgres.sh"
log "Aguardando PostgreSQL ficar disponível..."

# Usar variáveis de ambiente configuradas no docker-compose
POSTGRES_USER=${POSTGRES_USER:-pguser_dev}
POSTGRES_DB=${POSTGRES_DB:-notionai_dev}
POSTGRES_HOST=${POSTGRES_HOST:-db}
POSTGRES_PORT=${POSTGRES_PORT:-5432}

log "Configuração do PostgreSQL:"
log "  Host: $POSTGRES_HOST"
log "  Porta: $POSTGRES_PORT"
log "  Usuário: $POSTGRES_USER"
log "  Banco: $POSTGRES_DB"

# Contador para tentativas
attempt=1
max_attempts=30

# Função para tentar ler secret
read_secret() {
  local secret_name="$1"
  local default_value="$2"
  
  if [ -f "/run/secrets/$secret_name" ]; then
    cat "/run/secrets/$secret_name"
  else
    echo "$default_value"
  fi
}

# Carregar senhas diretamente
export POSTGRES_PASSWORD=$(read_secret "postgres_password" "dev_pg_password")
export JWT_SECRET=$(read_secret "jwt_secret" "dev_jwt_secret_for_local_testing_only")
export ADMIN_PASSWORD=$(read_secret "admin_password" "dev_admin_password")

# Loop até o PostgreSQL estar disponível
until pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -q; do
  if [ $attempt -ge $max_attempts ]; then
    log "ERRO: Tempo máximo de espera pelo PostgreSQL excedido após $max_attempts tentativas!"
    log "Continuando mesmo assim, mas pode haver problemas de conexão..."
    break
  fi
  
  log "Tentativa $attempt de $max_attempts: PostgreSQL ainda não está pronto. Aguardando..."
  sleep 2
  attempt=$((attempt + 1))
done

if [ $attempt -lt $max_attempts ]; then
  log "PostgreSQL está pronto após $attempt tentativas!"
fi

# Verificar permissões do diretório de secrets
if [ -d "/run/secrets" ]; then
  log "Diretório de secrets encontrado em /run/secrets"
  ls -la /run/secrets || log "Não foi possível listar os secrets"
  
  # Verificar se os segredos existem e imprimir os primeiros 3 caracteres
  for secret in postgres_password jwt_secret admin_password; do
    if [ -f "/run/secrets/$secret" ]; then
      value=$(cat "/run/secrets/$secret")
      masked="${value:0:3}***"
      log "Secret $secret encontrado: $masked"
    else
      log "Secret $secret não encontrado"
    fi
  done
fi

# Exibir variáveis de ambiente (ocultando valores sensíveis)
log "Variáveis de ambiente configuradas:"
log "  POSTGRES_USER: $POSTGRES_USER"
log "  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:0:3}***"
log "  POSTGRES_DB: $POSTGRES_DB"
log "  POSTGRES_HOST: $POSTGRES_HOST"
log "  POSTGRES_PORT: $POSTGRES_PORT"

# Exportar DATABASE_URL explicitamente
export DATABASE_URL="postgresql+asyncpg://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
log "DATABASE_URL construída: postgresql+asyncpg://${POSTGRES_USER}:***@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"

# Exibir variáveis da aplicação
log "Variáveis da aplicação:"
log "  ENVIRONMENT: $ENVIRONMENT"
log "  DEBUG: $DEBUG"
log "  LOG_LEVEL: $LOG_LEVEL"

# Teste de conexão simplificado (apenas verificar se o PostgreSQL responde)
log "Testando conectividade com PostgreSQL..."
if pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -q; then
  log "PostgreSQL está respondendo corretamente!"
else
  log "AVISO: PostgreSQL não está respondendo conforme esperado, mas continuando..."
fi

log "Configuração finalizada. Executando comando: $@"
exec "$@"