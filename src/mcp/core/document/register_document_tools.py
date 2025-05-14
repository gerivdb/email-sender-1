#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module pour enregistrer les outils de document auprès du serveur MCP.

Ce module fournit une fonction pour enregistrer tous les outils de document
auprès d'un serveur MCP.
"""

import logging
from typing import Any, Optional

from .DocumentManager import DocumentManager
from .tools import fetch_documentation, search_documentation, read_file

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.document.register")

def register_document_tools(mcp_server: Any, base_path: Optional[str] = None, cache_path: Optional[str] = None) -> DocumentManager:
    """
    Enregistre tous les outils de document auprès du serveur MCP.
    
    Args:
        mcp_server: Instance du serveur MCP
        base_path (Optional[str]): Chemin de base pour les documents
        cache_path (Optional[str]): Chemin pour le cache des documents
    
    Returns:
        DocumentManager: Instance du gestionnaire de documents
    """
    # Créer une instance du gestionnaire de documents
    document_manager = DocumentManager(base_path, cache_path)
    
    # Enregistrer chaque outil
    fetch_documentation.register_tool(mcp_server, document_manager)
    search_documentation.register_tool(mcp_server, document_manager)
    read_file.register_tool(mcp_server, document_manager)
    
    logger.info("Tous les outils de document ont été enregistrés auprès du serveur MCP")
    
    return document_manager
