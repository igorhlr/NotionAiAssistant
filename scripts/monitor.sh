#!/bin/bash

# Script de monitoramento do NotionAiAssistant
# Autor: Claude
# Data: May 29, 2025

# Cores para saída
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== NotionAiAssistant - Monitoramento ===${NC}"
echo "Data e hora: $(date)"
echo

# Verificar containers em execução
echo -e "${BLUE}🐳 Containers em execução:${NC}"
docker ps --filter "name=notionia_*" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo

# Verificar uso de recursos
echo -e "${BLUE}📊 Uso de recursos:${NC}"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" notionia_app notionia_postgres
echo

# Verificar status de saúde dos serviços
echo -e "${BLUE}🩺 Status de saúde dos serviços:${NC}"

# Verificar banco de dados
echo -n "PostgreSQL: "
if docker exec notionia_postgres pg_isready -U notioniauser -d notioniadb > /dev/null 2>&1; then
    echo -e "${GREEN}Operacional✅${NC}"
else
    echo -e "${RED}Falha❌${NC}"
fi

# Verificar API
echo -n "API: "
if curl -s http://localhost:8080/api/health | grep -q "ok"; then
    echo -e "${GREEN}Operacional✅${NC}"
else
    echo -e "${RED}Falha❌${NC}"
fi

# Verificar Frontend
echo -n "Frontend: "
if curl -s http://localhost:8501 > /dev/null 2>&1; then
    echo -e "${GREEN}Operacional✅${NC}"
else
    echo -e "${RED}Falha❌${NC}"
fi

# Verificar logs para erros
echo -e "${BLUE}📝 Verificando logs para erros (últimas 24h):${NC}"
echo -e "${YELLOW}Backend:${NC}"
ERROR_COUNT=$(docker logs --since 24h notionia_app 2>&1 | grep -i "error" | wc -l)
WARN_COUNT=$(docker logs --since 24h notionia_app 2>&1 | grep -i "warn" | wc -l)
echo "- Erros: $ERROR_COUNT"
echo "- Avisos: $WARN_COUNT"

echo -e "${YELLOW}PostgreSQL:${NC}"
PG_ERROR_COUNT=$(docker logs --since 24h notionia_postgres 2>&1 | grep -i "error" | wc -l)
PG_WARN_COUNT=$(docker logs --since 24h notionia_postgres 2>&1 | grep -i "warn" | wc -l)
echo "- Erros: $PG_ERROR_COUNT"
echo "- Avisos: $PG_WARN_COUNT"

# Verificar espaço em disco
echo -e "${BLUE}💾 Espaço em disco:${NC}"
echo "Volume de dados do PostgreSQL:"
du -sh /home/user0/docker-data/notion-assistant/postgres-data

echo "Backups:"
du -sh /home/user0/docker-data/notion-assistant/backups

# Resumo de estatísticas
echo -e "${BLUE}📈 Resumo de estatísticas:${NC}"
# Contar usuários (exemplo - ajuste conforme sua estrutura de banco)
USER_COUNT=$(docker exec notionia_postgres psql -U notioniauser -d notioniadb -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "N/A")
echo "- Total de usuários: $USER_COUNT"

# Tempo de atividade
echo -e "${BLUE}⏱️ Tempo de atividade:${NC}"
echo "App: $(docker inspect --format='{{.State.StartedAt}}' notionia_app | xargs -I{} bash -c 'echo $(( $(date +%s) - $(date -d {} +%s) )) / 60 " minutos"')"
echo "PostgreSQL: $(docker inspect --format='{{.State.StartedAt}}' notionia_postgres | xargs -I{} bash -c 'echo $(( $(date +%s) - $(date -d {} +%s) )) / 60 " minutos"')"

echo -e "${BLUE}=====================================${NC}"
