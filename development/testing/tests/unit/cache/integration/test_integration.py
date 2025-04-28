#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour le module d'intégration du cache.

Ce module contient les tests unitaires pour le module d'intégration du cache
utilisé pour faciliter l'utilisation du cache dans l'application.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import sys
import time
import json
import unittest
from unittest.mock import patch, MagicMock
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', '..')))
from scripts.utils.cache.local_cache import LocalCache
from scripts.utils.cache.integration import (
    CacheManager, get_cache_manager, cached_function, cached_http_request,
    cached_n8n_workflow, invalidate_cache, clear_all_caches,
    get_cache_statistics
)


class TestCacheManager(unittest.TestCase):
    """Tests pour le gestionnaire de cache."""

    def setUp(self):
        """Initialisation avant chaque test."""
        # Réinitialiser l'instance du gestionnaire de cache
        CacheManager._instance = None

        # Créer un fichier de configuration temporaire
        self.config_path = os.path.join(os.path.dirname(__file__), 'test_config.json')
        self.config = {
            "cache_dir": "test_cache_dir",
            "default_ttl": 60,
            "max_disk_size": 100,
            "eviction_policy": "LRU",
            "adapters": {
                "http": {
                    "default_ttl": 60,
                    "methods_to_cache": ["GET", "HEAD"],
                    "status_codes_to_cache": [200]
                },
                "n8n": {
                    "default_ttl": 60,
                    "base_url": "http://localhost:5678/webhook/",
                    "api_key": "test_api_key"
                }
            }
        }

        with open(self.config_path, 'w', encoding='utf-8') as f:
            json.dump(self.config, f)

    def tearDown(self):
        """Nettoyage après chaque test."""
        # Supprimer le fichier de configuration temporaire
        if os.path.exists(self.config_path):
            os.remove(self.config_path)

        # Fermer le cache avant de supprimer le répertoire
        if hasattr(self, 'cache_manager') and hasattr(self.cache_manager, 'cache'):
            self.cache_manager.cache.cache.close()

        # Supprimer le répertoire de cache temporaire
        if os.path.exists("test_cache_dir"):
            import shutil
            try:
                shutil.rmtree("test_cache_dir")
            except (PermissionError, OSError):
                # Ignorer les erreurs de suppression du répertoire
                pass

    def test_singleton_pattern(self):
        """Teste le pattern Singleton du gestionnaire de cache."""
        # Créer deux instances du gestionnaire de cache
        manager1 = CacheManager()
        manager2 = CacheManager()

        # Sauvegarder la référence pour le tearDown
        self.cache_manager = manager1

        # Vérifier que les deux instances sont identiques
        self.assertIs(manager1, manager2)

    def test_load_config(self):
        """Teste le chargement de la configuration."""
        # Créer une instance du gestionnaire de cache avec la configuration
        manager = CacheManager(config_path=self.config_path)

        # Sauvegarder la référence pour le tearDown
        self.cache_manager = manager

        # Vérifier que la configuration a été chargée correctement
        self.assertEqual(manager.config["cache_dir"], "test_cache_dir")
        self.assertEqual(manager.config["default_ttl"], 60)
        self.assertEqual(manager.config["max_disk_size"], 100)
        self.assertEqual(manager.config["eviction_policy"], "LRU")
        self.assertEqual(manager.config["adapters"]["http"]["default_ttl"], 60)
        self.assertEqual(manager.config["adapters"]["n8n"]["api_key"], "test_api_key")

    def test_get_cache(self):
        """Teste la récupération de l'instance de cache."""
        # Créer une instance du gestionnaire de cache
        manager = CacheManager()

        # Récupérer l'instance de cache
        cache = manager.get_cache()

        # Vérifier que l'instance est correcte
        self.assertIsInstance(cache, LocalCache)

    def test_get_http_adapter(self):
        """Teste la récupération de l'adaptateur HTTP."""
        # Créer une instance du gestionnaire de cache
        manager = CacheManager()

        # Récupérer l'adaptateur HTTP
        http_adapter = manager.get_http_adapter()

        # Vérifier que l'adaptateur est correct
        self.assertEqual(http_adapter.__class__.__name__, "HttpCacheAdapter")

    def test_get_n8n_adapter(self):
        """Teste la récupération de l'adaptateur n8n."""
        # Créer une instance du gestionnaire de cache
        manager = CacheManager()

        # Récupérer l'adaptateur n8n
        n8n_adapter = manager.get_n8n_adapter()

        # Vérifier que l'adaptateur est correct
        self.assertEqual(n8n_adapter.__class__.__name__, "N8nCacheAdapter")

    def test_cached_decorator(self):
        """Teste le décorateur cached du gestionnaire de cache."""
        # Créer une instance du gestionnaire de cache
        manager = CacheManager()

        # Compteur d'appels
        call_count = 0

        # Définir une fonction à mettre en cache
        @manager.cached(ttl=60)
        def test_function(param):
            nonlocal call_count
            call_count += 1
            return f"result_{param}"

        # Premier appel (exécute la fonction)
        result1 = test_function("test")
        self.assertEqual(result1, "result_test")
        self.assertEqual(call_count, 1)

        # Deuxième appel (utilise le cache)
        result2 = test_function("test")
        self.assertEqual(result2, "result_test")
        self.assertEqual(call_count, 1)

    def test_clear(self):
        """Teste la méthode clear du gestionnaire de cache."""
        # Créer une instance du gestionnaire de cache
        manager = CacheManager()

        # Ajouter des données au cache
        cache = manager.get_cache()
        cache.set("key1", "value1")
        cache.set("key2", "value2")

        # Vérifier que les données sont dans le cache
        self.assertEqual(cache.get("key1"), "value1")
        self.assertEqual(cache.get("key2"), "value2")

        # Vider le cache
        manager.clear()

        # Vérifier que les données ont été supprimées
        self.assertIsNone(cache.get("key1"))
        self.assertIsNone(cache.get("key2"))

    def test_get_statistics(self):
        """Teste la méthode get_statistics du gestionnaire de cache."""
        # Créer une instance du gestionnaire de cache
        manager = CacheManager()

        # Ajouter des données au cache
        cache = manager.get_cache()
        cache.set("key1", "value1")
        cache.set("key2", "value2")

        # Accéder à certaines clés
        cache.get("key1")
        cache.get("key3")  # Clé inexistante

        # Récupérer les statistiques
        stats = manager.get_statistics()

        # Vérifier les statistiques
        self.assertEqual(stats["sets"], 2)
        self.assertEqual(stats["hits"], 1)
        self.assertEqual(stats["misses"], 1)


class TestUtilityFunctions(unittest.TestCase):
    """Tests pour les fonctions utilitaires."""

    def setUp(self):
        """Initialisation avant chaque test."""
        # Réinitialiser l'instance du gestionnaire de cache
        CacheManager._instance = None

        # Vider le cache
        clear_all_caches()

    def test_get_cache_manager(self):
        """Teste la fonction get_cache_manager."""
        # Récupérer l'instance du gestionnaire de cache
        manager = get_cache_manager()

        # Vérifier que l'instance est correcte
        self.assertIsInstance(manager, CacheManager)

        # Récupérer une deuxième instance
        manager2 = get_cache_manager()

        # Vérifier que les deux instances sont identiques
        self.assertIs(manager, manager2)

    def test_cached_function(self):
        """Teste la fonction cached_function."""
        # Compteur d'appels
        call_count = 0

        # Définir une fonction à mettre en cache
        @cached_function(ttl=60)
        def test_function(param):
            nonlocal call_count
            call_count += 1
            return f"result_{param}"

        # Premier appel (exécute la fonction)
        result1 = test_function("test")
        self.assertEqual(result1, "result_test")
        self.assertEqual(call_count, 1)

        # Deuxième appel (utilise le cache)
        result2 = test_function("test")
        self.assertEqual(result2, "result_test")
        self.assertEqual(call_count, 1)

    @patch('requests.request')
    def test_cached_http_request(self, mock_request):
        """Teste la fonction cached_http_request."""
        # Configurer le mock
        mock_response = MagicMock()
        mock_response.json.return_value = {"id": 1, "title": "Test"}
        mock_request.return_value = mock_response

        # Appeler la fonction
        response = cached_http_request("GET", "https://example.com/api/test")

        # Vérifier que la fonction a été appelée
        mock_request.assert_called()

        # Vérifier la réponse
        self.assertEqual(response.json(), {"id": 1, "title": "Test"})

    def test_cached_n8n_workflow(self):
        """Teste la fonction cached_n8n_workflow."""
        # Créer un mock pour N8nCacheAdapter.execute_workflow
        with patch('scripts.utils.cache.adapters.n8n_adapter.N8nCacheAdapter.execute_workflow') as mock_execute_workflow:
            # Configurer le mock
            mock_execute_workflow.return_value = {"success": True, "data": {"result": "Test"}}

            # Appeler la fonction
            result = cached_n8n_workflow("workflow1", {"param": "value"})

            # Vérifier que la fonction a été appelée
            mock_execute_workflow.assert_called()

            # Vérifier le résultat
            self.assertEqual(result, {"success": True, "data": {"result": "Test"}})

    def test_invalidate_cache(self):
        """Teste la fonction invalidate_cache."""
        # Récupérer l'instance du gestionnaire de cache
        manager = get_cache_manager()
        cache = manager.get_cache()

        # Ajouter une donnée au cache
        cache.set("test_key", "test_value")

        # Vérifier que la donnée est dans le cache
        self.assertEqual(cache.get("test_key"), "test_value")

        # Invalider la donnée
        result = invalidate_cache("test_key")

        # Vérifier que l'invalidation a réussi
        self.assertTrue(result)

        # Vérifier que la donnée a été supprimée
        self.assertIsNone(cache.get("test_key"))

    def test_clear_all_caches(self):
        """Teste la fonction clear_all_caches."""
        # Récupérer l'instance du gestionnaire de cache
        manager = get_cache_manager()
        cache = manager.get_cache()

        # Ajouter des données au cache
        cache.set("key1", "value1")
        cache.set("key2", "value2")

        # Vérifier que les données sont dans le cache
        self.assertEqual(cache.get("key1"), "value1")
        self.assertEqual(cache.get("key2"), "value2")

        # Vider tous les caches
        clear_all_caches()

        # Vérifier que les données ont été supprimées
        self.assertIsNone(cache.get("key1"))
        self.assertIsNone(cache.get("key2"))

    def test_get_cache_statistics(self):
        """Teste la fonction get_cache_statistics."""
        # Récupérer l'instance du gestionnaire de cache
        manager = get_cache_manager()
        cache = manager.get_cache()

        # Ajouter des données au cache
        cache.set("key1", "value1")
        cache.set("key2", "value2")

        # Accéder à certaines clés
        cache.get("key1")
        cache.get("key3")  # Clé inexistante

        # Récupérer les statistiques
        stats = get_cache_statistics()

        # Vérifier les statistiques
        self.assertEqual(stats["sets"], 2)
        self.assertEqual(stats["hits"], 1)
        self.assertEqual(stats["misses"], 1)


if __name__ == '__main__':
    unittest.main()
