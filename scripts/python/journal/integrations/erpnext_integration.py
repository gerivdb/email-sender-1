import os
import json
import logging
import requests
from pathlib import Path
from typing import List, Dict, Any, Optional, Union
from datetime import datetime

# Configurer le logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("erpnext_integration")

class ERPNextIntegration:
    """Classe pour l'intégration avec ERPNext."""
    
    def __init__(self, config_path: str = "config.json"):
        """Initialise la classe ERPNextIntegration.
        
        Args:
            config_path: Chemin vers le fichier de configuration
        """
        self.config = self._load_config(config_path)
        
        # Répertoires
        journal_dir = self.config["journal"]["directory"]
        self.journal_dir = Path(journal_dir)
        self.entries_dir = self.journal_dir / self.config["journal"]["entries_dir"]
        
        # Configuration ERPNext
        self.erpnext_config = self.config["integrations"].get("erpnext", {})
        self.api_url = self.erpnext_config.get("api_url", "")
        self.api_key = self.erpnext_config.get("api_key", "")
        self.api_secret = self.erpnext_config.get("api_secret", "")
        
        # État de l'authentification
        self.authenticated = False
    
    def _load_config(self, config_path: str) -> Dict[str, Any]:
        """Charge la configuration depuis un fichier JSON.
        
        Args:
            config_path: Chemin vers le fichier de configuration
            
        Returns:
            Dict: Configuration chargée
        """
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Erreur lors du chargement de la configuration: {e}")
            # Configuration par défaut
            return {
                "journal": {
                    "directory": "docs/journal_de_bord",
                    "entries_dir": "entries"
                },
                "integrations": {
                    "erpnext": {
                        "enabled": False,
                        "api_url": "",
                        "api_key": "",
                        "api_secret": ""
                    }
                }
            }
    
    def save_config(self) -> bool:
        """Sauvegarde la configuration.
        
        Returns:
            bool: True si la sauvegarde a réussi, False sinon
        """
        try:
            # Mettre à jour la configuration ERPNext
            if "erpnext" not in self.config["integrations"]:
                self.config["integrations"]["erpnext"] = {}
                
            self.config["integrations"]["erpnext"] = {
                "enabled": self.erpnext_config.get("enabled", False),
                "api_url": self.api_url,
                "api_key": self.api_key,
                "api_secret": self.api_secret
            }
            
            # Sauvegarder la configuration
            with open("config.json", 'w', encoding='utf-8') as f:
                json.dump(self.config, f, ensure_ascii=False, indent=2)
            
            logger.info("Configuration ERPNext sauvegardée")
            return True
        except Exception as e:
            logger.error(f"Erreur lors de la sauvegarde de la configuration ERPNext: {e}")
            return False
    def _get_headers(self) -> Dict[str, str]:
        """Récupère les en-têtes pour les requêtes API.
        
        Returns:
            Dict[str, str]: En-têtes pour les requêtes API
        """
        return {
            "Authorization": f"token {self.api_key}:{self.api_secret}",
            "Content-Type": "application/json"
        }
    
    def get_projects(self) -> List[Dict[str, Any]]:
        """Récupère les projets ERPNext.
        
        Returns:
            List[Dict]: Liste des projets
        """
        if not self.authenticate():
            return []
        
        try:
            # Préparer les en-têtes
            headers = self._get_headers()
            
            # Récupérer les projets
            response = requests.get(f"{self.api_url}/api/resource/Project", headers=headers)
            
            if response.status_code == 200:
                data = response.json()
                projects = data.get("data", [])
                
                logger.info(f"Récupération de {len(projects)} projets ERPNext")
                return projects
            else:
                logger.error(f"Erreur lors de la récupération des projets ERPNext: {response.status_code} {response.text}")
                return []
        except Exception as e:
            logger.error(f"Erreur lors de la récupération des projets ERPNext: {e}")
            return []
    
    def get_project(self, project_name: str) -> Optional[Dict[str, Any]]:
        """Récupère un projet ERPNext.
        
        Args:
            project_name: Nom du projet
            
        Returns:
            Dict: Projet récupéré
        """
        if not self.authenticate():
            return None
        
        try:
            # Préparer les en-têtes
            headers = self._get_headers()
            
            # Récupérer le projet
            response = requests.get(f"{self.api_url}/api/resource/Project/{project_name}", headers=headers)
            
            if response.status_code == 200:
                data = response.json()
                project = data.get("data", {})
                
                logger.info(f"Récupération du projet ERPNext {project_name}")
                return project
            else:
                logger.error(f"Erreur lors de la récupération du projet ERPNext {project_name}: {response.status_code} {response.text}")
                return None
        except Exception as e:
            logger.error(f"Erreur lors de la récupération du projet ERPNext {project_name}: {e}")
            return None
    
    def get_tasks(self, project_name: str = None) -> List[Dict[str, Any]]:
        """Récupère les tâches ERPNext.
        
        Args:
            project_name: Nom du projet (None pour toutes les tâches)
            
        Returns:
            List[Dict]: Liste des tâches
        """
        if not self.authenticate():
            return []
        
        try:
            # Préparer les en-têtes
            headers = self._get_headers()
            
            # Préparer les filtres
            filters = []
            if project_name:
                filters.append(["project", "=", project_name])
            
            # Récupérer les tâches
            url = f"{self.api_url}/api/resource/Task"
            if filters:
                filters_json = json.dumps(filters)
                url += f"?filters={filters_json}"
            
            response = requests.get(url, headers=headers)
            
            if response.status_code == 200:
                data = response.json()
                tasks = data.get("data", [])
                
                logger.info(f"Récupération de {len(tasks)} tâches ERPNext")
                return tasks
            else:
                logger.error(f"Erreur lors de la récupération des tâches ERPNext: {response.status_code} {response.text}")
                return []
        except Exception as e:
            logger.error(f"Erreur lors de la récupération des tâches ERPNext: {e}")
            return []
    
    def get_task(self, task_name: str) -> Optional[Dict[str, Any]]:
        """Récupère une tâche ERPNext.
        
        Args:
            task_name: Nom de la tâche
            
        Returns:
            Dict: Tâche récupérée
        """
        if not self.authenticate():
            return None
        
        try:
            # Préparer les en-têtes
            headers = self._get_headers()
            
            # Récupérer la tâche
            response = requests.get(f"{self.api_url}/api/resource/Task/{task_name}", headers=headers)
            
            if response.status_code == 200:
                data = response.json()
                task = data.get("data", {})
                
                logger.info(f"Récupération de la tâche ERPNext {task_name}")
                return task
            else:
                logger.error(f"Erreur lors de la récupération de la tâche ERPNext {task_name}: {response.status_code} {response.text}")
                return None
        except Exception as e:
            logger.error(f"Erreur lors de la récupération de la tâche ERPNext {task_name}: {e}")
            return None
    
    def create_task(self, subject: str, description: str, project: str = None, status: str = "Open", priority: str = "Medium") -> Optional[str]:
        """Crée une tâche ERPNext.
        
        Args:
            subject: Sujet de la tâche
            description: Description de la tâche
            project: Nom du projet
            status: Statut de la tâche
            priority: Priorité de la tâche
            
        Returns:
            str: Nom de la tâche créée
        """
        if not self.authenticate():
            return None
        
        try:
            # Préparer les en-têtes
            headers = self._get_headers()
            
            # Préparer les données
            data = {
                "doctype": "Task",
                "subject": subject,
                "description": description,
                "status": status,
                "priority": priority
            }
            
            if project:
                data["project"] = project
            
            # Créer la tâche
            response = requests.post(
                f"{self.api_url}/api/resource/Task",
                headers=headers,
                json=data
            )
            
            if response.status_code == 200:
                result = response.json()
                task_name = result.get("data", {}).get("name")
                
                logger.info(f"Tâche ERPNext créée: {task_name}")
                return task_name
            else:
                logger.error(f"Erreur lors de la création de la tâche ERPNext: {response.status_code} {response.text}")
                return None
        except Exception as e:
            logger.error(f"Erreur lors de la création de la tâche ERPNext: {e}")
            return None

    def update_task(self, task_name: str, data: Dict[str, Any]) -> bool:
        """Met à jour une tâche ERPNext.
        
        Args:
            task_name: Nom de la tâche
            data: Données à mettre à jour
            
        Returns:
            bool: True si la mise à jour a réussi, False sinon
        """
        if not self.authenticate():
            return False
        
        try:
            # Préparer les en-têtes
            headers = self._get_headers()
            
            # Mettre à jour la tâche
            response = requests.put(
                f"{self.api_url}/api/resource/Task/{task_name}",
                headers=headers,
                json=data
            )
            
            if response.status_code == 200:
                logger.info(f"Tâche ERPNext mise à jour: {task_name}")
                return True
            else:
                logger.error(f"Erreur lors de la mise à jour de la tâche ERPNext {task_name}: {response.status_code} {response.text}")
                return False
        except Exception as e:
            logger.error(f"Erreur lors de la mise à jour de la tâche ERPNext {task_name}: {e}")
            return False
    
    def create_note_from_journal_entry(self, entry_path: str) -> Optional[str]:
        """Crée une note ERPNext à partir d'une entrée de journal.
        
        Args:
            entry_path: Chemin vers l'entrée de journal
            
        Returns:
            str: Nom de la note créée
        """
        if not self.authenticate():
            return None
        
        try:
            # Lire l'entrée de journal
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
                    
                    # Extraire le contenu sans les métadonnées
                    content = content[end_index + 3:].strip()
            
            # Préparer les en-têtes
            headers = self._get_headers()
            
            # Préparer les données
            title = metadata.get('title', Path(entry_path).stem)
            
            data = {
                "doctype": "Note",
                "title": title,
                "content": content
            }
            
            # Créer la note
            response = requests.post(
                f"{self.api_url}/api/resource/Note",
                headers=headers,
                json=data
            )
            
            if response.status_code == 200:
                result = response.json()
                note_name = result.get("data", {}).get("name")
                
                logger.info(f"Note ERPNext créée: {note_name}")
                return note_name
            else:
                logger.error(f"Erreur lors de la création de la note ERPNext: {response.status_code} {response.text}")
                return None
        except Exception as e:
            logger.error(f"Erreur lors de la création de la note ERPNext: {e}")
            return None
    
    def sync_to_journal(self) -> bool:
        """Synchronise les tâches ERPNext vers le journal.
        
        Returns:
            bool: True si la synchronisation a réussi, False sinon
        """
        if not self.authenticate():
            return False
        
        try:
            # Récupérer les tâches
            tasks = self.get_tasks()
            
            if not tasks:
                logger.warning("Aucune tâche ERPNext à synchroniser")
                return False
            
            # Créer une entrée de journal pour chaque tâche
            from journal_entry import create_journal_entry, update_journal_entry
            
            success_count = 0
            
            for task in tasks:
                task_name = task.get("name")
                task_details = self.get_task(task_name)
                
                if not task_details:
                    continue
                
                # Préparer les métadonnées
                title = f"Tâche ERPNext: {task_details.get('subject', task_name)}"
                tags = ["erpnext", "task"]
                
                if task_details.get("project"):
                    tags.append(f"project:{task_details.get('project')}")
                
                if task_details.get("status"):
                    tags.append(f"status:{task_details.get('status')}")
                
                if task_details.get("priority"):
                    tags.append(f"priority:{task_details.get('priority')}")
                
                # Créer l'entrée
                entry_path = create_journal_entry(
                    title=title,
                    tags=tags
                )
                
                if not entry_path:
                    logger.error(f"Erreur lors de la création de l'entrée pour la tâche {task_name}")
                    continue
                
                # Préparer le contenu
                content = f"""# {title}

## Détails de la tâche
- **ID**: {task_name}
- **Sujet**: {task_details.get('subject', '')}
- **Projet**: {task_details.get('project', 'Non assigné')}
- **Statut**: {task_details.get('status', 'Non défini')}
- **Priorité**: {task_details.get('priority', 'Non définie')}
- **Date de début**: {task_details.get('exp_start_date', 'Non définie')}
- **Date de fin**: {task_details.get('exp_end_date', 'Non définie')}

## Description
{task_details.get('description', 'Aucune description')}

## Actions réalisées
- Synchronisation depuis ERPNext le {datetime.now().strftime('%Y-%m-%d %H:%M')}

## Notes
- Cette entrée a été générée automatiquement à partir d'une tâche ERPNext.
- Pour mettre à jour la tâche dans ERPNext, modifiez cette entrée et exécutez la synchronisation vers ERPNext.
"""
                
                # Mettre à jour l'entrée
                success = update_journal_entry(
                    file_path=entry_path,
                    content=content
                )
                
                if success:
                    success_count += 1
                    logger.info(f"Entrée créée pour la tâche {task_name}: {entry_path}")
                else:
                    logger.error(f"Erreur lors de la mise à jour de l'entrée pour la tâche {task_name}")
            
            logger.info(f"Synchronisation ERPNext vers journal terminée: {success_count}/{len(tasks)} tâches synchronisées")
            return success_count > 0
        except Exception as e:
            logger.error(f"Erreur lors de la synchronisation ERPNext vers journal: {e}")
            return False
    
    def sync_from_journal(self) -> bool:
        """Synchronise les entrées du journal vers ERPNext.
        
        Returns:
            bool: True si la synchronisation a réussi, False sinon
        """
        if not self.authenticate():
            return False
        
        try:
            # Parcourir les entrées du journal
            success_count = 0
            
            for entry_file in self.entries_dir.glob("*.md"):
                # Vérifier si l'entrée contient le tag "erpnext"
                with open(entry_file, 'r', encoding='utf-8') as f:
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
                
                # Vérifier si l'entrée contient le tag "erpnext"
                tags = metadata.get('tags', [])
                if not isinstance(tags, list):
                    tags = [tags]
                
                if "erpnext" not in tags:
                    continue
                
                # Créer une note ERPNext
                note_name = self.create_note_from_journal_entry(str(entry_file))
                
                if note_name:
                    success_count += 1
                    logger.info(f"Note créée pour l'entrée {entry_file.name}: {note_name}")
                
                # Vérifier si l'entrée contient le tag "task"
                if "task" in tags:
                    # Extraire l'ID de la tâche
                    task_id = None
                    task_id_match = re.search(r'ID\s*:\s*([A-Za-z0-9-]+)', content)
                    if task_id_match:
                        task_id = task_id_match.group(1)
                    
                    if task_id:
                        # Extraire les informations de la tâche
                        subject_match = re.search(r'Sujet\s*:\s*(.+)$', content, re.MULTILINE)
                        subject = subject_match.group(1) if subject_match else metadata.get('title', '')
                        
                        description_match = re.search(r'Description\s*\n(.*?)(?=\n##|\Z)', content, re.DOTALL)
                        description = description_match.group(1).strip() if description_match else ''
                        
                        status_match = re.search(r'Statut\s*:\s*(.+)$', content, re.MULTILINE)
                        status = status_match.group(1) if status_match else 'Open'
                        
                        priority_match = re.search(r'Priorité\s*:\s*(.+)$', content, re.MULTILINE)
                        priority = priority_match.group(1) if priority_match else 'Medium'
                        
                        # Mettre à jour la tâche
                        data = {
                            "subject": subject,
                            "description": description,
                            "status": status,
                            "priority": priority
                        }
                        
                        success = self.update_task(task_id, data)
                        
                        if success:
                            logger.info(f"Tâche {task_id} mise à jour depuis l'entrée {entry_file.name}")
                        else:
                            logger.error(f"Erreur lors de la mise à jour de la tâche {task_id} depuis l'entrée {entry_file.name}")
            
            logger.info(f"Synchronisation journal vers ERPNext terminée: {success_count} entrées synchronisées")
            return success_count > 0
        except Exception as e:
            logger.error(f"Erreur lors de la synchronisation journal vers ERPNext: {e}")
            return False

# Point d'entrée
if __name__ == "__main__":
    import argparse
    import re
    
    parser = argparse.ArgumentParser(description="Intégration ERPNext pour le journal de bord")
    parser.add_argument("--url", type=str, help="URL de l'API ERPNext")
    parser.add_argument("--key", type=str, help="Clé API ERPNext")
    parser.add_argument("--secret", type=str, help="Secret API ERPNext")
    parser.add_argument("--test", action="store_true", help="Tester l'authentification")
    parser.add_argument("--projects", action="store_true", help="Récupérer les projets")
    parser.add_argument("--tasks", action="store_true", help="Récupérer les tâches")
    parser.add_argument("--project", type=str, help="Nom du projet pour les tâches")
    parser.add_argument("--create-task", action="store_true", help="Créer une tâche")
    parser.add_argument("--subject", type=str, help="Sujet de la tâche")
    parser.add_argument("--description", type=str, help="Description de la tâche")
    parser.add_argument("--sync-to-journal", action="store_true", help="Synchroniser ERPNext vers le journal")
    parser.add_argument("--sync-from-journal", action="store_true", help="Synchroniser le journal vers ERPNext")
    
    args = parser.parse_args()
    
    erpnext = ERPNextIntegration()
    
    # Mettre à jour la configuration
    if args.url:
        erpnext.api_url = args.url
    
    if args.key:
        erpnext.api_key = args.key
    
    if args.secret:
        erpnext.api_secret = args.secret
    
    # Activer l'intégration
    erpnext.erpnext_config["enabled"] = True
    
    # Sauvegarder la configuration
    erpnext.save_config()
    
    # Tester l'authentification
    if args.test:
        if erpnext.authenticate():
            print("Authentification ERPNext réussie")
        else:
            print("Erreur d'authentification ERPNext")
    
    # Récupérer les projets
    if args.projects:
        projects = erpnext.get_projects()
        print(f"Projets ERPNext ({len(projects)}):")
        for project in projects:
            print(f"- {project.get('name')}: {project.get('project_name')}")
    
    # Récupérer les tâches
    if args.tasks:
        tasks = erpnext.get_tasks(args.project)
        print(f"Tâches ERPNext ({len(tasks)}):")
        for task in tasks:
            print(f"- {task.get('name')}: {task.get('subject')}")
    
    # Créer une tâche
    if args.create_task:
        if not args.subject:
            print("Erreur: Le sujet de la tâche est requis")
        elif not args.description:
            print("Erreur: La description de la tâche est requise")
        else:
            task_name = erpnext.create_task(args.subject, args.description, args.project)
            if task_name:
                print(f"Tâche créée: {task_name}")
            else:
                print("Erreur lors de la création de la tâche")
    
    # Synchroniser ERPNext vers le journal
    if args.sync_to_journal:
        if erpnext.sync_to_journal():
            print("Synchronisation ERPNext vers journal réussie")
        else:
            print("Erreur lors de la synchronisation ERPNext vers journal")
    
    # Synchroniser le journal vers ERPNext
    if args.sync_from_journal:
        if erpnext.sync_from_journal():
            print("Synchronisation journal vers ERPNext réussie")
        else:
            print("Erreur lors de la synchronisation journal vers ERPNext")
