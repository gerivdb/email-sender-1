"""WebSocket transport implementation using modern websockets API."""

import asyncio
import json
from typing import Any, Dict, Optional, Set
import websockets
from websockets.legacy.server import WebSocketServerProtocol, serve

from pymcpfy.core.transport.base import BaseTransport
from pymcpfy.core.context import MCPContext
from pymcpfy.core.response import MCPResponse
from pymcpfy.config import TransportConfig

class WebSocketTransport(BaseTransport):
    """WebSocket transport implementation."""

    def __init__(self, config: TransportConfig):
        super().__init__(config)
        self._server = None
        self._connections: Set[WebSocketServerProtocol] = set()
        self.registry = None  # Will be set by the MCP core

    async def start(self):
        """Start WebSocket server."""
        self._server = await serve(
            self._handle_connection,
            self.config.host,
            self.config.port,
            ping_interval=self.config.ping_interval,
            ping_timeout=self.config.ping_timeout
        )
        await asyncio.Future()  # run forever

    async def stop(self):
        """Stop WebSocket server."""
        if self._server:
            self._server.close()
            await self._server.wait_closed()
            self._server = None

    def _create_error_response(self, request_id: Optional[str], code: int, message: str) -> Dict[str, Any]:
        """Create a standardized error response."""
        return {
            "jsonrpc": "2.0",
            "id": request_id or "unknown",
            "error": {
                "code": code,
                "message": message
            }
        }

    async def _handle_connection(self, websocket: WebSocketServerProtocol):
        """Handle WebSocket connection."""
        self._connections.add(websocket)
        try:
            async for message in websocket:
                try:
                    request = json.loads(message)
                except json.JSONDecodeError:
                    await websocket.send(json.dumps(
                        self._create_error_response(None, -32700, "Invalid JSON")
                    ))
                    continue

                request_id = request.get("id")

                # Vérifier que le registry est initialisé
                if not self.registry:
                    await websocket.send(json.dumps(
                        self._create_error_response(request_id, -32603, "Registry not initialized")
                    ))
                    continue

                # Créer le contexte
                context = MCPContext(
                    transport=self,
                    connection=websocket,
                    metadata={"client_info": websocket.remote_address}
                )

                try:
                    # Appel synchrone au registry
                    response = self.registry.handle_request(request, context)

                    # Formater et envoyer la réponse
                    if isinstance(response, MCPResponse):
                        response_data = response.to_dict()
                    elif isinstance(response, dict):
                        response_data = response
                    else:
                        response_data = {
                            "jsonrpc": "2.0",
                            "result": response,
                            "id": request_id
                        }

                    await websocket.send(json.dumps(response_data))

                except Exception as e:
                    await websocket.send(json.dumps(
                        self._create_error_response(request_id, -32603, str(e))
                    ))

        except websockets.exceptions.ConnectionClosed:
            pass
        finally:
            self._connections.remove(websocket)

    async def broadcast(self, message: Dict[str, Any]):
        """Broadcast message to all connected clients."""
        if not self._connections:
            return

        message_json = json.dumps({
            "jsonrpc": "2.0",
            "method": "broadcast",
            "params": message
        })

        await asyncio.gather(*[
            ws.send(message_json)
            for ws in self._connections
        ])
