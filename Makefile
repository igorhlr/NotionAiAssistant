# NotionAiAssistant Makefile Simplificado
# Data: 09/06/2025
# Descrição: Versão simplificada do Makefile para o projeto NotionAiAssistant

# Cores para melhorar a visualização dos comandos
BLUE := \033[1;34m
GREEN := \033[1;32m
YELLOW := \033[1;33m
RED := \033[1;31m
RESET := \033[0m

# Variáveis de configuração
PROJECT_DIR := $(shell pwd)
DATA_DIR := /Users/user0/Documents/VPS/home/user0/docker-data/notion-assistant
DOCKER_NETWORK := shared_network
ENV_FILE := /home/user0/docker-secrets/open-source-secrets/.env
ENV_EXAMPLE := $(PROJECT_DIR)/config/env/.env.example
COMPOSE_FILE := $(PROJECT_DIR)/docker-compose.yml

# Detectar se estamos em produção ou desenvolvimento
ifeq ($(shell hostname),llmway)
	ENVIRONMENT := production
	COMPOSE_OPTS := -f $(COMPOSE_FILE)
	DATA_DIR := /home/user0/docker-data/notion-assistant
else ifeq ($(shell grep -q "/home/user0" /etc/passwd && echo "vps"),vps)
	ENVIRONMENT := production
	COMPOSE_OPTS := -f $(COMPOSE_FILE)
	DATA_DIR := /home/user0/docker-data/notion-assistant
else
	ENVIRONMENT := development
	COMPOSE_OPTS := -f $(COMPOSE_FILE) -f docker-compose.dev.yml
	DATA_DIR := /Users/user0/Documents/VPS/home/user0/docker-data/notion-assistant
endif

.PHONY: help
help: ## Exibe ajuda com todos os comandos disponíveis
	@echo "$(BLUE)NotionAiAssistant - Sistema de Automação$(RESET)"
	@echo "$(BLUE)===========================================$(RESET)"
	@echo "$(GREEN)Ambiente: $(ENVIRONMENT)$(RESET)"
	@echo ""
	@echo "$(YELLOW)Uso:$(RESET)"
	@echo "  make $(GREEN)<comando>$(RESET)"
	@echo ""
	@echo "$(YELLOW)Comandos Disponíveis:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Para mais informações, consulte a documentação em /docs$(RESET)"

#-------------------------------------------------------
# Comandos de Configuração Inicial
#-------------------------------------------------------

.PHONY: setup
setup: ## Configuração inicial completa do projeto
	@echo "$(BLUE)Configurando projeto NotionAiAssistant...$(RESET)"
	@make check-deps
	@make setup-dirs
	@make setup-env
	@make validate-env
	@make setup-permissions
	@echo "$(GREEN)Configuração concluída com sucesso!$(RESET)"
	@echo "$(YELLOW)📋 Próximos passos:$(RESET)"
	@echo "$(BLUE)   1. Verifique/edite: $(ENV_FILE)$(RESET)"
	@echo "$(BLUE)   2. Execute: make start$(RESET)"
	@echo "$(BLUE)   3. Monitore: make status$(RESET)"

.PHONY: setup-env
setup-env: ## Configura arquivo de ambiente automaticamente
	@echo "$(BLUE)Configurando arquivo de ambiente...$(RESET)"
	@mkdir -p $(PROJECT_DIR)/config/env
	@if [ ! -f $(ENV_FILE) ]; then \
		if [ -f $(ENV_EXAMPLE) ]; then \
			cp $(ENV_EXAMPLE) $(ENV_FILE); \
			echo "$(YELLOW)📋 Arquivo .env criado a partir do .env.example$(RESET)"; \
			echo "$(RED)⚠️  IMPORTANTE: Configure o arquivo $(ENV_FILE) com valores reais!$(RESET)"; \
		else \
			echo "$(RED)❌ Arquivo .env.example não encontrado!$(RESET)"; \
			echo "$(YELLOW)📋 Criando .env básico...$(RESET)"; \
			echo "# Configure este arquivo com valores reais" > $(ENV_FILE); \
			echo "POSTGRES_USER=notioniauser" >> $(ENV_FILE); \
			echo "POSTGRES_PASSWORD=notioniapassword" >> $(ENV_FILE); \
			echo "POSTGRES_DB=notioniadb" >> $(ENV_FILE); \
			echo "JWT_SECRET=CHANGE_ME_jwt_secret" >> $(ENV_FILE); \
		fi; \
	else \
		echo "$(GREEN)✅ Arquivo .env já existe$(RESET)"; \
	fi
	@chmod 600 $(ENV_FILE)
	@echo "$(GREEN)📁 Permissões configuradas (600)$(RESET)"

.PHONY: validate-env
validate-env: ## Valida configurações do arquivo .env
	@echo "$(BLUE)Validando configurações do ambiente...$(RESET)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)❌ Arquivo .env não encontrado!$(RESET)"; \
		echo "$(YELLOW)💡 Execute: make setup-env$(RESET)"; \
		exit 1; \
	fi
	@if grep -q "CHANGE_ME" $(ENV_FILE); then \
		echo "$(RED)⚠️  ATENÇÃO: Arquivo .env contém valores padrão que precisam ser configurados!$(RESET)"; \
		echo "$(YELLOW)📝 Valores que precisam ser alterados:$(RESET)"; \
		grep "CHANGE_ME" $(ENV_FILE) | head -5 | sed 's/^/   /'; \
		echo "$(BLUE)📖 Para editar: vi $(ENV_FILE)$(RESET)"; \
		echo "$(BLUE)💡 Ou execute: make edit-env$(RESET)"; \
	else \
		echo "$(GREEN)✅ Arquivo .env configurado corretamente$(RESET)"; \
	fi

.PHONY: edit-env
edit-env: ## Abre editor para configurar arquivo .env
	@echo "$(BLUE)Abrindo editor para configurar .env...$(RESET)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(YELLOW)📋 Arquivo .env não existe, criando primeiro...$(RESET)"; \
		make setup-env; \
	fi
	@${EDITOR:-vi} $(ENV_FILE)
	@echo "$(GREEN)✅ Edição concluída$(RESET)"
	@make validate-env

.PHONY: health-check
health-check: ## Executa verificação completa de saúde do sistema
	@echo "$(BLUE)Executando verificação de saúde...$(RESET)"
	@chmod +x $(PROJECT_DIR)/scripts/health_check.sh
	@$(PROJECT_DIR)/scripts/health_check.sh

.PHONY: check-deps
check-deps: ## Verifica dependências necessárias
	@echo "$(BLUE)Verificando dependências...$(RESET)"
	@command -v docker >/dev/null 2>&1 || { echo "$(RED)Docker não encontrado. Por favor, instale o Docker.$(RESET)"; exit 1; }
	@command -v docker-compose >/dev/null 2>&1 || { echo "$(RED)Docker Compose não encontrado. Por favor, instale o Docker Compose.$(RESET)"; exit 1; }
	@echo "$(GREEN)Todas as dependências encontradas.$(RESET)"

.PHONY: setup-dirs
setup-dirs: ## Cria os diretórios necessários para o projeto
	@echo "$(BLUE)Criando diretórios necessários...$(RESET)"
	@mkdir -p $(PROJECT_DIR)/logs
	@if [ "$(ENVIRONMENT)" = "production" ]; then \
		sudo mkdir -p $(DATA_DIR)/data; \
		sudo mkdir -p $(DATA_DIR)/backups; \
		echo "$(GREEN)Diretórios externos criados em $(DATA_DIR)$(RESET)"; \
	else \
		mkdir -p $(DATA_DIR)/data; \
		mkdir -p $(DATA_DIR)/backups; \
		mkdir -p $(DATA_DIR)/logs; \
		echo "$(GREEN)Diretórios locais criados para desenvolvimento$(RESET)"; \
	fi

.PHONY: setup-permissions
setup-permissions: ## Configura permissões corretas para arquivos e diretórios
	@echo "$(BLUE)Configurando permissões...$(RESET)"
	@chmod +x $(PROJECT_DIR)/scripts/*.sh || echo "$(YELLOW)⚠️ Não foi possível tornar todos os scripts executáveis.$(RESET)"
	@mkdir -p $(PROJECT_DIR)/logs
	@chmod -R 775 $(PROJECT_DIR)/logs || echo "$(YELLOW)⚠️ Não foi possível configurar permissões para logs.$(RESET)"
	@if [ "$(ENVIRONMENT)" = "production" ]; then \
		echo "$(BLUE)Configurando permissões em ambiente de produção...$(RESET)"; \
		mkdir -p $(DATA_DIR)/data; \
		mkdir -p $(DATA_DIR)/logs; \
		mkdir -p $(DATA_DIR)/backups; \
		chmod -R 775 $(DATA_DIR) || echo "$(YELLOW)⚠️ Não foi possível configurar permissões para diretórios externos.$(RESET)"; \
		if [ -n "$$(which docker)" ]; then \
			if [ -n "$(shell id -Gn | grep -o docker)" ]; then \
				chown -R $(shell whoami):docker $(DATA_DIR) 2>/dev/null || echo "$(YELLOW)⚠️ Não foi possível alterar proprietário. Tentando com sudo...$(RESET)"; \
				if [ -n "$$(which sudo)" ]; then \
					sudo chown -R $(shell whoami):docker $(DATA_DIR) 2>/dev/null || echo "$(YELLOW)⚠️ Não foi possível alterar proprietário mesmo com sudo.$(RESET)"; \
				fi; \
			else \
				echo "$(YELLOW)⚠️ Usuário atual não está no grupo docker.$(RESET)"; \
			fi; \
		else \
			echo "$(YELLOW)⚠️ Docker não encontrado.$(RESET)"; \
		fi; \
		echo "$(GREEN)Permissões configuradas para diretórios externos.$(RESET)"; \
	else \
		echo "$(BLUE)Configurando permissões em ambiente de desenvolvimento...$(RESET)"; \
		mkdir -p $(DATA_DIR)/data; \
		mkdir -p $(DATA_DIR)/logs; \
		mkdir -p $(DATA_DIR)/backups; \
		chmod -R 775 $(DATA_DIR) || echo "$(YELLOW)⚠️ Não foi possível configurar permissões para diretórios locais.$(RESET)"; \
		echo "$(GREEN)Permissões configuradas para diretórios locais.$(RESET)"; \
	fi
	@if [ -f "$(ENV_FILE)" ]; then \
		chmod 640 $(ENV_FILE) || echo "$(YELLOW)⚠️ Não foi possível configurar permissões para .env$(RESET)"; \
		echo "$(GREEN)Permissões configuradas para .env.$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️ Arquivo .env não encontrado.$(RESET)"; \
		make setup-env; \
	fi
	@echo "$(GREEN)Configuração de permissões concluída.$(RESET)"

.PHONY: setup-network
setup-network: ## Configura a rede Docker necessária
	@echo "$(BLUE)Configurando rede Docker...$(RESET)"
	@docker network inspect $(DOCKER_NETWORK) >/dev/null 2>&1 || docker network create $(DOCKER_NETWORK)
	@echo "$(GREEN)Rede $(DOCKER_NETWORK) verificada/criada com sucesso.$(RESET)"

#-------------------------------------------------------
# Comandos de Implantação
#-------------------------------------------------------

.PHONY: dev
dev: ## Inicia ambiente de desenvolvimento com script automatizado
	@echo "$(BLUE)Iniciando ambiente de desenvolvimento...$(RESET)"
	@chmod +x $(PROJECT_DIR)/scripts/automated-deploy-dev.sh
	@$(PROJECT_DIR)/scripts/automated-deploy-dev.sh
	@echo "$(GREEN)Ambiente de desenvolvimento iniciado.$(RESET)"

.PHONY: dev-clean
dev-clean: ## Inicia ambiente de desenvolvimento limpo
	@echo "$(BLUE)Iniciando ambiente de desenvolvimento limpo...$(RESET)"
	@chmod +x $(PROJECT_DIR)/scripts/automated-deploy-dev.sh
	@$(PROJECT_DIR)/scripts/automated-deploy-dev.sh true
	@echo "$(GREEN)Ambiente de desenvolvimento limpo iniciado.$(RESET)"

.PHONY: deploy
deploy: ## Implanta em produção com script automatizado
	@echo "$(BLUE)Implantando em produção...$(RESET)"
	@chmod +x $(PROJECT_DIR)/scripts/automated-deploy.sh
	@$(PROJECT_DIR)/scripts/automated-deploy.sh
	@echo "$(GREEN)Implantação em produção concluída.$(RESET)"

.PHONY: deploy-full
deploy-full: ## Implanta em produção com limpeza e rotação de secrets
	@echo "$(BLUE)Implantando em produção (limpeza + rotação)...$(RESET)"
	@chmod +x $(PROJECT_DIR)/scripts/automated-deploy.sh
	@$(PROJECT_DIR)/scripts/automated-deploy.sh true true
	@echo "$(GREEN)Implantação completa em produção concluída.$(RESET)"

#-------------------------------------------------------
# Comandos de Construção e Execução
#-------------------------------------------------------

.PHONY: build
build: ## Constrói ou reconstrói os serviços
	@echo "$(BLUE)Construindo serviços...$(RESET)"
	@docker-compose $(COMPOSE_OPTS) build
	@echo "$(GREEN)Construção concluída.$(RESET)"

.PHONY: start
start: setup-env setup-network validate-env ## Inicia todos os serviços com validação automática
	@echo "$(BLUE)Iniciando serviços...$(RESET)"
	@docker-compose $(COMPOSE_OPTS) up -d
	@echo "$(GREEN)✅ Serviços iniciados em segundo plano.$(RESET)"
	@echo "$(YELLOW)📊 Para verificar o status: make status$(RESET)"
	@echo "$(BLUE)📋 Para logs em tempo real: make logs-follow$(RESET)"
	@echo "$(BLUE)🔍 Para verificação de saúde: make health-check$(RESET)"

.PHONY: stop
stop: ## Para todos os serviços
	@echo "$(BLUE)Parando serviços...$(RESET)"
	@docker-compose $(COMPOSE_OPTS) down
	@echo "$(GREEN)Serviços parados.$(RESET)"

.PHONY: restart
restart: ## Reinicia todos os serviços
	@echo "$(BLUE)Reiniciando serviços...$(RESET)"
	@make stop
	@make start
	@echo "$(GREEN)Serviços reiniciados.$(RESET)"

.PHONY: status
status: ## Exibe o status dos serviços
	@echo "$(BLUE)Status dos serviços:$(RESET)"
	@docker-compose $(COMPOSE_OPTS) ps
	@echo ""
	@echo "$(BLUE)Uso de recursos:$(RESET)"
	@docker stats --no-stream notionia_app notionia_postgres 2>/dev/null || echo "$(YELLOW)Serviços não estão em execução.$(RESET)"

#-------------------------------------------------------
# Comandos de Logs
#-------------------------------------------------------

.PHONY: logs
logs: ## Exibe logs dos serviços
	@echo "$(BLUE)Exibindo logs...$(RESET)"
	@docker-compose $(COMPOSE_OPTS) logs --tail=100

.PHONY: logs-follow
logs-follow: ## Acompanha logs em tempo real
	@echo "$(BLUE)Acompanhando logs em tempo real (Ctrl+C para sair)...$(RESET)"
	@docker-compose $(COMPOSE_OPTS) logs -f

.PHONY: logs-app
logs-app: ## Exibe logs apenas do aplicativo
	@echo "$(BLUE)Exibindo logs do aplicativo...$(RESET)"
	@docker-compose $(COMPOSE_OPTS) logs --tail=100 app

.PHONY: logs-db
logs-db: ## Exibe logs apenas do banco de dados
	@echo "$(BLUE)Exibindo logs do banco de dados...$(RESET)"
	@docker-compose $(COMPOSE_OPTS) logs --tail=100 db

#-------------------------------------------------------
# Comandos de Manutenção
#-------------------------------------------------------

.PHONY: backup
backup: ## Executa backup do banco de dados
	@echo "$(BLUE)Executando backup do banco de dados...$(RESET)"
	@$(PROJECT_DIR)/scripts/backup.sh
	@echo "$(GREEN)Backup concluído.$(RESET)"

.PHONY: restore
restore: ## Restaura backup do banco de dados (uso: make restore BACKUP_FILE=arquivo.sql.gz)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "$(RED)Erro: Você deve especificar o arquivo de backup.$(RESET)"; \
		echo "$(YELLOW)Uso: make restore BACKUP_FILE=arquivo.sql.gz$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Restaurando backup do banco de dados...$(RESET)"
	@$(PROJECT_DIR)/scripts/restore.sh $(BACKUP_FILE)
	@echo "$(GREEN)Restauração concluída.$(RESET)"

.PHONY: list-backups
list-backups: ## Lista backups disponíveis
	@echo "$(BLUE)Listando backups disponíveis:$(RESET)"
	@if [ "$(ENVIRONMENT)" = "production" ]; then \
		ls -lh $(DATA_DIR)/backups/; \
	else \
		ls -lh $(PROJECT_DIR)/data/backups/; \
	fi

.PHONY: monitor
monitor: ## Executa monitoramento dos serviços
	@echo "$(BLUE)Executando monitoramento...$(RESET)"
	@$(PROJECT_DIR)/scripts/monitor.sh

.PHONY: cleanup
cleanup: ## Remove containers e volumes não utilizados
	@echo "$(BLUE)Limpando recursos não utilizados...$(RESET)"
	@docker system prune -f
	@echo "$(GREEN)Limpeza concluída.$(RESET)"

.PHONY: cleanup-safe
cleanup-safe: ## Executa limpeza segura interativa
	@echo "$(BLUE)🧹 Executando limpeza segura...$(RESET)"
	@chmod +x $(PROJECT_DIR)/scripts/safe-cleanup.sh
	@$(PROJECT_DIR)/scripts/safe-cleanup.sh false
	@echo "$(GREEN)✅ Limpeza segura concluída$(RESET)"

#-------------------------------------------------------
# Comandos de Segurança
#-------------------------------------------------------

.PHONY: security-check
security-check: ## Executa verificações de segurança básicas
	@echo "$(BLUE)Executando verificações de segurança...$(RESET)"
	@chmod +x $(PROJECT_DIR)/scripts/security_check.sh
	@$(PROJECT_DIR)/scripts/security_check.sh
	@echo "$(GREEN)Verificação de segurança concluída.$(RESET)"

#-------------------------------------------------------
# Comandos de Desenvolvimento
#-------------------------------------------------------

.PHONY: venv
venv: ## Cria ambiente virtual Python
	@echo "$(BLUE)Criando ambiente virtual Python...$(RESET)"
	@if command -v uv >/dev/null 2>&1; then \
		uv venv venv; \
	else \
		python -m venv venv; \
	fi
	@echo "$(GREEN)Ambiente virtual criado em ./venv/$(RESET)"
	@echo "$(YELLOW)Para ativar, execute: source venv/bin/activate$(RESET)"

.PHONY: install-dev
install-dev: venv ## Instala dependências de desenvolvimento
	@echo "$(BLUE)Instalando dependências de desenvolvimento...$(RESET)"
	@if command -v uv >/dev/null 2>&1; then \
		uv pip sync --python venv/bin/python requirements-dev.txt; \
	else \
		./venv/bin/pip install -r requirements-dev.txt; \
	fi
	@echo "$(GREEN)Dependências instaladas.$(RESET)"

.PHONY: test
test: ## Executa testes automatizados
	@echo "$(BLUE)Executando testes...$(RESET)"
	@if [ -d "venv" ]; then \
		./venv/bin/pytest; \
	else \
		echo "$(RED)Ambiente virtual não encontrado. Execute 'make install-dev' primeiro.$(RESET)"; \
		exit 1; \
	fi

.PHONY: run-local
run-local: ## Executa aplicação localmente (fora do Docker)
	@echo "$(BLUE)Iniciando aplicação localmente...$(RESET)"
	@if [ ! -d "venv" ]; then \
		echo "$(RED)Ambiente virtual não encontrado. Execute 'make install-dev' primeiro.$(RESET)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Iniciando backend...$(RESET)"
	@(cd app && ../venv/bin/uvicorn backend.main:app --host 0.0.0.0 --port 8080 --reload) &
	@echo "$(YELLOW)Iniciando frontend...$(RESET)"
	@sleep 3
	@cd app && ../venv/bin/streamlit run main.py

#-------------------------------------------------------
# Comandos de Documentação
#-------------------------------------------------------

.PHONY: version
version: ## Exibe a versão atual do projeto
	@echo "$(BLUE)Versão do NotionAiAssistant:$(RESET)"
	@if [ -f "VERSION" ]; then \
		cat VERSION; \
	else \
		echo "$(YELLOW)Arquivo VERSION não encontrado.$(RESET)"; \
		echo "$(GREEN)Versão baseada no último commit:$(RESET)"; \
		git describe --tags --always 2>/dev/null || echo "$(RED)Não foi possível determinar a versão.$(RESET)"; \
	fi
