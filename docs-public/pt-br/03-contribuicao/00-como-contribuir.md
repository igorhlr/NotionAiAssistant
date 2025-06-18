# Como Contribuir -  Notion Assistant

Este guia explica como você pode contribuir para o projeto  Notion Assistant de forma efetiva. Agradecemos muito seu interesse em ajudar a melhorar nossa plataforma!

## Tipos de Contribuições

Existem várias maneiras de contribuir para o projeto:

- **Correção de bugs**: Identificar e corrigir problemas no código
- **Novas funcionalidades**: Implementar novas capacidades no assistente
- **Melhorias de desempenho**: Otimizar o código existente
- **Documentação**: Melhorar ou adicionar documentação
- **Testes**: Criar ou melhorar testes automatizados
- **Design**: Melhorar a interface de usuário e experiência
- **Feedback**: Reportar bugs ou sugerir melhorias

## Fluxo de Trabalho

### 1. Configure seu Ambiente

Siga os passos em [Configurando o Ambiente](../01-como-executar/00-configurando-ambiente.md) para preparar seu ambiente de desenvolvimento.

### 2. Escolha uma Tarefa

- Verifique as [Issues](https://github.com/igorhlr/NotionAiAssistant/issues) abertas no GitHub
- Procure por issues marcadas como `good first issue` se for sua primeira contribuição
- Ou proponha uma nova funcionalidade criando uma issue

### 3. Crie um Fork e Clone

1. Faça um fork do repositório para sua conta do GitHub
2. Clone seu fork:
   ```bash
   git clone https://github.com/igorhlr/NotionAiAssistant.git
   cd NotionAiAssistant
   ```
3. Adicione o repositório original como remote:
   ```bash
   git remote add upstream https://github.com/repositorio-original/NotionAiAssistant.git
   ```

### 4. Crie uma Branch

Sempre crie uma branch específica para sua contribuição:

```bash
git checkout -b feature/nome-da-funcionalidade
# ou
git checkout -b fix/nome-do-bug
```

### 5. Desenvolva

Ao desenvolver sua contribuição:

- Siga os [Padrões de Código](./01-padroes-codigo.md)
- Escreva testes para novas funcionalidades
- Mantenha o escopo da mudança focado
- Commit regularmente com mensagens claras

### 6. Teste sua Contribuição

Certifique-se de que sua contribuição funciona corretamente:

```bash
# Execute os testes automatizados
npm test

# Execute a aplicação localmente
docker-compose -f docker-compose.dev.yml up
```

### 7. Envie um Pull Request

1. Atualize sua branch com as mudanças mais recentes:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. Envie suas alterações para seu fork:
   ```bash
   git push origin feature/nome-da-funcionalidade
   ```

3. Abra um Pull Request no GitHub, detalhando:
   - O que sua contribuição faz
   - Como testá-la
   - Qualquer contexto adicional importante

4. Siga o [Fluxo de Pull Request](./02-fluxo-pr.md) para mais detalhes

## Boas Práticas

- **Comunique-se**: Comente na issue que está trabalhando para evitar duplicação de esforços
- **Foco**: Mantenha as mudanças pequenas e focadas em um único propósito
- **Testes**: Adicione testes para novas funcionalidades
- **Documentação**: Atualize a documentação para refletir suas mudanças
- **Código limpo**: Siga os padrões de código do projeto

## Reconhecimento

Todos os contribuidores são reconhecidos e listados no arquivo [CONTRIBUTORS.md](https://github.com/igorhlr/NotionAiAssistant/blob/main/CONTRIBUTORS.md).

## Dúvidas?

Se tiver dúvidas sobre como contribuir, sinta-se à vontade para:
- Abrir uma issue com a tag `question`
- Perguntar nos comentários de uma issue existente
- Entrar em contato com os mantenedores principais

Agradecemos muito sua contribuição para tornar o  Notion Assistant ainda melhor!