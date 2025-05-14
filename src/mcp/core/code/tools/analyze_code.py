#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Outil MCP pour analyser du code.

Cet outil permet d'analyser un fichier de code pour obtenir des métriques et détecter des problèmes.
"""

import os
import json
import logging
from typing import Dict, List, Any, Optional

from src.mcp.core.code.CodeManager import CodeManager

# Configuration du logger
logger = logging.getLogger("mcp.code.tools.analyze_code")

class AnalyzeCodeSchema:
    """
    Schéma pour l'outil analyze_code.
    """

    @staticmethod
    def get_schema() -> Dict[str, Any]:
        """
        Récupère le schéma de l'outil.

        Returns:
            Dict[str, Any]: Schéma de l'outil
        """
        return {
            "name": "analyze_code",
            "description": "Analyse un fichier de code pour obtenir des métriques et détecter des problèmes",
            "parameters": {
                "type": "object",
                "properties": {
                    "file_path": {
                        "type": "string",
                        "description": "Chemin du fichier à analyser"
                    },
                    "rules": {
                        "type": "array",
                        "items": {
                            "type": "string"
                        },
                        "description": "Liste des règles d'analyse à appliquer"
                    }
                },
                "required": ["file_path"]
            }
        }

def analyze_code(code_manager: CodeManager, params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Analyse un fichier de code.

    Args:
        code_manager (CodeManager): Instance du gestionnaire de code
        params (Dict[str, Any]): Paramètres de l'analyse

    Returns:
        Dict[str, Any]: Résultat de l'analyse
    """
    # Extraire les paramètres
    file_path = params["file_path"]
    rules = params.get("rules", None)

    # Analyser le code
    result = code_manager.analyze_code(
        file_path=file_path,
        rules=rules
    )

    return result

def register_tool(mcp_server, code_manager: CodeManager) -> None:
    """
    Enregistre l'outil analyze_code auprès du serveur MCP.

    Args:
        mcp_server: Instance du serveur MCP
        code_manager (CodeManager): Instance du gestionnaire de code
    """
    # Obtenir le schéma de l'outil
    schema = AnalyzeCodeSchema.get_schema()

    @mcp_server.tool()
    def analyze_code_tool(params: Dict[str, Any]) -> Dict[str, Any]:
        """Outil MCP pour analyser du code."""
        return analyze_code(code_manager, params)

    logger.info("Outil analyze_code enregistré auprès du serveur MCP")
