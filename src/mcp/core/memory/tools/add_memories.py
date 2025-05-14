#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Outil MCP pour ajouter des mémoires.

Cet outil permet d'ajouter une ou plusieurs mémoires au système MCP.
"""

import json
import logging
from typing import Dict, List, Any, Union, Optional

from ...memory.MemoryManager import MemoryManager

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.memory.tools.add_memories")

class AddMemoriesSchema:
    """Schéma pour l'outil add_memories."""
    
    @staticmethod
    def get_schema() -> Dict[str, Any]:
        """
        Retourne le schéma JSON de l'outil add_memories.
        
        Returns:
            Dict[str, Any]: Schéma de l'outil
        """
        return {
            "name": "add_memories",
            "description": "Ajoute une ou plusieurs mémoires au système",
            "parameters": {
                "type": "object",
                "properties": {
                    "memories": {
                        "type": "array",
                        "description": "Liste des mémoires à ajouter",
                        "items": {
                            "type": "object",
                            "properties": {
                                "content": {
                                    "type": "string",
                                    "description": "Contenu de la mémoire"
                                },
                                "metadata": {
                                    "type": "object",
                                    "description": "Métadonnées associées à la mémoire (optionnel)"
                                }
                            },
                            "required": ["content"]
                        }
                    }
                },
                "required": ["memories"]
            }
        }

def add_memories(memory_manager: MemoryManager, params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Implémentation de l'outil add_memories.
    
    Args:
        memory_manager (MemoryManager): Instance du gestionnaire de mémoire
        params (Dict[str, Any]): Paramètres de l'outil
    
    Returns:
        Dict[str, Any]: Résultat de l'opération
    
    Raises:
        ValueError: Si les paramètres sont invalides
    """
    # Valider les paramètres
    if "memories" not in params:
        raise ValueError("Le paramètre 'memories' est requis")
    
    memories = params["memories"]
    if not isinstance(memories, list):
        raise ValueError("Le paramètre 'memories' doit être une liste")
    
    # Ajouter chaque mémoire
    added_memories = []
    for memory in memories:
        if not isinstance(memory, dict):
            logger.warning(f"Mémoire ignorée car format invalide: {memory}")
            continue
        
        if "content" not in memory:
            logger.warning("Mémoire ignorée car 'content' est manquant")
            continue
        
        content = memory["content"]
        metadata = memory.get("metadata", {})
        
        # Ajouter la mémoire
        memory_id = memory_manager.add_memory(content, metadata)
        
        # Ajouter à la liste des mémoires ajoutées
        added_memories.append({
            "id": memory_id,
            "content": content,
            "metadata": metadata
        })
    
    # Préparer la réponse
    response = {
        "added_memories": added_memories,
        "count": len(added_memories)
    }
    
    return response

def register_tool(mcp_server, memory_manager: MemoryManager) -> None:
    """
    Enregistre l'outil add_memories auprès du serveur MCP.
    
    Args:
        mcp_server: Instance du serveur MCP
        memory_manager (MemoryManager): Instance du gestionnaire de mémoire
    """
    @mcp_server.tool(schema=AddMemoriesSchema.get_schema())
    def add_memories_tool(params: Dict[str, Any]) -> Dict[str, Any]:
        """Outil MCP pour ajouter des mémoires."""
        return add_memories(memory_manager, params)
    
    logger.info("Outil add_memories enregistré auprès du serveur MCP")
