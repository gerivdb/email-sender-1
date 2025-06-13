# FastAPI Chat Example with PyMCPfy

This example demonstrates how to build a real-time chat API using FastAPI and expose it via MCP using PyMCPfy.

## Features

- User authentication with JWT
- RESTful API endpoints for messages
- Real-time WebSocket communication
- MCP integration for AI interaction

## Setup

1. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

```plaintext
2. Install dependencies:
```bash
pip install -r requirements.txt
```plaintext
3. Run the server:
```bash
python app.py
```plaintext
The server will start at:
- HTTP: http://localhost:8000
- WebSocket: ws://localhost:8000/ws
- MCP: ws://localhost:8765

## API Endpoints

### Authentication

```bash
# Get access token

curl -X POST http://localhost:8000/token \
  -d "username=demo&password=demo123" \
  -H "Content-Type: application/x-www-form-urlencoded"
```plaintext
### Messages

```bash
# Get messages

curl http://localhost:8000/messages \
  -H "Authorization: Bearer YOUR_TOKEN"

# Create message

curl -X POST http://localhost:8000/messages \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content": "Hello, World!"}'
```plaintext
## MCP Integration

Connect to the MCP server and interact with the API:

```python
from mcp import MCPClient

async with MCPClient("ws://localhost:8765") as client:
    # Login

    token = await client.call_function(
        "login",
        {"username": "demo", "password": "demo123"}
    )
    
    # Get messages

    messages = await client.call_function(
        "get_messages",
        {"limit": 10},
        headers={"Authorization": f"Bearer {token['access_token']}"}
    )
    
    # Send message

    message = await client.call_function(
        "create_message",
        {"content": "Hello via MCP!"},
        headers={"Authorization": f"Bearer {token['access_token']}"}
    )
```plaintext
## WebSocket Chat

Connect to the WebSocket endpoint for real-time chat:

```python
import websockets
import asyncio

async def chat():
    async with websockets.connect("ws://localhost:8000/ws") as ws:
        # Send message

        await ws.send("Hello, everyone!")
        
        # Receive messages

        while True:
            message = await ws.recv()
            print(f"Received: {message}")

asyncio.run(chat())
