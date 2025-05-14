#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Exemple de serveur MCP avec outils de gestion de mémoire.

Ce script crée un serveur MCP minimal qui expose les outils de gestion de mémoire.
"""

import os
import sys
import logging
import traceback
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
print(f"Ajout du répertoire parent au chemin de recherche: {parent_dir}")
sys.path.append(parent_dir)

# Afficher le chemin de recherche des modules
print("Chemin de recherche des modules:")
for path in sys.path:
    print(f"  - {path}")

# Importer les modules MCP
try:
    print("Importation des modules MCP...")
    from mcp.server.fastmcp import FastMCP
    from mcp.core.memory.register_memory_tools import register_memory_tools
    print("Modules MCP importés avec succès")
except ImportError as e:
    print(f"Erreur lors de l'importation des modules MCP: {e}")
    traceback.print_exc()
    sys.exit(1)

# Configuration de la journalisation
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("memory_mcp_server")

def main():
    """Fonction principale pour démarrer le serveur MCP."""
    try:
        # Définir le chemin de stockage des mémoires
        user_home = os.path.expanduser("~")
        storage_path = os.path.join(user_home, ".mcp", "memory", "memories.json")
        print(f"Chemin de stockage des mémoires: {storage_path}")

        # Créer le dossier de stockage s'il n'existe pas
        os.makedirs(os.path.dirname(storage_path), exist_ok=True)
        print("Dossier de stockage créé ou existant")

        # Initialiser le serveur MCP
        print("Initialisation du serveur MCP...")
        mcp = FastMCP("memory_server")
        print("Serveur MCP initialisé")

        # Enregistrer les outils de mémoire
        print("Enregistrement des outils de mémoire...")
        memory_manager = register_memory_tools(mcp, storage_path)
        print("Outils de mémoire enregistrés")

        # Ajouter un outil de test
        print("Ajout de l'outil de test ping...")
        @mcp.tool()
        def ping():
            """Outil simple pour tester si le serveur est en ligne."""
            return {"status": "ok", "message": "Le serveur MCP de mémoire est en ligne"}
        print("Outil de test ping ajouté")

        # Démarrer le serveur MCP
        print(f"Démarrage du serveur MCP de mémoire avec stockage: {storage_path}")
        logger.info(f"Démarrage du serveur MCP de mémoire avec stockage: {storage_path}")
        mcp.run()
    except Exception as e:
        print(f"Erreur lors du démarrage du serveur MCP: {e}")
        traceback.print_exc()

if __name__ == "__main__":
    main()
