# Guide d'installation du module RoadmapParser

Ce guide explique comment installer et configurer le module RoadmapParser pour PowerShell.

## Prérequis

Avant d'installer le module RoadmapParser, assurez-vous que votre système répond aux exigences suivantes :

- Windows 7 ou version ultérieure, ou Windows Server 2008 R2 ou version ultérieure
- PowerShell 5.1 ou version ultérieure (recommandé : PowerShell 7.x)
- .NET Framework 4.5.2 ou version ultérieure

Pour vérifier votre version de PowerShell, exécutez la commande suivante dans une fenêtre PowerShell :

```powershell
$PSVersionTable.PSVersion
```

## Installation depuis le dépôt Git

### Clonage du dépôt

1. Ouvrez une fenêtre PowerShell et naviguez vers le répertoire où vous souhaitez cloner le dépôt :

```powershell
cd C:\Chemin\Vers\Votre\Repertoire
```

2. Clonez le dépôt Git :

```powershell
git clone https://github.com/votre-organisation/roadmap-parser.git
```

3. Naviguez vers le répertoire du module :

```powershell
cd roadmap-parser
```

### Installation manuelle

1. Copiez le répertoire du module dans l'un des chemins de modules PowerShell. Pour trouver les chemins disponibles, exécutez :

```powershell
$env:PSModulePath -split ';'
```

2. Généralement, vous pouvez utiliser le chemin utilisateur :

```powershell
Copy-Item -Path ".\tools\scripts\roadmap-parser\module" -Destination "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\RoadmapParser" -Recurse -Force
```

Pour PowerShell 7, utilisez plutôt :

```powershell
Copy-Item -Path ".\tools\scripts\roadmap-parser\module" -Destination "$env:USERPROFILE\Documents\PowerShell\Modules\RoadmapParser" -Recurse -Force
```

## Installation depuis un package

Si vous disposez d'un package NuGet ou d'un module PowerShell Gallery, vous pouvez l'installer comme suit :

### Depuis PowerShell Gallery (à venir)

```powershell
Install-Module -Name RoadmapParser -Scope CurrentUser
```

### Depuis un fichier .nupkg

```powershell
Install-Module -Name .\RoadmapParser.nupkg -Scope CurrentUser
```

## Vérification de l'installation

Pour vérifier que le module a été correctement installé, exécutez :

```powershell
Get-Module -Name RoadmapParser -ListAvailable
```

## Chargement du module

Pour charger le module dans votre session PowerShell actuelle, exécutez :

```powershell
Import-Module -Name RoadmapParser
```

Pour voir les commandes disponibles dans le module :

```powershell
Get-Command -Module RoadmapParser
```

## Configuration initiale

Après l'installation, vous pouvez configurer le module en créant un fichier de configuration :

1. Créez un répertoire de configuration :

```powershell
$configDir = Join-Path -Path $env:USERPROFILE -ChildPath ".roadmap-parser"
New-Item -Path $configDir -ItemType Directory -Force | Out-Null
```

2. Créez un fichier de configuration de base :

```powershell
$configFile = Join-Path -Path $configDir -ChildPath "config.json"
$config = @{
    LogLevel = "Info"
    LogFile = Join-Path -Path $configDir -ChildPath "roadmap-parser.log"
    DefaultRoadmapPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\Roadmaps"
    EnablePerformanceLogging = $true
    MaxLogSize = 10MB
    EnableLogRotation = $true
    MaxLogFiles = 5
}
$config | ConvertTo-Json | Set-Content -Path $configFile -Encoding UTF8
```

## Mise à jour du module

Pour mettre à jour le module à partir du dépôt Git :

1. Naviguez vers le répertoire du dépôt :

```powershell
cd C:\Chemin\Vers\Votre\Repertoire\roadmap-parser
```

2. Tirez les dernières modifications :

```powershell
git pull
```

3. Réinstallez le module comme décrit dans la section "Installation manuelle".

## Désinstallation

Pour désinstaller le module :

```powershell
Uninstall-Module -Name RoadmapParser -Force
```

Si vous avez installé le module manuellement, supprimez le répertoire du module :

```powershell
Remove-Item -Path "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\RoadmapParser" -Recurse -Force
```

Pour PowerShell 7 :

```powershell
Remove-Item -Path "$env:USERPROFILE\Documents\PowerShell\Modules\RoadmapParser" -Recurse -Force
```

## Résolution des problèmes

### Le module ne se charge pas

Si vous rencontrez des problèmes lors du chargement du module, vérifiez les points suivants :

1. Assurez-vous que le module est installé dans l'un des chemins de modules PowerShell :

```powershell
$env:PSModulePath -split ';'
```

2. Vérifiez la politique d'exécution PowerShell :

```powershell
Get-ExecutionPolicy
```

Si la politique est restrictive, vous pouvez la modifier pour votre session actuelle :

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

3. Vérifiez les erreurs de chargement du module :

```powershell
Import-Module -Name RoadmapParser -Verbose
```

### Problèmes de dépendances

Si vous rencontrez des problèmes liés aux dépendances, assurez-vous que toutes les dépendances requises sont installées :

```powershell
# Exemple d'installation de dépendances
Install-Module -Name Pester -Scope CurrentUser -Force
```

## Support

Si vous rencontrez des problèmes ou avez des questions, veuillez :

1. Consulter la [documentation](../api/index.md)
2. Vérifier les [problèmes connus](https://github.com/votre-organisation/roadmap-parser/issues)
3. Ouvrir un nouveau problème sur GitHub si nécessaire

## Licence

Ce module est distribué sous la licence MIT. Voir le fichier LICENSE pour plus de détails.
