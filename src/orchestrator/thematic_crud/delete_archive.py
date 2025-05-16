#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de suppression et archivage thématique.

Ce module fournit des fonctionnalités pour supprimer et archiver des éléments
de roadmap par thème et autres critères.
"""

import os
import sys
import json
import glob
import shutil
import time
import copy
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Union, Callable
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

# Import local
from src.orchestrator.thematic_crud.selection import ThematicSelector

class ThematicDeleteArchive:
    """Classe pour la suppression et l'archivage thématique."""

    def __init__(self, storage_path: str, archive_path: Optional[str] = None):
        """
        Initialise le gestionnaire de suppression et d'archivage thématique.

        Args:
            storage_path: Chemin vers le répertoire de stockage des données
            archive_path: Chemin vers le répertoire d'archivage (optionnel)
        """
        self.storage_path = storage_path

        # Utiliser un sous-répertoire "archive" par défaut
        if archive_path is None:
            self.archive_path = os.path.join(storage_path, "_archive")
        else:
            self.archive_path = archive_path

        # Créer le répertoire d'archivage s'il n'existe pas
        os.makedirs(self.archive_path, exist_ok=True)

        # Initialiser le sélecteur thématique
        self.selector = ThematicSelector(storage_path)

    def delete_item(self, item_id: str, permanent: bool = False, reason: Optional[str] = None) -> bool:
        """
        Supprime un élément.

        Args:
            item_id: Identifiant de l'élément à supprimer
            permanent: Si True, supprime définitivement l'élément sans l'archiver
            reason: Raison de la suppression/archivage (optionnel)

        Returns:
            True si l'élément a été supprimé, False sinon
        """
        # Vérifier si l'élément existe
        item_path = os.path.join(self.storage_path, f"{item_id}.json")
        if not os.path.exists(item_path):
            return False

        # Archiver l'élément si nécessaire
        if not permanent:
            try:
                # Charger l'élément pour obtenir ses thèmes
                with open(item_path, 'r', encoding='utf-8') as f:
                    item = json.load(f)

                # Archiver l'élément
                self._archive_item(item, reason or "Suppression")
            except Exception as e:
                print(f"Erreur lors de l'archivage de l'élément {item_id}: {str(e)}")
                return False

        # Supprimer l'élément du stockage principal
        try:
            os.remove(item_path)
        except Exception as e:
            print(f"Erreur lors de la suppression de l'élément {item_id}: {str(e)}")
            return False

        # Supprimer l'élément des répertoires thématiques
        try:
            # Parcourir tous les sous-répertoires
            for root, dirs, files in os.walk(self.storage_path):
                # Ignorer le répertoire d'archivage
                if os.path.abspath(root) == os.path.abspath(self.archive_path):
                    continue

                # Vérifier si l'élément existe dans ce répertoire
                theme_item_path = os.path.join(root, f"{item_id}.json")
                if os.path.exists(theme_item_path):
                    os.remove(theme_item_path)
        except Exception as e:
            print(f"Erreur lors de la suppression de l'élément {item_id} des répertoires thématiques: {str(e)}")
            # Ne pas échouer si la suppression des copies thématiques échoue

        return True

    def delete_items_by_theme(self, theme: str, permanent: bool = False, reason: Optional[str] = None) -> int:
        """
        Supprime tous les éléments d'un thème.

        Args:
            theme: Thème des éléments à supprimer
            permanent: Si True, supprime définitivement les éléments sans les archiver
            reason: Raison de la suppression/archivage (optionnel)

        Returns:
            Nombre d'éléments supprimés
        """
        theme_dir = os.path.join(self.storage_path, theme)

        if not os.path.exists(theme_dir) or not os.path.isdir(theme_dir):
            return 0

        # Récupérer tous les fichiers JSON dans le répertoire thématique
        json_files = glob.glob(os.path.join(theme_dir, "*.json"))

        # Supprimer chaque élément
        count = 0
        for file_path in json_files:
            item_id = os.path.splitext(os.path.basename(file_path))[0]
            if self.delete_item(item_id, permanent, reason or f"Suppression du thème '{theme}'"):
                count += 1

        return count

    def archive_item(self, item_id: str, reason: Optional[str] = None) -> bool:
        """
        Archive un élément sans le supprimer.

        Args:
            item_id: Identifiant de l'élément à archiver
            reason: Raison de l'archivage (optionnel)

        Returns:
            True si l'élément a été archivé, False sinon
        """
        # Vérifier si l'élément existe
        item_path = os.path.join(self.storage_path, f"{item_id}.json")
        if not os.path.exists(item_path):
            return False

        try:
            # Charger l'élément
            with open(item_path, 'r', encoding='utf-8') as f:
                item = json.load(f)

            # Archiver l'élément
            self._archive_item(item, reason)

            return True
        except Exception as e:
            print(f"Erreur lors de l'archivage de l'élément {item_id}: {str(e)}")
            return False

    def archive_items_by_theme(self, theme: str, reason: Optional[str] = None) -> int:
        """
        Archive tous les éléments d'un thème sans les supprimer.

        Args:
            theme: Thème des éléments à archiver
            reason: Raison de l'archivage (optionnel)

        Returns:
            Nombre d'éléments archivés
        """
        theme_dir = os.path.join(self.storage_path, theme)

        if not os.path.exists(theme_dir) or not os.path.isdir(theme_dir):
            return 0

        # Récupérer tous les fichiers JSON dans le répertoire thématique
        json_files = glob.glob(os.path.join(theme_dir, "*.json"))

        # Archiver chaque élément
        count = 0
        for file_path in json_files:
            item_id = os.path.splitext(os.path.basename(file_path))[0]
            if self.archive_item(item_id, reason):
                count += 1

        return count

    def restore_archived_item(self, item_id: str) -> bool:
        """
        Restaure un élément archivé.

        Args:
            item_id: Identifiant de l'élément à restaurer

        Returns:
            True si l'élément a été restauré, False sinon
        """
        # Vérifier si l'élément archivé existe
        archive_item_path = os.path.join(self.archive_path, f"{item_id}.json")
        if not os.path.exists(archive_item_path):
            return False

        try:
            # Charger l'élément archivé
            with open(archive_item_path, 'r', encoding='utf-8') as f:
                item = json.load(f)

            # Mettre à jour la date de restauration
            item["metadata"]["restored_at"] = datetime.now().isoformat()

            # Sauvegarder l'élément dans le stockage principal
            item_path = os.path.join(self.storage_path, f"{item_id}.json")
            with open(item_path, 'w', encoding='utf-8') as f:
                json.dump(item, f, ensure_ascii=False, indent=2)

            # Sauvegarder l'élément dans les répertoires thématiques
            themes = item["metadata"].get("themes", {})
            for theme in themes.keys():
                theme_dir = os.path.join(self.storage_path, theme)
                os.makedirs(theme_dir, exist_ok=True)

                theme_path = os.path.join(theme_dir, f"{item_id}.json")
                with open(theme_path, 'w', encoding='utf-8') as f:
                    json.dump(item, f, ensure_ascii=False, indent=2)

            # Supprimer l'élément archivé
            os.remove(archive_item_path)

            return True
        except Exception as e:
            print(f"Erreur lors de la restauration de l'élément {item_id}: {str(e)}")
            return False

    def get_archived_items(self, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]:
        """
        Récupère les éléments archivés.

        Args:
            limit: Nombre maximum d'éléments à récupérer (défaut: 100)
            offset: Décalage pour la pagination (défaut: 0)

        Returns:
            Liste des éléments archivés
        """
        # Récupérer tous les fichiers JSON dans le répertoire d'archivage principal (pas les sous-répertoires thématiques)
        json_files = glob.glob(os.path.join(self.archive_path, "*.json"))

        # Trier les fichiers par date de modification (du plus récent au plus ancien)
        json_files.sort(key=os.path.getmtime, reverse=True)

        # Appliquer la pagination
        paginated_files = json_files[offset:offset + limit]

        # Charger les éléments
        items = []
        for file_path in paginated_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    item = json.load(f)
                    items.append(item)
            except Exception as e:
                print(f"Erreur lors du chargement du fichier {file_path}: {str(e)}")

        return items

    def get_archived_items_by_theme(self, theme: str, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]:
        """
        Récupère les éléments archivés par thème.

        Args:
            theme: Thème des éléments à récupérer
            limit: Nombre maximum d'éléments à récupérer (défaut: 100)
            offset: Décalage pour la pagination (défaut: 0)

        Returns:
            Liste des éléments archivés pour le thème spécifié
        """
        # Méthode alternative: parcourir tous les éléments archivés et filtrer par thème
        all_items = self.get_archived_items(limit=1000, offset=0)  # Limiter à 1000 pour des raisons de performance

        # Filtrer les éléments par thème
        themed_items = []
        for item in all_items:
            if "metadata" in item and "themes" in item["metadata"]:
                themes = item["metadata"]["themes"]
                if theme in themes:
                    themed_items.append(item)

        # Trier par date d'archivage (du plus récent au plus ancien)
        themed_items.sort(key=lambda x: x["metadata"].get("archived_at", ""), reverse=True)

        # Appliquer la pagination
        return themed_items[offset:offset + limit]

    def search_archived_items(self, query: str, themes: Optional[List[str]] = None,
                             metadata_filters: Optional[Dict[str, Any]] = None,
                             limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]:
        """
        Recherche des éléments dans les archives.

        Args:
            query: Requête textuelle à rechercher dans le contenu
            themes: Liste des thèmes à inclure dans la recherche (optionnel)
            metadata_filters: Filtres de métadonnées (optionnel)
            limit: Nombre maximum d'éléments à récupérer (défaut: 100)
            offset: Décalage pour la pagination (défaut: 0)

        Returns:
            Liste des éléments archivés correspondant aux critères de recherche
        """
        # Récupérer tous les éléments archivés
        all_items = []

        if themes:
            # Récupérer les éléments des thèmes spécifiés
            for theme in themes:
                theme_items = self.get_archived_items_by_theme(theme)
                all_items.extend(theme_items)

            # Éliminer les doublons (un élément peut être dans plusieurs thèmes)
            unique_items = {}
            for item in all_items:
                unique_items[item["id"]] = item

            all_items = list(unique_items.values())
        else:
            # Récupérer tous les éléments archivés
            all_items = self.get_archived_items(limit=1000, offset=0)  # Limiter à 1000 pour des raisons de performance

        # Filtrer par requête textuelle
        if query:
            query = query.lower()
            filtered_items = []

            for item in all_items:
                # Rechercher dans le contenu
                if "content" in item and query in item["content"].lower():
                    filtered_items.append(item)
                    continue

                # Rechercher dans les métadonnées
                if "metadata" in item:
                    metadata = item["metadata"]

                    # Rechercher dans le titre
                    if "title" in metadata and query in metadata["title"].lower():
                        filtered_items.append(item)
                        continue

                    # Rechercher dans les tags
                    if "tags" in metadata and isinstance(metadata["tags"], list):
                        for tag in metadata["tags"]:
                            if query in tag.lower():
                                filtered_items.append(item)
                                break

            all_items = filtered_items

        # Filtrer par métadonnées
        if metadata_filters:
            filtered_items = []

            for item in all_items:
                if "metadata" not in item:
                    continue

                metadata = item["metadata"]
                match = True

                for key, value in metadata_filters.items():
                    if key not in metadata:
                        match = False
                        break

                    if isinstance(value, list) and isinstance(metadata[key], list):
                        # Vérifier si au moins un élément de value est dans metadata[key]
                        if not any(v in metadata[key] for v in value):
                            match = False
                            break
                    elif metadata[key] != value:
                        match = False
                        break

                if match:
                    filtered_items.append(item)

            all_items = filtered_items

        # Trier par date d'archivage (du plus récent au plus ancien)
        all_items.sort(key=lambda x: x["metadata"].get("archived_at", ""), reverse=True)

        # Appliquer la pagination
        return all_items[offset:offset + limit]

    def rotate_archives(self, max_age_days: int = 90, max_items: int = 1000,
                       backup_dir: Optional[str] = None) -> Dict[str, Any]:
        """
        Effectue une rotation des archives en déplaçant les archives anciennes vers un répertoire de sauvegarde
        ou en les supprimant.

        Args:
            max_age_days: Âge maximum des archives en jours (défaut: 90)
            max_items: Nombre maximum d'éléments à conserver (défaut: 1000)
            backup_dir: Répertoire de sauvegarde (optionnel, si None les archives sont supprimées)

        Returns:
            Statistiques sur la rotation (nombre d'éléments déplacés/supprimés, etc.)
        """
        # Récupérer tous les fichiers JSON dans le répertoire d'archivage principal
        json_files = glob.glob(os.path.join(self.archive_path, "*.json"))

        # Trier les fichiers par date de modification (du plus ancien au plus récent)
        json_files.sort(key=os.path.getmtime)

        # Calculer la date limite
        cutoff_date = datetime.now() - timedelta(days=max_age_days)
        cutoff_timestamp = cutoff_date.timestamp()

        # Statistiques
        stats = {
            "total_archives": len(json_files),
            "moved_count": 0,
            "deleted_count": 0,
            "error_count": 0,
            "kept_count": 0
        }

        # Si nous avons plus d'éléments que le maximum autorisé, traiter les plus anciens
        if len(json_files) > max_items:
            files_to_process = json_files[:len(json_files) - max_items]

            # Créer le répertoire de sauvegarde si nécessaire
            if backup_dir:
                os.makedirs(backup_dir, exist_ok=True)

            for file_path in files_to_process:
                # Vérifier si le fichier est plus ancien que la date limite
                if os.path.getmtime(file_path) < cutoff_timestamp:
                    try:
                        if backup_dir:
                            # Déplacer le fichier vers le répertoire de sauvegarde
                            backup_path = os.path.join(backup_dir, os.path.basename(file_path))
                            shutil.move(file_path, backup_path)
                            stats["moved_count"] += 1
                        else:
                            # Supprimer le fichier
                            os.remove(file_path)
                            stats["deleted_count"] += 1

                        # Récupérer l'ID de l'élément
                        item_id = os.path.splitext(os.path.basename(file_path))[0]

                        # Supprimer également les copies dans les sous-répertoires thématiques
                        for theme_dir in os.listdir(self.archive_path):
                            theme_path = os.path.join(self.archive_path, theme_dir)
                            if os.path.isdir(theme_path):
                                theme_file = os.path.join(theme_path, f"{item_id}.json")
                                if os.path.exists(theme_file):
                                    os.remove(theme_file)
                    except Exception as e:
                        print(f"Erreur lors de la rotation de l'archive {file_path}: {str(e)}")
                        stats["error_count"] += 1
                else:
                    stats["kept_count"] += 1
        else:
            stats["kept_count"] = len(json_files)

        return stats

    def delete_items_by_selection(self, selection_method: str, selection_params: Dict[str, Any],
                             permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]:
        """
        Supprime des éléments selon une méthode de sélection spécifiée.

        Args:
            selection_method: Méthode de sélection à utiliser
            selection_params: Paramètres pour la méthode de sélection
            permanent: Si True, supprime définitivement les éléments sans les archiver
            reason: Raison de la suppression/archivage (optionnel)

        Returns:
            Statistiques sur l'opération (nombre d'éléments supprimés, etc.)
        """
        # Sélectionner les éléments selon la méthode spécifiée
        selected_ids = self._select_items(selection_method, selection_params)

        # Statistiques
        stats = {
            "total_selected": len(selected_ids),
            "deleted_count": 0,
            "error_count": 0,
            "skipped_count": 0
        }

        # Supprimer chaque élément
        for item_id in selected_ids:
            try:
                if self.delete_item(item_id, permanent, reason):
                    stats["deleted_count"] += 1
                else:
                    stats["skipped_count"] += 1
            except Exception as e:
                print(f"Erreur lors de la suppression de l'élément {item_id}: {str(e)}")
                stats["error_count"] += 1

        return stats

    def archive_items_by_selection(self, selection_method: str, selection_params: Dict[str, Any],
                                 reason: Optional[str] = None) -> Dict[str, Any]:
        """
        Archive des éléments selon une méthode de sélection spécifiée.

        Args:
            selection_method: Méthode de sélection à utiliser
            selection_params: Paramètres pour la méthode de sélection
            reason: Raison de l'archivage (optionnel)

        Returns:
            Statistiques sur l'opération (nombre d'éléments archivés, etc.)
        """
        # Sélectionner les éléments selon la méthode spécifiée
        selected_ids = self._select_items(selection_method, selection_params)

        # Statistiques
        stats = {
            "total_selected": len(selected_ids),
            "archived_count": 0,
            "error_count": 0,
            "skipped_count": 0
        }

        # Archiver chaque élément
        for item_id in selected_ids:
            try:
                if self.archive_item(item_id, reason):
                    stats["archived_count"] += 1
                else:
                    stats["skipped_count"] += 1
            except Exception as e:
                print(f"Erreur lors de l'archivage de l'élément {item_id}: {str(e)}")
                stats["error_count"] += 1

        return stats

    def delete_items_by_theme_hierarchy(self, theme: str, include_subthemes: bool = True,
                                  permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]:
        """
        Supprime des éléments selon une hiérarchie thématique.

        Args:
            theme: Thème principal
            include_subthemes: Si True, inclut les sous-thèmes
            permanent: Si True, supprime définitivement les éléments sans les archiver
            reason: Raison de la suppression/archivage (optionnel)

        Returns:
            Statistiques sur l'opération (nombre d'éléments supprimés, etc.)
        """
        # Sélectionner les éléments selon la hiérarchie thématique
        selected_ids = self.selector.select_by_theme_hierarchy(theme, include_subthemes)

        # Statistiques
        stats = {
            "total_selected": len(selected_ids),
            "deleted_count": 0,
            "error_count": 0,
            "skipped_count": 0,
            "theme": theme,
            "include_subthemes": include_subthemes
        }

        # Supprimer chaque élément
        for item_id in selected_ids:
            try:
                if self.delete_item(item_id, permanent, reason or f"Suppression hiérarchique du thème '{theme}'"):
                    stats["deleted_count"] += 1
                else:
                    stats["skipped_count"] += 1
            except Exception as e:
                print(f"Erreur lors de la suppression de l'élément {item_id}: {str(e)}")
                stats["error_count"] += 1

        return stats

    def delete_items_by_theme_weight(self, theme: str, min_weight: float = 0.5,
                                   permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]:
        """
        Supprime des éléments selon le poids d'un thème.

        Args:
            theme: Thème à rechercher
            min_weight: Poids minimum du thème (0.0 à 1.0)
            permanent: Si True, supprime définitivement les éléments sans les archiver
            reason: Raison de la suppression/archivage (optionnel)

        Returns:
            Statistiques sur l'opération (nombre d'éléments supprimés, etc.)
        """
        # Sélectionner les éléments selon le poids du thème
        selected_ids = self.selector.select_by_theme_weight(theme, min_weight)

        # Statistiques
        stats = {
            "total_selected": len(selected_ids),
            "deleted_count": 0,
            "error_count": 0,
            "skipped_count": 0,
            "theme": theme,
            "min_weight": min_weight
        }

        # Supprimer chaque élément
        for item_id in selected_ids:
            try:
                if self.delete_item(item_id, permanent, reason or f"Suppression par poids du thème '{theme}' (min: {min_weight})"):
                    stats["deleted_count"] += 1
                else:
                    stats["skipped_count"] += 1
            except Exception as e:
                print(f"Erreur lors de la suppression de l'élément {item_id}: {str(e)}")
                stats["error_count"] += 1

        return stats

    def delete_items_by_theme_exclusivity(self, theme: str, exclusivity_threshold: float = 0.8,
                                        permanent: bool = False, reason: Optional[str] = None) -> Dict[str, Any]:
        """
        Supprime des éléments selon l'exclusivité d'un thème.

        Args:
            theme: Thème principal
            exclusivity_threshold: Seuil d'exclusivité (0.0 à 1.0)
            permanent: Si True, supprime définitivement les éléments sans les archiver
            reason: Raison de la suppression/archivage (optionnel)

        Returns:
            Statistiques sur l'opération (nombre d'éléments supprimés, etc.)
        """
        # Sélectionner les éléments selon l'exclusivité du thème
        selected_ids = self.selector.select_by_theme_exclusivity(theme, exclusivity_threshold)

        # Statistiques
        stats = {
            "total_selected": len(selected_ids),
            "deleted_count": 0,
            "error_count": 0,
            "skipped_count": 0,
            "theme": theme,
            "exclusivity_threshold": exclusivity_threshold
        }

        # Supprimer chaque élément
        for item_id in selected_ids:
            try:
                if self.delete_item(item_id, permanent, reason or f"Suppression par exclusivité du thème '{theme}' (seuil: {exclusivity_threshold})"):
                    stats["deleted_count"] += 1
                else:
                    stats["skipped_count"] += 1
            except Exception as e:
                print(f"Erreur lors de la suppression de l'élément {item_id}: {str(e)}")
                stats["error_count"] += 1

        return stats

    def _select_items(self, selection_method: str, selection_params: Dict[str, Any]) -> List[str]:
        """
        Sélectionne des éléments selon une méthode spécifiée.

        Args:
            selection_method: Méthode de sélection à utiliser
            selection_params: Paramètres pour la méthode de sélection

        Returns:
            Liste des identifiants des éléments sélectionnés
        """
        if selection_method == "by_id":
            return self.selector.select_by_id(selection_params.get("item_id", ""))

        elif selection_method == "by_ids":
            return self.selector.select_by_ids(selection_params.get("item_ids", []))

        elif selection_method == "by_theme":
            return self.selector.select_by_theme(selection_params.get("theme", ""))

        elif selection_method == "by_themes":
            return self.selector.select_by_themes(selection_params.get("themes", []))

        elif selection_method == "by_theme_hierarchy":
            return self.selector.select_by_theme_hierarchy(
                selection_params.get("theme", ""),
                selection_params.get("include_subthemes", True)
            )

        elif selection_method == "by_theme_weight":
            return self.selector.select_by_theme_weight(
                selection_params.get("theme", ""),
                selection_params.get("min_weight", 0.5)
            )

        elif selection_method == "by_theme_exclusivity":
            return self.selector.select_by_theme_exclusivity(
                selection_params.get("theme", ""),
                selection_params.get("exclusivity_threshold", 0.8)
            )

        elif selection_method == "by_theme_overlap":
            return self.selector.select_by_theme_overlap(
                selection_params.get("themes", []),
                selection_params.get("min_overlap", 2)
            )

        elif selection_method == "by_metadata":
            return self.selector.select_by_metadata(selection_params.get("metadata_filter", {}))

        elif selection_method == "by_content":
            return self.selector.select_by_content(
                selection_params.get("content_filter", ""),
                selection_params.get("case_sensitive", False)
            )

        elif selection_method == "by_regex":
            return self.selector.select_by_regex(
                selection_params.get("pattern", ""),
                selection_params.get("field", "content")
            )

        elif selection_method == "by_date_range":
            start_date = None
            end_date = None

            if "start_date" in selection_params:
                start_date_str = selection_params["start_date"]
                if isinstance(start_date_str, str):
                    start_date = datetime.fromisoformat(start_date_str)

            if "end_date" in selection_params:
                end_date_str = selection_params["end_date"]
                if isinstance(end_date_str, str):
                    end_date = datetime.fromisoformat(end_date_str)

            return self.selector.select_by_date_range(
                start_date,
                end_date,
                selection_params.get("date_field", "created_at")
            )

        elif selection_method == "combine":
            # Récupérer les sélections individuelles
            selections = []
            for sub_selection in selection_params.get("selections", []):
                sub_method = sub_selection.get("method", "")
                sub_params = sub_selection.get("params", {})
                selected_ids = self._select_items(sub_method, sub_params)
                selections.append(selected_ids)

            # Combiner les sélections
            return self.selector.combine_selections(
                selections,
                selection_params.get("mode", "union")
            )

        else:
            raise ValueError(f"Méthode de sélection non supportée: {selection_method}")

    def get_archive_statistics(self) -> Dict[str, Any]:
        """
        Récupère des statistiques sur les archives.

        Returns:
            Statistiques sur les archives (nombre d'éléments, taille, etc.)
        """
        # Récupérer tous les fichiers JSON dans le répertoire d'archivage principal
        json_files = glob.glob(os.path.join(self.archive_path, "*.json"))

        # Statistiques de base
        stats = {
            "total_items": len(json_files),
            "total_size_bytes": 0,
            "oldest_archive": None,
            "newest_archive": None,
            "themes": {},
            "archive_reasons": {},
            "archive_dates": {
                "last_7_days": 0,
                "last_30_days": 0,
                "last_90_days": 0,
                "older": 0
            }
        }

        # Dates limites
        now = datetime.now()
        days_7 = now - timedelta(days=7)
        days_30 = now - timedelta(days=30)
        days_90 = now - timedelta(days=90)

        # Parcourir les fichiers
        oldest_time = float('inf')
        newest_time = 0

        for file_path in json_files:
            # Taille du fichier
            file_size = os.path.getsize(file_path)
            stats["total_size_bytes"] += file_size

            # Date de modification
            mtime = os.path.getmtime(file_path)

            if mtime < oldest_time:
                oldest_time = mtime
                stats["oldest_archive"] = datetime.fromtimestamp(mtime).isoformat()

            if mtime > newest_time:
                newest_time = mtime
                stats["newest_archive"] = datetime.fromtimestamp(mtime).isoformat()

            # Catégoriser par date
            archive_date = datetime.fromtimestamp(mtime)
            if archive_date > days_7:
                stats["archive_dates"]["last_7_days"] += 1
            elif archive_date > days_30:
                stats["archive_dates"]["last_30_days"] += 1
            elif archive_date > days_90:
                stats["archive_dates"]["last_90_days"] += 1
            else:
                stats["archive_dates"]["older"] += 1

            # Analyser le contenu du fichier
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    item = json.load(f)

                    # Thèmes
                    if "metadata" in item and "themes" in item["metadata"]:
                        themes = item["metadata"]["themes"]
                        for theme in themes.keys():
                            if theme in stats["themes"]:
                                stats["themes"][theme] += 1
                            else:
                                stats["themes"][theme] = 1

                    # Raisons d'archivage
                    if "metadata" in item and "archive_reason" in item["metadata"]:
                        reason = item["metadata"]["archive_reason"]
                        if reason in stats["archive_reasons"]:
                            stats["archive_reasons"][reason] += 1
                        else:
                            stats["archive_reasons"][reason] = 1
            except Exception as e:
                print(f"Erreur lors de l'analyse du fichier {file_path}: {str(e)}")

        # Convertir la taille en formats lisibles
        stats["total_size_mb"] = round(stats["total_size_bytes"] / (1024 * 1024), 2)

        # Trier les thèmes et raisons par fréquence
        stats["themes"] = dict(sorted(stats["themes"].items(), key=lambda x: x[1], reverse=True))
        stats["archive_reasons"] = dict(sorted(stats["archive_reasons"].items(), key=lambda x: x[1], reverse=True))

        return stats

    def _archive_item(self, item: Dict[str, Any], reason: Optional[str] = None) -> None:
        """
        Archive un élément.

        Args:
            item: Élément à archiver
            reason: Raison de l'archivage (optionnel)
        """
        item_id = item["id"]

        # Créer une copie profonde de l'élément pour ne pas modifier l'original
        archived_item = copy.deepcopy(item)

        # Ajouter les métadonnées d'archivage
        now = datetime.now().isoformat()

        if "metadata" not in archived_item:
            archived_item["metadata"] = {}

        archived_item["metadata"]["archived_at"] = now
        archived_item["metadata"]["archive_status"] = "archived"

        if reason:
            archived_item["metadata"]["archive_reason"] = reason

        # Ajouter l'historique d'archivage si ce n'est pas le premier archivage
        if "archive_history" not in archived_item["metadata"]:
            archived_item["metadata"]["archive_history"] = []

        # Ajouter l'entrée d'historique
        history_entry = {
            "action": "archived",
            "timestamp": now
        }

        if reason:
            history_entry["reason"] = reason

        archived_item["metadata"]["archive_history"].append(history_entry)

        # Créer des sous-répertoires thématiques dans l'archive si nécessaire
        themes = archived_item["metadata"].get("themes", {})

        # Sauvegarder l'élément dans le répertoire d'archivage principal
        archive_path = os.path.join(self.archive_path, f"{item_id}.json")
        with open(archive_path, 'w', encoding='utf-8') as f:
            json.dump(archived_item, f, ensure_ascii=False, indent=2)

        # Sauvegarder l'élément dans les sous-répertoires thématiques de l'archive
        for theme in themes.keys():
            # Créer le répertoire thématique s'il n'existe pas
            theme_dir = os.path.join(self.archive_path, theme)
            os.makedirs(theme_dir, exist_ok=True)

            # Sauvegarder l'élément dans le répertoire thématique
            theme_path = os.path.join(theme_dir, f"{item_id}.json")
            with open(theme_path, 'w', encoding='utf-8') as f:
                json.dump(archived_item, f, ensure_ascii=False, indent=2)
