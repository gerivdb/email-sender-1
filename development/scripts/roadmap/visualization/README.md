# Visualisation des Roadmaps en Carte de Métro

Ce module permet de visualiser les roadmaps sous forme de carte de métro, en mettant en évidence les interconnexions entre différentes roadmaps. Il s'intègre avec Qdrant pour stocker et récupérer les données des roadmaps.

## Fonctionnalités

- Visualisation des roadmaps sous forme de carte de métro
- Mise en évidence des nœuds communs entre différentes roadmaps
- Détection des conflits potentiels (dépendances ou statuts incohérents)
- Création, modification et suppression de roadmaps
- Interface d'administration pour gérer les roadmaps

## Prérequis

- Serveur Qdrant en cours d'exécution (par défaut sur `http://localhost:6333`)
- Navigateur web moderne avec support de JavaScript ES6+
- Python 3.6+ (pour le script d'initialisation)

## Installation

1. Assurez-vous que Qdrant est installé et en cours d'exécution. Si ce n'est pas le cas, vous pouvez l'installer avec Docker :

```bash
docker run -p 6333:6333 -p 6334:6334 -v $(pwd)/qdrant_storage:/qdrant/storage qdrant/qdrant
```plaintext
2. Installez les dépendances Python pour le script d'initialisation :

```bash
pip install qdrant-client numpy
```plaintext
3. Initialisez la collection Qdrant avec des données de test :

```bash
python init_qdrant.py
```plaintext
## Utilisation

1. Ouvrez le fichier `index.html` dans un navigateur web.

2. Sélectionnez une ou plusieurs roadmaps dans la liste déroulante.

3. Cliquez sur le bouton "Visualiser" pour afficher les roadmaps sous forme de carte de métro.

4. Utilisez les fonctionnalités suivantes :
   - Zoom et déplacement dans la carte
   - Double-clic sur un nœud pour afficher ses détails
   - Survol d'un nœud pour afficher une infobulle
   - Détection des conflits entre roadmaps
   - Création de nouvelles roadmaps

## Structure du code

- `MetroMapVisualizer.js` : Classe principale pour la visualisation des roadmaps
- `index.html` : Interface utilisateur pour la visualisation
- `init_qdrant.py` : Script pour initialiser la collection Qdrant avec des données de test

## Intégration avec Qdrant

Le visualiseur utilise Qdrant comme base de données vectorielle pour stocker et récupérer les données des roadmaps. Chaque roadmap est représentée par un point dans Qdrant, avec un embedding vectoriel et des métadonnées (titre, description, tâches, etc.).

### Structure des données dans Qdrant

Chaque point dans la collection `roadmaps` a la structure suivante :

```json
{
  "id": "roadmap_1",
  "vector": [...],  // Embedding vectoriel
  "payload": {
    "title": "Titre de la roadmap",
    "description": "Description de la roadmap",
    "tasks": [
      {
        "id": "task_1",
        "title": "Titre de la tâche",
        "description": "Description de la tâche",
        "status": "Statut de la tâche",
        "dependencies": ["task_2", "task_3"]
      },
      ...
    ]
  }
}
```plaintext
## Personnalisation

Vous pouvez personnaliser l'apparence et le comportement du visualiseur en modifiant les options dans le constructeur de la classe `MetroMapVisualizer` :

```javascript
const visualizer = new MetroMapVisualizer('metro-map', {
  qdrantUrl: 'http://localhost:6333',
  qdrantCollection: 'roadmaps',
  nodeSize: 30,
  lineWidth: 4,
  metroColors: ['#FF6B6B', '#4ECDC4', '#45B7D1', ...]

});
```plaintext
## Intégration avec l'infrastructure existante

Ce module s'intègre parfaitement avec l'infrastructure existante :

1. **Intégration avec Qdrant** : Utilise la même instance Qdrant que le système RAG existant.

2. **Compatibilité avec les roadmaps existantes** : Le format de données est compatible avec les roadmaps existantes.

3. **Interface utilisateur cohérente** : Le style visuel est cohérent avec l'interface existante.

## Fonctionnalités avancées

### Détection des nœuds communs

Le visualiseur identifie automatiquement les nœuds communs entre différentes roadmaps en comparant les titres et descriptions des tâches. Les nœuds communs sont mis en évidence dans la visualisation et listés dans le panneau d'informations.

### Détection des conflits

Le visualiseur peut détecter deux types de conflits entre les roadmaps :

1. **Conflits de dépendances** : Lorsque la même tâche a des dépendances différentes dans différentes roadmaps.

2. **Conflits de statut** : Lorsque la même tâche a des statuts différents dans différentes roadmaps.

Les conflits détectés sont mis en évidence dans la visualisation et listés dans le panneau d'informations.

### Création et modification de roadmaps

L'interface permet de créer de nouvelles roadmaps et de modifier les roadmaps existantes. Les modifications sont immédiatement reflétées dans la visualisation.

## Exemples d'utilisation

### Visualisation de plusieurs roadmaps

```javascript
// Sélectionner plusieurs roadmaps
const roadmapIds = ['roadmap_1', 'roadmap_2', 'roadmap_3'];

// Visualiser les roadmaps sélectionnées
visualizer.visualizeRoadmaps(roadmapIds);
```plaintext
### Création d'une nouvelle roadmap

```javascript
// Créer une nouvelle roadmap
const newRoadmap = {
  title: "Nouvelle Roadmap",
  description: "Description de la nouvelle roadmap",
  tasks: [
    {
      id: "task_1",
      title: "Première tâche",
      description: "Description de la première tâche",
      status: "À faire",
      dependencies: []
    },
    {
      id: "task_2",
      title: "Deuxième tâche",
      description: "Description de la deuxième tâche",
      status: "À faire",
      dependencies: ["task_1"]
    }
  ]
};

// Ajouter la roadmap à Qdrant
visualizer.createRoadmap(newRoadmap);
```plaintext
## Limitations actuelles et améliorations futures

- **Performance** : La visualisation peut devenir lente avec un grand nombre de roadmaps et de tâches.
- **Édition visuelle** : L'édition directe des roadmaps dans la visualisation n'est pas encore implémentée.
- **Exportation** : L'exportation des roadmaps au format image ou PDF n'est pas encore disponible.
- **Filtrage** : Le filtrage des tâches par statut, priorité, etc. n'est pas encore implémenté.
- **Historique** : Le suivi des modifications des roadmaps n'est pas encore disponible.

## Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request pour proposer des améliorations.

## Licence

Ce projet est sous licence MIT.
