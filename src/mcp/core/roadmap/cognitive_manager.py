#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module pour la gestion de l'architecture cognitive des roadmaps.

Ce module contient les classes et fonctions pour gérer l'architecture cognitive
des roadmaps, notamment la création, la recherche et la navigation entre les nœuds.
"""

import logging
import traceback
from typing import Any, Dict, List, Optional, Set, Tuple

# Import local
from .cognitive_architecture import (
    CognitiveNode, Cosmos, Galaxy, StellarSystem,
    HierarchyLevel, NodeStatus
)
from .exceptions import (
    NodeNotFoundError, InvalidParentError, NodeHasChildrenError,
    StorageError, InvalidNodeDataError, CircularReferenceError
)

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.core.roadmap.cognitive_manager")

class CognitiveManager:
    """
    Gestionnaire de l'architecture cognitive des roadmaps.

    Cette classe gère la création, la recherche et la navigation entre les nœuds
    de l'architecture cognitive.
    """

    def __init__(self, storage_provider=None):
        """
        Initialise le gestionnaire de l'architecture cognitive.

        Args:
            storage_provider: Fournisseur de stockage pour les nœuds
        """
        self.storage_provider = storage_provider
        self.nodes = {}  # Stockage en mémoire par défaut
        logger.info("CognitiveManager initialisé")

    def create_cosmos(
        self,
        name: str,
        description: str = "",
        metadata: Optional[Dict[str, Any]] = None,
        node_id: Optional[str] = None
    ) -> str:
        """
        Crée un nouveau COSMOS.

        Args:
            name (str): Nom du COSMOS
            description (str, optional): Description du COSMOS. Par défaut "".
            metadata (Optional[Dict[str, Any]], optional): Métadonnées du COSMOS. Par défaut None.
            node_id (Optional[str], optional): Identifiant du COSMOS. Si None, un UUID est généré.

        Returns:
            str: Identifiant du COSMOS créé
        """
        # Créer un nouveau COSMOS
        cosmos = Cosmos(
            name=name,
            description=description,
            metadata=metadata,
            node_id=node_id
        )

        # Stocker le COSMOS
        self._store_node(cosmos)

        logger.info(f"COSMOS '{name}' (ID: {cosmos.node_id}) créé")
        return cosmos.node_id

    def create_galaxy(
        self,
        name: str,
        cosmos_id: str,
        description: str = "",
        metadata: Optional[Dict[str, Any]] = None,
        node_id: Optional[str] = None
    ) -> str:
        """
        Crée une nouvelle GALAXIE.

        Args:
            name (str): Nom de la GALAXIE
            cosmos_id (str): Identifiant du COSMOS parent
            description (str, optional): Description de la GALAXIE. Par défaut "".
            metadata (Optional[Dict[str, Any]], optional): Métadonnées de la GALAXIE. Par défaut None.
            node_id (Optional[str], optional): Identifiant de la GALAXIE. Si None, un UUID est généré.

        Returns:
            str: Identifiant de la GALAXIE créée

        Raises:
            NodeNotFoundError: Si le COSMOS parent n'existe pas
            InvalidParentError: Si le parent n'est pas un COSMOS
            StorageError: Si une erreur survient lors du stockage
        """
        # Vérifier les paramètres obligatoires
        if not name:
            raise ValueError("Le nom de la GALAXIE ne peut pas être vide")

        if not cosmos_id:
            raise ValueError("L'identifiant du COSMOS parent ne peut pas être vide")

        # Vérifier que le COSMOS parent existe
        cosmos = self.get_node(cosmos_id)
        if not cosmos:
            raise NodeNotFoundError(cosmos_id, f"Le COSMOS parent '{cosmos_id}' n'existe pas")

        # Vérifier que le parent est bien un COSMOS
        if cosmos.level != HierarchyLevel.COSMOS:
            raise InvalidParentError(cosmos_id, "COSMOS", cosmos.level.name)

        try:
            # Créer une nouvelle GALAXIE
            galaxy = Galaxy(
                name=name,
                cosmos_id=cosmos_id,
                description=description,
                metadata=metadata,
                node_id=node_id
            )

            # Stocker la GALAXIE
            self._store_node(galaxy)

            # Mettre à jour le COSMOS parent
            cosmos.add_child(galaxy.node_id)
            self._store_node(cosmos)

            logger.info(f"GALAXIE '{name}' (ID: {galaxy.node_id}) créée dans le COSMOS '{cosmos.name}' (ID: {cosmos_id})")
            return galaxy.node_id

        except Exception as e:
            logger.error(f"Erreur lors de la création de la GALAXIE '{name}' dans le COSMOS '{cosmos_id}': {e}")
            logger.debug(traceback.format_exc())
            if isinstance(e, (NodeNotFoundError, InvalidParentError, StorageError)):
                raise
            raise StorageError(node_id or "nouvelle galaxie", "création", e)

    def create_stellar_system(
        self,
        name: str,
        galaxy_id: str,
        description: str = "",
        metadata: Optional[Dict[str, Any]] = None,
        node_id: Optional[str] = None
    ) -> str:
        """
        Crée un nouveau SYSTEME STELLAIRE.

        Args:
            name (str): Nom du SYSTEME STELLAIRE
            galaxy_id (str): Identifiant de la GALAXIE parente
            description (str, optional): Description du SYSTEME STELLAIRE. Par défaut "".
            metadata (Optional[Dict[str, Any]], optional): Métadonnées du SYSTEME STELLAIRE. Par défaut None.
            node_id (Optional[str], optional): Identifiant du SYSTEME STELLAIRE. Si None, un UUID est généré.

        Returns:
            str: Identifiant du SYSTEME STELLAIRE créé

        Raises:
            NodeNotFoundError: Si la GALAXIE parente n'existe pas
            InvalidParentError: Si le parent n'est pas une GALAXIE
            StorageError: Si une erreur survient lors du stockage
        """
        # Vérifier les paramètres obligatoires
        if not name:
            raise ValueError("Le nom du SYSTEME STELLAIRE ne peut pas être vide")

        if not galaxy_id:
            raise ValueError("L'identifiant de la GALAXIE parente ne peut pas être vide")

        # Vérifier que la GALAXIE parente existe
        galaxy = self.get_node(galaxy_id)
        if not galaxy:
            raise NodeNotFoundError(galaxy_id, f"La GALAXIE parente '{galaxy_id}' n'existe pas")

        # Vérifier que le parent est bien une GALAXIE
        if galaxy.level != HierarchyLevel.GALAXIES:
            raise InvalidParentError(galaxy_id, "GALAXIE", galaxy.level.name)

        try:
            # Créer un nouveau SYSTEME STELLAIRE
            stellar_system = StellarSystem(
                name=name,
                galaxy_id=galaxy_id,
                description=description,
                metadata=metadata,
                node_id=node_id
            )

            # Stocker le SYSTEME STELLAIRE
            self._store_node(stellar_system)

            # Mettre à jour la GALAXIE parente
            galaxy.add_child(stellar_system.node_id)
            self._store_node(galaxy)

            logger.info(f"SYSTEME STELLAIRE '{name}' (ID: {stellar_system.node_id}) créé dans la GALAXIE '{galaxy.name}' (ID: {galaxy_id})")
            return stellar_system.node_id

        except Exception as e:
            logger.error(f"Erreur lors de la création du SYSTEME STELLAIRE '{name}' dans la GALAXIE '{galaxy_id}': {e}")
            logger.debug(traceback.format_exc())
            if isinstance(e, (NodeNotFoundError, InvalidParentError, StorageError)):
                raise
            raise StorageError(node_id or "nouveau système stellaire", "création", e)

    def get_node(self, node_id: str) -> Optional[CognitiveNode]:
        """
        Récupère un nœud par son identifiant.

        Args:
            node_id (str): Identifiant du nœud

        Returns:
            Optional[CognitiveNode]: Nœud récupéré, ou None s'il n'existe pas

        Raises:
            StorageError: Si une erreur survient lors de la récupération
        """
        if not node_id:
            logger.warning("Tentative de récupération d'un nœud avec un ID vide")
            return None

        # Vérifier d'abord dans le stockage en mémoire (cache)
        if node_id in self.nodes:
            return self.nodes[node_id]

        # Essayer de récupérer depuis le fournisseur de stockage
        if self.storage_provider:
            try:
                node_data = self.storage_provider.get_node(node_id)
                if node_data:
                    # Créer le nœud à partir des données
                    node = self._create_node_from_data(node_data)

                    # Mettre en cache le nœud
                    self.nodes[node_id] = node

                    return node
            except InvalidNodeDataError as e:
                # Erreur dans les données du nœud
                logger.error(f"Données invalides pour le nœud '{node_id}': {e}")
                raise
            except Exception as e:
                # Autre erreur lors de la récupération
                logger.error(f"Erreur lors de la récupération du nœud '{node_id}': {e}")
                logger.debug(traceback.format_exc())
                raise StorageError(node_id, "récupération", e)

        # Nœud non trouvé
        return None

    def update_node(
        self,
        node_id: str,
        name: Optional[str] = None,
        description: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        status: Optional[NodeStatus] = None
    ) -> bool:
        """
        Met à jour un nœud existant.

        Args:
            node_id (str): Identifiant du nœud
            name (Optional[str], optional): Nouveau nom. Par défaut None.
            description (Optional[str], optional): Nouvelle description. Par défaut None.
            metadata (Optional[Dict[str, Any]], optional): Nouvelles métadonnées. Par défaut None.
            status (Optional[NodeStatus], optional): Nouveau statut. Par défaut None.

        Returns:
            bool: True si la mise à jour a réussi, False sinon
        """
        # Récupérer le nœud
        node = self.get_node(node_id)
        if not node:
            logger.error(f"Nœud '{node_id}' non trouvé pour la mise à jour")
            return False

        # Mettre à jour les attributs si fournis
        if name is not None:
            node.name = name

        if description is not None:
            node.description = description

        if metadata is not None:
            node.update_metadata(metadata)

        if status is not None:
            node.update_status(status)

        # Stocker le nœud mis à jour
        self._store_node(node)

        logger.info(f"Nœud '{node_id}' mis à jour")
        return True

    def delete_node(self, node_id: str) -> bool:
        """
        Supprime un nœud.

        Args:
            node_id (str): Identifiant du nœud

        Returns:
            bool: True si la suppression a réussi, False sinon

        Raises:
            NodeNotFoundError: Si le nœud n'existe pas
            NodeHasChildrenError: Si le nœud a des enfants
            StorageError: Si une erreur survient lors de la suppression
        """
        if not node_id:
            raise ValueError("L'identifiant du nœud ne peut pas être vide")

        # Récupérer le nœud
        node = self.get_node(node_id)
        if not node:
            raise NodeNotFoundError(node_id)

        # Vérifier si le nœud a des enfants
        if node.children_ids:
            children_count = len(node.children_ids)
            raise NodeHasChildrenError(node_id, children_count)

        try:
            # Supprimer le nœud du parent
            if node.parent_id:
                parent = self.get_node(node.parent_id)
                if parent:
                    parent.remove_child(node_id)
                    self._store_node(parent)
                else:
                    logger.warning(f"Parent '{node.parent_id}' du nœud '{node_id}' non trouvé")

            # Supprimer le nœud
            if self.storage_provider:
                try:
                    success = self.storage_provider.delete_node(node_id)
                    if not success:
                        logger.warning(f"Échec de la suppression du nœud '{node_id}' via le fournisseur, fallback à la suppression en mémoire")
                except Exception as e:
                    logger.error(f"Erreur lors de la suppression du nœud '{node_id}' via le fournisseur: {e}")
                    logger.debug(traceback.format_exc())
                    raise StorageError(node_id, "suppression", e)

            # Supprimer du stockage en mémoire
            if node_id in self.nodes:
                del self.nodes[node_id]

            logger.info(f"Nœud '{node_id}' supprimé avec succès")
            return True

        except Exception as e:
            if isinstance(e, (NodeNotFoundError, NodeHasChildrenError, StorageError)):
                raise

            logger.error(f"Erreur inattendue lors de la suppression du nœud '{node_id}': {e}")
            logger.debug(traceback.format_exc())
            raise StorageError(node_id, "suppression", e)

    def get_children(self, node_id: str) -> List[CognitiveNode]:
        """
        Récupère les enfants d'un nœud.

        Args:
            node_id (str): Identifiant du nœud

        Returns:
            List[CognitiveNode]: Liste des enfants
        """
        # Récupérer le nœud
        node = self.get_node(node_id)
        if not node:
            logger.error(f"Nœud '{node_id}' non trouvé pour récupérer les enfants")
            return []

        # Récupérer les enfants
        children = []
        for child_id in node.children_ids:
            child = self.get_node(child_id)
            if child:
                children.append(child)

        return children

    def get_parent(self, node_id: str) -> Optional[CognitiveNode]:
        """
        Récupère le parent d'un nœud.

        Args:
            node_id (str): Identifiant du nœud

        Returns:
            Optional[CognitiveNode]: Parent du nœud, ou None s'il n'a pas de parent
        """
        # Récupérer le nœud
        node = self.get_node(node_id)
        if not node:
            logger.error(f"Nœud '{node_id}' non trouvé pour récupérer le parent")
            return None

        # Récupérer le parent
        if node.parent_id:
            return self.get_node(node.parent_id)

        return None

    def get_path(self, node_id: str) -> List[CognitiveNode]:
        """
        Récupère le chemin complet d'un nœud jusqu'à la racine.

        Args:
            node_id (str): Identifiant du nœud

        Returns:
            List[CognitiveNode]: Liste des nœuds du chemin, du plus haut niveau au plus bas

        Raises:
            NodeNotFoundError: Si le nœud n'existe pas
            CircularReferenceError: Si une référence circulaire est détectée
        """
        if not node_id:
            logger.warning("Tentative de récupération du chemin d'un nœud avec un ID vide")
            return []

        # Récupérer le nœud
        node = self.get_node(node_id)
        if not node:
            raise NodeNotFoundError(node_id, f"Nœud '{node_id}' non trouvé pour récupérer le chemin")

        # Construire le chemin
        path = [node]
        current = node
        visited = {node_id}  # Ensemble des nœuds déjà visités pour détecter les cycles

        while current.parent_id:
            # Vérifier s'il y a une référence circulaire
            if current.parent_id in visited:
                path_ids = [n.node_id for n in path]
                raise CircularReferenceError(current.node_id, current.parent_id, path_ids)

            parent = self.get_node(current.parent_id)
            if parent:
                path.insert(0, parent)
                visited.add(parent.node_id)
                current = parent
            else:
                logger.warning(f"Parent '{current.parent_id}' du nœud '{current.node_id}' non trouvé")
                break

        return path

    def check_consistency(self, repair: bool = False) -> Tuple[int, int, int]:
        """
        Vérifie la cohérence des relations parent-enfant.

        Cette méthode parcourt tous les nœuds et vérifie que:
        1. Chaque enfant référencé existe
        2. Chaque enfant a bien le nœud courant comme parent
        3. Chaque parent référencé existe
        4. Chaque parent a bien le nœud courant comme enfant

        Si repair=True, elle tente de réparer les incohérences.

        Args:
            repair (bool, optional): Si True, tente de réparer les incohérences. Par défaut False.

        Returns:
            Tuple[int, int, int]: (nombre de nœuds vérifiés, nombre d'incohérences trouvées, nombre d'incohérences réparées)
        """
        # Statistiques
        checked = 0
        inconsistencies = 0
        repaired = 0

        # Charger tous les nœuds
        all_nodes = {}

        # Si on a un fournisseur de stockage, charger tous les nœuds depuis le stockage
        if self.storage_provider:
            try:
                node_data_list = self.storage_provider.list_nodes()
                for node_data in node_data_list:
                    try:
                        node = self._create_node_from_data(node_data)
                        all_nodes[node.node_id] = node
                    except Exception as e:
                        logger.error(f"Erreur lors de la création du nœud à partir des données: {e}")
            except Exception as e:
                logger.error(f"Erreur lors de la liste des nœuds: {e}")

        # Ajouter les nœuds en mémoire
        for node_id, node in self.nodes.items():
            all_nodes[node_id] = node

        logger.info(f"Vérification de la cohérence de {len(all_nodes)} nœuds")

        # Vérifier chaque nœud
        for node_id, node in all_nodes.items():
            checked += 1

            # 1. Vérifier que chaque enfant référencé existe
            missing_children = []
            for child_id in node.children_ids:
                if child_id not in all_nodes:
                    logger.error(f"L'enfant '{child_id}' du nœud '{node_id}' n'existe pas")
                    inconsistencies += 1
                    missing_children.append(child_id)

            # Réparer les enfants manquants si demandé
            if repair and missing_children:
                for child_id in missing_children:
                    node.children_ids.remove(child_id)
                    logger.info(f"Enfant '{child_id}' supprimé des références du nœud '{node_id}'")
                    repaired += 1

                # Mettre à jour le nœud
                self._store_node(node)

            # 2. Vérifier que chaque enfant a bien le nœud courant comme parent
            for child_id in list(node.children_ids):  # Utiliser une copie pour pouvoir modifier pendant l'itération
                if child_id in all_nodes:
                    child = all_nodes[child_id]
                    if child.parent_id != node_id:
                        logger.error(f"L'enfant '{child_id}' du nœud '{node_id}' a un parent différent: '{child.parent_id}'")
                        inconsistencies += 1

                        # Réparer si demandé
                        if repair:
                            # Si l'enfant n'a pas de parent, lui attribuer le nœud courant
                            if not child.parent_id:
                                child.parent_id = node_id
                                logger.info(f"Parent '{node_id}' attribué au nœud '{child_id}'")
                                self._store_node(child)
                                repaired += 1
                            # Sinon, supprimer la référence à l'enfant
                            else:
                                node.children_ids.remove(child_id)
                                logger.info(f"Enfant '{child_id}' supprimé des références du nœud '{node_id}'")
                                self._store_node(node)
                                repaired += 1

            # 3. Vérifier que le parent référencé existe
            if node.parent_id and node.parent_id not in all_nodes:
                logger.error(f"Le parent '{node.parent_id}' du nœud '{node_id}' n'existe pas")
                inconsistencies += 1

                # Réparer si demandé
                if repair:
                    node.parent_id = None
                    logger.info(f"Référence au parent supprimée pour le nœud '{node_id}'")
                    self._store_node(node)
                    repaired += 1

            # 4. Vérifier que le parent a bien le nœud courant comme enfant
            if node.parent_id and node.parent_id in all_nodes:
                parent = all_nodes[node.parent_id]
                if node_id not in parent.children_ids:
                    logger.error(f"Le nœud '{node_id}' n'est pas référencé comme enfant par son parent '{node.parent_id}'")
                    inconsistencies += 1

                    # Réparer si demandé
                    if repair:
                        parent.add_child(node_id)
                        logger.info(f"Nœud '{node_id}' ajouté comme enfant du parent '{node.parent_id}'")
                        self._store_node(parent)
                        repaired += 1

        # Vérifier les références circulaires
        for node_id in all_nodes:
            try:
                self.get_path(node_id)
            except CircularReferenceError as e:
                logger.error(f"Référence circulaire détectée: {e}")
                inconsistencies += 1

                # Réparer si demandé
                if repair:
                    # Récupérer le nœud et son parent
                    node = all_nodes[e.node_id]

                    # Supprimer la référence au parent
                    node.parent_id = None
                    logger.info(f"Référence circulaire brisée pour le nœud '{e.node_id}'")
                    self._store_node(node)
                    repaired += 1
            except Exception as e:
                logger.error(f"Erreur lors de la vérification du chemin du nœud '{node_id}': {e}")

        # Afficher les statistiques
        logger.info(f"Vérification terminée: {checked} nœuds vérifiés, {inconsistencies} incohérences trouvées, {repaired} incohérences réparées")

        return checked, inconsistencies, repaired

    def _store_node(self, node: CognitiveNode) -> bool:
        """
        Stocke un nœud.

        Args:
            node (CognitiveNode): Nœud à stocker

        Returns:
            bool: True si le stockage a réussi, False sinon

        Raises:
            StorageError: Si une erreur survient lors du stockage
        """
        if node is None:
            raise ValueError("Impossible de stocker un nœud None")

        # Vérifier que le nœud a un ID
        if not node.node_id:
            raise InvalidNodeDataError(node.to_dict(), "node_id")

        # Vérifier que le nœud a un nom
        if not node.name:
            raise InvalidNodeDataError(node.to_dict(), "name")

        # Stocker dans le fournisseur de stockage
        if self.storage_provider:
            try:
                node_dict = node.to_dict()
                success = self.storage_provider.store_node(node_dict)
                if not success:
                    logger.warning(f"Échec du stockage du nœud '{node.node_id}' via le fournisseur, fallback au stockage en mémoire")
                    # Fallback au stockage en mémoire
                    self.nodes[node.node_id] = node
            except Exception as e:
                logger.error(f"Erreur lors du stockage du nœud '{node.node_id}': {e}")
                logger.debug(traceback.format_exc())
                # Fallback au stockage en mémoire
                self.nodes[node.node_id] = node
                # Propager l'erreur avec plus de contexte
                raise StorageError(node.node_id, "stockage", e)
        else:
            # Stockage en mémoire
            self.nodes[node.node_id] = node

        return True

    def _create_node_from_data(self, data: Dict[str, Any]) -> CognitiveNode:
        """
        Crée un nœud à partir de données.

        Args:
            data (Dict[str, Any]): Données du nœud

        Returns:
            CognitiveNode: Nœud créé

        Raises:
            InvalidNodeDataError: Si les données du nœud sont invalides
        """
        # Vérifier que les données contiennent les champs obligatoires
        if not data:
            raise InvalidNodeDataError({}, "données vides")

        # Vérifier que le nom est présent
        if "name" not in data:
            raise InvalidNodeDataError(data, "name")

        # Déterminer le niveau hiérarchique
        try:
            if "level" in data and isinstance(data["level"], str):
                level = HierarchyLevel[data["level"]]
            elif "level_value" in data and isinstance(data["level_value"], int):
                level = HierarchyLevel(data["level_value"])
            else:
                raise InvalidNodeDataError(data, "level ou level_value")
        except (KeyError, ValueError) as e:
            raise InvalidNodeDataError(data, "level invalide") from e

        # Déterminer le statut
        try:
            if "status" in data and isinstance(data["status"], str):
                status = NodeStatus[data["status"]]
            else:
                status = NodeStatus.PLANNED
        except (KeyError, ValueError) as e:
            logger.warning(f"Statut invalide dans les données du nœud, utilisation de PLANNED par défaut: {e}")
            status = NodeStatus.PLANNED

        try:
            if level == HierarchyLevel.COSMOS:
                # Créer un COSMOS
                node = Cosmos(
                    name=data["name"],
                    description=data.get("description", ""),
                    node_id=data.get("node_id"),
                    metadata=data.get("metadata", {}),
                    status=status
                )
            elif level == HierarchyLevel.GALAXIES:
                # Vérifier que le parent_id est présent pour une GALAXIE
                if "parent_id" not in data or not data["parent_id"]:
                    raise InvalidNodeDataError(data, "parent_id pour GALAXIE")

                # Créer une GALAXIE
                node = Galaxy(
                    name=data["name"],
                    cosmos_id=data["parent_id"],
                    description=data.get("description", ""),
                    node_id=data.get("node_id"),
                    metadata=data.get("metadata", {}),
                    status=status
                )
            elif level == HierarchyLevel.SYSTEMES:
                # Vérifier que le parent_id est présent pour un SYSTEME STELLAIRE
                if "parent_id" not in data or not data["parent_id"]:
                    raise InvalidNodeDataError(data, "parent_id pour SYSTEME STELLAIRE")

                # Créer un SYSTEME STELLAIRE
                node = StellarSystem(
                    name=data["name"],
                    galaxy_id=data["parent_id"],
                    description=data.get("description", ""),
                    node_id=data.get("node_id"),
                    metadata=data.get("metadata", {}),
                    status=status
                )
            else:
                # Créer un nœud générique
                node = CognitiveNode(
                    name=data["name"],
                    level=level,
                    description=data.get("description", ""),
                    node_id=data.get("node_id"),
                    metadata=data.get("metadata", {}),
                    status=status,
                    parent_id=data.get("parent_id")
                )

            # Ajouter les enfants
            if "children_ids" in data:
                if isinstance(data["children_ids"], list):
                    node.children_ids = set(data["children_ids"])
                else:
                    logger.warning(f"Format invalide pour children_ids, doit être une liste: {data['children_ids']}")

            return node

        except Exception as e:
            logger.error(f"Erreur lors de la création du nœud à partir des données: {e}")
            logger.debug(f"Données du nœud: {data}")
            logger.debug(traceback.format_exc())
            raise InvalidNodeDataError(data, str(e)) from e
