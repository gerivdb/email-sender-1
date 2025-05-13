"""
Script de test pour l'interface avec Qdrant.
"""

import os
import json
import unittest
from unittest.mock import patch, MagicMock
from typing import Dict, Any, List, Tuple

from vector_storage import QdrantConfig, QdrantClient


class TestQdrantConfig(unittest.TestCase):
    """
    Tests pour la classe QdrantConfig.
    """
    
    def test_initialization(self):
        """
        Teste l'initialisation de la configuration.
        """
        # Configuration par défaut
        config1 = QdrantConfig()
        self.assertEqual(config1.host, "localhost")
        self.assertEqual(config1.port, 6333)
        self.assertIsNone(config1.api_key)
        self.assertFalse(config1.https)
        self.assertEqual(config1.timeout, 10)
        self.assertEqual(config1.prefix, "")
        
        # Configuration personnalisée
        config2 = QdrantConfig(
            host="example.com",
            port=7777,
            api_key="test_key",
            https=True,
            timeout=20,
            prefix="/api"
        )
        self.assertEqual(config2.host, "example.com")
        self.assertEqual(config2.port, 7777)
        self.assertEqual(config2.api_key, "test_key")
        self.assertTrue(config2.https)
        self.assertEqual(config2.timeout, 20)
        self.assertEqual(config2.prefix, "/api")
    
    def test_base_url(self):
        """
        Teste la propriété base_url.
        """
        # HTTP
        config1 = QdrantConfig(host="example.com", port=7777)
        self.assertEqual(config1.base_url, "http://example.com:7777")
        
        # HTTPS
        config2 = QdrantConfig(host="example.com", port=7777, https=True)
        self.assertEqual(config2.base_url, "https://example.com:7777")
        
        # Avec préfixe
        config3 = QdrantConfig(host="example.com", port=7777, prefix="/api")
        self.assertEqual(config3.base_url, "http://example.com:7777/api")
    
    def test_get_headers(self):
        """
        Teste la méthode get_headers.
        """
        # Sans API key
        config1 = QdrantConfig()
        headers1 = config1.get_headers()
        self.assertEqual(headers1, {"Content-Type": "application/json"})
        
        # Avec API key
        config2 = QdrantConfig(api_key="test_key")
        headers2 = config2.get_headers()
        self.assertEqual(headers2, {
            "Content-Type": "application/json",
            "API-Key": "test_key"
        })
    
    def test_to_dict(self):
        """
        Teste la méthode to_dict.
        """
        config = QdrantConfig(
            host="example.com",
            port=7777,
            api_key="test_key",
            https=True,
            timeout=20,
            prefix="/api"
        )
        
        data = config.to_dict()
        self.assertEqual(data["host"], "example.com")
        self.assertEqual(data["port"], 7777)
        self.assertEqual(data["api_key"], "test_key")
        self.assertTrue(data["https"])
        self.assertEqual(data["timeout"], 20)
        self.assertEqual(data["prefix"], "/api")
    
    def test_from_dict(self):
        """
        Teste la méthode from_dict.
        """
        data = {
            "host": "example.com",
            "port": 7777,
            "api_key": "test_key",
            "https": True,
            "timeout": 20,
            "prefix": "/api"
        }
        
        config = QdrantConfig.from_dict(data)
        self.assertEqual(config.host, "example.com")
        self.assertEqual(config.port, 7777)
        self.assertEqual(config.api_key, "test_key")
        self.assertTrue(config.https)
        self.assertEqual(config.timeout, 20)
        self.assertEqual(config.prefix, "/api")
    
    @patch.dict(os.environ, {
        "QDRANT_HOST": "example.com",
        "QDRANT_PORT": "7777",
        "QDRANT_API_KEY": "test_key",
        "QDRANT_HTTPS": "true",
        "QDRANT_TIMEOUT": "20",
        "QDRANT_PREFIX": "/api"
    })
    def test_from_env(self):
        """
        Teste la méthode from_env.
        """
        config = QdrantConfig.from_env()
        self.assertEqual(config.host, "example.com")
        self.assertEqual(config.port, 7777)
        self.assertEqual(config.api_key, "test_key")
        self.assertTrue(config.https)
        self.assertEqual(config.timeout, 20)
        self.assertEqual(config.prefix, "/api")


class TestQdrantClient(unittest.TestCase):
    """
    Tests pour la classe QdrantClient.
    """
    
    def setUp(self):
        """
        Initialisation des tests.
        """
        self.config = QdrantConfig(
            host="example.com",
            port=7777,
            api_key="test_key"
        )
        self.client = QdrantClient(self.config)
    
    @patch("requests.get")
    def test_make_request_get(self, mock_get):
        """
        Teste la méthode _make_request avec GET.
        """
        # Configurer le mock
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"result": "success"}
        mock_get.return_value = mock_response
        
        # Effectuer la requête
        success, result = self.client._make_request("GET", "/test", params={"param": "value"})
        
        # Vérifier les résultats
        self.assertTrue(success)
        self.assertEqual(result, {"result": "success"})
        
        # Vérifier l'appel au mock
        mock_get.assert_called_once_with(
            "http://example.com:7777/test",
            headers={"Content-Type": "application/json", "API-Key": "test_key"},
            params={"param": "value"},
            timeout=10
        )
    
    @patch("requests.post")
    def test_make_request_post(self, mock_post):
        """
        Teste la méthode _make_request avec POST.
        """
        # Configurer le mock
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"result": "success"}
        mock_post.return_value = mock_response
        
        # Effectuer la requête
        success, result = self.client._make_request("POST", "/test", data={"data": "value"})
        
        # Vérifier les résultats
        self.assertTrue(success)
        self.assertEqual(result, {"result": "success"})
        
        # Vérifier l'appel au mock
        mock_post.assert_called_once_with(
            "http://example.com:7777/test",
            headers={"Content-Type": "application/json", "API-Key": "test_key"},
            json={"data": "value"},
            timeout=10
        )
    
    @patch("requests.get")
    def test_check_health(self, mock_get):
        """
        Teste la méthode check_health.
        """
        # Configurer le mock
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_get.return_value = mock_response
        
        # Effectuer la requête
        result = self.client.check_health()
        
        # Vérifier les résultats
        self.assertTrue(result)
        
        # Vérifier l'appel au mock
        mock_get.assert_called_once_with(
            "http://example.com:7777/healthz",
            headers={"Content-Type": "application/json", "API-Key": "test_key"},
            params=None,
            timeout=10
        )
    
    @patch("requests.get")
    def test_get_collections(self, mock_get):
        """
        Teste la méthode get_collections.
        """
        # Configurer le mock
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "result": {
                "collections": [
                    {"name": "collection1"},
                    {"name": "collection2"}
                ]
            }
        }
        mock_get.return_value = mock_response
        
        # Effectuer la requête
        success, collections = self.client.get_collections()
        
        # Vérifier les résultats
        self.assertTrue(success)
        self.assertEqual(collections, ["collection1", "collection2"])
        
        # Vérifier l'appel au mock
        mock_get.assert_called_once_with(
            "http://example.com:7777/collections",
            headers={"Content-Type": "application/json", "API-Key": "test_key"},
            params=None,
            timeout=10
        )
    
    @patch("requests.get")
    def test_collection_exists(self, mock_get):
        """
        Teste la méthode collection_exists.
        """
        # Configurer le mock
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_get.return_value = mock_response
        
        # Effectuer la requête
        result = self.client.collection_exists("test_collection")
        
        # Vérifier les résultats
        self.assertTrue(result)
        
        # Vérifier l'appel au mock
        mock_get.assert_called_once_with(
            "http://example.com:7777/collections/test_collection",
            headers={"Content-Type": "application/json", "API-Key": "test_key"},
            params=None,
            timeout=10
        )


if __name__ == "__main__":
    unittest.main()
