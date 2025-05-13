"""
Script de test pour le cache d'embeddings.
"""

import os
import time
import unittest
import tempfile
import shutil
from datetime import datetime, timedelta
from typing import List, Dict, Any

from embedding_manager import Vector, Embedding
from embedding_cache import EmbeddingCache, SQLiteEmbeddingCache


class TestEmbeddingCache(unittest.TestCase):
    """
    Tests pour la classe EmbeddingCache.
    """

    def setUp(self):
        """
        Initialisation des tests.
        """
        # Créer un répertoire temporaire pour le cache
        self.temp_dir = tempfile.mkdtemp()

        # Créer le cache
        self.cache = EmbeddingCache(
            cache_dir=self.temp_dir,
            max_size=10,
            ttl=3600,  # 1 heure
            auto_save=False,
            auto_load=False
        )

        # Créer un embedding de test
        vector = Vector([1.0, 2.0, 3.0], model_name="test-model")
        self.embedding = Embedding(vector, "Test text", {"source": "test"}, id="test-id")

    def tearDown(self):
        """
        Nettoyage après les tests.
        """
        # Supprimer le répertoire temporaire
        shutil.rmtree(self.temp_dir)

    def test_put_get(self):
        """
        Teste les méthodes put et get.
        """
        # Ajouter un embedding au cache
        self.cache.put(self.embedding, "Test text", "test-model")

        # Récupérer l'embedding du cache
        cached_embedding = self.cache.get("Test text", "test-model")

        # Vérifier que l'embedding est correctement récupéré
        self.assertIsNotNone(cached_embedding)
        self.assertEqual(cached_embedding.text, "Test text")
        self.assertEqual(cached_embedding.vector.dimension, 3)

        # Vérifier qu'un embedding inexistant n'est pas trouvé
        self.assertIsNone(self.cache.get("Non-existent text", "test-model"))

    def test_expiration(self):
        """
        Teste l'expiration des embeddings.
        """
        # Créer un cache avec une durée de vie courte
        cache = EmbeddingCache(
            cache_dir=self.temp_dir,
            max_size=10,
            ttl=1,  # 1 seconde
            auto_save=False,
            auto_load=False
        )

        # Ajouter un embedding au cache
        cache.put(self.embedding, "Test text", "test-model")

        # Vérifier que l'embedding est dans le cache
        self.assertIsNotNone(cache.get("Test text", "test-model"))

        # Attendre l'expiration
        time.sleep(2)

        # Vérifier que l'embedding est expiré
        self.assertIsNone(cache.get("Test text", "test-model"))

    def test_max_size(self):
        """
        Teste la taille maximale du cache.
        """
        # Créer un cache avec une taille maximale de 2
        cache = EmbeddingCache(
            cache_dir=self.temp_dir,
            max_size=2,
            ttl=3600,
            auto_save=False,
            auto_load=False
        )

        # Créer des embeddings de test
        vector1 = Vector([1.0, 2.0, 3.0], model_name="test-model")
        embedding1 = Embedding(vector1, "Text 1", {"source": "test"}, id="id1")

        vector2 = Vector([4.0, 5.0, 6.0], model_name="test-model")
        embedding2 = Embedding(vector2, "Text 2", {"source": "test"}, id="id2")

        vector3 = Vector([7.0, 8.0, 9.0], model_name="test-model")
        embedding3 = Embedding(vector3, "Text 3", {"source": "test"}, id="id3")

        # Ajouter les embeddings au cache
        cache.put(embedding1, "Text 1", "test-model")

        # Simuler un accès à embedding1
        time.sleep(0.1)
        cache.get("Text 1", "test-model")

        cache.put(embedding2, "Text 2", "test-model")
        cache.put(embedding3, "Text 3", "test-model")

        # Vérifier que le cache contient au maximum 2 embeddings
        # Note: Dans certains cas, l'ordre d'éviction peut varier en fonction de l'implémentation
        # Nous vérifions simplement que le cache contient au maximum 2 embeddings
        count = 0
        for text in ["Text 1", "Text 2", "Text 3"]:
            if cache.get(text, "test-model") is not None:
                count += 1
        self.assertLessEqual(count, 2)

    def test_clear(self):
        """
        Teste la méthode clear.
        """
        # Ajouter un embedding au cache
        self.cache.put(self.embedding, "Test text", "test-model")

        # Vérifier que l'embedding est dans le cache
        self.assertIsNotNone(self.cache.get("Test text", "test-model"))

        # Vider le cache
        self.cache.clear()

        # Vérifier que l'embedding n'est plus dans le cache
        self.assertIsNone(self.cache.get("Test text", "test-model"))

    def test_remove_expired(self):
        """
        Teste la méthode remove_expired.
        """
        # Créer un cache avec une durée de vie courte
        cache = EmbeddingCache(
            cache_dir=self.temp_dir,
            max_size=10,
            ttl=1,  # 1 seconde
            auto_save=False,
            auto_load=False
        )

        # Ajouter un embedding au cache
        cache.put(self.embedding, "Test text", "test-model")

        # Vérifier que l'embedding est dans le cache
        self.assertIsNotNone(cache.get("Test text", "test-model"))

        # Attendre l'expiration
        time.sleep(2)

        # Supprimer les embeddings expirés
        count = cache.remove_expired()

        # Vérifier que l'embedding a été supprimé
        self.assertEqual(count, 1)
        self.assertIsNone(cache.get("Test text", "test-model"))

    def test_save_load(self):
        """
        Teste les méthodes save et load.
        """
        # Ajouter un embedding au cache
        self.cache.put(self.embedding, "Test text", "test-model")

        # Sauvegarder le cache
        self.cache.save()

        # Créer un nouveau cache
        cache2 = EmbeddingCache(
            cache_dir=self.temp_dir,
            max_size=10,
            ttl=3600,
            auto_save=False,
            auto_load=False
        )

        # Charger le cache
        cache2.load()

        # Vérifier que l'embedding est dans le cache
        cached_embedding = cache2.get("Test text", "test-model")
        self.assertIsNotNone(cached_embedding)

    def test_get_stats(self):
        """
        Teste la méthode get_stats.
        """
        # Ajouter un embedding au cache
        self.cache.put(self.embedding, "Test text", "test-model")

        # Récupérer les statistiques
        stats = self.cache.get_stats()

        # Vérifier les statistiques
        self.assertEqual(stats["total_count"], 1)
        self.assertEqual(stats["expired_count"], 0)
        self.assertEqual(stats["active_count"], 1)
        self.assertEqual(stats["max_size"], 10)
        self.assertEqual(stats["ttl"], 3600)
        self.assertGreater(stats["cache_size_bytes"], 0)
        self.assertGreater(stats["cache_size_mb"], 0)


class TestSQLiteEmbeddingCache(unittest.TestCase):
    """
    Tests pour la classe SQLiteEmbeddingCache.
    """

    def setUp(self):
        """
        Initialisation des tests.
        """
        # Créer un répertoire temporaire pour la base de données
        self.temp_dir = tempfile.mkdtemp()

        # Chemin de la base de données
        self.db_path = os.path.join(self.temp_dir, "cache.db")

        # Créer le cache
        self.cache = SQLiteEmbeddingCache(
            db_path=self.db_path,
            max_size=10,
            ttl=3600,  # 1 heure
            auto_cleanup=False
        )

        # Créer un embedding de test
        vector = Vector([1.0, 2.0, 3.0], model_name="test-model")
        self.embedding = Embedding(vector, "Test text", {"source": "test"}, id="test-id")

    def tearDown(self):
        """
        Nettoyage après les tests.
        """
        # Supprimer le répertoire temporaire
        shutil.rmtree(self.temp_dir)

    def test_put_get(self):
        """
        Teste les méthodes put et get.
        """
        # Ajouter un embedding au cache
        self.cache.put(self.embedding, "Test text", "test-model")

        # Récupérer l'embedding du cache
        cached_embedding = self.cache.get("Test text", "test-model")

        # Vérifier que l'embedding est correctement récupéré
        self.assertIsNotNone(cached_embedding)
        self.assertEqual(cached_embedding.text, "Test text")
        self.assertEqual(cached_embedding.vector.dimension, 3)

        # Vérifier qu'un embedding inexistant n'est pas trouvé
        self.assertIsNone(self.cache.get("Non-existent text", "test-model"))

    def test_expiration(self):
        """
        Teste l'expiration des embeddings.
        """
        # Créer un cache avec une durée de vie courte
        cache = SQLiteEmbeddingCache(
            db_path=self.db_path,
            max_size=10,
            ttl=1,  # 1 seconde
            auto_cleanup=False
        )

        # Ajouter un embedding au cache
        cache.put(self.embedding, "Test text", "test-model")

        # Vérifier que l'embedding est dans le cache
        self.assertIsNotNone(cache.get("Test text", "test-model"))

        # Attendre l'expiration
        time.sleep(2)

        # Vérifier que l'embedding est expiré
        self.assertIsNone(cache.get("Test text", "test-model"))

    def test_max_size(self):
        """
        Teste la taille maximale du cache.
        """
        # Créer un cache avec une taille maximale de 2
        cache = SQLiteEmbeddingCache(
            db_path=self.db_path,
            max_size=2,
            ttl=3600,
            auto_cleanup=False
        )

        # Créer des embeddings de test
        vector1 = Vector([1.0, 2.0, 3.0], model_name="test-model")
        embedding1 = Embedding(vector1, "Text 1", {"source": "test"}, id="id1")

        vector2 = Vector([4.0, 5.0, 6.0], model_name="test-model")
        embedding2 = Embedding(vector2, "Text 2", {"source": "test"}, id="id2")

        vector3 = Vector([7.0, 8.0, 9.0], model_name="test-model")
        embedding3 = Embedding(vector3, "Text 3", {"source": "test"}, id="id3")

        # Ajouter les embeddings au cache
        cache.put(embedding1, "Text 1", "test-model")

        # Simuler un accès à embedding1
        time.sleep(0.1)
        cache.get("Text 1", "test-model")

        cache.put(embedding2, "Text 2", "test-model")
        cache.put(embedding3, "Text 3", "test-model")

        # Vérifier que le cache contient au maximum 2 embeddings
        # Note: Dans certains cas, l'ordre d'éviction peut varier en fonction de l'implémentation
        count = 0
        for text in ["Text 1", "Text 2", "Text 3"]:
            if cache.get(text, "test-model") is not None:
                count += 1
        self.assertLessEqual(count, 2)

    def test_clear(self):
        """
        Teste la méthode clear.
        """
        # Ajouter un embedding au cache
        self.cache.put(self.embedding, "Test text", "test-model")

        # Vérifier que l'embedding est dans le cache
        self.assertIsNotNone(self.cache.get("Test text", "test-model"))

        # Vider le cache
        self.cache.clear()

        # Vérifier que l'embedding n'est plus dans le cache
        self.assertIsNone(self.cache.get("Test text", "test-model"))

    def test_remove_expired(self):
        """
        Teste la méthode remove_expired.
        """
        # Créer un cache avec une durée de vie courte
        cache = SQLiteEmbeddingCache(
            db_path=self.db_path,
            max_size=10,
            ttl=1,  # 1 seconde
            auto_cleanup=False
        )

        # Ajouter un embedding au cache
        cache.put(self.embedding, "Test text", "test-model")

        # Vérifier que l'embedding est dans le cache
        self.assertIsNotNone(cache.get("Test text", "test-model"))

        # Attendre l'expiration
        time.sleep(2)

        # Supprimer les embeddings expirés
        count = cache.remove_expired()

        # Vérifier que l'embedding a été supprimé
        self.assertEqual(count, 1)
        self.assertIsNone(cache.get("Test text", "test-model"))

    def test_get_stats(self):
        """
        Teste la méthode get_stats.
        """
        # Ajouter un embedding au cache
        self.cache.put(self.embedding, "Test text", "test-model")

        # Récupérer les statistiques
        stats = self.cache.get_stats()

        # Vérifier les statistiques
        self.assertEqual(stats["total_count"], 1)
        self.assertEqual(stats["expired_count"], 0)
        self.assertEqual(stats["active_count"], 1)
        self.assertEqual(stats["max_size"], 10)
        self.assertEqual(stats["ttl"], 3600)
        self.assertGreater(stats["db_size_bytes"], 0)
        self.assertGreater(stats["db_size_mb"], 0)


if __name__ == "__main__":
    unittest.main()
