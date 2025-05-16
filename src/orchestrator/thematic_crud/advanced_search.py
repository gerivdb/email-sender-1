#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de recherche avancée pour le système CRUD thématique.

Ce module fournit des fonctionnalités avancées pour la recherche d'éléments
par thème, multi-critères et requêtes vectorielles.
"""

import os
import sys
import json
import glob
import re
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Union, Set, Tuple, Callable
from pathlib import Path
from collections import defaultdict

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

class ThematicAdvancedSearch:
    """Classe pour la recherche avancée thématique."""
    
    def __init__(self, storage_path: str):
        """
        Initialise le gestionnaire de recherche avancée thématique.
        
        Args:
            storage_path: Chemin vers le répertoire de stockage des données
        """
        self.storage_path = storage_path
    
    def search_by_multi_criteria(self, 
                               themes: Optional[List[str]] = None,
                               content_query: Optional[str] = None,
                               metadata_filters: Optional[Dict[str, Any]] = None,
                               date_range: Optional[Dict[str, str]] = None,
                               theme_weights: Optional[Dict[str, float]] = None,
                               sort_by: str = "relevance",
                               limit: int = 100, 
                               offset: int = 0) -> List[Dict[str, Any]]:
        """
        Recherche des éléments selon plusieurs critères combinés.
        
        Args:
            themes: Liste des thèmes à inclure dans la recherche (optionnel)
            content_query: Requête textuelle à rechercher dans le contenu (optionnel)
            metadata_filters: Filtres sur les métadonnées (optionnel)
            date_range: Plage de dates pour la recherche (optionnel)
            theme_weights: Poids minimum pour chaque thème (optionnel)
            sort_by: Critère de tri ("relevance", "date", "title", "theme_weight")
            limit: Nombre maximum d'éléments à récupérer (défaut: 100)
            offset: Décalage pour la pagination (défaut: 0)
            
        Returns:
            Liste des éléments correspondant aux critères de recherche
        """
        # Récupérer tous les fichiers JSON dans le répertoire principal
        json_files = glob.glob(os.path.join(self.storage_path, "*.json"))
        
        # Filtrer par thèmes si spécifiés
        if themes:
            theme_files = set()
            for theme in themes:
                theme_dir = os.path.join(self.storage_path, theme)
                if os.path.exists(theme_dir) and os.path.isdir(theme_dir):
                    theme_json_files = glob.glob(os.path.join(theme_dir, "*.json"))
                    # Extraire les IDs des éléments
                    theme_ids = [os.path.splitext(os.path.basename(file_path))[0] for file_path in theme_json_files]
                    # Ajouter les fichiers correspondants du répertoire principal
                    for file_path in json_files:
                        file_id = os.path.splitext(os.path.basename(file_path))[0]
                        if file_id in theme_ids:
                            theme_files.add(file_path)
            
            # Si des thèmes sont spécifiés mais aucun fichier ne correspond, retourner une liste vide
            if themes and not theme_files:
                return []
            
            # Utiliser uniquement les fichiers correspondant aux thèmes
            json_files = list(theme_files)
        
        # Charger et filtrer les éléments
        matching_items = []
        for file_path in json_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    item = json.load(f)
                    
                    # Appliquer tous les filtres
                    if (self._matches_content_query(item, content_query) and
                        self._matches_metadata_filters(item, metadata_filters) and
                        self._matches_date_range(item, date_range) and
                        self._matches_theme_weights(item, theme_weights)):
                        
                        # Calculer le score de pertinence
                        relevance_score = self._calculate_multi_criteria_relevance(
                            item, content_query, themes, theme_weights
                        )
                        
                        # Ajouter le score à l'élément pour le tri
                        item["_relevance_score"] = relevance_score
                        
                        matching_items.append(item)
            except Exception as e:
                print(f"Erreur lors du chargement du fichier {file_path}: {str(e)}")
        
        # Trier les éléments selon le critère spécifié
        if sort_by == "relevance":
            matching_items.sort(key=lambda x: x.get("_relevance_score", 0), reverse=True)
        elif sort_by == "date":
            matching_items.sort(
                key=lambda x: x.get("metadata", {}).get("created_at", ""),
                reverse=True
            )
        elif sort_by == "title":
            matching_items.sort(
                key=lambda x: x.get("metadata", {}).get("title", "").lower()
            )
        elif sort_by == "theme_weight":
            # Trier par le poids du premier thème spécifié
            if themes and len(themes) > 0:
                primary_theme = themes[0]
                matching_items.sort(
                    key=lambda x: x.get("metadata", {}).get("themes", {}).get(primary_theme, 0),
                    reverse=True
                )
        
        # Appliquer la pagination
        paginated_items = matching_items[offset:offset + limit]
        
        # Supprimer le score de pertinence temporaire
        for item in paginated_items:
            if "_relevance_score" in item:
                del item["_relevance_score"]
        
        return paginated_items
    
    def search_by_theme_relationships(self, 
                                    primary_theme: str,
                                    related_themes: Optional[List[str]] = None,
                                    relationship_type: str = "any",
                                    min_overlap: int = 1,
                                    limit: int = 100, 
                                    offset: int = 0) -> List[Dict[str, Any]]:
        """
        Recherche des éléments selon les relations entre thèmes.
        
        Args:
            primary_theme: Thème principal
            related_themes: Thèmes liés (optionnel)
            relationship_type: Type de relation ("any", "all", "only")
            min_overlap: Nombre minimum de thèmes liés requis
            limit: Nombre maximum d'éléments à récupérer (défaut: 100)
            offset: Décalage pour la pagination (défaut: 0)
            
        Returns:
            Liste des éléments correspondant aux critères de recherche
        """
        # Récupérer les éléments du thème principal
        primary_theme_dir = os.path.join(self.storage_path, primary_theme)
        if not os.path.exists(primary_theme_dir) or not os.path.isdir(primary_theme_dir):
            return []
        
        primary_json_files = glob.glob(os.path.join(primary_theme_dir, "*.json"))
        
        # Charger les éléments du thème principal
        primary_items = []
        for file_path in primary_json_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    item = json.load(f)
                    primary_items.append(item)
            except Exception as e:
                print(f"Erreur lors du chargement du fichier {file_path}: {str(e)}")
        
        # Si aucun thème lié n'est spécifié, retourner les éléments du thème principal
        if not related_themes:
            # Appliquer la pagination
            return primary_items[offset:offset + limit]
        
        # Filtrer les éléments selon les relations entre thèmes
        matching_items = []
        for item in primary_items:
            if "metadata" in item and "themes" in item["metadata"]:
                item_themes = set(item["metadata"]["themes"].keys())
                related_themes_set = set(related_themes)
                
                if relationship_type == "any":
                    # Au moins un thème lié doit être présent
                    overlap = len(item_themes.intersection(related_themes_set))
                    if overlap >= min_overlap:
                        matching_items.append(item)
                
                elif relationship_type == "all":
                    # Tous les thèmes liés doivent être présents
                    if related_themes_set.issubset(item_themes):
                        matching_items.append(item)
                
                elif relationship_type == "only":
                    # Uniquement les thèmes spécifiés doivent être présents
                    allowed_themes = {primary_theme}.union(related_themes_set)
                    if item_themes.issubset(allowed_themes):
                        matching_items.append(item)
        
        # Appliquer la pagination
        return matching_items[offset:offset + limit]
    
    def search_by_theme_hierarchy(self, 
                                theme: str,
                                include_subthemes: bool = True,
                                include_parent_themes: bool = False,
                                max_depth: int = 3,
                                limit: int = 100, 
                                offset: int = 0) -> List[Dict[str, Any]]:
        """
        Recherche des éléments selon une hiérarchie thématique.
        
        Args:
            theme: Thème principal
            include_subthemes: Inclure les sous-thèmes
            include_parent_themes: Inclure les thèmes parents
            max_depth: Profondeur maximale de la hiérarchie
            limit: Nombre maximum d'éléments à récupérer (défaut: 100)
            offset: Décalage pour la pagination (défaut: 0)
            
        Returns:
            Liste des éléments correspondant aux critères de recherche
        """
        # Récupérer tous les thèmes (répertoires)
        all_themes = [d for d in os.listdir(self.storage_path) 
                     if os.path.isdir(os.path.join(self.storage_path, d))]
        
        # Déterminer les thèmes à inclure dans la recherche
        themes_to_search = {theme}
        
        if include_subthemes:
            # Ajouter les sous-thèmes (répertoires commençant par le thème principal)
            subthemes = [t for t in all_themes if t.startswith(f"{theme}_")]
            
            # Limiter la profondeur
            current_depth = 1
            current_level_themes = set(subthemes)
            
            while current_depth < max_depth and current_level_themes:
                next_level_themes = set()
                for subtheme in current_level_themes:
                    themes_to_search.add(subtheme)
                    # Trouver les sous-thèmes du niveau suivant
                    next_level = [t for t in all_themes if t.startswith(f"{subtheme}_")]
                    next_level_themes.update(next_level)
                
                current_level_themes = next_level_themes
                current_depth += 1
            
            # Ajouter les derniers sous-thèmes
            themes_to_search.update(current_level_themes)
        
        if include_parent_themes:
            # Ajouter les thèmes parents (thèmes dont le thème principal est un sous-thème)
            parent_themes = [t for t in all_themes if theme.startswith(f"{t}_")]
            
            # Limiter la profondeur
            current_depth = 1
            current_level_themes = set(parent_themes)
            
            while current_depth < max_depth and current_level_themes:
                next_level_themes = set()
                for parent_theme in current_level_themes:
                    themes_to_search.add(parent_theme)
                    # Trouver les parents du niveau supérieur
                    next_level = [t for t in all_themes if parent_theme.startswith(f"{t}_")]
                    next_level_themes.update(next_level)
                
                current_level_themes = next_level_themes
                current_depth += 1
            
            # Ajouter les derniers thèmes parents
            themes_to_search.update(current_level_themes)
        
        # Récupérer les éléments des thèmes sélectionnés
        all_items = []
        for search_theme in themes_to_search:
            theme_dir = os.path.join(self.storage_path, search_theme)
            if os.path.exists(theme_dir) and os.path.isdir(theme_dir):
                json_files = glob.glob(os.path.join(theme_dir, "*.json"))
                
                for file_path in json_files:
                    try:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            item = json.load(f)
                            all_items.append(item)
                    except Exception as e:
                        print(f"Erreur lors du chargement du fichier {file_path}: {str(e)}")
        
        # Éliminer les doublons par ID
        unique_items = {}
        for item in all_items:
            if "id" in item:
                unique_items[item["id"]] = item
        
        # Convertir en liste et appliquer la pagination
        items_list = list(unique_items.values())
        
        # Trier par pertinence thématique (poids du thème principal)
        items_list.sort(
            key=lambda x: x.get("metadata", {}).get("themes", {}).get(theme, 0),
            reverse=True
        )
        
        return items_list[offset:offset + limit]
    
    def _matches_content_query(self, item: Dict[str, Any], content_query: Optional[str]) -> bool:
        """
        Vérifie si un élément correspond à une requête de contenu.
        
        Args:
            item: Élément à vérifier
            content_query: Requête de contenu
            
        Returns:
            True si l'élément correspond à la requête, False sinon
        """
        if not content_query:
            return True
        
        content_query = content_query.lower()
        
        # Vérifier dans le contenu
        if "content" in item and content_query in item["content"].lower():
            return True
        
        # Vérifier dans les métadonnées
        if "metadata" in item:
            metadata = item["metadata"]
            
            # Vérifier dans le titre
            if "title" in metadata and content_query in metadata["title"].lower():
                return True
            
            # Vérifier dans les tags
            if "tags" in metadata and isinstance(metadata["tags"], list):
                for tag in metadata["tags"]:
                    if content_query in tag.lower():
                        return True
        
        return False
    
    def _matches_metadata_filters(self, item: Dict[str, Any], 
                                metadata_filters: Optional[Dict[str, Any]]) -> bool:
        """
        Vérifie si un élément correspond aux filtres de métadonnées.
        
        Args:
            item: Élément à vérifier
            metadata_filters: Filtres de métadonnées
            
        Returns:
            True si l'élément correspond aux filtres, False sinon
        """
        if not metadata_filters:
            return True
        
        if "metadata" not in item:
            return False
        
        metadata = item["metadata"]
        
        for key, value in metadata_filters.items():
            if key not in metadata:
                return False
            
            if isinstance(value, list):
                # Vérifier si au moins une valeur correspond
                if not isinstance(metadata[key], list) or not any(v in metadata[key] for v in value):
                    return False
            elif metadata[key] != value:
                return False
        
        return True
    
    def _matches_date_range(self, item: Dict[str, Any], 
                          date_range: Optional[Dict[str, str]]) -> bool:
        """
        Vérifie si un élément correspond à une plage de dates.
        
        Args:
            item: Élément à vérifier
            date_range: Plage de dates
            
        Returns:
            True si l'élément correspond à la plage de dates, False sinon
        """
        if not date_range:
            return True
        
        if "metadata" not in item:
            return False
        
        metadata = item["metadata"]
        
        # Déterminer le champ de date à utiliser
        date_field = date_range.get("field", "created_at")
        
        if date_field not in metadata:
            return False
        
        try:
            item_date = datetime.fromisoformat(metadata[date_field])
            
            # Vérifier la date de début
            if "start" in date_range:
                start_date = datetime.fromisoformat(date_range["start"])
                if item_date < start_date:
                    return False
            
            # Vérifier la date de fin
            if "end" in date_range:
                end_date = datetime.fromisoformat(date_range["end"])
                if item_date > end_date:
                    return False
            
            return True
        except (ValueError, TypeError):
            return False
    
    def _matches_theme_weights(self, item: Dict[str, Any], 
                             theme_weights: Optional[Dict[str, float]]) -> bool:
        """
        Vérifie si un élément correspond aux poids de thèmes spécifiés.
        
        Args:
            item: Élément à vérifier
            theme_weights: Poids minimum pour chaque thème
            
        Returns:
            True si l'élément correspond aux poids de thèmes, False sinon
        """
        if not theme_weights:
            return True
        
        if "metadata" not in item or "themes" not in item["metadata"]:
            return False
        
        item_themes = item["metadata"]["themes"]
        
        for theme, min_weight in theme_weights.items():
            if theme not in item_themes or item_themes[theme] < min_weight:
                return False
        
        return True
    
    def _calculate_multi_criteria_relevance(self, item: Dict[str, Any], 
                                         content_query: Optional[str],
                                         themes: Optional[List[str]],
                                         theme_weights: Optional[Dict[str, float]]) -> float:
        """
        Calcule le score de pertinence pour une recherche multi-critères.
        
        Args:
            item: Élément à évaluer
            content_query: Requête de contenu
            themes: Thèmes à rechercher
            theme_weights: Poids minimum pour chaque thème
            
        Returns:
            Score de pertinence
        """
        relevance = 0.0
        
        # Pertinence du contenu
        if content_query:
            content_query = content_query.lower()
            
            # Vérifier dans le contenu
            if "content" in item:
                content = item["content"].lower()
                # Compter les occurrences
                relevance += content.count(content_query) * 0.5
                # Bonus si le contenu commence par la requête
                if content.startswith(content_query):
                    relevance += 2.0
            
            # Vérifier dans les métadonnées
            if "metadata" in item:
                metadata = item["metadata"]
                
                # Vérifier dans le titre (plus important)
                if "title" in metadata:
                    title = metadata["title"].lower()
                    relevance += title.count(content_query) * 2.0
                    # Bonus si le titre commence par la requête
                    if title.startswith(content_query):
                        relevance += 5.0
                
                # Vérifier dans les tags
                if "tags" in metadata and isinstance(metadata["tags"], list):
                    for tag in metadata["tags"]:
                        if content_query in tag.lower():
                            relevance += 1.0
                        # Bonus si le tag est exactement la requête
                        if tag.lower() == content_query:
                            relevance += 3.0
        
        # Pertinence des thèmes
        if themes and "metadata" in item and "themes" in item["metadata"]:
            item_themes = item["metadata"]["themes"]
            
            for theme in themes:
                if theme in item_themes:
                    # Ajouter le poids du thème au score de pertinence
                    relevance += item_themes[theme] * 3.0
        
        # Pertinence des poids de thèmes
        if theme_weights and "metadata" in item and "themes" in item["metadata"]:
            item_themes = item["metadata"]["themes"]
            
            for theme, min_weight in theme_weights.items():
                if theme in item_themes:
                    # Bonus si le poids du thème est supérieur au minimum requis
                    weight_diff = item_themes[theme] - min_weight
                    if weight_diff > 0:
                        relevance += weight_diff * 2.0
        
        return relevance
