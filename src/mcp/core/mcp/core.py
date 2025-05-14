#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module principal pour le Core MCP.

Ce module contient la classe principale MCPCore qui gère le parsing des requêtes
et le formatage des réponses MCP.
"""

import json
import logging
import time
from typing import Any, Callable, Dict, Optional

from .request import MCPRequest
from .response import MCPResponse, success_response, error_response
from .protocol import MCPProtocolHandler, MCPStdioHandler

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.core.core")

class MCPCore:
    """
    Classe principale pour le Core MCP.

    Cette classe gère le parsing des requêtes et le formatage des réponses MCP.
    Elle sert d'interface entre les outils MCP et les protocoles de communication.
    """

    def __init__(self, name: str, version: str = "1.0.0"):
        """
        Initialise le Core MCP.

        Args:
            name (str): Nom du serveur MCP
            version (str, optional): Version du serveur MCP. Par défaut "1.0.0".
        """
        self.name = name
        self.version = version
        self.start_time = time.time()
        self.tools = {}
        self.schemas = {}
        self.protocol_handler = None
        logger.info(f"Core MCP '{name}' v{version} initialisé")

    def register_tool(self, name: str, handler: Callable, schema: Dict[str, Any]) -> None:
        """
        Enregistre un outil MCP.

        Args:
            name (str): Nom de l'outil
            handler (Callable): Fonction de traitement de l'outil
            schema (Dict[str, Any]): Schéma JSON de l'outil
        """
        self.tools[name] = handler
        self.schemas[name] = schema
        logger.info(f"Outil '{name}' enregistré")

    def unregister_tool(self, name: str) -> None:
        """
        Désenregistre un outil MCP.

        Args:
            name (str): Nom de l'outil
        """
        if name in self.tools:
            del self.tools[name]
            del self.schemas[name]
            logger.info(f"Outil '{name}' désenregistré")

    def handle_request(self, request: MCPRequest) -> MCPResponse:
        """
        Traite une requête MCP.

        Args:
            request (MCPRequest): Requête MCP à traiter

        Returns:
            MCPResponse: Réponse MCP
        """
        try:
            # Valider les paramètres de la requête
            params = request.validate_params()

            # Traiter la requête en fonction de la méthode
            if request.method == "listTools":
                return self._handle_list_tools(request)
            elif request.method == "executeTool":
                return self._handle_execute_tool(request, params)
            elif request.method == "getSchema":
                return self._handle_get_schema(request, params)
            elif request.method == "getStatus":
                return self._handle_get_status(request)
            else:
                return error_response(
                    request_id=request.id,
                    code=-32601,
                    message=f"Méthode non trouvée: {request.method}"
                )
        except Exception as e:
            logger.error(f"Erreur lors du traitement de la requête: {e}")
            return error_response(
                request_id=request.id,
                code=-32603,
                message=f"Erreur interne: {str(e)}"
            )

    def _handle_list_tools(self, request: MCPRequest) -> MCPResponse:
        """
        Traite une requête listTools.

        Args:
            request (MCPRequest): Requête MCP

        Returns:
            MCPResponse: Réponse MCP
        """
        tools = []
        for name, schema in self.schemas.items():
            tools.append({
                "name": name,
                "description": schema.get("description", ""),
                "parameters": schema.get("parameters", {})
            })

        return success_response(request.id, {"tools": tools})

    def _handle_execute_tool(self, request: MCPRequest, params: Dict[str, Any]) -> MCPResponse:
        """
        Traite une requête executeTool.

        Args:
            request (MCPRequest): Requête MCP
            params (Dict[str, Any]): Paramètres validés de la requête

        Returns:
            MCPResponse: Réponse MCP
        """
        tool_name = params.get("name")
        arguments = params.get("arguments", {})

        if tool_name not in self.tools:
            return error_response(
                request_id=request.id,
                code=-32601,
                message=f"Outil non trouvé: {tool_name}"
            )

        try:
            # Exécuter l'outil
            result = self.tools[tool_name](**arguments)
            return success_response(request.id, {"result": result})
        except Exception as e:
            logger.error(f"Erreur lors de l'exécution de l'outil '{tool_name}': {e}")
            return error_response(
                request_id=request.id,
                code=-32603,
                message=f"Erreur lors de l'exécution de l'outil: {str(e)}"
            )

    def _handle_get_schema(self, request: MCPRequest, params: Dict[str, Any]) -> MCPResponse:
        """
        Traite une requête getSchema.

        Args:
            request (MCPRequest): Requête MCP
            params (Dict[str, Any]): Paramètres validés de la requête

        Returns:
            MCPResponse: Réponse MCP
        """
        tool_name = params.get("name")

        if tool_name not in self.schemas:
            return error_response(
                request_id=request.id,
                code=-32601,
                message=f"Outil non trouvé: {tool_name}"
            )

        return success_response(request.id, {"schema": self.schemas[tool_name]})

    def _handle_get_status(self, request: MCPRequest) -> MCPResponse:
        """
        Traite une requête getStatus.

        Args:
            request (MCPRequest): Requête MCP

        Returns:
            MCPResponse: Réponse MCP
        """
        uptime = time.time() - self.start_time
        return success_response(
            request_id=request.id,
            result={
                "status": "ok",
                "version": self.version,
                "name": self.name,
                "uptime": uptime,
                "tools_count": len(self.tools)
            }
        )

    def start(self, protocol: str = "stdio") -> None:
        """
        Démarre le Core MCP avec le protocole spécifié.

        Args:
            protocol (str, optional): Protocole à utiliser (stdio, http, sse). Par défaut "stdio".
        """
        if protocol == "stdio":
            self.protocol_handler = MCPStdioHandler(self.handle_request)
        else:
            raise ValueError(f"Protocole non supporté: {protocol}")

        logger.info(f"Démarrage du Core MCP avec le protocole {protocol}")
        self.protocol_handler.start()

    def stop(self) -> None:
        """
        Arrête le Core MCP.
        """
        if self.protocol_handler:
            self.protocol_handler.stop()
            logger.info("Arrêt du Core MCP")

    def tool(self, schema: Optional[Dict[str, Any]] = None):
        """
        Décorateur pour enregistrer un outil MCP.

        Args:
            schema (Dict[str, Any], optional): Schéma JSON de l'outil

        Returns:
            Callable: Décorateur
        """
        def decorator(func):
            name = schema.get("name") if schema else func.__name__
            description = schema.get("description") if schema else (func.__doc__ or "")

            # Créer un schéma par défaut si aucun n'est fourni
            if not schema:
                import inspect
                sig = inspect.signature(func)
                parameters = {}
                for param_name, param in sig.parameters.items():
                    parameters[param_name] = {
                        "type": "string",
                        "description": f"Paramètre {param_name}"
                    }

                schema_dict = {
                    "name": name,
                    "description": description,
                    "parameters": {
                        "type": "object",
                        "properties": parameters,
                        "required": [param_name for param_name, param in sig.parameters.items()
                                    if param.default == inspect.Parameter.empty]
                    }
                }
            else:
                schema_dict = schema

            # Enregistrer l'outil
            self.register_tool(name, func, schema_dict)
            return func

        return decorator
