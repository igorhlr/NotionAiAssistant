# Mapa do Frontend -  Notion Assistant

Este documento apresenta a estrutura e organização do frontend da aplicação  Notion Assistant.

## Visão Geral

O frontend da aplicação foi desenvolvido utilizando tecnologias modernas para criar uma interface intuitiva e responsiva para interação com o assistente Notion.

## Estrutura de Diretórios

```
frontend/
├── public/
│   ├── assets/
│   │   └── images/
│   └── index.html
├── src/
│   ├── components/
│   │   ├── common/
│   │   ├── layout/
│   │   └── pages/
│   ├── hooks/
│   ├── services/
│   ├── store/
│   ├── styles/
│   ├── utils/
│   ├── App.js
│   └── index.js
└── package.json
```

## Principais Componentes

### Página de Login/Registro

![Página de Login](../../assets/login-page.png)

A página de login/registro permite que usuários:
- Façam login com credenciais existentes
- Registrem-se na plataforma
- Conheçam o que é o 

### Interface Principal

A interface principal do assistente inclui:
- Área de chat para interação com o assistente
- Painel lateral para gerenciamento de documentos do Notion
- Barra de ferramentas com opções de configuração

## Fluxo de Navegação

O diagrama abaixo demonstra o fluxo principal de navegação do usuário:

```
Login/Registro → Dashboard → Chat com Assistente → Configurações
```

## Tecnologias Utilizadas

- Framework: [Especificar framework]
- Gerenciamento de Estado: [Especificar biblioteca]
- Estilização: [Especificar abordagem CSS]
- Requisições HTTP: [Especificar biblioteca]

## Integração com Backend

O frontend se comunica com o backend através de uma API REST, utilizando endpoints documentados na seção de [Arquitetura Backend](../02-arquitetura/02-backend.md).

## Próximos Passos

Veja os próximos desenvolvimentos planejados para o frontend em [Roadmap](../03-contribuicao/03-roadmap.md).