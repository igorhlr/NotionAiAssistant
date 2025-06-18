# Configurando o Ambiente -  Notion Assistant

Este guia detalha os passos necessários para configurar o ambiente de desenvolvimento para o projeto  Notion Assistant.

## Pré-requisitos

Antes de iniciar, certifique-se de ter instalado:

- [Docker](https://www.docker.com/get-started) (versão 20.10 ou superior)
- [Docker Compose](https://docs.docker.com/compose/install/) (versão 2.0 ou superior)
- [Node.js](https://nodejs.org/) (versão 16 ou superior)
- [npm](https://www.npmjs.com/) (versão 8 ou superior)
- [Git](https://git-scm.com/downloads)

## Passo 1: Clonar o Repositório

```bash
git clone https://github.com/igorhlr/NotionAiAssistant.git
cd NotionAiAssistant
```

## Passo 2: Configurar Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto baseado no modelo `.env.example`:

```bash
cp .env.example .env
```

Edite o arquivo `.env` com suas configurações:

```
# Configurações da Aplicação
APP_PORT=3000
NODE_ENV=development

# Configurações do Banco de Dados
DB_HOST=postgres
DB_PORT=5432
DB_NAME=notionassistant
DB_USER=postgres
DB_PASSWORD=postgres_password

# Configurações do Notion
NOTION_API_KEY=seu_api_key_notion
```

## Passo 3: Instalar Dependências

Para desenvolvimento local (fora do Docker):

```bash
# Instalar dependências do backend
cd backend
npm install

# Instalar dependências do frontend
cd ../frontend
npm install
```

## Passo 4: Iniciar Serviços com Docker Compose

Para iniciar todos os serviços (recomendado):

```bash
docker-compose -f docker-compose.dev.yml up
```

Este comando iniciará:
- Container da aplicação backend
- Container do banco de dados PostgreSQL
- Container do frontend com hot reload

## Passo 5: Verificar a Instalação

Após iniciar os serviços, você pode acessar:

- Frontend: http://localhost:3000
- API Backend: http://localhost:8080

## Passo 6: Configurar o Banco de Dados

O banco de dados será automaticamente configurado durante a inicialização do container. Para executar migrações manualmente:

```bash
# Dentro do container do backend
docker-compose exec backend npm run migrate
```

## Desenvolvimento Local sem Docker

Para desenvolvimento sem Docker:

1. Configure um banco de dados PostgreSQL local
2. Atualize o arquivo `.env` com as configurações locais
3. Execute o backend:
   ```bash
   cd backend
   npm run dev
   ```
4. Execute o frontend:
   ```bash
   cd frontend
   npm start
   ```

## Solução de Problemas

### Problema: Erro de conexão com o banco de dados

Verifique:
- Se o container do PostgreSQL está rodando
- Se as credenciais no arquivo `.env` estão corretas
- Se a rede Docker está configurada corretamente

### Problema: Hot reload não funciona

Verifique:
- Se o volume está mapeado corretamente no docker-compose.yml
- Se as dependências foram instaladas

## Próximos Passos

Após configurar o ambiente, consulte:
- [Desenvolvimento com Hot Reload](./02-desenvolvimento-hotreload.md)
- [Estrutura do Projeto](../02-arquitetura/00-visao-geral.md)
- [Como Contribuir](../03-contribuicao/00-como-contribuir.md)