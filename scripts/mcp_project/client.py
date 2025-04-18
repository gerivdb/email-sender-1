#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Client Python pour tester le serveur MCP.

Ce script montre comment utiliser le client MCP pour interagir avec le serveur MCP.
"""

import logging
import requests

# Configuration de la journalisation
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("mcp_client")

def call_mcp_tool(server_url, tool_name, parameters=None):
    """
    Appelle un outil MCP via l'API REST.

    Args:
        server_url: L'URL du serveur MCP.
        tool_name: Le nom de l'outil à appeler.
        parameters: Les paramètres à passer à l'outil.

    Returns:
        Le résultat de l'appel à l'outil.
    """
    url = f"{server_url}/tools/{tool_name}"
    logger.info(f"Appel de l'outil {tool_name} à l'URL {url}")

    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json"
    }

    try:
        response = requests.post(url, json=parameters or {}, headers=headers)
        response.raise_for_status()
        logger.info(f"Réponse: {response.text}")
        return response.json()
    except Exception as e:
        logger.error(f"Erreur lors de l'appel à l'outil {tool_name}: {e}")
        raise

def main():
    """
    Fonction principale qui montre comment utiliser le client MCP.
    """
    # URL du serveur MCP
    server_url = "http://localhost:8000"

    logger.info(f"Connexion au serveur MCP à l'adresse {server_url}")

    try:
        # Exemple 1: Additionner deux nombres
        logger.info("Exemple 1: Additionner deux nombres")
        add_result = call_mcp_tool(server_url, "add", {"a": 2, "b": 3})
        logger.info(f"Résultat de l'addition: 2 + 3 = {add_result}")

        # Exemple 2: Multiplier deux nombres
        logger.info("Exemple 2: Multiplier deux nombres")
        multiply_result = call_mcp_tool(server_url, "multiply", {"a": 4, "b": 5})
        logger.info(f"Résultat de la multiplication: 4 * 5 = {multiply_result}")

        # Exemple 3: Obtenir des informations sur le système
        logger.info("Exemple 3: Obtenir des informations sur le système")
        system_info = call_mcp_tool(server_url, "get_system_info", {})
        logger.info(f"Informations système: {system_info}")
    except Exception as e:
        logger.error(f"Erreur lors de la connexion au serveur MCP: {e}")

if __name__ == "__main__":
    # Exécution de la fonction principale
    main()
