from pydantic_settings import BaseSettings
from functools import lru_cache
import os
from dotenv import load_dotenv
import logging
from typing import Optional

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Determina se estamos em ambiente Docker
def is_running_in_docker():
    return os.path.exists('/.dockerenv') or os.environ.get('RUNNING_IN_DOCKER') == 'true'

# Função para ler secrets
def get_secret(secret_name: str, env_fallback: str, required: bool = False) -> str:
    """
    Tenta ler um secret do sistema de arquivos ou usa variável de ambiente como fallback.
    
    Args:
        secret_name: Nome do secret no Docker
        env_fallback: Variável de ambiente de fallback
        required: Se True, emite warning se não encontrado
    """
    secret_path = f"/run/secrets/{secret_name}"
    if os.path.exists(secret_path):
        try:
            with open(secret_path) as f:
                value = f.read().strip()
                logger.info(f"Secret {secret_name} carregado: {value[:3]}***")
                if value:  # Verificar se não está vazio
                    return value
        except Exception as e:
            if required:
                logger.warning(f"Erro ao ler secret {secret_name}: {str(e)}")
    
    # Fallback para variável de ambiente
    env_value = os.environ.get(env_fallback, "")
    if env_value:
        logger.info(f"Usando variável de ambiente {env_fallback}: {env_value[:3]}***")
    elif required:
        logger.warning(f"Secret {secret_name} e variável de ambiente {env_fallback} não configurados")
    
    return env_value

# Obtém a URL correta do banco de dados dependendo do ambiente
def get_database_url() -> str:
    """Constrói a URL do banco de dados usando variáveis seguras."""
    # Verificar se DATABASE_URL já foi definida diretamente
    direct_url = os.environ.get("DATABASE_URL")
    if direct_url:
        # Ocultar senha para log
        masked_url = direct_url.replace(":", ":***@", 1).split("@", 1)[0] + "@" + direct_url.split("@", 1)[1]
        logger.info(f"Usando DATABASE_URL diretamente: {masked_url}")
        return direct_url
    
    # Se não tiver URL direta, construir a partir das variáveis
    postgres_user = os.environ.get("POSTGRES_USER", "pguser_dev")
    postgres_password = get_secret("postgres_password", "POSTGRES_PASSWORD", required=True)
    postgres_db = os.environ.get("POSTGRES_DB", "notionai_dev")
    postgres_host = os.environ.get("POSTGRES_HOST", "db" if is_running_in_docker() else "localhost")
    postgres_port = os.environ.get("POSTGRES_PORT", "5432")
    
    # Verificar se as variáveis essenciais estão definidas
    if not postgres_password:
        logger.error("POSTGRES_PASSWORD não definido!")
        # Em ambiente de desenvolvimento, usar senha padrão
        if os.environ.get("ENVIRONMENT") == "development":
            logger.warning("Usando senha padrão para desenvolvimento")
            postgres_password = "dev_pg_password"
        else:
            raise ValueError("POSTGRES_PASSWORD é obrigatório")
    
    db_url = f"postgresql+asyncpg://{postgres_user}:{postgres_password}@{postgres_host}:{postgres_port}/{postgres_db}"
    
    # Log da URL (ocultando a senha)
    safe_url = db_url.replace(postgres_password, "********")
    logger.info(f"URL do banco de dados construída: {safe_url}")
    
    return db_url

class Settings(BaseSettings):
    """
    Configurações da aplicação usando variáveis seguras.
    APIs externas (OpenAI, Notion) são opcionais no startup e podem ser configuradas dinamicamente.
    """
    
    # Configurações essenciais do banco e autenticação
    database_url: str = get_database_url()
    jwt_secret: str = get_secret("jwt_secret", "JWT_SECRET", required=True)
    admin_password: str = get_secret("admin_password", "ADMIN_PASSWORD", required=True)
    admin_email: str = os.environ.get("ADMIN_EMAIL", "admin@localhost")
    
    # APIs externas - OPCIONAIS no startup (configuradas dinamicamente)
    openai_api_key: Optional[str] = get_secret("openai_api_key", "OPENAI_API_KEY", required=False)
    anthropic_api_key: Optional[str] = get_secret("anthropic_api_key", "ANTHROPIC_API_KEY", required=False)
    deepseek_api_key: Optional[str] = get_secret("deepseek_api_key", "DEEPSEEK_API_KEY", required=False)
    notion_api_key: Optional[str] = get_secret("notion_api_key", "NOTION_API_KEY", required=False)
    notion_page_id: Optional[str] = os.environ.get("NOTION_PAGE_ID", "")
    
    # Configurações de modelos AI
    openai_model: str = "gpt-4-turbo-preview"
    openai_max_tokens: int = 4096
    
    # Configurações gerais
    environment: str = os.environ.get("ENVIRONMENT", "development")
    debug: bool = os.environ.get("DEBUG", "False").lower() == "true"
    log_level: str = os.environ.get("LOG_LEVEL", "INFO")
    jwt_expire_minutes: int = int(os.environ.get("JWT_EXPIRE_MINUTES", "1440"))
    
    def __init__(self, **data):
        super().__init__(**data)
        
        # Log de inicialização (sem expor dados sensíveis)
        logger.info(f"Aplicação iniciada - Ambiente: {self.environment}")
        logger.info(f"Debug mode: {self.debug}")
        logger.info(f"Log level: {self.log_level}")
        logger.info(f"Admin email: {self.admin_email}")
        
        # Log do status das APIs externas (sem expor chaves)
        apis_status = {
            "OpenAI": "✅ Configurado" if self.openai_api_key else "⚠️  Não configurado",
            "Anthropic": "✅ Configurado" if self.anthropic_api_key else "⚠️  Não configurado", 
            "DeepSeek": "✅ Configurado" if self.deepseek_api_key else "⚠️  Não configurado",
            "Notion": "✅ Configurado" if self.notion_api_key else "⚠️  Não configurado"
        }
        
        logger.info("Status das APIs externas:")
        for api, status in apis_status.items():
            logger.info(f"  {api}: {status}")
        
        if self.notion_page_id:
            logger.info(f"Notion Page ID: {self.notion_page_id}")
        else:
            logger.info("Notion Page ID: Não configurado")
        
        # Verificações de segurança
        if self.environment == "production" and self.debug:
            logger.warning("⚠️  AVISO: Debug mode ativado em produção!")
        
        if self.jwt_secret == "your-secret-key-here-change-in-production":
            logger.error("🚨 JWT_SECRET usando valor padrão! ALTERE EM PRODUÇÃO!")

    def has_api_key(self, provider: str) -> bool:
        """Verifica se uma chave de API específica está configurada."""
        key_map = {
            "openai": self.openai_api_key,
            "anthropic": self.anthropic_api_key,
            "deepseek": self.deepseek_api_key,
            "notion": self.notion_api_key
        }
        return bool(key_map.get(provider.lower()))
    
    def get_api_key(self, provider: str) -> Optional[str]:
        """Retorna a chave de API para um provedor específico."""
        key_map = {
            "openai": self.openai_api_key,
            "anthropic": self.anthropic_api_key, 
            "deepseek": self.deepseek_api_key,
            "notion": self.notion_api_key
        }
        return key_map.get(provider.lower())
    
    def update_api_key(self, provider: str, api_key: str) -> bool:
        """
        Atualiza uma chave de API dinamicamente.
        Retorna True se atualizada com sucesso.
        """
        try:
            if provider.lower() == "openai":
                self.openai_api_key = api_key
            elif provider.lower() == "anthropic":
                self.anthropic_api_key = api_key
            elif provider.lower() == "deepseek":
                self.deepseek_api_key = api_key
            elif provider.lower() == "notion":
                self.notion_api_key = api_key
            else:
                logger.warning(f"Provedor desconhecido: {provider}")
                return False
            
            logger.info(f"Chave API atualizada para provedor: {provider}")
            return True
        except Exception as e:
            logger.error(f"Erro ao atualizar chave API para {provider}: {str(e)}")
            return False

    model_config = {
        "env_file": ".env",
        "extra": "ignore"
    }

@lru_cache()
def get_settings():
    return Settings()

# Função para resetar cache quando necessário (útil para testes)
def reset_settings_cache():
    get_settings.cache_clear()