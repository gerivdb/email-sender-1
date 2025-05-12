/**
 * Generate Example Cognitive Roadmap
 * 
 * This script generates an example cognitive roadmap
 * demonstrating all levels and dimensions.
 */

const fs = require('fs');
const path = require('path');
const hierarchyDefinitions = require('../models/hierarchy-definitions.json');
const dimensionDefinitions = require('../models/dimension-definitions.json');

// Configuration
const outputPath = path.join(__dirname, '../examples/example-cognitive-roadmap.md');

// Ensure examples directory exists
const examplesDir = path.dirname(outputPath);
if (!fs.existsSync(examplesDir)) {
  fs.mkdirSync(examplesDir, { recursive: true });
}

/**
 * Generate an example roadmap in Markdown format
 * @returns {string} The generated Markdown
 */
function generateExampleRoadmap() {
  let markdown = '';
  
  // Level 1: COSMOS (Méta-roadmap)
  const cosmos = hierarchyDefinitions.levels.find(l => l.level === 1);
  markdown += `${cosmos.markdown_representation.prefix}Email Sender Cognitive Architecture [${cosmos.name}]\n\n`;
  markdown += `> Représentation holistique de l'écosystème complet du projet Email Sender,\n`;
  markdown += `> intégrant tous les domaines, temporalités et dimensions stratégiques.\n\n`;
  markdown += `**${dimensionDefinitions.dimensions[0].name}**: Horizon: Long terme, Rythme: Planifié, Séquence: Début\n`;
  markdown += `**${dimensionDefinitions.dimensions[1].name}**: Complexité: Systémique, Abstraction: Conceptuelle\n`;
  markdown += `**${dimensionDefinitions.dimensions[2].name}**: Responsabilité: Organisationnelle, Compétences: [Techniques, Analytiques, Créatives]\n`;
  markdown += `**${dimensionDefinitions.dimensions[3].name}**: Valeur: Critique, Risque: Moyen, Priorité: Critique\n\n`;
  
  // Level 2: GALAXIES (Branches stratégiques)
  const galaxy = hierarchyDefinitions.levels.find(l => l.level === 2);
  markdown += `${galaxy.markdown_representation.prefix}Automatisation des Processus [${galaxy.name}]\n\n`;
  markdown += `> Branche stratégique couvrant tous les aspects d'automatisation\n`;
  markdown += `> des processus d'envoi d'emails et de gestion des réponses.\n\n`;
  markdown += `**${dimensionDefinitions.dimensions[0].name}**: Horizon: Moyen terme, Rythme: Itératif\n`;
  markdown += `**${dimensionDefinitions.dimensions[3].name}**: Valeur: Élevée, Priorité: Élevée\n\n`;
  
  // Level 3: SYSTÈMES STELLAIRES (Main roadmaps)
  const system = hierarchyDefinitions.levels.find(l => l.level === 3);
  markdown += `${system.markdown_representation.prefix}Backend Intelligent [${system.name}]\n\n`;
  markdown += `> Système principal pour le traitement intelligent des emails,\n`;
  markdown += `> incluant l'analyse, la personnalisation et l'automatisation.\n\n`;
  markdown += `**${dimensionDefinitions.dimensions[1].name}**: Complexité: Complexe, Abstraction: Architecturale\n`;
  markdown += `**${dimensionDefinitions.dimensions[2].name}**: Responsabilité: Équipe, Collaboration: Coordonnée\n\n`;
  
  // Level 4: PLANÈTES (Mid-roadmaps)
  const planet = hierarchyDefinitions.levels.find(l => l.level === 4);
  markdown += `${planet.markdown_representation.prefix}Module d'Analyse Sémantique [${planet.name}]\n\n`;
  markdown += `> Composant majeur pour l'analyse sémantique des emails\n`;
  markdown += `> et l'extraction d'informations pertinentes.\n\n`;
  markdown += `**${dimensionDefinitions.dimensions[1].name}**: Complexité: Complexe, Abstraction: Fonctionnelle\n`;
  markdown += `**${dimensionDefinitions.dimensions[3].name}**: Valeur: Élevée, Risque: Moyen\n\n`;
  
  // Level 5: CONTINENTS (Mini-roadmaps)
  const continent = hierarchyDefinitions.levels.find(l => l.level === 5);
  markdown += `${continent.markdown_representation.prefix}Système de Classification [${continent.name}]\n\n`;
  markdown += `> Fonctionnalité de classification automatique des emails\n`;
  markdown += `> basée sur leur contenu et leur contexte.\n\n`;
  markdown += `**${dimensionDefinitions.dimensions[0].name}**: Horizon: Court terme, Séquence: Milieu\n`;
  markdown += `**${dimensionDefinitions.dimensions[2].name}**: Compétences: [Techniques, Analytiques]\n\n`;
  
  // Level 6: RÉGIONS (Sections)
  const region = hierarchyDefinitions.levels.find(l => l.level === 6);
  markdown += `${region.markdown_representation.prefix}Algorithmes de Classification [${region.name}]\n\n`;
  markdown += `> Ensemble des algorithmes utilisés pour la classification des emails.\n\n`;
  
  // Level 7: LOCALITÉS (Tâches)
  const locality = hierarchyDefinitions.levels.find(l => l.level === 7);
  markdown += `- [ ] **task-001** Implémenter l'algorithme de classification par mots-clés #priority:high #complexity:moderate\n`;
  markdown += `  > Développer l'algorithme de base pour la classification par mots-clés.\n`;
  markdown += `  > \n`;
  markdown += `  > **${dimensionDefinitions.dimensions[0].name}**: Horizon: Court terme, Séquence: Début\n`;
  markdown += `  > **${dimensionDefinitions.dimensions[1].name}**: Complexité: Modérée, Abstraction: Fonctionnelle\n\n`;
  
  // Level 8: QUARTIERS (Sous-tâches)
  const district = hierarchyDefinitions.levels.find(l => l.level === 8);
  markdown += `  - [ ] **subtask-001** Définir la structure de données pour les mots-clés\n`;
  markdown += `    > Concevoir la structure de données optimale pour stocker et rechercher les mots-clés.\n`;
  markdown += `    > \n`;
  markdown += `    > **${dimensionDefinitions.dimensions[1].name}**: Complexité: Simple, Abstraction: Technique\n\n`;
  
  // Level 9: BÂTIMENTS (Micro-tâches)
  const building = hierarchyDefinitions.levels.find(l => l.level === 9);
  markdown += `    - [ ] **micro-001** Créer la classe KeywordRepository\n`;
  markdown += `      > Implémenter la classe qui gère le stockage et la recherche des mots-clés.\n`;
  markdown += `      > \n`;
  markdown += `      > **${dimensionDefinitions.dimensions[2].name}**: Responsabilité: Individuelle\n\n`;
  
  // Level 10: FONDATIONS (Principes d'implémentation)
  const foundation = hierarchyDefinitions.levels.find(l => l.level === 10);
  markdown += `      - [ ] **P.1** Optimiser pour la recherche rapide\n`;
  markdown += `        > Utiliser des structures de données optimisées pour la recherche rapide.\n\n`;
  
  // Add another task with different status
  markdown += `- [~] **task-002** Implémenter l'algorithme de classification par embeddings #priority:high #complexity:complex\n`;
  markdown += `  > Développer l'algorithme avancé utilisant des embeddings vectoriels.\n`;
  markdown += `  > \n`;
  markdown += `  > **${dimensionDefinitions.dimensions[0].name}**: Horizon: Court terme, Séquence: Milieu\n`;
  markdown += `  > **${dimensionDefinitions.dimensions[1].name}**: Complexité: Complexe, Abstraction: Fonctionnelle\n`;
  markdown += `  > **${dimensionDefinitions.dimensions[3].name}**: Valeur: Élevée, Risque: Élevé\n\n`;
  
  markdown += `  - [x] **subtask-002** Rechercher les modèles d'embeddings appropriés\n`;
  markdown += `    > Évaluer différents modèles d'embeddings pour trouver le plus adapté.\n\n`;
  
  markdown += `  - [ ] **subtask-003** Implémenter l'intégration avec le modèle d'embeddings\n`;
  markdown += `    > Développer le code d'intégration avec le modèle d'embeddings sélectionné.\n\n`;
  
  // Add another section
  markdown += `${region.markdown_representation.prefix}Évaluation et Métriques [${region.name}]\n\n`;
  markdown += `> Méthodes et outils pour évaluer la performance des algorithmes de classification.\n\n`;
  
  markdown += `- [ ] **task-003** Définir les métriques d'évaluation #priority:medium\n`;
  markdown += `  > Identifier et définir les métriques pertinentes pour évaluer la performance.\n`;
  markdown += `  > \n`;
  markdown += `  > **${dimensionDefinitions.dimensions[1].name}**: Complexité: Modérée, Abstraction: Conceptuelle\n\n`;
  
  markdown += `- [ ] **task-004** Implémenter le système d'évaluation automatique #priority:medium\n`;
  markdown += `  > Développer un système pour évaluer automatiquement les performances.\n`;
  markdown += `  > \n`;
  markdown += `  > **${dimensionDefinitions.dimensions[0].name}**: Horizon: Court terme, Séquence: Fin\n\n`;
  
  return markdown;
}

// Generate and save the example roadmap
const exampleRoadmap = generateExampleRoadmap();
fs.writeFileSync(outputPath, exampleRoadmap, 'utf8');

console.log(`Generated example cognitive roadmap: ${outputPath}`);

// Also generate a JSON version
const converter = require('./cognitive-converter');
const jsonPath = outputPath.replace('.md', '.json');
converter.convertMarkdownFileToJson(outputPath, jsonPath);

console.log(`Generated JSON version: ${jsonPath}`);
