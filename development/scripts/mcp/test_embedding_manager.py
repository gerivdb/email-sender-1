"""
Script de test pour le gestionnaire d'embeddings.
"""

import os
import numpy as np
import unittest
from embedding_manager import Vector, Embedding, EmbeddingCollection


class TestVector(unittest.TestCase):
    """
    Tests pour la classe Vector.
    """

    def test_initialization(self):
        """
        Teste l'initialisation d'un vecteur.
        """
        # Initialisation avec une liste
        v1 = Vector([1.0, 2.0, 3.0], model_name="test_model")
        self.assertEqual(v1.dimension, 3)
        self.assertEqual(v1.model_name, "test_model")

        # Initialisation avec un tableau numpy
        v2 = Vector(np.array([1.0, 2.0, 3.0]), model_name="test_model")
        self.assertEqual(v2.dimension, 3)

        # Vérifier la normalisation
        v3 = Vector([1.0, 0.0, 0.0], normalize=True)
        self.assertAlmostEqual(np.linalg.norm(v3.data), 1.0)

        v4 = Vector([2.0, 0.0, 0.0], normalize=False)
        self.assertAlmostEqual(np.linalg.norm(v4.data), 2.0)

    def test_normalize(self):
        """
        Teste la normalisation d'un vecteur.
        """
        v = Vector([3.0, 4.0], normalize=False)
        self.assertAlmostEqual(np.linalg.norm(v.data), 5.0)

        v.normalize()
        self.assertAlmostEqual(np.linalg.norm(v.data), 1.0)

    def test_conversions(self):
        """
        Teste les conversions de format.
        """
        v = Vector([1.0, 2.0, 3.0], normalize=False)

        # Test to_list
        self.assertEqual(v.to_list(), [1.0, 2.0, 3.0])

        # Test to_numpy
        np.testing.assert_array_almost_equal(v.to_numpy(), np.array([1.0, 2.0, 3.0]))

    def test_similarity(self):
        """
        Teste les calculs de similarité.
        """
        v1 = Vector([1.0, 0.0], normalize=True)
        v2 = Vector([0.0, 1.0], normalize=True)
        v3 = Vector([1.0, 1.0], normalize=True)

        # Test cosine_similarity
        self.assertAlmostEqual(v1.cosine_similarity(v1), 1.0)
        self.assertAlmostEqual(v1.cosine_similarity(v2), 0.0)
        self.assertAlmostEqual(v1.cosine_similarity(v3), 1.0 / np.sqrt(2))

        # Test euclidean_distance
        self.assertAlmostEqual(v1.euclidean_distance(v1), 0.0)
        self.assertAlmostEqual(v1.euclidean_distance(v2), np.sqrt(2))

        # Test dot_product
        self.assertAlmostEqual(v1.dot_product(v1), 1.0)
        self.assertAlmostEqual(v1.dot_product(v2), 0.0)

    def test_operators(self):
        """
        Teste les opérateurs.
        """
        v = Vector([1.0, 2.0, 3.0], normalize=False)

        # Test __len__
        self.assertEqual(len(v), 3)

        # Test __getitem__
        self.assertEqual(v[0], 1.0)
        self.assertEqual(v[1], 2.0)
        self.assertEqual(v[2], 3.0)

        # Test __repr__
        self.assertTrue("Vector" in repr(v))
        self.assertTrue("dim=3" in repr(v))


class TestEmbedding(unittest.TestCase):
    """
    Tests pour la classe Embedding.
    """

    def test_initialization(self):
        """
        Teste l'initialisation d'un embedding.
        """
        vector = Vector([1.0, 2.0, 3.0], model_name="test_model")
        text = "Ceci est un test"
        metadata = {"source": "test"}

        # Initialisation avec ID
        emb1 = Embedding(vector, text, metadata, id="test_id")
        self.assertEqual(emb1.id, "test_id")
        self.assertEqual(emb1.text, text)
        self.assertEqual(emb1.metadata["source"], "test")

        # Initialisation sans ID (génération automatique)
        emb2 = Embedding(vector, text, metadata)
        self.assertTrue(emb2.id.startswith("emb_"))

        # Vérifier les métadonnées de base
        self.assertEqual(emb1.metadata["model"], "test_model")
        self.assertEqual(emb1.metadata["dimension"], 3)
        self.assertTrue("created_at" in emb1.metadata)
        self.assertTrue("content_hash" in emb1.metadata)

    def test_conversions(self):
        """
        Teste les conversions de format.
        """
        vector = Vector([1.0, 2.0, 3.0], model_name="test_model")
        text = "Ceci est un test"
        metadata = {"source": "test"}
        emb = Embedding(vector, text, metadata, id="test_id")

        # Test to_dict
        data = emb.to_dict()
        self.assertEqual(data["id"], "test_id")
        self.assertEqual(data["text"], text)
        self.assertEqual(data["metadata"]["source"], "test")

        # Test from_dict
        emb2 = Embedding.from_dict(data)
        self.assertEqual(emb2.id, "test_id")
        self.assertEqual(emb2.text, text)
        self.assertEqual(emb2.metadata["source"], "test")

    def test_file_operations(self):
        """
        Teste les opérations de fichier.
        """
        vector = Vector([1.0, 2.0, 3.0], model_name="test_model")
        text = "Ceci est un test"
        metadata = {"source": "test"}
        emb = Embedding(vector, text, metadata, id="test_id")

        # Créer un fichier temporaire
        temp_file = "temp_embedding.json"

        try:
            # Test save_to_file
            emb.save_to_file(temp_file)
            self.assertTrue(os.path.exists(temp_file))

            # Test load_from_file
            emb2 = Embedding.load_from_file(temp_file)
            self.assertEqual(emb2.id, "test_id")
            self.assertEqual(emb2.text, text)
            self.assertEqual(emb2.metadata["source"], "test")
        finally:
            # Nettoyer
            if os.path.exists(temp_file):
                os.remove(temp_file)


class TestEmbeddingCollection(unittest.TestCase):
    """
    Tests pour la classe EmbeddingCollection.
    """

    def test_initialization(self):
        """
        Teste l'initialisation d'une collection.
        """
        collection = EmbeddingCollection(name="test_collection")
        self.assertEqual(collection.name, "test_collection")
        self.assertEqual(len(collection), 0)
        self.assertEqual(collection.metadata["name"], "test_collection")
        self.assertTrue("created_at" in collection.metadata)

    def test_add_get_remove(self):
        """
        Teste l'ajout, la récupération et la suppression d'embeddings.
        """
        collection = EmbeddingCollection(name="test_collection")

        # Créer un embedding
        vector = Vector([1.0, 2.0, 3.0], model_name="test_model")
        text = "Ceci est un test"
        metadata = {"source": "test"}
        emb = Embedding(vector, text, metadata, id="test_id")

        # Test add
        id = collection.add(emb)
        self.assertEqual(id, "test_id")
        self.assertEqual(len(collection), 1)
        self.assertEqual(collection.metadata["count"], 1)

        # Test get
        emb2 = collection.get("test_id")
        self.assertEqual(emb2.id, "test_id")
        self.assertEqual(emb2.text, text)

        # Test remove
        result = collection.remove("test_id")
        self.assertTrue(result)
        self.assertEqual(len(collection), 0)
        self.assertEqual(collection.metadata["count"], 0)

        # Test remove non-existent
        result = collection.remove("non_existent")
        self.assertFalse(result)

    def test_search(self):
        """
        Teste la recherche d'embeddings.
        """
        collection = EmbeddingCollection(name="test_collection")

        # Ajouter des embeddings
        v1 = Vector([1.0, 0.0, 0.0], model_name="test_model")
        v2 = Vector([0.0, 1.0, 0.0], model_name="test_model")
        v3 = Vector([0.0, 0.0, 1.0], model_name="test_model")

        emb1 = Embedding(v1, "Document 1", {"category": "A"}, id="id1")
        emb2 = Embedding(v2, "Document 2", {"category": "B"}, id="id2")
        emb3 = Embedding(v3, "Document 3", {"category": "A"}, id="id3")

        collection.add(emb1)
        collection.add(emb2)
        collection.add(emb3)

        # Test search
        query = Vector([1.0, 0.0, 0.0], model_name="test_model")
        results = collection.search(query, top_k=2)

        self.assertEqual(len(results), 2)
        self.assertEqual(results[0][0].id, "id1")
        self.assertAlmostEqual(results[0][1], 1.0)

        # Test search with threshold
        results = collection.search(query, threshold=0.5)
        self.assertEqual(len(results), 1)

        # Test search with filter
        results = collection.search(
            query,
            filter_func=lambda emb: emb.metadata.get("category") == "A"
        )
        self.assertEqual(len(results), 2)
        self.assertEqual(results[0][0].id, "id1")

    def test_file_operations(self):
        """
        Teste les opérations de fichier.
        """
        collection = EmbeddingCollection(name="test_collection")

        # Ajouter un embedding
        vector = Vector([1.0, 2.0, 3.0], model_name="test_model")
        text = "Ceci est un test"
        metadata = {"source": "test"}
        emb = Embedding(vector, text, metadata, id="test_id")
        collection.add(emb)

        # Créer un fichier temporaire
        temp_file = "temp_collection.json"

        try:
            # Test save_to_file
            collection.save_to_file(temp_file)
            self.assertTrue(os.path.exists(temp_file))

            # Test load_from_file
            collection2 = EmbeddingCollection.load_from_file(temp_file)
            self.assertEqual(collection2.name, "test_collection")
            self.assertEqual(len(collection2), 1)

            emb2 = collection2.get("test_id")
            self.assertEqual(emb2.id, "test_id")
            self.assertEqual(emb2.text, text)
        finally:
            # Nettoyer
            if os.path.exists(temp_file):
                os.remove(temp_file)


if __name__ == "__main__":
    unittest.main()
