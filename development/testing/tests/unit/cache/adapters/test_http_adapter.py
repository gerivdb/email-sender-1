#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour l'adaptateur de cache HTTP.

Ce module contient les tests unitaires pour la classe HttpCacheAdapter
qui implémente un adaptateur de cache pour les requêtes HTTP.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import sys
import json
import time
import shutil
import tempfile
import unittest
from unittest.mock import patch, MagicMock
import requests
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', '..')))
from scripts.utils.cache.adapters.cache_adapter import CacheAdapter
from scripts.utils.cache.adapters.http_adapter import HttpCacheAdapter, create_http_adapter_from_config
from scripts.utils.cache.local_cache import LocalCache


class TestHttpCacheAdapter(unittest.TestCase):
    """Tests pour la classe HttpCacheAdapter."""

    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un répertoire temporaire pour le cache
        self.temp_dir = tempfile.mkdtemp()
        self.cache = LocalCache(cache_dir=self.temp_dir)
        self.adapter = HttpCacheAdapter(cache=self.cache)

        # Créer un fichier de configuration temporaire pour les tests
        self.config_file = os.path.join(self.temp_dir, 'test_config.json')
        self.test_config = {
            "default_ttl": 1800,
            "methods_to_cache": ["GET", "HEAD"],
            "status_codes_to_cache": [200],
            "ignore_query_params": ["_", "timestamp"],
            "ignore_headers": ["User-Agent"],
            "vary_headers": ["Accept"]
        }
        with open(self.config_file, 'w', encoding='utf-8') as f:
            json.dump(self.test_config, f)

    def tearDown(self):
        """Nettoyage après chaque test."""
        # Fermer le cache
        self.cache.cache.close()

        # Supprimer le répertoire temporaire
        shutil.rmtree(self.temp_dir)

    def test_init_default(self):
        """Teste l'initialisation avec les paramètres par défaut."""
        adapter = HttpCacheAdapter()
        self.assertEqual(adapter.config["default_ttl"], 3600)
        self.assertEqual(adapter.config["methods_to_cache"], ["GET", "HEAD"])
        # Vérifier que les codes de statut à mettre en cache incluent au moins 200
        self.assertIn(200, adapter.config["status_codes_to_cache"])
        adapter.cache.cache.close()

    def test_init_with_config_file(self):
        """Teste l'initialisation avec un fichier de configuration."""
        adapter = create_http_adapter_from_config(self.config_file)
        self.assertEqual(adapter.config["default_ttl"], 1800)
        self.assertEqual(adapter.config["methods_to_cache"], ["GET", "HEAD"])
        self.assertEqual(adapter.config["status_codes_to_cache"], [200])
        self.assertEqual(adapter.config["ignore_query_params"], ["_", "timestamp"])
        adapter.cache.cache.close()

    def test_generate_cache_key(self):
        """Teste la génération de clés de cache."""
        # Clé pour une requête simple
        key1 = self.adapter.generate_cache_key("GET", "https://example.com/api")
        self.assertTrue(key1.startswith("http:"))
        self.assertEqual(len(key1), 69)  # "http:" + 64 caractères de hash

        # Clé pour une requête avec des paramètres
        key2 = self.adapter.generate_cache_key("GET", "https://example.com/api", params={"q": "test"})
        self.assertTrue(key2.startswith("http:"))
        self.assertNotEqual(key1, key2)

        # Clé pour une requête avec des en-têtes
        key3 = self.adapter.generate_cache_key("GET", "https://example.com/api", headers={"Accept": "application/json"})
        self.assertTrue(key3.startswith("http:"))
        self.assertNotEqual(key1, key3)
        self.assertNotEqual(key2, key3)

        # Clé pour une requête avec des paramètres à ignorer
        key4 = self.adapter.generate_cache_key("GET", "https://example.com/api", params={"q": "test", "_": "123"})
        self.assertTrue(key4.startswith("http:"))
        self.assertNotEqual(key1, key4)

        # Vérifier que les paramètres à ignorer sont ignorés
        adapter = HttpCacheAdapter(config_path=self.config_file)
        # Créer une nouvelle instance avec une configuration qui ignore le paramètre "_"
        adapter.config["ignore_query_params"] = ["_"]
        key5 = adapter.generate_cache_key("GET", "https://example.com/api", params={"q": "test", "_": "123"})
        key6 = adapter.generate_cache_key("GET", "https://example.com/api", params={"q": "test", "_": "456"})
        self.assertEqual(key5, key6)
        adapter.cache.cache.close()

    @patch('requests.request')
    def test_cached_request(self, mock_request):
        """Teste la mise en cache des requêtes."""
        # Simuler une réponse HTTP
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.headers = {"Content-Type": "application/json"}
        mock_response.content = b'{"data": "test"}'
        mock_response.encoding = "utf-8"
        mock_response.elapsed.total_seconds.return_value = 0.1
        mock_response.url = "https://example.com/api"
        mock_request.return_value = mock_response

        # Première requête (mise en cache)
        response1 = self.adapter.cached_request("GET", "https://example.com/api")
        self.assertEqual(response1.status_code, 200)
        mock_request.assert_called_once_with("GET", "https://example.com/api")

        # Réinitialiser le mock
        mock_request.reset_mock()

        # Deuxième requête (depuis le cache)
        response2 = self.adapter.cached_request("GET", "https://example.com/api")
        mock_request.assert_not_called()

        # Vérifier que la réponse vient du cache
        self.assertTrue(hasattr(response2, "from_cache"))
        self.assertTrue(response2.from_cache)

        # Troisième requête (force_refresh=True)
        # Créer une nouvelle réponse pour la requête forcée
        new_response = MagicMock()
        new_response.status_code = 200
        new_response.headers = {"Content-Type": "application/json"}
        new_response.content = b'{"data": "fresh"}'  # Contenu différent
        new_response.encoding = "utf-8"
        new_response.elapsed.total_seconds.return_value = 0.1
        new_response.url = "https://example.com/api"
        mock_request.return_value = new_response

        response3 = self.adapter.cached_request("GET", "https://example.com/api", force_refresh=True)
        mock_request.assert_called_once_with("GET", "https://example.com/api")

        # Vérifier que la réponse est fraîche (pas from_cache)
        self.assertEqual(response3.content, b'{"data": "fresh"}')

    @patch('requests.request')
    def test_http_methods(self, mock_request):
        """Teste les différentes méthodes HTTP."""
        # Simuler une réponse HTTP
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.headers = {"Content-Type": "application/json"}
        mock_response.content = b'{"data": "test"}'
        mock_response.encoding = "utf-8"
        mock_response.elapsed.total_seconds.return_value = 0.1
        mock_response.url = "https://example.com/api"
        mock_request.return_value = mock_response

        # Tester la méthode GET
        self.adapter.get("https://example.com/api")
        mock_request.assert_called_with("GET", "https://example.com/api")

        # Tester la méthode POST
        self.adapter.post("https://example.com/api", json={"key": "value"})
        mock_request.assert_called_with("POST", "https://example.com/api", json={"key": "value"})

        # Tester la méthode PUT
        self.adapter.put("https://example.com/api", json={"key": "value"})
        mock_request.assert_called_with("PUT", "https://example.com/api", json={"key": "value"})

        # Tester la méthode DELETE
        self.adapter.delete("https://example.com/api")
        mock_request.assert_called_with("DELETE", "https://example.com/api")

        # Tester la méthode HEAD
        self.adapter.head("https://example.com/api")
        mock_request.assert_called_with("HEAD", "https://example.com/api")

        # Tester la méthode OPTIONS
        self.adapter.options("https://example.com/api")
        mock_request.assert_called_with("OPTIONS", "https://example.com/api")

        # Tester la méthode PATCH
        self.adapter.patch("https://example.com/api", json={"key": "value"})
        mock_request.assert_called_with("PATCH", "https://example.com/api", json={"key": "value"})

    def test_serialize_deserialize_response(self):
        """Teste la sérialisation et la désérialisation des réponses."""
        # Créer une réponse HTTP
        response = requests.Response()
        response.status_code = 200
        response.headers = {"Content-Type": "application/json"}
        response._content = b'{"data": "test"}'
        response.encoding = "utf-8"
        response.url = "https://example.com/api"

        # Sérialiser la réponse
        serialized = self.adapter.serialize_response(response)

        # Vérifier les champs sérialisés
        self.assertEqual(serialized["url"], "https://example.com/api")
        self.assertEqual(serialized["status_code"], 200)
        self.assertEqual(serialized["headers"], {"Content-Type": "application/json"})
        self.assertEqual(serialized["content"], '{"data": "test"}')
        self.assertEqual(serialized["encoding"], "utf-8")
        self.assertIn("timestamp", serialized)

        # Désérialiser la réponse
        deserialized = self.adapter.deserialize_response(serialized)

        # Vérifier les champs désérialisés
        self.assertEqual(deserialized.url, "https://example.com/api")
        self.assertEqual(deserialized.status_code, 200)
        self.assertEqual(deserialized.headers["Content-Type"], "application/json")
        self.assertEqual(deserialized.content, b'{"data": "test"}')
        self.assertEqual(deserialized.encoding, "utf-8")
        self.assertTrue(hasattr(deserialized, "from_cache"))
        self.assertTrue(deserialized.from_cache)
        self.assertTrue(hasattr(deserialized, "cached_at"))
        self.assertEqual(deserialized.cached_at, serialized["timestamp"])

    def test_should_cache_response(self):
        """Teste la détermination si une réponse doit être mise en cache."""
        # Créer une réponse HTTP
        response = requests.Response()
        response.status_code = 200
        response.headers = {"Content-Type": "application/json"}

        # Vérifier qu'une réponse GET 200 doit être mise en cache
        self.assertTrue(self.adapter.should_cache_response("GET", response))

        # Vérifier qu'une réponse HEAD 200 doit être mise en cache
        self.assertTrue(self.adapter.should_cache_response("HEAD", response))

        # Vérifier qu'une réponse POST 200 ne doit pas être mise en cache
        self.assertFalse(self.adapter.should_cache_response("POST", response))

        # Vérifier qu'une réponse GET 404 ne doit pas être mise en cache
        response.status_code = 404
        self.assertFalse(self.adapter.should_cache_response("GET", response))

        # Vérifier qu'une réponse GET 200 avec Cache-Control: no-store ne doit pas être mise en cache
        response.status_code = 200
        response.headers["Cache-Control"] = "no-store"
        self.assertFalse(self.adapter.should_cache_response("GET", response))

        # Vérifier qu'une réponse GET 200 avec Cache-Control: no-cache ne doit pas être mise en cache
        response.headers["Cache-Control"] = "no-cache"
        self.assertFalse(self.adapter.should_cache_response("GET", response))

    def test_get_ttl_from_response(self):
        """Teste la détermination de la durée de vie à partir d'une réponse."""
        # Créer une réponse HTTP
        response = requests.Response()
        response.headers = {}

        # Vérifier que la durée de vie par défaut est utilisée
        self.assertEqual(self.adapter.get_ttl_from_response(response), 3600)

        # Vérifier que la durée de vie est extraite de Cache-Control: max-age
        response.headers["Cache-Control"] = "max-age=60"
        self.assertEqual(self.adapter.get_ttl_from_response(response), 60)

        # Vérifier que la durée de vie est extraite de Expires
        response.headers.pop("Cache-Control")
        response.headers["Expires"] = "Wed, 21 Oct 2025 07:28:00 GMT"

        # Simuler l'extraction de la date d'expiration
        with patch('email.utils.parsedate_to_datetime') as mock_parsedate:
            from datetime import datetime, timezone
            mock_parsedate.return_value = datetime(2025, 10, 21, 7, 28, 0, tzinfo=timezone.utc)
            with patch('time.time') as mock_time:
                mock_time.return_value = 1634799600  # 21 Oct 2025 07:00:00 GMT
                ttl = self.adapter.get_ttl_from_response(response)
                self.assertTrue(ttl > 0, f"TTL devrait être positif, mais est {ttl}")

    def test_invalidate_url(self):
        """Teste l'invalidation des entrées du cache pour une URL."""
        # Simuler une réponse HTTP
        with patch('requests.request') as mock_request:
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.headers = {"Content-Type": "application/json"}
            mock_response.content = b'{"data": "test"}'
            mock_response.encoding = "utf-8"
            mock_response.elapsed.total_seconds.return_value = 0.1
            mock_response.url = "https://example.com/api"
            mock_request.return_value = mock_response

            # Mettre en cache une réponse
            self.adapter.cached_request("GET", "https://example.com/api")

            # Vérifier que la réponse est dans le cache
            self.assertIsNotNone(self.adapter.get_cached_response(
                self.adapter.generate_cache_key("GET", "https://example.com/api")
            ))

            # Invalider l'URL
            self.adapter.invalidate_url("https://example.com/api")

            # Vérifier que la réponse n'est plus dans le cache
            self.assertIsNone(self.adapter.get_cached_response(
                self.adapter.generate_cache_key("GET", "https://example.com/api")
            ))

    def test_cached_decorator(self):
        """Teste le décorateur cached."""
        # Créer une classe d'adaptateur spécifique pour le test
        class TestAdapter(CacheAdapter):
            def generate_cache_key(self, *args, **kwargs):
                return self.hash_params(*args, **kwargs)

            def serialize_response(self, response):
                return {"value": response, "timestamp": time.time()}

            def deserialize_response(self, serialized_response):
                return serialized_response.get("value")

        # Créer une instance de l'adaptateur de test
        test_adapter = TestAdapter(cache=self.cache)

        # Créer une fonction mock
        mock_func = MagicMock(return_value="result")

        # Appliquer le décorateur
        decorated_func = test_adapter.cached()(mock_func)

        # Premier appel (exécute la fonction)
        result1 = decorated_func("arg1", "arg2", kwarg="kwarg")
        self.assertEqual(result1, "result")
        mock_func.assert_called_once_with("arg1", "arg2", kwarg="kwarg")

        # Réinitialiser le mock
        mock_func.reset_mock()

        # Deuxième appel (utilise le cache)
        result2 = decorated_func("arg1", "arg2", kwarg="kwarg")
        self.assertEqual(result2, "result")
        mock_func.assert_not_called()

        # Troisième appel avec des arguments différents (exécute la fonction)
        result3 = decorated_func("arg1", "arg3", kwarg="kwarg")
        self.assertEqual(result3, "result")
        mock_func.assert_called_once_with("arg1", "arg3", kwarg="kwarg")


if __name__ == '__main__':
    unittest.main()
