# Padrões de Código -  Notion Assistant

Este documento descreve os padrões de código e convenções adotados no projeto  Notion Assistant para garantir qualidade, consistência e manutenibilidade do código.

## Visão Geral

Seguimos um conjunto consistente de padrões para facilitar a colaboração e manter a qualidade do código. Estes padrões são inspirados em boas práticas da comunidade Python e nos guias de estilo de projetos bem estabelecidos.

## Estilo de Código

### PEP 8

Seguimos o [PEP 8](https://www.python.org/dev/peps/pep-0008/) como base para o estilo de código Python:

- **Indentação**: 4 espaços (não tabs)
- **Comprimento de linha**: Máximo de 88 caracteres
- **Quebras de linha**: Quebrar antes de operadores binários
- **Linhas em branco**: 2 linhas antes de definições de classe e funções de nível superior
- **Imports**: Agrupados por padrão e ordenados alfabeticamente

```python
# Imports corretos
import os
import sys
from typing import Dict, List, Optional

import pandas as pd
import requests

from app.core import security
from app.db import database
```

### Formatação com Black

Utilizamos o [Black](https://black.readthedocs.io/) como formatador automático de código:

```bash
# Formatar um arquivo
black app/main.py

# Formatar todos os arquivos
black app/
```

### Docstrings

Utilizamos docstrings no estilo Google para documentação de código:

```python
def generate_content(prompt: str, provider: str = "openai") -> str:
    """Gera conteúdo usando o provedor de IA especificado.
    
    Args:
        prompt: O prompt ou instrução para gerar conteúdo.
        provider: O provedor de IA a ser utilizado (padrão: "openai").
        
    Returns:
        O conteúdo gerado pelo modelo de IA.
        
    Raises:
        ValueError: Se o provedor não for suportado.
        APIError: Se houver um erro na chamada da API.
    """
    # Implementação
```

## Convenções de Nomenclatura

### Variáveis e Funções

- **snake_case** para variáveis, funções e métodos
- **Nomes descritivos** e significativos
- **Prefixo com underscore** para variáveis e métodos privados

```python
# Bom
user_profile = get_user_profile(user_id)
total_items = calculate_total_items(cart)
_internal_cache = {}

# Ruim
u = get_u(uid)
t = calc(c)
internalCache = {}
```

### Classes

- **PascalCase** (ou CapWords) para nomes de classes
- **Nomes específicos** que descrevem bem a entidade

```python
# Bom
class UserRepository:
    pass
    
class ContentGenerator:
    pass
    
class NotionIntegration:
    pass

# Ruim
class Data:
    pass
    
class Manager:
    pass
```

### Constantes

- **UPPERCASE_WITH_UNDERSCORES** para constantes
- Definidas no nível do módulo

```python
# Bom
MAX_RETRIES = 3
DEFAULT_TIMEOUT = 30
API_BASE_URL = "https://api.example.com/v1"

# Ruim
maxRetries = 3
default_timeout = 30
```

### Módulos e Pacotes

- **snake_case** para nomes de módulos e pacotes
- Nomes curtos e descritivos

```
app/
├── core/
│   ├── config.py
│   ├── security.py
│   └── exceptions.py
├── api/
│   ├── endpoints/
│   ├── dependencies.py
│   └── router.py
└── services/
    ├── content_service.py
    ├── notion_service.py
    └── ai_service.py
```

## Padrões de Programação

### Tipagem Estática

Utilizamos hints de tipo do Python para melhorar a legibilidade e permitir verificação estática:

```python
from typing import Dict, List, Optional, Union

def get_user_by_id(user_id: str) -> Optional[Dict[str, any]]:
    """Busca um usuário pelo ID."""
    # Implementação
    
def process_items(items: List[Dict[str, Union[str, int]]]) -> List[str]:
    """Processa uma lista de itens."""
    # Implementação
```

### Programação Assíncrona

Utilizamos programação assíncrona com `async/await` para operações I/O bound:

```python
async def fetch_content(prompt: str) -> str:
    """Busca conteúdo de uma API externa de forma assíncrona."""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://api.example.com/generate",
            json={"prompt": prompt}
        )
        response.raise_for_status()
        data = response.json()
        return data["content"]
```

### Tratamento de Exceções

Preferimos tratamento de exceções específico:

```python
try:
    result = await api_client.fetch_data(user_id)
except ApiConnectionError as e:
    logger.error(f"Connection error: {str(e)}")
    raise ServiceUnavailableError("Service temporarily unavailable")
except ApiTimeoutError as e:
    logger.warning(f"Timeout error: {str(e)}")
    raise RequestTimeoutError("Request timed out")
except ApiError as e:
    logger.error(f"API error: {str(e)}")
    raise InternalServerError("Internal server error")
```

### Padrão de Repositório

Utilizamos o padrão de repositório para acesso a dados:

```python
class UserRepository:
    def __init__(self, db: Database):
        self.db = db
        
    async def get_by_id(self, user_id: str) -> Optional[User]:
        """Busca um usuário pelo ID."""
        query = users.select().where(users.c.id == user_id)
        user_data = await self.db.fetch_one(query)
        if user_data:
            return User(**user_data)
        return None
        
    async def create(self, user: UserCreate) -> str:
        """Cria um novo usuário."""
        user_id = str(uuid.uuid4())
        query = users.insert().values(
            id=user_id,
            username=user.username,
            email=user.email,
            password_hash=get_password_hash(user.password)
        )
        await self.db.execute(query)
        return user_id
```

### Injeção de Dependências

Utilizamos injeção de dependências para facilitar testes e manutenção:

```python
# app/api/dependencies.py
from fastapi import Depends, HTTPException
from app.db.database import get_database
from app.repositories.user_repository import UserRepository

async def get_user_repository(db = Depends(get_database)):
    return UserRepository(db)

# app/api/endpoints/users.py
from fastapi import APIRouter, Depends
from app.api.dependencies import get_user_repository
from app.repositories.user_repository import UserRepository

router = APIRouter()

@router.get("/users/{user_id}")
async def get_user(
    user_id: str,
    user_repo: UserRepository = Depends(get_user_repository)
):
    user = await user_repo.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
```

## Testes

### Estrutura de Testes

Organizamos testes de forma hierárquica:

```
tests/
├── unit/                # Testes unitários
│   ├── test_services.py
│   ├── test_repositories.py
│   └── test_utils.py
├── integration/         # Testes de integração
│   ├── test_api.py
│   └── test_database.py
└── conftest.py          # Fixtures compartilhadas
```

### Fixtures para Testes

Utilizamos fixtures do pytest para preparar o ambiente de teste:

```python
# tests/conftest.py
import pytest
import asyncio
from databases import Database
from app.core.config import settings
from app.db.database import metadata

@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope="session")
async def test_db():
    # Usar banco de dados de teste
    test_db_url = settings.database_url.replace(
        "notionassistant", "notionassistant_test"
    )
    db = Database(test_db_url)
    await db.connect()
    
    # Criar tabelas
    engine = create_engine(test_db_url)
    metadata.create_all(engine)
    
    yield db
    
    # Limpar após testes
    await db.disconnect()
    metadata.drop_all(engine)

@pytest.fixture
async def user_repository(test_db):
    return UserRepository(test_db)
```

### Exemplos de Testes

#### Teste Unitário

```python
# tests/unit/test_services.py
import pytest
from unittest.mock import Mock, AsyncMock
from app.services.content_service import ContentService

@pytest.mark.asyncio
async def test_generate_content():
    # Arrange
    mock_ai_provider = AsyncMock()
    mock_ai_provider.generate.return_value = "Generated content"
    
    mock_content_repo = AsyncMock()
    mock_content_repo.save.return_value = "content_id"
    
    service = ContentService(
        ai_provider=mock_ai_provider,
        content_repository=mock_content_repo
    )
    
    # Act
    result = await service.generate_content(
        prompt="Test prompt",
        user_id="user123",
        provider="openai"
    )
    
    # Assert
    assert result == "Generated content"
    mock_ai_provider.generate.assert_called_once_with(
        prompt="Test prompt",
        provider="openai"
    )
    mock_content_repo.save.assert_called_once()
```

#### Teste de Integração

```python
# tests/integration/test_api.py
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_login_success():
    # Arrange
    login_data = {
        "email": "test@example.com",
        "password": "testpassword"
    }
    
    # Act
    response = client.post("/api/auth/login", json=login_data)
    
    # Assert
    assert response.status_code == 200
    data = response.json()
    assert "token" in data
    assert "user" in data
    assert data["user"]["email"] == login_data["email"]
```

## Documentação do Código

### Docstrings

Cada módulo, classe e função deve ter docstrings:

```python
"""
Módulo para gerenciamento de conteúdo gerado por IA.

Este módulo contém serviços e utilitários para geração,
processamento e armazenamento de conteúdo usando diferentes
provedores de IA.
"""

class ContentService:
    """Serviço para gerenciamento de conteúdo gerado por IA.
    
    Este serviço coordena a geração de conteúdo através de
    diferentes provedores de IA e gerencia o armazenamento
    do histórico de interações.
    """
    
    def __init__(self, ai_provider, content_repository):
        """Inicializa o serviço de conteúdo.
        
        Args:
            ai_provider: Provedor de serviços de IA.
            content_repository: Repositório para armazenamento de conteúdo.
        """
        self.ai_provider = ai_provider
        self.content_repository = content_repository
```

### Comentários

- Usamos comentários para explicar "por quê", não "o quê" ou "como"
- Comentários devem esclarecer decisões não óbvias e lógica complexa

```python
# Bom: Explica o motivo de uma abordagem específica
# Usamos cache em memória em vez de Redis para reduzir latência
# em ambientes de desenvolvimento
cache = {}

# Ruim: Apenas descreve o que o código faz
# Define a variável cache como um dicionário
cache = {}
```

## Ferramentas de Qualidade de Código

### Linting com Flake8

Utilizamos o Flake8 para análise estática de código:

```bash
# Configuração em .flake8
[flake8]
max-line-length = 88
extend-ignore = E203, W503
exclude = .git,__pycache__,build,dist

# Comando para verificar
flake8 app/ tests/
```

### Verificação de Tipos com MyPy

Verificamos os tipos estáticos com MyPy:

```bash
# Configuração em mypy.ini
[mypy]
python_version = 3.10
warn_return_any = True
warn_unused_configs = True
disallow_untyped_defs = True
disallow_incomplete_defs = True

# Comando para verificar
mypy app/
```

### Testes com Pytest

Executamos testes automatizados com Pytest:

```bash
# Executar todos os testes
pytest

# Com cobertura
pytest --cov=app --cov-report=html

# Testes específicos
pytest tests/unit/test_services.py -v
```

## Exemplos Completos

### Exemplo de Serviço

```python
"""
Serviço para integração com a API do Notion.

Este módulo fornece funcionalidades para criar, atualizar e gerenciar
páginas e bancos de dados no Notion.
"""
from typing import Dict, List, Optional
import httpx
from app.core.config import settings
from app.core.logging import logger
from app.schemas.notion import NotionPage, NotionDatabase

class NotionService:
    """Serviço para interação com a API do Notion."""
    
    def __init__(self, api_key: Optional[str] = None):
        """Inicializa o serviço Notion.
        
        Args:
            api_key: Chave da API do Notion. Se não fornecida,
                    será usada a chave configurada nas settings.
        """
        self.api_key = api_key or settings.notion_api_key
        self.base_url = "https://api.notion.com/v1"
        
    async def create_page(
        self, 
        parent_id: str, 
        title: str, 
        content: str
    ) -> Dict[str, any]:
        """Cria uma nova página no Notion.
        
        Args:
            parent_id: ID da página ou banco de dados pai.
            title: Título da página.
            content: Conteúdo da página em formato de texto.
            
        Returns:
            Metadados da página criada.
            
        Raises:
            NotionAPIError: Se houver erro na chamada à API.
        """
        try:
            # Converter conteúdo para blocos do Notion
            blocks = self._text_to_blocks(content)
            
            # Preparar payload
            payload = {
                "parent": {"page_id": parent_id},
                "properties": {
                    "title": {
                        "title": [
                            {
                                "text": {
                                    "content": title
                                }
                            }
                        ]
                    }
                },
                "children": blocks
            }
            
            # Fazer requisição à API
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/pages",
                    json=payload,
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Notion-Version": "2022-06-28",
                        "Content-Type": "application/json"
                    }
                )
                response.raise_for_status()
                
                # Retornar dados da página criada
                page_data = response.json()
                logger.info(f"Page created: {page_data['id']}")
                
                return {
                    "id": page_data["id"],
                    "url": page_data["url"]
                }
                
        except httpx.HTTPStatusError as e:
            logger.error(f"Notion API error: {str(e)}")
            raise NotionAPIError(f"Error creating page: {e.response.text}")
        except Exception as e:
            logger.error(f"Unexpected error: {str(e)}")
            raise NotionAPIError(f"Unexpected error: {str(e)}")
    
    def _text_to_blocks(self, text: str) -> List[Dict[str, any]]:
        """Converte texto em blocos do Notion.
        
        Args:
            text: Texto a ser convertido.
            
        Returns:
            Lista de blocos no formato da API do Notion.
        """
        # Lógica para converter texto em blocos do Notion
        # ...

class NotionAPIError(Exception):
    """Exceção para erros da API do Notion."""
    pass
```

### Exemplo de Repositório

```python
"""
Repositório para gerenciamento de histórico de conteúdo.

Este módulo fornece funcionalidades para armazenar e recuperar
histórico de conteúdo gerado.
"""
from typing import Dict, List, Optional
import uuid
from datetime import datetime
from databases import Database
from fastapi import Depends
from app.db.database import get_database
from app.models.content import content_history

class ContentRepository:
    """Repositório para operações de histórico de conteúdo."""
    
    def __init__(self, db: Database = Depends(get_database)):
        """Inicializa o repositório de conteúdo.
        
        Args:
            db: Instância de conexão com o banco de dados.
        """
        self.db = db
        
    async def save(
        self,
        user_id: str,
        prompt: str,
        generated_content: str,
        provider: str,
        notion_url: Optional[str] = None
    ) -> str:
        """Salva um item no histórico de conteúdo.
        
        Args:
            user_id: ID do usuário que gerou o conteúdo.
            prompt: Prompt utilizado para gerar o conteúdo.
            generated_content: Conteúdo gerado pelo modelo.
            provider: Provedor de IA utilizado.
            notion_url: URL da página do Notion (opcional).
            
        Returns:
            ID do item criado no histórico.
        """
        item_id = str(uuid.uuid4())
        
        query = content_history.insert().values(
            id=item_id,
            user_id=user_id,
            prompt=prompt,
            generated_content=generated_content,
            provider=provider,
            notion_url=notion_url,
            created_at=datetime.now()
        )
        
        await self.db.execute(query)
        return item_id
        
    async def get_user_history(
        self,
        user_id: str,
        limit: int = 50,
        offset: int = 0
    ) -> List[Dict[str, any]]:
        """Busca o histórico de conteúdo de um usuário.
        
        Args:
            user_id: ID do usuário.
            limit: Número máximo de itens a retornar.
            offset: Offset para paginação.
            
        Returns:
            Lista de itens do histórico.
        """
        query = content_history.select().where(
            content_history.c.user_id == user_id
        ).order_by(
            content_history.c.created_at.desc()
        ).limit(limit).offset(offset)
        
        return await self.db.fetch_all(query)
```

## Conclusão

Seguir estes padrões de código ajuda a manter a qualidade e consistência da base de código do  Notion Assistant. Incentivamos todos os contribuidores a aderirem a estas diretrizes e a sugerirem melhorias quando apropriado.

Para verificar se seu código segue os padrões:

1. Execute os formatadores: `black app/ tests/`
2. Verifique o linting: `flake8 app/ tests/`
3. Verifique os tipos: `mypy app/`
4. Execute os testes: `pytest`

Estas ferramentas estão configuradas para serem executadas automaticamente no CI/CD, mas é recomendável executá-las localmente antes de submeter um Pull Request.