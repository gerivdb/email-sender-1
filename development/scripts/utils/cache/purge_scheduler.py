#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de planification de purge du cache.

Ce module fournit des fonctionnalités pour planifier la purge périodique du cache
en fonction de différentes stratégies.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import time
import json
import logging
import threading
import schedule
from typing import Dict, List, Set, Any, Optional, Union, Callable
from pathlib import Path

# Importer les modules nécessaires
from scripts.utils.cache.local_cache import LocalCache
from scripts.utils.cache.dependency_manager import DependencyManager, get_default_manager
from scripts.utils.cache.invalidation import CacheInvalidator, get_default_invalidator

# Configurer le logger
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class PurgeScheduler:
    """
    Planificateur de purge du cache.
    
    Cette classe fournit des méthodes pour planifier la purge périodique du cache
    en fonction de différentes stratégies.
    """
    
    def __init__(self, invalidator: Optional[CacheInvalidator] = None, config_path: Optional[str] = None):
        """
        Initialise le planificateur de purge.
        
        Args:
            invalidator (CacheInvalidator, optional): Instance de l'invalidateur de cache.
                Si None, utilise l'instance par défaut.
            config_path (str, optional): Chemin vers le fichier de configuration.
                Si None, utilise un chemin par défaut.
        """
        self.invalidator = invalidator or get_default_invalidator()
        self.config_path = config_path
        
        # Configuration par défaut
        self.config = {
            "enabled": True,
            "purge_expired_interval": 300,  # 5 minutes
            "purge_patterns": [
                {
                    "pattern": "temp:*",
                    "interval": 3600  # 1 heure
                }
            ],
            "purge_tags": [
                {
                    "tag": "temporary",
                    "interval": 3600  # 1 heure
                }
            ],
            "max_cache_size": 100 * 1024 * 1024,  # 100 Mo
            "size_check_interval": 3600  # 1 heure
        }
        
        # Charger la configuration
        if config_path:
            self._load_config()
        
        # Verrou pour les opérations de planification
        self.lock = threading.RLock()
        
        # Planificateur pour les tâches périodiques
        self.scheduler = schedule.Scheduler()
        self.scheduler_thread = None
        self.scheduler_running = False
    
    def _load_config(self) -> None:
        """
        Charge la configuration à partir du fichier de configuration.
        """
        if not self.config_path or not os.path.exists(self.config_path):
            return
        
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                config = json.load(f)
                
                # Mettre à jour la configuration
                self.config.update(config)
                
            logger.info(f"Configuration chargée depuis {self.config_path}")
        except (json.JSONDecodeError, IOError) as e:
            logger.error(f"Erreur lors du chargement de la configuration: {e}")
    
    def _save_config(self) -> None:
        """
        Sauvegarde la configuration dans le fichier de configuration.
        """
        if not self.config_path:
            return
        
        # Créer le répertoire parent si nécessaire
        os.makedirs(os.path.dirname(self.config_path), exist_ok=True)
        
        try:
            with open(self.config_path, 'w', encoding='utf-8') as f:
                json.dump(self.config, f, indent=2)
                
            logger.info(f"Configuration sauvegardée dans {self.config_path}")
        except IOError as e:
            logger.error(f"Erreur lors de la sauvegarde de la configuration: {e}")
    
    def start(self) -> None:
        """
        Démarre le planificateur de purge.
        """
        with self.lock:
            if not self.config["enabled"]:
                logger.info("Le planificateur de purge est désactivé")
                return
            
            # Planifier la purge des clés expirées
            if self.config["purge_expired_interval"] > 0:
                self.invalidator.schedule_invalidation_expired(self.config["purge_expired_interval"])
            
            # Planifier la purge des motifs
            for pattern_config in self.config["purge_patterns"]:
                pattern = pattern_config["pattern"]
                interval = pattern_config["interval"]
                self.invalidator.schedule_invalidation_by_pattern(pattern, interval)
            
            # Planifier la purge des tags
            for tag_config in self.config["purge_tags"]:
                tag = tag_config["tag"]
                interval = tag_config["interval"]
                self.invalidator.schedule_invalidation_by_tag(tag, interval)
            
            # Planifier la vérification de la taille du cache
            if self.config["max_cache_size"] > 0 and self.config["size_check_interval"] > 0:
                self.schedule_size_check(self.config["size_check_interval"])
            
            logger.info("Planificateur de purge démarré")
    
    def stop(self) -> None:
        """
        Arrête le planificateur de purge.
        """
        with self.lock:
            self.invalidator.stop_scheduler()
            logger.info("Planificateur de purge arrêté")
    
    def schedule_size_check(self, interval: int) -> None:
        """
        Planifie une vérification périodique de la taille du cache.
        
        Args:
            interval (int): Intervalle en secondes.
        """
        self.invalidator.schedule_invalidation(interval, self._check_cache_size)
        logger.info(f"Vérification de la taille du cache planifiée toutes les {interval} secondes")
    
    def _check_cache_size(self) -> None:
        """
        Vérifie la taille du cache et purge les clés les plus anciennes si nécessaire.
        """
        with self.lock:
            # Récupérer la taille actuelle du cache
            cache_size = self.invalidator.cache.get_size()
            
            # Vérifier si la taille du cache dépasse la limite
            if cache_size > self.config["max_cache_size"]:
                # Calculer le pourcentage à purger (20% par défaut)
                purge_percentage = 0.2
                
                # Récupérer toutes les clés avec leur date d'accès
                keys_with_access_time = self.invalidator.cache.get_keys_with_access_time()
                
                # Trier les clés par date d'accès (les plus anciennes en premier)
                sorted_keys = sorted(keys_with_access_time, key=lambda x: x[1])
                
                # Calculer le nombre de clés à purger
                num_keys_to_purge = int(len(sorted_keys) * purge_percentage)
                
                # Purger les clés les plus anciennes
                keys_to_purge = [key for key, _ in sorted_keys[:num_keys_to_purge]]
                count = self.invalidator.invalidate_keys(keys_to_purge)
                
                logger.info(f"Taille du cache ({cache_size} octets) dépasse la limite ({self.config['max_cache_size']} octets). {count} clés purgées.")
    
    def add_pattern_purge(self, pattern: str, interval: int) -> None:
        """
        Ajoute une purge périodique pour un motif spécifique.
        
        Args:
            pattern (str): Motif de clé.
            interval (int): Intervalle en secondes.
        """
        with self.lock:
            # Ajouter le motif à la configuration
            self.config["purge_patterns"].append({
                "pattern": pattern,
                "interval": interval
            })
            
            # Sauvegarder la configuration
            self._save_config()
            
            # Planifier la purge si le planificateur est actif
            if self.scheduler_running:
                self.invalidator.schedule_invalidation_by_pattern(pattern, interval)
            
            logger.info(f"Purge périodique ajoutée pour le motif '{pattern}' toutes les {interval} secondes")
    
    def add_tag_purge(self, tag: str, interval: int) -> None:
        """
        Ajoute une purge périodique pour un tag spécifique.
        
        Args:
            tag (str): Tag.
            interval (int): Intervalle en secondes.
        """
        with self.lock:
            # Ajouter le tag à la configuration
            self.config["purge_tags"].append({
                "tag": tag,
                "interval": interval
            })
            
            # Sauvegarder la configuration
            self._save_config()
            
            # Planifier la purge si le planificateur est actif
            if self.scheduler_running:
                self.invalidator.schedule_invalidation_by_tag(tag, interval)
            
            logger.info(f"Purge périodique ajoutée pour le tag '{tag}' toutes les {interval} secondes")
    
    def remove_pattern_purge(self, pattern: str) -> bool:
        """
        Supprime une purge périodique pour un motif spécifique.
        
        Args:
            pattern (str): Motif de clé.
            
        Returns:
            bool: True si la purge a été supprimée, False sinon.
        """
        with self.lock:
            # Rechercher le motif dans la configuration
            for i, pattern_config in enumerate(self.config["purge_patterns"]):
                if pattern_config["pattern"] == pattern:
                    # Supprimer le motif de la configuration
                    del self.config["purge_patterns"][i]
                    
                    # Sauvegarder la configuration
                    self._save_config()
                    
                    logger.info(f"Purge périodique supprimée pour le motif '{pattern}'")
                    return True
            
            logger.warning(f"Motif '{pattern}' non trouvé dans la configuration")
            return False
    
    def remove_tag_purge(self, tag: str) -> bool:
        """
        Supprime une purge périodique pour un tag spécifique.
        
        Args:
            tag (str): Tag.
            
        Returns:
            bool: True si la purge a été supprimée, False sinon.
        """
        with self.lock:
            # Rechercher le tag dans la configuration
            for i, tag_config in enumerate(self.config["purge_tags"]):
                if tag_config["tag"] == tag:
                    # Supprimer le tag de la configuration
                    del self.config["purge_tags"][i]
                    
                    # Sauvegarder la configuration
                    self._save_config()
                    
                    logger.info(f"Purge périodique supprimée pour le tag '{tag}'")
                    return True
            
            logger.warning(f"Tag '{tag}' non trouvé dans la configuration")
            return False
    
    def set_max_cache_size(self, max_size: int) -> None:
        """
        Définit la taille maximale du cache.
        
        Args:
            max_size (int): Taille maximale en octets.
        """
        with self.lock:
            self.config["max_cache_size"] = max_size
            self._save_config()
            logger.info(f"Taille maximale du cache définie à {max_size} octets")
    
    def set_size_check_interval(self, interval: int) -> None:
        """
        Définit l'intervalle de vérification de la taille du cache.
        
        Args:
            interval (int): Intervalle en secondes.
        """
        with self.lock:
            self.config["size_check_interval"] = interval
            self._save_config()
            logger.info(f"Intervalle de vérification de la taille du cache défini à {interval} secondes")
    
    def set_purge_expired_interval(self, interval: int) -> None:
        """
        Définit l'intervalle de purge des clés expirées.
        
        Args:
            interval (int): Intervalle en secondes.
        """
        with self.lock:
            self.config["purge_expired_interval"] = interval
            self._save_config()
            logger.info(f"Intervalle de purge des clés expirées défini à {interval} secondes")
    
    def enable(self) -> None:
        """
        Active le planificateur de purge.
        """
        with self.lock:
            self.config["enabled"] = True
            self._save_config()
            logger.info("Planificateur de purge activé")
    
    def disable(self) -> None:
        """
        Désactive le planificateur de purge.
        """
        with self.lock:
            self.config["enabled"] = False
            self._save_config()
            self.stop()
            logger.info("Planificateur de purge désactivé")


# Fonction pour créer une instance du planificateur de purge
def create_purge_scheduler(invalidator: Optional[CacheInvalidator] = None, config_path: Optional[str] = None) -> PurgeScheduler:
    """
    Crée une instance du planificateur de purge.
    
    Args:
        invalidator (CacheInvalidator, optional): Instance de l'invalidateur de cache.
            Si None, utilise l'instance par défaut.
        config_path (str, optional): Chemin vers le fichier de configuration.
            Si None, utilise un chemin par défaut.
            
    Returns:
        PurgeScheduler: Instance du planificateur de purge.
    """
    if config_path is None:
        # Utiliser un chemin par défaut dans le répertoire du cache
        cache_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data')
        os.makedirs(cache_dir, exist_ok=True)
        config_path = os.path.join(cache_dir, 'purge_config.json')
    
    return PurgeScheduler(invalidator, config_path)


# Instance par défaut du planificateur de purge
_default_scheduler = None


def get_default_scheduler(invalidator: Optional[CacheInvalidator] = None) -> PurgeScheduler:
    """
    Récupère l'instance par défaut du planificateur de purge.
    
    Args:
        invalidator (CacheInvalidator, optional): Instance de l'invalidateur de cache.
            Si None, utilise l'instance par défaut.
            
    Returns:
        PurgeScheduler: Instance par défaut du planificateur de purge.
    """
    global _default_scheduler
    if _default_scheduler is None:
        _default_scheduler = create_purge_scheduler(invalidator)
    return _default_scheduler
