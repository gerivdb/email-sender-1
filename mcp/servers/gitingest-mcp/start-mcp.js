const http = require('http');
const url = require('url');
const fs = require('fs');
const path = require('path');
const analyzeGithubRepo = require('./analyze-github-repo');

// Charger la configuration
const config = JSON.parse(fs.readFileSync(path.join(__dirname, 'config.json'), 'utf8'));

// Créer le serveur HTTP
const server = http.createServer(async (req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  
  // Gérer les requêtes CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  // Gérer les requêtes OPTIONS
  if (req.method === 'OPTIONS') {
    res.statusCode = 200;
    res.end();
    return;
  }
  
  // Gérer les requêtes GET
  if (req.method === 'GET') {
    // Route pour la page d'accueil
    if (pathname === '/') {
      res.setHeader('Content-Type', 'text/html');
      res.statusCode = 200;
      res.end(`
        <!DOCTYPE html>
        <html>
          <head>
            <title>Gitingest MCP Server</title>
            <style>
              body {
                font-family: Arial, sans-serif;
                max-width: 800px;
                margin: 0 auto;
                padding: 20px;
              }
              h1 {
                color: #333;
              }
              form {
                margin-top: 20px;
                padding: 20px;
                border: 1px solid #ddd;
                border-radius: 5px;
              }
              label {
                display: block;
                margin-bottom: 5px;
                font-weight: bold;
              }
              input[type="text"] {
                width: 100%;
                padding: 8px;
                margin-bottom: 15px;
                border: 1px solid #ddd;
                border-radius: 3px;
              }
              button {
                background-color: #4CAF50;
                color: white;
                padding: 10px 15px;
                border: none;
                border-radius: 3px;
                cursor: pointer;
              }
              button:hover {
                background-color: #45a049;
              }
              pre {
                background-color: #f5f5f5;
                padding: 15px;
                border-radius: 5px;
                overflow-x: auto;
              }
            </style>
          </head>
          <body>
            <h1>Gitingest MCP Server</h1>
            <p>Ce serveur permet d'analyser des dépôts GitHub et de générer un résumé de leur contenu.</p>
            
            <form id="analyzeForm">
              <label for="repoUrl">URL du dépôt GitHub:</label>
              <input type="text" id="repoUrl" name="repoUrl" placeholder="https://github.com/username/repo" required>
              
              <button type="submit">Analyser</button>
            </form>
            
            <div id="result" style="margin-top: 20px; display: none;">
              <h2>Résultat:</h2>
              <pre id="resultContent"></pre>
            </div>
            
            <script>
              document.getElementById('analyzeForm').addEventListener('submit', async (e) => {
                e.preventDefault();
                
                const repoUrl = document.getElementById('repoUrl').value;
                
                document.getElementById('resultContent').textContent = 'Analyse en cours...';
                document.getElementById('result').style.display = 'block';
                
                try {
                  const response = await fetch(`/analyze?repoUrl=${encodeURIComponent(repoUrl)}`);
                  const data = await response.json();
                  
                  if (data.success) {
                    document.getElementById('resultContent').textContent = `Analyse terminée. Résultat sauvegardé dans: ${data.digestPath}

Aperçu:
${data.digest.substring(0, 1000)}...`;
                  } else {
                    document.getElementById('resultContent').textContent = `Erreur: ${data.error}`;
                  }
                } catch (error) {
                  document.getElementById('resultContent').textContent = `Erreur: ${error.message}`;
                }
              });
            </script>
          </body>
        </html>
      `);
      return;
    }
    
    // Route pour analyser un dépôt
    if (pathname === '/analyze') {
      const repoUrl = parsedUrl.query.repoUrl;
      
      if (!repoUrl) {
        res.statusCode = 400;
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ success: false, error: 'URL du dépôt GitHub manquante.' }));
        return;
      }
      
      try {
        const result = await analyzeGithubRepo(repoUrl, {
          outputDir: config.outputDir,
          maxFiles: config.maxFiles,
          excludePatterns: config.excludePatterns,
          cloneDir: config.cloneDir
        });
        
        res.statusCode = result.success ? 200 : 500;
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(result));
      } catch (error) {
        res.statusCode = 500;
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ success: false, error: error.message }));
      }
      
      return;
    }
    
    // Route pour récupérer un digest
    if (pathname.startsWith('/digest/')) {
      const repoName = pathname.substring('/digest/'.length);
      const digestPath = path.join(config.outputDir, `${repoName}-digest.md`);
      
      if (!fs.existsSync(digestPath)) {
        res.statusCode = 404;
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ success: false, error: 'Digest non trouvé.' }));
        return;
      }
      
      try {
        const digest = fs.readFileSync(digestPath, 'utf8');
        
        res.statusCode = 200;
        res.setHeader('Content-Type', 'text/markdown');
        res.end(digest);
      } catch (error) {
        res.statusCode = 500;
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ success: false, error: error.message }));
      }
      
      return;
    }
    
    // Route pour l'API MCP
    if (pathname === '/mcp') {
      const action = parsedUrl.query.action;
      const repoUrl = parsedUrl.query.repoUrl;
      
      if (!action) {
        res.statusCode = 400;
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ success: false, error: 'Action manquante.' }));
        return;
      }
      
      if (action === 'analyze') {
        if (!repoUrl) {
          res.statusCode = 400;
          res.setHeader('Content-Type', 'application/json');
          res.end(JSON.stringify({ success: false, error: 'URL du dépôt GitHub manquante.' }));
          return;
        }
        
        try {
          const result = await analyzeGithubRepo(repoUrl, {
            outputDir: config.outputDir,
            maxFiles: config.maxFiles,
            excludePatterns: config.excludePatterns,
            cloneDir: config.cloneDir
          });
          
          res.statusCode = result.success ? 200 : 500;
          res.setHeader('Content-Type', 'application/json');
          res.end(JSON.stringify(result));
        } catch (error) {
          res.statusCode = 500;
          res.setHeader('Content-Type', 'application/json');
          res.end(JSON.stringify({ success: false, error: error.message }));
        }
        
        return;
      }
      
      if (action === 'list') {
        try {
          const files = fs.readdirSync(config.outputDir);
          const digests = files.filter(file => file.endsWith('-digest.md'));
          
          res.statusCode = 200;
          res.setHeader('Content-Type', 'application/json');
          res.end(JSON.stringify({ success: true, digests }));
        } catch (error) {
          res.statusCode = 500;
          res.setHeader('Content-Type', 'application/json');
          res.end(JSON.stringify({ success: false, error: error.message }));
        }
        
        return;
      }
      
      res.statusCode = 400;
      res.setHeader('Content-Type', 'application/json');
      res.end(JSON.stringify({ success: false, error: 'Action non reconnue.' }));
      return;
    }
    
    // Route non trouvée
    res.statusCode = 404;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ success: false, error: 'Route non trouvée.' }));
    return;
  }
  
  // Méthode non supportée
  res.statusCode = 405;
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify({ success: false, error: 'Méthode non supportée.' }));
});

// Démarrer le serveur
server.listen(config.port, () => {
  console.log(`Serveur MCP Gitingest démarré sur le port ${config.port}`);
  console.log(`URL: http://localhost:${config.port}`);
  console.log(`API MCP: http://localhost:${config.port}/mcp`);
});