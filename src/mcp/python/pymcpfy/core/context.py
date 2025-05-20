"""Context object for MCP-wrapped functions."""

from typing import Any, Dict, Optional
from dataclasses import dataclass, field

@dataclass
class MCPContext:
    """Context object passed to MCP-wrapped functions."""
    transport: Any
    connection: Any
    metadata: Dict[str, Any] = field(default_factory=dict)
    raw_request: Optional[Dict[str, Any]] = None
