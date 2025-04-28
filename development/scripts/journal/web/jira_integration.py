import re
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
        logging.FileHandler('journal_jira.log')
    ]
)

class JiraIntegration(IntegrationBase):
    """Intégration avec Jira."""
    
    @property
    def integration_name(self):
        return "jira"
    
    def __init__(self):
        super().__init__()
        self.api_url = self.config.get("api_url", "")
        self.username = self.config.get("username", "")
        self.api_token = self.config.get("api_token", "")
        self.project_key = self.config.get("project_key", "")
    
    def authenticate(self):
        """Authentifie l'intégration Jira."""
        if not self.api_url or not self.username or not self.api_token:
            self.logger.error("Configuration Jira incomplète")
            return False
        
        try:
            response = requests.get(
                f"{self.api_url}/rest/api/2/myself",
                auth=(self.username, self.api_token)
            )
            response.raise_for_status()
            self.logger.info("Authentification Jira réussie")
            return True
        except requests.RequestException as e:
            self.logger.error(f"Erreur d'authentification Jira: {e}")
            return False
    
    def get_issues(self, jql="", max_results=50):
        """Récupère les issues Jira."""
        if not self.authenticate():
            return []
        
        if not jql and self.project_key:
            jql = f"project = {self.project_key} ORDER BY updated DESC"
        
        try:
            response = requests.get(
                f"{self.api_url}/rest/api/2/search",
                params={"jql": jql, "maxResults": max_results},
                auth=(self.username, self.api_token)
            )
            response.raise_for_status()
            return response.json().get("issues", [])
        except requests.RequestException as e:
            self.logger.error(f"Erreur lors de la récupération des issues Jira: {e}")
            return []
    
    def get_issue(self, issue_key):
        """Récupère une issue Jira spécifique."""
        if not self.authenticate():
            return None
        
        try:
            response = requests.get(
                f"{self.api_url}/rest/api/2/issue/{issue_key}",
                auth=(self.username, self.api_token)
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            self.logger.error(f"Erreur lors de la récupération de l'issue Jira {issue_key}: {e}")
            return None
    
    def create_journal_entry_from_issue(self, issue_key):
        """Crée une entrée de journal à partir d'une issue Jira."""
        issue = self.get_issue(issue_key)
        if not issue:
            return False
        
        try:
            # Importer la fonction de création d'entrée
            from ..journal_entry import create_journal_entry
            
            # Créer le titre
            title = f"Jira {issue_key}: {issue['fields']['summary']}"
            
            # Créer les tags
            tags = ["jira", "issue"]
            if "labels" in issue["fields"] and issue["fields"]["labels"]:
                tags.extend(issue["fields"]["labels"])
            
            # Créer l'entrée
            entry_path = create_journal_entry(title, tags)
            
            if entry_path:
                with open(entry_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Préparer le contenu de l'issue
                issue_content = f"""## Actions réalisées
- Création d'une entrée de journal à partir de l'issue Jira {issue_key}
- 

## Détails de l'issue Jira
- **Clé**: {issue_key}
- **Titre**: {issue['fields']['summary']}
- **État**: {issue['fields']['status']['name']}
- **Priorité**: {issue['fields']['priority']['name']}
- **Assigné à**: {issue['fields']['assignee']['displayName'] if issue['fields']['assignee'] else "Non assigné"}
- **URL**: {self.api_url}/browse/{issue_key}

## Description de l'issue
{issue['fields']['description'] or "Aucune description fournie."}

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
- Issue Jira: [{issue_key}]({self.api_url}/browse/{issue_key}) {issue['fields']['summary']}
"""
                
                # Remplacer le contenu
                content = re.sub(
                    r'## Actions réalisées\n-.*?(?=\n\n## )',
                    issue_content.rstrip(),
                    content,
                    flags=re.DOTALL
                )
                
                # Écrire le contenu mis à jour
                with open(entry_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                
                # Mettre à jour les associations
                associations = self.load_associations("issue_entries.json")
                if issue_key not in associations:
                    associations[issue_key] = []
                
                associations[issue_key].append({
                    "file": Path(entry_path).name,
                    "path": str(entry_path),
                    "created": datetime.now().isoformat()
                })
                
                self.save_associations(associations, "issue_entries.json")
                
                self.logger.info(f"Entrée créée à partir de l'issue Jira {issue_key}: {entry_path}")
                return True
            
            return False
        except Exception as e:
            self.logger.error(f"Erreur lors de la création de l'entrée à partir de l'issue Jira {issue_key}: {e}")
            return False
    
    def update_entry_from_issue(self, entry_path, issue_key):
        """Met à jour une entrée existante à partir d'une issue Jira."""
        issue = self.get_issue(issue_key)
        if not issue:
            return False
        
        try:
            with open(entry_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Mettre à jour les détails de l'issue
            issue_details = f"""## Détails de l'issue Jira
- **Clé**: {issue_key}
- **Titre**: {issue['fields']['summary']}
- **État**: {issue['fields']['status']['name']}
- **Priorité**: {issue['fields']['priority']['name']}
- **Assigné à**: {issue['fields']['assignee']['displayName'] if issue['fields']['assignee'] else "Non assigné"}
- **URL**: {self.api_url}/browse/{issue_key}

## Description de l'issue
{issue['fields']['description'] or "Aucune description fournie."}"""
            
            # Remplacer les détails de l'issue
            content = re.sub(
                r'## Détails de l\'issue Jira.*?(?=\n\n## )',
                issue_details,
                content,
                flags=re.DOTALL
            )
            
            # Écrire le contenu mis à jour
            with open(entry_path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            self.logger.info(f"Entrée mise à jour à partir de l'issue Jira {issue_key}: {entry_path}")
            return True
        except Exception as e:
            self.logger.error(f"Erreur lors de la mise à jour de l'entrée à partir de l'issue Jira {issue_key}: {e}")
            return False
    
    def create_issue_from_journal_entry(self, entry_path):
        """Crée une issue Jira à partir d'une entrée de journal."""
        if not self.authenticate() or not self.project_key:
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
            
            # Extraire le titre et la description
            title = metadata.get('title', Path(entry_path).stem)
            
            # Extraire la description à partir du contenu
            description = ""
            actions_match = re.search(r'## Actions réalisées\n(.*?)(?=\n\n## )', content, re.DOTALL)
            if actions_match:
                description += "Actions réalisées:\n" + actions_match.group(1) + "\n\n"
            
            errors_match = re.search(r'## Résolution des erreurs, déductions tirées\n(.*?)(?=\n\n## )', content, re.DOTALL)
            if errors_match:
                description += "Résolution des erreurs, déductions tirées:\n" + errors_match.group(1) + "\n\n"
            
            optimizations_match = re.search(r'## Optimisations identifiées\n(.*?)(?=\n\n## )', content, re.DOTALL)
            if optimizations_match:
                description += "Optimisations identifiées:\n" + optimizations_match.group(1) + "\n\n"
            
            lessons_match = re.search(r'## Enseignements techniques\n(.*?)(?=\n\n## )', content, re.DOTALL)
            if lessons_match:
                description += "Enseignements techniques:\n" + lessons_match.group(1) + "\n\n"
            
            # Créer l'issue
            issue_data = {
                "fields": {
                    "project": {
                        "key": self.project_key
                    },
                    "summary": title,
                    "description": description,
                    "issuetype": {
                        "name": "Task"
                    }
                }
            }
            
            # Ajouter les labels (tags)
            if 'tags' in metadata and metadata['tags']:
                issue_data["fields"]["labels"] = metadata['tags']
            
            # Créer l'issue
            response = requests.post(
                f"{self.api_url}/rest/api/2/issue",
                json=issue_data,
                auth=(self.username, self.api_token)
            )
            response.raise_for_status()
            issue_key = response.json()["key"]
            
            # Mettre à jour les associations
            associations = self.load_associations("issue_entries.json")
            if issue_key not in associations:
                associations[issue_key] = []
            
            associations[issue_key].append({
                "file": Path(entry_path).name,
                "path": str(entry_path),
                "created": datetime.now().isoformat()
            })
            
            self.save_associations(associations, "issue_entries.json")
            
            self.logger.info(f"Issue Jira créée à partir de l'entrée {entry_path}: {issue_key}")
            return issue_key
        except Exception as e:
            self.logger.error(f"Erreur lors de la création de l'issue Jira à partir de l'entrée {entry_path}: {e}")
            return False
    
    def sync_to_journal(self):
        """Synchronise les issues Jira vers le journal."""
        if not self.authenticate():
            return False
        
        try:
            # Récupérer les issues récentes
            issues = self.get_issues(jql=f"project = {self.project_key} AND updated >= -7d")
            
            # Charger les associations existantes
            associations = self.load_associations("issue_entries.json")
            
            # Synchroniser chaque issue
            for issue in issues:
                issue_key = issue["key"]
                
                # Vérifier si l'issue est déjà associée à une entrée
                if issue_key in associations:
                    # Mettre à jour l'entrée existante
                    for entry in associations[issue_key]:
                        entry_path = entry["path"]
                        if Path(entry_path).exists():
                            self.update_entry_from_issue(entry_path, issue_key)
                else:
                    # Créer une nouvelle entrée
                    self.create_journal_entry_from_issue(issue_key)
            
            self.logger.info(f"Synchronisation des issues Jira vers le journal terminée ({len(issues)} issues)")
            return True
        except Exception as e:
            self.logger.error(f"Erreur lors de la synchronisation des issues Jira vers le journal: {e}")
            return False
    
    def sync_from_journal(self):
        """Synchronise les entrées du journal vers Jira."""
        if not self.authenticate():
            return False
        
        try:
            # Charger les associations existantes
            associations = self.load_associations("issue_entries.json")
            
            # Inverser les associations pour obtenir les entrées par fichier
            entry_issues = {}
            for issue_key, entries in associations.items():
                for entry in entries:
                    entry_issues[entry["file"]] = issue_key
            
            # Parcourir les entrées récentes
            recent_entries = []
            for entry_file in self.entries_dir.glob("*.md"):
                # Vérifier si l'entrée est récente (moins de 7 jours)
                if (datetime.now() - datetime.fromtimestamp(entry_file.stat().st_mtime)).days <= 7:
                    recent_entries.append(entry_file)
            
            # Synchroniser chaque entrée récente
            for entry_file in recent_entries:
                # Vérifier si l'entrée est déjà associée à une issue
                if entry_file.name in entry_issues:
                    # Mettre à jour l'issue existante
                    # (non implémenté pour l'instant)
                    pass
                else:
                    # Vérifier si l'entrée contient le tag "jira"
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
                    
                    # Créer une issue si le tag "jira" est présent
                    if "jira" in tags:
                        self.create_issue_from_journal_entry(entry_file)
            
            self.logger.info(f"Synchronisation des entrées du journal vers Jira terminée ({len(recent_entries)} entrées récentes)")
            return True
        except Exception as e:
            self.logger.error(f"Erreur lors de la synchronisation des entrées du journal vers Jira: {e}")
            return False

# Point d'entrée
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Intégration Jira pour le journal de bord")
    parser.add_argument("--configure", action="store_true", help="Configurer l'intégration Jira")
    parser.add_argument("--api-url", type=str, help="URL de l'API Jira")
    parser.add_argument("--username", type=str, help="Nom d'utilisateur Jira")
    parser.add_argument("--api-token", type=str, help="Token API Jira")
    parser.add_argument("--project-key", type=str, help="Clé du projet Jira")
    parser.add_argument("--sync-to-journal", action="store_true", help="Synchroniser les issues Jira vers le journal")
    parser.add_argument("--sync-from-journal", action="store_true", help="Synchroniser les entrées du journal vers Jira")
    parser.add_argument("--create-entry", type=str, help="Créer une entrée à partir d'une issue Jira")
    parser.add_argument("--create-issue", type=str, help="Créer une issue Jira à partir d'une entrée de journal")
    
    args = parser.parse_args()
    
    jira = JiraIntegration()
    
    if args.configure:
        if args.api_url:
            jira.config["api_url"] = args.api_url
        if args.username:
            jira.config["username"] = args.username
        if args.api_token:
            jira.config["api_token"] = args.api_token
        if args.project_key:
            jira.config["project_key"] = args.project_key
        
        jira.save_config()
        print("Configuration Jira sauvegardée")
    
    if args.sync_to_journal:
        if jira.sync_to_journal():
            print("Synchronisation des issues Jira vers le journal terminée")
        else:
            print("Erreur lors de la synchronisation des issues Jira vers le journal")
    
    if args.sync_from_journal:
        if jira.sync_from_journal():
            print("Synchronisation des entrées du journal vers Jira terminée")
        else:
            print("Erreur lors de la synchronisation des entrées du journal vers Jira")
    
    if args.create_entry:
        if jira.create_journal_entry_from_issue(args.create_entry):
            print(f"Entrée créée à partir de l'issue Jira {args.create_entry}")
        else:
            print(f"Erreur lors de la création de l'entrée à partir de l'issue Jira {args.create_entry}")
    
    if args.create_issue:
        issue_key = jira.create_issue_from_journal_entry(args.create_issue)
        if issue_key:
            print(f"Issue Jira créée à partir de l'entrée {args.create_issue}: {issue_key}")
        else:
            print(f"Erreur lors de la création de l'issue Jira à partir de l'entrée {args.create_issue}")
