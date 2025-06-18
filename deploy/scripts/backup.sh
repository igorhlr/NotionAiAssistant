#!/bin/bash
# Script de backup automático para NotionIA

# Configurações
BACKUP_DIR="/home/user0/open-source-projects/NotionAiAssistant/data/backups"
POSTGRES_CONTAINER="notionia_postgres"
DB_NAME=${POSTGRES_DB}
DB_USER=${POSTGRES_USER}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/$DB_NAME-$TIMESTAMP.sql"
LOG_FILE="$BACKUP_DIR/backup_log.txt"

# Certificar que o diretório de backup existe
mkdir -p "$BACKUP_DIR"

echo "[$(date)] Iniciando backup do banco de dados $DB_NAME..." | tee -a "$LOG_FILE"

# Executar o backup
docker exec $POSTGRES_CONTAINER pg_dump -U $DB_USER -d $DB_NAME > "$BACKUP_FILE"
if [ $? -eq 0 ]; then
    echo "[$(date)] Backup concluído com sucesso: $BACKUP_FILE" | tee -a "$LOG_FILE"
    
    # Compactar o arquivo
    gzip "$BACKUP_FILE"
    echo "[$(date)] Arquivo compactado: $BACKUP_FILE.gz" | tee -a "$LOG_FILE"
    
    # Limpar backups antigos (manter os últimos 7 dias)
    find "$BACKUP_DIR" -name "*.sql.gz" -type f -mtime +7 -delete
    echo "[$(date)] Backups com mais de 7 dias foram removidos" | tee -a "$LOG_FILE"
else
    echo "[$(date)] ERRO: Falha ao criar backup" | tee -a "$LOG_FILE"
    exit 1
fi

echo "[$(date)] Processo de backup concluído" | tee -a "$LOG_FILE"
