const express = require('express');
const axios = require('axios');
const path = require('path');
const fs = require('fs');
const WebSocket = require('ws');

// Charger la configuration
const configPath = path.join(__dirname, '../../mcp-servers/unified_proxy/config.json');
let config = JSON.parse(fs.readFileSync(configPath));

const app = express();
app.use(express.json());

// Serveur WebSocket pour les mises à jour en temps réel
const wss = new WebSocket.Server({ noServer: true });

// Vérifier l'état d'un service
async function checkServiceHealth(service) {
    try {
        const response = await axios.get(`${service.url}${service.healthCheck}`, {
            timeout: config.fallbackTimeout
        });
        return response.status === 200;
    } catch (e) {
        return false;
    }
}

// Mettre à jour le service actif
async function updateActiveService() {
    const currentActive = config.activeService;
    const currentService = config.services[currentActive];

    if (!(await checkServiceHealth(currentService))) {
        // Trouver un service de secours actif
        for (const [name, service] of Object.entries(config.services)) {
            if (name !== currentActive && await checkServiceHealth(service)) {
                config.activeService = name;
                fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
                broadcastUpdate();
                break;
            }
        }
    }
}

// Diffuser les mises à jour aux clients WebSocket
function broadcastUpdate() {
    wss.clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify({
                event: 'serviceChange',
                activeService: config.activeService
            }));
        }
    });
}

// Route principal
app.all('/proxy/*', async (req, res) => {
    const activeService = config.services[config.activeService];
    const targetPath = req.path.replace('/proxy', '');

    try {
        const response = await axios({
            method: req.method,
            url: `${activeService.url}${targetPath}`,
            data: req.body,
            headers: req.headers,
            timeout: config.fallbackTimeout
        });
        res.status(response.status).json(response.data);
    } catch (error) {
        res.status(500).json({
            error: 'Service unavailable',
            activeService: config.activeService
        });
    }
});

// Endpoint de gestion
app.post('/switch', async (req, res) => {
    const { service } = req.body;
    if (config.services[service]) {
        config.activeService = service;
        fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
        broadcastUpdate();
        res.json({ status: 'switched', activeService: service });
    } else {
        res.status(400).json({ error: 'Invalid service' });
    }
});

// Démarrer le serveur
const server = app.listen(config.port, () => {
    console.log(`Proxy MCP démarré sur le port ${config.port}`);
    setInterval(updateActiveService, 5000); // Vérifier toutes les 5 secondes
});

// Intégration WebSocket
server.on('upgrade', (request, socket, head) => {
    wss.handleUpgrade(request, socket, head, ws => {
        wss.emit('connection', ws, request);
    });
});

// Gestion des erreurs
process.on('unhandledRejection', error => {
    console.error('Unhandled rejection:', error);
});
