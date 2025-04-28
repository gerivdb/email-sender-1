#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour l'adaptateur de cache n8n.

Ce module contient les tests unitaires pour la classe N8nCacheAdapter
qui implémente un adaptateur de cache pour l'API n8n.

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
from scripts.utils.cache.adapters.n8n_adapter import N8nCacheAdapter, create_n8n_adapter_from_config
from scripts.utils.cache.local_cache import LocalCache


class TestN8nCacheAdapter(unittest.TestCase):
    """Tests pour la classe N8nCacheAdapter."""

    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un répertoire temporaire pour le cache
        self.temp_dir = tempfile.mkdtemp()
        self.cache = LocalCache(cache_dir=self.temp_dir)
        self.adapter = N8nCacheAdapter(
            api_url="http://localhost:5678/api/v1",
            api_key="test-api-key",
            cache=self.cache
        )

        # Créer un fichier de configuration temporaire pour les tests
        self.config_file = os.path.join(self.temp_dir, 'test_config.json')
        self.test_config = {
            "api_url": "http://localhost:5678/api/v1",
            "api_key": "test-api-key",
            "default_ttl": 1800,
            "workflows_ttl": 3600,
            "executions_ttl": 900,
            "credentials_ttl": 7200,
            "tags_ttl": 7200,
            "users_ttl": 7200
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
        adapter = N8nCacheAdapter()
        self.assertEqual(adapter.config["api_url"], "http://localhost:5678/api/v1")
        self.assertEqual(adapter.config["api_key"], "")
        self.assertEqual(adapter.config["default_ttl"], 3600)
        self.assertEqual(adapter.config["workflows_ttl"], 3600)
        self.assertEqual(adapter.config["executions_ttl"], 1800)
        adapter.cache.cache.close()

    def test_init_with_config_file(self):
        """Teste l'initialisation avec un fichier de configuration."""
        adapter = create_n8n_adapter_from_config(self.config_file)
        self.assertEqual(adapter.config["api_url"], "http://localhost:5678/api/v1")
        self.assertEqual(adapter.config["api_key"], "test-api-key")
        self.assertEqual(adapter.config["default_ttl"], 1800)
        self.assertEqual(adapter.config["workflows_ttl"], 3600)
        self.assertEqual(adapter.config["executions_ttl"], 900)
        adapter.cache.cache.close()

    def test_init_with_params(self):
        """Teste l'initialisation avec des paramètres."""
        adapter = N8nCacheAdapter(
            api_url="http://example.com/api/v1",
            api_key="custom-api-key"
        )
        self.assertEqual(adapter.config["api_url"], "http://example.com/api/v1")
        self.assertEqual(adapter.config["api_key"], "custom-api-key")
        self.assertEqual(adapter.default_headers["X-N8N-API-KEY"], "custom-api-key")
        adapter.cache.cache.close()

    def test_get_ttl_for_endpoint(self):
        """Teste la détermination de la durée de vie pour un endpoint."""
        self.assertEqual(self.adapter.get_ttl_for_endpoint("/workflows"), 3600)
        self.assertEqual(self.adapter.get_ttl_for_endpoint("/executions"), 1800)
        self.assertEqual(self.adapter.get_ttl_for_endpoint("/credentials"), 7200)
        self.assertEqual(self.adapter.get_ttl_for_endpoint("/tags"), 7200)
        self.assertEqual(self.adapter.get_ttl_for_endpoint("/users"), 7200)
        self.assertEqual(self.adapter.get_ttl_for_endpoint("/other"), 3600)

    @patch('requests.request')
    def test_get_workflows(self, mock_request):
        """Teste la récupération des workflows."""
        # Simuler une réponse HTTP
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.headers = {"Content-Type": "application/json"}
        mock_response.content = b'{"data": [{"id": "1", "name": "Workflow 1"}, {"id": "2", "name": "Workflow 2"}]}'
        mock_response.encoding = "utf-8"
        mock_response.elapsed.total_seconds.return_value = 0.1
        mock_response.url = "http://localhost:5678/api/v1/workflows"
        mock_response.json.return_value = {"data": [{"id": "1", "name": "Workflow 1"}, {"id": "2", "name": "Workflow 2"}]}
        mock_request.return_value = mock_response

        # Récupérer les workflows
        workflows = self.adapter.get_workflows()

        # Vérifier que la requête a été effectuée correctement
        mock_request.assert_called_once_with(
            "GET",
            "http://localhost:5678/api/v1/workflows",
            params={},
            headers={"X-N8N-API-KEY": "test-api-key"}
        )

        # Vérifier les workflows récupérés
        self.assertEqual(len(workflows), 2)
        self.assertEqual(workflows[0]["id"], "1")
        self.assertEqual(workflows[0]["name"], "Workflow 1")
        self.assertEqual(workflows[1]["id"], "2")
        self.assertEqual(workflows[1]["name"], "Workflow 2")

        # Réinitialiser le mock
        mock_request.reset_mock()

        # Récupérer les workflows actifs
        self.adapter.get_workflows(active=True)

        # Vérifier que la requête a été effectuée correctement
        mock_request.assert_called_once_with(
            "GET",
            "http://localhost:5678/api/v1/workflows",
            params={"active": True},
            headers={"X-N8N-API-KEY": "test-api-key"}
        )

        # Réinitialiser le mock
        mock_request.reset_mock()

        # Récupérer les workflows avec un tag
        self.adapter.get_workflows(tags=["email"])

        # Vérifier que la requête a été effectuée correctement
        mock_request.assert_called_once_with(
            "GET",
            "http://localhost:5678/api/v1/workflows",
            params={"tags": "email"},
            headers={"X-N8N-API-KEY": "test-api-key"}
        )

        # Réinitialiser le mock
        mock_request.reset_mock()

        # Récupérer les workflows avec force_refresh=True
        self.adapter.get_workflows(force_refresh=True)

        # Vérifier que la requête a été effectuée correctement
        mock_request.assert_called_once_with(
            "GET",
            "http://localhost:5678/api/v1/workflows",
            params={},
            headers={"X-N8N-API-KEY": "test-api-key"}
        )

    @patch('requests.request')
    def test_get_workflow(self, mock_request):
        """Teste la récupération d'un workflow."""
        # Simuler une réponse HTTP
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.headers = {"Content-Type": "application/json"}
        mock_response.content = b'{"id": "1", "name": "Workflow 1"}'
        mock_response.encoding = "utf-8"
        mock_response.elapsed.total_seconds.return_value = 0.1
        mock_response.url = "http://localhost:5678/api/v1/workflows/1"
        mock_response.json.return_value = {"id": "1", "name": "Workflow 1"}
        mock_request.return_value = mock_response

        # Récupérer le workflow
        workflow = self.adapter.get_workflow("1")

        # Vérifier que la requête a été effectuée correctement
        mock_request.assert_called_once_with(
            "GET",
            "http://localhost:5678/api/v1/workflows/1",
            headers={"X-N8N-API-KEY": "test-api-key"}
        )

        # Vérifier le workflow récupéré
        self.assertEqual(workflow["id"], "1")
        self.assertEqual(workflow["name"], "Workflow 1")

    @patch('requests.request')
    def test_get_executions(self, mock_request):
        """Teste la récupération des exécutions."""
        # Simuler une réponse HTTP
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.headers = {"Content-Type": "application/json"}
        mock_response.content = b'{"data": [{"id": "1", "workflowId": "1"}, {"id": "2", "workflowId": "2"}]}'
        mock_response.encoding = "utf-8"
        mock_response.elapsed.total_seconds.return_value = 0.1
        mock_response.url = "http://localhost:5678/api/v1/executions"
        mock_response.json.return_value = {"data": [{"id": "1", "workflowId": "1"}, {"id": "2", "workflowId": "2"}]}
        mock_request.return_value = mock_response

        # Récupérer les exécutions
        executions = self.adapter.get_executions()

        # Vérifier que la requête a été effectuée correctement
        mock_request.assert_called_once_with(
            "GET",
            "http://localhost:5678/api/v1/executions",
            params={"limit": 20},
            headers={"X-N8N-API-KEY": "test-api-key"}
        )

        # Vérifier les exécutions récupérées
        self.assertEqual(len(executions), 2)
        self.assertEqual(executions[0]["id"], "1")
        self.assertEqual(executions[0]["workflowId"], "1")
        self.assertEqual(executions[1]["id"], "2")
        self.assertEqual(executions[1]["workflowId"], "2")

        # Réinitialiser le mock
        mock_request.reset_mock()

        # Récupérer les exécutions d'un workflow spécifique
        self.adapter.get_executions(workflow_id="1")

        # Vérifier que la requête a été effectuée correctement
        mock_request.assert_called_once_with(
            "GET",
            "http://localhost:5678/api/v1/executions",
            params={"limit": 20, "workflowId": "1"},
            headers={"X-N8N-API-KEY": "test-api-key"}
        )

        # Réinitialiser le mock
        mock_request.reset_mock()

        # Récupérer les exécutions avec un statut spécifique
        self.adapter.get_executions(status="success")

        # Vérifier que la requête a été effectuée correctement
        mock_request.assert_called_once_with(
            "GET",
            "http://localhost:5678/api/v1/executions",
            params={"limit": 20, "status": "success"},
            headers={"X-N8N-API-KEY": "test-api-key"}
        )

    @patch('requests.post')
    def test_execute_workflow(self, mock_post):
        """Teste l'exécution d'un workflow."""
        # Simuler une réponse HTTP
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.headers = {"Content-Type": "application/json"}
        mock_response.json.return_value = {"id": "1", "status": "success"}
        mock_post.return_value = mock_response

        # Exécuter le workflow
        result = self.adapter.execute_workflow("1", {"input": "value"})

        # Vérifier que la requête a été effectuée correctement
        mock_post.assert_called_once_with(
            "http://localhost:5678/api/v1/workflows/1/execute",
            json={"input": "value"},
            headers={"X-N8N-API-KEY": "test-api-key"}
        )

        # Vérifier le résultat
        self.assertEqual(result["id"], "1")
        self.assertEqual(result["status"], "success")

    @patch('requests.request')
    def test_get_tags(self, mock_request):
        """Teste la récupération des tags."""
        # Simuler une réponse HTTP
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.headers = {"Content-Type": "application/json"}
        mock_response.content = b'{"data": [{"id": "1", "name": "email"}, {"id": "2", "name": "notification"}]}'
        mock_response.encoding = "utf-8"
        mock_response.elapsed.total_seconds.return_value = 0.1
        mock_response.url = "http://localhost:5678/api/v1/tags"
        mock_response.json.return_value = {"data": [{"id": "1", "name": "email"}, {"id": "2", "name": "notification"}]}
        mock_request.return_value = mock_response

        # Récupérer les tags
        tags = self.adapter.get_tags()

        # Vérifier que la requête a été effectuée correctement
        mock_request.assert_called_once_with(
            "GET",
            "http://localhost:5678/api/v1/tags",
            headers={"X-N8N-API-KEY": "test-api-key"}
        )

        # Vérifier les tags récupérés
        self.assertEqual(len(tags), 2)
        self.assertEqual(tags[0]["id"], "1")
        self.assertEqual(tags[0]["name"], "email")
        self.assertEqual(tags[1]["id"], "2")
        self.assertEqual(tags[1]["name"], "notification")

    def test_invalidate_workflows_cache(self):
        """Teste l'invalidation du cache des workflows."""
        # Simuler une mise en cache
        with patch('requests.request') as mock_request:
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.headers = {"Content-Type": "application/json"}
            mock_response.content = b'{"data": []}'
            mock_response.encoding = "utf-8"
            mock_response.elapsed.total_seconds.return_value = 0.1
            mock_response.url = "http://localhost:5678/api/v1/workflows"
            mock_response.json.return_value = {"data": []}
            mock_request.return_value = mock_response

            # Mettre en cache une réponse
            self.adapter.get_workflows()

            # Réinitialiser le mock
            mock_request.reset_mock()

            # Vérifier que la réponse est dans le cache
            self.adapter.get_workflows()
            mock_request.assert_not_called()

            # Invalider le cache des workflows
            self.adapter.invalidate_workflows_cache()

            # Vérifier que la réponse n'est plus dans le cache
            self.adapter.get_workflows()
            mock_request.assert_called_once()

    def test_invalidate_executions_cache(self):
        """Teste l'invalidation du cache des exécutions."""
        # Simuler une mise en cache
        with patch('requests.request') as mock_request:
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.headers = {"Content-Type": "application/json"}
            mock_response.content = b'{"data": []}'
            mock_response.encoding = "utf-8"
            mock_response.elapsed.total_seconds.return_value = 0.1
            mock_response.url = "http://localhost:5678/api/v1/executions"
            mock_response.json.return_value = {"data": []}
            mock_request.return_value = mock_response

            # Mettre en cache une réponse
            self.adapter.get_executions()

            # Réinitialiser le mock
            mock_request.reset_mock()

            # Vérifier que la réponse est dans le cache
            self.adapter.get_executions()
            mock_request.assert_not_called()

            # Invalider le cache des exécutions
            self.adapter.invalidate_executions_cache()

            # Vérifier que la réponse n'est plus dans le cache
            self.adapter.get_executions()
            mock_request.assert_called_once()

    def test_invalidate_tags_cache(self):
        """Teste l'invalidation du cache des tags."""
        # Simuler une mise en cache
        with patch('requests.request') as mock_request:
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.headers = {"Content-Type": "application/json"}
            mock_response.content = b'{"data": []}'
            mock_response.encoding = "utf-8"
            mock_response.elapsed.total_seconds.return_value = 0.1
            mock_response.url = "http://localhost:5678/api/v1/tags"
            mock_response.json.return_value = {"data": []}
            mock_request.return_value = mock_response

            # Mettre en cache une réponse
            self.adapter.get_tags()

            # Réinitialiser le mock
            mock_request.reset_mock()

            # Vérifier que la réponse est dans le cache
            self.adapter.get_tags()
            mock_request.assert_not_called()

            # Invalider le cache des tags
            self.adapter.invalidate_tags_cache()

            # Vérifier que la réponse n'est plus dans le cache
            self.adapter.get_tags()
            mock_request.assert_called_once()

    def test_invalidate_all_cache(self):
        """Teste l'invalidation de tout le cache."""
        # Créer une instance de l'adaptateur n8n avec un cache vide
        adapter = N8nCacheAdapter(
            api_url="http://localhost:5678/api/v1",
            api_key="test-api-key",
            cache=LocalCache(cache_dir=os.path.join(self.temp_dir, 'test_invalidate_all'))
        )

        # Simuler des données en cache
        adapter.cache.set("n8n:workflows", {"data": [{"id": "1"}]})
        adapter.cache.set("n8n:executions", {"data": [{"id": "2"}]})
        adapter.cache.set("n8n:tags", {"data": [{"id": "3"}]})

        # Vérifier que les données sont dans le cache
        self.assertIsNotNone(adapter.cache.get("n8n:workflows"))
        self.assertIsNotNone(adapter.cache.get("n8n:executions"))
        self.assertIsNotNone(adapter.cache.get("n8n:tags"))

        # Invalider tout le cache
        adapter.invalidate_all_cache()

        # Vérifier que les données ne sont plus dans le cache
        self.assertIsNone(adapter.cache.get("n8n:workflows"))
        self.assertIsNone(adapter.cache.get("n8n:executions"))
        self.assertIsNone(adapter.cache.get("n8n:tags"))

        # Fermer le cache pour éviter les problèmes de fichiers verrouillés
        adapter.cache.cache.close()


if __name__ == '__main__':
    unittest.main()
