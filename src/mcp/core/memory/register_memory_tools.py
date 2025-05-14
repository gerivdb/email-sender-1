#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module pour enregistrer les outils de mémoire auprès du serveur MCP.

Ce module fournit une fonction pour enregistrer tous les outils de mémoire
auprès d'un serveur MCP.
"""

import logging
from typing import Any, Optional

from .MemoryManager import MemoryManager
from .tools import add_memories, search_memory, list_memories, delete_memories

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.memory.register")

def register_memory_tools(mcp_server: Any, storage_path: Optional[str] = None) -> MemoryManager:
    """
    Enregistre tous les outils de mémoire auprès du serveur MCP.
    
    Args:
        mcp_server: Instance du serveur MCP
        storage_path (Optional[str]): Chemin vers le fichier de stockage des mémoires
    
    Returns:
        MemoryManager: Instance du gestionnaire de mémoire
    """
    # Créer une instance du gestionnaire de mémoire
    memory_manager = MemoryManager(storage_path)
    
    # Enregistrer chaque outil
    add_memories.register_tool(mcp_server, memory_manager)
    search_memory.register_tool(mcp_server, memory_manager)
    list_memories.register_tool(mcp_server, memory_manager)
    delete_memories.register_tool(mcp_server, memory_manager)
    
    logger.info("Tous les outils de mémoire ont été enregistrés auprès du serveur MCP")
    
    return memory_manager
