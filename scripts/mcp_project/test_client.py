#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour le client Python.

Ce script contient les tests unitaires pour le client Python qui interagit avec le serveur FastAPI.
"""

import os
import sys
import unittest
from unittest.mock import patch, MagicMock

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Importer le client
from mcp_project.client import call_mcp_tool

class TestClient(unittest.TestCase):
    """Tests pour le client Python."""
    
    @patch('mcp_project.client.requests.post')
    def test_call_mcp_tool_success(self, mock_post):
        """Teste l'appel à un outil avec succès."""
        # Configurer le mock
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"result": 5}
        mock_post.return_value = mock_response
        
        # Appeler la fonction
        result = call_mcp_tool("http://localhost:8000", "add", {"a": 2, "b": 3})
        
        # Vérifier le résultat
        self.assertEqual(result, {"result": 5})
        
        # Vérifier que la requête a été faite correctement
        mock_post.assert_called_once_with(
            "http://localhost:8000/tools/add",
            json={"a": 2, "b": 3},
            headers={"Content-Type": "application/json", "Accept": "application/json"}
        )
    
    @patch('mcp_project.client.requests.post')
    def test_call_mcp_tool_error(self, mock_post):
        """Teste l'appel à un outil avec une erreur."""
        # Configurer le mock
        mock_response = MagicMock()
        mock_response.status_code = 404
        mock_response.raise_for_status.side_effect = Exception("404 Client Error: Not Found")
        mock_post.return_value = mock_response
        
        # Appeler la fonction et vérifier qu'elle lève une exception
        with self.assertRaises(Exception):
            call_mcp_tool("http://localhost:8000", "nonexistent", {})
        
        # Vérifier que la requête a été faite correctement
        mock_post.assert_called_once_with(
            "http://localhost:8000/tools/nonexistent",
            json={},
            headers={"Content-Type": "application/json", "Accept": "application/json"}
        )

if __name__ == "__main__":
    unittest.main()
