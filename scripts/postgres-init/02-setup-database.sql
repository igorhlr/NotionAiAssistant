-- Extensões e configurações adicionais do PostgreSQL
-- Este script é executado automaticamente pela imagem oficial do PostgreSQL
-- quando os arquivos estão no diretório /docker-entrypoint-initdb.d/

-- Conectar ao banco notioniadb
\c notioniadb;

-- Criar extensões úteis
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- Para busca de texto
CREATE EXTENSION IF NOT EXISTS "unaccent"; -- Para busca sem acentuação

-- Configurações de performance
ALTER SYSTEM SET max_connections = '100';
ALTER SYSTEM SET shared_buffers = '128MB';
ALTER SYSTEM SET effective_cache_size = '512MB';
ALTER SYSTEM SET work_mem = '16MB';
ALTER SYSTEM SET maintenance_work_mem = '128MB';

-- Configurações de log
ALTER SYSTEM SET log_min_duration_statement = '1000'; -- Log consultas acima de 1s
ALTER SYSTEM SET log_statement = 'ddl';              -- Log de todas as operações DDL
ALTER SYSTEM SET log_line_prefix = '%t [%p]: [%l-1] db=%d,user=%u ';

-- Reload das configurações
SELECT pg_reload_conf();
