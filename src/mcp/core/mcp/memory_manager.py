#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module pour la gestion des mémoires MCP.

Ce module contient les classes et fonctions pour gérer les mémoires MCP,
notamment le stockage, la recherche et la gestion du cycle de vie des mémoires.
"""

import os
import sys
import logging
import json
import uuid
import time
from datetime import datetime
from typing import Any, Dict, List, Optional, Union, Tuple

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.core.memory_manager")

class Memory:
    """
    Classe représentant une mémoire.
    
    Une mémoire contient un contenu textuel, des métadonnées et un embedding vectoriel.
    """
    
    def __init__(
        self,
        content: str,
        metadata: Optional[Dict[str, Any]] = None,
        memory_id: Optional[str] = None,
        embedding: Optional[List[float]] = None
    ):
        """
        Initialise une mémoire.
        
        Args:
            content (str): Contenu textuel de la mémoire
            metadata (Optional[Dict[str, Any]], optional): Métadonnées de la mémoire. Par défaut None.
            memory_id (Optional[str], optional): Identifiant de la mémoire. Si None, un UUID est généré.
            embedding (Optional[List[float]], optional): Embedding vectoriel de la mémoire. Par défaut None.
        """
        self.content = content
        self.metadata = metadata or {}
        self.memory_id = memory_id or str(uuid.uuid4())
        self.embedding = embedding
        
        # Ajouter des métadonnées par défaut si elles n'existent pas
        if "created_at" not in self.metadata:
            self.metadata["created_at"] = datetime.now().isoformat()
        if "updated_at" not in self.metadata:
            self.metadata["updated_at"] = self.metadata["created_at"]
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Convertit la mémoire en dictionnaire.
        
        Returns:
            Dict[str, Any]: Dictionnaire représentant la mémoire
        """
        return {
            "memory_id": self.memory_id,
            "content": self.content,
            "metadata": self.metadata,
            "embedding": self.embedding
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Memory":
        """
        Crée une mémoire à partir d'un dictionnaire.
        
        Args:
            data (Dict[str, Any]): Dictionnaire représentant la mémoire
        
        Returns:
            Memory: Instance de mémoire
        """
        return cls(
            content=data["content"],
            metadata=data.get("metadata", {}),
            memory_id=data.get("memory_id"),
            embedding=data.get("embedding")
        )
    
    def update_content(self, content: str) -> None:
        """
        Met à jour le contenu de la mémoire.
        
        Args:
            content (str): Nouveau contenu
        """
        self.content = content
        self.metadata["updated_at"] = datetime.now().isoformat()
        # L'embedding doit être recalculé
        self.embedding = None
    
    def update_metadata(self, metadata: Dict[str, Any]) -> None:
        """
        Met à jour les métadonnées de la mémoire.
        
        Args:
            metadata (Dict[str, Any]): Nouvelles métadonnées à fusionner avec les existantes
        """
        self.metadata.update(metadata)
        self.metadata["updated_at"] = datetime.now().isoformat()

class MemoryManager:
    """
    Gestionnaire des mémoires MCP.
    
    Cette classe gère le stockage, la recherche et le cycle de vie des mémoires.
    """
    
    def __init__(self, storage_provider=None, embedding_provider=None):
        """
        Initialise le gestionnaire de mémoires.
        
        Args:
            storage_provider: Fournisseur de stockage pour les mémoires
            embedding_provider: Fournisseur d'embeddings pour les mémoires
        """
        self.storage_provider = storage_provider
        self.embedding_provider = embedding_provider
        self.memories = {}  # Stockage en mémoire par défaut
        logger.info("MemoryManager initialisé")
    
    def add_memory(self, content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Ajoute une nouvelle mémoire.
        
        Args:
            content (str): Contenu textuel de la mémoire
            metadata (Optional[Dict[str, Any]], optional): Métadonnées de la mémoire. Par défaut None.
        
        Returns:
            str: Identifiant de la mémoire ajoutée
        """
        # Créer une nouvelle mémoire
        memory = Memory(content=content, metadata=metadata)
        
        # Générer l'embedding si un fournisseur est disponible
        if self.embedding_provider:
            try:
                memory.embedding = self.embedding_provider.get_embedding(content)
            except Exception as e:
                logger.error(f"Erreur lors de la génération de l'embedding: {e}")
        
        # Stocker la mémoire
        if self.storage_provider:
            try:
                self.storage_provider.store_memory(memory)
            except Exception as e:
                logger.error(f"Erreur lors du stockage de la mémoire: {e}")
                # Fallback au stockage en mémoire
                self.memories[memory.memory_id] = memory
        else:
            # Stockage en mémoire
            self.memories[memory.memory_id] = memory
        
        logger.info(f"Mémoire '{memory.memory_id}' ajoutée")
        return memory.memory_id
    
    def get_memory(self, memory_id: str) -> Optional[Memory]:
        """
        Récupère une mémoire par son identifiant.
        
        Args:
            memory_id (str): Identifiant de la mémoire
        
        Returns:
            Optional[Memory]: Mémoire récupérée, ou None si elle n'existe pas
        """
        # Essayer de récupérer depuis le fournisseur de stockage
        if self.storage_provider:
            try:
                memory = self.storage_provider.get_memory(memory_id)
                if memory:
                    return memory
            except Exception as e:
                logger.error(f"Erreur lors de la récupération de la mémoire '{memory_id}': {e}")
        
        # Fallback au stockage en mémoire
        return self.memories.get(memory_id)
    
    def update_memory(self, memory_id: str, content: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None) -> bool:
        """
        Met à jour une mémoire existante.
        
        Args:
            memory_id (str): Identifiant de la mémoire
            content (Optional[str], optional): Nouveau contenu. Par défaut None.
            metadata (Optional[Dict[str, Any]], optional): Nouvelles métadonnées. Par défaut None.
        
        Returns:
            bool: True si la mise à jour a réussi, False sinon
        """
        # Récupérer la mémoire
        memory = self.get_memory(memory_id)
        if not memory:
            logger.error(f"Mémoire '{memory_id}' non trouvée pour la mise à jour")
            return False
        
        # Mettre à jour le contenu si fourni
        if content is not None:
            memory.update_content(content)
            
            # Regénérer l'embedding si un fournisseur est disponible
            if self.embedding_provider:
                try:
                    memory.embedding = self.embedding_provider.get_embedding(content)
                except Exception as e:
                    logger.error(f"Erreur lors de la génération de l'embedding: {e}")
        
        # Mettre à jour les métadonnées si fournies
        if metadata is not None:
            memory.update_metadata(metadata)
        
        # Stocker la mémoire mise à jour
        if self.storage_provider:
            try:
                self.storage_provider.update_memory(memory)
            except Exception as e:
                logger.error(f"Erreur lors de la mise à jour de la mémoire '{memory_id}': {e}")
                # Fallback au stockage en mémoire
                self.memories[memory_id] = memory
        else:
            # Stockage en mémoire
            self.memories[memory_id] = memory
        
        logger.info(f"Mémoire '{memory_id}' mise à jour")
        return True
    
    def delete_memory(self, memory_id: str) -> bool:
        """
        Supprime une mémoire.
        
        Args:
            memory_id (str): Identifiant de la mémoire
        
        Returns:
            bool: True si la suppression a réussi, False sinon
        """
        # Essayer de supprimer depuis le fournisseur de stockage
        if self.storage_provider:
            try:
                success = self.storage_provider.delete_memory(memory_id)
                if success:
                    # Supprimer également du stockage en mémoire si présent
                    if memory_id in self.memories:
                        del self.memories[memory_id]
                    logger.info(f"Mémoire '{memory_id}' supprimée")
                    return True
            except Exception as e:
                logger.error(f"Erreur lors de la suppression de la mémoire '{memory_id}': {e}")
        
        # Fallback au stockage en mémoire
        if memory_id in self.memories:
            del self.memories[memory_id]
            logger.info(f"Mémoire '{memory_id}' supprimée")
            return True
        
        logger.error(f"Mémoire '{memory_id}' non trouvée pour la suppression")
        return False
    
    def search_memories(self, query: str, limit: int = 10, metadata_filter: Optional[Dict[str, Any]] = None) -> List[Tuple[Memory, float]]:
        """
        Recherche des mémoires par similarité sémantique.
        
        Args:
            query (str): Requête de recherche
            limit (int, optional): Nombre maximum de résultats. Par défaut 10.
            metadata_filter (Optional[Dict[str, Any]], optional): Filtre sur les métadonnées. Par défaut None.
        
        Returns:
            List[Tuple[Memory, float]]: Liste de tuples (mémoire, score) triés par score décroissant
        """
        # Si un fournisseur d'embeddings est disponible, utiliser la recherche sémantique
        if self.embedding_provider and self.storage_provider and hasattr(self.storage_provider, "search_memories"):
            try:
                query_embedding = self.embedding_provider.get_embedding(query)
                return self.storage_provider.search_memories(query_embedding, limit, metadata_filter)
            except Exception as e:
                logger.error(f"Erreur lors de la recherche sémantique: {e}")
        
        # Fallback à la recherche par mots-clés dans le stockage en mémoire
        results = []
        query_lower = query.lower()
        
        for memory in self.memories.values():
            # Appliquer le filtre de métadonnées si fourni
            if metadata_filter and not self._match_metadata_filter(memory.metadata, metadata_filter):
                continue
            
            # Calculer un score simple basé sur la présence des mots de la requête dans le contenu
            content_lower = memory.content.lower()
            score = 0.0
            
            # Vérifier si le contenu contient la requête exacte
            if query_lower in content_lower:
                score = 0.8
            else:
                # Sinon, calculer un score basé sur le nombre de mots de la requête présents dans le contenu
                query_words = query_lower.split()
                content_words = set(content_lower.split())
                matching_words = sum(1 for word in query_words if word in content_words)
                if query_words:
                    score = 0.5 * (matching_words / len(query_words))
            
            if score > 0:
                results.append((memory, score))
        
        # Trier les résultats par score décroissant et limiter le nombre de résultats
        results.sort(key=lambda x: x[1], reverse=True)
        return results[:limit]
    
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
        # Si un fournisseur de stockage est disponible et qu'il a une méthode list_memories
        if self.storage_provider and hasattr(self.storage_provider, "list_memories"):
            try:
                return self.storage_provider.list_memories(metadata_filter, limit, offset)
            except Exception as e:
                logger.error(f"Erreur lors de la liste des mémoires: {e}")
        
        # Fallback au stockage en mémoire
        memories = list(self.memories.values())
        
        # Appliquer le filtre de métadonnées si fourni
        if metadata_filter:
            memories = [memory for memory in memories if self._match_metadata_filter(memory.metadata, metadata_filter)]
        
        # Appliquer la pagination
        return memories[offset:offset + limit]
