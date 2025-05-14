#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module pour le stockage des nœuds cognitifs.

Ce module contient les interfaces et implémentations pour les fournisseurs de stockage
des nœuds cognitifs.
"""

import os
import sys
import logging
import json
import time
import shutil
import traceback
import tempfile
from pathlib import Path
from typing import Any, Dict, List, Optional, Protocol, runtime_checkable, Set, Tuple

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.core.roadmap.node_storage")

@runtime_checkable
class NodeStorageProvider(Protocol):
    """
    Interface pour les fournisseurs de stockage des nœuds cognitifs.
    """

    def store_node(self, node_data: Dict[str, Any]) -> bool:
        """
        Stocke un nœud cognitif.

        Args:
            node_data (Dict[str, Any]): Données du nœud à stocker

        Returns:
            bool: True si le stockage a réussi, False sinon
        """
        ...

    def get_node(self, node_id: str) -> Optional[Dict[str, Any]]:
        """
        Récupère un nœud cognitif par son identifiant.

        Args:
            node_id (str): Identifiant du nœud

        Returns:
            Optional[Dict[str, Any]]: Données du nœud récupéré, ou None s'il n'existe pas
        """
        ...

    def delete_node(self, node_id: str) -> bool:
        """
        Supprime un nœud cognitif.

        Args:
            node_id (str): Identifiant du nœud

        Returns:
            bool: True si la suppression a réussi, False sinon
        """
        ...

    def list_nodes(self, filter_criteria: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        """
        Liste les nœuds cognitifs, éventuellement filtrés par critères.

        Args:
            filter_criteria (Optional[Dict[str, Any]], optional): Critères de filtrage. Par défaut None.

        Returns:
            List[Dict[str, Any]]: Liste des nœuds
        """
        ...

class FileNodeStorageProvider:
    """
    Fournisseur de stockage des nœuds cognitifs basé sur des fichiers.

    Ce fournisseur stocke les nœuds dans des fichiers JSON.
    """

    def __init__(self, storage_dir: str):
        """
        Initialise le fournisseur de stockage.

        Args:
            storage_dir (str): Répertoire de stockage des nœuds
        """
        self.storage_dir = storage_dir

        # Créer le répertoire de stockage s'il n'existe pas
        os.makedirs(storage_dir, exist_ok=True)

        logger.info(f"FileNodeStorageProvider initialisé avec le répertoire '{storage_dir}'")

    def _get_node_path(self, node_id: str) -> str:
        """
        Retourne le chemin du fichier pour un nœud.

        Args:
            node_id (str): Identifiant du nœud

        Returns:
            str: Chemin du fichier
        """
        return os.path.join(self.storage_dir, f"{node_id}.json")

    def store_node(self, node_data: Dict[str, Any]) -> bool:
        """
        Stocke un nœud dans un fichier JSON.

        Cette méthode utilise un fichier temporaire pour éviter la corruption des données
        en cas d'erreur pendant l'écriture.

        Args:
            node_data (Dict[str, Any]): Données du nœud à stocker

        Returns:
            bool: True si le stockage a réussi, False sinon
        """
        if not node_data:
            logger.error("Tentative de stockage de données vides")
            return False

        if "node_id" not in node_data:
            logger.error("Les données du nœud ne contiennent pas d'identifiant")
            return False

        node_id = node_data["node_id"]
        if not node_id:
            logger.error("L'identifiant du nœud est vide")
            return False

        node_path = self._get_node_path(node_id)

        # Créer le répertoire parent s'il n'existe pas
        os.makedirs(os.path.dirname(node_path), exist_ok=True)

        # Utiliser un fichier temporaire pour éviter la corruption des données
        try:
            # Créer un fichier temporaire dans le même répertoire
            temp_fd, temp_path = tempfile.mkstemp(
                prefix=f"{node_id}_",
                suffix=".json.tmp",
                dir=os.path.dirname(node_path)
            )

            # Écrire les données dans le fichier temporaire
            with os.fdopen(temp_fd, "w", encoding="utf-8") as f:
                json.dump(node_data, f, ensure_ascii=False, indent=2)

            # Créer une copie de sauvegarde si le fichier existe déjà
            if os.path.exists(node_path):
                backup_path = f"{node_path}.bak"
                try:
                    shutil.copy2(node_path, backup_path)
                    logger.debug(f"Sauvegarde du nœud '{node_id}' créée dans '{backup_path}'")
                except Exception as e:
                    logger.warning(f"Impossible de créer une sauvegarde du nœud '{node_id}': {e}")

            # Remplacer le fichier original par le fichier temporaire
            if os.path.exists(node_path):
                os.replace(temp_path, node_path)
            else:
                os.rename(temp_path, node_path)

            logger.info(f"Nœud '{node_id}' stocké dans '{node_path}'")
            return True

        except Exception as e:
            logger.error(f"Erreur lors du stockage du nœud '{node_id}': {e}")
            logger.debug(traceback.format_exc())

            # Essayer de nettoyer le fichier temporaire
            try:
                if 'temp_path' in locals() and os.path.exists(temp_path):
                    os.remove(temp_path)
            except Exception:
                pass

            return False

    def get_node(self, node_id: str) -> Optional[Dict[str, Any]]:
        """
        Récupère un nœud depuis un fichier JSON.

        Cette méthode essaie de récupérer le nœud depuis le fichier principal,
        et si cela échoue, essaie de le récupérer depuis la sauvegarde.

        Args:
            node_id (str): Identifiant du nœud

        Returns:
            Optional[Dict[str, Any]]: Données du nœud récupéré, ou None s'il n'existe pas
        """
        if not node_id:
            logger.error("Tentative de récupération d'un nœud avec un ID vide")
            return None

        node_path = self._get_node_path(node_id)
        backup_path = f"{node_path}.bak"

        # Vérifier si le fichier principal existe
        if not os.path.exists(node_path):
            # Vérifier si une sauvegarde existe
            if os.path.exists(backup_path):
                logger.warning(f"Nœud '{node_id}' non trouvé dans '{node_path}', tentative de récupération depuis la sauvegarde")
                node_path = backup_path
            else:
                logger.warning(f"Nœud '{node_id}' non trouvé dans '{node_path}' et aucune sauvegarde disponible")
                return None

        # Essayer de charger le fichier
        try:
            with open(node_path, "r", encoding="utf-8") as f:
                data = json.load(f)

            # Vérifier que les données contiennent un ID et qu'il correspond
            if "node_id" not in data:
                logger.error(f"Le fichier '{node_path}' ne contient pas d'identifiant de nœud")
                return None

            if data["node_id"] != node_id:
                logger.error(f"L'identifiant du nœud dans le fichier '{node_path}' ({data['node_id']}) ne correspond pas à l'identifiant demandé ({node_id})")
                return None

            # Si on a récupéré depuis la sauvegarde, restaurer le fichier principal
            if node_path == backup_path:
                try:
                    shutil.copy2(backup_path, self._get_node_path(node_id))
                    logger.info(f"Nœud '{node_id}' restauré depuis la sauvegarde")
                except Exception as e:
                    logger.warning(f"Impossible de restaurer le nœud '{node_id}' depuis la sauvegarde: {e}")

            logger.info(f"Nœud '{node_id}' récupéré depuis '{node_path}'")
            return data

        except json.JSONDecodeError as e:
            logger.error(f"Erreur de décodage JSON pour le nœud '{node_id}' dans '{node_path}': {e}")

            # Essayer de récupérer depuis la sauvegarde si on n'est pas déjà en train de le faire
            if node_path != backup_path and os.path.exists(backup_path):
                logger.info(f"Tentative de récupération du nœud '{node_id}' depuis la sauvegarde")
                try:
                    with open(backup_path, "r", encoding="utf-8") as f:
                        data = json.load(f)

                    # Restaurer le fichier principal
                    shutil.copy2(backup_path, self._get_node_path(node_id))
                    logger.info(f"Nœud '{node_id}' restauré depuis la sauvegarde")

                    return data
                except Exception as backup_e:
                    logger.error(f"Erreur lors de la récupération du nœud '{node_id}' depuis la sauvegarde: {backup_e}")

            return None

        except Exception as e:
            logger.error(f"Erreur lors de la récupération du nœud '{node_id}': {e}")
            logger.debug(traceback.format_exc())
            return None

    def delete_node(self, node_id: str) -> bool:
        """
        Supprime un nœud.

        Cette méthode supprime le fichier principal et sa sauvegarde.

        Args:
            node_id (str): Identifiant du nœud

        Returns:
            bool: True si la suppression a réussi, False sinon
        """
        if not node_id:
            logger.error("Tentative de suppression d'un nœud avec un ID vide")
            return False

        node_path = self._get_node_path(node_id)
        backup_path = f"{node_path}.bak"
        archive_dir = os.path.join(self.storage_dir, "archive")

        # Vérifier si le fichier existe
        if not os.path.exists(node_path):
            logger.warning(f"Nœud '{node_id}' non trouvé dans '{node_path}' pour la suppression")

            # Vérifier si une sauvegarde existe
            if os.path.exists(backup_path):
                logger.warning(f"Sauvegarde du nœud '{node_id}' trouvée, suppression de la sauvegarde")
                try:
                    os.remove(backup_path)
                    return True
                except Exception as e:
                    logger.error(f"Erreur lors de la suppression de la sauvegarde du nœud '{node_id}': {e}")
                    return False

            return False

        try:
            # Créer un répertoire d'archive si nécessaire
            os.makedirs(archive_dir, exist_ok=True)

            # Déplacer le fichier dans l'archive au lieu de le supprimer
            archive_path = os.path.join(archive_dir, f"{node_id}_{int(time.time())}.json")

            try:
                # Déplacer le fichier dans l'archive
                shutil.move(node_path, archive_path)
                logger.info(f"Nœud '{node_id}' archivé dans '{archive_path}'")
            except Exception as e:
                # Si le déplacement échoue, supprimer le fichier
                logger.warning(f"Impossible d'archiver le nœud '{node_id}', suppression directe: {e}")
                os.remove(node_path)

            # Supprimer la sauvegarde si elle existe
            if os.path.exists(backup_path):
                try:
                    os.remove(backup_path)
                    logger.debug(f"Sauvegarde du nœud '{node_id}' supprimée")
                except Exception as e:
                    logger.warning(f"Erreur lors de la suppression de la sauvegarde du nœud '{node_id}': {e}")

            logger.info(f"Nœud '{node_id}' supprimé avec succès")
            return True

        except Exception as e:
            logger.error(f"Erreur lors de la suppression du nœud '{node_id}': {e}")
            logger.debug(traceback.format_exc())
            return False

    def list_nodes(self, filter_criteria: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        """
        Liste les nœuds, éventuellement filtrés par critères.

        Args:
            filter_criteria (Optional[Dict[str, Any]], optional): Critères de filtrage. Par défaut None.

        Returns:
            List[Dict[str, Any]]: Liste des nœuds
        """
        # Lister tous les fichiers JSON dans le répertoire de stockage
        node_files = [f for f in os.listdir(self.storage_dir) if f.endswith(".json")]

        # Charger tous les nœuds
        nodes = []
        for node_file in node_files:
            node_id = os.path.splitext(node_file)[0]
            node_data = self.get_node(node_id)
            if node_data:
                nodes.append(node_data)

        # Appliquer le filtre si fourni
        if filter_criteria:
            nodes = self._filter_nodes(nodes, filter_criteria)

        return nodes

    def _filter_nodes(self, nodes: List[Dict[str, Any]], filter_criteria: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Filtre les nœuds selon des critères.

        Args:
            nodes (List[Dict[str, Any]]): Liste des nœuds à filtrer
            filter_criteria (Dict[str, Any]): Critères de filtrage

        Returns:
            List[Dict[str, Any]]: Liste des nœuds filtrés
        """
        filtered_nodes = []
        for node in nodes:
            if self._match_filter(node, filter_criteria):
                filtered_nodes.append(node)
        return filtered_nodes

    def _match_filter(self, node: Dict[str, Any], filter_criteria: Dict[str, Any]) -> bool:
        """
        Vérifie si un nœud correspond aux critères de filtrage.

        Args:
            node (Dict[str, Any]): Nœud à vérifier
            filter_criteria (Dict[str, Any]): Critères de filtrage

        Returns:
            bool: True si le nœud correspond aux critères, False sinon
        """
        for key, value in filter_criteria.items():
            # Gestion des clés imbriquées (ex: "metadata.type")
            if "." in key:
                parts = key.split(".")
                node_value = node
                for part in parts:
                    if part not in node_value:
                        return False
                    node_value = node_value[part]

                if node_value != value:
                    return False
            elif key not in node:
                return False
            elif isinstance(value, dict) and isinstance(node[key], dict):
                # Récursion pour les dictionnaires imbriqués
                if not self._match_filter(node[key], value):
                    return False
            elif node[key] != value:
                return False

        return True

    def check_integrity(self, repair: bool = False) -> Tuple[int, int, int]:
        """
        Vérifie l'intégrité des données stockées.

        Cette méthode parcourt tous les fichiers de nœuds et vérifie leur intégrité.
        Si repair=True, elle tente de réparer les fichiers corrompus en utilisant les sauvegardes.

        Args:
            repair (bool, optional): Si True, tente de réparer les fichiers corrompus. Par défaut False.

        Returns:
            Tuple[int, int, int]: (nombre de fichiers vérifiés, nombre de fichiers corrompus, nombre de fichiers réparés)
        """
        # Statistiques
        checked = 0
        corrupted = 0
        repaired = 0

        # Lister tous les fichiers JSON dans le répertoire de stockage
        try:
            node_files = [f for f in os.listdir(self.storage_dir) if f.endswith(".json") and not f.endswith(".bak")]
        except Exception as e:
            logger.error(f"Erreur lors de la liste des fichiers dans '{self.storage_dir}': {e}")
            return checked, corrupted, repaired

        logger.info(f"Vérification de l'intégrité de {len(node_files)} fichiers dans '{self.storage_dir}'")

        # Vérifier chaque fichier
        for node_file in node_files:
            node_id = os.path.splitext(node_file)[0]
            node_path = self._get_node_path(node_id)
            backup_path = f"{node_path}.bak"

            checked += 1

            # Vérifier si le fichier est lisible et contient des données JSON valides
            try:
                with open(node_path, "r", encoding="utf-8") as f:
                    data = json.load(f)

                # Vérifier que les données contiennent un ID et qu'il correspond
                if "node_id" not in data:
                    logger.error(f"Le fichier '{node_path}' ne contient pas d'identifiant de nœud")
                    corrupted += 1
                    continue

                if data["node_id"] != node_id:
                    logger.error(f"L'identifiant du nœud dans le fichier '{node_path}' ({data['node_id']}) ne correspond pas à l'identifiant du fichier ({node_id})")
                    corrupted += 1
                    continue

                # Vérifier les champs obligatoires
                required_fields = ["name", "level", "level_value"]
                missing_fields = [field for field in required_fields if field not in data]

                if missing_fields:
                    logger.error(f"Le fichier '{node_path}' ne contient pas les champs obligatoires: {', '.join(missing_fields)}")
                    corrupted += 1
                    continue

                logger.debug(f"Fichier '{node_path}' vérifié avec succès")

            except json.JSONDecodeError as e:
                logger.error(f"Erreur de décodage JSON pour le fichier '{node_path}': {e}")
                corrupted += 1

                # Tenter de réparer si demandé
                if repair and os.path.exists(backup_path):
                    try:
                        # Vérifier que la sauvegarde est valide
                        with open(backup_path, "r", encoding="utf-8") as f:
                            backup_data = json.load(f)

                        # Vérifier que la sauvegarde contient un ID et qu'il correspond
                        if "node_id" not in backup_data or backup_data["node_id"] != node_id:
                            logger.error(f"La sauvegarde '{backup_path}' est invalide")
                            continue

                        # Restaurer depuis la sauvegarde
                        shutil.copy2(backup_path, node_path)
                        logger.info(f"Fichier '{node_path}' réparé depuis la sauvegarde")
                        repaired += 1

                    except Exception as repair_e:
                        logger.error(f"Erreur lors de la réparation du fichier '{node_path}': {repair_e}")

            except Exception as e:
                logger.error(f"Erreur lors de la vérification du fichier '{node_path}': {e}")
                corrupted += 1

        # Afficher les statistiques
        logger.info(f"Vérification terminée: {checked} fichiers vérifiés, {corrupted} fichiers corrompus, {repaired} fichiers réparés")

        return checked, corrupted, repaired
