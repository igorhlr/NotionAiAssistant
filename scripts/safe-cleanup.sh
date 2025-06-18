#!/bin/bash
# Script de Limpeza Segura do Projeto NotionAiAssistant
# Remove arquivos desnecessários mantendo a funcionalidade

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$PROJECT_DIR/logs/cleanup.log"
DRY_RUN="${1:-false}"

# Criar diretório de logs se não existir
mkdir -p "$(dirname "$LOG_FILE")"

# Função de logging
log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

# Função para confirmação interativa
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [ "$DRY_RUN" == "true" ]; then
        echo "[DRY RUN] $prompt"
        return 0
    fi
    
    while true; do
        read -p "$prompt [y/N]: " -n 1 -r
        echo
        case $REPLY in
            [Yy]) return 0 ;;
            [Nn]|"") return 1 ;;
            *) echo "Por favor, responda y ou n." ;;
        esac
    done
}

# Função para remoção segura
safe_remove() {
    local path="$1"
    local description="$2"
    
    if [ ! -e "$path" ]; then
        log "INFO" "$description - não existe, ignorando"
        return 0
    fi
    
    if [ "$DRY_RUN" == "true" ]; then
        log "DRY_RUN" "Removeria: $path ($description)"
        return 0
    fi
    
    if confirm "Remover $description?"; then
        if [ -d "$path" ]; then
            rm -rf "$path"
            log "INFO" "Diretório removido: $path"
        else
            rm -f "$path"
            log "INFO" "Arquivo removido: $path"
        fi
    else
        log "INFO" "Mantido: $path ($description)"
    fi
}

# Função principal de limpeza
main() {
    log "INFO" "Iniciando limpeza segura do projeto NotionAiAssistant"
    
    if [ "$DRY_RUN" == "true" ]; then
        log "INFO" "MODO DRY RUN - Nenhum arquivo será removido"
    fi
    
    echo "🧹 LIMPEZA SEGURA DO PROJETO"
    echo "=========================="
    echo ""
    
    # 1. Remover arquivos .DS_Store (macOS)
    echo "📱 Removendo arquivos .DS_Store do macOS..."
    find "$PROJECT_DIR" -name ".DS_Store" -type f 2>/dev/null | while read -r file; do
        safe_remove "$file" "Arquivo .DS_Store do macOS"
    done
    
    # 2. Remover diretórios .ropeproject (Python IDE)
    echo ""
    echo "🐍 Removendo configurações do Rope (Python IDE)..."
    find "$PROJECT_DIR" -name ".ropeproject" -type d 2>/dev/null | while read -r dir; do
        safe_remove "$dir" "Configuração do Rope (Python IDE)"
    done
    
    # 3. Lidar com fastDocs.md
    echo ""
    echo "📄 Analisando documentação duplicada..."
    if [ -f "$PROJECT_DIR/fastDocs.md" ]; then
        echo "Encontrado fastDocs.md no root do projeto."
        echo "Este arquivo pode ser movido para /docs para melhor organização."
        
        if confirm "Mover fastDocs.md para docs/fastDocs.md?"; then
            if [ "$DRY_RUN" != "true" ]; then
                mv "$PROJECT_DIR/fastDocs.md" "$PROJECT_DIR/docs/fastDocs.md"
                log "INFO" "fastDocs.md movido para docs/"
            else
                log "DRY_RUN" "Moveria fastDocs.md para docs/"
            fi
        fi
    fi
    
    # 4. Limpar logs vazios
    echo ""
    echo "📋 Limpando logs vazios..."
    if [ -d "$PROJECT_DIR/logs" ]; then
        find "$PROJECT_DIR/logs" -name "*.log" -size 0 2>/dev/null | while read -r log_file; do
            safe_remove "$log_file" "Log vazio"
        done
    fi
    
    # 5. Remover arquivos de backup antigos
    echo ""
    echo "💾 Removendo arquivos de backup antigos..."
    find "$PROJECT_DIR" \( -name "*.bak" -o -name "*.backup" -o -name "*~" \) 2>/dev/null | while read -r backup_file; do
        safe_remove "$backup_file" "Arquivo de backup antigo"
    done
    
    # 6. Limpar __pycache__ desnecessários
    echo ""
    echo "🐍 Limpando cache do Python..."
    find "$PROJECT_DIR" -name "__pycache__" -type d 2>/dev/null | while read -r cache_dir; do
        safe_remove "$cache_dir" "Cache do Python"
    done
    
    # 7. Remover arquivos .pyc
    echo ""
    echo "🗑️  Removendo arquivos compilados do Python..."
    find "$PROJECT_DIR" -name "*.pyc" -type f 2>/dev/null | while read -r pyc_file; do
        safe_remove "$pyc_file" "Arquivo Python compilado"
    done
    
    # 8. Verificar e otimizar .gitignore
    echo ""
    echo "📝 Verificando .gitignore..."
    if [ -f "$PROJECT_DIR/.gitignore" ]; then
        log "INFO" ".gitignore encontrado e está atualizado"
    else
        log "WARNING" ".gitignore não encontrado - considere criar um"
    fi
    
    # 9. Relatório final
    echo ""
    echo "📊 RELATÓRIO FINAL:"
    echo "=================="
    
    local total_files=$(find "$PROJECT_DIR" -type f | wc -l)
    local total_dirs=$(find "$PROJECT_DIR" -type d | wc -l)
    local project_size=$(du -sh "$PROJECT_DIR" 2>/dev/null | cut -f1)
    
    echo "📁 Arquivos restantes: $total_files"
    echo "📂 Diretórios restantes: $total_dirs"
    echo "💾 Tamanho atual: $project_size"
    
    # 10. Verificar integridade crítica
    echo ""
    echo "🔍 VERIFICAÇÃO DE INTEGRIDADE:"
    echo "============================="
    
    local critical_files=(
        "docker-compose.yml"
        "Makefile"
        "config/secrets"
        "app"
        "scripts"
        ".github/workflows"
    )
    
    local missing_critical=()
    
    for critical in "${critical_files[@]}"; do
        if [ ! -e "$PROJECT_DIR/$critical" ]; then
            missing_critical+=("$critical")
        else
            echo "✅ $critical"
        fi
    done
    
    if [ ${#missing_critical[@]} -gt 0 ]; then
        log "ERROR" "Arquivos críticos faltando: ${missing_critical[*]}"
        echo "❌ ATENÇÃO: Arquivos críticos estão faltando!"
        echo "   ${missing_critical[*]}"
    else
        log "INFO" "Todos os arquivos críticos estão presentes"
        echo "✅ Todos os arquivos críticos estão presentes"
    fi
    
    log "INFO" "Limpeza concluída"
    
    if [ "$DRY_RUN" == "true" ]; then
        echo ""
        echo "💡 Para executar a limpeza real, execute:"
        echo "   $0 false"
    fi
    
    echo ""
    echo "📋 Log completo disponível em: $LOG_FILE"
}

# Verificar argumentos
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "Uso: $0 [dry_run]"
    echo ""
    echo "Parâmetros:"
    echo "  true|dry_run  - Executar em modo simulação (não remove arquivos)"
    echo "  false         - Executar limpeza real (padrão)"
    echo ""
    echo "Exemplos:"
    echo "  $0 true       - Simular limpeza"
    echo "  $0 false      - Executar limpeza real"
    echo "  $0            - Executar limpeza real (padrão)"
    exit 0
fi

# Executar limpeza
main
