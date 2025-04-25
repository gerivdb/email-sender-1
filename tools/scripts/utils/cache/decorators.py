#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de décorateurs pour la mise en cache.

Ce module fournit des décorateurs pour faciliter l'utilisation du cache
dans différents contextes (fonctions, méthodes, classes).

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

# Importer le module LocalCache
from scripts.utils.cache.local_cache import LocalCache


def cached(ttl: Optional[int] = None, key_prefix: str = "", 
           cache_instance: Optional[LocalCache] = None,
           key_generator: Optional[Callable] = None) -> Callable:
    """
    Décorateur pour mettre en cache les résultats d'une fonction.

    Args:
        ttl (int, optional): Durée de vie du résultat en secondes.
            Si None, utilise la durée de vie par défaut du cache.
        key_prefix (str, optional): Préfixe pour la clé de cache.
        cache_instance (LocalCache, optional): Instance de LocalCache à utiliser.
            Si None, une nouvelle instance sera créée.
        key_generator (Callable, optional): Fonction pour générer la clé de cache.
            Si None, utilise une fonction par défaut.

    Returns:
        Callable: Décorateur de mise en cache.
    """
    def decorator(func):
        # Créer ou utiliser une instance de cache
        nonlocal cache_instance
        if cache_instance is None:
            cache_instance = LocalCache()

        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            # Générer une clé de cache
            if key_generator:
                cache_key = key_generator(func, *args, **kwargs)
            else:
                # Utiliser une fonction par défaut pour générer la clé
                func_name = func.__module__ + "." + func.__name__
                # Convertir les arguments en chaîne de caractères
                args_str = str(args)
                kwargs_str = str(sorted(kwargs.items()))

                # Générer un hash SHA-256
                hash_obj = hashlib.sha256()
                hash_obj.update(func_name.encode('utf-8'))
                hash_obj.update(args_str.encode('utf-8'))
                hash_obj.update(kwargs_str.encode('utf-8'))
                hash_key = hash_obj.hexdigest()

                cache_key = f"{key_prefix}func:{hash_key}"

            # Vérifier si le résultat est dans le cache
            cached_result = cache_instance.get(cache_key)
            if cached_result is not None:
                return cached_result

            # Exécuter la fonction et mettre en cache le résultat
            result = func(*args, **kwargs)
            cache_instance.set(cache_key, result, ttl)

            return result

        # Ajouter des méthodes utilitaires au wrapper
        wrapper.invalidate_cache = lambda *a, **kw: invalidate_cache(func, cache_instance, key_generator, key_prefix, *a, **kw)
        wrapper.clear_cache = lambda: cache_instance.clear()
        wrapper.get_cache_key = lambda *a, **kw: get_cache_key(func, key_generator, key_prefix, *a, **kw)
        wrapper.cache_instance = cache_instance

        return wrapper

    return decorator


def invalidate_cache(func: Callable, cache_instance: LocalCache, 
                    key_generator: Optional[Callable], key_prefix: str,
                    *args, **kwargs) -> bool:
    """
    Invalide une entrée du cache pour une fonction.

    Args:
        func (Callable): Fonction dont l'entrée de cache doit être invalidée.
        cache_instance (LocalCache): Instance de LocalCache.
        key_generator (Callable, optional): Fonction pour générer la clé de cache.
        key_prefix (str): Préfixe pour la clé de cache.
        *args: Arguments positionnels de la fonction.
        **kwargs: Arguments nommés de la fonction.

    Returns:
        bool: True si l'entrée a été invalidée, False sinon.
    """
    cache_key = get_cache_key(func, key_generator, key_prefix, *args, **kwargs)
    return cache_instance.delete(cache_key)


def get_cache_key(func: Callable, key_generator: Optional[Callable], 
                 key_prefix: str, *args, **kwargs) -> str:
    """
    Génère la clé de cache pour une fonction.

    Args:
        func (Callable): Fonction pour laquelle générer la clé de cache.
        key_generator (Callable, optional): Fonction pour générer la clé de cache.
        key_prefix (str): Préfixe pour la clé de cache.
        *args: Arguments positionnels de la fonction.
        **kwargs: Arguments nommés de la fonction.

    Returns:
        str: Clé de cache.
    """
    if key_generator:
        return key_generator(func, *args, **kwargs)
    else:
        # Utiliser une fonction par défaut pour générer la clé
        func_name = func.__module__ + "." + func.__name__
        # Convertir les arguments en chaîne de caractères
        args_str = str(args)
        kwargs_str = str(sorted(kwargs.items()))

        # Générer un hash SHA-256
        hash_obj = hashlib.sha256()
        hash_obj.update(func_name.encode('utf-8'))
        hash_obj.update(args_str.encode('utf-8'))
        hash_obj.update(kwargs_str.encode('utf-8'))
        hash_key = hash_obj.hexdigest()

        return f"{key_prefix}func:{hash_key}"


def cached_property(ttl: Optional[int] = None, key_prefix: str = "",
                   cache_instance: Optional[LocalCache] = None) -> Callable:
    """
    Décorateur pour mettre en cache les résultats d'une propriété.

    Args:
        ttl (int, optional): Durée de vie du résultat en secondes.
            Si None, utilise la durée de vie par défaut du cache.
        key_prefix (str, optional): Préfixe pour la clé de cache.
        cache_instance (LocalCache, optional): Instance de LocalCache à utiliser.
            Si None, une nouvelle instance sera créée.

    Returns:
        Callable: Décorateur de mise en cache pour une propriété.
    """
    def decorator(func):
        # Créer ou utiliser une instance de cache
        nonlocal cache_instance
        if cache_instance is None:
            cache_instance = LocalCache()

        @property
        @functools.wraps(func)
        def wrapper(self):
            # Générer une clé de cache
            func_name = func.__module__ + "." + func.__name__
            obj_id = id(self)
            cache_key = f"{key_prefix}prop:{func_name}:{obj_id}"

            # Vérifier si le résultat est dans le cache
            cached_result = cache_instance.get(cache_key)
            if cached_result is not None:
                return cached_result

            # Exécuter la fonction et mettre en cache le résultat
            result = func(self)
            cache_instance.set(cache_key, result, ttl)

            return result

        return wrapper

    return decorator


def cached_class(ttl: Optional[int] = None, key_prefix: str = "",
                cache_instance: Optional[LocalCache] = None) -> Callable:
    """
    Décorateur pour mettre en cache les instances d'une classe.

    Args:
        ttl (int, optional): Durée de vie du résultat en secondes.
            Si None, utilise la durée de vie par défaut du cache.
        key_prefix (str, optional): Préfixe pour la clé de cache.
        cache_instance (LocalCache, optional): Instance de LocalCache à utiliser.
            Si None, une nouvelle instance sera créée.

    Returns:
        Callable: Décorateur de mise en cache pour une classe.
    """
    def decorator(cls):
        # Créer ou utiliser une instance de cache
        nonlocal cache_instance
        if cache_instance is None:
            cache_instance = LocalCache()

        # Sauvegarder le constructeur original
        original_init = cls.__init__

        @functools.wraps(original_init)
        def new_init(self, *args, **kwargs):
            # Générer une clé de cache
            cls_name = cls.__module__ + "." + cls.__name__
            # Convertir les arguments en chaîne de caractères
            args_str = str(args)
            kwargs_str = str(sorted(kwargs.items()))

            # Générer un hash SHA-256
            hash_obj = hashlib.sha256()
            hash_obj.update(cls_name.encode('utf-8'))
            hash_obj.update(args_str.encode('utf-8'))
            hash_obj.update(kwargs_str.encode('utf-8'))
            hash_key = hash_obj.hexdigest()

            self._cache_key = f"{key_prefix}cls:{hash_key}"
            self._cache_instance = cache_instance

            # Appeler le constructeur original
            original_init(self, *args, **kwargs)

        # Remplacer le constructeur
        cls.__init__ = new_init

        # Ajouter des méthodes utilitaires à la classe
        cls.invalidate_cache = lambda self: cache_instance.delete(self._cache_key)
        cls.get_cache_key = lambda self: self._cache_key

        # Créer une nouvelle méthode de classe pour créer ou récupérer une instance
        @classmethod
        def get_instance(cls, *args, **kwargs):
            # Générer une clé de cache
            cls_name = cls.__module__ + "." + cls.__name__
            # Convertir les arguments en chaîne de caractères
            args_str = str(args)
            kwargs_str = str(sorted(kwargs.items()))

            # Générer un hash SHA-256
            hash_obj = hashlib.sha256()
            hash_obj.update(cls_name.encode('utf-8'))
            hash_obj.update(args_str.encode('utf-8'))
            hash_obj.update(kwargs_str.encode('utf-8'))
            hash_key = hash_obj.hexdigest()

            cache_key = f"{key_prefix}cls:{hash_key}"

            # Vérifier si l'instance est dans le cache
            cached_instance = cache_instance.get(cache_key)
            if cached_instance is not None:
                return cached_instance

            # Créer une nouvelle instance
            instance = cls(*args, **kwargs)
            cache_instance.set(cache_key, instance, ttl)

            return instance

        # Ajouter la méthode de classe
        cls.get_instance = get_instance

        return cls

    return decorator


def timed_cache(seconds: int = 60, maxsize: int = 128, typed: bool = False) -> Callable:
    """
    Décorateur pour mettre en cache les résultats d'une fonction pendant une durée limitée.
    Utilise functools.lru_cache en interne.

    Args:
        seconds (int, optional): Durée de vie du cache en secondes. Par défaut: 60.
        maxsize (int, optional): Nombre maximum d'entrées dans le cache. Par défaut: 128.
        typed (bool, optional): Si True, les arguments de différents types sont mis en cache séparément.
            Par défaut: False.

    Returns:
        Callable: Décorateur de mise en cache.
    """
    def decorator(func):
        # Utiliser une fonction pour stocker le temps d'expiration
        expiration = [time.time() + seconds]
        
        # Créer un cache LRU
        @functools.lru_cache(maxsize=maxsize, typed=typed)
        def cached_func(*args, **kwargs):
            return func(*args, **kwargs)
        
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            # Vérifier si le cache a expiré
            if time.time() > expiration[0]:
                cached_func.cache_clear()
                expiration[0] = time.time() + seconds
            
            return cached_func(*args, **kwargs)
        
        # Ajouter des méthodes utilitaires au wrapper
        wrapper.cache_clear = cached_func.cache_clear
        wrapper.cache_info = cached_func.cache_info
        wrapper.set_expiration = lambda s: expiration.__setitem__(0, time.time() + s)
        
        return wrapper
    
    return decorator


def cache_result(result_key: Callable, ttl: Optional[int] = None,
                cache_instance: Optional[LocalCache] = None) -> Callable:
    """
    Décorateur pour mettre en cache les résultats d'une fonction en utilisant une clé
    extraite du résultat lui-même.

    Args:
        result_key (Callable): Fonction qui extrait la clé de cache du résultat.
        ttl (int, optional): Durée de vie du résultat en secondes.
            Si None, utilise la durée de vie par défaut du cache.
        cache_instance (LocalCache, optional): Instance de LocalCache à utiliser.
            Si None, une nouvelle instance sera créée.

    Returns:
        Callable: Décorateur de mise en cache.
    """
    def decorator(func):
        # Créer ou utiliser une instance de cache
        nonlocal cache_instance
        if cache_instance is None:
            cache_instance = LocalCache()

        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            # Exécuter la fonction
            result = func(*args, **kwargs)
            
            # Extraire la clé du résultat
            key = result_key(result)
            
            # Mettre en cache le résultat
            cache_instance.set(key, result, ttl)
            
            return result
        
        # Ajouter des méthodes utilitaires au wrapper
        wrapper.get_cached = lambda key: cache_instance.get(key)
        wrapper.invalidate = lambda key: cache_instance.delete(key)
        wrapper.clear_cache = lambda: cache_instance.clear()
        wrapper.cache_instance = cache_instance
        
        return wrapper
    
    return decorator


if __name__ == "__main__":
    # Exemple d'utilisation
    cache = LocalCache()
    
    # Exemple avec le décorateur cached
    @cached(ttl=60, cache_instance=cache)
    def expensive_function(param):
        print(f"Exécution de la fonction coûteuse avec param={param}")
        return param.upper()
    
    # Premier appel (exécute la fonction)
    result1 = expensive_function("test")
    print(f"Résultat 1: {result1}")
    
    # Deuxième appel (utilise le cache)
    result2 = expensive_function("test")
    print(f"Résultat 2: {result2}")
    
    # Invalider le cache
    expensive_function.invalidate_cache("test")
    
    # Troisième appel (exécute à nouveau la fonction)
    result3 = expensive_function("test")
    print(f"Résultat 3: {result3}")
    
    # Exemple avec le décorateur timed_cache
    @timed_cache(seconds=5)
    def timed_function(param):
        print(f"Exécution de la fonction avec expiration avec param={param}")
        return param.upper()
    
    # Premier appel (exécute la fonction)
    result1 = timed_function("test")
    print(f"Résultat 1: {result1}")
    
    # Deuxième appel (utilise le cache)
    result2 = timed_function("test")
    print(f"Résultat 2: {result2}")
    
    # Attendre l'expiration du cache
    print("Attente de l'expiration du cache (5 secondes)...")
    time.sleep(5)
    
    # Troisième appel (exécute à nouveau la fonction)
    result3 = timed_function("test")
    print(f"Résultat 3: {result3}")
