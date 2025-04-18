#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour le serveur FastAPI.

Ce script contient les tests unitaires pour le serveur FastAPI qui expose des outils similaires à MCP.
"""

import os
import sys
import platform
import pytest
from fastapi.testclient import TestClient

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Importer le serveur
from mcp_project.server import app, add_tool, multiply_tool, get_system_info_tool

# Créer un client de test
client = TestClient(app)

# Tests des fonctions individuelles
@pytest.mark.asyncio
async def test_add_function():
    """Teste la fonction add."""
    from mcp_project.server import AddRequest

    # Créer une requête
    request = AddRequest(a=2, b=3)

    # Appeler la fonction
    result = await add_tool(request)

    # Vérifier le résultat
    assert result["result"] == 5

@pytest.mark.asyncio
async def test_multiply_function():
    """Teste la fonction multiply."""
    from mcp_project.server import MultiplyRequest

    # Créer une requête
    request = MultiplyRequest(a=4, b=5)

    # Appeler la fonction
    result = await multiply_tool(request)

    # Vérifier le résultat
    assert result["result"] == 20

@pytest.mark.asyncio
async def test_get_system_info_function():
    """Teste la fonction get_system_info."""
    # Appeler la fonction
    result = await get_system_info_tool()

    # Vérifier le résultat
    assert "result" in result
    assert "os" in result["result"]
    assert "os_version" in result["result"]
    assert "python_version" in result["result"]
    assert "hostname" in result["result"]
    assert "cpu_count" in result["result"]

    # Vérifier que les valeurs sont correctes
    assert result["result"]["os"] == platform.system()
    assert result["result"]["os_version"] == platform.version()
    assert result["result"]["python_version"] == platform.python_version()
    assert result["result"]["hostname"] == platform.node()
    assert result["result"]["cpu_count"] == os.cpu_count()

# Tests des endpoints API
def test_root_endpoint():
    """Teste l'endpoint racine."""
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "PowerShell MCP Server"}

def test_list_tools_endpoint():
    """Teste l'endpoint de liste des outils."""
    response = client.get("/tools")
    assert response.status_code == 200
    assert len(response.json()) == 3

    # Vérifier que les outils attendus sont présents
    tools = response.json()
    tool_names = [tool["name"] for tool in tools]
    assert "add" in tool_names
    assert "multiply" in tool_names
    assert "get_system_info" in tool_names

def test_add_endpoint():
    """Teste l'endpoint add."""
    response = client.post(
        "/tools/add",
        json={"a": 2, "b": 3}
    )
    assert response.status_code == 200
    assert response.json() == {"result": 5}

def test_multiply_endpoint():
    """Teste l'endpoint multiply."""
    response = client.post(
        "/tools/multiply",
        json={"a": 4, "b": 5}
    )
    assert response.status_code == 200
    assert response.json() == {"result": 20}

def test_get_system_info_endpoint():
    """Teste l'endpoint get_system_info."""
    response = client.post("/tools/get_system_info")
    assert response.status_code == 200
    assert "result" in response.json()
    assert "os" in response.json()["result"]
    assert "os_version" in response.json()["result"]
    assert "python_version" in response.json()["result"]
    assert "hostname" in response.json()["result"]
    assert "cpu_count" in response.json()["result"]

# Tests des cas d'erreur
def test_add_endpoint_with_invalid_input():
    """Teste l'endpoint add avec des entrées invalides."""
    response = client.post(
        "/tools/add",
        json={"a": "invalid", "b": 3}
    )
    assert response.status_code == 422  # Unprocessable Entity

def test_multiply_endpoint_with_invalid_input():
    """Teste l'endpoint multiply avec des entrées invalides."""
    response = client.post(
        "/tools/multiply",
        json={"a": 4, "b": "invalid"}
    )
    assert response.status_code == 422  # Unprocessable Entity

def test_nonexistent_endpoint():
    """Teste un endpoint qui n'existe pas."""
    response = client.post("/tools/nonexistent")
    assert response.status_code == 404  # Not Found

if __name__ == "__main__":
    pytest.main(["-v", __file__])
