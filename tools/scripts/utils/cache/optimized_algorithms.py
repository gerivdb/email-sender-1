#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module d'algorithmes optimisés pour le cache.

Ce module fournit des implémentations optimisées des algorithmes
utilisés par le système de cache pour améliorer les performances.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import time
import json
import logging
import hashlib
import functools
from typing import Dict, List, Any, Optional, Tuple, Callable, TypeVar, Generic, Union
from collections import OrderedDict, Counter

# Configurer le logger
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Type générique pour les valeurs
T = TypeVar('T')


class OptimizedLRUCache(Generic[T]):
    """
    Implémentation optimisée d'un cache LRU (Least Recently Used).
    
    Cette classe utilise OrderedDict pour une implémentation efficace
    de l'algorithme LRU avec une complexité O(1) pour les opérations courantes.
    """
    
    def __init__(self, capacity: int):
        """
        Initialise le cache LRU.
        
        Args:
            capacity (int): Capacité maximale du cache.
        """
        self.capacity = capacity
        self.cache = OrderedDict()
    
    def get(self, key: str) -> Optional[T]:
        """
        Récupère une valeur du cache.
        
        Args:
            key (str): Clé de l'élément à récupérer.
            
        Returns:
            Optional[T]: Valeur associée à la clé ou None si la clé n'existe pas.
        """
        if key not in self.cache:
            return None
        
        # Déplacer l'élément à la fin (le plus récemment utilisé)
        self.cache.move_to_end(key)
        return self.cache[key]
    
    def put(self, key: str, value: T) -> None:
        """
        Stocke une valeur dans le cache.
        
        Args:
            key (str): Clé de l'élément à stocker.
            value (T): Valeur de l'élément à stocker.
        """
        # Si la clé existe déjà, la mettre à jour et la déplacer à la fin
        if key in self.cache:
            self.cache[key] = value
            self.cache.move_to_end(key)
            return
        
        # Si le cache est plein, supprimer l'élément le moins récemment utilisé
        if len(self.cache) >= self.capacity:
            self.cache.popitem(last=False)
        
        # Ajouter le nouvel élément
        self.cache[key] = value
    
    def remove(self, key: str) -> bool:
        """
        Supprime un élément du cache.
        
        Args:
            key (str): Clé de l'élément à supprimer.
            
        Returns:
            bool: True si l'élément a été supprimé, False sinon.
        """
        if key in self.cache:
            del self.cache[key]
            return True
        return False
    
    def clear(self) -> None:
        """Vide le cache."""
        self.cache.clear()
    
    def __len__(self) -> int:
        """Retourne le nombre d'éléments dans le cache."""
        return len(self.cache)
    
    def __contains__(self, key: str) -> bool:
        """Vérifie si une clé existe dans le cache."""
        return key in self.cache
    
    def keys(self) -> List[str]:
        """Retourne la liste des clés dans le cache."""
        return list(self.cache.keys())
    
    def values(self) -> List[T]:
        """Retourne la liste des valeurs dans le cache."""
        return list(self.cache.values())
    
    def items(self) -> List[Tuple[str, T]]:
        """Retourne la liste des paires (clé, valeur) dans le cache."""
        return list(self.cache.items())


class OptimizedLFUCache(Generic[T]):
    """
    Implémentation optimisée d'un cache LFU (Least Frequently Used).
    
    Cette classe utilise une combinaison de dictionnaires et de listes
    pour une implémentation efficace de l'algorithme LFU.
    """
    
    def __init__(self, capacity: int):
        """
        Initialise le cache LFU.
        
        Args:
            capacity (int): Capacité maximale du cache.
        """
        self.capacity = capacity
        self.min_freq = 0
        self.key_to_val = {}  # key -> value
        self.key_to_freq = {}  # key -> frequency
        self.freq_to_keys = {}  # frequency -> set of keys
    
    def get(self, key: str) -> Optional[T]:
        """
        Récupère une valeur du cache.
        
        Args:
            key (str): Clé de l'élément à récupérer.
            
        Returns:
            Optional[T]: Valeur associée à la clé ou None si la clé n'existe pas.
        """
        if key not in self.key_to_val:
            return None
        
        # Mettre à jour la fréquence
        self._update_frequency(key)
        
        return self.key_to_val[key]
    
    def put(self, key: str, value: T) -> None:
        """
        Stocke une valeur dans le cache.
        
        Args:
            key (str): Clé de l'élément à stocker.
            value (T): Valeur de l'élément à stocker.
        """
        # Si la capacité est 0, ne rien faire
        if self.capacity == 0:
            return
        
        # Si la clé existe déjà, mettre à jour la valeur et la fréquence
        if key in self.key_to_val:
            self.key_to_val[key] = value
            self._update_frequency(key)
            return
        
        # Si le cache est plein, supprimer l'élément le moins fréquemment utilisé
        if len(self.key_to_val) >= self.capacity:
            self._remove_least_frequent()
        
        # Ajouter le nouvel élément avec une fréquence de 1
        self.key_to_val[key] = value
        self.key_to_freq[key] = 1
        if 1 not in self.freq_to_keys:
            self.freq_to_keys[1] = set()
        self.freq_to_keys[1].add(key)
        self.min_freq = 1
    
    def remove(self, key: str) -> bool:
        """
        Supprime un élément du cache.
        
        Args:
            key (str): Clé de l'élément à supprimer.
            
        Returns:
            bool: True si l'élément a été supprimé, False sinon.
        """
        if key not in self.key_to_val:
            return False
        
        # Récupérer la fréquence
        freq = self.key_to_freq[key]
        
        # Supprimer la clé des structures de données
        del self.key_to_val[key]
        del self.key_to_freq[key]
        self.freq_to_keys[freq].remove(key)
        
        # Si la fréquence n'a plus de clés, la supprimer
        if not self.freq_to_keys[freq]:
            del self.freq_to_keys[freq]
            
            # Mettre à jour min_freq si nécessaire
            if freq == self.min_freq:
                self.min_freq = min(self.freq_to_keys.keys()) if self.freq_to_keys else 0
        
        return True
    
    def clear(self) -> None:
        """Vide le cache."""
        self.key_to_val.clear()
        self.key_to_freq.clear()
        self.freq_to_keys.clear()
        self.min_freq = 0
    
    def _update_frequency(self, key: str) -> None:
        """
        Met à jour la fréquence d'une clé.
        
        Args:
            key (str): Clé à mettre à jour.
        """
        # Récupérer l'ancienne fréquence
        old_freq = self.key_to_freq[key]
        
        # Calculer la nouvelle fréquence
        new_freq = old_freq + 1
        
        # Mettre à jour les structures de données
        self.key_to_freq[key] = new_freq
        self.freq_to_keys[old_freq].remove(key)
        
        # Si l'ancienne fréquence n'a plus de clés, la supprimer
        if not self.freq_to_keys[old_freq]:
            del self.freq_to_keys[old_freq]
            
            # Mettre à jour min_freq si nécessaire
            if old_freq == self.min_freq:
                self.min_freq = new_freq
        
        # Ajouter la clé à la nouvelle fréquence
        if new_freq not in self.freq_to_keys:
            self.freq_to_keys[new_freq] = set()
        self.freq_to_keys[new_freq].add(key)
    
    def _remove_least_frequent(self) -> None:
        """Supprime l'élément le moins fréquemment utilisé."""
        # Récupérer une clé avec la fréquence minimale
        key_to_remove = next(iter(self.freq_to_keys[self.min_freq]))
        
        # Supprimer la clé des structures de données
        self.freq_to_keys[self.min_freq].remove(key_to_remove)
        if not self.freq_to_keys[self.min_freq]:
            del self.freq_to_keys[self.min_freq]
        
        del self.key_to_val[key_to_remove]
        del self.key_to_freq[key_to_remove]
    
    def __len__(self) -> int:
        """Retourne le nombre d'éléments dans le cache."""
        return len(self.key_to_val)
    
    def __contains__(self, key: str) -> bool:
        """Vérifie si une clé existe dans le cache."""
        return key in self.key_to_val
    
    def keys(self) -> List[str]:
        """Retourne la liste des clés dans le cache."""
        return list(self.key_to_val.keys())
    
    def values(self) -> List[T]:
        """Retourne la liste des valeurs dans le cache."""
        return list(self.key_to_val.values())
    
    def items(self) -> List[Tuple[str, T]]:
        """Retourne la liste des paires (clé, valeur) dans le cache."""
        return list(self.key_to_val.items())


class OptimizedARCache(Generic[T]):
    """
    Implémentation optimisée d'un cache ARC (Adaptive Replacement Cache).
    
    Cette classe implémente l'algorithme ARC qui combine les avantages
    des algorithmes LRU et LFU pour une meilleure performance.
    """
    
    def __init__(self, capacity: int):
        """
        Initialise le cache ARC.
        
        Args:
            capacity (int): Capacité maximale du cache.
        """
        self.capacity = capacity
        
        # Diviser la capacité en deux parties égales
        self.p = 0  # Taille adaptative de T1
        
        # T1: Cache LRU pour les éléments récemment utilisés
        self.t1 = OrderedDict()
        
        # T2: Cache LRU pour les éléments fréquemment utilisés
        self.t2 = OrderedDict()
        
        # B1: Historique des éléments récemment évincés de T1
        self.b1 = OrderedDict()
        
        # B2: Historique des éléments récemment évincés de T2
        self.b2 = OrderedDict()
    
    def get(self, key: str) -> Optional[T]:
        """
        Récupère une valeur du cache.
        
        Args:
            key (str): Clé de l'élément à récupérer.
            
        Returns:
            Optional[T]: Valeur associée à la clé ou None si la clé n'existe pas.
        """
        # Cas 1: La clé est dans T1
        if key in self.t1:
            # Déplacer de T1 à T2
            value = self.t1.pop(key)
            self.t2[key] = value
            return value
        
        # Cas 2: La clé est dans T2
        if key in self.t2:
            # Déplacer à la fin de T2
            value = self.t2.pop(key)
            self.t2[key] = value
            return value
        
        # La clé n'est pas dans le cache
        return None
    
    def put(self, key: str, value: T) -> None:
        """
        Stocke une valeur dans le cache.
        
        Args:
            key (str): Clé de l'élément à stocker.
            value (T): Valeur de l'élément à stocker.
        """
        # Cas 1: La clé est déjà dans T1 ou T2
        if key in self.t1:
            # Mettre à jour la valeur et déplacer de T1 à T2
            self.t1.pop(key)
            self.t2[key] = value
            return
        
        if key in self.t2:
            # Mettre à jour la valeur et déplacer à la fin de T2
            self.t2.pop(key)
            self.t2[key] = value
            return
        
        # Cas 2: La clé est dans B1
        if key in self.b1:
            # Adapter p = min(c, p + max(|B2| / |B1|, 1))
            b1_size = len(self.b1)
            b2_size = len(self.b2)
            delta = 1 if b1_size == 0 else max(b2_size // b1_size, 1)
            self.p = min(self.capacity, self.p + delta)
            
            # Remplacer un élément
            self._replace(key)
            
            # Supprimer de B1 et ajouter à T2
            self.b1.pop(key)
            self.t2[key] = value
            return
        
        # Cas 3: La clé est dans B2
        if key in self.b2:
            # Adapter p = max(0, p - max(|B1| / |B2|, 1))
            b1_size = len(self.b1)
            b2_size = len(self.b2)
            delta = 1 if b2_size == 0 else max(b1_size // b2_size, 1)
            self.p = max(0, self.p - delta)
            
            # Remplacer un élément
            self._replace(key)
            
            # Supprimer de B2 et ajouter à T2
            self.b2.pop(key)
            self.t2[key] = value
            return
        
        # Cas 4: La clé n'est ni dans le cache ni dans l'historique
        
        # Cas 4.1: L1 a atteint sa taille maximale
        l1_size = len(self.t1) + len(self.b1)
        if l1_size == self.capacity:
            # Si B1 est vide, supprimer l'élément le plus ancien de T1
            if len(self.b1) > 0:
                # Supprimer l'élément le plus ancien de B1
                self.b1.popitem(last=False)
            else:
                # Supprimer l'élément le plus ancien de T1
                self.t1.popitem(last=False)
        
        # Cas 4.2: L1 n'a pas atteint sa taille maximale, mais le cache est plein
        elif l1_size < self.capacity and len(self.t1) + len(self.t2) >= self.capacity:
            # Remplacer un élément
            self._replace(None)
        
        # Ajouter la nouvelle clé à T1
        self.t1[key] = value
    
    def remove(self, key: str) -> bool:
        """
        Supprime un élément du cache.
        
        Args:
            key (str): Clé de l'élément à supprimer.
            
        Returns:
            bool: True si l'élément a été supprimé, False sinon.
        """
        if key in self.t1:
            del self.t1[key]
            return True
        
        if key in self.t2:
            del self.t2[key]
            return True
        
        return False
    
    def clear(self) -> None:
        """Vide le cache."""
        self.t1.clear()
        self.t2.clear()
        self.b1.clear()
        self.b2.clear()
        self.p = 0
    
    def _replace(self, key: Optional[str]) -> None:
        """
        Remplace un élément dans le cache.
        
        Args:
            key (Optional[str]): Clé qui va être ajoutée (pour éviter de la supprimer).
        """
        # Si T1 est non vide et (|T1| > p ou key est dans B2)
        if len(self.t1) > 0 and (len(self.t1) > self.p or (key is not None and key in self.b2)):
            # Supprimer l'élément le plus ancien de T1 et l'ajouter à B1
            old_key, old_value = self.t1.popitem(last=False)
            self.b1[old_key] = None  # La valeur n'est pas importante dans B1
            
            # Limiter la taille de B1
            while len(self.b1) > self.capacity:
                self.b1.popitem(last=False)
        else:
            # Supprimer l'élément le plus ancien de T2 et l'ajouter à B2
            old_key, old_value = self.t2.popitem(last=False)
            self.b2[old_key] = None  # La valeur n'est pas importante dans B2
            
            # Limiter la taille de B2
            while len(self.b2) > self.capacity:
                self.b2.popitem(last=False)
    
    def __len__(self) -> int:
        """Retourne le nombre d'éléments dans le cache."""
        return len(self.t1) + len(self.t2)
    
    def __contains__(self, key: str) -> bool:
        """Vérifie si une clé existe dans le cache."""
        return key in self.t1 or key in self.t2
    
    def keys(self) -> List[str]:
        """Retourne la liste des clés dans le cache."""
        return list(self.t1.keys()) + list(self.t2.keys())
    
    def values(self) -> List[T]:
        """Retourne la liste des valeurs dans le cache."""
        return list(self.t1.values()) + list(self.t2.values())
    
    def items(self) -> List[Tuple[str, T]]:
        """Retourne la liste des paires (clé, valeur) dans le cache."""
        return list(self.t1.items()) + list(self.t2.items())


# Fonction optimisée pour générer des clés de cache
def optimized_key_generator(prefix: str, *args, **kwargs) -> str:
    """
    Génère une clé de cache optimisée.
    
    Args:
        prefix (str): Préfixe de la clé.
        *args: Arguments positionnels.
        **kwargs: Arguments nommés.
        
    Returns:
        str: Clé de cache.
    """
    # Convertir les arguments en chaînes de caractères
    args_str = ','.join(str(arg) for arg in args)
    kwargs_str = ','.join(f"{k}={v}" for k, v in sorted(kwargs.items()))
    
    # Générer un hash SHA-256 tronqué
    hash_input = f"{args_str}|{kwargs_str}"
    hash_obj = hashlib.sha256(hash_input.encode('utf-8'))
    hash_hex = hash_obj.hexdigest()[:16]  # Utiliser seulement les 16 premiers caractères
    
    # Construire la clé
    return f"{prefix}:{hash_hex}"


# Fonction pour créer un cache optimisé
def create_optimized_cache(algorithm: str, capacity: int) -> Union[OptimizedLRUCache, OptimizedLFUCache, OptimizedARCache]:
    """
    Crée un cache optimisé.
    
    Args:
        algorithm (str): Algorithme à utiliser ('lru', 'lfu', 'arc').
        capacity (int): Capacité du cache.
        
    Returns:
        Union[OptimizedLRUCache, OptimizedLFUCache, OptimizedARCache]: Cache optimisé.
        
    Raises:
        ValueError: Si l'algorithme est invalide.
    """
    algorithm = algorithm.lower()
    
    if algorithm == 'lru':
        return OptimizedLRUCache(capacity)
    elif algorithm == 'lfu':
        return OptimizedLFUCache(capacity)
    elif algorithm == 'arc':
        return OptimizedARCache(capacity)
    else:
        raise ValueError(f"Algorithme invalide: {algorithm}")


if __name__ == "__main__":
    # Exemple d'utilisation
    
    # Créer un cache LRU
    lru_cache = OptimizedLRUCache(capacity=100)
    
    # Ajouter des éléments
    for i in range(200):
        lru_cache.put(f"key{i}", f"value{i}")
    
    # Vérifier la taille du cache
    print(f"Taille du cache LRU: {len(lru_cache)}")
    
    # Récupérer un élément
    print(f"Valeur pour key50: {lru_cache.get('key50')}")
    
    # Créer un cache LFU
    lfu_cache = OptimizedLFUCache(capacity=100)
    
    # Ajouter des éléments
    for i in range(200):
        lfu_cache.put(f"key{i}", f"value{i}")
    
    # Accéder à certains éléments plusieurs fois
    for _ in range(5):
        lfu_cache.get("key10")
        lfu_cache.get("key20")
        lfu_cache.get("key30")
    
    # Vérifier la taille du cache
    print(f"Taille du cache LFU: {len(lfu_cache)}")
    
    # Récupérer un élément fréquemment utilisé
    print(f"Valeur pour key10: {lfu_cache.get('key10')}")
    
    # Créer un cache ARC
    arc_cache = OptimizedARCache(capacity=100)
    
    # Ajouter des éléments
    for i in range(200):
        arc_cache.put(f"key{i}", f"value{i}")
    
    # Vérifier la taille du cache
    print(f"Taille du cache ARC: {len(arc_cache)}")
    
    # Récupérer un élément
    print(f"Valeur pour key50: {arc_cache.get('key50')}")
    
    # Tester la fonction de génération de clé optimisée
    key = optimized_key_generator("test", 123, "abc", x=1, y=2)
    print(f"Clé optimisée: {key}")
