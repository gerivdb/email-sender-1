#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Outil MCP pour rechercher du code.

Cet outil permet de rechercher du code dans des fichiers en fonction de différents critères.
"""

import os
import json
import logging
from typing import Dict, List, Any, Optional

from src.mcp.core.code.CodeManager import CodeManager

# Configuration du logger
logger = logging.getLogger("mcp.code.tools.search_code")

class SearchCodeSchema:
    """
    Schéma pour l'outil search_code.
    """

    @staticmethod
    def get_schema() -> Dict[str, Any]:
        """
        Récupère le schéma de l'outil.

        Returns:
            Dict[str, Any]: Schéma de l'outil
        """
        return {
            "name": "search_code",
            "description": "Recherche du code correspondant à une requête",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Requête de recherche"
                    },
                    "paths": {
                        "type": "array",
                        "items": {
                            "type": "string"
                        },
                        "description": "Liste des chemins à rechercher"
                    },
                    "languages": {
                        "type": "array",
                        "items": {
                            "type": "string"
                        },
                        "description": "Liste des langages à inclure"
                    },
                    "recursive": {
                        "type": "boolean",
                        "description": "Recherche récursive dans les sous-dossiers"
                    },
                    "case_sensitive": {
                        "type": "boolean",
                        "description": "Recherche sensible à la casse"
                    },
                    "whole_word": {
                        "type": "boolean",
                        "description": "Recherche de mots entiers"
                    },
                    "regex": {
                        "type": "boolean",
                        "description": "Interprète la requête comme une expression régulière"
                    },
                    "max_results": {
                        "type": "integer",
                        "description": "Nombre maximum de résultats"
                    }
                },
                "required": ["query"]
            }
        }

def search_code(code_manager: CodeManager, params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Recherche du code correspondant à une requête.

    Args:
        code_manager (CodeManager): Instance du gestionnaire de code
        params (Dict[str, Any]): Paramètres de la recherche

    Returns:
        Dict[str, Any]: Résultats de la recherche
    """
    # Extraire les paramètres
    query = params["query"]
    paths = params.get("paths", None)
    languages = params.get("languages", None)
    recursive = params.get("recursive", True)
    case_sensitive = params.get("case_sensitive", False)
    whole_word = params.get("whole_word", False)
    regex = params.get("regex", False)
    max_results = params.get("max_results", 100)

    # Rechercher le code
    results = code_manager.search_code(
        query=query,
        paths=paths,
        languages=languages,
        recursive=recursive,
        case_sensitive=case_sensitive,
        whole_word=whole_word,
        regex=regex,
        max_results=max_results
    )

    # Préparer la réponse
    response = {
        "query": query,
        "paths": paths or [],
        "languages": languages or [],
        "recursive": recursive,
        "case_sensitive": case_sensitive,
        "whole_word": whole_word,
        "regex": regex,
        "results": results,
        "count": len(results)
    }

    return response

def register_tool(mcp_server, code_manager: CodeManager) -> None:
    """
    Enregistre l'outil search_code auprès du serveur MCP.

    Args:
        mcp_server: Instance du serveur MCP
        code_manager (CodeManager): Instance du gestionnaire de code
    """
    # Obtenir le schéma de l'outil
    schema = SearchCodeSchema.get_schema()

    @mcp_server.tool()
    def search_code_tool(params: Dict[str, Any]) -> Dict[str, Any]:
        """Outil MCP pour rechercher du code."""
        return search_code(code_manager, params)

    logger.info("Outil search_code enregistré auprès du serveur MCP")
