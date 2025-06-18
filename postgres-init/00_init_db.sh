#!/bin/bash
# Script de inicialização para PostgreSQL - Ambiente de Desenvolvimento
# Este script é executado automaticamente pelo PostgreSQL durante a inicialização do container

set -e

# Função para logging
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "🚀 Iniciando script de configuração do PostgreSQL para ambiente de desenvolvimento"

# Verificar se estamos rodando como postgres
if [ "$(whoami)" != "postgres" ]; then
  log "⚠️  Este script deve ser executado como usuário postgres!"
  exit 1
fi

# Função para verificar se um usuário existe
user_exists() {
  psql -t -c "SELECT 1 FROM pg_roles WHERE rolname='$1'" | grep -q 1
}

# Carregar senhas dos secrets
if [ -f "/run/secrets/postgres_password" ]; then
  POSTGRES_PASSWORD=$(cat /run/secrets/postgres_password)
  log "✅ Senha do PostgreSQL carregada do secret"
else
  log "⚠️  Secret postgres_password não encontrado!"
  POSTGRES_PASSWORD="dev_pg_password"
fi

if [ -f "/run/secrets/notioniauser_password" ]; then
  NOTIONIAUSER_PASSWORD=$(cat /run/secrets/notioniauser_password)
  log "✅ Senha do notioniauser carregada do secret"
else
  log "⚠️  Secret notioniauser_password não encontrado!"
  NOTIONIAUSER_PASSWORD="dev_notioniauser_password"
fi

if [ -f "/run/secrets/appuser_password" ]; then
  APPUSER_PASSWORD=$(cat /run/secrets/appuser_password)
  log "✅ Senha do appuser carregada do secret"
else
  log "⚠️  Secret appuser_password não encontrado!"
  APPUSER_PASSWORD="dev_appuser_password"
fi

# Atualizar método de autenticação
log "🔒 Definindo método de autenticação para MD5"
psql -c "ALTER SYSTEM SET password_encryption = 'md5';"
psql -c "SELECT pg_reload_conf();"

# Verificar se o banco notionai_dev existe
DB_EXISTS=$(psql -tAc "SELECT 1 FROM pg_database WHERE datname='notionai_dev'")
if [ "$DB_EXISTS" != "1" ]; then
  log "🔧 Criando banco de dados notionai_dev"
  psql -c "CREATE DATABASE notionai_dev;"
else
  log "✅ Banco de dados notionai_dev já existe"
fi

# Acessar o banco para configurações adicionais
psql -d notionai_dev -c "
-- Criar usuário pguser_dev se não existir
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='pguser_dev') THEN
    CREATE USER pguser_dev WITH PASSWORD '$POSTGRES_PASSWORD' SUPERUSER;
  ELSE
    ALTER USER pguser_dev WITH PASSWORD '$POSTGRES_PASSWORD' SUPERUSER;
  END IF;
END
\$\$;

-- Criar usuário notioniauser se não existir
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='notioniauser') THEN
    CREATE USER notioniauser WITH PASSWORD '$NOTIONIAUSER_PASSWORD' CREATEDB NOSUPERUSER;
  ELSE
    ALTER USER notioniauser WITH PASSWORD '$NOTIONIAUSER_PASSWORD' CREATEDB NOSUPERUSER;
  END IF;
END
\$\$;

-- Criar usuário appuser se não existir
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='appuser') THEN
    CREATE USER appuser WITH PASSWORD '$APPUSER_PASSWORD' NOSUPERUSER NOCREATEDB;
  ELSE
    ALTER USER appuser WITH PASSWORD '$APPUSER_PASSWORD' NOSUPERUSER NOCREATEDB;
  END IF;
END
\$\$;

-- Conceder privilégios
GRANT ALL PRIVILEGES ON DATABASE notionai_dev TO pguser_dev;
GRANT ALL PRIVILEGES ON DATABASE notionai_dev TO notioniauser;
GRANT CONNECT ON DATABASE notionai_dev TO appuser;

-- Criar esquema se não existir
CREATE SCHEMA IF NOT EXISTS app;

-- Definir permissões no esquema
GRANT ALL ON SCHEMA app TO pguser_dev;
GRANT ALL ON SCHEMA app TO notioniauser;
GRANT USAGE ON SCHEMA app TO appuser;

-- Permissões nas tabelas atuais e futuras
ALTER DEFAULT PRIVILEGES FOR USER pguser_dev IN SCHEMA app
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO appuser;
ALTER DEFAULT PRIVILEGES FOR USER notioniauser IN SCHEMA app
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO appuser;

-- Permissões em sequências
ALTER DEFAULT PRIVILEGES FOR USER pguser_dev IN SCHEMA app
  GRANT USAGE, SELECT ON SEQUENCES TO appuser;
ALTER DEFAULT PRIVILEGES FOR USER notioniauser IN SCHEMA app
  GRANT USAGE, SELECT ON SEQUENCES TO appuser;

-- Definir esquema de busca padrão
ALTER USER pguser_dev SET search_path TO app, public;
ALTER USER notioniauser SET search_path TO app, public;
ALTER USER appuser SET search_path TO app, public;
"

log "✅ Usuários e permissões configurados com sucesso!"
log "✅ Configuração do PostgreSQL concluída"

# Configurar credenciais de administrador
psql -d notionai_dev -c "
-- Configurar pguser_dev como proprietário de tabelas e objetos existentes
DO \$\$
DECLARE
  tbl_name text;
  seq_name text;
BEGIN
  -- Tabelas
  FOR tbl_name IN (SELECT tablename FROM pg_tables WHERE schemaname = 'app')
  LOOP
    EXECUTE 'ALTER TABLE app.' || quote_ident(tbl_name) || ' OWNER TO pguser_dev';
  END LOOP;
  
  -- Sequências
  FOR seq_name IN (SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = 'app')
  LOOP
    EXECUTE 'ALTER SEQUENCE app.' || quote_ident(seq_name) || ' OWNER TO pguser_dev';
  END LOOP;
END
\$\$;
"

log "👤 Permissões de administrador configuradas"
log "🎉 Inicialização do PostgreSQL concluída com sucesso!"