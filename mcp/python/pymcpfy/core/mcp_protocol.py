"""Core MCP protocol implementation for PyMCPfy."""

from dataclasses import dataclass
from typing import Any, Callable, Dict, List, Optional, Type, Union
from pydantic import BaseModel

class MCPSchema(BaseModel):
    """Schema for an MCP-exposed function."""
    name: str
    description: str
    parameters: Dict[str, Dict[str, Any]]
    return_type: Dict[str, Any]
    is_async: bool = False

@dataclass
class MCPContext:
    """Context object passed to MCP-wrapped functions."""
    request_id: str
    metadata: Dict[str, Any]
    transport: str
    raw_request: Any

class MCPResponse:
    """Wrapper for responses from MCP-exposed functions."""
    def __init__(self, data: Any, status: int = 200, metadata: Optional[Dict[str, Any]] = None):
        self.data = data
        self.status = status
        self.metadata = metadata or {}

    def to_dict(self) -> Dict[str, Any]:
        """Convert response to MCP-compatible dictionary."""
        return {
            "data": self.data,
            "status": self.status,
            "metadata": self.metadata
        }

class MCPFunction:
    """Wrapper for functions exposed via MCP."""
    def __init__(
        self,
        func: Callable,
        name: Optional[str] = None,
        description: Optional[str] = None,
        parameter_types: Optional[Dict[str, Type]] = None,
        return_type: Optional[Type] = None,
        is_async: bool = False
    ):
        self.func = func
        self.name = name or func.__name__
        self.description = description or func.__doc__ or ""
        self.parameter_types = parameter_types or {}
        self.return_type = return_type
        self.is_async = is_async

    def generate_schema(self) -> MCPSchema:
        """Generate MCP schema for the function."""
        parameters = {}
        for name, type_ in self.parameter_types.items():
            parameters[name] = {
                "type": self._get_type_schema(type_),
                "description": f"Parameter {name}"  # Could be enhanced with docstring parsing
            }

        return MCPSchema(
            name=self.name,
            description=self.description,
            parameters=parameters,
            return_type=self._get_type_schema(self.return_type or Any),
            is_async=self.is_async
        )

    @staticmethod
    def _get_type_schema(type_: Type) -> Dict[str, Any]:
        """Convert Python type to MCP type schema."""
        if type_ == str:
            return {"type": "string"}
        elif type_ == int:
            return {"type": "integer"}
        elif type_ == float:
            return {"type": "number"}
        elif type_ == bool:
            return {"type": "boolean"}
        elif type_ == List:
            return {"type": "array"}
        elif type_ == Dict:
            return {"type": "object"}
        else:
            return {"type": "any"}

class MCPRegistry:
    """Registry for MCP-exposed functions."""
    def __init__(self):
        self.functions: Dict[str, MCPFunction] = {}

    def register(
        self,
        func: Union[Callable, MCPFunction],
        name: Optional[str] = None,
        description: Optional[str] = None,
        parameter_types: Optional[Dict[str, Type]] = None,
        return_type: Optional[Type] = None,
        is_async: bool = False
    ) -> MCPFunction:
        """Register a function with the MCP registry."""
        if isinstance(func, MCPFunction):
            mcp_func = func
        else:
            mcp_func = MCPFunction(
                func=func,
                name=name,
                description=description,
                parameter_types=parameter_types,
                return_type=return_type,
                is_async=is_async
            )

        self.functions[mcp_func.name] = mcp_func
        return mcp_func

    def get_function(self, name: str) -> Optional[MCPFunction]:
        """Get a registered function by name."""
        return self.functions.get(name)

    def get_schema(self) -> Dict[str, MCPSchema]:
        """Get schema for all registered functions."""
        return {
            name: func.generate_schema()
            for name, func in self.functions.items()
        }
