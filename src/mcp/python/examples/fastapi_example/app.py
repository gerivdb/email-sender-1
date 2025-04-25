"""
FastAPI Example: Real-time Chat API with MCP Integration
"""

from typing import List, Optional
from datetime import datetime
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Depends
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
from pymcpfy.fastapi import mcpfy
import jwt
import uvicorn

# Initialize FastAPI app
app = FastAPI(title="Chat API")

# Security
SECRET_KEY = "your-secret-key"  # In production, use environment variable
ALGORITHM = "HS256"
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# In-memory storage (use a proper database in production)
messages = []
active_connections: List[WebSocket] = []
users = {
    "demo": {
        "username": "demo",
        "password": "demo123",  # In production, use hashed passwords
        "full_name": "Demo User"
    }
}

# Models
class Message(BaseModel):
    id: int
    content: str
    sender: str
    timestamp: datetime

class User(BaseModel):
    username: str
    full_name: str

class Token(BaseModel):
    access_token: str
    token_type: str

# Authentication
def create_token(username: str) -> str:
    """Create JWT token for user."""
    token = jwt.encode(
        {"sub": username},
        SECRET_KEY,
        algorithm=ALGORITHM
    )
    return token

async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    """Get current user from token."""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        if not username or username not in users:
            raise HTTPException(status_code=401)
        return User(**users[username])
    except jwt.JWTError:
        raise HTTPException(status_code=401)

# WebSocket Manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)

manager = ConnectionManager()

# API Endpoints
@app.post("/token")
@mcpfy()
async def login(form_data: OAuth2PasswordRequestForm = Depends()) -> Token:
    """Login to get access token.
    
    :param form_data: Username and password
    :return: Access token
    """
    user = users.get(form_data.username)
    if not user or form_data.password != user["password"]:
        raise HTTPException(status_code=400, detail="Invalid credentials")
    
    token = create_token(user["username"])
    return Token(access_token=token, token_type="bearer")

@app.get("/messages")
@mcpfy()
async def get_messages(
    limit: Optional[int] = 50,
    current_user: User = Depends(get_current_user)
) -> List[Message]:
    """Get chat messages.
    
    :param limit: Maximum number of messages to return
    :return: List of messages
    """
    return messages[-limit:]

@app.post("/messages")
@mcpfy()
async def create_message(
    content: str,
    current_user: User = Depends(get_current_user)
) -> Message:
    """Create a new message.
    
    :param content: Message content
    :return: Created message
    """
    message = Message(
        id=len(messages),
        content=content,
        sender=current_user.username,
        timestamp=datetime.now()
    )
    messages.append(message)
    
    # Broadcast to WebSocket clients
    await manager.broadcast(
        f"{current_user.username}: {content}"
    )
    
    return message

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time chat."""
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            await manager.broadcast(f"Message: {data}")
    except WebSocketDisconnect:
        manager.disconnect(websocket)
        await manager.broadcast("Client disconnected")

if __name__ == "__main__":
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
