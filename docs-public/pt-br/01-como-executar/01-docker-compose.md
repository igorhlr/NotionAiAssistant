# Como Executar com Docker -  Notion Assistant

Este guia explica como executar o projeto  Notion Assistant utilizando Docker e Docker Compose, oferecendo um ambiente isolado e consistente para desenvolvimento e testes.

## Pré-requisitos

Certifique-se de ter instalado:
- Docker (versão 20.10 ou superior)
- Docker Compose (versão 2.0 ou superior)

Para verificar as versões instaladas:
```bash
docker --version
docker-compose --version
```

## Configuração Inicial

Antes de iniciar os containers, configure o arquivo de ambiente:

1. Copie o arquivo de exemplo:
   ```bash
   cp .env.example .env
   ```

2. Edite o arquivo `.env` com suas configurações locais

## Iniciando a Aplicação

### Ambiente de Desenvolvimento

Para iniciar a aplicação em modo de desenvolvimento:

```bash
docker-compose -f docker-compose.dev.yml up
```

Este comando inicia:
- Container da aplicação (com hot reload)
- Container do PostgreSQL
- Mapeamento de volumes para desenvolvimento

Para executar em segundo plano:
```bash
docker-compose -f docker-compose.dev.yml up -d
```

### Ambiente de Produção Local

Para simular o ambiente de produção localmente:

```bash
docker-compose up
```

Este comando utiliza as configurações do arquivo `docker-compose.yml` padrão, que está otimizado para um ambiente similar ao de produção.

## Verificando os Containers

Para verificar o status dos containers em execução:

```bash
docker-compose ps
```

Exemplo de saída:
```
         Name                        Command               State                  Ports                
-------------------------------------------------------------------------------------------------------
notionaissistant_app      docker-entrypoint.sh node  ...   Up      0.0.0.0:3000->3000/tcp              
notionaissistant_postgres docker-entrypoint.sh postgres    Up      0.0.0.0:5432->5432/tcp
```

## Acessando a Aplicação

Após iniciar os containers, você pode acessar:

- Interface Web: http://localhost:3000
- API: http://localhost:3000/api

## Visualizando Logs

Para acompanhar os logs em tempo real:

```bash
# Todos os containers
docker-compose logs -f

# Container específico
docker-compose logs -f app
```

## Executando Comandos

Para executar comandos dentro dos containers:

```bash
# Shell no container da aplicação
docker-compose exec app sh

# Executar comando NPM
docker-compose exec app npm run <comando>

# Shell no container do PostgreSQL
docker-compose exec postgres psql -U postgres -d notionassistant
```

## Parando a Aplicação

Para parar todos os containers:

```bash
# Se iniciado em primeiro plano (com Ctrl+C)
# Ou se iniciado em segundo plano:
docker-compose down
```

Para parar e remover volumes (cuidado, isso apagará o banco de dados):

```bash
docker-compose down -v
```

## Reconstruindo a Aplicação

Se você modificar o Dockerfile ou precisar reconstruir as imagens:

```bash
docker-compose build
# ou
docker-compose up --build
```

## Solução de Problemas

### Problema: Porta já em uso

Se a porta 3000 ou 5432 já estiver em uso:

1. Verifique quais processos estão usando as portas:
   ```bash
   lsof -i :3000
   lsof -i :5432
   ```

2. Encerre esses processos ou altere as portas no arquivo `docker-compose.yml`

### Problema: Erro de permissão em volumes

Se encontrar erros de permissão ao montar volumes:

```bash
# No Linux/macOS
sudo chown -R $USER:$USER .
```

## Próximos Passos

Após executar a aplicação com Docker, consulte:
- [Desenvolvimento com Hot Reload](./02-desenvolvimento-hotreload.md)
- [Como Contribuir](../03-contribuicao/00-como-contribuir.md)