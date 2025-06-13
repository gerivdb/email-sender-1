# Getting Started with PyMCPfy

This guide will help you get started with PyMCPfy and expose your first API via MCP.

## Installation

Install PyMCPfy with your preferred framework support:

```bash
# For Django

pip install "pymcpfy[django]"

# For Flask

pip install "pymcpfy[flask]"

# For FastAPI

pip install "pymcpfy[fastapi]"

# For development (includes all frameworks and dev tools)

pip install "pymcpfy[dev]"
```plaintext
## Basic Configuration

1. Create a `pymcpfy_config.yaml` file in your project root:

```yaml
transport:
  type: websocket  # or 'http'

  host: localhost
  port: 8765
backend_url: http://localhost:8000
debug: true
cors_origins:
  - http://localhost:3000
```plaintext
2. Or use environment variables:

```bash
export PYMCPFY_TRANSPORT_TYPE=websocket
export PYMCPFY_HOST=localhost
export PYMCPFY_PORT=8765
export PYMCPFY_BACKEND_URL=http://localhost:8000
export PYMCPFY_DEBUG=true
export PYMCPFY_CORS_ORIGINS=http://localhost:3000
```plaintext
## Your First MCP API

### FastAPI Example

```python
from fastapi import FastAPI
from pymcpfy.fastapi import mcpfy

app = FastAPI()

@app.get("/hello/{name}")
@mcpfy()
async def hello(name: str) -> dict:
    """Say hello to a user.
    
    :param name: The name of the user to greet
    :return: A greeting message
    """
    return {"message": f"Hello, {name}!"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```plaintext
### Django Example

```python
# views.py

from django.http import JsonResponse
from pymcpfy.django import mcpfy

@mcpfy()
def hello(request, name: str):
    """Say hello to a user."""
    return JsonResponse({"message": f"Hello, {name}!"})

# urls.py

from django.urls import path
from . import views

urlpatterns = [
    path('hello/<str:name>/', views.hello, name='hello'),
]
```plaintext
### Flask Example

```python
from flask import Flask, jsonify
from pymcpfy.flask import mcpfy

app = Flask(__name__)

@app.route("/hello/<name>")
@mcpfy()
def hello(name: str):
    """Say hello to a user."""
    return jsonify({"message": f"Hello, {name}!"})

if __name__ == "__main__":
    app.run(debug=True)
```plaintext
## Running the MCP Server

### FastAPI/Flask

```bash
python app.py --mcp
```plaintext
### Django

```bash
python manage.py runmcp
```plaintext
## Verifying the Setup

1. Your API will be available at its normal endpoint (e.g., `http://localhost:8000/hello/world`)
2. The MCP interface will be available at:
   - WebSocket: `ws://localhost:8765`
   - HTTP: `http://localhost:8765`

3. Test the MCP interface:

```python
from mcp import MCPClient

async with MCPClient("ws://localhost:8765") as client:
    result = await client.call_function("hello", {"name": "World"})
    print(result)  # {"message": "Hello, World!"}

```plaintext
## Next Steps

- Learn about [Configuration Options](configuration.md)
- Explore framework-specific guides:
  - [Django Integration](django_integration.md)
  - [Flask Integration](flask_integration.md)
  - [FastAPI Integration](fastapi_integration.md)
- Check out the [Examples](../examples/)
- Read the [API Reference](api_reference.md)
