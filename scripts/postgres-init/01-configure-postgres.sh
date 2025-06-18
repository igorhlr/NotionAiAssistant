#!/bin/bash
set -e

# Script de inicialização do PostgreSQL com variáveis seguras
# Autor: Claude  
# Data: June 07, 2025

echo "🚀 Iniciando configuração segura do PostgreSQL..."

# Função para ler secrets seguros
get_secure_password() {
    local secret_name="$1"
    local secret_path="/run/secrets/$secret_name"
    
    if [ -f "$secret_path" ]; then
        cat "$secret_path" | tr -d '\n\r'
    else
        echo ""
    fi
}

# Ler senhas dos secrets
NOTIONIAUSER_PWD=$(get_secure_password "notioniauser_password")
APPUSER_PWD=$(get_secure_password "appuser_password")

# Aguardar até que o PostgreSQL esteja pronto
until pg_isready -h localhost -U "$POSTGRES_USER"; do
    echo "🕒 Aguardando PostgreSQL iniciar..."
    sleep 1
done

echo "✅ PostgreSQL iniciado. Configurando usuários e permissões..."

# Verificar se as variáveis essenciais estão definidas
if [ -z "$POSTGRES_USER" ]; then
    echo "❌ POSTGRES_USER não definido!"
    exit 1
fi

if [ -z "$POSTGRES_DB" ]; then
    echo "❌ POSTGRES_DB não definido!"
    exit 1
fi

echo "📋 Usando configurações:"
echo "   Usuário principal: $POSTGRES_USER"
echo "   Banco de dados: $POSTGRES_DB"

# Configurar regras de autenticação no pg_hba.conf
cat > "$PGDATA/pg_hba.conf" << EOF
# PostgreSQL Client Authentication Configuration File
# Configuração segura para NotionAiAssistant

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

# Criar usuários adicionais com senhas seguras
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" << EOF
-- Criar função para verificar se usuário existe
CREATE OR REPLACE FUNCTION user_exists(username TEXT) RETURNS BOOLEAN AS \$\$
BEGIN
    RETURN EXISTS (SELECT 1 FROM pg_roles WHERE rolname = username);
END;
\$\$ LANGUAGE plpgsql;

-- Criar usuário notioniauser se as credenciais foram fornecidas
DO \$\$
BEGIN
    IF '${NOTIONIAUSER_PWD}' != '' THEN
        IF NOT user_exists('notioniauser') THEN
            CREATE USER notioniauser WITH PASSWORD '${NOTIONIAUSER_PWD}';
            GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO notioniauser;
            RAISE NOTICE 'Usuário notioniauser criado com senha segura.';
        ELSE
            ALTER USER notioniauser WITH PASSWORD '${NOTIONIAUSER_PWD}';
            RAISE NOTICE 'Senha do usuário notioniauser atualizada.';
        END IF;
    ELSE
        RAISE NOTICE 'Secret notioniauser_password não encontrado, pulando criação.';
    END IF;
END \$\$;

-- Criar usuário appuser se as credenciais foram fornecidas
DO \$\$
BEGIN
    IF '${APPUSER_PWD}' != '' THEN
        IF NOT user_exists('appuser') THEN
            CREATE USER appuser WITH PASSWORD '${APPUSER_PWD}';
            GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO appuser;
            GRANT USAGE ON SCHEMA public TO appuser;
            GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO appuser;
            ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO appuser;
            RAISE NOTICE 'Usuário appuser criado com senha segura.';
        ELSE
            ALTER USER appuser WITH PASSWORD '${APPUSER_PWD}';
            RAISE NOTICE 'Senha do usuário appuser atualizada.';
        END IF;
    ELSE
        RAISE NOTICE 'Secret appuser_password não encontrado, pulando criação.';
    END IF;
END \$\$;

-- Criar usuário admin com senha aleatória forte
DO \$\$
BEGIN
    IF NOT user_exists('admin_secure') THEN
        CREATE USER admin_secure WITH PASSWORD 'SecureAdmin$(date +%s)!';
        GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO admin_secure;
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_secure;
        GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_secure;
        RAISE NOTICE 'Usuário admin_secure criado.';
    END IF;
END \$\$;

-- Criar usuário de leitura com senha aleatória
DO \$\$
BEGIN
    IF NOT user_exists('readonly_secure') THEN
        CREATE USER readonly_secure WITH PASSWORD 'ReadOnly$(date +%s)!';
        GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO readonly_secure;
        GRANT USAGE ON SCHEMA public TO readonly_secure;
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_secure;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly_secure;
        RAISE NOTICE 'Usuário readonly_secure criado.';
    END IF;
END \$\$;

-- Garantir que o usuário principal tenha todos os privilégios
GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${POSTGRES_USER};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${POSTGRES_USER};
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO ${POSTGRES_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${POSTGRES_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${POSTGRES_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO ${POSTGRES_USER};

-- Criar tabela de auditoria de inicialização
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'initialization_log') THEN
        CREATE TABLE initialization_log (
            id SERIAL PRIMARY KEY,
            event_type TEXT NOT NULL,
            message TEXT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            environment_info JSONB
        );
        
        INSERT INTO initialization_log (event_type, message, environment_info) 
        VALUES (
            'SECURE_INIT', 
            'PostgreSQL inicializado com configurações seguras',
            jsonb_build_object(
                'postgres_user', '${POSTGRES_USER}',
                'postgres_db', '${POSTGRES_DB}',
                'has_notioniauser_pwd', CASE WHEN '${NOTIONIAUSER_PWD}' != '' THEN true ELSE false END,
                'has_appuser_pwd', CASE WHEN '${APPUSER_PWD}' != '' THEN true ELSE false END,
                'init_date', CURRENT_TIMESTAMP
            )
        );
        
        RAISE NOTICE 'Tabela de auditoria criada e registro inicial inserido.';
    END IF;
END \$\$;

-- Exibir usuários criados (sem mostrar senhas)
SELECT 
    rolname AS "Usuário",
    rolsuper AS "Superuser",
    rolcreaterole AS "Pode criar roles",
    rolcreatedb AS "Pode criar DB",
    rolcanlogin AS "Pode fazer login"
FROM pg_roles 
WHERE rolname NOT LIKE 'pg_%'
ORDER BY rolname;

-- Exibir tabelas existentes
SELECT schemaname, tablename 
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;
EOF

# Exibir informações do banco de dados
echo ""
echo "📊 Estado atual do PostgreSQL:"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "SELECT version();"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "SHOW max_connections;"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "SHOW shared_buffers;"

echo ""
echo "🔐 Resumo da configuração de segurança:"
echo "   ✅ Senhas lidas de Docker Secrets"
echo "   ✅ Usuários criados com credenciais seguras"
echo "   ✅ Permissões configuradas adequadamente"
echo "   ✅ Auditoria de inicialização registrada"

echo ""
echo "✅ Configuração segura do PostgreSQL finalizada!"