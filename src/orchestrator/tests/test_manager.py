#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests pour le gestionnaire CRUD modulaire thématique.
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

from src.orchestrator.thematic_crud.manager import ThematicCRUDManager

class TestThematicCRUDManager(unittest.TestCase):
    """Tests pour le gestionnaire CRUD modulaire thématique."""

    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un répertoire temporaire pour le stockage
        self.temp_dir = tempfile.mkdtemp()
        self.archive_dir = os.path.join(self.temp_dir, "archive")

        # Créer un gestionnaire CRUD modulaire thématique
        self.manager = ThematicCRUDManager(self.temp_dir, self.archive_dir)

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

        self.item1 = self.manager.create_item(content1, metadata1)

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

        self.item2 = self.manager.create_item(content2, metadata2)

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

        self.item3 = self.manager.create_item(content3, metadata3)

        # Attendre un peu pour que les dates de modification soient différentes
        time.sleep(0.1)

    def test_crud_operations(self):
        """Teste les opérations CRUD de base."""
        # Créer un nouvel élément
        content = "Nouveau document"
        metadata = {"title": "Nouveau document", "author": "Test User"}
        item = self.manager.create_item(content, metadata)

        # Vérifier que l'élément a été créé correctement
        self.assertIsNotNone(item)
        self.assertIn("id", item)
        self.assertEqual(item["content"], content)

        # Récupérer l'élément
        retrieved_item = self.manager.get_item(item["id"])
        self.assertIsNotNone(retrieved_item)
        if retrieved_item is not None:  # Vérification supplémentaire pour éviter l'erreur "None is not subscriptable"
            self.assertEqual(retrieved_item["id"], item["id"])

        # Mettre à jour l'élément
        updated_content = "Document mis à jour"
        updated_item = self.manager.update_item(item["id"], content=updated_content)
        self.assertIsNotNone(updated_item)
        if updated_item is not None:  # Vérification supplémentaire pour éviter l'erreur "None is not subscriptable"
            self.assertEqual(updated_item["content"], updated_content)

        # Supprimer l'élément
        result = self.manager.delete_item(item["id"])
        self.assertTrue(result)

        # Vérifier que l'élément a été supprimé
        deleted_item = self.manager.get_item(item["id"])
        self.assertIsNone(deleted_item)

    def test_theme_operations(self):
        """Teste les opérations liées aux thèmes."""
        # Récupérer les éléments par thème
        items = self.manager.get_items_by_theme("architecture")
        self.assertGreaterEqual(len(items), 1)
        item_ids = [item["id"] for item in items]
        self.assertIn(self.item1["id"], item_ids)

        # Récupérer les statistiques sur les thèmes
        statistics = self.manager.get_theme_statistics()
        self.assertIn("architecture", statistics)
        self.assertIn("development", statistics)
        self.assertIn("testing", statistics)

        # Archiver les éléments d'un thème
        count = self.manager.archive_items_by_theme("testing")
        self.assertEqual(count, 1)

        # Récupérer les éléments archivés
        archived_items = self.manager.get_archived_items()
        self.assertEqual(len(archived_items), 1)
        self.assertEqual(archived_items[0]["id"], self.item3["id"])

        # Restaurer un élément archivé
        result = self.manager.restore_archived_item(self.item3["id"])
        self.assertTrue(result)

        # Vérifier que l'élément a été restauré
        restored_item = self.manager.get_item(self.item3["id"])
        self.assertIsNotNone(restored_item)

    def test_search_operations(self):
        """Teste les opérations de recherche."""
        # Rechercher par requête textuelle
        items = self.manager.search_items("architecture")
        self.assertGreaterEqual(len(items), 1)
        item_ids = [item["id"] for item in items]
        self.assertIn(self.item1["id"], item_ids)

        # Rechercher par thème et requête
        items = self.manager.search_items("système", themes=["architecture"])
        self.assertGreaterEqual(len(items), 1)
        item_ids = [item["id"] for item in items]
        self.assertIn(self.item1["id"], item_ids)

        # Rechercher par métadonnées
        items = self.manager.search_items("", metadata_filters={"author": "John Doe"})
        self.assertEqual(len(items), 2)

    def test_theme_attribution(self):
        """Teste l'attribution thématique."""
        # Attribuer des thèmes à un contenu
        content = "Ce document décrit l'architecture du système."
        themes = self.manager.attribute_theme(content)

        # Vérifier que les thèmes ont été attribués correctement
        self.assertIn("architecture", themes)
        self.assertGreater(themes["architecture"], 0.5)

if __name__ == '__main__':
    unittest.main()
