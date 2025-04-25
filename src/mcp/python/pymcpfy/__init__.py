"""PyMCPfy: A Python library to MCP-fy web framework APIs."""

from .core import (
    MCPContext,
    MCPFunction,
    MCPRegistry,
    MCPResponse,
    MCPSchema,
    SchemaGenerator,
    BaseTransport,
    WebSocketTransport,
    HTTPTransport,
)
from .config import MCPConfig, TransportConfig, load_config

__version__ = "0.1.0"

__all__ = [
    "MCPContext",
    "MCPFunction",
    "MCPRegistry",
    "MCPResponse",
    "MCPSchema",
    "SchemaGenerator",
    "BaseTransport",
    "WebSocketTransport",
    "HTTPTransport",
    "MCPConfig",
    "TransportConfig",
    "load_config",
]
