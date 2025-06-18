"""
Este script executa uma migração para adicionar colunas para o provedor DeepSeek ao modelo de usuário.
"""

import asyncio
import logging
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from backend.models import engine

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def add_deepseek_columns():
    """Adiciona as colunas necessárias para o provedor DeepSeek"""
    try:
        async with AsyncSession(engine) as session:
            # Verificar se a coluna deepseek_api_key já existe
            query = """
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = 'users' AND column_name = 'deepseek_api_key';
            """
            result = await session.execute(text(query))
            exists = result.fetchone() is not None
            
            if not exists:
                # Adicionar coluna deepseek_api_key
                await session.execute(text(
                    "ALTER TABLE users ADD COLUMN IF NOT EXISTS deepseek_api_key VARCHAR;"
                ))
                
                # Adicionar coluna deepseek_settings
                await session.execute(text(
                    "ALTER TABLE users ADD COLUMN IF NOT EXISTS deepseek_settings VARCHAR;"
                ))
                
                await session.commit()
                logger.info("Colunas para DeepSeek adicionadas com sucesso")
            else:
                logger.info("Colunas para DeepSeek já existem")
                
    except Exception as e:
        logger.error(f"Erro ao adicionar colunas para DeepSeek: {str(e)}")
        raise

if __name__ == "__main__":
    asyncio.run(add_deepseek_columns())