#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Outil MCP pour rechercher des mémoires.

Cet outil permet de rechercher des mémoires dans le système MCP.
"""

import json
import logging
from typing import Dict, List, Any, Union, Optional

from ...memory.MemoryManager import MemoryManager

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.memory.tools.search_memory")

class SearchMemorySchema:
    """Schéma pour l'outil search_memory."""
    
    @staticmethod
    def get_schema() -> Dict[str, Any]:
        """
        Retourne le schéma JSON de l'outil search_memory.
        
        Returns:
            Dict[str, Any]: Schéma de l'outil
        """
        return {
            "name": "search_memory",
            "description": "Recherche des mémoires dans le système",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Requête de recherche"
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Nombre maximum de résultats à retourner (défaut: 5)",
                        "default": 5
                    },
                    "filters": {
                        "type": "object",
                        "description": "Filtres à appliquer sur les métadonnées (optionnel)"
                    }
                },
                "required": ["query"]
            }
        }

def search_memory(memory_manager: MemoryManager, params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Implémentation de l'outil search_memory.
    
    Args:
        memory_manager (MemoryManager): Instance du gestionnaire de mémoire
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
    limit = params.get("limit", 5)
    filters = params.get("filters", {})
    
    # Créer une fonction de filtrage si des filtres sont spécifiés
    filter_func = None
    if filters:
        def filter_func(memory):
            # Vérifier que toutes les conditions de filtrage sont satisfaites
            for key, value in filters.items():
                # Vérifier si la clé existe dans les métadonnées
                if key not in memory["metadata"]:
                    return False
                
                # Vérifier si la valeur correspond
                if memory["metadata"][key] != value:
                    return False
            
            return True
    
    # Rechercher les mémoires
    results = memory_manager.search_memory(query, limit)
    
    # Appliquer le filtre si spécifié
    if filter_func:
        results = [r for r in results if filter_func(r)]
    
    # Préparer la réponse
    response = {
        "query": query,
        "results": results,
        "count": len(results)
    }
    
    return response

def register_tool(mcp_server, memory_manager: MemoryManager) -> None:
    """
    Enregistre l'outil search_memory auprès du serveur MCP.
    
    Args:
        mcp_server: Instance du serveur MCP
        memory_manager (MemoryManager): Instance du gestionnaire de mémoire
    """
    @mcp_server.tool(schema=SearchMemorySchema.get_schema())
    def search_memory_tool(params: Dict[str, Any]) -> Dict[str, Any]:
        """Outil MCP pour rechercher des mémoires."""
        return search_memory(memory_manager, params)
    
    logger.info("Outil search_memory enregistré auprès du serveur MCP")
