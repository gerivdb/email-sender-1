/**
 * Cosmos Data Converter
 * 
 * This module converts roadmap JSON data to the format expected by the cosmos visualization.
 */

const fs = require('fs');
const path = require('path');

/**
 * Convert a roadmap JSON file to cosmos visualization data
 * @param {string} jsonPath - Path to the roadmap JSON file
 * @param {string} outputPath - Path where the cosmos data should be saved
 * @param {object} options - Optional configuration
 */
function convertRoadmapToCosmosData(jsonPath, outputPath, options = {}) {
  try {
    // Read the roadmap JSON file
    const roadmapJson = fs.readFileSync(jsonPath, 'utf8');
    const roadmap = JSON.parse(roadmapJson);
    
    // Convert the roadmap to cosmos data
    const cosmosData = convertRoadmapObject(roadmap, options);
    
    // Save the cosmos data
    fs.writeFileSync(outputPath, JSON.stringify(cosmosData, null, 2), 'utf8');
    console.log(`Converted ${jsonPath} to cosmos data: ${outputPath}`);
  } catch (error) {
    console.error(`Error converting ${jsonPath} to cosmos data:`, error);
  }
}

/**
 * Convert a roadmap object to cosmos visualization data
 * @param {object} roadmap - The roadmap object
 * @param {object} options - Optional configuration
 * @returns {object} - The cosmos data
 */
function convertRoadmapObject(roadmap, options = {}) {
  // Default options
  const defaultOptions = {
    maxDepth: 10, // Maximum depth to include in the visualization
    includeCompleted: true, // Whether to include completed tasks
    includeCancelled: false, // Whether to include cancelled tasks
    maxNodesPerLevel: 50, // Maximum number of nodes to include per level
    priorityFilter: null, // Filter by priority (e.g., 'high', 'critical')
    dimensionFilters: {} // Filters for dimensions (e.g., { temporal: { horizon: 'short_term' } })
  };
  
  // Merge options with defaults
  const mergedOptions = { ...defaultOptions, ...options };
  
  // Function to convert a roadmap node to a cosmos node
  function convertNode(node, depth = 0) {
    // Skip nodes beyond the maximum depth
    if (depth > mergedOptions.maxDepth) {
      return null;
    }
    
    // Skip completed nodes if not included
    if (!mergedOptions.includeCompleted && node.status === 'completed') {
      return null;
    }
    
    // Skip cancelled nodes if not included
    if (!mergedOptions.includeCancelled && node.status === 'cancelled') {
      return null;
    }
    
    // Apply priority filter if specified
    if (mergedOptions.priorityFilter && 
        node.metadata && 
        node.metadata.strategic && 
        node.metadata.strategic.priority !== mergedOptions.priorityFilter) {
      return null;
    }
    
    // Apply dimension filters if specified
    for (const [dimension, filters] of Object.entries(mergedOptions.dimensionFilters)) {
      if (node.metadata && node.metadata[dimension]) {
        for (const [key, value] of Object.entries(filters)) {
          if (node.metadata[dimension][key] !== value) {
            return null;
          }
        }
      }
    }
    
    // Convert children
    const children = [];
    if (node.children && Array.isArray(node.children)) {
      // Sort children by priority (if available) or by title
      const sortedChildren = [...node.children].sort((a, b) => {
        // Sort by priority if available
        const priorityA = a.metadata?.strategic?.priority;
        const priorityB = b.metadata?.strategic?.priority;
        
        if (priorityA && priorityB) {
          const priorityMap = { 'critical': 0, 'high': 1, 'medium': 2, 'low': 3 };
          return (priorityMap[priorityA] || 999) - (priorityMap[priorityB] || 999);
        }
        
        // Fall back to sorting by title
        return (a.title || '').localeCompare(b.title || '');
      });
      
      // Limit the number of children per level
      const limitedChildren = sortedChildren.slice(0, mergedOptions.maxNodesPerLevel);
      
      // Convert each child
      for (const child of limitedChildren) {
        const convertedChild = convertNode(child, depth + 1);
        if (convertedChild) {
          children.push(convertedChild);
        }
      }
    }
    
    // Create the cosmos node
    return {
      id: node.id,
      title: node.title,
      type: node.type,
      status: node.status || 'planned',
      description: node.description,
      metadata: node.metadata || {
        temporal: {},
        cognitive: {},
        organizational: {},
        strategic: {}
      },
      children
    };
  }
  
  // Convert the root node
  return convertNode(roadmap);
}

/**
 * Generate a sample cosmos data file
 * @param {string} outputPath - Path where the sample data should be saved
 */
function generateSampleCosmosData(outputPath) {
  const sampleData = {
    id: 'root',
    title: 'Email Sender Cognitive Architecture',
    type: 'cosmos',
    status: 'in_progress',
    description: 'Représentation holistique de l\'écosystème complet du projet Email Sender',
    metadata: {
      temporal: { horizon: 'long_term' },
      cognitive: { complexity: 'systemic' },
      organizational: { responsibility: 'organizational' },
      strategic: { priority: 'high' }
    },
    children: [
      {
        id: 'galaxy-1',
        title: 'Automatisation des Processus',
        type: 'galaxy',
        status: 'in_progress',
        description: 'Branche stratégique couvrant tous les aspects d\'automatisation',
        metadata: {
          temporal: { horizon: 'medium_term' },
          strategic: { value: 'high' }
        },
        children: [
          {
            id: 'system-1',
            title: 'Backend Intelligent',
            type: 'stellar_system',
            status: 'in_progress',
            description: 'Système principal pour le traitement intelligent des emails',
            metadata: {
              cognitive: { complexity: 'complex' },
              organizational: { responsibility: 'team' }
            },
            children: [
              {
                id: 'planet-1',
                title: 'Module d\'Analyse Sémantique',
                type: 'planet',
                status: 'planned',
                description: 'Composant majeur pour l\'analyse sémantique des emails',
                metadata: {
                  cognitive: { complexity: 'complex' },
                  strategic: { value: 'high' }
                },
                children: []
              }
            ]
          }
        ]
      },
      {
        id: 'galaxy-2',
        title: 'Interface Utilisateur',
        type: 'galaxy',
        status: 'planned',
        description: 'Branche stratégique pour l\'expérience utilisateur',
        metadata: {
          temporal: { horizon: 'short_term' },
          strategic: { priority: 'medium' }
        },
        children: []
      }
    ]
  };
  
  fs.writeFileSync(outputPath, JSON.stringify(sampleData, null, 2), 'utf8');
  console.log(`Generated sample cosmos data: ${outputPath}`);
}

/**
 * Convert all roadmap JSON files in a directory to cosmos data
 * @param {string} jsonDir - Directory containing roadmap JSON files
 * @param {string} outputDir - Directory where cosmos data should be saved
 * @param {object} options - Optional configuration
 */
function convertAllRoadmapsToCosmosData(jsonDir, outputDir, options = {}) {
  try {
    // Ensure output directory exists
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }
    
    // Get all JSON files in the directory
    const files = fs.readdirSync(jsonDir)
      .filter(file => file.endsWith('.json'))
      .map(file => path.join(jsonDir, file));
    
    console.log(`Found ${files.length} JSON files in ${jsonDir}`);
    
    // Convert each file
    for (const file of files) {
      const baseName = path.basename(file, '.json');
      const outputPath = path.join(outputDir, `${baseName}-cosmos.json`);
      
      convertRoadmapToCosmosData(file, outputPath, options);
    }
    
    console.log(`Converted ${files.length} roadmap files to cosmos data`);
  } catch (error) {
    console.error(`Error converting roadmaps to cosmos data:`, error);
  }
}

module.exports = {
  convertRoadmapToCosmosData,
  convertRoadmapObject,
  generateSampleCosmosData,
  convertAllRoadmapsToCosmosData
};
