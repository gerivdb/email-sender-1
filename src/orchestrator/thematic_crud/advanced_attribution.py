#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module d'attribution thématique avancée.

Ce module fournit des fonctionnalités avancées pour l'attribution automatique
de thèmes, incluant l'apprentissage continu, l'analyse contextuelle et
l'adaptation aux préférences utilisateur.
"""

import os
import sys
import json
import re
import time
import math
from datetime import datetime
from typing import Dict, List, Any, Optional, Union, Set, Tuple
from pathlib import Path
from collections import defaultdict, Counter

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

# Importer le gestionnaire de thèmes hiérarchiques
from src.orchestrator.thematic_crud.hierarchical_themes import HierarchicalThemeManager

# Importer le gestionnaire de cache
from src.orchestrator.utils.cache_manager import cached

# Essayer d'importer sklearn, mais continuer même si l'importation échoue
try:
    import numpy as np
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.metrics.pairwise import cosine_similarity
    from sklearn.cluster import DBSCAN
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False
    print("Warning: sklearn not available. Advanced attribution features will be limited.")

class ThematicAttributionHistory:
    """Classe pour gérer l'historique des attributions thématiques."""

    def __init__(self, history_path: Optional[str] = None):
        """
        Initialise le gestionnaire d'historique d'attributions.

        Args:
            history_path: Chemin vers le fichier d'historique (optionnel)
        """
        self.history_path = history_path or os.path.join(
            os.path.dirname(os.path.abspath(__file__)),
            "data",
            "attribution_history.json"
        )

        # Créer le répertoire parent s'il n'existe pas
        os.makedirs(os.path.dirname(self.history_path), exist_ok=True)

        # Charger l'historique existant ou créer un nouveau
        self.history = self._load_history()

    def _load_history(self) -> Dict[str, Any]:
        """
        Charge l'historique des attributions.

        Returns:
            Historique des attributions
        """
        if os.path.exists(self.history_path):
            try:
                with open(self.history_path, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception as e:
                print(f"Erreur lors du chargement de l'historique: {str(e)}")

        # Créer un nouvel historique
        return {
            "items": {},
            "themes": {},
            "keywords": {},
            "user_feedback": {},
            "last_updated": datetime.now().isoformat()
        }

    def _save_history(self) -> None:
        """Sauvegarde l'historique des attributions."""
        try:
            with open(self.history_path, 'w', encoding='utf-8') as f:
                json.dump(self.history, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"Erreur lors de la sauvegarde de l'historique: {str(e)}")

    def add_attribution(self, item_id: str, content: str, themes: Dict[str, float],
                       metadata: Optional[Dict[str, Any]] = None) -> None:
        """
        Ajoute une attribution à l'historique.

        Args:
            item_id: Identifiant de l'élément
            content: Contenu de l'élément
            themes: Thèmes attribués avec leurs scores
            metadata: Métadonnées de l'élément (optionnel)
        """
        # Ajouter l'élément à l'historique
        self.history["items"][item_id] = {
            "themes": themes,
            "timestamp": datetime.now().isoformat(),
            "content_length": len(content),
            "metadata": metadata or {}
        }

        # Mettre à jour les statistiques des thèmes
        for theme, score in themes.items():
            if theme not in self.history["themes"]:
                self.history["themes"][theme] = {
                    "count": 0,
                    "total_score": 0.0,
                    "items": []
                }

            self.history["themes"][theme]["count"] += 1
            self.history["themes"][theme]["total_score"] += score
            self.history["themes"][theme]["items"].append(item_id)

        # Extraire et mettre à jour les mots-clés
        words = re.findall(r'\b\w+\b', content.lower())
        for word in words:
            if len(word) > 3:  # Ignorer les mots trop courts
                if word not in self.history["keywords"]:
                    self.history["keywords"][word] = {
                        "count": 0,
                        "themes": {}
                    }

                self.history["keywords"][word]["count"] += 1

                for theme, score in themes.items():
                    if theme not in self.history["keywords"][word]["themes"]:
                        self.history["keywords"][word]["themes"][theme] = 0.0

                    self.history["keywords"][word]["themes"][theme] += score

        # Mettre à jour la date de dernière mise à jour
        self.history["last_updated"] = datetime.now().isoformat()

        # Sauvegarder l'historique
        self._save_history()

    def add_user_feedback(self, item_id: str, user_themes: Dict[str, float]) -> None:
        """
        Ajoute un retour utilisateur sur l'attribution thématique.

        Args:
            item_id: Identifiant de l'élément
            user_themes: Thèmes attribués par l'utilisateur avec leurs scores
        """
        # Ajouter le retour utilisateur
        self.history["user_feedback"][item_id] = {
            "themes": user_themes,
            "timestamp": datetime.now().isoformat()
        }

        # Mettre à jour la date de dernière mise à jour
        self.history["last_updated"] = datetime.now().isoformat()

        # Sauvegarder l'historique
        self._save_history()

    def get_theme_statistics(self) -> Dict[str, Any]:
        """
        Récupère des statistiques sur les thèmes.

        Returns:
            Statistiques sur les thèmes
        """
        stats = {}

        for theme, data in self.history["themes"].items():
            stats[theme] = {
                "count": data["count"],
                "average_score": data["total_score"] / data["count"] if data["count"] > 0 else 0.0,
                "item_count": len(data["items"])
            }

        return stats

    def get_keyword_statistics(self) -> Dict[str, Any]:
        """
        Récupère des statistiques sur les mots-clés.

        Returns:
            Statistiques sur les mots-clés
        """
        stats = {}

        for word, data in self.history["keywords"].items():
            # Calculer le thème principal pour ce mot-clé
            main_theme = None
            max_score = 0.0

            for theme, score in data["themes"].items():
                if score > max_score:
                    max_score = score
                    main_theme = theme

            stats[word] = {
                "count": data["count"],
                "main_theme": main_theme,
                "main_theme_score": max_score
            }

        return stats

    def get_user_feedback_statistics(self) -> Dict[str, Any]:
        """
        Récupère des statistiques sur les retours utilisateur.

        Returns:
            Statistiques sur les retours utilisateur
        """
        stats = {
            "total_feedback_count": len(self.history["user_feedback"]),
            "theme_adjustments": {}
        }

        # Analyser les ajustements de thèmes
        for item_id, feedback in self.history["user_feedback"].items():
            if item_id in self.history["items"]:
                original_themes = self.history["items"][item_id]["themes"]
                user_themes = feedback["themes"]

                # Comparer les thèmes originaux et les thèmes utilisateur
                all_themes = set(original_themes.keys()) | set(user_themes.keys())

                for theme in all_themes:
                    original_score = original_themes.get(theme, 0.0)
                    user_score = user_themes.get(theme, 0.0)

                    if theme not in stats["theme_adjustments"]:
                        stats["theme_adjustments"][theme] = {
                            "added": 0,
                            "removed": 0,
                            "increased": 0,
                            "decreased": 0,
                            "total_adjustment": 0.0
                        }

                    if original_score == 0.0 and user_score > 0.0:
                        stats["theme_adjustments"][theme]["added"] += 1
                    elif original_score > 0.0 and user_score == 0.0:
                        stats["theme_adjustments"][theme]["removed"] += 1
                    elif user_score > original_score:
                        stats["theme_adjustments"][theme]["increased"] += 1
                    elif user_score < original_score:
                        stats["theme_adjustments"][theme]["decreased"] += 1

                    stats["theme_adjustments"][theme]["total_adjustment"] += user_score - original_score

        return stats

class AdvancedThemeAttributor:
    """Classe pour l'attribution thématique avancée."""

    def __init__(self, themes_config_path: Optional[str] = None,
                history_path: Optional[str] = None,
                learning_rate: float = 0.1,
                context_weight: float = 0.3,
                user_feedback_weight: float = 0.5):
        """
        Initialise l'attributeur de thèmes avancé.

        Args:
            themes_config_path: Chemin vers le fichier de configuration des thèmes (optionnel)
            history_path: Chemin vers le fichier d'historique (optionnel)
            learning_rate: Taux d'apprentissage pour l'adaptation (défaut: 0.1)
            context_weight: Poids du contexte dans l'attribution (défaut: 0.3)
            user_feedback_weight: Poids du retour utilisateur (défaut: 0.5)
        """
        # Initialiser le gestionnaire de thèmes hiérarchiques
        self.theme_manager = HierarchicalThemeManager(themes_config_path)

        # Récupérer les thèmes et les mots-clés du gestionnaire
        self.themes = self.theme_manager.themes
        self.theme_keywords = self.theme_manager.theme_keywords

        # Initialiser le gestionnaire d'historique
        self.history = ThematicAttributionHistory(history_path)

        # Paramètres d'apprentissage
        self.learning_rate = learning_rate
        self.context_weight = context_weight
        self.user_feedback_weight = user_feedback_weight

        # Initialiser le vectoriseur si sklearn est disponible
        if SKLEARN_AVAILABLE:
            self.vectorizer = TfidfVectorizer(stop_words='english')
        else:
            self.vectorizer = None

    @cached(ttl_memory=1800, ttl_disk=43200)  # 30 minutes en mémoire, 12 heures sur disque
    def attribute_theme(self, content: str, metadata: Optional[Dict[str, Any]] = None,
                       context: Optional[Dict[str, Any]] = None) -> Dict[str, float]:
        """
        Attribue des thèmes à un contenu avec analyse contextuelle et apprentissage.

        Args:
            content: Contenu textuel à analyser
            metadata: Métadonnées associées au contenu (optionnel)
            context: Contexte d'attribution (optionnel)

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

        # Intégrer le contexte si disponible
        if context:
            context_scores = self._extract_themes_from_context(context)
            combined_scores = self._combine_scores(combined_scores, context_scores,
                                                 weight_a=1.0 - self.context_weight,
                                                 weight_b=self.context_weight)

        # Appliquer l'apprentissage basé sur l'historique
        final_scores = self._apply_learning(combined_scores, processed_content)

        # Normaliser les scores
        normalized_scores = self._normalize_scores(final_scores)

        # Ajouter à l'historique si un ID est fourni dans les métadonnées
        if metadata and "id" in metadata:
            self.history.add_attribution(metadata["id"], content, normalized_scores, metadata)

        return normalized_scores

    def add_user_feedback(self, item_id: str, user_themes: Dict[str, float]) -> None:
        """
        Ajoute un retour utilisateur sur l'attribution thématique.

        Args:
            item_id: Identifiant de l'élément
            user_themes: Thèmes attribués par l'utilisateur avec leurs scores
        """
        self.history.add_user_feedback(item_id, user_themes)

    def get_theme_statistics(self) -> Dict[str, Any]:
        """
        Récupère des statistiques sur les thèmes.

        Returns:
            Statistiques sur les thèmes
        """
        return self.history.get_theme_statistics()

    def get_keyword_statistics(self) -> Dict[str, Any]:
        """
        Récupère des statistiques sur les mots-clés.

        Returns:
            Statistiques sur les mots-clés
        """
        return self.history.get_keyword_statistics()

    def get_user_feedback_statistics(self) -> Dict[str, Any]:
        """
        Récupère des statistiques sur les retours utilisateur.

        Returns:
            Statistiques sur les retours utilisateur
        """
        return self.history.get_user_feedback_statistics()

    def _preprocess_content(self, content: str) -> str:
        """
        Prétraite le contenu pour l'analyse.

        Args:
            content: Contenu à prétraiter

        Returns:
            Contenu prétraité
        """
        # Convertir en minuscules
        processed = content.lower()

        # Supprimer les caractères spéciaux
        processed = re.sub(r'[^\w\s]', ' ', processed)

        # Supprimer les espaces multiples
        processed = re.sub(r'\s+', ' ', processed)

        return processed.strip()

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
            keyword_matches = {}

            for keyword in enriched_keywords:
                # Compter les occurrences du mot-clé
                occurrences = len(re.findall(r'\b' + re.escape(keyword.lower()) + r'\b', content))

                if occurrences > 0:
                    keyword_matches[keyword] = occurrences

                    # Donner plus de poids aux mots-clés plus longs
                    length_factor = min(1.0, len(keyword) / 10.0)
                    weighted_occurrences = occurrences * (1.0 + length_factor)

                    score += weighted_occurrences

            # Normaliser le score par le nombre de mots-clés
            if enriched_keywords:
                base_score = score / len(enriched_keywords)

                # Bonus pour la diversité des mots-clés trouvés
                diversity_factor = len(keyword_matches) / len(enriched_keywords)
                diversity_bonus = diversity_factor * 0.5  # Jusqu'à 50% de bonus

                scores[theme] = base_score * (1.0 + diversity_bonus)
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
        if 'themes' in metadata and isinstance(metadata['themes'], dict):
            for theme, score in metadata['themes'].items():
                if theme in scores:
                    scores[theme] = score
        elif 'themes' in metadata and isinstance(metadata['themes'], list):
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

    def _extract_themes_from_context(self, context: Dict[str, Any]) -> Dict[str, float]:
        """
        Extrait des thèmes à partir du contexte.

        Args:
            context: Contexte d'attribution

        Returns:
            Dictionnaire des scores par thème
        """
        scores = {theme: 0.0 for theme in self.themes.keys()}

        # Extraire les thèmes à partir des éléments liés
        if 'related_items' in context and isinstance(context['related_items'], list):
            for item in context['related_items']:
                if 'themes' in item and isinstance(item['themes'], dict):
                    for theme, score in item['themes'].items():
                        if theme in scores:
                            # Pondérer par la proximité de l'élément
                            proximity = item.get('proximity', 1.0)
                            scores[theme] = max(scores[theme], score * proximity)

        # Extraire les thèmes à partir du contexte de navigation
        if 'navigation_context' in context and isinstance(context['navigation_context'], dict):
            nav_context = context['navigation_context']

            # Thèmes de la section actuelle
            if 'current_section' in nav_context and nav_context['current_section'] in self.themes:
                scores[nav_context['current_section']] = max(scores[nav_context['current_section']], 0.7)

            # Thèmes des sections parentes
            if 'parent_sections' in nav_context and isinstance(nav_context['parent_sections'], list):
                for i, section in enumerate(nav_context['parent_sections']):
                    if section in self.themes:
                        # Les sections plus proches ont plus de poids
                        weight = 0.5 * (1.0 - (i / len(nav_context['parent_sections'])))
                        scores[section] = max(scores[section], weight)

        return scores

    def _apply_learning(self, scores: Dict[str, float], content: str) -> Dict[str, float]:
        """
        Applique l'apprentissage basé sur l'historique.

        Args:
            scores: Scores initiaux
            content: Contenu prétraité

        Returns:
            Scores ajustés
        """
        adjusted_scores = scores.copy()

        # Récupérer les statistiques des mots-clés
        keyword_stats = self.history.get_keyword_statistics()

        # Extraire les mots du contenu
        words = re.findall(r'\b\w+\b', content.lower())

        # Ajuster les scores en fonction des mots-clés appris
        for word in words:
            if word in keyword_stats and len(word) > 3:  # Ignorer les mots trop courts
                main_theme = keyword_stats[word]["main_theme"]
                if main_theme and main_theme in adjusted_scores:
                    # Ajuster le score en fonction de l'apprentissage
                    adjustment = self.learning_rate * (keyword_stats[word]["count"] / 10.0)  # Limiter l'influence
                    adjusted_scores[main_theme] += adjustment

        # Ajuster en fonction des retours utilisateur
        user_feedback_stats = self.history.get_user_feedback_statistics()

        if "theme_adjustments" in user_feedback_stats:
            for theme, adjustments in user_feedback_stats["theme_adjustments"].items():
                if theme in adjusted_scores:
                    # Calculer l'ajustement moyen
                    total_feedback = (
                        adjustments["added"] +
                        adjustments["removed"] +
                        adjustments["increased"] +
                        adjustments["decreased"]
                    )

                    if total_feedback > 0:
                        avg_adjustment = adjustments["total_adjustment"] / total_feedback

                        # Appliquer l'ajustement pondéré par le poids du retour utilisateur
                        adjusted_scores[theme] += avg_adjustment * self.user_feedback_weight

        return adjusted_scores

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
            Scores combinés
        """
        combined = {}

        # Combiner les scores
        for theme in set(scores_a.keys()) | set(scores_b.keys()):
            score_a = scores_a.get(theme, 0.0)
            score_b = scores_b.get(theme, 0.0)
            combined[theme] = (score_a * weight_a) + (score_b * weight_b)

        return combined

    def _normalize_scores(self, scores: Dict[str, float], min_threshold: float = 0.1) -> Dict[str, float]:
        """
        Normalise les scores et applique un seuil minimum.

        Args:
            scores: Scores à normaliser
            min_threshold: Seuil minimum pour conserver un thème (défaut: 0.1)

        Returns:
            Scores normalisés
        """
        # Trouver le score maximum
        max_score = max(scores.values()) if scores else 0.0

        # Normaliser les scores
        normalized = {}
        if max_score > 0:
            for theme, score in scores.items():
                normalized_score = score / max_score
                if normalized_score >= min_threshold:
                    normalized[theme] = normalized_score

        return normalized
