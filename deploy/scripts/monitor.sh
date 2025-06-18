#!/bin/bash
# Script de monitoramento para NotionIA

# Configurações
APP_CONTAINER="notionia_app"
DB_CONTAINER="notioniadb"
LOG_FILE="/home/user0/open-source-projects/NotionAiAssistant/logs/monitor.log"
ALERT_EMAIL="seu-email@example.com"  # Substitua pelo seu email

# Função para enviar alertas
send_alert() {
    echo "[$(date)] ALERTA: $1" >> "$LOG_FILE"
    # Descomente para enviar emails reais
    # echo "$1" | mail -s "Alerta NotionIA: $1" "$ALERT_EMAIL"
    echo "Alerta: $1"
}

# Verificar se os containers estão rodando
check_containers() {
    if ! docker ps | grep -q "$APP_CONTAINER"; then
        send_alert "Container da aplicação não está rodando"
        return 1
    fi
    
    if ! docker ps | grep -q "$DB_CONTAINER"; then
        send_alert "Container do banco de dados não está rodando"
        return 1
    fi
    
    return 0
}

# Verificar uso de recursos
check_resources() {
    # Uso de CPU do container da aplicação (%)
    CPU_USAGE=$(docker stats $APP_CONTAINER --no-stream --format "{{.CPUPerc}}" | sed 's/%//g')
    
    # Uso de memória do container da aplicação (%)
    MEM_USAGE=$(docker stats $APP_CONTAINER --no-stream --format "{{.MemPerc}}" | sed 's/%//g')
    
    # Verificar limites
    if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
        send_alert "Uso elevado de CPU: $CPU_USAGE%"
    fi
    
    if (( $(echo "$MEM_USAGE > 80" | bc -l) )); then
        send_alert "Uso elevado de memória: $MEM_USAGE%"
    fi
}

# Verificar saúde da aplicação
check_health() {
    # Verificar endpoint de saúde
    HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8085/api/health)
    
    if [ "$HEALTH_STATUS" != "200" ]; then
        send_alert "API não está respondendo corretamente. Status: $HEALTH_STATUS"
    fi
}

# Verificar espaço em disco
check_disk() {
    # Uso do disco (%)
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//g')
    
    if [ "$DISK_USAGE" -gt 80 ]; then
        send_alert "Espaço em disco baixo: $DISK_USAGE%"
    fi
}

# Executar verificações
echo "[$(date)] Iniciando verificações de monitoramento..." >> "$LOG_FILE"

check_containers
if [ $? -eq 0 ]; then
    check_resources
    check_health
fi
check_disk

echo "[$(date)] Verificações concluídas" >> "$LOG_FILE"
