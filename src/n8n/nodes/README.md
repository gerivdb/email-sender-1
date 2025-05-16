# MCP Integration for n8n

This directory contains custom nodes for integrating the Model Context Protocol (MCP) with n8n.

## Nodes

### MCP Client

The MCP Client node provides a generic interface to interact with MCP servers. It supports the following operations:

- **Get Context**: Retrieve context from MCP server based on a prompt and selected sources
- **List Tools**: List available tools on the MCP server
- **Execute Tool**: Execute a specific tool on the MCP server with custom parameters

### MCP Memory

The MCP Memory node provides functionality for managing memories in MCP. It supports the following operations:

- **Add Memory**: Add a new memory to MCP
- **Get Memory**: Retrieve a memory by its ID
- **Search Memories**: Search for memories based on content or metadata
- **Update Memory**: Update an existing memory's content or metadata
- **Delete Memory**: Remove a memory from MCP

## Installation

To install these custom nodes in your n8n instance:

1. Copy the node directories (`mcp-client` and `mcp-memory`) to your n8n custom nodes directory
2. Restart your n8n instance
3. Configure the MCP Client API credentials in n8n

## Configuration

### MCP Client API Credentials

The MCP nodes require credentials to connect to MCP servers. You can configure these in n8n:

1. Go to **Settings** > **Credentials**
2. Click **New Credential**
3. Select **MCP Client API**
4. Configure the connection:
   - For HTTP connection:
     - **Base URL**: The URL of your MCP server (e.g., `http://localhost:3000`)
     - **API Key**: Your MCP server API key
   - For Command Line connection:
     - **Command**: The command to execute (e.g., `node` or `python`)
     - **Arguments**: Arguments to pass to the command (e.g., `mcp-server.js` or `mcp_server.py`)
     - **Environment Variables**: Environment variables to set (format: `KEY1=value1,KEY2=value2`)

## Example Workflows

Example workflows demonstrating the use of MCP nodes can be found in the `workflows/examples` directory:

- **mcp-memory-management.json**: Demonstrates basic memory operations (add, get, update, search, delete)
- **mcp-email-generation.json**: Shows how to use MCP for context-aware email generation

## Development

To modify or extend these nodes:

1. Make your changes to the TypeScript files
2. Compile the nodes using the n8n build process
3. Restart your n8n instance to load the updated nodes

## Troubleshooting

If you encounter issues with the MCP nodes:

1. Check that your MCP server is running and accessible
2. Verify that your credentials are correctly configured
3. Check the n8n logs for error messages
4. Ensure that your MCP server supports the operations you're trying to use

## License

These nodes are provided under the same license as the main project.
