const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

// Fonction principale
async function sendEmail(options) {
  try {
    console.log('Envoi d\'un email depuis GitHub Actions...');
    
    // Récupérer les informations d'authentification depuis les variables d'environnement
    const clientId = process.env.GMAIL_CLIENT_ID;
    const clientSecret = process.env.GMAIL_CLIENT_SECRET;
    const refreshToken = process.env.GMAIL_REFRESH_TOKEN;
    
    if (!clientId || !clientSecret || !refreshToken) {
      throw new Error('Les variables d\'environnement GMAIL_CLIENT_ID, GMAIL_CLIENT_SECRET et GMAIL_REFRESH_TOKEN doivent être définies.');
    }
    
    // Créer un client OAuth2
    const auth = new google.auth.OAuth2(
      clientId,
      clientSecret
    );
    
    // Définir les informations d'authentification
    auth.setCredentials({
      refresh_token: refreshToken
    });
    
    // Initialiser l'API Gmail
    const gmail = google.gmail({
      version: 'v1',
      auth: auth
    });
    
    // Valeurs par défaut
    const {
      to = 'gerivonderbitsh@gmail.com',
      from = 'gerivonderbitsh@gmail.com',
      subject = 'Notification de GitHub Actions',
      body = 'Ceci est un email envoyé depuis GitHub Actions.',
      name = 'GitHub Actions'
    } = options || {};
    
    // Créer le message
    const emailLines = [
      `From: "${name}" <${from}>`,
      `To: ${to}`,
      `Subject: ${subject}`,
      '',
      body
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
    
    if (error.response) {
      console.error('Détails de l\'erreur:', error.response.data);
    }
    
    return {
      success: false,
      error: error.message
    };
  }
}

// Exporter la fonction
module.exports = sendEmail;

// Si le script est exécuté directement
if (require.main === module) {
  // Récupérer les arguments de la ligne de commande
  const args = process.argv.slice(2);
  
  // Vérifier si des arguments ont été fournis
  if (args.length > 0) {
    try {
      // Analyser les arguments
      const options = JSON.parse(args[0]);
      
      // Envoyer l'email
      sendEmail(options)
        .then(result => {
          if (!result.success) {
            process.exit(1);
          }
        })
        .catch(error => {
          console.error('Erreur non gérée:', error);
          process.exit(1);
        });
    } catch (error) {
      console.error('Erreur lors de l\'analyse des arguments:', error.message);
      process.exit(1);
    }
  } else {
    // Envoyer un email avec les valeurs par défaut
    sendEmail()
      .then(result => {
        if (!result.success) {
          process.exit(1);
        }
      })
      .catch(error => {
        console.error('Erreur non gérée:', error);
        process.exit(1);
      });
  }
}
