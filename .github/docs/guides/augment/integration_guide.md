# Guide d'intégration avec Augment Code

Ce guide explique comment intégrer efficacement Augment Code avec notre système de gestion de modes et de Memories.

## Introduction

Augment Code est un assistant IA basé sur Claude 3.7 Sonnet d'Anthropic, qui offre des capacités avancées pour assister les développeurs dans leurs tâches de programmation. Pour tirer le meilleur parti d'Augment Code dans notre projet, nous avons mis en place une intégration spécifique qui permet à Augment d'interagir directement avec notre système de gestion de modes et de Memories.

## Configuration initiale

Pour configurer l'intégration avec Augment Code, exécutez le script suivant :

```powershell
.\development\scripts\maintenance\augment\configure-augment-mcp.ps1 -StartServers
```

Ce script effectue les actions suivantes :
1. Crée les fichiers de configuration nécessaires dans le répertoire `.augment`
2. Configure les serveurs MCP (Model Context Protocol) pour l'intégration avec Augment
3. Optimise les Memories d'Augment selon nos besoins spécifiques
4. Démarre les serveurs MCP (si l'option `-StartServers` est spécifiée)

## Composants de l'intégration

### 1. Serveur MCP pour les Memories

Le serveur MCP pour les Memories permet à Augment d'accéder directement à nos Memories optimisées. Il expose les fonctionnalités suivantes :

- `getMemories` : Récupère les Memories actuelles
- `updateMemories` : Met à jour les Memories avec un nouveau contenu
- `splitInput` : Divise un input en segments pour respecter la limite de taille
- `exportToVSCode` : Exporte les Memories vers VS Code

Pour démarrer manuellement ce serveur :

```powershell
.\development\scripts\maintenance\augment\mcp-memories-server.ps1 -Port 7891
```

### 2. Adaptateur MCP pour le gestionnaire de modes

L'adaptateur MCP pour le gestionnaire de modes permet à Augment d'interagir directement avec notre système de gestion de modes. Il expose les fonctionnalités suivantes :

- `listModes` : Récupère la liste des modes disponibles
- `executeMode` : Exécute un mode spécifique
- `getModeConfig` : Récupère la configuration d'un mode
- `executeChain` : Exécute une chaîne de modes séquentiellement

Pour démarrer manuellement cet adaptateur :

```powershell
.\development\scripts\maintenance\augment\mcp-mode-manager-adapter.ps1 -Port 7892
```

### 3. Script d'intégration pour le gestionnaire de modes

Ce script permet d'exécuter un mode spécifique et de mettre à jour les Memories d'Augment avec les informations du mode :

```powershell
.\development\scripts\maintenance\augment\mode-manager-augment-integration.ps1 -Mode GRAN -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -UpdateMemories
```

### 4. Script d'optimisation des Memories

Ce script optimise les Memories d'Augment selon nos besoins spécifiques, en organisant les Memories par catégories fonctionnelles et en implémentant un système de sélection contextuelle des Memories basé sur le mode actif :

```powershell
.\development\scripts\maintenance\augment\optimize-augment-memories.ps1 -Mode GRAN -OutputPath ".augment\memories\journal_memories.json"
```

## Utilisation avec Augment Code

### Activation des modes via Augment

Pour activer un mode spécifique via Augment, vous pouvez utiliser les commandes suivantes :

```
Peux-tu activer le mode GRAN pour décomposer la tâche 1.2.3 dans le fichier docs/plans/plan-modes-stepup.md ?
```

Augment utilisera l'adaptateur MCP pour exécuter le mode GRAN et mettra à jour ses Memories en conséquence.

### Optimisation des inputs pour Augment

Pour respecter la limite de taille de 5KB par input, vous pouvez utiliser la fonction de segmentation :

```
Peux-tu diviser ce code en segments de moins de 5KB pour que je puisse te les envoyer ?
```

Augment utilisera le serveur MCP pour diviser l'input en segments de taille appropriée.

### Utilisation des Memories optimisées

Les Memories optimisées sont organisées par catégories fonctionnelles et adaptées au mode actif. Cela permet à Augment de fournir des réponses plus pertinentes et contextuelles.

## Modes disponibles

Voici la liste des modes disponibles et leur description :

| Mode | Description |
|------|-------------|
| ARCHI | Structurer, modéliser, anticiper les dépendances |
| CHECK | Vérifier l'état d'avancement des tâches |
| C-BREAK | Détecter et résoudre les dépendances circulaires |
| DEBUG | Isoler, comprendre, corriger les anomalies |
| DEV-R | Implémenter ce qui est dans la roadmap |
| GRAN | Décomposer les blocs complexes |
| OPTI | Réduire complexité, taille ou temps d'exécution |
| PREDIC | Anticiper performances, détecter anomalies, analyser tendances |
| REVIEW | Vérifier lisibilité, standards, documentation |
| TEST | Maximiser couverture et fiabilité |

## Bonnes pratiques

### 1. Respecter les limites de taille

Augment Code a une limite stricte de 5KB par input. Pour respecter cette limite :
- Utilisez la fonction de segmentation pour diviser les inputs volumineux
- Préférez envoyer des fichiers individuels plutôt que des répertoires entiers
- Utilisez des références à des fichiers existants plutôt que de copier-coller du code

### 2. Utiliser les modes appropriés

Chaque mode est conçu pour un objectif spécifique. Utilisez le mode approprié pour votre tâche :
- GRAN pour décomposer une tâche complexe
- DEV-R pour implémenter une tâche
- CHECK pour vérifier l'état d'avancement
- etc.

### 3. Optimiser les Memories

Les Memories sont essentielles pour fournir un contexte à Augment. Pour optimiser les Memories :
- Mettez à jour les Memories après chaque changement de mode
- Utilisez le script d'optimisation des Memories pour adapter les Memories à votre contexte actuel
- Évitez de surcharger les Memories avec des informations non pertinentes

## Dépannage

### Les serveurs MCP ne démarrent pas

Si les serveurs MCP ne démarrent pas, vérifiez les points suivants :
- Les ports 7891 et 7892 sont disponibles
- Les scripts sont exécutés avec les droits d'administrateur si nécessaire
- Les chemins vers les scripts sont corrects

### Augment ne reconnaît pas les commandes MCP

Si Augment ne reconnaît pas les commandes MCP, vérifiez les points suivants :
- Les serveurs MCP sont démarrés
- La configuration VS Code est correcte
- L'extension Augment est à jour

### Les Memories ne sont pas mises à jour

Si les Memories ne sont pas mises à jour, vérifiez les points suivants :
- Le chemin vers les Memories est correct
- Le script d'optimisation des Memories est exécuté avec succès
- Le serveur MCP pour les Memories est démarré

## Intégration avec le MCP Manager

Pour intégrer les serveurs MCP d'Augment avec le MCP Manager existant, exécutez le script suivant :

```powershell
.\development\scripts\maintenance\augment\integrate-with-mcp-manager.ps1
```

Ce script effectue les actions suivantes :
1. Met à jour le module MCPManager pour inclure les serveurs MCP d'Augment
2. Met à jour la configuration MCP globale
3. Met à jour le script de démarrage de tous les serveurs MCP

Après l'intégration, vous pouvez démarrer tous les serveurs MCP, y compris les serveurs MCP d'Augment, en utilisant le script de démarrage global :

```powershell
.\src\mcp\utils\scripts\start-all-mcp-servers.ps1
```

Pour plus d'informations sur l'intégration MCP, consultez le [Guide d'intégration MCP](./mcp_integration.md).

## Module PowerShell d'intégration

Pour faciliter l'utilisation de l'intégration avec Augment Code, nous avons développé un module PowerShell qui expose toutes les fonctionnalités nécessaires. Pour installer ce module, exécutez le script suivant :

```powershell
.\development\scripts\maintenance\augment\Install-AugmentIntegration.ps1
```

Une fois le module installé, vous pouvez l'utiliser dans n'importe quel script PowerShell :

```powershell
# Importer le module
Import-Module AugmentIntegration

# Initialiser l'intégration avec Augment Code
Initialize-AugmentIntegration -StartServers

# Exécuter un mode spécifique
Invoke-AugmentMode -Mode GRAN -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -UpdateMemories

# Mettre à jour les Memories pour un mode spécifique
Update-AugmentMemoriesForMode -Mode GRAN
```

Pour plus d'informations sur l'utilisation du module, consultez le [Guide d'utilisation avancée](./advanced_usage.md).

## Ressources supplémentaires

- [Limitations d'Augment Code](./limitations.md)
- [Optimisation des Memories](./memories_optimization.md)
- [Intégration MCP](./mcp_integration.md)
- [Utilisation avancée](./advanced_usage.md)
- [Documentation officielle d'Augment Code](https://docs.augment.dev)
