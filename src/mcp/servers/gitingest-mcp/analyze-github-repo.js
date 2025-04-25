const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const gitingest = require('@magarcia/gitingest');

// Fonction principale
async function analyzeGithubRepo(repoUrl, options = {}) {
  try {
    console.log(`Analyse du dépôt GitHub: ${repoUrl}`);
    
    // Options par défaut
    const defaultOptions = {
      outputDir: path.join(__dirname, 'output'),
      maxFiles: 100,
      includePatterns: [],
      excludePatterns: [
        'node_modules/**',
        '.git/**',
        '**/*.min.js',
        '**/*.bundle.js',
        '**/*.map',
        '**/dist/**',
        '**/build/**'
      ],
      cloneDir: path.join(__dirname, 'repos')
    };
    
    // Fusionner les options
    const mergedOptions = { ...defaultOptions, ...options };
    
    // Créer les répertoires s'ils n'existent pas
    if (!fs.existsSync(mergedOptions.outputDir)) {
      fs.mkdirSync(mergedOptions.outputDir, { recursive: true });
    }
    
    if (!fs.existsSync(mergedOptions.cloneDir)) {
      fs.mkdirSync(mergedOptions.cloneDir, { recursive: true });
    }
    
    // Extraire le nom du dépôt à partir de l'URL
    const repoName = repoUrl.split('/').pop().replace('.git', '');
    const repoPath = path.join(mergedOptions.cloneDir, repoName);
    
    // Vérifier si le dépôt existe déjà
    if (fs.existsSync(repoPath)) {
      console.log(`Le dépôt existe déjà localement. Mise à jour...`);
      try {
        execSync(`cd "${repoPath}" && git pull`, { stdio: 'inherit' });
      } catch (error) {
        console.warn(`Erreur lors de la mise à jour du dépôt: ${error.message}`);
        console.log(`Suppression et re-clonage du dépôt...`);
        fs.rmSync(repoPath, { recursive: true, force: true });
        execSync(`git clone ${repoUrl} "${repoPath}"`, { stdio: 'inherit' });
      }
    } else {
      console.log(`Clonage du dépôt...`);
      execSync(`git clone ${repoUrl} "${repoPath}"`, { stdio: 'inherit' });
    }
    
    console.log(`Analyse du dépôt...`);
    
    // Configurer les options pour gitingest
    const gitingestOptions = {
      path: repoPath,
      output: path.join(mergedOptions.outputDir, `${repoName}-digest.md`),
      maxFiles: mergedOptions.maxFiles,
      include: mergedOptions.includePatterns,
      exclude: mergedOptions.excludePatterns
    };
    
    // Exécuter gitingest
    await gitingest(gitingestOptions);
    
    console.log(`Analyse terminée. Résultat sauvegardé dans: ${gitingestOptions.output}`);
    
    // Lire le résultat
    const digest = fs.readFileSync(gitingestOptions.output, 'utf8');
    
    return {
      success: true,
      repoName,
      digestPath: gitingestOptions.output,
      digest
    };
  } catch (error) {
    console.error(`Erreur lors de l'analyse du dépôt: ${error.message}`);
    
    return {
      success: false,
      error: error.message
    };
  }
}

// Si le script est exécuté directement
if (require.main === module) {
  // Récupérer les arguments de la ligne de commande
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.error('Erreur: URL du dépôt GitHub manquante.');
    console.log('Usage: node analyze-github-repo.js <repo-url> [options]');
    console.log('Exemple: node analyze-github-repo.js https://github.com/username/repo');
    process.exit(1);
  }
  
  const repoUrl = args[0];
  
  // Analyser les options
  const options = {};
  
  if (args.length > 1) {
    try {
      const optionsArg = args[1];
      Object.assign(options, JSON.parse(optionsArg));
    } catch (error) {
      console.error(`Erreur lors de l'analyse des options: ${error.message}`);
      process.exit(1);
    }
  }
  
  // Exécuter l'analyse
  analyzeGithubRepo(repoUrl, options)
    .then(result => {
      if (!result.success) {
        process.exit(1);
      }
    })
    .catch(error => {
      console.error(`Erreur non gérée: ${error.message}`);
      process.exit(1);
    });
}

// Exporter la fonction
module.exports = analyzeGithubRepo;
