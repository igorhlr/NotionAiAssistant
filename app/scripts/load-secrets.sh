#!/bin/bash
# app/scripts/load-secrets.sh

set -euo pipefail

readonly LOG_PREFIX="[LOAD-SECRETS]"

# Função de logging
log() {
    echo "${LOG_PREFIX} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Função principal
main() {
    log "Loading secrets for application..."
    
    # Verificar se script de inicialização de secrets existe
    if [[ -x "/config/secrets/init-secrets.sh" ]]; then
        log "Executing secrets initialization script..."
        "/config/secrets/init-secrets.sh"
    else
        log "ERROR: Secrets initialization script not found or not executable"
        return 1
    fi
    
    # Verificar se arquivo .env foi criado
    if [[ -f "/app/.env" ]]; then
        log "✓ Secrets loaded successfully"
        
        # Source do arquivo .env para disponibilizar as variáveis
        set -a
        source "/app/.env"
        set +a
        
        log "Environment variables loaded from /app/.env"
    else
        log "ERROR: Environment file not created by secrets initialization"
        return 1
    fi
}

main "$@"
