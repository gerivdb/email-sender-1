/**
 * Script de test pour la connexion en ligne de commande
 * 
 * Ce script teste la communication avec le serveur MCP en ligne de commande
 */

const { spawn } = require('child_process');
const path = require('path');

// Chemin vers le script du serveur MCP en ligne de commande
const serverPath = path.join(__dirname, 'mcp-cmd-server.js');

// Fonction pour exécuter une commande MCP
async function executeMCPCommand(operation, params = {}) {
  return new Promise((resolve, reject) => {
    // Créer l'objet de requête
    const request = {
      operation,
      ...params
    };
    
    // Lancer le processus
    const process = spawn('node', [serverPath]);
    
    // Collecter la sortie
    let stdout = '';
    let stderr = '';
    
    process.stdout.on('data', (data) => {
      stdout += data.toString();
    });
    
    process.stderr.on('data', (data) => {
      stderr += data.toString();
    });
    
    // Gérer la fin du processus
    process.on('close', (code) => {
      if (code !== 0) {
        reject(new Error(`La commande a échoué avec le code ${code}: ${stderr}`));
        return;
      }
      
      try {
        const response = JSON.parse(stdout);
        resolve(response);
      } catch (error) {
        reject(new Error(`Impossible d'analyser la sortie JSON: ${stdout}`));
      }
    });
    
    // Envoyer la requête au processus
    process.stdin.write(JSON.stringify(request));
    process.stdin.end();
  });
}

// Fonction pour tester le nœud MCP Client
async function testMCPClient() {
  console.log('=== Test du nœud MCP Client (ligne de commande) ===');
  
  try {
    // Test de l'opération getContext
    console.log('\n1. Test de l\'opération getContext');
    const contextResponse = await executeMCPCommand('getContext', {
      prompt: 'Générer un email pour Jean Dupont',
      sources: ['notion', 'calendar', 'memory'],
    });
    
    console.log('Réponse:', JSON.stringify(contextResponse, null, 2));
    
    // Test de l'opération listTools
    console.log('\n2. Test de l\'opération listTools');
    const toolsResponse = await executeMCPCommand('listTools');
    
    console.log('Réponse:', JSON.stringify(toolsResponse, null, 2));
    
    // Test de l'opération executeTool
    console.log('\n3. Test de l\'opération executeTool');
    const executeToolResponse = await executeMCPCommand('executeTool', {
      toolName: 'search_documentation',
      parameters: {
        query: 'Comment utiliser MCP avec n8n',
      },
    });
    
    console.log('Réponse:', JSON.stringify(executeToolResponse, null, 2));
    
    console.log('\nTous les tests du nœud MCP Client ont réussi!');
  } catch (error) {
    console.error('Erreur lors des tests du nœud MCP Client:', error.message);
  }
}

// Fonction pour tester le nœud MCP Memory
async function testMCPMemory() {
  console.log('\n=== Test du nœud MCP Memory (ligne de commande) ===');
  
  try {
    // Test de l'opération addMemory
    console.log('\n1. Test de l\'opération addMemory');
    const addMemoryResponse = await executeMCPCommand('addMemory', {
      content: 'Ceci est une mémoire de test pour n8n',
      metadata: {
        category: 'test',
        tags: ['n8n', 'mcp', 'test'],
      },
    });
    
    console.log('Réponse:', JSON.stringify(addMemoryResponse, null, 2));
    const memoryId = addMemoryResponse.memory_id;
    
    // Test de l'opération getMemory
    console.log('\n2. Test de l\'opération getMemory');
    const getMemoryResponse = await executeMCPCommand('getMemory', {
      memoryId,
    });
    
    console.log('Réponse:', JSON.stringify(getMemoryResponse, null, 2));
    
    // Test de l'opération searchMemories
    console.log('\n3. Test de l\'opération searchMemories');
    const searchMemoriesResponse = await executeMCPCommand('searchMemories', {
      query: 'test',
      metadata: {
        category: 'test',
      },
      limit: 10,
    });
    
    console.log('Réponse:', JSON.stringify(searchMemoriesResponse, null, 2));
    
    console.log('\nTous les tests du nœud MCP Memory ont réussi!');
  } catch (error) {
    console.error('Erreur lors des tests du nœud MCP Memory:', error.message);
  }
}

// Exécution des tests
async function runTests() {
  console.log('Démarrage des tests pour l\'intégration MCP avec n8n (ligne de commande)...\n');
  
  try {
    // Exécuter les tests
    await testMCPClient();
    await testMCPMemory();
    
    console.log('\nTous les tests ont été exécutés!');
  } catch (error) {
    console.error('Erreur lors de l\'exécution des tests:', error.message);
  }
}

// Exécuter les tests
runTests();
