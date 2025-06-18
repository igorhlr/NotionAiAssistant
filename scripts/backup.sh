#!/bin/bash

# Script para backup do banco de dados PostgreSQL
# Autor: Claude
# Data: May 29, 2025

# Carregar variáveis de ambiente
if [ -f /home/user0/docker-secrets/open-source-secrets/.env ]; then
    source /home/user0/docker-secrets/open-source-secrets/.env
else
    echo "⚠️ Arquivo .env não encontrado. Usando valores padrão."
fi

# Configurações
BACKUP_DIR="/home/user0/docker-data/notion-assistant/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/notionia_backup_${TIMESTAMP}.sql.gz"

# Garantir que o diretório de backup existe
mkdir -p ${BACKUP_DIR}

# Executar backup
echo "🚀 Iniciando backup do PostgreSQL..."
docker exec notionia_postgres pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB} | gzip > ${BACKUP_FILE}

# Verificar se o backup foi bem-sucedido
if [ $? -eq 0 ]; then
    echo "✅ Backup realizado com sucesso: ${BACKUP_FILE}"
    
    # Listar backups disponíveis
    echo "📁 Backups disponíveis:"
    ls -lh ${BACKUP_DIR}
    
    # Limpar backups antigos (manter os 5 mais recentes)
    echo "🧹 Removendo backups antigos (mantendo os 5 mais recentes)..."
    ls -t ${BACKUP_DIR}/notionia_backup_*.sql.gz | tail -n +6 | xargs -r rm
    
    echo "📊 Estatísticas do backup:"
    echo "- Tamanho: $(du -h ${BACKUP_FILE} | cut -f1)"
    echo "- Data: $(date -r ${BACKUP_FILE})"
else
    echo "❌ Falha ao realizar backup!"
    exit 1
fi

echo "🏁 Processo de backup concluído!"
