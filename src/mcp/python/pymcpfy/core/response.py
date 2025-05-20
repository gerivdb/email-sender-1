"""MCP response module."""

from dataclasses import dataclass, field
from typing import Any, Dict, Optional

@dataclass
class MCPResponse:
    """Response from MCP request."""
    data: Any
    status: int = 200
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        """Convert response to dictionary."""
        return {
            "data": self.data,
            "status": self.status,
            "metadata": self.metadata
        }
