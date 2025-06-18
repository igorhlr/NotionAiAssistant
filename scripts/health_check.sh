#!/bin/bash

# NotionAiAssistant Health Check Script
# Verifica a saúde do sistema e configurações

ENV_FILE="/home/user0/docker-secrets/open-source-secrets/.env"
PROJECT_DIR="/home/user0/open-source-projects/NotionAiAssistant"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 NotionAiAssistant - Verificação de Saúde${NC}"
echo "=========================================="

# Verificar localização
if [ "$(pwd)" != "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}📁 Navegando para diretório do projeto...${NC}"
    cd "$PROJECT_DIR" || exit 1
fi

# Verificar .env
echo -e "${BLUE}📋 Verificando arquivo de ambiente...${NC}"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}❌ Arquivo .env não encontrado!${NC}"
    echo -e "${YELLOW}💡 Execute: make setup-env${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Arquivo .env encontrado${NC}"
fi

# Verificar valores CHANGE_ME
echo -e "${BLUE}🔍 Verificando configurações padrão...${NC}"
if grep -q "CHANGE_ME" "$ENV_FILE"; then
    echo -e "${YELLOW}⚠️  Arquivo .env contém valores padrão que precisam ser configurados:${NC}"
    grep "CHANGE_ME" "$ENV_FILE" | head -5 | sed 's/^/   /'
    echo -e "${BLUE}📝 Para editar: vi $ENV_FILE${NC}"
    echo ""
else
    echo -e "${GREEN}✅ Arquivo .env configurado (sem valores padrão)${NC}"
fi

# Verificar permissões do .env
echo -e "${BLUE}🔒 Verificando permissões...${NC}"
PERMS=$(stat -c %a "$ENV_FILE" 2>/dev/null)
if [ "$PERMS" = "600" ]; then
    echo -e "${GREEN}✅ Permissões corretas (600)${NC}"
else
    echo -e "${YELLOW}⚠️  Permissões incorretas ($PERMS), corrigindo...${NC}"
    chmod 600 "$ENV_FILE"
    echo -e "${GREEN}✅ Permissões corrigidas (600)${NC}"
fi

# Verificar Docker e containers
echo -e "${BLUE}🐳 Verificando status dos containers...${NC}"
if command -v docker-compose >/dev/null 2>&1; then
    if docker-compose ps >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker Compose funcionando${NC}"
        
        # Status dos containers
        echo ""
        echo -e "${BLUE}📊 Status dos containers:${NC}"
        docker-compose ps | grep -E "(Name|notionia_)" || echo -e "${YELLOW}⚠️  Nenhum container em execução${NC}"
        
        # Verificar logs de erro
        echo ""
        echo -e "${BLUE}🔍 Verificando erros recentes nos logs:${NC}"
        ERROR_COUNT=$(docker-compose logs --tail=50 app 2>/dev/null | grep -i error | wc -l)
        if [ "$ERROR_COUNT" -gt 0 ]; then
            echo -e "${YELLOW}⚠️  Encontrados $ERROR_COUNT erros nos logs da aplicação${NC}"
            echo -e "${BLUE}📋 Últimos erros:${NC}"
            docker-compose logs --tail=50 app | grep -i error | tail -3 | sed 's/^/   /'
            echo -e "${BLUE}💡 Para ver logs completos: make logs-app${NC}"
        else
            echo -e "${GREEN}✅ Nenhum erro encontrado nos logs recentes${NC}"
        fi
        
    else
        echo -e "${YELLOW}⚠️  Docker Compose não está ativo ou tem problemas de configuração${NC}"
    fi
else
    echo -e "${RED}❌ Docker Compose não encontrado${NC}"
fi

# Verificar espaço em disco
echo ""
echo -e "${BLUE}💾 Verificando espaço em disco...${NC}"
DISK_USAGE=$(df -h "$PROJECT_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    echo -e "${YELLOW}⚠️  Uso de disco alto: ${DISK_USAGE}%${NC}"
else
    echo -e "${GREEN}✅ Espaço em disco OK: ${DISK_USAGE}% usado${NC}"
fi

# Verificar conectividade de rede
echo -e "${BLUE}🌐 Verificando conectividade...${NC}"
if ping -c 1 google.com >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Conectividade de rede OK${NC}"
else
    echo -e "${YELLOW}⚠️  Problemas de conectividade de rede${NC}"
fi

# Resumo final
echo ""
echo "=========================================="
echo -e "${BLUE}📊 Resumo da Verificação de Saúde:${NC}"

# Contagem de problemas
PROBLEMS=0
if [ ! -f "$ENV_FILE" ]; then ((PROBLEMS++)); fi
if grep -q "CHANGE_ME" "$ENV_FILE" 2>/dev/null; then ((PROBLEMS++)); fi
if [ "$ERROR_COUNT" -gt 0 ] 2>/dev/null; then ((PROBLEMS++)); fi

if [ "$PROBLEMS" -eq 0 ]; then
    echo -e "${GREEN}🎉 Sistema está saudável! Nenhum problema crítico encontrado.${NC}"
    echo -e "${BLUE}💡 Para monitoramento contínuo: make monitor${NC}"
else
    echo -e "${YELLOW}⚠️  Encontrados $PROBLEMS problemas que precisam de atenção.${NC}"
    echo -e "${BLUE}💡 Execute as correções sugeridas acima.${NC}"
fi

echo ""
echo -e "${BLUE}📋 Comandos úteis:${NC}"
echo -e "   ${GREEN}make setup-env${NC}     - Configurar arquivo .env"
echo -e "   ${GREEN}make validate-env${NC}  - Validar configurações"
echo -e "   ${GREEN}make start${NC}         - Iniciar aplicação"
echo -e "   ${GREEN}make status${NC}        - Verificar status"
echo -e "   ${GREEN}make logs-follow${NC}   - Acompanhar logs"
echo -e "   ${GREEN}make monitor${NC}       - Monitoramento completo"

echo "=========================================="
