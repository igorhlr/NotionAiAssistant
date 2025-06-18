#!/bin/bash
# Sistema Avançado de Gerenciamento de Variáveis de Ambiente Seguras
# NotionAiAssistant - Produção Automatizada com Rotação de Secrets

set -e

# Configurações
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_DIR="$PROJECT_DIR/config/secrets"
PRODUCTION_SECRETS_DIR="$SECRETS_DIR/production"
ENV_FILE="/home/user0/docker-secrets/open-source-secrets/.env"
BACKUP_DIR="$PROJECT_DIR/backups/secrets"
LOG_FILE="$PROJECT_DIR/logs/secrets-management.log"

# Criar diretórios se não existirem
mkdir -p "$PRODUCTION_SECRETS_DIR" "$BACKUP_DIR" "$(dirname "$LOG_FILE")"

# Função de logging
log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

# Função para gerar senha segura
generate_secure_password() {
    local length="${1:-32}"
    local chars="A-Za-z0-9!@#$%^&*()-_=+[]{}|;:,.<>?"
    
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 48 | tr -dc "$chars" | head -c "$length"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "import secrets, string; chars='$chars'; print(''.join(secrets.choice(chars) for _ in range($length)))"
    else
        # Fallback para /dev/urandom
        cat /dev/urandom | tr -dc "$chars" | head -c "$length"
    fi
}

# Função para gerar JWT secret
generate_jwt_secret() {
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -hex 64
    else
        generate_secure_password 64
    fi
}

# Função para backup dos secrets atuais
backup_current_secrets() {
    log "INFO" "Criando backup dos secrets atuais..."
    
    if [ -d "$PRODUCTION_SECRETS_DIR" ] && [ "$(ls -A "$PRODUCTION_SECRETS_DIR" 2>/dev/null)" ]; then
        local backup_timestamp=$(date '+%Y%m%d_%H%M%S')
        local backup_path="$BACKUP_DIR/secrets_backup_$backup_timestamp"
        
        mkdir -p "$backup_path"
        cp -r "$PRODUCTION_SECRETS_DIR"/* "$backup_path/" 2>/dev/null || true
        
        # Criar arquivo de metadados do backup
        cat > "$backup_path/backup_metadata.json" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "environment": "production",
    "backup_type": "secrets_rotation",
    "files_count": $(ls -1 "$PRODUCTION_SECRETS_DIR" | wc -l),
    "created_by": "secure-env-management-system"
}
EOF
        
        log "INFO" "Backup criado em: $backup_path"
        echo "$backup_path"
    else
        log "WARNING" "Nenhum secret existente para backup"
        echo ""
    fi
}

# Função para criar secret seguro
create_secure_secret() {
    local secret_name="$1"
    local secret_value="$2"
    local force_update="${3:-false}"
    local secret_file="$PRODUCTION_SECRETS_DIR/$secret_name"
    
    if [ -f "$secret_file" ] && [ "$force_update" != "true" ]; then
        log "INFO" "Secret $secret_name já existe, mantendo valor atual"
        return 0
    fi
    
    echo -n "$secret_value" > "$secret_file"
    chmod 600 "$secret_file"
    
    log "INFO" "Secret $secret_name criado/atualizado com sucesso"
}

# Função para validar secrets obrigatórios
validate_required_secrets() {
    log "INFO" "Validando secrets obrigatórios..."
    
    local required_secrets=(
        "postgres_password"
        "jwt_secret"
        "admin_password"
        "openai_api_key"
        "notion_api_key"
    )
    
    local missing_secrets=()
    
    for secret in "${required_secrets[@]}"; do
        if [ ! -f "$PRODUCTION_SECRETS_DIR/$secret" ] || [ ! -s "$PRODUCTION_SECRETS_DIR/$secret" ]; then
            missing_secrets+=("$secret")
        fi
    done
    
    if [ ${#missing_secrets[@]} -gt 0 ]; then
        log "ERROR" "Secrets obrigatórios faltando: ${missing_secrets[*]}"
        return 1
    fi
    
    log "INFO" "Todos os secrets obrigatórios estão presentes"
    return 0
}

# Função para rotacionar secrets
rotate_secrets() {
    local rotate_all="${1:-false}"
    
    log "INFO" "Iniciando rotação de secrets..."
    
    # Backup antes da rotação
    local backup_path=$(backup_current_secrets)
    
    # Rotacionar senhas de sistema (sempre rotacionar por segurança)
    create_secure_secret "postgres_password" "$(generate_secure_password 32)" "true"
    create_secure_secret "notioniauser_password" "$(generate_secure_password 32)" "true"
    create_secure_secret "appuser_password" "$(generate_secure_password 32)" "true"
    create_secure_secret "admin_password" "$(generate_secure_password 24)" "true"
    create_secure_secret "jwt_secret" "$(generate_jwt_secret)" "true"
    
    # Rotacionar API keys apenas se force_all for true
    if [ "$rotate_all" == "true" ]; then
        log "WARNING" "Rotação completa solicitada - API keys serão invalidadas"
        log "WARNING" "Certifique-se de atualizar as API keys reais antes do deploy"
        
        create_secure_secret "openai_api_key" "sk-rotated-$(date +%s)-REPLACE-WITH-REAL-KEY" "true"
        create_secure_secret "notion_api_key" "secret_rotated-$(date +%s)-REPLACE-WITH-REAL-KEY" "true"
        create_secure_secret "anthropic_api_key" "sk-ant-rotated-$(date +%s)-REPLACE-WITH-REAL-KEY" "true"
        create_secure_secret "deepseek_api_key" "sk-deepseek-rotated-$(date +%s)-REPLACE-WITH-REAL-KEY" "true"
    fi
    
    log "INFO" "Rotação de secrets concluída"
    
    if [ -n "$backup_path" ]; then
        log "INFO" "Backup disponível em: $backup_path"
    fi
}

# Função para criar secrets iniciais seguros
create_initial_secure_secrets() {
    log "INFO" "Criando secrets iniciais seguros..."
    
    # Carregar .env se existir
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
        log "INFO" "Variáveis carregadas de $ENV_FILE"
    fi
    
    # Secrets obrigatórios com valores seguros
    create_secure_secret "postgres_password" "${POSTGRES_PASSWORD:-$(generate_secure_password 32)}"
    create_secure_secret "jwt_secret" "${JWT_SECRET:-$(generate_jwt_secret)}"
    create_secure_secret "admin_password" "${ADMIN_PASSWORD:-$(generate_secure_password 24)}"
    
    # API Keys (usar do .env ou placeholders seguros)
    create_secure_secret "openai_api_key" "${OPENAI_API_KEY:-sk-placeholder-CONFIGURE-REAL-KEY}"
    create_secure_secret "notion_api_key" "${NOTION_API_KEY:-secret_placeholder-CONFIGURE-REAL-KEY}"
    
    # Secrets opcionais com valores seguros padrão
    create_secure_secret "notioniauser_password" "$(generate_secure_password 32)"
    create_secure_secret "appuser_password" "$(generate_secure_password 32)"
    create_secure_secret "anthropic_api_key" "${ANTHROPIC_API_KEY:-sk-ant-placeholder-CONFIGURE-IF-NEEDED}"
    create_secure_secret "deepseek_api_key" "${DEEPSEEK_API_KEY:-sk-deepseek-placeholder-CONFIGURE-IF-NEEDED}"
    
    log "INFO" "Secrets iniciais criados com sucesso"
}

# Função para verificar e melhorar secrets existentes
upgrade_existing_secrets() {
    log "INFO" "Verificando e melhorando secrets existentes..."
    
    # Lista de secrets que devem ser atualizados se contiverem valores inseguros
    local insecure_secrets=(
        "admin_password:change-this-admin-password"
        "postgres_password:postgres_secure_password"
        "notioniauser_password:NotionIA_User2025!"
        "appuser_password:AppUser_Secure2025!"
        "jwt_secret:your-secret-key-here"
    )
    
    local updated_secrets=()
    
    for item in "${insecure_secrets[@]}"; do
        local secret_name="${item%%:*}"
        local insecure_value="${item##*:}"
        local secret_file="$PRODUCTION_SECRETS_DIR/$secret_name"
        
        if [ -f "$secret_file" ]; then
            local current_value=$(cat "$secret_file" 2>/dev/null || echo "")
            
            if [ "$current_value" == "$insecure_value" ] || [ ${#current_value} -lt 16 ]; then
                log "WARNING" "Secret $secret_name contém valor inseguro, atualizando..."
                
                if [ "$secret_name" == "jwt_secret" ]; then
                    create_secure_secret "$secret_name" "$(generate_jwt_secret)" "true"
                else
                    create_secure_secret "$secret_name" "$(generate_secure_password 32)" "true"
                fi
                
                updated_secrets+=("$secret_name")
            fi
        fi
    done
    
    if [ ${#updated_secrets[@]} -gt 0 ]; then
        log "INFO" "Secrets atualizados por segurança: ${updated_secrets[*]}"
    else
        log "INFO" "Todos os secrets estão seguros"
    fi
}

# Função principal
main() {
    local action="${1:-create}"
    
    case "$action" in
        "create"|"init")
            log "INFO" "Inicializando sistema de secrets seguros..."
            create_initial_secure_secrets
            upgrade_existing_secrets
            validate_required_secrets
            ;;
        "rotate")
            log "INFO" "Rotacionando secrets..."
            rotate_secrets "${2:-false}"
            validate_required_secrets
            ;;
        "upgrade")
            log "INFO" "Melhorando secrets existentes..."
            upgrade_existing_secrets
            validate_required_secrets
            ;;
        "validate")
            log "INFO" "Validando secrets..."
            validate_required_secrets
            ;;
        "backup")
            log "INFO" "Criando backup de secrets..."
            backup_current_secrets
            ;;
        *)
            echo "Uso: $0 {create|rotate|upgrade|validate|backup} [force_all]"
            echo ""
            echo "Ações:"
            echo "  create   - Criar secrets iniciais seguros"
            echo "  rotate   - Rotacionar secrets (adicione 'force_all' para incluir API keys)"
            echo "  upgrade  - Melhorar secrets existentes inseguros"
            echo "  validate - Validar se todos os secrets obrigatórios existem"
            echo "  backup   - Criar backup dos secrets atuais"
            exit 1
            ;;
    esac
    
    log "INFO" "Operação '$action' concluída com sucesso"
    
    # Mostrar resumo
    echo ""
    echo "📊 RESUMO DOS SECRETS:"
    echo "====================="
    
    if [ -d "$PRODUCTION_SECRETS_DIR" ]; then
        for secret_file in "$PRODUCTION_SECRETS_DIR"/*; do
            if [ -f "$secret_file" ]; then
                local secret_name=$(basename "$secret_file")
                local secret_size=$(stat -f%z "$secret_file" 2>/dev/null || stat -c%s "$secret_file" 2>/dev/null || echo "0")
                echo "✅ $secret_name ($secret_size bytes)"
            fi
        done
    fi
    
    echo ""
    echo "📁 Secrets localizados em: $PRODUCTION_SECRETS_DIR"
    echo "📋 Log completo em: $LOG_FILE"
    
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        echo "💾 Backups disponíveis em: $BACKUP_DIR"
    fi
}

# Executar função principal com parâmetros
main "$@"
