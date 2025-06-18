from notion_client import AsyncClient
from backend.config import get_settings
from backend.services.formatter import format_for_notion, split_content
import logging
import asyncio
import os

# Configure logging
logger = logging.getLogger(__name__)

settings = get_settings()

# Melhorar o log para depuração
logger.info(f"Configurando Notion client com API key: {settings.notion_api_key[:4] if settings.notion_api_key else ''}...{settings.notion_api_key[-4:] if settings.notion_api_key else 'None'}")
logger.info(f"Page ID configurado: {settings.notion_page_id}")

# Verificar variáveis de ambiente diretamente
env_api_key = os.environ.get("NOTION_API_KEY", "")
env_page_id = os.environ.get("NOTION_PAGE_ID", "")
logger.info(f"Variável de ambiente NOTION_API_KEY: {env_api_key[:4] if env_api_key else ''}...{env_api_key[-4:] if env_api_key else 'None'}")
logger.info(f"Variável de ambiente NOTION_PAGE_ID: {env_page_id}")

# Se a chave no settings estiver vazia, tentar usar a variável de ambiente diretamente
notion_api_key = settings.notion_api_key or env_api_key

# Aumentando timeout para lidar com documentos maiores
notion = AsyncClient(auth=notion_api_key, timeout_ms=60000)  # 60 segundos

# Função para atualizar a API key do cliente Notion
def update_notion_client(api_key):
    global notion_api_key
    global notion
    
    if not api_key:
        logger.warning("Tentativa de atualizar o cliente Notion com uma API key vazia")
        return False
        
    try:
        logger.info(f"Atualizando cliente Notion com nova API key: {api_key[:4]}...{api_key[-4:]}")
        notion_api_key = api_key
        notion = AsyncClient(auth=api_key, timeout_ms=60000)
        return True
    except Exception as e:
        logger.error(f"Erro ao atualizar cliente Notion: {str(e)}")
        return False

async def create_page(title: str, formatted_blocks: list, page_id_override=None) -> str:
    """Create a new Notion page with formatted blocks"""
    try:
        # Log para depuração
        logger.info(f"Criando página no Notion com título: {title}")
        logger.info(f"Número de blocos a serem criados: {len(formatted_blocks)}")
        
        # Verificar se a API key está presente
        if not notion_api_key:
            raise ValueError("Notion API key está vazia")
        
        # Determinar qual page_id usar
        if page_id_override:
            page_id = page_id_override.replace("-", "")
            logger.info(f"Usando page_id override: {page_id}")
        else:
            # Verificar se o Page ID está presente
            if not settings.notion_page_id:
                raise ValueError("Notion Page ID está vazio")
            
            # Garantir que o page_id esteja no formato correto (sem hífens)
            page_id = settings.notion_page_id.replace("-", "")
        
        logger.info(f"Usando page_id formatado: {page_id}")
        
        # Adicionar blocos em tamanhos menores para evitar falhas
        max_blocks_per_request = 50  # Reduzido de 100 para 50 para maior estabilidade
        
        # Criar um bloco mínimo para teste se houver problemas
        if not formatted_blocks:
            formatted_blocks = [{
                "object": "block",
                "type": "paragraph",
                "paragraph": {
                    "rich_text": [{"type": "text", "text": {"content": "Teste de conexão"}}]
                }
            }]
            
        # Tentar criar a página
        try:
            response = await notion.pages.create(
                parent={"page_id": page_id},
                properties={
                    "title": {
                        "title": [
                            {
                                "text": {
                                    "content": title
                                }
                            }
                        ]
                    }
                },
                children=formatted_blocks[:max_blocks_per_request]
            )
        except Exception as api_error:
            logger.error(f"Erro na API do Notion: {str(api_error)}")
            # Tentar verificar o status da API
            try:
                # Teste simples para verificar se a API está funcionando
                user = await notion.users.me()
                logger.info(f"API do Notion está funcionando, usuário: {user.get('name')}")
            except Exception as user_error:
                logger.error(f"Erro ao verificar usuário Notion: {str(user_error)}")
            
            # Propagar o erro original
            raise api_error

        # Se houver mais blocos, append em lotes menores com pequeno intervalo entre requests
        if len(formatted_blocks) > max_blocks_per_request:
            remaining_blocks = formatted_blocks[max_blocks_per_request:]
            
            for i in range(0, len(remaining_blocks), max_blocks_per_request):
                chunk = remaining_blocks[i:i + max_blocks_per_request]
                
                try:
                    await notion.blocks.children.append(
                        block_id=response["id"],
                        children=chunk
                    )
                    # Pequena pausa para não sobrecarregar a API
                    await asyncio.sleep(1)
                except Exception as e:
                    logger.error(f"Error appending blocks {i} to {i+max_blocks_per_request}: {str(e)}")
                    # Continua mesmo com erro para tentar salvar o máximo possível de conteúdo
                    continue

        logger.info(f"Created new Notion page with ID: {response['id']}")
        return response['id']
    except Exception as e:
        logger.error(f"Error creating Notion page: {str(e)}")
        raise Exception(f"Error creating Notion page: {str(e)}")

async def write_to_notion(content: str, page_id_override=None) -> dict:
    """Write content to Notion page with proper formatting and chunking"""
    try:
        # Split content into manageable chunks
        content_chunks = split_content(content, max_length=4000)  # Aumentando tamanho máximo
        formatted_blocks = []

        # Format each chunk and combine blocks
        for chunk in content_chunks:
            try:
                blocks = format_for_notion(chunk)
                formatted_blocks.extend(blocks)
            except Exception as block_error:
                logger.warning(f"Error formatting chunk, skipping: {str(block_error)}")
                # Continue com outros chunks mesmo se um falhar
                continue

        # Validar todos os blocos antes de enviar para o Notion
        # Especialmente útil para identificar URLs inválidas
        sanitized_blocks = []
        for block in formatted_blocks:
            try:
                # Verificar se é um link com URL inválida
                if block.get("type") == "paragraph":
                    rich_text_list = block["paragraph"].get("rich_text", [])
                    for rt in rich_text_list:
                        if "link" in rt.get("text", {}):
                            url = rt["text"]["link"].get("url", "")
                            # Verificar se a URL é válida
                            if not url or not isinstance(url, str) or ' ' in url:
                                # Remover o link, manter apenas o texto
                                rt["text"].pop("link", None)
                                logger.warning(f"Removed invalid URL: '{url}'")
                
                sanitized_blocks.append(block)
            except Exception as block_error:
                logger.warning(f"Error validating block, skipping: {str(block_error)}")
                continue

        # Se não tiver blocos válidos após a sanitização, lançar erro
        if not sanitized_blocks:
            raise ValueError("No valid blocks after sanitization")

        # Create the page with formatted blocks
        page_id = await create_page("AI Generated Content", sanitized_blocks, page_id_override)

        logger.info(f"Successfully wrote content to Notion page: {page_id}")
        return {
            "id": page_id,
            "url": f"https://notion.so/{page_id.replace('-', '')}"
        }
    except Exception as e:
        logger.error(f"Error writing to Notion: {str(e)}")
        raise Exception(f"Error writing to Notion: {str(e)}")