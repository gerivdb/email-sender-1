# Moteur de Layout Automatique pour Carte de Métro

Ce module fournit un moteur de layout automatique spécialisé pour les visualisations de type "carte de métro" des roadmaps. Il permet de positionner automatiquement les stations (tâches) et les lignes (roadmaps) de manière optimale pour une lisibilité maximale.

## Fonctionnalités

- **Layout automatique optimisé** pour les visualisations de type carte de métro
- **Algorithmes avancés** pour minimiser les croisements et optimiser l'esthétique
- **Personnalisation complète** des paramètres de layout
- **Intégration transparente** avec Cytoscape.js
- **Support pour les graphes complexes** avec multiples lignes et correspondances

## Architecture

Le moteur de layout est composé de plusieurs composants clés :

1. **Prétraitement du graphe** : Analyse et préparation des données pour le layout
2. **Ordonnancement topologique** : Détermination de l'ordre optimal des nœuds
3. **Assignation des rangs** : Positionnement sur l'axe principal (horizontal ou vertical)
4. **Minimisation des croisements** : Optimisation de l'ordre des nœuds sur l'axe secondaire
5. **Optimisation des positions** : Ajustement fin des positions pour un rendu esthétique
6. **Routage des arêtes** : Calcul des points de contrôle pour les courbes des arêtes

## Utilisation

### Installation

Aucune installation n'est nécessaire, il suffit d'importer le module dans votre projet :

```javascript
import MetroMapLayoutEngine from './MetroMapLayoutEngine.js';
```

### Utilisation basique

```javascript
// Créer une instance du moteur de layout
const layoutEngine = new MetroMapLayoutEngine({
  preferredDirection: 'horizontal',
  nodeSeparation: 50,
  rankSeparation: 100
});

// Appliquer le layout à un graphe
const layoutResult = layoutEngine.applyLayout(graph);

// Utiliser les positions calculées
layoutResult.nodes.forEach(node => {
  console.log(`Node ${node.id} at position (${node.position.x}, ${node.position.y})`);
});
```

### Format du graphe d'entrée

Le graphe d'entrée doit avoir la structure suivante :

```javascript
const graph = {
  nodes: [
    { id: 'A', name: 'Station A', lines: ['L1'] },
    { id: 'B', name: 'Station B', lines: ['L1', 'L2'] },
    // ...
  ],
  edges: [
    { source: 'A', target: 'B', line: 'L1' },
    // ...
  ],
  lines: [
    { id: 'L1', name: 'Ligne 1', color: '#FF6B6B' },
    { id: 'L2', name: 'Ligne 2', color: '#4ECDC4' },
    // ...
  ]
};
```

### Options de configuration

Le moteur de layout accepte les options suivantes :

| Option | Description | Valeur par défaut |
|--------|-------------|-------------------|
| `nodeSeparation` | Distance minimale entre les nœuds | 50 |
| `rankSeparation` | Distance entre les rangs | 100 |
| `edgeSeparation` | Distance minimale entre les arêtes | 50 |
| `padding` | Marge autour du graphe | 50 |
| `optimizationIterations` | Nombre d'itérations pour l'optimisation | 50 |
| `optimizationTemperature` | Température initiale pour le recuit simulé | 1.0 |
| `optimizationCooling` | Facteur de refroidissement | 0.95 |
| `preferredDirection` | Direction préférée ('horizontal' ou 'vertical') | 'horizontal' |
| `directionBias` | Biais pour la direction préférée (0-1) | 0.7 |
| `layoutAlgorithm` | Algorithme de layout ('metro', 'dagre', 'cose-bilkent', 'klay') | 'metro' |
| `metroLineSpacing` | Espacement entre les lignes parallèles | 30 |
| `metroStationRadius` | Rayon des stations | 15 |
| `metroJunctionRadius` | Rayon des jonctions | 20 |

## Intégration avec Cytoscape.js

Le moteur de layout peut être facilement intégré avec Cytoscape.js en utilisant la classe `MetroMapVisualizerEnhanced` :

```javascript
import MetroMapVisualizerEnhanced from './MetroMapVisualizerEnhanced.js';

// Initialiser le visualiseur
const visualizer = new MetroMapVisualizerEnhanced('container-id', {
  layoutOptions: {
    layoutAlgorithm: 'metro',
    preferredDirection: 'horizontal',
    nodeSeparation: 50,
    rankSeparation: 100
  }
});

// Initialiser et visualiser
await visualizer.initialize();
await visualizer.visualizeRoadmaps(['roadmap1', 'roadmap2']);
```

## Algorithmes

### Ordonnancement topologique

L'algorithme d'ordonnancement topologique est utilisé pour déterminer l'ordre optimal des nœuds sur l'axe principal. Il garantit que les nœuds sont placés de manière à ce que les arêtes aillent généralement dans la même direction.

### Minimisation des croisements

L'algorithme de minimisation des croisements utilise une approche heuristique basée sur le barycentre pour réduire le nombre de croisements entre les arêtes. Il calcule le barycentre des voisins de chaque nœud et les ordonne en conséquence.

### Optimisation des positions

L'algorithme d'optimisation des positions utilise une technique de recuit simulé pour ajuster finement les positions des nœuds. Il minimise une fonction d'énergie qui pénalise les nœuds trop proches et les arêtes trop longues.

### Routage des arêtes

L'algorithme de routage des arêtes calcule des points de contrôle pour les courbes de Bézier qui représentent les arêtes. Il prend en compte la direction préférée et ajuste les courbes pour éviter les croisements et les superpositions.

## Exemples

### Exemple 1 : Layout simple

```javascript
const graph = {
  nodes: [
    { id: 'A', name: 'Station A', lines: ['L1'] },
    { id: 'B', name: 'Station B', lines: ['L1'] },
    { id: 'C', name: 'Station C', lines: ['L1'] }
  ],
  edges: [
    { source: 'A', target: 'B', line: 'L1' },
    { source: 'B', target: 'C', line: 'L1' }
  ],
  lines: [
    { id: 'L1', name: 'Ligne 1', color: '#FF6B6B' }
  ]
};

const layoutEngine = new MetroMapLayoutEngine();
const result = layoutEngine.applyLayout(graph);
```

### Exemple 2 : Layout avec multiples lignes

```javascript
const graph = {
  nodes: [
    { id: 'A', name: 'Station A', lines: ['L1'] },
    { id: 'B', name: 'Station B', lines: ['L1', 'L2'] },
    { id: 'C', name: 'Station C', lines: ['L1'] },
    { id: 'D', name: 'Station D', lines: ['L2'] }
  ],
  edges: [
    { source: 'A', target: 'B', line: 'L1' },
    { source: 'B', target: 'C', line: 'L1' },
    { source: 'B', target: 'D', line: 'L2' }
  ],
  lines: [
    { id: 'L1', name: 'Ligne 1', color: '#FF6B6B' },
    { id: 'L2', name: 'Ligne 2', color: '#4ECDC4' }
  ]
};

const layoutEngine = new MetroMapLayoutEngine({
  preferredDirection: 'vertical'
});
const result = layoutEngine.applyLayout(graph);
```

## Démonstration

Une démonstration interactive est disponible dans le fichier `test-metro-layout.html`. Elle permet de tester différentes configurations de layout sur des graphes prédéfinis.

## Limitations actuelles

- Les graphes cycliques peuvent produire des résultats sous-optimaux
- Les performances peuvent se dégrader avec des graphes très grands (>1000 nœuds)
- L'optimisation des positions peut converger vers des minimums locaux

## Roadmap

- [ ] Amélioration de l'algorithme de minimisation des croisements
- [ ] Support pour les contraintes de positionnement
- [ ] Optimisation des performances pour les grands graphes
- [ ] Meilleure gestion des graphes cycliques
- [ ] Intégration avec d'autres bibliothèques de visualisation

## Licence

Ce module est distribué sous licence MIT.

## Auteur

EMAIL_SENDER_1 Team
