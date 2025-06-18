# Mapa Completo da Aplicação -  Notion Assistant

Este documento apresenta uma visão holística de toda a arquitetura e fluxo de dados da aplicação  Notion Assistant.

## Diagrama de Arquitetura

A arquitetura da aplicação é composta pelos seguintes componentes principais:

```
                   ┌─────────────┐
                   │    Cliente  │
                   │   (Browser) │
                   └──────┬──────┘
                          │
                          ▼
┌──────────────────────────────────────────┐
│                 Traefik                  │
│      (Reverse Proxy / Load Balancer)     │
└─────────┬─────────────────────┬──────────┘
          │                     │
          ▼                     ▼
┌─────────────────┐    ┌─────────────────┐
│   Aplicação     │    │   PostgreSQL    │
│  (Backend API)  │◄───►│  (Database)    │
└─────────┬───────┘    └─────────────────┘
          │
          ▼
┌─────────────────┐
│  Notion API     │
│  (Integração)   │
└─────────────────┘
```

## Componentes do Sistema

### 1. Frontend (Cliente)

Interface web que permite aos usuários:
- Autenticar-se no sistema
- Interagir com o assistente
- Gerenciar integrações com o Notion

### 2. Traefik (Proxy Reverso)

Gerencia:
- Roteamento de tráfego
- Certificados SSL
- Load balancing

### 3. Backend (API)

Fornece:
- Endpoints para autenticação
- Processamento de linguagem natural
- Integração com APIs externas
- Lógica de negócio da aplicação

### 4. Banco de Dados (PostgreSQL)

Armazena:
- Dados de usuários
- Configurações
- Histórico de interações
- Tokens de integração

### 5. Integração com Notion

Permite:
- Leitura e escrita em documentos Notion
- Sincronização de dados
- Acesso a conteúdo do Notion

## Fluxo de Dados

1. O usuário acessa a aplicação através do navegador
2. O Traefik roteia a requisição para o container da aplicação
3. A aplicação processa a requisição, consultando o banco de dados quando necessário
4. Para interações com o Notion, a aplicação utiliza a API do Notion
5. Os resultados são retornados ao usuário através da interface web

## Containers Docker

A aplicação é executada em containers Docker:

| Container | Imagem | Função |
|-----------|--------|--------|
| notionaissistant_app | notionaissistant_app | Aplicação principal |
| notionaissistant_postgres | postgres:15-alpine | Banco de dados |
| traefik | production_traefik | Proxy reverso |

## Portas e Endpoints

- **Aplicação Web**: Porta 80/443 (HTTP/HTTPS)
- **API Backend**: [Detalhes dos endpoints]
- **Banco de Dados**: Porta 5432 (PostgreSQL)

## Ambiente de Produção

A aplicação está hospedada em uma VPS, com o domínio [notionassistant.llmway.com.br](https://notionassistant.llmway.com.br).

Para mais detalhes sobre componentes específicos, consulte:
- [Documentação do Frontend](./00-front.md)
- [Arquitetura Backend](../02-arquitetura/02-backend.md)
- [Configuração do Banco de Dados](../02-arquitetura/03-banco-dados.md)