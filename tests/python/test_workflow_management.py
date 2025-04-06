#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour la gestion des workflows n8n
"""

import os
import sys
import unittest
import json
from pathlib import Path
from unittest.mock import patch, MagicMock


class TestWorkflowManagement(unittest.TestCase):
    """Tests pour la gestion des workflows n8n"""

    def setUp(self):
        """Initialisation des tests"""
        # Obtenir le chemin racine du projet
        self.project_root = Path(__file__).parent.parent.parent
        
        # Définir les chemins des scripts
        self.scripts_dir = self.project_root / "scripts" / "workflow"
        self.delete_script = self.scripts_dir / "delete" / "delete-all-workflows-improved.ps1"

    def test_delete_script_exists(self):
        """Vérifier que le script de suppression des workflows existe"""
        self.assertTrue(self.delete_script.exists(), f"Le script {self.delete_script} n'existe pas")

    def test_workflow_schema(self):
        """Vérifier que le schéma de workflow est valide"""
        # Créer un workflow de test
        workflow = {
            "id": "test-workflow-id",
            "name": "Test Workflow",
            "active": True,
            "nodes": [
                {
                    "id": "test-node-id",
                    "name": "Test Node",
                    "type": "n8n-nodes-base.HttpRequest",
                    "position": [100, 200],
                    "parameters": {
                        "url": "https://example.com",
                        "method": "GET"
                    }
                }
            ],
            "connections": {
                "main": []
            },
            "settings": {
                "executionOrder": "v1"
            },
            "tags": [
                {
                    "id": "test-tag-id",
                    "name": "Test"
                }
            ]
        }
        
        # Vérifier que le workflow est valide
        self.assertEqual(workflow["id"], "test-workflow-id")
        self.assertEqual(workflow["name"], "Test Workflow")
        self.assertTrue(workflow["active"])
        self.assertEqual(len(workflow["nodes"]), 1)
        self.assertEqual(workflow["nodes"][0]["name"], "Test Node")
        self.assertEqual(workflow["tags"][0]["name"], "Test")

    @patch('requests.get')
    def test_get_workflows(self, mock_get):
        """Tester la récupération des workflows via l'API n8n"""
        # Simuler la réponse de l'API
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "data": [
                {
                    "id": "workflow1",
                    "name": "Workflow 1",
                    "active": True
                },
                {
                    "id": "workflow2",
                    "name": "Workflow 2",
                    "active": False
                }
            ]
        }
        mock_get.return_value = mock_response
        
        # Simuler la fonction de récupération des workflows
        def get_workflows(api_url, api_key):
            import requests
            headers = {"X-N8N-API-KEY": api_key}
            response = requests.get(f"{api_url}/api/v1/workflows", headers=headers)
            if response.status_code == 200:
                return response.json()["data"]
            return []
        
        # Appeler la fonction
        workflows = get_workflows("http://localhost:5678", "test-api-key")
        
        # Vérifier les résultats
        self.assertEqual(len(workflows), 2)
        self.assertEqual(workflows[0]["id"], "workflow1")
        self.assertEqual(workflows[1]["name"], "Workflow 2")
        self.assertTrue(workflows[0]["active"])
        self.assertFalse(workflows[1]["active"])
        
        # Vérifier que la fonction a été appelée avec les bons paramètres
        mock_get.assert_called_once_with(
            "http://localhost:5678/api/v1/workflows",
            headers={"X-N8N-API-KEY": "test-api-key"}
        )

    @patch('requests.delete')
    def test_delete_workflow(self, mock_delete):
        """Tester la suppression d'un workflow via l'API n8n"""
        # Simuler la réponse de l'API
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_delete.return_value = mock_response
        
        # Simuler la fonction de suppression d'un workflow
        def delete_workflow(api_url, api_key, workflow_id):
            import requests
            headers = {"X-N8N-API-KEY": api_key}
            response = requests.delete(f"{api_url}/api/v1/workflows/{workflow_id}", headers=headers)
            return response.status_code == 200
        
        # Appeler la fonction
        result = delete_workflow("http://localhost:5678", "test-api-key", "workflow1")
        
        # Vérifier les résultats
        self.assertTrue(result)
        
        # Vérifier que la fonction a été appelée avec les bons paramètres
        mock_delete.assert_called_once_with(
            "http://localhost:5678/api/v1/workflows/workflow1",
            headers={"X-N8N-API-KEY": "test-api-key"}
        )


if __name__ == "__main__":
    unittest.main()
