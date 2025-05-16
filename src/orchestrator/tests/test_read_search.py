#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests pour le module de lecture et recherche thématique.
"""

import os
import sys
import unittest
import tempfile
import json
import shutil
import time
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

from src.orchestrator.thematic_crud.create_update import ThematicCreateUpdate
from src.orchestrator.thematic_crud.read_search import ThematicReadSearch

class TestThematicReadSearch(unittest.TestCase):
    """Tests pour le gestionnaire de lecture et recherche thématique."""
    
    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un répertoire temporaire pour le stockage
        self.temp_dir = tempfile.mkdtemp()
        
        # Créer un gestionnaire de création et mise à jour thématique
        self.create_update = ThematicCreateUpdate(self.temp_dir)
        
        # Créer un gestionnaire de lecture et recherche thématique
        self.read_search = ThematicReadSearch(self.temp_dir)
        
        # Créer des éléments de test
        self._create_test_items()
    
    def tearDown(self):
        """Nettoyage après chaque test."""
        # Supprimer le répertoire temporaire
        if os.path.exists(self.temp_dir):
            shutil.rmtree(self.temp_dir)
    
    def _create_test_items(self):
        """Crée des éléments de test."""
        # Élément 1: Architecture
        content1 = """
        # Architecture du système
        
        Ce document décrit l'architecture et la conception du système.
        Il présente les différents composants et leurs interactions.
        """
        
        metadata1 = {
            "title": "Architecture du système",
            "author": "John Doe",
            "tags": ["architecture", "conception", "système"]
        }
        
        self.item1 = self.create_update.create_item(content1, metadata1)
        
        # Élément 2: Développement
        content2 = """
        # Guide de développement
        
        Ce document présente les pratiques de développement du système.
        Il décrit les conventions de code et les outils à utiliser.
        """
        
        metadata2 = {
            "title": "Guide de développement",
            "author": "Jane Smith",
            "tags": ["développement", "code", "pratiques"]
        }
        
        self.item2 = self.create_update.create_item(content2, metadata2)
        
        # Élément 3: Tests
        content3 = """
        # Stratégie de test
        
        Ce document décrit la stratégie de test du système.
        Il présente les différents types de tests et leur mise en œuvre.
        """
        
        metadata3 = {
            "title": "Stratégie de test",
            "author": "John Doe",
            "tags": ["test", "qualité", "validation"]
        }
        
        self.item3 = self.create_update.create_item(content3, metadata3)
        
        # Attendre un peu pour que les dates de modification soient différentes
        time.sleep(0.1)
    
    def test_get_item(self):
        """Teste la récupération d'un élément par son identifiant."""
        # Récupérer l'élément 1
        item = self.read_search.get_item(self.item1["id"])
        
        # Vérifier que l'élément a été récupéré correctement
        self.assertIsNotNone(item)
        self.assertEqual(item["id"], self.item1["id"])
        self.assertEqual(item["content"], self.item1["content"])
        self.assertEqual(item["metadata"]["title"], self.item1["metadata"]["title"])
    
    def test_get_nonexistent_item(self):
        """Teste la récupération d'un élément inexistant."""
        # Tenter de récupérer un élément inexistant
        item = self.read_search.get_item("nonexistent")
        
        # Vérifier que la récupération a échoué
        self.assertIsNone(item)
    
    def test_get_items_by_theme(self):
        """Teste la récupération des éléments par thème."""
        # Récupérer les éléments du thème "architecture"
        items = self.read_search.get_items_by_theme("architecture")
        
        # Vérifier que les éléments ont été récupérés correctement
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0]["id"], self.item1["id"])
        
        # Récupérer les éléments du thème "development"
        items = self.read_search.get_items_by_theme("development")
        
        # Vérifier que les éléments ont été récupérés correctement
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0]["id"], self.item2["id"])
    
    def test_search_items_by_query(self):
        """Teste la recherche d'éléments par requête textuelle."""
        # Rechercher les éléments contenant "architecture"
        items = self.read_search.search_items("architecture")
        
        # Vérifier que les éléments ont été récupérés correctement
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0]["id"], self.item1["id"])
        
        # Rechercher les éléments contenant "test"
        items = self.read_search.search_items("test")
        
        # Vérifier que les éléments ont été récupérés correctement
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0]["id"], self.item3["id"])
        
        # Rechercher les éléments contenant "système"
        items = self.read_search.search_items("système")
        
        # Vérifier que les éléments ont été récupérés correctement
        self.assertEqual(len(items), 3)
    
    def test_search_items_by_theme(self):
        """Teste la recherche d'éléments par thème."""
        # Rechercher les éléments du thème "architecture" contenant "système"
        items = self.read_search.search_items("système", themes=["architecture"])
        
        # Vérifier que les éléments ont été récupérés correctement
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0]["id"], self.item1["id"])
    
    def test_search_items_by_metadata(self):
        """Teste la recherche d'éléments par métadonnées."""
        # Rechercher les éléments de l'auteur "John Doe"
        items = self.read_search.search_items("", metadata_filters={"author": "John Doe"})
        
        # Vérifier que les éléments ont été récupérés correctement
        self.assertEqual(len(items), 2)
        
        # Rechercher les éléments avec le tag "conception"
        items = self.read_search.search_items("", metadata_filters={"tags": ["conception"]})
        
        # Vérifier que les éléments ont été récupérés correctement
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0]["id"], self.item1["id"])
    
    def test_get_theme_statistics(self):
        """Teste la récupération des statistiques sur les thèmes."""
        # Récupérer les statistiques
        statistics = self.read_search.get_theme_statistics()
        
        # Vérifier que les statistiques ont été récupérées correctement
        self.assertIn("architecture", statistics)
        self.assertIn("development", statistics)
        self.assertIn("testing", statistics)
        
        self.assertEqual(statistics["architecture"]["count"], 1)
        self.assertEqual(statistics["development"]["count"], 1)
        self.assertEqual(statistics["testing"]["count"], 1)
        
        self.assertIsNotNone(statistics["architecture"]["last_modified"])
        self.assertIsNotNone(statistics["development"]["last_modified"])
        self.assertIsNotNone(statistics["testing"]["last_modified"])

if __name__ == '__main__':
    unittest.main()
