"""Base transport interface for MCP."""

from abc import ABC, abstractmethod
from typing import Optional

from ..mcp_protocol import MCPRegistry

class BaseTransport(ABC):
    """Abstract base class for MCP transports."""

    def __init__(self, registry: MCPRegistry):
        """Initialize the transport with an MCP registry."""
        self.registry = registry

    @abstractmethod
    async def start(self):
        """Start the transport server."""
        pass

    @abstractmethod
    async def stop(self):
        """Stop the transport server."""
        pass
