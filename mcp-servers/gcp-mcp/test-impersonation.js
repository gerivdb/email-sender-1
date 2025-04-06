const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

// Chemin vers le fichier de clé du compte de service
const keyFilePath = path.join(__dirname, 'service-account-key.json');

// Fonction principale
async function testImpersonation() {
  try {
    console.log('Test d\'impersonification...');

    // Vérifier si le fichier de clé existe
    if (!fs.existsSync(keyFilePath)) {
      throw new Error(`Le fichier de clé n'existe pas: ${keyFilePath}`);
    }

    // Lire le fichier de clé
    const keyFile = JSON.parse(fs.readFileSync(keyFilePath, 'utf8'));

    console.log(`Compte de service: ${keyFile.client_email}`);
    console.log(`Tentative d'impersonification de: gerivonderbitsh@gmail.com`);

    // Créer un client JWT avec le compte de service
    const jwtClient = new google.auth.JWT(
      keyFile.client_email,
      null,
      keyFile.private_key,
      ['https://www.googleapis.com/auth/gmail.metadata'],
      'gerivonderbitsh@gmail.com' // L'utilisateur à impersonifier
    );

    // Authentifier le client
    await jwtClient.authorize();

    console.log('Authentification réussie !');

    // Initialiser l'API Gmail
    const gmail = google.gmail({
      version: 'v1',
      auth: jwtClient
    });

    // Tester l'accès en récupérant le profil de l'utilisateur
    const profile = await gmail.users.getProfile({
      userId: 'me'
    });

    console.log('Impersonification réussie !');
    console.log(`Profil récupéré pour: ${profile.data.emailAddress}`);

    return {
      success: true,
      profile: profile.data
    };
  } catch (error) {
    console.error('Erreur lors du test d\'impersonification:', error.message);

    if (error.message.includes('invalid_grant')) {
      console.log('\nErreur d\'authentification. Vérifiez que :');
      console.log('1. Le compte de service a le rôle "Gmail API User"');
      console.log('2. L\'API Gmail est activée dans votre projet GCP');
      console.log('3. Le compte de service a la permission d\'impersonifier l\'utilisateur');
      console.log('\nPour configurer l\'impersonification :');
      console.log('1. Allez sur la console Google Cloud: https://console.cloud.google.com/');
      console.log('2. Allez dans "IAM & Admin" > "Comptes de service"');
      console.log('3. Cliquez sur votre compte de service');
      console.log('4. Allez dans l\'onglet "Permissions"');
      console.log('5. Ajoutez l\'utilisateur gerivonderbitsh@gmail.com avec le rôle "Utilisateur du compte de service"');
    }

    if (error.message.includes('Permission denied')) {
      console.log('\nErreur de permission. Vérifiez que :');
      console.log('1. L\'API Gmail est activée dans votre projet GCP');
      console.log('2. Le compte de service a le rôle "Gmail API User"');
      console.log('3. L\'utilisateur a accordé les permissions nécessaires au compte de service');
    }

    return {
      success: false,
      error: error.message
    };
  }
}

// Exécuter la fonction principale
testImpersonation();
