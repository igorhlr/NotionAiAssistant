#!/bin/bash
set -e

# Script de inicialização do PostgreSQL
# Autor: Claude
# Data: May 29, 2025

echo "🚀 Iniciando configuração do PostgreSQL..."

# Aguardar até que o PostgreSQL esteja pronto
until pg_isready -h localhost -U "$POSTGRES_USER"; do
    echo "🕒 Aguardando PostgreSQL iniciar..."
    sleep 1
done

# Configurar regras de autenticação no pg_hba.conf
cat > "$PGDATA/pg_hba.conf" << EOF
# PostgreSQL Client Authentication Configuration File
# Allow local connections
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
# Allow Docker internal network connections
host    all             all             172.0.0.0/8             trust
host    all             all             192.168.0.0/16          trust
host    all             all             10.0.0.0/8              trust
# Allow all connections with password
host    all             all             0.0.0.0/0               scram-sha-256
# Allow replication connections
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
EOF

# Criar usuários adicionais e ajustar permissões
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" << EOF
-- Criar função para verificar se usuário existe
CREATE OR REPLACE FUNCTION user_exists(username TEXT) RETURNS BOOLEAN AS \$\$
BEGIN
    RETURN EXISTS (SELECT 1 FROM pg_roles WHERE rolname = username);
END;
\$\$ LANGUAGE plpgsql;

-- Criar usuário admin se não existir
DO \$\$
BEGIN
    IF NOT user_exists('admin_user') THEN
        CREATE USER admin_user WITH PASSWORD 'S3cure@dmin2025!';
        GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO admin_user;
    ELSE
        RAISE NOTICE 'Usuário admin_user já existe, pulando criação.';
    END IF;
END \$\$;

-- Criar usuário de leitura se não existir
DO \$\$
BEGIN
    IF NOT user_exists('read_user') THEN
        CREATE USER read_user WITH PASSWORD 'Re@dOnly2025!';
        GRANT CONNECT ON DATABASE $POSTGRES_DB TO read_user;
        GRANT USAGE ON SCHEMA public TO read_user;
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_user;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO read_user;
    ELSE
        RAISE NOTICE 'Usuário read_user já existe, pulando criação.';
    END IF;
END \$\$;

-- Garantir que o usuário padrão tenha todos os privilégios
GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $POSTGRES_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $POSTGRES_USER;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO $POSTGRES_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $POSTGRES_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $POSTGRES_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO $POSTGRES_USER;

-- Criar tabela de teste para verificar persistência
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'teste_persistencia') THEN
        CREATE TABLE teste_persistencia (
            id SERIAL PRIMARY KEY,
            mensagem TEXT,
            data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        INSERT INTO teste_persistencia (mensagem) VALUES ('Teste inicial de persistência');
    END IF;
END \$\$;

-- Exibir usuários
SELECT rolname, rolsuper, rolcreaterole, rolcreatedb
FROM pg_roles
WHERE rolname NOT LIKE 'pg_%'
ORDER BY rolname;

-- Exibir tabelas
SELECT tablename FROM pg_tables WHERE schemaname = 'public';
EOF

# Exibir informações do banco de dados
echo "📊 Estado atual do PostgreSQL:"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "SELECT version();"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "SHOW max_connections;"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "SHOW shared_buffers;"

echo "✅ Configuração do PostgreSQL finalizada com sucesso!"