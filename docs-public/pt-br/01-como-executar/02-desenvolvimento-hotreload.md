# Desenvolvimento com Hot Reload -  Notion Assistant

Este guia explica como configurar um ambiente de desenvolvimento com hot reload, permitindo visualizar alterações no código em tempo real sem a necessidade de reiniciar a aplicação manualmente.

## Benefícios do Hot Reload

- **Desenvolvimento mais rápido**: Visualize alterações instantaneamente
- **Feedback imediato**: Identifique erros rapidamente
- **Melhor experiência de desenvolvimento**: Mantenha o contexto da aplicação entre as alterações
- **Preservação de estado**: O estado da aplicação é preservado entre recargas

## Configuração do Ambiente

### Pré-requisitos

Certifique-se de ter instalado:
- Docker e Docker Compose
- Node.js e npm
- Git

Siga as instruções em [Configurando o Ambiente](./00-configurando-ambiente.md) se ainda não tiver configurado.

## Opção 1: Hot Reload com Docker

O projeto inclui uma configuração especial do Docker Compose para desenvolvimento com hot reload.

### Iniciando com Docker

```bash
# Na raiz do projeto
docker-compose -f docker-compose.dev.yml up
```

Esta configuração:
- Mapeia os diretórios de código como volumes
- Configura nodemon para o backend
- Configura o webpack dev server para o frontend
- Expõe as portas necessárias para desenvolvimento

### Como Funciona

1. Os arquivos do projeto são montados como volumes nos containers
2. Ferramentas de watch monitoram alterações nos arquivos
3. Quando um arquivo é alterado, apenas o código afetado é recarregado
4. O estado da aplicação é preservado quando possível

## Opção 2: Desenvolvimento Local (Sem Docker)

Para desenvolvimento sem Docker, é necessário configurar o hot reload localmente.

### Backend

1. Instale as dependências:
   ```bash
   cd backend
   npm install
   ```

2. Inicie o servidor com nodemon:
   ```bash
   npm run dev
   ```

### Frontend

1. Instale as dependências:
   ```bash
   cd frontend
   npm install
   ```

2. Inicie o servidor de desenvolvimento:
   ```bash
   npm start
   ```

## Configurações Personalizadas

### Ajustando o Hot Reload do Backend

O hot reload do backend é configurado através do nodemon. Você pode personalizar seu comportamento editando o arquivo `nodemon.json` na raiz do projeto backend:

```json
{
  "watch": ["src/**/*.js", "config/**/*.js"],
  "ignore": ["src/**/*.test.js", "src/**/*.spec.js"],
  "exec": "node src/index.js",
  "ext": "js,json"
}
```

### Ajustando o Hot Reload do Frontend

Para o frontend, as configurações do webpack dev server podem ser ajustadas no arquivo de configuração do webpack:

```js
// Exemplo de configuração do webpack.config.js
module.exports = {
  // ... outras configurações
  devServer: {
    hot: true,
    historyApiFallback: true,
    port: 3000,
    proxy: {
      '/api': 'http://localhost:8080'
    }
  }
};
```

## Dicas e Melhores Práticas

### Melhorando a Experiência de Desenvolvimento

1. **Feedback Visual**: Configure seu bundler para mostrar notificações de sucesso/erro
2. **Preservação de Estado**: Implemente Hot Module Replacement (HMR) para manter o estado
3. **Logs Claros**: Configure logs informativos para facilitar a depuração

### Depuração

1. **DevTools**: Use as ferramentas de desenvolvedor do navegador para inspecionar a aplicação
2. **Breakpoints**: Configure breakpoints no código para parar a execução e inspecionar variáveis
3. **Source Maps**: Certifique-se de que source maps estão habilitados para depuração de código transpilado

### Solução de Problemas Comuns

#### Hot Reload Não Funciona

Verifique:
- Se os volumes estão configurados corretamente no docker-compose.yml
- Se as ferramentas de watch estão monitorando os diretórios corretos
- Se há erros de sintaxe que podem estar impedindo a recarga

#### Mudanças Não Aparecem

Possíveis soluções:
- Limpe o cache do navegador (Ctrl+F5 ou Cmd+Shift+R)
- Verifique se o arquivo alterado está sendo monitorado
- Reinicie o servidor de desenvolvimento

#### Estado Perdido Entre Recargas

Considere:
- Implementar armazenamento persistente (localStorage, Redux persistente)
- Configurar HMR apropriadamente
- Usar ferramentas de gerenciamento de estado que preservem o estado durante o hot reload

## Próximos Passos

Após configurar o ambiente de desenvolvimento com hot reload, você está pronto para começar a contribuir! Consulte:

- [Como Contribuir](../03-contribuicao/00-como-contribuir.md)
- [Padrões de Código](../03-contribuicao/01-padroes-codigo.md)
- [Arquitetura do Projeto](../02-arquitetura/00-visao-geral.md)