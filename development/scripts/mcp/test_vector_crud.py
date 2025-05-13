"""
Script de test pour les opérations CRUD sur les vecteurs.
"""

import unittest
from unittest.mock import patch, MagicMock
from typing import List, Dict, Any, Tuple

from embedding_manager import Vector, Embedding
from vector_storage_manager import VectorStorageManager
from vector_crud import VectorCRUD


class TestVectorCRUD(unittest.TestCase):
    """
    Tests pour la classe VectorCRUD.
    """
    
    def setUp(self):
        """
        Initialisation des tests.
        """
        # Créer un mock pour le gestionnaire de stockage
        self.mock_storage_manager = MagicMock(spec=VectorStorageManager)
        
        # Configurer le mock pour list_collections
        self.mock_storage_manager.list_collections.return_value = []
        
        # Configurer le mock pour create_collection
        self.mock_storage_manager.create_collection.return_value = True
        
        # Créer l'instance de VectorCRUD avec le mock
        self.crud = VectorCRUD(storage_manager=self.mock_storage_manager)
    
    def test_initialization(self):
        """
        Teste l'initialisation de VectorCRUD.
        """
        # Vérifier que la collection par défaut a été créée
        self.mock_storage_manager.create_collection.assert_called_once_with("default")
        self.assertEqual(self.crud.default_collection, "default")
    
    def test_create(self):
        """
        Teste la méthode create.
        """
        # Configurer le mock pour store_embedding
        self.mock_storage_manager.store_embedding.return_value = True
        
        # Créer un embedding
        vector = Vector([1.0, 2.0, 3.0])
        embedding = Embedding(vector, "Test text", {"source": "test"}, id="test_id")
        
        # Appeler la méthode create
        result = self.crud.create(embedding)
        
        # Vérifier les résultats
        self.assertTrue(result)
        self.mock_storage_manager.store_embedding.assert_called_once_with("default", embedding)
        
        # Tester avec une collection spécifique
        self.mock_storage_manager.store_embedding.reset_mock()
        result = self.crud.create(embedding, collection_name="test_collection")
        self.mock_storage_manager.store_embedding.assert_called_once_with("test_collection", embedding)
    
    def test_create_batch(self):
        """
        Teste la méthode create_batch.
        """
        # Configurer le mock pour store_embeddings
        self.mock_storage_manager.store_embeddings.return_value = (True, 2)
        
        # Créer des embeddings
        vector1 = Vector([1.0, 2.0, 3.0])
        vector2 = Vector([4.0, 5.0, 6.0])
        embedding1 = Embedding(vector1, "Test text 1", {"source": "test"}, id="test_id_1")
        embedding2 = Embedding(vector2, "Test text 2", {"source": "test"}, id="test_id_2")
        embeddings = [embedding1, embedding2]
        
        # Appeler la méthode create_batch
        success, count = self.crud.create_batch(embeddings)
        
        # Vérifier les résultats
        self.assertTrue(success)
        self.assertEqual(count, 2)
        self.mock_storage_manager.store_embeddings.assert_called_once_with("default", embeddings)
        
        # Tester avec une collection spécifique
        self.mock_storage_manager.store_embeddings.reset_mock()
        self.crud.create_batch(embeddings, collection_name="test_collection")
        self.mock_storage_manager.store_embeddings.assert_called_once_with("test_collection", embeddings)
    
    def test_read(self):
        """
        Teste la méthode read.
        """
        # Créer un embedding
        vector = Vector([1.0, 2.0, 3.0])
        embedding = Embedding(vector, "Test text", {"source": "test"}, id="test_id")
        
        # Configurer le mock pour search_similar
        self.mock_storage_manager.search_similar.return_value = [(embedding, 1.0)]
        
        # Appeler la méthode read
        result = self.crud.read("test_id")
        
        # Vérifier les résultats
        self.assertEqual(result, embedding)
        
        # Vérifier l'appel au mock
        self.mock_storage_manager.search_similar.assert_called_once()
        args, kwargs = self.mock_storage_manager.search_similar.call_args
        self.assertEqual(kwargs["collection_name"], "default")
        self.assertEqual(kwargs["limit"], 1)
        self.assertIsNotNone(kwargs["filter"])
        
        # Tester avec une collection spécifique
        self.mock_storage_manager.search_similar.reset_mock()
        self.crud.read("test_id", collection_name="test_collection")
        args, kwargs = self.mock_storage_manager.search_similar.call_args
        self.assertEqual(kwargs["collection_name"], "test_collection")
        
        # Tester le cas où l'embedding n'est pas trouvé
        self.mock_storage_manager.search_similar.return_value = []
        result = self.crud.read("non_existent_id")
        self.assertIsNone(result)
    
    def test_read_batch(self):
        """
        Teste la méthode read_batch.
        """
        # Créer des embeddings
        vector1 = Vector([1.0, 2.0, 3.0])
        vector2 = Vector([4.0, 5.0, 6.0])
        embedding1 = Embedding(vector1, "Test text 1", {"source": "test"}, id="test_id_1")
        embedding2 = Embedding(vector2, "Test text 2", {"source": "test"}, id="test_id_2")
        
        # Configurer le mock pour search_similar
        self.mock_storage_manager.search_similar.return_value = [
            (embedding1, 1.0),
            (embedding2, 1.0)
        ]
        
        # Appeler la méthode read_batch
        results = self.crud.read_batch(["test_id_1", "test_id_2"])
        
        # Vérifier les résultats
        self.assertEqual(len(results), 2)
        self.assertEqual(results[0], embedding1)
        self.assertEqual(results[1], embedding2)
        
        # Vérifier l'appel au mock
        self.mock_storage_manager.search_similar.assert_called_once()
        args, kwargs = self.mock_storage_manager.search_similar.call_args
        self.assertEqual(kwargs["collection_name"], "default")
        self.assertEqual(kwargs["limit"], 2)
        self.assertIsNotNone(kwargs["filter"])
    
    def test_update(self):
        """
        Teste la méthode update.
        """
        # Configurer le mock pour store_embedding
        self.mock_storage_manager.store_embedding.return_value = True
        
        # Créer un embedding
        vector = Vector([1.0, 2.0, 3.0])
        embedding = Embedding(vector, "Test text", {"source": "test"}, id="test_id")
        
        # Appeler la méthode update
        result = self.crud.update(embedding)
        
        # Vérifier les résultats
        self.assertTrue(result)
        self.mock_storage_manager.store_embedding.assert_called_once_with("default", embedding)
    
    def test_delete(self):
        """
        Teste la méthode delete.
        """
        # Configurer le mock pour delete_embedding
        self.mock_storage_manager.delete_embedding.return_value = True
        
        # Appeler la méthode delete
        result = self.crud.delete("test_id")
        
        # Vérifier les résultats
        self.assertTrue(result)
        self.mock_storage_manager.delete_embedding.assert_called_once_with("default", "test_id")
        
        # Tester avec une collection spécifique
        self.mock_storage_manager.delete_embedding.reset_mock()
        self.crud.delete("test_id", collection_name="test_collection")
        self.mock_storage_manager.delete_embedding.assert_called_once_with("test_collection", "test_id")
    
    def test_delete_batch(self):
        """
        Teste la méthode delete_batch.
        """
        # Configurer le mock pour delete_embeddings
        self.mock_storage_manager.delete_embeddings.return_value = True
        
        # Appeler la méthode delete_batch
        result = self.crud.delete_batch(["test_id_1", "test_id_2"])
        
        # Vérifier les résultats
        self.assertTrue(result)
        self.mock_storage_manager.delete_embeddings.assert_called_once()
        args, kwargs = self.mock_storage_manager.delete_embeddings.call_args
        self.assertEqual(args[0], "default")
        self.assertIsNotNone(args[1])
    
    def test_search(self):
        """
        Teste la méthode search.
        """
        # Créer un embedding
        vector = Vector([1.0, 2.0, 3.0])
        embedding = Embedding(vector, "Test text", {"source": "test"}, id="test_id")
        
        # Configurer le mock pour search_similar
        self.mock_storage_manager.search_similar.return_value = [(embedding, 0.9)]
        
        # Appeler la méthode search
        query_vector = Vector([1.0, 2.0, 3.0])
        results = self.crud.search(query_vector, limit=5)
        
        # Vérifier les résultats
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0][0], embedding)
        self.assertEqual(results[0][1], 0.9)
        
        # Vérifier l'appel au mock
        self.mock_storage_manager.search_similar.assert_called_once()
        args, kwargs = self.mock_storage_manager.search_similar.call_args
        self.assertEqual(kwargs["collection_name"], "default")
        self.assertEqual(kwargs["query_vector"], query_vector)
        self.assertEqual(kwargs["limit"], 5)
        self.assertIsNone(kwargs["filter"])
        
        # Tester avec un filtre
        self.mock_storage_manager.search_similar.reset_mock()
        filter = {"must": [{"key": "metadata.type", "match": {"value": "document"}}]}
        self.crud.search(query_vector, filter=filter)
        args, kwargs = self.mock_storage_manager.search_similar.call_args
        self.assertEqual(kwargs["filter"], filter)
    
    def test_search_by_text(self):
        """
        Teste la méthode search_by_text.
        """
        # Créer un embedding
        vector = Vector([1.0, 2.0, 3.0])
        embedding = Embedding(vector, "Test text", {"source": "test"}, id="test_id")
        
        # Configurer le mock pour search_similar
        self.mock_storage_manager.search_similar.return_value = [(embedding, 0.9)]
        
        # Créer une fonction d'embedding fictive
        def mock_embedding_function(text: str) -> Vector:
            return Vector([1.0, 2.0, 3.0])
        
        # Appeler la méthode search_by_text
        results = self.crud.search_by_text("query text", mock_embedding_function)
        
        # Vérifier les résultats
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0][0], embedding)
        self.assertEqual(results[0][1], 0.9)
        
        # Vérifier l'appel au mock
        self.mock_storage_manager.search_similar.assert_called_once()
    
    def test_count(self):
        """
        Teste la méthode count.
        """
        # Configurer le mock pour get_collection_info
        self.mock_storage_manager.get_collection_info.return_value = {
            "vectors_count": 42
        }
        
        # Appeler la méthode count
        count = self.crud.count()
        
        # Vérifier les résultats
        self.assertEqual(count, 42)
        self.mock_storage_manager.get_collection_info.assert_called_once_with("default")
        
        # Tester avec une collection spécifique
        self.mock_storage_manager.get_collection_info.reset_mock()
        self.crud.count(collection_name="test_collection")
        self.mock_storage_manager.get_collection_info.assert_called_once_with("test_collection")
        
        # Tester avec un filtre (non implémenté pour l'instant)
        count = self.crud.count(filter={"key": "value"})
        self.assertEqual(count, 0)


if __name__ == "__main__":
    unittest.main()
