#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module d'attribution thématique automatique.

Ce module fournit des fonctionnalités pour attribuer automatiquement des thèmes
à des éléments de roadmap en fonction de leur contenu et de leurs métadonnées.
"""

import os
import sys
import re
import json
from typing import Dict, List, Any, Optional, Union, Set
from pathlib import Path

# Essayer d'importer sklearn, mais continuer même si l'importation échoue
try:
    import numpy as np
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.metrics.pairwise import cosine_similarity
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False
    print("Warning: sklearn not available. Vector similarity will be disabled.")

# Importer le gestionnaire de thèmes hiérarchiques
from src.orchestrator.thematic_crud.hierarchical_themes import HierarchicalThemeManager

# Importer le gestionnaire de cache
from src.orchestrator.utils.cache_manager import cached

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

class ThemeAttributor:
    """Classe pour l'attribution automatique de thèmes."""

    def __init__(self, themes_config_path: Optional[str] = None):
        """
        Initialise l'attributeur de thèmes.

        Args:
            themes_config_path: Chemin vers le fichier de configuration des thèmes (optionnel)
        """
        # Initialiser le gestionnaire de thèmes hiérarchiques
        self.theme_manager = HierarchicalThemeManager(themes_config_path)

        # Récupérer les thèmes et les mots-clés du gestionnaire
        self.themes = self.theme_manager.themes
        self.theme_keywords = self.theme_manager.theme_keywords

        # Initialiser le vectoriseur si sklearn est disponible
        if SKLEARN_AVAILABLE:
            self.vectorizer = TfidfVectorizer(stop_words='english')
        else:
            self.vectorizer = None

    # Les méthodes _load_themes_config et _load_default_themes ne sont plus nécessaires
    # car elles sont gérées par le gestionnaire de thèmes hiérarchiques

    @cached(ttl_memory=1800, ttl_disk=43200)  # 30 minutes en mémoire, 12 heures sur disque
    def attribute_theme(self, content: str, metadata: Optional[Dict[str, Any]] = None) -> Dict[str, float]:
        """
        Attribue des thèmes à un contenu en fonction de sa similarité avec les thèmes connus.

        Args:
            content: Contenu textuel à analyser
            metadata: Métadonnées associées au contenu (optionnel)

        Returns:
            Dictionnaire des thèmes attribués avec leur score de confiance
        """
        # Préparer le contenu
        processed_content = self._preprocess_content(content)

        # Calculer les scores basés sur les mots-clés
        keyword_scores = self._calculate_keyword_scores(processed_content)

        # Calculer les scores basés sur la similarité vectorielle
        vector_scores = self._calculate_vector_similarity(processed_content)

        # Ajuster les poids en fonction de la disponibilité de sklearn
        if SKLEARN_AVAILABLE and self.vectorizer is not None:
            # Si sklearn est disponible, donner un poids égal aux deux méthodes
            combined_scores = self._combine_scores(keyword_scores, vector_scores, weight_a=0.5, weight_b=0.5)
        else:
            # Si sklearn n'est pas disponible, utiliser uniquement les scores basés sur les mots-clés
            combined_scores = keyword_scores

        # Intégrer les métadonnées si disponibles
        if metadata:
            metadata_scores = self._extract_themes_from_metadata(metadata)
            combined_scores = self._combine_scores(combined_scores, metadata_scores, weight_a=0.7, weight_b=0.3)

        # Propager les scores à travers la hiérarchie des thèmes
        propagated_scores = self.theme_manager.propagate_theme_scores(combined_scores)

        # Normaliser et filtrer les scores
        return self._normalize_and_filter_scores(propagated_scores)

    def _preprocess_content(self, content: str) -> str:
        """
        Prétraite le contenu pour l'analyse.

        Args:
            content: Contenu à prétraiter

        Returns:
            Contenu prétraité
        """
        # Convertir en minuscules
        content = content.lower()

        # Supprimer les caractères spéciaux
        content = re.sub(r'[^\w\s]', ' ', content)

        # Supprimer les espaces multiples
        content = re.sub(r'\s+', ' ', content).strip()

        return content

    @cached(ttl_memory=1800, ttl_disk=43200)  # 30 minutes en mémoire, 12 heures sur disque
    def _calculate_keyword_scores(self, content: str) -> Dict[str, float]:
        """
        Calcule les scores basés sur la présence de mots-clés.

        Args:
            content: Contenu prétraité

        Returns:
            Dictionnaire des scores par thème
        """
        scores = {}

        for theme in self.themes.keys():
            # Utiliser les mots-clés enrichis par la hiérarchie
            enriched_keywords = self.theme_manager.get_theme_keywords(theme)

            score = 0
            for keyword in enriched_keywords:
                # Compter les occurrences du mot-clé
                occurrences = len(re.findall(r'\b' + re.escape(keyword.lower()) + r'\b', content))
                score += occurrences

            # Normaliser le score par le nombre de mots-clés
            if enriched_keywords:
                scores[theme] = score / len(enriched_keywords)
            else:
                scores[theme] = 0

        return scores

    @cached(ttl_memory=1800, ttl_disk=43200)  # 30 minutes en mémoire, 12 heures sur disque
    def _calculate_vector_similarity(self, content: str) -> Dict[str, float]:
        """
        Calcule les scores basés sur la similarité vectorielle.

        Args:
            content: Contenu prétraité

        Returns:
            Dictionnaire des scores par thème
        """
        scores = {}

        # Initialiser les scores à zéro
        for theme_key in self.themes.keys():
            scores[theme_key] = 0.0

        # Si sklearn n'est pas disponible, retourner des scores nuls
        if not SKLEARN_AVAILABLE or self.vectorizer is None:
            return scores

        # Préparer les données pour la vectorisation

        try:
            # Vectoriser séparément le contenu et les thèmes
            content_vector = self.vectorizer.fit_transform([content])
            theme_vectors = self.vectorizer.transform(list(self.themes.values()))

            # Calculer la similarité cosinus entre le contenu et chaque thème
            cosine_similarities = cosine_similarity(content_vector, theme_vectors).flatten()

            # Attribuer les scores
            for i, theme_key in enumerate(self.themes.keys()):
                scores[theme_key] = float(cosine_similarities[i])
        except Exception as e:
            print(f"Erreur lors du calcul de la similarité vectorielle: {str(e)}")

        return scores

    def _extract_themes_from_metadata(self, metadata: Dict[str, Any]) -> Dict[str, float]:
        """
        Extrait des thèmes à partir des métadonnées.

        Args:
            metadata: Métadonnées associées au contenu

        Returns:
            Dictionnaire des scores par thème
        """
        scores = {theme: 0.0 for theme in self.themes.keys()}

        # Extraire les thèmes explicites
        if 'themes' in metadata and isinstance(metadata['themes'], list):
            for theme in metadata['themes']:
                if theme in scores:
                    scores[theme] = 1.0

        # Extraire les thèmes à partir des tags
        if 'tags' in metadata and isinstance(metadata['tags'], list):
            for tag in metadata['tags']:
                tag_lower = tag.lower()
                for theme, keywords in self.theme_keywords.items():
                    if any(keyword.lower() in tag_lower for keyword in keywords):
                        scores[theme] = max(scores[theme], 0.8)

        # Extraire les thèmes à partir du titre
        if 'title' in metadata and isinstance(metadata['title'], str):
            title_scores = self._calculate_keyword_scores(metadata['title'])
            for theme, score in title_scores.items():
                if score > 0:
                    scores[theme] = max(scores[theme], score * 0.9)

        return scores

    def _combine_scores(self, scores_a: Dict[str, float], scores_b: Dict[str, float],
                        weight_a: float = 0.5, weight_b: float = 0.5) -> Dict[str, float]:
        """
        Combine deux ensembles de scores.

        Args:
            scores_a: Premier ensemble de scores
            scores_b: Deuxième ensemble de scores
            weight_a: Poids du premier ensemble (défaut: 0.5)
            weight_b: Poids du deuxième ensemble (défaut: 0.5)

        Returns:
            Dictionnaire des scores combinés
        """
        combined = {}

        # Combiner les scores avec pondération
        for theme in set(scores_a.keys()) | set(scores_b.keys()):
            score_a = scores_a.get(theme, 0.0)
            score_b = scores_b.get(theme, 0.0)
            combined[theme] = (score_a * weight_a) + (score_b * weight_b)

        return combined

    def _normalize_and_filter_scores(self, scores: Dict[str, float],
                                    threshold: float = 0.1) -> Dict[str, float]:
        """
        Normalise et filtre les scores.

        Args:
            scores: Scores à normaliser et filtrer
            threshold: Seuil minimal pour conserver un score (défaut: 0.1)

        Returns:
            Dictionnaire des scores normalisés et filtrés
        """
        # Trouver le score maximum
        max_score = max(scores.values()) if scores else 0

        # Normaliser les scores
        normalized = {}
        if max_score > 0:
            for theme, score in scores.items():
                normalized[theme] = score / max_score
        else:
            normalized = scores.copy()

        # Filtrer les scores inférieurs au seuil
        filtered = {theme: score for theme, score in normalized.items() if score >= threshold}

        # Trier par score décroissant
        return dict(sorted(filtered.items(), key=lambda x: x[1], reverse=True))
