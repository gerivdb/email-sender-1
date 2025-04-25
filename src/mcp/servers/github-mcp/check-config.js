const fs = require('fs');
const path = require('path');

// Fonction principale
async function checkConfig() {
  try {
    console.log('Vérification de la configuration du serveur MCP GitHub...');
    
    // Vérifier si le fichier de configuration existe
    const configPath = path.join(__dirname, 'config.json');
    
    if (!fs.existsSync(configPath)) {
      console.log('Le fichier de configuration n\'existe pas.');
      console.log('Veuillez exécuter le script setup.js pour créer le fichier de configuration.');
      return;
    }
    
    // Lire le fichier de configuration
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    
    console.log('Configuration:');
    console.log(`- Dépôt: ${config.owner}/${config.repo}`);
    console.log(`- Token: ${config.token ? (config.token === 'VOTRE_TOKEN_GITHUB' ? 'Non défini' : '********') : 'Non défini'}`);
    
    if (config.token === 'VOTRE_TOKEN_GITHUB') {
      console.log('\nVeuillez modifier le fichier config.json pour définir votre token GitHub.');
    } else if (config.token) {
      console.log('\nLa configuration semble correcte.');
      console.log('Vous pouvez démarrer le serveur MCP GitHub en exécutant le script start.cmd.');
    } else {
      console.log('\nVeuillez modifier le fichier config.json pour définir votre token GitHub.');
    }
  } catch (error) {
    console.error('Erreur lors de la vérification de la configuration:', error.message);
  }
}

// Exécuter la fonction principale
checkConfig();