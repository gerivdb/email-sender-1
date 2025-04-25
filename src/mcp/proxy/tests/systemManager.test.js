/**
 * Tests pour le module de gestion du système actif
 */

const path = require('path');
const fs = require('fs-extra');
const os = require('os');

// Créer un fichier de lock temporaire pour les tests
const tempDir = os.tmpdir();
const testDir = path.join(tempDir, 'proxy_mcp_test_system');
const lockFilePath = path.join(testDir, 'active_system.lock');

// Mock du module de configuration
jest.mock('../src/utils/config', () => ({
  proxy: {
    defaultTarget: 'test_system',
    targets: {
      test_system: {
        url: 'http://localhost:3001',
        priority: 1
      },
      other_system: {
        url: 'http://localhost:3002',
        priority: 2
      }
    }
  },
  lockFile: lockFilePath
}));

// Mock du module de journalisation
jest.mock('../src/utils/logger', () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn()
}));

describe('System Manager Module', () => {
  beforeAll(() => {
    // Créer le répertoire de test
    fs.ensureDirSync(testDir);
  });
  
  afterAll(() => {
    // Nettoyer le répertoire temporaire
    fs.removeSync(testDir);
  });
  
  beforeEach(() => {
    // Supprimer le fichier de lock avant chaque test
    if (fs.existsSync(lockFilePath)) {
      fs.unlinkSync(lockFilePath);
    }
  });
  
  test('should return default system when lock file does not exist', async () => {
    const { getActiveSystem } = require('../src/utils/systemManager');
    
    const activeSystem = await getActiveSystem();
    
    expect(activeSystem).toBe('test_system');
    expect(fs.existsSync(lockFilePath)).toBe(true);
    expect(fs.readFileSync(lockFilePath, 'utf8')).toBe('test_system');
  });
  
  test('should return system from lock file when it exists', async () => {
    // Créer un fichier de lock avec un système
    fs.writeFileSync(lockFilePath, 'other_system', 'utf8');
    
    const { getActiveSystem } = require('../src/utils/systemManager');
    
    const activeSystem = await getActiveSystem();
    
    expect(activeSystem).toBe('other_system');
  });
  
  test('should return default system when lock file contains invalid system', async () => {
    // Créer un fichier de lock avec un système invalide
    fs.writeFileSync(lockFilePath, 'invalid_system', 'utf8');
    
    const { getActiveSystem } = require('../src/utils/systemManager');
    
    const activeSystem = await getActiveSystem();
    
    expect(activeSystem).toBe('test_system');
    expect(fs.readFileSync(lockFilePath, 'utf8')).toBe('test_system');
  });
  
  test('should set active system correctly', async () => {
    const { setActiveSystem } = require('../src/utils/systemManager');
    
    await setActiveSystem('other_system');
    
    expect(fs.existsSync(lockFilePath)).toBe(true);
    expect(fs.readFileSync(lockFilePath, 'utf8')).toBe('other_system');
  });
  
  test('should throw error when setting invalid system', async () => {
    const { setActiveSystem } = require('../src/utils/systemManager');
    
    await expect(setActiveSystem('invalid_system')).rejects.toThrow();
    
    // Vérifier que le fichier de lock n'a pas été modifié
    expect(fs.existsSync(lockFilePath)).toBe(false);
  });
});
