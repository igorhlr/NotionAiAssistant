import re
from typing import List, Dict, Any

def get_valid_notion_language(language: str) -> str:
    """Map language to a valid Notion code block language"""
    # List of languages supported by Notion API
    valid_languages = [
        "abap", "agda", "arduino", "assembly", "bash", "basic", "c", "c#", "c++", 
        "clojure", "coffeescript", "css", "dart", "diff", "docker", "elixir", 
        "elm", "erlang", "f#", "flow", "fortran", "go", "graphql", "groovy", 
        "haskell", "html", "java", "javascript", "json", "julia", "kotlin", "latex", 
        "less", "lisp", "lua", "makefile", "markdown", "matlab", "mermaid", 
        "nix", "objective-c", "ocaml", "pascal", "perl", "php", "python", 
        "r", "ruby", "rust", "scala", "scheme", "scss", "shell", "sql", 
        "swift", "typescript", "vb.net", "verilog", "vhdl", "xml", "yaml"
    ]
    
    # Normalize the language name
    language = language.lower() if language else ""
    
    # Common aliases and normalization
    language_mapping = {
        # JavaScript variants
        "js": "javascript",
        "jsx": "javascript",
        "node": "javascript",
        "nodejs": "javascript",
        "es6": "javascript",
        
        # JSON variants
        "jsonc": "json",
        "json5": "json",
        
        # Python variants
        "py": "python",
        "python3": "python",
        "py3": "python",
        "ipython": "python",
        
        # Shell variants
        "sh": "shell",
        "bash": "shell",
        "zsh": "shell",
        "ksh": "shell",
        
        # YAML variants
        "yml": "yaml",
        
        # Markup variants
        "md": "markdown",
        
        # TypeScript variants
        "ts": "typescript",
        "tsx": "typescript",
        
        # C-like languages
        "csharp": "c#",
        "cpp": "c++",
        
        # Other common aliases
        "dockerfile": "docker",
        "reactjs": "javascript",
        "reactts": "typescript",
        "vue": "javascript",
        "angular": "typescript"
    }
    
    # First check if it's a known alias
    if language in language_mapping:
        language = language_mapping[language]
    
    # Return the language if it's valid, otherwise default to "plain text"
    if language in valid_languages:
        return language
    elif language == "" or language == "plain_text" or language == "text":
        return "plain text"  # Notion's default for plain text
    else:
        # If not found in valid_languages, check once more after removing special chars
        normalized = ''.join(e for e in language if e.isalnum()).lower()
        if normalized in valid_languages:
            return normalized
        for valid in valid_languages:
            if normalized == ''.join(e for e in valid if e.isalnum()).lower():
                return valid
                
        # Last resort: try to guess based on common prefixes
        if normalized.startswith("java"):
            return "javascript" if "script" in normalized else "java"
        elif normalized.startswith("type") or normalized.endswith("ts"):
            return "typescript"
        elif normalized.startswith("py") or normalized == "script":
            return "python"
        else:
            return "plain text"  # Default fallback

def process_rich_text(text: str) -> List[Dict[str, Any]]:
    """Process inline formatting for rich text"""
    # This is a simplified version - in a real implementation, 
    # you'd want to handle nested formatting and more complex cases
    rich_text = []
    
    # Split the text by formatting markers
    segments = re.split(r'(\*\*.*?\*\*|\*.*?\*|`.*?`|~~.*?~~|\[.*?\]\(.*?\))', text)
    
    for segment in segments:
        if not segment:
            continue
            
        # Bold text: **text**
        bold_match = re.match(r'\*\*(.*?)\*\*', segment)
        if bold_match:
            rich_text.append({
                "text": {"content": bold_match.group(1)},
                "annotations": {"bold": True}
            })
            continue
            
        # Italic text: *text*
        italic_match = re.match(r'\*(.*?)\*', segment)
        if italic_match:
            rich_text.append({
                "text": {"content": italic_match.group(1)},
                "annotations": {"italic": True}
            })
            continue
            
        # Code inline: `text`
        code_match = re.match(r'`(.*?)`', segment)
        if code_match:
            rich_text.append({
                "text": {"content": code_match.group(1)},
                "annotations": {"code": True}
            })
            continue
            
        # Strikethrough: ~~text~~
        strike_match = re.match(r'~~(.*?)~~', segment)
        if strike_match:
            rich_text.append({
                "text": {"content": strike_match.group(1)},
                "annotations": {"strikethrough": True}
            })
            continue
            
        # Link: [text](url)
        link_match = re.match(r'\[(.*?)\]\((.*?)\)', segment)
        if link_match:
            url = link_match.group(2).strip()
            
            # Validar e corrigir URLs
            # Adicionar protocolo se estiver faltando (nem http:// nem https://)
            if url and not re.match(r'^https?://', url) and not url.startswith('#'):
                url = 'https://' + url
                
            # Verificar se a URL é minimamente válida (não vazia e contém pelo menos um ponto)
            if url and ('.' in url or url.startswith('http://localhost') or url.startswith('#')):
                rich_text.append({
                    "text": {
                        "content": link_match.group(1),
                        "link": {"url": url}
                    }
                })
            else:
                # Se a URL for inválida, renderize apenas o texto sem link
                rich_text.append({
                    "text": {"content": link_match.group(1)}
                })
            continue
            
        # Regular text
        rich_text.append({"text": {"content": segment}})
    
    return rich_text

def format_for_notion(text: str) -> List[Dict[str, Any]]:
    """Converts Markdown text to Notion blocks with proper formatting"""
    lines = text.split("\n")
    blocks = []
    current_code_block = None
    in_list = False
    in_table = False
    table_rows = []
    in_quote_block = False
    quote_content = []

    i = 0
    while i < len(lines):
        line = lines[i].rstrip()
        i += 1

        # Detect horizontal rule/separator (---)
        if re.match(r'^-{3,}$', line):
            blocks.append({
                "type": "divider",
                "divider": {}
            })
            continue

        # Detect code block start (```language)
        code_match = re.match(r"```(\w*)$", line)
        if not code_match:
            # Tentar outro formato possível como ```javascript ou ```json com espaços
            code_match = re.match(r"```([a-zA-Z0-9_\-+#]+)\s*$", line.strip())
            
        if code_match and current_code_block is None:
            language = code_match.group(1)
            
            # Se não especificou a linguagem, tentar inferir do contexto
            if not language and i < len(lines) - 1:
                next_line = lines[i].strip()
                
                # Tentar identificar a linguagem com base nas próximas linhas
                if re.match(r'(import|from|def|class|if\s+__name__)', next_line):
                    language = "python"
                elif re.match(r'(function|const|let|var|import\s+{|export)', next_line):
                    language = "javascript"
                elif re.match(r'(#include|int\s+main|namespace)', next_line):
                    language = "cpp"
                elif re.match(r'(<\?php|namespace)', next_line):
                    language = "php"
                elif re.match(r'(public\s+class|import\s+java)', next_line):
                    language = "java"
                elif re.match(r'(\{|\[)(\s*"[^"]+"\s*:|\s*\d+\s*,)', next_line):
                    language = "json"
                elif re.match(r'(<[a-zA-Z][^>]*>)', next_line):
                    language = "html"
                
            # Start a new code block
            current_code_block = {
                "type": "code",
                "code": {
                    "rich_text": [],
                    "language": get_valid_notion_language(language)
                }
            }
            continue
        
        # Detect code block end
        if re.match(r"^\s*```\s*$", line) and current_code_block is not None:
            # Close the current code block
            blocks.append(current_code_block)
            current_code_block = None
            continue

        # Add lines to current code block
        if current_code_block is not None:
            current_code_block["code"]["rich_text"].append({"text": {"content": line + "\n"}})
            continue
            
        # Process quote blocks (lines starting with >)
        if line.startswith('>'):
            if not in_quote_block:
                in_quote_block = True
                quote_content = []
            
            # Add the line without the '>' prefix to the quote content
            quote_content.append(line[1:].strip())
            continue
        else:
            # End of quote block
            if in_quote_block:
                in_quote_block = False
                # Join all quote lines and process rich text formatting
                quote_text = "\n".join(quote_content)
                blocks.append({
                    "type": "quote",
                    "quote": {
                        "rich_text": process_rich_text(quote_text)
                    }
                })
                quote_content = []

        # Process tables
        if line.strip().startswith("|") and line.strip().endswith("|"):
            if not in_table:
                in_table = True
                table_rows = []
            
            # Clean up the table row
            cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
            table_rows.append(cells)
            
            # Check if next line is a separator row (|---|---|)
            if i < len(lines) and re.match(r'^\s*\|[-:\s]*\|[-:\s]*\|\s*$', lines[i]):
                i += 1  # Skip the separator row
            continue
        else:
            # End of table
            if in_table and len(table_rows) >= 2:
                # Process table into a database block
                # This is a simplified version - in a real implementation,
                # you'd want to handle more complex table structures
                table_block = {
                    "type": "table",
                    "table": {
                        "table_width": len(table_rows[0]),
                        "has_column_header": True,
                        "has_row_header": False,
                        "children": []
                    }
                }
                
                # Add each row as a table_row block
                for row_idx, row in enumerate(table_rows):
                    table_row = {
                        "type": "table_row",
                        "table_row": {
                            "cells": []
                        }
                    }
                    
                    # Add each cell's content
                    for cell in row:
                        table_row["table_row"]["cells"].append(process_rich_text(cell))
                    
                    table_block["table"]["children"].append(table_row)
                
                blocks.append(table_block)
                in_table = False
                table_rows = []

        # Skip empty lines outside of code blocks
        if not line.strip():
            # Add a paragraph with a newline for spacing
            blocks.append({
                "type": "paragraph",
                "paragraph": {"rich_text": []}
            })
            continue

        # Headers with # syntax
        if line.startswith("# "):
            blocks.append({
                "type": "heading_1",
                "heading_1": {"rich_text": process_rich_text(line[2:])}
            })
        elif line.startswith("## "):
            blocks.append({
                "type": "heading_2",
                "heading_2": {"rich_text": process_rich_text(line[3:])}
            })
        elif line.startswith("### "):
            blocks.append({
                "type": "heading_3",
                "heading_3": {"rich_text": process_rich_text(line[4:])}
            })
        # Bullet points
        elif line.startswith("- ") or line.startswith("* "):
            content = line[2:]
            blocks.append({
                "type": "bulleted_list_item",
                "bulleted_list_item": {"rich_text": process_rich_text(content)}
            })
        # Numbered lists
        elif re.match(r"^\d+\. ", line):
            content = re.sub(r"^\d+\. ", "", line)
            blocks.append({
                "type": "numbered_list_item",
                "numbered_list_item": {"rich_text": process_rich_text(content)}
            })
        # Regular paragraphs
        else:
            blocks.append({
                "type": "paragraph",
                "paragraph": {"rich_text": process_rich_text(line)}
            })

    # Close any remaining code block
    if current_code_block is not None:
        blocks.append(current_code_block)
        
    # Close any remaining quote block
    if in_quote_block:
        quote_text = "\n".join(quote_content)
        blocks.append({
            "type": "quote",
            "quote": {
                "rich_text": process_rich_text(quote_text)
            }
        })
        
    # Close any remaining table
    if in_table and len(table_rows) >= 2:
        table_block = {
            "type": "table",
            "table": {
                "table_width": len(table_rows[0]),
                "has_column_header": True,
                "has_row_header": False,
                "children": []
            }
        }
        
        for row_idx, row in enumerate(table_rows):
            table_row = {
                "type": "table_row",
                "table_row": {
                    "cells": []
                }
            }
            
            for cell in row:
                table_row["table_row"]["cells"].append(process_rich_text(cell))
            
            table_block["table"]["children"].append(table_row)
        
        blocks.append(table_block)

    return blocks

def split_content(text: str, max_length: int = 2000) -> List[str]:
    """Split content into chunks that respect Notion's token limit and preserve markdown structure"""
    if len(text) <= max_length:
        return [text]
    
    # Split by markdown headers as natural boundaries
    header_pattern = re.compile(r'^(#{1,3}\s.+)$', re.MULTILINE)
    parts = []
    
    # Find all headers as potential split points
    headers = list(header_pattern.finditer(text))
    
    if not headers:
        # No headers to split on, fall back to simpler method
        return _simple_split(text, max_length)
    
    last_pos = 0
    current_chunk = ""
    
    # Process headers as split points
    for i, match in enumerate(headers):
        # Get content from last position to current header
        if i > 0:
            header_content = text[last_pos:match.start()]
            
            # If adding this header section would exceed max length, start a new chunk
            if len(current_chunk) + len(header_content) > max_length:
                parts.append(current_chunk)
                current_chunk = header_content
            else:
                current_chunk += header_content
        
        # First header or after a split
        if not current_chunk:
            current_chunk = text[match.start():]
        
        last_pos = match.start()
    
    # Add final chunk
    if last_pos < len(text):
        final_content = text[last_pos:]
        if len(current_chunk) + len(final_content) > max_length:
            parts.append(current_chunk)
            parts.append(final_content)
        else:
            current_chunk += final_content
            parts.append(current_chunk)
    elif current_chunk:
        parts.append(current_chunk)
    
    # If any chunk is still too long, split it further
    result = []
    for chunk in parts:
        if len(chunk) > max_length:
            result.extend(_simple_split(chunk, max_length))
        else:
            result.append(chunk)
    
    return result

def _simple_split(text: str, max_length: int) -> List[str]:
    """Simple fallback splitting algorithm that preserves whole lines"""
    chunks = []
    current_chunk = ""
    in_code_block = False
    code_block_content = ""
    in_table = False
    table_content = ""
    
    for line in text.split("\n"):
        # Check for code block markers
        if re.match(r"^\s*```.*$", line.strip()):
            in_code_block = not in_code_block
            
            # If we're starting a code block
            if in_code_block:
                code_block_content = line + "\n"
                continue
            else:
                # We're ending a code block, add it as a whole
                code_block_content += line
                if len(current_chunk) + len(code_block_content) > max_length:
                    # If adding the whole code block exceeds the limit,
                    # finish the current chunk and start a new one
                    if current_chunk:
                        chunks.append(current_chunk)
                    chunks.append(code_block_content)
                    current_chunk = ""
                else:
                    current_chunk += code_block_content
                code_block_content = ""
                continue
        
        # If we're inside a code block, collect the content
        if in_code_block:
            code_block_content += line + "\n"
            continue
            
        # Check for table markers
        if line.strip().startswith("|") and line.strip().endswith("|"):
            if not in_table:
                in_table = True
                table_content = line + "\n"
            else:
                table_content += line + "\n"
            continue
        else:
            # End of table
            if in_table:
                in_table = False
                if len(current_chunk) + len(table_content) > max_length:
                    if current_chunk:
                        chunks.append(current_chunk)
                    chunks.append(table_content)
                    current_chunk = ""
                else:
                    current_chunk += table_content
                table_content = ""
        
        # For regular lines
        if len(current_chunk) + len(line) + 1 > max_length:
            if current_chunk:
                chunks.append(current_chunk)
            current_chunk = line
        else:
            current_chunk = current_chunk + "\n" + line if current_chunk else line
    
    # Add any remaining content
    if code_block_content:
        if len(current_chunk) + len(code_block_content) > max_length:
            if current_chunk:
                chunks.append(current_chunk)
            chunks.append(code_block_content)
        else:
            current_chunk += code_block_content
            
    if table_content:
        if len(current_chunk) + len(table_content) > max_length:
            if current_chunk:
                chunks.append(current_chunk)
            chunks.append(table_content)
        else:
            current_chunk += table_content
    
    if current_chunk:
        chunks.append(current_chunk)
    
    return chunks