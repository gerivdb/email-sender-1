#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module pour enregistrer les outils de code auprès du serveur MCP.

Ce module fournit une fonction pour enregistrer tous les outils de code auprès du serveur MCP.
"""

import os
import logging
from typing import Dict, List, Any, Optional

from src.mcp.core.code.CodeManager import CodeManager
from src.mcp.core.code.tools import search_code, analyze_code, get_code_structure

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.code")

def register_code_tools(mcp_server, base_path: Optional[str] = None, cache_path: Optional[str] = None) -> CodeManager:
    """
    Enregistre tous les outils de code auprès du serveur MCP.
    
    Args:
        mcp_server: Instance du serveur MCP
        base_path (Optional[str]): Chemin de base pour le code
        cache_path (Optional[str]): Chemin pour le cache des analyses
    
    Returns:
        CodeManager: Instance du gestionnaire de code
    """
    # Créer une instance du gestionnaire de code
    code_manager = CodeManager(base_path, cache_path)
    
    # Enregistrer chaque outil
    search_code.register_tool(mcp_server, code_manager)
    analyze_code.register_tool(mcp_server, code_manager)
    get_code_structure.register_tool(mcp_server, code_manager)
    
    logger.info("Tous les outils de code ont été enregistrés auprès du serveur MCP")
    
    return code_manager
