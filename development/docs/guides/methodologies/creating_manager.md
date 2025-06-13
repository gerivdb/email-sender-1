# Création d'un gestionnaire pour le Process Manager

## Introduction

Ce guide explique comment créer un nouveau gestionnaire compatible avec le Process Manager. Il détaille la structure requise, les fonctions à implémenter et les bonnes pratiques à suivre.

## Structure d'un gestionnaire

Un gestionnaire est un script PowerShell qui implémente un ensemble de fonctions standard pour interagir avec le Process Manager. La structure de base d'un gestionnaire est la suivante :

```plaintext
development/managers/<nom-du-gestionnaire>/
├── scripts/
│   ├── <nom-du-gestionnaire>.ps1         # Script principal du gestionnaire

│   ├── <nom-du-gestionnaire>.manifest.json # Manifeste du gestionnaire (optionnel)

│   └── ...                               # Autres scripts

├── modules/
│   └── ...                               # Modules PowerShell spécifiques au gestionnaire

├── tests/
│   ├── Test-<NomDuGestionnaire>.ps1      # Tests unitaires

│   └── ...                               # Autres tests

└── config/
    └── ...                               # Fichiers de configuration locaux

```plaintext
## Fonctions requises

Un gestionnaire doit implémenter les fonctions suivantes :

1. **Start-\<NomDuGestionnaire\>** : Démarre le gestionnaire.
2. **Stop-\<NomDuGestionnaire\>** : Arrête le gestionnaire.
3. **Get-\<NomDuGestionnaire\>Status** : Récupère l'état du gestionnaire.

## Exemple de gestionnaire

Voici un exemple de gestionnaire simple :

```powershell
<#

.SYNOPSIS
    Exemple de gestionnaire pour le Process Manager.

.DESCRIPTION
    Ce script est un exemple de gestionnaire pour le Process Manager.

.MANIFEST
{
    "Name": "ExampleManager",
    "Description": "Exemple de gestionnaire pour le Process Manager",
    "Version": "1.0.0",
    "Author": "EMAIL_SENDER_1",
    "Dependencies": [
        {
            "Name": "OtherManager",
            "MinimumVersion": "1.0.0",
            "Required": true
        }
    ]
}
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$Command = "Status"
)

function Start-ExampleManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire d'exemple..."
}

function Stop-ExampleManager {
    [CmdletBinding()]
    param()
    
    Write-Host "Arrêt du gestionnaire d'exemple..."
}

function Get-ExampleManagerStatus {
    [CmdletBinding()]
    param()
    
    return @{
        Status = "Running"
        StartTime = Get-Date
    }
}

# Exécuter la commande spécifiée

switch ($Command) {
    "Start" {
        Start-ExampleManager
    }
    "Stop" {
        Stop-ExampleManager
    }
    "Status" {
        Get-ExampleManagerStatus
    }
    default {
        Write-Host "Commande inconnue : $Command"
    }
}
```plaintext
## Manifeste du gestionnaire

Un manifeste de gestionnaire est un objet JSON qui décrit les métadonnées et les dépendances du gestionnaire. Il peut être défini de plusieurs façons :

1. **Dans un bloc de commentaires** : Utilisez un bloc de commentaires avec la balise `.MANIFEST` dans le script du gestionnaire.
2. **Dans un fichier JSON séparé** : Créez un fichier JSON avec le nom `<nom-du-gestionnaire>.manifest.json` dans le même répertoire que le script du gestionnaire.
3. **Dans un fichier PSD1** : Utilisez un fichier de manifeste PowerShell (PSD1) avec des métadonnées spécifiques au Process Manager.

### Structure du manifeste

```json
{
    "Name": "ExampleManager",
    "Description": "Exemple de gestionnaire pour le Process Manager",
    "Version": "1.0.0",
    "Author": "EMAIL_SENDER_1",
    "Contact": "contact@email-sender-1.com",
    "License": "MIT",
    "RequiredPowerShellVersion": "5.1",
    "Dependencies": [
        {
            "Name": "OtherManager",
            "MinimumVersion": "1.0.0",
            "MaximumVersion": "2.0.0",
            "Required": true
        }
    ],
    "Capabilities": [
        "Startable",
        "Stoppable",
        "StatusReporting",
        "Configurable"
    ],
    "EntryPoint": "Start-ExampleManager",
    "StopFunction": "Stop-ExampleManager",
    "ConfigurationSchema": {
        "LogLevel": {
            "Type": "string",
            "Default": "Info",
            "AllowedValues": ["Debug", "Info", "Warning", "Error"]
        },
        "MaxThreads": {
            "Type": "integer",
            "Default": 4,
            "Minimum": 1,
            "Maximum": 16
        }
    },
    "SecurityRequirements": {
        "RequireAdministrator": false,
        "RequireElevation": false
    }
}
```plaintext
### Propriétés du manifeste

| Propriété | Type | Description | Requis |
|-----------|------|-------------|--------|
| Name | string | Nom du gestionnaire | Oui |
| Description | string | Description du gestionnaire | Non |
| Version | string | Version du gestionnaire (format X.Y.Z) | Oui |
| Author | string | Auteur du gestionnaire | Non |
| Contact | string | Contact de l'auteur | Non |
| License | string | Licence du gestionnaire | Non |
| RequiredPowerShellVersion | string | Version minimale de PowerShell requise | Non |
| Dependencies | array | Dépendances du gestionnaire | Non |
| Capabilities | array | Capacités du gestionnaire | Non |
| EntryPoint | string | Fonction d'entrée du gestionnaire | Non |
| StopFunction | string | Fonction d'arrêt du gestionnaire | Non |
| ConfigurationSchema | object | Schéma de configuration du gestionnaire | Non |
| SecurityRequirements | object | Exigences de sécurité du gestionnaire | Non |

## Enregistrement du gestionnaire

Une fois le gestionnaire créé, vous devez l'enregistrer dans le Process Manager pour pouvoir l'utiliser. Vous pouvez le faire de deux façons :

### Enregistrement manuel

```powershell
.\development\managers\process-manager\scripts\process-manager.ps1 -Command Register -ManagerName "ExampleManager" -ManagerPath "development\managers\example-manager\scripts\example-manager.ps1"
```plaintext
### Découverte automatique

Si votre gestionnaire suit la convention de nommage et la structure de répertoires standard, vous pouvez utiliser la commande Discover pour l'enregistrer automatiquement :

```powershell
.\development\managers\process-manager\scripts\process-manager.ps1 -Command Discover
```plaintext
## Validation du gestionnaire

Avant d'enregistrer votre gestionnaire, vous pouvez le valider pour vous assurer qu'il est compatible avec le Process Manager. Vous pouvez utiliser les fonctions du module ValidationService pour cela :

```powershell
Import-Module ProcessManager
Test-ManagerValidity -Path "development\managers\example-manager\scripts\example-manager.ps1"
```plaintext
## Gestion des dépendances

Si votre gestionnaire dépend d'autres gestionnaires, vous devez spécifier ces dépendances dans le manifeste. Vous pouvez utiliser les fonctions du module DependencyResolver pour vérifier la disponibilité des dépendances :

```powershell
Import-Module ProcessManager
$dependencies = Get-ManagerDependencies -Path "development\managers\example-manager\scripts\example-manager.ps1"
Test-DependenciesAvailability -Dependencies $dependencies
```plaintext
## Tests

Il est recommandé de créer des tests unitaires pour votre gestionnaire. Vous pouvez utiliser le framework de test Pester pour cela. Voici un exemple de test unitaire pour un gestionnaire :

```powershell
Describe "ExampleManager" {
    BeforeAll {
        # Charger le gestionnaire

        . "development\managers\example-manager\scripts\example-manager.ps1"
    }

    It "Should start correctly" {
        # Tester la fonction Start-ExampleManager

        Start-ExampleManager
        # Vérifier que le gestionnaire a démarré correctement

    }

    It "Should stop correctly" {
        # Tester la fonction Stop-ExampleManager

        Stop-ExampleManager
        # Vérifier que le gestionnaire s'est arrêté correctement

    }

    It "Should return status correctly" {
        # Tester la fonction Get-ExampleManagerStatus

        $status = Get-ExampleManagerStatus
        $status | Should -Not -BeNullOrEmpty
        $status.Status | Should -Be "Running"
    }
}
```plaintext
## Bonnes pratiques

### Conception du gestionnaire

1. **Suivez les conventions de nommage** : Utilisez les préfixes `Start-`, `Stop-` et `Get-` pour les fonctions principales.
2. **Implémentez toutes les fonctions requises** : Assurez-vous que votre gestionnaire implémente toutes les fonctions requises.
3. **Gérez les erreurs correctement** : Utilisez `try/catch` pour gérer les erreurs et journalisez-les correctement.
4. **Documentez votre gestionnaire** : Utilisez des commentaires pour documenter votre gestionnaire et ses fonctions.
5. **Spécifiez les dépendances** : Utilisez un manifeste pour spécifier les dépendances de votre gestionnaire.

### Structure du code

1. **Utilisez des fonctions privées** : Utilisez des fonctions privées pour le code interne du gestionnaire.
2. **Utilisez des paramètres nommés** : Utilisez des paramètres nommés pour les fonctions.
3. **Utilisez des types de données appropriés** : Utilisez des types de données appropriés pour les paramètres et les valeurs de retour.
4. **Utilisez des commentaires** : Utilisez des commentaires pour documenter le code.
5. **Utilisez des régions** : Utilisez des régions pour organiser le code.

### Journalisation

1. **Utilisez une journalisation cohérente** : Utilisez une journalisation cohérente dans tout le gestionnaire.
2. **Journalisez les événements importants** : Journalisez les événements importants comme le démarrage, l'arrêt et les erreurs.
3. **Utilisez des niveaux de journalisation appropriés** : Utilisez des niveaux de journalisation appropriés (Debug, Info, Warning, Error).

### Configuration

1. **Utilisez des fichiers de configuration** : Utilisez des fichiers de configuration pour les paramètres du gestionnaire.
2. **Validez la configuration** : Validez la configuration avant de l'utiliser.
3. **Utilisez des valeurs par défaut** : Utilisez des valeurs par défaut pour les paramètres de configuration.

## Conclusion

La création d'un gestionnaire compatible avec le Process Manager est simple si vous suivez les conventions et les bonnes pratiques décrites dans ce guide. Assurez-vous d'implémenter toutes les fonctions requises, de spécifier les dépendances dans le manifeste et de créer des tests unitaires pour votre gestionnaire.
