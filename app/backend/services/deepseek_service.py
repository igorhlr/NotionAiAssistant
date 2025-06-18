from .provider_interface import AIProvider
import httpx
from typing import Dict, Any, Optional
from .prompts import ENHANCED_SYSTEM_PROMPT
import json
import logging

logger = logging.getLogger(__name__)

class DeepSeekProvider(AIProvider):
    """
    Provedor para integração com a API DeepSeek.
    Suporta os modelos DeepSeek Chat e DeepSeek Coder.
    """
    
    API_BASE_URL = "https://api.deepseek.com/v1"
    
    def __init__(self):
        self.client = None
        self.api_key = None
        self.settings = None
        
    async def initialize(self, api_key: str, settings: Optional[Dict[str, Any]] = None) -> None:
        """
        Inicializa o cliente com a chave API e configurações.
        
        Args:
            api_key: Chave de API DeepSeek
            settings: Configurações específicas para este provedor
        """
        self.api_key = api_key
        self.client = httpx.AsyncClient(timeout=httpx.Timeout(120.0))
        self.settings = settings or self.get_default_settings()
        logger.info(f"DeepSeek provider initialized with model: {self.settings.get('model')}")
        
    async def generate_content(self, prompt: str) -> str:
        """
        Gera conteúdo com base no prompt fornecido usando a API DeepSeek.
        
        Args:
            prompt: O prompt do usuário
            
        Returns:
            Conteúdo gerado pelo modelo DeepSeek
            
        Raises:
            Exception: Se houver problemas na comunicação com a API
        """
        if not self.client or not self.api_key:
            raise ValueError("Provider não inicializado. Chame initialize() primeiro.")
            
        try:
            # Preparar payload para a API
            payload = {
                "model": self.settings.get("model", "deepseek-chat"),
                "messages": [
                    {"role": "system", "content": self.settings.get("system_prompt", ENHANCED_SYSTEM_PROMPT)},
                    {"role": "user", "content": prompt}
                ],
                "temperature": float(self.settings.get("temperature", 0.7)),
                "max_tokens": int(self.settings.get("max_tokens", 1500)),
            }
            
            # Parâmetros específicos para modelo Coder, se aplicável
            if "coder" in self.settings.get("model", "").lower():
                payload["top_p"] = float(self.settings.get("top_p", 0.95))
                payload["presence_penalty"] = float(self.settings.get("presence_penalty", 0.0))
                payload["frequency_penalty"] = float(self.settings.get("frequency_penalty", 0.0))
            
            # Log da solicitação para depuração
            logger.debug(f"DeepSeek API request payload: {json.dumps(payload)}")
            
            # Enviar solicitação à API
            response = await self.client.post(
                f"{self.API_BASE_URL}/chat/completions",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json=payload
            )
            
            # Verificar resposta
            response_text = response.text
            logger.debug(f"DeepSeek API raw response: {response_text}")
            
            if response.status_code != 200:
                try:
                    error_body = response.json()
                    error_detail = error_body.get("error", {}).get("message", "Unknown error")
                except:
                    error_detail = response_text
                
                logger.error(f"DeepSeek API error: {response.status_code} - {error_detail}")
                raise Exception(f"DeepSeek API error: {error_detail}")
            
            # Processar resposta
            try:
                response_data = response.json()
                content = response_data["choices"][0]["message"]["content"]
                return content
            except KeyError as ke:
                logger.error(f"Invalid DeepSeek API response structure: {ke}")
                logger.error(f"Response data: {response_data}")
                raise Exception(f"Invalid DeepSeek API response structure: {ke}")
            
        except httpx.RequestError as e:
            logger.error(f"DeepSeek API request error: {str(e)}")
            raise Exception(f"Erro ao comunicar com a API DeepSeek: {str(e)}")
            
        except Exception as e:
            logger.error(f"Unexpected error with DeepSeek API: {str(e)}")
            raise
        
    def get_provider_name(self) -> str:
        """
        Retorna o nome do provedor.
        
        Returns:
            Nome do provedor para exibição
        """
        return "DeepSeek"
        
    def get_default_settings(self) -> Dict[str, Any]:
        """
        Retorna as configurações padrão para este provedor.
        
        Returns:
            Configurações padrão para DeepSeek
        """
        return {
            "model": "deepseek-chat",
            "system_prompt": ENHANCED_SYSTEM_PROMPT,
            "temperature": 0.7,
            "max_tokens": 2000,
            "top_p": 0.95,
            "presence_penalty": 0.0,
            "frequency_penalty": 0.0
        }
        
    async def close(self) -> None:
        """
        Fecha o cliente HTTP quando não for mais necessário.
        """
        if self.client:
            await self.client.aclose()