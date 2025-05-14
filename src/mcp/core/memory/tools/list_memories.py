#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Outil MCP pour lister les mémoires.

Cet outil permet de lister toutes les mémoires du système MCP avec des options de filtrage.
"""

import json
import logging
from typing import Dict, List, Any, Union, Optional, Callable

from ...memory.MemoryManager import MemoryManager

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.memory.tools.list_memories")

class ListMemoriesSchema:
    """Schéma pour l'outil list_memories."""
    
    @staticmethod
    def get_schema() -> Dict[str, Any]:
        """
        Retourne le schéma JSON de l'outil list_memories.
        
        Returns:
            Dict[str, Any]: Schéma de l'outil
        """
        return {
            "name": "list_memories",
            "description": "Liste toutes les mémoires du système avec options de filtrage",
            "parameters": {
                "type": "object",
                "properties": {
                    "page": {
                        "type": "integer",
                        "description": "Numéro de page (pour la pagination, commence à 1)",
                        "default": 1
                    },
                    "page_size": {
                        "type": "integer",
                        "description": "Nombre d'éléments par page",
                        "default": 20
                    },
                    "filters": {
                        "type": "object",
                        "description": "Filtres à appliquer sur les métadonnées (optionnel)"
                    },
                    "sort_by": {
                        "type": "string",
                        "description": "Champ sur lequel trier (created_at, updated_at)",
                        "default": "created_at"
                    },
                    "sort_order": {
                        "type": "string",
                        "description": "Ordre de tri (asc, desc)",
                        "default": "desc"
                    }
                }
            }
        }

def list_memories(memory_manager: MemoryManager, params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Implémentation de l'outil list_memories.
    
    Args:
        memory_manager (MemoryManager): Instance du gestionnaire de mémoire
        params (Dict[str, Any]): Paramètres de l'outil
    
    Returns:
        Dict[str, Any]: Résultat de l'opération
    """
    # Extraire les paramètres avec valeurs par défaut
    page = max(1, params.get("page", 1))  # Page minimale est 1
    page_size = params.get("page_size", 20)
    filters = params.get("filters", {})
    sort_by = params.get("sort_by", "created_at")
    sort_order = params.get("sort_order", "desc")
    
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
    
    # Récupérer toutes les mémoires avec le filtre
    all_memories = memory_manager.list_memories(filter_func)
    
    # Trier les résultats
    if sort_by in ["created_at", "updated_at"]:
        # Gérer le cas où updated_at est None
        if sort_by == "updated_at":
            all_memories.sort(
                key=lambda x: x.get(sort_by) or x.get("created_at"),
                reverse=(sort_order.lower() == "desc")
            )
        else:
            all_memories.sort(
                key=lambda x: x.get(sort_by),
                reverse=(sort_order.lower() == "desc")
            )
    
    # Calculer les indices pour la pagination
    total_items = len(all_memories)
    total_pages = (total_items + page_size - 1) // page_size if total_items > 0 else 1
    
    # Ajuster la page si nécessaire
    page = min(page, total_pages)
    
    # Calculer les indices de début et de fin
    start_idx = (page - 1) * page_size
    end_idx = min(start_idx + page_size, total_items)
    
    # Extraire les éléments de la page
    page_items = all_memories[start_idx:end_idx]
    
    # Préparer la réponse
    response = {
        "items": page_items,
        "pagination": {
            "page": page,
            "page_size": page_size,
            "total_items": total_items,
            "total_pages": total_pages
        },
        "filters": filters,
        "sort": {
            "field": sort_by,
            "order": sort_order
        }
    }
    
    return response

def register_tool(mcp_server, memory_manager: MemoryManager) -> None:
    """
    Enregistre l'outil list_memories auprès du serveur MCP.
    
    Args:
        mcp_server: Instance du serveur MCP
        memory_manager (MemoryManager): Instance du gestionnaire de mémoire
    """
    @mcp_server.tool(schema=ListMemoriesSchema.get_schema())
    def list_memories_tool(params: Dict[str, Any]) -> Dict[str, Any]:
        """Outil MCP pour lister les mémoires."""
        return list_memories(memory_manager, params)
    
    logger.info("Outil list_memories enregistré auprès du serveur MCP")
