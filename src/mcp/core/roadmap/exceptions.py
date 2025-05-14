#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module pour les exceptions spécifiques à l'architecture cognitive des roadmaps.

Ce module contient les exceptions personnalisées pour l'architecture cognitive des roadmaps.
"""

from typing import Optional, List, Union

class CognitiveArchitectureError(Exception):
    """Exception de base pour l'architecture cognitive des roadmaps."""
    pass

class NodeNotFoundError(CognitiveArchitectureError):
    """Exception levée lorsqu'un nœud n'est pas trouvé."""

    def __init__(self, node_id: str, message: Optional[str] = None):
        """
        Initialise l'exception.

        Args:
            node_id (str): Identifiant du nœud non trouvé
            message (str, optional): Message d'erreur personnalisé. Par défaut None.
        """
        self.node_id = node_id
        self.message = message or f"Nœud '{node_id}' non trouvé"
        super().__init__(self.message)

class InvalidParentError(CognitiveArchitectureError):
    """Exception levée lorsqu'un parent est invalide."""

    def __init__(self, parent_id: str, expected_level: str, actual_level: Optional[str] = None):
        """
        Initialise l'exception.

        Args:
            parent_id (str): Identifiant du parent invalide
            expected_level (str): Niveau hiérarchique attendu
            actual_level (str, optional): Niveau hiérarchique actuel. Par défaut None.
        """
        self.parent_id = parent_id
        self.expected_level = expected_level
        self.actual_level = actual_level

        if actual_level:
            self.message = f"Le nœud parent '{parent_id}' n'est pas un {expected_level} (niveau actuel: {actual_level})"
        else:
            self.message = f"Le nœud parent '{parent_id}' n'est pas un {expected_level}"

        super().__init__(self.message)

class NodeHasChildrenError(CognitiveArchitectureError):
    """Exception levée lorsqu'un nœud a des enfants et ne peut pas être supprimé."""

    def __init__(self, node_id: str, children_count: int):
        """
        Initialise l'exception.

        Args:
            node_id (str): Identifiant du nœud
            children_count (int): Nombre d'enfants
        """
        self.node_id = node_id
        self.children_count = children_count
        self.message = f"Impossible de supprimer le nœud '{node_id}' car il a {children_count} enfant(s)"
        super().__init__(self.message)

class StorageError(CognitiveArchitectureError):
    """Exception levée lors d'une erreur de stockage."""

    def __init__(self, node_id: str, operation: str, cause: Optional[Exception] = None):
        """
        Initialise l'exception.

        Args:
            node_id (str): Identifiant du nœud
            operation (str): Opération qui a échoué
            cause (Exception, optional): Cause de l'erreur. Par défaut None.
        """
        self.node_id = node_id
        self.operation = operation
        self.cause = cause

        if cause:
            self.message = f"Erreur lors de l'{operation} du nœud '{node_id}': {cause}"
        else:
            self.message = f"Erreur lors de l'{operation} du nœud '{node_id}'"

        super().__init__(self.message)

class InvalidNodeDataError(CognitiveArchitectureError):
    """Exception levée lorsque les données d'un nœud sont invalides."""

    def __init__(self, data: dict, missing_field: Optional[str] = None):
        """
        Initialise l'exception.

        Args:
            data (dict): Données du nœud
            missing_field (str, optional): Champ manquant. Par défaut None.
        """
        self.data = data
        self.missing_field = missing_field

        if missing_field:
            self.message = f"Données de nœud invalides: champ '{missing_field}' manquant"
        else:
            self.message = "Données de nœud invalides"

        super().__init__(self.message)

class CircularReferenceError(CognitiveArchitectureError):
    """Exception levée lorsqu'une référence circulaire est détectée."""

    def __init__(self, node_id: str, parent_id: str, path: Optional[List[str]] = None):
        """
        Initialise l'exception.

        Args:
            node_id (str): Identifiant du nœud
            parent_id (str): Identifiant du parent
            path (list, optional): Chemin de la référence circulaire. Par défaut None.
        """
        self.node_id = node_id
        self.parent_id = parent_id
        self.path = path

        if path and isinstance(path, list):
            path_str = " -> ".join(path)
            self.message = f"Référence circulaire détectée: {node_id} -> {parent_id} (chemin: {path_str})"
        else:
            self.message = f"Référence circulaire détectée: {node_id} -> {parent_id}"

        super().__init__(self.message)
