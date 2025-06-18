from anthropic import AsyncAnthropic
from typing import Dict, Any, Optional
from .provider_interface import AIProvider
from .prompts import ENHANCED_SYSTEM_PROMPT
import logging

logger = logging.getLogger(__name__)

class AnthropicProvider(AIProvider):
    def __init__(self):
        self.client = None
        self.settings = None
        
    async def initialize(self, api_key: str, settings: Optional[Dict[str, Any]] = None) -> None:
        """Inicializa o cliente Anthropic"""
        self.client = AsyncAnthropic(api_key=api_key)
        self.settings = settings or self.get_default_settings()
        logger.info(f"Anthropic provider initialized with model: {self.settings.get('model')}")
        
    async def generate_content(self, prompt: str) -> str:
        """Gera conteúdo usando o modelo Claude da Anthropic"""
        try:
            response = await self.client.messages.create(
                model=self.settings.get("model", "claude-3-opus-20240229"),
                max_tokens=self.settings.get("max_tokens", 1500),
                system=self.settings.get("system_prompt", ENHANCED_SYSTEM_PROMPT),
                messages=[
                    {"role": "user", "content": prompt}
                ],
                temperature=self.settings.get("temperature", 0.7),
            )
            return response.content[0].text
        except Exception as e:
            logger.error(f"Error generating content with Anthropic: {str(e)}")
            raise Exception(f"Error generating content with Anthropic: {str(e)}")
        
    def get_provider_name(self) -> str:
        """Retorna o nome do provedor"""
        return "Anthropic Claude"
        
    def get_default_settings(self) -> Dict[str, Any]:
        """Retorna as configurações padrão para o provedor Anthropic"""
        return {
            "model": "claude-3-opus-20240229",
            "system_prompt": ENHANCED_SYSTEM_PROMPT,
            "temperature": 0.7,
            "max_tokens": 4000  # Aumentando de 1500 para 4000
        }
