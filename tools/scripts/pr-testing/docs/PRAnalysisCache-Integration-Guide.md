# Guide d'intÃ©gration du systÃ¨me de cache PRAnalysisCache

Ce guide explique comment intÃ©grer le systÃ¨me de cache PRAnalysisCache dans d'autres parties de l'application pour amÃ©liorer les performances des opÃ©rations coÃ»teuses.

## Table des matiÃ¨res

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Utilisation de base](#utilisation-de-base)
4. [IntÃ©gration dans des scripts existants](#intÃ©gration-dans-des-scripts-existants)
5. [Bonnes pratiques](#bonnes-pratiques)
6. [Exemples d'intÃ©gration](#exemples-dintÃ©gration)
7. [DÃ©pannage](#dÃ©pannage)

## Introduction

Le systÃ¨me de cache PRAnalysisCache est conÃ§u pour amÃ©liorer les performances des opÃ©rations coÃ»teuses en mettant en cache les rÃ©sultats. Il offre les fonctionnalitÃ©s suivantes :

- Stockage en mÃ©moire pour un accÃ¨s rapide
- Persistance sur disque pour une durabilitÃ© des donnÃ©es
- Gestion de l'expiration des Ã©lÃ©ments du cache
- Nettoyage automatique du cache en mÃ©moire lorsque la limite est atteinte
- Gestion robuste des erreurs

## Installation

Pour utiliser le systÃ¨me de cache PRAnalysisCache, vous devez d'abord importer le module :

```powershell
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
$cacheModulePath = Join-Path -Path $modulesPath -ChildPath "PRAnalysisCache.psm1"

if (-not (Test-Path -Path $cacheModulePath)) {
    Write-Error "Module PRAnalysisCache.psm1 non trouvÃ© Ã  l'emplacement: $cacheModulePath"
    exit 1
}

Import-Module $cacheModulePath -Force
```

## Utilisation de base

### CrÃ©ation d'un cache

Pour crÃ©er un nouveau cache, utilisez la fonction `New-PRAnalysisCache` :

```powershell
# CrÃ©er un cache avec une limite de 1000 Ã©lÃ©ments en mÃ©moire
$cache = New-PRAnalysisCache -MaxMemoryItems 1000

# Configurer le chemin du cache sur disque
$cachePath = Join-Path -Path $env:TEMP -ChildPath "MonCache"
if (-not (Test-Path -Path $cachePath)) {
    New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
}
$cache.DiskCachePath = $cachePath
```

### Ajout d'un Ã©lÃ©ment au cache

Pour ajouter un Ã©lÃ©ment au cache, utilisez la mÃ©thode `SetItem` :

```powershell
# Ajouter un Ã©lÃ©ment avec une durÃ©e de vie de 1 heure
$cache.SetItem("MaCle", "MaValeur", (New-TimeSpan -Hours 1))

# Ajouter un objet complexe avec une durÃ©e de vie de 24 heures
$monObjet = @{
    Nom = "Test"
    Valeur = 42
    Date = Get-Date
}
$cache.SetItem("MonObjet", $monObjet, (New-TimeSpan -Hours 24))
```

### RÃ©cupÃ©ration d'un Ã©lÃ©ment du cache

Pour rÃ©cupÃ©rer un Ã©lÃ©ment du cache, utilisez la mÃ©thode `GetItem` :

```powershell
# RÃ©cupÃ©rer un Ã©lÃ©ment du cache
$valeur = $cache.GetItem("MaCle")

# VÃ©rifier si l'Ã©lÃ©ment existe
if ($null -ne $valeur) {
    Write-Host "Ã‰lÃ©ment trouvÃ© dans le cache: $valeur"
} else {
    Write-Host "Ã‰lÃ©ment non trouvÃ© dans le cache."
}
```

### Suppression d'un Ã©lÃ©ment du cache

Pour supprimer un Ã©lÃ©ment du cache, utilisez la mÃ©thode `RemoveItem` :

```powershell
# Supprimer un Ã©lÃ©ment du cache
$cache.RemoveItem("MaCle")
```

### Vidage du cache

Pour vider complÃ¨tement le cache, utilisez la mÃ©thode `Clear` :

```powershell
# Vider le cache
$cache.Clear()
```

## IntÃ©gration dans des scripts existants

Pour intÃ©grer le systÃ¨me de cache dans des scripts existants, suivez ces Ã©tapes :

1. Importez le module PRAnalysisCache
2. CrÃ©ez un cache avec `New-PRAnalysisCache`
3. GÃ©nÃ©rez une clÃ© de cache unique pour chaque opÃ©ration
4. VÃ©rifiez si le rÃ©sultat est dÃ©jÃ  dans le cache
5. Si oui, utilisez le rÃ©sultat du cache
6. Sinon, effectuez l'opÃ©ration et stockez le rÃ©sultat dans le cache

Voici un exemple d'intÃ©gration :

```powershell
function Invoke-CachedOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputData,
        
        [Parameter()]
        [switch]$UseCache = $true,
        
        [Parameter()]
        [switch]$ForceRefresh
    )
    
    # CrÃ©er un cache si demandÃ©
    $cache = $null
    if ($UseCache) {
        $cache = New-PRAnalysisCache -MaxMemoryItems 1000
        $cachePath = Join-Path -Path $env:TEMP -ChildPath "MonCache"
        if (-not (Test-Path -Path $cachePath)) {
            New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
        }
        $cache.DiskCachePath = $cachePath
    }
    
    # GÃ©nÃ©rer une clÃ© de cache unique
    $cacheKey = "Operation:$InputData:$(Get-Date -Format 'yyyyMMdd')"
    
    # VÃ©rifier le cache si activÃ©
    if ($UseCache -and -not $ForceRefresh -and $null -ne $cache) {
        $cachedResult = $cache.GetItem($cacheKey)
        if ($null -ne $cachedResult) {
            Write-Verbose "RÃ©sultat rÃ©cupÃ©rÃ© du cache pour $InputData"
            return $cachedResult
        }
    }
    
    # Effectuer l'opÃ©ration coÃ»teuse
    Write-Verbose "ExÃ©cution de l'opÃ©ration pour $InputData..."
    $result = Invoke-ExpensiveOperation -InputData $InputData
    
    # Stocker le rÃ©sultat dans le cache si activÃ©
    if ($UseCache -and $null -ne $cache) {
        $cache.SetItem($cacheKey, $result, (New-TimeSpan -Hours 24))
        Write-Verbose "RÃ©sultat stockÃ© dans le cache pour $InputData"
    }
    
    return $result
}
```

## Bonnes pratiques

### GÃ©nÃ©ration de clÃ©s de cache

- Utilisez des clÃ©s de cache uniques et significatives
- Incluez les paramÃ¨tres d'entrÃ©e dans la clÃ© de cache
- Incluez la date de modification des fichiers dans la clÃ© de cache pour les opÃ©rations basÃ©es sur des fichiers
- Ã‰vitez les clÃ©s trop longues (la mÃ©thode `NormalizeKey` tronque les clÃ©s trop longues)

### DurÃ©e de vie des Ã©lÃ©ments

- Adaptez la durÃ©e de vie des Ã©lÃ©ments en fonction de la frÃ©quence de changement des donnÃ©es
- Utilisez des durÃ©es plus courtes pour les donnÃ©es qui changent frÃ©quemment
- Utilisez des durÃ©es plus longues pour les donnÃ©es qui changent rarement

### Gestion de la mÃ©moire

- Limitez le nombre d'Ã©lÃ©ments en mÃ©moire en fonction des ressources disponibles
- Utilisez des valeurs plus petites pour `MaxMemoryItems` sur les systÃ¨mes avec peu de mÃ©moire
- Utilisez des valeurs plus grandes pour `MaxMemoryItems` sur les systÃ¨mes avec beaucoup de mÃ©moire

### Invalidation du cache

- Invalidez le cache lorsque les donnÃ©es sources changent
- Utilisez le paramÃ¨tre `ForceRefresh` pour forcer l'actualisation du cache
- Incluez la date de modification des fichiers dans la clÃ© de cache pour une invalidation automatique

## Exemples d'intÃ©gration

### Exemple 1 : Analyse de fichiers

```powershell
function Invoke-CachedFileAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter()]
        [switch]$UseCache = $true,
        
        [Parameter()]
        [switch]$ForceRefresh
    )
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Warning "Le fichier n'existe pas: $FilePath"
        return $null
    }
    
    # Obtenir les informations sur le fichier
    $fileInfo = Get-Item -Path $FilePath
    
    # CrÃ©er un cache si demandÃ©
    $cache = $null
    if ($UseCache) {
        $cache = New-PRAnalysisCache -MaxMemoryItems 1000
        $cachePath = Join-Path -Path $env:TEMP -ChildPath "FileAnalysisCache"
        if (-not (Test-Path -Path $cachePath)) {
            New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
        }
        $cache.DiskCachePath = $cachePath
    }
    
    # GÃ©nÃ©rer une clÃ© de cache unique basÃ©e sur le chemin du fichier et sa date de modification
    $cacheKey = "FileAnalysis:$($FilePath):$($fileInfo.LastWriteTimeUtc.Ticks)"
    
    # VÃ©rifier le cache si activÃ©
    if ($UseCache -and -not $ForceRefresh -and $null -ne $cache) {
        $cachedResult = $cache.GetItem($cacheKey)
        if ($null -ne $cachedResult) {
            Write-Verbose "RÃ©sultats rÃ©cupÃ©rÃ©s du cache pour $FilePath"
            return $cachedResult
        }
    }
    
    # Analyser le fichier
    Write-Verbose "Analyse du fichier $FilePath..."
    $result = Invoke-FileAnalysis -FilePath $FilePath
    
    # Stocker les rÃ©sultats dans le cache si activÃ©
    if ($UseCache -and $null -ne $cache) {
        $cache.SetItem($cacheKey, $result, (New-TimeSpan -Hours 24))
        Write-Verbose "RÃ©sultats stockÃ©s dans le cache pour $FilePath"
    }
    
    return $result
}
```

### Exemple 2 : DÃ©tection de format

```powershell
function Invoke-CachedFormatDetection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter()]
        [switch]$UseCache = $true,
        
        [Parameter()]
        [switch]$ForceRefresh
    )
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Warning "Le fichier n'existe pas: $FilePath"
        return $null
    }
    
    # Obtenir les informations sur le fichier
    $fileInfo = Get-Item -Path $FilePath
    
    # CrÃ©er un cache si demandÃ©
    $cache = $null
    if ($UseCache) {
        $cache = New-PRAnalysisCache -MaxMemoryItems 1000
        $cachePath = Join-Path -Path $env:TEMP -ChildPath "FormatDetectionCache"
        if (-not (Test-Path -Path $cachePath)) {
            New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
        }
        $cache.DiskCachePath = $cachePath
    }
    
    # GÃ©nÃ©rer une clÃ© de cache unique basÃ©e sur le chemin du fichier et sa date de modification
    $cacheKey = "FormatDetection:$($FilePath):$($fileInfo.LastWriteTimeUtc.Ticks)"
    
    # VÃ©rifier le cache si activÃ©
    if ($UseCache -and -not $ForceRefresh -and $null -ne $cache) {
        $cachedResult = $cache.GetItem($cacheKey)
        if ($null -ne $cachedResult) {
            Write-Verbose "RÃ©sultats de dÃ©tection de format rÃ©cupÃ©rÃ©s du cache pour $FilePath"
            return $cachedResult
        }
    }
    
    # DÃ©tecter le format du fichier
    Write-Verbose "DÃ©tection du format du fichier $FilePath..."
    $result = Invoke-FormatDetection -FilePath $FilePath
    
    # Stocker les rÃ©sultats dans le cache si activÃ©
    if ($UseCache -and $null -ne $cache) {
        $cache.SetItem($cacheKey, $result, (New-TimeSpan -Hours 24))
        Write-Verbose "RÃ©sultats de dÃ©tection de format stockÃ©s dans le cache pour $FilePath"
    }
    
    return $result
}
```

## DÃ©pannage

### ProblÃ¨mes courants

#### Le cache ne fonctionne pas

- VÃ©rifiez que le module PRAnalysisCache est correctement importÃ©
- VÃ©rifiez que le cache est correctement initialisÃ©
- VÃ©rifiez que le chemin du cache sur disque existe et est accessible en Ã©criture
- VÃ©rifiez que la clÃ© de cache est correctement gÃ©nÃ©rÃ©e

#### Les rÃ©sultats du cache sont obsolÃ¨tes

- VÃ©rifiez que la clÃ© de cache inclut la date de modification des fichiers
- Utilisez le paramÃ¨tre `ForceRefresh` pour forcer l'actualisation du cache
- VÃ©rifiez que la durÃ©e de vie des Ã©lÃ©ments est adaptÃ©e Ã  la frÃ©quence de changement des donnÃ©es

#### Le cache utilise trop de mÃ©moire

- RÃ©duisez la valeur de `MaxMemoryItems`
- Utilisez des durÃ©es de vie plus courtes pour les Ã©lÃ©ments du cache
- Videz rÃ©guliÃ¨rement le cache avec la mÃ©thode `Clear`

### Journalisation et dÃ©bogage

Pour faciliter le dÃ©bogage, ajoutez des messages de journalisation dÃ©taillÃ©s :

```powershell
# Activer la journalisation dÃ©taillÃ©e
$VerbosePreference = "Continue"

# CrÃ©er un cache
$cache = New-PRAnalysisCache -MaxMemoryItems 1000
$cachePath = Join-Path -Path $env:TEMP -ChildPath "DebugCache"
if (-not (Test-Path -Path $cachePath)) {
    New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
}
$cache.DiskCachePath = $cachePath

Write-Verbose "Cache initialisÃ© avec 1000 Ã©lÃ©ments maximum en mÃ©moire et stockage sur disque dans $cachePath"

# Ajouter un Ã©lÃ©ment au cache
$cache.SetItem("TestKey", "TestValue", (New-TimeSpan -Hours 1))
Write-Verbose "Ã‰lÃ©ment ajoutÃ© au cache: TestKey -> TestValue (durÃ©e de vie: 1 heure)"

# RÃ©cupÃ©rer un Ã©lÃ©ment du cache
$value = $cache.GetItem("TestKey")
Write-Verbose "Ã‰lÃ©ment rÃ©cupÃ©rÃ© du cache: TestKey -> $value"

# VÃ©rifier les fichiers de cache sur disque
$diskCacheFiles = Get-ChildItem -Path $cachePath -Filter "*.xml"
Write-Verbose "Nombre de fichiers de cache sur disque: $($diskCacheFiles.Count)"
```

### VÃ©rification de l'intÃ©gritÃ© du cache

Pour vÃ©rifier l'intÃ©gritÃ© du cache, utilisez le script `Test-PRCacheIntegration.ps1` :

```powershell
# ExÃ©cuter les tests d'intÃ©gration
.\Test-PRCacheIntegration.ps1 -TestType All
```

Ce script effectue des tests d'intÃ©gration pour vÃ©rifier que le systÃ¨me de cache fonctionne correctement avec diffÃ©rents types d'analyses.
