const fs = require('fs');
const { spawn } = require('child_process');

// Fonction pour exécuter une commande MCP GitHub
async function runMcpGithubCommand(tool, params) {
  return new Promise((resolve, reject) => {
    // Préparer la commande MCP
    const mcpCommand = {
      tool,
      params
    };
    
    // Convertir en JSON
    const mcpJson = JSON.stringify(mcpCommand);
    
    // Chemin vers le script MCP GitHub
    const mcpPath = './scripts/cmd/augment/augment-mcp-github.cmd';
    
    // Lancer le processus
    const process = spawn(mcpPath, [], { shell: true });
    
    let stdout = '';
    let stderr = '';
    
    process.stdout.on('data', (data) => {
      stdout += data.toString();
    });
    
    process.stderr.on('data', (data) => {
      stderr += data.toString();
    });
    
    process.on('close', (code) => {
      if (code !== 0) {
        console.error(`Le processus s'est terminé avec le code ${code}`);
        console.error(`STDERR: ${stderr}`);
        reject(new Error(`Le processus s'est terminé avec le code ${code}`));
        return;
      }
      
      try {
        // Écrire la sortie dans un fichier pour déboguer
        fs.writeFileSync('mcp_output.txt', stdout);
        
        // Essayer de trouver une réponse JSON valide dans la sortie
        const jsonMatch = stdout.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          const result = JSON.parse(jsonMatch[0]);
          resolve(result);
        } else {
          console.error('Aucune réponse JSON valide trouvée dans la sortie');
          reject(new Error('Aucune réponse JSON valide trouvée dans la sortie'));
        }
      } catch (error) {
        console.error(`Erreur lors du traitement de la réponse: ${error.message}`);
        reject(error);
      }
    });
    
    // Envoyer la commande JSON
    process.stdin.write(mcpJson);
    process.stdin.end();
  });
}

// Fonction principale
async function main() {
  const command = process.argv[2];
  
  if (command === 'repo') {
    try {
      const result = await runMcpGithubCommand('github_repo_info', {
        repo_url: 'https://github.com/augmentcode/DeeperSpeed'
      });
      console.log(JSON.stringify(result, null, 2));
    } catch (error) {
      console.error(`Erreur: ${error.message}`);
    }
  } else if (command === 'files') {
    try {
      const result = await runMcpGithubCommand('github_list_files', {
        repo_url: 'https://github.com/augmentcode/DeeperSpeed'
      });
      console.log(JSON.stringify(result, null, 2));
    } catch (error) {
      console.error(`Erreur: ${error.message}`);
    }
  } else if (command === 'read') {
    const filePath = process.argv[3] || 'README.md';
    try {
      const result = await runMcpGithubCommand('github_read_file', {
        repo_url: 'https://github.com/augmentcode/DeeperSpeed',
        file_path: filePath
      });
      console.log(JSON.stringify(result, null, 2));
    } catch (error) {
      console.error(`Erreur: ${error.message}`);
    }
  } else {
    console.log('Usage: node temp_github_mcp.js [repo|files|read] [file_path]');
    console.log('  repo: Affiche les informations sur le dépôt');
    console.log('  files: Liste les fichiers du dépôt');
    console.log('  read: Lit un fichier spécifique (par défaut: README.md)');
  }
}

main();
