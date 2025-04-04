import { spawn } from 'child_process';

// Démarrer le serveur MCP
const proc = spawn('node', ['./dist/index.js']);

// Afficher les sorties du serveur
proc.stdout.on('data', data => console.log(`Stdout: ${data.toString()}`));
proc.stderr.on('data', data => console.error(`Stderr: ${data.toString()}`));

// Attendre que le serveur démarre
setTimeout(() => {
  // Envoyer une requête pour lister les méthodes disponibles
  const request = {
    jsonrpc: '2.0',
    id: '1',
    method: 'rpc.discover',
    params: {}
  };
  
  console.log('Envoi de la requête de découverte...');
  proc.stdin.write(JSON.stringify(request) + '\n');
  
  // Attendre la réponse et terminer le processus
  setTimeout(() => {
    console.log('Fin du test');
    proc.kill();
    process.exit(0);
  }, 5000);
}, 1000);
