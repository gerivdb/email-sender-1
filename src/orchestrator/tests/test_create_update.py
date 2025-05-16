#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests pour le module de création et mise à jour thématique.
"""

import os
import sys
import unittest
import tempfile
import json
import shutil
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

from src.orchestrator.thematic_crud.create_update import ThematicCreateUpdate

class TestThematicCreateUpdate(unittest.TestCase):
    """Tests pour le gestionnaire de création et mise à jour thématique."""
    
    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un répertoire temporaire pour le stockage
        self.temp_dir = tempfile.mkdtemp()
        
        # Créer un gestionnaire de création et mise à jour thématique
        self.manager = ThematicCreateUpdate(self.temp_dir)
    
    def tearDown(self):
        """Nettoyage après chaque test."""
        # Supprimer le répertoire temporaire
        if os.path.exists(self.temp_dir):
            shutil.rmtree(self.temp_dir)
    
    def test_create_theme_directories(self):
        """Teste la création des répertoires thématiques."""
        # Vérifier que les répertoires thématiques ont été créés
        for theme in self.manager.theme_attributor.themes.keys():
            theme_dir = os.path.join(self.temp_dir, theme)
            self.assertTrue(os.path.exists(theme_dir))
            self.assertTrue(os.path.isdir(theme_dir))
    
    def test_create_item(self):
        """Teste la création d'un élément."""
        content = """
        # Architecture du système
        
        Ce document décrit l'architecture et la conception du système.
        Il présente les différents composants et leurs interactions.
        """
        
        metadata = {
            "title": "Architecture du système",
            "author": "John Doe",
            "tags": ["architecture", "conception", "système"]
        }
        
        # Créer un élément
        item = self.manager.create_item(content, metadata)
        
        # Vérifier que l'élément a été créé correctement
        self.assertIsNotNone(item)
        self.assertIn("id", item)
        self.assertEqual(item["content"], content)
        self.assertEqual(item["metadata"]["title"], metadata["title"])
        self.assertEqual(item["metadata"]["author"], metadata["author"])
        self.assertIn("themes", item["metadata"])
        self.assertIn("created_at", item["metadata"])
        self.assertIn("updated_at", item["metadata"])
        
        # Vérifier que l'élément a été sauvegardé
        item_path = os.path.join(self.temp_dir, f"{item['id']}.json")
        self.assertTrue(os.path.exists(item_path))
        
        # Vérifier que l'élément a été sauvegardé dans les répertoires thématiques
        for theme in item["metadata"]["themes"].keys():
            theme_path = os.path.join(self.temp_dir, theme, f"{item['id']}.json")
            self.assertTrue(os.path.exists(theme_path))
    
    def test_update_item(self):
        """Teste la mise à jour d'un élément."""
        # Créer un élément
        content = "Ce document décrit l'architecture du système."
        metadata = {"title": "Architecture du système"}
        item = self.manager.create_item(content, metadata)
        
        # Mettre à jour l'élément
        new_content = "Ce document décrit l'architecture et les tests du système."
        updated_item = self.manager.update_item(item["id"], content=new_content)
        
        # Vérifier que l'élément a été mis à jour correctement
        self.assertIsNotNone(updated_item)
        self.assertEqual(updated_item["id"], item["id"])
        self.assertEqual(updated_item["content"], new_content)
        self.assertIn("themes", updated_item["metadata"])
        self.assertNotEqual(updated_item["metadata"]["updated_at"], item["metadata"]["updated_at"])
        
        # Vérifier que les thèmes ont été mis à jour
        self.assertIn("testing", updated_item["metadata"]["themes"])
    
    def test_update_nonexistent_item(self):
        """Teste la mise à jour d'un élément inexistant."""
        # Tenter de mettre à jour un élément inexistant
        updated_item = self.manager.update_item("nonexistent", content="New content")
        
        # Vérifier que la mise à jour a échoué
        self.assertIsNone(updated_item)
    
    def test_detect_theme_changes(self):
        """Teste la détection des changements thématiques."""
        old_themes = {
            "architecture": 0.8,
            "development": 0.4,
            "documentation": 0.3
        }
        
        new_themes = {
            "architecture": 0.6,
            "development": 0.5,
            "testing": 0.7
        }
        
        changes = self.manager._detect_theme_changes(old_themes, new_themes)
        
        self.assertIn("added", changes)
        self.assertIn("removed", changes)
        self.assertIn("increased", changes)
        self.assertIn("decreased", changes)
        
        self.assertIn("testing", changes["added"])
        self.assertIn("documentation", changes["removed"])
        self.assertIn("development", changes["increased"])
        self.assertIn("architecture", changes["decreased"])
    
    def test_create_and_update_with_theme_changes(self):
        """Teste la création et la mise à jour avec détection des changements thématiques."""
        # Créer un élément orienté architecture
        content = "Ce document décrit l'architecture du système."
        metadata = {"title": "Architecture du système"}
        item = self.manager.create_item(content, metadata)
        
        # Vérifier que le thème principal est l'architecture
        self.assertIn("architecture", item["metadata"]["themes"])
        
        # Mettre à jour l'élément avec un contenu orienté tests
        new_content = "Ce document décrit les tests du système."
        updated_item = self.manager.update_item(item["id"], content=new_content)
        
        # Vérifier que les thèmes ont changé
        self.assertIn("testing", updated_item["metadata"]["themes"])
        self.assertIn("theme_changes", updated_item["metadata"])
        self.assertIn("added", updated_item["metadata"]["theme_changes"])
        self.assertIn("testing", updated_item["metadata"]["theme_changes"]["added"])

if __name__ == '__main__':
    unittest.main()
