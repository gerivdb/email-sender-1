"""Schema generator for MCP functions."""

import inspect
from typing import Any, Callable, Dict, Optional, Type, get_type_hints

from pydantic import BaseModel

class SchemaGenerator:
    """Generate MCP schema from Python functions."""

    @staticmethod
    def generate_parameter_schema(func: Callable) -> Dict[str, Dict[str, Any]]:
        """Generate parameter schema from function signature."""
        params = {}
        signature = inspect.signature(func)
        type_hints = get_type_hints(func)

        for name, param in signature.parameters.items():
            # Skip self, cls, and context parameters
            if name in ("self", "cls", "context"):
                continue

            param_type = type_hints.get(name, Any)
            params[name] = SchemaGenerator._get_type_schema(param_type)

            # Add description from docstring if available
            if func.__doc__:
                param_desc = SchemaGenerator._extract_param_description(func.__doc__, name)
                if param_desc:
                    params[name]["description"] = param_desc

        return params

    @staticmethod
    def generate_return_schema(func: Callable) -> Dict[str, Any]:
        """Generate return type schema from function."""
        return_type = get_type_hints(func).get("return", Any)
        return SchemaGenerator._get_type_schema(return_type)

    @staticmethod
    def _get_type_schema(type_hint: Type) -> Dict[str, Any]:
        """Convert Python type hint to MCP type schema."""
        if hasattr(type_hint, "__origin__"):  # Handle generic types
            origin = type_hint.__origin__
            if origin in (list, List):
                return {
                    "type": "array",
                    "items": SchemaGenerator._get_type_schema(type_hint.__args__[0])
                }
            elif origin in (dict, Dict):
                return {
                    "type": "object",
                    "additionalProperties": SchemaGenerator._get_type_schema(type_hint.__args__[1])
                }
            elif origin in (Optional, Union):
                non_none_types = [t for t in type_hint.__args__ if t != type(None)]
                if len(non_none_types) == 1:
                    schema = SchemaGenerator._get_type_schema(non_none_types[0])
                    schema["nullable"] = True
                    return schema
                return {"oneOf": [SchemaGenerator._get_type_schema(t) for t in non_none_types]}
        elif inspect.isclass(type_hint) and issubclass(type_hint, BaseModel):
            return type_hint.model_json_schema()
        elif type_hint == str:
            return {"type": "string"}
        elif type_hint == int:
            return {"type": "integer"}
        elif type_hint == float:
            return {"type": "number"}
        elif type_hint == bool:
            return {"type": "boolean"}
        elif type_hint == bytes:
            return {"type": "string", "format": "binary"}
        else:
            return {"type": "any"}

    @staticmethod
    def _extract_param_description(docstring: str, param_name: str) -> Optional[str]:
        """Extract parameter description from docstring."""
        lines = docstring.split("\n")
        param_marker = f":param {param_name}:"
        for i, line in enumerate(lines):
            if param_marker in line:
                desc = line.split(param_marker)[1].strip()
                # Check for multi-line description
                j = i + 1
                while j < len(lines) and lines[j].strip() and not lines[j].strip().startswith(":"):
                    desc += " " + lines[j].strip()
                    j += 1
                return desc
        return None
