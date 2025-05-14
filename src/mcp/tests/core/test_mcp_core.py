#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour le Core MCP.

Ce module contient les tests unitaires pour le Core MCP.
"""

import sys
import unittest
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent.parent)
sys.path.append(parent_dir)

from src.mcp.core.mcp import MCPCore, MCPRequest

class TestMCPCore(unittest.TestCase):
    """Tests pour la classe MCPCore."""

    def setUp(self):
        """Initialisation avant chaque test."""
        self.mcp = MCPCore("test_server", "1.0.0")

        # Enregistrer quelques outils de test
        @self.mcp.tool()
        def add(a: int, b: int) -> int:
            """Additionne deux nombres."""
            return a + b

        @self.mcp.tool()
        def multiply(a: int, b: int) -> int:
            """Multiplie deux nombres."""
            return a * b

        # Ces fonctions sont utilisées par le MCPCore, donc pas d'avertissement "unused"
        _ = add, multiply

    def test_register_tool(self):
        """Teste l'enregistrement d'un outil."""
        # Vérifier que les outils ont été enregistrés
        self.assertIn("add", self.mcp.tools)
        self.assertIn("multiply", self.mcp.tools)

        # Vérifier les schémas
        self.assertIn("add", self.mcp.schemas)
        self.assertIn("multiply", self.mcp.schemas)

        # Vérifier que les schémas contiennent les informations attendues
        self.assertEqual(self.mcp.schemas["add"]["name"], "add")
        self.assertEqual(self.mcp.schemas["add"]["description"], "Additionne deux nombres.")
        self.assertIn("parameters", self.mcp.schemas["add"])

        self.assertEqual(self.mcp.schemas["multiply"]["name"], "multiply")
        self.assertEqual(self.mcp.schemas["multiply"]["description"], "Multiplie deux nombres.")
        self.assertIn("parameters", self.mcp.schemas["multiply"])

    def test_unregister_tool(self):
        """Teste le désenregistrement d'un outil."""
        # Désenregistrer un outil
        self.mcp.unregister_tool("add")

        # Vérifier que l'outil a été désenregistré
        self.assertNotIn("add", self.mcp.tools)
        self.assertNotIn("add", self.mcp.schemas)

        # Vérifier que l'autre outil est toujours enregistré
        self.assertIn("multiply", self.mcp.tools)
        self.assertIn("multiply", self.mcp.schemas)

    def test_handle_list_tools(self):
        """Teste le traitement d'une requête listTools."""
        # Créer une requête listTools
        request = MCPRequest(
            jsonrpc="2.0",
            id="1",
            method="listTools",
            params={}
        )

        # Traiter la requête
        response = self.mcp.handle_request(request)

        # Vérifier la réponse
        self.assertEqual(response.id, "1")
        self.assertIsNotNone(response.result)
        self.assertIsNone(response.error)

        # Vérifier que la réponse contient la liste des outils
        self.assertIsNotNone(response.result)
        if response.result:
            self.assertIn("tools", response.result)
            tools = response.result["tools"]
            self.assertEqual(len(tools), 2)

        # Vérifier que les outils sont présents dans la liste
        tool_names = [tool["name"] for tool in tools]
        self.assertIn("add", tool_names)
        self.assertIn("multiply", tool_names)

    def test_handle_execute_tool(self):
        """Teste le traitement d'une requête executeTool."""
        # Créer une requête executeTool
        request = MCPRequest(
            jsonrpc="2.0",
            id="1",
            method="executeTool",
            params={
                "name": "add",
                "arguments": {"a": 2, "b": 3}
            }
        )

        # Traiter la requête
        response = self.mcp.handle_request(request)

        # Vérifier la réponse
        self.assertEqual(response.id, "1")
        self.assertIsNotNone(response.result)
        self.assertIsNone(response.error)

        # Vérifier que la réponse contient le résultat de l'exécution
        self.assertIsNotNone(response.result)
        if response.result:
            self.assertIn("result", response.result)
            self.assertEqual(response.result["result"], 5)

    def test_handle_execute_tool_error(self):
        """Teste le traitement d'une requête executeTool avec une erreur."""
        # Créer une requête executeTool avec un outil inexistant
        request = MCPRequest(
            jsonrpc="2.0",
            id="1",
            method="executeTool",
            params={
                "name": "nonexistent",
                "arguments": {}
            }
        )

        # Traiter la requête
        response = self.mcp.handle_request(request)

        # Vérifier la réponse
        self.assertEqual(response.id, "1")
        self.assertIsNone(response.result)
        self.assertIsNotNone(response.error)

        # Vérifier que l'erreur contient les informations attendues
        self.assertIsNotNone(response.error)
        if response.error:
            self.assertEqual(response.error.code, -32601)
            self.assertIn("nonexistent", response.error.message)

    def test_handle_get_schema(self):
        """Teste le traitement d'une requête getSchema."""
        # Créer une requête getSchema
        request = MCPRequest(
            jsonrpc="2.0",
            id="1",
            method="getSchema",
            params={
                "name": "add"
            }
        )

        # Traiter la requête
        response = self.mcp.handle_request(request)

        # Vérifier la réponse
        self.assertEqual(response.id, "1")
        self.assertIsNotNone(response.result)
        self.assertIsNone(response.error)

        # Vérifier que la réponse contient le schéma de l'outil
        self.assertIsNotNone(response.result)
        if response.result:
            self.assertIn("schema", response.result)
            schema = response.result["schema"]
            self.assertEqual(schema["name"], "add")
            self.assertEqual(schema["description"], "Additionne deux nombres.")
            self.assertIn("parameters", schema)

    def test_handle_get_schema_error(self):
        """Teste le traitement d'une requête getSchema avec une erreur."""
        # Créer une requête getSchema avec un outil inexistant
        request = MCPRequest(
            jsonrpc="2.0",
            id="1",
            method="getSchema",
            params={
                "name": "nonexistent"
            }
        )

        # Traiter la requête
        response = self.mcp.handle_request(request)

        # Vérifier la réponse
        self.assertEqual(response.id, "1")
        self.assertIsNone(response.result)
        self.assertIsNotNone(response.error)

        # Vérifier que l'erreur contient les informations attendues
        self.assertIsNotNone(response.error)
        if response.error:
            self.assertEqual(response.error.code, -32601)
            self.assertIn("nonexistent", response.error.message)

    def test_handle_get_status(self):
        """Teste le traitement d'une requête getStatus."""
        # Créer une requête getStatus
        request = MCPRequest(
            jsonrpc="2.0",
            id="1",
            method="getStatus",
            params={}
        )

        # Traiter la requête
        response = self.mcp.handle_request(request)

        # Vérifier la réponse
        self.assertEqual(response.id, "1")
        self.assertIsNotNone(response.result)
        self.assertIsNone(response.error)

        # Vérifier que la réponse contient les informations de statut
        self.assertIsNotNone(response.result)
        if response.result:
            self.assertEqual(response.result["status"], "ok")
            self.assertEqual(response.result["version"], "1.0.0")
            self.assertEqual(response.result["name"], "test_server")
            self.assertIn("uptime", response.result)
            self.assertEqual(response.result["tools_count"], 2)

    def test_handle_unknown_method(self):
        """Teste le traitement d'une requête avec une méthode inconnue."""
        # Créer une requête avec une méthode inconnue
        request = MCPRequest(
            jsonrpc="2.0",
            id="1",
            method="unknownMethod",
            params={}
        )

        # Traiter la requête
        response = self.mcp.handle_request(request)

        # Vérifier la réponse
        self.assertEqual(response.id, "1")
        self.assertIsNone(response.result)
        self.assertIsNotNone(response.error)

        # Vérifier que l'erreur contient les informations attendues
        self.assertIsNotNone(response.error)
        if response.error:
            self.assertEqual(response.error.code, -32601)
            self.assertIn("unknownMethod", response.error.message)

if __name__ == "__main__":
    unittest.main()
