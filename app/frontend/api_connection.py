"""
Módulo para conexão com a API
"""
import os
import requests
import streamlit as st

# Importar configuração da API
try:
    from api_config import API_URL
except ImportError:
    # Fallback para desenvolvimento local fora do container
    API_URL = os.getenv("NOTION_API_BACKEND_URL", "http://localhost:8080")

def check_api_health():
    """Verifica se a API está saudável"""
    try:
        response = requests.get(f"{API_URL}/api/health", timeout=5)
        return response.status_code == 200
    except Exception:
        # Tentar endpoint raiz como fallback (para desenvolvimento)
        try:
            response = requests.get(f"{API_URL}/health", timeout=5)
            return response.status_code == 200
        except Exception:
            return False

def init_connection():
    """Inicializa a conexão com a API no estado da sessão"""
    if "api_healthy" not in st.session_state:
        st.session_state.api_healthy = check_api_health()