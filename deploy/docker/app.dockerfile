FROM python:3.11-slim

WORKDIR /app

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    postgresql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configurar ambiente Python
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV RUNNING_IN_DOCKER=true

# Copiar os arquivos de requisitos
COPY app/requirements.txt ./

# Instalar dependências
RUN pip install --no-cache-dir -r requirements.txt

# Copiar o código da aplicação
COPY app/backend /app/backend/
COPY app/frontend /app/frontend/
COPY app/shared /app/shared/
COPY app/__init__.py /app/

# Copiar script wait-for-postgres.sh
COPY scripts/wait-for-postgres.sh /app/wait-for-postgres.sh
RUN chmod +x /app/wait-for-postgres.sh

# Criar diretório de logs
RUN mkdir -p /app/logs && chmod 777 /app/logs

# Expor portas
EXPOSE 8501
EXPOSE 8080

# Script de entrypoint que usa wait-for-postgres.sh
RUN echo '#!/bin/bash\nset -e\n\n# Iniciar o backend em segundo plano\necho "Iniciando servidor backend..."\nPYTHONPATH=/app uvicorn backend.main:app --host 0.0.0.0 --port 8080 &\n\n# Aguardar o backend iniciar\necho "Aguardando o backend iniciar..."\nsleep 10\n\n# Iniciar o frontend\necho "Iniciando frontend Streamlit..."\ncd /app/frontend\nexec streamlit run main.py --server.port=8501 --server.address=0.0.0.0 --browser.gatherUsageStats=false' > /app/start-services.sh

RUN chmod +x /app/start-services.sh

# Configurar usuário não-root
RUN useradd -m appuser
RUN chown -R appuser:appuser /app
USER appuser

# Usar wait-for-postgres.sh como entrypoint
ENTRYPOINT ["/app/wait-for-postgres.sh"]
CMD ["/app/start-services.sh"]
