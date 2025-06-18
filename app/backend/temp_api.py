"""
API temporária para desenvolvimento
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

# Criar app FastAPI
app = FastAPI(
    title="NotionAI Assistant API (DEV)",
    description="API para integração com Notion e Assistentes de IA (Ambiente de Desenvolvimento)",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Configurar CORS
origins = [
    "http://localhost:8501",
    "http://127.0.0.1:8501",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Rota de saúde para verificação
@app.get("/health")
async def health_check():
    return {"status": "healthy", "message": "API de desenvolvimento em execução"}

# Rota raiz
@app.get("/")
async def root():
    return {
        "message": "NotionAI Assistant API - Ambiente de Desenvolvimento",
        "status": "online",
        "docs": "/docs"
    }

# Se executado diretamente
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
