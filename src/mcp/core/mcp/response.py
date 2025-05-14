#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module pour la gestion des réponses MCP.

Ce module contient les classes et fonctions pour gérer les réponses MCP.
"""

import json
import logging
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, ValidationError

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.core.response")

class MCPResponseResult(BaseModel):
    """
    Modèle pour le résultat d'une réponse MCP.

    Cette classe est utilisée comme classe de base pour les différents types de résultats
    de réponses MCP.
    """
    pass

class ListToolsResult(MCPResponseResult):
    """
    Modèle pour le résultat d'une réponse listTools.
    """
    tools: List[Dict[str, Any]] = Field(..., description="Liste des outils disponibles")

class ExecuteToolResult(MCPResponseResult):
    """
    Modèle pour le résultat d'une réponse executeTool.
    """
    result: Any = Field(..., description="Résultat de l'exécution de l'outil")

class GetSchemaResult(MCPResponseResult):
    """
    Modèle pour le résultat d'une réponse getSchema.
    """
    schema: Dict[str, Any] = Field(..., description="Schéma de l'outil")

class GetStatusResult(MCPResponseResult):
    """
    Modèle pour le résultat d'une réponse getStatus.
    """
    status: str = Field(..., description="Statut du serveur")
    version: str = Field(..., description="Version du serveur")
    uptime: float = Field(..., description="Temps d'activité du serveur en secondes")

class MCPErrorResponse(BaseModel):
    """
    Modèle pour une erreur MCP.
    """
    code: int = Field(..., description="Code d'erreur")
    message: str = Field(..., description="Message d'erreur")
    data: Optional[Dict[str, Any]] = Field(None, description="Données supplémentaires sur l'erreur")

class MCPResponse(BaseModel):
    """
    Modèle pour une réponse MCP.

    Cette classe représente une réponse MCP complète, avec son résultat ou son erreur.
    """
    jsonrpc: str = Field("2.0", description="Version de JSON-RPC")
    id: str = Field(..., description="Identifiant de la requête")
    result: Optional[Any] = Field(None, description="Résultat de la méthode")
    error: Optional[MCPErrorResponse] = Field(None, description="Erreur éventuelle")

    def to_dict(self, **kwargs) -> Dict[str, Any]:
        """
        Convertit la réponse en dictionnaire.

        Returns:
            Dict[str, Any]: Dictionnaire représentant la réponse
        """
        try:
            # Pydantic v2
            return self.model_dump(exclude_none=True, **kwargs)
        except AttributeError:
            # Pydantic v1 fallback
            return self.dict(exclude_none=True, **kwargs)

    def to_json(self, **kwargs) -> str:
        """
        Convertit la réponse en chaîne JSON.

        Returns:
            str: Chaîne JSON représentant la réponse
        """
        try:
            # Pydantic v2
            return self.model_dump_json(exclude_none=True, **kwargs)
        except AttributeError:
            # Pydantic v1 fallback
            import json
            return json.dumps(self.to_dict(**kwargs))

def success_response(request_id: str, result: Any) -> "MCPResponse":
    """
    Crée une réponse MCP de succès.

    Args:
        request_id (str): Identifiant de la requête
        result (Any): Résultat de la méthode

    Returns:
        MCPResponse: Réponse MCP de succès
    """
    return MCPResponse(jsonrpc="2.0", id=request_id, result=result, error=None)

def error_response(request_id: str, code: int, message: str, data: Optional[Dict[str, Any]] = None) -> "MCPResponse":
    """
    Crée une réponse MCP d'erreur.

    Args:
        request_id (str): Identifiant de la requête
        code (int): Code d'erreur
        message (str): Message d'erreur
        data (Optional[Dict[str, Any]], optional): Données supplémentaires sur l'erreur

    Returns:
        MCPResponse: Réponse MCP d'erreur
    """
    return MCPResponse(jsonrpc="2.0", id=request_id, result=None, error=MCPErrorResponse(code=code, message=message, data=data))

class MCPResponseUtils:
    """
    Utilitaires pour les réponses MCP.
    """

    @staticmethod
    def from_json(json_str: str) -> MCPResponse:
        """
        Crée une réponse MCP à partir d'une chaîne JSON.

        Args:
            json_str (str): Chaîne JSON représentant la réponse

        Returns:
            MCPResponse: Réponse MCP

        Raises:
            ValidationError: Si la réponse n'est pas valide
            json.JSONDecodeError: Si la chaîne JSON n'est pas valide
        """
        try:
            data = json.loads(json_str)
            return MCPResponse(**data)
        except json.JSONDecodeError as e:
            logger.error(f"Erreur de décodage JSON: {e}")
            raise
        except ValidationError as e:
            logger.error(f"Erreur de validation de la réponse: {e}")
            raise
