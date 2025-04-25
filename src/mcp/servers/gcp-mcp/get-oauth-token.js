const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

// Chemin vers le fichier d'identifiants
const credentialsPath = path.join(__dirname, 'credentials.json');
const tokenPath = path.join(__dirname, 'token.json');

// Lire le fichier credentials.json
const credentials = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));

// Créer un client OAuth2
const { client_secret, client_id, redirect_uris } = credentials.installed;
const oAuth2Client = new google.auth.OAuth2(
  client_id,
  client_secret,
  redirect_uris[0]
);

// Définir les scopes
const SCOPES = [
  'https://www.googleapis.com/auth/gmail.send',
  'https://www.googleapis.com/auth/gmail.compose',
  'https://www.googleapis.com/auth/gmail.modify'
];

// Fonction principale
async function getNewToken() {
  try {
    console.log('Obtention d\'un nouveau token OAuth2...');
    
    // Générer l'URL d'autorisation
    const authUrl = oAuth2Client.generateAuthUrl({
      access_type: 'offline',
      scope: SCOPES,
      prompt: 'consent'
    });
    
    console.log('Autorisez cette application en visitant cette URL:');
    console.log(authUrl);
    
    // Créer une interface de ligne de commande
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
    
    // Demander le code d'autorisation
    rl.question('Entrez le code de la page de redirection: ', async (code) => {
      rl.close();
      
      try {
        // Échanger le code contre un token
        const { tokens } = await oAuth2Client.getToken(code);
        
        // Sauvegarder le token
        fs.writeFileSync(tokenPath, JSON.stringify({
          ...tokens,
          client_id,
          client_secret
        }));
        
        console.log('Token sauvegardé dans:', tokenPath);
        
        return {
          success: true,
          tokens
        };
      } catch (error) {
        console.error('Erreur lors de l\'obtention du token:', error.message);
        
        return {
          success: false,
          error: error.message
        };
      }
    });
  } catch (error) {
    console.error('Erreur lors de l\'obtention du token:', error.message);
    
    return {
      success: false,
      error: error.message
    };
  }
}

// Exécuter la fonction principale
getNewToken();
