-- 01_init_users.sql
-- Script para criar usuários e banco de dados

-- Configurações de segurança para o banco
ALTER SYSTEM SET password_encryption = 'scram-sha-256';

-- Garantir que estamos no banco correto
\c notionai_dev;

-- Variáveis para definir usuários e senhas
\set notioniauser_password `cat /run/secrets/notioniauser_password`
\set appuser_password `cat /run/secrets/appuser_password`

-- Criar usuário para operações de manutenção do NotionAI
CREATE USER notioniauser WITH 
    PASSWORD :'notioniauser_password'
    CREATEDB 
    NOSUPERUSER;

-- Criar usuário para aplicação
CREATE USER appuser WITH 
    PASSWORD :'appuser_password'
    NOSUPERUSER 
    NOCREATEDB;

-- Conceder privilégios adequados
GRANT ALL PRIVILEGES ON DATABASE notionai_dev TO notioniauser;
GRANT CONNECT ON DATABASE notionai_dev TO appuser;

-- Criar esquema para dados da aplicação
CREATE SCHEMA IF NOT EXISTS app;

-- Definir permissões
ALTER DEFAULT PRIVILEGES FOR USER notioniauser IN SCHEMA app
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO appuser;
    
ALTER DEFAULT PRIVILEGES FOR USER notioniauser IN SCHEMA app
    GRANT USAGE, SELECT ON SEQUENCES TO appuser;
    
-- Conceder permissões no esquema app
GRANT USAGE ON SCHEMA app TO appuser;

-- Definir esquema de busca padrão
ALTER USER notioniauser SET search_path TO app, public;
ALTER USER appuser SET search_path TO app, public;

-- Finalizar com mensagem
\echo 'Configuração inicial de usuários e permissões concluída'