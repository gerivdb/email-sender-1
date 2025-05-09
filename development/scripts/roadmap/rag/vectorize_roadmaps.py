# vectorize_roadmaps.py
# Script pour vectoriser le contenu des roadmaps et les stocker dans Qdrant
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
DEFAULT_CHUNK_SIZE = 512
DEFAULT_CHUNK_OVERLAP = 128

class RoadmapVectorizer:
    """Classe pour vectoriser le contenu des roadmaps et les stocker dans Qdrant"""
    
    def __init__(
        self,
        model_name: str = DEFAULT_MODEL,
        collection_name: str = DEFAULT_COLLECTION,
        qdrant_host: str = DEFAULT_QDRANT_HOST,
        qdrant_port: int = DEFAULT_QDRANT_PORT,
        chunk_size: int = DEFAULT_CHUNK_SIZE,
        chunk_overlap: int = DEFAULT_CHUNK_OVERLAP
    ):
        """Initialise le vectoriseur de roadmaps
        
        Args:
            model_name: Nom du modèle SentenceTransformer à utiliser
            collection_name: Nom de la collection Qdrant
            qdrant_host: Hôte du serveur Qdrant
            qdrant_port: Port du serveur Qdrant
            chunk_size: Taille maximale des chunks de texte
            chunk_overlap: Chevauchement entre les chunks
        """
        self.model_name = model_name
        self.collection_name = collection_name
        self.qdrant_host = qdrant_host
        self.qdrant_port = qdrant_port
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap
        
        # Charger le modèle
        logger.info(f"Chargement du modèle {model_name}...")
        self.model = SentenceTransformer(model_name)
        
        # Connexion à Qdrant
        logger.info(f"Connexion à Qdrant ({qdrant_host}:{qdrant_port})...")
        self.client = QdrantClient(host=qdrant_host, port=qdrant_port)
        
        # Vérifier si la collection existe, sinon la créer
        self._ensure_collection_exists()
    
    def _ensure_collection_exists(self) -> None:
        """Vérifie si la collection existe, sinon la crée"""
        collections = self.client.get_collections().collections
        collection_names = [collection.name for collection in collections]
        
        if self.collection_name not in collection_names:
            logger.info(f"Création de la collection {self.collection_name}...")
            self.client.create_collection(
                collection_name=self.collection_name,
                vectors_config=models.VectorParams(
                    size=self.model.get_sentence_embedding_dimension(),
                    distance=models.Distance.COSINE
                )
            )
    
    def chunk_markdown(self, text: str) -> List[Dict[str, Any]]:
        """Découpe un texte markdown en chunks
        
        Args:
            text: Texte markdown à découper
            
        Returns:
            Liste de chunks avec leurs métadonnées
        """
        # Diviser le texte en lignes
        lines = text.split("\n")
        
        chunks = []
        current_chunk = []
        current_chunk_size = 0
        current_headers = []
        current_path = []
        task_id = None
        
        for line in lines:
            # Détecter les en-têtes
            header_match = re.match(r"^(#+)\s+(.+)$", line)
            if header_match:
                level = len(header_match.group(1))
                title = header_match.group(2).strip()
                
                # Mettre à jour le chemin de navigation
                current_path = current_path[:level-1] + [title]
                current_headers = current_headers[:level-1] + [{"level": level, "title": title}]
            
            # Détecter les tâches
            task_match = re.match(r"\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*([0-9.]+)\*\*)?\s*(.+)$", line)
            if task_match:
                completed = task_match.group(1).lower() == "x"
                task_num = task_match.group(2)
                task_text = task_match.group(3).strip()
                
                if task_num:
                    task_id = task_num
            
            # Ajouter la ligne au chunk actuel
            current_chunk.append(line)
            current_chunk_size += len(line)
            
            # Si le chunk atteint la taille maximale, l'ajouter à la liste et commencer un nouveau chunk
            if current_chunk_size >= self.chunk_size:
                chunk_text = "\n".join(current_chunk)
                chunks.append({
                    "text": chunk_text,
                    "headers": current_headers.copy(),
                    "path": "/".join(current_path),
                    "task_id": task_id
                })
                
                # Commencer un nouveau chunk avec chevauchement
                overlap_lines = current_chunk[-self.chunk_overlap:]
                current_chunk = overlap_lines
                current_chunk_size = sum(len(line) for line in overlap_lines)
        
        # Ajouter le dernier chunk s'il n'est pas vide
        if current_chunk:
            chunk_text = "\n".join(current_chunk)
            chunks.append({
                "text": chunk_text,
                "headers": current_headers.copy(),
                "path": "/".join(current_path),
                "task_id": task_id
            })
        
        return chunks
    
    def vectorize_roadmap(self, roadmap_file: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Vectorise un fichier de roadmap
        
        Args:
            roadmap_file: Dictionnaire contenant les informations du fichier de roadmap
            
        Returns:
            Liste de points vectoriels à insérer dans Qdrant
        """
        file_path = roadmap_file["Path"]
        content = roadmap_file["Content"]
        
        logger.info(f"Vectorisation de {file_path}...")
        
        # Découper le contenu en chunks
        chunks = self.chunk_markdown(content)
        logger.info(f"  - {len(chunks)} chunks créés")
        
        # Vectoriser les chunks
        points = []
        for i, chunk in enumerate(chunks):
            # Générer l'embedding
            embedding = self.model.encode(chunk["text"])
            
            # Créer le point vectoriel
            point = {
                "id": f"{os.path.basename(file_path)}_{i}",
                "vector": embedding.tolist(),
                "payload": {
                    "file_path": file_path,
                    "chunk_index": i,
                    "text": chunk["text"],
                    "headers": chunk["headers"],
                    "path": chunk["path"],
                    "task_id": chunk["task_id"],
                    "metadata": {
                        "file_name": os.path.basename(file_path),
                        "creation_time": roadmap_file.get("CreationTime", ""),
                        "last_write_time": roadmap_file.get("LastWriteTime", ""),
                        "vectorized_at": datetime.now().isoformat()
                    }
                }
            }
            points.append(point)
        
        return points
    
    def index_roadmaps(self, inventory_path: str) -> None:
        """Indexe tous les fichiers de roadmap dans l'inventaire
        
        Args:
            inventory_path: Chemin vers le fichier d'inventaire JSON
        """
        # Charger l'inventaire
        logger.info(f"Chargement de l'inventaire depuis {inventory_path}...")
        with open(inventory_path, "r", encoding="utf-8") as f:
            inventory = json.load(f)
        
        logger.info(f"Indexation de {len(inventory)} fichiers de roadmap...")
        
        # Vectoriser chaque fichier
        all_points = []
        for roadmap_file in inventory:
            points = self.vectorize_roadmap(roadmap_file)
            all_points.extend(points)
        
        # Insérer les points dans Qdrant
        if all_points:
            logger.info(f"Insertion de {len(all_points)} points dans Qdrant...")
            
            # Préparer les points pour l'insertion
            qdrant_points = []
            for point in all_points:
                qdrant_point = models.PointStruct(
                    id=point["id"],
                    vector=point["vector"],
                    payload=point["payload"]
                )
                qdrant_points.append(qdrant_point)
            
            # Insérer les points par lots de 100
            batch_size = 100
            for i in range(0, len(qdrant_points), batch_size):
                batch = qdrant_points[i:i+batch_size]
                self.client.upsert(
                    collection_name=self.collection_name,
                    points=batch
                )
                logger.info(f"  - Lot {i//batch_size + 1}/{(len(qdrant_points)-1)//batch_size + 1} inséré")
        
        logger.info("Indexation terminée avec succès!")

def main():
    """Fonction principale"""
    parser = argparse.ArgumentParser(description="Vectorise les roadmaps et les stocke dans Qdrant")
    parser.add_argument("--inventory", "-i", required=True, help="Chemin vers le fichier d'inventaire JSON")
    parser.add_argument("--model", "-m", default=DEFAULT_MODEL, help=f"Nom du modèle SentenceTransformer (défaut: {DEFAULT_MODEL})")
    parser.add_argument("--collection", "-c", default=DEFAULT_COLLECTION, help=f"Nom de la collection Qdrant (défaut: {DEFAULT_COLLECTION})")
    parser.add_argument("--host", default=DEFAULT_QDRANT_HOST, help=f"Hôte du serveur Qdrant (défaut: {DEFAULT_QDRANT_HOST})")
    parser.add_argument("--port", type=int, default=DEFAULT_QDRANT_PORT, help=f"Port du serveur Qdrant (défaut: {DEFAULT_QDRANT_PORT})")
    parser.add_argument("--chunk-size", type=int, default=DEFAULT_CHUNK_SIZE, help=f"Taille maximale des chunks (défaut: {DEFAULT_CHUNK_SIZE})")
    parser.add_argument("--chunk-overlap", type=int, default=DEFAULT_CHUNK_OVERLAP, help=f"Chevauchement entre les chunks (défaut: {DEFAULT_CHUNK_OVERLAP})")
    
    args = parser.parse_args()
    
    # Créer le vectoriseur
    vectorizer = RoadmapVectorizer(
        model_name=args.model,
        collection_name=args.collection,
        qdrant_host=args.host,
        qdrant_port=args.port,
        chunk_size=args.chunk_size,
        chunk_overlap=args.chunk_overlap
    )
    
    # Indexer les roadmaps
    vectorizer.index_roadmaps(args.inventory)

if __name__ == "__main__":
    main()
