#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Outil MCP pour supprimer des mémoires.

Cet outil permet de supprimer une ou plusieurs mémoires du système MCP.
"""

import json
import logging
from typing import Dict, List, Any, Union, Optional

from ...memory.MemoryManager import MemoryManager

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.memory.tools.delete_memories")

class DeleteMemoriesSchema:
    """Schéma pour l'outil delete_memories."""
    
    @staticmethod
    def get_schema() -> Dict[str, Any]:
        """
        Retourne le schéma JSON de l'outil delete_memories.
        
        Returns:
            Dict[str, Any]: Schéma de l'outil
        """
        return {
            "name": "delete_memories",
            "description": "Supprime une ou plusieurs mémoires du système",
            "parameters": {
                "type": "object",
                "properties": {
                    "memory_ids": {
                        "type": "array",
                        "description": "Liste des identifiants des mémoires à supprimer",
                        "items": {
                            "type": "string"
                        }
                    },
                    "filters": {
                        "type": "object",
                        "description": "Filtres pour supprimer des mémoires par métadonnées (optionnel)"
                    },
                    "confirm": {
                        "type": "boolean",
                        "description": "Confirmation de suppression (requis pour les suppressions par filtre)",
                        "default": False
                    }
                },
                "oneOf": [
                    {"required": ["memory_ids"]},
                    {"required": ["filters", "confirm"]}
                ]
            }
        }

def delete_memories(memory_manager: MemoryManager, params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Implémentation de l'outil delete_memories.
    
    Args:
        memory_manager (MemoryManager): Instance du gestionnaire de mémoire
        params (Dict[str, Any]): Paramètres de l'outil
    
    Returns:
        Dict[str, Any]: Résultat de l'opération
    
    Raises:
        ValueError: Si les paramètres sont invalides
    """
    # Vérifier si nous avons des IDs de mémoire
    if "memory_ids" in params:
        memory_ids = params["memory_ids"]
        
        # Valider le format
        if not isinstance(memory_ids, list):
            raise ValueError("Le paramètre 'memory_ids' doit être une liste")
        
        # Supprimer chaque mémoire
        deleted_ids = []
        failed_ids = []
        
        for memory_id in memory_ids:
            success = memory_manager.delete_memory(memory_id)
            if success:
                deleted_ids.append(memory_id)
            else:
                failed_ids.append(memory_id)
        
        # Préparer la réponse
        response = {
            "deleted_count": len(deleted_ids),
            "deleted_ids": deleted_ids,
            "failed_ids": failed_ids
        }
        
        return response
    
    # Sinon, vérifier si nous avons des filtres
    elif "filters" in params:
        filters = params["filters"]
        confirm = params.get("confirm", False)
        
        # Vérifier la confirmation
        if not confirm:
            raise ValueError("La confirmation est requise pour supprimer des mémoires par filtre")
        
        # Créer une fonction de filtrage
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
        
        # Récupérer les mémoires correspondant au filtre
        memories_to_delete = memory_manager.list_memories(filter_func)
        
        # Supprimer chaque mémoire
        deleted_ids = []
        failed_ids = []
        
        for memory in memories_to_delete:
            memory_id = memory["id"]
            success = memory_manager.delete_memory(memory_id)
            if success:
                deleted_ids.append(memory_id)
            else:
                failed_ids.append(memory_id)
        
        # Préparer la réponse
        response = {
            "deleted_count": len(deleted_ids),
            "deleted_ids": deleted_ids,
            "failed_ids": failed_ids,
            "filters": filters
        }
        
        return response
    
    else:
        raise ValueError("Vous devez spécifier soit 'memory_ids' soit 'filters'")

def register_tool(mcp_server, memory_manager: MemoryManager) -> None:
    """
    Enregistre l'outil delete_memories auprès du serveur MCP.
    
    Args:
        mcp_server: Instance du serveur MCP
        memory_manager (MemoryManager): Instance du gestionnaire de mémoire
    """
    @mcp_server.tool(schema=DeleteMemoriesSchema.get_schema())
    def delete_memories_tool(params: Dict[str, Any]) -> Dict[str, Any]:
        """Outil MCP pour supprimer des mémoires."""
        return delete_memories(memory_manager, params)
    
    logger.info("Outil delete_memories enregistré auprès du serveur MCP")
