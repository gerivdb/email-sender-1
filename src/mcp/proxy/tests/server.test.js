/**
 * Tests pour le serveur principal
 */

const request = require('supertest');
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');

// Mock des modules
jest.mock('http-proxy-middleware');
jest.mock('../src/utils/systemManager');
jest.mock('../src/utils/healthCheck');
jest.mock('../src/utils/logger');

// Mock du module de configuration
jest.mock('../src/utils/config', () => ({
  server: {
    port: 4001,
    host: 'localhost'
  },
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
    },
    standardEndpoints: {
      health: '/health',
      config: '/config'
    }
  }
}));

describe('Server Module', () => {
  let app;
  let server;
  
  beforeEach(() => {
    // Réinitialiser les mocks
    jest.clearAllMocks();
    
    // Mock de createProxyMiddleware
    createProxyMiddleware.mockImplementation(() => {
      return (req, res, next) => {
        res.status(200).json({ proxied: true });
      };
    });
    
    // Mock de getActiveSystem
    const systemManager = require('../src/utils/systemManager');
    systemManager.getActiveSystem.mockResolvedValue('test_system');
    
    // Mock de checkSystemHealth
    const healthCheck = require('../src/utils/healthCheck');
    healthCheck.checkSystemHealth.mockResolvedValue(true);
    healthCheck.checkAllSystemsHealth.mockResolvedValue({
      test_system: true,
      other_system: true
    });
    
    // Charger le serveur
    const serverModule = require('../src/server');
    app = serverModule.app;
    server = serverModule.server;
  });
  
  afterEach(() => {
    // Fermer le serveur après chaque test
    if (server && server.close) {
      server.close();
    }
  });
  
  test('should respond to health endpoint', async () => {
    const response = await request(app).get('/health');
    
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('status', 'healthy');
    expect(response.body).toHaveProperty('activeSystem', 'test_system');
    expect(response.body).toHaveProperty('systems');
    expect(response.body.systems).toHaveProperty('test_system');
    expect(response.body.systems).toHaveProperty('other_system');
  });
  
  test('should respond to config endpoint', async () => {
    const response = await request(app).get('/config');
    
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('server');
    expect(response.body).toHaveProperty('proxy');
    expect(response.body.proxy).toHaveProperty('targets');
    expect(response.body.proxy.targets).toHaveProperty('test_system');
    expect(response.body.proxy.targets).toHaveProperty('other_system');
  });
  
  test('should respond to status endpoint', async () => {
    const response = await request(app).get('/api/proxy/status');
    
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('activeSystem', 'test_system');
  });
  
  test('should switch system', async () => {
    const systemManager = require('../src/utils/systemManager');
    
    const response = await request(app)
      .post('/api/proxy/switch')
      .send({ system: 'other_system' });
    
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('success', true);
    expect(response.body).toHaveProperty('activeSystem', 'other_system');
    expect(systemManager.setActiveSystem).toHaveBeenCalledWith('other_system');
  });
  
  test('should reject invalid system', async () => {
    const response = await request(app)
      .post('/api/proxy/switch')
      .send({ system: 'invalid_system' });
    
    expect(response.status).toBe(400);
    expect(response.body).toHaveProperty('error');
  });
  
  test('should reject unhealthy system', async () => {
    const healthCheck = require('../src/utils/healthCheck');
    healthCheck.checkSystemHealth.mockResolvedValue(false);
    
    const response = await request(app)
      .post('/api/proxy/switch')
      .send({ system: 'other_system' });
    
    expect(response.status).toBe(400);
    expect(response.body).toHaveProperty('error');
  });
  
  test('should proxy requests to active system', async () => {
    const response = await request(app).get('/some-endpoint');
    
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('proxied', true);
    expect(createProxyMiddleware).toHaveBeenCalled();
  });
});
