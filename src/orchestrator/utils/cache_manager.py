#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de gestion du cache.

Ce module fournit des fonctionnalités pour mettre en cache les résultats
des opérations coûteuses afin d'améliorer les performances.
"""

import os
import sys
import json
import hashlib
import time
import pickle
from typing import Dict, Any, Optional, Callable, TypeVar, cast
from pathlib import Path
from functools import wraps

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

# Type variable pour les fonctions décorées
T = TypeVar('T')

class CacheManager:
    """Gestionnaire de cache pour l'orchestrateur."""
    
    # Cache en mémoire
    _memory_cache: Dict[str, Dict[str, Any]] = {
        "data": {},
        "expiration": {}
    }
    
    # Répertoire de cache sur disque
    _cache_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".cache")
    
    @classmethod
    def initialize(cls, cache_dir: Optional[str] = None) -> None:
        """
        Initialise le gestionnaire de cache.
        
        Args:
            cache_dir: Répertoire de cache sur disque (optionnel)
        """
        if cache_dir:
            cls._cache_dir = cache_dir
        
        # Créer le répertoire de cache s'il n'existe pas
        os.makedirs(cls._cache_dir, exist_ok=True)
    
    @classmethod
    def get_cache_key(cls, func_name: str, args: tuple, kwargs: Dict[str, Any]) -> str:
        """
        Génère une clé de cache unique pour une fonction et ses arguments.
        
        Args:
            func_name: Nom de la fonction
            args: Arguments positionnels
            kwargs: Arguments nommés
            
        Returns:
            Clé de cache unique
        """
        # Convertir les arguments en chaîne JSON
        args_str = json.dumps(args, sort_keys=True, default=str)
        kwargs_str = json.dumps(kwargs, sort_keys=True, default=str)
        
        # Générer un hash SHA-256
        hash_input = f"{func_name}:{args_str}:{kwargs_str}"
        return hashlib.sha256(hash_input.encode()).hexdigest()
    
    @classmethod
    def get_from_memory_cache(cls, cache_key: str) -> Optional[Any]:
        """
        Récupère une valeur du cache en mémoire.
        
        Args:
            cache_key: Clé de cache
            
        Returns:
            Valeur mise en cache ou None si non trouvée ou expirée
        """
        if cache_key not in cls._memory_cache["data"]:
            return None
        
        # Vérifier si la valeur a expiré
        if cache_key in cls._memory_cache["expiration"]:
            expiration = cls._memory_cache["expiration"][cache_key]
            if expiration < time.time():
                # Supprimer la valeur expirée
                del cls._memory_cache["data"][cache_key]
                del cls._memory_cache["expiration"][cache_key]
                return None
        
        return cls._memory_cache["data"][cache_key]
    
    @classmethod
    def set_in_memory_cache(cls, cache_key: str, value: Any, ttl: int = 3600) -> None:
        """
        Stocke une valeur dans le cache en mémoire.
        
        Args:
            cache_key: Clé de cache
            value: Valeur à mettre en cache
            ttl: Durée de vie en secondes (défaut: 1 heure)
        """
        cls._memory_cache["data"][cache_key] = value
        cls._memory_cache["expiration"][cache_key] = time.time() + ttl
    
    @classmethod
    def get_from_disk_cache(cls, cache_key: str) -> Optional[Any]:
        """
        Récupère une valeur du cache sur disque.
        
        Args:
            cache_key: Clé de cache
            
        Returns:
            Valeur mise en cache ou None si non trouvée ou expirée
        """
        cache_file = os.path.join(cls._cache_dir, f"{cache_key}.pickle")
        
        if not os.path.exists(cache_file):
            return None
        
        try:
            with open(cache_file, "rb") as f:
                cache_data = pickle.load(f)
            
            # Vérifier si la valeur a expiré
            if "expiration" in cache_data and cache_data["expiration"] < time.time():
                # Supprimer le fichier de cache expiré
                os.remove(cache_file)
                return None
            
            return cache_data["value"]
        except Exception as e:
            print(f"Erreur lors du chargement du cache: {str(e)}")
            # En cas d'erreur, supprimer le fichier de cache corrompu
            if os.path.exists(cache_file):
                os.remove(cache_file)
            return None
    
    @classmethod
    def set_in_disk_cache(cls, cache_key: str, value: Any, ttl: int = 86400) -> None:
        """
        Stocke une valeur dans le cache sur disque.
        
        Args:
            cache_key: Clé de cache
            value: Valeur à mettre en cache
            ttl: Durée de vie en secondes (défaut: 24 heures)
        """
        cache_file = os.path.join(cls._cache_dir, f"{cache_key}.pickle")
        
        try:
            cache_data = {
                "value": value,
                "expiration": time.time() + ttl
            }
            
            with open(cache_file, "wb") as f:
                pickle.dump(cache_data, f)
        except Exception as e:
            print(f"Erreur lors de l'écriture du cache: {str(e)}")
            # En cas d'erreur, supprimer le fichier de cache corrompu
            if os.path.exists(cache_file):
                os.remove(cache_file)
    
    @classmethod
    def clear_memory_cache(cls) -> None:
        """Vide le cache en mémoire."""
        cls._memory_cache = {
            "data": {},
            "expiration": {}
        }
    
    @classmethod
    def clear_disk_cache(cls) -> None:
        """Vide le cache sur disque."""
        if os.path.exists(cls._cache_dir):
            for file_name in os.listdir(cls._cache_dir):
                if file_name.endswith(".pickle"):
                    os.remove(os.path.join(cls._cache_dir, file_name))
    
    @classmethod
    def clear_all_cache(cls) -> None:
        """Vide tous les caches."""
        cls.clear_memory_cache()
        cls.clear_disk_cache()

def cached(ttl_memory: int = 3600, ttl_disk: Optional[int] = 86400) -> Callable[[Callable[..., T]], Callable[..., T]]:
    """
    Décorateur pour mettre en cache les résultats d'une fonction.
    
    Args:
        ttl_memory: Durée de vie en mémoire en secondes (défaut: 1 heure)
        ttl_disk: Durée de vie sur disque en secondes (défaut: 24 heures, None pour désactiver)
        
    Returns:
        Fonction décorée
    """
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> T:
            # Générer la clé de cache
            cache_key = CacheManager.get_cache_key(func.__name__, args, kwargs)
            
            # Essayer de récupérer du cache en mémoire
            cached_value = CacheManager.get_from_memory_cache(cache_key)
            if cached_value is not None:
                return cast(T, cached_value)
            
            # Essayer de récupérer du cache sur disque
            if ttl_disk is not None:
                cached_value = CacheManager.get_from_disk_cache(cache_key)
                if cached_value is not None:
                    # Mettre également en cache en mémoire
                    CacheManager.set_in_memory_cache(cache_key, cached_value, ttl_memory)
                    return cast(T, cached_value)
            
            # Exécuter la fonction
            result = func(*args, **kwargs)
            
            # Mettre en cache en mémoire
            CacheManager.set_in_memory_cache(cache_key, result, ttl_memory)
            
            # Mettre en cache sur disque
            if ttl_disk is not None:
                CacheManager.set_in_disk_cache(cache_key, result, ttl_disk)
            
            return result
        
        return wrapper
    
    return decorator

# Initialiser le gestionnaire de cache
CacheManager.initialize()
