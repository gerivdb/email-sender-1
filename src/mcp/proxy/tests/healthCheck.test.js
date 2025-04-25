/**
 * Tests pour le module de vérification de santé
 */

const axios = require('axios');

// Mock d'axios
jest.mock('axios');

// Mock du module de configuration
jest.mock('../src/utils/config', () => ({
  proxy: {
    targets: {
      test_system: {
        url: 'http://localhost:3001',
        healthEndpoint: '/health'
      },
      other_system: {
        url: 'http://localhost:3002'
      }
    },
    standardEndpoints: {
      health: '/health'
    },
    healthCheckInterval: 5000
  }
}));

// Mock du module de journalisation
jest.mock('../src/utils/logger', () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
  debug: jest.fn()
}));

describe('Health Check Module', () => {
  beforeEach(() => {
    // Réinitialiser les mocks
    jest.clearAllMocks();
  });
  
  test('should return true when system is healthy', async () => {
    // Configurer le mock d'axios pour retourner une réponse réussie
    axios.get.mockResolvedValueOnce({
      status: 200,
      data: { status: 'healthy' }
    });
    
    const { checkSystemHealth } = require('../src/utils/healthCheck');
    
    const isHealthy = await checkSystemHealth('test_system');
    
    expect(isHealthy).toBe(true);
    expect(axios.get).toHaveBeenCalledWith('http://localhost:3001/health', { timeout: 5000 });
  });
  
  test('should return false when system is unhealthy', async () => {
    // Configurer le mock d'axios pour retourner une réponse non réussie
    axios.get.mockResolvedValueOnce({
      status: 500,
      data: { status: 'unhealthy' }
    });
    
    const { checkSystemHealth } = require('../src/utils/healthCheck');
    
    const isHealthy = await checkSystemHealth('test_system');
    
    expect(isHealthy).toBe(false);
    expect(axios.get).toHaveBeenCalledWith('http://localhost:3001/health', { timeout: 5000 });
  });
  
  test('should return false when request fails', async () => {
    // Configurer le mock d'axios pour rejeter la promesse
    axios.get.mockRejectedValueOnce(new Error('Connection refused'));
    
    const { checkSystemHealth } = require('../src/utils/healthCheck');
    
    const isHealthy = await checkSystemHealth('test_system');
    
    expect(isHealthy).toBe(false);
    expect(axios.get).toHaveBeenCalledWith('http://localhost:3001/health', { timeout: 5000 });
  });
  
  test('should use standard health endpoint when not specified', async () => {
    // Configurer le mock d'axios pour retourner une réponse réussie
    axios.get.mockResolvedValueOnce({
      status: 200,
      data: { status: 'healthy' }
    });
    
    const { checkSystemHealth } = require('../src/utils/healthCheck');
    
    const isHealthy = await checkSystemHealth('other_system');
    
    expect(isHealthy).toBe(true);
    expect(axios.get).toHaveBeenCalledWith('http://localhost:3002/health', { timeout: 5000 });
  });
  
  test('should return false for invalid system', async () => {
    const { checkSystemHealth } = require('../src/utils/healthCheck');
    
    const isHealthy = await checkSystemHealth('invalid_system');
    
    expect(isHealthy).toBe(false);
    expect(axios.get).not.toHaveBeenCalled();
  });
  
  test('should check all systems', async () => {
    // Configurer le mock d'axios pour retourner des réponses différentes
    axios.get.mockResolvedValueOnce({
      status: 200,
      data: { status: 'healthy' }
    }).mockResolvedValueOnce({
      status: 500,
      data: { status: 'unhealthy' }
    });
    
    const { checkAllSystemsHealth } = require('../src/utils/healthCheck');
    
    const results = await checkAllSystemsHealth();
    
    expect(results).toEqual({
      test_system: true,
      other_system: false
    });
    expect(axios.get).toHaveBeenCalledTimes(2);
  });
});
