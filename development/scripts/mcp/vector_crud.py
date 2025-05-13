"""
Module pour les opérations CRUD sur les vecteurs.
Ce module fournit des classes et fonctions pour effectuer des opérations CRUD sur les vecteurs.
"""

import os
import json
import time
import uuid
from typing import List, Dict, Any, Optional, Union, Tuple, Callable, Iterator
from datetime import datetime

from embedding_manager import Vector, Embedding, EmbeddingCollection
from vector_storage import QdrantConfig, QdrantClient
from vector_storage_manager import VectorStorageManager


class VectorCRUD:
    """
    Classe pour les opérations CRUD sur les vecteurs.
    """
    
    def __init__(
        self,
        storage_manager: Optional[VectorStorageManager] = None,
        default_collection: str = "default"
    ):
        """
        Initialise le gestionnaire CRUD pour les vecteurs.
        
        Args:
            storage_manager: Gestionnaire de stockage vectoriel (crée un nouveau gestionnaire si None).
            default_collection: Nom de la collection par défaut.
        """
        self.storage_manager = storage_manager or VectorStorageManager()
        self.default_collection = default_collection
        
        # Créer la collection par défaut si elle n'existe pas
        if default_collection not in self.storage_manager.list_collections():
            self.storage_manager.create_collection(default_collection)
    
    def create(
        self,
        embedding: Embedding,
        collection_name: Optional[str] = None
    ) -> bool:
        """
        Crée un nouvel embedding dans le stockage.
        
        Args:
            embedding: Embedding à créer.
            collection_name: Nom de la collection (utilise la collection par défaut si None).
            
        Returns:
            True si la création a réussi, False sinon.
        """
        collection = collection_name or self.default_collection
        return self.storage_manager.store_embedding(collection, embedding)
    
    def create_batch(
        self,
        embeddings: List[Embedding],
        collection_name: Optional[str] = None
    ) -> Tuple[bool, int]:
        """
        Crée plusieurs embeddings dans le stockage.
        
        Args:
            embeddings: Liste d'embeddings à créer.
            collection_name: Nom de la collection (utilise la collection par défaut si None).
            
        Returns:
            Tuple (succès, nombre d'embeddings créés).
        """
        collection = collection_name or self.default_collection
        return self.storage_manager.store_embeddings(collection, embeddings)
    
    def read(
        self,
        embedding_id: str,
        collection_name: Optional[str] = None
    ) -> Optional[Embedding]:
        """
        Lit un embedding depuis le stockage.
        
        Args:
            embedding_id: Identifiant de l'embedding à lire.
            collection_name: Nom de la collection (utilise la collection par défaut si None).
            
        Returns:
            Embedding lu ou None si non trouvé.
        """
        collection = collection_name or self.default_collection
        
        # Créer un filtre pour récupérer l'embedding par ID
        filter = {
            "must": [
                {
                    "key": "id",
                    "match": {
                        "value": embedding_id
                    }
                }
            ]
        }
        
        # Rechercher l'embedding (sans vecteur de requête spécifique)
        # Utiliser un vecteur aléatoire pour la recherche (sera ignoré car on filtre par ID)
        dummy_vector = Vector([0.0] * 1536)
        results = self.storage_manager.search_similar(
            collection_name=collection,
            query_vector=dummy_vector,
            limit=1,
            filter=filter
        )
        
        if results:
            return results[0][0]
        
        return None
    
    def read_batch(
        self,
        embedding_ids: List[str],
        collection_name: Optional[str] = None
    ) -> List[Embedding]:
        """
        Lit plusieurs embeddings depuis le stockage.
        
        Args:
            embedding_ids: Liste d'identifiants d'embeddings à lire.
            collection_name: Nom de la collection (utilise la collection par défaut si None).
            
        Returns:
            Liste d'embeddings lus.
        """
        collection = collection_name or self.default_collection
        
        # Créer un filtre pour récupérer les embeddings par IDs
        filter = {
            "must": [
                {
                    "key": "id",
                    "match": {
                        "any": embedding_ids
                    }
                }
            ]
        }
        
        # Rechercher les embeddings (sans vecteur de requête spécifique)
        dummy_vector = Vector([0.0] * 1536)
        results = self.storage_manager.search_similar(
            collection_name=collection,
            query_vector=dummy_vector,
            limit=len(embedding_ids),
            filter=filter
        )
        
        return [result[0] for result in results]
    
    def update(
        self,
        embedding: Embedding,
        collection_name: Optional[str] = None
    ) -> bool:
        """
        Met à jour un embedding dans le stockage.
        
        Args:
            embedding: Embedding à mettre à jour.
            collection_name: Nom de la collection (utilise la collection par défaut si None).
            
        Returns:
            True si la mise à jour a réussi, False sinon.
        """
        collection = collection_name or self.default_collection
        
        # Mettre à jour l'embedding (upsert)
        return self.storage_manager.store_embedding(collection, embedding)
    
    def update_batch(
        self,
        embeddings: List[Embedding],
        collection_name: Optional[str] = None
    ) -> Tuple[bool, int]:
        """
        Met à jour plusieurs embeddings dans le stockage.
        
        Args:
            embeddings: Liste d'embeddings à mettre à jour.
            collection_name: Nom de la collection (utilise la collection par défaut si None).
            
        Returns:
            Tuple (succès, nombre d'embeddings mis à jour).
        """
        collection = collection_name or self.default_collection
        
        # Mettre à jour les embeddings (upsert)
        return self.storage_manager.store_embeddings(collection, embeddings)
    
    def delete(
        self,
        embedding_id: str,
        collection_name: Optional[str] = None
    ) -> bool:
        """
        Supprime un embedding du stockage.
        
        Args:
            embedding_id: Identifiant de l'embedding à supprimer.
            collection_name: Nom de la collection (utilise la collection par défaut si None).
            
        Returns:
            True si la suppression a réussi, False sinon.
        """
        collection = collection_name or self.default_collection
        return self.storage_manager.delete_embedding(collection, embedding_id)
    
    def delete_batch(
        self,
        embedding_ids: List[str],
        collection_name: Optional[str] = None
    ) -> bool:
        """
        Supprime plusieurs embeddings du stockage.
        
        Args:
            embedding_ids: Liste d'identifiants d'embeddings à supprimer.
            collection_name: Nom de la collection (utilise la collection par défaut si None).
            
        Returns:
            True si la suppression a réussi, False sinon.
        """
        collection = collection_name or self.default_collection
        
        # Créer un filtre pour supprimer les embeddings par IDs
        filter = {
            "must": [
                {
                    "key": "id",
                    "match": {
                        "any": embedding_ids
                    }
                }
            ]
        }
        
        return self.storage_manager.delete_embeddings(collection, filter)
    
    def delete_by_filter(
        self,
        filter: Dict[str, Any],
        collection_name: Optional[str] = None
    ) -> bool:
        """
        Supprime des embeddings du stockage selon un filtre.
        
        Args:
            filter: Filtre pour sélectionner les embeddings à supprimer.
            collection_name: Nom de la collection (utilise la collection par défaut si None).
            
        Returns:
            True si la suppression a réussi, False sinon.
        """
        collection = collection_name or self.default_collection
        return self.storage_manager.delete_embeddings(collection, filter)
    
    def search(
        self,
        query_vector: Vector,
        limit: int = 10,
        filter: Optional[Dict[str, Any]] = None,
        collection_name: Optional[str] = None
    ) -> List[Tuple[Embedding, float]]:
        """
        Recherche des embeddings similaires à un vecteur.
        
        Args:
            query_vector: Vecteur de requête.
            limit: Nombre maximum de résultats.
            filter: Filtre sur les payloads.
            collection_name: Nom de la collection (utilise la collection par défaut si None).
            
        Returns:
            Liste de tuples (embedding, score).
        """
        collection = collection_name or self.default_collection
        return self.storage_manager.search_similar(
            collection_name=collection,
            query_vector=query_vector,
            limit=limit,
            filter=filter
        )
    
    def search_by_text(
        self,
        query_text: str,
        embedding_function: Callable[[str], Vector],
        limit: int = 10,
        filter: Optional[Dict[str, Any]] = None,
        collection_name: Optional[str] = None
    ) -> List[Tuple[Embedding, float]]:
        """
        Recherche des embeddings similaires à un texte.
        
        Args:
            query_text: Texte de requête.
            embedding_function: Fonction pour convertir le texte en vecteur.
            limit: Nombre maximum de résultats.
            filter: Filtre sur les payloads.
            collection_name: Nom de la collection (utilise la collection par défaut si None).
            
        Returns:
            Liste de tuples (embedding, score).
        """
        # Convertir le texte en vecteur
        query_vector = embedding_function(query_text)
        
        # Rechercher les embeddings similaires
        return self.search(
            query_vector=query_vector,
            limit=limit,
            filter=filter,
            collection_name=collection_name
        )
    
    def count(
        self,
        filter: Optional[Dict[str, Any]] = None,
        collection_name: Optional[str] = None
    ) -> int:
        """
        Compte le nombre d'embeddings dans une collection.
        
        Args:
            filter: Filtre pour sélectionner les embeddings à compter.
            collection_name: Nom de la collection (utilise la collection par défaut si None).
            
        Returns:
            Nombre d'embeddings.
        """
        collection = collection_name or self.default_collection
        
        # Récupérer les informations sur la collection
        info = self.storage_manager.get_collection_info(collection)
        
        # Si un filtre est spécifié, on ne peut pas utiliser le count global
        if filter:
            # TODO: Implémenter le comptage avec filtre
            # Pour l'instant, on retourne 0
            return 0
        
        # Retourner le nombre de points dans la collection
        return info.get("vectors_count", 0) if info else 0
