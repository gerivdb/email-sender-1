/**
 * Serveur principal du proxy MCP unifié
 * Gère le routage des requêtes entre les systèmes Augment et Cline
 */

const express = require('express');
const http = require('http');
const cors = require('cors');
const morgan = require('morgan');
const fs = require('fs-extra');
const path = require('path');
const { createProxyMiddleware } = require('http-proxy-middleware');
const socketIo = require('socket.io');
const session = require('express-session');
const bodyParser = require('body-parser');

// Modules internes
const logger = require('./utils/logger');
const { getActiveSystem, setActiveSystem } = require('./utils/systemManager');
const { checkSystemHealth } = require('./utils/healthCheck');
const config = require('./utils/config');
const metrics = require('./utils/metrics');
const auth = require('./utils/auth');
const cache = require('./utils/cache');

// Initialisation de l'application Express
const app = express();
const server = http.createServer(app);
const io = socketIo(server);

// Middleware
app.use(cors());
app.use(express.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(morgan('combined', { stream: { write: message => logger.info(message.trim()) } }));

// Configuration de la session
if (config.auth?.enabled) {
  app.use(session({
    secret: config.auth.session.secret,
    resave: false,
    saveUninitialized: false,
    cookie: {
      secure: process.env.NODE_ENV === 'production',
      maxAge: config.auth.session.maxAge
    }
  }));
}

// Routes d'authentification
app.get('/login', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'login.html'));
});

app.post('/login', (req, res) => {
  const { username, password } = req.body;

  if (auth.verifyCredentials(username, password)) {
    // Authentification réussie
    req.session.user = username;
    req.session.role = auth.getUserRole(username);

    // Rediriger vers l'interface web
    res.redirect('/ui');
  } else {
    // Authentification échouée
    res.redirect('/login?error=1');
  }
});

app.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/login');
});

// Middleware d'authentification pour les routes protégées
app.use((req, res, next) => {
  // Vérifier si l'authentification est activée
  if (!config.auth?.enabled) {
    return next();
  }

  // Vérifier si le chemin est public
  if (config.auth.publicPaths && config.auth.publicPaths.some(path => req.path.startsWith(path))) {
    return next();
  }

  // Vérifier si la requête est une API avec un token
  if (req.path.startsWith('/api/')) {
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];

      if (token === config.auth.apiToken) {
        return next();
      }
    }

    return res.status(401).json({ error: 'Authentification requise' });
  }

  // Vérifier si l'utilisateur est authentifié pour l'interface web
  if (req.session?.user) {
    return next();
  }

  // Rediriger vers la page de connexion
  res.redirect('/login');
});

// Middleware pour vérifier et router vers le système actif
app.use(async (req, res, next) => {
  try {
    // Exclure les endpoints standardisés et l'interface web de la redirection
    if (req.path.startsWith('/api/proxy') ||
        req.path === config.proxy.standardEndpoints.health ||
        req.path === config.proxy.standardEndpoints.config ||
        req.path.startsWith('/ui')) {
      return next();
    }

    const activeSystem = await getActiveSystem();
    const targetConfig = config.proxy.targets[activeSystem];

    if (!targetConfig) {
      logger.error(`Système actif invalide: ${activeSystem}`);
      return res.status(500).json({ error: 'Configuration du système invalide' });
    }

    // Vérifier si la santé du système est dans le cache
    const healthCacheKey = `health_${activeSystem}`;
    let isHealthy = cache.get(healthCacheKey);

    // Si la santé n'est pas dans le cache, la vérifier
    if (isHealthy === undefined) {
      isHealthy = await checkSystemHealth(activeSystem);

      // Mettre en cache le résultat (TTL de 5 secondes)
      cache.set(healthCacheKey, isHealthy, 5);
    }

    if (!isHealthy) {
      logger.warn(`Le système actif ${activeSystem} n'est pas en bonne santé, tentative de basculement`);

      // Trouver un système alternatif en bonne santé
      const systems = Object.keys(config.proxy.targets)
        .filter(sys => sys !== activeSystem)
        .sort((a, b) => config.proxy.targets[a].priority - config.proxy.targets[b].priority);

      let fallbackSystem = null;
      for (const sys of systems) {
        if (await checkSystemHealth(sys)) {
          fallbackSystem = sys;
          break;
        }
      }

      if (fallbackSystem) {
        logger.info(`Basculement vers le système ${fallbackSystem}`);
        await setActiveSystem(fallbackSystem);

        // Enregistrer le basculement dans les métriques
        metrics.recordFailover(activeSystem, fallbackSystem, true, 'Système non disponible');
        metrics.recordActiveSystem(fallbackSystem);

        // Notifier les clients connectés du changement
        io.emit('system-change', { activeSystem: fallbackSystem });

        // Rediriger vers le nouveau système
        const proxy = createProxyMiddleware({
          target: config.proxy.targets[fallbackSystem].url,
          changeOrigin: true,
          logLevel: 'silent'
        });

        return proxy(req, res, next);
      } else {
        logger.error('Aucun système de secours disponible');
        return res.status(503).json({ error: 'Service indisponible' });
      }
    }

    // Proxy vers le système actif
    const startTime = Date.now();

    const proxy = createProxyMiddleware({
      target: targetConfig.url,
      changeOrigin: true,
      logLevel: 'silent',
      onProxyReq: (proxyReq, req, res) => {
        logger.debug(`Proxying request to ${activeSystem}: ${req.method} ${req.path}`);
      },
      onProxyRes: (proxyRes, req, res) => {
        // Calculer le temps de réponse
        const responseTime = Date.now() - startTime;

        // Enregistrer la requête dans les métriques
        const success = proxyRes.statusCode >= 200 && proxyRes.statusCode < 400;
        metrics.recordRequest(activeSystem, success, responseTime);
      },
      onError: (err, req, res) => {
        logger.error(`Proxy error: ${err.message}`);

        // Enregistrer l'erreur dans les métriques
        const responseTime = Date.now() - startTime;
        metrics.recordRequest(activeSystem, false, responseTime);

        res.status(500).json({ error: 'Erreur de proxy' });
      }
    });

    proxy(req, res, next);
  } catch (error) {
    logger.error(`Erreur dans le middleware de routage: ${error.message}`);
    res.status(500).json({ error: 'Erreur interne du serveur' });
  }
});

// Endpoints standardisés
app.get(config.proxy.standardEndpoints.health, async (req, res) => {
  try {
    // Vérifier si les données de santé sont dans le cache
    const cacheKey = 'health_all';
    let healthData = cache.get(cacheKey);

    if (!healthData) {
      const activeSystem = await getActiveSystem();
      const systemHealth = {};

      // Vérifier la santé de tous les systèmes
      for (const [system, systemConfig] of Object.entries(config.proxy.targets)) {
        const isHealthy = await checkSystemHealth(system);

        // Enregistrer la vérification de santé dans les métriques
        metrics.recordHealthCheck(system, isHealthy);

        // Mettre en cache le résultat individuel
        cache.set(`health_${system}`, isHealthy, 5);

        systemHealth[system] = {
          isActive: system === activeSystem,
          isHealthy,
          url: systemConfig.url,
          priority: systemConfig.priority
        };
      }

      const allHealthy = Object.values(systemHealth).some(sys => sys.isHealthy);

      healthData = {
        status: allHealthy ? 'healthy' : 'unhealthy',
        timestamp: new Date().toISOString(),
        activeSystem,
        systems: systemHealth
      };

      // Mettre en cache les données de santé (TTL de 5 secondes)
      cache.set(cacheKey, healthData, 5);
    }

    res.json(healthData);
  } catch (error) {
    logger.error(`Erreur lors de la vérification de santé: ${error.message}`);
    res.status(500).json({ error: 'Erreur lors de la vérification de santé' });
  }
});

app.get(config.proxy.standardEndpoints.config, (req, res) => {
  // Retourner une version sécurisée de la configuration (sans informations sensibles)
  const safeConfig = {
    server: {
      port: config.server.port,
      host: config.server.host
    },
    proxy: {
      targets: Object.keys(config.proxy.targets).reduce((acc, system) => {
        acc[system] = {
          url: config.proxy.targets[system].url,
          priority: config.proxy.targets[system].priority
        };
        return acc;
      }, {}),
      standardEndpoints: config.proxy.standardEndpoints
    }
  };

  res.json(safeConfig);
});

// API pour la gestion du proxy
app.get('/api/proxy/status', async (req, res) => {
  try {
    const activeSystem = await getActiveSystem();
    res.json({ activeSystem });
  } catch (error) {
    logger.error(`Erreur lors de la récupération du statut: ${error.message}`);
    res.status(500).json({ error: 'Erreur lors de la récupération du statut' });
  }
});

app.post('/api/proxy/switch', async (req, res) => {
  try {
    const { system } = req.body;

    if (!system || !config.proxy.targets[system]) {
      return res.status(400).json({ error: 'Système invalide' });
    }

    // Vérifier la santé du système cible
    const isHealthy = await checkSystemHealth(system);
    if (!isHealthy) {
      return res.status(400).json({ error: `Le système ${system} n'est pas en bonne santé` });
    }

    // Récupérer l'ancien système actif
    const oldSystem = await getActiveSystem();

    await setActiveSystem(system);

    // Enregistrer le basculement dans les métriques
    metrics.recordFailover(oldSystem, system, false, 'Basculement manuel');
    metrics.recordActiveSystem(system);

    // Notifier les clients connectés du changement
    io.emit('system-change', { activeSystem: system });

    res.json({ success: true, activeSystem: system });
  } catch (error) {
    logger.error(`Erreur lors du changement de système: ${error.message}`);
    res.status(500).json({ error: 'Erreur lors du changement de système' });
  }
});

// Endpoint pour les métriques
app.get('/api/proxy/metrics', (req, res) => {
  try {
    // Vérifier si les métriques sont dans le cache
    const cacheKey = 'metrics';
    let metricsData = cache.get(cacheKey);

    if (!metricsData) {
      // Récupérer les métriques
      metricsData = metrics.getMetrics();

      // Ajouter les métriques du cache
      metricsData.cache = cache.getStats();

      // Mettre en cache les métriques (TTL court de 5 secondes)
      cache.set(cacheKey, metricsData, 5);
    }

    res.json(metricsData);
  } catch (error) {
    logger.error(`Erreur lors de la récupération des métriques: ${error.message}`);
    res.status(500).json({ error: 'Erreur lors de la récupération des métriques' });
  }
});

// Endpoint pour la gestion du cache
app.get('/api/proxy/cache', (req, res) => {
  try {
    // Vérifier si l'utilisateur est un administrateur
    if (config.auth?.enabled && req.session?.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    const stats = cache.getStats();
    res.json(stats);
  } catch (error) {
    logger.error(`Erreur lors de la récupération des statistiques du cache: ${error.message}`);
    res.status(500).json({ error: 'Erreur lors de la récupération des statistiques du cache' });
  }
});

app.get('/api/proxy/cache/entries', (req, res) => {
  try {
    // Vérifier si l'utilisateur est un administrateur
    if (config.auth?.enabled && req.session?.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    const entries = cache.getEntries();
    res.json(entries);
  } catch (error) {
    logger.error(`Erreur lors de la récupération des entrées du cache: ${error.message}`);
    res.status(500).json({ error: 'Erreur lors de la récupération des entrées du cache' });
  }
});

app.delete('/api/proxy/cache', (req, res) => {
  try {
    // Vérifier si l'utilisateur est un administrateur
    if (config.auth?.enabled && req.session?.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    const success = cache.clear();
    res.json({ success });
  } catch (error) {
    logger.error(`Erreur lors de la suppression du cache: ${error.message}`);
    res.status(500).json({ error: 'Erreur lors de la suppression du cache' });
  }
});

app.delete('/api/proxy/cache/:key', (req, res) => {
  try {
    // Vérifier si l'utilisateur est un administrateur
    if (config.auth?.enabled && req.session?.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    const { key } = req.params;
    const success = cache.del(key);
    res.json({ success });
  } catch (error) {
    logger.error(`Erreur lors de la suppression de l'entrée du cache: ${error.message}`);
    res.status(500).json({ error: 'Erreur lors de la suppression de l\'entrée du cache' });
  }
});

// API pour la gestion des utilisateurs (réservée aux administrateurs)
app.get('/api/proxy/users', (req, res) => {
  // Vérifier si l'utilisateur est un administrateur
  if (config.auth?.enabled && req.session?.role !== 'admin') {
    return res.status(403).json({ error: 'Accès refusé' });
  }

  const users = auth.listUsers();
  res.json(users);
});

app.post('/api/proxy/users', (req, res) => {
  // Vérifier si l'utilisateur est un administrateur
  if (config.auth?.enabled && req.session?.role !== 'admin') {
    return res.status(403).json({ error: 'Accès refusé' });
  }

  const { username, password, role } = req.body;

  if (!username || !password || !role) {
    return res.status(400).json({ error: 'Paramètres manquants' });
  }

  auth.addUser(username, password, role)
    .then(success => {
      if (success) {
        res.json({ success: true, message: `Utilisateur ${username} ajouté` });
      } else {
        res.status(400).json({ error: `L'utilisateur ${username} existe déjà` });
      }
    })
    .catch(error => {
      res.status(500).json({ error: error.message });
    });
});

app.delete('/api/proxy/users/:username', (req, res) => {
  // Vérifier si l'utilisateur est un administrateur
  if (config.auth?.enabled && req.session?.role !== 'admin') {
    return res.status(403).json({ error: 'Accès refusé' });
  }

  const { username } = req.params;

  auth.removeUser(username)
    .then(success => {
      if (success) {
        res.json({ success: true, message: `Utilisateur ${username} supprimé` });
      } else {
        res.status(404).json({ error: `L'utilisateur ${username} n'existe pas` });
      }
    })
    .catch(error => {
      res.status(500).json({ error: error.message });
    });
});

app.put('/api/proxy/users/:username/password', (req, res) => {
  // Vérifier si l'utilisateur est un administrateur ou l'utilisateur lui-même
  if (config.auth?.enabled && req.session?.role !== 'admin' && req.session?.user !== req.params.username) {
    return res.status(403).json({ error: 'Accès refusé' });
  }

  const { username } = req.params;
  const { password } = req.body;

  if (!password) {
    return res.status(400).json({ error: 'Paramètre manquant' });
  }

  auth.changePassword(username, password)
    .then(success => {
      if (success) {
        res.json({ success: true, message: `Mot de passe de l'utilisateur ${username} changé` });
      } else {
        res.status(404).json({ error: `L'utilisateur ${username} n'existe pas` });
      }
    })
    .catch(error => {
      res.status(500).json({ error: error.message });
    });
});

// Interface web simple
app.use('/ui', express.static(path.join(__dirname, 'public')));

// Gestion des WebSockets
io.on('connection', (socket) => {
  logger.info(`Nouvelle connexion WebSocket: ${socket.id}`);

  socket.on('disconnect', () => {
    logger.info(`Déconnexion WebSocket: ${socket.id}`);
  });
});

// Démarrage du serveur
server.listen(config.server.port, config.server.host, async () => {
  logger.info(`Proxy MCP unifié démarré sur http://${config.server.host}:${config.server.port}`);

  // Initialiser les métriques avec le système actif
  const activeSystem = await getActiveSystem();
  metrics.recordActiveSystem(activeSystem);
});

// Gestion des erreurs non capturées
process.on('uncaughtException', (error) => {
  logger.error(`Exception non capturée: ${error.message}`, { stack: error.stack });
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error(`Promesse rejetée non gérée: ${reason}`, { promise });
});

module.exports = { app, server };
