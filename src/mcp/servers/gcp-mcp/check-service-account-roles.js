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
async function checkServiceAccountRoles() {
  try {
    console.log('Vérification des rôles du compte de service...');
    
    // Définir le projet
    const projectId = 'gen-lang-client-0391388747';
    
    // Lire le fichier de clé du compte de service
    const keyFilePath = path.join(__dirname, 'service-account-key.json');
    if (!fs.existsSync(keyFilePath)) {
      throw new Error(`Le fichier de clé n'existe pas: ${keyFilePath}`);
    }
    
    // Lire le fichier de clé
    const keyFile = JSON.parse(fs.readFileSync(keyFilePath, 'utf8'));
    const serviceAccountEmail = keyFile.client_email;
    
    console.log(`Compte de service: ${serviceAccountEmail}`);
    
    // Initialiser l'API IAM
    const iam = google.iam({
      version: 'v1',
      auth: auth
    });
    
    // Vérifier les rôles du compte de service
    const resourceName = `projects/${projectId}`;
    const iamPolicy = await iam.projects.getIamPolicy({
      resource: resourceName,
      requestBody: {
        options: {
          requestedPolicyVersion: 3
        }
      }
    });
    
    // Rechercher les rôles du compte de service
    const serviceAccountRoles = [];
    if (iamPolicy.data.bindings) {
      iamPolicy.data.bindings.forEach(binding => {
        if (binding.members && binding.members.includes(`serviceAccount:${serviceAccountEmail}`)) {
          serviceAccountRoles.push(binding.role);
        }
      });
    }
    
    console.log('\nRôles du compte de service:');
    if (serviceAccountRoles.length > 0) {
      serviceAccountRoles.forEach(role => {
        console.log(`- ${role}`);
      });
    } else {
      console.log('Aucun rôle trouvé pour ce compte de service.');
    }
    
    // Vérifier si le compte de service a le rôle Gmail API User
    const hasGmailApiUserRole = serviceAccountRoles.some(role => 
      role === 'roles/gmail.serviceAccountUser' || 
      role === 'roles/gmail.user' || 
      role === 'roles/gmail.apiUser'
    );
    
    console.log(`\nRôle Gmail API User: ${hasGmailApiUserRole ? 'Oui' : 'Non'}`);
    
    if (!hasGmailApiUserRole) {
      console.log('\nPour ajouter le rôle Gmail API User:');
      console.log('1. Allez sur la console Google Cloud: https://console.cloud.google.com/');
      console.log('2. Allez dans "IAM & Admin" > "IAM"');
      console.log('3. Cliquez sur "Ajouter"');
      console.log(`4. Entrez l'adresse email du compte de service: ${serviceAccountEmail}`);
      console.log('5. Ajoutez le rôle "Gmail API User" (roles/gmail.apiUser)');
      console.log('6. Cliquez sur "Enregistrer"');
    }
    
    // Vérifier si l'API Gmail est activée
    const serviceUsage = google.serviceusage({
      version: 'v1',
      auth: auth
    });
    
    const gmailService = await serviceUsage.services.get({
      name: `projects/${projectId}/services/gmail.googleapis.com`
    }).catch(error => {
      if (error.code === 404 || (error.response && error.response.status === 404)) {
        return { data: { state: 'DISABLED' } };
      }
      throw error;
    });
    
    const gmailApiEnabled = gmailService.data.state === 'ENABLED';
    
    console.log(`\nAPI Gmail activée: ${gmailApiEnabled ? 'Oui' : 'Non'}`);
    
    if (!gmailApiEnabled) {
      console.log('\nPour activer l\'API Gmail:');
      console.log('1. Visitez https://console.cloud.google.com/apis/library/gmail.googleapis.com?project=gen-lang-client-0391388747');
      console.log('2. Cliquez sur le bouton "Activer"');
      console.log('3. Attendez quelques minutes pour que l\'activation se propage');
    }
    
    // Vérifier si l'utilisateur a le rôle Service Account User
    const serviceAccountsAdmin = google.iam({
      version: 'v1',
      auth: auth
    });
    
    const serviceAccountResource = `projects/${projectId}/serviceAccounts/${serviceAccountEmail}`;
    const serviceAccountPolicy = await serviceAccountsAdmin.projects.serviceAccounts.getIamPolicy({
      resource: serviceAccountResource
    });
    
    const userEmail = 'gerivonderbitsh@gmail.com';
    let hasServiceAccountUserRole = false;
    
    if (serviceAccountPolicy.data.bindings) {
      serviceAccountPolicy.data.bindings.forEach(binding => {
        if (binding.role === 'roles/iam.serviceAccountUser' && 
            binding.members && 
            binding.members.includes(`user:${userEmail}`)) {
          hasServiceAccountUserRole = true;
        }
      });
    }
    
    console.log(`\nUtilisateur ${userEmail} a le rôle Service Account User: ${hasServiceAccountUserRole ? 'Oui' : 'Non'}`);
    
    if (!hasServiceAccountUserRole) {
      console.log('\nPour ajouter le rôle Service Account User:');
      console.log('1. Allez sur la console Google Cloud: https://console.cloud.google.com/');
      console.log('2. Allez dans "IAM & Admin" > "Comptes de service"');
      console.log(`3. Cliquez sur le compte de service: ${serviceAccountEmail}`);
      console.log('4. Allez dans l\'onglet "Permissions"');
      console.log('5. Cliquez sur "Ajouter un compte principal"');
      console.log(`6. Entrez l'adresse email: ${userEmail}`);
      console.log('7. Ajoutez le rôle "Utilisateur du compte de service" (roles/iam.serviceAccountUser)');
      console.log('8. Cliquez sur "Enregistrer"');
    }
    
    return {
      success: true,
      serviceAccountRoles,
      hasGmailApiUserRole,
      gmailApiEnabled,
      hasServiceAccountUserRole
    };
  } catch (error) {
    console.error('Erreur lors de la vérification des rôles:', error.message);
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
checkServiceAccountRoles();
