/**
 * Test script for MCP Client node
 * 
 * This script simulates an MCP server for testing the MCP Client node.
 * It creates a simple HTTP server that responds to MCP API requests.
 */

const http = require('http');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

// Configuration
const PORT = 3000;
const API_KEY = 'test-api-key';

// Sample data
const memories = {
  'mem-123': {
    memory_id: 'mem-123',
    content: 'This is a test memory',
    metadata: {
      category: 'test',
      tags: ['example', 'n8n', 'mcp']
    },
    created_at: new Date().toISOString(),
    updated_at: null
  }
};

const tools = [
  {
    name: 'search_documentation',
    description: 'Search documentation for a query',
    parameters: {
      query: {
        type: 'string',
        description: 'The query to search for'
      }
    }
  },
  {
    name: 'get_context',
    description: 'Get context for a prompt',
    parameters: {
      prompt: {
        type: 'string',
        description: 'The prompt to get context for'
      },
      sources: {
        type: 'array',
        description: 'The sources to use for context'
      }
    }
  }
];

// Create HTTP server
const server = http.createServer((req, res) => {
  // Check API key
  const authHeader = req.headers.authorization;
  if (!authHeader || authHeader !== `Bearer ${API_KEY}`) {
    res.writeHead(401, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Unauthorized' }));
    return;
  }

  // Parse URL
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const path = url.pathname;
  
  // Handle different endpoints
  if (path === '/api/context' && req.method === 'POST') {
    // Get context
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        const { prompt, sources } = data;
        
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          context: `Context for prompt: "${prompt}" using sources: ${sources.join(', ')}`,
          sources_used: sources,
          timestamp: new Date().toISOString()
        }));
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid request body' }));
      }
    });
  } else if (path === '/api/tools' && req.method === 'GET') {
    // List tools
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ tools }));
  } else if (path.startsWith('/api/tools/') && req.method === 'POST') {
    // Execute tool
    const toolName = path.split('/').pop();
    const tool = tools.find(t => t.name === toolName);
    
    if (!tool) {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Tool not found' }));
      return;
    }
    
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });
    req.on('end', () => {
      try {
        const parameters = JSON.parse(body);
        
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          result: `Executed tool: ${toolName} with parameters: ${JSON.stringify(parameters)}`,
          timestamp: new Date().toISOString()
        }));
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid request body' }));
      }
    });
  } else if (path === '/api/memory' && req.method === 'POST') {
    // Add memory
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        const { content, metadata } = data;
        
        const memoryId = `mem-${Date.now()}`;
        memories[memoryId] = {
          memory_id: memoryId,
          content,
          metadata,
          created_at: new Date().toISOString(),
          updated_at: null
        };
        
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          memory_id: memoryId,
          message: 'Memory added successfully'
        }));
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid request body' }));
      }
    });
  } else if (path.match(/^\/api\/memory\/[^\/]+$/) && req.method === 'GET') {
    // Get memory
    const memoryId = path.split('/').pop();
    const memory = memories[memoryId];
    
    if (!memory) {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Memory not found' }));
      return;
    }
    
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(memory));
  } else if (path === '/api/memory/search' && req.method === 'POST') {
    // Search memories
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        const { query, metadata, limit } = data;
        
        // Simple search implementation
        const results = Object.values(memories)
          .filter(memory => {
            // Filter by content
            if (query && !memory.content.includes(query)) {
              return false;
            }
            
            // Filter by metadata
            if (metadata) {
              for (const [key, value] of Object.entries(metadata)) {
                if (memory.metadata[key] !== value) {
                  return false;
                }
              }
            }
            
            return true;
          })
          .slice(0, limit || 10);
        
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          results,
          count: results.length,
          query,
          metadata
        }));
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid request body' }));
      }
    });
  } else {
    // Not found
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
  }
});

// Start server
server.listen(PORT, () => {
  console.log(`MCP test server running at http://localhost:${PORT}`);
  console.log(`API Key: ${API_KEY}`);
  console.log('Press Ctrl+C to stop');
});

// Handle server shutdown
process.on('SIGINT', () => {
  console.log('Shutting down MCP test server');
  server.close();
  process.exit(0);
});
