#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de gestion des dépendances pour le cache.

Ce module fournit des fonctionnalités pour gérer les dépendances entre les éléments du cache
et faciliter l'invalidation des éléments liés.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import json
import time
import logging
from typing import Dict, List, Set, Any, Optional, Union
from pathlib import Path

# Configurer le logger
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class DependencyManager:
    """
    Gestionnaire de dépendances pour le cache.
    
    Cette classe permet de suivre les dépendances entre les éléments du cache
    et de faciliter l'invalidation des éléments liés.
    """
    
    def __init__(self, storage_path: Optional[str] = None):
        """
        Initialise le gestionnaire de dépendances.
        
        Args:
            storage_path (str, optional): Chemin vers le fichier de stockage des dépendances.
                Si None, utilise un stockage en mémoire uniquement.
        """
        self.storage_path = storage_path
        
        # Dictionnaire des dépendances directes (clé -> dépendances)
        self.dependencies: Dict[str, Set[str]] = {}
        
        # Dictionnaire inverse (dépendance -> clés qui en dépendent)
        self.reverse_dependencies: Dict[str, Set[str]] = {}
        
        # Dictionnaire des tags (tag -> clés associées)
        self.tags: Dict[str, Set[str]] = {}
        
        # Dictionnaire inverse (clé -> tags associés)
        self.key_tags: Dict[str, Set[str]] = {}
        
        # Charger les dépendances existantes si un chemin de stockage est fourni
        if storage_path:
            self._load_dependencies()
    
    def _load_dependencies(self) -> None:
        """
        Charge les dépendances à partir du fichier de stockage.
        """
        if not self.storage_path or not os.path.exists(self.storage_path):
            return
        
        try:
            with open(self.storage_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                
                # Convertir les listes en ensembles
                self.dependencies = {k: set(v) for k, v in data.get('dependencies', {}).items()}
                self.reverse_dependencies = {k: set(v) for k, v in data.get('reverse_dependencies', {}).items()}
                self.tags = {k: set(v) for k, v in data.get('tags', {}).items()}
                self.key_tags = {k: set(v) for k, v in data.get('key_tags', {}).items()}
                
            logger.info(f"Dépendances chargées depuis {self.storage_path}")
        except (json.JSONDecodeError, IOError) as e:
            logger.error(f"Erreur lors du chargement des dépendances: {e}")
    
    def _save_dependencies(self) -> None:
        """
        Sauvegarde les dépendances dans le fichier de stockage.
        """
        if not self.storage_path:
            return
        
        # Créer le répertoire parent si nécessaire
        os.makedirs(os.path.dirname(self.storage_path), exist_ok=True)
        
        try:
            # Convertir les ensembles en listes pour la sérialisation JSON
            data = {
                'dependencies': {k: list(v) for k, v in self.dependencies.items()},
                'reverse_dependencies': {k: list(v) for k, v in self.reverse_dependencies.items()},
                'tags': {k: list(v) for k, v in self.tags.items()},
                'key_tags': {k: list(v) for k, v in self.key_tags.items()},
                'timestamp': time.time()
            }
            
            with open(self.storage_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2)
                
            logger.info(f"Dépendances sauvegardées dans {self.storage_path}")
        except IOError as e:
            logger.error(f"Erreur lors de la sauvegarde des dépendances: {e}")
    
    def add_dependency(self, key: str, dependency: str) -> None:
        """
        Ajoute une dépendance pour une clé de cache.
        
        Args:
            key (str): Clé de cache.
            dependency (str): Dépendance à ajouter.
        """
        # Initialiser les ensembles si nécessaire
        if key not in self.dependencies:
            self.dependencies[key] = set()
        
        if dependency not in self.reverse_dependencies:
            self.reverse_dependencies[dependency] = set()
        
        # Ajouter la dépendance
        self.dependencies[key].add(dependency)
        self.reverse_dependencies[dependency].add(key)
        
        # Sauvegarder les modifications
        self._save_dependencies()
        
        logger.debug(f"Dépendance ajoutée: {key} -> {dependency}")
    
    def add_dependencies(self, key: str, dependencies: List[str]) -> None:
        """
        Ajoute plusieurs dépendances pour une clé de cache.
        
        Args:
            key (str): Clé de cache.
            dependencies (List[str]): Liste des dépendances à ajouter.
        """
        for dependency in dependencies:
            self.add_dependency(key, dependency)
    
    def remove_dependency(self, key: str, dependency: str) -> None:
        """
        Supprime une dépendance pour une clé de cache.
        
        Args:
            key (str): Clé de cache.
            dependency (str): Dépendance à supprimer.
        """
        # Vérifier si la clé et la dépendance existent
        if key in self.dependencies and dependency in self.dependencies[key]:
            self.dependencies[key].remove(dependency)
            
            # Supprimer la clé si elle n'a plus de dépendances
            if not self.dependencies[key]:
                del self.dependencies[key]
        
        # Mettre à jour les dépendances inverses
        if dependency in self.reverse_dependencies and key in self.reverse_dependencies[dependency]:
            self.reverse_dependencies[dependency].remove(key)
            
            # Supprimer la dépendance si elle n'est plus utilisée
            if not self.reverse_dependencies[dependency]:
                del self.reverse_dependencies[dependency]
        
        # Sauvegarder les modifications
        self._save_dependencies()
        
        logger.debug(f"Dépendance supprimée: {key} -> {dependency}")
    
    def get_dependencies(self, key: str) -> Set[str]:
        """
        Récupère les dépendances d'une clé de cache.
        
        Args:
            key (str): Clé de cache.
            
        Returns:
            Set[str]: Ensemble des dépendances.
        """
        return self.dependencies.get(key, set())
    
    def get_dependent_keys(self, dependency: str) -> Set[str]:
        """
        Récupère les clés qui dépendent d'une dépendance donnée.
        
        Args:
            dependency (str): Dépendance.
            
        Returns:
            Set[str]: Ensemble des clés dépendantes.
        """
        return self.reverse_dependencies.get(dependency, set())
    
    def add_tag(self, key: str, tag: str) -> None:
        """
        Ajoute un tag à une clé de cache.
        
        Args:
            key (str): Clé de cache.
            tag (str): Tag à ajouter.
        """
        # Initialiser les ensembles si nécessaire
        if tag not in self.tags:
            self.tags[tag] = set()
        
        if key not in self.key_tags:
            self.key_tags[key] = set()
        
        # Ajouter le tag
        self.tags[tag].add(key)
        self.key_tags[key].add(tag)
        
        # Sauvegarder les modifications
        self._save_dependencies()
        
        logger.debug(f"Tag ajouté: {key} -> {tag}")
    
    def add_tags(self, key: str, tags: List[str]) -> None:
        """
        Ajoute plusieurs tags à une clé de cache.
        
        Args:
            key (str): Clé de cache.
            tags (List[str]): Liste des tags à ajouter.
        """
        for tag in tags:
            self.add_tag(key, tag)
    
    def remove_tag(self, key: str, tag: str) -> None:
        """
        Supprime un tag d'une clé de cache.
        
        Args:
            key (str): Clé de cache.
            tag (str): Tag à supprimer.
        """
        # Vérifier si la clé et le tag existent
        if key in self.key_tags and tag in self.key_tags[key]:
            self.key_tags[key].remove(tag)
            
            # Supprimer la clé si elle n'a plus de tags
            if not self.key_tags[key]:
                del self.key_tags[key]
        
        # Mettre à jour les tags
        if tag in self.tags and key in self.tags[tag]:
            self.tags[tag].remove(key)
            
            # Supprimer le tag s'il n'est plus utilisé
            if not self.tags[tag]:
                del self.tags[tag]
        
        # Sauvegarder les modifications
        self._save_dependencies()
        
        logger.debug(f"Tag supprimé: {key} -> {tag}")
    
    def get_tags(self, key: str) -> Set[str]:
        """
        Récupère les tags d'une clé de cache.
        
        Args:
            key (str): Clé de cache.
            
        Returns:
            Set[str]: Ensemble des tags.
        """
        return self.key_tags.get(key, set())
    
    def get_keys_by_tag(self, tag: str) -> Set[str]:
        """
        Récupère les clés associées à un tag.
        
        Args:
            tag (str): Tag.
            
        Returns:
            Set[str]: Ensemble des clés.
        """
        return self.tags.get(tag, set())
    
    def get_keys_by_tags(self, tags: List[str], match_all: bool = False) -> Set[str]:
        """
        Récupère les clés associées à plusieurs tags.
        
        Args:
            tags (List[str]): Liste des tags.
            match_all (bool, optional): Si True, retourne les clés qui ont tous les tags.
                Si False, retourne les clés qui ont au moins un des tags.
                
        Returns:
            Set[str]: Ensemble des clés.
        """
        if not tags:
            return set()
        
        # Récupérer les clés pour chaque tag
        keys_sets = [self.get_keys_by_tag(tag) for tag in tags]
        
        if not keys_sets:
            return set()
        
        if match_all:
            # Intersection des ensembles (clés qui ont tous les tags)
            result = keys_sets[0]
            for keys_set in keys_sets[1:]:
                result = result.intersection(keys_set)
            return result
        else:
            # Union des ensembles (clés qui ont au moins un des tags)
            result = set()
            for keys_set in keys_sets:
                result = result.union(keys_set)
            return result
    
    def clear_key(self, key: str) -> None:
        """
        Supprime toutes les dépendances et tags d'une clé de cache.
        
        Args:
            key (str): Clé de cache.
        """
        # Supprimer les dépendances
        if key in self.dependencies:
            dependencies = list(self.dependencies[key])
            for dependency in dependencies:
                self.remove_dependency(key, dependency)
        
        # Supprimer les tags
        if key in self.key_tags:
            tags = list(self.key_tags[key])
            for tag in tags:
                self.remove_tag(key, tag)
        
        logger.debug(f"Clé nettoyée: {key}")
    
    def clear_all(self) -> None:
        """
        Supprime toutes les dépendances et tags.
        """
        self.dependencies.clear()
        self.reverse_dependencies.clear()
        self.tags.clear()
        self.key_tags.clear()
        
        # Sauvegarder les modifications
        self._save_dependencies()
        
        logger.info("Toutes les dépendances et tags ont été supprimés")


# Fonction pour créer une instance du gestionnaire de dépendances
def create_dependency_manager(storage_path: Optional[str] = None) -> DependencyManager:
    """
    Crée une instance du gestionnaire de dépendances.
    
    Args:
        storage_path (str, optional): Chemin vers le fichier de stockage des dépendances.
            Si None, utilise un stockage en mémoire uniquement.
            
    Returns:
        DependencyManager: Instance du gestionnaire de dépendances.
    """
    if storage_path is None:
        # Utiliser un chemin par défaut dans le répertoire du cache
        cache_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data')
        os.makedirs(cache_dir, exist_ok=True)
        storage_path = os.path.join(cache_dir, 'dependencies.json')
    
    return DependencyManager(storage_path)


# Instance par défaut du gestionnaire de dépendances
_default_manager = None


def get_default_manager() -> DependencyManager:
    """
    Récupère l'instance par défaut du gestionnaire de dépendances.
    
    Returns:
        DependencyManager: Instance par défaut du gestionnaire de dépendances.
    """
    global _default_manager
    if _default_manager is None:
        _default_manager = create_dependency_manager()
    return _default_manager
