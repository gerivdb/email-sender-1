"""Configuration management for PyMCPfy."""

import os
from dataclasses import dataclass
from typing import Optional, Union
import yaml

@dataclass
class TransportConfig:
    """Configuration for MCP transport."""
    type: str = "websocket"  # "websocket" or "http"
    host: str = "localhost"
    port: int = 8765
    ping_interval: int = 20
    ping_timeout: int = 20

@dataclass
class MCPConfig:
    """Configuration for PyMCPfy."""
    transport: TransportConfig = TransportConfig()
    backend_url: Optional[str] = None
    debug: bool = False
    cors_origins: list[str] = None

    @classmethod
    def from_file(cls, path: str) -> "MCPConfig":
        """Load configuration from YAML file."""
        if not os.path.exists(path):
            return cls()

        with open(path, "r") as f:
            config_dict = yaml.safe_load(f)

        transport_config = TransportConfig(**config_dict.get("transport", {}))
        return cls(
            transport=transport_config,
            backend_url=config_dict.get("backend_url"),
            debug=config_dict.get("debug", False),
            cors_origins=config_dict.get("cors_origins", [])
        )

    @classmethod
    def from_dict(cls, config_dict: dict) -> "MCPConfig":
        """Load configuration from dictionary."""
        transport_config = TransportConfig(**config_dict.get("transport", {}))
        return cls(
            transport=transport_config,
            backend_url=config_dict.get("backend_url"),
            debug=config_dict.get("debug", False),
            cors_origins=config_dict.get("cors_origins", [])
        )

def load_config(config: Union[str, dict, None] = None) -> MCPConfig:
    """Load configuration from file, dict, or environment variables."""
    if isinstance(config, str):
        return MCPConfig.from_file(config)
    elif isinstance(config, dict):
        return MCPConfig.from_dict(config)
    else:
        # Load from environment variables
        transport_config = TransportConfig(
            type=os.getenv("PYMCPFY_TRANSPORT_TYPE", "websocket"),
            host=os.getenv("PYMCPFY_HOST", "localhost"),
            port=int(os.getenv("PYMCPFY_PORT", "8765")),
            ping_interval=int(os.getenv("PYMCPFY_PING_INTERVAL", "20")),
            ping_timeout=int(os.getenv("PYMCPFY_PING_TIMEOUT", "20"))
        )

        return MCPConfig(
            transport=transport_config,
            backend_url=os.getenv("PYMCPFY_BACKEND_URL"),
            debug=os.getenv("PYMCPFY_DEBUG", "false").lower() == "true",
            cors_origins=os.getenv("PYMCPFY_CORS_ORIGINS", "").split(",") if os.getenv("PYMCPFY_CORS_ORIGINS") else []
        )
