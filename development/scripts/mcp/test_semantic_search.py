"""
Script de test pour le module semantic_search.
Ce script teste la classe SemanticSearch avec les stratégies de recherche et de rescoring.
"""

import os
import sys
import unittest
from unittest.mock import patch, MagicMock
from typing import List, Dict, Any

# Ajouter le répertoire courant au chemin de recherche
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Importer les modules nécessaires
try:
    from semantic_search import SemanticSearch
    from search_strategies import (
        SearchStrategy,
        RescoringStrategy,
        SearchResult,
        SearchFilter,
        SearchParams
    )
    from embedding_manager import Vector, Embedding
except ImportError as e:
    print(f"Erreur d'importation: {e}")
    print(f"Répertoire courant: {os.path.dirname(os.path.abspath(__file__))}")
    print(f"Fichiers disponibles: {os.listdir(os.path.dirname(os.path.abspath(__file__)))}")
    raise


class TestSemanticSearch(unittest.TestCase):
    """
    Tests pour la classe SemanticSearch.
    """

    def setUp(self):
        """
        Initialisation des tests.
        """
        # Créer un vecteur de test
        self.test_vector = Vector([0.1] * 16, model_name="test-model")

        # Créer des embeddings de test
        self.test_embeddings = [
            Embedding(
                vector=self.test_vector,
                text="Ceci est un document sur l'intelligence artificielle et le machine learning.",
                metadata={"source": "doc1.md", "timestamp": 1620000000}
            ),
            Embedding(
                vector=self.test_vector,
                text="L'apprentissage automatique est un sous-domaine de l'intelligence artificielle.",
                metadata={"source": "doc2.md", "timestamp": 1630000000}
            ),
            Embedding(
                vector=self.test_vector,
                text="Les réseaux de neurones sont utilisés en deep learning.",
                metadata={"source": "doc3.md", "timestamp": 1640000000}
            )
        ]

        # Créer des patchs pour les dépendances
        self.qdrant_client_patch = patch('semantic_search.QdrantClient')
        self.vector_crud_patch = patch('semantic_search.VectorCRUD')
        self.model_manager_patch = patch('semantic_search.EmbeddingModelManager')
        self.embedding_generator_patch = patch('semantic_search.EmbeddingGenerator')

        # Démarrer les patchs
        self.mock_qdrant_client = self.qdrant_client_patch.start()
        self.mock_vector_crud = self.vector_crud_patch.start()
        self.mock_model_manager = self.model_manager_patch.start()
        self.mock_embedding_generator = self.embedding_generator_patch.start()

        # Configurer les mocks
        self.mock_embedding_generator.return_value.generate_embedding.return_value = self.test_embeddings[0]
        self.mock_vector_crud.return_value.search.return_value = [
            (self.test_embeddings[0], 0.9),
            (self.test_embeddings[1], 0.8),
            (self.test_embeddings[2], 0.7)
        ]

        # Initialiser le système de recherche sémantique
        self.search = SemanticSearch(embedding_model_id="test-model")

    def tearDown(self):
        """
        Nettoyage après les tests.
        """
        # Arrêter les patchs
        self.qdrant_client_patch.stop()
        self.vector_crud_patch.stop()
        self.model_manager_patch.stop()
        self.embedding_generator_patch.stop()

    def test_search_semantic(self):
        """
        Teste la recherche sémantique.
        """
        # Configurer les mocks
        self.mock_embedding_generator.return_value.generate_embedding.return_value = self.test_embeddings[0]
        self.mock_vector_crud.return_value.search.return_value = [
            (self.test_embeddings[0], 0.9),
            (self.test_embeddings[1], 0.8)
        ]

        # Effectuer la recherche
        results = self.search.search(
            query="intelligence artificielle",
            collection_name="test_collection",
            limit=2,
            search_strategy=SearchStrategy.SEMANTIC
        )

        # Vérifier que la méthode generate_embedding a été appelée
        self.mock_embedding_generator.return_value.generate_embedding.assert_called_once()

        # Vérifier que la méthode search a été appelée
        self.mock_vector_crud.return_value.search.assert_called_once()

        # Vérifier les résultats
        self.assertEqual(len(results), 2)
        self.assertIsInstance(results[0], SearchResult)
        self.assertEqual(results[0].score, 0.9)
        self.assertEqual(results[1].score, 0.8)

    def test_search_with_reranking(self):
        """
        Teste la recherche avec reranking.
        """
        # Configurer les mocks
        self.mock_embedding_generator.return_value.generate_embedding.return_value = self.test_embeddings[0]
        self.mock_vector_crud.return_value.search.return_value = [
            (self.test_embeddings[0], 0.9),
            (self.test_embeddings[1], 0.8)
        ]

        # Effectuer la recherche avec reranking
        with patch('semantic_search.SearchStrategies.apply_rescoring') as mock_apply_rescoring:
            # Configurer le mock pour apply_rescoring
            mock_apply_rescoring.return_value = [
                SearchResult(
                    document_id="1",
                    text=self.test_embeddings[0].text,
                    metadata=self.test_embeddings[0].metadata,
                    score=0.95
                ),
                SearchResult(
                    document_id="2",
                    text=self.test_embeddings[1].text,
                    metadata=self.test_embeddings[1].metadata,
                    score=0.85
                )
            ]

            # Ajouter des détails de rescoring
            mock_apply_rescoring.return_value[0].rescoring_details = {"keyword_score": 0.8}
            mock_apply_rescoring.return_value[1].rescoring_details = {"keyword_score": 0.7}

            results = self.search.search_with_reranking(
                query="intelligence artificielle",
                collection_name="test_collection",
                limit=2,
                rescoring_strategy=RescoringStrategy.KEYWORD_MATCH
            )

            # Vérifier que la méthode apply_rescoring a été appelée
            mock_apply_rescoring.assert_called_once()

            # Vérifier les résultats
            self.assertEqual(len(results), 2)
            self.assertIsInstance(results[0], SearchResult)
            self.assertEqual(results[0].score, 0.95)
            self.assertEqual(results[1].score, 0.85)
            self.assertIn("keyword_score", results[0].rescoring_details)

    def test_hybrid_search(self):
        """
        Teste la recherche hybride.
        """
        # Configurer les mocks
        self.mock_embedding_generator.return_value.generate_embedding.return_value = self.test_embeddings[0]
        self.mock_vector_crud.return_value.search.return_value = [
            (self.test_embeddings[0], 0.9),
            (self.test_embeddings[1], 0.8)
        ]

        # Effectuer la recherche hybride
        with patch('semantic_search.Rescorer.keyword_match_rescorer') as mock_keyword_match_rescorer:
            # Configurer le mock pour keyword_match_rescorer
            mock_keyword_match_rescorer.return_value = [
                SearchResult(
                    document_id="1",
                    text=self.test_embeddings[0].text,
                    metadata=self.test_embeddings[0].metadata,
                    score=0.95
                ),
                SearchResult(
                    document_id="2",
                    text=self.test_embeddings[1].text,
                    metadata=self.test_embeddings[1].metadata,
                    score=0.85
                )
            ]

            results = self.search.search(
                query="intelligence artificielle",
                collection_name="test_collection",
                limit=2,
                search_strategy=SearchStrategy.HYBRID
            )

            # Vérifier les résultats
            self.assertEqual(len(results), 2)
            self.assertIsInstance(results[0], SearchResult)
            self.assertEqual(results[0].score, 0.95)
            self.assertEqual(results[1].score, 0.85)


if __name__ == "__main__":
    unittest.main()
