from typing import Optional, Dict, Any
from fastapi_users import schemas
from pydantic import BaseModel

class UserRead(schemas.BaseUser[int]):
    id: int
    email: str
    is_active: bool = True
    is_superuser: bool = False
    is_verified: bool = False

    class Config:
        orm_mode = True

class UserCreate(schemas.BaseUserCreate):
    email: str
    password: str
    is_active: Optional[bool] = True
    is_superuser: Optional[bool] = False
    is_verified: Optional[bool] = False

class UserSettingsUpdate(BaseModel):
    # API keys para diferentes provedores
    openai_api_key: Optional[str] = None 
    anthropic_api_key: Optional[str] = None
    deepseek_api_key: Optional[str] = None
    
    # Notion settings
    notion_api_key: Optional[str] = None
    notion_page_id: Optional[str] = None
    
    # Configurações de AI
    ai_provider: Optional[str] = None
    openai_settings: Optional[Dict[str, Any]] = None
    anthropic_settings: Optional[Dict[str, Any]] = None
    deepseek_settings: Optional[Dict[str, Any]] = None
