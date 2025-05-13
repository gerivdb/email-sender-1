# Plan d'intégration Hygen-Roadmapper
*Version 1.0 - 2025-05-14*

Ce document détaille l'intégration entre Hygen (générateur de templates), le roadmapper (visualiseur de roadmaps) et Qdrant (base de données vectorielle pour RAG), dans le cadre du plan de développement v14.

## 1. Vue d'ensemble

### 1.1 Composants principaux

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    Hygen    │────▶│  Templates  │────▶│    Code     │
└─────────────┘     └─────────────┘     └─────────────┘
       ▲                                        │
       │                                        │
       │                                        ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Roadmapper │◀───▶│   Qdrant    │◀────│    PRDs     │
└─────────────┘     └─────────────┘     └─────────────┘
       ▲                  ▲                   ▲
       │                  │                   │
       └──────────────────┴───────────────────┘
                          │
                    ┌─────────────┐
                    │    Tâches   │
                    └─────────────┘
```

### 1.2 Flux de travail

1. Les PRD sont créés et stockés dans `/projet/guides/prd/`
2. Les PRD sont indexés dans Qdrant pour la recherche sémantique
3. Les PRD sont décomposés en tâches stockées dans `/projet/tasks/`
4. Les tâches sont visualisées via le roadmapper
5. Hygen génère des templates de code, tests et documentation
6. Le code implémenté est lié aux tâches et PRD correspondants

## 2. Configuration de Hygen

### 2.1 Structure des templates

```
_templates/
├── module/
│   ├── new/
│   │   ├── index.js          # Logique de génération
│   │   ├── module.ejs.t      # Template de module PowerShell
│   │   ├── test.ejs.t        # Template de test unitaire
│   │   └── readme.ejs.t      # Template de documentation
│   └── with-state/
│       ├── index.js
│       └── module-state.ejs.t
├── test/
│   └── new/
│       ├── index.js
│       └── test.ejs.t
├── prd/
│   └── new/
│       ├── index.js
│       └── prd.ejs.t
└── task/
    └── new/
        ├── index.js
        └── task.ejs.t
```

### 2.2 Commandes Hygen

```bash
# Générer un nouveau module PowerShell
hygen module new --name MonModule --description "Description du module"

# Générer un module avec gestion d'état
hygen module with-state --name MonModule --description "Description du module"

# Générer un test unitaire
hygen test new --name MonTest --module MonModule

# Générer un PRD
hygen prd new --name "Nom du PRD" --description "Description du PRD"

# Générer une tâche
hygen task new --name "Nom de la tâche" --prd "Nom du PRD" --priority high
```

### 2.3 Intégration avec le workflow de développement

1. Création du PRD avec Hygen: `hygen prd new`
2. Décomposition en tâches avec Hygen: `hygen task new`
3. Implémentation avec templates Hygen: `hygen module new`
4. Tests avec templates Hygen: `hygen test new`

## 3. Indexation dans Qdrant

### 3.1 Structure des collections Qdrant

```
qdrant/
├── prds/         # Collection des PRD
├── tasks/        # Collection des tâches
├── roadmaps/     # Collection des roadmaps
└── code/         # Collection des modules de code
```

### 3.2 Schéma des points pour les PRD

```json
{
  "id": "prd-123",
  "payload": {
    "title": "Titre du PRD",
    "description": "Description du PRD",
    "sections": ["introduction", "user_stories", "specifications"],
    "path": "/projet/guides/prd/nom_du_prd.md",
    "created_at": "2025-05-14T10:00:00Z",
    "updated_at": "2025-05-14T10:00:00Z",
    "status": "active",
    "tags": ["module", "prediction", "v14"]
  },
  "vector": [0.1, 0.2, 0.3, ...]
}
```

### 3.3 Schéma des points pour les tâches

```json
{
  "id": "task-456",
  "payload": {
    "title": "Titre de la tâche",
    "description": "Description de la tâche",
    "prd_id": "prd-123",
    "path": "/projet/tasks/task_456.md",
    "status": "pending",
    "priority": "high",
    "estimated_hours": 4,
    "dependencies": ["task-123", "task-234"],
    "roadmap_id": "v14-5.1.2",
    "created_at": "2025-05-14T10:00:00Z",
    "updated_at": "2025-05-14T10:00:00Z"
  },
  "vector": [0.4, 0.5, 0.6, ...]
}
```

### 3.4 Processus d'indexation

1. **Extraction** : Lecture des fichiers Markdown (PRD, tâches, roadmaps)
2. **Transformation** : Conversion en format structuré
3. **Vectorisation** : Génération des embeddings avec un modèle approprié
4. **Indexation** : Stockage dans Qdrant avec métadonnées
5. **Mise à jour** : Détection des changements et mise à jour incrémentale

## 4. Extension du roadmapper

### 4.1 Nouvelles fonctionnalités

1. **Visualisation des dépendances** :
   - Graphe de dépendances entre tâches
   - Chemin critique pour l'implémentation
   - Regroupement par PRD

2. **Filtres avancés** :
   - Par statut (pending, in-progress, done)
   - Par priorité (high, medium, low)
   - Par type (module, test, documentation)
   - Par roadmap (v14, v13, etc.)

3. **Intégration avec Hygen** :
   - Bouton "Générer template" pour chaque tâche
   - Sélection du type de template à générer
   - Pré-remplissage des paramètres basé sur la tâche

### 4.2 Interface utilisateur

```
┌─────────────────────────────────────────────────────────┐
│ Roadmapper v2.0                                [Search] │
├─────────────┬───────────────────┬───────────────────────┤
│             │                   │                       │
│  Roadmaps   │     Tâches        │      Détails          │
│             │                   │                       │
│ ▶ v13       │ □ 5.1.1.1         │ Titre: Install Hygen  │
│ ▼ v14       │ □ 5.1.1.2         │ Priorité: High        │
│   ▶ 1.x     │ □ 5.1.1.3         │ Statut: Pending       │
│   ▶ 2.x     │ ■ 5.1.2.1         │ Estimation: 2h        │
│   ▶ 3.x     │ □ 5.1.2.2         │ Dépendances:          │
│   ▶ 4.x     │ □ 5.1.2.3         │  - 5.1.1.1            │
│   ▼ 5.x     │ □ 5.1.3.1         │  - 5.1.1.2            │
│     ▼ 5.1   │ □ 5.1.3.2         │                       │
│       ▶ ... │ □ 5.1.3.3         │ [Générer Template]    │
│             │                   │ [Voir PRD]            │
│             │                   │ [Éditer Tâche]        │
│             │                   │                       │
└─────────────┴───────────────────┴───────────────────────┘
```

### 4.3 API pour l'intégration

```javascript
// Exemple d'API pour l'intégration Roadmapper-Hygen
const roadmapperAPI = {
  // Récupérer les détails d'une tâche
  getTaskDetails: async (taskId) => {
    // Requête à Qdrant pour obtenir les détails
    return taskDetails;
  },
  
  // Générer un template avec Hygen
  generateTemplate: async (taskId, templateType) => {
    const task = await getTaskDetails(taskId);
    // Appel à Hygen avec les paramètres appropriés
    return { success: true, output: "..." };
  },
  
  // Mettre à jour le statut d'une tâche
  updateTaskStatus: async (taskId, status) => {
    // Mise à jour dans Qdrant
    return { success: true };
  }
};
```

## 5. Plan d'implémentation

### 5.1 Phase 1: Configuration de base

1. Installer Hygen et créer la structure de templates
2. Configurer Qdrant avec les collections nécessaires
3. Développer les scripts d'indexation de base

### 5.2 Phase 2: Développement des templates

1. Créer les templates Hygen pour les modules PowerShell
2. Développer les templates pour les tests
3. Implémenter les templates pour la documentation et les PRD

### 5.3 Phase 3: Extension du roadmapper

1. Ajouter le support des nouvelles catégories de tâches
2. Implémenter la visualisation des dépendances
3. Intégrer les fonctionnalités de recherche avancée

### 5.4 Phase 4: Intégration complète

1. Développer l'API d'intégration Roadmapper-Hygen
2. Implémenter l'interface utilisateur pour la génération de templates
3. Créer le système de mise à jour automatique des index Qdrant

## 6. Exemples d'utilisation

### 6.1 Création d'un nouveau module via le roadmapper

1. Sélectionner la tâche "5.1.2.1" dans le roadmapper
2. Cliquer sur "Générer Template"
3. Sélectionner "Module PowerShell"
4. Remplir les paramètres supplémentaires
5. Générer le template avec Hygen
6. Implémenter le code dans le template généré
7. Mettre à jour le statut de la tâche

### 6.2 Recherche de tâches similaires

1. Sélectionner une tâche existante
2. Utiliser la fonction "Rechercher similaires"
3. Qdrant retourne les tâches sémantiquement proches
4. Consulter les tâches similaires pour s'inspirer des solutions existantes

## 7. Conclusion

L'intégration de Hygen avec le roadmapper et Qdrant permettra d'optimiser significativement le workflow de développement en:

1. Standardisant la création de code, tests et documentation
2. Facilitant la visualisation et le suivi des tâches
3. Améliorant la recherche et la réutilisation des connaissances
4. Automatisant les tâches répétitives

Cette intégration est essentielle pour la mise en œuvre efficace du plan de développement v14 et l'amélioration continue des pratiques de développement avec Augment/Claude.
