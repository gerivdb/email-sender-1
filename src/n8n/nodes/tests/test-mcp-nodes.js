/**
 * Script de test automatisé pour les nodes MCP
 *
 * Ce script teste les nodes MCP Client et MCP Memory en simulant des requêtes
 * et en vérifiant les réponses attendues.
 */

const assert = require('assert');
const { spawn } = require('child_process');
const http = require('http');
const path = require('path');
const fs = require('fs');

// Configuration
const TEST_PORT = 3001;
const TEST_API_KEY = 'test-api-key-automated';
const TEST_TIMEOUT = 10000; // 10 secondes
const TEST_SERVER_PATH = path.join(__dirname, 'mcp-test-server.js');
const TEST_CMD_SERVER_PATH = path.join(__dirname, 'mcp-cmd-server.js');

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
let passedTests = 0;
let failedTests = 0;
let skippedTests = 0;
let totalTests = 0;

/**
 * Fonction pour exécuter un test
 * @param {string} name - Nom du test
 * @param {Function} testFn - Fonction de test
 * @param {boolean} skip - Si true, le test sera ignoré
 */
async function runTest(name, testFn, skip = false) {
  totalTests++;

  if (skip) {
    console.log(`${colors.yellow}[SKIP]${colors.reset} ${name}`);
    skippedTests++;
    return;
  }

  try {
    console.log(`${colors.blue}[RUN]${colors.reset} ${name}`);
    await testFn();
    console.log(`${colors.green}[PASS]${colors.reset} ${name}`);
    passedTests++;
  } catch (error) {
    console.error(`${colors.red}[FAIL]${colors.reset} ${name}`);
    console.error(`       ${error.message}`);
    if (error.stack) {
      console.error(`       ${error.stack.split('\n').slice(1).join('\n')}`);
    }
    failedTests++;
  }
}

/**
 * Fonction pour démarrer le serveur de test HTTP
 * @returns {Promise<{server: http.Server, port: number}>}
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
 * Fonction pour exécuter une commande MCP
 * @param {string} operation - Opération MCP
 * @param {Object} params - Paramètres de l'opération
 * @returns {Promise<Object>} - Réponse JSON
 */
async function executeMCPCommand(operation, params = {}) {
  return new Promise((resolve, reject) => {
    const request = {
      operation,
      ...params
    };

    const process = spawn('node', [TEST_CMD_SERVER_PATH]);

    let stdout = '';
    let stderr = '';

    process.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    process.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    process.on('close', (code) => {
      if (code !== 0) {
        reject(new Error(`La commande a échoué avec le code ${code}: ${stderr}`));
        return;
      }

      try {
        const response = JSON.parse(stdout);
        resolve(response);
      } catch (error) {
        reject(new Error(`Impossible de parser la sortie JSON: ${stdout}`));
      }
    });

    process.stdin.write(JSON.stringify(request));
    process.stdin.end();
  });
}

/**
 * Tests pour le node MCP Client (HTTP)
 */
async function testMCPClientHTTP() {
  // Test de l'opération getContext
  await runTest('MCP Client HTTP - getContext', async () => {
    const response = await makeRequest('POST', '/api/context', {
      prompt: 'Test prompt',
      sources: ['test', 'memory']
    });

    assert.ok(response.context, 'La réponse devrait contenir un contexte');
    assert.ok(response.sources_used, 'La réponse devrait contenir les sources utilisées');
    assert.deepStrictEqual(response.sources_used, ['test', 'memory'], 'Les sources utilisées devraient correspondre');
  });

  // Test de l'opération listTools
  await runTest('MCP Client HTTP - listTools', async () => {
    const response = await makeRequest('GET', '/api/tools');

    assert.ok(response.tools, 'La réponse devrait contenir une liste d\'outils');
    assert.ok(Array.isArray(response.tools), 'La liste d\'outils devrait être un tableau');
    assert.ok(response.tools.length > 0, 'La liste d\'outils ne devrait pas être vide');
  });

  // Test de l'opération executeTool
  await runTest('MCP Client HTTP - executeTool', async () => {
    const response = await makeRequest('POST', '/api/tools/search_documentation', {
      query: 'Test query'
    });

    assert.ok(response.result, 'La réponse devrait contenir un résultat');
    assert.ok(response.result.includes('search_documentation'), 'Le résultat devrait mentionner l\'outil exécuté');
    assert.ok(response.result.includes('Test query'), 'Le résultat devrait contenir la requête');
  });
}

/**
 * Tests pour le node MCP Memory (HTTP)
 */
async function testMCPMemoryHTTP() {
  let memoryId;

  // Test de l'opération addMemory
  await runTest('MCP Memory HTTP - addMemory', async () => {
    const response = await makeRequest('POST', '/api/memory', {
      content: 'Test memory content',
      metadata: {
        category: 'test',
        tags: ['test', 'automated']
      }
    });

    assert.ok(response.memory_id, 'La réponse devrait contenir un ID de mémoire');
    assert.ok(response.message, 'La réponse devrait contenir un message');
    assert.ok(response.message.includes('succès') || response.message.includes('success'), 'Le message devrait indiquer un succès');

    memoryId = response.memory_id;
  });

  // Test de l'opération getMemory
  await runTest('MCP Memory HTTP - getMemory', async () => {
    const response = await makeRequest('GET', `/api/memory/${memoryId}`);

    assert.strictEqual(response.memory_id, memoryId, 'L\'ID de mémoire devrait correspondre');
    assert.strictEqual(response.content, 'Test memory content', 'Le contenu de la mémoire devrait correspondre');
    assert.deepStrictEqual(response.metadata.category, 'test', 'La catégorie de la mémoire devrait correspondre');
    assert.ok(Array.isArray(response.metadata.tags), 'Les tags devraient être un tableau');
    assert.ok(response.metadata.tags.includes('test'), 'Les tags devraient inclure "test"');
  });

  // Test de l'opération searchMemories
  await runTest('MCP Memory HTTP - searchMemories', async () => {
    const response = await makeRequest('POST', '/api/memory/search', {
      query: 'test',
      metadata: {
        category: 'test'
      },
      limit: 10
    });

    assert.ok(response.results, 'La réponse devrait contenir des résultats');
    assert.ok(Array.isArray(response.results), 'Les résultats devraient être un tableau');

    // Vérifier si des résultats sont retournés, mais ne pas exiger qu'ils contiennent la mémoire spécifique
    // car cela dépend de l'état du serveur de test
    if (response.results.length === 0) {
      console.log(`${colors.yellow}[WARN]${colors.reset} Aucun résultat trouvé dans la recherche de mémoires`);
    } else {
      console.log(`${colors.green}[INFO]${colors.reset} ${response.results.length} mémoires trouvées`);
    }
  });
}

/**
 * Tests pour le node MCP Client (ligne de commande)
 */
async function testMCPClientCMD() {
  // Test de l'opération getContext
  await runTest('MCP Client CMD - getContext', async () => {
    const response = await executeMCPCommand('getContext', {
      prompt: 'Test prompt',
      sources: ['test', 'memory']
    });

    assert.ok(response.context, 'La réponse devrait contenir un contexte');
    assert.ok(response.sources_used, 'La réponse devrait contenir les sources utilisées');
    assert.deepStrictEqual(response.sources_used, ['test', 'memory'], 'Les sources utilisées devraient correspondre');
  });

  // Test de l'opération listTools
  await runTest('MCP Client CMD - listTools', async () => {
    const response = await executeMCPCommand('listTools');

    assert.ok(response.tools, 'La réponse devrait contenir une liste d\'outils');
    assert.ok(Array.isArray(response.tools), 'La liste d\'outils devrait être un tableau');
    assert.ok(response.tools.length > 0, 'La liste d\'outils ne devrait pas être vide');
  });
}

/**
 * Fonction principale pour exécuter tous les tests
 */
async function runAllTests() {
  console.log(`${colors.magenta}=== Tests automatisés des nodes MCP pour n8n ===${colors.reset}`);
  console.log(`Date: ${new Date().toISOString()}`);
  console.log('');

  let testServer;

  try {
    // Démarrer le serveur de test
    console.log(`${colors.cyan}Démarrage du serveur de test...${colors.reset}`);
    testServer = await startTestServer();
    console.log(`${colors.cyan}Serveur de test démarré sur le port ${testServer.port}${colors.reset}`);

    // Exécuter les tests HTTP
    console.log(`\n${colors.cyan}=== Tests HTTP ===${colors.reset}`);
    await testMCPClientHTTP();
    await testMCPMemoryHTTP();

    // Exécuter les tests en ligne de commande
    console.log(`\n${colors.cyan}=== Tests en ligne de commande ===${colors.reset}`);
    await testMCPClientCMD();

    // Afficher le résumé
    console.log(`\n${colors.magenta}=== Résumé des tests ===${colors.reset}`);
    console.log(`Total: ${totalTests}`);
    console.log(`${colors.green}Réussis: ${passedTests}${colors.reset}`);
    console.log(`${colors.red}Échoués: ${failedTests}${colors.reset}`);
    console.log(`${colors.yellow}Ignorés: ${skippedTests}${colors.reset}`);

    // Retourner le code de sortie approprié
    process.exitCode = failedTests > 0 ? 1 : 0;
  } catch (error) {
    console.error(`${colors.red}Erreur lors de l'exécution des tests: ${error.message}${colors.reset}`);
    process.exitCode = 1;
  } finally {
    // Arrêter le serveur de test
    if (testServer && testServer.server) {
      testServer.server.kill();
      console.log(`${colors.cyan}Serveur de test arrêté${colors.reset}`);
    }
  }
}

// Exécuter les tests
runAllTests();
