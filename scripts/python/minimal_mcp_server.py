#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Serveur MCP minimal pour tester l'intégration avec PowerShell.

Ce script crée un serveur MCP minimal qui expose un outil simple.
"""

import os
import logging
from mcp.server.fastmcp import FastMCP

# Configuration de la journalisation
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("mcp_server")

# Initialisation du serveur MCP
mcp = FastMCP("minimal_server")

@mcp.tool()
def add(a: int, b: int) -> int:
    """Additionne deux nombres."""
    logger.info(f"Appel de la fonction add avec a={a}, b={b}")
    result = a + b
    logger.info(f"Résultat: {result}")
    return result

@mcp.tool()
def get_hello() -> str:
    """Retourne un message de salutation."""
    logger.info("Appel de la fonction get_hello")
    return "Hello from MCP Server!"

def start_server():
    """Démarre le serveur MCP avec transport SSE."""
    try:
        # Configuration du transport SSE
        port = 8000
        host = "localhost"
        logger.info(f"Configuration du transport SSE sur {host}:{port}")

        # Définir les variables d'environnement pour le serveur MCP
        os.environ["MCP_HOST"] = host
        os.environ["MCP_PORT"] = str(port)

        # Démarrage du serveur
        logger.info("Démarrage du serveur MCP...")
        mcp.run(transport="sse")
    except Exception as e:
        logger.error(f"Erreur lors du démarrage du serveur: {e}")
        raise

if __name__ == "__main__":
    print("Démarrage du serveur MCP minimal avec transport SSE...")
    print("Journalisation détaillée activée (niveau DEBUG)")
    print(f"Le serveur sera accessible à l'adresse: http://localhost:8000")

    try:
        # Exécution du serveur
        start_server()
    except KeyboardInterrupt:
        print("\nArrêt du serveur MCP...")
    except Exception as e:
        print(f"\nErreur fatale: {e}")
