"""
Module pour la gestion du stockage vectoriel.
Ce module fournit des classes pour gérer le stockage et la recherche de vecteurs avec Qdrant.
"""

import os
import json
import time
import uuid
from typing import List, Dict, Any, Optional, Union, Tuple, Callable
from datetime import datetime

from embedding_manager import Vector, Embedding, EmbeddingCollection
from vector_storage import QdrantConfig, QdrantClient


class VectorStorageManager:
    """
    Gestionnaire de stockage vectoriel.
    """
    
    def __init__(
        self,
        client: Optional[QdrantClient] = None,
        config_path: Optional[str] = None
    ):
        """
        Initialise le gestionnaire de stockage vectoriel.
        
        Args:
            client: Client Qdrant (crée un nouveau client si None).
            config_path: Chemin vers le fichier de configuration (optionnel).
        """
        if client:
            self.client = client
        elif config_path and os.path.exists(config_path):
            with open(config_path, 'r', encoding='utf-8') as f:
                config_data = json.load(f)
            
            config = QdrantConfig.from_dict(config_data)
            self.client = QdrantClient(config)
        else:
            self.client = QdrantClient()
    
    def is_healthy(self) -> bool:
        """
        Vérifie si le stockage vectoriel est en ligne.
        
        Returns:
            True si le stockage est en ligne, False sinon.
        """
        return self.client.check_health()
    
    def list_collections(self) -> List[str]:
        """
        Liste les collections disponibles.
        
        Returns:
            Liste des noms de collections.
        """
        success, collections = self.client.get_collections()
        return collections if success else []
    
    def create_collection(
        self,
        collection_name: str,
        vector_size: int = 1536,
        distance: str = "Cosine",
        on_disk_payload: bool = False,
        create_metadata_indices: bool = True
    ) -> bool:
        """
        Crée une nouvelle collection.
        
        Args:
            collection_name: Nom de la collection.
            vector_size: Taille des vecteurs.
            distance: Métrique de distance (Cosine, Euclid, Dot).
            on_disk_payload: Si True, stocke les payloads sur disque.
            create_metadata_indices: Si True, crée des indices sur les métadonnées communes.
            
        Returns:
            True si la création a réussi, False sinon.
        """
        # Vérifier si la collection existe déjà
        if self.client.collection_exists(collection_name):
            return True
        
        # Créer la collection
        success, _ = self.client.create_collection(
            collection_name=collection_name,
            vector_size=vector_size,
            distance=distance,
            on_disk_payload=on_disk_payload
        )
        
        if not success:
            return False
        
        # Créer des indices sur les métadonnées communes
        if create_metadata_indices:
            # Indice sur le type de mémoire
            self.client.create_payload_index(
                collection_name=collection_name,
                field_name="metadata.type",
                field_schema="keyword"
            )
            
            # Indice sur la source
            self.client.create_payload_index(
                collection_name=collection_name,
                field_name="metadata.source",
                field_schema="keyword"
            )
            
            # Indice sur les tags
            self.client.create_payload_index(
                collection_name=collection_name,
                field_name="metadata.tags",
                field_schema="keyword"
            )
            
            # Indice sur l'importance
            self.client.create_payload_index(
                collection_name=collection_name,
                field_name="importance",
                field_schema="float"
            )
        
        return True
    
    def delete_collection(self, collection_name: str) -> bool:
        """
        Supprime une collection.
        
        Args:
            collection_name: Nom de la collection.
            
        Returns:
            True si la suppression a réussi, False sinon.
        """
        success, _ = self.client.delete_collection(collection_name)
        return success
    
    def get_collection_info(self, collection_name: str) -> Dict[str, Any]:
        """
        Récupère les informations sur une collection.
        
        Args:
            collection_name: Nom de la collection.
            
        Returns:
            Informations sur la collection.
        """
        success, info = self.client.get_collection_info(collection_name)
        return info if success else {}
    
    def store_embedding(
        self,
        collection_name: str,
        embedding: Embedding
    ) -> bool:
        """
        Stocke un embedding dans une collection.
        
        Args:
            collection_name: Nom de la collection.
            embedding: Embedding à stocker.
            
        Returns:
            True si le stockage a réussi, False sinon.
        """
        # Vérifier si la collection existe
        if not self.client.collection_exists(collection_name):
            return False
        
        # Préparer le point
        point = {
            "id": embedding.id,
            "vector": embedding.vector.to_list(),
            "payload": {
                "text": embedding.text,
                "metadata": embedding.metadata,
                "created_at": datetime.now().isoformat()
            }
        }
        
        # Stocker le point
        success, _ = self.client.upsert_points(collection_name, [point])
        return success
    
    def store_embeddings(
        self,
        collection_name: str,
        embeddings: List[Embedding]
    ) -> Tuple[bool, int]:
        """
        Stocke plusieurs embeddings dans une collection.
        
        Args:
            collection_name: Nom de la collection.
            embeddings: Liste d'embeddings à stocker.
            
        Returns:
            Tuple (succès, nombre d'embeddings stockés).
        """
        # Vérifier si la collection existe
        if not self.client.collection_exists(collection_name):
            return False, 0
        
        # Préparer les points
        points = []
        for embedding in embeddings:
            point = {
                "id": embedding.id,
                "vector": embedding.vector.to_list(),
                "payload": {
                    "text": embedding.text,
                    "metadata": embedding.metadata,
                    "created_at": datetime.now().isoformat()
                }
            }
            points.append(point)
        
        # Stocker les points
        success, _ = self.client.upsert_points(collection_name, points)
        return success, len(points) if success else 0
    
    def store_collection(
        self,
        collection_name: str,
        embedding_collection: EmbeddingCollection
    ) -> Tuple[bool, int]:
        """
        Stocke une collection d'embeddings.
        
        Args:
            collection_name: Nom de la collection Qdrant.
            embedding_collection: Collection d'embeddings à stocker.
            
        Returns:
            Tuple (succès, nombre d'embeddings stockés).
        """
        embeddings = list(embedding_collection)
        return self.store_embeddings(collection_name, embeddings)
    
    def delete_embedding(
        self,
        collection_name: str,
        embedding_id: str
    ) -> bool:
        """
        Supprime un embedding d'une collection.
        
        Args:
            collection_name: Nom de la collection.
            embedding_id: Identifiant de l'embedding à supprimer.
            
        Returns:
            True si la suppression a réussi, False sinon.
        """
        # Vérifier si la collection existe
        if not self.client.collection_exists(collection_name):
            return False
        
        # Supprimer le point
        success, _ = self.client.delete_points(
            collection_name=collection_name,
            points_selector={"ids": [embedding_id]}
        )
        
        return success
    
    def delete_embeddings(
        self,
        collection_name: str,
        filter: Dict[str, Any]
    ) -> bool:
        """
        Supprime des embeddings d'une collection selon un filtre.
        
        Args:
            collection_name: Nom de la collection.
            filter: Filtre pour sélectionner les embeddings à supprimer.
            
        Returns:
            True si la suppression a réussi, False sinon.
        """
        # Vérifier si la collection existe
        if not self.client.collection_exists(collection_name):
            return False
        
        # Supprimer les points
        success, _ = self.client.delete_points(
            collection_name=collection_name,
            points_selector={"filter": filter}
        )
        
        return success
    
    def search_similar(
        self,
        collection_name: str,
        query_vector: Vector,
        limit: int = 10,
        filter: Optional[Dict[str, Any]] = None,
        with_payload: bool = True
    ) -> List[Tuple[Embedding, float]]:
        """
        Recherche des embeddings similaires à un vecteur.
        
        Args:
            collection_name: Nom de la collection.
            query_vector: Vecteur de requête.
            limit: Nombre maximum de résultats.
            filter: Filtre sur les payloads.
            with_payload: Si True, inclut les payloads dans les résultats.
            
        Returns:
            Liste de tuples (embedding, score).
        """
        # Vérifier si la collection existe
        if not self.client.collection_exists(collection_name):
            return []
        
        # Rechercher les points
        success, results = self.client.search_points(
            collection_name=collection_name,
            vector=query_vector.to_list(),
            limit=limit,
            filter=filter,
            with_payload=with_payload
        )
        
        if not success:
            return []
        
        # Convertir les résultats en embeddings
        embeddings = []
        for result in results:
            if "payload" in result and "text" in result["payload"] and "metadata" in result["payload"]:
                vector = Vector(result.get("vector", query_vector.to_list()))
                embedding = Embedding(
                    vector=vector,
                    text=result["payload"]["text"],
                    metadata=result["payload"]["metadata"],
                    id=result["id"]
                )
                score = result.get("score", 0.0)
                embeddings.append((embedding, score))
        
        return embeddings
