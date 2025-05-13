"""
Script de test pour le générateur d'embeddings.
"""

import unittest
from unittest.mock import patch, MagicMock
import numpy as np
from typing import List, Dict, Any

from embedding_manager import Vector, Embedding, EmbeddingCollection
from embedding_models import EmbeddingModel, EmbeddingModelConfig
from embedding_models_factory import EmbeddingModelManager
from embedding_generator import EmbeddingGenerator


class MockEmbeddingModel(EmbeddingModel):
    """
    Modèle d'embeddings fictif pour les tests.
    """

    def __init__(self, config: EmbeddingModelConfig):
        """
        Initialise le modèle d'embeddings fictif.

        Args:
            config: Configuration du modèle.
        """
        super().__init__(config)

    def embed_text(self, text: str) -> Vector:
        """
        Génère un embedding fictif pour un texte.

        Args:
            text: Texte à encoder.

        Returns:
            Vecteur d'embedding fictif.
        """
        # Générer un vecteur fictif basé sur le hash du texte
        import hashlib
        hash_obj = hashlib.md5(text.encode())
        hash_bytes = hash_obj.digest()

        # Convertir les bytes en flottants entre -1 et 1
        vector_data = [((b / 255) * 2 - 1) for b in hash_bytes]

        # Ajuster la taille du vecteur à la dimension configurée
        if len(vector_data) < self.config.dimension:
            vector_data = vector_data * (self.config.dimension // len(vector_data) + 1)
        vector_data = vector_data[:self.config.dimension]

        return Vector(vector_data, model_name=self.config.model_name)

    def embed_batch(self, texts: List[str]) -> List[Vector]:
        """
        Génère des embeddings fictifs pour une liste de textes.

        Args:
            texts: Liste de textes à encoder.

        Returns:
            Liste de vecteurs d'embedding fictifs.
        """
        return [self.embed_text(text) for text in texts]


class TestEmbeddingGenerator(unittest.TestCase):
    """
    Tests pour la classe EmbeddingGenerator.
    """

    def setUp(self):
        """
        Initialisation des tests.
        """
        # Créer un mock pour le gestionnaire de modèles
        self.mock_model_manager = MagicMock(spec=EmbeddingModelManager)

        # Créer une configuration pour le modèle fictif
        self.config = EmbeddingModelConfig(
            model_name="test-model",
            model_type="mock",
            dimension=16
        )

        # Créer un modèle fictif
        self.model = MockEmbeddingModel(self.config)

        # Configurer le mock pour get_model
        self.mock_model_manager.get_model.return_value = self.model

        # Créer l'instance de EmbeddingGenerator avec le mock
        self.generator = EmbeddingGenerator(
            model_manager=self.mock_model_manager,
            default_model_id="test-model"
        )

    def test_initialization(self):
        """
        Teste l'initialisation du générateur d'embeddings.
        """
        self.assertEqual(self.generator.model_manager, self.mock_model_manager)
        self.assertEqual(self.generator.default_model_id, "test-model")

    def test_generate_embedding(self):
        """
        Teste la méthode generate_embedding.
        """
        # Appeler la méthode generate_embedding
        embedding = self.generator.generate_embedding("Test text")

        # Vérifier les résultats
        self.assertIsInstance(embedding, Embedding)
        self.assertEqual(embedding.text, "Test text")
        self.assertEqual(embedding.vector.dimension, 16)
        self.assertEqual(embedding.vector.model_name, "test-model")

        # Vérifier l'appel au mock
        self.mock_model_manager.get_model.assert_called_once_with("test-model")

        # Tester avec un modèle spécifique
        self.mock_model_manager.get_model.reset_mock()
        self.generator.generate_embedding("Test text", model_id="other-model")
        self.mock_model_manager.get_model.assert_called_once_with("other-model")

        # Tester avec des métadonnées
        embedding = self.generator.generate_embedding("Test text", metadata={"source": "test"})
        self.assertEqual(embedding.metadata.get("source"), "test")

        # Tester avec un identifiant
        embedding = self.generator.generate_embedding("Test text", id="test-id")
        self.assertEqual(embedding.id, "test-id")

    def test_generate_embeddings(self):
        """
        Teste la méthode generate_embeddings.
        """
        # Appeler la méthode generate_embeddings
        embeddings = self.generator.generate_embeddings(["Text 1", "Text 2", "Text 3"])

        # Vérifier les résultats
        self.assertEqual(len(embeddings), 3)
        self.assertIsInstance(embeddings[0], Embedding)
        self.assertEqual(embeddings[0].text, "Text 1")
        self.assertEqual(embeddings[1].text, "Text 2")
        self.assertEqual(embeddings[2].text, "Text 3")

        # Vérifier l'appel au mock
        self.mock_model_manager.get_model.assert_called_once_with("test-model")

        # Tester avec des métadonnées
        metadata_list = [{"source": "test1"}, {"source": "test2"}, {"source": "test3"}]
        embeddings = self.generator.generate_embeddings(
            ["Text 1", "Text 2", "Text 3"],
            metadata_list=metadata_list
        )
        self.assertEqual(embeddings[0].metadata.get("source"), "test1")
        self.assertEqual(embeddings[1].metadata.get("source"), "test2")
        self.assertEqual(embeddings[2].metadata.get("source"), "test3")

        # Tester avec des identifiants
        ids = ["id1", "id2", "id3"]
        embeddings = self.generator.generate_embeddings(
            ["Text 1", "Text 2", "Text 3"],
            ids=ids
        )
        self.assertEqual(embeddings[0].id, "id1")
        self.assertEqual(embeddings[1].id, "id2")
        self.assertEqual(embeddings[2].id, "id3")

        # Tester avec une taille de lot personnalisée
        self.generator.generate_embeddings(
            ["Text 1", "Text 2", "Text 3"],
            batch_size=2
        )
        # Pas de vérification spécifique car le modèle fictif ne gère pas réellement les lots

    def test_generate_embeddings_parallel(self):
        """
        Teste la méthode generate_embeddings_parallel.
        """
        # Appeler la méthode generate_embeddings_parallel
        embeddings = self.generator.generate_embeddings_parallel(
            ["Text 1", "Text 2", "Text 3"],
            max_workers=2
        )

        # Vérifier les résultats
        self.assertEqual(len(embeddings), 3)
        self.assertIsInstance(embeddings[0], Embedding)
        self.assertEqual(embeddings[0].text, "Text 1")
        self.assertEqual(embeddings[1].text, "Text 2")
        self.assertEqual(embeddings[2].text, "Text 3")

        # Vérifier l'appel au mock
        self.mock_model_manager.get_model.assert_called_once_with("test-model")

    def test_generate_collection(self):
        """
        Teste la méthode generate_collection.
        """
        # Appeler la méthode generate_collection
        collection = self.generator.generate_collection(
            ["Text 1", "Text 2", "Text 3"],
            collection_name="test-collection"
        )

        # Vérifier les résultats
        self.assertIsInstance(collection, EmbeddingCollection)
        self.assertEqual(collection.name, "test-collection")
        self.assertEqual(len(collection), 3)

        # Vérifier l'appel au mock
        self.mock_model_manager.get_model.assert_called_once_with("test-model")

    def test_error_handling(self):
        """
        Teste la gestion des erreurs.
        """
        # Tester avec des listes de métadonnées de longueur incorrecte
        with self.assertRaises(ValueError):
            self.generator.generate_embeddings(
                ["Text 1", "Text 2", "Text 3"],
                metadata_list=[{"source": "test1"}, {"source": "test2"}]
            )

        # Tester avec des listes d'identifiants de longueur incorrecte
        with self.assertRaises(ValueError):
            self.generator.generate_embeddings(
                ["Text 1", "Text 2", "Text 3"],
                ids=["id1", "id2"]
            )


if __name__ == "__main__":
    unittest.main()
