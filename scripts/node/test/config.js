module.exports = {
  proxyUrl: 'http://localhost:4000',
  services: {
    augment: {
      url: 'http://localhost:3000',
      healthCheck: '/api/health',
      testEndpoints: [
        '/api/query',
        '/api/process',
        '/api/validate'
      ]
    },
    cline: {
      url: 'http://localhost:5000',
      healthCheck: '/health',
      testEndpoints: [
        '/tools',
        '/resources',
        '/execute'
      ]
    }
  },
  testTimeout: 10000,
  logLevel: 'verbose',
  retryCount: 3,
  waitTime: 2000
};
