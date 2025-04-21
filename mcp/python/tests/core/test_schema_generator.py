"""Tests for schema generator functionality."""

from typing import Dict, List, Optional, Union
from pydantic import BaseModel

import pytest
from pymcpfy.core import SchemaGenerator

class SampleModel(BaseModel):
    """Sample Pydantic model for testing."""
    name: str
    age: int
    tags: List[str]

def test_basic_type_schema():
    """Test schema generation for basic Python types."""
    def func(
        str_param: str,
        int_param: int,
        float_param: float,
        bool_param: bool,
        bytes_param: bytes
    ) -> str:
        """Test function with basic types.
        
        :param str_param: A string parameter
        :param int_param: An integer parameter
        :param float_param: A float parameter
        :param bool_param: A boolean parameter
        :param bytes_param: A bytes parameter
        """
        return "test"

    params = SchemaGenerator.generate_parameter_schema(func)
    
    assert params["str_param"]["type"] == "string"
    assert params["int_param"]["type"] == "integer"
    assert params["float_param"]["type"] == "number"
    assert params["bool_param"]["type"] == "boolean"
    assert params["bytes_param"]["type"] == "string"
    assert params["bytes_param"]["format"] == "binary"

def test_container_type_schema():
    """Test schema generation for container types."""
    def func(
        list_param: List[str],
        dict_param: Dict[str, int],
        optional_param: Optional[str],
        union_param: Union[int, str]
    ) -> List[Dict[str, Any]]:
        """Test function with container types.
        
        :param list_param: A list parameter
        :param dict_param: A dict parameter
        :param optional_param: An optional parameter
        :param union_param: A union parameter
        """
        return []

    params = SchemaGenerator.generate_parameter_schema(func)
    
    assert params["list_param"]["type"] == "array"
    assert params["list_param"]["items"]["type"] == "string"
    
    assert params["dict_param"]["type"] == "object"
    assert params["dict_param"]["additionalProperties"]["type"] == "integer"
    
    assert "nullable" in params["optional_param"]
    assert params["optional_param"]["type"] == "string"
    
    assert "oneOf" in params["union_param"]
    types = {schema["type"] for schema in params["union_param"]["oneOf"]}
    assert types == {"integer", "string"}

def test_pydantic_model_schema():
    """Test schema generation for Pydantic models."""
    def func(model: SampleModel) -> SampleModel:
        """Test function with Pydantic model.
        
        :param model: A sample model
        """
        return model

    params = SchemaGenerator.generate_parameter_schema(func)
    model_schema = params["model"]
    
    assert model_schema["type"] == "object"
    assert "properties" in model_schema
    assert "name" in model_schema["properties"]
    assert "age" in model_schema["properties"]
    assert "tags" in model_schema["properties"]

def test_docstring_extraction():
    """Test parameter description extraction from docstring."""
    def func(param: str) -> str:
        """Test function.
        
        :param param: This is a test parameter
            with a multi-line description
        """
        return param

    params = SchemaGenerator.generate_parameter_schema(func)
    assert "description" in params["param"]
    assert "This is a test parameter with a multi-line description" in params["param"]["description"]
