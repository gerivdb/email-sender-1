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
async function checkGmailApi() {
  try {
    console.log('Vérification de l\'API Gmail...');
    
    // Définir le projet
    const projectId = 'gen-lang-client-0391388747';
    
    // Initialiser l'API Service Management
    const serviceManagement = google.servicemanagement({
      version: 'v1',
      auth: auth
    });
    
    // Vérifier si l'API Gmail est activée
    const response = await serviceManagement.services.list({
      consumerId: `project:${projectId}`
    });
    
    const gmailApiEnabled = response.data.services && 
                           response.data.services.some(service => service.serviceName === 'gmail.googleapis.com');
    
    console.log(`API Gmail : ${gmailApiEnabled ? 'Activée' : 'Non activée'}`);
    
    if (!gmailApiEnabled) {
      console.log('\nPour activer l\'API Gmail :');
      console.log('1. Visitez https://console.cloud.google.com/apis/library/gmail.googleapis.com?project=gen-lang-client-0391388747');
      console.log('2. Cliquez sur le bouton "Activer"');
      console.log('3. Attendez quelques minutes pour que l\'activation se propage');
    } else {
      console.log('\nL\'API Gmail est activée. Vous pouvez maintenant utiliser le compte de service pour envoyer des emails.');
      console.log('\nN\'oubliez pas de configurer l\'impersonification :');
      console.log('1. Allez sur la console Google Cloud: https://console.cloud.google.com/');
      console.log('2. Allez dans "IAM & Admin" > "Comptes de service"');
      console.log('3. Cliquez sur votre compte de service');
      console.log('4. Allez dans l\'onglet "Permissions"');
      console.log('5. Ajoutez l\'utilisateur gerivonderbitsh+dev@gmail.com avec le rôle "Utilisateur du compte de service"');
    }
    
    return {
      success: true,
      gmailApiEnabled
    };
  } catch (error) {
    console.error('Erreur lors de la vérification de l\'API Gmail :', error.message);
    if (error.response) {
      console.error('Détails de l\'erreur:', error.response.data);
    }
    
    return {
      success: false,
      error: error.message
    };
  }
}

// Exécuter la fonction principale
checkGmailApi();
