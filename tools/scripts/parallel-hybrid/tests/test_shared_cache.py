#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour le module de gestion du cache partagé.

Ce script exécute des tests unitaires pour vérifier le bon fonctionnement
du module de gestion du cache partagé (shared_cache.py).
"""

import os
import sys
import time
import unittest
import tempfile
import shutil
import threading
import multiprocessing
from concurrent.futures import ThreadPoolExecutor

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from python.shared_cache import SharedCache


class TestSharedCache(unittest.TestCase):
    """Tests pour la classe SharedCache."""

    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un répertoire temporaire pour le cache
        self.cache_dir = tempfile.mkdtemp()
        
        # Initialiser le cache
        self.cache = SharedCache(
            cache_path=self.cache_dir,
            cache_type="hybrid",
            max_memory_size=50,
            max_disk_size=100,
            default_ttl=3600,
            eviction_policy="lru",
            partitions=4,
            preload_factor=0.2
        )
        
        # Vider le cache
        self.cache.clear()

    def tearDown(self):
        """Nettoyage après chaque test."""
        # Supprimer le répertoire temporaire
        shutil.rmtree(self.cache_dir, ignore_errors=True)

    def test_set_get(self):
        """Test des méthodes set et get."""
        # Stocker une valeur
        self.cache.set("test_key", "test_value")
        
        # Récupérer la valeur
        value = self.cache.get("test_key")
        
        # Vérifier le résultat
        self.assertEqual(value, "test_value")
        
        # Vérifier qu'une clé inexistante retourne None
        value = self.cache.get("nonexistent_key")
        self.assertIsNone(value)
        
        # Vérifier qu'une clé inexistante avec une valeur par défaut retourne la valeur par défaut
        value = self.cache.get("nonexistent_key", "default_value")
        self.assertEqual(value, "default_value")

    def test_remove(self):
        """Test de la méthode remove."""
        # Stocker une valeur
        self.cache.set("remove_key", "remove_value")
        
        # Vérifier que la valeur existe
        value = self.cache.get("remove_key")
        self.assertEqual(value, "remove_value")
        
        # Supprimer la valeur
        self.cache.remove("remove_key")
        
        # Vérifier que la valeur n'existe plus
        value = self.cache.get("remove_key")
        self.assertIsNone(value)
        
        # Vérifier que la suppression d'une clé inexistante ne provoque pas d'erreur
        self.cache.remove("nonexistent_key")

    def test_clear(self):
        """Test de la méthode clear."""
        # Stocker plusieurs valeurs
        self.cache.set("clear_key1", "clear_value1")
        self.cache.set("clear_key2", "clear_value2")
        
        # Vérifier que les valeurs existent
        value1 = self.cache.get("clear_key1")
        value2 = self.cache.get("clear_key2")
        self.assertEqual(value1, "clear_value1")
        self.assertEqual(value2, "clear_value2")
        
        # Vider le cache
        self.cache.clear()
        
        # Vérifier que les valeurs n'existent plus
        value1 = self.cache.get("clear_key1")
        value2 = self.cache.get("clear_key2")
        self.assertIsNone(value1)
        self.assertIsNone(value2)

    def test_ttl(self):
        """Test de la durée de vie des éléments."""
        # Stocker une valeur avec une durée de vie courte
        self.cache.set("ttl_key", "ttl_value", ttl=1)
        
        # Vérifier que la valeur existe
        value = self.cache.get("ttl_key")
        self.assertEqual(value, "ttl_value")
        
        # Attendre que la durée de vie expire
        time.sleep(2)
        
        # Vérifier que la valeur n'existe plus
        value = self.cache.get("ttl_key")
        self.assertIsNone(value)

    def test_dependencies(self):
        """Test des dépendances et de l'invalidation sélective."""
        # Stocker une valeur de base
        self.cache.set("base_key", "base_value")
        
        # Stocker des valeurs dépendantes
        self.cache.set("dep_key1", "dep_value1", dependencies=["base_key"])
        self.cache.set("dep_key2", "dep_value2", dependencies=["base_key"])
        
        # Vérifier que les valeurs existent
        self.assertEqual(self.cache.get("base_key"), "base_value")
        self.assertEqual(self.cache.get("dep_key1"), "dep_value1")
        self.assertEqual(self.cache.get("dep_key2"), "dep_value2")
        
        # Invalider la valeur de base
        count = self.cache.invalidate("base_key")
        
        # Vérifier que le nombre d'éléments invalidés est correct
        self.assertEqual(count, 3)  # base_key + 2 dépendances
        
        # Vérifier que la valeur de base et les valeurs dépendantes n'existent plus
        self.assertIsNone(self.cache.get("base_key"))
        self.assertIsNone(self.cache.get("dep_key1"))
        self.assertIsNone(self.cache.get("dep_key2"))

    def test_cascade_dependencies(self):
        """Test des dépendances en cascade."""
        # Stocker une valeur de base
        self.cache.set("cascade_base", "base_value")
        
        # Stocker une valeur dépendante de niveau 1
        self.cache.set("cascade_level1", "level1_value", dependencies=["cascade_base"])
        
        # Stocker une valeur dépendante de niveau 2
        self.cache.set("cascade_level2", "level2_value", dependencies=["cascade_level1"])
        
        # Vérifier que les valeurs existent
        self.assertEqual(self.cache.get("cascade_base"), "base_value")
        self.assertEqual(self.cache.get("cascade_level1"), "level1_value")
        self.assertEqual(self.cache.get("cascade_level2"), "level2_value")
        
        # Invalider la valeur de base
        count = self.cache.invalidate("cascade_base")
        
        # Vérifier que le nombre d'éléments invalidés est correct
        self.assertEqual(count, 3)  # cascade_base + cascade_level1 + cascade_level2
        
        # Vérifier que toutes les valeurs n'existent plus
        self.assertIsNone(self.cache.get("cascade_base"))
        self.assertIsNone(self.cache.get("cascade_level1"))
        self.assertIsNone(self.cache.get("cascade_level2"))

    def test_partitioning(self):
        """Test du partitionnement du cache."""
        # Stocker un grand nombre de valeurs pour tester le partitionnement
        num_keys = 100
        keys = [f"partition_key_{i}" for i in range(num_keys)]
        values = [f"partition_value_{i}" for i in range(num_keys)]
        
        # Stocker les valeurs
        for i in range(num_keys):
            self.cache.set(keys[i], values[i])
        
        # Vérifier que toutes les valeurs sont correctement stockées
        for i in range(num_keys):
            self.assertEqual(self.cache.get(keys[i]), values[i])
        
        # Vérifier que les valeurs sont réparties dans les différentes partitions
        partition_counts = [0] * self.cache.config["partitions"]
        for i in range(num_keys):
            partition = self.cache._get_partition(keys[i])
            partition_counts[partition] += 1
        
        # Vérifier que chaque partition contient au moins une valeur
        for count in partition_counts:
            self.assertGreater(count, 0)

    def test_concurrent_access(self):
        """Test des accès concurrents."""
        # Nombre de threads
        num_threads = 10
        # Nombre d'opérations par thread
        num_ops = 10
        
        # Fonction pour exécuter des opérations de cache en parallèle
        def worker(thread_id):
            for i in range(num_ops):
                key = f"concurrent_key_{thread_id}_{i}"
                value = f"concurrent_value_{thread_id}_{i}"
                
                # Stocker la valeur
                self.cache.set(key, value)
                
                # Récupérer la valeur
                result = self.cache.get(key)
                
                # Vérifier le résultat
                if result != value:
                    return False
            
            return True
        
        # Exécuter les threads
        with ThreadPoolExecutor(max_workers=num_threads) as executor:
            results = list(executor.map(worker, range(num_threads)))
        
        # Vérifier que toutes les opérations ont réussi
        self.assertTrue(all(results))

    def test_preloading(self):
        """Test du préchargement prédictif."""
        # Stocker des valeurs avec des modèles d'accès
        self.cache.set("preload_key1", "preload_value1")
        self.cache.set("preload_key2", "preload_value2")
        self.cache.set("preload_key3", "preload_value3")
        
        # Accéder aux valeurs dans un ordre spécifique pour créer un modèle d'accès
        self.cache.get("preload_key1")
        time.sleep(0.1)
        self.cache.get("preload_key2")
        time.sleep(0.1)
        self.cache.get("preload_key3")
        time.sleep(0.1)
        self.cache.get("preload_key1")
        time.sleep(0.1)
        self.cache.get("preload_key2")
        
        # Vérifier que les modèles d'accès ont été enregistrés
        self.assertIn("preload_key1", self.cache.access_patterns)
        self.assertIn("preload_key2", self.cache.access_patterns)
        self.assertIn("preload_key3", self.cache.access_patterns)
        
        # Vérifier que les relations entre les clés ont été enregistrées
        self.assertIn("preload_key2", self.cache.access_patterns["preload_key1"]["related_keys"])
        self.assertIn("preload_key3", self.cache.access_patterns["preload_key2"]["related_keys"])

    def test_eviction_lru(self):
        """Test de la politique d'éviction LRU."""
        # Configurer un cache avec une taille mémoire limitée
        small_cache = SharedCache(
            cache_path=self.cache_dir,
            cache_type="memory",
            max_memory_size=2,  # Très petite taille pour forcer l'éviction
            max_disk_size=100,
            default_ttl=3600,
            eviction_policy="lru",
            partitions=1  # Une seule partition pour simplifier le test
        )
        
        # Stocker des valeurs
        small_cache.set("lru_key1", "lru_value1")
        small_cache.set("lru_key2", "lru_value2")
        
        # Vérifier que les valeurs existent
        self.assertEqual(small_cache.get("lru_key1"), "lru_value1")
        self.assertEqual(small_cache.get("lru_key2"), "lru_value2")
        
        # Accéder à la première valeur pour la rendre plus récemment utilisée
        small_cache.get("lru_key1")
        
        # Stocker une troisième valeur pour forcer l'éviction
        small_cache.set("lru_key3", "lru_value3")
        
        # Vérifier que la deuxième valeur a été évincée (la moins récemment utilisée)
        self.assertEqual(small_cache.get("lru_key1"), "lru_value1")
        self.assertIsNone(small_cache.get("lru_key2"))
        self.assertEqual(small_cache.get("lru_key3"), "lru_value3")

    def test_eviction_fifo(self):
        """Test de la politique d'éviction FIFO."""
        # Configurer un cache avec une taille mémoire limitée
        small_cache = SharedCache(
            cache_path=self.cache_dir,
            cache_type="memory",
            max_memory_size=2,  # Très petite taille pour forcer l'éviction
            max_disk_size=100,
            default_ttl=3600,
            eviction_policy="fifo",
            partitions=1  # Une seule partition pour simplifier le test
        )
        
        # Stocker des valeurs
        small_cache.set("fifo_key1", "fifo_value1")
        time.sleep(0.1)  # Attendre pour s'assurer que les timestamps sont différents
        small_cache.set("fifo_key2", "fifo_value2")
        
        # Vérifier que les valeurs existent
        self.assertEqual(small_cache.get("fifo_key1"), "fifo_value1")
        self.assertEqual(small_cache.get("fifo_key2"), "fifo_value2")
        
        # Stocker une troisième valeur pour forcer l'éviction
        small_cache.set("fifo_key3", "fifo_value3")
        
        # Vérifier que la première valeur a été évincée (la première entrée)
        self.assertIsNone(small_cache.get("fifo_key1"))
        self.assertEqual(small_cache.get("fifo_key2"), "fifo_value2")
        self.assertEqual(small_cache.get("fifo_key3"), "fifo_value3")

    def test_stats(self):
        """Test des statistiques du cache."""
        # Stocker et récupérer des valeurs pour générer des statistiques
        self.cache.set("stats_key1", "stats_value1")
        self.cache.set("stats_key2", "stats_value2")
        
        # Récupérer les valeurs (hits)
        self.cache.get("stats_key1")
        self.cache.get("stats_key2")
        
        # Récupérer des valeurs inexistantes (misses)
        self.cache.get("nonexistent_key1")
        self.cache.get("nonexistent_key2")
        
        # Récupérer les statistiques
        stats = self.cache.get_stats()
        
        # Vérifier les statistiques
        self.assertIn("memory_hits", stats)
        self.assertIn("memory_misses", stats)
        self.assertIn("disk_hits", stats)
        self.assertIn("disk_misses", stats)
        self.assertIn("evictions", stats)
        self.assertIn("preloads", stats)
        self.assertIn("invalidations", stats)
        self.assertIn("lock_contentions", stats)
        
        # Vérifier que les hits et misses sont corrects
        self.assertEqual(stats["memory_hits"], 2)
        self.assertEqual(stats["memory_misses"], 2)


if __name__ == "__main__":
    unittest.main()
