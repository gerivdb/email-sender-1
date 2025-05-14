#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Outil MCP pour rechercher dans la documentation.

Cet outil permet de rechercher des documents correspondant à une requête.
"""

import json
import logging
from typing import Dict, List, Any, Optional, Union

from ...document.DocumentManager import DocumentManager

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.document.tools.search_documentation")

class SearchDocumentationSchema:
    """Schéma pour l'outil search_documentation."""
    
    @staticmethod
    def get_schema() -> Dict[str, Any]:
        """
        Retourne le schéma JSON de l'outil search_documentation.
        
        Returns:
            Dict[str, Any]: Schéma de l'outil
        """
        return {
            "name": "search_documentation",
            "description": "Recherche des documents correspondant à une requête",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Requête de recherche"
                    },
                    "paths": {
                        "type": "array",
                        "description": "Liste des chemins à rechercher",
                        "items": {
                            "type": "string"
                        },
                        "default": []
                    },
                    "recursive": {
                        "type": "boolean",
                        "description": "Recherche récursive dans les sous-dossiers",
                        "default": False
                    },
                    "file_patterns": {
                        "type": "array",
                        "description": "Patterns de fichiers à inclure (expressions régulières)",
                        "items": {
                            "type": "string"
                        },
                        "default": []
                    },
                    "max_results": {
                        "type": "integer",
                        "description": "Nombre maximum de résultats à retourner",
                        "default": 10
                    },
                    "include_content": {
                        "type": "boolean",
                        "description": "Inclure le contenu des fichiers dans les résultats",
                        "default": False
                    },
                    "include_snippets": {
                        "type": "boolean",
                        "description": "Inclure des extraits de texte autour des correspondances",
                        "default": True
                    },
                    "snippet_size": {
                        "type": "integer",
                        "description": "Nombre de caractères à inclure avant et après la correspondance",
                        "default": 100
                    }
                },
                "required": ["query"]
            }
        }

def _extract_snippets(content: str, query: str, snippet_size: int = 100) -> List[str]:
    """
    Extrait des extraits de texte autour des correspondances.
    
    Args:
        content (str): Contenu du document
        query (str): Requête de recherche
        snippet_size (int): Nombre de caractères à inclure avant et après la correspondance
    
    Returns:
        List[str]: Liste des extraits
    """
    snippets = []
    query_lower = query.lower()
    content_lower = content.lower()
    
    # Trouver toutes les occurrences de la requête
    start_idx = 0
    while True:
        idx = content_lower.find(query_lower, start_idx)
        if idx == -1:
            break
        
        # Calculer les indices de début et de fin de l'extrait
        start = max(0, idx - snippet_size)
        end = min(len(content), idx + len(query) + snippet_size)
        
        # Extraire l'extrait
        snippet = content[start:end]
        
        # Ajouter des ellipses si nécessaire
        if start > 0:
            snippet = "..." + snippet
        if end < len(content):
            snippet = snippet + "..."
        
        snippets.append(snippet)
        
        # Passer à la prochaine occurrence
        start_idx = idx + len(query)
        
        # Limiter le nombre d'extraits
        if len(snippets) >= 5:
            break
    
    return snippets

def search_documentation(document_manager: DocumentManager, params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Implémentation de l'outil search_documentation.
    
    Args:
        document_manager (DocumentManager): Instance du gestionnaire de documents
        params (Dict[str, Any]): Paramètres de l'outil
    
    Returns:
        Dict[str, Any]: Résultat de l'opération
    
    Raises:
        ValueError: Si les paramètres sont invalides
    """
    # Valider les paramètres
    if "query" not in params:
        raise ValueError("Le paramètre 'query' est requis")
    
    query = params["query"]
    paths = params.get("paths", [])
    recursive = params.get("recursive", False)
    file_patterns = params.get("file_patterns", [])
    max_results = params.get("max_results", 10)
    include_content = params.get("include_content", False)
    include_snippets = params.get("include_snippets", True)
    snippet_size = params.get("snippet_size", 100)
    
    # Rechercher dans les documents
    results = document_manager.search_documentation(query, paths, recursive, file_patterns, max_results)
    
    # Ajouter le contenu et les extraits si demandé
    for result in results:
        file_path = result["path"]
        file_data = document_manager.read_file(file_path)
        
        if file_data["success"]:
            if include_content:
                result["content"] = file_data["content"]
                result["encoding"] = file_data["encoding"]
            
            if include_snippets:
                result["snippets"] = _extract_snippets(file_data["content"], query, snippet_size)
    
    # Préparer la réponse
    response = {
        "query": query,
        "paths": paths,
        "recursive": recursive,
        "file_patterns": file_patterns,
        "results": results,
        "count": len(results)
    }
    
    return response

def register_tool(mcp_server, document_manager: DocumentManager) -> None:
    """
    Enregistre l'outil search_documentation auprès du serveur MCP.
    
    Args:
        mcp_server: Instance du serveur MCP
        document_manager (DocumentManager): Instance du gestionnaire de documents
    """
    @mcp_server.tool(schema=SearchDocumentationSchema.get_schema())
    def search_documentation_tool(params: Dict[str, Any]) -> Dict[str, Any]:
        """Outil MCP pour rechercher dans la documentation."""
        return search_documentation(document_manager, params)
    
    logger.info("Outil search_documentation enregistré auprès du serveur MCP")
