from datetime import datetime
from typing import AsyncGenerator
from fastapi import Depends
from fastapi_users.db import SQLAlchemyBaseUserTable, SQLAlchemyUserDatabase
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import Mapped, mapped_column, declarative_base
from sqlalchemy import text
import os
import logging
import traceback
from urllib.parse import urlparse, urlunparse
from .config import get_settings

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

settings = get_settings()

Base = declarative_base()

class User(SQLAlchemyBaseUserTable[int], Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    email: Mapped[str] = mapped_column(unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(nullable=False)
    is_active: Mapped[bool] = mapped_column(default=True, nullable=False)
    is_superuser: Mapped[bool] = mapped_column(default=False, nullable=False)
    is_verified: Mapped[bool] = mapped_column(default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow, nullable=False)
    
    # API keys para diferentes provedores
    openai_api_key: Mapped[str] = mapped_column(nullable=True)
    anthropic_api_key: Mapped[str] = mapped_column(nullable=True)
    deepseek_api_key: Mapped[str] = mapped_column(nullable=True)
    
    # Notion settings
    notion_api_key: Mapped[str] = mapped_column(nullable=True)
    notion_page_id: Mapped[str] = mapped_column(nullable=True)
    
    # Configurações de AI
    ai_provider: Mapped[str] = mapped_column(default="openai", nullable=False)
    openai_settings: Mapped[str] = mapped_column(nullable=True)
    anthropic_settings: Mapped[str] = mapped_column(nullable=True)
    deepseek_settings: Mapped[str] = mapped_column(nullable=True)

# Create async database URL
database_url = settings.database_url
logger.info(f"Configurando conexão com: {database_url}")

# Add asyncpg driver if not already present
if 'postgresql+asyncpg://' not in database_url:
    database_url = database_url.replace('postgresql://', 'postgresql+asyncpg://')
    logger.info(f"URL ajustada para driver asyncpg: {database_url}")

async_url = database_url

# Validate URL before creating engine
try:
    parsed_url = urlparse(async_url)
    if not all([parsed_url.scheme, parsed_url.netloc]):
        raise ValueError(f"URL inválida: {async_url}")
    logger.info(f"Hostname: {parsed_url.hostname}, Porta: {parsed_url.port}")
except Exception as e:
    logger.error(f"Erro ao validar URL do banco de dados: {str(e)}")
    logger.error(traceback.format_exc())
    raise

# Create async engine
try:
    engine = create_async_engine(
        async_url,
        echo=True,
        pool_pre_ping=True,
        pool_size=10,
        max_overflow=20
    )
    logger.info("Engine do SQLAlchemy criada com sucesso")
except Exception as e:
    logger.error(f"Erro ao criar engine do SQLAlchemy: {str(e)}")
    logger.error(traceback.format_exc())
    raise

async def create_db_and_tables():
    """Initialize database and create tables"""
    try:
        logger.info(f"Tentando conectar ao banco de dados: {async_url}")
        async with engine.begin() as conn:
            # Check if tables exist already
            exists = await conn.run_sync(lambda sync_conn: sync_conn.dialect.has_table(sync_conn, 'users'))
            
            # If tables exist and we need to recreate them, drop them first
            if exists:
                logger.info("Dropping existing tables")
                await conn.run_sync(Base.metadata.drop_all)
            
            # Create tables
            await conn.run_sync(Base.metadata.create_all)
            logger.info("Database tables created successfully")
    except Exception as e:
        logger.error(f"Error during database initialization: {str(e)}")
        logger.error(traceback.format_exc())
        raise

async def get_async_session() -> AsyncGenerator[AsyncSession, None]:
    """Get async database session"""
    async with AsyncSession(engine) as session:
        try:
            yield session
        except Exception as e:
            logger.error(f"Database session error: {str(e)}")
            await session.rollback()
            raise
        finally:
            await session.close()

async def get_user_db(session: AsyncSession = Depends(get_async_session)):
    """Get user database dependency"""
    yield SQLAlchemyUserDatabase(session, User)