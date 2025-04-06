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
async function createServiceAccount() {
  try {
    console.log('Création d\'un compte de service pour Gmail...');
    
    // Initialiser l'API IAM
    const iam = google.iam({
      version: 'v1',
      auth: auth
    });
    
    // Définir le projet
    const projectId = 'gen-lang-client-0391388747';
    
    // Créer un compte de service
    const serviceAccountName = 'github-actions-email';
    const serviceAccountDisplayName = 'GitHub Actions Email Service';
    
    console.log(`Création du compte de service ${serviceAccountName}...`);
    
    const createResponse = await iam.projects.serviceAccounts.create({
      name: `projects/${projectId}`,
      requestBody: {
        accountId: serviceAccountName,
        serviceAccount: {
          displayName: serviceAccountDisplayName,
          description: 'Compte de service pour envoyer des emails via GitHub Actions'
        }
      }
    });
    
    const serviceAccountEmail = createResponse.data.email;
    console.log(`Compte de service créé avec succès: ${serviceAccountEmail}`);
    
    // Créer une clé pour le compte de service
    console.log('Création d\'une clé pour le compte de service...');
    
    const keyResponse = await iam.projects.serviceAccounts.keys.create({
      name: `projects/${projectId}/serviceAccounts/${serviceAccountEmail}`,
      requestBody: {
        privateKeyType: 'TYPE_GOOGLE_CREDENTIALS_FILE',
        keyAlgorithm: 'KEY_ALG_RSA_2048'
      }
    });
    
    // Décoder la clé (elle est en base64)
    const privateKey = Buffer.from(keyResponse.data.privateKeyData, 'base64').toString('utf8');
    
    // Sauvegarder la clé dans un fichier
    const keyFilePath = path.join(__dirname, 'service-account-key.json');
    fs.writeFileSync(keyFilePath, privateKey);
    
    console.log(`Clé du compte de service sauvegardée dans: ${keyFilePath}`);
    
    // Accorder les permissions Gmail au compte de service
    console.log('Pour accorder les permissions Gmail au compte de service:');
    console.log('1. Allez sur la console Google Cloud: https://console.cloud.google.com/');
    console.log(`2. Sélectionnez le projet: ${projectId}`);
    console.log('3. Allez dans "IAM & Admin" > "IAM"');
    console.log(`4. Ajoutez le compte de service ${serviceAccountEmail} avec le rôle "Gmail API User"`);
    console.log('5. Activez l\'API Gmail pour ce projet si ce n\'est pas déjà fait');
    
    console.log('\nConfiguration pour GitHub Actions:');
    console.log('1. Allez dans votre dépôt GitHub');
    console.log('2. Allez dans "Settings" > "Secrets and variables" > "Actions"');
    console.log('3. Créez un nouveau secret nommé "EMAIL_PASSWORD"');
    console.log('4. Copiez le contenu du fichier service-account-key.json comme valeur du secret');
    
    return {
      success: true,
      serviceAccountEmail,
      keyFilePath
    };
  } catch (error) {
    console.error('Erreur lors de la création du compte de service:', error.message);
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
createServiceAccount();
