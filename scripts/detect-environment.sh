#!/bin/bash

# Script para detectar se estamos em ambiente CI/CD ou local
# e definir variáveis de ambiente adequadamente

# Detectar estrutura de diretórios
if [ -d "/app" ] && [ -f "/app/requirements.txt" ]; then
    # Ambiente local
    echo "Detectado ambiente de desenvolvimento local"
    echo "APP_PATH=./" >> /etc/environment
    echo "CI_ENVIRONMENT=false" >> /etc/environment
    echo "USE_ROOT_USER=true" >> /etc/environment
elif [ -d "/app" ] && [ -f "/app/app/requirements.txt" ]; then
    # Ambiente CI/CD
    echo "Detectado ambiente CI/CD"
    echo "APP_PATH=./app/" >> /etc/environment
    echo "CI_ENVIRONMENT=true" >> /etc/environment
    echo "USE_ROOT_USER=false" >> /etc/environment
else
    # Fallback padrão
    echo "Não foi possível detectar ambiente, usando configuração padrão"
    echo "APP_PATH=./" >> /etc/environment
    echo "CI_ENVIRONMENT=false" >> /etc/environment
    echo "USE_ROOT_USER=true" >> /etc/environment
fi

# Exibir configuração para debug
echo "Configuração do ambiente:"
cat /etc/environment

# Carregar variáveis para a sessão atual
source /etc/environment

# Criar links simbólicos se necessário
if [ "$CI_ENVIRONMENT" = "true" ]; then
    echo "Criando links simbólicos para compatibilidade com CI/CD..."
    # Links seriam criados aqui se necessário
fi

exit 0
