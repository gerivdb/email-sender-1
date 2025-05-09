# Generate-DynamicViews.py
# Script pour générer des vues dynamiques à partir des données vectorisées
# Version: 1.0
# Date: 2025-05-15

import os
import json
import re
import logging
import argparse
from typing import List, Dict, Any, Optional, Tuple
import numpy as np
from datetime import datetime
import jinja2

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

try:
    from sentence_transformers import SentenceTransformer
    from qdrant_client import QdrantClient
    from qdrant_client.http import models
except ImportError:
    logger.error("Dépendances manquantes. Installez-les avec: pip install sentence-transformers qdrant-client jinja2")
    exit(1)

# Configuration par défaut
DEFAULT_MODEL = "all-MiniLM-L6-v2"
DEFAULT_COLLECTION = "roadmaps"
DEFAULT_QDRANT_HOST = "localhost"
DEFAULT_QDRANT_PORT = 6333
DEFAULT_TEMPLATES_DIR = "projet/roadmaps/templates"
DEFAULT_OUTPUT_DIR = "projet/roadmaps/views"

class DynamicViewGenerator:
    """Classe pour générer des vues dynamiques à partir des données vectorisées"""
    
    def __init__(
        self,
        model_name: str = DEFAULT_MODEL,
        collection_name: str = DEFAULT_COLLECTION,
        qdrant_host: str = DEFAULT_QDRANT_HOST,
        qdrant_port: int = DEFAULT_QDRANT_PORT,
        templates_dir: str = DEFAULT_TEMPLATES_DIR,
        output_dir: str = DEFAULT_OUTPUT_DIR
    ):
        """Initialise le générateur de vues dynamiques
        
        Args:
            model_name: Nom du modèle SentenceTransformer à utiliser
            collection_name: Nom de la collection Qdrant
            qdrant_host: Hôte du serveur Qdrant
            qdrant_port: Port du serveur Qdrant
            templates_dir: Dossier contenant les templates
            output_dir: Dossier de sortie pour les vues générées
        """
        self.model_name = model_name
        self.collection_name = collection_name
        self.qdrant_host = qdrant_host
        self.qdrant_port = qdrant_port
        self.templates_dir = templates_dir
        self.output_dir = output_dir
        
        # Charger le modèle
        logger.info(f"Chargement du modèle {model_name}...")
        self.model = SentenceTransformer(model_name)
        
        # Connexion à Qdrant
        logger.info(f"Connexion à Qdrant ({qdrant_host}:{qdrant_port})...")
        self.client = QdrantClient(host=qdrant_host, port=qdrant_port)
        
        # Initialiser le moteur de templates
        self.jinja_env = jinja2.Environment(
            loader=jinja2.FileSystemLoader(templates_dir),
            autoescape=jinja2.select_autoescape(['html', 'xml']),
            trim_blocks=True,
            lstrip_blocks=True
        )
        
        # Créer le dossier de sortie s'il n'existe pas
        os.makedirs(output_dir, exist_ok=True)
    
    def search_tasks(
        self,
        query: str = None,
        filter_condition: Optional[Dict[str, Any]] = None,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """Recherche des tâches dans Qdrant
        
        Args:
            query: Requête de recherche (si None, retourne toutes les tâches)
            filter_condition: Condition de filtrage pour Qdrant
            limit: Nombre maximum de résultats à retourner
            
        Returns:
            Liste de tâches
        """
        if query:
            # Générer l'embedding de la requête
            query_vector = self.model.encode(query).tolist()
            
            # Effectuer la recherche
            search_result = self.client.search(
                collection_name=self.collection_name,
                query_vector=query_vector,
                limit=limit,
                query_filter=filter_condition
            )
            
            # Extraire les payloads
            tasks = [point.payload for point in search_result]
        else:
            # Récupérer toutes les tâches (avec filtrage si spécifié)
            scroll_result = self.client.scroll(
                collection_name=self.collection_name,
                limit=limit,
                filter=filter_condition
            )
            
            # Extraire les payloads
            tasks = [point.payload for point in scroll_result[0]]
        
        return tasks
    
    def generate_view(
        self,
        template_name: str,
        output_name: str,
        context: Dict[str, Any]
    ) -> str:
        """Génère une vue à partir d'un template
        
        Args:
            template_name: Nom du template à utiliser
            output_name: Nom du fichier de sortie
            context: Contexte à passer au template
            
        Returns:
            Chemin vers le fichier généré
        """
        logger.info(f"Génération de la vue {output_name} avec le template {template_name}...")
        
        # Charger le template
        template = self.jinja_env.get_template(template_name)
        
        # Rendre le template
        rendered = template.render(**context)
        
        # Enregistrer le résultat
        output_path = os.path.join(self.output_dir, output_name)
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(rendered)
        
        logger.info(f"Vue générée dans {output_path}")
        return output_path
    
    def generate_task_list_view(
        self,
        query: str = None,
        filter_condition: Optional[Dict[str, Any]] = None,
        template_name: str = "task_list.md.j2",
        output_name: str = "task_list.md",
        title: str = "Liste des tâches",
        description: str = "Vue générée automatiquement"
    ) -> str:
        """Génère une vue de liste de tâches
        
        Args:
            query: Requête de recherche (si None, retourne toutes les tâches)
            filter_condition: Condition de filtrage pour Qdrant
            template_name: Nom du template à utiliser
            output_name: Nom du fichier de sortie
            title: Titre de la vue
            description: Description de la vue
            
        Returns:
            Chemin vers le fichier généré
        """
        # Rechercher les tâches
        tasks = self.search_tasks(query, filter_condition)
        
        # Préparer le contexte
        context = {
            "title": title,
            "description": description,
            "query": query,
            "filter": filter_condition,
            "tasks": tasks,
            "generated_at": datetime.now().isoformat(),
            "task_count": len(tasks)
        }
        
        # Générer la vue
        return self.generate_view(template_name, output_name, context)
    
    def generate_kanban_view(
        self,
        status_field: str = "status",
        statuses: List[str] = ["À faire", "En cours", "Terminé"],
        query: str = None,
        filter_condition: Optional[Dict[str, Any]] = None,
        template_name: str = "kanban.md.j2",
        output_name: str = "kanban.md",
        title: str = "Tableau Kanban",
        description: str = "Vue Kanban générée automatiquement"
    ) -> str:
        """Génère une vue Kanban
        
        Args:
            status_field: Nom du champ de statut dans les métadonnées
            statuses: Liste des statuts à afficher
            query: Requête de recherche (si None, retourne toutes les tâches)
            filter_condition: Condition de filtrage pour Qdrant
            template_name: Nom du template à utiliser
            output_name: Nom du fichier de sortie
            title: Titre de la vue
            description: Description de la vue
            
        Returns:
            Chemin vers le fichier généré
        """
        # Rechercher les tâches
        tasks = self.search_tasks(query, filter_condition)
        
        # Organiser les tâches par statut
        tasks_by_status = {status: [] for status in statuses}
        for task in tasks:
            status = task.get(status_field, "À faire")
            if status in tasks_by_status:
                tasks_by_status[status].append(task)
        
        # Préparer le contexte
        context = {
            "title": title,
            "description": description,
            "query": query,
            "filter": filter_condition,
            "statuses": statuses,
            "tasks_by_status": tasks_by_status,
            "generated_at": datetime.now().isoformat(),
            "task_count": len(tasks)
        }
        
        # Générer la vue
        return self.generate_view(template_name, output_name, context)
    
    def generate_timeline_view(
        self,
        date_field: str = "due_date",
        query: str = None,
        filter_condition: Optional[Dict[str, Any]] = None,
        template_name: str = "timeline.md.j2",
        output_name: str = "timeline.md",
        title: str = "Chronologie",
        description: str = "Vue chronologique générée automatiquement"
    ) -> str:
        """Génère une vue chronologique
        
        Args:
            date_field: Nom du champ de date dans les métadonnées
            query: Requête de recherche (si None, retourne toutes les tâches)
            filter_condition: Condition de filtrage pour Qdrant
            template_name: Nom du template à utiliser
            output_name: Nom du fichier de sortie
            title: Titre de la vue
            description: Description de la vue
            
        Returns:
            Chemin vers le fichier généré
        """
        # Rechercher les tâches
        tasks = self.search_tasks(query, filter_condition)
        
        # Filtrer les tâches qui ont une date
        tasks_with_date = [task for task in tasks if date_field in task]
        
        # Trier les tâches par date
        tasks_with_date.sort(key=lambda task: task[date_field])
        
        # Préparer le contexte
        context = {
            "title": title,
            "description": description,
            "query": query,
            "filter": filter_condition,
            "tasks": tasks_with_date,
            "generated_at": datetime.now().isoformat(),
            "task_count": len(tasks_with_date)
        }
        
        # Générer la vue
        return self.generate_view(template_name, output_name, context)

def main():
    """Fonction principale"""
    parser = argparse.ArgumentParser(description="Génère des vues dynamiques à partir des données vectorisées")
    parser.add_argument("--view-type", "-t", choices=["task-list", "kanban", "timeline"], required=True, help="Type de vue à générer")
    parser.add_argument("--query", "-q", help="Requête de recherche")
    parser.add_argument("--filter-file", "-f", help="Fichier JSON contenant les filtres à appliquer")
    parser.add_argument("--output", "-o", help="Nom du fichier de sortie")
    parser.add_argument("--title", help="Titre de la vue")
    parser.add_argument("--description", help="Description de la vue")
    parser.add_argument("--model", "-m", default=DEFAULT_MODEL, help=f"Nom du modèle SentenceTransformer (défaut: {DEFAULT_MODEL})")
    parser.add_argument("--collection", "-c", default=DEFAULT_COLLECTION, help=f"Nom de la collection Qdrant (défaut: {DEFAULT_COLLECTION})")
    parser.add_argument("--host", default=DEFAULT_QDRANT_HOST, help=f"Hôte du serveur Qdrant (défaut: {DEFAULT_QDRANT_HOST})")
    parser.add_argument("--port", type=int, default=DEFAULT_QDRANT_PORT, help=f"Port du serveur Qdrant (défaut: {DEFAULT_QDRANT_PORT})")
    parser.add_argument("--templates-dir", default=DEFAULT_TEMPLATES_DIR, help=f"Dossier contenant les templates (défaut: {DEFAULT_TEMPLATES_DIR})")
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR, help=f"Dossier de sortie pour les vues générées (défaut: {DEFAULT_OUTPUT_DIR})")
    
    args = parser.parse_args()
    
    # Charger les filtres si spécifiés
    filter_condition = None
    if args.filter_file:
        with open(args.filter_file, "r", encoding="utf-8") as f:
            filter_condition = json.load(f)
    
    # Créer le générateur de vues
    generator = DynamicViewGenerator(
        model_name=args.model,
        collection_name=args.collection,
        qdrant_host=args.host,
        qdrant_port=args.port,
        templates_dir=args.templates_dir,
        output_dir=args.output_dir
    )
    
    # Générer la vue demandée
    if args.view_type == "task-list":
        output_name = args.output or "task_list.md"
        title = args.title or "Liste des tâches"
        description = args.description or "Vue générée automatiquement"
        
        generator.generate_task_list_view(
            query=args.query,
            filter_condition=filter_condition,
            output_name=output_name,
            title=title,
            description=description
        )
    
    elif args.view_type == "kanban":
        output_name = args.output or "kanban.md"
        title = args.title or "Tableau Kanban"
        description = args.description or "Vue Kanban générée automatiquement"
        
        generator.generate_kanban_view(
            query=args.query,
            filter_condition=filter_condition,
            output_name=output_name,
            title=title,
            description=description
        )
    
    elif args.view_type == "timeline":
        output_name = args.output or "timeline.md"
        title = args.title or "Chronologie"
        description = args.description or "Vue chronologique générée automatiquement"
        
        generator.generate_timeline_view(
            query=args.query,
            filter_condition=filter_condition,
            output_name=output_name,
            title=title,
            description=description
        )

if __name__ == "__main__":
    main()
