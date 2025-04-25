import { spawn } from 'child_process';

// Démarrer le serveur MCP
const proc = spawn('node', ['./dist/index.js']);

// Afficher les sorties du serveur
proc.stdout.on('data', data => console.log(`Stdout: ${data.toString()}`));
proc.stderr.on('data', data => console.error(`Stderr: ${data.toString()}`));

// Attendre que le serveur démarre
setTimeout(() => {
  // Envoyer une requête de recherche pour les Google Docs
  const request = {
    jsonrpc: '2.0',
    id: '1',
    method: 'mcp.tools.search',
    params: {
      query: 'mimeType="application/vnd.google-apps.document"'
    }
  };

  console.log('Envoi de la requête de recherche...');
  proc.stdin.write(JSON.stringify(request) + '\n');

  // Attendre la réponse et terminer le processus
  setTimeout(() => {
    console.log('Fin du test');
    proc.kill();
    process.exit(0);
  }, 5000);
}, 1000);
