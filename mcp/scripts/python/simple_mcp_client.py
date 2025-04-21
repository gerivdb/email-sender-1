#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Client MCP simple pour tester l'intégration avec PowerShell.

Ce script montre comment utiliser le client MCP pour interagir avec le serveur MCP simple.
"""

import requests
import json

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
    
    print("=== Exemple d'utilisation du client MCP simple ===")
    
    try:
        # Exemple 1: Additionner deux nombres
        print("\n=== Exemple 1: Additionner deux nombres ===")
        result = call_mcp_tool(base_url, "add", {"a": 2, "b": 3})
        print(f"Résultat: 2 + 3 = {result}")
        
        # Exemple 2: Récupérer la date actuelle
        print("\n=== Exemple 2: Récupérer la date actuelle ===")
        result = call_mcp_tool(base_url, "get_date")
        print(f"Date actuelle: {result}")
        
        # Exemple 3: Récupérer les informations système
        print("\n=== Exemple 3: Récupérer les informations système ===")
        system_info = call_mcp_tool(base_url, "get_system_info")
        print(f"Informations système:")
        print(f"- OS: {system_info.get('OsName', 'N/A')}")
        print(f"- Version: {system_info.get('OsVersion', 'N/A')}")
        print(f"- Architecture: {system_info.get('OsArchitecture', 'N/A')}")
    except Exception as e:
        print(f"Erreur: {e}")
    
    print("\n=== Fin de l'exemple ===")

if __name__ == "__main__":
    main()
