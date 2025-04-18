#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Serveur MCP pour exécuter des commandes PowerShell.

Ce script crée un serveur MCP qui permet d'exécuter des commandes PowerShell
et de récupérer les résultats. Il utilise le SDK MCP officiel d'Anthropic.
"""

import os
import sys
import json
import subprocess
from typing import List, Dict, Any, Optional
from mcp.server.fastmcp import FastMCP

# Initialisation du serveur MCP
mcp = FastMCP("powershell_server")

@mcp.tool()
def run_powershell_command(command: str) -> str:
    """
    Exécute une commande PowerShell et retourne le résultat.

    Args:
        command: La commande PowerShell à exécuter.

    Returns:
        Le résultat de l'exécution de la commande.
    """
    try:
        # Utiliser PowerShell 7 si disponible, sinon utiliser PowerShell standard
        powershell_exe = "pwsh" if os.system("where pwsh > nul 2>&1") == 0 else "powershell"

        # Exécuter la commande PowerShell
        result = subprocess.run(
            [powershell_exe, "-Command", command],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        return f"Erreur lors de l'exécution de la commande PowerShell: {e.stderr}"

@mcp.tool()
def get_system_info() -> Dict[str, Any]:
    """
    Récupère les informations système via PowerShell.

    Returns:
        Un dictionnaire contenant les informations système.
    """
    try:
        # Utiliser PowerShell 7 si disponible, sinon utiliser PowerShell standard
        powershell_exe = "pwsh" if os.system("where pwsh > nul 2>&1") == 0 else "powershell"

        # Exécuter la commande PowerShell pour récupérer les informations système
        result = subprocess.run(
            [powershell_exe, "-Command", "Get-ComputerInfo | ConvertTo-Json -Depth 1"],
            capture_output=True,
            text=True,
            check=True
        )

        # Convertir la sortie JSON en dictionnaire Python
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        return {"error": f"Erreur lors de la récupération des informations système: {e.stderr}"}
    except json.JSONDecodeError as e:
        return {"error": f"Erreur lors du décodage JSON: {e}"}

@mcp.tool()
def find_mcp_servers() -> List[Dict[str, Any]]:
    """
    Détecte les serveurs MCP disponibles en utilisant le module MCPManager.

    Returns:
        Une liste de serveurs MCP détectés.
    """
    try:
        # Utiliser PowerShell 7 si disponible, sinon utiliser PowerShell standard
        powershell_exe = "pwsh" if os.system("where pwsh > nul 2>&1") == 0 else "powershell"

        # Exécuter la commande PowerShell pour détecter les serveurs MCP
        result = subprocess.run(
            [powershell_exe, "-Command", "Import-Module .\\modules\\MCPManager.psm1; Find-MCPServers -Force | ConvertTo-Json -Depth 3"],
            capture_output=True,
            text=True,
            check=True
        )

        # Convertir la sortie JSON en liste Python
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        return [{"error": f"Erreur lors de la détection des serveurs MCP: {e.stderr}"}]
    except json.JSONDecodeError as e:
        return [{"error": f"Erreur lors du décodage JSON: {e}"}]

@mcp.tool()
def start_mcp_manager(agent: bool = False, query: Optional[str] = None) -> str:
    """
    Démarre le gestionnaire de serveurs MCP ou un agent MCP.

    Args:
        agent: Si True, démarre un agent MCP au lieu du gestionnaire de serveurs.
        query: La requête à exécuter par l'agent MCP (uniquement si agent=True).

    Returns:
        Le résultat de l'exécution de la commande.
    """
    try:
        # Utiliser PowerShell 7 si disponible, sinon utiliser PowerShell standard
        powershell_exe = "pwsh" if os.system("where pwsh > nul 2>&1") == 0 else "powershell"

        # Construire la commande PowerShell
        command = "Import-Module .\\modules\\MCPManager.psm1; "
        if agent:
            if query:
                command += f"Start-MCPManager -Agent -Query '{query}'"
            else:
                command += "Start-MCPManager -Agent"
        else:
            command += "Start-MCPManager"

        # Exécuter la commande PowerShell
        result = subprocess.run(
            [powershell_exe, "-Command", command],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        return f"Erreur lors du démarrage du gestionnaire MCP: {e.stderr}"

if __name__ == "__main__":
    # Démarrer le serveur MCP
    print("Démarrage du serveur MCP PowerShell sur localhost:8000...")
    # Définir les variables d'environnement pour le serveur MCP
    os.environ["MCP_HOST"] = "localhost"
    os.environ["MCP_PORT"] = "8000"
    # Démarrer le serveur MCP
    mcp.run()
