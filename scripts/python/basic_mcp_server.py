#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Serveur MCP basique basé sur la documentation officielle.

Ce script crée un serveur MCP simple qui expose quelques outils de base.
"""

import logging
from mcp.server.fastmcp import FastMCP

# Configuration de la journalisation
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("basic_mcp_server")

# Initialisation du serveur MCP
mcp = FastMCP("basic_server")

@mcp.tool()
def add(a: int, b: int) -> int:
    """Additionne deux nombres."""
    logger.info(f"Appel de la fonction add avec a={a}, b={b}")
    result = a + b
    logger.info(f"Résultat: {result}")
    return result

@mcp.tool()
def hello(name: str = "World") -> str:
    """Retourne un message de salutation."""
    logger.info(f"Appel de la fonction hello avec name={name}")
    result = f"Hello, {name}!"
    logger.info(f"Résultat: {result}")
    return result

if __name__ == "__main__":
    print("Démarrage du serveur MCP basique...")
    print("Journalisation détaillée activée (niveau DEBUG)")
    print("Le serveur sera accessible via le protocole MCP")
    
    try:
        # Exécution du serveur avec le transport par défaut (stdio)
        mcp.run()
    except KeyboardInterrupt:
        print("\nArrêt du serveur MCP...")
    except Exception as e:
        print(f"\nErreur fatale: {e}")
