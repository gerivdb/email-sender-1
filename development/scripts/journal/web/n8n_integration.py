import os
import json
import logging
import requests
from pathlib import Path
from typing import List, Dict, Any, Optional, Union
from datetime import datetime

# Configurer le logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("n8n_integration")

class N8nIntegration:
    """Classe pour l'intégration avec n8n."""
    
    def __init__(self, config_path: str = "config.json"):
        """Initialise la classe N8nIntegration.
        
        Args:
            config_path: Chemin vers le fichier de configuration
        """
        self.config = self._load_config(config_path)
        
        # Répertoires
        journal_dir = self.config["journal"]["directory"]
        self.journal_dir = Path(journal_dir)
        self.entries_dir = self.journal_dir / self.config["journal"]["entries_dir"]
        
        # Configuration n8n
        self.n8n_config = self.config["integrations"]["n8n"]
        self.api_url = self.n8n_config.get("api_url", "http://localhost:5678/api/v1")
        self.api_key = self.n8n_config.get("api_key", "")
        
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
                    "n8n": {
                        "enabled": False,
                        "api_url": "http://localhost:5678/api/v1",
                        "api_key": ""
                    }
                }
            }
    
    def save_config(self) -> bool:
        """Sauvegarde la configuration.
        
        Returns:
            bool: True si la sauvegarde a réussi, False sinon
        """
        try:
            # Mettre à jour la configuration n8n
            self.config["integrations"]["n8n"] = {
                "enabled": self.n8n_config.get("enabled", False),
                "api_url": self.api_url,
                "api_key": self.api_key
            }
            
            # Sauvegarder la configuration
            with open("config.json", 'w', encoding='utf-8') as f:
                json.dump(self.config, f, ensure_ascii=False, indent=2)
            
            logger.info("Configuration n8n sauvegardée")
            return True
        except Exception as e:
            logger.error(f"Erreur lors de la sauvegarde de la configuration n8n: {e}")
            return False
    
    def authenticate(self) -> bool:
        """Vérifie l'authentification avec n8n.
        
        Returns:
            bool: True si l'authentification a réussi, False sinon
        """
        if not self.n8n_config.get("enabled", False):
            logger.warning("L'intégration n8n n'est pas activée")
            return False
        
        try:
            # Préparer les en-têtes
            headers = {}
            if self.api_key:
                headers["X-N8N-API-KEY"] = self.api_key
            
            # Tester l'authentification en récupérant les workflows
            response = requests.get(f"{self.api_url}/workflows", headers=headers)
            
            if response.status_code == 200:
                self.authenticated = True
                logger.info("Authentification n8n réussie")
                return True
            else:
                self.authenticated = False
                logger.error(f"Erreur d'authentification n8n: {response.status_code} {response.text}")
                return False
        except Exception as e:
            self.authenticated = False
            logger.error(f"Erreur lors de l'authentification n8n: {e}")
            return False
    
    def get_workflows(self) -> List[Dict[str, Any]]:
        """Récupère les workflows n8n.
        
        Returns:
            List[Dict]: Liste des workflows
        """
        if not self.authenticate():
            return []
        
        try:
            # Préparer les en-têtes
            headers = {}
            if self.api_key:
                headers["X-N8N-API-KEY"] = self.api_key
            
            # Récupérer les workflows
            response = requests.get(f"{self.api_url}/workflows", headers=headers)
            
            if response.status_code == 200:
                workflows = response.json()
                
                # Formater les workflows
                formatted_workflows = []
                
                for workflow in workflows:
                    formatted_workflows.append({
                        "id": workflow.get("id", ""),
                        "name": workflow.get("name", ""),
                        "active": workflow.get("active", False),
                        "createdAt": workflow.get("createdAt", ""),
                        "updatedAt": workflow.get("updatedAt", ""),
                        "tags": workflow.get("tags", [])
                    })
                
                logger.info(f"Récupération de {len(formatted_workflows)} workflows n8n")
                return formatted_workflows
            else:
                logger.error(f"Erreur lors de la récupération des workflows n8n: {response.status_code} {response.text}")
                return []
        except Exception as e:
            logger.error(f"Erreur lors de la récupération des workflows n8n: {e}")
            return []
    
    def get_workflow(self, workflow_id: str) -> Optional[Dict[str, Any]]:
        """Récupère un workflow n8n.
        
        Args:
            workflow_id: ID du workflow
            
        Returns:
            Dict: Workflow récupéré
        """
        if not self.authenticate():
            return None
        
        try:
            # Préparer les en-têtes
            headers = {}
            if self.api_key:
                headers["X-N8N-API-KEY"] = self.api_key
            
            # Récupérer le workflow
            response = requests.get(f"{self.api_url}/workflows/{workflow_id}", headers=headers)
            
            if response.status_code == 200:
                workflow = response.json()
                logger.info(f"Récupération du workflow n8n {workflow_id}")
                return workflow
            else:
                logger.error(f"Erreur lors de la récupération du workflow n8n {workflow_id}: {response.status_code} {response.text}")
                return None
        except Exception as e:
            logger.error(f"Erreur lors de la récupération du workflow n8n {workflow_id}: {e}")
            return None
    
    def activate_workflow(self, workflow_id: str, active: bool = True) -> bool:
        """Active ou désactive un workflow n8n.
        
        Args:
            workflow_id: ID du workflow
            active: True pour activer, False pour désactiver
            
        Returns:
            bool: True si l'opération a réussi, False sinon
        """
        if not self.authenticate():
            return False
        
        try:
            # Préparer les en-têtes
            headers = {
                "Content-Type": "application/json"
            }
            if self.api_key:
                headers["X-N8N-API-KEY"] = self.api_key
            
            # Préparer les données
            data = {
                "active": active
            }
            
            # Activer ou désactiver le workflow
            response = requests.patch(
                f"{self.api_url}/workflows/{workflow_id}/activate",
                headers=headers,
                json=data
            )
            
            if response.status_code == 200:
                logger.info(f"Workflow n8n {workflow_id} {'activé' if active else 'désactivé'}")
                return True
            else:
                logger.error(f"Erreur lors de l'{'activation' if active else 'désactivation'} du workflow n8n {workflow_id}: {response.status_code} {response.text}")
                return False
        except Exception as e:
            logger.error(f"Erreur lors de l'{'activation' if active else 'désactivation'} du workflow n8n {workflow_id}: {e}")
            return False
    
    def execute_workflow(self, workflow_id: str, data: Dict[str, Any] = None) -> Optional[Dict[str, Any]]:
        """Exécute un workflow n8n.
        
        Args:
            workflow_id: ID du workflow
            data: Données à passer au workflow
            
        Returns:
            Dict: Résultat de l'exécution
        """
        if not self.authenticate():
            return None
        
        try:
            # Préparer les en-têtes
            headers = {
                "Content-Type": "application/json"
            }
            if self.api_key:
                headers["X-N8N-API-KEY"] = self.api_key
            
            # Préparer les données
            if data is None:
                data = {}
            
            # Exécuter le workflow
            response = requests.post(
                f"{self.api_url}/workflows/{workflow_id}/execute",
                headers=headers,
                json=data
            )
            
            if response.status_code == 200:
                result = response.json()
                logger.info(f"Exécution du workflow n8n {workflow_id}")
                return result
            else:
                logger.error(f"Erreur lors de l'exécution du workflow n8n {workflow_id}: {response.status_code} {response.text}")
                return None
        except Exception as e:
            logger.error(f"Erreur lors de l'exécution du workflow n8n {workflow_id}: {e}")
            return None
    
    def get_executions(self, workflow_id: str = None, limit: int = 20) -> List[Dict[str, Any]]:
        """Récupère les exécutions de workflows n8n.
        
        Args:
            workflow_id: ID du workflow (None pour tous les workflows)
            limit: Nombre maximum d'exécutions à récupérer
            
        Returns:
            List[Dict]: Liste des exécutions
        """
        if not self.authenticate():
            return []
        
        try:
            # Préparer les en-têtes
            headers = {}
            if self.api_key:
                headers["X-N8N-API-KEY"] = self.api_key
            
            # Préparer l'URL
            url = f"{self.api_url}/executions"
            if workflow_id:
                url += f"?workflowId={workflow_id}"
            
            # Récupérer les exécutions
            response = requests.get(url, headers=headers)
            
            if response.status_code == 200:
                executions = response.json()
                
                # Limiter le nombre d'exécutions
                if limit and len(executions) > limit:
                    executions = executions[:limit]
                
                logger.info(f"Récupération de {len(executions)} exécutions n8n")
                return executions
            else:
                logger.error(f"Erreur lors de la récupération des exécutions n8n: {response.status_code} {response.text}")
                return []
        except Exception as e:
            logger.error(f"Erreur lors de la récupération des exécutions n8n: {e}")
            return []
    
    def create_journal_entry_workflow(self, name: str = "Create Journal Entry") -> Optional[str]:
        """Crée un workflow n8n pour créer une entrée de journal.
        
        Args:
            name: Nom du workflow
            
        Returns:
            str: ID du workflow créé
        """
        if not self.authenticate():
            return None
        
        try:
            # Préparer les en-têtes
            headers = {
                "Content-Type": "application/json"
            }
            if self.api_key:
                headers["X-N8N-API-KEY"] = self.api_key
            
            # Préparer les données du workflow
            workflow_data = {
                "name": name,
                "active": False,
                "nodes": [
                    {
                        "parameters": {},
                        "name": "Start",
                        "type": "n8n-nodes-base.start",
                        "typeVersion": 1,
                        "position": [
                            250,
                            300
                        ]
                    },
                    {
                        "parameters": {
                            "method": "POST",
                            "url": "http://localhost:8000/api/journal/entries",
                            "authentication": "none",
                            "sendHeaders": True,
                            "headerParameters": {
                                "parameters": [
                                    {
                                        "name": "Content-Type",
                                        "value": "application/json"
                                    }
                                ]
                            },
                            "sendBody": True,
                            "bodyParameters": {
                                "parameters": [
                                    {
                                        "name": "title",
                                        "value": "={{ $json.title }}"
                                    },
                                    {
                                        "name": "tags",
                                        "value": "={{ $json.tags }}"
                                    },
                                    {
                                        "name": "content",
                                        "value": "={{ $json.content }}"
                                    }
                                ]
                            },
                            "options": {}
                        },
                        "name": "HTTP Request",
                        "type": "n8n-nodes-base.httpRequest",
                        "typeVersion": 3,
                        "position": [
                            450,
                            300
                        ]
                    }
                ],
                "connections": {
                    "Start": {
                        "main": [
                            [
                                {
                                    "node": "HTTP Request",
                                    "type": "main",
                                    "index": 0
                                }
                            ]
                        ]
                    }
                }
            }
            
            # Créer le workflow
            response = requests.post(
                f"{self.api_url}/workflows",
                headers=headers,
                json=workflow_data
            )
            
            if response.status_code == 200:
                workflow = response.json()
                workflow_id = workflow.get("id", "")
                logger.info(f"Workflow n8n '{name}' créé avec l'ID {workflow_id}")
                return workflow_id
            else:
                logger.error(f"Erreur lors de la création du workflow n8n: {response.status_code} {response.text}")
                return None
        except Exception as e:
            logger.error(f"Erreur lors de la création du workflow n8n: {e}")
            return None
    
    def create_journal_analysis_workflow(self, name: str = "Journal Analysis") -> Optional[str]:
        """Crée un workflow n8n pour analyser le journal.
        
        Args:
            name: Nom du workflow
            
        Returns:
            str: ID du workflow créé
        """
        if not self.authenticate():
            return None
        
        try:
            # Préparer les en-têtes
            headers = {
                "Content-Type": "application/json"
            }
            if self.api_key:
                headers["X-N8N-API-KEY"] = self.api_key
            
            # Préparer les données du workflow
            workflow_data = {
                "name": name,
                "active": False,
                "nodes": [
                    {
                        "parameters": {
                            "rule": {
                                "interval": [
                                    {
                                        "field": "days",
                                        "minutesInterval": 1,
                                        "hoursInterval": 1
                                    }
                                ]
                            }
                        },
                        "name": "Schedule Trigger",
                        "type": "n8n-nodes-base.scheduleTrigger",
                        "typeVersion": 1,
                        "position": [
                            250,
                            300
                        ]
                    },
                    {
                        "parameters": {
                            "method": "POST",
                            "url": "http://localhost:8000/api/analysis/run",
                            "authentication": "none",
                            "sendHeaders": True,
                            "headerParameters": {
                                "parameters": [
                                    {
                                        "name": "Content-Type",
                                        "value": "application/json"
                                    }
                                ]
                            },
                            "sendBody": True,
                            "bodyParameters": {
                                "parameters": [
                                    {
                                        "name": "analysis_type",
                                        "value": "all"
                                    }
                                ]
                            },
                            "options": {}
                        },
                        "name": "Run Analysis",
                        "type": "n8n-nodes-base.httpRequest",
                        "typeVersion": 3,
                        "position": [
                            450,
                            300
                        ]
                    },
                    {
                        "parameters": {
                            "method": "POST",
                            "url": "http://localhost:8000/api/notifications/detect",
                            "authentication": "none",
                            "sendHeaders": True,
                            "headerParameters": {
                                "parameters": [
                                    {
                                        "name": "Content-Type",
                                        "value": "application/json"
                                    }
                                ]
                            },
                            "options": {}
                        },
                        "name": "Detect Patterns",
                        "type": "n8n-nodes-base.httpRequest",
                        "typeVersion": 3,
                        "position": [
                            650,
                            300
                        ]
                    }
                ],
                "connections": {
                    "Schedule Trigger": {
                        "main": [
                            [
                                {
                                    "node": "Run Analysis",
                                    "type": "main",
                                    "index": 0
                                }
                            ]
                        ]
                    },
                    "Run Analysis": {
                        "main": [
                            [
                                {
                                    "node": "Detect Patterns",
                                    "type": "main",
                                    "index": 0
                                }
                            ]
                        ]
                    }
                }
            }
            
            # Créer le workflow
            response = requests.post(
                f"{self.api_url}/workflows",
                headers=headers,
                json=workflow_data
            )
            
            if response.status_code == 200:
                workflow = response.json()
                workflow_id = workflow.get("id", "")
                logger.info(f"Workflow n8n '{name}' créé avec l'ID {workflow_id}")
                return workflow_id
            else:
                logger.error(f"Erreur lors de la création du workflow n8n: {response.status_code} {response.text}")
                return None
        except Exception as e:
            logger.error(f"Erreur lors de la création du workflow n8n: {e}")
            return None
    
    def create_notion_sync_workflow(self, name: str = "Notion Sync") -> Optional[str]:
        """Crée un workflow n8n pour synchroniser avec Notion.
        
        Args:
            name: Nom du workflow
            
        Returns:
            str: ID du workflow créé
        """
        if not self.authenticate():
            return None
        
        try:
            # Préparer les en-têtes
            headers = {
                "Content-Type": "application/json"
            }
            if self.api_key:
                headers["X-N8N-API-KEY"] = self.api_key
            
            # Préparer les données du workflow
            workflow_data = {
                "name": name,
                "active": False,
                "nodes": [
                    {
                        "parameters": {
                            "rule": {
                                "interval": [
                                    {
                                        "field": "hours",
                                        "minutesInterval": 1,
                                        "hoursInterval": 1
                                    }
                                ]
                            }
                        },
                        "name": "Schedule Trigger",
                        "type": "n8n-nodes-base.scheduleTrigger",
                        "typeVersion": 1,
                        "position": [
                            250,
                            300
                        ]
                    },
                    {
                        "parameters": {
                            "method": "POST",
                            "url": "http://localhost:8000/api/integrations/notion/sync-to-journal",
                            "authentication": "none",
                            "sendHeaders": True,
                            "headerParameters": {
                                "parameters": [
                                    {
                                        "name": "Content-Type",
                                        "value": "application/json"
                                    }
                                ]
                            },
                            "options": {}
                        },
                        "name": "Sync Notion to Journal",
                        "type": "n8n-nodes-base.httpRequest",
                        "typeVersion": 3,
                        "position": [
                            450,
                            300
                        ]
                    },
                    {
                        "parameters": {
                            "method": "POST",
                            "url": "http://localhost:8000/api/integrations/notion/sync-from-journal",
                            "authentication": "none",
                            "sendHeaders": True,
                            "headerParameters": {
                                "parameters": [
                                    {
                                        "name": "Content-Type",
                                        "value": "application/json"
                                    }
                                ]
                            },
                            "options": {}
                        },
                        "name": "Sync Journal to Notion",
                        "type": "n8n-nodes-base.httpRequest",
                        "typeVersion": 3,
                        "position": [
                            650,
                            300
                        ]
                    }
                ],
                "connections": {
                    "Schedule Trigger": {
                        "main": [
                            [
                                {
                                    "node": "Sync Notion to Journal",
                                    "type": "main",
                                    "index": 0
                                }
                            ]
                        ]
                    },
                    "Sync Notion to Journal": {
                        "main": [
                            [
                                {
                                    "node": "Sync Journal to Notion",
                                    "type": "main",
                                    "index": 0
                                }
                            ]
                        ]
                    }
                }
            }
            
            # Créer le workflow
            response = requests.post(
                f"{self.api_url}/workflows",
                headers=headers,
                json=workflow_data
            )
            
            if response.status_code == 200:
                workflow = response.json()
                workflow_id = workflow.get("id", "")
                logger.info(f"Workflow n8n '{name}' créé avec l'ID {workflow_id}")
                return workflow_id
            else:
                logger.error(f"Erreur lors de la création du workflow n8n: {response.status_code} {response.text}")
                return None
        except Exception as e:
            logger.error(f"Erreur lors de la création du workflow n8n: {e}")
            return None
    
    def create_default_workflows(self) -> Dict[str, str]:
        """Crée les workflows n8n par défaut.
        
        Returns:
            Dict[str, str]: Dictionnaire des workflows créés (nom -> ID)
        """
        workflows = {}
        
        # Créer le workflow de création d'entrée
        entry_workflow_id = self.create_journal_entry_workflow()
        if entry_workflow_id:
            workflows["Create Journal Entry"] = entry_workflow_id
        
        # Créer le workflow d'analyse
        analysis_workflow_id = self.create_journal_analysis_workflow()
        if analysis_workflow_id:
            workflows["Journal Analysis"] = analysis_workflow_id
        
        # Créer le workflow de synchronisation Notion
        notion_workflow_id = self.create_notion_sync_workflow()
        if notion_workflow_id:
            workflows["Notion Sync"] = notion_workflow_id
        
        return workflows

# Point d'entrée
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Intégration n8n pour le journal de bord")
    parser.add_argument("--url", type=str, help="URL de l'API n8n")
    parser.add_argument("--key", type=str, help="Clé API n8n")
    parser.add_argument("--test", action="store_true", help="Tester l'authentification")
    parser.add_argument("--workflows", action="store_true", help="Récupérer les workflows")
    parser.add_argument("--executions", action="store_true", help="Récupérer les exécutions")
    parser.add_argument("--create-workflows", action="store_true", help="Créer les workflows par défaut")
    parser.add_argument("--activate", type=str, help="Activer un workflow")
    parser.add_argument("--deactivate", type=str, help="Désactiver un workflow")
    parser.add_argument("--execute", type=str, help="Exécuter un workflow")
    
    args = parser.parse_args()
    
    n8n = N8nIntegration()
    
    # Mettre à jour la configuration
    if args.url:
        n8n.api_url = args.url
    
    if args.key:
        n8n.api_key = args.key
    
    # Activer l'intégration
    n8n.n8n_config["enabled"] = True
    
    # Sauvegarder la configuration
    n8n.save_config()
    
    # Tester l'authentification
    if args.test:
        if n8n.authenticate():
            print("Authentification n8n réussie")
        else:
            print("Erreur d'authentification n8n")
    
    # Récupérer les workflows
    if args.workflows:
        workflows = n8n.get_workflows()
        print(f"Workflows n8n ({len(workflows)}):")
        for workflow in workflows:
            print(f"- {workflow['name']} (ID: {workflow['id']}, Actif: {workflow['active']})")
    
    # Récupérer les exécutions
    if args.executions:
        executions = n8n.get_executions()
        print(f"Exécutions n8n ({len(executions)}):")
        for execution in executions:
            workflow_name = execution.get("workflowName", "")
            status = execution.get("status", "")
            started_at = execution.get("startedAt", "")
            print(f"- {workflow_name} (Statut: {status}, Démarré: {started_at})")
    
    # Créer les workflows par défaut
    if args.create_workflows:
        workflows = n8n.create_default_workflows()
        print(f"Workflows n8n créés ({len(workflows)}):")
        for name, workflow_id in workflows.items():
            print(f"- {name} (ID: {workflow_id})")
    
    # Activer un workflow
    if args.activate:
        if n8n.activate_workflow(args.activate, True):
            print(f"Workflow n8n {args.activate} activé")
        else:
            print(f"Erreur lors de l'activation du workflow n8n {args.activate}")
    
    # Désactiver un workflow
    if args.deactivate:
        if n8n.activate_workflow(args.deactivate, False):
            print(f"Workflow n8n {args.deactivate} désactivé")
        else:
            print(f"Erreur lors de la désactivation du workflow n8n {args.deactivate}")
    
    # Exécuter un workflow
    if args.execute:
        result = n8n.execute_workflow(args.execute)
        if result:
            print(f"Workflow n8n {args.execute} exécuté")
        else:
            print(f"Erreur lors de l'exécution du workflow n8n {args.execute}")
