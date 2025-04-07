#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests pour les utilitaires de gestion des chemins
-------------------------------------------------
Ce script teste les fonctionnalités des modules path_manager.py,
path_normalizer.py et file_finder.py.
"""

import os
import sys
import unittest
from pathlib import Path

# Ajouter le répertoire src/utils au chemin de recherche des modules
sys.path.append(str(Path(__file__).parent.parent.parent / "src" / "utils"))

# Importer les modules à tester
import path_manager
import path_normalizer
import file_finder


class TestPathManager(unittest.TestCase):
    """Tests pour le module path_manager.py."""
    
    def setUp(self):
        """Initialisation avant chaque test."""
        self.project_root = Path(__file__).parent.parent.parent
        self.path_manager = path_manager.PathManager(self.project_root)
    
    def test_get_project_path(self):
        """Test de la méthode get_project_path."""
        relative_path = "scripts/utils/path-utils.ps1"
        absolute_path = self.path_manager.get_project_path(relative_path)
        self.assertEqual(absolute_path, self.project_root / "scripts" / "utils" / "path-utils.ps1")
        self.assertTrue(absolute_path.exists())
    
    def test_get_relative_path(self):
        """Test de la méthode get_relative_path."""
        absolute_path = self.project_root / "scripts" / "utils" / "path-utils.ps1"
        relative_path = self.path_manager.get_relative_path(absolute_path)
        self.assertEqual(relative_path, "scripts/utils/path-utils.ps1")
    
    def test_normalize_path(self):
        """Test de la méthode normalize_path."""
        path = "scripts/utils/path-utils.ps1"
        normalized_path = self.path_manager.normalize_path(path)
        expected_path = "scripts" + os.path.sep + "utils" + os.path.sep + "path-utils.ps1"
        self.assertEqual(normalized_path, expected_path)
        
        # Test avec force_windows_style
        normalized_path = self.path_manager.normalize_path(path, force_windows_style=True)
        self.assertEqual(normalized_path, "scripts\\utils\\path-utils.ps1")
        
        # Test avec force_unix_style
        normalized_path = self.path_manager.normalize_path(path, force_unix_style=True)
        self.assertEqual(normalized_path, "scripts/utils/path-utils.ps1")
    
    def test_remove_path_accents(self):
        """Test de la méthode remove_path_accents."""
        path = "scripts/utilitès/path-utils.ps1"
        path_without_accents = self.path_manager.remove_path_accents(path)
        self.assertEqual(path_without_accents, "scripts/utilites/path-utils.ps1")
    
    def test_replace_path_spaces(self):
        """Test de la méthode replace_path_spaces."""
        path = "scripts/utils test/path-utils.ps1"
        path_without_spaces = self.path_manager.replace_path_spaces(path)
        self.assertEqual(path_without_spaces, "scripts/utils_test/path-utils.ps1")
    
    def test_normalize_path_full(self):
        """Test de la méthode normalize_path_full."""
        path = "scripts/utilitès test/path-utils.ps1"
        normalized_path = self.path_manager.normalize_path_full(path)
        expected_path = "scripts" + os.path.sep + "utilites_test" + os.path.sep + "path-utils.ps1"
        self.assertEqual(normalized_path, expected_path)
    
    def test_has_path_accents(self):
        """Test de la méthode has_path_accents."""
        path_with_accents = "scripts/utilitès/path-utils.ps1"
        path_without_accents = "scripts/utilities/path-utils.ps1"
        self.assertTrue(self.path_manager.has_path_accents(path_with_accents))
        self.assertFalse(self.path_manager.has_path_accents(path_without_accents))
    
    def test_has_path_spaces(self):
        """Test de la méthode has_path_spaces."""
        path_with_spaces = "scripts/utils test/path-utils.ps1"
        path_without_spaces = "scripts/utils_test/path-utils.ps1"
        self.assertTrue(self.path_manager.has_path_spaces(path_with_spaces))
        self.assertFalse(self.path_manager.has_path_spaces(path_without_spaces))
    
    def test_find_files(self):
        """Test de la méthode find_files."""
        files = self.path_manager.find_files(self.project_root / "scripts", "*.ps1", recurse=True)
        self.assertGreater(len(files), 0)


class TestPathNormalizer(unittest.TestCase):
    """Tests pour le module path_normalizer.py."""
    
    def setUp(self):
        """Initialisation avant chaque test."""
        self.project_root = Path(__file__).parent.parent.parent
        self.path_normalizer = path_normalizer.PathNormalizer(self.project_root)
    
    def test_normalize_file_content(self):
        """Test de la méthode normalize_file_content."""
        # Créer un fichier temporaire pour le test
        test_file = self.project_root / "tests" / "path-utils" / "test_file.txt"
        with open(test_file, "w", encoding="utf-8") as f:
            f.write("Test avec des caractères accentués: é à ç\n")
            f.write("Test avec des espaces: test test\n")
            f.write("Test avec des chemins: D:\\DO\\WEB\\N8N tests\\scripts json à tester\\EMAIL SENDER 1\n")
        
        # Normaliser le fichier
        result = self.path_normalizer.normalize_file_content(test_file, dry_run=True)
        self.assertTrue(result)
        
        # Supprimer le fichier temporaire
        test_file.unlink()


class TestFileFinder(unittest.TestCase):
    """Tests pour le module file_finder.py."""
    
    def setUp(self):
        """Initialisation avant chaque test."""
        self.project_root = Path(__file__).parent.parent.parent
        self.file_finder = file_finder.FileFinder(self.project_root)
    
    def test_find_files(self):
        """Test de la méthode find_files."""
        results = self.file_finder.find_files(self.project_root / "scripts", "*.ps1", recurse=True)
        self.assertGreater(len(results), 0)
        self.assertIn("full_path", results[0])
        self.assertIn("relative_path", results[0])
        self.assertIn("name", results[0])
        self.assertIn("extension", results[0])
        self.assertIn("size", results[0])
        self.assertIn("last_modified", results[0])
        self.assertIn("is_readonly", results[0])


if __name__ == "__main__":
    unittest.main()
