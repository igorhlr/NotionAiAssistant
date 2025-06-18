import streamlit as st
import tiktoken
import time
import httpx
import json
import asyncio
import traceback

# API URL configuration
API_BASE_URL = "http://localhost:8080"

st.set_page_config(
    page_title=" Notion Assistant",
    page_icon="📝",
    layout="wide"
)

# Initialize session state
if 'messages' not in st.session_state:
    st.session_state.messages = []
if 'token_count' not in st.session_state:
    st.session_state.token_count = 0
if 'access_token' not in st.session_state:
    st.session_state.access_token = None
if 'user_email' not in st.session_state:
    st.session_state.user_email = None
if 'provider_changed' not in st.session_state:
    st.session_state.provider_changed = False
if 'show_notion_key_tutorial' not in st.session_state:
    st.session_state.show_notion_key_tutorial = False
if 'show_notion_id_tutorial' not in st.session_state:
    st.session_state.show_notion_id_tutorial = False
if 'notion_key_tutorial_step' not in st.session_state:
    st.session_state.notion_key_tutorial_step = 1
if 'notion_id_tutorial_step' not in st.session_state:
    st.session_state.notion_id_tutorial_step = 1
if 'show_general_help' not in st.session_state:
    st.session_state.show_general_help = False
if 'show_about_help' not in st.session_state:
    st.session_state.show_about_help = False
if 'language' not in st.session_state:
    st.session_state.language = "pt"  # Default language: Portuguese

# Translations dictionary
translations = {
    "pt": {
        "login": "Entrar",
        "register": "Registrar",
        "email": "Email",
        "password": "Senha",
        "confirm_password": "Confirmar Senha",
        "enter_credentials": "Entre com suas credenciais",
        "create_account": "Crie sua conta",
        "passwords_dont_match": "As senhas não coincidem",
        "fill_all_fields": "Por favor, preencha todos os campos",
        "login_successful": "Login realizado com sucesso!",
        "registration_successful": "Registro realizado com sucesso! Por favor, faça login.",
        "about_llm_way": "O que é IA Notion Assistant?",
        "how_to_use": "Guia de uso",
        "notion_settings": "Configurações do Notion",
        "notion_api_key": "Chave API do Notion",
        "notion_page_id": "ID da Página do Notion",
        "save_settings": "Salvar Configurações",
        "how_to_get": "Como obter",
        "how_to_get_api_key": "Como obter API Key",
        "how_to_get_page_id": "Como obter Page ID",
        "close": "Fechar",
        "next": "Próximo",
        "previous": "Anterior",
        "close_tutorial": "Fechar Tutorial",
        "about_title": "Sobre o  Notion Assistant",
        "step": "Passo",
        "about_description": """
        ##  Notion Assistant
        
        O ** Notion Assistant** é uma ferramenta que permite interagir com Modelos de Linguagem de grande escala (LLMs) como OpenAI GPT, Claude da Anthropic e DeepSeek, e salvar automaticamente o conteúdo gerado em suas páginas do Notion.
        
        ### Principais recursos:
        
        - **Fácil integração com o Notion**: Conecte-se diretamente à sua conta do Notion
        - **Múltiplos provedores de IA**: Escolha entre OpenAI, Claude e DeepSeek
        - **Configurações personalizáveis**: Ajuste parâmetros como temperatura e modelo
        - **Salvamento automático**: Todo conteúdo gerado é salvo automaticamente no Notion
        - **Interface amigável**: Interaja naturalmente através de uma interface de chat
        
        ### Como começar:
        
        1. Crie uma conta utilizando o formulário de registro
        2. Obtenha sua chave de API do Notion e configure sua integração
        3. Escolha e configure seu provedor de IA preferido
        4. Comece a gerar conteúdo diretamente para o Notion!
        
        Criado por [Igor Rozalem](https://github.com/igorhlr) | [LinkedIn](https://www.linkedin.com/in/igor-rozalem-a67560209/) | [Buy Me a Coffee](https://buymeacoffee.com/igorrozalem)
        
        Mais informações: [docs.notionassistant.llmway.com.br](https://docs.notionassistant.llmway.com.br/)
        """,
        "guide_title": "Guia Rápido de Uso",
        "guide_description": """
        
        
        ### Configuração inicial:
        
        1. **Configurar o Notion**:
           - Na barra lateral, clique em "API Settings"
           - Preencha sua Notion API Key (clique em "Como obter" se precisar de ajuda)
           - Preencha o ID da página do Notion onde o conteúdo será salvo
           - Clique em "Salvar Configurações"
        
        2. **Escolha um provedor de IA**:
           - Selecione uma das abas: OpenAI, Claude ou DeepSeek
           - Insira sua chave de API para o provedor escolhido
           - Ajuste as configurações conforme necessário
           - Marque a opção "Usar [provedor] para geração"
           - Clique em "Salvar Configurações"
        
        ### Usando o assistente:
        
        1. Digite sua mensagem ou prompt no campo de chat na parte inferior da tela
        2. O assistente irá gerar o conteúdo utilizando o provedor de IA selecionado
        3. O conteúdo gerado será automaticamente salvo na sua página do Notion
        4. Você verá um link para visualizar o conteúdo diretamente no Notion
        
        ### Dicas:
        
        - Seja específico em seus prompts para obter melhores resultados
        - Experimente diferentes provedores de IA para diferentes tipos de conteúdo
        - Ajuste as configurações de temperatura para controlar a criatividade da resposta
        """,
        "change_language": "English",
        "api_key_tutorial_title": "Como obter sua Notion API Key",
        "page_id_tutorial_title": "Como obter o ID da sua Página do Notion",
        "logout": "Sair",
        "api_settings": "Configurações de API"
    },
    "en": {
        "login": "Login",
        "register": "Register",
        "email": "Email",
        "password": "Password",
        "confirm_password": "Confirm Password",
        "enter_credentials": "Enter your credentials",
        "create_account": "Create your account",
        "passwords_dont_match": "Passwords don't match",
        "fill_all_fields": "Please fill all fields",
        "login_successful": "Login successful!",
        "registration_successful": "Registration successful! Please login.",
        "about_llm_way": "What is Notion Ai Assistant ?",
        "how_to_use": "How to use",
        "notion_settings": "Notion Settings",
        "notion_api_key": "Notion API Key",
        "notion_page_id": "Notion Page ID",
        "save_settings": "Save Settings",
        "how_to_get": "How to get",
        "how_to_get_api_key": "How to get API Key",
        "how_to_get_page_id": "How to get Page ID",
        "close": "Close",
        "next": "Next",
        "previous": "Previous",
        "close_tutorial": "Close Tutorial",
        "about_title": "About  Notion Assistant",
        "step": "Step",
        "about_description": """
        ##  Notion Assistant
        
        The ** Notion Assistant** is a tool that allows you to interact with Large Language Models (LLMs) such as OpenAI GPT, Anthropic's Claude, and DeepSeek, and automatically save the generated content to your Notion pages.
        
        ### Key features:
        
        - **Easy Notion integration**: Connect directly to your Notion account
        - **Multiple AI providers**: Choose between OpenAI, Claude, and DeepSeek
        - **Customizable settings**: Adjust parameters like temperature and model
        - **Automatic saving**: All generated content is automatically saved to Notion
        - **User-friendly interface**: Interact naturally through a chat interface
        
        ### Getting started:
        
        1. Create an account using the registration form
        2. Get your Notion API key and configure your integration
        3. Choose and configure your preferred AI provider
        4. Start generating content directly to Notion!
        
        Created by [Igor Rozalem](https://github.com/igorhlr) | [LinkedIn](https://www.linkedin.com/in/igor-rozalem-a67560209/) | [Buy Me a Coffee](https://buymeacoffee.com/igorrozalem)
        
        More information: [docs.notionassistant.llmway.com.br](https://docs.notionassistant.llmway.com.br/)
        """,
        "guide_title": "Quick User Guide",
        "guide_description": """
        
        
        ### Initial setup:
        
        1. **Configure Notion**:
           - In the sidebar, click on "API Settings"
           - Fill in your Notion API Key (click on "How to get" if you need help)
           - Fill in the ID of the Notion page where the content will be saved
           - Click on "Save Settings"
        
        2. **Choose an AI provider**:
           - Select one of the tabs: OpenAI, Claude, or DeepSeek
           - Enter your API key for the chosen provider
           - Adjust the settings as needed
           - Check the "Use [provider] for generation" option
           - Click on "Save Settings"
        
        ### Using the assistant:
        
        1. Type your message or prompt in the chat field at the bottom of the screen
        2. The assistant will generate content using the selected AI provider
        3. The generated content will be automatically saved to your Notion page
        4. You will see a link to view the content directly in Notion
        
        ### Tips:
        
        - Be specific in your prompts to get better results
        - Try different AI providers for different types of content
        - Adjust temperature settings to control the creativity of the response
        """,
        "change_language": "Português",
        "api_key_tutorial_title": "How to get your Notion API Key",
        "page_id_tutorial_title": "How to get your Notion Page ID",
        "logout": "Logout",
        "api_settings": "API Settings"
    }
}

def count_tokens(text: str) -> int:
    encoder = tiktoken.get_encoding("cl100k_base")
    return len(encoder.encode(text))

async def test_backend_connection():
    """Test the connection to the backend API"""
    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(60.0)) as client:
            response = await client.get(
                f"{API_BASE_URL}/api/health",
                timeout=5.0
            )
            return response.status_code == 200, response.text
    except Exception as e:
        return False, str(e)

async def get_user_settings():
    """Obtém as configurações atuais do usuário"""
    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(60.0)) as client:
            response = await client.get(
                f"{API_BASE_URL}/api/settings",
                headers={"Authorization": f"Bearer {st.session_state.access_token}"}
            )
            if response.status_code == 200:
                return response.json()
            else:
                st.error(f"Failed to get user settings: {response.status_code}")
                return None
    except Exception as e:
        st.error(f"Error getting user settings: {str(e)}")
        return None

async def register(email: str, password: str) -> bool:
    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(60.0)) as client:
            response = await client.post(
                f"{API_BASE_URL}/auth/register",
                json={
                    "email": email,
                    "password": password
                }
            )
            if response.status_code == 201:
                st.success("Registration successful! Please login.")
                return True
            st.error(f"Registration failed: {response.text}")
            return False
    except Exception as e:
        st.error(f"Registration error: {str(e)}")
        st.error(traceback.format_exc())
        return False

async def login(email: str, password: str) -> bool:
    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(60.0)) as client:
            response = await client.post(
                f"{API_BASE_URL}/auth/jwt/login",
                data={
                    "username": email,
                    "password": password,
                    "grant_type": "password"
                },
                headers={"Content-Type": "application/x-www-form-urlencoded"},
                timeout=30.0
            )
            if response.status_code == 200:
                data = response.json()
                st.session_state.access_token = data["access_token"]
                st.session_state.user_email = email
                return True
            st.error(f"Login failed: {response.status_code}")
            st.error(f"Response: {response.text}")
            return False
    except Exception as e:
        st.error(f"Login error: {str(e)}")
        st.error(traceback.format_exc())
        return False

async def generate_content(prompt: str) -> tuple[str, str]:
    async with httpx.AsyncClient(timeout=httpx.Timeout(300.0)) as client:  # Aumentando timeout para 5 minutos
        try:
            response = await client.post(
                f"{API_BASE_URL}/api/generate",
                json={"prompt": prompt},
                headers={"Authorization": f"Bearer {st.session_state.access_token}"}
            )
            response.raise_for_status()
            data = response.json()
            return data["content"], data["notion_url"]
        except Exception as e:
            st.error(f"Error generating content: {str(e)}")
            st.error(traceback.format_exc())
            return None, None

def logout():
    st.session_state.access_token = None
    st.session_state.user_email = None
    st.session_state.messages = []
    st.rerun()

if not st.session_state.access_token:
    # Language selector
    lang = st.session_state.language
    t = translations[lang]
    
        # Test backend connection
    connection_status, message = asyncio.run(test_backend_connection())
    if connection_status:
        st.success("Seja muito bem vindo!😁") # Backend connection successful!
    else:
        st.error(f"Backend connection failed: {message}")
        st.info(f"Make sure the backend server is running at {API_BASE_URL}")

    # Adicionar espaço antes das abas
    st.write("")
    

    # Botão para alternar idioma
    language_col1, language_col2 = st.columns([9, 1])
    with language_col2:
        if st.button(t["change_language"]):
            st.session_state.language = "en" if lang == "pt" else "pt"
            st.rerun()
    
    # Exibir a logo do  Notion Assistant de forma mais responsiva
    col1, col2, col3 = st.columns([1, 1, 1])
    with col2:
        st.image("img/logo-notionia.png", use_container_width=True)
    
    # Adicionar um espaçamento após o logo
    st.write("")
    st.write("")
    
    # Botão de ajuda na página de login
    help_col1, help_col2, help_col3 = st.columns([3, 1, 3])
    with help_col2:
        if st.button(t["about_llm_way"], use_container_width=True):
            st.session_state['show_about_help'] = True
    
    # Exibir informações sobre o 
    if st.session_state.get('show_about_help', False):
        with st.expander(t["about_title"], expanded=True):
            st.markdown(t["about_description"])
            
            if st.button(t["close"], key="close_about_help"):
                st.session_state['show_about_help'] = False
                st.rerun()

    # # Test backend connection
    # connection_status, message = asyncio.run(test_backend_connection())
    # if connection_status:
    #     st.success("Seja muito bem vindo!😁") # Backend connection successful!
    # else:
    #     st.error(f"Backend connection failed: {message}")
    #     st.info(f"Make sure the backend server is running at {API_BASE_URL}")

    # # Adicionar espaço antes das abas
    # st.write("")
    
    tab1, tab2 = st.tabs([t["login"], t["register"]])

    with tab1:
        with st.form("login_form"):
            st.subheader(t["enter_credentials"])
            email = st.text_input(t["email"], placeholder="seu@email.com")
            password = st.text_input(t["password"], type="password", placeholder="••••••••")
            
            # Centralizar o botão de login
            col1, col2, col3 = st.columns([1, 1, 1])
            with col2:
                submit = st.form_submit_button(t["login"], use_container_width=True)

            if submit and email and password:
                if asyncio.run(login(email, password)):
                    st.success(t["login_successful"])
                    time.sleep(1)
                    st.rerun()

    with tab2:
        with st.form("register_form"):
            st.subheader(t["create_account"])
            reg_email = st.text_input(t["email"], placeholder="seu@email.com")
            reg_password = st.text_input(t["password"], type="password", placeholder="••••••••")
            reg_password_confirm = st.text_input(t["confirm_password"], type="password", placeholder="••••••••")
            
            # Centralizar o botão de registro
            col1, col2, col3 = st.columns([1, 1, 1])
            with col2:
                submit = st.form_submit_button(t["register"], use_container_width=True)

            if submit:
                if not reg_email or not reg_password:
                    st.error(t["fill_all_fields"])
                elif reg_password != reg_password_confirm:
                    st.error(t["passwords_dont_match"])
                else:
                    asyncio.run(register(reg_email, reg_password))

else:
    # Language selector
    lang = st.session_state.language
    t = translations[lang]
    
    # Botão para alternar idioma
    language_col1, language_col2 = st.columns([9, 1])
    with language_col2:
        if st.button(t["change_language"]):
            st.session_state.language = "en" if lang == "pt" else "pt"
            st.rerun()
    
    # Exibir a logo do  Notion Assistant de forma mais responsiva
    col1, col2, col3 = st.columns([1, 1, 1])
    with col2:
        st.image("img/logo-notionia.png", use_container_width=True)
    
    # Adicionar espaço após o logo
    st.write("")
    st.write("")
    
    # Área de botões de ajuda - organizados em 3 colunas
    help_col1, help_col2, help_col3 = st.columns(3)
    with help_col1:
        if st.button(t["how_to_use"], use_container_width=True):
            st.session_state['show_general_help'] = True
            st.session_state['show_notion_key_tutorial'] = False
            st.session_state['show_notion_id_tutorial'] = False
    
    with help_col2:
        if st.button(t["how_to_get_api_key"], use_container_width=True):
            st.session_state['show_notion_key_tutorial'] = True
            st.session_state['show_general_help'] = False
            st.session_state['show_notion_id_tutorial'] = False
            st.session_state['notion_key_tutorial_step'] = 1
    
    with help_col3:
        if st.button(t["how_to_get_page_id"], use_container_width=True):
            st.session_state['show_notion_id_tutorial'] = True
            st.session_state['show_general_help'] = False
            st.session_state['show_notion_key_tutorial'] = False
            st.session_state['notion_id_tutorial_step'] = 1
    
    # Área de conteúdo - imagem centralizada e maior
    st.write("")
    
    # Exibir o conteúdo ativo ocupando toda a largura
    if st.session_state.get('show_general_help', False):
        st.header(t["guide_title"])
        st.markdown(t["guide_description"])
        
        if st.button(t["close"], key="close_general_help"):
            st.session_state['show_general_help'] = False
            st.rerun()

    # Mostrar o tutorial de como obter a API Key do Notion
    if st.session_state.get('show_notion_key_tutorial', False):
        st.header(t["api_key_tutorial_title"])
        
        current_step = st.session_state.notion_key_tutorial_step
        
        # Descrições para cada passo
        step_descriptions = {
            1: "Acesse o site do Notion e faça login na sua conta." if lang == "pt" else "Access the Notion website and log in to your account.",
            2: "Clique no seu perfil no canto inferior esquerdo e depois em 'Settings & members'." if lang == "pt" else "Click on your profile in the bottom left corner and then on 'Settings & members'.",
            3: "No menu lateral, escolha 'Connections'." if lang == "pt" else "In the side menu, choose 'Connections'.",
            4: "Role para baixo até 'Develop or manage integrations' e clique no link." if lang == "pt" else "Scroll down to 'Develop or manage integrations' and click on the link.",
            5: "Você será redirecionado para a página de integrações. Clique em '+ New integration'." if lang == "pt" else "You will be redirected to the integrations page. Click on '+ New integration'.",
            6: "Preencha o nome da sua integração e clique em 'Submit'." if lang == "pt" else "Fill in the name of your integration and click on 'Submit'.",
            7: "Selecione as permissões adequadas para sua integração. No mínimo, você precisará de 'Read content', 'Update content' e 'Insert content'." if lang == "pt" else "Select the appropriate permissions for your integration. At minimum, you'll need 'Read content', 'Update content', and 'Insert content'.",
            8: "Role para baixo e clique em 'Submit' para criar sua integração." if lang == "pt" else "Scroll down and click on 'Submit' to create your integration.",
            9: "Sua integração foi criada! Agora copie o 'Internal Integration Token'." if lang == "pt" else "Your integration has been created! Now copy the 'Internal Integration Token'.",
            10: "Cole o token copiado no campo 'Notion API Key' da aplicação." if lang == "pt" else "Paste the copied token into the 'Notion API Key' field of the application.",
            11: "Lembre-se de compartilhar sua página do Notion com a integração criada. Clique nos três pontos da página e depois em 'Add connections'." if lang == "pt" else "Remember to share your Notion page with the created integration. Click on the three dots of the page and then on 'Add connections'."
        }
        
        # Exibir a imagem e descrição centralizadas
        if 1 <= current_step <= 11:
            image_path = f"img/{current_step}.png"
            
            # Mostrar a descrição do passo atual
            st.write(f"**{t['step']} {current_step}/11:** {step_descriptions.get(current_step, '')}")
            
            # Exibir a imagem atual em tamanho maior
            st.image(image_path, use_container_width=True)
            
            # Botões de navegação
            nav_col1, nav_col2, nav_col3 = st.columns([1, 5, 1])
            with nav_col1:
                if current_step > 1:
                    if st.button(f"⬅️ {t['previous']}", key="prev_key"):
                        st.session_state.notion_key_tutorial_step -= 1
                        st.rerun()
            
            with nav_col3:
                if current_step < 11:
                    if st.button(f"{t['next']} ➡️", key="next_key"):
                        st.session_state.notion_key_tutorial_step += 1
                        st.rerun()
                else:
                    if st.button(t["close_tutorial"], key="close_key"):
                        st.session_state.show_notion_key_tutorial = False
                        st.rerun()
    
    # Mostrar o tutorial de como obter o Page ID do Notion
    if st.session_state.get('show_notion_id_tutorial', False):
        st.header(t["page_id_tutorial_title"])
        
        current_step = st.session_state.notion_id_tutorial_step
        
        # Descrições para cada passo
        step_descriptions = {
            1: "Abra a página do Notion que deseja conectar. Na barra de endereço do navegador, você verá a URL completa. O ID da página é a parte após 'notion.so/' e geralmente começa após a última barra (/) e contém caracteres alfanuméricos." if lang == "pt" else "Open the Notion page you want to connect. In the browser's address bar, you'll see the full URL. The page ID is the part after 'notion.so/' and usually starts after the last slash (/) and contains alphanumeric characters.",
            2: "Copie o ID da página e cole-o no campo 'Notion Page ID' da aplicação." if lang == "pt" else "Copy the page ID and paste it into the 'Notion Page ID' field of the application."
        }
        
        # Exibir a imagem e descrição centralizadas
        total_steps = 2  # Temos duas imagens para este tutorial
        if 1 <= current_step <= total_steps:
            image_path = f"img/{11 + current_step}-id-pg.png"
            
            # Mostrar a descrição do passo atual
            st.write(f"**{t['step']} {current_step}/2:** {step_descriptions.get(current_step, '')}")
            
            # Exibir a imagem atual em tamanho maior
            st.image(image_path, use_container_width=True)
            
            # Botões de navegação
            nav_col1, nav_col2, nav_col3 = st.columns([1, 5, 1])
            with nav_col1:
                if current_step > 1:
                    if st.button(f"⬅️ {t['previous']}", key="prev_id"):
                        st.session_state.notion_id_tutorial_step -= 1
                        st.rerun()
            
            with nav_col3:
                if current_step < total_steps:
                    if st.button(f"{t['next']} ➡️", key="next_id"):
                        st.session_state.notion_id_tutorial_step += 1
                        st.rerun()
                else:
                    if st.button(t["close_tutorial"], key="close_id"):
                        st.session_state.show_notion_id_tutorial = False
                        st.rerun()
    
    st.sidebar.button(t["logout"], on_click=logout)

    # Display user email
    st.sidebar.text(f"Logged in as: {st.session_state.user_email}")
    
    # Carrega as configurações do usuário se ainda não tivermos carregado
    if 'user_settings' not in st.session_state:
        with st.spinner("Loading settings..."):
            st.session_state.user_settings = asyncio.run(get_user_settings()) or {}
    
    # Settings in sidebar
    with st.sidebar:
        # Language selector
        lang = st.session_state.language
        t = translations[lang]
        
        st.header(t["api_settings"])
        
        # Obter valores das configurações atuais
        settings = st.session_state.get("user_settings", {})
        notion_key_value = settings.get("notion_api_key", "")
        notion_id_value = settings.get("notion_page_id", "")
        openai_key_value = settings.get("openai_api_key", "")
        anthropic_key_value = settings.get("anthropic_api_key", "")
        deepseek_key_value = settings.get("deepseek_api_key", "")
        
        openai_settings = settings.get("openai_settings", {}) or {}
        anthropic_settings = settings.get("anthropic_settings", {}) or {}
        deepseek_settings = settings.get("deepseek_settings", {}) or {}
        
        # Grupo de configurações do Notion (fora das abas)
        with st.form(key="notion_settings_form_" + str(id(st.session_state.access_token))):
            st.subheader(t["notion_settings"])
            
            # Campos para Notion API Key e Page ID
            notion_key = st.text_input(t["notion_api_key"], value=notion_key_value, type="password")
            notion_id = st.text_input(t["notion_page_id"], value=notion_id_value)
            
            notion_submit = st.form_submit_button(t["save_settings"])
            
            if notion_submit:
                async def save_notion_settings():
                    try:
                        settings_data = {
                            "notion_api_key": notion_key,
                            "notion_page_id": notion_id
                        }
                        
                        async with httpx.AsyncClient(timeout=httpx.Timeout(120.0)) as client:
                            response = await client.post(
                                f"{API_BASE_URL}/api/settings/update",
                                json=settings_data,
                                headers={"Authorization": f"Bearer {st.session_state.access_token}"}
                            )
                            if response.status_code == 200:
                                st.success("Notion settings saved!")
                                # Atualizar as configurações armazenadas
                                st.session_state.user_settings = await get_user_settings()
                            else:
                                st.error(f"Failed to save settings: {response.text}")
                    except Exception as e:
                        st.error(f"Error: {str(e)}")
                        st.error(traceback.format_exc())
                
                asyncio.run(save_notion_settings())
        
        # Abas para provedores de IA
        st.subheader("AI Provider Settings")
        ai_tab1, ai_tab2, ai_tab3 = st.tabs(["OpenAI", "Claude", "DeepSeek"])
        
        # Aba OpenAI
        with ai_tab1:
            with st.form("openai_settings_form"):
                openai_key = st.text_input("OpenAI API Key", value=openai_key_value, type="password")
                openai_model = st.selectbox(
                    "Model", 
                    ["gpt-4o", "gpt-4-turbo", "gpt-3.5-turbo"],
                    index=0 if not openai_settings.get("model") else 
                           ["gpt-4o", "gpt-4-turbo", "gpt-3.5-turbo"].index(openai_settings.get("model", "gpt-4o")),
                    key="openai_model"
                )
                openai_temp = st.slider(
                    "Temperature", 
                    0.0, 1.0, 
                    value=openai_settings.get("temperature", 0.7), 
                    step=0.1, 
                    key="openai_temp"
                )
                
                openai_settings_data = {
                    "model": openai_model,
                    "temperature": openai_temp
                }
                
                openai_use = st.checkbox("Use OpenAI for generation", 
                                       value=settings.get("ai_provider") == "openai", 
                                       key="use_openai")
                
                openai_submit = st.form_submit_button("Save OpenAI Settings")
                
                if openai_submit:
                    async def save_openai_settings():
                        try:
                            settings_data = {
                                "openai_api_key": openai_key,
                                "openai_settings": openai_settings_data
                            }
                            
                            # Se o checkbox estiver marcado, define como provedor padrão
                            if openai_use:
                                settings_data["ai_provider"] = "openai"
                            
                            async with httpx.AsyncClient(timeout=httpx.Timeout(120.0)) as client:
                                response = await client.post(
                                    f"{API_BASE_URL}/api/settings/update",
                                    json=settings_data,
                                    headers={"Authorization": f"Bearer {st.session_state.access_token}"}
                                )
                                if response.status_code == 200:
                                    st.success("OpenAI settings saved!")
                                    # Atualizar as configurações armazenadas
                                    st.session_state.user_settings = await get_user_settings()
                                else:
                                    st.error(f"Failed to save settings: {response.text}")
                        except Exception as e:
                            st.error(f"Error: {str(e)}")
                            st.error(traceback.format_exc())
                    
                    asyncio.run(save_openai_settings())
        
        # Aba Claude
        with ai_tab2:
            with st.form("claude_settings_form"):
                claude_key = st.text_input("Anthropic API Key", value=anthropic_key_value, type="password")
                
                claude_models = ["claude-3-opus-20240229", "claude-3-sonnet-20240229", "claude-3-haiku-20240307"]
                
                claude_model = st.selectbox(
                    "Model", 
                    claude_models,
                    index=0 if not anthropic_settings.get("model") else 
                           claude_models.index(anthropic_settings.get("model", "claude-3-opus-20240229")),
                    key="claude_model"
                )
                
                claude_temp = st.slider(
                    "Temperature", 
                    0.0, 1.0, 
                    value=anthropic_settings.get("temperature", 0.7), 
                    step=0.1, 
                    key="claude_temp"
                )
                
                claude_settings_data = {
                    "model": claude_model,
                    "temperature": claude_temp
                }
                
                claude_use = st.checkbox("Use Claude for generation", 
                                        value=settings.get("ai_provider") == "anthropic", 
                                        key="use_claude")
                
                claude_submit = st.form_submit_button("Save Claude Settings")
                
                if claude_submit:
                    async def save_claude_settings():
                        try:
                            settings_data = {
                                "anthropic_api_key": claude_key,
                                "anthropic_settings": claude_settings_data
                            }
                            
                            # Se o checkbox estiver marcado, define como provedor padrão
                            if claude_use:
                                settings_data["ai_provider"] = "anthropic"
                            
                            async with httpx.AsyncClient(timeout=httpx.Timeout(120.0)) as client:
                                response = await client.post(
                                    f"{API_BASE_URL}/api/settings/update",
                                    json=settings_data,
                                    headers={"Authorization": f"Bearer {st.session_state.access_token}"}
                                )
                                if response.status_code == 200:
                                    st.success("Claude settings saved!")
                                    # Atualizar as configurações armazenadas
                                    st.session_state.user_settings = await get_user_settings()
                                else:
                                    st.error(f"Failed to save settings: {response.text}")
                        except Exception as e:
                            st.error(f"Error: {str(e)}")
                            st.error(traceback.format_exc())
                    
                    asyncio.run(save_claude_settings())
                    
        # Aba DeepSeek
        with ai_tab3:
            with st.form("deepseek_settings_form"):
                deepseek_key = st.text_input("DeepSeek API Key", value=deepseek_key_value, type="password")
                
                deepseek_models = ["deepseek-chat", "deepseek-coder", "deepseek-chat-v2"]
                
                deepseek_model = st.selectbox(
                    "Model", 
                    deepseek_models,
                    index=0 if not deepseek_settings.get("model") else 
                           deepseek_models.index(deepseek_settings.get("model", "deepseek-chat")),
                    key="deepseek_model"
                )
                
                deepseek_temp = st.slider(
                    "Temperature", 
                    0.0, 1.0, 
                    value=deepseek_settings.get("temperature", 0.7), 
                    step=0.1, 
                    key="deepseek_temp"
                )
                
                deepseek_max_tokens = st.number_input(
                    "Max Tokens",
                    min_value=100,
                    max_value=4000,
                    value=deepseek_settings.get("max_tokens", 1500),
                    step=100,
                    key="deepseek_max_tokens"
                )
                
                deepseek_settings_data = {
                    "model": deepseek_model,
                    "temperature": deepseek_temp,
                    "max_tokens": deepseek_max_tokens
                }
                
                # Opções adicionais para o modelo Coder
                if "coder" in deepseek_model:
                    with st.expander("Opções Avançadas"):
                        top_p = st.slider(
                            "Top P", 
                            0.0, 1.0, 
                            value=deepseek_settings.get("top_p", 0.95), 
                            step=0.01, 
                            key="deepseek_top_p"
                        )
                        
                        presence_penalty = st.slider(
                            "Presence Penalty", 
                            0.0, 2.0, 
                            value=deepseek_settings.get("presence_penalty", 0.0), 
                            step=0.1, 
                            key="deepseek_presence_penalty"
                        )
                        
                        frequency_penalty = st.slider(
                            "Frequency Penalty", 
                            0.0, 2.0, 
                            value=deepseek_settings.get("frequency_penalty", 0.0), 
                            step=0.1, 
                            key="deepseek_frequency_penalty"
                        )
                        
                        deepseek_settings_data.update({
                            "top_p": top_p,
                            "presence_penalty": presence_penalty,
                            "frequency_penalty": frequency_penalty
                        })
                
                deepseek_use = st.checkbox(
                    "Use DeepSeek for generation", 
                    value=settings.get("ai_provider") == "deepseek", 
                    key="use_deepseek"
                )
                
                deepseek_submit = st.form_submit_button("Save DeepSeek Settings")
                
                if deepseek_submit:
                    async def save_deepseek_settings():
                        try:
                            settings_data = {
                                "deepseek_api_key": deepseek_key,
                                "deepseek_settings": deepseek_settings_data
                            }
                            
                            # Se o checkbox estiver marcado, define como provedor padrão
                            if deepseek_use:
                                settings_data["ai_provider"] = "deepseek"
                            
                            async with httpx.AsyncClient(timeout=httpx.Timeout(120.0)) as client:
                                response = await client.post(
                                    f"{API_BASE_URL}/api/settings/update",
                                    json=settings_data,
                                    headers={"Authorization": f"Bearer {st.session_state.access_token}"}
                                )
                                if response.status_code == 200:
                                    st.success("DeepSeek settings saved!")
                                    # Atualizar as configurações armazenadas
                                    st.session_state.user_settings = await get_user_settings()
                                else:
                                    st.error(f"Failed to save settings: {response.text}")
                        except Exception as e:
                            st.error(f"Error: {str(e)}")
                            st.error(traceback.format_exc())
                    
                    asyncio.run(save_deepseek_settings())

    # Chat interface
    # Mostrar qual provedor está sendo usado
    active_provider = settings.get("ai_provider", "openai")
    provider_display_name = "OpenAI"
    if active_provider == "anthropic":
        provider_display_name = "Claude"
    elif active_provider == "deepseek":
        provider_display_name = "DeepSeek"
    
    st.info(f"**Provedor ativo:** {provider_display_name}")
    
    for message in st.session_state.messages:
        with st.chat_message(message["role"]):
            st.markdown(message["content"])
            if "notion_url" in message:
                st.markdown(f"[View in Notion]({message['notion_url']})")

    if prompt := st.chat_input("Type your message"):
        st.session_state.messages.append({"role": "user", "content": prompt})
        with st.chat_message("user"):
            st.markdown(prompt)

        with st.chat_message("assistant"):
            message_placeholder = st.empty()
            message_placeholder.info(f"Gerando conteúdo com {provider_display_name}. Isso pode levar alguns segundos...")
            
            progress_bar = st.progress(0)
            for i in range(25):
                # Simulando os estágios de progresso
                progress_bar.progress(i * 4)
                if i == 5:
                    message_placeholder.info(f"Processando seu prompt com {provider_display_name}...")
                elif i == 15:
                    message_placeholder.info(f"Formatando resposta para o Notion...")
                elif i == 20:
                    message_placeholder.info(f"Enviando para o Notion...")
                time.sleep(0.1)
                
            content, notion_url = asyncio.run(generate_content(prompt))
            progress_bar.progress(100)
            
            if content and notion_url:
                message_placeholder.empty()
                st.markdown(content)
                st.success(f"✅ Conteúdo gerado com sucesso!")
                st.markdown(f"[Visualizar no Notion]({notion_url})")
                st.session_state.messages.append({
                    "role": "assistant",
                    "content": content,
                    "notion_url": notion_url
                })
            else:
                message_placeholder.error("Ocorreu um erro na geração do conteúdo. Por favor, tente novamente ou verifique os logs.")
            
            # Esconder a barra de progresso quando terminar
            progress_bar.empty()