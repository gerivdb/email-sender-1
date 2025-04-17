#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour les stratégies d'éviction.

Ce module contient les tests unitaires pour les différentes stratégies d'éviction
utilisées pour optimiser l'utilisation de la mémoire du cache.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import sys
import unittest
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', '..')))
from scripts.utils.cache.eviction_strategies import (
    LRUStrategy, LFUStrategy, FIFOStrategy, SizeAwareStrategy, TTLAwareStrategy, CompositeStrategy
)


class TestLRUStrategy(unittest.TestCase):
    """Tests pour la stratégie LRU (Least Recently Used)."""

    def setUp(self):
        """Initialisation avant chaque test."""
        self.strategy = LRUStrategy()

    def test_register_access(self):
        """Teste l'enregistrement d'un accès."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        
        # Accéder à une clé
        self.strategy.register_access("key2")
        
        # Vérifier l'ordre d'accès
        candidates = self.strategy.get_eviction_candidates(3)
        self.assertEqual(candidates, ["key1", "key3", "key2"])

    def test_register_set(self):
        """Teste l'enregistrement d'un ajout."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        
        # Vérifier l'ordre d'accès
        candidates = self.strategy.get_eviction_candidates(3)
        self.assertEqual(candidates, ["key1", "key2", "key3"])
        
        # Ajouter une clé existante
        self.strategy.register_set("key1")
        
        # Vérifier que la clé a été déplacée à la fin
        candidates = self.strategy.get_eviction_candidates(3)
        self.assertEqual(candidates, ["key2", "key3", "key1"])

    def test_register_delete(self):
        """Teste l'enregistrement d'une suppression."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        
        # Supprimer une clé
        self.strategy.register_delete("key2")
        
        # Vérifier que la clé a été supprimée
        candidates = self.strategy.get_eviction_candidates(3)
        self.assertEqual(candidates, ["key1", "key3"])

    def test_get_eviction_candidates(self):
        """Teste la récupération des candidats à l'éviction."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        self.strategy.register_set("key4")
        self.strategy.register_set("key5")
        
        # Accéder à certaines clés
        self.strategy.register_access("key3")
        self.strategy.register_access("key1")
        
        # Vérifier les candidats à l'éviction
        candidates = self.strategy.get_eviction_candidates(2)
        self.assertEqual(candidates, ["key2", "key4"])
        
        # Vérifier avec un nombre supérieur au nombre de clés
        candidates = self.strategy.get_eviction_candidates(10)
        self.assertEqual(candidates, ["key2", "key4", "key5", "key3", "key1"])

    def test_clear(self):
        """Teste la suppression de toutes les données."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        
        # Vider la stratégie
        self.strategy.clear()
        
        # Vérifier que toutes les clés ont été supprimées
        candidates = self.strategy.get_eviction_candidates(10)
        self.assertEqual(candidates, [])


class TestLFUStrategy(unittest.TestCase):
    """Tests pour la stratégie LFU (Least Frequently Used)."""

    def setUp(self):
        """Initialisation avant chaque test."""
        self.strategy = LFUStrategy()

    def test_register_access(self):
        """Teste l'enregistrement d'un accès."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        
        # Accéder à certaines clés plusieurs fois
        self.strategy.register_access("key2")
        self.strategy.register_access("key2")
        self.strategy.register_access("key3")
        
        # Vérifier l'ordre d'accès
        candidates = self.strategy.get_eviction_candidates(3)
        self.assertEqual(candidates, ["key1", "key3", "key2"])

    def test_register_set(self):
        """Teste l'enregistrement d'un ajout."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        
        # Vérifier l'ordre d'accès
        candidates = self.strategy.get_eviction_candidates(3)
        self.assertIn("key1", candidates)
        self.assertIn("key2", candidates)
        self.assertIn("key3", candidates)

    def test_register_delete(self):
        """Teste l'enregistrement d'une suppression."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        
        # Supprimer une clé
        self.strategy.register_delete("key2")
        
        # Vérifier que la clé a été supprimée
        candidates = self.strategy.get_eviction_candidates(3)
        self.assertIn("key1", candidates)
        self.assertIn("key3", candidates)
        self.assertNotIn("key2", candidates)

    def test_get_eviction_candidates(self):
        """Teste la récupération des candidats à l'éviction."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        self.strategy.register_set("key4")
        self.strategy.register_set("key5")
        
        # Accéder à certaines clés plusieurs fois
        for _ in range(3):
            self.strategy.register_access("key3")
        for _ in range(2):
            self.strategy.register_access("key1")
        self.strategy.register_access("key4")
        
        # Vérifier les candidats à l'éviction
        candidates = self.strategy.get_eviction_candidates(2)
        self.assertIn("key2", candidates)
        self.assertIn("key5", candidates)

    def test_clear(self):
        """Teste la suppression de toutes les données."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        
        # Vider la stratégie
        self.strategy.clear()
        
        # Vérifier que toutes les clés ont été supprimées
        candidates = self.strategy.get_eviction_candidates(10)
        self.assertEqual(candidates, [])


class TestFIFOStrategy(unittest.TestCase):
    """Tests pour la stratégie FIFO (First In, First Out)."""

    def setUp(self):
        """Initialisation avant chaque test."""
        self.strategy = FIFOStrategy()

    def test_register_access(self):
        """Teste l'enregistrement d'un accès."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        
        # Accéder à une clé (ne devrait pas affecter l'ordre)
        self.strategy.register_access("key2")
        
        # Vérifier l'ordre d'insertion
        candidates = self.strategy.get_eviction_candidates(3)
        self.assertEqual(candidates, ["key1", "key2", "key3"])

    def test_register_set(self):
        """Teste l'enregistrement d'un ajout."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        
        # Vérifier l'ordre d'insertion
        candidates = self.strategy.get_eviction_candidates(3)
        self.assertEqual(candidates, ["key1", "key2", "key3"])
        
        # Ajouter une clé existante
        self.strategy.register_set("key1")
        
        # Vérifier que la clé a été déplacée à la fin
        candidates = self.strategy.get_eviction_candidates(3)
        self.assertEqual(candidates, ["key2", "key3", "key1"])

    def test_register_delete(self):
        """Teste l'enregistrement d'une suppression."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        
        # Supprimer une clé
        self.strategy.register_delete("key2")
        
        # Vérifier que la clé a été supprimée
        candidates = self.strategy.get_eviction_candidates(3)
        self.assertEqual(candidates, ["key1", "key3"])

    def test_get_eviction_candidates(self):
        """Teste la récupération des candidats à l'éviction."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        self.strategy.register_set("key4")
        self.strategy.register_set("key5")
        
        # Vérifier les candidats à l'éviction
        candidates = self.strategy.get_eviction_candidates(2)
        self.assertEqual(candidates, ["key1", "key2"])

    def test_clear(self):
        """Teste la suppression de toutes les données."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        
        # Vider la stratégie
        self.strategy.clear()
        
        # Vérifier que toutes les clés ont été supprimées
        candidates = self.strategy.get_eviction_candidates(10)
        self.assertEqual(candidates, [])


class TestSizeAwareStrategy(unittest.TestCase):
    """Tests pour la stratégie basée sur la taille."""

    def setUp(self):
        """Initialisation avant chaque test."""
        self.strategy = SizeAwareStrategy()

    def test_register_set(self):
        """Teste l'enregistrement d'un ajout avec taille."""
        # Ajouter des clés avec différentes tailles
        self.strategy.register_set("key1", 100)
        self.strategy.register_set("key2", 200)
        self.strategy.register_set("key3", 50)
        
        # Vérifier les candidats à l'éviction (les plus volumineux d'abord)
        candidates = self.strategy.get_eviction_candidates(3)
        self.assertEqual(candidates, ["key2", "key1", "key3"])

    def test_register_delete(self):
        """Teste l'enregistrement d'une suppression."""
        # Ajouter des clés
        self.strategy.register_set("key1", 100)
        self.strategy.register_set("key2", 200)
        self.strategy.register_set("key3", 50)
        
        # Supprimer une clé
        self.strategy.register_delete("key2")
        
        # Vérifier que la clé a été supprimée
        candidates = self.strategy.get_eviction_candidates(3)
        self.assertEqual(candidates, ["key1", "key3"])

    def test_clear(self):
        """Teste la suppression de toutes les données."""
        # Ajouter des clés
        self.strategy.register_set("key1", 100)
        self.strategy.register_set("key2", 200)
        self.strategy.register_set("key3", 50)
        
        # Vider la stratégie
        self.strategy.clear()
        
        # Vérifier que toutes les clés ont été supprimées
        candidates = self.strategy.get_eviction_candidates(10)
        self.assertEqual(candidates, [])


class TestTTLAwareStrategy(unittest.TestCase):
    """Tests pour la stratégie basée sur la durée de vie (TTL)."""

    def setUp(self):
        """Initialisation avant chaque test."""
        self.strategy = TTLAwareStrategy()

    def test_register_set(self):
        """Teste l'enregistrement d'un ajout avec TTL."""
        # Ajouter des clés avec différents TTL
        self.strategy.register_set("key1", ttl=60)
        self.strategy.register_set("key2", ttl=30)
        self.strategy.register_set("key3", ttl=120)
        
        # Vérifier les candidats à l'éviction (les TTL les plus courts d'abord)
        candidates = self.strategy.get_eviction_candidates(3)
        self.assertEqual(candidates, ["key2", "key1", "key3"])

    def test_register_delete(self):
        """Teste l'enregistrement d'une suppression."""
        # Ajouter des clés
        self.strategy.register_set("key1", ttl=60)
        self.strategy.register_set("key2", ttl=30)
        self.strategy.register_set("key3", ttl=120)
        
        # Supprimer une clé
        self.strategy.register_delete("key2")
        
        # Vérifier que la clé a été supprimée
        candidates = self.strategy.get_eviction_candidates(3)
        self.assertEqual(candidates, ["key1", "key3"])

    def test_clear(self):
        """Teste la suppression de toutes les données."""
        # Ajouter des clés
        self.strategy.register_set("key1", ttl=60)
        self.strategy.register_set("key2", ttl=30)
        self.strategy.register_set("key3", ttl=120)
        
        # Vider la stratégie
        self.strategy.clear()
        
        # Vérifier que toutes les clés ont été supprimées
        candidates = self.strategy.get_eviction_candidates(10)
        self.assertEqual(candidates, [])


class TestCompositeStrategy(unittest.TestCase):
    """Tests pour la stratégie composite."""

    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer une stratégie composite avec LRU (60%) et LFU (40%)
        self.lru_strategy = LRUStrategy()
        self.lfu_strategy = LFUStrategy()
        self.strategy = CompositeStrategy({
            self.lru_strategy: 0.6,
            self.lfu_strategy: 0.4
        })

    def test_register_access(self):
        """Teste l'enregistrement d'un accès."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        
        # Accéder à certaines clés
        self.strategy.register_access("key2")
        
        # Vérifier que l'accès a été propagé aux stratégies sous-jacentes
        self.assertIn("key2", self.lru_strategy.access_order)
        self.assertEqual(self.lfu_strategy.access_count["key2"], 2)  # 1 pour register_set + 1 pour register_access

    def test_register_set(self):
        """Teste l'enregistrement d'un ajout."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        
        # Vérifier que l'ajout a été propagé aux stratégies sous-jacentes
        self.assertIn("key1", self.lru_strategy.access_order)
        self.assertIn("key2", self.lru_strategy.access_order)
        self.assertIn("key3", self.lru_strategy.access_order)
        
        self.assertEqual(self.lfu_strategy.access_count["key1"], 1)
        self.assertEqual(self.lfu_strategy.access_count["key2"], 1)
        self.assertEqual(self.lfu_strategy.access_count["key3"], 1)

    def test_register_delete(self):
        """Teste l'enregistrement d'une suppression."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        
        # Supprimer une clé
        self.strategy.register_delete("key2")
        
        # Vérifier que la suppression a été propagée aux stratégies sous-jacentes
        self.assertNotIn("key2", self.lru_strategy.access_order)
        self.assertNotIn("key2", self.lfu_strategy.access_count)

    def test_get_eviction_candidates(self):
        """Teste la récupération des candidats à l'éviction."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        self.strategy.register_set("key4")
        self.strategy.register_set("key5")
        
        # Accéder à certaines clés plusieurs fois
        self.strategy.register_access("key3")
        self.strategy.register_access("key3")
        self.strategy.register_access("key1")
        
        # Vérifier les candidats à l'éviction
        candidates = self.strategy.get_eviction_candidates(2)
        
        # Les candidats devraient être influencés par les deux stratégies
        # key2, key4 et key5 sont les moins récemment utilisés (LRU)
        # key2, key4 et key5 sont les moins fréquemment utilisés (LFU)
        # Donc key2, key4 et key5 devraient être les candidats
        self.assertIn(candidates[0], ["key2", "key4", "key5"])
        self.assertIn(candidates[1], ["key2", "key4", "key5"])

    def test_clear(self):
        """Teste la suppression de toutes les données."""
        # Ajouter des clés
        self.strategy.register_set("key1")
        self.strategy.register_set("key2")
        self.strategy.register_set("key3")
        
        # Vider la stratégie
        self.strategy.clear()
        
        # Vérifier que toutes les clés ont été supprimées des stratégies sous-jacentes
        self.assertEqual(len(self.lru_strategy.access_order), 0)
        self.assertEqual(len(self.lfu_strategy.access_count), 0)


if __name__ == '__main__':
    unittest.main()
