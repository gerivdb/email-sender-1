#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Serveur MCP simple pour tester l'intégration avec PowerShell.

Ce script crée un serveur MCP simple qui expose quelques outils de base.
"""

import os
import json
import subprocess
from mcp.server.fastmcp import FastMCP

# Initialisation du serveur MCP
mcp = FastMCP("simple_server")

@mcp.tool()
def add(a: int, b: int) -> int:
    """Additionne deux nombres."""
    return a + b

@mcp.tool()
def get_date() -> str:
    """Récupère la date actuelle via PowerShell."""
    try:
        # Utiliser PowerShell 7 si disponible, sinon utiliser PowerShell standard
        powershell_exe = "pwsh" if os.system("where pwsh > nul 2>&1") == 0 else "powershell"
        
        # Exécuter la commande PowerShell
        result = subprocess.run(
            [powershell_exe, "-Command", "Get-Date"],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        return f"Erreur: {e.stderr}"

@mcp.tool()
def get_system_info() -> dict:
    """Récupère les informations système via PowerShell."""
    try:
        # Utiliser PowerShell 7 si disponible, sinon utiliser PowerShell standard
        powershell_exe = "pwsh" if os.system("where pwsh > nul 2>&1") == 0 else "powershell"
        
        # Exécuter la commande PowerShell
        result = subprocess.run(
            [powershell_exe, "-Command", "Get-ComputerInfo | Select-Object OsName, OsVersion, OsArchitecture | ConvertTo-Json"],
            capture_output=True,
            text=True,
            check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        return {"error": f"Erreur: {e.stderr}"}
    except json.JSONDecodeError:
        return {"error": "Erreur lors du décodage JSON"}

if __name__ == "__main__":
    print("Démarrage du serveur MCP simple sur localhost:8000...")
    # Définir les variables d'environnement pour le serveur MCP
    os.environ["MCP_HOST"] = "localhost"
    os.environ["MCP_PORT"] = "8000"
    # Démarrer le serveur MCP
    mcp.run()
