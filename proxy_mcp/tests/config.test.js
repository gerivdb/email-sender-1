/**
 * Tests pour le module de configuration
 */

const path = require('path');
const fs = require('fs-extra');
const os = require('os');

// Créer un fichier de configuration temporaire pour les tests
const tempDir = os.tmpdir();
const configDir = path.join(tempDir, 'proxy_mcp_test_config');
const configPath = path.join(configDir, 'default.json');

// Configuration de test
const testConfig = {
  server: {
    port: 4001,
    host: 'localhost'
  },
  proxy: {
    defaultTarget: 'test_system',
    targets: {
      test_system: {
        url: 'http://localhost:3001',
        priority: 1,
        healthEndpoint: '/health'
      }
    },
    standardEndpoints: {
      health: '/health',
      config: '/config'
    },
    failoverThreshold: 3,
    healthCheckInterval: 5000
  },
  logging: {
    level: 'error',
    format: 'combined',
    directory: '../logs'
  },
  lockFile: '../config/active_system.lock'
};

describe('Configuration Module', () => {
  beforeAll(() => {
    // Créer le répertoire de configuration temporaire
    fs.ensureDirSync(configDir);
    
    // Écrire la configuration de test
    fs.writeJsonSync(configPath, testConfig);
    
    // Modifier le chemin du module pour utiliser notre configuration de test
    jest.mock('../src/utils/config', () => {
      const originalModule = jest.requireActual('../src/utils/config');
      return {
        ...originalModule,
        configPath: configPath
      };
    });
  });
  
  afterAll(() => {
    // Nettoyer le répertoire temporaire
    fs.removeSync(configDir);
  });
  
  test('should load configuration correctly', () => {
    // Réinitialiser le cache des modules pour forcer le rechargement
    jest.resetModules();
    
    // Charger le module de configuration
    const config = require('../src/utils/config');
    
    // Vérifier que la configuration est chargée correctement
    expect(config).toBeDefined();
    expect(config.server.port).toBe(4001);
    expect(config.proxy.defaultTarget).toBe('test_system');
    expect(config.proxy.targets.test_system).toBeDefined();
    expect(config.proxy.targets.test_system.url).toBe('http://localhost:3001');
  });
  
  test('should resolve relative paths', () => {
    // Réinitialiser le cache des modules pour forcer le rechargement
    jest.resetModules();
    
    // Charger le module de configuration
    const config = require('../src/utils/config');
    
    // Vérifier que les chemins relatifs sont résolus
    expect(config.logging.directory).not.toContain('../');
    expect(config.lockFile).not.toContain('../');
  });
  
  test('should validate configuration', () => {
    // Créer une configuration invalide (sans serveur)
    const invalidConfig = { ...testConfig };
    delete invalidConfig.server;
    
    // Écrire la configuration invalide
    fs.writeJsonSync(configPath, invalidConfig);
    
    // Réinitialiser le cache des modules pour forcer le rechargement
    jest.resetModules();
    
    // Vérifier que le chargement de la configuration échoue
    expect(() => {
      require('../src/utils/config');
    }).toThrow();
  });
});
