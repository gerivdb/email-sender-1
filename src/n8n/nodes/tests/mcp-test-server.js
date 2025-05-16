/**
 * Serveur de test MCP pour les tests automatisés
 * 
 * Ce serveur simule un serveur MCP pour les tests automatisés des nodes n8n.
 * Il prend en charge les opérations de base du MCP Client et du MCP Memory.
 */

const http = require('http');
const url = require('url');

// Récupérer les arguments de la ligne de commande
const port = process.argv[2] ? parseInt(process.argv[2]) : 3001;
const apiKey = process.argv[3] || 'test-api-key-automated';

// Données de test
const memories = {
  'mem-123': {
    memory_id: 'mem-123',
    content: 'Contenu de test pour la mémoire 123',
    metadata: {
      category: 'test',
      tags: ['exemple', 'n8n', 'mcp']
    },
    created_at: new Date().toISOString(),
    updated_at: null
  }
};

const tools = [
  {
    name: 'search_documentation',
    description: 'Rechercher dans la documentation',
    parameters: {
      query: {
        type: 'string',
        description: 'La requête de recherche'
      }
    }
  },
  {
    name: 'get_context',
    description: 'Obtenir du contexte pour un prompt',
    parameters: {
      prompt: {
        type: 'string',
        description: 'Le prompt pour lequel obtenir du contexte'
      },
      sources: {
        type: 'array',
        description: 'Les sources à utiliser pour le contexte'
      }
    }
  }
];

// Fonction pour lire le corps de la requête
function readRequestBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    
    req.on('data', chunk => {
      body += chunk.toString();
    });
    
    req.on('end', () => {
      try {
        const data = body ? JSON.parse(body) : {};
        resolve(data);
      } catch (error) {
        reject(new Error(`Impossible de parser le corps de la requête: ${error.message}`));
      }
    });
    
    req.on('error', error => {
      reject(error);
    });
  });
}

// Fonction pour envoyer une réponse JSON
function sendJsonResponse(res, statusCode, data) {
  res.writeHead(statusCode, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
}

// Fonction pour vérifier l'API key
function checkApiKey(req, res) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || authHeader !== `Bearer ${apiKey}`) {
    sendJsonResponse(res, 401, { error: 'Non autorisé' });
    return false;
  }
  
  return true;
}

// Fonction pour gérer les requêtes
async function handleRequest(req, res) {
  // Vérifier l'API key
  if (!checkApiKey(req, res)) {
    return;
  }
  
  // Parser l'URL
  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;
  const method = req.method;
  
  try {
    // Gérer les différentes routes
    if (path === '/api/context' && method === 'POST') {
      // Opération getContext
      const data = await readRequestBody(req);
      const { prompt, sources } = data;
      
      sendJsonResponse(res, 200, {
        context: `Contexte pour le prompt: "${prompt}" en utilisant les sources: ${sources.join(', ')}`,
        sources_used: sources,
        timestamp: new Date().toISOString()
      });
    } 
    else if (path === '/api/tools' && method === 'GET') {
      // Opération listTools
      sendJsonResponse(res, 200, { tools });
    } 
    else if (path.startsWith('/api/tools/') && method === 'POST') {
      // Opération executeTool
      const toolName = path.split('/').pop();
      const tool = tools.find(t => t.name === toolName);
      
      if (!tool) {
        sendJsonResponse(res, 404, { error: 'Outil non trouvé' });
        return;
      }
      
      const data = await readRequestBody(req);
      
      sendJsonResponse(res, 200, {
        result: `Exécution de l'outil: ${toolName} avec les paramètres: ${JSON.stringify(data)}`,
        timestamp: new Date().toISOString()
      });
    } 
    else if (path === '/api/memory' && method === 'POST') {
      // Opération addMemory
      const data = await readRequestBody(req);
      const { content, metadata } = data;
      
      const memoryId = `mem-${Date.now()}`;
      memories[memoryId] = {
        memory_id: memoryId,
        content,
        metadata,
        created_at: new Date().toISOString(),
        updated_at: null
      };
      
      sendJsonResponse(res, 200, {
        memory_id: memoryId,
        message: 'Mémoire ajoutée avec succès'
      });
    } 
    else if (path.match(/^\/api\/memory\/[^\/]+$/) && method === 'GET') {
      // Opération getMemory
      const memoryId = path.split('/').pop();
      const memory = memories[memoryId];
      
      if (!memory) {
        sendJsonResponse(res, 404, { error: 'Mémoire non trouvée' });
        return;
      }
      
      sendJsonResponse(res, 200, memory);
    } 
    else if (path === '/api/memory/search' && method === 'POST') {
      // Opération searchMemories
      const data = await readRequestBody(req);
      const { query, metadata, limit } = data;
      
      // Recherche simple
      const results = Object.values(memories)
        .filter(memory => {
          // Filtrer par contenu
          if (query && !memory.content.includes(query)) {
            return false;
          }
          
          // Filtrer par métadonnées
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
      
      sendJsonResponse(res, 200, {
        results,
        count: results.length,
        query,
        metadata
      });
    } 
    else if (path.match(/^\/api\/memory\/[^\/]+$/) && method === 'PUT') {
      // Opération updateMemory
      const memoryId = path.split('/').pop();
      const memory = memories[memoryId];
      
      if (!memory) {
        sendJsonResponse(res, 404, { error: 'Mémoire non trouvée' });
        return;
      }
      
      const data = await readRequestBody(req);
      const { content, metadata } = data;
      
      if (content) {
        memory.content = content;
      }
      
      if (metadata) {
        memory.metadata = { ...memory.metadata, ...metadata };
      }
      
      memory.updated_at = new Date().toISOString();
      
      sendJsonResponse(res, 200, {
        memory_id: memoryId,
        message: 'Mémoire mise à jour avec succès'
      });
    } 
    else if (path.match(/^\/api\/memory\/[^\/]+$/) && method === 'DELETE') {
      // Opération deleteMemory
      const memoryId = path.split('/').pop();
      
      if (!memories[memoryId]) {
        sendJsonResponse(res, 404, { error: 'Mémoire non trouvée' });
        return;
      }
      
      delete memories[memoryId];
      
      sendJsonResponse(res, 200, {
        memory_id: memoryId,
        message: 'Mémoire supprimée avec succès'
      });
    } 
    else if (path === '/' && method === 'GET') {
      // Route de base pour vérifier que le serveur est en cours d'exécution
      sendJsonResponse(res, 200, {
        message: 'Serveur de test MCP en cours d\'exécution',
        version: '1.0.0'
      });
    } 
    else {
      // Route non trouvée
      sendJsonResponse(res, 404, { error: 'Route non trouvée' });
    }
  } catch (error) {
    console.error(`Erreur lors du traitement de la requête: ${error.message}`);
    sendJsonResponse(res, 500, { error: `Erreur interne du serveur: ${error.message}` });
  }
}

// Créer et démarrer le serveur
const server = http.createServer(handleRequest);

server.listen(port, () => {
  console.log(`MCP test server running at http://localhost:${port}`);
  console.log(`API Key: ${apiKey}`);
});

// Gérer l'arrêt du serveur
process.on('SIGINT', () => {
  console.log('Arrêt du serveur de test MCP');
  server.close();
  process.exit(0);
});
