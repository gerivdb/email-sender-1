/**
 * Helper pour la gestion des chemins cross-platform dans les templates Hygen
 * Ce module fournit des fonctions pour manipuler les chemins de façon compatible
 * entre différents systèmes d'exploitation.
 */
const path = require('path');
const os = require('os');
const fs = require('fs');

/**
 * Configuration globale pour les chemins
 */
const config = {
  // Chemin racine du projet, détecté automatiquement
  projectRoot: getProjectRoot(),
  
  // Dossiers communs du projet
  commonFolders: {
    roadmaps: 'roadmaps/plans/consolidated',
    scripts: 'scripts',
    templates: '_templates',
    docs: 'docs'
  }
};

/**
 * Détecte le chemin racine du projet en recherchant le dossier contenant package.json
 * @returns {string} Chemin racine du projet
 */
function getProjectRoot() {
  // Obtenir le répertoire de travail actuel
  let currentDir = process.cwd();
  
  // Remonter jusqu'à trouver package.json ou atteindre la racine du système
  while (!fs.existsSync(path.join(currentDir, 'package.json'))) {
    const parentDir = path.dirname(currentDir);
    if (parentDir === currentDir) {
      // Nous sommes à la racine du système, utiliser le répertoire actuel par défaut
      return process.cwd();
    }
    currentDir = parentDir;
  }
  
  return currentDir;
}

/**
 * Construit un chemin relatif à la racine du projet
 * @param {string} pathSegments - Segments de chemin à joindre
 * @returns {string} Chemin résolu
 */
function projectPath(...pathSegments) {
  return path.join(config.projectRoot, ...pathSegments);
}

/**
 * Construit un chemin vers le dossier roadmaps/plans/consolidated
 * @param {string} filename - Nom du fichier plan
 * @returns {string} Chemin complet vers le fichier plan
 */
function planPath(filename) {
  return projectPath(config.commonFolders.roadmaps, filename);
}

/**
 * Normalise un nom de fichier pour qu'il soit compatible avec tous les systèmes
 * @param {string} name - Nom brut à normaliser
 * @returns {string} Nom normalisé, sans caractères spéciaux et en minuscules
 */
function normalizeName(name) {
  return name
    .toLowerCase()
    .replace(/ /g, '-')
    .replace(/[^a-z0-9\-]/g, '')
    .slice(0, 50);
}

/**
 * Génère un chemin de fichier pour un plan de développement
 * @param {string} version - Version du plan (ex: v2025-05)
 * @param {string} title - Titre du plan
 * @returns {string} Chemin complet pour le fichier plan-dev
 */
function generatePlanDevPath(version, title) {
  const normalizedTitle = normalizeName(title);
  const filename = `plan-dev-${version}-${normalizedTitle}.md`;
  return planPath(filename);
}

/**
 * Vérifie si un chemin est absolu sur la plateforme actuelle
 * @param {string} filePath - Chemin à vérifier
 * @returns {boolean} true si le chemin est absolu
 */
function isAbsolutePath(filePath) {
  return path.isAbsolute(filePath);
}

/**
 * Convertit un chemin Windows en chemin compatible avec le système actuel
 * @param {string} windowsPath - Chemin au format Windows (ex: D:\path\to\file)
 * @returns {string} Chemin compatible avec le système actuel
 */
function convertFromWindowsPath(windowsPath) {
  // Détection des chemins Windows (commençant par C:\, D:\, etc.)
  if (/^[A-Za-z]:\\/.test(windowsPath)) {
    // Convertir les backslash en forward slash
    const posixPath = windowsPath.replace(/\\/g, '/');
    
    // Si on est sous Windows, retourner le chemin convertit
    // Sinon, considérer comme un chemin relatif (ignorer le lecteur)
    if (os.platform() === 'win32') {
      return posixPath;
    } else {
      // Extraction du chemin sans la lettre de lecteur (ex: D:\path -> /path)
      return posixPath.replace(/^[A-Za-z]:/, '');
    }
  }
  
  // Si ce n'est pas un chemin Windows, retourner tel quel
  return windowsPath;
}

module.exports = {
  projectPath,
  planPath,
  normalizeName,
  generatePlanDevPath,
  isAbsolutePath,
  convertFromWindowsPath,
  config
};
