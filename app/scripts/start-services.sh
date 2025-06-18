#!/bin/bash
# app/scripts/start-services.sh

set -euo pipefail

readonly LOG_PREFIX="[START-SERVICES]"
readonly APP_DIR="/app"

# Função de logging
log() {
    echo "${LOG_PREFIX} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Função para iniciar FastAPI
start_fastapi() {
    log "Starting FastAPI backend..."
    cd "${APP_DIR}"
    uvicorn backend.main:app --host 0.0.0.0 --port 8080 --reload &
    local fastapi_pid=$!
    log "FastAPI started with PID: ${fastapi_pid}"
    echo $fastapi_pid > /tmp/fastapi.pid
}

# Função para iniciar Streamlit
start_streamlit() {
    log "Starting Streamlit frontend..."
    cd "${APP_DIR}"
    streamlit run frontend/main.py --server.port 8501 --server.address 0.0.0.0 &
    local streamlit_pid=$!
    log "Streamlit started with PID: ${streamlit_pid}"
    echo $streamlit_pid > /tmp/streamlit.pid
}

# Função para aguardar sinal de parada
wait_for_shutdown() {
    log "Services started successfully. Waiting for shutdown signal..."
    
    # Função para parar serviços
    shutdown_services() {
        log "Received shutdown signal, stopping services..."
        
        if [[ -f /tmp/fastapi.pid ]]; then
            local fastapi_pid=$(cat /tmp/fastapi.pid)
            log "Stopping FastAPI (PID: ${fastapi_pid})..."
            kill $fastapi_pid 2>/dev/null || true
            rm -f /tmp/fastapi.pid
        fi
        
        if [[ -f /tmp/streamlit.pid ]]; then
            local streamlit_pid=$(cat /tmp/streamlit.pid)
            log "Stopping Streamlit (PID: ${streamlit_pid})..."
            kill $streamlit_pid 2>/dev/null || true
            rm -f /tmp/streamlit.pid
        fi
        
        log "Services stopped"
        exit 0
    }
    
    # Configurar handlers para sinais
    trap shutdown_services SIGTERM SIGINT
    
    # Aguardar indefinidamente
    while true; do
        sleep 1
        
        # Verificar se processos ainda estão rodando
        if [[ -f /tmp/fastapi.pid ]]; then
            local fastapi_pid=$(cat /tmp/fastapi.pid)
            if ! kill -0 $fastapi_pid 2>/dev/null; then
                log "ERROR: FastAPI process died unexpectedly"
                shutdown_services
            fi
        fi
        
        if [[ -f /tmp/streamlit.pid ]]; then
            local streamlit_pid=$(cat /tmp/streamlit.pid)
            if ! kill -0 $streamlit_pid 2>/dev/null; then
                log "ERROR: Streamlit process died unexpectedly"
                shutdown_services
            fi
        fi
    done
}

# Função principal
main() {
    log "Starting NotionAI application services..."
    
    # Verificar se estamos no diretório correto
    if [[ ! -d "${APP_DIR}/backend" ]] || [[ ! -d "${APP_DIR}/frontend" ]]; then
        log "ERROR: Application directories not found in ${APP_DIR}"
        exit 1
    fi
    
    # Aguardar um pouco para garantir que tudo está inicializado
    sleep 5
    
    # Iniciar serviços
    start_fastapi
    start_streamlit
    
    # Aguardar sinal de parada
    wait_for_shutdown
}

main "$@"
