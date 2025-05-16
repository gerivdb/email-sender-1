#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests pour le gestionnaire de cache.

Ce module contient les tests unitaires pour le gestionnaire de cache.
"""

import os
import sys
import time
import unittest
import tempfile
import shutil
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

from src.langchain.utils.cache_manager import CacheManager, cached

class TestCacheManager(unittest.TestCase):
    """Tests pour le gestionnaire de cache."""
    
    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un répertoire temporaire pour les tests
        self.temp_dir = tempfile.mkdtemp()
        CacheManager.initialize(cache_dir=self.temp_dir)
        CacheManager.clear_all_cache()
    
    def tearDown(self):
        """Nettoyage après chaque test."""
        # Supprimer le répertoire temporaire
        shutil.rmtree(self.temp_dir)
    
    def test_memory_cache(self):
        """Teste le cache en mémoire."""
        # Générer une clé de cache
        cache_key = CacheManager.get_cache_key("test_func", (1, 2), {"a": "b"})
        
        # Vérifier que la clé n'est pas dans le cache
        self.assertIsNone(CacheManager.get_from_memory_cache(cache_key))
        
        # Ajouter une valeur au cache
        CacheManager.set_in_memory_cache(cache_key, "test_value", ttl=1)
        
        # Vérifier que la valeur est dans le cache
        self.assertEqual(CacheManager.get_from_memory_cache(cache_key), "test_value")
        
        # Attendre que la valeur expire
        time.sleep(1.1)
        
        # Vérifier que la valeur a expiré
        self.assertIsNone(CacheManager.get_from_memory_cache(cache_key))
    
    def test_disk_cache(self):
        """Teste le cache sur disque."""
        # Générer une clé de cache
        cache_key = CacheManager.get_cache_key("test_func", (1, 2), {"a": "b"})
        
        # Vérifier que la clé n'est pas dans le cache
        self.assertIsNone(CacheManager.get_from_disk_cache(cache_key))
        
        # Ajouter une valeur au cache
        CacheManager.set_in_disk_cache(cache_key, "test_value", ttl=1)
        
        # Vérifier que la valeur est dans le cache
        self.assertEqual(CacheManager.get_from_disk_cache(cache_key), "test_value")
        
        # Attendre que la valeur expire
        time.sleep(1.1)
        
        # Vérifier que la valeur a expiré
        self.assertIsNone(CacheManager.get_from_disk_cache(cache_key))
    
    def test_cached_decorator(self):
        """Teste le décorateur @cached."""
        # Compteur d'appels
        call_count = [0]
        
        # Fonction de test avec cache
        @cached(ttl_memory=1, ttl_disk=2)
        def test_func(a, b):
            call_count[0] += 1
            return a + b
        
        # Premier appel (non mis en cache)
        result1 = test_func(1, 2)
        self.assertEqual(result1, 3)
        self.assertEqual(call_count[0], 1)
        
        # Deuxième appel (depuis le cache mémoire)
        result2 = test_func(1, 2)
        self.assertEqual(result2, 3)
        self.assertEqual(call_count[0], 1)  # Pas d'appel supplémentaire
        
        # Attendre que le cache mémoire expire
        time.sleep(1.1)
        
        # Troisième appel (depuis le cache disque)
        result3 = test_func(1, 2)
        self.assertEqual(result3, 3)
        self.assertEqual(call_count[0], 1)  # Pas d'appel supplémentaire
        
        # Attendre que le cache disque expire
        time.sleep(1.1)
        
        # Quatrième appel (non mis en cache)
        result4 = test_func(1, 2)
        self.assertEqual(result4, 3)
        self.assertEqual(call_count[0], 2)  # Un appel supplémentaire
    
    def test_clear_cache(self):
        """Teste les méthodes de nettoyage du cache."""
        # Générer des clés de cache
        memory_key = CacheManager.get_cache_key("memory_func", (1, 2), {})
        disk_key = CacheManager.get_cache_key("disk_func", (3, 4), {})
        
        # Ajouter des valeurs aux caches
        CacheManager.set_in_memory_cache(memory_key, "memory_value")
        CacheManager.set_in_disk_cache(disk_key, "disk_value")
        
        # Vérifier que les valeurs sont dans les caches
        self.assertEqual(CacheManager.get_from_memory_cache(memory_key), "memory_value")
        self.assertEqual(CacheManager.get_from_disk_cache(disk_key), "disk_value")
        
        # Nettoyer le cache mémoire
        CacheManager.clear_memory_cache()
        
        # Vérifier que la valeur mémoire a été supprimée
        self.assertIsNone(CacheManager.get_from_memory_cache(memory_key))
        self.assertEqual(CacheManager.get_from_disk_cache(disk_key), "disk_value")
        
        # Ajouter à nouveau une valeur au cache mémoire
        CacheManager.set_in_memory_cache(memory_key, "memory_value")
        
        # Nettoyer tous les caches
        CacheManager.clear_all_cache()
        
        # Vérifier que toutes les valeurs ont été supprimées
        self.assertIsNone(CacheManager.get_from_memory_cache(memory_key))
        self.assertIsNone(CacheManager.get_from_disk_cache(disk_key))

if __name__ == '__main__':
    unittest.main()
