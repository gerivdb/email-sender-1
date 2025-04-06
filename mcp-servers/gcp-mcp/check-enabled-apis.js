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
async function checkEnabledApis() {
  try {
    console.log('Vérification des API activées dans votre projet GCP...');
    
    // Définir le projet
    const projectId = 'gen-lang-client-0391388747';
    
    // Initialiser l'API Service Management
    const serviceManagement = google.servicemanagement({
      version: 'v1',
      auth: auth
    });
    
    // Lister les services activés
    const response = await serviceManagement.services.list({
      consumerId: `project:${projectId}`
    });
    
    console.log('API activées dans votre projet :');
    if (response.data.services && response.data.services.length > 0) {
      response.data.services.forEach(service => {
        console.log(`- ${service.serviceName}`);
      });
    } else {
      console.log('Aucune API activée trouvée.');
    }
    
    // Vérifier spécifiquement les API nécessaires
    const requiredApis = [
      'iam.googleapis.com',
      'gmail.googleapis.com'
    ];
    
    console.log('\nVérification des API requises :');
    requiredApis.forEach(api => {
      const isEnabled = response.data.services && 
                        response.data.services.some(service => service.serviceName === api);
      console.log(`- ${api}: ${isEnabled ? 'Activée' : 'Non activée'}`);
    });
    
    console.log('\nPour activer les API manquantes :');
    console.log('1. Visitez https://console.cloud.google.com/apis/library?project=gen-lang-client-0391388747');
    console.log('2. Recherchez l\'API que vous souhaitez activer');
    console.log('3. Cliquez sur l\'API puis sur le bouton "Activer"');
    console.log('4. Attendez quelques minutes pour que l\'activation se propage');
    
    return {
      success: true,
      services: response.data.services || []
    };
  } catch (error) {
    console.error('Erreur lors de la vérification des API :', error.message);
    if (error.response) {
      console.error('Détails de l\'erreur:', error.response.data);
    }
    
    console.log('\nSi vous rencontrez des erreurs d\'autorisation, vous devrez peut-être :');
    console.log('1. Vérifier que votre compte a les permissions nécessaires');
    console.log('2. Réauthentifier en exécutant setup-auth.cmd');
    console.log('3. Activer l\'API Service Management en visitant :');
    console.log('   https://console.cloud.google.com/apis/library/servicemanagement.googleapis.com?project=gen-lang-client-0391388747');
    
    return {
      success: false,
      error: error.message
    };
  }
}

// Exécuter la fonction principale
checkEnabledApis();
