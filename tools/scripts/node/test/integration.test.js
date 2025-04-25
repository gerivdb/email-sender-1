const { expect } = require('chai');
const axios = require('axios');
const { exec } = require('child_process');
const config = require('./config');

describe('Proxy MCP Integration Tests', function() {
  this.timeout(10000); // Augmenter le timeout pour les tests d'intégration

  let proxyProcess;

  before((done) => {
    // Démarrer le proxy
    proxyProcess = exec('node ../unified_proxy.js', (err) => {
      if (err) console.error('Proxy error:', err);
    });

    // Attendre que le proxy soit prêt
    setTimeout(done, 2000);
  });

  after(() => {
    // Arrêter le proxy
    proxyProcess.kill();
  });

  it('devrait basculer entre les services', async () => {
    const initialStatus = await axios.get(`${config.proxyUrl}/status`);
    const targetService = initialStatus.data.activeService === 'augment'
      ? 'cline'
      : 'augment';

    await axios.post(`${config.proxyUrl}/switch`, {
      service: targetService
    });

    const newStatus = await axios.get(`${config.proxyUrl}/status`);
    expect(newStatus.data.activeService).to.equal(targetService);
  });

  it('devrait router les requêtes', async () => {
    const res = await axios.get(
      `${config.proxyUrl}/proxy${config.services.augment.healthCheck}`
    );
    expect(res.status).to.equal(200);
  });

  it('devrait gérer les erreurs de service', async () => {
    try {
      await axios.get(`${config.proxyUrl}/proxy/invalid-endpoint`);
      throw new Error('Should have failed');
    } catch (err) {
      expect(err.response.status).to.equal(500);
    }
  });
});
