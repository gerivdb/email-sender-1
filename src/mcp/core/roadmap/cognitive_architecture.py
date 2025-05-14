#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module pour l'architecture cognitive des roadmaps.

Ce module contient les classes et fonctions pour implémenter l'architecture cognitive
des roadmaps, avec un modèle hiérarchique à 10 niveaux.
"""

import logging
import uuid
from datetime import datetime
from enum import Enum, auto
from typing import Any, Dict, Optional, Set

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.core.roadmap.cognitive_architecture")

class HierarchyLevel(Enum):
    """Énumération des niveaux hiérarchiques de l'architecture cognitive."""
    COSMOS = 1       # Niveau le plus élevé - Vision globale
    GALAXIES = 2     # Grands domaines ou thèmes
    SYSTEMES = 3     # Systèmes stellaires - Groupes de projets liés
    PLANETES = 4     # Projets individuels
    CONTINENTS = 5   # Grandes fonctionnalités ou modules
    REGIONS = 6      # Fonctionnalités spécifiques
    VILLES = 7       # Composants ou services
    QUARTIERS = 8    # Sous-composants
    RUES = 9         # Classes ou fonctions
    BATIMENTS = 10   # Éléments de base (variables, constantes, etc.)

class NodeStatus(Enum):
    """Énumération des statuts possibles pour un nœud."""
    PLANNED = auto()     # Planifié mais pas encore commencé
    IN_PROGRESS = auto() # En cours de développement
    COMPLETED = auto()   # Terminé
    BLOCKED = auto()     # Bloqué par une dépendance
    DEPRECATED = auto()  # Déprécié ou abandonné

class CognitiveNode:
    """
    Classe de base pour tous les nœuds de l'architecture cognitive.

    Un nœud représente un élément à n'importe quel niveau de la hiérarchie.
    """

    def __init__(
        self,
        name: str,
        level: HierarchyLevel,
        description: str = "",
        node_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        status: NodeStatus = NodeStatus.PLANNED,
        parent_id: Optional[str] = None
    ):
        """
        Initialise un nœud cognitif.

        Args:
            name (str): Nom du nœud
            level (HierarchyLevel): Niveau hiérarchique du nœud
            description (str, optional): Description du nœud. Par défaut "".
            node_id (Optional[str], optional): Identifiant du nœud. Si None, un UUID est généré.
            metadata (Optional[Dict[str, Any]], optional): Métadonnées du nœud. Par défaut None.
            status (NodeStatus, optional): Statut du nœud. Par défaut NodeStatus.PLANNED.
            parent_id (Optional[str], optional): Identifiant du nœud parent. Par défaut None.
        """
        self.name = name
        self.level = level
        self.description = description
        self.node_id = node_id or str(uuid.uuid4())
        self.metadata = metadata or {}
        self.status = status
        self.parent_id = parent_id
        self.children_ids: Set[str] = set()

        # Ajouter des métadonnées par défaut si elles n'existent pas
        if "created_at" not in self.metadata:
            self.metadata["created_at"] = datetime.now().isoformat()
        if "updated_at" not in self.metadata:
            self.metadata["updated_at"] = self.metadata["created_at"]

        logger.debug(f"Nœud '{self.name}' (ID: {self.node_id}) créé au niveau {self.level.name}")

    def to_dict(self) -> Dict[str, Any]:
        """
        Convertit le nœud en dictionnaire.

        Returns:
            Dict[str, Any]: Dictionnaire représentant le nœud
        """
        return {
            "node_id": self.node_id,
            "name": self.name,
            "level": self.level.name,
            "level_value": self.level.value,
            "description": self.description,
            "metadata": self.metadata,
            "status": self.status.name,
            "parent_id": self.parent_id,
            "children_ids": list(self.children_ids)
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "CognitiveNode":
        """
        Crée un nœud à partir d'un dictionnaire.

        Args:
            data (Dict[str, Any]): Dictionnaire représentant le nœud

        Returns:
            CognitiveNode: Instance de nœud
        """
        # Convertir le niveau et le statut de chaîne en énumération
        level = HierarchyLevel[data["level"]] if isinstance(data["level"], str) else HierarchyLevel(data["level_value"])
        status = NodeStatus[data["status"]] if "status" in data else NodeStatus.PLANNED

        # Créer une instance de la classe appropriée
        if cls == CognitiveNode:
            # Pour CognitiveNode, utiliser le constructeur normal
            node = cls(
                name=data["name"],
                level=level,
                description=data.get("description", ""),
                node_id=data.get("node_id"),
                metadata=data.get("metadata", {}),
                status=status,
                parent_id=data.get("parent_id")
            )
        elif cls == Cosmos:
            # Pour Cosmos, utiliser son constructeur spécifique
            node = cls(
                name=data["name"],
                description=data.get("description", ""),
                node_id=data.get("node_id"),
                metadata=data.get("metadata", {}),
                status=status
            )
        elif cls == Galaxy:
            # Pour Galaxy, utiliser son constructeur spécifique
            node = cls(
                name=data["name"],
                cosmos_id=data.get("parent_id", ""),
                description=data.get("description", ""),
                node_id=data.get("node_id"),
                metadata=data.get("metadata", {}),
                status=status
            )
        elif cls == StellarSystem:
            # Pour StellarSystem, utiliser son constructeur spécifique
            node = cls(
                name=data["name"],
                galaxy_id=data.get("parent_id", ""),
                description=data.get("description", ""),
                node_id=data.get("node_id"),
                metadata=data.get("metadata", {}),
                status=status
            )
        elif cls == Planet:
            # Pour Planet, utiliser son constructeur spécifique
            node = cls(
                name=data["name"],
                system_id=data.get("parent_id", ""),
                description=data.get("description", ""),
                node_id=data.get("node_id"),
                metadata=data.get("metadata", {}),
                status=status
            )
        elif cls == Continent:
            # Pour Continent, utiliser son constructeur spécifique
            node = cls(
                name=data["name"],
                planet_id=data.get("parent_id", ""),
                description=data.get("description", ""),
                node_id=data.get("node_id"),
                metadata=data.get("metadata", {}),
                status=status
            )
        elif cls == Region:
            # Pour Region, utiliser son constructeur spécifique
            node = cls(
                name=data["name"],
                continent_id=data.get("parent_id", ""),
                description=data.get("description", ""),
                node_id=data.get("node_id"),
                metadata=data.get("metadata", {}),
                status=status
            )
        elif cls == City:
            # Pour City, utiliser son constructeur spécifique
            node = cls(
                name=data["name"],
                region_id=data.get("parent_id", ""),
                description=data.get("description", ""),
                node_id=data.get("node_id"),
                metadata=data.get("metadata", {}),
                status=status
            )
        elif cls == District:
            # Pour District, utiliser son constructeur spécifique
            node = cls(
                name=data["name"],
                city_id=data.get("parent_id", ""),
                description=data.get("description", ""),
                node_id=data.get("node_id"),
                metadata=data.get("metadata", {}),
                status=status
            )
        elif cls == Street:
            # Pour Street, utiliser son constructeur spécifique
            node = cls(
                name=data["name"],
                district_id=data.get("parent_id", ""),
                description=data.get("description", ""),
                node_id=data.get("node_id"),
                metadata=data.get("metadata", {}),
                status=status
            )
        elif cls == Building:
            # Pour Building, utiliser son constructeur spécifique
            node = cls(
                name=data["name"],
                street_id=data.get("parent_id", ""),
                description=data.get("description", ""),
                node_id=data.get("node_id"),
                metadata=data.get("metadata", {}),
                status=status
            )
        else:
            # Pour toute autre classe dérivée, utiliser le constructeur de base
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
            node.children_ids = set(data["children_ids"])

        return node

    def add_child(self, child_id: str) -> None:
        """
        Ajoute un enfant au nœud.

        Args:
            child_id (str): Identifiant de l'enfant à ajouter
        """
        self.children_ids.add(child_id)
        self.metadata["updated_at"] = datetime.now().isoformat()
        logger.debug(f"Enfant '{child_id}' ajouté au nœud '{self.name}' (ID: {self.node_id})")

    def remove_child(self, child_id: str) -> bool:
        """
        Supprime un enfant du nœud.

        Args:
            child_id (str): Identifiant de l'enfant à supprimer

        Returns:
            bool: True si l'enfant a été supprimé, False sinon
        """
        if child_id in self.children_ids:
            self.children_ids.remove(child_id)
            self.metadata["updated_at"] = datetime.now().isoformat()
            logger.debug(f"Enfant '{child_id}' supprimé du nœud '{self.name}' (ID: {self.node_id})")
            return True
        return False

    def update_status(self, status: NodeStatus) -> None:
        """
        Met à jour le statut du nœud.

        Args:
            status (NodeStatus): Nouveau statut
        """
        self.status = status
        self.metadata["updated_at"] = datetime.now().isoformat()
        self.metadata["status_updated_at"] = self.metadata["updated_at"]
        logger.debug(f"Statut du nœud '{self.name}' (ID: {self.node_id}) mis à jour à {status.name}")

    def update_metadata(self, metadata: Dict[str, Any]) -> None:
        """
        Met à jour les métadonnées du nœud.

        Args:
            metadata (Dict[str, Any]): Nouvelles métadonnées à fusionner avec les existantes
        """
        self.metadata.update(metadata)
        self.metadata["updated_at"] = datetime.now().isoformat()
        logger.debug(f"Métadonnées du nœud '{self.name}' (ID: {self.node_id}) mises à jour")

class Cosmos(CognitiveNode):
    """
    Classe représentant le niveau COSMOS de l'architecture cognitive.

    Le COSMOS est le niveau le plus élevé, représentant la vision globale du système.
    """

    def __init__(
        self,
        name: str,
        description: str = "",
        node_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        status: NodeStatus = NodeStatus.PLANNED
    ):
        """
        Initialise un nœud COSMOS.

        Args:
            name (str): Nom du COSMOS
            description (str, optional): Description du COSMOS. Par défaut "".
            node_id (Optional[str], optional): Identifiant du COSMOS. Si None, un UUID est généré.
            metadata (Optional[Dict[str, Any]], optional): Métadonnées du COSMOS. Par défaut None.
            status (NodeStatus, optional): Statut du COSMOS. Par défaut NodeStatus.PLANNED.
        """
        super().__init__(
            name=name,
            level=HierarchyLevel.COSMOS,
            description=description,
            node_id=node_id,
            metadata=metadata,
            status=status,
            parent_id=None  # Un COSMOS n'a pas de parent
        )

        # Métadonnées spécifiques au COSMOS
        self.metadata["type"] = "cosmos"

        logger.info(f"COSMOS '{self.name}' (ID: {self.node_id}) créé")

class Galaxy(CognitiveNode):
    """
    Classe représentant le niveau GALAXIES de l'architecture cognitive.

    Une GALAXIE représente un grand domaine ou thème du système.
    """

    def __init__(
        self,
        name: str,
        cosmos_id: str,
        description: str = "",
        node_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        status: NodeStatus = NodeStatus.PLANNED
    ):
        """
        Initialise un nœud GALAXIE.

        Args:
            name (str): Nom de la GALAXIE
            cosmos_id (str): Identifiant du COSMOS parent
            description (str, optional): Description de la GALAXIE. Par défaut "".
            node_id (Optional[str], optional): Identifiant de la GALAXIE. Si None, un UUID est généré.
            metadata (Optional[Dict[str, Any]], optional): Métadonnées de la GALAXIE. Par défaut None.
            status (NodeStatus, optional): Statut de la GALAXIE. Par défaut NodeStatus.PLANNED.
        """
        super().__init__(
            name=name,
            level=HierarchyLevel.GALAXIES,
            description=description,
            node_id=node_id,
            metadata=metadata,
            status=status,
            parent_id=cosmos_id
        )

        # Métadonnées spécifiques à la GALAXIE
        self.metadata["type"] = "galaxy"

        logger.info(f"GALAXIE '{self.name}' (ID: {self.node_id}) créée dans le COSMOS '{cosmos_id}'")

class StellarSystem(CognitiveNode):
    """
    Classe représentant le niveau SYSTEMES STELLAIRES de l'architecture cognitive.

    Un SYSTEME STELLAIRE représente un groupe de projets liés.
    """

    def __init__(
        self,
        name: str,
        galaxy_id: str,
        description: str = "",
        node_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        status: NodeStatus = NodeStatus.PLANNED
    ):
        """
        Initialise un nœud SYSTEME STELLAIRE.

        Args:
            name (str): Nom du SYSTEME STELLAIRE
            galaxy_id (str): Identifiant de la GALAXIE parente
            description (str, optional): Description du SYSTEME STELLAIRE. Par défaut "".
            node_id (Optional[str], optional): Identifiant du SYSTEME STELLAIRE. Si None, un UUID est généré.
            metadata (Optional[Dict[str, Any]], optional): Métadonnées du SYSTEME STELLAIRE. Par défaut None.
            status (NodeStatus, optional): Statut du SYSTEME STELLAIRE. Par défaut NodeStatus.PLANNED.
        """
        super().__init__(
            name=name,
            level=HierarchyLevel.SYSTEMES,
            description=description,
            node_id=node_id,
            metadata=metadata,
            status=status,
            parent_id=galaxy_id
        )

        # Métadonnées spécifiques au SYSTEME STELLAIRE
        self.metadata["type"] = "stellar_system"

        logger.info(f"SYSTEME STELLAIRE '{self.name}' (ID: {self.node_id}) créé dans la GALAXIE '{galaxy_id}'")

class Planet(CognitiveNode):
    """
    Classe représentant le niveau PLANETES de l'architecture cognitive.

    Une PLANETE représente un projet individuel.
    """

    def __init__(
        self,
        name: str,
        system_id: str,
        description: str = "",
        node_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        status: NodeStatus = NodeStatus.PLANNED
    ):
        """
        Initialise un nœud PLANETE.

        Args:
            name (str): Nom de la PLANETE
            system_id (str): Identifiant du SYSTEME STELLAIRE parent
            description (str, optional): Description de la PLANETE. Par défaut "".
            node_id (Optional[str], optional): Identifiant de la PLANETE. Si None, un UUID est généré.
            metadata (Optional[Dict[str, Any]], optional): Métadonnées de la PLANETE. Par défaut None.
            status (NodeStatus, optional): Statut de la PLANETE. Par défaut NodeStatus.PLANNED.
        """
        super().__init__(
            name=name,
            level=HierarchyLevel.PLANETES,
            description=description,
            node_id=node_id,
            metadata=metadata,
            status=status,
            parent_id=system_id
        )

        # Métadonnées spécifiques à la PLANETE
        self.metadata["type"] = "planet"

        logger.info(f"PLANETE '{self.name}' (ID: {self.node_id}) créée dans le SYSTEME STELLAIRE '{system_id}'")

class Continent(CognitiveNode):
    """
    Classe représentant le niveau CONTINENTS de l'architecture cognitive.

    Un CONTINENT représente une grande fonctionnalité ou un module.
    """

    def __init__(
        self,
        name: str,
        planet_id: str,
        description: str = "",
        node_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        status: NodeStatus = NodeStatus.PLANNED
    ):
        """
        Initialise un nœud CONTINENT.

        Args:
            name (str): Nom du CONTINENT
            planet_id (str): Identifiant de la PLANETE parente
            description (str, optional): Description du CONTINENT. Par défaut "".
            node_id (Optional[str], optional): Identifiant du CONTINENT. Si None, un UUID est généré.
            metadata (Optional[Dict[str, Any]], optional): Métadonnées du CONTINENT. Par défaut None.
            status (NodeStatus, optional): Statut du CONTINENT. Par défaut NodeStatus.PLANNED.
        """
        super().__init__(
            name=name,
            level=HierarchyLevel.CONTINENTS,
            description=description,
            node_id=node_id,
            metadata=metadata,
            status=status,
            parent_id=planet_id
        )

        # Métadonnées spécifiques au CONTINENT
        self.metadata["type"] = "continent"

        logger.info(f"CONTINENT '{self.name}' (ID: {self.node_id}) créé dans la PLANETE '{planet_id}'")

class Region(CognitiveNode):
    """
    Classe représentant le niveau REGIONS de l'architecture cognitive.

    Une REGION représente une fonctionnalité spécifique.
    """

    def __init__(
        self,
        name: str,
        continent_id: str,
        description: str = "",
        node_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        status: NodeStatus = NodeStatus.PLANNED
    ):
        """
        Initialise un nœud REGION.

        Args:
            name (str): Nom de la REGION
            continent_id (str): Identifiant du CONTINENT parent
            description (str, optional): Description de la REGION. Par défaut "".
            node_id (Optional[str], optional): Identifiant de la REGION. Si None, un UUID est généré.
            metadata (Optional[Dict[str, Any]], optional): Métadonnées de la REGION. Par défaut None.
            status (NodeStatus, optional): Statut de la REGION. Par défaut NodeStatus.PLANNED.
        """
        super().__init__(
            name=name,
            level=HierarchyLevel.REGIONS,
            description=description,
            node_id=node_id,
            metadata=metadata,
            status=status,
            parent_id=continent_id
        )

        # Métadonnées spécifiques à la REGION
        self.metadata["type"] = "region"

        logger.info(f"REGION '{self.name}' (ID: {self.node_id}) créée dans le CONTINENT '{continent_id}'")

class City(CognitiveNode):
    """
    Classe représentant le niveau VILLES de l'architecture cognitive.

    Une VILLE représente un composant ou un service.
    """

    def __init__(
        self,
        name: str,
        region_id: str,
        description: str = "",
        node_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        status: NodeStatus = NodeStatus.PLANNED
    ):
        """
        Initialise un nœud VILLE.

        Args:
            name (str): Nom de la VILLE
            region_id (str): Identifiant de la REGION parente
            description (str, optional): Description de la VILLE. Par défaut "".
            node_id (Optional[str], optional): Identifiant de la VILLE. Si None, un UUID est généré.
            metadata (Optional[Dict[str, Any]], optional): Métadonnées de la VILLE. Par défaut None.
            status (NodeStatus, optional): Statut de la VILLE. Par défaut NodeStatus.PLANNED.
        """
        super().__init__(
            name=name,
            level=HierarchyLevel.VILLES,
            description=description,
            node_id=node_id,
            metadata=metadata,
            status=status,
            parent_id=region_id
        )

        # Métadonnées spécifiques à la VILLE
        self.metadata["type"] = "city"

        logger.info(f"VILLE '{self.name}' (ID: {self.node_id}) créée dans la REGION '{region_id}'")

class District(CognitiveNode):
    """
    Classe représentant le niveau QUARTIERS de l'architecture cognitive.

    Un QUARTIER représente un sous-composant.
    """

    def __init__(
        self,
        name: str,
        city_id: str,
        description: str = "",
        node_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        status: NodeStatus = NodeStatus.PLANNED
    ):
        """
        Initialise un nœud QUARTIER.

        Args:
            name (str): Nom du QUARTIER
            city_id (str): Identifiant de la VILLE parente
            description (str, optional): Description du QUARTIER. Par défaut "".
            node_id (Optional[str], optional): Identifiant du QUARTIER. Si None, un UUID est généré.
            metadata (Optional[Dict[str, Any]], optional): Métadonnées du QUARTIER. Par défaut None.
            status (NodeStatus, optional): Statut du QUARTIER. Par défaut NodeStatus.PLANNED.
        """
        super().__init__(
            name=name,
            level=HierarchyLevel.QUARTIERS,
            description=description,
            node_id=node_id,
            metadata=metadata,
            status=status,
            parent_id=city_id
        )

        # Métadonnées spécifiques au QUARTIER
        self.metadata["type"] = "district"

        logger.info(f"QUARTIER '{self.name}' (ID: {self.node_id}) créé dans la VILLE '{city_id}'")

class Street(CognitiveNode):
    """
    Classe représentant le niveau RUES de l'architecture cognitive.

    Une RUE représente une classe ou une fonction.
    """

    def __init__(
        self,
        name: str,
        district_id: str,
        description: str = "",
        node_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        status: NodeStatus = NodeStatus.PLANNED
    ):
        """
        Initialise un nœud RUE.

        Args:
            name (str): Nom de la RUE
            district_id (str): Identifiant du QUARTIER parent
            description (str, optional): Description de la RUE. Par défaut "".
            node_id (Optional[str], optional): Identifiant de la RUE. Si None, un UUID est généré.
            metadata (Optional[Dict[str, Any]], optional): Métadonnées de la RUE. Par défaut None.
            status (NodeStatus, optional): Statut de la RUE. Par défaut NodeStatus.PLANNED.
        """
        super().__init__(
            name=name,
            level=HierarchyLevel.RUES,
            description=description,
            node_id=node_id,
            metadata=metadata,
            status=status,
            parent_id=district_id
        )

        # Métadonnées spécifiques à la RUE
        self.metadata["type"] = "street"

        logger.info(f"RUE '{self.name}' (ID: {self.node_id}) créée dans le QUARTIER '{district_id}'")

class Building(CognitiveNode):
    """
    Classe représentant le niveau BATIMENTS de l'architecture cognitive.

    Un BATIMENT représente un élément de base (variable, constante, etc.).
    """

    def __init__(
        self,
        name: str,
        street_id: str,
        description: str = "",
        node_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        status: NodeStatus = NodeStatus.PLANNED
    ):
        """
        Initialise un nœud BATIMENT.

        Args:
            name (str): Nom du BATIMENT
            street_id (str): Identifiant de la RUE parente
            description (str, optional): Description du BATIMENT. Par défaut "".
            node_id (Optional[str], optional): Identifiant du BATIMENT. Si None, un UUID est généré.
            metadata (Optional[Dict[str, Any]], optional): Métadonnées du BATIMENT. Par défaut None.
            status (NodeStatus, optional): Statut du BATIMENT. Par défaut NodeStatus.PLANNED.
        """
        super().__init__(
            name=name,
            level=HierarchyLevel.BATIMENTS,
            description=description,
            node_id=node_id,
            metadata=metadata,
            status=status,
            parent_id=street_id
        )

        # Métadonnées spécifiques au BATIMENT
        self.metadata["type"] = "building"

        logger.info(f"BATIMENT '{self.name}' (ID: {self.node_id}) créé dans la RUE '{street_id}'")
