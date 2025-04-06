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
async function sendTestEmail() {
  try {
    console.log('Envoi d\'un email de test (méthode OAuth2)...');
    
    // Initialiser l'API Gmail
    const gmail = google.gmail({
      version: 'v1',
      auth: auth
    });
    
    // Créer le message
    const emailLines = [
      'From: "GitHub Actions Test" <gerivonderbitsh@gmail.com>',
      'To: gerivonderbitsh@gmail.com',
      'Subject: Test Email from GitHub Actions',
      '',
      'Ceci est un email de test envoyé depuis le script OAuth2.',
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
      console.log('1. Le token OAuth2 est valide');
      console.log('2. L\'API Gmail est activée dans votre projet GCP');
      console.log('3. L\'utilisateur a accordé les permissions nécessaires');
    }
    
    if (error.message.includes('Permission denied')) {
      console.log('\nErreur de permission. Vérifiez que :');
      console.log('1. L\'API Gmail est activée dans votre projet GCP');
      console.log('2. L\'utilisateur a accordé les permissions nécessaires');
    }
    
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
sendTestEmail();
