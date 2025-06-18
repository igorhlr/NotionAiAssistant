#!/bin/bash
# Script de Deploy Automatizado para Ambiente de Desenvolvimento - NotionAiAssistant
# Integra limpeza, segurança de variáveis e deploy para ambiente de desenvolvimento

set -e

# Configurações
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$PROJECT_DIR/logs/automated-deploy-dev.log"
ENVIRONMENT="development"
FORCE_CLEAN="${1:-false}"
ROTATE_SECRETS="${2:-false}"
DEV_PORT="${3:-8501}"
API_PORT="${4:-8080}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função de logging com cores
log() {
    local level="$1"
    local color="$NC"
    shift
    
    case "$level" in
        "ERROR") color="$RED" ;;
        "SUCCESS") color="$GREEN" ;;
        "WARNING") color="$YELLOW" ;;
        "INFO") color="$BLUE" ;;
    esac
    
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [${color}${level}${NC}] $*" | tee -a "$LOG_FILE"
}

# Função para exibir banner
show_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  NOTIONAIASSISTANT                           ║"
    echo "║              DEPLOY AUTOMATIZADO DEV                         ║"
    echo "║                                                              ║"
    echo "║  🚀 Deploy Integrado para Ambiente de Desenvolvimento        ║"
    echo "║  🔒 Gestão Automática de Secrets para Desenvolvimento        ║"
    echo "║  🧹 Limpeza Inteligente do Projeto                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Função para verificar pré-requisitos
check_prerequisites() {
    log "INFO" "Verificando pré-requisitos do sistema..."
    
    local missing_tools=()
    
    # Verificar ferramentas essenciais
    local required_tools=("docker" "docker-compose" "git")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log "ERROR" "Ferramentas faltando: ${missing_tools[*]}"
        exit 1
    fi
    
    # Verificar estrutura do projeto
    local critical_paths=(
        "docker-compose.yml"
        "config/secrets"
        "scripts/secure-env-management.sh"
        "app"
    )
    
    for path in "${critical_paths[@]}"; do
        if [ ! -e "$PROJECT_DIR/$path" ]; then
            log "ERROR" "Estrutura crítica faltando: $path"
            exit 1
        fi
    done
    
    # Verificar ambiente Docker
    if ! docker info >/dev/null 2>&1; then
        log "ERROR" "Docker não está executando ou não acessível"
        exit 1
    fi
    
    # Verificar rede Docker
    if ! docker network inspect shared_network >/dev/null 2>&1; then
        log "INFO" "Criando rede Docker shared_network..."
        docker network create shared_network
    fi
    
    # Criar diretório de secrets para development se não existir
    if [ ! -d "$PROJECT_DIR/config/secrets/development" ]; then
        log "INFO" "Criando diretório de secrets para desenvolvimento..."
        mkdir -p "$PROJECT_DIR/config/secrets/development"
    fi
    
    log "SUCCESS" "Todos os pré-requisitos verificados"
}

# Função para limpeza inteligente
intelligent_cleanup() {
    log "INFO" "Iniciando limpeza inteligente do projeto..."
    
    if [ "$FORCE_CLEAN" == "true" ]; then
        log "INFO" "Limpeza forçada ativada"
        chmod +x "$PROJECT_DIR/scripts/safe-cleanup.sh"
        "$PROJECT_DIR/scripts/safe-cleanup.sh" false
    else
        log "INFO" "Limpeza segura (apenas arquivos desnecessários)"
        
        # Limpeza automática de arquivos seguros
        find "$PROJECT_DIR" -name ".DS_Store" -type f -delete 2>/dev/null || true
        find "$PROJECT_DIR" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
        find "$PROJECT_DIR" -name "*.pyc" -type f -delete 2>/dev/null || true
        
        log "SUCCESS" "Limpeza automática concluída"
    fi
}

# Função para gestão segura de variáveis de ambiente para desenvolvimento
secure_environment_setup() {
    log "INFO" "Configurando variáveis de ambiente seguras para desenvolvimento..."
    
    # Verificar se o diretório de secrets para desenvolvimento existe
    if [ ! -d "$PROJECT_DIR/config/secrets/development" ]; then
        mkdir -p "$PROJECT_DIR/config/secrets/development"
        log "INFO" "Diretório de secrets para desenvolvimento criado"
    fi
    
    # Função para criar secrets de desenvolvimento
    create_dev_secret() {
        local secret_name="$1"
        local secret_value="$2"
        local secret_file="$PROJECT_DIR/config/secrets/development/$secret_name"
        
        if [ ! -f "$secret_file" ] || [ "$ROTATE_SECRETS" == "true" ]; then
            echo -n "$secret_value" > "$secret_file"
            chmod 600 "$secret_file"
            log "INFO" "Secret de desenvolvimento $secret_name criado/atualizado"
        else
            log "INFO" "Secret de desenvolvimento $secret_name já existe, mantendo valor atual"
        fi
    }
    
    # Criar secrets básicos para desenvolvimento
    create_dev_secret "postgres_password" "dev_pg_password"
    create_dev_secret "notioniauser_password" "dev_notioniauser_password"
    create_dev_secret "appuser_password" "dev_appuser_password"
    create_dev_secret "jwt_secret" "dev_jwt_secret_for_local_testing_only"
    create_dev_secret "admin_password" "dev_admin_password"
    
    # Verificar se há secrets de produção e copiar chaves de API (se solicitado)
    if [ -d "/home/user0/docker-secrets/open-source-secrets" ]; then
        log "INFO" "Encontrado diretório de secrets de produção"
        
        if [ "$ROTATE_SECRETS" != "true" ]; then
            # Copiar chaves de API da produção (opcional)
            for api_key in "openai_api_key" "notion_api_key" "anthropic_api_key" "deepseek_api_key"; do
                if [ -f "/home/user0/docker-secrets/open-source-secrets/$api_key" ]; then
                    if [ ! -f "$PROJECT_DIR/config/secrets/development/$api_key" ]; then
                        log "INFO" "Copiando $api_key da produção para desenvolvimento"
                        cp "/home/user0/docker-secrets/open-source-secrets/$api_key" "$PROJECT_DIR/config/secrets/development/$api_key"
                    fi
                else
                    log "WARNING" "$api_key não encontrado em produção"
                    create_dev_secret "$api_key" "sk-dev-placeholder-key-for-testing"
                fi
            done
        else
            # Criar chaves de API placeholder para desenvolvimento
            create_dev_secret "openai_api_key" "sk-dev-placeholder-key-for-testing"
            create_dev_secret "notion_api_key" "secret_dev-placeholder-key-for-testing"
            create_dev_secret "anthropic_api_key" "sk-ant-dev-placeholder-key-for-testing"
            create_dev_secret "deepseek_api_key" "sk-deepseek-dev-placeholder-key-for-testing"
        fi
    else
        # Criar chaves de API placeholder para desenvolvimento
        create_dev_secret "openai_api_key" "sk-dev-placeholder-key-for-testing"
        create_dev_secret "notion_api_key" "secret_dev-placeholder-key-for-testing"
        create_dev_secret "anthropic_api_key" "sk-ant-dev-placeholder-key-for-testing"
        create_dev_secret "deepseek_api_key" "sk-deepseek-dev-placeholder-key-for-testing"
    fi
    
    log "SUCCESS" "Variáveis de ambiente de desenvolvimento configuradas"
}

# Função para backup pré-deploy
pre_deploy_backup() {
    log "INFO" "Criando backup pré-deploy para ambiente de desenvolvimento..."
    
    local backup_timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_dir="$PROJECT_DIR/backups/dev-pre-deploy_$backup_timestamp"
    
    mkdir -p "$backup_dir"
    
    # Backup de configurações críticas
    cp -r "$PROJECT_DIR/config" "$backup_dir/" 2>/dev/null || true
    
    # Backup de dados se existirem
    if command -v docker >/dev/null 2>&1 && docker ps -q --filter "name=notionia_dev_postgres" >/dev/null 2>&1; then
        log "INFO" "Fazendo backup do banco de dados de desenvolvimento..."
        local db_backup="$backup_dir/database_backup.sql"
        
        docker exec notionia_dev_postgres pg_dump -U pguser_dev notionai_dev > "$db_backup" 2>/dev/null || {
            log "WARNING" "Não foi possível fazer backup do banco de dados de desenvolvimento"
        }
    fi
    
    # Criar manifesto do backup
    cat > "$backup_dir/backup_manifest.json" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "environment": "$ENVIRONMENT",
    "backup_type": "pre_deploy",
    "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
    "git_branch": "$(git branch --show-current 2>/dev/null || echo 'unknown')"
}
EOF
    
    log "SUCCESS" "Backup de desenvolvimento criado em: $backup_dir"
    echo "$backup_dir"
}

# Função para configurar ambiente Docker para desenvolvimento
setup_docker_environment() {
    log "INFO" "Configurando ambiente Docker para desenvolvimento..."
    
    # Certificar que o script tem permissão de execução
    chmod +x "$PROJECT_DIR/scripts/setup-docker-env.sh"
    
    # Detectar ambiente e configurar variáveis
    source "$PROJECT_DIR/scripts/setup-docker-env.sh"
    
    log "INFO" "Ambiente Docker configurado: DOCKER_DATA_PATH=${DOCKER_DATA_PATH}"
    
    # Criar diretório para dados de desenvolvimento
    mkdir -p "${DOCKER_DATA_PATH}/docker-data/notion-assistant/dev/data"
    mkdir -p "${DOCKER_DATA_PATH}/docker-data/notion-assistant/dev/backups"
    mkdir -p "${DOCKER_DATA_PATH}/docker-data/notion-assistant/dev/logs"
    
    log "INFO" "Diretórios para ambiente de desenvolvimento criados"
}

# Função para gerar docker-compose.dev.yml
generate_dev_docker_compose() {
    log "INFO" "Gerando docker-compose.dev.yml para ambiente de desenvolvimento..."
    
    cat > "$PROJECT_DIR/docker-compose.dev.yml" << EOF
services:
  db:
    image: postgres:15-alpine
    container_name: notionia_dev_postgres
    environment:
      # Variáveis seguras do PostgreSQL - usando somente Docker Secrets
      POSTGRES_USER: pguser_dev
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
      POSTGRES_DB: notionai_dev
      POSTGRES_HOST_AUTH_METHOD: md5
    secrets:
      - postgres_password
      - notioniauser_password
      - appuser_password
    volumes:
      - \${DOCKER_DATA_PATH:-./docker-data}/notion-assistant/dev/data:/var/lib/postgresql/data
      - \${DOCKER_DATA_PATH:-./docker-data}/notion-assistant/dev/backups:/backups
      - ./postgres-init:/docker-entrypoint-initdb.d
    command: ["postgres", "-c", "listen_addresses=*"]
    restart: unless-stopped
    networks:
      - shared_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U pguser_dev -d notionai_dev"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 15s
    ports:
      - "5433:5432"  # Mapeamento para porta diferente para não conflitar com possível instância em produção

  app:
    build:
      context: ./app
      dockerfile: Dockerfile.dev
    container_name: notionia_dev_app
    environment:
      # Variáveis de configuração do banco (não sensíveis)
      POSTGRES_USER: pguser_dev
      POSTGRES_DB: notionai_dev
      POSTGRES_HOST: db
      POSTGRES_PORT: 5432
      
      # Configurações da aplicação
      ADMIN_EMAIL: admin@notionai-dev.local
      JWT_EXPIRE_MINUTES: 1440
      DEBUG: "True"
      ENVIRONMENT: "development"
      LOG_LEVEL: "DEBUG"
      RUNNING_IN_DOCKER: "true"
      
      # Configurações opcionais (podem ser vazias)
      NOTION_PAGE_ID: ""
    secrets:
      # Secrets essenciais
      - postgres_password
      - notioniauser_password
      - appuser_password
      - jwt_secret
      - admin_password
      
      # Secrets opcionais para APIs externas (podem estar vazios)
      - openai_api_key
      - notion_api_key
      - anthropic_api_key
      - deepseek_api_key
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    networks:
      - shared_network
    volumes:
      - \${DOCKER_DATA_PATH:-./docker-data}/notion-assistant/dev/logs:/app/logs
      - ./app:/app  # Montar o código fonte para desenvolvimento (hot reload)
    ports:
      - "${API_PORT}:8080"  # API
      - "${DEV_PORT}:8501"  # Frontend

secrets:
  # Secrets essenciais para operação da aplicação
  postgres_password:
    file: ./config/secrets/development/postgres_password
  notioniauser_password:
    file: ./config/secrets/development/notioniauser_password
  appuser_password:
    file: ./config/secrets/development/appuser_password
  jwt_secret:
    file: ./config/secrets/development/jwt_secret
  admin_password:
    file: ./config/secrets/development/admin_password
    
  # Secrets opcionais para APIs externas
  openai_api_key:
    file: ./config/secrets/development/openai_api_key
  notion_api_key:
    file: ./config/secrets/development/notion_api_key
  anthropic_api_key:
    file: ./config/secrets/development/anthropic_api_key
  deepseek_api_key:
    file: ./config/secrets/development/deepseek_api_key

networks:
  shared_network:
    external: true
EOF
    
    log "SUCCESS" "Arquivo docker-compose.dev.yml criado com sucesso"
}

# Função para deploy do Docker para desenvolvimento
docker_deploy_dev() {
    log "INFO" "Iniciando deploy Docker para ambiente de desenvolvimento..."
    
    cd "$PROJECT_DIR"
    
    # Configurar ambiente Docker primeiro
    setup_docker_environment
    
    # Gerar docker-compose.dev.yml
    generate_dev_docker_compose
    
    # Parar containers existentes
    log "INFO" "Parando containers de desenvolvimento existentes..."
    docker-compose -f docker-compose.dev.yml down -v || true
    
    # Construir e iniciar novos containers
    log "INFO" "Construindo e iniciando containers de desenvolvimento..."
    docker-compose -f docker-compose.dev.yml up -d --build
    
    # Aguardar inicialização
    log "INFO" "Aguardando inicialização dos serviços de desenvolvimento..."
    sleep 10
    
    # Verificar status dos containers
    if docker ps | grep -q "notionia_dev_app" && docker ps | grep -q "notionia_dev_postgres"; then
        log "SUCCESS" "Containers de desenvolvimento iniciados com sucesso"
    else
        log "ERROR" "Falha ao iniciar containers de desenvolvimento"
        log "INFO" "Exibindo logs para diagnóstico:"
        docker-compose -f docker-compose.dev.yml logs --tail=50
        return 1
    fi
}

# Função para verificação pós-deploy
post_deploy_verification() {
    log "INFO" "Executando verificações pós-deploy para ambiente de desenvolvimento..."
    
    # Verificar saúde dos containers
    local app_healthy=false
    local db_healthy=false
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log "INFO" "Verificação $attempt/$max_attempts..."
        
        # Verificar PostgreSQL
        if docker exec notionia_dev_postgres pg_isready -U pguser_dev -d notionai_dev >/dev/null 2>&1; then
            db_healthy=true
        fi
        
        # Verificar aplicação
        if docker logs notionia_dev_app 2>&1 | grep -q "Application startup complete\|Running on http\|Streamlit app is running" >/dev/null 2>&1; then
            app_healthy=true
        fi
        
        if [ "$app_healthy" == "true" ] && [ "$db_healthy" == "true" ]; then
            break
        fi
        
        sleep 5
        ((attempt++))
    done
    
    # Relatório de verificação
    if [ "$db_healthy" == "true" ]; then
        log "SUCCESS" "PostgreSQL de desenvolvimento está saudável"
    else
        log "ERROR" "PostgreSQL de desenvolvimento não está respondendo adequadamente"
    fi
    
    if [ "$app_healthy" == "true" ]; then
        log "SUCCESS" "Aplicação de desenvolvimento está saudável"
    else
        log "WARNING" "Aplicação de desenvolvimento pode estar com problemas - verificar logs"
    fi
    
    # Exibir estatísticas finais
    echo ""
    echo "📊 ESTATÍSTICAS PÓS-DEPLOY (DESENVOLVIMENTO):"
    echo "==========================================="
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "notionia_dev"
    
    echo ""
    echo "💾 UTILIZAÇÃO DE RECURSOS:"
    echo "========================="
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep "notionia_dev"
}

# Função para relatório final
final_report() {
    local deploy_success="$1"
    local backup_path="$2"
    
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                RELATÓRIO FINAL (DESENVOLVIMENTO)            ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ "$deploy_success" == "true" ]; then
        echo -e "${GREEN}🎉 DEPLOY DE DESENVOLVIMENTO CONCLUÍDO COM SUCESSO!${NC}"
        echo ""
        echo "✅ Sistema limpo e otimizado"
        echo "✅ Variáveis de ambiente de desenvolvimento configuradas"
        echo "✅ Containers de desenvolvimento em execução"
        echo "✅ Verificações pós-deploy aprovadas"
    else
        echo -e "${RED}❌ DEPLOY DE DESENVOLVIMENTO FALHOU${NC}"
        echo ""
        echo -e "${YELLOW}📋 Passos de recuperação:${NC}"
        echo "1. Verificar logs em: $LOG_FILE"
        echo "2. Restaurar backup de: $backup_path"
        echo "3. Executar: docker-compose -f docker-compose.dev.yml logs para diagnóstico"
    fi
    
    echo ""
    echo -e "${BLUE}📋 INFORMAÇÕES IMPORTANTES:${NC}"
    echo "• Log completo: $LOG_FILE"
    echo "• Backup disponível: $backup_path"
    echo "• Secrets de desenvolvimento em: $PROJECT_DIR/config/secrets/development"
    echo ""
    echo -e "${YELLOW}🔧 COMANDOS ÚTEIS:${NC}"
    echo "• docker-compose -f docker-compose.dev.yml ps   - Verificar status dos serviços"
    echo "• docker-compose -f docker-compose.dev.yml logs - Ver logs"
    echo "• docker-compose -f docker-compose.dev.yml down - Parar serviços"
    echo "• docker-compose -f docker-compose.dev.yml up -d --build - Reiniciar serviços"
    
    if [ "$deploy_success" == "true" ]; then
        echo ""
        echo -e "${GREEN}🌐 ACESSO À APLICAÇÃO DE DESENVOLVIMENTO:${NC}"
        echo "• Frontend: http://localhost:${DEV_PORT}"
        echo "• API: http://localhost:${API_PORT}"
        echo ""
        echo -e "${YELLOW}💡 DICA:${NC} As alterações no código em ./app serão automaticamente refletidas (hot reload)"
    fi
}

# Função principal
main() {
    # Criar logs directory
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Iniciar log
    log "INFO" "Iniciando deploy automatizado para ambiente de desenvolvimento..."
    log "INFO" "Ambiente: $ENVIRONMENT"
    log "INFO" "Limpeza forçada: $FORCE_CLEAN"
    log "INFO" "Rotação de secrets: $ROTATE_SECRETS"
    log "INFO" "Porta Frontend: $DEV_PORT"
    log "INFO" "Porta API: $API_PORT"
    
    show_banner
    
    local backup_path=""
    local deploy_success=false
    
    # Executar pipeline de deploy
    if check_prerequisites; then
        if intelligent_cleanup; then
            if secure_environment_setup; then
                backup_path=$(pre_deploy_backup)
                if docker_deploy_dev; then
                    if post_deploy_verification; then
                        deploy_success=true
                        log "SUCCESS" "Pipeline de deploy de desenvolvimento concluído com sucesso!"
                    else
                        log "ERROR" "Falha na verificação pós-deploy de desenvolvimento"
                    fi
                else
                    log "ERROR" "Falha no deploy Docker para desenvolvimento"
                fi
            else
                log "ERROR" "Falha na configuração de variáveis seguras para desenvolvimento"
            fi
        else
            log "ERROR" "Falha na limpeza do projeto"
        fi
    else
        log "ERROR" "Falha na verificação de pré-requisitos"
    fi
    
    # Relatório final
    final_report "$deploy_success" "$backup_path"
    
    # Exit code baseado no sucesso
    if [ "$deploy_success" == "true" ]; then
        exit 0
    else
        exit 1
    fi
}

# Verificar argumentos de ajuda
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "Uso: $0 [force_clean] [rotate_secrets] [dev_port] [api_port]"
    echo ""
    echo "Parâmetros:"
    echo "  force_clean     - true|false (padrão: false)"
    echo "  rotate_secrets  - true|false (padrão: false)"
    echo "  dev_port        - Porta para o frontend (padrão: 8501)"
    echo "  api_port        - Porta para a API (padrão: 8080)"
    echo ""
    echo "Exemplos:"
    echo "  $0                      - Deploy padrão"
    echo "  $0 true                 - Deploy com limpeza forçada"
    echo "  $0 false true           - Deploy com rotação de secrets"
    echo "  $0 false false 3000 3001 - Deploy com portas personalizadas"
    echo ""
    echo "Ambiente:"
    echo "  Este script configura um ambiente de desenvolvimento local."
    echo "  O código fonte é montado para hot reload durante o desenvolvimento."
    exit 0
fi

# Executar deploy
main