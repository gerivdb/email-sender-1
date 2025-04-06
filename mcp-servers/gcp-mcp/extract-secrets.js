const fs = require('fs');
const path = require('path');

// Chemin vers le fichier d'identifiants
const tokenPath = path.join(__dirname, 'token.json');

// Lire le fichier token.json
const token = JSON.parse(fs.readFileSync(tokenPath, 'utf8'));

// Afficher les secrets
console.log('Secrets pour GitHub Actions:');
console.log('---------------------------');
console.log(`GMAIL_CLIENT_ID: ${token.client_id}`);
console.log(`GMAIL_CLIENT_SECRET: ${token.client_secret}`);
console.log(`GMAIL_REFRESH_TOKEN: ${token.refresh_token}`);
console.log('---------------------------');
console.log();
console.log('Instructions:');
console.log('1. Allez dans les paramètres de votre dépôt GitHub');
console.log('2. Cliquez sur "Secrets and variables" > "Actions"');
console.log('3. Cliquez sur "New repository secret"');
console.log('4. Ajoutez les secrets ci-dessus un par un');
console.log('5. Cliquez sur "Add secret" pour chaque secret');
