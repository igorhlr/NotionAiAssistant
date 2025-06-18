#!/bin/bash
# Script de detecção de ambiente para configuração do Docker
# Este script detecta automaticamente o ambiente e configura o caminho correto para volumes Docker

# Detectar sistema operacional
OS=$(uname -s)

# Detectar tipo de ambiente (local vs produção)
if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
    # Rodando dentro de um container (produção)
    ENV_TYPE="production"
else
    # Desenvolvimento local
    ENV_TYPE="development"
fi

# Verificar se existe arquivo de configuração local
CONFIG_FILE="./config/local-env.conf"
USER_DATA_PATH=""

if [ "$ENV_TYPE" = "development" ] && [ -f "$CONFIG_FILE" ]; then
    # Lê o caminho personalizado do arquivo de configuração
    USER_DATA_PATH=$(grep -v "^#" "$CONFIG_FILE" | grep "DOCKER_DATA_PATH" | cut -d "=" -f2- | tr -d '"' | tr -d "'" | xargs)
    if [ ! -z "$USER_DATA_PATH" ]; then
        echo "Usando caminho personalizado do arquivo de configuração: $USER_DATA_PATH"
    fi
fi

# Definir caminho base de dados com base no sistema e ambiente
if [ "$ENV_TYPE" = "production" ]; then
    # Ambiente de produção - caminho fixo
    if [ "$OS" = "Linux" ]; then
        DOCKER_DATA_PATH="/home/user0"
    else
        # Fallback para outros sistemas em produção (improvável)
        DOCKER_DATA_PATH="/home/user0"
    fi
else
    # Ambiente de desenvolvimento local
    if [ ! -z "$USER_DATA_PATH" ]; then
        # Usar o caminho definido pelo usuário
        DOCKER_DATA_PATH="$USER_DATA_PATH"
    elif [ "$OS" = "Darwin" ]; then
        # macOS (local) - Caminho padrão
        DOCKER_DATA_PATH="/Users/user0/Documents/VPS/home/user0"
    elif [ "$OS" = "Linux" ]; then
        # Linux em desenvolvimento local
        DOCKER_DATA_PATH="/Users/user0/Documents/VPS/home/user0"
    else
        # Fallback para Windows ou outros sistemas
        DOCKER_DATA_PATH="/Users/user0/Documents/VPS/home/user0"
    fi
    
    # Garantir que os diretórios existam
    mkdir -p "$DOCKER_DATA_PATH/docker-data/notion-assistant/data"
    mkdir -p "$DOCKER_DATA_PATH/docker-data/notion-assistant/backups"
    mkdir -p "$DOCKER_DATA_PATH/docker-data/notion-assistant/logs"
    
    # Para ambiente de desenvolvimento, também garantir que existam os diretórios dev/
    mkdir -p "$DOCKER_DATA_PATH/docker-data/notion-assistant/dev/data"
    mkdir -p "$DOCKER_DATA_PATH/docker-data/notion-assistant/dev/backups"
    mkdir -p "$DOCKER_DATA_PATH/docker-data/notion-assistant/dev/logs"
fi

echo "Configurado para $OS ($ENV_TYPE)"
echo "DOCKER_DATA_PATH=$DOCKER_DATA_PATH"

# Exportar a variável para uso nos arquivos docker-compose
export DOCKER_DATA_PATH

# Informações adicionais
echo "Variáveis de ambiente configuradas com sucesso"
echo "Diretório de dados: $DOCKER_DATA_PATH/docker-data/notion-assistant"

# Executar o comando passado com as variáveis de ambiente configuradas
if [ $# -gt 0 ]; then
    exec "$@"
fi