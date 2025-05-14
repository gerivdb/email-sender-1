#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Client pour tester le Core MCP.

Ce script montre comment interagir avec un serveur MCP basé sur le Core MCP.
"""

import os
import sys
import json
import uuid
import time
import logging
import subprocess
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
print(f"Ajout du répertoire parent au chemin de recherche: {parent_dir}")
sys.path.append(parent_dir)

# Configuration du logger
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("core_mcp_client")

def send_request(server_process, method, params=None):
    """
    Envoie une requête au serveur MCP.

    Args:
        server_process: Processus du serveur MCP
        method: Méthode à appeler
        params: Paramètres de la méthode

    Returns:
        Réponse du serveur
    """
    # Créer la requête
    request = {
        "jsonrpc": "2.0",
        "id": str(uuid.uuid4()),
        "method": method,
        "params": params or {}
    }

    # Convertir la requête en JSON
    request_json = json.dumps(request)
    logger.info(f"Envoi de la requête: {request_json}")

    # Attendre un peu que le serveur démarre
    time.sleep(0.1)

    # Envoyer la requête au serveur
    server_process.stdin.write(request_json + "\n")
    server_process.stdin.flush()

    # Attendre et lire la réponse
    response_json = None
    timeout = 5  # Timeout en secondes
    start_time = time.time()
    debug_output = []

    while time.time() - start_time < timeout:
        response_line = server_process.stdout.readline().strip()
        if not response_line:
            time.sleep(0.1)
            continue

        logger.info(f"Ligne reçue: {response_line}")
        debug_output.append(response_line)

        # Essayer de parser la ligne comme du JSON
        try:
            response_data = json.loads(response_line)
            if isinstance(response_data, dict) and "jsonrpc" in response_data and "id" in response_data:
                response_json = response_data
                break
        except json.JSONDecodeError:
            # Ce n'est pas du JSON valide, c'est probablement un message de débogage
            continue

    if response_json:
        logger.info(f"Réponse JSON valide reçue: {json.dumps(response_json)}")
        return response_json
    else:
        logger.error("Aucune réponse JSON valide reçue après timeout")
        logger.error(f"Sortie de débogage: {debug_output}")

        # Essayer de lire plus de lignes pour voir s'il y a un problème
        for _ in range(5):
            line = server_process.stdout.readline().strip()
            if line:
                logger.error(f"Ligne supplémentaire: {line}")

        return None

def main():
    """
    Fonction principale.
    """
    # Chemin vers le script du serveur MCP
    server_script = os.path.join(parent_dir, "src", "mcp", "examples", "core_mcp_example.py")

    # Démarrer le serveur MCP
    logger.info(f"Démarrage du serveur MCP: {server_script}")
    server_process = subprocess.Popen(
        [sys.executable, server_script],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1  # Line buffered
    )

    try:
        # Attendre que le serveur démarre
        import time
        time.sleep(1)

        # Exemple 1: Lister les outils disponibles
        logger.info("Exemple 1: Lister les outils disponibles")
        response = send_request(server_process, "listTools")
        if response and "result" in response:
            tools = response["result"].get("tools", [])
            logger.info(f"Outils disponibles ({len(tools)}):")
            for tool in tools:
                logger.info(f"  - {tool['name']}: {tool['description']}")

        # Exemple 2: Exécuter l'outil add
        logger.info("Exemple 2: Exécuter l'outil add")
        response = send_request(server_process, "executeTool", {
            "name": "add",
            "arguments": {"a": 2, "b": 3}
        })
        if response and "result" in response:
            result = response["result"].get("result")
            logger.info(f"Résultat de l'addition: 2 + 3 = {result}")

        # Exemple 3: Exécuter l'outil multiply
        logger.info("Exemple 3: Exécuter l'outil multiply")
        response = send_request(server_process, "executeTool", {
            "name": "multiply",
            "arguments": {"a": 4, "b": 5}
        })
        if response and "result" in response:
            result = response["result"].get("result")
            logger.info(f"Résultat de la multiplication: 4 * 5 = {result}")

        # Exemple 4: Récupérer le schéma de l'outil get_system_info
        logger.info("Exemple 4: Récupérer le schéma de l'outil get_system_info")
        response = send_request(server_process, "getSchema", {
            "name": "get_system_info"
        })
        if response and "result" in response:
            schema = response["result"].get("schema")
            logger.info(f"Schéma de l'outil get_system_info: {json.dumps(schema, indent=2)}")

        # Exemple 5: Exécuter l'outil get_system_info
        logger.info("Exemple 5: Exécuter l'outil get_system_info")
        response = send_request(server_process, "executeTool", {
            "name": "get_system_info",
            "arguments": {}
        })
        if response and "result" in response:
            result = response["result"].get("result")
            logger.info(f"Informations système:")
            for key, value in result.items():
                logger.info(f"  - {key}: {value}")

        # Exemple 6: Récupérer le statut du serveur
        logger.info("Exemple 6: Récupérer le statut du serveur")
        response = send_request(server_process, "getStatus")
        if response and "result" in response:
            status = response["result"]
            logger.info(f"Statut du serveur:")
            for key, value in status.items():
                logger.info(f"  - {key}: {value}")

        # Exemple 7: Appeler une méthode inexistante
        logger.info("Exemple 7: Appeler une méthode inexistante")
        response = send_request(server_process, "nonExistentMethod")
        if response and "error" in response:
            error = response["error"]
            logger.info(f"Erreur: {error['message']} (code: {error['code']})")

        # Exemple 8: Appeler un outil inexistant
        logger.info("Exemple 8: Appeler un outil inexistant")
        response = send_request(server_process, "executeTool", {
            "name": "nonExistentTool",
            "arguments": {}
        })
        if response and "error" in response:
            error = response["error"]
            logger.info(f"Erreur: {error['message']} (code: {error['code']})")

    finally:
        # Arrêter le serveur MCP
        logger.info("Arrêt du serveur MCP")
        server_process.terminate()
        server_process.wait()

if __name__ == "__main__":
    main()
