import logging
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import sys
import os
import json
from sqlalchemy.ext.asyncio import AsyncSession
from backend.auth import auth_backend, fastapi_users, current_active_user
from backend.models import User, create_db_and_tables, get_async_session
from backend.schemas import UserRead, UserCreate, UserSettingsUpdate
from backend.create_admin import create_admin_user
import traceback

# Configuração básica de logging
logging.basicConfig(
    level=logging.DEBUG if os.getenv("ENVIRONMENT") == "development" else logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    stream=sys.stdout
)
logger = logging.getLogger(__name__)

# Importar configuração de ambiente
from backend.environment import configure_environment

# Criar a aplicação FastAPI
app = FastAPI(title="AI Notion Assistant API")

# Configurar ambiente (desenvolvimento ou produção)
is_dev_mode = configure_environment(app)
logger.info(f"Modo de desenvolvimento: {'Ativado' if is_dev_mode else 'Desativado'}")

# Se o ambiente não foi configurado como desenvolvimento, usar configuração padrão de CORS
if not is_dev_mode:
    logger.info("Configurando CORS middleware padrão")
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# Auth routes
logger.info("Setting up authentication routes")
app.include_router(
    fastapi_users.get_auth_router(auth_backend),
    prefix="/auth/jwt",
    tags=["auth"],
)

app.include_router(
    fastapi_users.get_register_router(UserRead, UserCreate),
    prefix="/auth",
    tags=["auth"],
)

class PromptRequest(BaseModel):
    prompt: str

class NotionResponse(BaseModel):
    content: str
    notion_url: Optional[str]

@app.on_event("startup")
async def startup_event():
    logger.info("Starting up FastAPI application")
    try:
        await create_db_and_tables()
        logger.info("Database tables created successfully")
        
        # Create admin user if doesn't exist
        await create_admin_user()
    except Exception as e:
        logger.error(f"Error during startup: {str(e)}")
        raise

@app.post("/api/settings/update")
async def update_settings(
    settings: UserSettingsUpdate,
    session: AsyncSession = Depends(get_async_session),
    user: User = Depends(current_active_user)
):
    """Update user API settings"""
    try:
        logger.info(f"Updating settings for user {user.id}")

        # Get fresh user instance from current session
        fresh_user = await session.get(User, user.id)
        
        # Atualizar chaves existentes
        if settings.openai_api_key is not None:
            fresh_user.openai_api_key = settings.openai_api_key
        if settings.anthropic_api_key is not None:
            fresh_user.anthropic_api_key = settings.anthropic_api_key
        if settings.deepseek_api_key is not None:
            fresh_user.deepseek_api_key = settings.deepseek_api_key
        if settings.notion_api_key is not None:
            fresh_user.notion_api_key = settings.notion_api_key
        if settings.notion_page_id is not None:
            fresh_user.notion_page_id = settings.notion_page_id
            
        # Atualizar preferência de provedor
        if settings.ai_provider is not None:
            fresh_user.ai_provider = settings.ai_provider
            
        # Atualizar configurações específicas do provedor (convertendo para JSON string)
        if settings.openai_settings is not None:
            fresh_user.openai_settings = json.dumps(settings.openai_settings)
        if settings.anthropic_settings is not None:
            fresh_user.anthropic_settings = json.dumps(settings.anthropic_settings)
        if settings.deepseek_settings is not None:
            fresh_user.deepseek_settings = json.dumps(settings.deepseek_settings)

        await session.commit()
        logger.info("Settings updated successfully")
        return {"status": "success"}
    except Exception as e:
        logger.error(f"Error updating settings: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/generate")
async def generate_and_save(
    request: PromptRequest,
    user: User = Depends(current_active_user)
):
    """Generate content and save to Notion"""
    
    # Verificar se a chave do Notion está configurada (sempre necessária)
    if not all([user.notion_api_key, user.notion_page_id]):
        logger.error("Notion API key or page ID not configured")
        raise HTTPException(
            status_code=400, 
            detail="Por favor, configure as chaves da API Notion primeiro"
        )
    
    # Verificar apenas o provedor selecionado pelo usuário
    provider = user.ai_provider
    logger.info(f"Using provider: {provider}")
    
    if provider == "openai":
        if not user.openai_api_key:
            logger.error("OpenAI API key not configured")
            raise HTTPException(status_code=400, detail="OpenAI API key não configurada")
    elif provider == "anthropic":
        if not user.anthropic_api_key:
            logger.error("Anthropic API key not configured")
            raise HTTPException(status_code=400, detail="Anthropic API key não configurada")
    elif provider == "deepseek":
        if not user.deepseek_api_key:
            logger.error("DeepSeek API key not configured")
            raise HTTPException(status_code=400, detail="DeepSeek API key não configurada")
    else:
        logger.error(f"Invalid provider: {provider}")
        raise HTTPException(status_code=400, detail=f"Provedor inválido: {provider}")

    try:
        # Importar serviços
        from backend.services import content_generation_service, notion_service
        
        # Configurar o serviço de geração para o usuário
        logger.info(f"Initializing provider {provider} for user {user.id}")
        await content_generation_service.initialize_provider_for_user(user)
        
        # Configurar o serviço Notion usando o método atualizado
        logger.info(f"Configuring Notion service with key: {user.notion_api_key[:5]}*** and page ID: {user.notion_page_id}")
        notion_service.update_notion_client(user.notion_api_key)

        # Gerar conteúdo
        logger.info(f"Generating content using provider: {user.ai_provider}")
        content = await content_generation_service.generate_content(request.prompt)
        logger.info(f"Generated content length: {len(content)} characters")

        # Salvar para Notion
        logger.info("Saving content to Notion")
        notion_response = await notion_service.write_to_notion(content, user.notion_page_id)
        logger.info(f"Content saved to Notion: {notion_response}")

        return NotionResponse(
            content=content,
            notion_url=notion_response["url"]
        )
    except Exception as e:
        logger.error(f"Error in generate_and_save: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/providers")
async def get_available_providers(
    user: User = Depends(current_active_user)
):
    """Get available AI providers"""
    try:
        from backend.services import AIProviderFactory
        providers = AIProviderFactory.list_available_providers()
        return {"providers": providers}
    except Exception as e:
        logger.error(f"Error getting providers: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/settings")
async def get_user_settings(
    user: User = Depends(current_active_user)
):
    """Get current user settings"""
    try:
        # Convertemos as configurações salvas de volta para dicionários se necessário
        openai_settings = None
        anthropic_settings = None
        deepseek_settings = None
        
        if user.openai_settings:
            try:
                openai_settings = json.loads(user.openai_settings)
            except:
                logger.warning(f"Failed to parse openai_settings for user {user.id}")
                
        if user.anthropic_settings:
            try:
                anthropic_settings = json.loads(user.anthropic_settings)
            except:
                logger.warning(f"Failed to parse anthropic_settings for user {user.id}")
                
        if user.deepseek_settings:
            try:
                deepseek_settings = json.loads(user.deepseek_settings)
            except:
                logger.warning(f"Failed to parse deepseek_settings for user {user.id}")
                
        return {
            "openai_api_key": user.openai_api_key,
            "anthropic_api_key": user.anthropic_api_key,
            "deepseek_api_key": user.deepseek_api_key,
            "notion_api_key": user.notion_api_key,
            "notion_page_id": user.notion_page_id,
            "ai_provider": user.ai_provider,
            "openai_settings": openai_settings,
            "anthropic_settings": anthropic_settings,
            "deepseek_settings": deepseek_settings
        }
    except Exception as e:
        logger.error(f"Error getting user settings: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/health")
async def health_check():
    """Health check endpoint with dependency verification"""
    try:
        logger.info("Performing health check")
        from backend.config import get_settings
        settings = get_settings()
        return {
            "status": "healthy",
            "config_status": {
                "openai_configured": bool(settings.openai_api_key),
                "notion_configured": bool(settings.notion_api_key),
                "notion_page_configured": bool(settings.notion_page_id)
            }
        }
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Service unhealthy")

@app.get("/api/provider-status")
async def check_provider_status(
    user: User = Depends(current_active_user)
):
    """Verifica o status de configuração de cada provedor"""
    try:
        result = {
            "openai": {
                "configured": bool(user.openai_api_key),
                "is_active": user.ai_provider == "openai"
            },
            "anthropic": {
                "configured": bool(user.anthropic_api_key),
                "is_active": user.ai_provider == "anthropic"
            },
            "deepseek": {
                "configured": bool(user.deepseek_api_key),
                "is_active": user.ai_provider == "deepseek"
            },
            "notion": {
                "configured": bool(user.notion_api_key and user.notion_page_id)
            },
            "active_provider": user.ai_provider
        }
        return result
    except Exception as e:
        logger.error(f"Error checking provider status: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))