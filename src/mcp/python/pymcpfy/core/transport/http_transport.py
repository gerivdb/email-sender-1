"""HTTP transport implementation for MCP using aiohttp."""

import asyncio
import json
from typing import Any, Dict, Optional, Callable
from aiohttp import web
from aiohttp.web import Request, Response

from ..mcp_protocol import MCPRegistry, MCPContext, MCPResponse

def create_error_response(request_id: Optional[str], code: int, message: str) -> Dict[str, Any]:
    """Create a standardized error response."""
    return {
        "jsonrpc": "2.0",
        "id": request_id or "unknown",
        "error": {
            "code": code,
            "message": message
        }
    }

class MCPHTTPTransport:
    """HTTP transport for MCP using aiohttp."""

    def __init__(self, registry: MCPRegistry, host: str = "localhost", port: int = 8000):
        """Initialize the HTTP transport."""
        self.registry = registry
        self.host = host
        self.port = port
        self.app = web.Application()
        self.app.router.add_post("/", self.handle_request)
        self.app.router.add_get("/schema", self.handle_schema_request)
        self.runner = None

    async def handle_schema_request(self, request: Request) -> Response:
        """Handle GET request for schema."""
        try:
            schema = self.registry.get_schema()
            return web.json_response(schema)
        except Exception as e:
            error = create_error_response(None, 500, str(e))
            return web.json_response(error, status=500)

    async def handle_request(self, request: Request) -> Response:
        """Handle POST request for MCP function execution."""
        try:
            data = await request.json()
            request_id = data.get("id")
            function_name = data.get("function")
            parameters = data.get("parameters", {})

            # Create context
            context = MCPContext(
                request_id=request_id or "unknown",
                transport="http",
                metadata={"remote": request.remote},
                raw_request=data
            )

            if not function_name:
                return web.json_response(
                    create_error_response(request_id, 400, "Missing function name"),
                    status=400
                )

            function = self.registry.get_function(function_name)
            if not function:
                return web.json_response(
                    create_error_response(request_id, 404, f"Function {function_name} not found"),
                    status=404
                )

            try:
                if function.is_async:
                    result = await function.func(context, **parameters)
                else:
                    result = await asyncio.to_thread(function.func, context, **parameters)

                if isinstance(result, MCPResponse):
                    response = result.to_dict()
                else:
                    response = {
                        "jsonrpc": "2.0",
                        "result": result,
                        "id": request_id
                    }

                return web.json_response(response)

            except Exception as e:
                return web.json_response(
                    create_error_response(request_id, 500, str(e)),
                    status=500
                )

        except json.JSONDecodeError:
            return web.json_response(
                create_error_response(None, 400, "Invalid JSON"),
                status=400
            )

    async def start(self) -> None:
        """Start the HTTP server."""
        self.runner = web.AppRunner(self.app)
        await self.runner.setup()
        site = web.TCPSite(self.runner, self.host, self.port)
        await site.start()
        print(f"MCP HTTP server started at http://{self.host}:{self.port}")

    async def stop(self) -> None:
        """Stop the HTTP server."""
        if self.runner:
            await self.runner.cleanup()
            self.runner = None

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

    def do_POST(self):
        """Handle POST requests."""
        try:
            # Handled by aiohttp
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
            error_response = self._create_error_response(None, 400, "Invalid JSON")
            self._send_error_response(error_response)
        except Exception as e:
            error_response = self._create_error_response(None, 500, str(e))
            self._send_error_response(error_response)

    def do_GET(self):
        """Handle GET requests for schema."""
        if self.path == "/schema":
            schema = self.registry.get_schema()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(schema).encode())
        else:
            error_response = self._create_error_response(None, 404, "Not found")
            self._send_error_response(error_response)

    def _send_error_response(self, error_response: Dict[str, Any]):
        """Send error response."""
        self.send_response(error_response.get("error", {}).get("code", 500))
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        return
        """Handle MCP request."""
        request_id = request.get("id")
        function_name = request.get("function")
        parameters = request.get("parameters", {})

        # Create context early to be available throughout the function
        context = MCPContext(
            request_id=request.get("id", "unknown"),
            transport="http",
            metadata={"client_info": self.client_address},
            raw_request=request
        )

        if not function_name:
            return self._create_error_response(request_id, 400, "Missing function name")

        function = self.registry.get_function(function_name)
        if not function:
            return self._create_error_response(request_id, 404, f"Function {function_name} not found")

        try:
            if function.is_async:
                result = await function.func(context, **parameters)
            else:
                result = await asyncio.to_thread(function.func, context, **parameters)

            if isinstance(result, MCPResponse):
                response = result.to_dict()
            else:
                response = {
                    "jsonrpc": "2.0",
                    "result": result,
                    "id": request_id
                }

            return response

        except Exception as e:
            return self._create_error_response(request_id, 500, str(e))

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
