"""WebSocket transport implementation for MCP."""

import asyncio
import json
from typing import Any, Dict, Optional
import websockets
from websockets.server import WebSocketServerProtocol

from ..mcp_protocol import MCPRegistry, MCPContext, MCPResponse

class WebSocketTransport:
    """WebSocket transport for MCP communication."""
    def __init__(
        self,
        registry: MCPRegistry,
        host: str = "localhost",
        port: int = 8765,
        ping_interval: int = 20,
        ping_timeout: int = 20
    ):
        self.registry = registry
        self.host = host
        self.port = port
        self.ping_interval = ping_interval
        self.ping_timeout = ping_timeout
        self._server: Optional[websockets.WebSocketServer] = None

    async def start(self):
        """Start the WebSocket server."""
        self._server = await websockets.serve(
            self._handle_connection,
            self.host,
            self.port,
            ping_interval=self.ping_interval,
            ping_timeout=self.ping_timeout
        )
        print(f"MCP WebSocket server running at ws://{self.host}:{self.port}")

    async def stop(self):
        """Stop the WebSocket server."""
        if self._server:
            self._server.close()
            await self._server.wait_closed()

    async def _handle_connection(self, websocket: WebSocketServerProtocol, path: str):
        """Handle incoming WebSocket connections."""
        try:
            async for message in websocket:
                try:
                    request = json.loads(message)
                    response = await self._handle_request(request, websocket)
                    await websocket.send(json.dumps(response))
                except json.JSONDecodeError:
                    await websocket.send(json.dumps({
                        "error": "Invalid JSON",
                        "status": 400
                    }))
                except Exception as e:
                    await websocket.send(json.dumps({
                        "error": str(e),
                        "status": 500
                    }))
        except websockets.exceptions.ConnectionClosed:
            pass

    async def _handle_request(
        self,
        request: Dict[str, Any],
        websocket: WebSocketServerProtocol
    ) -> Dict[str, Any]:
        """Handle incoming MCP requests."""
        request_id = request.get("id")
        function_name = request.get("function")
        parameters = request.get("parameters", {})

        if not function_name:
            return {
                "id": request_id,
                "error": "Missing function name",
                "status": 400
            }

        function = self.registry.get_function(function_name)
        if not function:
            return {
                "id": request_id,
                "error": f"Function {function_name} not found",
                "status": 404
            }

        context = MCPContext(
            request_id=request_id,
            metadata=request.get("metadata", {}),
            transport="websocket",
            raw_request=request
        )

        try:
            if function.is_async:
                result = await function.func(context, **parameters)
            else:
                result = await asyncio.to_thread(function.func, context, **parameters)

            if isinstance(result, MCPResponse):
                response = result.to_dict()
            else:
                response = MCPResponse(result).to_dict()

            response["id"] = request_id
            return response

        except Exception as e:
            return {
                "id": request_id,
                "error": str(e),
                "status": 500
            }
