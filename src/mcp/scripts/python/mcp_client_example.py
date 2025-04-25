#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Exemple d'utilisation du serveur MCP PowerShell.

Ce script montre comment utiliser le client MCP pour interagir avec le serveur MCP PowerShell.
"""

import os
import sys
import json
import requests

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
    url = f"{base_url}/tools/{tool_name}"
    response = requests.post(url, json=params or {})
    response.raise_for_status()
    return response.json()

def main():
    """
    Fonction principale qui montre comment utiliser le client MCP.
    """
    # URL de base du serveur MCP
    base_url = "http://localhost:8000"

    print("=== Exemple d'utilisation du client MCP pour PowerShell ===")

    try:
        # Exemple 1: Exécuter une commande PowerShell simple
        print("\n=== Exemple 1: Exécuter une commande PowerShell simple ===")
        result = call_mcp_tool(base_url, "run_powershell_command", {"command": "Get-Date"})
        print(f"Résultat: {result}")

        # Exemple 2: Récupérer les informations système
        print("\n=== Exemple 2: Récupérer les informations système ===")
        system_info = call_mcp_tool(base_url, "get_system_info")
        print(f"Informations système:")
        print(f"- OS: {system_info.get('OsName', 'N/A')}")
        print(f"- Version: {system_info.get('OsVersion', 'N/A')}")
        print(f"- Architecture: {system_info.get('OsArchitecture', 'N/A')}")

        # Exemple 3: Détecter les serveurs MCP
        print("\n=== Exemple 3: Détecter les serveurs MCP ===")
        servers = call_mcp_tool(base_url, "find_mcp_servers")
        print(f"Serveurs MCP détectés ({len(servers)}):")
        for server in servers:
            if "error" in server:
                print(f"Erreur: {server['error']}")
            else:
                print(f"- {server.get('Type', 'N/A')} v{server.get('Version', 'N/A')} sur {server.get('Host', 'N/A')}:{server.get('Port', 'N/A')}")
    except Exception as e:
        print(f"Erreur: {e}")

    print("\n=== Fin de l'exemple ===")

if __name__ == "__main__":
    main()
