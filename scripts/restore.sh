#!/bin/bash

# Script para restauração de backup do PostgreSQL
# Autor: Claude
# Data: May 29, 2025

# Carregar variáveis de ambiente
if [ -f /home/user0/docker-secrets/open-source-secrets/.env ]; then
    source /home/user0/docker-secrets/open-source-secrets/.env
else
    echo "⚠️ Arquivo .env não encontrado. Usando valores padrão."
fi

# Verificar se um arquivo de backup foi fornecido
if [ $# -ne 1 ]; then
    echo "❌ Uso: $0 <arquivo_backup>"
    echo "📁 Backups disponíveis:"
    ls -lh /Users/user0/Documents/VPS/home/user0/docker-data/notion-assistant/backups
    exit 1
fi

BACKUP_FILE=$1

# Verificar se o arquivo existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Arquivo de backup não encontrado: $BACKUP_FILE"
    exit 1
fi

# Perguntar confirmação ao usuário
echo "⚠️  ATENÇÃO: Esta operação irá substituir TODOS os dados no banco de dados!"
echo "📂 Backup a ser restaurado: $BACKUP_FILE"
read -p "🔄 Deseja continuar? (s/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[sS]$ ]]; then
    echo "🛑 Operação cancelada pelo usuário."
    exit 0
fi

echo "🚀 Iniciando restauração do banco de dados..."

# Verificar se é um arquivo comprimido
if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo "📦 Descomprimindo arquivo..."
    gunzip -c "$BACKUP_FILE" | docker exec -i notionia_postgres psql -U ${POSTGRES_USER:-notioniauser} -d ${POSTGRES_DB:-notioniadb}
else
    docker exec -i notionia_postgres psql -U ${POSTGRES_USER:-notioniauser} -d ${POSTGRES_DB:-notioniadb} < "$BACKUP_FILE"
fi

# Verificar se a restauração foi bem-sucedida
if [ $? -eq 0 ]; then
    echo "✅ Restauração concluída com sucesso!"
    
    # Verificar dados restaurados
    echo "📊 Verificando dados restaurados..."
    docker exec -it notionia_postgres psql -U ${POSTGRES_USER:-notioniauser} -d ${POSTGRES_DB:-notioniadb} -c "SELECT COUNT(*) AS total_tables FROM information_schema.tables WHERE table_schema = 'public';"
else
    echo "❌ Falha na restauração do banco de dados!"
    exit 1
fi

echo "🏁 Processo de restauração concluído!"
