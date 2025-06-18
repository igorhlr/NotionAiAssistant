import asyncio
import logging
import sys
import os

# Adicionar o diretório atual ao PYTHONPATH
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from backend.models import User, get_async_session, create_db_and_tables
from backend.auth import get_user_manager
from fastapi_users.password import PasswordHelper
from sqlalchemy.future import select

logger = logging.getLogger(__name__)
password_helper = PasswordHelper()

# Alternativa para anext, compatível com Python 3.9
async def get_first_item(agen):
    """Get the first item from an async generator."""
    async for item in agen:
        return item
    return None

async def create_admin_user():
    """Create a default admin user if not exists"""
    try:
        logger.info("Creating database tables...")
        await create_db_and_tables()
        
        logger.info("Checking if admin user exists...")
        
        async for session in get_async_session():
            # Usando nossa função auxiliar em vez de anext
            user_manager = await get_first_item(get_user_manager(session))
            
            # Check if admin user already exists
            stmt = select(User).where(User.email == "igorrozalem@llmway.com.br")
            result = await session.execute(stmt)
            admin_user = result.scalars().first()
            
            if admin_user:
                logger.info("Admin user already exists.")
                return
            
            # Create admin user
            logger.info("Creating admin user...")
            hashed_password = password_helper.hash("admin123")
            
            new_admin = User(
                email="igorrozalem@llmway.com.br",
                hashed_password=hashed_password,
                is_active=True,
                is_superuser=True,
                is_verified=True
            )
            
            session.add(new_admin)
            await session.commit()
            logger.info("Admin user created successfully.")
            
            # Create regular user
            logger.info("Creating regular user...")
            hashed_password = password_helper.hash("user123")
            
            new_user = User(
                email="user@example.com",
                hashed_password=hashed_password,
                is_active=True,
                is_superuser=False,
                is_verified=True
            )
            
            session.add(new_user)
            await session.commit()
            logger.info("Regular user created successfully.")
    except Exception as e:
        logger.error(f"Error creating admin user: {str(e)}")
        raise

# Executar a função quando o script é executado diretamente
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(create_admin_user())