const axios = require('axios');
const WebSocket = require('ws');

// Configuration
const PROXY_URL = 'http://localhost:4000';
const WS_URL = 'ws://localhost:4000';

async function testProxy() {
  // Tester la connexion WebSocket
  const ws = new WebSocket(WS_URL);

  ws.on('open', () => {
    console.log('WebSocket connected');
  });

  ws.on('message', (data) => {
    console.log('WebSocket message:', data.toString());
  });

  ws.on('error', (err) => {
    console.error('WebSocket error:', err);
  });

  // Tester la bascule de service
  try {
    console.log('\nTesting service switch to augment...');
    const switchRes = await axios.post(`${PROXY_URL}/switch`, {
      service: 'augment'
    });
    console.log('Switch response:', switchRes.data);

    // Tester le nouveau service actif
    const statusRes1 = await axios.get(`${PROXY_URL}/status`);
    console.log('Current service:', statusRes1.data.activeService);
  } catch (error) {
    console.error('Switch test failed:', error.response?.data || error.message);
  }

  // Tester une requête proxy
  try {
    console.log('\nTesting proxy health check...');
    const proxyRes = await axios.get(`${PROXY_URL}/proxy/api/health`);
    console.log('Proxy health check:', proxyRes.data);
  } catch (error) {
    console.error('Proxy test failed:', error.response?.data || error.message);
  }

  // Tester le endpoint status
  try {
    console.log('\nTesting status endpoint...');
    const statusRes = await axios.get(`${PROXY_URL}/status`);
    console.log('Service status:', {
      active: statusRes.data.activeService,
      services: Object.keys(statusRes.data.services)
    });
  } catch (error) {
    console.error('Status test failed:', error.response?.data || error.message);
  }

  // Fermer WebSocket après 5 secondes
  setTimeout(() => {
    ws.close();
    console.log('\nTests completed');
    process.exit(0);
  }, 5000);
}

testProxy().catch(err => {
  console.error('Test error:', err);
  process.exit(1);
});
