#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module pour la gestion des requêtes MCP.

Ce module contient les classes et fonctions pour gérer les requêtes MCP.
"""

import json
import logging
from typing import Any, Dict, Optional
from pydantic import BaseModel, Field, ValidationError

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.core.request")

class MCPRequestParams(BaseModel):
    """
    Modèle pour les paramètres d'une requête MCP.

    Cette classe est utilisée comme classe de base pour les différents types de paramètres
    de requêtes MCP.
    """
    pass

class ListToolsParams(MCPRequestParams):
    """
    Modèle pour les paramètres d'une requête listTools.
    """
    pass

class ExecuteToolParams(MCPRequestParams):
    """
    Modèle pour les paramètres d'une requête executeTool.
    """
    name: str = Field(..., description="Nom de l'outil à exécuter")
    arguments: Dict[str, Any] = Field(default_factory=dict, description="Arguments de l'outil")

class GetSchemaParams(MCPRequestParams):
    """
    Modèle pour les paramètres d'une requête getSchema.
    """
    name: str = Field(..., description="Nom de l'outil dont on veut récupérer le schéma")

class GetStatusParams(MCPRequestParams):
    """
    Modèle pour les paramètres d'une requête getStatus.
    """
    pass

class MCPRequest(BaseModel):
    """
    Modèle pour une requête MCP.

    Cette classe représente une requête MCP complète, avec sa méthode et ses paramètres.
    """
    jsonrpc: str = Field("2.0", description="Version de JSON-RPC")
    id: str = Field(..., description="Identifiant de la requête")
    method: str = Field(..., description="Méthode à appeler")
    params: Optional[Dict[str, Any]] = Field(None, description="Paramètres de la méthode")

    def validate_params(self) -> Dict[str, Any]:
        """
        Valide les paramètres de la requête en fonction de la méthode.

        Returns:
            Dict[str, Any]: Paramètres validés

        Raises:
            ValidationError: Si les paramètres ne sont pas valides
        """
        if self.params is None:
            self.params = {}

        try:
            if self.method == "listTools":
                ListToolsParams(**self.params)
            elif self.method == "executeTool":
                ExecuteToolParams(**self.params)
            elif self.method == "getSchema":
                GetSchemaParams(**self.params)
            elif self.method == "getStatus":
                GetStatusParams(**self.params)

            return self.params
        except ValidationError as e:
            logger.error(f"Erreur de validation des paramètres: {e}")
            raise

    @classmethod
    def from_json(cls, json_str: str) -> "MCPRequest":
        """
        Crée une requête MCP à partir d'une chaîne JSON.

        Args:
            json_str (str): Chaîne JSON représentant la requête

        Returns:
            MCPRequest: Requête MCP

        Raises:
            ValidationError: Si la requête n'est pas valide
            json.JSONDecodeError: Si la chaîne JSON n'est pas valide
        """
        try:
            data = json.loads(json_str)
            return cls(**data)
        except json.JSONDecodeError as e:
            logger.error(f"Erreur de décodage JSON: {e}")
            raise
        except ValidationError as e:
            logger.error(f"Erreur de validation de la requête: {e}")
            raise

    def to_dict(self, **kwargs) -> Dict[str, Any]:
        """
        Convertit la requête en dictionnaire.

        Returns:
            Dict[str, Any]: Dictionnaire représentant la requête
        """
        try:
            # Pydantic v2
            return self.model_dump(**kwargs)
        except AttributeError:
            # Pydantic v1 fallback
            return self.dict(**kwargs)

    def to_json(self, **kwargs) -> str:
        """
        Convertit la requête en chaîne JSON.

        Returns:
            str: Chaîne JSON représentant la requête
        """
        try:
            # Pydantic v2
            return self.model_dump_json(**kwargs)
        except AttributeError:
            # Pydantic v1 fallback
            import json
            return json.dumps(self.to_dict(**kwargs))
