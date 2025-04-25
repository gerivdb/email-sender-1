"""Tests for configuration functionality."""

import os
import tempfile
from typing import Dict

import pytest
import yaml

from pymcpfy.config import MCPConfig, TransportConfig, load_config

def test_transport_config_defaults():
    """Test TransportConfig default values."""
    config = TransportConfig()
    assert config.type == "websocket"
    assert config.host == "localhost"
    assert config.port == 8765
    assert config.ping_interval == 20
    assert config.ping_timeout == 20

def test_mcp_config_defaults():
    """Test MCPConfig default values."""
    config = MCPConfig()
    assert isinstance(config.transport, TransportConfig)
    assert config.backend_url is None
    assert config.debug is False
    assert config.cors_origins is None

def test_config_from_dict():
    """Test configuration loading from dictionary."""
    config_dict = {
        "transport": {
            "type": "http",
            "host": "127.0.0.1",
            "port": 8080
        },
        "backend_url": "http://api.example.com",
        "debug": True,
        "cors_origins": ["http://localhost:3000"]
    }

    config = MCPConfig.from_dict(config_dict)
    assert config.transport.type == "http"
    assert config.transport.host == "127.0.0.1"
    assert config.transport.port == 8080
    assert config.backend_url == "http://api.example.com"
    assert config.debug is True
    assert config.cors_origins == ["http://localhost:3000"]

def test_config_from_yaml():
    """Test configuration loading from YAML file."""
    config_dict = {
        "transport": {
            "type": "http",
            "host": "127.0.0.1",
            "port": 8080
        },
        "backend_url": "http://api.example.com",
        "debug": True,
        "cors_origins": ["http://localhost:3000"]
    }

    with tempfile.NamedTemporaryFile(mode="w", suffix=".yaml") as f:
        yaml.dump(config_dict, f)
        f.flush()
        
        config = MCPConfig.from_file(f.name)
        assert config.transport.type == "http"
        assert config.transport.host == "127.0.0.1"
        assert config.transport.port == 8080
        assert config.backend_url == "http://api.example.com"
        assert config.debug is True
        assert config.cors_origins == ["http://localhost:3000"]

def test_config_from_env_vars(monkeypatch):
    """Test configuration loading from environment variables."""
    env_vars = {
        "PYMCPFY_TRANSPORT_TYPE": "http",
        "PYMCPFY_HOST": "127.0.0.1",
        "PYMCPFY_PORT": "8080",
        "PYMCPFY_PING_INTERVAL": "30",
        "PYMCPFY_PING_TIMEOUT": "30",
        "PYMCPFY_BACKEND_URL": "http://api.example.com",
        "PYMCPFY_DEBUG": "true",
        "PYMCPFY_CORS_ORIGINS": "http://localhost:3000,http://localhost:8000"
    }

    for key, value in env_vars.items():
        monkeypatch.setenv(key, value)

    config = load_config()
    assert config.transport.type == "http"
    assert config.transport.host == "127.0.0.1"
    assert config.transport.port == 8080
    assert config.transport.ping_interval == 30
    assert config.transport.ping_timeout == 30
    assert config.backend_url == "http://api.example.com"
    assert config.debug is True
    assert config.cors_origins == ["http://localhost:3000", "http://localhost:8000"]

def test_load_config_precedence(monkeypatch):
    """Test configuration loading precedence."""
    # Set environment variables (lowest precedence)
    env_vars = {
        "PYMCPFY_TRANSPORT_TYPE": "http",
        "PYMCPFY_HOST": "127.0.0.1",
        "PYMCPFY_PORT": "8080"
    }
    for key, value in env_vars.items():
        monkeypatch.setenv(key, value)

    # Create config dict (highest precedence)
    config_dict = {
        "transport": {
            "type": "websocket",
            "host": "localhost",
            "port": 8765
        }
    }

    # Dict should override environment variables
    config = load_config(config_dict)
    assert config.transport.type == "websocket"
    assert config.transport.host == "localhost"
    assert config.transport.port == 8765

    # Environment variables should be used when no dict is provided
    config = load_config()
    assert config.transport.type == "http"
    assert config.transport.host == "127.0.0.1"
    assert config.transport.port == 8080
