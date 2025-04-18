#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Serveur FastAPI qui expose des outils similaires à MCP.

Ce script crée un serveur FastAPI qui expose quelques outils via une API REST.
"""

import logging
import platform
import os
from fastapi import FastAPI
from pydantic import BaseModel
import uvicorn

# Configuration de la journalisation
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("mcp_server")

# Initialisation du serveur FastAPI
app = FastAPI(
    title="PowerShell MCP Server",
    description="Un serveur qui expose des outils pour PowerShell.",
    version="1.0.0"
)

# Modèles de données
class AddRequest(BaseModel):
    a: int
    b: int

class MultiplyRequest(BaseModel):
    a: int
    b: int

class SystemInfoResponse(BaseModel):
    os: str
    os_version: str
    python_version: str
    hostname: str
    cpu_count: int

# Routes
@app.get("/")
async def root():
    return {"message": "PowerShell MCP Server"}

@app.get("/tools")
async def list_tools():
    return [
        {
            "name": "add",
            "description": "Additionne deux nombres",
            "parameters": {"a": "int", "b": "int"},
            "returns": "int"
        },
        {
            "name": "multiply",
            "description": "Multiplie deux nombres",
            "parameters": {"a": "int", "b": "int"},
            "returns": "int"
        },
        {
            "name": "get_system_info",
            "description": "Retourne des informations sur le système",
            "parameters": {},
            "returns": "dict"
        }
    ]

@app.post("/tools/add")
async def add_tool(request: AddRequest):
    logger.info(f"Appel de la fonction add avec a={request.a}, b={request.b}")
    result = request.a + request.b
    logger.info(f"Résultat: {result}")
    return {"result": result}

@app.post("/tools/multiply")
async def multiply_tool(request: MultiplyRequest):
    logger.info(f"Appel de la fonction multiply avec a={request.a}, b={request.b}")
    result = request.a * request.b
    logger.info(f"Résultat: {result}")
    return {"result": result}

@app.post("/tools/get_system_info")
async def get_system_info_tool():
    logger.info("Appel de la fonction get_system_info")

    info = {
        "os": platform.system(),
        "os_version": platform.version(),
        "python_version": platform.python_version(),
        "hostname": platform.node(),
        "cpu_count": os.cpu_count()
    }

    logger.info(f"Résultat: {info}")
    return {"result": info}

# Point d'entrée principal
if __name__ == "__main__":
    # Configuration du serveur
    host = "localhost"
    port = 8000

    logger.info(f"Démarrage du serveur FastAPI sur {host}:{port}")
    logger.info("Utilisez Ctrl+C pour arrêter le serveur")

    # Démarrage du serveur avec uvicorn
    uvicorn.run(app, host=host, port=port)
