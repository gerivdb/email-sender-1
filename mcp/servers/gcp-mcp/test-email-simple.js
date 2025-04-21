const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

// Chemin vers le fichier de clé du compte de service
const keyFilePath = path.join(__dirname, 'service-account-key.json');

// Fonction principale
async function sendTestEmail() {
  try {
    console.log('Envoi d\'un email de test (méthode simple)...');
    
    // Vérifier si le fichier de clé existe
    if (!fs.existsSync(keyFilePath)) {
      throw new Error(`Le fichier de clé n'existe pas: ${keyFilePath}`);
    }
    
    // Lire le fichier de clé
    const keyFile = JSON.parse(fs.readFileSync(keyFilePath, 'utf8'));
    
    console.log(`Compte de service: ${keyFile.client_email}`);
    console.log(`Tentative d'envoi d'email en tant que: gerivonderbitsh@gmail.com`);
    
    // Créer un client JWT avec le compte de service
    const jwtClient = new google.auth.JWT({
      email: keyFile.client_email,
      key: keyFile.private_key,
      scopes: ['https://www.googleapis.com/auth/gmail.send'],
      subject: 'gerivonderbitsh@gmail.com' // L'utilisateur à impersonifier
    });
    
    // Authentifier le client
    await jwtClient.authorize();
    
    console.log('Authentification réussie !');
    
    // Initialiser l'API Gmail
    const gmail = google.gmail({
      version: 'v1',
      auth: jwtClient
    });
    
    // Créer le message
    const emailLines = [
      'From: "GitHub Actions Test" <gerivonderbitsh@gmail.com>',
      'To: gerivonderbitsh@gmail.com',
      'Subject: Test Email from GitHub Actions',
      '',
      'Ceci est un email de test envoyé depuis le compte de service GitHub Actions.',
      '',
      'Si vous recevez cet email, cela signifie que la configuration a été effectuée avec succès.',
      '',
      'Cordialement,',
      'Le script de test'
    ];
    
    // Encoder le message en base64
    const email = emailLines.join('\r\n');
    const encodedEmail = Buffer.from(email).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
    
    // Envoyer le message
    const response = await gmail.users.messages.send({
      userId: 'me',
      requestBody: {
        raw: encodedEmail
      }
    });
    
    console.log('Email envoyé avec succès !');
    console.log('ID du message:', response.data.id);
    
    return {
      success: true,
      messageId: response.data.id
    };
  } catch (error) {
    console.error('Erreur lors de l\'envoi de l\'email:', error.message);
    
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
sendTestEmail();
