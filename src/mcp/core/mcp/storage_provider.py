#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module pour les fournisseurs de stockage vectoriel.

Ce module contient les interfaces et implémentations pour les fournisseurs de stockage vectoriel.
"""

import os
import sys
import logging
import json
import abc
from typing import Any, Dict, List, Optional, Tuple, Protocol, runtime_checkable

# Import local
from .memory_manager import Memory

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.core.storage_provider")

@runtime_checkable
class StorageProvider(Protocol):
    """
    Interface pour les fournisseurs de stockage vectoriel.
    """
    
    def store_memory(self, memory: Memory) -> bool:
        """
        Stocke une mémoire.
        
        Args:
            memory (Memory): Mémoire à stocker
        
        Returns:
            bool: True si le stockage a réussi, False sinon
        """
        ...
    
    def get_memory(self, memory_id: str) -> Optional[Memory]:
        """
        Récupère une mémoire par son identifiant.
        
        Args:
            memory_id (str): Identifiant de la mémoire
        
        Returns:
            Optional[Memory]: Mémoire récupérée, ou None si elle n'existe pas
        """
        ...
    
    def update_memory(self, memory: Memory) -> bool:
        """
        Met à jour une mémoire existante.
        
        Args:
            memory (Memory): Mémoire à mettre à jour
        
        Returns:
            bool: True si la mise à jour a réussi, False sinon
        """
        ...
    
    def delete_memory(self, memory_id: str) -> bool:
        """
        Supprime une mémoire.
        
        Args:
            memory_id (str): Identifiant de la mémoire
        
        Returns:
            bool: True si la suppression a réussi, False sinon
        """
        ...
    
    def search_memories(self, query_embedding: List[float], limit: int = 10, metadata_filter: Optional[Dict[str, Any]] = None) -> List[Tuple[Memory, float]]:
        """
        Recherche des mémoires par similarité sémantique.
        
        Args:
            query_embedding (List[float]): Embedding de la requête
            limit (int, optional): Nombre maximum de résultats. Par défaut 10.
            metadata_filter (Optional[Dict[str, Any]], optional): Filtre sur les métadonnées. Par défaut None.
        
        Returns:
            List[Tuple[Memory, float]]: Liste de tuples (mémoire, score) triés par score décroissant
        """
        ...
    
    def list_memories(self, metadata_filter: Optional[Dict[str, Any]] = None, limit: int = 100, offset: int = 0) -> List[Memory]:
        """
        Liste les mémoires, éventuellement filtrées par métadonnées.
        
        Args:
            metadata_filter (Optional[Dict[str, Any]], optional): Filtre sur les métadonnées. Par défaut None.
            limit (int, optional): Nombre maximum de résultats. Par défaut 100.
            offset (int, optional): Décalage pour la pagination. Par défaut 0.
        
        Returns:
            List[Memory]: Liste des mémoires
        """
        ...

class FileStorageProvider:
    """
    Fournisseur de stockage vectoriel basé sur des fichiers.
    
    Ce fournisseur stocke les mémoires dans des fichiers JSON.
    """
    
    def __init__(self, storage_dir: str):
        """
        Initialise le fournisseur de stockage.
        
        Args:
            storage_dir (str): Répertoire de stockage des mémoires
        """
        self.storage_dir = storage_dir
        
        # Créer le répertoire de stockage s'il n'existe pas
        os.makedirs(storage_dir, exist_ok=True)
        
        logger.info(f"FileStorageProvider initialisé avec le répertoire '{storage_dir}'")
    
    def _get_memory_path(self, memory_id: str) -> str:
        """
        Retourne le chemin du fichier pour une mémoire.
        
        Args:
            memory_id (str): Identifiant de la mémoire
        
        Returns:
            str: Chemin du fichier
        """
        return os.path.join(self.storage_dir, f"{memory_id}.json")
    
    def store_memory(self, memory: Memory) -> bool:
        """
        Stocke une mémoire dans un fichier JSON.
        
        Args:
            memory (Memory): Mémoire à stocker
        
        Returns:
            bool: True si le stockage a réussi, False sinon
        """
        try:
            memory_path = self._get_memory_path(memory.memory_id)
            with open(memory_path, "w", encoding="utf-8") as f:
                json.dump(memory.to_dict(), f, ensure_ascii=False, indent=2)
            logger.info(f"Mémoire '{memory.memory_id}' stockée dans '{memory_path}'")
            return True
        except Exception as e:
            logger.error(f"Erreur lors du stockage de la mémoire '{memory.memory_id}': {e}")
            return False
    
    def get_memory(self, memory_id: str) -> Optional[Memory]:
        """
        Récupère une mémoire depuis un fichier JSON.
        
        Args:
            memory_id (str): Identifiant de la mémoire
        
        Returns:
            Optional[Memory]: Mémoire récupérée, ou None si elle n'existe pas
        """
        memory_path = self._get_memory_path(memory_id)
        if not os.path.exists(memory_path):
            logger.warning(f"Mémoire '{memory_id}' non trouvée dans '{memory_path}'")
            return None
        
        try:
            with open(memory_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            logger.info(f"Mémoire '{memory_id}' récupérée depuis '{memory_path}'")
            return Memory.from_dict(data)
        except Exception as e:
            logger.error(f"Erreur lors de la récupération de la mémoire '{memory_id}': {e}")
            return None
    
    def update_memory(self, memory: Memory) -> bool:
        """
        Met à jour une mémoire existante.
        
        Args:
            memory (Memory): Mémoire à mettre à jour
        
        Returns:
            bool: True si la mise à jour a réussi, False sinon
        """
        # La mise à jour est identique au stockage pour ce fournisseur
        return self.store_memory(memory)
    
    def delete_memory(self, memory_id: str) -> bool:
        """
        Supprime une mémoire.
        
        Args:
            memory_id (str): Identifiant de la mémoire
        
        Returns:
            bool: True si la suppression a réussi, False sinon
        """
        memory_path = self._get_memory_path(memory_id)
        if not os.path.exists(memory_path):
            logger.warning(f"Mémoire '{memory_id}' non trouvée dans '{memory_path}' pour la suppression")
            return False
        
        try:
            os.remove(memory_path)
            logger.info(f"Mémoire '{memory_id}' supprimée de '{memory_path}'")
            return True
        except Exception as e:
            logger.error(f"Erreur lors de la suppression de la mémoire '{memory_id}': {e}")
            return False
    
    def search_memories(self, query_embedding: List[float], limit: int = 10, metadata_filter: Optional[Dict[str, Any]] = None) -> List[Tuple[Memory, float]]:
        """
        Recherche des mémoires par similarité sémantique.
        
        Note: Cette implémentation est très basique et ne fait pas de recherche vectorielle.
        Elle charge toutes les mémoires et calcule la similarité cosinus en mémoire.
        
        Args:
            query_embedding (List[float]): Embedding de la requête
            limit (int, optional): Nombre maximum de résultats. Par défaut 10.
            metadata_filter (Optional[Dict[str, Any]], optional): Filtre sur les métadonnées. Par défaut None.
        
        Returns:
            List[Tuple[Memory, float]]: Liste de tuples (mémoire, score) triés par score décroissant
        """
        # Charger toutes les mémoires
        memories = self.list_memories(metadata_filter=metadata_filter)
        
        # Filtrer les mémoires qui ont un embedding
        memories_with_embedding = [memory for memory in memories if memory.embedding is not None]
        
        # Calculer la similarité cosinus pour chaque mémoire
        results = []
        for memory in memories_with_embedding:
            score = self._cosine_similarity(query_embedding, memory.embedding)
            results.append((memory, score))
        
        # Trier les résultats par score décroissant et limiter le nombre de résultats
        results.sort(key=lambda x: x[1], reverse=True)
        return results[:limit]
    
    def _cosine_similarity(self, vec1: List[float], vec2: List[float]) -> float:
        """
        Calcule la similarité cosinus entre deux vecteurs.
        
        Args:
            vec1 (List[float]): Premier vecteur
            vec2 (List[float]): Deuxième vecteur
        
        Returns:
            float: Similarité cosinus
        """
        if not vec1 or not vec2 or len(vec1) != len(vec2):
            return 0.0
        
        dot_product = sum(a * b for a, b in zip(vec1, vec2))
        magnitude1 = sum(a * a for a in vec1) ** 0.5
        magnitude2 = sum(b * b for b in vec2) ** 0.5
        
        if magnitude1 == 0 or magnitude2 == 0:
            return 0.0
        
        return dot_product / (magnitude1 * magnitude2)
    
    def list_memories(self, metadata_filter: Optional[Dict[str, Any]] = None, limit: int = 100, offset: int = 0) -> List[Memory]:
        """
        Liste les mémoires, éventuellement filtrées par métadonnées.
        
        Args:
            metadata_filter (Optional[Dict[str, Any]], optional): Filtre sur les métadonnées. Par défaut None.
            limit (int, optional): Nombre maximum de résultats. Par défaut 100.
            offset (int, optional): Décalage pour la pagination. Par défaut 0.
        
        Returns:
            List[Memory]: Liste des mémoires
        """
        # Lister tous les fichiers JSON dans le répertoire de stockage
        memory_files = [f for f in os.listdir(self.storage_dir) if f.endswith(".json")]
        
        # Charger toutes les mémoires
        memories = []
        for memory_file in memory_files:
            memory_id = os.path.splitext(memory_file)[0]
            memory = self.get_memory(memory_id)
            if memory:
                memories.append(memory)
        
        # Appliquer le filtre de métadonnées si fourni
        if metadata_filter:
            memories = self._filter_memories_by_metadata(memories, metadata_filter)
        
        # Appliquer la pagination
        return memories[offset:offset + limit]
    
    def _filter_memories_by_metadata(self, memories: List[Memory], metadata_filter: Dict[str, Any]) -> List[Memory]:
        """
        Filtre les mémoires par métadonnées.
        
        Args:
            memories (List[Memory]): Liste des mémoires à filtrer
            metadata_filter (Dict[str, Any]): Filtre sur les métadonnées
        
        Returns:
            List[Memory]: Liste des mémoires filtrées
        """
        filtered_memories = []
        for memory in memories:
            if self._match_metadata_filter(memory.metadata, metadata_filter):
                filtered_memories.append(memory)
        return filtered_memories
    
    def _match_metadata_filter(self, metadata: Dict[str, Any], metadata_filter: Dict[str, Any]) -> bool:
        """
        Vérifie si les métadonnées correspondent au filtre.
        
        Args:
            metadata (Dict[str, Any]): Métadonnées à vérifier
            metadata_filter (Dict[str, Any]): Filtre à appliquer
        
        Returns:
            bool: True si les métadonnées correspondent au filtre, False sinon
        """
        for key, value in metadata_filter.items():
            if key not in metadata:
                return False
            
            if isinstance(value, dict) and isinstance(metadata[key], dict):
                # Récursion pour les dictionnaires imbriqués
                if not self._match_metadata_filter(metadata[key], value):
                    return False
            elif metadata[key] != value:
                return False
        
        return True
