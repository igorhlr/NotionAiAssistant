from abc import ABC, abstractmethod
from typing import Dict, Any, Optional

class AIProvider(ABC):
    @abstractmethod
    async def initialize(self, api_key: str, settings: Optional[Dict[str, Any]] = None) -> None:
        """Inicializa o cliente com a chave API e configurações opcionais."""
        pass
        
    @abstractmethod
    async def generate_content(self, prompt: str) -> str:
        """Gera conteúdo com base no prompt fornecido."""
        pass
        
    @abstractmethod
    def get_provider_name(self) -> str:
        """Retorna o nome do provedor."""
        pass
        
    @abstractmethod
    def get_default_settings(self) -> Dict[str, Any]:
        """Retorna as configurações padrão para este provedor."""
        pass
