# Guide de démarrage rapide

## Introduction

Bienvenue dans le projet EMAIL_SENDER_1 ! Ce guide de démarrage rapide vous aidera à comprendre les bases du projet, à installer les modules nécessaires et à commencer à utiliser les fonctionnalités principales. Que vous soyez un développeur, un administrateur système ou un utilisateur final, ce guide vous fournira les informations essentielles pour démarrer rapidement.

## Prérequis

Avant de commencer, assurez-vous de disposer des éléments suivants :

- PowerShell 5.1 ou PowerShell 7+ installé
- Python 3.11+ installé (pour certaines fonctionnalités)
- Accès au dépôt du projet
- Droits d'administrateur sur votre système (pour certaines installations)
- Visual Studio Code (recommandé pour le développement)

## Structure du projet

Le projet EMAIL_SENDER_1 est organisé comme suit :

```
EMAIL_SENDER_1/
├── modules/              # Modules PowerShell principaux
├── scripts/              # Scripts PowerShell et Python
├── tests/                # Tests unitaires et d'intégration
├── docs/                 # Documentation
│   ├── api/              # Documentation API
│   ├── guides/           # Guides d'utilisation
│   └── technical/        # Documentation technique
├── n8n/                  # Workflows et nodes n8n
└── config/               # Fichiers de configuration
```

## Installation

Pour installer le projet, suivez ces étapes :

1. Clonez le dépôt :

```powershell
git clone https://github.com/votre-organisation/EMAIL_SENDER_1.git
cd EMAIL_SENDER_1
```

2. Importez les modules principaux :

```powershell
# Importer tous les modules
Get-ChildItem -Path .\modules\*.psm1 | ForEach-Object {
    Import-Module $_.FullName -Force
}

# Ou importer des modules spécifiques
Import-Module -Path .\modules\CycleDetector.psm1 -Force
Import-Module -Path .\modules\DependencyManager.psm1 -Force
Import-Module -Path .\modules\MCPManager.psm1 -Force
Import-Module -Path .\modules\InputSegmenter.psm1 -Force
```

3. Initialisez les modules :

```powershell
# Initialiser les modules avec les paramètres par défaut
Initialize-CycleDetector
Initialize-DependencyManager
Initialize-MCPManager
Initialize-InputSegmentation

# Ou avec des paramètres personnalisés
Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
```

## Modules principaux

Le projet EMAIL_SENDER_1 comprend plusieurs modules principaux :

### CycleDetector

Le module `CycleDetector` permet de détecter et de corriger les cycles dans différents types de graphes, notamment les dépendances de scripts et les workflows n8n.

```powershell
# Exemple d'utilisation de base
$graph = @{
    "A" = @("B")
    "B" = @("C")
    "C" = @("A")
}
$result = Find-Cycle -Graph $graph
if ($result.HasCycle) {
    Write-Host "Cycle détecté: $($result.CyclePath -join ' -> ')"
}
```

### DependencyManager

Le module `DependencyManager` permet de gérer les dépendances entre les scripts, les modules et les workflows.

```powershell
# Exemple d'utilisation de base
$dependencies = Get-ScriptDependencies -Path ".\scripts\main.ps1"
$order = Resolve-DependencyOrder -Path ".\scripts" -Recursive
```

### MCPManager

Le module `MCPManager` permet de gérer les serveurs MCP (Model Context Protocol), de détecter les serveurs disponibles et d'interagir avec eux.

```powershell
# Exemple d'utilisation de base
$servers = Find-MCPServers -ScanLocalPorts
$server = Start-MCPServer -ServerType "local" -Port 8000 -Wait
$result = Invoke-MCPCommand -Command "get_status" -ServerType "local" -Port 8000
```

### InputSegmenter

Le module `InputSegmenter` permet de segmenter automatiquement les entrées volumineuses en morceaux plus petits et gérables.

```powershell
# Exemple d'utilisation de base
$text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 1000
$segments = Split-TextInput -Text $text -SegmentSizeKB 10
```

## Premiers pas

Voici quelques exemples pour vous aider à démarrer avec le projet EMAIL_SENDER_1 :

### Exemple 1 : Analyser les dépendances d'un script

```powershell
# Importer les modules nécessaires
Import-Module -Path .\modules\CycleDetector.psm1 -Force
Import-Module -Path .\modules\DependencyManager.psm1 -Force

# Initialiser les modules
Initialize-CycleDetector
Initialize-DependencyManager

# Analyser les dépendances d'un script
$result = Find-ScriptDependencyCycles -Path ".\scripts" -Recursive -GenerateGraph -GraphOutputPath ".\dependency_graph.html"

# Afficher les résultats
if ($result.HasCycles) {
    Write-Host "Cycles détectés dans les scripts suivants:"
    foreach ($cycle in $result.Cycles) {
        Write-Host "- $($cycle -join ' -> ')"
    }
} else {
    Write-Host "Aucun cycle détecté dans les scripts"
}
```

### Exemple 2 : Démarrer un serveur MCP et exécuter une commande

```powershell
# Importer le module nécessaire
Import-Module -Path .\modules\MCPManager.psm1 -Force

# Initialiser le module
Initialize-MCPManager

# Démarrer un serveur MCP local
$server = Start-MCPServer -ServerType "local" -Port 8000 -Wait

if ($server.Status -eq "running") {
    Write-Host "Serveur MCP démarré avec succès: $($server.Url)"
    
    # Exécuter une commande sur le serveur
    $result = Invoke-MCPCommand -Command "get_status" -ServerType "local" -Port 8000
    Write-Host "Statut du serveur: $($result.status)"
    
    # Arrêter le serveur
    Stop-MCPServer -ServerType "local" -Port 8000
}
```

### Exemple 3 : Segmenter un texte volumineux

```powershell
# Importer le module nécessaire
Import-Module -Path .\modules\InputSegmenter.psm1 -Force

# Initialiser le module
Initialize-InputSegmentation

# Créer un texte volumineux
$text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 1000

# Mesurer la taille du texte
$textSize = Measure-InputSize -Input $text -InputType "Text"
Write-Host "Taille du texte: $($textSize.SizeKB) KB"

# Segmenter le texte
$segments = Split-TextInput -Text $text -SegmentSizeKB 10

# Afficher des informations sur les segments
Write-Host "Nombre de segments: $($segments.Count)"
```

## Étapes suivantes

Maintenant que vous avez compris les bases du projet EMAIL_SENDER_1, voici quelques suggestions pour approfondir vos connaissances :

1. Consultez les guides spécifiques à chaque module :
   - [Guide de détection de cycles](cycle_detection.md)
   - [Guide de gestion des dépendances](dependency_management.md)
   - [Guide d'intégration MCP](mcp_integration.md)
   - [Guide de segmentation des entrées](input_segmentation.md)

2. Explorez la documentation API pour une référence complète des fonctions disponibles :
   - [API CycleDetector](../api/CycleDetector.html)
   - [API DependencyManager](../api/DependencyManager.html)
   - [API MCPManager](../api/MCPManager.html)
   - [API InputSegmenter](../api/InputSegmenter.html)

3. Consultez les exemples d'utilisation pour des cas d'utilisation plus avancés :
   - [Exemples CycleDetector](../api/examples/CycleDetector_Examples.html)
   - [Exemples DependencyManager](../api/examples/DependencyManager_Examples.html)
   - [Exemples MCPManager](../api/examples/MCPManager_Examples.html)
   - [Exemples InputSegmenter](../api/examples/InputSegmenter_Examples.html)

## Dépannage

### Problème : Les modules ne s'importent pas correctement

Assurez-vous que vous êtes dans le répertoire racine du projet et que les chemins sont corrects. Utilisez des chemins absolus si nécessaire.

### Problème : Erreurs lors de l'initialisation des modules

Vérifiez que vous avez les droits d'administrateur nécessaires et que tous les prérequis sont installés.

## Ressources supplémentaires

- [Documentation complète du projet](../index.html)
- [Dépôt GitHub du projet](https://github.com/votre-organisation/EMAIL_SENDER_1)
- [Signaler un problème](https://github.com/votre-organisation/EMAIL_SENDER_1/issues)
