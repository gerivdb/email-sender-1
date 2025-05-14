#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Exemple d'utilisation du Core MCP.

Ce script montre comment utiliser le Core MCP pour créer un serveur MCP simple.
"""

import os
import sys
import logging
import platform
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
print(f"Ajout du répertoire parent au chemin de recherche: {parent_dir}")
sys.path.append(parent_dir)

# Importer les modules nécessaires
try:
    from src.mcp.core.mcp import MCPCore
    print("Modules importés avec succès")
except ImportError as e:
    print(f"Erreur lors de l'importation des modules: {e}")
    sys.exit(1)

# Configuration du logger
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("core_mcp_example")

def main():
    """
    Fonction principale.
    """
    # Créer une instance du Core MCP
    mcp = MCPCore("example_server", "1.0.0")
    
    # Enregistrer quelques outils
    @mcp.tool()
    def add(a: int, b: int) -> int:
        """Additionne deux nombres."""
        return a + b
    
    @mcp.tool()
    def multiply(a: int, b: int) -> int:
        """Multiplie deux nombres."""
        return a * b
    
    @mcp.tool()
    def get_system_info() -> dict:
        """Récupère des informations sur le système."""
        return {
            "os": platform.system(),
            "os_version": platform.version(),
            "python_version": platform.python_version(),
            "hostname": platform.node(),
            "cpu_count": os.cpu_count()
        }
    
    # Démarrer le serveur MCP
    try:
        logger.info("Démarrage du serveur MCP...")
        mcp.start(protocol="stdio")
    except KeyboardInterrupt:
        logger.info("Interruption clavier, arrêt du serveur")
    except Exception as e:
        logger.error(f"Erreur lors du démarrage du serveur: {e}")
    finally:
        mcp.stop()

if __name__ == "__main__":
    main()
