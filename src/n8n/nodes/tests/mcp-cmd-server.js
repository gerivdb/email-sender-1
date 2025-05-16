/**
 * Command-line MCP server for testing
 * 
 * This script simulates an MCP server that communicates via stdin/stdout.
 * It reads JSON requests from stdin and writes JSON responses to stdout.
 */

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

// Read input from stdin
process.stdin.setEncoding('utf8');

let inputData = '';

process.stdin.on('data', (chunk) => {
  inputData += chunk;
});

process.stdin.on('end', () => {
  try {
    // Parse the input JSON
    const request = JSON.parse(inputData);
    const { operation } = request;
    
    let response;
    
    // Handle different operations
    if (operation === 'getContext') {
      const { prompt, sources } = request;
      
      response = {
        context: `Context for prompt: "${prompt}" using sources: ${sources.join(', ')}`,
        sources_used: sources,
        timestamp: new Date().toISOString()
      };
    } else if (operation === 'listTools') {
      response = { tools };
    } else if (operation === 'executeTool') {
      const { toolName, parameters } = request;
      const tool = tools.find(t => t.name === toolName);
      
      if (!tool) {
        response = { error: 'Tool not found' };
      } else {
        response = {
          result: `Executed tool: ${toolName} with parameters: ${JSON.stringify(parameters)}`,
          timestamp: new Date().toISOString()
        };
      }
    } else if (operation === 'addMemory') {
      const { content, metadata } = request;
      
      const memoryId = `mem-${Date.now()}`;
      memories[memoryId] = {
        memory_id: memoryId,
        content,
        metadata,
        created_at: new Date().toISOString(),
        updated_at: null
      };
      
      response = {
        memory_id: memoryId,
        message: 'Memory added successfully'
      };
    } else if (operation === 'getMemory') {
      const { memoryId } = request;
      const memory = memories[memoryId];
      
      if (!memory) {
        response = { error: 'Memory not found' };
      } else {
        response = memory;
      }
    } else if (operation === 'searchMemories') {
      const { query, metadata, limit } = request;
      
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
      
      response = {
        results,
        count: results.length,
        query,
        metadata
      };
    } else if (operation === 'updateMemory') {
      const { memoryId, content, metadata } = request;
      const memory = memories[memoryId];
      
      if (!memory) {
        response = { error: 'Memory not found' };
      } else {
        if (content) {
          memory.content = content;
        }
        
        if (metadata) {
          memory.metadata = { ...memory.metadata, ...metadata };
        }
        
        memory.updated_at = new Date().toISOString();
        
        response = {
          memory_id: memoryId,
          message: 'Memory updated successfully'
        };
      }
    } else if (operation === 'deleteMemory') {
      const { memoryId } = request;
      
      if (!memories[memoryId]) {
        response = { error: 'Memory not found' };
      } else {
        delete memories[memoryId];
        
        response = {
          memory_id: memoryId,
          message: 'Memory deleted successfully'
        };
      }
    } else {
      response = { error: `Unknown operation: ${operation}` };
    }
    
    // Write the response to stdout
    process.stdout.write(JSON.stringify(response));
  } catch (error) {
    // Handle parsing errors
    process.stdout.write(JSON.stringify({ error: `Error processing request: ${error.message}` }));
  }
});
