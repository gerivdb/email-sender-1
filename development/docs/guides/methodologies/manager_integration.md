# Guide d'intégration des gestionnaires

## Introduction

Ce guide explique comment intégrer les différents gestionnaires du système avec le gestionnaire de processus (Process Manager). L'intégration permet une gestion centralisée et standardisée de tous les gestionnaires, facilitant leur utilisation et leur maintenance.

## Objectif

L'objectif de l'intégration des gestionnaires est de :

- Fournir une interface unifiée pour tous les gestionnaires
- Standardiser les interactions entre les gestionnaires
- Faciliter la découverte et l'utilisation des gestionnaires
- Centraliser la configuration et la journalisation
- Améliorer la maintenance et l'évolutivité du système

## Architecture

### Structure des adaptateurs

Chaque gestionnaire est intégré au Process Manager via un adaptateur dédié. Les adaptateurs sont organisés selon la structure suivante :

```
development/managers/process-manager/
├── adapters/
│   ├── mode-manager-adapter.ps1
│   ├── roadmap-manager-adapter.ps1
│   ├── integrated-manager-adapter.ps1
│   ├── script-manager-adapter.ps1
│   └── error-manager-adapter.ps1
└── scripts/
    ├── process-manager.ps1
    └── integrate-managers.ps1
```

### Fonctionnement des adaptateurs

Les adaptateurs agissent comme des ponts entre le Process Manager et les gestionnaires spécifiques. Ils :

1. Traduisent les commandes standardisées du Process Manager en commandes spécifiques au gestionnaire
2. Gèrent les paramètres et les options spécifiques à chaque gestionnaire
3. Assurent la compatibilité entre les différentes versions des gestionnaires
4. Fournissent une gestion des erreurs cohérente

## Gestionnaires intégrés

### Mode Manager

Le Mode Manager est responsable de la gestion des modes opérationnels du système. Son adaptateur expose les fonctionnalités suivantes :

- **GetMode** : Obtient le mode actuel
- **SetMode** : Définit le mode actuel
- **ListModes** : Liste tous les modes disponibles
- **GetModeInfo** : Obtient des informations sur un mode spécifique

Exemple d'utilisation via le Process Manager :

```powershell
.\process-manager.ps1 -Command Run -ManagerName "ModeManager" -ManagerCommand "SetMode" -Mode "CHECK"
```

### Roadmap Manager

Le Roadmap Manager est responsable de la gestion des roadmaps et des tâches. Son adaptateur expose les fonctionnalités suivantes :

- **ParseRoadmap** : Analyse une roadmap
- **GetTaskInfo** : Obtient des informations sur une tâche spécifique
- **UpdateTaskStatus** : Met à jour le statut d'une tâche
- **GenerateReport** : Génère un rapport sur la roadmap

Exemple d'utilisation via le Process Manager :

```powershell
.\process-manager.ps1 -Command Run -ManagerName "RoadmapManager" -ManagerCommand "ParseRoadmap" -FilePath "projet/roadmaps/roadmap_complete_converted.md"
```

### Integrated Manager

L'Integrated Manager est responsable de l'intégration avec les systèmes externes. Son adaptateur expose les fonctionnalités suivantes :

- **ExecuteWorkflow** : Exécute un workflow intégré
- **GetStatus** : Obtient le statut d'un workflow
- **ListWorkflows** : Liste tous les workflows disponibles
- **GetWorkflowInfo** : Obtient des informations sur un workflow spécifique

Exemple d'utilisation via le Process Manager :

```powershell
.\process-manager.ps1 -Command Run -ManagerName "IntegratedManager" -ManagerCommand "ExecuteWorkflow" -WorkflowName "ProcessEmail"
```

### Script Manager

Le Script Manager est responsable de la gestion des scripts. Son adaptateur expose les fonctionnalités suivantes :

- **ExecuteScript** : Exécute un script
- **ListScripts** : Liste tous les scripts disponibles
- **GetScriptInfo** : Obtient des informations sur un script spécifique
- **OrganizeScripts** : Organise les scripts dans le répertoire approprié

Exemple d'utilisation via le Process Manager :

```powershell
.\process-manager.ps1 -Command Run -ManagerName "ScriptManager" -ManagerCommand "ExecuteScript" -ScriptName "update-roadmap-checkboxes.ps1" -RoadmapPath "projet/roadmaps/roadmap_complete_converted.md" -Force
```

### Error Manager

L'Error Manager est responsable de la gestion des erreurs. Son adaptateur expose les fonctionnalités suivantes :

- **LogError** : Enregistre une erreur
- **GetErrors** : Obtient les erreurs enregistrées
- **ClearErrors** : Efface les erreurs enregistrées
- **AnalyzeErrors** : Analyse les erreurs enregistrées

Exemple d'utilisation via le Process Manager :

```powershell
.\process-manager.ps1 -Command Run -ManagerName "ErrorManager" -ManagerCommand "LogError" -ErrorMessage "Une erreur est survenue" -ErrorSource "Process Manager" -ErrorCode "PM001"
```

## Installation et configuration

### Installation automatique

Pour installer et intégrer tous les gestionnaires, utilisez le script d'intégration :

```powershell
.\development\managers\process-manager\scripts\integrate-managers.ps1
```

Ce script :
1. Découvre automatiquement les gestionnaires disponibles
2. Enregistre chaque gestionnaire avec le Process Manager
3. Configure les adaptateurs appropriés
4. Vérifie que l'intégration est fonctionnelle

### Installation manuelle

Si vous préférez une installation manuelle, suivez ces étapes pour chaque gestionnaire :

1. Enregistrez le gestionnaire avec le Process Manager :

```powershell
.\process-manager.ps1 -Command Register -ManagerName "NomDuGestionnaire" -ManagerPath "chemin/vers/le/gestionnaire.ps1"
```

2. Vérifiez que le gestionnaire est correctement enregistré :

```powershell
.\process-manager.ps1 -Command List
```

3. Testez l'intégration en exécutant une commande sur le gestionnaire :

```powershell
.\process-manager.ps1 -Command Run -ManagerName "NomDuGestionnaire" -ManagerCommand "CommandeDuGestionnaire"
```

## Développement de nouveaux adaptateurs

### Structure d'un adaptateur

Un adaptateur doit suivre la structure suivante :

```powershell
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("Commande1", "Commande2", "Commande3")]
    [string]$Command,

    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters = @{}
)

# Définir le chemin vers le gestionnaire
$managerPath = "chemin/vers/le/gestionnaire.ps1"

# Fonction pour exécuter une commande sur le gestionnaire
function Invoke-ManagerCommand {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    # Logique d'exécution de la commande
}

# Exécuter la commande spécifiée
switch ($Command) {
    "Commande1" {
        # Logique pour la commande 1
    }
    
    "Commande2" {
        # Logique pour la commande 2
    }
    
    "Commande3" {
        # Logique pour la commande 3
    }
}
```

### Bonnes pratiques

Lors du développement d'un nouvel adaptateur, suivez ces bonnes pratiques :

1. **Validation des paramètres** : Validez tous les paramètres avant de les transmettre au gestionnaire
2. **Gestion des erreurs** : Gérez correctement les erreurs et retournez des messages d'erreur clairs
3. **Documentation** : Documentez toutes les commandes et paramètres disponibles
4. **Tests** : Créez des tests unitaires pour vérifier le bon fonctionnement de l'adaptateur
5. **Compatibilité** : Assurez-vous que l'adaptateur est compatible avec les différentes versions du gestionnaire

## Tests

### Tests unitaires

Pour exécuter les tests unitaires des adaptateurs, utilisez la commande suivante :

```powershell
.\development\managers\process-manager\tests\Test-ManagerAdapters.ps1
```

Ces tests vérifient :
- L'existence des adaptateurs
- La syntaxe des adaptateurs
- Le chargement des adaptateurs
- Les fonctionnalités de base des adaptateurs

### Tests d'intégration

Pour tester l'intégration complète des gestionnaires, utilisez la commande suivante :

```powershell
.\process-manager.ps1 -Command List
```

Cette commande liste tous les gestionnaires enregistrés et vérifie qu'ils sont correctement intégrés.

## Dépannage

### Problèmes courants et solutions

#### Problème 1 : Gestionnaire non trouvé

**Symptômes :**
- Message d'erreur indiquant que le gestionnaire n'existe pas
- La commande échoue avec une erreur de chemin

**Causes possibles :**
- Le gestionnaire n'est pas enregistré
- Le chemin vers le script du gestionnaire est incorrect

**Solutions :**
1. Vérifiez que le gestionnaire est correctement enregistré
2. Assurez-vous que le chemin vers le script du gestionnaire est correct
3. Utilisez la commande Discover pour découvrir automatiquement les gestionnaires

#### Problème 2 : Erreurs lors de l'exécution d'une commande

**Symptômes :**
- La commande échoue avec des erreurs
- Le gestionnaire ne répond pas comme prévu

**Causes possibles :**
- Paramètres incorrects passés au gestionnaire
- Problèmes dans l'adaptateur
- Gestionnaire désactivé

**Solutions :**
1. Vérifiez que les paramètres passés au gestionnaire sont corrects
2. Assurez-vous que l'adaptateur fonctionne correctement
3. Vérifiez que le gestionnaire est activé

### Journalisation

Le Process Manager génère des journaux dans le répertoire suivant :

```
logs/process-manager/
```

Les niveaux de journalisation peuvent être configurés dans le fichier de configuration principal.

## Références

- [Documentation du Process Manager](process_manager.md)
- [Documentation du Mode Manager](mode_manager.md)
- [Documentation du Roadmap Manager](roadmap_manager.md)
- [Documentation de l'Integrated Manager](integrated_manager.md)
- [Documentation du Script Manager](script_manager.md)
- [Documentation de l'Error Manager](error_manager.md)

## Historique des versions

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2025-05-03 | Version initiale |
