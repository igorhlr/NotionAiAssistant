# Configuração do Diretório de Dados do Docker

Ao desenvolver localmente, o NotionAiAssistant utiliza volumes do Docker para persistir dados. Por padrão, o caminho utilizado é `/Users/user0/Documents/VPS/home/user0/docker-data/notion-assistant/`.

Este guia explica como personalizar esse caminho para atender às suas necessidades.

## Introdução

O caminho dos dados do Docker é controlado pela variável de ambiente `DOCKER_DATA_PATH`, que é configurada automaticamente pelo script `setup-docker-env.sh`. Em ambiente de desenvolvimento local, você pode personalizar esse caminho para melhor se adequar à estrutura de diretórios do seu sistema.

## Como Personalizar o Caminho de Dados

1. **Copie o arquivo de configuração de exemplo**:

   ```bash
   cp config/local-env.conf.example config/local-env.conf
   ```

2. **Edite o arquivo `config/local-env.conf`**:
   
   Abra o arquivo em seu editor preferido e defina o valor de `DOCKER_DATA_PATH` para o caminho que você deseja usar:

   ```
   # Configuração para macOS
   DOCKER_DATA_PATH=/Users/seu_usuario/Documents/Projetos/NotionAiAssistant
   
   # OU para Linux
   # DOCKER_DATA_PATH=/home/seu_usuario/projetos/NotionAiAssistant
   
   # OU para Windows (WSL)
   # DOCKER_DATA_PATH=/mnt/c/Users/seu_usuario/Documents/Projetos/NotionAiAssistant
   ```

3. **Salve o arquivo** e inicie o projeto normalmente.

## Estrutura de Diretórios

Após definir seu `DOCKER_DATA_PATH`, os seguintes diretórios serão criados automaticamente:

```
${DOCKER_DATA_PATH}/docker-data/notion-assistant/
├── data/           # Dados do PostgreSQL
├── backups/        # Backups do banco de dados
└── logs/           # Logs da aplicação
```

E para ambiente de desenvolvimento:

```
${DOCKER_DATA_PATH}/docker-data/notion-assistant/dev/
├── data/           # Dados do PostgreSQL (ambiente dev)
├── backups/        # Backups do banco de dados (ambiente dev)
└── logs/           # Logs da aplicação (ambiente dev)
```

## Observações Importantes

- O arquivo `config/local-env.conf` está no `.gitignore`, então suas configurações locais não serão enviadas para o repositório.
- Em ambiente de produção, esta configuração é ignorada e o caminho padrão de produção é utilizado.
- Certifique-se de que o diretório que você especificar tenha permissões de escrita para o usuário que executa o Docker.

## Resolução de Problemas

Se você encontrar problemas com permissões após alterar o caminho, tente:

1. Verificar as permissões do diretório especificado:
   ```bash
   ls -la ${DOCKER_DATA_PATH}
   ```

2. Conceder permissões de escrita se necessário:
   ```bash
   chmod -R 755 ${DOCKER_DATA_PATH}/docker-data
   ```

3. Se estiver usando Docker Desktop, verifique se o diretório está nas configurações de compartilhamento de arquivo.
