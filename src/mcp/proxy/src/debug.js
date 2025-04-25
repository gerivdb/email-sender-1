/**
 * Script de débogage pour le proxy MCP unifié
 */

const express = require('express');
const app = express();

// Route de base
app.get('/', (req, res) => {
  res.send('Proxy MCP unifié - Mode débogage');
});

// Route de santé
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    message: 'Proxy MCP unifié en mode débogage'
  });
});

// Démarrage du serveur
const port = 4000;
app.listen(port, () => {
  console.log(`Serveur de débogage démarré sur le port ${port}`);
});
