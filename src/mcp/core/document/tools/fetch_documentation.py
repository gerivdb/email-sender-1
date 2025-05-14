#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Outil MCP pour récupérer de la documentation.

Cet outil permet de récupérer des documents à partir d'un chemin spécifié.
"""

import json
import logging
from typing import Dict, List, Any, Optional, Union

from ...document.DocumentManager import DocumentManager

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.document.tools.fetch_documentation")

class FetchDocumentationSchema:
    """Schéma pour l'outil fetch_documentation."""
    
    @staticmethod
    def get_schema() -> Dict[str, Any]:
        """
        Retourne le schéma JSON de l'outil fetch_documentation.
        
        Returns:
            Dict[str, Any]: Schéma de l'outil
        """
        return {
            "name": "fetch_documentation",
            "description": "Récupère des documents à partir d'un chemin spécifié",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Chemin du dossier ou du fichier à récupérer"
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
                    "max_files": {
                        "type": "integer",
                        "description": "Nombre maximum de fichiers à récupérer",
                        "default": 100
                    },
                    "include_content": {
                        "type": "boolean",
                        "description": "Inclure le contenu des fichiers dans les résultats",
                        "default": False
                    }
                },
                "required": ["path"]
            }
        }

def fetch_documentation(document_manager: DocumentManager, params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Implémentation de l'outil fetch_documentation.
    
    Args:
        document_manager (DocumentManager): Instance du gestionnaire de documents
        params (Dict[str, Any]): Paramètres de l'outil
    
    Returns:
        Dict[str, Any]: Résultat de l'opération
    
    Raises:
        ValueError: Si les paramètres sont invalides
    """
    # Valider les paramètres
    if "path" not in params:
        raise ValueError("Le paramètre 'path' est requis")
    
    path = params["path"]
    recursive = params.get("recursive", False)
    file_patterns = params.get("file_patterns", [])
    max_files = params.get("max_files", 100)
    include_content = params.get("include_content", False)
    
    # Récupérer les documents
    documents = document_manager.fetch_documentation(path, recursive, file_patterns)
    
    # Limiter le nombre de documents
    if len(documents) > max_files:
        documents = documents[:max_files]
        logger.warning(f"Nombre de documents limité à {max_files}")
    
    # Inclure le contenu si demandé
    if include_content:
        for doc in documents:
            file_data = document_manager.read_file(doc["path"])
            if file_data["success"]:
                doc["content"] = file_data["content"]
                doc["encoding"] = file_data["encoding"]
    
    # Préparer la réponse
    response = {
        "path": path,
        "recursive": recursive,
        "file_patterns": file_patterns,
        "documents": documents,
        "count": len(documents)
    }
    
    return response

def register_tool(mcp_server, document_manager: DocumentManager) -> None:
    """
    Enregistre l'outil fetch_documentation auprès du serveur MCP.
    
    Args:
        mcp_server: Instance du serveur MCP
        document_manager (DocumentManager): Instance du gestionnaire de documents
    """
    @mcp_server.tool(schema=FetchDocumentationSchema.get_schema())
    def fetch_documentation_tool(params: Dict[str, Any]) -> Dict[str, Any]:
        """Outil MCP pour récupérer des documents."""
        return fetch_documentation(document_manager, params)
    
    logger.info("Outil fetch_documentation enregistré auprès du serveur MCP")
