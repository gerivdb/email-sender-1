#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de sélection pour le système CRUD thématique.

Ce module fournit des fonctionnalités pour sélectionner des éléments
selon différents critères pour les opérations d'archivage et de suppression.
"""

import os
import glob
import json
import re
from typing import List, Dict, Any, Optional, Callable, Union, Set, Tuple
from datetime import datetime, timedelta

class ThematicSelector:
    """Classe pour la sélection d'éléments selon différents critères."""

    def __init__(self, storage_path: str):
        """
        Initialise le sélecteur thématique.

        Args:
            storage_path: Chemin vers le répertoire de stockage des données
        """
        self.storage_path = storage_path

    def select_by_id(self, item_id: str) -> List[str]:
        """
        Sélectionne un élément par son identifiant.

        Args:
            item_id: Identifiant de l'élément à sélectionner

        Returns:
            Liste contenant l'identifiant de l'élément s'il existe, sinon liste vide
        """
        item_path = os.path.join(self.storage_path, f"{item_id}.json")
        if os.path.exists(item_path):
            return [item_id]
        return []

    def select_by_ids(self, item_ids: List[str]) -> List[str]:
        """
        Sélectionne des éléments par leurs identifiants.

        Args:
            item_ids: Liste d'identifiants des éléments à sélectionner

        Returns:
            Liste des identifiants des éléments qui existent
        """
        existing_ids = []
        for item_id in item_ids:
            item_path = os.path.join(self.storage_path, f"{item_id}.json")
            if os.path.exists(item_path):
                existing_ids.append(item_id)
        return existing_ids

    def select_by_theme(self, theme: str) -> List[str]:
        """
        Sélectionne tous les éléments d'un thème.

        Args:
            theme: Thème des éléments à sélectionner

        Returns:
            Liste des identifiants des éléments du thème
        """
        theme_dir = os.path.join(self.storage_path, theme)
        if not os.path.exists(theme_dir) or not os.path.isdir(theme_dir):
            return []

        # Récupérer tous les fichiers JSON dans le répertoire thématique
        json_files = glob.glob(os.path.join(theme_dir, "*.json"))

        # Extraire les identifiants des éléments
        item_ids = [os.path.splitext(os.path.basename(file_path))[0] for file_path in json_files]

        return item_ids

    def select_by_themes(self, themes: List[str]) -> List[str]:
        """
        Sélectionne tous les éléments de plusieurs thèmes.

        Args:
            themes: Liste des thèmes des éléments à sélectionner

        Returns:
            Liste des identifiants des éléments des thèmes
        """
        all_item_ids = set()
        for theme in themes:
            theme_items = self.select_by_theme(theme)
            all_item_ids.update(theme_items)

        return list(all_item_ids)

    def select_by_metadata(self, metadata_filter: Dict[str, Any]) -> List[str]:
        """
        Sélectionne les éléments selon des critères de métadonnées.

        Args:
            metadata_filter: Dictionnaire de filtres de métadonnées

        Returns:
            Liste des identifiants des éléments correspondant aux critères
        """
        # Récupérer tous les fichiers JSON dans le répertoire principal
        json_files = glob.glob(os.path.join(self.storage_path, "*.json"))

        matching_ids = []

        for file_path in json_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    item = json.load(f)

                # Vérifier si l'élément correspond aux critères
                if "metadata" in item:
                    matches = True
                    for key, value in metadata_filter.items():
                        if key not in item["metadata"] or item["metadata"][key] != value:
                            matches = False
                            break

                    if matches:
                        matching_ids.append(item["id"])
            except Exception as e:
                print(f"Erreur lors de la lecture du fichier {file_path}: {str(e)}")

        return matching_ids

    def select_by_content(self, content_filter: str, case_sensitive: bool = False) -> List[str]:
        """
        Sélectionne les éléments selon leur contenu.

        Args:
            content_filter: Texte à rechercher dans le contenu
            case_sensitive: Si True, la recherche est sensible à la casse

        Returns:
            Liste des identifiants des éléments correspondant aux critères
        """
        # Récupérer tous les fichiers JSON dans le répertoire principal
        json_files = glob.glob(os.path.join(self.storage_path, "*.json"))

        matching_ids = []

        for file_path in json_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    item = json.load(f)

                # Vérifier si l'élément contient le texte recherché
                if "content" in item:
                    content = item["content"]
                    if not case_sensitive:
                        content = content.lower()
                        content_filter = content_filter.lower()

                    if content_filter in content:
                        matching_ids.append(item["id"])
            except Exception as e:
                print(f"Erreur lors de la lecture du fichier {file_path}: {str(e)}")

        return matching_ids

    def select_by_regex(self, pattern: str, field: str = "content") -> List[str]:
        """
        Sélectionne les éléments selon une expression régulière.

        Args:
            pattern: Expression régulière à appliquer
            field: Champ sur lequel appliquer l'expression régulière

        Returns:
            Liste des identifiants des éléments correspondant aux critères
        """
        # Récupérer tous les fichiers JSON dans le répertoire principal
        json_files = glob.glob(os.path.join(self.storage_path, "*.json"))

        matching_ids = []
        regex = re.compile(pattern)

        for file_path in json_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    item = json.load(f)

                # Vérifier si l'élément correspond à l'expression régulière
                if field in item:
                    if regex.search(str(item[field])):
                        matching_ids.append(item["id"])
            except Exception as e:
                print(f"Erreur lors de la lecture du fichier {file_path}: {str(e)}")

        return matching_ids

    def select_by_date_range(self,
                           start_date: Optional[datetime] = None,
                           end_date: Optional[datetime] = None,
                           date_field: str = "created_at") -> List[str]:
        """
        Sélectionne les éléments selon une plage de dates.

        Args:
            start_date: Date de début de la plage (optionnel)
            end_date: Date de fin de la plage (optionnel)
            date_field: Champ de date à utiliser pour la sélection

        Returns:
            Liste des identifiants des éléments correspondant aux critères
        """
        # Récupérer tous les fichiers JSON dans le répertoire principal
        json_files = glob.glob(os.path.join(self.storage_path, "*.json"))

        matching_ids = []

        for file_path in json_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    item = json.load(f)

                # Vérifier si l'élément a le champ de date
                if "metadata" in item and date_field in item["metadata"]:
                    date_str = item["metadata"][date_field]
                    item_date = datetime.fromisoformat(date_str)

                    # Vérifier si la date est dans la plage
                    in_range = True
                    if start_date and item_date < start_date:
                        in_range = False
                    if end_date and item_date > end_date:
                        in_range = False

                    if in_range:
                        matching_ids.append(item["id"])
            except Exception as e:
                print(f"Erreur lors de la lecture du fichier {file_path}: {str(e)}")

        return matching_ids

    def select_by_custom_filter(self, filter_func: Callable[[Dict[str, Any]], bool]) -> List[str]:
        """
        Sélectionne les éléments selon une fonction de filtrage personnalisée.

        Args:
            filter_func: Fonction qui prend un élément et retourne True si l'élément doit être sélectionné

        Returns:
            Liste des identifiants des éléments correspondant aux critères
        """
        # Récupérer tous les fichiers JSON dans le répertoire principal
        json_files = glob.glob(os.path.join(self.storage_path, "*.json"))

        matching_ids = []

        for file_path in json_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    item = json.load(f)

                # Appliquer la fonction de filtrage
                if filter_func(item):
                    matching_ids.append(item["id"])
            except Exception as e:
                print(f"Erreur lors de la lecture du fichier {file_path}: {str(e)}")

        return matching_ids

    def select_by_theme_hierarchy(self, theme: str, include_subthemes: bool = True) -> List[str]:
        """
        Sélectionne les éléments d'un thème et optionnellement de ses sous-thèmes.

        Args:
            theme: Thème principal
            include_subthemes: Si True, inclut les sous-thèmes

        Returns:
            Liste des identifiants des éléments sélectionnés
        """
        # Sélectionner les éléments du thème principal
        selected_ids = self.select_by_theme(theme)

        if include_subthemes:
            # Rechercher les sous-thèmes (répertoires commençant par le thème principal)
            all_dirs = [d for d in os.listdir(self.storage_path)
                       if os.path.isdir(os.path.join(self.storage_path, d))]

            subthemes = [d for d in all_dirs if d.startswith(f"{theme}_")]

            # Ajouter les éléments des sous-thèmes
            for subtheme in subthemes:
                subtheme_ids = self.select_by_theme(subtheme)
                selected_ids.extend(subtheme_ids)

        return list(set(selected_ids))  # Éliminer les doublons

    def select_by_theme_weight(self, theme: str, min_weight: float = 0.5) -> List[str]:
        """
        Sélectionne les éléments d'un thème avec un poids minimum.

        Args:
            theme: Thème à rechercher
            min_weight: Poids minimum du thème (0.0 à 1.0)

        Returns:
            Liste des identifiants des éléments sélectionnés
        """
        # Récupérer tous les fichiers JSON dans le répertoire principal
        json_files = glob.glob(os.path.join(self.storage_path, "*.json"))

        matching_ids = []

        for file_path in json_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    item = json.load(f)

                # Vérifier si l'élément a le thème avec un poids suffisant
                if "metadata" in item and "themes" in item["metadata"]:
                    themes = item["metadata"]["themes"]
                    if theme in themes and themes[theme] >= min_weight:
                        matching_ids.append(item["id"])
            except Exception as e:
                print(f"Erreur lors de la lecture du fichier {file_path}: {str(e)}")

        return matching_ids

    def select_by_theme_exclusivity(self, theme: str, exclusivity_threshold: float = 0.8) -> List[str]:
        """
        Sélectionne les éléments qui appartiennent principalement au thème spécifié.

        Args:
            theme: Thème principal
            exclusivity_threshold: Seuil d'exclusivité (0.0 à 1.0)

        Returns:
            Liste des identifiants des éléments sélectionnés
        """
        # Récupérer tous les fichiers JSON dans le répertoire principal
        json_files = glob.glob(os.path.join(self.storage_path, "*.json"))

        matching_ids = []

        for file_path in json_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    item = json.load(f)

                # Vérifier si l'élément appartient principalement au thème spécifié
                if "metadata" in item and "themes" in item["metadata"]:
                    themes = item["metadata"]["themes"]
                    if theme in themes:
                        theme_weight = themes[theme]

                        # Calculer le poids total de tous les thèmes
                        total_weight = sum(themes.values())

                        # Calculer l'exclusivité du thème
                        if total_weight > 0:
                            exclusivity = theme_weight / total_weight

                            if exclusivity >= exclusivity_threshold:
                                matching_ids.append(item["id"])
            except Exception as e:
                print(f"Erreur lors de la lecture du fichier {file_path}: {str(e)}")

        return matching_ids

    def select_by_theme_overlap(self, themes: List[str], min_overlap: int = 2) -> List[str]:
        """
        Sélectionne les éléments qui appartiennent à plusieurs thèmes spécifiés.

        Args:
            themes: Liste des thèmes à rechercher
            min_overlap: Nombre minimum de thèmes auxquels un élément doit appartenir

        Returns:
            Liste des identifiants des éléments sélectionnés
        """
        # Récupérer tous les fichiers JSON dans le répertoire principal
        json_files = glob.glob(os.path.join(self.storage_path, "*.json"))

        matching_ids = []

        for file_path in json_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    item = json.load(f)

                # Vérifier si l'élément appartient à plusieurs thèmes spécifiés
                if "metadata" in item and "themes" in item["metadata"]:
                    item_themes = item["metadata"]["themes"]

                    # Compter le nombre de thèmes en commun
                    overlap_count = sum(1 for theme in themes if theme in item_themes)

                    if overlap_count >= min_overlap:
                        matching_ids.append(item["id"])
            except Exception as e:
                print(f"Erreur lors de la lecture du fichier {file_path}: {str(e)}")

        return matching_ids

    def combine_selections(self, selections: List[List[str]], mode: str = "union") -> List[str]:
        """
        Combine plusieurs sélections selon un mode spécifié.

        Args:
            selections: Liste de listes d'identifiants d'éléments
            mode: Mode de combinaison ("union", "intersection", "difference")

        Returns:
            Liste des identifiants des éléments résultant de la combinaison
        """
        if not selections:
            return []

        if mode == "union":
            # Union de toutes les sélections
            result = set()
            for selection in selections:
                result.update(selection)
            return list(result)

        elif mode == "intersection":
            # Intersection de toutes les sélections
            if not selections:
                return []
            result = set(selections[0])
            for selection in selections[1:]:
                result.intersection_update(selection)
            return list(result)

        elif mode == "difference":
            # Différence entre la première sélection et les autres
            if not selections:
                return []
            result = set(selections[0])
            for selection in selections[1:]:
                result.difference_update(selection)
            return list(result)

        else:
            raise ValueError(f"Mode de combinaison non supporté: {mode}")
