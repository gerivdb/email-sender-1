/**
 * Script de test pour simuler des requêtes vers un serveur MCP
 */

const axios = require('axios');

// Configuration
const BASE_URL = 'http://localhost:3000';
const API_KEY = 'test-api-key';

// Fonction pour tester le nœud MCP Client
async function testMCPClient() {
  console.log('=== Test du nœud MCP Client ===');
  
  try {
    // Test de l'opération getContext
    console.log('\n1. Test de l\'opération getContext');
    const contextResponse = await axios({
      method: 'POST',
      url: `${BASE_URL}/api/context`,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${API_KEY}`,
      },
      data: {
        prompt: 'Générer un email pour Jean Dupont',
        sources: ['notion', 'calendar', 'memory'],
      },
    });
    
    console.log('Réponse:', JSON.stringify(contextResponse.data, null, 2));
    
    // Test de l'opération listTools
    console.log('\n2. Test de l\'opération listTools');
    const toolsResponse = await axios({
      method: 'GET',
      url: `${BASE_URL}/api/tools`,
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
      },
    });
    
    console.log('Réponse:', JSON.stringify(toolsResponse.data, null, 2));
    
    // Test de l'opération executeTool
    console.log('\n3. Test de l\'opération executeTool');
    const executeToolResponse = await axios({
      method: 'POST',
      url: `${BASE_URL}/api/tools/search_documentation`,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${API_KEY}`,
      },
      data: {
        query: 'Comment utiliser MCP avec n8n',
      },
    });
    
    console.log('Réponse:', JSON.stringify(executeToolResponse.data, null, 2));
    
    console.log('\nTous les tests du nœud MCP Client ont réussi!');
  } catch (error) {
    console.error('Erreur lors des tests du nœud MCP Client:', error.message);
    if (error.response) {
      console.error('Détails de la réponse:', error.response.data);
    }
  }
}

// Fonction pour tester le nœud MCP Memory
async function testMCPMemory() {
  console.log('\n=== Test du nœud MCP Memory ===');
  
  try {
    // Test de l'opération addMemory
    console.log('\n1. Test de l\'opération addMemory');
    const addMemoryResponse = await axios({
      method: 'POST',
      url: `${BASE_URL}/api/memory`,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${API_KEY}`,
      },
      data: {
        content: 'Ceci est une mémoire de test pour n8n',
        metadata: {
          category: 'test',
          tags: ['n8n', 'mcp', 'test'],
        },
      },
    });
    
    console.log('Réponse:', JSON.stringify(addMemoryResponse.data, null, 2));
    const memoryId = addMemoryResponse.data.memory_id;
    
    // Test de l'opération getMemory
    console.log('\n2. Test de l\'opération getMemory');
    const getMemoryResponse = await axios({
      method: 'GET',
      url: `${BASE_URL}/api/memory/${memoryId}`,
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
      },
    });
    
    console.log('Réponse:', JSON.stringify(getMemoryResponse.data, null, 2));
    
    // Test de l'opération searchMemories
    console.log('\n3. Test de l\'opération searchMemories');
    const searchMemoriesResponse = await axios({
      method: 'POST',
      url: `${BASE_URL}/api/memory/search`,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${API_KEY}`,
      },
      data: {
        query: 'test',
        metadata: {
          category: 'test',
        },
        limit: 10,
      },
    });
    
    console.log('Réponse:', JSON.stringify(searchMemoriesResponse.data, null, 2));
    
    console.log('\nTous les tests du nœud MCP Memory ont réussi!');
  } catch (error) {
    console.error('Erreur lors des tests du nœud MCP Memory:', error.message);
    if (error.response) {
      console.error('Détails de la réponse:', error.response.data);
    }
  }
}

// Exécution des tests
async function runTests() {
  console.log('Démarrage des tests pour l\'intégration MCP avec n8n...\n');
  
  try {
    // Vérifier que le serveur est accessible
    await axios.get(BASE_URL);
    console.log(`Serveur accessible à ${BASE_URL}`);
    
    // Exécuter les tests
    await testMCPClient();
    await testMCPMemory();
    
    console.log('\nTous les tests ont été exécutés!');
  } catch (error) {
    console.error(`Erreur: Impossible de se connecter au serveur à ${BASE_URL}`);
    console.error('Assurez-vous que le serveur de test est en cours d\'exécution.');
    console.error('Détails de l\'erreur:', error.message);
  }
}

// Exécuter les tests
runTests();
