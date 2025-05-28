/**
 * Tests pour le module path-helper
 * Exécuter avec: node path-helper.test.js
 */
const assert = require('assert');
const path = require('path');
const os = require('os');
const pathHelper = require('../path-helper');

// Tests pour les fonctions principales
function runTests() {
  console.log('Exécution des tests pour path-helper.js...');
  
  // Test de normalizeName
  assert.strictEqual(pathHelper.normalizeName('Mon Titre Spécial!'), 'mon-titre-spcial', 'La normalisation du nom ne fonctionne pas correctement');
  assert.strictEqual(pathHelper.normalizeName('Test with spaces and UPPERCASE'), 'test-with-spaces-and-uppercase', 'La normalisation du nom ne fonctionne pas correctement');
  console.log('✅ Test de normalizeName réussi');
  
  // Test d'isAbsolutePath
  assert.strictEqual(pathHelper.isAbsolutePath('/usr/local/bin'), true, 'La détection de chemin absolu ne fonctionne pas pour les chemins Unix');
  assert.strictEqual(pathHelper.isAbsolutePath('C:\\Windows\\System32'), true, 'La détection de chemin absolu ne fonctionne pas pour les chemins Windows');
  assert.strictEqual(pathHelper.isAbsolutePath('relative/path'), false, 'La détection de chemin relatif ne fonctionne pas');
  console.log('✅ Test d\'isAbsolutePath réussi');
  
  // Test de convertFromWindowsPath
  const testWindowsPath = 'D:\\project\\file.txt';
  const converted = pathHelper.convertFromWindowsPath(testWindowsPath);
  if (os.platform() === 'win32') {
    assert.strictEqual(converted, 'D:/project/file.txt', 'La conversion de chemin Windows ne fonctionne pas sur Windows');
  } else {
    assert.strictEqual(converted, '/project/file.txt', 'La conversion de chemin Windows ne fonctionne pas sur Unix');
  }
  console.log('✅ Test de convertFromWindowsPath réussi');
  
  // Test de generatePlanDevPath
  const planPath = pathHelper.generatePlanDevPath('v2025-05', 'Test Plan');
  assert.ok(planPath.includes('plan-dev-v2025-05-test-plan.md'), 'La génération du chemin de plan ne fonctionne pas correctement');
  console.log('✅ Test de generatePlanDevPath réussi');
  
  console.log('\nTous les tests ont réussi! ✅');
}

// Exécution des tests
runTests();
