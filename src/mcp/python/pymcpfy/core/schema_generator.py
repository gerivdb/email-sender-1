"""Schema generator for MCP functions."""

import inspect
from typing import (
    Any, Dict, Optional, Union, List, Type, Callable,
    get_origin, get_args, get_type_hints
)

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
    def _get_type_schema(type_hint: Union[Type, Any]) -> Dict[str, Any]:
        """Convert Python type to MCP type schema."""
        if type_hint is None:
            return {"type": "null"}

        origin = get_origin(type_hint)
        if origin is None:
            # Handle simple types
            if type_hint == str:
                return {"type": "string"}
            elif type_hint == int:
                return {"type": "integer"}
            elif type_hint == float:
                return {"type": "number"}
            elif type_hint == bool:
                return {"type": "boolean"}
            elif type_hint == dict:
                return {"type": "object"}
            elif type_hint == list:
                return {"type": "array"}
            else:
                return {"type": "any"}

        # Handle complex types
        if origin in (list, List):
            args = get_args(type_hint)
            item_type = args[0] if args else Any
            return {
                "type": "array",
                "items": SchemaGenerator._get_type_schema(item_type)
            }
        elif origin in (Optional, Union):
            args = get_args(type_hint)
            types = [SchemaGenerator._get_type_schema(arg) for arg in args if arg != type(None)]
            if len(types) == 1:
                return types[0]
            return {"anyOf": types}
        elif origin == dict:
            args = get_args(type_hint)
            key_type = args[0] if args else Any
            value_type = args[1] if len(args) > 1 else Any
            return {
                "type": "object",
                "additionalProperties": SchemaGenerator._get_type_schema(value_type)
            }

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
