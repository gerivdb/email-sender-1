#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de gestion des versions pour le système CRUD thématique.

Ce module fournit des fonctionnalités pour gérer les versions des éléments
par thème, permettant de suivre l'historique des modifications et de restaurer
des versions antérieures.
"""

import os
import json
import glob
import shutil
import copy
import time
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple
from pathlib import Path

class ThematicVersionControl:
    """Classe pour la gestion des versions des éléments par thème."""

    def __init__(self, storage_path: str, versions_path: Optional[str] = None):
        """
        Initialise le gestionnaire de versions thématique.

        Args:
            storage_path: Chemin vers le répertoire de stockage des données
            versions_path: Chemin vers le répertoire de stockage des versions (optionnel)
        """
        self.storage_path = storage_path

        # Utiliser un sous-répertoire "_versions" par défaut
        if versions_path is None:
            self.versions_path = os.path.join(storage_path, "_versions")
        else:
            self.versions_path = versions_path

        # Créer le répertoire de versions s'il n'existe pas
        os.makedirs(self.versions_path, exist_ok=True)

    def create_version(self, item: Dict[str, Any], version_tag: Optional[str] = None,
                      version_message: Optional[str] = None) -> Dict[str, Any]:
        """
        Crée une nouvelle version d'un élément.

        Args:
            item: Élément à versionner
            version_tag: Tag de version (optionnel)
            version_message: Message de version (optionnel)

        Returns:
            Métadonnées de la version créée
        """
        # Vérifier que l'élément a un ID
        if "id" not in item:
            raise ValueError("L'élément doit avoir un ID pour être versionné")

        item_id = item["id"]

        # Créer une copie profonde de l'élément pour ne pas modifier l'original
        versioned_item = copy.deepcopy(item)

        # Ajouter les métadonnées de version
        version_timestamp = datetime.now().isoformat()
        version_number = self._get_next_version_number(item_id)

        version_metadata = {
            "version_number": version_number,
            "version_timestamp": version_timestamp,
            "version_tag": version_tag,
            "version_message": version_message
        }

        # Mettre à jour les métadonnées de l'élément
        if "metadata" not in versioned_item:
            versioned_item["metadata"] = {}

        versioned_item["metadata"]["version"] = version_metadata

        # Créer le répertoire de versions pour cet élément
        item_versions_path = os.path.join(self.versions_path, item_id)
        os.makedirs(item_versions_path, exist_ok=True)

        # Sauvegarder la version
        version_path = os.path.join(item_versions_path, f"v{version_number}.json")
        with open(version_path, 'w', encoding='utf-8') as f:
            json.dump(versioned_item, f, ensure_ascii=False, indent=2)

        # Créer des versions thématiques si l'élément a des thèmes
        if "metadata" in item and "themes" in item["metadata"]:
            for theme in item["metadata"]["themes"]:
                theme_versions_path = os.path.join(self.versions_path, theme)
                os.makedirs(theme_versions_path, exist_ok=True)

                theme_item_versions_path = os.path.join(theme_versions_path, item_id)
                os.makedirs(theme_item_versions_path, exist_ok=True)

                theme_version_path = os.path.join(theme_item_versions_path, f"v{version_number}.json")
                with open(theme_version_path, 'w', encoding='utf-8') as f:
                    json.dump(versioned_item, f, ensure_ascii=False, indent=2)

        return version_metadata

    def get_versions(self, item_id: str) -> List[Dict[str, Any]]:
        """
        Récupère toutes les versions d'un élément.

        Args:
            item_id: Identifiant de l'élément

        Returns:
            Liste des métadonnées de versions, triées par numéro de version décroissant
        """
        item_versions_path = os.path.join(self.versions_path, item_id)

        if not os.path.exists(item_versions_path) or not os.path.isdir(item_versions_path):
            return []

        # Récupérer tous les fichiers de version
        version_files = glob.glob(os.path.join(item_versions_path, "v*.json"))

        versions = []
        for version_file in version_files:
            try:
                with open(version_file, 'r', encoding='utf-8') as f:
                    item = json.load(f)

                if "metadata" in item and "version" in item["metadata"]:
                    versions.append(item["metadata"]["version"])
            except Exception as e:
                print(f"Erreur lors de la lecture de la version {version_file}: {str(e)}")

        # Trier les versions par numéro de version décroissant
        versions.sort(key=lambda v: v["version_number"], reverse=True)

        return versions

    def get_versions_by_theme(self, theme: str, item_id: Optional[str] = None) -> Dict[str, List[Dict[str, Any]]]:
        """
        Récupère les versions des éléments d'un thème.

        Args:
            theme: Thème des éléments
            item_id: Identifiant de l'élément (optionnel)

        Returns:
            Dictionnaire des versions par élément
        """
        theme_versions_path = os.path.join(self.versions_path, theme)

        if not os.path.exists(theme_versions_path) or not os.path.isdir(theme_versions_path):
            return {}

        versions_by_item = {}

        # Si un ID d'élément est spécifié, récupérer uniquement les versions de cet élément
        if item_id:
            theme_item_versions_path = os.path.join(theme_versions_path, item_id)

            if os.path.exists(theme_item_versions_path) and os.path.isdir(theme_item_versions_path):
                versions_by_item[item_id] = self._get_item_versions_from_path(theme_item_versions_path)
        else:
            # Récupérer tous les répertoires d'éléments dans le répertoire de versions du thème
            item_dirs = [d for d in os.listdir(theme_versions_path)
                        if os.path.isdir(os.path.join(theme_versions_path, d))]

            for item_dir in item_dirs:
                theme_item_versions_path = os.path.join(theme_versions_path, item_dir)
                versions_by_item[item_dir] = self._get_item_versions_from_path(theme_item_versions_path)

        return versions_by_item

    def get_version(self, item_id: str, version_number: int) -> Optional[Dict[str, Any]]:
        """
        Récupère une version spécifique d'un élément.

        Args:
            item_id: Identifiant de l'élément
            version_number: Numéro de version

        Returns:
            Élément à la version spécifiée, ou None si la version n'existe pas
        """
        item_versions_path = os.path.join(self.versions_path, item_id)
        version_path = os.path.join(item_versions_path, f"v{version_number}.json")

        if not os.path.exists(version_path):
            return None

        try:
            with open(version_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"Erreur lors de la lecture de la version {version_path}: {str(e)}")
            return None

    def restore_version(self, item_id: str, version_number: int,
                       storage_path: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """
        Restaure une version spécifique d'un élément.

        Args:
            item_id: Identifiant de l'élément
            version_number: Numéro de version
            storage_path: Chemin vers le répertoire de stockage (optionnel)

        Returns:
            Élément restauré, ou None si la restauration a échoué
        """
        # Récupérer la version spécifiée
        version = self.get_version(item_id, version_number)

        if version is None:
            return None

        # Utiliser le chemin de stockage spécifié ou le chemin par défaut
        if storage_path is None:
            storage_path = self.storage_path

        # Créer une copie de la version pour la restauration
        restored_item = copy.deepcopy(version)

        # Ajouter des métadonnées de restauration
        if "metadata" not in restored_item:
            restored_item["metadata"] = {}

        restored_item["metadata"]["restored_from_version"] = version_number
        restored_item["metadata"]["restored_at"] = datetime.now().isoformat()

        # Sauvegarder l'élément restauré dans le stockage principal
        item_path = os.path.join(storage_path, f"{item_id}.json")

        try:
            with open(item_path, 'w', encoding='utf-8') as f:
                json.dump(restored_item, f, ensure_ascii=False, indent=2)

            # Restaurer l'élément dans les répertoires thématiques
            if "metadata" in restored_item and "themes" in restored_item["metadata"]:
                for theme in restored_item["metadata"]["themes"]:
                    theme_dir = os.path.join(storage_path, theme)
                    os.makedirs(theme_dir, exist_ok=True)

                    theme_path = os.path.join(theme_dir, f"{item_id}.json")
                    with open(theme_path, 'w', encoding='utf-8') as f:
                        json.dump(restored_item, f, ensure_ascii=False, indent=2)

            # Créer une nouvelle version pour marquer la restauration
            self.create_version(restored_item,
                              version_tag="restored",
                              version_message=f"Restauré depuis la version {version_number}")

            return restored_item

        except Exception as e:
            print(f"Erreur lors de la restauration de la version {version_number} de l'élément {item_id}: {str(e)}")
            return None

    def compare_versions(self, item_id: str, version1: int, version2: int) -> Dict[str, Any]:
        """
        Compare deux versions d'un élément.

        Args:
            item_id: Identifiant de l'élément
            version1: Numéro de la première version
            version2: Numéro de la deuxième version

        Returns:
            Dictionnaire des différences entre les versions
        """
        # Récupérer les versions spécifiées
        item1 = self.get_version(item_id, version1)
        item2 = self.get_version(item_id, version2)

        if item1 is None or item2 is None:
            raise ValueError("Une ou plusieurs versions spécifiées n'existent pas")

        # Comparer les versions
        content1 = item1.get("content", "")
        content2 = item2.get("content", "")

        # Vérifier si le contenu a changé
        content_changed = content1 != content2

        # Comparer les métadonnées et les thèmes
        differences = {
            "content_changed": content_changed,
            "content_diff": {
                "old": content1,
                "new": content2
            } if content_changed else None,
            "metadata_changes": self._compare_metadata(item1.get("metadata", {}), item2.get("metadata", {})),
            "themes_changes": self._compare_themes(
                item1.get("metadata", {}).get("themes", {}),
                item2.get("metadata", {}).get("themes", {})
            )
        }

        return differences

    def _get_next_version_number(self, item_id: str) -> int:
        """
        Récupère le prochain numéro de version pour un élément.

        Args:
            item_id: Identifiant de l'élément

        Returns:
            Prochain numéro de version
        """
        versions = self.get_versions(item_id)

        if not versions:
            return 1

        return max(v["version_number"] for v in versions) + 1

    def _get_item_versions_from_path(self, path: str) -> List[Dict[str, Any]]:
        """
        Récupère les versions d'un élément à partir d'un chemin.

        Args:
            path: Chemin vers le répertoire de versions de l'élément

        Returns:
            Liste des métadonnées de versions, triées par numéro de version décroissant
        """
        # Récupérer tous les fichiers de version
        version_files = glob.glob(os.path.join(path, "v*.json"))

        versions = []
        for version_file in version_files:
            try:
                with open(version_file, 'r', encoding='utf-8') as f:
                    item = json.load(f)

                if "metadata" in item and "version" in item["metadata"]:
                    versions.append(item["metadata"]["version"])
            except Exception as e:
                print(f"Erreur lors de la lecture de la version {version_file}: {str(e)}")

        # Trier les versions par numéro de version décroissant
        versions.sort(key=lambda v: v["version_number"], reverse=True)

        return versions

    def _compare_metadata(self, metadata1: Dict[str, Any], metadata2: Dict[str, Any]) -> Dict[str, Any]:
        """
        Compare les métadonnées de deux versions.

        Args:
            metadata1: Métadonnées de la première version
            metadata2: Métadonnées de la deuxième version

        Returns:
            Dictionnaire des différences entre les métadonnées
        """
        changes = {}

        # Comparer les champs communs
        all_keys = set(metadata1.keys()) | set(metadata2.keys())

        for key in all_keys:
            if key == "themes" or key == "version":
                continue  # Traités séparément

            if key not in metadata1:
                changes[key] = {"type": "added", "value": metadata2[key]}
            elif key not in metadata2:
                changes[key] = {"type": "removed", "value": metadata1[key]}
            elif metadata1[key] != metadata2[key]:
                changes[key] = {
                    "type": "changed",
                    "old_value": metadata1[key],
                    "new_value": metadata2[key]
                }

        return changes

    def _compare_themes(self, themes1: Dict[str, float], themes2: Dict[str, float]) -> Dict[str, Any]:
        """
        Compare les thèmes de deux versions.

        Args:
            themes1: Thèmes de la première version
            themes2: Thèmes de la deuxième version

        Returns:
            Dictionnaire des différences entre les thèmes
        """
        changes = {}

        # Comparer les thèmes communs
        all_themes = set(themes1.keys()) | set(themes2.keys())

        for theme in all_themes:
            if theme not in themes1:
                changes[theme] = {"type": "added", "value": themes2[theme]}
            elif theme not in themes2:
                changes[theme] = {"type": "removed", "value": themes1[theme]}
            elif themes1[theme] != themes2[theme]:
                changes[theme] = {
                    "type": "changed",
                    "old_value": themes1[theme],
                    "new_value": themes2[theme]
                }

        return changes
