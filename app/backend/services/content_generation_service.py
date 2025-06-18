from .ai_provider_factory import AIProviderFactory
from backend.models import User
import json
import logging

logger = logging.getLogger(__name__)

class ContentGenerationService:
    def __init__(self):
        self.provider = None
        
    async def initialize_provider_for_user(self, user: User):
        """Inicializa o provedor apropriado para o usuário"""
        provider_name = user.ai_provider
        logger.info(f"Initializing provider '{provider_name}' for user {user.id}")
        
        try:
            self.provider = AIProviderFactory.get_provider(provider_name)
            
            # Verificar e configurar o provedor específico
            if provider_name == "openai":
                if not user.openai_api_key:
                    raise ValueError("OpenAI API key não configurada")
                    
                settings = self._parse_settings(user.openai_settings)
                logger.debug(f"OpenAI settings: {settings}")
                await self.provider.initialize(user.openai_api_key, settings)
                
            elif provider_name == "anthropic":
                if not user.anthropic_api_key:
                    raise ValueError("Anthropic API key não configurada")
                    
                settings = self._parse_settings(user.anthropic_settings)
                logger.debug(f"Anthropic settings: {settings}")
                await self.provider.initialize(user.anthropic_api_key, settings)
                
            elif provider_name == "deepseek":
                if not user.deepseek_api_key:
                    raise ValueError("DeepSeek API key não configurada")
                    
                settings = self._parse_settings(user.deepseek_settings)
                logger.debug(f"DeepSeek settings: {settings}")
                await self.provider.initialize(user.deepseek_api_key, settings)
                
            else:
                logger.error(f"Unsupported provider: {provider_name}")
                raise ValueError(f"Unsupported provider: {provider_name}")
            
            logger.info(f"Provider '{provider_name}' initialized successfully")
        except Exception as e:
            logger.error(f"Error initializing provider: {str(e)}")
            raise
    
    def _parse_settings(self, settings_json):
        """Converte as configurações de JSON para dicionário se necessário"""
        if not settings_json:
            logger.debug("No settings provided, using defaults")
            return {}
            
        if isinstance(settings_json, dict):
            return settings_json
            
        try:
            settings = json.loads(settings_json)
            # Certificar-se de que os valores numéricos são do tipo certo
            for key, value in settings.items():
                if key in ["temperature", "top_p", "presence_penalty", "frequency_penalty"]:
                    if value is not None:
                        settings[key] = float(value)
                elif key in ["max_tokens"]:
                    if value is not None:
                        settings[key] = int(value)
            return settings
        except (json.JSONDecodeError, TypeError) as e:
            logger.error(f"Error parsing settings JSON: {str(e)}")
            return {}
    
    async def generate_content(self, prompt: str) -> str:
        """Gera conteúdo usando o provedor inicializado"""
        if not self.provider:
            logger.error("Provider not initialized. Call initialize_provider_for_user first")
            raise ValueError("Provider not initialized. Call initialize_provider_for_user first")
        
        try:
            logger.info(f"Generating content with provider: {self.provider.get_provider_name()}")
            return await self.provider.generate_content(prompt)
        except Exception as e:
            logger.error(f"Error generating content: {str(e)}")
            raise

# Instância global do serviço
content_generation_service = ContentGenerationService()
