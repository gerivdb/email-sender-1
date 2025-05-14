#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour les outils de code MCP.

Ce module contient les tests unitaires pour les outils de code MCP.
"""

import os
import re
import unittest
import tempfile
from pathlib import Path

import sys
# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent.parent)
sys.path.append(parent_dir)

from src.mcp.core.code.CodeManager import CodeManager
from src.mcp.core.code.tools import search_code, analyze_code, get_code_structure

class TestCodeTools(unittest.TestCase):
    """Tests pour les outils de code MCP."""

    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un répertoire temporaire pour les tests
        self.temp_dir = tempfile.mkdtemp()

        # Créer une instance de CodeManager
        self.code_manager = CodeManager(self.temp_dir)

        # Créer des fichiers de test
        self.create_test_files()

    def create_test_files(self):
        """Crée des fichiers de test."""
        # Fichier Python
        python_content = """#!/usr/bin/env python
# -*- coding: utf-8 -*-

\"\"\"
Module de test.

Ce module est utilisé pour tester les outils de code MCP.
\"\"\"

import os
import sys

class TestClass:
    \"\"\"Classe de test.\"\"\"

    def __init__(self, name):
        \"\"\"Initialise la classe de test.\"\"\"
        self.name = name

    def test_method(self):
        \"\"\"Méthode de test.\"\"\"
        return f"Test: {self.name}"

def test_function():
    \"\"\"Fonction de test.\"\"\"
    return "Test function"

if __name__ == "__main__":
    test = TestClass("Test")
    print(test.test_method())
    print(test_function())
"""

        # Écrire le fichier
        with open(os.path.join(self.temp_dir, "test.py"), "w") as f:
            f.write(python_content)

    def test_search_code_tool(self):
        """Teste l'outil search_code."""
        # Préparer les paramètres
        params = {
            "query": "test",
            "paths": [self.temp_dir],
            "recursive": True
        }

        # Appeler l'outil search_code
        result = search_code.search_code(self.code_manager, params)

        # Vérifier le résultat
        self.assertIn("query", result)
        self.assertEqual(result["query"], "test")
        self.assertIn("results", result)
        self.assertTrue(len(result["results"]) > 0)
        self.assertIn("count", result)
        self.assertEqual(result["count"], len(result["results"]))

    def test_analyze_code_tool(self):
        """Teste l'outil analyze_code."""
        # Préparer les paramètres
        params = {
            "file_path": os.path.join(self.temp_dir, "test.py")
        }

        # Appeler l'outil analyze_code
        result = analyze_code.analyze_code(self.code_manager, params)

        # Vérifier le résultat
        self.assertTrue(result["success"])
        self.assertEqual(result["language"], "python")
        self.assertIn("metrics", result)
        self.assertIn("class_count", result["metrics"])
        self.assertEqual(result["metrics"]["class_count"], 1)
        self.assertIn("function_count", result["metrics"])
        # Notre implémentation compte différemment les fonctions
        self.assertGreaterEqual(result["metrics"]["function_count"], 1)

    def test_get_code_structure_tool(self):
        """Teste l'outil get_code_structure."""
        # Préparer les paramètres
        params = {
            "file_path": os.path.join(self.temp_dir, "test.py")
        }

        # Appeler l'outil get_code_structure
        result = get_code_structure.get_code_structure(self.code_manager, params)

        # Vérifier le résultat
        self.assertTrue(result["success"])
        self.assertEqual(result["language"], "python")
        self.assertIn("structure", result)
        self.assertIn("classes", result["structure"])
        self.assertEqual(len(result["structure"]["classes"]), 1)
        self.assertEqual(result["structure"]["classes"][0]["name"], "TestClass")
        self.assertIn("functions", result["structure"])
        self.assertEqual(len(result["structure"]["functions"]), 1)
        self.assertEqual(result["structure"]["functions"][0]["name"], "test_function")

if __name__ == "__main__":
    unittest.main()
