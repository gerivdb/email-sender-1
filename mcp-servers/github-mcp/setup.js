const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Fonction principale
async function setupGithubMcp() {
  try {
    console.log('Configuration du serveur MCP GitHub...');
    
    // Vérifier si le package @modelcontextprotocol/server-github est installé
    try {
      require('@modelcontextprotocol/server-github');
      console.log('Le package @modelcontextprotocol/server-github est déjà installé.');
    } catch (error) {
      console.log('Installation du package @modelcontextprotocol/server-github...');
      execSync('npm install -g @modelcontextprotocol/server-github', { stdio: 'inherit' });
      console.log('Package installé avec succès.');
    }
    
    // Créer le fichier de configuration
    const configPath = path.join(__dirname, 'config.json');
    
    // Vérifier si le fichier de configuration existe déjà
    if (fs.existsSync(configPath)) {
      console.log('Le fichier de configuration existe déjà.');
      const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      console.log('Configuration actuelle:');
      console.log(`- Dépôt: ${config.owner}/${config.repo}`);
      console.log(`- Token: ${config.token ? '********' : 'Non défini'}`);
    } else {
      console.log('Création du fichier de configuration...');
      
      // Demander les informations de configuration
      console.log('Veuillez fournir les informations suivantes:');
      console.log('1. Propriétaire du dépôt (owner): gerivonderbitsh');
      console.log('2. Nom du dépôt (repo): EMAIL_SENDER_1');
      console.log('3. Token GitHub: (à définir manuellement dans le fichier config.json)');
      
      // Créer le fichier de configuration
      const config = {
        owner: 'gerivonderbitsh',
        repo: 'EMAIL_SENDER_1',
        token: 'VOTRE_TOKEN_GITHUB'
      };
      
      fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
      console.log('Fichier de configuration créé avec succès.');
      console.log('Veuillez modifier le fichier config.json pour définir votre token GitHub.');
    }
    
    // Créer le script de démarrage
    const startScriptPath = path.join(__dirname, 'start.cmd');
    
    if (!fs.existsSync(startScriptPath)) {
      console.log('Création du script de démarrage...');
      
      const startScript = `@echo off
echo Démarrage du serveur MCP GitHub...
echo.
echo Ce script va démarrer le serveur MCP GitHub pour interagir avec votre dépôt GitHub.
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

:: Démarrer le serveur
mcp-server-github --config "%~dp0config.json"

echo.
echo Serveur arrêté.
echo.
pause`;
      
      fs.writeFileSync(startScriptPath, startScript);
      console.log('Script de démarrage créé avec succès.');
    } else {
      console.log('Le script de démarrage existe déjà.');
    }
    
    // Créer le script de vérification
    const checkScriptPath = path.join(__dirname, 'check-config.js');
    
    if (!fs.existsSync(checkScriptPath)) {
      console.log('Création du script de vérification...');
      
      const checkScript = `const fs = require('fs');
const path = require('path');

// Fonction principale
async function checkConfig() {
  try {
    console.log('Vérification de la configuration du serveur MCP GitHub...');
    
    // Vérifier si le fichier de configuration existe
    const configPath = path.join(__dirname, 'config.json');
    
    if (!fs.existsSync(configPath)) {
      console.log('Le fichier de configuration n\\'existe pas.');
      console.log('Veuillez exécuter le script setup.js pour créer le fichier de configuration.');
      return;
    }
    
    // Lire le fichier de configuration
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    
    console.log('Configuration:');
    console.log(\`- Dépôt: \${config.owner}/\${config.repo}\`);
    console.log(\`- Token: \${config.token ? (config.token === 'VOTRE_TOKEN_GITHUB' ? 'Non défini' : '********') : 'Non défini'}\`);
    
    if (config.token === 'VOTRE_TOKEN_GITHUB') {
      console.log('\\nVeuillez modifier le fichier config.json pour définir votre token GitHub.');
    } else if (config.token) {
      console.log('\\nLa configuration semble correcte.');
      console.log('Vous pouvez démarrer le serveur MCP GitHub en exécutant le script start.cmd.');
    } else {
      console.log('\\nVeuillez modifier le fichier config.json pour définir votre token GitHub.');
    }
  } catch (error) {
    console.error('Erreur lors de la vérification de la configuration:', error.message);
  }
}

// Exécuter la fonction principale
checkConfig();`;
      
      fs.writeFileSync(checkScriptPath, checkScript);
      console.log('Script de vérification créé avec succès.');
    } else {
      console.log('Le script de vérification existe déjà.');
    }
    
    console.log('\nConfiguration terminée.');
    console.log('Veuillez suivre ces étapes:');
    console.log('1. Modifiez le fichier config.json pour définir votre token GitHub');
    console.log('2. Exécutez le script check-config.js pour vérifier la configuration');
    console.log('3. Exécutez le script start.cmd pour démarrer le serveur MCP GitHub');
    
    return {
      success: true
    };
  } catch (error) {
    console.error('Erreur lors de la configuration du serveur MCP GitHub:', error.message);
    
    return {
      success: false,
      error: error.message
    };
  }
}

// Exécuter la fonction principale
setupGithubMcp();
