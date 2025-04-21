const fs = require('fs');
const path = require('path');
const { Octokit } = require('@octokit/rest');
const sodium = require('libsodium-wrappers');

// Fonction principale
async function configureGitHubSecret() {
  try {
    console.log('Configuration du secret EMAIL_PASSWORD dans GitHub Actions...');
    
    // Vérifier si le fichier .env existe à la racine du projet
    const envFilePath = path.join(__dirname, '..', '..', '.env');
    if (!fs.existsSync(envFilePath)) {
      throw new Error(`Le fichier .env n'existe pas: ${envFilePath}`);
    }
    
    // Lire le contenu du fichier .env
    const envContent = fs.readFileSync(envFilePath, 'utf8');
    
    // Extraire la variable GITHUB_TOKEN
    const githubTokenMatch = envContent.match(/GITHUB_TOKEN=([^\r\n]+)/);
    if (!githubTokenMatch) {
      throw new Error('GITHUB_TOKEN non trouvé dans le fichier .env');
    }
    const githubToken = githubTokenMatch[1];
    
    // Extraire la variable GITHUB_OWNER
    const githubOwnerMatch = envContent.match(/GITHUB_OWNER=([^\r\n]+)/);
    if (!githubOwnerMatch) {
      throw new Error('GITHUB_OWNER non trouvé dans le fichier .env');
    }
    const githubOwner = githubOwnerMatch[1];
    
    // Extraire la variable GITHUB_REPO
    const githubRepoMatch = envContent.match(/GITHUB_REPO=([^\r\n]+)/);
    if (!githubRepoMatch) {
      throw new Error('GITHUB_REPO non trouvé dans le fichier .env');
    }
    const githubRepo = githubRepoMatch[1];
    
    // Vérifier si le fichier service-account-key.json existe
    const keyFilePath = path.join(__dirname, 'service-account-key.json');
    if (!fs.existsSync(keyFilePath)) {
      throw new Error(`Le fichier service-account-key.json n'existe pas: ${keyFilePath}`);
    }
    
    // Lire le contenu du fichier service-account-key.json
    const keyContent = fs.readFileSync(keyFilePath, 'utf8');
    
    // Initialiser Octokit avec le token GitHub
    const octokit = new Octokit({
      auth: githubToken
    });
    
    // Obtenir la clé publique pour le chiffrement
    const { data: publicKeyData } = await octokit.actions.getRepoPublicKey({
      owner: githubOwner,
      repo: githubRepo
    });
    
    // Chiffrer le secret avec la clé publique
    await sodium.ready;
    
    const messageBytes = Buffer.from(keyContent);
    const keyBytes = Buffer.from(publicKeyData.key, 'base64');
    
    const encryptedBytes = sodium.crypto_box_seal(messageBytes, keyBytes);
    const encrypted = Buffer.from(encryptedBytes).toString('base64');
    
    // Créer ou mettre à jour le secret
    await octokit.actions.createOrUpdateRepoSecret({
      owner: githubOwner,
      repo: githubRepo,
      secret_name: 'EMAIL_PASSWORD',
      encrypted_value: encrypted,
      key_id: publicKeyData.key_id
    });
    
    console.log('Secret EMAIL_PASSWORD configuré avec succès dans GitHub Actions');
    
    return {
      success: true
    };
  } catch (error) {
    console.error('Erreur lors de la configuration du secret GitHub:', error.message);
    return {
      success: false,
      error: error.message
    };
  }
}

// Exécuter la fonction principale
configureGitHubSecret();
