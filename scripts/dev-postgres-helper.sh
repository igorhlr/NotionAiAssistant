#!/bin/bash
# Script auxiliar para interagir com o PostgreSQL em ambiente de desenvolvimento
# Uso: ./dev-postgres-helper.sh [comando]

set -e

# Diretório do projeto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$PROJECT_DIR/logs/dev-postgres-helper.log"

# Criar diretório de logs se não existir
mkdir -p "$(dirname "$LOG_FILE")"

# Configurações do banco de dados de desenvolvimento
DB_CONTAINER="notionia_dev_postgres"
DB_USER="pguser_dev"
DB_NAME="notionai_dev"

# Função de logging
log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

# Verificar se o container está em execução
check_container() {
    if ! docker ps -q --filter "name=$DB_CONTAINER" >/dev/null 2>&1; then
        log "ERROR" "Container $DB_CONTAINER não está em execução"
        echo "Use docker-compose -f docker-compose.dev.yml up -d para iniciar o ambiente de desenvolvimento"
        exit 1
    fi
}

# Executar comando SQL
run_sql() {
    local sql="$1"
    
    check_container
    
    log "INFO" "Executando SQL: $sql"
    docker exec -i $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "$sql"
}

# Executar arquivo SQL
run_sql_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        log "ERROR" "Arquivo SQL não encontrado: $file"
        exit 1
    fi
    
    check_container
    
    log "INFO" "Executando arquivo SQL: $file"
    cat "$file" | docker exec -i $DB_CONTAINER psql -U $DB_USER -d $DB_NAME
}

# Backup do banco de dados
backup_db() {
    local backup_dir="${1:-$PROJECT_DIR/backups/dev}"
    local backup_file="$backup_dir/notionai_dev_$(date '+%Y%m%d_%H%M%S').sql"
    
    mkdir -p "$backup_dir"
    
    check_container
    
    log "INFO" "Criando backup do banco de dados para: $backup_file"
    docker exec $DB_CONTAINER pg_dump -U $DB_USER $DB_NAME > "$backup_file"
    
    log "SUCCESS" "Backup criado com sucesso: $backup_file"
    echo "$backup_file"
}

# Restaurar banco de dados
restore_db() {
    local backup_file="$1"
    
    if [ ! -f "$backup_file" ]; then
        log "ERROR" "Arquivo de backup não encontrado: $backup_file"
        exit 1
    fi
    
    check_container
    
    log "WARNING" "Restaurando banco de dados de: $backup_file"
    log "WARNING" "Isso irá sobrescrever o banco de dados atual!"
    
    # Pergunta de confirmação
    read -p "Continuar com a restauração? (s/N): " confirm
    if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
        log "INFO" "Restauração cancelada pelo usuário"
        exit 0
    fi
    
    cat "$backup_file" | docker exec -i $DB_CONTAINER psql -U $DB_USER -d $DB_NAME
    
    log "SUCCESS" "Banco de dados restaurado com sucesso"
}

# Verificar versão do PostgreSQL
check_version() {
    check_container
    
    log "INFO" "Verificando versão do PostgreSQL"
    docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "SELECT version();"
}

# Verificar saúde do banco de dados
check_health() {
    check_container
    
    log "INFO" "Verificando saúde do banco de dados"
    if docker exec $DB_CONTAINER pg_isready -U $DB_USER -d $DB_NAME >/dev/null 2>&1; then
        log "SUCCESS" "Banco de dados está respondendo corretamente"
        return 0
    else
        log "ERROR" "Banco de dados não está respondendo"
        return 1
    fi
}

# Listar tabelas
list_tables() {
    check_container
    
    log "INFO" "Listando tabelas do banco de dados"
    docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "\dt"
}

# Função principal
main() {
    local command="${1:-help}"
    
    case "$command" in
        "sql")
            if [ -z "$2" ]; then
                log "ERROR" "Comando SQL não especificado"
                echo "Uso: $0 sql \"SELECT * FROM tabela;\""
                exit 1
            fi
            run_sql "$2"
            ;;
        "file")
            if [ -z "$2" ]; then
                log "ERROR" "Arquivo SQL não especificado"
                echo "Uso: $0 file caminho/para/arquivo.sql"
                exit 1
            fi
            run_sql_file "$2"
            ;;
        "backup")
            backup_db "$2"
            ;;
        "restore")
            if [ -z "$2" ]; then
                log "ERROR" "Arquivo de backup não especificado"
                echo "Uso: $0 restore caminho/para/backup.sql"
                exit 1
            fi
            restore_db "$2"
            ;;
        "version")
            check_version
            ;;
        "health")
            check_health
            ;;
        "tables")
            list_tables
            ;;
        "help"|*)
            echo "Uso: $0 [comando] [argumentos]"
            echo ""
            echo "Comandos disponíveis:"
            echo "  sql \"COMANDO\"   - Executar comando SQL"
            echo "  file ARQUIVO    - Executar arquivo SQL"
            echo "  backup [DIR]    - Criar backup do banco de dados"
            echo "  restore ARQUIVO - Restaurar banco de dados a partir de backup"
            echo "  version         - Verificar versão do PostgreSQL"
            echo "  health          - Verificar saúde do banco de dados"
            echo "  tables          - Listar tabelas do banco de dados"
            echo "  help            - Exibir esta ajuda"
            echo ""
            echo "Exemplo:"
            echo "  $0 sql \"SELECT * FROM users;\""
            echo "  $0 backup"
            echo "  $0 health"
            ;;
    esac
}

# Executar comando
main "$@"
