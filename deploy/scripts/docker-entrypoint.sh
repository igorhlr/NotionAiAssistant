#!/bin/bash
set -e

# Definir que estamos executando em Docker
export RUNNING_IN_DOCKER=true

# Função para aguardar o banco de dados
wait_for_postgres() {
    echo "Aguardando PostgreSQL ficar disponível...."
    
    # Variáveis para conexão
    PG_HOST=${POSTGRES_HOST}
    PG_PORT=${POSTGRES_PORT}
    PG_USER=${POSTGRES_USER}
    PG_DB=${POSTGRES_DB}
    
    # Looping até conseguir conectar
    until pg_isready -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB; do
        echo "PostgreSQL não está pronto - esperando..."
        sleep 2
    done
    
    echo "PostgreSQL está pronto!"
}

# Aguardar o banco de dados estar pronto
wait_for_postgres

# Iniciar o backend em segundo plano
cd /app
echo "Iniciando servidor backend..."
PYTHONPATH=/app uvicorn backend.main:app --host 0.0.0.0 --port 8080 &

# Aguardar o backend iniciar
echo "Aguardando o backend iniciar..."
sleep 5

# Verificar se o backend está rodando
curl_check() {
    for i in {1..30}; do
        if curl -s -f http://localhost:8080/api/health > /dev/null; then
            echo "Backend está pronto!"
            return 0
        fi
        echo "Aguardando backend iniciar... ($i/30)"
        sleep 2
    done
    echo "Backend não iniciou corretamente!"
    return 1
}

curl_check

# Iniciar o frontend
echo "Iniciando frontend Streamlit..."
cd /app/frontend
exec streamlit run main.py --server.port=8501 --server.address=0.0.0.0 --browser.gatherUsageStats=false --server.maxUploadSize=50 --server.maxMessageSize=50
