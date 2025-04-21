"""HTTP transport implementation for MCP."""

import asyncio
import json
from typing import Any, Dict, Optional, Tuple, Callable
from urllib.parse import parse_qs
from http.server import HTTPServer, BaseHTTPRequestHandler

from ..mcp_protocol import MCPRegistry, MCPContext, MCPResponse

class MCPHTTPRequestHandler(BaseHTTPRequestHandler):
    """HTTP request handler for MCP."""
    registry: MCPRegistry
    event_loop: asyncio.AbstractEventLoop

    def do_POST(self):
        """Handle POST requests."""
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            request_body = self.rfile.read(content_length).decode('utf-8')
            request = json.loads(request_body)

            response = self.event_loop.run_until_complete(
                self._handle_request(request)
            )

            self.send_response(response.get("status", 200))
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())

        except json.JSONDecodeError:
            self._send_error(400, "Invalid JSON")
        except Exception as e:
            self._send_error(500, str(e))

    def do_GET(self):
        """Handle GET requests for schema."""
        if self.path == "/schema":
            schema = self.registry.get_schema()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(schema).encode())
        else:
            self._send_error(404, "Not found")

    def _send_error(self, status: int, message: str):
        """Send error response."""
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({
            "error": message,
            "status": status
        }).encode())

    async def _handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle MCP request."""
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
            transport="http",
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

class HTTPTransport:
    """HTTP transport for MCP communication."""
    def __init__(
        self,
        registry: MCPRegistry,
        host: str = "localhost",
        port: int = 8080
    ):
        self.registry = registry
        self.host = host
        self.port = port
        self._server: Optional[HTTPServer] = None
        self._event_loop: Optional[asyncio.AbstractEventLoop] = None

    def start(self):
        """Start the HTTP server."""
        class Handler(MCPHTTPRequestHandler):
            registry = self.registry
            event_loop = asyncio.new_event_loop()

        self._server = HTTPServer((self.host, self.port), Handler)
        print(f"MCP HTTP server running at http://{self.host}:{self.port}")
        self._server.serve_forever()

    def stop(self):
        """Stop the HTTP server."""
        if self._server:
            self._server.shutdown()
            self._server.server_close()
