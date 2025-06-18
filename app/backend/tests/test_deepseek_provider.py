import pytest
import json
from unittest.mock import AsyncMock, patch
from httpx import Response
from backend.services.deepseek_service import DeepSeekProvider

@pytest.fixture
def mock_httpx_client():
    with patch("httpx.AsyncClient") as mock_client:
        client_instance = AsyncMock()
        mock_client.return_value = client_instance
        yield client_instance

@pytest.fixture
def deepseek_provider(mock_httpx_client):
    provider = DeepSeekProvider()
    return provider

@pytest.mark.asyncio
async def test_initialize(deepseek_provider):
    # Teste de inicialização do provedor
    await deepseek_provider.initialize("test-api-key")
    assert deepseek_provider.api_key == "test-api-key"
    assert deepseek_provider.settings["model"] == "deepseek-chat"

@pytest.mark.asyncio
async def test_generate_content_success(deepseek_provider, mock_httpx_client):
    # Configurar mock de resposta de sucesso
    mock_response = Response(
        200,
        json={
            "id": "test-id",
            "object": "chat.completion",
            "created": 1700000000,
            "model": "deepseek-chat",
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": "Este é um conteúdo de teste gerado pelo DeepSeek."
                    },
                    "finish_reason": "stop"
                }
            ],
            "usage": {
                "prompt_tokens": 50,
                "completion_tokens": 20,
                "total_tokens": 70
            }
        }
    )
    mock_httpx_client.post.return_value = mock_response
    
    # Inicializar o provedor
    await deepseek_provider.initialize("test-api-key")
    
    # Testar geração de conteúdo
    result = await deepseek_provider.generate_content("Teste de prompt")
    
    # Verificar resultado
    assert result == "Este é um conteúdo de teste gerado pelo DeepSeek."
    mock_httpx_client.post.assert_called_once()

@pytest.mark.asyncio
async def test_generate_content_error(deepseek_provider, mock_httpx_client):
    # Configurar mock de resposta de erro
    mock_response = Response(
        400,
        json={
            "error": {
                "message": "Erro de teste da API",
                "type": "invalid_request_error",
                "code": "bad_request"
            }
        }
    )
    mock_httpx_client.post.return_value = mock_response
    
    # Inicializar o provedor
    await deepseek_provider.initialize("test-api-key")
    
    # Testar erro na geração de conteúdo
    with pytest.raises(Exception) as excinfo:
        await deepseek_provider.generate_content("Teste de prompt")
    
    # Verificar mensagem de erro
    assert "Erro de teste da API" in str(excinfo.value)

@pytest.mark.asyncio
async def test_coder_model_settings(deepseek_provider, mock_httpx_client):
    # Configurar mock de resposta
    mock_response = Response(
        200,
        json={
            "id": "test-id",
            "choices": [{"message": {"content": "Código de teste"}, "index": 0, "finish_reason": "stop"}]
        }
    )
    mock_httpx_client.post.return_value = mock_response
    
    # Inicializar o provedor com configurações de modelo coder
    coder_settings = {
        "model": "deepseek-coder",
        "temperature": 0.5,
        "top_p": 0.99,
        "presence_penalty": 0.2,
        "frequency_penalty": 0.3
    }
    await deepseek_provider.initialize("test-api-key", coder_settings)
    
    # Gerar conteúdo
    await deepseek_provider.generate_content("Escreva uma função para calcular fibonacci")
    
    # Verificar se as configurações específicas do coder foram aplicadas
    call_kwargs = mock_httpx_client.post.call_args[1]
    assert "json" in call_kwargs
    sent_payload = call_kwargs["json"]
    
    assert sent_payload["model"] == "deepseek-coder"
    assert sent_payload["temperature"] == 0.5
    assert sent_payload["top_p"] == 0.99
    assert sent_payload["presence_penalty"] == 0.2
    assert sent_payload["frequency_penalty"] == 0.3
