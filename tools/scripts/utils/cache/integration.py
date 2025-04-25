#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module d'intégration du cache dans l'application.

Ce module fournit des fonctions et des classes pour faciliter l'intégration
du cache dans différentes parties de l'application.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import json
import time
import hashlib
import inspect
import functools
from typing import Any, Dict, List, Optional, Tuple, Union, Callable, Type

# Importer les modules de cache
from scripts.utils.cache.local_cache import LocalCache
from scripts.utils.cache.decorators import cached, cached_property, cached_class, timed_cache, cache_result
from scripts.utils.cache.adapters.http_adapter import HttpCacheAdapter
from scripts.utils.cache.adapters.n8n_adapter import N8nCacheAdapter


class CacheManager:
    """
    Gestionnaire de cache pour l'application.
    
    Cette classe fournit un point d'accès centralisé pour toutes les fonctionnalités
    de cache de l'application.
    """
    
    _instance = None
    
    def __new__(cls, *args, **kwargs):
        """Implémentation du pattern Singleton."""
        if cls._instance is None:
            cls._instance = super(CacheManager, cls).__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def __init__(self, config_path: Optional[str] = None):
        """
        Initialise le gestionnaire de cache.
        
        Args:
            config_path (str, optional): Chemin vers un fichier de configuration JSON.
                Si None, utilise la configuration par défaut.
        """
        # Éviter l'initialisation multiple (pattern Singleton)
        if self._initialized:
            return
        
        self.config = {
            "cache_dir": "cache_dir",
            "default_ttl": 3600,
            "max_disk_size": 1000,  # Mo
            "eviction_policy": "LRU",
            "adapters": {
                "http": {
                    "default_ttl": 3600,
                    "methods_to_cache": ["GET", "HEAD"],
                    "status_codes_to_cache": [200]
                },
                "n8n": {
                    "default_ttl": 3600,
                    "base_url": "http://localhost:5678/webhook/",
                    "api_key": ""
                }
            }
        }
        
        # Charger la configuration si spécifiée
        if config_path and os.path.exists(config_path):
            try:
                with open(config_path, 'r', encoding='utf-8') as f:
                    loaded_config = json.load(f)
                
                # Fusionner la configuration chargée avec la configuration par défaut
                self._merge_config(self.config, loaded_config)
            except Exception as e:
                print(f"Erreur lors du chargement de la configuration: {e}")
        
        # Créer l'instance de cache principal
        self.cache = LocalCache(
            cache_dir=self.config["cache_dir"],
            config_path=config_path
        )
        
        # Créer les adaptateurs
        self.http_adapter = HttpCacheAdapter(self.cache, config_path)
        self.n8n_adapter = N8nCacheAdapter(self.cache, config_path)
        
        # Marquer comme initialisé
        self._initialized = True
    
    def _merge_config(self, base_config: Dict, new_config: Dict) -> None:
        """
        Fusionne deux configurations de manière récursive.
        
        Args:
            base_config (Dict): Configuration de base.
            new_config (Dict): Nouvelle configuration à fusionner.
        """
        for key, value in new_config.items():
            if key in base_config and isinstance(base_config[key], dict) and isinstance(value, dict):
                self._merge_config(base_config[key], value)
            else:
                base_config[key] = value
    
    def get_cache(self) -> LocalCache:
        """
        Récupère l'instance de cache principal.
        
        Returns:
            LocalCache: Instance de cache principal.
        """
        return self.cache
    
    def get_http_adapter(self) -> HttpCacheAdapter:
        """
        Récupère l'adaptateur HTTP.
        
        Returns:
            HttpCacheAdapter: Adaptateur HTTP.
        """
        return self.http_adapter
    
    def get_n8n_adapter(self) -> N8nCacheAdapter:
        """
        Récupère l'adaptateur n8n.
        
        Returns:
            N8nCacheAdapter: Adaptateur n8n.
        """
        return self.n8n_adapter
    
    def cached(self, ttl: Optional[int] = None, key_prefix: str = "") -> Callable:
        """
        Décorateur pour mettre en cache les résultats d'une fonction.
        
        Args:
            ttl (int, optional): Durée de vie du résultat en secondes.
                Si None, utilise la durée de vie par défaut du cache.
            key_prefix (str, optional): Préfixe pour la clé de cache.
        
        Returns:
            Callable: Décorateur de mise en cache.
        """
        return cached(ttl=ttl, key_prefix=key_prefix, cache_instance=self.cache)
    
    def cached_property(self, ttl: Optional[int] = None, key_prefix: str = "") -> Callable:
        """
        Décorateur pour mettre en cache les résultats d'une propriété.
        
        Args:
            ttl (int, optional): Durée de vie du résultat en secondes.
                Si None, utilise la durée de vie par défaut du cache.
            key_prefix (str, optional): Préfixe pour la clé de cache.
        
        Returns:
            Callable: Décorateur de mise en cache pour une propriété.
        """
        return cached_property(ttl=ttl, key_prefix=key_prefix, cache_instance=self.cache)
    
    def cached_class(self, ttl: Optional[int] = None, key_prefix: str = "") -> Callable:
        """
        Décorateur pour mettre en cache les instances d'une classe.
        
        Args:
            ttl (int, optional): Durée de vie du résultat en secondes.
                Si None, utilise la durée de vie par défaut du cache.
            key_prefix (str, optional): Préfixe pour la clé de cache.
        
        Returns:
            Callable: Décorateur de mise en cache pour une classe.
        """
        return cached_class(ttl=ttl, key_prefix=key_prefix, cache_instance=self.cache)
    
    def timed_cache(self, seconds: int = 60, maxsize: int = 128, typed: bool = False) -> Callable:
        """
        Décorateur pour mettre en cache les résultats d'une fonction pendant une durée limitée.
        
        Args:
            seconds (int, optional): Durée de vie du cache en secondes. Par défaut: 60.
            maxsize (int, optional): Nombre maximum d'entrées dans le cache. Par défaut: 128.
            typed (bool, optional): Si True, les arguments de différents types sont mis en cache séparément.
                Par défaut: False.
        
        Returns:
            Callable: Décorateur de mise en cache.
        """
        return timed_cache(seconds=seconds, maxsize=maxsize, typed=typed)
    
    def cache_result(self, result_key: Callable, ttl: Optional[int] = None) -> Callable:
        """
        Décorateur pour mettre en cache les résultats d'une fonction en utilisant une clé
        extraite du résultat lui-même.
        
        Args:
            result_key (Callable): Fonction qui extrait la clé de cache du résultat.
            ttl (int, optional): Durée de vie du résultat en secondes.
                Si None, utilise la durée de vie par défaut du cache.
        
        Returns:
            Callable: Décorateur de mise en cache.
        """
        return cache_result(result_key=result_key, ttl=ttl, cache_instance=self.cache)
    
    def clear(self) -> None:
        """Vide le cache."""
        self.cache.clear()
    
    def get_statistics(self) -> Dict[str, Any]:
        """
        Récupère les statistiques d'utilisation du cache.
        
        Returns:
            Dict[str, Any]: Dictionnaire contenant les statistiques d'utilisation.
        """
        return self.cache.get_statistics()


# Fonction utilitaire pour récupérer l'instance du gestionnaire de cache
def get_cache_manager(config_path: Optional[str] = None) -> CacheManager:
    """
    Récupère l'instance du gestionnaire de cache.
    
    Args:
        config_path (str, optional): Chemin vers un fichier de configuration JSON.
            Si None, utilise la configuration par défaut.
    
    Returns:
        CacheManager: Instance du gestionnaire de cache.
    """
    return CacheManager(config_path)


# Fonctions utilitaires pour faciliter l'utilisation du cache

def cached_function(ttl: Optional[int] = None, key_prefix: str = "") -> Callable:
    """
    Décorateur pour mettre en cache les résultats d'une fonction.
    
    Args:
        ttl (int, optional): Durée de vie du résultat en secondes.
            Si None, utilise la durée de vie par défaut du cache.
        key_prefix (str, optional): Préfixe pour la clé de cache.
    
    Returns:
        Callable: Décorateur de mise en cache.
    """
    cache_manager = get_cache_manager()
    return cache_manager.cached(ttl=ttl, key_prefix=key_prefix)


def cached_http_request(method: str, url: str, ttl: Optional[int] = None,
                       force_refresh: bool = False, **kwargs) -> Any:
    """
    Effectue une requête HTTP avec mise en cache.
    
    Args:
        method (str): Méthode HTTP (GET, POST, etc.).
        url (str): URL de la requête.
        ttl (int, optional): Durée de vie de la réponse en secondes.
            Si None, utilise la durée de vie déterminée à partir de la réponse.
        force_refresh (bool, optional): Si True, ignore le cache et force une nouvelle requête.
        **kwargs: Arguments supplémentaires à passer à requests.request().
    
    Returns:
        Any: Réponse HTTP (du cache ou fraîche).
    """
    cache_manager = get_cache_manager()
    http_adapter = cache_manager.get_http_adapter()
    return http_adapter.cached_request(method, url, ttl=ttl, force_refresh=force_refresh, **kwargs)


def cached_n8n_workflow(workflow_id: str, payload: Dict = None, ttl: Optional[int] = None,
                       force_refresh: bool = False) -> Dict:
    """
    Exécute un workflow n8n avec mise en cache.
    
    Args:
        workflow_id (str): Identifiant du workflow n8n.
        payload (Dict, optional): Données à envoyer au workflow.
        ttl (int, optional): Durée de vie de la réponse en secondes.
            Si None, utilise la durée de vie par défaut.
        force_refresh (bool, optional): Si True, ignore le cache et force une nouvelle exécution.
    
    Returns:
        Dict: Résultat de l'exécution du workflow (du cache ou frais).
    """
    cache_manager = get_cache_manager()
    n8n_adapter = cache_manager.get_n8n_adapter()
    return n8n_adapter.execute_workflow(workflow_id, payload, ttl=ttl, force_refresh=force_refresh)


def invalidate_cache(key: str) -> bool:
    """
    Invalide une entrée du cache.
    
    Args:
        key (str): Clé de cache à invalider.
    
    Returns:
        bool: True si l'entrée a été invalidée, False sinon.
    """
    cache_manager = get_cache_manager()
    return cache_manager.get_cache().delete(key)


def invalidate_http_cache(url: str, method: str = None) -> int:
    """
    Invalide toutes les entrées du cache pour une URL HTTP donnée.
    
    Args:
        url (str): URL à invalider.
        method (str, optional): Méthode HTTP à invalider. Si None, invalide toutes les méthodes.
    
    Returns:
        int: Nombre d'entrées invalidées.
    """
    cache_manager = get_cache_manager()
    http_adapter = cache_manager.get_http_adapter()
    return http_adapter.invalidate_url(url, method)


def invalidate_n8n_cache(workflow_id: str) -> bool:
    """
    Invalide toutes les entrées du cache pour un workflow n8n donné.
    
    Args:
        workflow_id (str): Identifiant du workflow n8n.
    
    Returns:
        bool: True si les entrées ont été invalidées, False sinon.
    """
    cache_manager = get_cache_manager()
    n8n_adapter = cache_manager.get_n8n_adapter()
    return n8n_adapter.invalidate_workflow(workflow_id)


def clear_all_caches() -> None:
    """Vide tous les caches."""
    cache_manager = get_cache_manager()
    cache_manager.clear()


def get_cache_statistics() -> Dict[str, Any]:
    """
    Récupère les statistiques d'utilisation du cache.
    
    Returns:
        Dict[str, Any]: Dictionnaire contenant les statistiques d'utilisation.
    """
    cache_manager = get_cache_manager()
    return cache_manager.get_statistics()


if __name__ == "__main__":
    # Exemple d'utilisation
    
    # Récupérer l'instance du gestionnaire de cache
    cache_manager = get_cache_manager()
    
    # Exemple avec le décorateur cached
    @cache_manager.cached(ttl=60)
    def expensive_function(param):
        print(f"Exécution de la fonction coûteuse avec param={param}")
        return param.upper()
    
    # Premier appel (exécute la fonction)
    result1 = expensive_function("test")
    print(f"Résultat 1: {result1}")
    
    # Deuxième appel (utilise le cache)
    result2 = expensive_function("test")
    print(f"Résultat 2: {result2}")
    
    # Exemple avec l'adaptateur HTTP
    http_adapter = cache_manager.get_http_adapter()
    response = http_adapter.get("https://jsonplaceholder.typicode.com/todos/1")
    print(f"Réponse HTTP: {response.json()}")
    
    # Deuxième appel (utilise le cache)
    response = http_adapter.get("https://jsonplaceholder.typicode.com/todos/1")
    print(f"Réponse HTTP (du cache): {response.json()}")
    
    # Afficher les statistiques
    stats = cache_manager.get_statistics()
    print(f"Statistiques du cache: {stats}")
