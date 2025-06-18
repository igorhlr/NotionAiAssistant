from openai import AsyncOpenAI
from typing import Dict, Any, Optional
from .provider_interface import AIProvider
from .prompts import ENHANCED_SYSTEM_PROMPT
import logging

logger = logging.getLogger(__name__)

class OpenAIProvider(AIProvider):
    def __init__(self):
        self.client = None
        self.settings = None
        
    async def initialize(self, api_key: str, settings: Optional[Dict[str, Any]] = None) -> None:
        """Inicializa o cliente OpenAI"""
        self.client = AsyncOpenAI(api_key=api_key)
        self.settings = settings or self.get_default_settings()
        logger.info(f"OpenAI provider initialized with model: {self.settings.get('model')}")
        
    async def generate_content(self, prompt: str) -> str:
        """Gera conteúdo usando o modelo GPT da OpenAI"""
        try:
            response = await self.client.chat.completions.create(
                model=self.settings.get("model", "gpt-4o"),
                messages=[
                    {"role": "system", "content": self.settings.get("system_prompt", ENHANCED_SYSTEM_PROMPT)},
                    {"role": "user", "content": prompt}
                ],
                temperature=self.settings.get("temperature", 0.7),
                max_tokens=self.settings.get("max_tokens", 1500)
            )
            return response.choices[0].message.content
        except Exception as e:
            logger.error(f"Error generating content with OpenAI: {str(e)}")
            raise Exception(f"Error generating content with OpenAI: {str(e)}")
        
    def get_provider_name(self) -> str:
        """Retorna o nome do provedor"""
        return "OpenAI"
        
    def get_default_settings(self) -> Dict[str, Any]:
        """Retorna as configurações padrão para o provedor OpenAI"""
        return {
            "model": "gpt-4o", 
            "system_prompt": ENHANCED_SYSTEM_PROMPT,
            "temperature": 0.7,
            "max_tokens": 4000  # Aumentando de 1500 para 4000
        }
