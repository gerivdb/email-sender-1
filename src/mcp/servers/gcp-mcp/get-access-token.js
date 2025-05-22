const fs = require('fs');
const { google } = require('googleapis');
const path = require('path');

// Chemin vers le fichier d'identifiants
const credentialsPath = path.join(__dirname, 'credentials.json');

// Lire le fichier d'identifiants
const credentials = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));

// Extraire les informations d'identification
const { client_id, client_secret } = credentials.installed;

// Créer un client OAuth2
const oauth2Client = new google.auth.OAuth2(
  client_id,
  client_secret,
  'http://localhost'
);

// Fonction interactive pour obtenir le code d'autorisation
async function promptForAuthCode() {
  const readline = require('readline');
  const authUrl = oauth2Client.generateAuthUrl({
    access_type: 'offline',
    scope: ['https://www.googleapis.com/auth/cloud-platform']
  });
  console.log('Ouvrez ce lien dans votre navigateur pour autoriser l\'application :\n');
  console.log(authUrl + '\n');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  return new Promise(resolve => {
    rl.question('Collez ici le code d\'autorisation Google : ', code => {
      rl.close();
      resolve(code.trim());
    });
  });
}

// Échanger le code contre des jetons
async function getToken() {
  let code = process.env.GCP_AUTH_CODE;
  if (!code) {
    code = await promptForAuthCode();
  }
  try {
    const { tokens } = await oauth2Client.getToken(code);

    // Sauvegarder les jetons dans un fichier
    const tokenPath = path.join(__dirname, 'token.json');
    fs.writeFileSync(tokenPath, JSON.stringify(tokens, null, 2));

    console.log('\nJetons sauvegardés dans token.json');
    console.log('Vous pouvez maintenant utiliser le MCP GCP.');
  } catch (error) {
    console.error('Erreur lors de l\'obtention des jetons:', error.message);

    // En cas d'erreur, créer un jeton factice
    console.log('\nCréation d\'un jeton factice...');
    const tokenPath = path.join(__dirname, 'token.json');
    const token = {
      access_token: 'dummy_token',
      refresh_token: 'dummy_refresh_token',
      scope: 'https://www.googleapis.com/auth/cloud-platform',
      token_type: 'Bearer',
      expiry_date: new Date().getTime() + 3600 * 1000
    };
    fs.writeFileSync(tokenPath, JSON.stringify(token, null, 2));
    console.log('Jeton factice créé dans token.json');
    console.log('Note: Ce jeton est factice et ne fournit pas d\'authentification réelle.');
    console.log('Il permet simplement au MCP GCP de démarrer sans erreur.');
  }
}

getToken();

