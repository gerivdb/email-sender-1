#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Client MCP minimal pour tester l'intégration avec PowerShell.

Ce script montre comment utiliser le client MCP pour interagir avec le serveur MCP minimal.
"""

import requests
import json
import logging

# Configuration de la journalisation
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("mcp_client")

def call_mcp_tool(base_url, tool_name, params=None):
    """
    Appelle un outil MCP via l'API REST.

    Args:
        base_url: L'URL de base du serveur MCP.
        tool_name: Le nom de l'outil à appeler.
        params: Les paramètres à passer à l'outil.

    Returns:
        Le résultat de l'appel à l'outil.
    """
    # Essayer différentes URL possibles pour le protocole MCP
    urls = [
        f"{base_url}/tools/{tool_name}",
        f"{base_url}/api/tools/{tool_name}",
        f"{base_url}/mcp/tools/{tool_name}",
        f"{base_url}/v1/tools/{tool_name}",
        f"{base_url}/mcp/v1/tools/{tool_name}",
        f"{base_url}/api/v1/tools/{tool_name}"
    ]

    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json"
    }

    for url in urls:
        try:
            logger.info(f"Essai de l'URL: {url}")
            print(f"Essai de l'URL: {url}")
            print(f"Paramètres: {params}")

            response = requests.post(url, json=params or {}, headers=headers)
            print(f"Statut de la réponse: {response.status_code}")
            logger.debug(f"Réponse complète: {response.text}")

            if response.status_code == 200:
                return response.json()
        except Exception as e:
            logger.error(f"Erreur avec l'URL {url}: {e}")
            print(f"Erreur avec l'URL {url}: {e}")

    # Si aucune URL ne fonctionne, explorer le serveur pour trouver les endpoints disponibles
    try:
        logger.info("Exploration du serveur pour trouver les endpoints disponibles...")
        print("\nExploration du serveur pour trouver les endpoints disponibles...")

        # Essayer de récupérer la racine du serveur
        response = requests.get(base_url)
        print(f"GET {base_url} - Statut: {response.status_code}")
        if response.status_code == 200:
            print(f"Contenu: {response.text[:500]}...")

        # Essayer de récupérer les routes /docs (FastAPI)
        docs_url = f"{base_url}/docs"
        response = requests.get(docs_url)
        print(f"GET {docs_url} - Statut: {response.status_code}")

        # Essayer de récupérer les routes /openapi.json (FastAPI)
        openapi_url = f"{base_url}/openapi.json"
        response = requests.get(openapi_url)
        print(f"GET {openapi_url} - Statut: {response.status_code}")
        if response.status_code == 200:
            api_spec = response.json()
            print("Routes disponibles:")
            for path in api_spec.get("paths", {}):
                print(f"  - {path}")
    except Exception as e:
        logger.error(f"Erreur lors de l'exploration du serveur: {e}")
        print(f"Erreur lors de l'exploration du serveur: {e}")

    raise Exception(f"Impossible d'appeler l'outil {tool_name}. Aucune URL ne fonctionne.")

def main():
    """
    Fonction principale qui montre comment utiliser le client MCP.
    """
    # URL de base du serveur MCP
    base_url = "http://localhost:8000"

    print("=== Exemple d'utilisation du client MCP minimal ===")

    try:
        # Exemple 1: Obtenir un message de salutation
        print("\n=== Exemple 1: Obtenir un message de salutation ===")
        result = call_mcp_tool(base_url, "get_hello", {})
        print(f"Résultat: {result}")

        # Exemple 2: Additionner deux nombres
        print("\n=== Exemple 2: Additionner deux nombres ===")
        result = call_mcp_tool(base_url, "add", {"a": 2, "b": 3})
        print(f"Résultat: 2 + 3 = {result}")
    except Exception as e:
        logger.error(f"Erreur: {e}")
        print(f"Erreur: {e}")

    print("\n=== Fin de l'exemple ===")

if __name__ == "__main__":
    main()
