/**
 * Script pour générer des données de test pour la visualisation "ligne de métro" cognitive
 *
 * Ce script convertit les données JSON des roadmaps en un format adapté
 * à la visualisation "ligne de métro" cognitive.
 */

const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
  inputDir: path.join(__dirname, 'data'),
  outputDir: path.join(__dirname, 'data', 'metro'),
  combinedOutputFile: path.join(__dirname, 'data', 'metro', 'combined-metro-data.json')
};

// Créer le répertoire de sortie s'il n'existe pas
if (!fs.existsSync(CONFIG.outputDir)) {
  fs.mkdirSync(CONFIG.outputDir, { recursive: true });
}

/**
 * Convertit les données d'une roadmap en format "ligne de métro" cognitive
 * @param {Object} data - Données de la roadmap
 * @returns {Object} - Données au format "ligne de métro"
 */
function convertToMetroFormat(data) {
  // Créer une copie des données pour éviter de modifier l'original
  const metroData = JSON.parse(JSON.stringify(data));

  // Ajouter des métadonnées pour la visualisation "ligne de métro"
  metroData.metroMap = {
    lines: [],
    stations: [],
    connections: []
  };

  // Générer les lignes de métro (une ligne par niveau hiérarchique)
  const levelOrder = ['cosmos', 'galaxy', 'stellar_system', 'planet', 'continent', 'region', 'locality', 'district', 'building', 'foundation'];

  levelOrder.forEach((level, index) => {
    metroData.metroMap.lines.push({
      id: `line-${level}`,
      name: level.toUpperCase(),
      color: getLevelColor(level),
      order: index
    });
  });

  // Générer les stations et les connexions
  const processNode = (node, parentId = null, depth = 0) => {
    // Déterminer la ligne de métro pour ce nœud
    const nodeType = node.type || 'locality';
    const lineId = `line-${nodeType}`;
    const lineIndex = levelOrder.indexOf(nodeType);

    // Créer la station
    const station = {
      id: node.id,
      name: node.title,
      lineId: lineId,
      status: node.status || 'planned',
      description: node.description || '',
      metadata: node.metadata || {
        temporal: {},
        cognitive: {},
        organizational: {},
        strategic: {}
      }
    };

    metroData.metroMap.stations.push(station);

    // Créer la connexion avec le parent si existant
    if (parentId) {
      metroData.metroMap.connections.push({
        id: `conn-${parentId}-${node.id}`,
        sourceId: parentId,
        targetId: node.id,
        type: 'hierarchical'
      });
    }

    // Traiter les enfants
    if (node.children && node.children.length > 0) {
      node.children.forEach(child => {
        processNode(child, node.id, depth + 1);
      });
    }

    // Ajouter les dépendances si définies
    if (node.dependencies) {
      node.dependencies.forEach(dep => {
        metroData.metroMap.connections.push({
          id: `dep-${node.id}-${dep.id}`,
          sourceId: node.id,
          targetId: dep.id,
          type: 'dependency'
        });
      });
    }
  };

  // Commencer le traitement par le nœud racine
  try {
    // Vérifier si les données ont la structure attendue
    if (!metroData.id || !metroData.title) {
      console.warn('Structure de données non standard, ajout d\'attributs par défaut');
      metroData.id = metroData.id || 'root-' + Date.now();
      metroData.title = metroData.title || 'Roadmap';
      metroData.type = metroData.type || 'cosmos';
      metroData.status = metroData.status || 'planned';
    }

    processNode(metroData);
  } catch (error) {
    console.error('Erreur lors du traitement du nœud racine:', error);
    // Créer un nœud racine minimal pour éviter l'échec complet
    metroData.metroMap.stations.push({
      id: 'error-node',
      name: 'Erreur de traitement',
      lineId: 'line-cosmos',
      status: 'blocked',
      description: 'Une erreur est survenue lors du traitement des données: ' + error.message,
      metadata: {
        temporal: { horizon: 'immediate' },
        cognitive: { complexity: 'high' },
        organizational: { responsibility: 'technical' },
        strategic: { priority: 'high' }
      }
    });
  }

  return metroData;
}

/**
 * Obtient la couleur associée à un niveau hiérarchique
 * @param {string} level - Niveau hiérarchique
 * @returns {string} - Code couleur hexadécimal
 */
function getLevelColor(level) {
  const colors = {
    cosmos: '#1a237e',     // Bleu profond
    galaxy: '#7b1fa2',     // Violet
    stellar_system: '#d32f2f', // Rouge
    planet: '#ff9800',     // Orange
    continent: '#ffc107',  // Ambre
    region: '#4caf50',     // Vert
    locality: '#00bcd4',   // Cyan
    district: '#2196f3',   // Bleu
    building: '#3f51b5',   // Indigo
    foundation: '#212121'  // Noir
  };

  return colors[level] || '#999999';
}

/**
 * Combine plusieurs roadmaps en une seule visualisation "ligne de métro"
 * @param {Array} metroDataArray - Tableau de données au format "ligne de métro"
 * @returns {Object} - Données combinées
 */
function combineMetroData(metroDataArray) {
  // Créer un objet pour les données combinées
  const combinedData = {
    id: 'combined-metro-map',
    title: 'Architecture Cognitive Combinée',
    type: 'cosmos',
    status: 'in_progress',
    description: 'Visualisation combinée de toutes les roadmaps',
    metadata: {
      temporal: { horizon: 'long_term' },
      cognitive: { complexity: 'systemic' },
      organizational: { responsibility: 'organizational' },
      strategic: { priority: 'high' }
    },
    metroMap: {
      lines: [],
      stations: [],
      connections: []
    }
  };

  // Ensemble pour suivre les IDs uniques
  const lineIds = new Set();
  const stationIds = new Set();
  const connectionIds = new Set();

  // Combiner les données
  metroDataArray.forEach(data => {
    // Ajouter les lignes uniques
    data.metroMap.lines.forEach(line => {
      if (!lineIds.has(line.id)) {
        lineIds.add(line.id);
        combinedData.metroMap.lines.push(line);
      }
    });

    // Ajouter les stations uniques
    data.metroMap.stations.forEach(station => {
      if (!stationIds.has(station.id)) {
        stationIds.add(station.id);
        combinedData.metroMap.stations.push(station);
      }
    });

    // Ajouter les connexions uniques
    data.metroMap.connections.forEach(connection => {
      if (!connectionIds.has(connection.id)) {
        connectionIds.add(connection.id);
        combinedData.metroMap.connections.push(connection);
      }
    });
  });

  return combinedData;
}

/**
 * Fonction principale
 */
function main() {
  try {
    // Lire tous les fichiers JSON dans le répertoire d'entrée
    const files = fs.readdirSync(CONFIG.inputDir)
      .filter(file => file.endsWith('.json') && !file.includes('combined'));

    console.log(`Traitement de ${files.length} fichiers...`);

    const metroDataArray = [];

    // Traiter chaque fichier
    files.forEach(file => {
      const inputPath = path.join(CONFIG.inputDir, file);
      const outputPath = path.join(CONFIG.outputDir, file.replace('.json', '-metro.json'));

      try {
        // Lire les données
        const data = JSON.parse(fs.readFileSync(inputPath, 'utf8'));

        // Convertir au format "ligne de métro"
        const metroData = convertToMetroFormat(data);

        // Enregistrer les données converties
        fs.writeFileSync(outputPath, JSON.stringify(metroData, null, 2), 'utf8');
        console.log(`Fichier traité: ${file} -> ${path.basename(outputPath)}`);

        // Ajouter au tableau pour la combinaison
        metroDataArray.push(metroData);
      } catch (error) {
        console.error(`Erreur lors du traitement du fichier ${file}:`, error);
      }
    });

    // Combiner toutes les données
    if (metroDataArray.length > 0) {
      const combinedData = combineMetroData(metroDataArray);
      fs.writeFileSync(CONFIG.combinedOutputFile, JSON.stringify(combinedData, null, 2), 'utf8');
      console.log(`Données combinées enregistrées dans: ${path.basename(CONFIG.combinedOutputFile)}`);
    }

    console.log('Traitement terminé avec succès!');
  } catch (error) {
    console.error('Erreur lors du traitement:', error);
  }
}

// Exécuter la fonction principale
main();
