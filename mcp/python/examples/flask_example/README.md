# Flask Todo List Example with PyMCPfy

This example demonstrates how to build a Todo List API using Flask and expose it via MCP using PyMCPfy.

## Features

- User authentication with JWT
- CRUD operations for todos
- SQLite database with SQLAlchemy
- MCP integration for AI interaction

## Setup

1. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Run the server:
```bash
python app.py
```

The server will start at:
- HTTP: http://localhost:5000
- MCP: ws://localhost:8765

## API Endpoints

### Authentication

```bash
# Get access token
curl -X POST http://localhost:5000/login \
  -H "Content-Type: application/json" \
  -d '{"username": "demo", "password": "demo123"}'
```

### Todos

```bash
# Get all todos
curl http://localhost:5000/todos \
  -H "Authorization: Bearer YOUR_TOKEN"

# Create todo
curl -X POST http://localhost:5000/todos \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Learn PyMCPfy",
    "description": "Build an awesome API",
    "due_date": "2025-04-15T12:00:00"
  }'

# Update todo
curl -X PUT http://localhost:5000/todos/1 \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "done": true
  }'

# Delete todo
curl -X DELETE http://localhost:5000/todos/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## MCP Integration

Connect to the MCP server and interact with the API:

```python
from mcp import MCPClient

async with MCPClient("ws://localhost:8765") as client:
    # Login
    response = await client.call_function(
        "login",
        {"username": "demo", "password": "demo123"}
    )
    token = response["access_token"]
    
    # Create todo
    todo = await client.call_function(
        "create_todo",
        {
            "title": "Learn PyMCPfy",
            "description": "Build an awesome API",
            "due_date": "2025-04-15T12:00:00"
        },
        headers={"Authorization": f"Bearer {token}"}
    )
    
    # Get todos
    todos = await client.call_function(
        "get_todos",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    # Update todo
    updated_todo = await client.call_function(
        "update_todo",
        {"done": True},
        headers={"Authorization": f"Bearer {token}"},
        params={"todo_id": todo["id"]}
    )
    
    # Delete todo
    result = await client.call_function(
        "delete_todo",
        headers={"Authorization": f"Bearer {token}"},
        params={"todo_id": todo["id"]}
    )
```

## Database

The application uses SQLite with SQLAlchemy. The database file (`todos.db`) will be created automatically when you run the application for the first time.

## Security Note

This is a demo application. In production:
- Use proper password hashing
- Use a more secure JWT secret key
- Implement proper error handling
- Use a production-grade database
- Add input validation
- Implement rate limiting
