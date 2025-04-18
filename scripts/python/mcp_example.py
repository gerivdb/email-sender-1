#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Exemple minimal de serveur MCP.

Ce script crée un serveur MCP minimal qui expose un outil simple.
"""

from mcp.server.fastmcp import FastMCP

# Initialisation du serveur MCP
mcp = FastMCP("example_server")

@mcp.tool()
def add(a: int, b: int) -> int:
    """Additionne deux nombres."""
    return a + b

if __name__ == "__main__":
    # Démarrage du serveur MCP
    mcp.run()
