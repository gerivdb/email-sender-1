# Organisation des fichiers et dossiers pour EMAIL_SENDER_1

*Version 1.0 - 2025-05-15*

Ce document définit la structure standardisée des fichiers et dossiers pour le projet EMAIL_SENDER_1. Cette organisation vise à assurer la cohérence, la maintenabilité et la scalabilité du projet.

## Principes généraux

### Séparation des préoccupations
- Séparer clairement les différentes parties du projet selon leur fonction
- Regrouper les fichiers liés par leur fonctionnalité plutôt que par leur type
- Maintenir une hiérarchie logique et intuitive

### Modularité
- Organiser le code en modules indépendants et réutilisables
- Limiter les dépendances entre les modules
- Faciliter l'ajout, la modification ou la suppression de fonctionnalités

### Cohérence
- Appliquer les mêmes conventions d'organisation dans tout le projet
- Utiliser des noms de dossiers et de fichiers cohérents
- Maintenir une structure prévisible

## Structure racine du projet

La structure racine du projet EMAIL_SENDER_1 est organisée comme suit :

```
EMAIL_SENDER_1/
├── development/        # Code de développement et outils
├── docs/               # Documentation du projet
├── projet/             # Configuration et planification du projet
├── src/                # Code source principal
└── tests/              # Tests automatisés
```

### Dossier `development/`

Le dossier `development/` contient tous les scripts, outils et ressources utilisés pendant le développement mais qui ne font pas partie du code source principal.

```
development/
├── scripts/            # Scripts utilitaires et d'automatisation
│   ├── analysis/       # Scripts d'analyse de données
│   ├── core/           # Scripts fondamentaux
│   ├── extraction/     # Scripts d'extraction de données
│   ├── integration/    # Scripts d'intégration avec d'autres systèmes
│   ├── maintenance/    # Scripts de maintenance
│   ├── optimization/   # Scripts d'optimisation
│   ├── reporting/      # Scripts de génération de rapports
│   ├── testing/        # Scripts de test
│   └── utils/          # Scripts utilitaires généraux
├── templates/          # Templates pour la génération de code
│   ├── hygen/          # Templates Hygen
│   ├── powershell/     # Templates PowerShell
│   └── python/         # Templates Python
└── tools/              # Outils de développement
    ├── analyzers/      # Outils d'analyse de code
    ├── generators/     # Générateurs de code
    └── validators/     # Validateurs de code
```

#### Organisation des scripts

Chaque sous-dossier de `development/scripts/` suit une structure commune :

```
scripts/category/
├── modules/            # Modules PowerShell
│   ├── ModuleName1/    # Module spécifique
│   │   ├── ModuleName1.psd1    # Manifeste du module
│   │   ├── ModuleName1.psm1    # Module principal
│   │   ├── Public/             # Fonctions publiques
│   │   ├── Private/            # Fonctions privées
│   │   ├── Tests/              # Tests du module
│   │   ├── config/             # Configuration du module
│   │   └── data/               # Données du module
│   └── ModuleName2/    # Autre module
├── examples/           # Exemples d'utilisation
└── standalone/         # Scripts autonomes
```

### Dossier `docs/`

Le dossier `docs/` contient toute la documentation du projet.

```
docs/
├── api/                # Documentation de l'API
├── architecture/       # Documentation de l'architecture
├── guides/             # Guides d'utilisation
│   ├── development/    # Guides pour les développeurs
│   ├── installation/   # Guides d'installation
│   ├── powershell/     # Guides spécifiques à PowerShell
│   ├── python/         # Guides spécifiques à Python
│   ├── standards/      # Standards et conventions
│   └── usage/          # Guides d'utilisation
├── references/         # Documents de référence
└── tutorials/          # Tutoriels pas à pas
```

### Dossier `projet/`

Le dossier `projet/` contient les fichiers de configuration et de planification du projet.

```
projet/
├── config/             # Fichiers de configuration
├── roadmaps/           # Plans de développement
│   ├── plans/          # Plans détaillés
│   └── visualizations/ # Visualisations des plans
└── templates/          # Templates pour les documents du projet
```

### Dossier `src/`

Le dossier `src/` contient le code source principal du projet.

```
src/
├── core/               # Fonctionnalités fondamentales
├── integrations/       # Intégrations avec d'autres systèmes
├── mcp/                # Serveurs MCP (Model Context Protocol)
│   ├── servers/        # Implémentations des serveurs
│   └── clients/        # Clients pour les serveurs
├── n8n/                # Workflows et configurations n8n
│   ├── config/         # Configuration n8n
│   ├── credentials/    # Credentials n8n (sécurisées)
│   └── workflows/      # Workflows n8n
│       ├── active/     # Workflows actifs
│       └── archive/    # Workflows archivés
└── web/                # Composants web
    ├── api/            # API web
    ├── client/         # Client web
    └── dashboard/      # Tableau de bord
```

### Dossier `tests/`

Le dossier `tests/` contient tous les tests automatisés du projet.

```
tests/
├── integration/        # Tests d'intégration
├── performance/        # Tests de performance
├── security/           # Tests de sécurité
└── unit/               # Tests unitaires
    ├── core/           # Tests des fonctionnalités fondamentales
    ├── integrations/   # Tests des intégrations
    └── n8n/            # Tests des workflows n8n
```

## Organisation des modules PowerShell

Chaque module PowerShell suit une structure standardisée :

```
ModuleName/
├── ModuleName.psd1     # Manifeste du module
├── ModuleName.psm1     # Module principal
├── Public/             # Fonctions publiques
│   ├── Function1.ps1   # Fonction publique individuelle
│   └── Function2.ps1   # Autre fonction publique
├── Private/            # Fonctions privées
│   ├── Function1.ps1   # Fonction privée individuelle
│   └── Function2.ps1   # Autre fonction privée
├── Tests/              # Tests du module
│   ├── ModuleName.Tests.ps1       # Tests généraux
│   ├── Function1.Tests.ps1        # Tests spécifiques à une fonction
│   └── TestData/                  # Données de test
├── config/             # Configuration du module
│   └── ModuleName.config.json     # Configuration par défaut
├── data/               # Données du module
│   ├── templates/      # Templates
│   └── schemas/        # Schémas de validation
├── logs/               # Logs du module (générés)
└── README.md           # Documentation du module
```

### Fichier de module principal (`.psm1`)

Le fichier de module principal (`.psm1`) suit une structure standardisée :

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Description courte du module.
.DESCRIPTION
    Description détaillée du module.
.NOTES
    Version: 1.0.0
    Auteur: Nom de l'auteur
    Date de création: YYYY-MM-DD
#>

#region Variables globales
$script:ModuleName = 'NomDuModule'
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = '1.0.0'
$script:ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "config\$script:ModuleName.config.json"
$script:LogPath = Join-Path -Path $PSScriptRoot -ChildPath "logs\$script:ModuleName.log"
#endregion

#region Fonctions privées
# Importer toutes les fonctions privées
$PrivateFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)
foreach ($Function in $PrivateFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Fonction privée importée : $($Function.BaseName)"
    }
    catch {
        Write-Error "Échec de l'importation de la fonction privée $($Function.FullName): $_"
    }
}
#endregion

#region Fonctions publiques
# Importer toutes les fonctions publiques
$PublicFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue)
foreach ($Function in $PublicFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Fonction publique importée : $($Function.BaseName)"
    }
    catch {
        Write-Error "Échec de l'importation de la fonction publique $($Function.FullName): $_"
    }
}
#endregion

#region Initialisation du module
function Initialize-ModuleName {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    # Créer les dossiers nécessaires s'ils n'existent pas
    $Folders = @(
        (Join-Path -Path $script:ModuleRoot -ChildPath "config"),
        (Join-Path -Path $script:ModuleRoot -ChildPath "logs"),
        (Join-Path -Path $script:ModuleRoot -ChildPath "data")
    )

    foreach ($Folder in $Folders) {
        if (-not (Test-Path -Path $Folder)) {
            if ($PSCmdlet.ShouldProcess($Folder, "Créer le dossier")) {
                New-Item -Path $Folder -ItemType Directory -Force | Out-Null
                Write-Verbose "Dossier créé : $Folder"
            }
        }
    }

    # Initialiser le fichier de configuration s'il n'existe pas
    if (-not (Test-Path -Path $script:ConfigPath)) {
        if ($PSCmdlet.ShouldProcess($script:ConfigPath, "Créer le fichier de configuration")) {
            $DefaultConfig = @{
                ModuleName = $script:ModuleName
                Version = $script:ModuleVersion
                LogLevel = "Info"
                LogPath = $script:LogPath
                Enabled = $true
            }

            $DefaultConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath $script:ConfigPath -Encoding utf8
            Write-Verbose "Fichier de configuration créé : $script:ConfigPath"
        }
    }
}
#endregion

#region Exportation des fonctions
# Exporter uniquement les fonctions publiques
Export-ModuleMember -Function $PublicFunctions.BaseName -Variable @()
#endregion

# Initialiser le module lors du chargement
Initialize-ModuleName
```

## Organisation des packages Python

Les packages Python suivent une structure standardisée :

```
package_name/
├── __init__.py         # Initialisation du package
├── main.py             # Point d'entrée principal
├── core/               # Fonctionnalités fondamentales
│   ├── __init__.py     # Initialisation du sous-package
│   └── module1.py      # Module spécifique
├── utils/              # Utilitaires
│   ├── __init__.py     # Initialisation du sous-package
│   └── helpers.py      # Fonctions d'aide
├── models/             # Modèles de données
│   ├── __init__.py     # Initialisation du sous-package
│   └── user.py         # Modèle spécifique
├── config/             # Configuration
│   ├── __init__.py     # Initialisation du sous-package
│   └── settings.py     # Paramètres de configuration
├── tests/              # Tests
│   ├── __init__.py     # Initialisation du package de tests
│   ├── test_main.py    # Tests du module principal
│   └── test_utils.py   # Tests des utilitaires
├── docs/               # Documentation
│   └── index.md        # Documentation principale
├── setup.py            # Script d'installation
└── README.md           # Documentation du package
```

## Organisation des projets JavaScript/TypeScript

Les projets JavaScript/TypeScript suivent une structure standardisée :

```
project-name/
├── src/                # Code source
│   ├── components/     # Composants React
│   │   ├── common/     # Composants communs
│   │   └── specific/   # Composants spécifiques
│   ├── services/       # Services
│   │   ├── api.js      # Service API
│   │   └── auth.js     # Service d'authentification
│   ├── utils/          # Utilitaires
│   │   └── helpers.js  # Fonctions d'aide
│   ├── models/         # Modèles de données
│   │   └── user.js     # Modèle spécifique
│   ├── config/         # Configuration
│   │   └── settings.js # Paramètres de configuration
│   └── index.js        # Point d'entrée principal
├── public/             # Fichiers statiques
│   ├── index.html      # Page HTML principale
│   └── assets/         # Ressources statiques
│       ├── images/     # Images
│       └── styles/     # Styles CSS
├── tests/              # Tests
│   ├── components/     # Tests des composants
│   └── services/       # Tests des services
├── docs/               # Documentation
├── package.json        # Configuration npm
└── README.md           # Documentation du projet
```

## Bonnes pratiques

### Taille des fichiers
- Limiter la taille des fichiers à environ 300-500 lignes
- Diviser les fichiers volumineux en modules plus petits et plus spécifiques
- Un fichier = une responsabilité

### Profondeur de l'arborescence
- Limiter la profondeur de l'arborescence à 4-5 niveaux maximum
- Éviter les structures trop profondes qui rendent la navigation difficile
- Privilégier une structure plate mais organisée

### Fichiers README
- Chaque module ou composant important doit avoir un fichier README.md
- Le README doit expliquer le but, l'utilisation et les dépendances du module
- Inclure des exemples d'utilisation dans le README

### Fichiers de configuration
- Centraliser les configurations dans des fichiers dédiés
- Séparer les configurations par environnement (dev, test, prod)
- Éviter les valeurs codées en dur dans le code

### Gestion des dépendances
- Documenter clairement les dépendances externes
- Minimiser les dépendances entre les modules
- Utiliser des gestionnaires de dépendances appropriés (npm, pip, etc.)

## Exemples pratiques

### Exemple de structure pour un module PowerShell

```
EmailSender/
├── EmailSender.psd1
├── EmailSender.psm1
├── Public/
│   ├── Send-Email.ps1
│   ├── Get-EmailStatus.ps1
│   └── Test-SmtpConnection.ps1
├── Private/
│   ├── Format-EmailBody.ps1
│   ├── Get-SmtpConfig.ps1
│   └── Write-EmailLog.ps1
├── Tests/
│   ├── EmailSender.Tests.ps1
│   ├── Send-Email.Tests.ps1
│   └── TestData/
│       ├── email-template.html
│       └── test-recipients.csv
├── config/
│   └── EmailSender.config.json
├── data/
│   ├── templates/
│   │   ├── welcome.html
│   │   └── notification.html
│   └── schemas/
│       └── email-schema.json
├── logs/
└── README.md
```

### Exemple de structure pour un package Python

```
email_sender/
├── __init__.py
├── main.py
├── core/
│   ├── __init__.py
│   ├── sender.py
│   └── validator.py
├── utils/
│   ├── __init__.py
│   ├── formatters.py
│   └── loggers.py
├── models/
│   ├── __init__.py
│   ├── email.py
│   └── recipient.py
├── config/
│   ├── __init__.py
│   └── settings.py
├── tests/
│   ├── __init__.py
│   ├── test_sender.py
│   └── test_validator.py
├── docs/
│   └── index.md
├── setup.py
└── README.md
```

### Exemple de structure pour un projet JavaScript/TypeScript

```
email-dashboard/
├── src/
│   ├── components/
│   │   ├── common/
│   │   │   ├── Button.jsx
│   │   │   └── Input.jsx
│   │   └── email/
│   │       ├── EmailForm.jsx
│   │       └── EmailList.jsx
│   ├── services/
│   │   ├── api.js
│   │   └── email-service.js
│   ├── utils/
│   │   └── validators.js
│   ├── models/
│   │   └── email.js
│   ├── config/
│   │   └── settings.js
│   └── index.js
├── public/
│   ├── index.html
│   └── assets/
│       ├── images/
│       └── styles/
├── tests/
│   ├── components/
│   └── services/
├── docs/
├── package.json
└── README.md
```
