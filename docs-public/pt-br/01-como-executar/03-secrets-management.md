# Gerenciamento de Segredos no NotionAiAssistant

Este documento descreve como o NotionAiAssistant gerencia informações sensíveis e segredos, e como você deve configurar seu ambiente para desenvolvimento e produção.

## Conceitos Básicos

O NotionAiAssistant utiliza várias informações sensíveis:

1. **Credenciais de Banco de Dados**: Senhas do PostgreSQL e usuários
2. **Chaves de API**: OpenAI, Anthropic, Notion, DeepSeek, etc.
3. **Segredos do Sistema**: JWT secrets, chaves de criptografia, etc.
4. **Credenciais de Administração**: Senhas de usuários administrativos

Estas informações **nunca** devem ser armazenadas diretamente no código ou commitadas em repositórios.

## Configuração de Desenvolvimento

### Usando .env

1. Copie o arquivo `.env.example` para `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edite o arquivo `.env` com suas configurações:
   ```
   # Configurações do Banco de Dados
   DATABASE_URL=postgresql://notioniauser:dev_password@localhost:5432/notionassistant
   
   # Chaves de API (preencha com suas chaves)
   OPENAI_API_KEY=sua_chave_aqui
   NOTION_API_KEY=sua_chave_aqui
   ```

3. O arquivo `.env` é ignorado pelo Git e não será incluído nos commits.

### Usando Secrets em Desenvolvimento

Para uma abordagem mais segura em desenvolvimento:

1. Execute o script de geração de segredos:
   ```bash
   ./config/secrets/generate-secure-vars.sh
   ```

2. Este script gera:
   - Senhas seguras para o banco de dados
   - Senhas para usuários de aplicação
   - JWT secrets
   - Arquivos de configuração em `config/secrets/development/`

3. Os arquivos gerados são automaticamente ignorados pelo Git.

## Configuração de Produção

### Usando Docker Secrets

Em produção, recomendamos o uso de Docker Secrets:

1. Crie os secrets necessários:
   ```bash
   echo "senha_segura" | docker secret create postgres_password -
   echo "outra_senha" | docker secret create jwt_secret -
   # Repita para outros segredos necessários
   ```

2. No arquivo `docker-compose.yml`, referencie os secrets:
   ```yaml
   services:
     app:
       secrets:
         - postgres_password
         - jwt_secret
         - openai_api_key
   
   secrets:
     postgres_password:
       external: true
     jwt_secret:
       external: true
     openai_api_key:
       external: true
   ```

3. A aplicação lerá os segredos do diretório `/run/secrets/` em tempo de execução.

### Script de Inicialização de Segredos

O NotionAiAssistant inclui um script de inicialização que:

1. Procura por segredos no diretório `/run/secrets/`
2. Se não encontrados, utiliza variáveis de ambiente
3. Gera um arquivo `.env` temporário com os valores corretos
4. Configura permissões adequadas

Esse script está em `config/secrets/init-secrets.sh` e é executado automaticamente ao iniciar o container.

## Gerenciamento de Chaves de API Externas

### Abordagem Recomendada

Para APIs externas (OpenAI, Notion, etc.), recomendamos:

1. **Em desenvolvimento**:
   - Armazene temporariamente no arquivo `.env`
   - Ou use variáveis de ambiente na sua sessão

2. **Em produção**:
   - Use Docker Secrets para armazenamento seguro
   - Ou utilize um serviço externo de gerenciamento de segredos
   - Considere a integração com HashiCorp Vault ou AWS Secrets Manager

### Configuração Dinâmica

O NotionAiAssistant permite que usuários configurem suas próprias chaves de API através da interface:

1. As chaves são armazenadas temporariamente durante a sessão do usuário
2. Nenhuma chave é persistida no banco de dados
3. Os usuários precisam reconfigurar as chaves ao reiniciar o aplicativo

## Segurança de Segredos

### Recomendações de Permissões

- Arquivos `.env`: `chmod 600`
- Diretório `config/secrets/`: `chmod 700`
- Arquivos individuais de segredos: `chmod 600`

### Verificação de Segurança

Antes de commits ou deploy, você pode executar:

```bash
./config/secrets/validate-secrets.sh
```

Este script verifica:
- Se segredos sensíveis estão sendo commitados
- Se arquivos de exemplo estão presentes
- Se há informações sensíveis em logs ou backups

## Referências

- [Docker Secrets Documentation](https://docs.docker.com/engine/swarm/secrets/)
- [FastAPI Environment Variables](https://fastapi.tiangolo.com/advanced/settings/)
- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/current/auth-best-practices.html)

---

**IMPORTANTE**: Nunca compartilhe suas chaves de API ou segredos com outras pessoas. Se você suspeitar que uma chave foi comprometida, gere uma nova imediatamente e revogue a antiga.

## Configuração do Diretório de Dados do Docker

Siga as instruções em [Configurando o data path](./04-configuracao-docker-data-path.md) se ainda não tiver configurado.
