#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Client MCP basique pour tester le serveur MCP.

Ce script montre comment utiliser le client MCP pour interagir avec le serveur MCP basique.
"""

import subprocess
import json
import logging

# Configuration de la journalisation
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("basic_mcp_client")

def call_mcp_tool(server_path, tool_name, params=None):
    """
    Appelle un outil MCP via le protocole MCP standard (stdio).
    
    Args:
        server_path: Le chemin vers le script du serveur MCP.
        tool_name: Le nom de l'outil à appeler.
        params: Les paramètres à passer à l'outil.
        
    Returns:
        Le résultat de l'appel à l'outil.
    """
    # Construire la requête JSON-RPC
    request = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "callTool",
        "params": {
            "name": tool_name,
            "parameters": params or {}
        }
    }
    
    # Convertir la requête en JSON
    request_json = json.dumps(request)
    logger.info(f"Requête: {request_json}")
    
    # Exécuter le serveur MCP et envoyer la requête
    try:
        logger.info(f"Exécution du serveur MCP: {server_path}")
        process = subprocess.Popen(
            ["python", server_path],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Envoyer la requête au serveur
        stdout, stderr = process.communicate(input=request_json + "\n")
        
        # Analyser la réponse
        if stderr:
            logger.error(f"Erreur du serveur: {stderr}")
        
        logger.info(f"Réponse brute: {stdout}")
        
        # Extraire la réponse JSON
        for line in stdout.splitlines():
            try:
                response = json.loads(line)
                if "result" in response:
                    return response["result"]
                elif "error" in response:
                    raise Exception(f"Erreur du serveur: {response['error']}")
            except json.JSONDecodeError:
                continue
        
        raise Exception("Aucune réponse valide du serveur")
    except Exception as e:
        logger.error(f"Erreur lors de l'appel à l'outil {tool_name}: {e}")
        raise

def main():
    """
    Fonction principale qui montre comment utiliser le client MCP.
    """
    # Chemin vers le script du serveur MCP
    server_path = "scripts/python/basic_mcp_server.py"
    
    print("=== Exemple d'utilisation du client MCP basique ===")
    
    try:
        # Exemple 1: Obtenir un message de salutation
        print("\n=== Exemple 1: Obtenir un message de salutation ===")
        result = call_mcp_tool(server_path, "hello", {"name": "PowerShell"})
        print(f"Résultat: {result}")
        
        # Exemple 2: Additionner deux nombres
        print("\n=== Exemple 2: Additionner deux nombres ===")
        result = call_mcp_tool(server_path, "add", {"a": 2, "b": 3})
        print(f"Résultat: 2 + 3 = {result}")
    except Exception as e:
        logger.error(f"Erreur: {e}")
        print(f"Erreur: {e}")
    
    print("\n=== Fin de l'exemple ===")

if __name__ == "__main__":
    main()
