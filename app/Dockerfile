FROM python:3.11-slim

WORKDIR /app

# Instalar dependências do sistema
# Adicionado procps para o comando ps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    postgresql-client \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configurar ambiente Python
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV RUNNING_IN_DOCKER=true

# Copiar os arquivos de requisitos
COPY requirements.txt ./

# Instalar dependências
RUN pip install --no-cache-dir -r requirements.txt

# Copiar o código da aplicação
COPY backend /app/backend/
COPY frontend /app/frontend/
COPY shared /app/shared/
COPY __init__.py /app/
COPY scripts /app/scripts/
COPY wait-for-postgres.sh /app/wait-for-postgres.sh

# Ajustar permissões do script wait-for-postgres.sh
RUN chmod +x /app/wait-for-postgres.sh

# Criar diretório de logs
RUN mkdir -p /app/logs && chmod 777 /app/logs

# Expor portas
EXPOSE 8501
EXPOSE 8080

# Script de entrypoint melhorado com mais logs e tratamento de erros
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "[$(date "+%Y-%m-%d %H:%M:%S")] Iniciando aplicação..."\n\
\n\
# Função para logging\n\
log() {\n\
  echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1"\n\
}\n\
\n\
# Certifique-se de que o diretório de logs existe\n\
mkdir -p /app/logs\n\
touch /app/logs/app.log\n\
\n\
# Iniciar o backend em segundo plano\n\
log "Iniciando servidor backend..."\n\
PYTHONPATH=/app uvicorn backend.main:app --host 0.0.0.0 --port 8080 &\n\
BACKEND_PID=$!\n\
\n\
# Verificar se o backend iniciou corretamente\n\
log "Aguardando o backend iniciar..."\n\
ATTEMPTS=0\n\
MAX_ATTEMPTS=30\n\
while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do\n\
  if curl -s http://localhost:8080/api/health > /dev/null; then\n\
    log "Backend iniciado com sucesso! (tentativa $((ATTEMPTS+1)))"\n\
    break\n\
  fi\n\
\n\
  # Verificar se o processo ainda está em execução\n\
  if ! ps -p $BACKEND_PID > /dev/null; then\n\
    log "ERRO: O processo do backend não está mais em execução!"\n\
    log "Verificando logs de erro:"\n\
    cat /app/logs/app.log || log "Não foi possível ler o arquivo de log"\n\
    # Reiniciar o backend\n\
    log "Tentando reiniciar o backend..."\n\
    PYTHONPATH=/app uvicorn backend.main:app --host 0.0.0.0 --port 8080 &\n\
    BACKEND_PID=$!\n\
    log "Backend reiniciado com PID $BACKEND_PID"\n\
  fi\n\
\n\
  ATTEMPTS=$((ATTEMPTS+1))\n\
  log "Backend ainda não está pronto. Tentativa $ATTEMPTS de $MAX_ATTEMPTS..."\n\
  sleep 3\n\
done\n\
\n\
if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then\n\
  log "AVISO: Tempo máximo excedido esperando o backend iniciar. Continuando mesmo assim..."\n\
  log "Últimas linhas do log do backend:"\n\
  cat /app/logs/app.log || log "Não foi possível ler o arquivo de log"\n\
fi\n\
\n\
# Iniciar o frontend\n\
log "Iniciando frontend Streamlit..."\n\
cd /app/frontend\n\
exec streamlit run main.py --server.port=8501 --server.address=0.0.0.0 --browser.gatherUsageStats=false\n\
' > /app/start-services.sh

RUN chmod +x /app/start-services.sh

# Configurar usuário não-root com acesso aos secrets
RUN useradd -m appuser
RUN chown -R appuser:appuser /app

# IMPORTANTE: Docker Secrets são montados com permissões para root apenas
# Precisamos garantir que appuser possa acessar os secrets

# Usar wait-for-postgres.sh como entrypoint
USER root
ENTRYPOINT ["/app/wait-for-postgres.sh"]
CMD ["/app/start-services.sh"]
