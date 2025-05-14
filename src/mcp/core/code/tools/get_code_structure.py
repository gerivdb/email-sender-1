#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Outil MCP pour obtenir la structure d'un fichier de code.

Cet outil permet d'extraire la structure d'un fichier de code (classes, fonctions, imports, etc.).
"""

import os
import json
import logging
from typing import Dict, List, Any, Optional

from src.mcp.core.code.CodeManager import CodeManager

# Configuration du logger
logger = logging.getLogger("mcp.code.tools.get_code_structure")

class GetCodeStructureSchema:
    """
    Schéma pour l'outil get_code_structure.
    """

    @staticmethod
    def get_schema() -> Dict[str, Any]:
        """
        Récupère le schéma de l'outil.

        Returns:
            Dict[str, Any]: Schéma de l'outil
        """
        return {
            "name": "get_code_structure",
            "description": "Obtient la structure d'un fichier de code (classes, fonctions, imports, etc.)",
            "parameters": {
                "type": "object",
                "properties": {
                    "file_path": {
                        "type": "string",
                        "description": "Chemin du fichier"
                    }
                },
                "required": ["file_path"]
            }
        }

def get_code_structure(code_manager: CodeManager, params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Obtient la structure d'un fichier de code.

    Args:
        code_manager (CodeManager): Instance du gestionnaire de code
        params (Dict[str, Any]): Paramètres de la requête

    Returns:
        Dict[str, Any]: Structure du code
    """
    # Extraire les paramètres
    file_path = params["file_path"]

    # Obtenir la structure du code
    result = code_manager.get_code_structure(
        file_path=file_path
    )

    return result

def register_tool(mcp_server, code_manager: CodeManager) -> None:
    """
    Enregistre l'outil get_code_structure auprès du serveur MCP.

    Args:
        mcp_server: Instance du serveur MCP
        code_manager (CodeManager): Instance du gestionnaire de code
    """
    # Obtenir le schéma de l'outil
    schema = GetCodeStructureSchema.get_schema()

    @mcp_server.tool()
    def get_code_structure_tool(params: Dict[str, Any]) -> Dict[str, Any]:
        """Outil MCP pour obtenir la structure d'un fichier de code."""
        return get_code_structure(code_manager, params)

    logger.info("Outil get_code_structure enregistré auprès du serveur MCP")
