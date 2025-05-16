#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests pour le module de suppression et archivage thématique.
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
from src.orchestrator.thematic_crud.delete_archive import ThematicDeleteArchive

class TestThematicDeleteArchive(unittest.TestCase):
    """Tests pour le gestionnaire de suppression et d'archivage thématique."""

    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un répertoire temporaire pour le stockage
        self.temp_dir = tempfile.mkdtemp()

        # Créer un gestionnaire de création et mise à jour thématique
        self.create_update = ThematicCreateUpdate(self.temp_dir)

        # Créer un gestionnaire de lecture et recherche thématique
        self.read_search = ThematicReadSearch(self.temp_dir)

        # Créer un gestionnaire de suppression et d'archivage thématique
        self.delete_archive = ThematicDeleteArchive(self.temp_dir)

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

    def test_delete_item(self):
        """Teste la suppression d'un élément."""
        # Vérifier que l'élément existe
        item = self.read_search.get_item(self.item1["id"])
        self.assertIsNotNone(item)

        # Supprimer l'élément
        result = self.delete_archive.delete_item(self.item1["id"])
        self.assertTrue(result)

        # Vérifier que l'élément a été supprimé
        item = self.read_search.get_item(self.item1["id"])
        self.assertIsNone(item)

        # Vérifier que l'élément a été archivé
        archived_items = self.delete_archive.get_archived_items()
        self.assertEqual(len(archived_items), 1)
        self.assertEqual(archived_items[0]["id"], self.item1["id"])

    def test_delete_item_permanent(self):
        """Teste la suppression permanente d'un élément."""
        # Supprimer l'élément de manière permanente
        result = self.delete_archive.delete_item(self.item1["id"], permanent=True)
        self.assertTrue(result)

        # Vérifier que l'élément a été supprimé
        item = self.read_search.get_item(self.item1["id"])
        self.assertIsNone(item)

        # Vérifier que l'élément n'a pas été archivé
        archived_items = self.delete_archive.get_archived_items()
        self.assertEqual(len(archived_items), 0)

    def test_delete_nonexistent_item(self):
        """Teste la suppression d'un élément inexistant."""
        # Tenter de supprimer un élément inexistant
        result = self.delete_archive.delete_item("nonexistent")
        self.assertFalse(result)

    def test_delete_items_by_theme(self):
        """Teste la suppression des éléments par thème."""
        # Vérifier que les éléments existent
        items = self.read_search.get_items_by_theme("development")
        self.assertEqual(len(items), 1)

        # Supprimer les éléments du thème "development"
        count = self.delete_archive.delete_items_by_theme("development")
        self.assertEqual(count, 1)

        # Vérifier que l'élément a été supprimé
        items = self.read_search.get_items_by_theme("development")
        item_ids = [item["id"] for item in items]
        self.assertNotIn(self.item2["id"], item_ids)

        # Vérifier que les éléments ont été archivés
        archived_items = self.delete_archive.get_archived_items()
        self.assertGreaterEqual(len(archived_items), 1)
        archived_item_ids = [item["id"] for item in archived_items]
        self.assertIn(self.item2["id"], archived_item_ids)

    def test_archive_item(self):
        """Teste l'archivage d'un élément sans le supprimer."""
        # Archiver l'élément
        result = self.delete_archive.archive_item(self.item1["id"])
        self.assertTrue(result)

        # Vérifier que l'élément existe toujours
        item = self.read_search.get_item(self.item1["id"])
        self.assertIsNotNone(item)

        # Vérifier que l'élément a été archivé
        archived_items = self.delete_archive.get_archived_items()
        self.assertEqual(len(archived_items), 1)
        self.assertEqual(archived_items[0]["id"], self.item1["id"])

    def test_archive_items_by_theme(self):
        """Teste l'archivage des éléments par thème sans les supprimer."""
        # Archiver les éléments du thème "testing"
        count = self.delete_archive.archive_items_by_theme("testing")
        self.assertEqual(count, 1)

        # Vérifier que les éléments existent toujours
        items = self.read_search.get_items_by_theme("testing")
        self.assertEqual(len(items), 1)

        # Vérifier que les éléments ont été archivés
        archived_items = self.delete_archive.get_archived_items()
        self.assertGreaterEqual(len(archived_items), 1)
        archived_item_ids = [item["id"] for item in archived_items]
        self.assertIn(self.item3["id"], archived_item_ids)

    def test_restore_archived_item(self):
        """Teste la restauration d'un élément archivé."""
        # Supprimer l'élément
        self.delete_archive.delete_item(self.item1["id"])

        # Vérifier que l'élément a été supprimé
        item = self.read_search.get_item(self.item1["id"])
        self.assertIsNone(item)

        # Restaurer l'élément
        result = self.delete_archive.restore_archived_item(self.item1["id"])
        self.assertTrue(result)

        # Vérifier que l'élément a été restauré
        item = self.read_search.get_item(self.item1["id"])
        self.assertIsNotNone(item)
        if item is not None:  # Vérification supplémentaire pour éviter l'erreur "None is not subscriptable"
            self.assertEqual(item["id"], self.item1["id"])

        # Vérifier que l'élément a été supprimé de l'archive
        archived_items = self.delete_archive.get_archived_items()
        self.assertEqual(len(archived_items), 0)

    def test_restore_nonexistent_archived_item(self):
        """Teste la restauration d'un élément archivé inexistant."""
        # Tenter de restaurer un élément archivé inexistant
        result = self.delete_archive.restore_archived_item("nonexistent")
        self.assertFalse(result)

    def test_get_archived_items(self):
        """Teste la récupération des éléments archivés."""
        # Archiver plusieurs éléments
        self.delete_archive.archive_item(self.item1["id"])
        self.delete_archive.archive_item(self.item2["id"])
        self.delete_archive.archive_item(self.item3["id"])

        # Récupérer les éléments archivés
        archived_items = self.delete_archive.get_archived_items()

        # Vérifier que les éléments ont été récupérés correctement
        self.assertEqual(len(archived_items), 3)

        # Récupérer les éléments archivés avec pagination
        archived_items = self.delete_archive.get_archived_items(limit=2, offset=1)

        # Vérifier que la pagination fonctionne correctement
        self.assertEqual(len(archived_items), 2)

if __name__ == '__main__':
    unittest.main()
