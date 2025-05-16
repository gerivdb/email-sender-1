/**
 * Script pour exécuter tous les tests des nodes MCP
 * 
 * Ce script exécute tous les tests et génère un rapport de test.
 */

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

// Configuration
const TEST_TIMEOUT = 60000; // 60 secondes par test
const REPORT_DIR = path.join(__dirname, 'reports');
const REPORT_FILE = path.join(REPORT_DIR, `test-report-${new Date().toISOString().replace(/:/g, '-')}.md`);

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

// Tests à exécuter
const tests = [
  {
    name: 'Tests automatisés des nodes MCP',
    script: path.join(__dirname, 'test-mcp-nodes.js'),
    description: 'Tests unitaires des nodes MCP Client et MCP Memory'
  },
  {
    name: 'Tests de scénarios',
    script: path.join(__dirname, 'test-scenarios.js'),
    description: 'Tests de scénarios d\'utilisation des nodes MCP'
  }
];

// Résultats des tests
const testResults = [];

/**
 * Fonction pour exécuter un script de test
 * @param {Object} test - Informations sur le test à exécuter
 * @returns {Promise<Object>} - Résultat du test
 */
async function runTest(test) {
  return new Promise((resolve, reject) => {
    console.log(`\n${colors.magenta}=== Exécution de: ${test.name} ===${colors.reset}`);
    console.log(`Script: ${test.script}`);
    console.log(`Description: ${test.description}`);
    console.log('');
    
    const startTime = Date.now();
    const testProcess = spawn('node', [test.script]);
    
    let output = '';
    let error = '';
    
    testProcess.stdout.on('data', (data) => {
      const dataStr = data.toString();
      output += dataStr;
      process.stdout.write(dataStr);
    });
    
    testProcess.stderr.on('data', (data) => {
      const dataStr = data.toString();
      error += dataStr;
      process.stderr.write(dataStr);
    });
    
    testProcess.on('close', (code) => {
      const endTime = Date.now();
      const duration = (endTime - startTime) / 1000;
      
      const result = {
        name: test.name,
        script: test.script,
        description: test.description,
        exitCode: code,
        output,
        error,
        duration,
        success: code === 0,
        timestamp: new Date().toISOString()
      };
      
      if (code === 0) {
        console.log(`\n${colors.green}✓ Test réussi en ${duration.toFixed(2)} secondes${colors.reset}`);
      } else {
        console.log(`\n${colors.red}✗ Test échoué avec le code ${code} en ${duration.toFixed(2)} secondes${colors.reset}`);
      }
      
      resolve(result);
    });
    
    testProcess.on('error', (err) => {
      reject(err);
    });
    
    // Timeout
    setTimeout(() => {
      testProcess.kill();
      reject(new Error(`Timeout lors de l'exécution du test: ${test.name}`));
    }, TEST_TIMEOUT);
  });
}

/**
 * Fonction pour générer un rapport de test
 * @param {Array<Object>} results - Résultats des tests
 */
function generateReport(results) {
  // Créer le répertoire de rapports s'il n'existe pas
  if (!fs.existsSync(REPORT_DIR)) {
    fs.mkdirSync(REPORT_DIR, { recursive: true });
  }
  
  // Calculer les statistiques
  const totalTests = results.length;
  const passedTests = results.filter(r => r.success).length;
  const failedTests = totalTests - passedTests;
  const successRate = (passedTests / totalTests) * 100;
  
  // Générer le contenu du rapport
  let report = `# Rapport de test des nodes MCP pour n8n\n\n`;
  report += `Date: ${new Date().toISOString()}\n\n`;
  
  report += `## Résumé\n\n`;
  report += `- **Total des tests**: ${totalTests}\n`;
  report += `- **Tests réussis**: ${passedTests}\n`;
  report += `- **Tests échoués**: ${failedTests}\n`;
  report += `- **Taux de réussite**: ${successRate.toFixed(2)}%\n\n`;
  
  report += `## Détails des tests\n\n`;
  
  results.forEach((result, index) => {
    report += `### ${index + 1}. ${result.name}\n\n`;
    report += `- **Script**: \`${result.script}\`\n`;
    report += `- **Description**: ${result.description}\n`;
    report += `- **Statut**: ${result.success ? '✅ Réussi' : '❌ Échoué'}\n`;
    report += `- **Code de sortie**: ${result.exitCode}\n`;
    report += `- **Durée**: ${result.duration.toFixed(2)} secondes\n`;
    report += `- **Horodatage**: ${result.timestamp}\n\n`;
    
    if (!result.success) {
      report += `#### Erreurs\n\n`;
      report += '```\n';
      report += result.error || 'Aucune erreur spécifique rapportée';
      report += '\n```\n\n';
    }
    
    report += `#### Sortie\n\n`;
    report += '```\n';
    report += result.output || 'Aucune sortie';
    report += '\n```\n\n';
  });
  
  // Écrire le rapport dans un fichier
  fs.writeFileSync(REPORT_FILE, report);
  
  console.log(`\n${colors.cyan}Rapport de test généré: ${REPORT_FILE}${colors.reset}`);
}

/**
 * Fonction principale pour exécuter tous les tests
 */
async function runAllTests() {
  console.log(`${colors.magenta}=== Exécution de tous les tests des nodes MCP ===${colors.reset}`);
  console.log(`Date: ${new Date().toISOString()}`);
  console.log(`Nombre de tests à exécuter: ${tests.length}`);
  console.log('');
  
  try {
    // Exécuter chaque test séquentiellement
    for (const test of tests) {
      try {
        const result = await runTest(test);
        testResults.push(result);
      } catch (error) {
        console.error(`${colors.red}Erreur lors de l'exécution du test ${test.name}: ${error.message}${colors.reset}`);
        testResults.push({
          name: test.name,
          script: test.script,
          description: test.description,
          exitCode: -1,
          output: '',
          error: error.message,
          duration: 0,
          success: false,
          timestamp: new Date().toISOString()
        });
      }
    }
    
    // Générer le rapport
    generateReport(testResults);
    
    // Afficher le résumé
    const passedTests = testResults.filter(r => r.success).length;
    const failedTests = testResults.length - passedTests;
    
    console.log(`\n${colors.magenta}=== Résumé des tests ===${colors.reset}`);
    console.log(`Total: ${testResults.length}`);
    console.log(`${colors.green}Réussis: ${passedTests}${colors.reset}`);
    console.log(`${colors.red}Échoués: ${failedTests}${colors.reset}`);
    
    // Retourner le code de sortie approprié
    process.exitCode = failedTests > 0 ? 1 : 0;
  } catch (error) {
    console.error(`${colors.red}Erreur lors de l'exécution des tests: ${error.message}${colors.reset}`);
    process.exitCode = 1;
  }
}

// Exécuter tous les tests
runAllTests();
