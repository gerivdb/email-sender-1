# search_roadmaps.py
# Script pour rechercher dans les roadmaps vectorisées
# Version: 1.0
# Date: 2025-05-15

import os
import json
import logging
import argparse
from typing import List, Dict, Any, Optional, Tuple
import numpy as np
from datetime import datetime

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
    logger.error("Dépendances manquantes. Installez-les avec: pip install sentence-transformers qdrant-client")
    exit(1)

# Configuration par défaut
DEFAULT_MODEL = "all-MiniLM-L6-v2"
DEFAULT_COLLECTION = "roadmaps"
DEFAULT_QDRANT_HOST = "localhost"
DEFAULT_QDRANT_PORT = 6333
DEFAULT_LIMIT = 10
DEFAULT_OUTPUT_FORMAT = "text"

class RoadmapSearcher:
    """Classe pour rechercher dans les roadmaps vectorisées"""
    
    def __init__(
        self,
        model_name: str = DEFAULT_MODEL,
        collection_name: str = DEFAULT_COLLECTION,
        qdrant_host: str = DEFAULT_QDRANT_HOST,
        qdrant_port: int = DEFAULT_QDRANT_PORT
    ):
        """Initialise le chercheur de roadmaps
        
        Args:
            model_name: Nom du modèle SentenceTransformer à utiliser
            collection_name: Nom de la collection Qdrant
            qdrant_host: Hôte du serveur Qdrant
            qdrant_port: Port du serveur Qdrant
        """
        self.model_name = model_name
        self.collection_name = collection_name
        self.qdrant_host = qdrant_host
        self.qdrant_port = qdrant_port
        
        # Charger le modèle
        logger.info(f"Chargement du modèle {model_name}...")
        self.model = SentenceTransformer(model_name)
        
        # Connexion à Qdrant
        logger.info(f"Connexion à Qdrant ({qdrant_host}:{qdrant_port})...")
        self.client = QdrantClient(host=qdrant_host, port=qdrant_port)
        
        # Vérifier si la collection existe
        self._check_collection()
    
    def _check_collection(self) -> None:
        """Vérifie si la collection existe"""
        collections = self.client.get_collections().collections
        collection_names = [collection.name for collection in collections]
        
        if self.collection_name not in collection_names:
            logger.error(f"La collection {self.collection_name} n'existe pas.")
            logger.error("Exécutez d'abord vectorize_roadmaps.py pour créer la collection.")
            exit(1)
    
    def search(
        self,
        query: str,
        limit: int = DEFAULT_LIMIT,
        filter_condition: Optional[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """Recherche dans les roadmaps vectorisées
        
        Args:
            query: Requête de recherche
            limit: Nombre maximum de résultats à retourner
            filter_condition: Condition de filtrage pour Qdrant
            
        Returns:
            Liste de résultats de recherche
        """
        logger.info(f"Recherche: '{query}'")
        
        # Générer l'embedding de la requête
        query_vector = self.model.encode(query).tolist()
        
        # Effectuer la recherche
        search_result = self.client.search(
            collection_name=self.collection_name,
            query_vector=query_vector,
            limit=limit,
            query_filter=filter_condition
        )
        
        # Formater les résultats
        results = []
        for scored_point in search_result:
            result = {
                "score": scored_point.score,
                "payload": scored_point.payload
            }
            results.append(result)
        
        logger.info(f"Trouvé {len(results)} résultats")
        return results
    
    def format_results(self, results: List[Dict[str, Any]], format: str = DEFAULT_OUTPUT_FORMAT) -> str:
        """Formate les résultats de recherche
        
        Args:
            results: Liste de résultats de recherche
            format: Format de sortie (text, json, markdown)
            
        Returns:
            Résultats formatés
        """
        if format == "json":
            return json.dumps(results, indent=2, ensure_ascii=False)
        
        elif format == "markdown":
            markdown = "# Résultats de recherche\n\n"
            for i, result in enumerate(results):
                score = result["score"]
                payload = result["payload"]
                file_path = payload["file_path"]
                text = payload["text"]
                path = payload.get("path", "")
                task_id = payload.get("task_id", "")
                
                markdown += f"## Résultat {i+1} (score: {score:.4f})\n\n"
                markdown += f"**Fichier:** {file_path}\n\n"
                if path:
                    markdown += f"**Chemin:** {path}\n\n"
                if task_id:
                    markdown += f"**ID de tâche:** {task_id}\n\n"
                markdown += "```markdown\n"
                markdown += text
                markdown += "\n```\n\n"
            
            return markdown
        
        else:  # format == "text"
            text = "Résultats de recherche:\n\n"
            for i, result in enumerate(results):
                score = result["score"]
                payload = result["payload"]
                file_path = payload["file_path"]
                text_content = payload["text"]
                path = payload.get("path", "")
                task_id = payload.get("task_id", "")
                
                text += f"Résultat {i+1} (score: {score:.4f})\n"
                text += f"Fichier: {file_path}\n"
                if path:
                    text += f"Chemin: {path}\n"
                if task_id:
                    text += f"ID de tâche: {task_id}\n"
                text += "-" * 40 + "\n"
                text += text_content
                text += "\n" + "=" * 80 + "\n\n"
            
            return text

def main():
    """Fonction principale"""
    parser = argparse.ArgumentParser(description="Recherche dans les roadmaps vectorisées")
    parser.add_argument("query", help="Requête de recherche")
    parser.add_argument("--model", "-m", default=DEFAULT_MODEL, help=f"Nom du modèle SentenceTransformer (défaut: {DEFAULT_MODEL})")
    parser.add_argument("--collection", "-c", default=DEFAULT_COLLECTION, help=f"Nom de la collection Qdrant (défaut: {DEFAULT_COLLECTION})")
    parser.add_argument("--host", default=DEFAULT_QDRANT_HOST, help=f"Hôte du serveur Qdrant (défaut: {DEFAULT_QDRANT_HOST})")
    parser.add_argument("--port", type=int, default=DEFAULT_QDRANT_PORT, help=f"Port du serveur Qdrant (défaut: {DEFAULT_QDRANT_PORT})")
    parser.add_argument("--limit", "-l", type=int, default=DEFAULT_LIMIT, help=f"Nombre maximum de résultats (défaut: {DEFAULT_LIMIT})")
    parser.add_argument("--format", "-f", choices=["text", "json", "markdown"], default=DEFAULT_OUTPUT_FORMAT, help=f"Format de sortie (défaut: {DEFAULT_OUTPUT_FORMAT})")
    parser.add_argument("--output", "-o", help="Fichier de sortie (si non spécifié, affiche sur la sortie standard)")
    parser.add_argument("--filter-file", help="Fichier JSON contenant les filtres à appliquer")
    
    args = parser.parse_args()
    
    # Charger les filtres si spécifiés
    filter_condition = None
    if args.filter_file:
        with open(args.filter_file, "r", encoding="utf-8") as f:
            filter_condition = json.load(f)
    
    # Créer le chercheur
    searcher = RoadmapSearcher(
        model_name=args.model,
        collection_name=args.collection,
        qdrant_host=args.host,
        qdrant_port=args.port
    )
    
    # Effectuer la recherche
    results = searcher.search(
        query=args.query,
        limit=args.limit,
        filter_condition=filter_condition
    )
    
    # Formater les résultats
    formatted_results = searcher.format_results(results, format=args.format)
    
    # Afficher ou enregistrer les résultats
    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(formatted_results)
        logger.info(f"Résultats enregistrés dans {args.output}")
    else:
        print(formatted_results)

if __name__ == "__main__":
    main()
