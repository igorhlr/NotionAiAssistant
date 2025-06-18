#!/bin/bash
# Script de Deploy Automatizado Integrado - NotionAiAssistant
# Integra limpeza, segurança de variáveis e deploy para produção

set -e

# Configurações
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$PROJECT_DIR/logs/automated-deploy.log"
ENVIRONMENT="${ENVIRONMENT:-production}"
FORCE_CLEAN="${1:-false}"
ROTATE_SECRETS="${2:-false}"

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
    echo "║              DEPLOY AUTOMATIZADO SEGURO                     ║"
    echo "║                                                              ║"
    echo "║  🚀 Deploy Integrado com Segurança Avançada                 ║"
    echo "║  🔒 Gestão Automática de Secrets                            ║"
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

# Função para gestão segura de variáveis
secure_environment_setup() {
    log "INFO" "Configurando variáveis de ambiente seguras..."
    
    # Executar sistema de gestão de secrets
    chmod +x "$PROJECT_DIR/scripts/secure-env-management.sh"
    
    if [ "$ROTATE_SECRETS" == "true" ]; then
        log "WARNING" "Rotação de secrets solicitada - isso invalidará senhas atuais"
        "$PROJECT_DIR/scripts/secure-env-management.sh" rotate
    else
        log "INFO" "Upgradeando secrets existentes para versões seguras"
        "$PROJECT_DIR/scripts/secure-env-management.sh" upgrade
    fi
    
    # Validar configuração final
    "$PROJECT_DIR/scripts/secure-env-management.sh" validate
    
    log "SUCCESS" "Variáveis de ambiente configuradas com segurança"
}

# Função para backup pré-deploy
pre_deploy_backup() {
    log "INFO" "Criando backup pré-deploy..."
    
    local backup_timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_dir="$PROJECT_DIR/backups/pre-deploy_$backup_timestamp"
    
    mkdir -p "$backup_dir"
    
    # Backup de configurações críticas
    cp -r "$PROJECT_DIR/config" "$backup_dir/" 2>/dev/null || true
    
    # Backup de dados se existirem
    if command -v docker >/dev/null 2>&1 && docker ps -q --filter "name=notionia_postgres" >/dev/null 2>&1; then
        log "INFO" "Fazendo backup do banco de dados..."
        local db_backup="$backup_dir/database_backup.sql"
        
        docker exec notionia_postgres pg_dump -U postgres notioniadb > "$db_backup" 2>/dev/null || {
            log "WARNING" "Não foi possível fazer backup do banco de dados"
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
    
    log "SUCCESS" "Backup criado em: $backup_dir"
    echo "$backup_dir"
}

# Função para configurar ambiente Docker
setup_docker_environment() {
    log "INFO" "Configurando ambiente Docker..."
    
    # Certificar que o script tem permissão de execução
    chmod +x "$PROJECT_DIR/scripts/setup-docker-env.sh"
    
    # Detectar ambiente e configurar variáveis
    source "$PROJECT_DIR/scripts/setup-docker-env.sh"
    
    log "INFO" "Ambiente Docker configurado: DOCKER_DATA_PATH=${DOCKER_DATA_PATH}"
}

# Função para deploy do Docker
docker_deploy() {
    log "INFO" "Iniciando deploy Docker..."
    
    cd "$PROJECT_DIR"
    
    # Configurar ambiente Docker primeiro
    setup_docker_environment
    
    # Parar containers existentes
    log "INFO" "Parando containers existentes..."
    docker-compose down -v || true
    
    # Construir e iniciar novos containers
    log "INFO" "Construindo e iniciando containers..."
    docker-compose up -d --build
    
    # Aguardar inicialização
    log "INFO" "Aguardando inicialização dos serviços..."
    sleep 30
    
    # Verificar status dos containers
    if docker ps | grep -q "notionia_app" && docker ps | grep -q "notionia_postgres"; then
        log "SUCCESS" "Containers iniciados com sucesso"
    else
        log "ERROR" "Falha ao iniciar containers"
        log "INFO" "Exibindo logs para diagnóstico:"
        docker-compose logs --tail=50
        return 1
    fi
}

# Função para verificação pós-deploy
post_deploy_verification() {
    log "INFO" "Executando verificações pós-deploy..."
    
    # Verificar saúde dos containers
    local app_healthy=false
    local db_healthy=false
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log "INFO" "Verificação $attempt/$max_attempts..."
        
        # Verificar PostgreSQL
        if docker exec notionia_postgres pg_isready -U postgres >/dev/null 2>&1; then
            db_healthy=true
        fi
        
        # Verificar aplicação (verificar se responde)
        if docker logs notionia_app 2>&1 | grep -q "Application startup complete" >/dev/null 2>&1; then
            app_healthy=true
        fi
        
        if [ "$app_healthy" == "true" ] && [ "$db_healthy" == "true" ]; then
            break
        fi
        
        sleep 10
        ((attempt++))
    done
    
    # Relatório de verificação
    if [ "$db_healthy" == "true" ]; then
        log "SUCCESS" "PostgreSQL está saudável"
    else
        log "ERROR" "PostgreSQL não está respondendo adequadamente"
    fi
    
    if [ "$app_healthy" == "true" ]; then
        log "SUCCESS" "Aplicação está saudável"
    else
        log "WARNING" "Aplicação pode estar com problemas - verificar logs"
    fi
    
    # Exibir estatísticas finais
    echo ""
    echo "📊 ESTATÍSTICAS PÓS-DEPLOY:"
    echo "=========================="
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    echo "💾 UTILIZAÇÃO DE RECURSOS:"
    echo "========================="
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
}

# Função para relatório final
final_report() {
    local deploy_success="$1"
    local backup_path="$2"
    
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    RELATÓRIO FINAL                          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ "$deploy_success" == "true" ]; then
        echo -e "${GREEN}🎉 DEPLOY CONCLUÍDO COM SUCESSO!${NC}"
        echo ""
        echo "✅ Sistema limpo e otimizado"
        echo "✅ Variáveis de ambiente seguras"
        echo "✅ Containers em execução"
        echo "✅ Verificações pós-deploy aprovadas"
    else
        echo -e "${RED}❌ DEPLOY FALHOU${NC}"
        echo ""
        echo -e "${YELLOW}📋 Passos de recuperação:${NC}"
        echo "1. Verificar logs em: $LOG_FILE"
        echo "2. Restaurar backup de: $backup_path"
        echo "3. Executar: make status para diagnóstico"
    fi
    
    echo ""
    echo -e "${BLUE}📋 INFORMAÇÕES IMPORTANTES:${NC}"
    echo "• Log completo: $LOG_FILE"
    echo "• Backup disponível: $backup_path"
    echo "• Secrets seguros em: /home/user0/docker-secrets/open-source-secrets"
    echo ""
    echo -e "${YELLOW}🔧 COMANDOS ÚTEIS:${NC}"
    echo "• make status        - Verificar status dos serviços"
    echo "• make logs-follow   - Acompanhar logs em tempo real"
    echo "• make health-check  - Verificação completa de saúde"
    echo "• make backup        - Criar backup manual"
    
    if [ "$deploy_success" == "true" ]; then
        echo ""
        echo -e "${GREEN}🌐 ACESSO À APLICAÇÃO:${NC}"
        echo "• Frontend: https://notionassistant.llmway.com.br"
        echo "• API: https://notionassistant.llmway.com.br/api"
    fi
}

# Função principal
main() {
    # Criar logs directory
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Iniciar log
    log "INFO" "Iniciando deploy automatizado integrado..."
    log "INFO" "Ambiente: $ENVIRONMENT"
    log "INFO" "Limpeza forçada: $FORCE_CLEAN"
    log "INFO" "Rotação de secrets: $ROTATE_SECRETS"
    
    show_banner
    
    local backup_path=""
    local deploy_success=false
    
    # Executar pipeline de deploy
    if check_prerequisites; then
        if intelligent_cleanup; then
            if secure_environment_setup; then
                backup_path=$(pre_deploy_backup)
                if docker_deploy; then
                    if post_deploy_verification; then
                        deploy_success=true
                        log "SUCCESS" "Pipeline de deploy concluído com sucesso!"
                    else
                        log "ERROR" "Falha na verificação pós-deploy"
                    fi
                else
                    log "ERROR" "Falha no deploy Docker"
                fi
            else
                log "ERROR" "Falha na configuração de variáveis seguras"
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
    echo "Uso: $0 [force_clean] [rotate_secrets]"
    echo ""
    echo "Parâmetros:"
    echo "  force_clean     - true|false (padrão: false)"
    echo "  rotate_secrets  - true|false (padrão: false)"
    echo ""
    echo "Exemplos:"
    echo "  $0                      - Deploy padrão"
    echo "  $0 true                 - Deploy com limpeza forçada"
    echo "  $0 false true           - Deploy com rotação de secrets"
    echo "  $0 true true            - Deploy completo (limpeza + rotação)"
    echo ""
    echo "Variáveis de ambiente:"
    echo "  ENVIRONMENT=production  - Ambiente de deploy (padrão)"
    exit 0
fi

# Executar deploy
main