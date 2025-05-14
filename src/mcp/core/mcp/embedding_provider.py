#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module pour les fournisseurs d'embeddings.

Ce module contient les interfaces et implémentations pour les fournisseurs d'embeddings.
"""

import os
import sys
import logging
import json
import hashlib
from typing import Any, Dict, List, Optional, Protocol, runtime_checkable

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.core.embedding_provider")

@runtime_checkable
class EmbeddingProvider(Protocol):
    """
    Interface pour les fournisseurs d'embeddings.
    """
    
    def get_embedding(self, text: str) -> List[float]:
        """
        Génère un embedding pour un texte.
        
        Args:
            text (str): Texte à encoder
        
        Returns:
            List[float]: Embedding vectoriel
        """
        ...
    
    def get_embeddings(self, texts: List[str]) -> List[List[float]]:
        """
        Génère des embeddings pour une liste de textes.
        
        Args:
            texts (List[str]): Liste de textes à encoder
        
        Returns:
            List[List[float]]: Liste d'embeddings vectoriels
        """
        ...

class DummyEmbeddingProvider:
    """
    Fournisseur d'embeddings factice pour les tests.
    
    Ce fournisseur génère des embeddings déterministes basés sur le hachage du texte.
    """
    
    def __init__(self, dimension: int = 128):
        """
        Initialise le fournisseur d'embeddings.
        
        Args:
            dimension (int, optional): Dimension des embeddings. Par défaut 128.
        """
        self.dimension = dimension
        logger.info(f"DummyEmbeddingProvider initialisé avec dimension {dimension}")
    
    def get_embedding(self, text: str) -> List[float]:
        """
        Génère un embedding déterministe pour un texte.
        
        Args:
            text (str): Texte à encoder
        
        Returns:
            List[float]: Embedding vectoriel
        """
        # Générer un hash du texte
        hash_obj = hashlib.sha256(text.encode("utf-8"))
        hash_bytes = hash_obj.digest()
        
        # Convertir le hash en une liste de flottants
        embedding = []
        for i in range(self.dimension):
            # Utiliser des bytes du hash pour générer des valeurs entre -1 et 1
            byte_index = i % len(hash_bytes)
            value = (hash_bytes[byte_index] / 128.0) - 1.0
            embedding.append(value)
        
        # Normaliser l'embedding
        norm = sum(x * x for x in embedding) ** 0.5
        if norm > 0:
            embedding = [x / norm for x in embedding]
        
        return embedding
    
    def get_embeddings(self, texts: List[str]) -> List[List[float]]:
        """
        Génère des embeddings pour une liste de textes.
        
        Args:
            texts (List[str]): Liste de textes à encoder
        
        Returns:
            List[List[float]]: Liste d'embeddings vectoriels
        """
        return [self.get_embedding(text) for text in texts]

class CachedEmbeddingProvider:
    """
    Fournisseur d'embeddings avec cache.
    
    Ce fournisseur utilise un autre fournisseur d'embeddings et met en cache les résultats.
    """
    
    def __init__(self, provider: EmbeddingProvider, cache_dir: Optional[str] = None):
        """
        Initialise le fournisseur d'embeddings avec cache.
        
        Args:
            provider (EmbeddingProvider): Fournisseur d'embeddings sous-jacent
            cache_dir (Optional[str], optional): Répertoire de cache. Par défaut None (cache en mémoire).
        """
        self.provider = provider
        self.cache_dir = cache_dir
        self.memory_cache = {}
        
        # Créer le répertoire de cache s'il est spécifié et n'existe pas
        if cache_dir:
            os.makedirs(cache_dir, exist_ok=True)
        
        logger.info(f"CachedEmbeddingProvider initialisé avec cache_dir '{cache_dir}'")
    
    def _get_cache_key(self, text: str) -> str:
        """
        Génère une clé de cache pour un texte.
        
        Args:
            text (str): Texte
        
        Returns:
            str: Clé de cache
        """
        return hashlib.md5(text.encode("utf-8")).hexdigest()
    
    def _get_cache_path(self, cache_key: str) -> str:
        """
        Retourne le chemin du fichier de cache pour une clé.
        
        Args:
            cache_key (str): Clé de cache
        
        Returns:
            str: Chemin du fichier de cache
        """
        return os.path.join(self.cache_dir, f"{cache_key}.json")
    
    def get_embedding(self, text: str) -> List[float]:
        """
        Génère un embedding pour un texte, en utilisant le cache si disponible.
        
        Args:
            text (str): Texte à encoder
        
        Returns:
            List[float]: Embedding vectoriel
        """
        cache_key = self._get_cache_key(text)
        
        # Vérifier le cache en mémoire
        if cache_key in self.memory_cache:
            logger.debug(f"Embedding trouvé dans le cache en mémoire pour la clé '{cache_key}'")
            return self.memory_cache[cache_key]
        
        # Vérifier le cache sur disque si un répertoire de cache est spécifié
        if self.cache_dir:
            cache_path = self._get_cache_path(cache_key)
            if os.path.exists(cache_path):
                try:
                    with open(cache_path, "r", encoding="utf-8") as f:
                        embedding = json.load(f)
                    logger.debug(f"Embedding trouvé dans le cache sur disque pour la clé '{cache_key}'")
                    
                    # Mettre en cache en mémoire
                    self.memory_cache[cache_key] = embedding
                    
                    return embedding
                except Exception as e:
                    logger.error(f"Erreur lors de la lecture du cache pour la clé '{cache_key}': {e}")
        
        # Générer l'embedding
        embedding = self.provider.get_embedding(text)
        
        # Mettre en cache en mémoire
        self.memory_cache[cache_key] = embedding
        
        # Mettre en cache sur disque si un répertoire de cache est spécifié
        if self.cache_dir:
            cache_path = self._get_cache_path(cache_key)
            try:
                with open(cache_path, "w", encoding="utf-8") as f:
                    json.dump(embedding, f, ensure_ascii=False)
                logger.debug(f"Embedding mis en cache sur disque pour la clé '{cache_key}'")
            except Exception as e:
                logger.error(f"Erreur lors de l'écriture du cache pour la clé '{cache_key}': {e}")
        
        return embedding
    
    def get_embeddings(self, texts: List[str]) -> List[List[float]]:
        """
        Génère des embeddings pour une liste de textes, en utilisant le cache si disponible.
        
        Args:
            texts (List[str]): Liste de textes à encoder
        
        Returns:
            List[List[float]]: Liste d'embeddings vectoriels
        """
        # Vérifier quels textes sont déjà en cache
        cache_keys = [self._get_cache_key(text) for text in texts]
        cached_embeddings = {}
        
        # Vérifier le cache en mémoire
        for i, cache_key in enumerate(cache_keys):
            if cache_key in self.memory_cache:
                cached_embeddings[i] = self.memory_cache[cache_key]
        
        # Vérifier le cache sur disque pour les textes non trouvés en mémoire
        if self.cache_dir:
            for i, cache_key in enumerate(cache_keys):
                if i not in cached_embeddings:
                    cache_path = self._get_cache_path(cache_key)
                    if os.path.exists(cache_path):
                        try:
                            with open(cache_path, "r", encoding="utf-8") as f:
                                embedding = json.load(f)
                            
                            # Mettre en cache en mémoire
                            self.memory_cache[cache_key] = embedding
                            
                            cached_embeddings[i] = embedding
                        except Exception as e:
                            logger.error(f"Erreur lors de la lecture du cache pour la clé '{cache_key}': {e}")
        
        # Générer les embeddings pour les textes non trouvés en cache
        uncached_texts = [texts[i] for i in range(len(texts)) if i not in cached_embeddings]
        uncached_indices = [i for i in range(len(texts)) if i not in cached_embeddings]
        
        if uncached_texts:
            uncached_embeddings = self.provider.get_embeddings(uncached_texts)
            
            # Mettre en cache les nouveaux embeddings
            for i, embedding in zip(uncached_indices, uncached_embeddings):
                cache_key = cache_keys[i]
                
                # Mettre en cache en mémoire
                self.memory_cache[cache_key] = embedding
                
                # Mettre en cache sur disque si un répertoire de cache est spécifié
                if self.cache_dir:
                    cache_path = self._get_cache_path(cache_key)
                    try:
                        with open(cache_path, "w", encoding="utf-8") as f:
                            json.dump(embedding, f, ensure_ascii=False)
                    except Exception as e:
                        logger.error(f"Erreur lors de l'écriture du cache pour la clé '{cache_key}': {e}")
                
                cached_embeddings[i] = embedding
        
        # Reconstruire la liste d'embeddings dans l'ordre original
        return [cached_embeddings[i] for i in range(len(texts))]
