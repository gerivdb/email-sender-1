#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Serveur MCP pour les outils de code.

Ce script démarre un serveur MCP qui expose les outils de code.
"""

import os
import sys
import json
import argparse
import traceback
import logging
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
print(f"Ajout du répertoire parent au chemin de recherche: {parent_dir}")
sys.path.append(parent_dir)

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.code.server")

# Importer les modules nécessaires
try:
    from mcp.server.fastmcp import FastMCP
    from src.mcp.core.code.register_code_tools import register_code_tools
    print("Modules importés avec succès")
except ImportError as e:
    print(f"Erreur lors de l'importation des modules: {e}")
    traceback.print_exc()
    sys.exit(1)

def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description="Serveur MCP pour les outils de code")
    parser.add_argument("--base-path", help="Chemin de base pour le code")
    parser.add_argument("--cache-path", help="Chemin pour le cache des analyses")
    parser.add_argument("--host", default="localhost", help="Hôte du serveur MCP")
    parser.add_argument("--port", type=int, default=8080, help="Port du serveur MCP")
    
    # Analyser les arguments
    args = parser.parse_args()
    
    # Utiliser le répertoire courant comme base par défaut
    base_path = args.base_path or os.getcwd()
    
    try:
        # Initialiser le serveur MCP
        print(f"Initialisation du serveur MCP pour les outils de code...")
        mcp = FastMCP("code_server", host=args.host, port=args.port)
        
        # Enregistrer les outils de code
        print(f"Enregistrement des outils de code...")
        code_manager = register_code_tools(mcp, base_path, args.cache_path)
        
        # Ajouter un outil de test
        print("Ajout de l'outil de test ping...")
        @mcp.tool()
        def ping():
            """Outil simple pour tester si le serveur est en ligne."""
            return {"status": "ok", "message": "Le serveur MCP de code est en ligne"}
        print("Outil de test ping ajouté")
        
        # Démarrer le serveur MCP
        print(f"Démarrage du serveur MCP de code avec base: {base_path}")
        logger.info(f"Démarrage du serveur MCP de code avec base: {base_path}")
        mcp.run()
    except Exception as e:
        print(f"Erreur lors du démarrage du serveur MCP: {e}")
        traceback.print_exc()

if __name__ == "__main__":
    main()
