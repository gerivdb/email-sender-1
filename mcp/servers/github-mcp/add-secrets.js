const fs = require('fs');
const path = require('path');
const { Octokit } = require('@octokit/rest');
const sodium = require('libsodium-wrappers');

// Chemin vers le fichier de configuration
const configPath = path.join(__dirname, 'config.json');

// Chemin vers le fichier d'identifiants
const tokenPath = path.join(__dirname, '..', 'gcp-mcp', 'token.json');

// Fonction principale
async function addSecrets() {
  try {
    console.log('Ajout des secrets pour GitHub Actions...');
    
    // Vérifier si le fichier de configuration existe
    if (!fs.existsSync(configPath)) {
      throw new Error('Le fichier de configuration n\'existe pas.');
    }
    
    // Lire le fichier de configuration
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    
    // Vérifier si le token est défini
    if (!config.token || config.token === 'VOTRE_TOKEN_GITHUB') {
      throw new Error('Le token GitHub n\'est pas défini dans le fichier de configuration.');
    }
    
    // Vérifier si le fichier d'identifiants existe
    if (!fs.existsSync(tokenPath)) {
      throw new Error('Le fichier d\'identifiants n\'existe pas.');
    }
    
    // Lire le fichier d'identifiants
    const token = JSON.parse(fs.readFileSync(tokenPath, 'utf8'));
    
    // Créer un client Octokit
    const octokit = new Octokit({
      auth: config.token
    });
    
    // Récupérer la clé publique pour chiffrer les secrets
    const { data: publicKeyData } = await octokit.actions.getRepoPublicKey({
      owner: config.owner,
      repo: config.repo
    });
    
    // Attendre que libsodium soit prêt
    await sodium.ready;
    
    // Fonction pour chiffrer un secret
    const encryptSecret = (secret, key_id, key) => {
      // Convertir la clé publique en Uint8Array
      const keyBytes = Buffer.from(key, 'base64');
      
      // Convertir le secret en Uint8Array
      const secretBytes = Buffer.from(secret);
      
      // Chiffrer le secret
      const encryptedBytes = sodium.crypto_box_seal(secretBytes, keyBytes);
      
      // Convertir le secret chiffré en base64
      const encrypted = Buffer.from(encryptedBytes).toString('base64');
      
      return {
        encrypted_value: encrypted,
        key_id
      };
    };
    
    // Secrets à ajouter
    const secrets = {
      GMAIL_CLIENT_ID: token.client_id,
      GMAIL_CLIENT_SECRET: token.client_secret,
      GMAIL_REFRESH_TOKEN: token.refresh_token
    };
    
    // Ajouter chaque secret
    for (const [name, value] of Object.entries(secrets)) {
      console.log(`Ajout du secret ${name}...`);
      
      // Chiffrer le secret
      const encryptedSecret = encryptSecret(value, publicKeyData.key_id, publicKeyData.key);
      
      // Ajouter le secret
      await octokit.actions.createOrUpdateRepoSecret({
        owner: config.owner,
        repo: config.repo,
        secret_name: name,
        encrypted_value: encryptedSecret.encrypted_value,
        key_id: encryptedSecret.key_id
      });
      
      console.log(`Secret ${name} ajouté avec succès.`);
    }
    
    console.log('\nTous les secrets ont été ajoutés avec succès.');
    console.log('Vous pouvez maintenant utiliser ces secrets dans vos workflows GitHub Actions.');
    
    return {
      success: true
    };
  } catch (error) {
    console.error('Erreur lors de l\'ajout des secrets:', error.message);
    
    return {
      success: false,
      error: error.message
    };
  }
}

// Exécuter la fonction principale
addSecrets();
