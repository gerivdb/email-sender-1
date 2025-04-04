#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour lancer le serveur MCP Git Ingest.
"""

import asyncio
import sys
import uvicorn
from fastapi import FastAPI
from mcp_git_ingest.main import FastMCP, git_directory_structure, git_read_important_files

async def main():
    """Fonction principale pour lancer le serveur MCP Git Ingest."""
    # Créer une application FastAPI
    app = FastAPI(title="MCP Git Ingest")

    # Ajouter un endpoint /health
    @app.get("/health")
    async def health_check():
        return {"status": "ok"}

    # Ajouter les endpoints pour les outils MCP Git Ingest
    from pydantic import BaseModel

    class DirectoryStructureRequest(BaseModel):
        repo_url: str

    class ReadFilesRequest(BaseModel):
        repo_url: str
        file_paths: list[str]

    @app.post("/tools/github_directory_structure")
    async def github_directory_structure(request: DirectoryStructureRequest):
        return await git_directory_structure(request.repo_url)

    @app.post("/tools/github_read_important_files")
    async def github_read_important_files(request: ReadFilesRequest):
        return await git_read_important_files(request.repo_url, request.file_paths)

    # Vérifier si nous devons utiliser STDIO ou HTTP
    if len(sys.argv) > 1 and sys.argv[1] == "--stdio":
        # Utiliser STDIO pour n8n et Augment
        mcp_app = FastMCP()
        await mcp_app.run_stdio_async()
    else:
        # Lancer le serveur HTTP
        config = uvicorn.Config(
            app=app,
            host="0.0.0.0",
            port=8001,
            log_level="info"
        )
        server = uvicorn.Server(config)
        await server.serve()

if __name__ == "__main__":
    asyncio.run(main())
