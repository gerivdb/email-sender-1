#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour la classe DocumentManager.

Ce module contient les tests unitaires pour la classe DocumentManager.
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

class TestDocumentManager(unittest.TestCase):
    """Tests pour la classe DocumentManager."""
    
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
    
    def test_fetch_documentation(self):
        """Test de la méthode fetch_documentation."""
        # Récupérer tous les documents
        documents = self.document_manager.fetch_documentation(self.temp_dir)
        
        # Vérifier qu'il y a 2 documents (sans récursion)
        self.assertEqual(len(documents), 2)
        
        # Récupérer tous les documents avec récursion
        documents = self.document_manager.fetch_documentation(self.temp_dir, recursive=True)
        
        # Vérifier qu'il y a 3 documents (avec récursion)
        self.assertEqual(len(documents), 3)
        
        # Récupérer les documents avec un pattern
        documents = self.document_manager.fetch_documentation(self.temp_dir, recursive=True, file_patterns=[r"\.txt$"])
        
        # Vérifier qu'il y a 2 documents .txt
        self.assertEqual(len(documents), 2)
    
    def test_read_file(self):
        """Test de la méthode read_file."""
        # Lire un fichier existant
        file_path = os.path.join(self.temp_dir, "test.txt")
        result = self.document_manager.read_file(file_path)
        
        # Vérifier que la lecture a réussi
        self.assertTrue(result["success"])
        self.assertEqual(result["content"], "Ceci est un fichier de test.\nIl contient plusieurs lignes.\nPython est un langage de programmation.")
        
        # Lire un fichier inexistant
        result = self.document_manager.read_file(os.path.join(self.temp_dir, "nonexistent.txt"))
        
        # Vérifier que la lecture a échoué
        self.assertFalse(result["success"])
    
    def test_search_documentation(self):
        """Test de la méthode search_documentation."""
        # Rechercher un terme présent dans un seul fichier
        results = self.document_manager.search_documentation("Python", [self.temp_dir], recursive=True)
        
        # Vérifier qu'il y a 1 résultat
        self.assertEqual(len(results), 1)
        
        # Rechercher un terme présent dans plusieurs fichiers
        results = self.document_manager.search_documentation("Ceci", [self.temp_dir], recursive=True)
        
        # Vérifier qu'il y a 3 résultats
        self.assertEqual(len(results), 3)
        
        # Rechercher un terme absent
        results = self.document_manager.search_documentation("inexistant", [self.temp_dir], recursive=True)
        
        # Vérifier qu'il n'y a pas de résultat
        self.assertEqual(len(results), 0)

if __name__ == "__main__":
    unittest.main()
