# Conventions standardisées pour les gestionnaires

## Introduction

Ce document définit les conventions standardisées pour les gestionnaires dans le projet EMAIL_SENDER_1. Ces conventions sont basées sur les bonnes pratiques PowerShell et visent à améliorer la cohérence et la maintenabilité du code.

## Conventions de nommage

### Noms des dossiers

Les dossiers des gestionnaires doivent suivre les conventions suivantes :

1. **Format** : `<Domaine>Manager`
2. **Casse** : PascalCase (première lettre de chaque mot en majuscule)
3. **Exemples** :
   - `ModeManager`
   - `RoadmapManager`
   - `ScriptManager`
   - `ErrorManager`
   - `ProcessManager`
   - `N8nManager`
   - `MCPManager`

### Noms des fichiers

Les fichiers des gestionnaires doivent suivre les conventions suivantes :

#### Scripts principaux

1. **Format** : `<Domaine>Manager.ps1`
2. **Casse** : PascalCase
3. **Exemples** :
   - `ModeManager.ps1`
   - `RoadmapManager.ps1`
   - `ScriptManager.ps1`

#### Modules

1. **Format** : `<Domaine>Manager.psm1`
2. **Casse** : PascalCase
3. **Exemples** :
   - `ModeManager.psm1`
   - `RoadmapManager.psm1`
   - `ScriptManager.psm1`

#### Manifestes

1. **Format** : `<Domaine>Manager.psd1`
2. **Casse** : PascalCase
3. **Exemples** :
   - `ModeManager.psd1`
   - `RoadmapManager.psd1`
   - `ScriptManager.psd1`

#### Fichiers de configuration

1. **Format** : `<Domaine>Manager.config.json`
2. **Casse** : PascalCase
3. **Exemples** :
   - `ModeManager.config.json`
   - `RoadmapManager.config.json`
   - `ScriptManager.config.json`

#### Tests

1. **Format** : `<Domaine>Manager.Tests.ps1` ou `Test-<Domaine>Manager.ps1`
2. **Casse** : PascalCase
3. **Exemples** :
   - `ModeManager.Tests.ps1` ou `Test-ModeManager.ps1`
   - `RoadmapManager.Tests.ps1` ou `Test-RoadmapManager.ps1`
   - `ScriptManager.Tests.ps1` ou `Test-ScriptManager.ps1`

### Noms des fonctions

Les fonctions des gestionnaires doivent suivre les conventions suivantes :

1. **Format** : `Verb-<Domaine>Manager<Action>`
2. **Casse** : PascalCase
3. **Verbes** : Utiliser les verbes approuvés par PowerShell (Get, Set, New, Remove, Start, Stop, etc.)
4. **Exemples** :
   - `Start-ModeManager`
   - `Stop-ModeManager`
   - `Get-ModeManagerStatus`
   - `Set-ModeManagerConfiguration`
   - `New-ModeManagerInstance`
   - `Remove-ModeManagerInstance`

### Noms des paramètres

Les paramètres des fonctions doivent suivre les conventions suivantes :

1. **Casse** : PascalCase
2. **Noms standards** : Utiliser les noms de paramètres standards lorsque c'est possible (Name, Path, Force, etc.)
3. **Noms singuliers** : Utiliser des noms singuliers plutôt que pluriels, sauf si le paramètre accepte toujours plusieurs valeurs
4. **Exemples** :
   - `Name`
   - `Path`
   - `Force`
   - `Verbose`
   - `WhatIf`
   - `Confirm`

### Noms des variables

Les variables doivent suivre les conventions suivantes :

1. **Format** : `$<domaine>Manager` ou `$<domaine>ManagerPath`
2. **Casse** : camelCase (première lettre en minuscule, première lettre de chaque mot suivant en majuscule)
3. **Exemples** :
   - `$modeManager`
   - `$roadmapManager`
   - `$scriptManager`
   - `$modeManagerPath`
   - `$roadmapManagerPath`
   - `$scriptManagerPath`

## Structure des dossiers

### Structure standard

Tous les gestionnaires doivent suivre la structure standard suivante :

```plaintext
development/managers/<DomaineManager>/
├── <DomaineManager>.psd1     # Manifeste du module

├── <DomaineManager>.psm1     # Module principal

├── Public/                   # Fonctions publiques

│   └── ...
├── Private/                  # Fonctions privées

│   └── ...
├── Classes/                  # Classes

│   └── ...
├── Config/                   # Configuration locale

│   └── ...
├── Data/                     # Données

│   └── ...
└── Tests/                    # Tests

    ├── Unit/                 # Tests unitaires

    ├── Integration/          # Tests d'intégration

    ├── Performance/          # Tests de performance

    └── Load/                 # Tests de charge

```plaintext
### Emplacement des gestionnaires

Tous les gestionnaires doivent être placés dans le répertoire suivant :

```plaintext
development/managers/
```plaintext
### Configuration centralisée

La configuration centralisée des gestionnaires doit être placée dans le répertoire suivant :

```plaintext
projet/config/managers/<DomaineManager>/
└── <DomaineManager>.config.json  # Fichier de configuration principal

```plaintext
## Manifestes

### Format des manifestes

Les manifestes des gestionnaires doivent être au format PSD1 et suivre la structure standard des manifestes PowerShell.

### Contenu des manifestes

Les manifestes doivent inclure les éléments suivants :

```powershell
@{
    # Module principal associé à ce manifeste

    RootModule = '<DomaineManager>.psm1'

    # Numéro de version de ce module

    ModuleVersion = '1.0.0'

    # ID utilisé pour identifier de manière unique ce module

    GUID = '<GUID>'

    # Auteur de ce module

    Author = 'EMAIL_SENDER_1'

    # Société ou fournisseur de ce module

    CompanyName = 'EMAIL_SENDER_1'

    # Description de la fonctionnalité fournie par ce module

    Description = 'Description du gestionnaire <DomaineManager>'

    # Version minimale du moteur PowerShell requise par ce module

    PowerShellVersion = '5.1'

    # Modules qui doivent être importés dans l'environnement global avant d'importer ce module

    RequiredModules = @()

    # Assemblys qui doivent être chargés avant d'importer ce module

    RequiredAssemblies = @()

    # Fichiers de script (.ps1) qui sont exécutés dans l'environnement de l'appelant avant d'importer ce module

    ScriptsToProcess = @()

    # Fichiers de type (.ps1xml) à charger lors de l'importation de ce module

    TypesToProcess = @()

    # Fichiers de format (.ps1xml) à charger lors de l'importation de ce module

    FormatsToProcess = @()

    # Modules à importer en tant que modules imbriqués du module spécifié dans RootModule/ModuleToProcess

    NestedModules = @()

    # Fonctions à exporter à partir de ce module

    FunctionsToExport = @(
        'Start-<DomaineManager>',
        'Stop-<DomaineManager>',
        'Get-<DomaineManager>Status'
    )

    # Cmdlets à exporter à partir de ce module

    CmdletsToExport = @()

    # Variables à exporter à partir de ce module

    VariablesToExport = '*'

    # Alias à exporter à partir de ce module

    AliasesToExport = @()

    # Données privées à transmettre au module spécifié dans RootModule/ModuleToProcess

    PrivateData = @{
        PSData = @{
            # Tags appliqués à ce module

            Tags = @('Manager', '<Domaine>', 'EMAIL_SENDER_1')

            # URL vers la licence de ce module

            LicenseUri = ''

            # URL vers le site web principal de ce projet

            ProjectUri = ''

            # URL vers une icône représentant ce module

            IconUri = ''

            # Notes de version de ce module

            ReleaseNotes = ''
        }
    }

    # URI d'aide de ce module

    HelpInfoURI = ''

    # Préfixe par défaut pour les commandes exportées à partir de ce module

    DefaultCommandPrefix = ''
}
```plaintext
## Fonctions standard

Chaque gestionnaire doit implémenter les fonctions standard suivantes :

1. **Start-\<DomaineManager\>** : Démarre le gestionnaire
2. **Stop-\<DomaineManager\>** : Arrête le gestionnaire
3. **Get-\<DomaineManager\>Status** : Récupère l'état du gestionnaire

Exemple :

```powershell
function Start-ModeManager {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    
    if ($PSCmdlet.ShouldProcess("ModeManager", "Start")) {
        # Code pour démarrer le gestionnaire

    }
}

function Stop-ModeManager {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    
    if ($PSCmdlet.ShouldProcess("ModeManager", "Stop")) {
        # Code pour arrêter le gestionnaire

    }
}

function Get-ModeManagerStatus {
    [CmdletBinding()]
    param()
    
    # Code pour récupérer l'état du gestionnaire

}
```plaintext
## Tests

### Framework de test

Tous les tests doivent utiliser le framework Pester.

### Organisation des tests

Les tests doivent être organisés dans les sous-dossiers suivants :

1. **Unit** : Tests unitaires
2. **Integration** : Tests d'intégration
3. **Performance** : Tests de performance
4. **Load** : Tests de charge

### Convention de nommage des tests

Les fichiers de test doivent suivre la convention de nommage suivante :

1. **Format** : `<DomaineManager>.Tests.ps1` ou `Test-<DomaineManager>.ps1`
2. **Casse** : PascalCase

### Structure des tests

Les tests doivent suivre la structure suivante :

```powershell
Describe "<DomaineManager>" {
    BeforeAll {
        # Code d'initialisation

    }
    
    AfterAll {
        # Code de nettoyage

    }
    
    Context "Start-<DomaineManager>" {
        It "Should start the manager" {
            # Test

        }
    }
    
    Context "Stop-<DomaineManager>" {
        It "Should stop the manager" {
            # Test

        }
    }
    
    Context "Get-<DomaineManager>Status" {
        It "Should return the manager status" {
            # Test

        }
    }
}
```plaintext
## Intégration avec le Process Manager

### Enregistrement des gestionnaires

Les gestionnaires doivent être enregistrés auprès du Process Manager en utilisant la fonction `Register-Manager` :

```powershell
Register-Manager -Name "<DomaineManager>" -Path "development\managers\<DomaineManager>\<DomaineManager>.ps1"
```plaintext
### Manifeste pour le Process Manager

Chaque gestionnaire doit fournir un manifeste pour le Process Manager :

```json
{
    "Name": "<DomaineManager>",
    "Description": "Description du gestionnaire <DomaineManager>",
    "Version": "1.0.0",
    "Author": "EMAIL_SENDER_1",
    "Dependencies": [
        {
            "Name": "ProcessManager",
            "MinimumVersion": "1.0.0",
            "Required": true
        }
    ],
    "Capabilities": [
        "Startable",
        "Stoppable",
        "StatusReporting"
    ],
    "EntryPoint": "Start-<DomaineManager>",
    "StopFunction": "Stop-<DomaineManager>"
}
```plaintext
## Migration vers les nouvelles conventions

### Étapes de migration

1. **Renommer les dossiers** : Renommer les dossiers des gestionnaires pour suivre la convention `<DomaineManager>`.
2. **Renommer les fichiers** : Renommer les fichiers des gestionnaires pour suivre les conventions appropriées.
3. **Restructurer les dossiers** : Restructurer les dossiers des gestionnaires pour suivre la structure standard.
4. **Renommer les fonctions** : Renommer les fonctions des gestionnaires pour suivre la convention `Verb-<DomaineManager><Action>`.
5. **Renommer les variables** : Renommer les variables pour suivre la convention `$<domaine>Manager`.
6. **Créer des manifestes** : Créer des manifestes pour tous les gestionnaires.
7. **Mettre à jour les références** : Mettre à jour toutes les références aux anciens noms dans le code.
8. **Mettre à jour la documentation** : Mettre à jour la documentation pour refléter les nouvelles conventions.

### Script de migration

Un script de migration sera fourni pour automatiser le processus de migration vers les nouvelles conventions.

## Conclusion

L'adoption de ces conventions standardisées pour les gestionnaires permettra d'améliorer la cohérence et la maintenabilité du code. Ces conventions sont basées sur les bonnes pratiques PowerShell et visent à fournir une structure claire et cohérente pour tous les gestionnaires du projet EMAIL_SENDER_1.
