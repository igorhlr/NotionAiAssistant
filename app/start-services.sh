#!/bin/bash
set -e

echo "[$(date "+%Y-%m-%d %H:%M:%S")] Iniciando aplicação..."

log() {
  echo "[$(date "+%Y-%m-%d %H:%M:%S")] $*"
}

# Criar diretório de logs
mkdir -p /app/logs

# Verificar se estamos em modo de desenvolvimento
if [ "$ENVIRONMENT" == "development" ]; then
  log "Executando em modo de desenvolvimento - ativando DEBUG e CORS"
  export DEBUG="True"
  export ENABLE_CORS="True"
  export BACKEND_URL="http://localhost:8080"  # Para desenvolvimento local
  export ALLOW_ORIGINS="http://localhost:8501,http://127.0.0.1:8501,http://localhost:8080,http://127.0.0.1:8080"
else
  log "Executando em modo de produção"
  export BACKEND_URL="/api"  # Usando caminho relativo para produção
fi

# Criar arquivo de configuração da API para o ambiente apropriado
mkdir -p /app/backend/config
cat > /app/backend/config/api_config.py << EOF
"""
Configuração da API para ambiente: $ENVIRONMENT
"""
# Configurações geradas automaticamente durante inicialização
API_URL = "$BACKEND_URL"
DEBUG = $DEBUG
ENVIRONMENT = "$ENVIRONMENT"
EOF

# Iniciar a API em background
log "Iniciando API FastAPI (modo $ENVIRONMENT)..."
cd /app
export PYTHONPATH=/app
python -m uvicorn backend.main:app --host 0.0.0.0 --port 8080 --reload >> /app/logs/api.log 2>&1 &
API_PID=$!
log "API iniciada (PID: $API_PID)"

# Aguardar um momento para o backend iniciar
sleep 3

# Verificar se o backend está em execução
if curl -s http://localhost:8080/api/health >/dev/null 2>&1; then
  log "Backend está respondendo corretamente"
else
  log "AVISO: Backend pode não estar respondendo. Verificar logs em /app/logs/api.log"
fi

# Iniciar o frontend
log "Iniciando frontend Streamlit (modo $ENVIRONMENT)..."
cd /app/frontend

# Criar arquivo de configuração do Streamlit para o ambiente apropriado
mkdir -p /app/.streamlit
cat > /app/.streamlit/config.toml << EOF
[server]
port = 8501
address = "0.0.0.0"
enableCORS = true
enableXsrfProtection = false
maxUploadSize = 200

[browser]
serverAddress = "localhost"
gatherUsageStats = false
serverPort = 8501

[theme]
primaryColor = "#0066cc"
backgroundColor = "#ffffff"
secondaryBackgroundColor = "#f0f2f6"
textColor = "#262730"

[client]
toolbarMode = "auto"
EOF

# Criar arquivo de configuração API para o frontend
cat > /app/frontend/api_config.py << EOF
"""
Configuração da API para o frontend - Ambiente: $ENVIRONMENT
"""
# Configurações geradas automaticamente durante inicialização
API_URL = "$BACKEND_URL"
DEBUG = $DEBUG
ENVIRONMENT = "$ENVIRONMENT"
EOF

# Exportar variável de ambiente para configurar URL do backend
export NOTION_API_BACKEND_URL="$BACKEND_URL"

# Iniciar o frontend com o arquivo principal
streamlit run /app/frontend/main.py --server.port=8501 --server.address=0.0.0.0 --server.enableCORS=true >> /app/logs/frontend.log 2>&1 &
FRONTEND_PID=$!
log "Frontend iniciado (PID: $FRONTEND_PID)"

# Registrar PIDs para capturar sinais
echo $API_PID > /tmp/api.pid
echo $FRONTEND_PID > /tmp/frontend.pid

log "Aplicação startup complete"

# Função para desligar serviços graciosamente
shutdown() {
  log "Desligando serviços..."
  kill -TERM $API_PID $FRONTEND_PID 2>/dev/null || true
  wait
  log "Todos os serviços desligados"
  exit 0
}

# Capturar sinais para desligamento gracioso
trap shutdown SIGTERM SIGINT

# Exibir informações de acesso
log "============================================================="
log "🚀 Serviços iniciados com sucesso!"
log "📊 Frontend: http://localhost:8501"
log "🔌 Backend: http://localhost:8080"
log "📝 Logs em: /app/logs/"
log "============================================================="

# Manter o script em execução (para que o container não encerre)
log "Monitorando logs..."
tail -f /app/logs/api.log /app/logs/frontend.log