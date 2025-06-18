"""
Configuração de ambiente para NotionAiAssistant
"""
import os
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Configurar logging
logger = logging.getLogger(__name__)

def configure_environment(app: FastAPI) -> bool:
    """
    Configura o ambiente da aplicação.
    Retorna True se estiver em modo de desenvolvimento.
    """
    environment = os.environ.get("ENVIRONMENT", "development").lower()
    debug = os.environ.get("DEBUG", "False").lower() == "true"
    
    logger.info(f"Configurando ambiente: {environment}")
    logger.info(f"Debug mode: {debug}")
    
    # Configurações de desenvolvimento
    if environment == "development" or debug:
        logger.info("Configurando ambiente de desenvolvimento")
        
        # Configurar CORS para desenvolvimento
        origins = [
            "http://localhost:8501",
            "http://127.0.0.1:8501",
            "http://localhost:8080",
            "http://127.0.0.1:8080",
            "*"  # Para facilitar desenvolvimento local
        ]
        
        logger.info(f"Configurando CORS com origens: {origins}")
        
        app.add_middleware(
            CORSMiddleware,
            allow_origins=origins,
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )
        
        # Definir diretório de logs
        os.makedirs("logs", exist_ok=True)
        
        # Verificar variáveis de ambiente para o PostgreSQL
        pg_user = os.environ.get("POSTGRES_USER")
        pg_password_file = "/run/secrets/postgres_password"
        
        # Verificar secrets
        if os.path.exists("/run/secrets"):
            logger.info("Diretório de secrets encontrado")
            secrets = os.listdir("/run/secrets")
            logger.info(f"Secrets disponíveis: {secrets}")
            
            # Verificar se as senhas estão disponíveis
            if os.path.exists(pg_password_file):
                with open(pg_password_file, "r") as f:
                    pg_password = f.read().strip()
                    logger.info(f"Senha do PostgreSQL lida do secret (primeiros 3 caracteres): {pg_password[:3]}***")
                    
                    # Exportar para variável de ambiente diretamente
                    os.environ["POSTGRES_PASSWORD"] = pg_password
                    logger.info("POSTGRES_PASSWORD exportada como variável de ambiente")
            else:
                logger.warning(f"Secret {pg_password_file} não encontrado!")
        else:
            logger.warning("Diretório de secrets não encontrado!")
        
        logger.info(f"POSTGRES_USER configurado como: {pg_user}")
        
        # Log de outras variáveis de ambiente
        pg_db = os.environ.get("POSTGRES_DB")
        pg_host = os.environ.get("POSTGRES_HOST")
        pg_port = os.environ.get("POSTGRES_PORT")
        
        logger.info(f"POSTGRES_DB: {pg_db}")
        logger.info(f"POSTGRES_HOST: {pg_host}")
        logger.info(f"POSTGRES_PORT: {pg_port}")
        
        return True  # Ambiente de desenvolvimento
    
    # Configurações de produção
    logger.info("Configurando ambiente de produção")
    
    # Configurações adicionais para produção podem ser adicionadas aqui
    
    return False  # Ambiente de produção