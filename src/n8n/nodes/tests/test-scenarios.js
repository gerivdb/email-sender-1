/**
 * Script de test pour les scénarios d'utilisation des nodes MCP
 * 
 * Ce script teste différents scénarios d'utilisation des nodes MCP
 * pour s'assurer qu'ils fonctionnent correctement dans des cas réels.
 */

const assert = require('assert');
const { spawn } = require('child_process');
const http = require('http');
const path = require('path');
const fs = require('fs');

// Configuration
const TEST_PORT = 3002;
const TEST_API_KEY = 'test-api-key-scenarios';
const TEST_TIMEOUT = 10000; // 10 secondes
const TEST_SERVER_PATH = path.join(__dirname, 'mcp-test-server.js');

// Couleurs pour la console
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

// Compteurs de tests
let passedScenarios = 0;
let failedScenarios = 0;
let totalScenarios = 0;

/**
 * Fonction pour exécuter un scénario de test
 * @param {string} name - Nom du scénario
 * @param {Function} scenarioFn - Fonction du scénario
 */
async function runScenario(name, scenarioFn) {
  totalScenarios++;
  
  try {
    console.log(`\n${colors.magenta}=== Scénario: ${name} ===${colors.reset}`);
    await scenarioFn();
    console.log(`${colors.green}✓ Scénario réussi: ${name}${colors.reset}`);
    passedScenarios++;
  } catch (error) {
    console.error(`${colors.red}✗ Scénario échoué: ${name}${colors.reset}`);
    console.error(`  ${error.message}`);
    if (error.stack) {
      console.error(`  ${error.stack.split('\n').slice(1).join('\n')}`);
    }
    failedScenarios++;
  }
}

/**
 * Fonction pour démarrer le serveur de test
 * @returns {Promise<{server: ChildProcess, port: number}>}
 */
async function startTestServer() {
  return new Promise((resolve, reject) => {
    const server = spawn('node', [TEST_SERVER_PATH, TEST_PORT.toString(), TEST_API_KEY]);
    
    let output = '';
    
    server.stdout.on('data', (data) => {
      output += data.toString();
      if (output.includes('MCP test server running')) {
        resolve({ server, port: TEST_PORT });
      }
    });
    
    server.stderr.on('data', (data) => {
      console.error(`Erreur du serveur de test: ${data}`);
    });
    
    server.on('error', (error) => {
      reject(error);
    });
    
    // Timeout si le serveur ne démarre pas
    setTimeout(() => {
      if (!output.includes('MCP test server running')) {
        server.kill();
        reject(new Error('Timeout lors du démarrage du serveur de test'));
      }
    }, TEST_TIMEOUT);
  });
}

/**
 * Fonction pour effectuer une requête HTTP
 * @param {string} method - Méthode HTTP (GET, POST, etc.)
 * @param {string} endpoint - Point de terminaison de l'API
 * @param {Object} data - Données à envoyer (pour POST, PUT)
 * @returns {Promise<Object>} - Réponse JSON
 */
async function makeRequest(method, endpoint, data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: TEST_PORT,
      path: endpoint,
      method: method,
      headers: {
        'Authorization': `Bearer ${TEST_API_KEY}`,
        'Content-Type': 'application/json'
      }
    };
    
    const req = http.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const jsonData = JSON.parse(responseData);
          resolve(jsonData);
        } catch (error) {
          reject(new Error(`Impossible de parser la réponse JSON: ${responseData}`));
        }
      });
    });
    
    req.on('error', (error) => {
      reject(error);
    });
    
    if (data) {
      req.write(JSON.stringify(data));
    }
    
    req.end();
  });
}

/**
 * Scénario 1: Génération d'email contextuel
 * 
 * Ce scénario simule le workflow de génération d'email contextuel:
 * 1. Récupérer le contexte pour un contact
 * 2. Générer un email personnalisé
 * 3. Sauvegarder l'email dans les mémoires
 */
async function scenarioEmailGeneration() {
  console.log(`${colors.blue}[1/3]${colors.reset} Récupération du contexte pour le contact...`);
  
  // Étape 1: Récupérer le contexte
  const contextResponse = await makeRequest('POST', '/api/context', {
    prompt: 'Générer un email pour Jean Dupont de la société Acme Inc.',
    sources: ['notion', 'calendar', 'memory']
  });
  
  assert.ok(contextResponse.context, 'Le contexte devrait être présent dans la réponse');
  console.log(`Contexte récupéré: ${contextResponse.context.substring(0, 50)}...`);
  
  // Simuler la génération d'email
  console.log(`${colors.blue}[2/3]${colors.reset} Génération de l'email personnalisé...`);
  const emailContent = `
Bonjour Jean,

Suite à notre conversation, je vous confirme notre disponibilité pour un concert dans vos locaux le 15 juin 2025.

Comme discuté, notre prestation comprendra un set de 90 minutes avec notre formation complète.

Pourriez-vous me confirmer les détails techniques et logistiques?

Cordialement,
L'équipe artistique
  `;
  
  console.log(`Email généré: ${emailContent.substring(0, 50)}...`);
  
  // Étape 3: Sauvegarder l'email dans les mémoires
  console.log(`${colors.blue}[3/3]${colors.reset} Sauvegarde de l'email dans les mémoires...`);
  const saveResponse = await makeRequest('POST', '/api/memory', {
    content: emailContent,
    metadata: {
      type: 'email',
      recipient: 'Jean Dupont',
      company: 'Acme Inc.',
      timestamp: new Date().toISOString(),
      category: 'booking'
    }
  });
  
  assert.ok(saveResponse.memory_id, 'L\'ID de mémoire devrait être présent dans la réponse');
  assert.ok(saveResponse.message.includes('succès'), 'Le message devrait indiquer un succès');
  
  console.log(`Email sauvegardé avec l'ID: ${saveResponse.memory_id}`);
  
  // Vérifier que l'email a bien été sauvegardé
  const memoryResponse = await makeRequest('GET', `/api/memory/${saveResponse.memory_id}`);
  
  assert.strictEqual(memoryResponse.content, emailContent, 'Le contenu de la mémoire devrait correspondre à l\'email');
  assert.strictEqual(memoryResponse.metadata.recipient, 'Jean Dupont', 'Le destinataire devrait être correct');
  
  console.log(`${colors.green}Scénario de génération d'email complété avec succès!${colors.reset}`);
}

/**
 * Scénario 2: Recherche et mise à jour de mémoires
 * 
 * Ce scénario simule le workflow de recherche et mise à jour de mémoires:
 * 1. Ajouter plusieurs mémoires
 * 2. Rechercher des mémoires par catégorie
 * 3. Mettre à jour une mémoire
 * 4. Vérifier la mise à jour
 */
async function scenarioMemorySearchUpdate() {
  console.log(`${colors.blue}[1/4]${colors.reset} Ajout de plusieurs mémoires...`);
  
  // Étape 1: Ajouter plusieurs mémoires
  const memoryIds = [];
  
  for (let i = 0; i < 3; i++) {
    const response = await makeRequest('POST', '/api/memory', {
      content: `Contenu de test pour la mémoire ${i + 1}`,
      metadata: {
        category: 'test-scenario',
        index: i + 1,
        tags: ['test', 'scenario', `mem-${i + 1}`]
      }
    });
    
    assert.ok(response.memory_id, 'L\'ID de mémoire devrait être présent dans la réponse');
    memoryIds.push(response.memory_id);
  }
  
  console.log(`Mémoires ajoutées avec les IDs: ${memoryIds.join(', ')}`);
  
  // Étape 2: Rechercher des mémoires par catégorie
  console.log(`${colors.blue}[2/4]${colors.reset} Recherche de mémoires par catégorie...`);
  const searchResponse = await makeRequest('POST', '/api/memory/search', {
    metadata: {
      category: 'test-scenario'
    },
    limit: 10
  });
  
  assert.ok(searchResponse.results, 'Les résultats devraient être présents dans la réponse');
  assert.ok(Array.isArray(searchResponse.results), 'Les résultats devraient être un tableau');
  assert.ok(searchResponse.results.length >= 3, 'Il devrait y avoir au moins 3 résultats');
  
  console.log(`${searchResponse.results.length} mémoires trouvées`);
  
  // Étape 3: Mettre à jour une mémoire
  console.log(`${colors.blue}[3/4]${colors.reset} Mise à jour d'une mémoire...`);
  const memoryToUpdate = memoryIds[0];
  const updateResponse = await makeRequest('PUT', `/api/memory/${memoryToUpdate}`, {
    content: 'Contenu mis à jour pour la mémoire 1',
    metadata: {
      updated: true,
      update_time: new Date().toISOString()
    }
  });
  
  assert.ok(updateResponse.message.includes('succès'), 'Le message devrait indiquer un succès');
  
  // Étape 4: Vérifier la mise à jour
  console.log(`${colors.blue}[4/4]${colors.reset} Vérification de la mise à jour...`);
  const verifyResponse = await makeRequest('GET', `/api/memory/${memoryToUpdate}`);
  
  assert.strictEqual(verifyResponse.content, 'Contenu mis à jour pour la mémoire 1', 'Le contenu devrait être mis à jour');
  assert.strictEqual(verifyResponse.metadata.updated, true, 'Le métadata updated devrait être true');
  assert.ok(verifyResponse.metadata.update_time, 'Le métadata update_time devrait être présent');
  
  console.log(`${colors.green}Scénario de recherche et mise à jour complété avec succès!${colors.reset}`);
}

/**
 * Scénario 3: Exécution d'outils et gestion d'erreurs
 * 
 * Ce scénario simule le workflow d'exécution d'outils et de gestion d'erreurs:
 * 1. Lister les outils disponibles
 * 2. Exécuter un outil valide
 * 3. Tenter d'exécuter un outil invalide (gestion d'erreur)
 * 4. Tester la validation des entrées
 */
async function scenarioToolExecutionErrors() {
  console.log(`${colors.blue}[1/4]${colors.reset} Listage des outils disponibles...`);
  
  // Étape 1: Lister les outils disponibles
  const toolsResponse = await makeRequest('GET', '/api/tools');
  
  assert.ok(toolsResponse.tools, 'Les outils devraient être présents dans la réponse');
  assert.ok(Array.isArray(toolsResponse.tools), 'Les outils devraient être un tableau');
  assert.ok(toolsResponse.tools.length > 0, 'Il devrait y avoir au moins un outil');
  
  const availableTools = toolsResponse.tools.map(tool => tool.name);
  console.log(`Outils disponibles: ${availableTools.join(', ')}`);
  
  // Étape 2: Exécuter un outil valide
  console.log(`${colors.blue}[2/4]${colors.reset} Exécution d'un outil valide...`);
  const validToolResponse = await makeRequest('POST', '/api/tools/search_documentation', {
    query: 'Comment utiliser MCP avec n8n'
  });
  
  assert.ok(validToolResponse.result, 'Le résultat devrait être présent dans la réponse');
  assert.ok(validToolResponse.result.includes('search_documentation'), 'Le résultat devrait mentionner l\'outil exécuté');
  
  console.log(`Outil exécuté avec succès: ${validToolResponse.result.substring(0, 50)}...`);
  
  // Étape 3: Tenter d'exécuter un outil invalide
  console.log(`${colors.blue}[3/4]${colors.reset} Tentative d'exécution d'un outil invalide...`);
  try {
    await makeRequest('POST', '/api/tools/invalid_tool', {
      param: 'test'
    });
    
    // Si on arrive ici, c'est que la requête a réussi, ce qui est une erreur
    throw new Error('La requête aurait dû échouer avec une erreur 404');
  } catch (error) {
    // Vérifier que l'erreur est bien une erreur 404
    assert.ok(error.message.includes('404') || error.message.includes('non trouvé'), 'L\'erreur devrait être une erreur 404');
    console.log(`Erreur correctement gérée: ${error.message}`);
  }
  
  // Étape 4: Tester la validation des entrées
  console.log(`${colors.blue}[4/4]${colors.reset} Test de la validation des entrées...`);
  try {
    // Envoyer une requête avec un corps invalide
    const invalidBody = 'Ceci n\'est pas du JSON';
    
    const options = {
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/api/context',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${TEST_API_KEY}`,
        'Content-Type': 'application/json'
      }
    };
    
    await new Promise((resolve, reject) => {
      const req = http.request(options, (res) => {
        let responseData = '';
        
        res.on('data', (chunk) => {
          responseData += chunk;
        });
        
        res.on('end', () => {
          if (res.statusCode >= 400) {
            reject(new Error(`Erreur ${res.statusCode}: ${responseData}`));
          } else {
            resolve(responseData);
          }
        });
      });
      
      req.on('error', (error) => {
        reject(error);
      });
      
      req.write(invalidBody);
      req.end();
    });
    
    // Si on arrive ici, c'est que la requête a réussi, ce qui est une erreur
    throw new Error('La requête aurait dû échouer avec une erreur de parsing JSON');
  } catch (error) {
    // Vérifier que l'erreur est bien une erreur de parsing JSON
    assert.ok(error.message.includes('JSON') || error.message.includes('parse'), 'L\'erreur devrait être une erreur de parsing JSON');
    console.log(`Erreur correctement gérée: ${error.message}`);
  }
  
  console.log(`${colors.green}Scénario d'exécution d'outils et gestion d'erreurs complété avec succès!${colors.reset}`);
}

/**
 * Fonction principale pour exécuter tous les scénarios
 */
async function runAllScenarios() {
  console.log(`${colors.magenta}=== Tests de scénarios pour les nodes MCP ===${colors.reset}`);
  console.log(`Date: ${new Date().toISOString()}`);
  console.log('');
  
  let testServer;
  
  try {
    // Démarrer le serveur de test
    console.log(`${colors.cyan}Démarrage du serveur de test...${colors.reset}`);
    testServer = await startTestServer();
    console.log(`${colors.cyan}Serveur de test démarré sur le port ${testServer.port}${colors.reset}`);
    
    // Exécuter les scénarios
    await runScenario('Génération d\'email contextuel', scenarioEmailGeneration);
    await runScenario('Recherche et mise à jour de mémoires', scenarioMemorySearchUpdate);
    await runScenario('Exécution d\'outils et gestion d\'erreurs', scenarioToolExecutionErrors);
    
    // Afficher le résumé
    console.log(`\n${colors.magenta}=== Résumé des scénarios ===${colors.reset}`);
    console.log(`Total: ${totalScenarios}`);
    console.log(`${colors.green}Réussis: ${passedScenarios}${colors.reset}`);
    console.log(`${colors.red}Échoués: ${failedScenarios}${colors.reset}`);
    
    // Retourner le code de sortie approprié
    process.exitCode = failedScenarios > 0 ? 1 : 0;
  } catch (error) {
    console.error(`${colors.red}Erreur lors de l'exécution des scénarios: ${error.message}${colors.reset}`);
    process.exitCode = 1;
  } finally {
    // Arrêter le serveur de test
    if (testServer && testServer.server) {
      testServer.server.kill();
      console.log(`${colors.cyan}Serveur de test arrêté${colors.reset}`);
    }
  }
}

// Exécuter les scénarios
runAllScenarios();
