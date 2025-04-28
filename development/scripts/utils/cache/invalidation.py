#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module d'invalidation du cache.

Ce module fournit des fonctionnalités pour invalider les éléments du cache
en fonction de différentes stratégies.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import time
import logging
import threading
import schedule
from typing import Dict, List, Set, Any, Optional, Union, Callable
from pathlib import Path

# Importer les modules nécessaires
from scripts.utils.cache.local_cache import LocalCache
from scripts.utils.cache.dependency_manager import DependencyManager, get_default_manager

# Configurer le logger
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class CacheInvalidator:
    """
    Invalidateur de cache.
    
    Cette classe fournit des méthodes pour invalider les éléments du cache
    en fonction de différentes stratégies.
    """
    
    def __init__(self, cache: LocalCache, dependency_manager: Optional[DependencyManager] = None):
        """
        Initialise l'invalidateur de cache.
        
        Args:
            cache (LocalCache): Instance du cache local.
            dependency_manager (DependencyManager, optional): Instance du gestionnaire de dépendances.
                Si None, utilise l'instance par défaut.
        """
        self.cache = cache
        self.dependency_manager = dependency_manager or get_default_manager()
        
        # Verrou pour les opérations d'invalidation
        self.lock = threading.RLock()
        
        # Planificateur pour les tâches périodiques
        self.scheduler = schedule.Scheduler()
        self.scheduler_thread = None
        self.scheduler_running = False
    
    def invalidate_key(self, key: str) -> bool:
        """
        Invalide une clé spécifique dans le cache.
        
        Args:
            key (str): Clé à invalider.
            
        Returns:
            bool: True si la clé a été invalidée, False sinon.
        """
        with self.lock:
            # Supprimer la clé du cache
            result = self.cache.delete(key)
            
            if result:
                logger.debug(f"Clé invalidée: {key}")
            else:
                logger.debug(f"Clé non trouvée pour invalidation: {key}")
            
            # Nettoyer les dépendances et tags
            self.dependency_manager.clear_key(key)
            
            return result
    
    def invalidate_keys(self, keys: List[str]) -> int:
        """
        Invalide plusieurs clés dans le cache.
        
        Args:
            keys (List[str]): Liste des clés à invalider.
            
        Returns:
            int: Nombre de clés invalidées.
        """
        count = 0
        for key in keys:
            if self.invalidate_key(key):
                count += 1
        
        logger.info(f"{count} clés invalidées sur {len(keys)}")
        return count
    
    def invalidate_by_dependency(self, dependency: str) -> int:
        """
        Invalide toutes les clés qui dépendent d'une dépendance spécifique.
        
        Args:
            dependency (str): Dépendance.
            
        Returns:
            int: Nombre de clés invalidées.
        """
        with self.lock:
            # Récupérer les clés dépendantes
            dependent_keys = self.dependency_manager.get_dependent_keys(dependency)
            
            # Invalider les clés
            count = self.invalidate_keys(list(dependent_keys))
            
            logger.info(f"{count} clés invalidées pour la dépendance: {dependency}")
            return count
    
    def invalidate_by_dependencies(self, dependencies: List[str]) -> int:
        """
        Invalide toutes les clés qui dépendent d'une liste de dépendances.
        
        Args:
            dependencies (List[str]): Liste des dépendances.
            
        Returns:
            int: Nombre de clés invalidées.
        """
        count = 0
        for dependency in dependencies:
            count += self.invalidate_by_dependency(dependency)
        
        logger.info(f"{count} clés invalidées pour {len(dependencies)} dépendances")
        return count
    
    def invalidate_by_tag(self, tag: str) -> int:
        """
        Invalide toutes les clés associées à un tag spécifique.
        
        Args:
            tag (str): Tag.
            
        Returns:
            int: Nombre de clés invalidées.
        """
        with self.lock:
            # Récupérer les clés associées au tag
            tagged_keys = self.dependency_manager.get_keys_by_tag(tag)
            
            # Invalider les clés
            count = self.invalidate_keys(list(tagged_keys))
            
            logger.info(f"{count} clés invalidées pour le tag: {tag}")
            return count
    
    def invalidate_by_tags(self, tags: List[str], match_all: bool = False) -> int:
        """
        Invalide toutes les clés associées à une liste de tags.
        
        Args:
            tags (List[str]): Liste des tags.
            match_all (bool, optional): Si True, invalide les clés qui ont tous les tags.
                Si False, invalide les clés qui ont au moins un des tags.
                
        Returns:
            int: Nombre de clés invalidées.
        """
        with self.lock:
            # Récupérer les clés associées aux tags
            tagged_keys = self.dependency_manager.get_keys_by_tags(tags, match_all)
            
            # Invalider les clés
            count = self.invalidate_keys(list(tagged_keys))
            
            match_type = "tous" if match_all else "au moins un"
            logger.info(f"{count} clés invalidées pour {len(tags)} tags (correspondant à {match_type})")
            return count
    
    def invalidate_by_pattern(self, pattern: str) -> int:
        """
        Invalide toutes les clés qui correspondent à un motif.
        
        Args:
            pattern (str): Motif de clé (peut contenir des caractères génériques).
                Exemple: "user:*" pour toutes les clés commençant par "user:".
                
        Returns:
            int: Nombre de clés invalidées.
        """
        with self.lock:
            # Récupérer les clés qui correspondent au motif
            matching_keys = self.cache.get_keys_by_pattern(pattern)
            
            # Invalider les clés
            count = self.invalidate_keys(matching_keys)
            
            logger.info(f"{count} clés invalidées pour le motif: {pattern}")
            return count
    
    def invalidate_all(self) -> int:
        """
        Invalide toutes les clés du cache.
        
        Returns:
            int: Nombre de clés invalidées.
        """
        with self.lock:
            # Récupérer toutes les clés
            all_keys = self.cache.get_all_keys()
            
            # Invalider les clés
            count = self.invalidate_keys(all_keys)
            
            # Nettoyer toutes les dépendances et tags
            self.dependency_manager.clear_all()
            
            logger.info(f"{count} clés invalidées (cache vidé)")
            return count
    
    def invalidate_expired(self) -> int:
        """
        Invalide toutes les clés expirées du cache.
        
        Returns:
            int: Nombre de clés invalidées.
        """
        with self.lock:
            # Récupérer toutes les clés expirées
            expired_keys = self.cache.get_expired_keys()
            
            # Invalider les clés
            count = self.invalidate_keys(expired_keys)
            
            logger.info(f"{count} clés expirées invalidées")
            return count
    
    def schedule_invalidation(self, interval: int, method: Callable, *args, **kwargs) -> None:
        """
        Planifie une invalidation périodique.
        
        Args:
            interval (int): Intervalle en secondes.
            method (Callable): Méthode d'invalidation à appeler.
            *args: Arguments à passer à la méthode.
            **kwargs: Arguments nommés à passer à la méthode.
        """
        # Créer une tâche planifiée
        self.scheduler.every(interval).seconds.do(method, *args, **kwargs)
        
        # Démarrer le thread du planificateur si nécessaire
        if not self.scheduler_running:
            self._start_scheduler()
        
        logger.info(f"Invalidation planifiée toutes les {interval} secondes")
    
    def schedule_invalidation_by_tag(self, tag: str, interval: int) -> None:
        """
        Planifie une invalidation périodique pour un tag spécifique.
        
        Args:
            tag (str): Tag.
            interval (int): Intervalle en secondes.
        """
        self.schedule_invalidation(interval, self.invalidate_by_tag, tag)
        logger.info(f"Invalidation planifiée pour le tag '{tag}' toutes les {interval} secondes")
    
    def schedule_invalidation_by_pattern(self, pattern: str, interval: int) -> None:
        """
        Planifie une invalidation périodique pour un motif spécifique.
        
        Args:
            pattern (str): Motif de clé.
            interval (int): Intervalle en secondes.
        """
        self.schedule_invalidation(interval, self.invalidate_by_pattern, pattern)
        logger.info(f"Invalidation planifiée pour le motif '{pattern}' toutes les {interval} secondes")
    
    def schedule_invalidation_expired(self, interval: int) -> None:
        """
        Planifie une invalidation périodique des clés expirées.
        
        Args:
            interval (int): Intervalle en secondes.
        """
        self.schedule_invalidation(interval, self.invalidate_expired)
        logger.info(f"Invalidation des clés expirées planifiée toutes les {interval} secondes")
    
    def _start_scheduler(self) -> None:
        """
        Démarre le thread du planificateur.
        """
        if self.scheduler_thread is not None and self.scheduler_thread.is_alive():
            return
        
        self.scheduler_running = True
        
        def run_scheduler():
            while self.scheduler_running:
                self.scheduler.run_pending()
                time.sleep(1)
        
        self.scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
        self.scheduler_thread.start()
        
        logger.info("Planificateur d'invalidation démarré")
    
    def stop_scheduler(self) -> None:
        """
        Arrête le thread du planificateur.
        """
        self.scheduler_running = False
        
        if self.scheduler_thread is not None:
            self.scheduler_thread.join(timeout=5)
            self.scheduler_thread = None
        
        # Supprimer toutes les tâches planifiées
        self.scheduler.clear()
        
        logger.info("Planificateur d'invalidation arrêté")


# Fonction pour créer une instance de l'invalidateur de cache
def create_cache_invalidator(cache: LocalCache, dependency_manager: Optional[DependencyManager] = None) -> CacheInvalidator:
    """
    Crée une instance de l'invalidateur de cache.
    
    Args:
        cache (LocalCache): Instance du cache local.
        dependency_manager (DependencyManager, optional): Instance du gestionnaire de dépendances.
            Si None, utilise l'instance par défaut.
            
    Returns:
        CacheInvalidator: Instance de l'invalidateur de cache.
    """
    return CacheInvalidator(cache, dependency_manager)


# Instance par défaut de l'invalidateur de cache
_default_invalidator = None


def get_default_invalidator(cache: Optional[LocalCache] = None) -> CacheInvalidator:
    """
    Récupère l'instance par défaut de l'invalidateur de cache.
    
    Args:
        cache (LocalCache, optional): Instance du cache local.
            Si None, crée une nouvelle instance de LocalCache.
            
    Returns:
        CacheInvalidator: Instance par défaut de l'invalidateur de cache.
    """
    global _default_invalidator
    if _default_invalidator is None:
        if cache is None:
            cache = LocalCache()
        _default_invalidator = create_cache_invalidator(cache)
    return _default_invalidator
