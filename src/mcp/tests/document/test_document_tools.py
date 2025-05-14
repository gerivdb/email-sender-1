#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour les outils de document MCP.

Ce module contient les tests unitaires pour les outils de document MCP.
"""

import os
import sys
import unittest
import tempfile
import shutil
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(str(Path(__file__).parent.parent.parent.parent.parent))

from src.mcp.core.document.DocumentManager import DocumentManager
from src.mcp.core.document.tools import fetch_documentation, search_documentation, read_file

class TestDocumentTools(unittest.TestCase):
    """Tests pour les outils de document MCP."""
    
    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un dossier temporaire pour les tests
        self.temp_dir = tempfile.mkdtemp()
        
        # Créer quelques fichiers de test
        self.create_test_files()
        
        # Créer une instance de DocumentManager avec le dossier temporaire
        self.document_manager = DocumentManager(self.temp_dir)
    
    def tearDown(self):
        """Nettoyage après chaque test."""
        # Supprimer le dossier temporaire
        shutil.rmtree(self.temp_dir)
    
    def create_test_files(self):
        """Crée des fichiers de test dans le dossier temporaire."""
        # Créer un fichier texte
        with open(os.path.join(self.temp_dir, "test.txt"), "w", encoding="utf-8") as f:
            f.write("Ceci est un fichier de test.\nIl contient plusieurs lignes.\nPython est un langage de programmation.")
        
        # Créer un fichier Markdown
        with open(os.path.join(self.temp_dir, "readme.md"), "w", encoding="utf-8") as f:
            f.write("# Titre\n\nCeci est un fichier Markdown.\n\n## Section\n\nContenu de la section.")
        
        # Créer un sous-dossier
        subdir = os.path.join(self.temp_dir, "subdir")
        os.makedirs(subdir, exist_ok=True)
        
        # Créer un fichier dans le sous-dossier
        with open(os.path.join(subdir, "subfile.txt"), "w", encoding="utf-8") as f:
            f.write("Ceci est un fichier dans un sous-dossier.")
    
    def test_fetch_documentation_tool(self):
        """Test de l'outil fetch_documentation."""
        # Paramètres pour l'outil
        params = {
            "path": self.temp_dir,
            "recursive": True,
            "file_patterns": [r"\.txt$"],
            "max_files": 10,
            "include_content": True
        }
        
        # Appeler l'outil
        result = fetch_documentation.fetch_documentation(self.document_manager, params)
        
        # Vérifier le résultat
        self.assertEqual(result["path"], self.temp_dir)
        self.assertTrue(result["recursive"])
        self.assertEqual(len(result["documents"]), 2)
        self.assertEqual(result["count"], 2)
        
        # Vérifier que le contenu est inclus
        self.assertIn("content", result["documents"][0])
    
    def test_fetch_documentation_tool_invalid_params(self):
        """Test de l'outil fetch_documentation avec des paramètres invalides."""
        # Paramètres invalides
        invalid_params = {"invalid": "params"}
        
        # Vérifier que l'outil lève une exception
        with self.assertRaises(ValueError):
            fetch_documentation.fetch_documentation(self.document_manager, invalid_params)
    
    def test_search_documentation_tool(self):
        """Test de l'outil search_documentation."""
        # Paramètres pour l'outil
        params = {
            "query": "Python",
            "paths": [self.temp_dir],
            "recursive": True,
            "include_snippets": True,
            "snippet_size": 20
        }
        
        # Appeler l'outil
        result = search_documentation.search_documentation(self.document_manager, params)
        
        # Vérifier le résultat
        self.assertEqual(result["query"], "Python")
        self.assertEqual(len(result["results"]), 1)
        self.assertEqual(result["count"], 1)
        
        # Vérifier que les extraits sont inclus
        self.assertIn("snippets", result["results"][0])
        self.assertTrue(len(result["results"][0]["snippets"]) > 0)
    
    def test_search_documentation_tool_invalid_params(self):
        """Test de l'outil search_documentation avec des paramètres invalides."""
        # Paramètres invalides
        invalid_params = {"invalid": "params"}
        
        # Vérifier que l'outil lève une exception
        with self.assertRaises(ValueError):
            search_documentation.search_documentation(self.document_manager, invalid_params)
    
    def test_read_file_tool(self):
        """Test de l'outil read_file."""
        # Paramètres pour l'outil
        file_path = os.path.join(self.temp_dir, "test.txt")
        params = {
            "file_path": file_path,
            "line_numbers": True,
            "start_line": 2,
            "end_line": 3
        }
        
        # Appeler l'outil
        result = read_file.read_file(self.document_manager, params)
        
        # Vérifier le résultat
        self.assertTrue(result["success"])
        self.assertIn("2: Il contient plusieurs lignes.", result["content"])
        self.assertIn("3: Python est un langage de programmation.", result["content"])
        
        # Vérifier les informations de ligne
        self.assertEqual(result["line_info"]["start_line"], 2)
        self.assertEqual(result["line_info"]["end_line"], 3)
        self.assertEqual(result["line_info"]["total_lines"], 3)
    
    def test_read_file_tool_invalid_params(self):
        """Test de l'outil read_file avec des paramètres invalides."""
        # Paramètres invalides
        invalid_params = {"invalid": "params"}
        
        # Vérifier que l'outil lève une exception
        with self.assertRaises(ValueError):
            read_file.read_file(self.document_manager, invalid_params)
    
    def test_read_file_tool_nonexistent_file(self):
        """Test de l'outil read_file avec un fichier inexistant."""
        # Paramètres avec un fichier inexistant
        params = {
            "file_path": os.path.join(self.temp_dir, "nonexistent.txt")
        }
        
        # Appeler l'outil
        result = read_file.read_file(self.document_manager, params)
        
        # Vérifier que la lecture a échoué
        self.assertFalse(result["success"])
        self.assertIn("error", result)

if __name__ == "__main__":
    unittest.main()
