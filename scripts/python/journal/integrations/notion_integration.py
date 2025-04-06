import re
import json
import requests
from datetime import datetime
from pathlib import Path
import logging
from typing import List, Dict, Any, Optional

from .integration_base import IntegrationBase

# Configurer le logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('journal_notion.log')
    ]
)

class NotionIntegration(IntegrationBase):
    """Intégration avec Notion."""
    
    @property
    def integration_name(self):
        return "notion"
    
    def __init__(self):
        super().__init__()
        self.api_token = self.config.get("api_token", "")
        self.database_id = self.config.get("database_id", "")
    
    def authenticate(self):
        """Authentifie l'intégration Notion."""
        if not self.api_token:
            self.logger.error("Token API Notion non configuré")
            return False
        
        try:
            response = requests.get(
                "https://api.notion.com/v1/users/me",
                headers={
                    "Authorization": f"Bearer {self.api_token}",
                    "Notion-Version": "2022-06-28"
                }
            )
            response.raise_for_status()
            self.logger.info("Authentification Notion réussie")
            return True
        except requests.RequestException as e:
            self.logger.error(f"Erreur d'authentification Notion: {e}")
            return False
    
    def get_database_pages(self, filter_params=None):
        """Récupère les pages d'une base de données Notion."""
        if not self.authenticate() or not self.database_id:
            return []
        
        try:
            url = f"https://api.notion.com/v1/databases/{self.database_id}/query"
            headers = {
                "Authorization": f"Bearer {self.api_token}",
                "Notion-Version": "2022-06-28",
                "Content-Type": "application/json"
            }
            
            data = {}
            if filter_params:
                data["filter"] = filter_params
            
            response = requests.post(url, headers=headers, json=data)
            response.raise_for_status()
            
            return response.json().get("results", [])
        except requests.RequestException as e:
            self.logger.error(f"Erreur lors de la récupération des pages Notion: {e}")
            return []
    
    def get_page(self, page_id):
        """Récupère une page Notion spécifique."""
        if not self.authenticate():
            return None
        
        try:
            response = requests.get(
                f"https://api.notion.com/v1/pages/{page_id}",
                headers={
                    "Authorization": f"Bearer {self.api_token}",
                    "Notion-Version": "2022-06-28"
                }
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            self.logger.error(f"Erreur lors de la récupération de la page Notion {page_id}: {e}")
            return None
    
    def get_page_content(self, page_id):
        """Récupère le contenu d'une page Notion."""
        if not self.authenticate():
            return None
        
        try:
            response = requests.get(
                f"https://api.notion.com/v1/blocks/{page_id}/children",
                headers={
                    "Authorization": f"Bearer {self.api_token}",
                    "Notion-Version": "2022-06-28"
                }
            )
            response.raise_for_status()
            return response.json().get("results", [])
        except requests.RequestException as e:
            self.logger.error(f"Erreur lors de la récupération du contenu de la page Notion {page_id}: {e}")
            return None
    
    def create_journal_entry_from_page(self, page_id):
        """Crée une entrée de journal à partir d'une page Notion."""
        page = self.get_page(page_id)
        if not page:
            return False
        
        content_blocks = self.get_page_content(page_id)
        if content_blocks is None:
            return False
        
        try:
            # Importer la fonction de création d'entrée
            from ..journal_entry import create_journal_entry
            
            # Extraire le titre
            title = "Page Notion"
            if "properties" in page and "title" in page["properties"]:
                title_property = page["properties"]["title"]
                if "title" in title_property and title_property["title"]:
                    title = "".join([text["plain_text"] for text in title_property["title"]])
            
            # Extraire les tags
            tags = ["notion"]
            if "properties" in page and "tags" in page["properties"]:
                tags_property = page["properties"]["tags"]
                if "multi_select" in tags_property:
                    tags.extend([tag["name"] for tag in tags_property["multi_select"]])
            
            # Créer l'entrée
            entry_path = create_journal_entry(title, tags)
            
            if entry_path:
                with open(entry_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Convertir les blocs Notion en Markdown
                markdown_content = self._blocks_to_markdown(content_blocks)
                
                # Préparer le contenu de la page
                page_content = f"""## Actions réalisées
- Création d'une entrée de journal à partir de la page Notion
- 

## Contenu de la page Notion
{markdown_content}

## Résolution des erreurs, déductions tirées
- 

## Optimisations identifiées
- Pour le système: 
- Pour le code: 
- Pour la gestion des erreurs: 
- Pour les workflows: 

## Enseignements techniques
- 

## Impact sur le projet musical
- 

## Références et ressources
- Page Notion: [{title}](https://notion.so/{page_id.replace('-', '')})
"""
                
                # Remplacer le contenu
                content = re.sub(
                    r'## Actions réalisées\n-.*?(?=\n\n## )',
                    page_content.rstrip(),
                    content,
                    flags=re.DOTALL
                )
                
                # Écrire le contenu mis à jour
                with open(entry_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                
                # Mettre à jour les associations
                associations = self.load_associations("page_entries.json")
                if page_id not in associations:
                    associations[page_id] = []
                
                associations[page_id].append({
                    "file": Path(entry_path).name,
                    "path": str(entry_path),
                    "created": datetime.now().isoformat()
                })
                
                self.save_associations(associations, "page_entries.json")
                
                self.logger.info(f"Entrée créée à partir de la page Notion {page_id}: {entry_path}")
                return True
            
            return False
        except Exception as e:
            self.logger.error(f"Erreur lors de la création de l'entrée à partir de la page Notion {page_id}: {e}")
            return False
    
    def _blocks_to_markdown(self, blocks):
        """Convertit les blocs Notion en Markdown."""
        markdown = ""
        
        for block in blocks:
            block_type = block.get("type")
            
            if block_type == "paragraph":
                text = self._get_rich_text(block.get("paragraph", {}).get("rich_text", []))
                markdown += text + "\n\n"
            
            elif block_type == "heading_1":
                text = self._get_rich_text(block.get("heading_1", {}).get("rich_text", []))
                markdown += f"# {text}\n\n"
            
            elif block_type == "heading_2":
                text = self._get_rich_text(block.get("heading_2", {}).get("rich_text", []))
                markdown += f"## {text}\n\n"
            
            elif block_type == "heading_3":
                text = self._get_rich_text(block.get("heading_3", {}).get("rich_text", []))
                markdown += f"### {text}\n\n"
            
            elif block_type == "bulleted_list_item":
                text = self._get_rich_text(block.get("bulleted_list_item", {}).get("rich_text", []))
                markdown += f"- {text}\n"
            
            elif block_type == "numbered_list_item":
                text = self._get_rich_text(block.get("numbered_list_item", {}).get("rich_text", []))
                markdown += f"1. {text}\n"
            
            elif block_type == "to_do":
                text = self._get_rich_text(block.get("to_do", {}).get("rich_text", []))
                checked = block.get("to_do", {}).get("checked", False)
                markdown += f"- {'[x]' if checked else '[ ]'} {text}\n"
            
            elif block_type == "code":
                text = self._get_rich_text(block.get("code", {}).get("rich_text", []))
                language = block.get("code", {}).get("language", "")
                markdown += f"```{language}\n{text}\n```\n\n"
            
            elif block_type == "quote":
                text = self._get_rich_text(block.get("quote", {}).get("rich_text", []))
                markdown += f"> {text}\n\n"
            
            elif block_type == "divider":
                markdown += "---\n\n"
            
            elif block_type == "callout":
                text = self._get_rich_text(block.get("callout", {}).get("rich_text", []))
                emoji = block.get("callout", {}).get("icon", {}).get("emoji", "")
                markdown += f"> {emoji} {text}\n\n"
            
            elif block_type == "image":
                image_block = block.get("image", {})
                if "external" in image_block:
                    url = image_block["external"].get("url", "")
                    markdown += f"![Image]({url})\n\n"
                elif "file" in image_block:
                    url = image_block["file"].get("url", "")
                    markdown += f"![Image]({url})\n\n"
        
        return markdown
    
    def _get_rich_text(self, rich_text):
        """Extrait le texte à partir d'un objet rich_text de Notion."""
        text = ""
        
        for text_obj in rich_text:
            content = text_obj.get("plain_text", "")
            annotations = text_obj.get("annotations", {})
            
            if annotations.get("bold"):
                content = f"**{content}**"
            if annotations.get("italic"):
                content = f"*{content}*"
            if annotations.get("strikethrough"):
                content = f"~~{content}~~"
            if annotations.get("code"):
                content = f"`{content}`"
            
            if text_obj.get("href"):
                content = f"[{content}]({text_obj.get('href')})"
            
            text += content
        
        return text
    
    def create_page_from_journal_entry(self, entry_path):
        """Crée une page Notion à partir d'une entrée de journal."""
        if not self.authenticate() or not self.database_id:
            return False
        
        try:
            with open(entry_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extraire les métadonnées YAML
            metadata = {}
            if content.startswith('---'):
                end_index = content.find('---', 3)
                if end_index != -1:
                    yaml_content = content[3:end_index].strip()
                    for line in yaml_content.split('\n'):
                        if ':' in line:
                            key, value = line.split(':', 1)
                            key = key.strip()
                            value = value.strip()
                            
                            if key == 'tags' and value.startswith('[') and value.endswith(']'):
                                value = [tag.strip() for tag in value[1:-1].split(',')]
                            elif key == 'related' and value.startswith('[') and value.endswith(']'):
                                value = [file.strip() for file in value[1:-1].split(',')]
                            
                            metadata[key] = value
            
            # Extraire le titre
            title = metadata.get('title', Path(entry_path).stem)
            
            # Extraire les tags
            tags = metadata.get('tags', [])
            
            # Créer la page
            page_data = {
                "parent": {
                    "database_id": self.database_id
                },
                "properties": {
                    "title": {
                        "title": [
                            {
                                "text": {
                                    "content": title
                                }
                            }
                        ]
                    }
                }
            }
            
            # Ajouter les tags
            if tags:
                page_data["properties"]["tags"] = {
                    "multi_select": [{"name": tag} for tag in tags]
                }
            
            # Ajouter la date
            if 'date' in metadata:
                page_data["properties"]["date"] = {
                    "date": {
                        "start": metadata['date']
                    }
                }
            
            # Créer la page
            response = requests.post(
                "https://api.notion.com/v1/pages",
                headers={
                    "Authorization": f"Bearer {self.api_token}",
                    "Notion-Version": "2022-06-28",
                    "Content-Type": "application/json"
                },
                json=page_data
            )
            response.raise_for_status()
            page_id = response.json()["id"]
            
            # Ajouter le contenu à la page
            self._add_content_to_page(page_id, content)
            
            # Mettre à jour les associations
            associations = self.load_associations("page_entries.json")
            if page_id not in associations:
                associations[page_id] = []
            
            associations[page_id].append({
                "file": Path(entry_path).name,
                "path": str(entry_path),
                "created": datetime.now().isoformat()
            })
            
            self.save_associations(associations, "page_entries.json")
            
            self.logger.info(f"Page Notion créée à partir de l'entrée {entry_path}: {page_id}")
            return page_id
        except Exception as e:
            self.logger.error(f"Erreur lors de la création de la page Notion à partir de l'entrée {entry_path}: {e}")
            return False
    
    def _add_content_to_page(self, page_id, content):
        """Ajoute du contenu à une page Notion."""
        if not self.authenticate():
            return False
        
        try:
            # Extraire le contenu sans les métadonnées YAML
            if content.startswith('---'):
                end_index = content.find('---', 3)
                if end_index != -1:
                    content = content[end_index + 3:].strip()
            
            # Convertir le contenu Markdown en blocs Notion
            blocks = self._markdown_to_blocks(content)
            
            # Ajouter les blocs à la page
            response = requests.patch(
                f"https://api.notion.com/v1/blocks/{page_id}/children",
                headers={
                    "Authorization": f"Bearer {self.api_token}",
                    "Notion-Version": "2022-06-28",
                    "Content-Type": "application/json"
                },
                json={"children": blocks}
            )
            response.raise_for_status()
            
            return True
        except Exception as e:
            self.logger.error(f"Erreur lors de l'ajout de contenu à la page Notion {page_id}: {e}")
            return False
    
    def _markdown_to_blocks(self, markdown):
        """Convertit du Markdown en blocs Notion."""
        blocks = []
        
        # Diviser le contenu en lignes
        lines = markdown.split('\n')
        i = 0
        
        while i < len(lines):
            line = lines[i].strip()
            
            # Titre de niveau 1
            if line.startswith('# '):
                blocks.append({
                    "object": "block",
                    "type": "heading_1",
                    "heading_1": {
                        "rich_text": [{"type": "text", "text": {"content": line[2:]}}]
                    }
                })
            
            # Titre de niveau 2
            elif line.startswith('## '):
                blocks.append({
                    "object": "block",
                    "type": "heading_2",
                    "heading_2": {
                        "rich_text": [{"type": "text", "text": {"content": line[3:]}}]
                    }
                })
            
            # Titre de niveau 3
            elif line.startswith('### '):
                blocks.append({
                    "object": "block",
                    "type": "heading_3",
                    "heading_3": {
                        "rich_text": [{"type": "text", "text": {"content": line[4:]}}]
                    }
                })
            
            # Liste à puces
            elif line.startswith('- '):
                blocks.append({
                    "object": "block",
                    "type": "bulleted_list_item",
                    "bulleted_list_item": {
                        "rich_text": [{"type": "text", "text": {"content": line[2:]}}]
                    }
                })
            
            # Liste numérotée
            elif re.match(r'^\d+\. ', line):
                text = re.sub(r'^\d+\. ', '', line)
                blocks.append({
                    "object": "block",
                    "type": "numbered_list_item",
                    "numbered_list_item": {
                        "rich_text": [{"type": "text", "text": {"content": text}}]
                    }
                })
            
            # Liste de tâches
            elif line.startswith('- [ ] ') or line.startswith('- [x] '):
                checked = line.startswith('- [x] ')
                text = line[6:] if checked else line[6:]
                blocks.append({
                    "object": "block",
                    "type": "to_do",
                    "to_do": {
                        "rich_text": [{"type": "text", "text": {"content": text}}],
                        "checked": checked
                    }
                })
            
            # Bloc de code
            elif line.startswith('```'):
                # Extraire le langage
                language = line[3:].strip()
                
                # Collecter les lignes du bloc de code
                code_lines = []
                i += 1
                while i < len(lines) and not lines[i].strip().startswith('```'):
                    code_lines.append(lines[i])
                    i += 1
                
                blocks.append({
                    "object": "block",
                    "type": "code",
                    "code": {
                        "rich_text": [{"type": "text", "text": {"content": '\n'.join(code_lines)}}],
                        "language": language if language else "plain text"
                    }
                })
            
            # Citation
            elif line.startswith('> '):
                blocks.append({
                    "object": "block",
                    "type": "quote",
                    "quote": {
                        "rich_text": [{"type": "text", "text": {"content": line[2:]}}]
                    }
                })
            
            # Séparateur
            elif line == '---':
                blocks.append({
                    "object": "block",
                    "type": "divider",
                    "divider": {}
                })
            
            # Paragraphe (par défaut)
            elif line:
                blocks.append({
                    "object": "block",
                    "type": "paragraph",
                    "paragraph": {
                        "rich_text": [{"type": "text", "text": {"content": line}}]
                    }
                })
            
            i += 1
        
        return blocks
    
    def sync_to_journal(self):
        """Synchronise les pages Notion vers le journal."""
        if not self.authenticate() or not self.database_id:
            return False
        
        try:
            # Récupérer les pages récentes
            # Filtrer pour les pages mises à jour au cours des 7 derniers jours
            one_week_ago = (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d")
            filter_params = {
                "property": "last_edited_time",
                "date": {
                    "on_or_after": one_week_ago
                }
            }
            
            pages = self.get_database_pages(filter_params)
            
            # Charger les associations existantes
            associations = self.load_associations("page_entries.json")
            
            # Synchroniser chaque page
            for page in pages:
                page_id = page["id"]
                
                # Vérifier si la page est déjà associée à une entrée
                if page_id in associations:
                    # Mettre à jour l'entrée existante (non implémenté pour l'instant)
                    pass
                else:
                    # Créer une nouvelle entrée
                    self.create_journal_entry_from_page(page_id)
            
            self.logger.info(f"Synchronisation des pages Notion vers le journal terminée ({len(pages)} pages)")
            return True
        except Exception as e:
            self.logger.error(f"Erreur lors de la synchronisation des pages Notion vers le journal: {e}")
            return False
    
    def sync_from_journal(self):
        """Synchronise les entrées du journal vers Notion."""
        if not self.authenticate() or not self.database_id:
            return False
        
        try:
            # Charger les associations existantes
            associations = self.load_associations("page_entries.json")
            
            # Inverser les associations pour obtenir les entrées par fichier
            entry_pages = {}
            for page_id, entries in associations.items():
                for entry in entries:
                    entry_pages[entry["file"]] = page_id
            
            # Parcourir les entrées récentes
            recent_entries = []
            for entry_file in self.entries_dir.glob("*.md"):
                # Vérifier si l'entrée est récente (moins de 7 jours)
                if (datetime.now() - datetime.fromtimestamp(entry_file.stat().st_mtime)).days <= 7:
                    recent_entries.append(entry_file)
            
            # Synchroniser chaque entrée récente
            for entry_file in recent_entries:
                # Vérifier si l'entrée est déjà associée à une page
                if entry_file.name in entry_pages:
                    # Mettre à jour la page existante (non implémenté pour l'instant)
                    pass
                else:
                    # Vérifier si l'entrée contient le tag "notion"
                    with open(entry_file, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Extraire les métadonnées YAML
                    tags = []
                    if content.startswith('---'):
                        end_index = content.find('---', 3)
                        if end_index != -1:
                            yaml_content = content[3:end_index].strip()
                            for line in yaml_content.split('\n'):
                                if line.strip().startswith('tags:'):
                                    tags_str = line.split(':', 1)[1].strip()
                                    if tags_str.startswith('[') and tags_str.endswith(']'):
                                        tags = [tag.strip() for tag in tags_str[1:-1].split(',')]
                    
                    # Créer une page si le tag "notion" est présent
                    if "notion" in tags:
                        self.create_page_from_journal_entry(entry_file)
            
            self.logger.info(f"Synchronisation des entrées du journal vers Notion terminée ({len(recent_entries)} entrées récentes)")
            return True
        except Exception as e:
            self.logger.error(f"Erreur lors de la synchronisation des entrées du journal vers Notion: {e}")
            return False

# Point d'entrée
if __name__ == "__main__":
    import argparse
    from datetime import timedelta
    
    parser = argparse.ArgumentParser(description="Intégration Notion pour le journal de bord")
    parser.add_argument("--configure", action="store_true", help="Configurer l'intégration Notion")
    parser.add_argument("--api-token", type=str, help="Token API Notion")
    parser.add_argument("--database-id", type=str, help="ID de la base de données Notion")
    parser.add_argument("--sync-to-journal", action="store_true", help="Synchroniser les pages Notion vers le journal")
    parser.add_argument("--sync-from-journal", action="store_true", help="Synchroniser les entrées du journal vers Notion")
    parser.add_argument("--create-entry", type=str, help="Créer une entrée à partir d'une page Notion")
    parser.add_argument("--create-page", type=str, help="Créer une page Notion à partir d'une entrée de journal")
    
    args = parser.parse_args()
    
    notion = NotionIntegration()
    
    if args.configure:
        if args.api_token:
            notion.config["api_token"] = args.api_token
        if args.database_id:
            notion.config["database_id"] = args.database_id
        
        notion.save_config()
        print("Configuration Notion sauvegardée")
    
    if args.sync_to_journal:
        if notion.sync_to_journal():
            print("Synchronisation des pages Notion vers le journal terminée")
        else:
            print("Erreur lors de la synchronisation des pages Notion vers le journal")
    
    if args.sync_from_journal:
        if notion.sync_from_journal():
            print("Synchronisation des entrées du journal vers Notion terminée")
        else:
            print("Erreur lors de la synchronisation des entrées du journal vers Notion")
    
    if args.create_entry:
        if notion.create_journal_entry_from_page(args.create_entry):
            print(f"Entrée créée à partir de la page Notion {args.create_entry}")
        else:
            print(f"Erreur lors de la création de l'entrée à partir de la page Notion {args.create_entry}")
    
    if args.create_page:
        page_id = notion.create_page_from_journal_entry(args.create_page)
        if page_id:
            print(f"Page Notion créée à partir de l'entrée {args.create_page}: {page_id}")
        else:
            print(f"Erreur lors de la création de la page Notion à partir de l'entrée {args.create_page}")
