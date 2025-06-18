#!/bin/bash
# app/scripts/init-with-secrets.sh

set -euo pipefail

readonly LOG_PREFIX="[INIT]"
readonly APP_DIR="/app"
readonly SCRIPTS_DIR="${APP_DIR}/scripts"

# Função de logging
log() {
    echo "${LOG_PREFIX} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Função para aguardar serviço
wait_for_service() {
    local service_name=$1
    local service_host=$2
    local service_port=$3
    local max_attempts=${4:-30}
    
    log "Waiting for ${service_name} at ${service_host}:${service_port}..."
    
    for ((i=1; i<=max_attempts; i++)); do
        if nc -z "${service_host}" "${service_port}" 2>/dev/null; then
            log "✓ ${service_name} is ready"
            return 0
        fi
        
        log "Attempt ${i}/${max_attempts}: ${service_name} not ready, waiting..."
        sleep 2
    done
    
    log "✗ ${service_name} failed to become ready after ${max_attempts} attempts"
    return 1
}

# Função principal
main() {
    log "Starting application initialization with secrets..."
    
    # Verificar se estamos em um container
    if [[ ! -f /.dockerenv ]]; then
        log "WARNING: Not running in Docker container"
    fi
    
    # Executar script de carregamento de secrets
    if [[ -x "/config/secrets/init-secrets.sh" ]]; then
        log "Loading secrets..."
        "/config/secrets/init-secrets.sh" || {
            log "ERROR: Failed to load secrets"
            exit 1
        }
    else
        log "WARNING: Secrets loader not found, using environment variables"
    fi
    
    # Validar configuração crítica com Python
    log "Validating application configuration..."
    python3 -c "
import os
import sys

# Variáveis obrigatórias
required_vars = [
    'POSTGRES_USER',
    'POSTGRES_PASSWORD', 
    'POSTGRES_DB',
    'JWT_SECRET',
    'ADMIN_PASSWORD'
]

# Verificar variáveis obrigatórias
missing_vars = []
for var in required_vars:
    if not os.getenv(var):
        missing_vars.append(var)

if missing_vars:
    print(f'ERROR: Missing required environment variables: {missing_vars}')
    sys.exit(1)

# Validar DATABASE_URL
database_url = os.getenv('DATABASE_URL')
if not database_url or 'postgresql://' not in database_url:
    print('ERROR: Invalid or missing DATABASE_URL')
    sys.exit(1)

# Validar JWT_SECRET length
jwt_secret = os.getenv('JWT_SECRET', '')
if len(jwt_secret) < 32:
    print('ERROR: JWT_SECRET must be at least 32 characters')
    sys.exit(1)

print('✓ Configuration validation passed')
" || {
        log "ERROR: Configuration validation failed"
        exit 1
    }
    
    # Aguardar serviços dependentes
    if [[ "${ENVIRONMENT:-}" == "production" ]]; then
        wait_for_service "PostgreSQL" "db" "5432" || {
            log "ERROR: Database not available"
            exit 1
        }
    fi
    
    # Executar migrações de banco de dados se necessário
    if [[ -f "${APP_DIR}/run_migrations.py" ]]; then
        log "Running database migrations..."
        cd "${APP_DIR}"
        python3 run_migrations.py || {
            log "WARNING: Database migrations failed"
        }
    fi
    
    log "Application initialization completed successfully"
    
    # Executar comando original passado como argumentos
    if [[ $# -gt 0 ]]; then
        log "Executing command: $*"
        exec "$@"
    else
        log "No command specified, starting default services..."
        exec "${SCRIPTS_DIR}/start-services.sh"
    fi
}

# Limpeza em caso de erro
cleanup() {
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        log "Application initialization failed (exit code: ${exit_code})"
    fi
}

trap cleanup EXIT

# Executar função principal
main "$@"
