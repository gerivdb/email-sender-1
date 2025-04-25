#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de cache parallèle.

Ce module fournit des implémentations de cache qui supportent
les opérations concurrentes pour améliorer les performances.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import time
import json
import logging
import threading
import multiprocessing
from typing import Dict, List, Any, Optional, Tuple, Callable, TypeVar, Generic, Union
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor

# Importer le module de cache local
from scripts.utils.cache.local_cache import LocalCache

# Configurer le logger
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Type générique pour les valeurs
T = TypeVar('T')


class ThreadSafeCache:
    """
    Cache thread-safe qui utilise un verrou pour synchroniser les accès.
    
    Cette classe encapsule un cache LocalCache et utilise un verrou
    pour garantir la sécurité des accès concurrents.
    """
    
    def __init__(self, cache_dir: str = 'cache_dir', config_path: Optional[str] = None):
        """
        Initialise le cache thread-safe.
        
        Args:
            cache_dir (str): Chemin du répertoire de cache. Par défaut: 'cache_dir'.
            config_path (str, optional): Chemin vers un fichier de configuration JSON.
                Si fourni, les paramètres du fichier de configuration seront utilisés.
        """
        self.cache = LocalCache(cache_dir, config_path)
        self.lock = threading.RLock()  # Verrou réentrant
    
    def get(self, key: str, default: Any = None) -> Any:
        """
        Récupère une valeur du cache de manière thread-safe.
        
        Args:
            key (str): Clé de l'élément à récupérer.
            default (Any, optional): Valeur à retourner si la clé n'existe pas.
                Par défaut: None.
                
        Returns:
            Any: Valeur associée à la clé ou valeur par défaut si la clé n'existe pas.
        """
        with self.lock:
            return self.cache.get(key, default)
    
    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> None:
        """
        Stocke une valeur dans le cache de manière thread-safe.
        
        Args:
            key (str): Clé de l'élément à stocker.
            value (Any): Valeur de l'élément à stocker.
            ttl (int, optional): Durée de vie de l'élément en secondes.
                Si None, utilise la durée de vie par défaut du cache.
        """
        with self.lock:
            self.cache.set(key, value, ttl)
    
    def delete(self, key: str) -> bool:
        """
        Supprime un élément du cache de manière thread-safe.
        
        Args:
            key (str): Clé de l'élément à supprimer.
            
        Returns:
            bool: True si l'élément a été supprimé, False sinon.
        """
        with self.lock:
            return self.cache.delete(key)
    
    def clear(self) -> None:
        """Vide le cache de manière thread-safe."""
        with self.lock:
            self.cache.clear()
    
    def get_statistics(self) -> Dict[str, Any]:
        """
        Récupère les statistiques d'utilisation du cache de manière thread-safe.
        
        Returns:
            Dict[str, Any]: Dictionnaire contenant les statistiques d'utilisation.
        """
        with self.lock:
            return self.cache.get_statistics()
    
    def __enter__(self):
        """Entre dans le gestionnaire de contexte."""
        return self
    
    def __exit__(self, exc_type=None, exc_val=None, exc_tb=None):
        """Sort du gestionnaire de contexte."""
        self.cache.__exit__(exc_type, exc_val, exc_tb)
        return False  # Ne pas supprimer l'exception


class ShardedCache:
    """
    Cache partitionné qui distribue les clés sur plusieurs caches.
    
    Cette classe utilise plusieurs instances de LocalCache pour
    répartir la charge et améliorer les performances.
    """
    
    def __init__(self, shards: int = 4, cache_dir: str = 'cache_dir', config_path: Optional[str] = None):
        """
        Initialise le cache partitionné.
        
        Args:
            shards (int, optional): Nombre de partitions. Par défaut: 4.
            cache_dir (str): Chemin du répertoire de cache. Par défaut: 'cache_dir'.
            config_path (str, optional): Chemin vers un fichier de configuration JSON.
                Si fourni, les paramètres du fichier de configuration seront utilisés.
        """
        self.shards = shards
        self.caches = []
        
        # Créer les partitions
        for i in range(shards):
            shard_dir = os.path.join(cache_dir, f"shard_{i}")
            self.caches.append(ThreadSafeCache(shard_dir, config_path))
    
    def _get_shard(self, key: str) -> ThreadSafeCache:
        """
        Détermine la partition à utiliser pour une clé.
        
        Args:
            key (str): Clé de l'élément.
            
        Returns:
            ThreadSafeCache: Partition à utiliser.
        """
        # Utiliser un hachage simple pour répartir les clés
        shard_index = hash(key) % self.shards
        return self.caches[shard_index]
    
    def get(self, key: str, default: Any = None) -> Any:
        """
        Récupère une valeur du cache.
        
        Args:
            key (str): Clé de l'élément à récupérer.
            default (Any, optional): Valeur à retourner si la clé n'existe pas.
                Par défaut: None.
                
        Returns:
            Any: Valeur associée à la clé ou valeur par défaut si la clé n'existe pas.
        """
        shard = self._get_shard(key)
        return shard.get(key, default)
    
    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> None:
        """
        Stocke une valeur dans le cache.
        
        Args:
            key (str): Clé de l'élément à stocker.
            value (Any): Valeur de l'élément à stocker.
            ttl (int, optional): Durée de vie de l'élément en secondes.
                Si None, utilise la durée de vie par défaut du cache.
        """
        shard = self._get_shard(key)
        shard.set(key, value, ttl)
    
    def delete(self, key: str) -> bool:
        """
        Supprime un élément du cache.
        
        Args:
            key (str): Clé de l'élément à supprimer.
            
        Returns:
            bool: True si l'élément a été supprimé, False sinon.
        """
        shard = self._get_shard(key)
        return shard.delete(key)
    
    def clear(self) -> None:
        """Vide toutes les partitions du cache."""
        for shard in self.caches:
            shard.clear()
    
    def get_statistics(self) -> Dict[str, Any]:
        """
        Récupère les statistiques d'utilisation de toutes les partitions.
        
        Returns:
            Dict[str, Any]: Dictionnaire contenant les statistiques d'utilisation.
        """
        # Initialiser les statistiques combinées
        combined_stats = {
            "size": 0,
            "count": 0,
            "hits": 0,
            "misses": 0,
            "sets": 0,
            "deletes": 0,
            "evictions": 0
        }
        
        # Agréger les statistiques de toutes les partitions
        for shard in self.caches:
            stats = shard.get_statistics()
            for key in combined_stats:
                if key in stats:
                    combined_stats[key] += stats[key]
        
        # Calculer le taux de succès
        total_requests = combined_stats["hits"] + combined_stats["misses"]
        combined_stats["hit_ratio"] = combined_stats["hits"] / total_requests if total_requests > 0 else 0
        
        # Ajouter des informations sur les partitions
        combined_stats["shards"] = self.shards
        
        return combined_stats
    
    def __enter__(self):
        """Entre dans le gestionnaire de contexte."""
        return self
    
    def __exit__(self, exc_type=None, exc_val=None, exc_tb=None):
        """Sort du gestionnaire de contexte."""
        for shard in self.caches:
            shard.__exit__(exc_type, exc_val, exc_tb)
        return False  # Ne pas supprimer l'exception


class AsyncCache:
    """
    Cache asynchrone qui effectue certaines opérations en arrière-plan.
    
    Cette classe utilise un pool de threads pour effectuer les opérations
    d'écriture en arrière-plan, ce qui permet de réduire la latence.
    """
    
    def __init__(self, cache_dir: str = 'cache_dir', config_path: Optional[str] = None, max_workers: int = 4):
        """
        Initialise le cache asynchrone.
        
        Args:
            cache_dir (str): Chemin du répertoire de cache. Par défaut: 'cache_dir'.
            config_path (str, optional): Chemin vers un fichier de configuration JSON.
                Si fourni, les paramètres du fichier de configuration seront utilisés.
            max_workers (int, optional): Nombre maximum de threads. Par défaut: 4.
        """
        self.cache = ThreadSafeCache(cache_dir, config_path)
        self.executor = ThreadPoolExecutor(max_workers=max_workers)
        self.futures = []
    
    def get(self, key: str, default: Any = None) -> Any:
        """
        Récupère une valeur du cache.
        
        Args:
            key (str): Clé de l'élément à récupérer.
            default (Any, optional): Valeur à retourner si la clé n'existe pas.
                Par défaut: None.
                
        Returns:
            Any: Valeur associée à la clé ou valeur par défaut si la clé n'existe pas.
        """
        # Les opérations de lecture sont synchrones
        return self.cache.get(key, default)
    
    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> None:
        """
        Stocke une valeur dans le cache de manière asynchrone.
        
        Args:
            key (str): Clé de l'élément à stocker.
            value (Any): Valeur de l'élément à stocker.
            ttl (int, optional): Durée de vie de l'élément en secondes.
                Si None, utilise la durée de vie par défaut du cache.
        """
        # Soumettre l'opération d'écriture au pool de threads
        future = self.executor.submit(self.cache.set, key, value, ttl)
        self.futures.append(future)
        
        # Nettoyer les futures terminés
        self.futures = [f for f in self.futures if not f.done()]
    
    def set_sync(self, key: str, value: Any, ttl: Optional[int] = None) -> None:
        """
        Stocke une valeur dans le cache de manière synchrone.
        
        Args:
            key (str): Clé de l'élément à stocker.
            value (Any): Valeur de l'élément à stocker.
            ttl (int, optional): Durée de vie de l'élément en secondes.
                Si None, utilise la durée de vie par défaut du cache.
        """
        # Opération d'écriture synchrone
        self.cache.set(key, value, ttl)
    
    def delete(self, key: str) -> bool:
        """
        Supprime un élément du cache de manière asynchrone.
        
        Args:
            key (str): Clé de l'élément à supprimer.
            
        Returns:
            bool: True si l'élément existe, False sinon.
                Note: L'opération de suppression est asynchrone, donc le retour
                indique seulement si la clé existe, pas si la suppression a réussi.
        """
        # Vérifier si la clé existe
        exists = key in self.cache.cache.cache
        
        if exists:
            # Soumettre l'opération de suppression au pool de threads
            future = self.executor.submit(self.cache.delete, key)
            self.futures.append(future)
            
            # Nettoyer les futures terminés
            self.futures = [f for f in self.futures if not f.done()]
        
        return exists
    
    def delete_sync(self, key: str) -> bool:
        """
        Supprime un élément du cache de manière synchrone.
        
        Args:
            key (str): Clé de l'élément à supprimer.
            
        Returns:
            bool: True si l'élément a été supprimé, False sinon.
        """
        # Opération de suppression synchrone
        return self.cache.delete(key)
    
    def clear(self) -> None:
        """Vide le cache de manière synchrone."""
        # Attendre que toutes les opérations en cours soient terminées
        for future in self.futures:
            future.result()
        
        # Vider le cache
        self.cache.clear()
        self.futures = []
    
    def get_statistics(self) -> Dict[str, Any]:
        """
        Récupère les statistiques d'utilisation du cache.
        
        Returns:
            Dict[str, Any]: Dictionnaire contenant les statistiques d'utilisation.
        """
        stats = self.cache.get_statistics()
        stats["pending_operations"] = len(self.futures)
        return stats
    
    def wait_for_all(self) -> None:
        """Attend que toutes les opérations asynchrones soient terminées."""
        for future in self.futures:
            future.result()
        self.futures = []
    
    def __enter__(self):
        """Entre dans le gestionnaire de contexte."""
        return self
    
    def __exit__(self, exc_type=None, exc_val=None, exc_tb=None):
        """Sort du gestionnaire de contexte."""
        # Attendre que toutes les opérations en cours soient terminées
        self.wait_for_all()
        
        # Fermer l'executor
        self.executor.shutdown(wait=True)
        
        # Fermer le cache
        self.cache.__exit__(exc_type, exc_val, exc_tb)
        return False  # Ne pas supprimer l'exception


class BatchCache:
    """
    Cache qui supporte les opérations par lots.
    
    Cette classe permet d'effectuer des opérations sur plusieurs clés
    en une seule fois, ce qui améliore les performances.
    """
    
    def __init__(self, cache_dir: str = 'cache_dir', config_path: Optional[str] = None, max_workers: int = 4):
        """
        Initialise le cache par lots.
        
        Args:
            cache_dir (str): Chemin du répertoire de cache. Par défaut: 'cache_dir'.
            config_path (str, optional): Chemin vers un fichier de configuration JSON.
                Si fourni, les paramètres du fichier de configuration seront utilisés.
            max_workers (int, optional): Nombre maximum de threads. Par défaut: 4.
        """
        self.cache = ThreadSafeCache(cache_dir, config_path)
        self.executor = ThreadPoolExecutor(max_workers=max_workers)
    
    def get_many(self, keys: List[str], default: Any = None) -> Dict[str, Any]:
        """
        Récupère plusieurs valeurs du cache en parallèle.
        
        Args:
            keys (List[str]): Liste des clés à récupérer.
            default (Any, optional): Valeur par défaut pour les clés inexistantes.
                Par défaut: None.
                
        Returns:
            Dict[str, Any]: Dictionnaire des valeurs récupérées.
        """
        # Soumettre les opérations de lecture au pool de threads
        futures = {key: self.executor.submit(self.cache.get, key, default) for key in keys}
        
        # Récupérer les résultats
        results = {}
        for key, future in futures.items():
            results[key] = future.result()
        
        return results
    
    def set_many(self, items: Dict[str, Any], ttl: Optional[int] = None) -> None:
        """
        Stocke plusieurs valeurs dans le cache en parallèle.
        
        Args:
            items (Dict[str, Any]): Dictionnaire des clés et valeurs à stocker.
            ttl (int, optional): Durée de vie des éléments en secondes.
                Si None, utilise la durée de vie par défaut du cache.
        """
        # Soumettre les opérations d'écriture au pool de threads
        futures = []
        for key, value in items.items():
            futures.append(self.executor.submit(self.cache.set, key, value, ttl))
        
        # Attendre que toutes les opérations soient terminées
        for future in futures:
            future.result()
    
    def delete_many(self, keys: List[str]) -> int:
        """
        Supprime plusieurs éléments du cache en parallèle.
        
        Args:
            keys (List[str]): Liste des clés à supprimer.
            
        Returns:
            int: Nombre d'éléments supprimés.
        """
        # Soumettre les opérations de suppression au pool de threads
        futures = {key: self.executor.submit(self.cache.delete, key) for key in keys}
        
        # Récupérer les résultats
        deleted_count = 0
        for future in futures.values():
            if future.result():
                deleted_count += 1
        
        return deleted_count
    
    def get(self, key: str, default: Any = None) -> Any:
        """
        Récupère une valeur du cache.
        
        Args:
            key (str): Clé de l'élément à récupérer.
            default (Any, optional): Valeur à retourner si la clé n'existe pas.
                Par défaut: None.
                
        Returns:
            Any: Valeur associée à la clé ou valeur par défaut si la clé n'existe pas.
        """
        return self.cache.get(key, default)
    
    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> None:
        """
        Stocke une valeur dans le cache.
        
        Args:
            key (str): Clé de l'élément à stocker.
            value (Any): Valeur de l'élément à stocker.
            ttl (int, optional): Durée de vie de l'élément en secondes.
                Si None, utilise la durée de vie par défaut du cache.
        """
        self.cache.set(key, value, ttl)
    
    def delete(self, key: str) -> bool:
        """
        Supprime un élément du cache.
        
        Args:
            key (str): Clé de l'élément à supprimer.
            
        Returns:
            bool: True si l'élément a été supprimé, False sinon.
        """
        return self.cache.delete(key)
    
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
    
    def __enter__(self):
        """Entre dans le gestionnaire de contexte."""
        return self
    
    def __exit__(self, exc_type=None, exc_val=None, exc_tb=None):
        """Sort du gestionnaire de contexte."""
        # Fermer l'executor
        self.executor.shutdown(wait=True)
        
        # Fermer le cache
        self.cache.__exit__(exc_type, exc_val, exc_tb)
        return False  # Ne pas supprimer l'exception


# Fonction pour créer un cache parallèle
def create_parallel_cache(cache_type: str, **kwargs) -> Union[ThreadSafeCache, ShardedCache, AsyncCache, BatchCache]:
    """
    Crée un cache parallèle.
    
    Args:
        cache_type (str): Type de cache ('thread_safe', 'sharded', 'async', 'batch').
        **kwargs: Arguments supplémentaires à passer au constructeur du cache.
        
    Returns:
        Union[ThreadSafeCache, ShardedCache, AsyncCache, BatchCache]: Cache parallèle.
        
    Raises:
        ValueError: Si le type de cache est invalide.
    """
    cache_type = cache_type.lower()
    
    if cache_type == 'thread_safe':
        return ThreadSafeCache(**kwargs)
    elif cache_type == 'sharded':
        return ShardedCache(**kwargs)
    elif cache_type == 'async':
        return AsyncCache(**kwargs)
    elif cache_type == 'batch':
        return BatchCache(**kwargs)
    else:
        raise ValueError(f"Type de cache invalide: {cache_type}")


if __name__ == "__main__":
    # Exemple d'utilisation
    import random
    
    # Créer un cache thread-safe
    thread_safe_cache = ThreadSafeCache()
    
    # Ajouter des données au cache
    thread_safe_cache.set("key1", "value1")
    thread_safe_cache.set("key2", "value2")
    
    # Récupérer des données du cache
    print(f"Valeur pour key1: {thread_safe_cache.get('key1')}")
    print(f"Valeur pour key2: {thread_safe_cache.get('key2')}")
    
    # Créer un cache partitionné
    sharded_cache = ShardedCache(shards=4)
    
    # Ajouter des données au cache
    for i in range(100):
        sharded_cache.set(f"key{i}", f"value{i}")
    
    # Récupérer des données du cache
    print(f"Valeur pour key50: {sharded_cache.get('key50')}")
    
    # Afficher les statistiques
    print(f"Statistiques du cache partitionné: {sharded_cache.get_statistics()}")
    
    # Créer un cache asynchrone
    async_cache = AsyncCache()
    
    # Ajouter des données au cache de manière asynchrone
    for i in range(100):
        async_cache.set(f"key{i}", f"value{i}")
    
    # Attendre que toutes les opérations soient terminées
    async_cache.wait_for_all()
    
    # Récupérer des données du cache
    print(f"Valeur pour key50: {async_cache.get('key50')}")
    
    # Créer un cache par lots
    batch_cache = BatchCache()
    
    # Ajouter des données au cache par lots
    items = {f"key{i}": f"value{i}" for i in range(100)}
    batch_cache.set_many(items)
    
    # Récupérer des données du cache par lots
    keys = [f"key{i}" for i in range(10)]
    values = batch_cache.get_many(keys)
    print(f"Valeurs récupérées par lots: {values}")
    
    # Nettoyer
    thread_safe_cache.clear()
    sharded_cache.clear()
    async_cache.clear()
    batch_cache.clear()
