#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de stratégies d'éviction pour le cache.

Ce module fournit différentes stratégies d'éviction pour le cache,
permettant d'optimiser l'utilisation de la mémoire en supprimant les éléments
selon différents critères (LRU, LFU, FIFO, etc.).

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import time
import heapq
import logging
from abc import ABC, abstractmethod
from typing import Dict, List, Any, Optional, Tuple, Set
from collections import OrderedDict, Counter

# Configurer le logger
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class EvictionStrategy(ABC):
    """
    Interface abstraite pour les stratégies d'éviction.
    
    Cette classe définit l'interface commune à toutes les stratégies d'éviction.
    """
    
    @abstractmethod
    def register_access(self, key: str) -> None:
        """
        Enregistre un accès à une clé.
        
        Args:
            key (str): Clé accédée.
        """
        pass
    
    @abstractmethod
    def register_set(self, key: str, size: int = 1) -> None:
        """
        Enregistre l'ajout ou la mise à jour d'une clé.
        
        Args:
            key (str): Clé ajoutée ou mise à jour.
            size (int, optional): Taille de la valeur. Par défaut: 1.
        """
        pass
    
    @abstractmethod
    def register_delete(self, key: str) -> None:
        """
        Enregistre la suppression d'une clé.
        
        Args:
            key (str): Clé supprimée.
        """
        pass
    
    @abstractmethod
    def get_eviction_candidates(self, count: int = 1) -> List[str]:
        """
        Récupère les clés candidates à l'éviction.
        
        Args:
            count (int, optional): Nombre de clés à récupérer. Par défaut: 1.
            
        Returns:
            List[str]: Liste des clés candidates à l'éviction.
        """
        pass
    
    @abstractmethod
    def clear(self) -> None:
        """
        Vide la stratégie d'éviction.
        """
        pass


class LRUStrategy(EvictionStrategy):
    """
    Stratégie d'éviction Least Recently Used (LRU).
    
    Cette stratégie supprime les éléments les moins récemment utilisés.
    """
    
    def __init__(self):
        """
        Initialise la stratégie LRU.
        """
        # Utiliser un OrderedDict pour maintenir l'ordre d'accès
        self.access_order = OrderedDict()
    
    def register_access(self, key: str) -> None:
        """
        Enregistre un accès à une clé.
        
        Args:
            key (str): Clé accédée.
        """
        # Déplacer la clé à la fin (la plus récemment utilisée)
        if key in self.access_order:
            self.access_order.move_to_end(key)
        else:
            self.access_order[key] = None
    
    def register_set(self, key: str, size: int = 1) -> None:
        """
        Enregistre l'ajout ou la mise à jour d'une clé.
        
        Args:
            key (str): Clé ajoutée ou mise à jour.
            size (int, optional): Taille de la valeur. Par défaut: 1.
        """
        # Traiter comme un accès
        self.register_access(key)
    
    def register_delete(self, key: str) -> None:
        """
        Enregistre la suppression d'une clé.
        
        Args:
            key (str): Clé supprimée.
        """
        # Supprimer la clé de l'ordre d'accès
        if key in self.access_order:
            del self.access_order[key]
    
    def get_eviction_candidates(self, count: int = 1) -> List[str]:
        """
        Récupère les clés candidates à l'éviction.
        
        Args:
            count (int, optional): Nombre de clés à récupérer. Par défaut: 1.
            
        Returns:
            List[str]: Liste des clés candidates à l'éviction.
        """
        # Récupérer les clés les moins récemment utilisées
        candidates = []
        for key in self.access_order:
            candidates.append(key)
            if len(candidates) >= count:
                break
        return candidates
    
    def clear(self) -> None:
        """
        Vide la stratégie d'éviction.
        """
        self.access_order.clear()


class LFUStrategy(EvictionStrategy):
    """
    Stratégie d'éviction Least Frequently Used (LFU).
    
    Cette stratégie supprime les éléments les moins fréquemment utilisés.
    """
    
    def __init__(self):
        """
        Initialise la stratégie LFU.
        """
        # Compteur d'accès pour chaque clé
        self.access_count = Counter()
        
        # Horodatage du dernier accès pour départager les ex-aequo
        self.last_access = {}
    
    def register_access(self, key: str) -> None:
        """
        Enregistre un accès à une clé.
        
        Args:
            key (str): Clé accédée.
        """
        # Incrémenter le compteur d'accès
        self.access_count[key] += 1
        
        # Mettre à jour l'horodatage du dernier accès
        self.last_access[key] = time.time()
    
    def register_set(self, key: str, size: int = 1) -> None:
        """
        Enregistre l'ajout ou la mise à jour d'une clé.
        
        Args:
            key (str): Clé ajoutée ou mise à jour.
            size (int, optional): Taille de la valeur. Par défaut: 1.
        """
        # Traiter comme un accès
        self.register_access(key)
    
    def register_delete(self, key: str) -> None:
        """
        Enregistre la suppression d'une clé.
        
        Args:
            key (str): Clé supprimée.
        """
        # Supprimer la clé des compteurs
        if key in self.access_count:
            del self.access_count[key]
        
        if key in self.last_access:
            del self.last_access[key]
    
    def get_eviction_candidates(self, count: int = 1) -> List[str]:
        """
        Récupère les clés candidates à l'éviction.
        
        Args:
            count (int, optional): Nombre de clés à récupérer. Par défaut: 1.
            
        Returns:
            List[str]: Liste des clés candidates à l'éviction.
        """
        # Récupérer les clés les moins fréquemment utilisées
        candidates = []
        
        # Trier les clés par fréquence d'accès, puis par dernier accès
        sorted_keys = sorted(
            self.access_count.keys(),
            key=lambda k: (self.access_count[k], self.last_access.get(k, 0))
        )
        
        # Récupérer les premières clés
        candidates = sorted_keys[:count]
        
        return candidates
    
    def clear(self) -> None:
        """
        Vide la stratégie d'éviction.
        """
        self.access_count.clear()
        self.last_access.clear()


class FIFOStrategy(EvictionStrategy):
    """
    Stratégie d'éviction First In, First Out (FIFO).
    
    Cette stratégie supprime les éléments les plus anciens.
    """
    
    def __init__(self):
        """
        Initialise la stratégie FIFO.
        """
        # Liste des clés dans l'ordre d'insertion
        self.insertion_order = []
        
        # Ensemble des clés pour une recherche rapide
        self.keys = set()
    
    def register_access(self, key: str) -> None:
        """
        Enregistre un accès à une clé.
        
        Args:
            key (str): Clé accédée.
        """
        # Ne rien faire, FIFO ne dépend pas des accès
        pass
    
    def register_set(self, key: str, size: int = 1) -> None:
        """
        Enregistre l'ajout ou la mise à jour d'une clé.
        
        Args:
            key (str): Clé ajoutée ou mise à jour.
            size (int, optional): Taille de la valeur. Par défaut: 1.
        """
        # Si la clé existe déjà, la supprimer pour la réinsérer à la fin
        if key in self.keys:
            self.insertion_order.remove(key)
        
        # Ajouter la clé à la fin
        self.insertion_order.append(key)
        self.keys.add(key)
    
    def register_delete(self, key: str) -> None:
        """
        Enregistre la suppression d'une clé.
        
        Args:
            key (str): Clé supprimée.
        """
        # Supprimer la clé
        if key in self.keys:
            self.insertion_order.remove(key)
            self.keys.remove(key)
    
    def get_eviction_candidates(self, count: int = 1) -> List[str]:
        """
        Récupère les clés candidates à l'éviction.
        
        Args:
            count (int, optional): Nombre de clés à récupérer. Par défaut: 1.
            
        Returns:
            List[str]: Liste des clés candidates à l'éviction.
        """
        # Récupérer les premières clés (les plus anciennes)
        return self.insertion_order[:count]
    
    def clear(self) -> None:
        """
        Vide la stratégie d'éviction.
        """
        self.insertion_order.clear()
        self.keys.clear()


class SizeAwareStrategy(EvictionStrategy):
    """
    Stratégie d'éviction basée sur la taille des éléments.
    
    Cette stratégie supprime les éléments les plus volumineux.
    """
    
    def __init__(self):
        """
        Initialise la stratégie basée sur la taille.
        """
        # Dictionnaire des tailles des éléments
        self.sizes = {}
    
    def register_access(self, key: str) -> None:
        """
        Enregistre un accès à une clé.
        
        Args:
            key (str): Clé accédée.
        """
        # Ne rien faire, cette stratégie ne dépend pas des accès
        pass
    
    def register_set(self, key: str, size: int = 1) -> None:
        """
        Enregistre l'ajout ou la mise à jour d'une clé.
        
        Args:
            key (str): Clé ajoutée ou mise à jour.
            size (int, optional): Taille de la valeur. Par défaut: 1.
        """
        # Enregistrer la taille
        self.sizes[key] = size
    
    def register_delete(self, key: str) -> None:
        """
        Enregistre la suppression d'une clé.
        
        Args:
            key (str): Clé supprimée.
        """
        # Supprimer la clé
        if key in self.sizes:
            del self.sizes[key]
    
    def get_eviction_candidates(self, count: int = 1) -> List[str]:
        """
        Récupère les clés candidates à l'éviction.
        
        Args:
            count (int, optional): Nombre de clés à récupérer. Par défaut: 1.
            
        Returns:
            List[str]: Liste des clés candidates à l'éviction.
        """
        # Récupérer les clés les plus volumineuses
        sorted_keys = sorted(self.sizes.keys(), key=lambda k: self.sizes[k], reverse=True)
        return sorted_keys[:count]
    
    def clear(self) -> None:
        """
        Vide la stratégie d'éviction.
        """
        self.sizes.clear()


class TTLAwareStrategy(EvictionStrategy):
    """
    Stratégie d'éviction basée sur la durée de vie (TTL) des éléments.
    
    Cette stratégie supprime les éléments dont la durée de vie est la plus courte.
    """
    
    def __init__(self):
        """
        Initialise la stratégie basée sur la durée de vie.
        """
        # Dictionnaire des TTL des éléments
        self.ttls = {}
        
        # Horodatage d'insertion des éléments
        self.insertion_times = {}
    
    def register_access(self, key: str) -> None:
        """
        Enregistre un accès à une clé.
        
        Args:
            key (str): Clé accédée.
        """
        # Ne rien faire, cette stratégie ne dépend pas des accès
        pass
    
    def register_set(self, key: str, size: int = 1, ttl: Optional[int] = None) -> None:
        """
        Enregistre l'ajout ou la mise à jour d'une clé.
        
        Args:
            key (str): Clé ajoutée ou mise à jour.
            size (int, optional): Taille de la valeur. Par défaut: 1.
            ttl (int, optional): Durée de vie en secondes. Par défaut: None.
        """
        # Enregistrer le TTL et l'horodatage d'insertion
        if ttl is not None:
            self.ttls[key] = ttl
            self.insertion_times[key] = time.time()
    
    def register_delete(self, key: str) -> None:
        """
        Enregistre la suppression d'une clé.
        
        Args:
            key (str): Clé supprimée.
        """
        # Supprimer la clé
        if key in self.ttls:
            del self.ttls[key]
        
        if key in self.insertion_times:
            del self.insertion_times[key]
    
    def get_eviction_candidates(self, count: int = 1) -> List[str]:
        """
        Récupère les clés candidates à l'éviction.
        
        Args:
            count (int, optional): Nombre de clés à récupérer. Par défaut: 1.
            
        Returns:
            List[str]: Liste des clés candidates à l'éviction.
        """
        # Calculer le temps restant pour chaque clé
        now = time.time()
        remaining_times = {}
        
        for key in self.ttls:
            if key in self.insertion_times:
                elapsed = now - self.insertion_times[key]
                remaining = self.ttls[key] - elapsed
                remaining_times[key] = max(0, remaining)
        
        # Récupérer les clés avec le temps restant le plus court
        sorted_keys = sorted(remaining_times.keys(), key=lambda k: remaining_times[k])
        return sorted_keys[:count]
    
    def clear(self) -> None:
        """
        Vide la stratégie d'éviction.
        """
        self.ttls.clear()
        self.insertion_times.clear()


class CompositeStrategy(EvictionStrategy):
    """
    Stratégie d'éviction composite.
    
    Cette stratégie combine plusieurs stratégies d'éviction avec des poids différents.
    """
    
    def __init__(self, strategies: Dict[EvictionStrategy, float]):
        """
        Initialise la stratégie composite.
        
        Args:
            strategies (Dict[EvictionStrategy, float]): Dictionnaire des stratégies avec leurs poids.
                Les poids doivent être positifs et leur somme doit être égale à 1.
        """
        # Vérifier que les poids sont valides
        total_weight = sum(strategies.values())
        if abs(total_weight - 1.0) > 1e-6:
            raise ValueError("La somme des poids doit être égale à 1")
        
        self.strategies = strategies
    
    def register_access(self, key: str) -> None:
        """
        Enregistre un accès à une clé.
        
        Args:
            key (str): Clé accédée.
        """
        # Propager l'accès à toutes les stratégies
        for strategy in self.strategies:
            strategy.register_access(key)
    
    def register_set(self, key: str, size: int = 1) -> None:
        """
        Enregistre l'ajout ou la mise à jour d'une clé.
        
        Args:
            key (str): Clé ajoutée ou mise à jour.
            size (int, optional): Taille de la valeur. Par défaut: 1.
        """
        # Propager l'ajout à toutes les stratégies
        for strategy in self.strategies:
            strategy.register_set(key, size)
    
    def register_delete(self, key: str) -> None:
        """
        Enregistre la suppression d'une clé.
        
        Args:
            key (str): Clé supprimée.
        """
        # Propager la suppression à toutes les stratégies
        for strategy in self.strategies:
            strategy.register_delete(key)
    
    def get_eviction_candidates(self, count: int = 1) -> List[str]:
        """
        Récupère les clés candidates à l'éviction.
        
        Args:
            count (int, optional): Nombre de clés à récupérer. Par défaut: 1.
            
        Returns:
            List[str]: Liste des clés candidates à l'éviction.
        """
        # Récupérer les candidats de chaque stratégie
        all_candidates = {}
        
        for strategy, weight in self.strategies.items():
            # Récupérer plus de candidats pour avoir une meilleure distribution
            strategy_count = max(count, 10)
            candidates = strategy.get_eviction_candidates(strategy_count)
            
            # Attribuer un score à chaque candidat
            for i, key in enumerate(candidates):
                score = (strategy_count - i) * weight
                all_candidates[key] = all_candidates.get(key, 0) + score
        
        # Trier les candidats par score décroissant
        sorted_candidates = sorted(all_candidates.keys(), key=lambda k: all_candidates[k], reverse=True)
        
        # Récupérer les premiers candidats
        return sorted_candidates[:count]
    
    def clear(self) -> None:
        """
        Vide la stratégie d'éviction.
        """
        # Vider toutes les stratégies
        for strategy in self.strategies:
            strategy.clear()


# Fonction pour créer une stratégie d'éviction
def create_eviction_strategy(strategy_name: str) -> EvictionStrategy:
    """
    Crée une stratégie d'éviction.
    
    Args:
        strategy_name (str): Nom de la stratégie d'éviction.
            Valeurs possibles: "lru", "lfu", "fifo", "size", "ttl", "composite".
            
    Returns:
        EvictionStrategy: Instance de la stratégie d'éviction.
        
    Raises:
        ValueError: Si le nom de la stratégie est invalide.
    """
    strategy_name = strategy_name.lower()
    
    if strategy_name == "lru":
        return LRUStrategy()
    elif strategy_name == "lfu":
        return LFUStrategy()
    elif strategy_name == "fifo":
        return FIFOStrategy()
    elif strategy_name == "size":
        return SizeAwareStrategy()
    elif strategy_name == "ttl":
        return TTLAwareStrategy()
    elif strategy_name == "composite":
        # Créer une stratégie composite avec LRU (60%) et LFU (40%)
        return CompositeStrategy({
            LRUStrategy(): 0.6,
            LFUStrategy(): 0.4
        })
    else:
        raise ValueError(f"Stratégie d'éviction invalide: {strategy_name}")


if __name__ == "__main__":
    # Exemple d'utilisation
    
    # Créer une stratégie LRU
    lru_strategy = LRUStrategy()
    
    # Ajouter des clés
    for i in range(10):
        lru_strategy.register_set(f"key{i}")
    
    # Accéder à certaines clés
    lru_strategy.register_access("key5")
    lru_strategy.register_access("key2")
    lru_strategy.register_access("key8")
    
    # Récupérer les candidats à l'éviction
    candidates = lru_strategy.get_eviction_candidates(3)
    print(f"Candidats LRU: {candidates}")
    
    # Créer une stratégie LFU
    lfu_strategy = LFUStrategy()
    
    # Ajouter des clés
    for i in range(10):
        lfu_strategy.register_set(f"key{i}")
    
    # Accéder à certaines clés plusieurs fois
    for _ in range(5):
        lfu_strategy.register_access("key5")
    for _ in range(3):
        lfu_strategy.register_access("key2")
    lfu_strategy.register_access("key8")
    
    # Récupérer les candidats à l'éviction
    candidates = lfu_strategy.get_eviction_candidates(3)
    print(f"Candidats LFU: {candidates}")
    
    # Créer une stratégie composite
    composite_strategy = CompositeStrategy({
        lru_strategy: 0.7,
        lfu_strategy: 0.3
    })
    
    # Récupérer les candidats à l'éviction
    candidates = composite_strategy.get_eviction_candidates(3)
    print(f"Candidats composite: {candidates}")
