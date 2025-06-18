# Política de Segurança

## Relatando Vulnerabilidades de Segurança

Se você descobrir uma vulnerabilidade de segurança no NotionAiAssistant, por favor, **NÃO** abra uma Issue pública no GitHub. Em vez disso, envie um relatório detalhado para:

- Email: security@example.com (substitua pelo email correto)

Inclua as seguintes informações no seu relatório:

1. Descrição da vulnerabilidade e impacto potencial
2. Passos para reproduzir o problema
3. Versão do software e ambiente afetados
4. Possíveis mitigações, se conhecidas

Nossa equipe irá analisar seu relatório e responder o mais rápido possível. Agradecemos sua contribuição para a segurança deste projeto.

## Boas Práticas de Segurança para Usuários

Ao utilizar o NotionAiAssistant, recomendamos as seguintes práticas:

### Gerenciamento de Chaves de API

- **Nunca compartilhe suas chaves de API** (Notion, OpenAI, etc.) publicamente
- Utilize variáveis de ambiente ou arquivos seguros para armazenar suas chaves
- Considere utilizar chaves com permissões limitadas quando possível
- Faça rotação periódica das suas chaves de API

### Configuração do Ambiente

- Siga o arquivo `.env.example` para configurar seu ambiente
- Nunca inclua o arquivo `.env` em commits para repositórios
- Configure permissões de arquivo restritivas (chmod 600) para arquivos de configuração
- Utilize senhas fortes para o banco de dados PostgreSQL

### Uso em Produção

- Execute o aplicativo atrás de um proxy reverso com HTTPS configurado
- Ative o modo `DEBUG=false` em ambientes de produção
- Configure rate limiting adequado para prevenir abusos
- Mantenha o sistema e dependências atualizados

## Funcionalidades de Segurança

O NotionAiAssistant inclui várias funcionalidades de segurança:

- Autenticação baseada em JWT com expiração configurável
- Armazenamento seguro de senhas com hashing e salt
- Proteção contra SQL Injection através do ORM
- Validação de inputs e sanitização de dados
- Rotação automática de logs para prevenir vazamento de informações

## Gestão de Segredos

O projeto utiliza um sistema robusto para gestão de segredos:

1. **Em Desenvolvimento**:
   - Variáveis de ambiente armazenadas em arquivos `.env`
   - Scripts de geração de senhas seguras

2. **Em Produção**:
   - Docker Secrets para credenciais sensíveis
   - Integração com gestor de segredos externo (opcional)
   - Permissões restritivas em arquivos de configuração

Para configurar corretamente, consulte a [documentação sobre gestão de segredos](./docs-public/pt-br/01-como-executar/03-secrets-management.md).

## Divulgação Responsável

Comprometemo-nos a:

- Reconhecer sua contribuição ao reportar vulnerabilidades
- Responder prontamente a relatórios de segurança (meta: 48 horas)
- Manter você informado sobre o progresso da correção
- Dar crédito adequado quando a vulnerabilidade for corrigida (a menos que você prefira anonimato)

---

Este documento é atualizado conforme evoluímos nossas práticas de segurança. Última atualização: Junho/2025.
