"""Tests for core MCP protocol functionality."""

import pytest
from typing import Dict, Any

from pymcpfy.core import (
    MCPContext,
    MCPFunction,
    MCPRegistry,
    MCPResponse,
    MCPSchema,
)

def test_mcp_function_schema():
    """Test MCP function schema generation."""
    def sample_func(a: int, b: str) -> Dict[str, Any]:
        """Sample function for testing.
        
        :param a: An integer parameter
        :param b: A string parameter
        :return: A dictionary result
        """
        return {"result": f"{a} {b}"}

    mcp_func = MCPFunction(
        func=sample_func,
        name="test_func",
        description="Test function",
        parameter_types={"a": int, "b": str},
        return_type=Dict[str, Any]
    )

    schema = mcp_func.generate_schema()
    assert isinstance(schema, MCPSchema)
    assert schema.name == "test_func"
    assert schema.description == "Test function"
    assert "a" in schema.parameters
    assert schema.parameters["a"]["type"]["type"] == "integer"
    assert "b" in schema.parameters
    assert schema.parameters["b"]["type"]["type"] == "string"

def test_mcp_registry():
    """Test MCP registry functionality."""
    registry = MCPRegistry()

    @registry.register
    def test_func(a: int) -> str:
        return str(a)

    assert "test_func" in registry.functions
    func = registry.get_function("test_func")
    assert func is not None
    assert func.name == "test_func"

    schema = registry.get_schema()
    assert "test_func" in schema

def test_mcp_response():
    """Test MCP response handling."""
    data = {"result": "test"}
    response = MCPResponse(data, status=200, metadata={"type": "test"})
    response_dict = response.to_dict()

    assert response_dict["data"] == data
    assert response_dict["status"] == 200
    assert response_dict["metadata"] == {"type": "test"}

def test_mcp_context():
    """Test MCP context object."""
    context = MCPContext(
        request_id="123",
        metadata={"user": "test"},
        transport="websocket",
        raw_request={"type": "request"}
    )

    assert context.request_id == "123"
    assert context.metadata == {"user": "test"}
    assert context.transport == "websocket"
    assert context.raw_request == {"type": "request"}
