# Guide d'optimisation des Memories pour Augment Code

Ce guide explique comment optimiser les Memories d'Augment Code pour améliorer les performances et la pertinence des réponses.

## Introduction

Les Memories sont un mécanisme essentiel d'Augment Code qui permet de stocker des informations persistantes entre les sessions. Elles fournissent un contexte important pour l'assistant IA, lui permettant de mieux comprendre vos besoins et de fournir des réponses plus pertinentes.

Dans notre projet, nous avons mis en place un système d'optimisation des Memories qui organise les informations par catégories fonctionnelles et implémente un système de sélection contextuelle basé sur le mode actif.

## Principes d'optimisation

### 1. Organisation par catégories fonctionnelles

Les Memories sont organisées en catégories fonctionnelles pour faciliter leur accès et leur mise à jour :

- **PROJECT STRUCTURE** : Informations sur la structure du projet
- **DEVELOPMENT STANDARDS** : Standards de développement à respecter
- **ROADMAP & TESTING PRINCIPLES** : Principes de gestion de la roadmap et des tests
- **OPERATIONAL MODES** : Modes opérationnels disponibles
- **TOOLS & STACK** : Outils et technologies utilisés
- **USER PREFERENCES** : Préférences de l'utilisateur
- **MÉTHODO** : Méthodologie de développement
- **STANDARDS** : Standards de qualité
- **INPUT_OPTIM** : Optimisation des inputs
- **AUTONOMIE** : Autonomie de l'assistant
- **COMMUNICATION** : Style de communication

### 2. Sélection contextuelle basée sur le mode actif

Les Memories sont adaptées au mode actif pour fournir des informations plus pertinentes :

- En mode GRAN, les Memories incluent des informations spécifiques à la granularisation des tâches
- En mode DEV-R, les Memories incluent des informations spécifiques à l'implémentation des tâches
- etc.

### 3. Respect des limites de taille

Les Memories sont optimisées pour respecter les limites de taille d'Augment Code :

- Chaque section est concise et focalisée sur l'essentiel
- Les informations redondantes sont évitées
- Les exemples sont limités au minimum nécessaire

## Utilisation du script d'optimisation

Pour optimiser les Memories d'Augment Code, utilisez le script suivant :

```powershell
.\development\scripts\maintenance\augment\optimize-augment-memories.ps1 -Mode GRAN -OutputPath ".augment\memories\journal_memories.json"
```plaintext
### Paramètres

- `-Mode` : Mode actif pour lequel optimiser les Memories. Valeurs possibles : ARCHI, CHECK, C-BREAK, DEBUG, DEV-R, GRAN, OPTI, PREDIC, REVIEW, TEST, ALL. Par défaut : ALL.
- `-OutputPath` : Chemin du fichier de sortie pour les Memories optimisées. Par défaut, utilise le chemin des Memories d'Augment dans VS Code.
- `-ConfigPath` : Chemin vers le fichier de configuration. Par défaut : "development\config\unified-config.json".

### Exemples

#### Optimiser les Memories pour tous les modes

```powershell
.\development\scripts\maintenance\augment\optimize-augment-memories.ps1
```plaintext
#### Optimiser les Memories pour le mode GRAN

```powershell
.\development\scripts\maintenance\augment\optimize-augment-memories.ps1 -Mode GRAN
```plaintext
#### Optimiser les Memories et les enregistrer dans un fichier spécifique

```powershell
.\development\scripts\maintenance\augment\optimize-augment-memories.ps1 -OutputPath "C:\temp\augment_memories.json"
```plaintext
## Structure des Memories optimisées

Les Memories optimisées sont structurées en sections, chaque section ayant un nom et un contenu :

```json
{
  "version": "2.0.0",
  "lastUpdated": "2025-06-01T12:00:00.000Z",
  "sections": [
    {
      "name": "PROJECT STRUCTURE",
      "content": "..."
    },
    {
      "name": "DEVELOPMENT STANDARDS",
      "content": "..."
    },
    ...
  ]
}
```plaintext
### Sections communes

Les sections communes sont présentes dans toutes les Memories, quel que soit le mode actif :

- **PROJECT STRUCTURE** : Structure du projet
- **DEVELOPMENT STANDARDS** : Standards de développement
- **ROADMAP & TESTING PRINCIPLES** : Principes de gestion de la roadmap et des tests
- **OPERATIONAL MODES** : Modes opérationnels
- **TOOLS & STACK** : Outils et technologies
- **USER PREFERENCES** : Préférences de l'utilisateur

### Sections spécifiques aux modes

Les sections spécifiques aux modes sont présentes uniquement lorsque le mode correspondant est actif :

- **GRAN MODE** et **GRAN IMPLEMENTATION** : Informations spécifiques au mode GRAN
- **DEV-R MODE** et **DEV-R IMPLEMENTATION** : Informations spécifiques au mode DEV-R
- etc.

### Sections d'optimisation

Les sections d'optimisation sont présentes dans toutes les Memories et fournissent des directives pour optimiser les réponses d'Augment :

- **MÉTHODO** : Méthodologie de développement
- **STANDARDS** : Standards de qualité
- **INPUT_OPTIM** : Optimisation des inputs
- **AUTONOMIE** : Autonomie de l'assistant
- **COMMUNICATION** : Style de communication

## Intégration avec le gestionnaire de modes

Le script d'intégration pour le gestionnaire de modes met à jour automatiquement les Memories d'Augment avec les informations du mode actif :

```powershell
.\development\scripts\maintenance\augment\mode-manager-augment-integration.ps1 -Mode GRAN -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -UpdateMemories
```plaintext
Lorsque l'option `-UpdateMemories` est spécifiée, le script effectue les actions suivantes :
1. Exécute le mode spécifié
2. Génère les Memories optimisées pour ce mode
3. Met à jour les Memories d'Augment dans VS Code

## Bonnes pratiques

### 1. Mettre à jour les Memories après chaque changement de mode

Pour garantir que les Memories sont toujours à jour, mettez-les à jour après chaque changement de mode :

```powershell
.\development\scripts\maintenance\augment\mode-manager-augment-integration.ps1 -Mode <MODE> -UpdateMemories
```plaintext
### 2. Adapter les Memories à votre contexte actuel

Si vous travaillez sur une tâche spécifique, adaptez les Memories à votre contexte actuel :

```powershell
.\development\scripts\maintenance\augment\optimize-augment-memories.ps1 -Mode <MODE>
```plaintext
### 3. Éviter de surcharger les Memories

Les Memories ont une taille limitée. Évitez de les surcharger avec des informations non pertinentes :

- Supprimez les sections inutiles
- Limitez les exemples au minimum nécessaire
- Focalisez-vous sur les informations essentielles

### 4. Utiliser les Memories pour les informations persistantes

Utilisez les Memories pour les informations qui doivent persister entre les sessions :

- Standards de développement
- Préférences de l'utilisateur
- Structure du projet
- etc.

## Dépannage

### Les Memories ne sont pas mises à jour

Si les Memories ne sont pas mises à jour, vérifiez les points suivants :

- Le chemin vers les Memories est correct
- Le script d'optimisation des Memories est exécuté avec succès
- Le serveur MCP pour les Memories est démarré

### Les Memories sont trop volumineuses

Si les Memories sont trop volumineuses, vérifiez les points suivants :

- Supprimez les sections inutiles
- Limitez les exemples au minimum nécessaire
- Focalisez-vous sur les informations essentielles

### Les Memories ne sont pas pertinentes

Si les Memories ne sont pas pertinentes pour votre contexte actuel, vérifiez les points suivants :

- Utilisez le mode approprié
- Adaptez les Memories à votre contexte actuel
- Mettez à jour les Memories après chaque changement de contexte

## Ressources supplémentaires

- [Guide d'intégration avec Augment Code](./integration_guide.md)
- [Limitations d'Augment Code](./limitations.md)
- [Plans et Quotas d'Augment Code](./plans_and_quotas.md)
- [Documentation officielle d'Augment Code](https://docs.augment.dev)
