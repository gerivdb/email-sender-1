#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Client MCP en ligne de commande.

Ce script permet d'appeler un outil MCP via la ligne de commande.
"""

import sys
import json
import subprocess

def main():
    """
    Fonction principale.
    """
    # Paramètres fixes pour simplifier
    server_path = "scripts/python/mcp_example.py"
    tool_name = "add"
    parameters = {"a": 2, "b": 3}

    # Construire la requête d'initialisation
    init_request = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "0.1.0",
            "capabilities": {},
            "clientInfo": {
                "name": "mcp_cli",
                "version": "1.0.0"
            }
        }
    }

    # Construire la requête d'appel d'outil
    tool_request = {
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/call",
        "params": {
            "name": tool_name,
            "parameters": parameters
        }
    }

    # Convertir les requêtes en JSON
    init_json = json.dumps(init_request)
    tool_json = json.dumps(tool_request)
    print(f"Requête d'initialisation: {init_json}")
    print(f"Requête d'appel d'outil: {tool_json}")

    # Exécuter le serveur MCP et envoyer les requêtes
    try:
        print(f"Exécution du serveur MCP: {server_path}")
        process = subprocess.Popen(
            ["python", server_path],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        # Envoyer les requêtes au serveur
        stdout, stderr = process.communicate(input=init_json + "\n" + tool_json + "\n")

        # Analyser la réponse
        if stderr:
            print(f"Erreur du serveur: {stderr}")

        print(f"Réponse brute: {stdout}")

        # Extraire la réponse JSON
        for line in stdout.splitlines():
            try:
                response = json.loads(line)
                if "result" in response:
                    print(f"Résultat: {response['result']}")
                    return
                elif "error" in response:
                    print(f"Erreur du serveur: {response['error']}")
                    return
            except json.JSONDecodeError:
                continue

        print("Aucune réponse valide du serveur")
    except Exception as e:
        print(f"Erreur lors de l'appel à l'outil {tool_name}: {e}")

if __name__ == "__main__":
    main()
