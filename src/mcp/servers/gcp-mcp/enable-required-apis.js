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
async function enableRequiredApis() {
  try {
    console.log('Activation des API requises dans votre projet GCP...');
    
    // Définir le projet
    const projectId = 'gen-lang-client-0391388747';
    
    // Initialiser l'API Service Usage
    const serviceUsage = google.serviceusage({
      version: 'v1',
      auth: auth
    });
    
    // Liste des API requises
    const requiredApis = [
      'iam.googleapis.com',
      'gmail.googleapis.com',
      'servicemanagement.googleapis.com',
      'serviceusage.googleapis.com'
    ];
    
    console.log('Tentative d\'activation des API suivantes :');
    for (const api of requiredApis) {
      console.log(`- ${api}`);
      try {
        const response = await serviceUsage.services.enable({
          name: `projects/${projectId}/services/${api}`
        });
        
        console.log(`  Statut : ${response.data.name}`);
        console.log(`  Opération lancée. L'activation peut prendre quelques minutes.`);
      } catch (apiError) {
        console.error(`  Erreur lors de l'activation de ${api} :`, apiError.message);
        if (apiError.response) {
          console.error(`  Détails :`, apiError.response.data);
        }
        
        console.log(`  Veuillez activer cette API manuellement via la console Google Cloud :`);
        console.log(`  https://console.cloud.google.com/apis/library/${api}?project=${projectId}`);
      }
    }
    
    console.log('\nImportant :');
    console.log('1. L\'activation des API peut prendre quelques minutes');
    console.log('2. Si des erreurs se produisent, activez les API manuellement via la console Google Cloud');
    console.log('3. URL de la bibliothèque d\'API : https://console.cloud.google.com/apis/library?project=gen-lang-client-0391388747');
    
    return {
      success: true
    };
  } catch (error) {
    console.error('Erreur lors de l\'activation des API :', error.message);
    if (error.response) {
      console.error('Détails de l\'erreur:', error.response.data);
    }
    
    console.log('\nSi vous rencontrez des erreurs d\'autorisation, vous devrez peut-être :');
    console.log('1. Vérifier que votre compte a les permissions nécessaires');
    console.log('2. Réauthentifier en exécutant setup-auth.cmd');
    console.log('3. Activer les API manuellement via la console Google Cloud :');
    console.log('   https://console.cloud.google.com/apis/library?project=gen-lang-client-0391388747');
    
    return {
      success: false,
      error: error.message
    };
  }
}

// Exécuter la fonction principale
enableRequiredApis();
