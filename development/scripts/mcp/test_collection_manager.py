"""
Script de test pour le gestionnaire de collections.
"""

import os
import json
import unittest
from unittest.mock import patch, MagicMock
from typing import List, Dict, Any, Tuple

from vector_storage_manager import VectorStorageManager
from vector_crud import VectorCRUD
from collection_manager import CollectionConfig, CollectionManager


class TestCollectionConfig(unittest.TestCase):
    """
    Tests pour la classe CollectionConfig.
    """

    def test_initialization(self):
        """
        Teste l'initialisation de la configuration.
        """
        # Configuration par défaut
        config1 = CollectionConfig(name="test_collection")
        self.assertEqual(config1.name, "test_collection")
        self.assertEqual(config1.vector_size, 1536)
        self.assertEqual(config1.distance, "Cosine")
        self.assertFalse(config1.on_disk_payload)
        self.assertEqual(config1.optimizers_config, {})
        self.assertEqual(config1.metadata_indices, [])
        self.assertEqual(config1.description, "")

        # Configuration personnalisée
        config2 = CollectionConfig(
            name="test_collection",
            vector_size=768,
            distance="Euclid",
            on_disk_payload=True,
            optimizers_config={"ef_construct": 100},
            metadata_indices=[{"field_name": "metadata.type", "field_schema": "keyword"}],
            description="Test collection"
        )
        self.assertEqual(config2.name, "test_collection")
        self.assertEqual(config2.vector_size, 768)
        self.assertEqual(config2.distance, "Euclid")
        self.assertTrue(config2.on_disk_payload)
        self.assertEqual(config2.optimizers_config, {"ef_construct": 100})
        self.assertEqual(config2.metadata_indices, [{"field_name": "metadata.type", "field_schema": "keyword"}])
        self.assertEqual(config2.description, "Test collection")

    def test_to_dict(self):
        """
        Teste la méthode to_dict.
        """
        config = CollectionConfig(
            name="test_collection",
            vector_size=768,
            distance="Euclid",
            on_disk_payload=True,
            optimizers_config={"ef_construct": 100},
            metadata_indices=[{"field_name": "metadata.type", "field_schema": "keyword"}],
            description="Test collection"
        )

        data = config.to_dict()
        self.assertEqual(data["name"], "test_collection")
        self.assertEqual(data["vector_size"], 768)
        self.assertEqual(data["distance"], "Euclid")
        self.assertTrue(data["on_disk_payload"])
        self.assertEqual(data["optimizers_config"], {"ef_construct": 100})
        self.assertEqual(data["metadata_indices"], [{"field_name": "metadata.type", "field_schema": "keyword"}])
        self.assertEqual(data["description"], "Test collection")

    def test_from_dict(self):
        """
        Teste la méthode from_dict.
        """
        data = {
            "name": "test_collection",
            "vector_size": 768,
            "distance": "Euclid",
            "on_disk_payload": True,
            "optimizers_config": {"ef_construct": 100},
            "metadata_indices": [{"field_name": "metadata.type", "field_schema": "keyword"}],
            "description": "Test collection"
        }

        config = CollectionConfig.from_dict(data)
        self.assertEqual(config.name, "test_collection")
        self.assertEqual(config.vector_size, 768)
        self.assertEqual(config.distance, "Euclid")
        self.assertTrue(config.on_disk_payload)
        self.assertEqual(config.optimizers_config, {"ef_construct": 100})
        self.assertEqual(config.metadata_indices, [{"field_name": "metadata.type", "field_schema": "keyword"}])
        self.assertEqual(config.description, "Test collection")


class TestCollectionManager(unittest.TestCase):
    """
    Tests pour la classe CollectionManager.
    """

    def setUp(self):
        """
        Initialisation des tests.
        """
        # Créer un mock pour le gestionnaire de stockage
        self.mock_storage_manager = MagicMock(spec=VectorStorageManager)

        # Créer un mock pour le client
        self.mock_client = MagicMock()
        self.mock_storage_manager.client = self.mock_client

        # Configurer le mock pour list_collections
        self.mock_storage_manager.list_collections.return_value = ["collection1", "collection2"]

        # Configurer le mock pour get_collection_info
        self.mock_storage_manager.get_collection_info.return_value = {
            "config": {
                "vectors": {
                    "size": 1536,
                    "distance": "Cosine"
                },
                "on_disk_payload": False
            },
            "vectors_count": 100,
            "segments_count": 1,
            "points_count": 100,
            "status": "green"
        }

        # Créer l'instance de CollectionManager avec le mock
        self.manager = CollectionManager(storage_manager=self.mock_storage_manager)

    def test_initialization(self):
        """
        Teste l'initialisation du gestionnaire de collections.
        """
        # Vérifier que les collections ont été découvertes
        self.assertEqual(len(self.manager.collections), 2)
        self.assertIn("collection1", self.manager.collections)
        self.assertIn("collection2", self.manager.collections)

        # Vérifier les configurations des collections
        config1 = self.manager.collections["collection1"]
        self.assertEqual(config1.name, "collection1")
        self.assertEqual(config1.vector_size, 1536)
        self.assertEqual(config1.distance, "Cosine")
        self.assertFalse(config1.on_disk_payload)

    def test_list_collections(self):
        """
        Teste la méthode list_collections.
        """
        collections = self.manager.list_collections()
        self.assertEqual(len(collections), 2)
        self.assertIn("collection1", collections)
        self.assertIn("collection2", collections)

    def test_get_collection_config(self):
        """
        Teste la méthode get_collection_config.
        """
        # Collection existante
        config = self.manager.get_collection_config("collection1")
        self.assertIsNotNone(config)
        self.assertEqual(config.name, "collection1")

        # Collection inexistante
        config = self.manager.get_collection_config("non_existent")
        self.assertIsNone(config)

    def test_get_collection_info(self):
        """
        Teste la méthode get_collection_info.
        """
        info = self.manager.get_collection_info("collection1")
        self.assertIsNotNone(info)
        self.assertEqual(info["vectors_count"], 100)
        self.assertEqual(info["status"], "green")

    def test_create_collection(self):
        """
        Teste la méthode create_collection.
        """
        # Configurer le mock pour create_collection
        self.mock_storage_manager.create_collection.return_value = True

        # Créer une configuration
        config = CollectionConfig(
            name="new_collection",
            vector_size=768,
            distance="Euclid",
            on_disk_payload=True,
            metadata_indices=[{"field_name": "metadata.type", "field_schema": "keyword"}]
        )

        # Appeler la méthode create_collection
        result = self.manager.create_collection(config)

        # Vérifier les résultats
        self.assertTrue(result)
        self.assertIn("new_collection", self.manager.collections)

        # Vérifier l'appel au mock
        self.mock_storage_manager.create_collection.assert_called_once_with(
            collection_name="new_collection",
            vector_size=768,
            distance="Euclid",
            on_disk_payload=True,
            create_metadata_indices=False
        )

    def test_delete_collection(self):
        """
        Teste la méthode delete_collection.
        """
        # Configurer le mock pour delete_collection
        self.mock_storage_manager.delete_collection.return_value = True

        # Appeler la méthode delete_collection
        result = self.manager.delete_collection("collection1")

        # Vérifier les résultats
        self.assertTrue(result)
        self.assertNotIn("collection1", self.manager.collections)

        # Vérifier l'appel au mock
        self.mock_storage_manager.delete_collection.assert_called_once_with("collection1")

        # Tester avec une collection inexistante
        result = self.manager.delete_collection("non_existent")
        self.assertFalse(result)

    def test_get_crud_for_collection(self):
        """
        Teste la méthode get_crud_for_collection.
        """
        # Collection existante
        crud = self.manager.get_crud_for_collection("collection1")
        self.assertIsNotNone(crud)
        self.assertIsInstance(crud, VectorCRUD)
        self.assertEqual(crud.default_collection, "collection1")

        # Collection inexistante
        crud = self.manager.get_crud_for_collection("non_existent")
        self.assertIsNone(crud)

    def test_get_collection_stats(self):
        """
        Teste la méthode get_collection_stats.
        """
        # Collection existante
        stats = self.manager.get_collection_stats("collection1")
        self.assertIsNotNone(stats)
        self.assertEqual(stats["name"], "collection1")
        self.assertEqual(stats["vectors_count"], 100)
        self.assertEqual(stats["segments_count"], 1)
        self.assertEqual(stats["points_count"], 100)
        self.assertEqual(stats["status"], "green")
        self.assertEqual(stats["vector_size"], 1536)
        self.assertEqual(stats["distance"], "Cosine")
        self.assertFalse(stats["on_disk_payload"])

        # Collection inexistante
        stats = self.manager.get_collection_stats("non_existent")
        self.assertEqual(stats, {})


if __name__ == "__main__":
    unittest.main()
