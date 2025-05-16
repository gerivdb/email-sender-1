module.exports = {
  // Nodes
  nodeTypes: [
    require('./mcp-client/MCP.node.js'),
    require('./mcp-memory/MCPMemory.node.js'),
  ],
  // Credentials
  credentialTypes: [
    require('./mcp-client/MCPClientApi.credentials.js'),
  ],
};
