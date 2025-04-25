#!/usr/bin/env node

/**
 * CLI pour la gestion du proxy MCP unifié
 * Permet de basculer entre les systèmes, vérifier l'état, etc.
 */

const yargs = require('yargs');
const axios = require('axios');
const fs = require('fs-extra');
const path = require('path');
const config = require('./utils/config');
const { getActiveSystem, setActiveSystem } = require('./utils/systemManager');
const { checkSystemHealth, checkAllSystemsHealth } = require('./utils/healthCheck');

// Configuration de l'URL de base du proxy
const PROXY_URL = `http://${config.server.host}:${config.server.port}`;

// Fonction pour afficher l'état actuel
const showStatus = async () => {
  try {
    // Récupérer le système actif
    const activeSystem = await getActiveSystem();
    console.log(`Système actif: ${activeSystem}`);
    
    // Vérifier la santé de tous les systèmes
    console.log('\nSanté des systèmes:');
    const healthResults = await checkAllSystemsHealth();
    
    for (const [system, isHealthy] of Object.entries(healthResults)) {
      const status = isHealthy ? 'En bonne santé' : 'Problème détecté';
      const isActive = system === activeSystem;
      const priority = config.proxy.targets[system].priority;
      
      console.log(`- ${system}${isActive ? ' (ACTIF)' : ''}:`);
      console.log(`  URL: ${config.proxy.targets[system].url}`);
      console.log(`  Priorité: ${priority}`);
      console.log(`  État: ${status}`);
      console.log('');
    }
  } catch (error) {
    console.error(`Erreur lors de l'affichage du statut: ${error.message}`);
    process.exit(1);
  }
};

// Fonction pour basculer vers un autre système
const switchSystem = async (system) => {
  try {
    // Vérifier si le système est valide
    if (!config.proxy.targets[system]) {
      console.error(`Système invalide: ${system}`);
      console.log(`Systèmes disponibles: ${Object.keys(config.proxy.targets).join(', ')}`);
      process.exit(1);
    }
    
    // Vérifier la santé du système cible
    const isHealthy = await checkSystemHealth(system);
    if (!isHealthy) {
      console.error(`Le système ${system} n'est pas en bonne santé. Voulez-vous continuer ? (y/N)`);
      
      // Attendre la réponse de l'utilisateur
      const readline = require('readline').createInterface({
        input: process.stdin,
        output: process.stdout
      });
      
      const answer = await new Promise(resolve => {
        readline.question('', resolve);
      });
      
      readline.close();
      
      if (answer.toLowerCase() !== 'y') {
        console.log('Opération annulée.');
        process.exit(0);
      }
    }
    
    // Récupérer le système actif
    const activeSystem = await getActiveSystem();
    if (system === activeSystem) {
      console.log(`Le système ${system} est déjà actif.`);
      process.exit(0);
    }
    
    // Basculer vers le nouveau système
    await setActiveSystem(system);
    console.log(`Basculement vers le système ${system} effectué avec succès.`);
    
    // Notifier le proxy si possible
    try {
      await axios.post(`${PROXY_URL}/api/proxy/switch`, { system });
    } catch (error) {
      console.warn(`Impossible de notifier le proxy: ${error.message}`);
      console.warn('Le changement a été effectué localement, mais le proxy devra être redémarré pour le prendre en compte.');
    }
  } catch (error) {
    console.error(`Erreur lors du basculement: ${error.message}`);
    process.exit(1);
  }
};

// Configuration des commandes
yargs
  .command('status', 'Affiche l\'état actuel du proxy', {}, showStatus)
  .command('switch <system>', 'Bascule vers un autre système', {
    system: {
      describe: 'Le système vers lequel basculer',
      type: 'string',
      demandOption: true
    }
  }, (argv) => switchSystem(argv.system))
  .command('list', 'Liste les systèmes disponibles', {}, () => {
    console.log('Systèmes disponibles:');
    for (const [system, config] of Object.entries(config.proxy.targets)) {
      console.log(`- ${system} (${config.url}, priorité: ${config.priority})`);
    }
  })
  .demandCommand(1, 'Vous devez spécifier une commande.')
  .help()
  .argv;
