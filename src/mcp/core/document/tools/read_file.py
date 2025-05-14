#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Outil MCP pour lire des fichiers.

Cet outil permet de lire le contenu d'un fichier.
"""

import json
import logging
from typing import Dict, List, Any, Optional, Union

from ...document.DocumentManager import DocumentManager

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.document.tools.read_file")

class ReadFileSchema:
    """Schéma pour l'outil read_file."""
    
    @staticmethod
    def get_schema() -> Dict[str, Any]:
        """
        Retourne le schéma JSON de l'outil read_file.
        
        Returns:
            Dict[str, Any]: Schéma de l'outil
        """
        return {
            "name": "read_file",
            "description": "Lit le contenu d'un fichier",
            "parameters": {
                "type": "object",
                "properties": {
                    "file_path": {
                        "type": "string",
                        "description": "Chemin du fichier à lire"
                    },
                    "encoding": {
                        "type": "string",
                        "description": "Encodage du fichier (auto-détecté si non spécifié)",
                        "default": None
                    },
                    "line_numbers": {
                        "type": "boolean",
                        "description": "Inclure les numéros de ligne dans le résultat",
                        "default": False
                    },
                    "start_line": {
                        "type": "integer",
                        "description": "Ligne de début (1-indexed, inclus)",
                        "default": 1
                    },
                    "end_line": {
                        "type": "integer",
                        "description": "Ligne de fin (1-indexed, inclus, -1 pour toutes les lignes)",
                        "default": -1
                    }
                },
                "required": ["file_path"]
            }
        }

def read_file(document_manager: DocumentManager, params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Implémentation de l'outil read_file.
    
    Args:
        document_manager (DocumentManager): Instance du gestionnaire de documents
        params (Dict[str, Any]): Paramètres de l'outil
    
    Returns:
        Dict[str, Any]: Résultat de l'opération
    
    Raises:
        ValueError: Si les paramètres sont invalides
    """
    # Valider les paramètres
    if "file_path" not in params:
        raise ValueError("Le paramètre 'file_path' est requis")
    
    file_path = params["file_path"]
    encoding = params.get("encoding")
    line_numbers = params.get("line_numbers", False)
    start_line = params.get("start_line", 1)
    end_line = params.get("end_line", -1)
    
    # Lire le fichier
    file_data = document_manager.read_file(file_path, encoding)
    
    # Vérifier si la lecture a réussi
    if not file_data["success"]:
        return file_data
    
    # Extraire les lignes si nécessaire
    if start_line > 1 or end_line != -1 or line_numbers:
        lines = file_data["content"].splitlines()
        
        # Ajuster les indices (1-indexed à 0-indexed)
        start_idx = max(0, start_line - 1)
        end_idx = len(lines) if end_line == -1 else min(len(lines), end_line)
        
        # Extraire les lignes
        if line_numbers:
            # Formater les lignes avec les numéros de ligne
            extracted_lines = []
            for i in range(start_idx, end_idx):
                line_num = i + 1
                extracted_lines.append(f"{line_num}: {lines[i]}")
            
            file_data["content"] = "\n".join(extracted_lines)
        else:
            # Extraire les lignes sans numéros de ligne
            file_data["content"] = "\n".join(lines[start_idx:end_idx])
        
        # Ajouter les informations de ligne
        file_data["line_info"] = {
            "start_line": start_line,
            "end_line": end_line if end_line != -1 else len(lines),
            "total_lines": len(lines)
        }
    
    return file_data

def register_tool(mcp_server, document_manager: DocumentManager) -> None:
    """
    Enregistre l'outil read_file auprès du serveur MCP.
    
    Args:
        mcp_server: Instance du serveur MCP
        document_manager (DocumentManager): Instance du gestionnaire de documents
    """
    @mcp_server.tool(schema=ReadFileSchema.get_schema())
    def read_file_tool(params: Dict[str, Any]) -> Dict[str, Any]:
        """Outil MCP pour lire des fichiers."""
        return read_file(document_manager, params)
    
    logger.info("Outil read_file enregistré auprès du serveur MCP")
