#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module définissant l'interface générique pour les adaptateurs de cache.

Ce module fournit une classe abstraite CacheAdapter qui définit l'interface
que tous les adaptateurs de cache doivent implémenter.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import json
import time
import hashlib
from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional, Tuple, Union, Callable

# Importer le module LocalCache
import sys
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(str(Path(__file__).parent.parent.parent.parent))
from scripts.utils.cache.local_cache import LocalCache


class CacheAdapter(ABC):
    """Interface abstraite pour les adaptateurs de cache."""

    def __init__(self, cache: LocalCache = None, config_path: str = None):
        """
        Initialise l'adaptateur de cache.

        Args:
            cache (LocalCache, optional): Instance de LocalCache à utiliser.
                Si None, une nouvelle instance sera créée.
            config_path (str, optional): Chemin vers un fichier de configuration JSON.
                Si fourni, les paramètres du fichier de configuration seront utilisés.
        """
        self.cache = cache or LocalCache(config_path=config_path)
        self.config = {}

        # Charger la configuration si spécifiée
        if config_path and os.path.exists(config_path):
            try:
                with open(config_path, 'r', encoding='utf-8') as f:
                    self.config = json.load(f)
            except Exception as e:
                print(f"Erreur lors du chargement de la configuration: {e}")

    @abstractmethod
    def generate_cache_key(self, *args, **kwargs) -> str:
        """
        Génère une clé de cache unique basée sur les paramètres fournis.

        Args:
            *args: Arguments positionnels.
            **kwargs: Arguments nommés.

        Returns:
            str: Clé de cache unique.
        """
        pass

    @abstractmethod
    def serialize_response(self, response: Any) -> Dict[str, Any]:
        """
        Sérialise une réponse pour le stockage dans le cache.

        Args:
            response: Réponse à sérialiser.

        Returns:
            Dict[str, Any]: Réponse sérialisée.
        """
        # Si la réponse est déjà un dictionnaire ou une valeur simple, la retourner telle quelle
        if isinstance(response, (dict, str, int, float, bool, type(None))):
            return {"value": response, "timestamp": time.time()}
        # Sinon, laisser les classes dérivées implémenter leur propre sérialisation
        raise NotImplementedError("La méthode serialize_response doit être implémentée par les classes dérivées.")

    @abstractmethod
    def deserialize_response(self, serialized_response: Dict[str, Any]) -> Any:
        """
        Désérialise une réponse du cache.

        Args:
            serialized_response: Réponse sérialisée.

        Returns:
            Any: Réponse désérialisée.
        """
        # Si la réponse a été sérialisée avec la méthode par défaut
        if "value" in serialized_response:
            return serialized_response["value"]
        # Sinon, laisser les classes dérivées implémenter leur propre désérialisation
        raise NotImplementedError("La méthode deserialize_response doit être implémentée par les classes dérivées.")

    def get_cached_response(self, cache_key: str) -> Optional[Any]:
        """
        Récupère une réponse du cache.

        Args:
            cache_key (str): Clé de cache.

        Returns:
            Optional[Any]: Réponse désérialisée ou None si la clé n'existe pas.
        """
        serialized_response = self.cache.get(cache_key)
        if serialized_response is None:
            return None
        return self.deserialize_response(serialized_response)

    def cache_response(self, cache_key: str, response: Any, ttl: Optional[int] = None) -> None:
        """
        Met en cache une réponse.

        Args:
            cache_key (str): Clé de cache.
            response (Any): Réponse à mettre en cache.
            ttl (int, optional): Durée de vie de la réponse en secondes.
                Si None, utilise la durée de vie par défaut du cache.
        """
        serialized_response = self.serialize_response(response)
        self.cache.set(cache_key, serialized_response, ttl)

    def invalidate(self, cache_key: str) -> bool:
        """
        Invalide une entrée du cache.

        Args:
            cache_key (str): Clé de cache à invalider.

        Returns:
            bool: True si l'entrée a été invalidée, False sinon.
        """
        return self.cache.delete(cache_key)

    def clear(self) -> None:
        """Vide le cache."""
        self.cache.clear()

    def get_statistics(self) -> Dict[str, int]:
        """
        Récupère les statistiques d'utilisation du cache.

        Returns:
            Dict[str, int]: Dictionnaire contenant les statistiques d'utilisation.
        """
        return self.cache.get_statistics()

    @staticmethod
    def hash_params(*args, **kwargs) -> str:
        """
        Génère un hash à partir des paramètres fournis.

        Args:
            *args: Arguments positionnels.
            **kwargs: Arguments nommés.

        Returns:
            str: Hash des paramètres.
        """
        # Convertir les arguments en chaîne de caractères
        args_str = str(args)
        kwargs_str = str(sorted(kwargs.items()))

        # Générer un hash SHA-256
        hash_obj = hashlib.sha256()
        hash_obj.update(args_str.encode('utf-8'))
        hash_obj.update(kwargs_str.encode('utf-8'))

        return hash_obj.hexdigest()

    def cached(self, ttl: Optional[int] = None) -> Callable:
        """
        Décorateur pour mettre en cache les résultats d'une fonction.

        Args:
            ttl (int, optional): Durée de vie du résultat en secondes.
                Si None, utilise la durée de vie par défaut du cache.

        Returns:
            Callable: Décorateur de mise en cache.
        """
        def decorator(func):
            def wrapper(*args, **kwargs):
                # Générer une clé de cache
                func_name = getattr(func, "__name__", str(func))
                # Utiliser le hash_params pour générer une clé unique
                hash_key = self.hash_params(func_name, *args, **kwargs)
                cache_key = f"func:{hash_key}"

                # Vérifier si le résultat est dans le cache
                cached_result = self.get_cached_response(cache_key)
                if cached_result is not None:
                    return cached_result

                # Exécuter la fonction et mettre en cache le résultat
                result = func(*args, **kwargs)
                self.cache_response(cache_key, result, ttl)

                return result

            return wrapper

        return decorator
