#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour le gestionnaire de l'architecture cognitive des roadmaps.

Ce module contient les tests unitaires pour le gestionnaire de l'architecture cognitive des roadmaps.
"""

import sys
import unittest
import tempfile
import os
import shutil
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent.parent)
sys.path.append(parent_dir)

from src.mcp.core.roadmap import (
    CognitiveManager, FileNodeStorageProvider,
    HierarchyLevel, NodeStatus
)

class TestCognitiveManager(unittest.TestCase):
    """Tests pour la classe CognitiveManager."""

    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un répertoire temporaire pour les tests
        self.temp_dir = tempfile.mkdtemp()
        self.storage_dir = os.path.join(self.temp_dir, "nodes")

        # Créer le fournisseur de stockage
        self.storage_provider = FileNodeStorageProvider(self.storage_dir)

        # Créer une instance du gestionnaire cognitif
        self.cognitive_manager = CognitiveManager(storage_provider=self.storage_provider)

    def tearDown(self):
        """Nettoyage après chaque test."""
        # Supprimer le répertoire temporaire
        shutil.rmtree(self.temp_dir)

    def test_create_cosmos(self):
        """Teste la création d'un COSMOS."""
        # Créer un COSMOS
        cosmos_id = self.cognitive_manager.create_cosmos(
            name="Test Cosmos",
            description="Test description",
            metadata={"version": "1.0"}
        )

        # Vérifier que l'ID a été retourné
        self.assertIsNotNone(cosmos_id)

        # Récupérer le COSMOS
        cosmos = self.cognitive_manager.get_node(cosmos_id)

        # Vérifier les valeurs
        self.assertIsNotNone(cosmos)
        self.assertEqual(cosmos.name, "Test Cosmos")
        self.assertEqual(cosmos.level, HierarchyLevel.COSMOS)
        self.assertEqual(cosmos.description, "Test description")
        self.assertEqual(cosmos.metadata["version"], "1.0")
        self.assertEqual(cosmos.status, NodeStatus.PLANNED)
        self.assertIsNone(cosmos.parent_id)

    def test_create_galaxy(self):
        """Teste la création d'une GALAXIE."""
        # Créer un COSMOS
        cosmos_id = self.cognitive_manager.create_cosmos(
            name="Test Cosmos",
            description="Test description"
        )

        # Créer une GALAXIE
        galaxy_id = self.cognitive_manager.create_galaxy(
            name="Test Galaxy",
            cosmos_id=cosmos_id,
            description="Test description",
            metadata={"priority": "high"}
        )

        # Vérifier que l'ID a été retourné
        self.assertIsNotNone(galaxy_id)

        # Récupérer la GALAXIE
        galaxy = self.cognitive_manager.get_node(galaxy_id)

        # Vérifier les valeurs
        self.assertIsNotNone(galaxy)
        self.assertEqual(galaxy.name, "Test Galaxy")
        self.assertEqual(galaxy.level, HierarchyLevel.GALAXIES)
        self.assertEqual(galaxy.description, "Test description")
        self.assertEqual(galaxy.metadata["priority"], "high")
        self.assertEqual(galaxy.status, NodeStatus.PLANNED)
        self.assertEqual(galaxy.parent_id, cosmos_id)

        # Vérifier que le COSMOS a été mis à jour
        cosmos = self.cognitive_manager.get_node(cosmos_id)
        self.assertIn(galaxy_id, cosmos.children_ids)

        # Essayer de créer une GALAXIE avec un COSMOS inexistant
        from src.mcp.core.roadmap.exceptions import NodeNotFoundError
        with self.assertRaises(NodeNotFoundError):
            self.cognitive_manager.create_galaxy(
                name="Invalid Galaxy",
                cosmos_id="nonexistent"
            )

    def test_create_stellar_system(self):
        """Teste la création d'un SYSTEME STELLAIRE."""
        # Créer un COSMOS
        cosmos_id = self.cognitive_manager.create_cosmos(
            name="Test Cosmos",
            description="Test description"
        )

        # Créer une GALAXIE
        galaxy_id = self.cognitive_manager.create_galaxy(
            name="Test Galaxy",
            cosmos_id=cosmos_id,
            description="Test description"
        )

        # Créer un SYSTEME STELLAIRE
        system_id = self.cognitive_manager.create_stellar_system(
            name="Test System",
            galaxy_id=galaxy_id,
            description="Test description",
            metadata={"status": "in_progress"}
        )

        # Vérifier que l'ID a été retourné
        self.assertIsNotNone(system_id)

        # Récupérer le SYSTEME STELLAIRE
        system = self.cognitive_manager.get_node(system_id)

        # Vérifier les valeurs
        self.assertIsNotNone(system)
        self.assertEqual(system.name, "Test System")
        self.assertEqual(system.level, HierarchyLevel.SYSTEMES)
        self.assertEqual(system.description, "Test description")
        self.assertEqual(system.metadata["status"], "in_progress")
        self.assertEqual(system.status, NodeStatus.PLANNED)
        self.assertEqual(system.parent_id, galaxy_id)

        # Vérifier que la GALAXIE a été mise à jour
        galaxy = self.cognitive_manager.get_node(galaxy_id)
        self.assertIsNotNone(galaxy)
        if galaxy:  # Vérification supplémentaire pour l'IDE
            self.assertIn(system_id, galaxy.children_ids)

        # Essayer de créer un SYSTEME STELLAIRE avec une GALAXIE inexistante
        from src.mcp.core.roadmap.exceptions import NodeNotFoundError
        with self.assertRaises(NodeNotFoundError):
            self.cognitive_manager.create_stellar_system(
                name="Invalid System",
                galaxy_id="nonexistent"
            )

    def test_get_node(self):
        """Teste la récupération d'un nœud."""
        # Créer un COSMOS
        cosmos_id = self.cognitive_manager.create_cosmos(
            name="Test Cosmos",
            description="Test description"
        )

        # Récupérer le COSMOS
        cosmos = self.cognitive_manager.get_node(cosmos_id)

        # Vérifier les valeurs
        self.assertIsNotNone(cosmos)
        if cosmos:  # Vérification supplémentaire pour l'IDE
            self.assertEqual(cosmos.name, "Test Cosmos")

        # Essayer de récupérer un nœud inexistant
        node = self.cognitive_manager.get_node("nonexistent")
        self.assertIsNone(node)

    def test_update_node(self):
        """Teste la mise à jour d'un nœud."""
        # Créer un COSMOS
        cosmos_id = self.cognitive_manager.create_cosmos(
            name="Test Cosmos",
            description="Test description",
            metadata={"version": "1.0"}
        )

        # Mettre à jour le COSMOS
        success = self.cognitive_manager.update_node(
            node_id=cosmos_id,
            name="Updated Cosmos",
            description="Updated description",
            metadata={"version": "2.0", "tags": ["test"]},
            status=NodeStatus.IN_PROGRESS
        )

        # Vérifier que la mise à jour a réussi
        self.assertTrue(success)

        # Récupérer le COSMOS mis à jour
        cosmos = self.cognitive_manager.get_node(cosmos_id)

        # Vérifier les valeurs
        self.assertIsNotNone(cosmos)
        if cosmos:  # Vérification supplémentaire pour l'IDE
            self.assertEqual(cosmos.name, "Updated Cosmos")
            self.assertEqual(cosmos.description, "Updated description")
            self.assertEqual(cosmos.metadata["version"], "2.0")
            self.assertEqual(cosmos.metadata["tags"], ["test"])
            self.assertEqual(cosmos.status, NodeStatus.IN_PROGRESS)

        # Essayer de mettre à jour un nœud inexistant
        success = self.cognitive_manager.update_node(
            node_id="nonexistent",
            name="Invalid"
        )
        self.assertFalse(success)

    def test_delete_node(self):
        """Teste la suppression d'un nœud."""
        # Créer un COSMOS
        cosmos_id = self.cognitive_manager.create_cosmos(
            name="Test Cosmos",
            description="Test description"
        )

        # Créer une GALAXIE
        galaxy_id = self.cognitive_manager.create_galaxy(
            name="Test Galaxy",
            cosmos_id=cosmos_id,
            description="Test description"
        )

        # Essayer de supprimer le COSMOS (qui a un enfant)
        from src.mcp.core.roadmap.exceptions import NodeHasChildrenError
        with self.assertRaises(NodeHasChildrenError):
            self.cognitive_manager.delete_node(cosmos_id)

        # Supprimer la GALAXIE
        success = self.cognitive_manager.delete_node(galaxy_id)
        self.assertTrue(success)

        # Vérifier que la GALAXIE a été supprimée
        galaxy = self.cognitive_manager.get_node(galaxy_id)
        self.assertIsNone(galaxy)

        # Vérifier que le COSMOS a été mis à jour
        cosmos = self.cognitive_manager.get_node(cosmos_id)
        self.assertIsNotNone(cosmos)
        if cosmos:  # Vérification supplémentaire pour l'IDE
            self.assertNotIn(galaxy_id, cosmos.children_ids)

        # Maintenant, supprimer le COSMOS
        success = self.cognitive_manager.delete_node(cosmos_id)
        self.assertTrue(success)

        # Vérifier que le COSMOS a été supprimé
        cosmos = self.cognitive_manager.get_node(cosmos_id)
        self.assertIsNone(cosmos)

    def test_get_children(self):
        """Teste la récupération des enfants d'un nœud."""
        # Créer un COSMOS
        cosmos_id = self.cognitive_manager.create_cosmos(
            name="Test Cosmos",
            description="Test description"
        )

        # Créer des GALAXIES
        galaxy_id1 = self.cognitive_manager.create_galaxy(
            name="Test Galaxy 1",
            cosmos_id=cosmos_id,
            description="Test description 1"
        )

        galaxy_id2 = self.cognitive_manager.create_galaxy(
            name="Test Galaxy 2",
            cosmos_id=cosmos_id,
            description="Test description 2"
        )

        # Récupérer les enfants du COSMOS
        children = self.cognitive_manager.get_children(cosmos_id)

        # Vérifier les valeurs
        self.assertEqual(len(children), 2)
        child_ids = [child.node_id for child in children]
        self.assertIn(galaxy_id1, child_ids)
        self.assertIn(galaxy_id2, child_ids)

        # Essayer de récupérer les enfants d'un nœud inexistant
        children = self.cognitive_manager.get_children("nonexistent")
        self.assertEqual(len(children), 0)

    def test_get_parent(self):
        """Teste la récupération du parent d'un nœud."""
        # Créer un COSMOS
        cosmos_id = self.cognitive_manager.create_cosmos(
            name="Test Cosmos",
            description="Test description"
        )

        # Créer une GALAXIE
        galaxy_id = self.cognitive_manager.create_galaxy(
            name="Test Galaxy",
            cosmos_id=cosmos_id,
            description="Test description"
        )

        # Récupérer le parent de la GALAXIE
        parent = self.cognitive_manager.get_parent(galaxy_id)

        # Vérifier les valeurs
        self.assertIsNotNone(parent)
        if parent:  # Vérification supplémentaire pour l'IDE
            self.assertEqual(parent.node_id, cosmos_id)

        # Récupérer le parent du COSMOS (qui n'en a pas)
        parent = self.cognitive_manager.get_parent(cosmos_id)
        self.assertIsNone(parent)

        # Essayer de récupérer le parent d'un nœud inexistant
        parent = self.cognitive_manager.get_parent("nonexistent")
        self.assertIsNone(parent)

    def test_get_path(self):
        """Teste la récupération du chemin d'un nœud."""
        # Créer un COSMOS
        cosmos_id = self.cognitive_manager.create_cosmos(
            name="Test Cosmos",
            description="Test description"
        )

        # Créer une GALAXIE
        galaxy_id = self.cognitive_manager.create_galaxy(
            name="Test Galaxy",
            cosmos_id=cosmos_id,
            description="Test description"
        )

        # Créer un SYSTEME STELLAIRE
        system_id = self.cognitive_manager.create_stellar_system(
            name="Test System",
            galaxy_id=galaxy_id,
            description="Test description"
        )

        # Récupérer le chemin du SYSTEME STELLAIRE
        path = self.cognitive_manager.get_path(system_id)

        # Vérifier les valeurs
        self.assertEqual(len(path), 3)
        self.assertEqual(path[0].node_id, cosmos_id)
        self.assertEqual(path[1].node_id, galaxy_id)
        self.assertEqual(path[2].node_id, system_id)

        # Récupérer le chemin du COSMOS
        path = self.cognitive_manager.get_path(cosmos_id)
        self.assertEqual(len(path), 1)
        self.assertEqual(path[0].node_id, cosmos_id)

        # Essayer de récupérer le chemin d'un nœud inexistant
        from src.mcp.core.roadmap.exceptions import NodeNotFoundError
        with self.assertRaises(NodeNotFoundError):
            self.cognitive_manager.get_path("nonexistent")

if __name__ == "__main__":
    unittest.main()
