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

@mcp.tool()
def multiply(a: int, b: int) -> int:
    """Multiplie deux nombres."""
    logger.info(f"Appel de la fonction multiply avec a={a}, b={b}")
    result = a * b
    logger.info(f"Résultat: {result}")
    return result

@mcp.tool()
def divide(a: int, b: int) -> float:
    """Divise deux nombres."""
    logger.info(f"Appel de la fonction divide avec a={a}, b={b}")
    if b == 0:
        logger.error("Division par zéro")
        raise ValueError("Division par zéro")
    result = a / b
    logger.info(f"Résultat: {result}")
    return result

@mcp.tool()
def get_system_info() -> dict:
    """Retourne des informations sur le système."""
    logger.info("Appel de la fonction get_system_info")
    import platform

    system_info = {
        "os": platform.system(),
        "version": platform.version(),
        "architecture": platform.architecture(),
        "processor": platform.processor(),
        "hostname": platform.node(),
        "python_version": platform.python_version()
    }

    logger.info(f"Informations système: {system_info}")
    return system_info

@mcp.tool()
def echo(text: str) -> str:
    """Retourne le texte fourni."""
    logger.info(f"Appel de la fonction echo avec text={text}")
    return text

@mcp.tool()
def concat(strings: list) -> str:
    """Concatène une liste de chaînes de caractères."""
    logger.info(f"Appel de la fonction concat avec strings={strings}")
    result = "".join(strings)
    logger.info(f"Résultat: {result}")
    return result

@mcp.tool()
def sleep(seconds: int) -> str:
    """Attend le nombre de secondes spécifié."""
    import time
    logger.info(f"Appel de la fonction sleep avec seconds={seconds}")
    time.sleep(seconds)
    logger.info(f"Fin de l'attente de {seconds} secondes")
    return f"Waited for {seconds} seconds"

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
