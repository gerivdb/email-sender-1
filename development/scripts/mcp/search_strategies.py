"""
Module pour les stratégies de recherche et de rescoring.
Ce module fournit des classes et fonctions pour améliorer la précision des recherches sémantiques.
"""

import re
import math
from typing import List, Dict, Any, Optional, Union, Tuple, Callable
from enum import Enum, auto


class SearchStrategy(Enum):
    """
    Énumération des stratégies de recherche disponibles.
    """
    SEMANTIC = auto()  # Recherche sémantique pure
    KEYWORD = auto()   # Recherche par mots-clés
    HYBRID = auto()    # Recherche hybride (sémantique + mots-clés)
    BM25 = auto()      # Recherche BM25
    MMR = auto()       # Maximum Marginal Relevance


class RescoringStrategy(Enum):
    """
    Énumération des stratégies de rescoring disponibles.
    """
    NONE = auto()           # Pas de rescoring
    KEYWORD_MATCH = auto()  # Rescoring basé sur la présence de mots-clés
    LENGTH_PENALTY = auto() # Rescoring avec pénalité de longueur
    RECENCY = auto()        # Rescoring basé sur la récence
    CUSTOM = auto()         # Rescoring personnalisé


class SearchResult:
    """
    Classe pour représenter un résultat de recherche.
    """
    
    def __init__(
        self,
        document_id: str,
        text: str,
        metadata: Dict[str, Any],
        score: float,
        vector: Optional[List[float]] = None
    ):
        """
        Initialise un résultat de recherche.
        
        Args:
            document_id: Identifiant du document.
            text: Texte du document.
            metadata: Métadonnées du document.
            score: Score de similarité.
            vector: Vecteur d'embedding du document.
        """
        self.document_id = document_id
        self.text = text
        self.metadata = metadata
        self.score = score
        self.vector = vector
        self.original_score = score
        self.rescoring_details = {}
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Convertit le résultat en dictionnaire.
        
        Returns:
            Dictionnaire représentant le résultat.
        """
        return {
            "id": self.document_id,
            "text": self.text,
            "metadata": self.metadata,
            "score": self.score,
            "original_score": self.original_score,
            "rescoring_details": self.rescoring_details
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'SearchResult':
        """
        Crée un résultat à partir d'un dictionnaire.
        
        Args:
            data: Dictionnaire représentant le résultat.
            
        Returns:
            Résultat de recherche.
        """
        result = cls(
            document_id=data["id"],
            text=data["text"],
            metadata=data["metadata"],
            score=data["score"],
            vector=data.get("vector")
        )
        
        if "original_score" in data:
            result.original_score = data["original_score"]
        
        if "rescoring_details" in data:
            result.rescoring_details = data["rescoring_details"]
        
        return result


class SearchFilter:
    """
    Classe pour représenter un filtre de recherche.
    """
    
    def __init__(
        self,
        field: str,
        operator: str,
        value: Any
    ):
        """
        Initialise un filtre de recherche.
        
        Args:
            field: Champ sur lequel appliquer le filtre.
            operator: Opérateur de comparaison.
            value: Valeur à comparer.
        """
        self.field = field
        self.operator = operator
        self.value = value
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Convertit le filtre en dictionnaire.
        
        Returns:
            Dictionnaire représentant le filtre.
        """
        return {
            "field": self.field,
            "operator": self.operator,
            "value": self.value
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'SearchFilter':
        """
        Crée un filtre à partir d'un dictionnaire.
        
        Args:
            data: Dictionnaire représentant le filtre.
            
        Returns:
            Filtre de recherche.
        """
        return cls(
            field=data["field"],
            operator=data["operator"],
            value=data["value"]
        )


class SearchParams:
    """
    Classe pour représenter les paramètres de recherche.
    """
    
    def __init__(
        self,
        query: str,
        limit: int = 10,
        filters: Optional[List[SearchFilter]] = None,
        strategy: SearchStrategy = SearchStrategy.SEMANTIC,
        rescoring_strategy: RescoringStrategy = RescoringStrategy.NONE,
        rescoring_params: Optional[Dict[str, Any]] = None,
        min_score_threshold: Optional[float] = None
    ):
        """
        Initialise les paramètres de recherche.
        
        Args:
            query: Requête de recherche.
            limit: Nombre maximum de résultats.
            filters: Liste de filtres à appliquer.
            strategy: Stratégie de recherche à utiliser.
            rescoring_strategy: Stratégie de rescoring à utiliser.
            rescoring_params: Paramètres pour la stratégie de rescoring.
            min_score_threshold: Seuil minimum de score pour les résultats.
        """
        self.query = query
        self.limit = limit
        self.filters = filters or []
        self.strategy = strategy
        self.rescoring_strategy = rescoring_strategy
        self.rescoring_params = rescoring_params or {}
        self.min_score_threshold = min_score_threshold
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Convertit les paramètres en dictionnaire.
        
        Returns:
            Dictionnaire représentant les paramètres.
        """
        return {
            "query": self.query,
            "limit": self.limit,
            "filters": [f.to_dict() for f in self.filters],
            "strategy": self.strategy.name,
            "rescoring_strategy": self.rescoring_strategy.name,
            "rescoring_params": self.rescoring_params,
            "min_score_threshold": self.min_score_threshold
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'SearchParams':
        """
        Crée des paramètres à partir d'un dictionnaire.
        
        Args:
            data: Dictionnaire représentant les paramètres.
            
        Returns:
            Paramètres de recherche.
        """
        return cls(
            query=data["query"],
            limit=data["limit"],
            filters=[SearchFilter.from_dict(f) for f in data.get("filters", [])],
            strategy=SearchStrategy[data["strategy"]],
            rescoring_strategy=RescoringStrategy[data["rescoring_strategy"]],
            rescoring_params=data.get("rescoring_params", {}),
            min_score_threshold=data.get("min_score_threshold")
        )


class Rescorer:
    """
    Classe pour le rescoring des résultats de recherche.
    """
    
    @staticmethod
    def keyword_match_rescorer(
        results: List[SearchResult],
        query: str,
        params: Optional[Dict[str, Any]] = None
    ) -> List[SearchResult]:
        """
        Rescoring basé sur la présence de mots-clés.
        
        Args:
            results: Liste de résultats à rescorer.
            query: Requête de recherche.
            params: Paramètres de rescoring.
            
        Returns:
            Liste de résultats rescorés.
        """
        params = params or {}
        
        # Extraire les mots-clés de la requête
        keywords = re.findall(r'\b\w+\b', query.lower())
        
        # Poids du score original vs score de mots-clés
        original_weight = params.get("original_weight", 0.7)
        keyword_weight = params.get("keyword_weight", 0.3)
        
        for result in results:
            # Calculer le score de mots-clés
            text_lower = result.text.lower()
            keyword_matches = sum(1 for keyword in keywords if keyword in text_lower)
            keyword_score = keyword_matches / max(1, len(keywords))
            
            # Calculer le score final
            final_score = (result.original_score * original_weight) + (keyword_score * keyword_weight)
            
            # Mettre à jour le score
            result.rescoring_details["keyword_score"] = keyword_score
            result.rescoring_details["keyword_matches"] = keyword_matches
            result.score = final_score
        
        # Trier les résultats par score décroissant
        return sorted(results, key=lambda x: x.score, reverse=True)
    
    @staticmethod
    def length_penalty_rescorer(
        results: List[SearchResult],
        query: str,
        params: Optional[Dict[str, Any]] = None
    ) -> List[SearchResult]:
        """
        Rescoring avec pénalité de longueur.
        
        Args:
            results: Liste de résultats à rescorer.
            query: Requête de recherche.
            params: Paramètres de rescoring.
            
        Returns:
            Liste de résultats rescorés.
        """
        params = params or {}
        
        # Poids du score original vs pénalité de longueur
        original_weight = params.get("original_weight", 0.8)
        length_weight = params.get("length_weight", 0.2)
        
        # Facteur de pénalité (plus il est élevé, plus les documents courts sont favorisés)
        length_penalty_factor = params.get("length_penalty_factor", 0.001)
        
        for result in results:
            # Calculer la pénalité de longueur
            text_length = len(result.text)
            length_penalty = 1.0 / (1.0 + length_penalty_factor * text_length)
            
            # Calculer le score final
            final_score = (result.original_score * original_weight) + (length_penalty * length_weight)
            
            # Mettre à jour le score
            result.rescoring_details["length_penalty"] = length_penalty
            result.rescoring_details["text_length"] = text_length
            result.score = final_score
        
        # Trier les résultats par score décroissant
        return sorted(results, key=lambda x: x.score, reverse=True)
    
    @staticmethod
    def recency_rescorer(
        results: List[SearchResult],
        query: str,
        params: Optional[Dict[str, Any]] = None
    ) -> List[SearchResult]:
        """
        Rescoring basé sur la récence.
        
        Args:
            results: Liste de résultats à rescorer.
            query: Requête de recherche.
            params: Paramètres de rescoring.
            
        Returns:
            Liste de résultats rescorés.
        """
        params = params or {}
        
        # Poids du score original vs score de récence
        original_weight = params.get("original_weight", 0.7)
        recency_weight = params.get("recency_weight", 0.3)
        
        # Champ de date dans les métadonnées
        date_field = params.get("date_field", "timestamp")
        
        # Filtrer les résultats qui ont le champ de date
        valid_results = [r for r in results if date_field in r.metadata]
        
        if not valid_results:
            return results
        
        # Trouver la date la plus récente
        latest_date = max(r.metadata[date_field] for r in valid_results)
        
        for result in results:
            if date_field in result.metadata:
                # Calculer le score de récence
                date_value = result.metadata[date_field]
                recency_score = date_value / latest_date
                
                # Calculer le score final
                final_score = (result.original_score * original_weight) + (recency_score * recency_weight)
                
                # Mettre à jour le score
                result.rescoring_details["recency_score"] = recency_score
                result.score = final_score
        
        # Trier les résultats par score décroissant
        return sorted(results, key=lambda x: x.score, reverse=True)
    
    @staticmethod
    def custom_rescorer(
        results: List[SearchResult],
        query: str,
        rescoring_function: Callable[[List[SearchResult], str, Dict[str, Any]], List[SearchResult]],
        params: Optional[Dict[str, Any]] = None
    ) -> List[SearchResult]:
        """
        Rescoring personnalisé.
        
        Args:
            results: Liste de résultats à rescorer.
            query: Requête de recherche.
            rescoring_function: Fonction de rescoring personnalisée.
            params: Paramètres de rescoring.
            
        Returns:
            Liste de résultats rescorés.
        """
        return rescoring_function(results, query, params or {})


class SearchStrategies:
    """
    Classe pour les stratégies de recherche.
    """
    
    @staticmethod
    def apply_rescoring(
        results: List[SearchResult],
        query: str,
        strategy: RescoringStrategy,
        params: Optional[Dict[str, Any]] = None,
        custom_rescorer: Optional[Callable[[List[SearchResult], str, Dict[str, Any]], List[SearchResult]]] = None
    ) -> List[SearchResult]:
        """
        Applique une stratégie de rescoring aux résultats.
        
        Args:
            results: Liste de résultats à rescorer.
            query: Requête de recherche.
            strategy: Stratégie de rescoring à utiliser.
            params: Paramètres de rescoring.
            custom_rescorer: Fonction de rescoring personnalisée.
            
        Returns:
            Liste de résultats rescorés.
        """
        # Sauvegarder les scores originaux
        for result in results:
            result.original_score = result.score
        
        # Appliquer la stratégie de rescoring
        if strategy == RescoringStrategy.NONE:
            return results
        elif strategy == RescoringStrategy.KEYWORD_MATCH:
            return Rescorer.keyword_match_rescorer(results, query, params)
        elif strategy == RescoringStrategy.LENGTH_PENALTY:
            return Rescorer.length_penalty_rescorer(results, query, params)
        elif strategy == RescoringStrategy.RECENCY:
            return Rescorer.recency_rescorer(results, query, params)
        elif strategy == RescoringStrategy.CUSTOM:
            if custom_rescorer is None:
                raise ValueError("Custom rescorer function is required for CUSTOM strategy")
            return Rescorer.custom_rescorer(results, query, custom_rescorer, params)
        else:
            raise ValueError(f"Unknown rescoring strategy: {strategy}")
    
    @staticmethod
    def filter_results(
        results: List[SearchResult],
        filters: List[SearchFilter]
    ) -> List[SearchResult]:
        """
        Filtre les résultats selon les critères spécifiés.
        
        Args:
            results: Liste de résultats à filtrer.
            filters: Liste de filtres à appliquer.
            
        Returns:
            Liste de résultats filtrés.
        """
        if not filters:
            return results
        
        filtered_results = []
        
        for result in results:
            # Vérifier si le résultat satisfait tous les filtres
            if all(SearchStrategies._apply_filter(result, f) for f in filters):
                filtered_results.append(result)
        
        return filtered_results
    
    @staticmethod
    def _apply_filter(result: SearchResult, filter: SearchFilter) -> bool:
        """
        Applique un filtre à un résultat.
        
        Args:
            result: Résultat à filtrer.
            filter: Filtre à appliquer.
            
        Returns:
            True si le résultat satisfait le filtre, False sinon.
        """
        # Déterminer si le champ est dans les métadonnées ou dans le résultat lui-même
        if filter.field in result.metadata:
            field_value = result.metadata[filter.field]
        elif hasattr(result, filter.field):
            field_value = getattr(result, filter.field)
        else:
            return False
        
        # Appliquer l'opérateur
        if filter.operator == "eq":
            return field_value == filter.value
        elif filter.operator == "neq":
            return field_value != filter.value
        elif filter.operator == "gt":
            return field_value > filter.value
        elif filter.operator == "gte":
            return field_value >= filter.value
        elif filter.operator == "lt":
            return field_value < filter.value
        elif filter.operator == "lte":
            return field_value <= filter.value
        elif filter.operator == "in":
            return field_value in filter.value
        elif filter.operator == "nin":
            return field_value not in filter.value
        elif filter.operator == "contains":
            return filter.value in field_value
        elif filter.operator == "startswith":
            return field_value.startswith(filter.value)
        elif filter.operator == "endswith":
            return field_value.endswith(filter.value)
        else:
            raise ValueError(f"Unknown operator: {filter.operator}")
