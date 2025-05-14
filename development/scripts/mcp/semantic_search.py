"""
Module pour la recherche sémantique avec Qdrant.
Ce module fournit des classes pour effectuer des recherches sémantiques
dans une base de données vectorielle Qdrant.
"""

import os
import json
import time
import re
from typing import List, Dict, Any, Optional, Union, Tuple, Callable

from vector_storage import QdrantConfig, QdrantClient
from vector_crud import VectorCRUD
from embedding_models_factory import EmbeddingModelFactory, EmbeddingModelManager
from embedding_generator import EmbeddingGenerator
from search_strategies import (
    SearchStrategy,
    RescoringStrategy,
    SearchResult,
    SearchFilter,
    SearchParams,
    Rescorer,
    SearchStrategies
)


class SemanticSearch:
    """
    Classe pour effectuer des recherches sémantiques dans Qdrant.
    """

    def __init__(
        self,
        qdrant_config: Optional[QdrantConfig] = None,
        embedding_model_id: str = "text-embedding-3-small",
        model_manager: Optional[EmbeddingModelManager] = None
    ):
        """
        Initialise le système de recherche sémantique.

        Args:
            qdrant_config: Configuration pour la connexion à Qdrant.
            embedding_model_id: Identifiant du modèle d'embeddings à utiliser.
            model_manager: Gestionnaire de modèles d'embeddings.
        """
        # Initialiser la configuration Qdrant
        self.qdrant_config = qdrant_config or QdrantConfig()

        # Initialiser le client Qdrant
        self.qdrant_client = QdrantClient(self.qdrant_config)

        # Initialiser le VectorCRUD
        self.vector_crud = VectorCRUD(self.qdrant_client)

        # Initialiser le gestionnaire de modèles d'embeddings
        self.model_manager = model_manager or EmbeddingModelManager()

        # Initialiser le générateur d'embeddings
        self.embedding_generator = EmbeddingGenerator(
            model_manager=self.model_manager,
            default_model_id=embedding_model_id
        )

        # Modèle d'embeddings par défaut
        self.default_model_id = embedding_model_id

    def search(
        self,
        query: str,
        collection_name: str,
        limit: int = 5,
        filter_params: Optional[Dict[str, Any]] = None,
        model_id: Optional[str] = None,
        score_threshold: Optional[float] = None,
        with_payload: bool = True,
        with_vectors: bool = False,
        search_strategy: SearchStrategy = SearchStrategy.SEMANTIC,
        rescoring_strategy: RescoringStrategy = RescoringStrategy.NONE,
        rescoring_params: Optional[Dict[str, Any]] = None
    ) -> List[SearchResult]:
        """
        Effectue une recherche sémantique.

        Args:
            query: Requête de recherche.
            collection_name: Nom de la collection Qdrant.
            limit: Nombre maximum de résultats à retourner.
            filter_params: Paramètres de filtrage pour la recherche.
            model_id: Identifiant du modèle d'embeddings à utiliser.
            score_threshold: Seuil de score minimum pour les résultats.
            with_payload: Si True, inclut les payloads dans les résultats.
            with_vectors: Si True, inclut les vecteurs dans les résultats.
            search_strategy: Stratégie de recherche à utiliser.
            rescoring_strategy: Stratégie de rescoring à utiliser.
            rescoring_params: Paramètres pour la stratégie de rescoring.

        Returns:
            Liste de résultats de recherche.
        """
        # Utiliser le modèle par défaut si non spécifié
        model_id = model_id or self.default_model_id

        # Générer l'embedding pour la requête
        query_embedding = self.embedding_generator.generate_embedding(
            text=query,
            model_id=model_id
        )

        # Convertir les paramètres de filtrage en filtres SearchFilter
        filters = []
        if filter_params:
            for field, value in filter_params.items():
                if isinstance(value, dict):
                    for operator, op_value in value.items():
                        filters.append(SearchFilter(field=field, operator=operator, value=op_value))
                else:
                    filters.append(SearchFilter(field=field, operator="eq", value=value))

        # Effectuer la recherche selon la stratégie
        if search_strategy == SearchStrategy.SEMANTIC:
            # Recherche sémantique pure
            raw_results = self.vector_crud.search(
                query_vector=query_embedding.vector,
                collection_name=collection_name,
                limit=limit * 2  # Récupérer plus de résultats pour le filtrage et le rescoring
            )

            # Convertir les résultats bruts en SearchResult
            results = []
            for embedding, score in raw_results:
                result = SearchResult(
                    document_id=embedding.id,
                    text=embedding.text,
                    metadata=embedding.metadata,
                    score=score,
                    vector=embedding.vector.to_list() if with_vectors else None
                )
                results.append(result)

        elif search_strategy == SearchStrategy.HYBRID:
            # Recherche hybride (sémantique + mots-clés)
            # Effectuer d'abord la recherche sémantique
            raw_results = self.vector_crud.search(
                query_vector=query_embedding.vector,
                collection_name=collection_name,
                limit=limit * 3  # Récupérer plus de résultats pour le filtrage et le rescoring
            )

            # Convertir les résultats bruts en SearchResult
            results = []
            for embedding, score in raw_results:
                result = SearchResult(
                    document_id=embedding.id,
                    text=embedding.text,
                    metadata=embedding.metadata,
                    score=score,
                    vector=embedding.vector.to_list() if with_vectors else None
                )
                results.append(result)

            # Appliquer le rescoring basé sur les mots-clés
            results = Rescorer.keyword_match_rescorer(
                results=results,
                query=query,
                params=rescoring_params
            )

        else:
            raise ValueError(f"Stratégie de recherche non supportée: {search_strategy}")

        # Appliquer les filtres
        if filters:
            results = SearchStrategies.filter_results(
                results=results,
                filters=filters
            )

        # Appliquer le rescoring si demandé
        if rescoring_strategy != RescoringStrategy.NONE:
            results = SearchStrategies.apply_rescoring(
                results=results,
                query=query,
                strategy=rescoring_strategy,
                params=rescoring_params
            )

        # Appliquer le seuil de score
        if score_threshold is not None:
            results = [r for r in results if r.score >= score_threshold]

        # Limiter le nombre de résultats
        results = results[:limit]

        return results

    def search_with_reranking(
        self,
        query: str,
        collection_name: str,
        limit: int = 5,
        filter_params: Optional[Dict[str, Any]] = None,
        model_id: Optional[str] = None,
        rescoring_strategy: RescoringStrategy = RescoringStrategy.KEYWORD_MATCH,
        rescoring_params: Optional[Dict[str, Any]] = None,
        initial_limit: Optional[int] = None
    ) -> List[SearchResult]:
        """
        Effectue une recherche sémantique avec reranking.

        Args:
            query: Requête de recherche.
            collection_name: Nom de la collection Qdrant.
            limit: Nombre maximum de résultats à retourner après reranking.
            filter_params: Paramètres de filtrage pour la recherche.
            model_id: Identifiant du modèle d'embeddings à utiliser.
            rescoring_strategy: Stratégie de rescoring à utiliser.
            rescoring_params: Paramètres pour la stratégie de rescoring.
            initial_limit: Nombre de résultats à récupérer avant reranking.

        Returns:
            Liste de résultats de recherche reranked.
        """
        # Définir la limite initiale (2x la limite finale par défaut)
        if initial_limit is None:
            initial_limit = limit * 2

        # Effectuer la recherche initiale
        initial_results = self.search(
            query=query,
            collection_name=collection_name,
            limit=initial_limit,
            filter_params=filter_params,
            model_id=model_id,
            with_vectors=False,
            search_strategy=SearchStrategy.SEMANTIC,
            rescoring_strategy=RescoringStrategy.NONE
        )

        # Appliquer le rescoring
        reranked_results = SearchStrategies.apply_rescoring(
            results=initial_results,
            query=query,
            strategy=rescoring_strategy,
            params=rescoring_params
        )

        # Limiter les résultats
        return reranked_results[:limit]

    def hybrid_search(
        self,
        query: str,
        collection_name: str,
        limit: int = 5,
        filter_params: Optional[Dict[str, Any]] = None,
        model_id: Optional[str] = None,
        keyword_weight: float = 0.3,
        semantic_weight: float = 0.7
    ) -> List[SearchResult]:
        """
        Effectue une recherche hybride (sémantique + mots-clés).

        Args:
            query: Requête de recherche.
            collection_name: Nom de la collection Qdrant.
            limit: Nombre maximum de résultats à retourner.
            filter_params: Paramètres de filtrage pour la recherche.
            model_id: Identifiant du modèle d'embeddings à utiliser.
            keyword_weight: Poids de la recherche par mots-clés.
            semantic_weight: Poids de la recherche sémantique.

        Returns:
            Liste de résultats de recherche hybride.
        """
        # Configurer les paramètres de rescoring
        rescoring_params = {
            "original_weight": semantic_weight,
            "keyword_weight": keyword_weight
        }

        # Utiliser la recherche avec stratégie hybride
        return self.search(
            query=query,
            collection_name=collection_name,
            limit=limit,
            filter_params=filter_params,
            model_id=model_id,
            search_strategy=SearchStrategy.HYBRID,
            rescoring_params=rescoring_params
        )


if __name__ == "__main__":
    # Exemple d'utilisation
    import argparse

    parser = argparse.ArgumentParser(description="Effectuer une recherche sémantique")
    parser.add_argument("--query", required=True, help="Requête de recherche")
    parser.add_argument("--collection", required=True, help="Nom de la collection Qdrant")
    parser.add_argument("--limit", type=int, default=5, help="Nombre maximum de résultats")
    parser.add_argument("--model", default="text-embedding-3-small", help="Modèle d'embeddings")
    parser.add_argument("--rerank", action="store_true", help="Utiliser le reranking")
    parser.add_argument("--hybrid", action="store_true", help="Utiliser la recherche hybride")
    parser.add_argument("--strategy", choices=["semantic", "hybrid", "keyword"], default="semantic", help="Stratégie de recherche")
    parser.add_argument("--rescoring", choices=["none", "keyword", "length", "recency"], default="none", help="Stratégie de rescoring")

    args = parser.parse_args()

    # Initialiser le système de recherche sémantique
    search = SemanticSearch(
        embedding_model_id=args.model
    )

    # Déterminer la stratégie de recherche
    search_strategy = SearchStrategy.SEMANTIC
    if args.strategy == "hybrid":
        search_strategy = SearchStrategy.HYBRID
    elif args.strategy == "keyword":
        search_strategy = SearchStrategy.KEYWORD

    # Déterminer la stratégie de rescoring
    rescoring_strategy = RescoringStrategy.NONE
    if args.rescoring == "keyword":
        rescoring_strategy = RescoringStrategy.KEYWORD_MATCH
    elif args.rescoring == "length":
        rescoring_strategy = RescoringStrategy.LENGTH_PENALTY
    elif args.rescoring == "recency":
        rescoring_strategy = RescoringStrategy.RECENCY

    # Effectuer la recherche
    if args.rerank:
        results = search.search_with_reranking(
            query=args.query,
            collection_name=args.collection,
            limit=args.limit,
            rescoring_strategy=rescoring_strategy
        )
    elif args.hybrid:
        results = search.hybrid_search(
            query=args.query,
            collection_name=args.collection,
            limit=args.limit
        )
    else:
        results = search.search(
            query=args.query,
            collection_name=args.collection,
            limit=args.limit,
            search_strategy=search_strategy,
            rescoring_strategy=rescoring_strategy
        )

    # Afficher les résultats
    print(f"Résultats pour la requête: {args.query}")
    print("-----------------------------------")

    for i, result in enumerate(results):
        print(f"Résultat {i+1} (score: {result.score:.4f}):")
        print(f"  Texte: {result.text[:100]}...")

        # Afficher les détails de rescoring
        for key, value in result.rescoring_details.items():
            if isinstance(value, float):
                print(f"  {key}: {value:.4f}")
            else:
                print(f"  {key}: {value}")

        print()
