# Configuration Guide

PyMCPfy offers flexible configuration options through YAML files, environment variables, or programmatic configuration.

## Configuration File

Create a `pymcpfy_config.yaml` file:

```yaml
# Basic configuration
transport:
  type: websocket  # or 'http'
  host: localhost
  port: 8765
  ping_interval: 20  # seconds
  ping_timeout: 20   # seconds

# Backend configuration
backend_url: http://localhost:8000
debug: true

# CORS configuration
cors_origins:
  - http://localhost:3000
  - https://your-app.com

# Authentication (optional)
auth:
  enabled: true
  jwt_secret: your-secret-key
  token_expiry: 3600  # seconds

# Logging
logging:
  level: INFO
  format: "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
  file: pymcpfy.log
```

## Environment Variables

All configuration options can be set via environment variables:

```bash
# Transport
export PYMCPFY_TRANSPORT_TYPE=websocket
export PYMCPFY_HOST=localhost
export PYMCPFY_PORT=8765
export PYMCPFY_PING_INTERVAL=20
export PYMCPFY_PING_TIMEOUT=20

# Backend
export PYMCPFY_BACKEND_URL=http://localhost:8000
export PYMCPFY_DEBUG=true

# CORS
export PYMCPFY_CORS_ORIGINS=http://localhost:3000,https://your-app.com

# Authentication
export PYMCPFY_AUTH_ENABLED=true
export PYMCPFY_JWT_SECRET=your-secret-key
export PYMCPFY_TOKEN_EXPIRY=3600

# Logging
export PYMCPFY_LOG_LEVEL=INFO
export PYMCPFY_LOG_FORMAT="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
export PYMCPFY_LOG_FILE=pymcpfy.log
```

## Programmatic Configuration

```python
from pymcpfy import MCPConfig, TransportConfig

config = MCPConfig(
    transport=TransportConfig(
        type="websocket",
        host="localhost",
        port=8765,
        ping_interval=20,
        ping_timeout=20
    ),
    backend_url="http://localhost:8000",
    debug=True,
    cors_origins=["http://localhost:3000"]
)
```

## Configuration Priority

Configuration values are loaded in the following order (highest priority first):

1. Programmatic configuration
2. Environment variables
3. Configuration file
4. Default values

## Configuration Reference

### Transport Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `type` | str | "websocket" | Transport protocol ("websocket" or "http") |
| `host` | str | "localhost" | Host to bind the MCP server |
| `port` | int | 8765 | Port to bind the MCP server |
| `ping_interval` | int | 20 | WebSocket ping interval in seconds |
| `ping_timeout` | int | 20 | WebSocket ping timeout in seconds |

### Backend Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `backend_url` | str | None | URL of your web application |
| `debug` | bool | False | Enable debug mode |

### CORS Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `cors_origins` | List[str] | [] | Allowed CORS origins |

### Authentication Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `auth.enabled` | bool | False | Enable authentication |
| `auth.jwt_secret` | str | None | JWT secret key |
| `auth.token_expiry` | int | 3600 | Token expiry in seconds |

### Logging Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `logging.level` | str | "INFO" | Logging level |
| `logging.format` | str | See above | Log format string |
| `logging.file` | str | None | Log file path |

## Framework-Specific Configuration

### Django

In `settings.py`:

```python
INSTALLED_APPS = [
    ...
    'pymcpfy.django',
]

PYMCPFY = {
    'transport': {
        'type': 'websocket',
        'host': 'localhost',
        'port': 8765,
    },
    'debug': True,
}
```

### Flask

```python
app.config['PYMCPFY'] = {
    'transport': {
        'type': 'websocket',
        'host': 'localhost',
        'port': 8765,
    },
    'debug': True,
}
```

### FastAPI

```python
app = FastAPI()
app.mcp_config = {
    'transport': {
        'type': 'websocket',
        'host': 'localhost',
        'port': 8765,
    },
    'debug': True,
}
