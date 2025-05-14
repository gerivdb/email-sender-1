"""
Script de test pour le module search_strategies.
Ce script teste les différentes stratégies de recherche et de rescoring.
"""

import os
import sys
import unittest
from typing import List, Dict, Any

# Importer les modules nécessaires
from search_strategies import (
    SearchStrategy,
    RescoringStrategy,
    SearchResult,
    SearchFilter,
    SearchParams,
    Rescorer,
    SearchStrategies
)


class TestSearchStrategies(unittest.TestCase):
    """
    Tests pour les stratégies de recherche et de rescoring.
    """

    def setUp(self):
        """
        Initialisation des tests.
        """
        # Créer des résultats de recherche de test
        self.results = [
            SearchResult(
                document_id="1",
                text="Ceci est un document sur l'intelligence artificielle et le machine learning.",
                metadata={"source": "doc1.md", "timestamp": 1620000000},
                score=0.9
            ),
            SearchResult(
                document_id="2",
                text="L'apprentissage automatique est un sous-domaine de l'intelligence artificielle.",
                metadata={"source": "doc2.md", "timestamp": 1630000000},
                score=0.8
            ),
            SearchResult(
                document_id="3",
                text="Les réseaux de neurones sont utilisés en deep learning.",
                metadata={"source": "doc3.md", "timestamp": 1640000000},
                score=0.7
            ),
            SearchResult(
                document_id="4",
                text="Le traitement du langage naturel est une application de l'intelligence artificielle.",
                metadata={"source": "doc4.md", "timestamp": 1650000000},
                score=0.6
            ),
            SearchResult(
                document_id="5",
                text="Ceci est un très long document qui parle de beaucoup de choses différentes, notamment de l'intelligence artificielle, du machine learning, du deep learning, du traitement du langage naturel, et de bien d'autres sujets encore. Ce document est intentionnellement long pour tester la pénalité de longueur.",
                metadata={"source": "doc5.md", "timestamp": 1660000000},
                score=0.5
            )
        ]

    def test_keyword_match_rescorer(self):
        """
        Teste le rescoring basé sur la présence de mots-clés.
        """
        # Appliquer le rescoring
        query = "intelligence artificielle"
        rescored_results = Rescorer.keyword_match_rescorer(
            results=self.results.copy(),
            query=query
        )

        # Vérifier que les résultats ont été rescorés
        self.assertEqual(len(rescored_results), len(self.results))

        # Vérifier que les scores ont été modifiés
        for result in rescored_results:
            self.assertIn("keyword_score", result.rescoring_details)
            self.assertIn("keyword_matches", result.rescoring_details)

        # Vérifier que les résultats sont triés par score décroissant
        for i in range(len(rescored_results) - 1):
            self.assertGreaterEqual(rescored_results[i].score, rescored_results[i + 1].score)

        # Vérifier que les documents contenant les mots-clés ont un meilleur score
        for result in rescored_results:
            if "intelligence artificielle" in result.text.lower():
                self.assertGreater(result.rescoring_details["keyword_score"], 0)

    def test_length_penalty_rescorer(self):
        """
        Teste le rescoring avec pénalité de longueur.
        """
        # Appliquer le rescoring
        query = "intelligence artificielle"
        rescored_results = Rescorer.length_penalty_rescorer(
            results=self.results.copy(),
            query=query
        )

        # Vérifier que les résultats ont été rescorés
        self.assertEqual(len(rescored_results), len(self.results))

        # Vérifier que les scores ont été modifiés
        for result in rescored_results:
            self.assertIn("length_penalty", result.rescoring_details)
            self.assertIn("text_length", result.rescoring_details)

        # Vérifier que les résultats sont triés par score décroissant
        for i in range(len(rescored_results) - 1):
            self.assertGreaterEqual(rescored_results[i].score, rescored_results[i + 1].score)

        # Vérifier que les documents plus courts ont une meilleure pénalité
        for i in range(len(rescored_results)):
            for j in range(i + 1, len(rescored_results)):
                if rescored_results[i].rescoring_details["text_length"] < rescored_results[j].rescoring_details["text_length"]:
                    self.assertGreater(rescored_results[i].rescoring_details["length_penalty"], rescored_results[j].rescoring_details["length_penalty"])

    def test_recency_rescorer(self):
        """
        Teste le rescoring basé sur la récence.
        """
        # Appliquer le rescoring
        query = "intelligence artificielle"
        rescored_results = Rescorer.recency_rescorer(
            results=self.results.copy(),
            query=query
        )

        # Vérifier que les résultats ont été rescorés
        self.assertEqual(len(rescored_results), len(self.results))

        # Vérifier que les scores ont été modifiés
        for result in rescored_results:
            self.assertIn("recency_score", result.rescoring_details)

        # Vérifier que les résultats sont triés par score décroissant
        for i in range(len(rescored_results) - 1):
            self.assertGreaterEqual(rescored_results[i].score, rescored_results[i + 1].score)

        # Vérifier que les documents plus récents ont un meilleur score de récence
        latest_timestamp = max(r.metadata["timestamp"] for r in self.results)
        for result in rescored_results:
            expected_recency_score = result.metadata["timestamp"] / latest_timestamp
            self.assertAlmostEqual(result.rescoring_details["recency_score"], expected_recency_score)

    def test_custom_rescorer(self):
        """
        Teste le rescoring personnalisé.
        """
        # Définir une fonction de rescoring personnalisée
        def custom_rescoring_function(results, query, params):
            for result in results:
                # Calculer un score personnalisé (exemple simple)
                custom_score = result.original_score * 0.5

                # Mettre à jour le score
                result.rescoring_details["custom_score"] = custom_score
                result.score = custom_score

            # Trier les résultats par score décroissant
            return sorted(results, key=lambda x: x.score, reverse=True)

        # Appliquer le rescoring
        query = "intelligence artificielle"
        rescored_results = Rescorer.custom_rescorer(
            results=self.results.copy(),
            query=query,
            rescoring_function=custom_rescoring_function
        )

        # Vérifier que les résultats ont été rescorés
        self.assertEqual(len(rescored_results), len(self.results))

        # Vérifier que les scores ont été modifiés
        for result in rescored_results:
            self.assertIn("custom_score", result.rescoring_details)
            self.assertEqual(result.score, result.original_score * 0.5)

        # Vérifier que les résultats sont triés par score décroissant
        for i in range(len(rescored_results) - 1):
            self.assertGreaterEqual(rescored_results[i].score, rescored_results[i + 1].score)

    def test_apply_rescoring(self):
        """
        Teste l'application des stratégies de rescoring.
        """
        # Tester différentes stratégies
        strategies = [
            RescoringStrategy.NONE,
            RescoringStrategy.KEYWORD_MATCH,
            RescoringStrategy.LENGTH_PENALTY,
            RescoringStrategy.RECENCY
        ]

        query = "intelligence artificielle"

        for strategy in strategies:
            # Appliquer la stratégie
            rescored_results = SearchStrategies.apply_rescoring(
                results=self.results.copy(),
                query=query,
                strategy=strategy
            )

            # Vérifier que les résultats ont été rescorés
            self.assertEqual(len(rescored_results), len(self.results))

            # Vérifier que les résultats sont triés par score décroissant
            for i in range(len(rescored_results) - 1):
                self.assertGreaterEqual(rescored_results[i].score, rescored_results[i + 1].score)

    def test_filter_results(self):
        """
        Teste le filtrage des résultats.
        """
        # Créer des filtres
        filters = [
            SearchFilter(field="score", operator="gte", value=0.7)
        ]

        # Appliquer les filtres
        filtered_results = SearchStrategies.filter_results(
            results=self.results.copy(),
            filters=filters
        )

        # Vérifier que les résultats ont été filtrés
        self.assertEqual(len(filtered_results), 3)

        # Vérifier que tous les résultats satisfont les filtres
        for result in filtered_results:
            self.assertGreaterEqual(result.score, 0.7)

        # Tester d'autres opérateurs
        filters = [
            SearchFilter(field="text", operator="contains", value="deep learning")
        ]

        filtered_results = SearchStrategies.filter_results(
            results=self.results.copy(),
            filters=filters
        )

        self.assertEqual(len(filtered_results), 2)

        # Tester la combinaison de filtres
        filters = [
            SearchFilter(field="score", operator="gte", value=0.7),
            SearchFilter(field="text", operator="contains", value="intelligence artificielle")
        ]

        filtered_results = SearchStrategies.filter_results(
            results=self.results.copy(),
            filters=filters
        )

        # Vérifier que les résultats satisfont tous les filtres
        for result in filtered_results:
            self.assertGreaterEqual(result.score, 0.7)
            self.assertIn("intelligence artificielle", result.text)

    def test_search_params(self):
        """
        Teste la classe SearchParams.
        """
        # Créer des paramètres de recherche
        params = SearchParams(
            query="intelligence artificielle",
            limit=10,
            filters=[
                SearchFilter(field="score", operator="gte", value=0.7)
            ],
            strategy=SearchStrategy.HYBRID,
            rescoring_strategy=RescoringStrategy.KEYWORD_MATCH,
            rescoring_params={"original_weight": 0.6, "keyword_weight": 0.4},
            min_score_threshold=0.5
        )

        # Convertir en dictionnaire
        params_dict = params.to_dict()

        # Vérifier les valeurs
        self.assertEqual(params_dict["query"], "intelligence artificielle")
        self.assertEqual(params_dict["limit"], 10)
        self.assertEqual(len(params_dict["filters"]), 1)
        self.assertEqual(params_dict["strategy"], "HYBRID")
        self.assertEqual(params_dict["rescoring_strategy"], "KEYWORD_MATCH")
        self.assertEqual(params_dict["rescoring_params"]["original_weight"], 0.6)
        self.assertEqual(params_dict["min_score_threshold"], 0.5)

        # Recréer à partir du dictionnaire
        params2 = SearchParams.from_dict(params_dict)

        # Vérifier que les valeurs sont identiques
        self.assertEqual(params2.query, params.query)
        self.assertEqual(params2.limit, params.limit)
        self.assertEqual(len(params2.filters), len(params.filters))
        self.assertEqual(params2.strategy, params.strategy)
        self.assertEqual(params2.rescoring_strategy, params.rescoring_strategy)
        self.assertEqual(params2.rescoring_params, params.rescoring_params)
        self.assertEqual(params2.min_score_threshold, params.min_score_threshold)


if __name__ == "__main__":
    unittest.main()
