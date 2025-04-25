const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

// Chemin vers le fichier d'identifiants
const tokenPath = path.join(__dirname, 'token.json');

// Lire le fichier token.json
const token = JSON.parse(fs.readFileSync(tokenPath, 'utf8'));

// Créer un client OAuth2
const auth = new google.auth.OAuth2(
  token.client_id,
  token.client_secret
);

// Définir les informations d'authentification
auth.setCredentials({
  refresh_token: token.refresh_token
});

// Fonction principale
async function enableGmailApi() {
  try {
    console.log('Activation de l\'API Gmail...');
    
    // Définir le projet
    const projectId = 'gen-lang-client-0391388747';
    
    // Initialiser l'API Service Usage
    const serviceUsage = google.serviceusage({
      version: 'v1',
      auth: auth
    });
    
    // Activer l'API Gmail
    console.log('Tentative d\'activation de l\'API Gmail...');
    const response = await serviceUsage.services.enable({
      name: `projects/${projectId}/services/gmail.googleapis.com`
    });
    
    console.log('Opération lancée pour activer l\'API Gmail.');
    console.log('L\'activation peut prendre quelques minutes.');
    console.log('Vous pouvez vérifier l\'état de l\'activation en visitant:');
    console.log('https://console.cloud.google.com/apis/library/gmail.googleapis.com?project=gen-lang-client-0391388747');
    
    return {
      success: true,
      operation: response.data
    };
  } catch (error) {
    console.error('Erreur lors de l\'activation de l\'API Gmail:', error.message);
    if (error.response) {
      console.error('Détails de l\'erreur:', error.response.data);
    }
    
    console.log('\nSi vous rencontrez des erreurs, activez l\'API Gmail manuellement:');
    console.log('1. Visitez https://console.cloud.google.com/apis/library/gmail.googleapis.com?project=gen-lang-client-0391388747');
    console.log('2. Cliquez sur le bouton "Activer"');
    console.log('3. Attendez quelques minutes pour que l\'activation se propage');
    
    return {
      success: false,
      error: error.message
    };
  }
}

// Exécuter la fonction principale
enableGmailApi();
