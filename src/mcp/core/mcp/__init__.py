#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module principal pour le Core MCP.

Ce module contient les classes et fonctions pour le Core MCP.
"""

from .core import MCPCore
from .request import MCPRequest
from .response import MCPResponse
from .protocol import MCPProtocolHandler
from .tools_manager import ToolsManager, tool
from .memory_manager import MemoryManager, Memory
from .storage_provider import StorageProvider, FileStorageProvider
from .embedding_provider import EmbeddingProvider, DummyEmbeddingProvider, CachedEmbeddingProvider

__all__ = [
    "MCPCore",
    "MCPRequest",
    "MCPResponse",
    "MCPProtocolHandler",
    "ToolsManager",
    "tool",
    "MemoryManager",
    "Memory",
    "StorageProvider",
    "FileStorageProvider",
    "EmbeddingProvider",
    "DummyEmbeddingProvider",
    "CachedEmbeddingProvider"
]
