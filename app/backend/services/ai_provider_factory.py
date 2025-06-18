from typing import Dict, Type
from .provider_interface import AIProvider
from .openai_service import OpenAIProvider
from .anthropic_service import AnthropicProvider
from .deepseek_service import DeepSeekProvider
import logging

logger = logging.getLogger(__name__)

class AIProviderFactory:
    _providers: Dict[str, Type[AIProvider]] = {
        "openai": OpenAIProvider,
        "anthropic": AnthropicProvider,
        "deepseek": DeepSeekProvider,
    }
    
    @classmethod
    def get_provider(cls, provider_name: str) -> AIProvider:
        """Retorna uma instância do provedor com o nome especificado"""
        provider_class = cls._providers.get(provider_name.lower())
        if not provider_class:
            logger.error(f"Provedor desconhecido: {provider_name}")
            raise ValueError(f"Provedor desconhecido: {provider_name}")
        return provider_class()
    
    @classmethod
    def list_available_providers(cls) -> Dict[str, str]:
        """Retorna um dicionário com os nomes dos provedores disponíveis"""
        result = {}
        for name, provider_class in cls._providers.items():
            provider_instance = provider_class()
            result[name] = provider_instance.get_provider_name()
        return result
