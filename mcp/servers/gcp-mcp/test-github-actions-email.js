const fs = require('fs');
const path = require('path');
const sendEmail = require('./github-actions-email');

// Chemin vers le fichier d'identifiants
const tokenPath = path.join(__dirname, 'token.json');

// Lire le fichier token.json
const token = JSON.parse(fs.readFileSync(tokenPath, 'utf8'));

// Définir les variables d'environnement
process.env.GMAIL_CLIENT_ID = token.client_id;
process.env.GMAIL_CLIENT_SECRET = token.client_secret;
process.env.GMAIL_REFRESH_TOKEN = token.refresh_token;

// Afficher les variables (masquées pour la sécurité)
console.log('Variables d\'environnement:');
console.log(`GMAIL_CLIENT_ID=${process.env.GMAIL_CLIENT_ID.substring(0, 10)}...`);
console.log(`GMAIL_CLIENT_SECRET=${process.env.GMAIL_CLIENT_SECRET.substring(0, 10)}...`);
console.log(`GMAIL_REFRESH_TOKEN=${process.env.GMAIL_REFRESH_TOKEN.substring(0, 10)}...`);
console.log();

// Envoyer un email de test
sendEmail({
  to: 'gerivonderbitsh@gmail.com',
  subject: 'Test GitHub Actions Email',
  body: 'Ceci est un test d\'envoi d\'email depuis GitHub Actions.\n\nSi vous recevez cet email, cela signifie que la configuration a été effectuée avec succès.\n\nCordialement,\nLe script de test'
});
