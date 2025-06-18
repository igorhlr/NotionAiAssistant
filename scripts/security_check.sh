#!/bin/bash
# Script para verificação de segurança do NotionAiAssistant
# Autor: Claude
# Data: 02/06/2025

# Cores para output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Diretório do projeto
PROJECT_DIR=$(pwd)
ENV_FILE="/home/user0/docker-secrets/open-source-secrets/.env"

echo -e "${BLUE}Executando verificação de segurança...${NC}"

# Variáveis para contar problemas
WARNINGS=0
CRITICAL=0

# Função para verificar vazamento de segredos
check_secrets() {
    echo -e "${YELLOW}Verificando vazamento de segredos...${NC}"
    
    # Lista de padrões de segredos
    local patterns=(
        "sk-[a-zA-Z0-9]{48}" # OpenAI API Key
        "secret.*['\"][a-zA-Z0-9]{16,}['\"]" # Generic secrets
        "password.*['\"][a-zA-Z0-9]{8,}['\"]" # Passwords
        "apikey.*['\"][a-zA-Z0-9]{8,}['\"]" # API Keys
        "-----BEGIN PRIVATE KEY-----" # Private keys
        "aws_access_key_id" # AWS credentials
        "jwt_secret.*['\"][a-zA-Z0-9]{16,}['\"]" # JWT secrets
    )
    
    # Arquivos a ignorar
    local ignore_files=(
        ".env"
        ".env.example"
        ".env.local"
        "*.md"
        "*.log"
        "*.pyc"
        "venv/*"
        "node_modules/*"
        "__pycache__/*"
    )
    
    # Construir string de exclusão
    local exclude=""
    for file in "${ignore_files[@]}"; do
        exclude="$exclude --exclude='$file'"
    done
    
    # Verificar cada padrão
    for pattern in "${patterns[@]}"; do
        # shellcheck disable=SC2086
        results=$(grep -r --include="*.py" --include="*.js" --include="*.ts" --include="*.yml" --include="*.yaml" --include="*.json" --include="*.sh" $exclude "$pattern" "$PROJECT_DIR" 2>/dev/null)
        
        if [ -n "$results" ]; then
            echo -e "${RED}ALERTA: Possível vazamento de segredo encontrado:${NC}"
            echo "$results" | head -n 5
            if [ "$(echo "$results" | wc -l)" -gt 5 ]; then
                echo -e "${YELLOW}... e mais $(( $(echo "$results" | wc -l) - 5 )) ocorrências.${NC}"
            fi
            CRITICAL=$((CRITICAL + 1))
        fi
    done
    
    if [ $CRITICAL -eq 0 ]; then
        echo -e "${GREEN}Nenhum vazamento de segredo encontrado.${NC}"
    fi
}

# Verificar permissões de arquivos sensíveis
check_permissions() {
    echo -e "${YELLOW}Verificando permissões de arquivos sensíveis...${NC}"
    
    # Verificar permissões do arquivo .env
    if [ -f "$ENV_FILE" ]; then
        perms=$(stat -c "%a" "$ENV_FILE")
        if [ "$perms" != "640" ] && [ "$perms" != "600" ]; then
            echo -e "${RED}ALERTA: Permissões incorretas no arquivo $ENV_FILE: $perms (deveria ser 640 ou 600)${NC}"
            CRITICAL=$((CRITICAL + 1))
        else
            echo -e "${GREEN}Permissões corretas no arquivo $ENV_FILE: $perms${NC}"
        fi
    else
        echo -e "${YELLOW}Arquivo .env não encontrado em $ENV_FILE${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # Verificar permissões dos scripts
    for script in $(find "$PROJECT_DIR/scripts" -name "*.sh" 2>/dev/null); do
        if [ ! -x "$script" ]; then
            echo -e "${YELLOW}AVISO: Script $script não é executável${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
}

# Verificar configuração de Docker
check_docker_config() {
    echo -e "${YELLOW}Verificando configuração do Docker...${NC}"
    
    # Verificar se o Docker está em execução
    if ! docker info >/dev/null 2>&1; then
        echo -e "${YELLOW}AVISO: Docker não está em execução ou o usuário não tem permissões${NC}"
        WARNINGS=$((WARNINGS + 1))
        return
    fi
    
    # Verificar se seccomp está habilitado
    if docker info --format '{{.SecurityOptions}}' | grep -q "name=seccomp,profile=default"; then
        echo -e "${GREEN}Seccomp está habilitado no Docker${NC}"
    else
        echo -e "${YELLOW}AVISO: Seccomp não está habilitado no Docker${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # Verificar se a rede compartilhada existe
    if docker network ls | grep -q "shared_network"; then
        echo -e "${GREEN}Rede shared_network existe${NC}"
    else
        echo -e "${YELLOW}AVISO: Rede shared_network não existe${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
}

# Verificar configuração do GitHub
check_github_config() {
    echo -e "${YELLOW}Verificando configuração do GitHub...${NC}"
    
    # Verificar se o diretório .github existe
    if [ -d "$PROJECT_DIR/.github" ]; then
        echo -e "${GREEN}Diretório .github encontrado${NC}"
        
        # Verificar se há workflows configurados
        if [ -d "$PROJECT_DIR/.github/workflows" ]; then
            workflows=$(find "$PROJECT_DIR/.github/workflows" -name "*.yml" -o -name "*.yaml" | wc -l)
            echo -e "${GREEN}$workflows workflows encontrados em .github/workflows/${NC}"
            
            # Verificar conteúdo dos workflows
            for workflow in $(find "$PROJECT_DIR/.github/workflows" -name "*.yml" -o -name "*.yaml"); do
                if grep -q "uses: actions/checkout@" "$workflow"; then
                    if ! grep -q "uses: actions/checkout@v[4-9]" "$workflow"; then
                        echo -e "${YELLOW}AVISO: Workflow $workflow usa versão antiga do actions/checkout${NC}"
                        WARNINGS=$((WARNINGS + 1))
                    fi
                fi
                
                # Verificar se há segredos sendo usados
                if grep -q "secrets\\." "$workflow"; then
                    echo -e "${GREEN}Workflow $workflow usa segredos do GitHub${NC}"
                else
                    echo -e "${YELLOW}AVISO: Workflow $workflow não parece usar segredos do GitHub${NC}"
                    WARNINGS=$((WARNINGS + 1))
                fi
            done
        else
            echo -e "${YELLOW}AVISO: Diretório .github/workflows não encontrado${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo -e "${YELLOW}AVISO: Diretório .github não encontrado${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
}

# Verificar variáveis de ambiente
check_env_vars() {
    echo -e "${YELLOW}Verificando variáveis de ambiente...${NC}"
    
    if [ -f "$ENV_FILE" ]; then
        # Lista de variáveis obrigatórias
        required_vars=(
            "DATABASE_URL"
            "POSTGRES_USER"
            "POSTGRES_PASSWORD"
            "POSTGRES_DB"
            "JWT_SECRET"
            "ADMIN_EMAIL"
            "ADMIN_PASSWORD"
            "OPENAI_API_KEY"
            "NOTION_API_KEY"
            "NOTION_PAGE_ID"
        )
        
        missing=0
        for var in "${required_vars[@]}"; do
            if ! grep -q "^$var=" "$ENV_FILE"; then
                echo -e "${YELLOW}AVISO: Variável $var não encontrada em $ENV_FILE${NC}"
                missing=$((missing + 1))
            fi
        done
        
        if [ $missing -eq 0 ]; then
            echo -e "${GREEN}Todas as variáveis obrigatórias estão presentes em $ENV_FILE${NC}"
        else
            echo -e "${YELLOW}AVISO: $missing variáveis obrigatórias estão faltando em $ENV_FILE${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo -e "${YELLOW}AVISO: Arquivo .env não encontrado em $ENV_FILE${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
}

# Executar verificações
check_secrets
check_permissions
check_docker_config
check_github_config
check_env_vars

# Resumo
echo ""
echo -e "${BLUE}Resumo da verificação de segurança:${NC}"
echo -e "${YELLOW}Avisos: $WARNINGS${NC}"
echo -e "${RED}Problemas críticos: $CRITICAL${NC}"

if [ $CRITICAL -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}Nenhum problema encontrado!${NC}"
    exit 0
elif [ $CRITICAL -eq 0 ]; then
    echo -e "${YELLOW}Verificação concluída com avisos. Recomenda-se revisar antes de prosseguir.${NC}"
    exit 0
else
    echo -e "${RED}Verificação falhou! Corrija os problemas críticos antes de prosseguir.${NC}"
    exit 1
fi
