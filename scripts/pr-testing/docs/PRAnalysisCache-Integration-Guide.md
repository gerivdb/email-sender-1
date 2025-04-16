# Guide d'intégration du système de cache PRAnalysisCache

Ce guide explique comment intégrer le système de cache PRAnalysisCache dans d'autres parties de l'application pour améliorer les performances des opérations coûteuses.

## Table des matières

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Utilisation de base](#utilisation-de-base)
4. [Intégration dans des scripts existants](#intégration-dans-des-scripts-existants)
5. [Bonnes pratiques](#bonnes-pratiques)
6. [Exemples d'intégration](#exemples-dintégration)
7. [Dépannage](#dépannage)

## Introduction

Le système de cache PRAnalysisCache est conçu pour améliorer les performances des opérations coûteuses en mettant en cache les résultats. Il offre les fonctionnalités suivantes :

- Stockage en mémoire pour un accès rapide
- Persistance sur disque pour une durabilité des données
- Gestion de l'expiration des éléments du cache
- Nettoyage automatique du cache en mémoire lorsque la limite est atteinte
- Gestion robuste des erreurs

## Installation

Pour utiliser le système de cache PRAnalysisCache, vous devez d'abord importer le module :

```powershell
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
$cacheModulePath = Join-Path -Path $modulesPath -ChildPath "PRAnalysisCache.psm1"

if (-not (Test-Path -Path $cacheModulePath)) {
    Write-Error "Module PRAnalysisCache.psm1 non trouvé à l'emplacement: $cacheModulePath"
    exit 1
}

Import-Module $cacheModulePath -Force
```

## Utilisation de base

### Création d'un cache

Pour créer un nouveau cache, utilisez la fonction `New-PRAnalysisCache` :

```powershell
# Créer un cache avec une limite de 1000 éléments en mémoire
$cache = New-PRAnalysisCache -MaxMemoryItems 1000

# Configurer le chemin du cache sur disque
$cachePath = Join-Path -Path $env:TEMP -ChildPath "MonCache"
if (-not (Test-Path -Path $cachePath)) {
    New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
}
$cache.DiskCachePath = $cachePath
```

### Ajout d'un élément au cache

Pour ajouter un élément au cache, utilisez la méthode `SetItem` :

```powershell
# Ajouter un élément avec une durée de vie de 1 heure
$cache.SetItem("MaCle", "MaValeur", (New-TimeSpan -Hours 1))

# Ajouter un objet complexe avec une durée de vie de 24 heures
$monObjet = @{
    Nom = "Test"
    Valeur = 42
    Date = Get-Date
}
$cache.SetItem("MonObjet", $monObjet, (New-TimeSpan -Hours 24))
```

### Récupération d'un élément du cache

Pour récupérer un élément du cache, utilisez la méthode `GetItem` :

```powershell
# Récupérer un élément du cache
$valeur = $cache.GetItem("MaCle")

# Vérifier si l'élément existe
if ($null -ne $valeur) {
    Write-Host "Élément trouvé dans le cache: $valeur"
} else {
    Write-Host "Élément non trouvé dans le cache."
}
```

### Suppression d'un élément du cache

Pour supprimer un élément du cache, utilisez la méthode `RemoveItem` :

```powershell
# Supprimer un élément du cache
$cache.RemoveItem("MaCle")
```

### Vidage du cache

Pour vider complètement le cache, utilisez la méthode `Clear` :

```powershell
# Vider le cache
$cache.Clear()
```

## Intégration dans des scripts existants

Pour intégrer le système de cache dans des scripts existants, suivez ces étapes :

1. Importez le module PRAnalysisCache
2. Créez un cache avec `New-PRAnalysisCache`
3. Générez une clé de cache unique pour chaque opération
4. Vérifiez si le résultat est déjà dans le cache
5. Si oui, utilisez le résultat du cache
6. Sinon, effectuez l'opération et stockez le résultat dans le cache

Voici un exemple d'intégration :

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
    
    # Créer un cache si demandé
    $cache = $null
    if ($UseCache) {
        $cache = New-PRAnalysisCache -MaxMemoryItems 1000
        $cachePath = Join-Path -Path $env:TEMP -ChildPath "MonCache"
        if (-not (Test-Path -Path $cachePath)) {
            New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
        }
        $cache.DiskCachePath = $cachePath
    }
    
    # Générer une clé de cache unique
    $cacheKey = "Operation:$InputData:$(Get-Date -Format 'yyyyMMdd')"
    
    # Vérifier le cache si activé
    if ($UseCache -and -not $ForceRefresh -and $null -ne $cache) {
        $cachedResult = $cache.GetItem($cacheKey)
        if ($null -ne $cachedResult) {
            Write-Verbose "Résultat récupéré du cache pour $InputData"
            return $cachedResult
        }
    }
    
    # Effectuer l'opération coûteuse
    Write-Verbose "Exécution de l'opération pour $InputData..."
    $result = Invoke-ExpensiveOperation -InputData $InputData
    
    # Stocker le résultat dans le cache si activé
    if ($UseCache -and $null -ne $cache) {
        $cache.SetItem($cacheKey, $result, (New-TimeSpan -Hours 24))
        Write-Verbose "Résultat stocké dans le cache pour $InputData"
    }
    
    return $result
}
```

## Bonnes pratiques

### Génération de clés de cache

- Utilisez des clés de cache uniques et significatives
- Incluez les paramètres d'entrée dans la clé de cache
- Incluez la date de modification des fichiers dans la clé de cache pour les opérations basées sur des fichiers
- Évitez les clés trop longues (la méthode `NormalizeKey` tronque les clés trop longues)

### Durée de vie des éléments

- Adaptez la durée de vie des éléments en fonction de la fréquence de changement des données
- Utilisez des durées plus courtes pour les données qui changent fréquemment
- Utilisez des durées plus longues pour les données qui changent rarement

### Gestion de la mémoire

- Limitez le nombre d'éléments en mémoire en fonction des ressources disponibles
- Utilisez des valeurs plus petites pour `MaxMemoryItems` sur les systèmes avec peu de mémoire
- Utilisez des valeurs plus grandes pour `MaxMemoryItems` sur les systèmes avec beaucoup de mémoire

### Invalidation du cache

- Invalidez le cache lorsque les données sources changent
- Utilisez le paramètre `ForceRefresh` pour forcer l'actualisation du cache
- Incluez la date de modification des fichiers dans la clé de cache pour une invalidation automatique

## Exemples d'intégration

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
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Warning "Le fichier n'existe pas: $FilePath"
        return $null
    }
    
    # Obtenir les informations sur le fichier
    $fileInfo = Get-Item -Path $FilePath
    
    # Créer un cache si demandé
    $cache = $null
    if ($UseCache) {
        $cache = New-PRAnalysisCache -MaxMemoryItems 1000
        $cachePath = Join-Path -Path $env:TEMP -ChildPath "FileAnalysisCache"
        if (-not (Test-Path -Path $cachePath)) {
            New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
        }
        $cache.DiskCachePath = $cachePath
    }
    
    # Générer une clé de cache unique basée sur le chemin du fichier et sa date de modification
    $cacheKey = "FileAnalysis:$($FilePath):$($fileInfo.LastWriteTimeUtc.Ticks)"
    
    # Vérifier le cache si activé
    if ($UseCache -and -not $ForceRefresh -and $null -ne $cache) {
        $cachedResult = $cache.GetItem($cacheKey)
        if ($null -ne $cachedResult) {
            Write-Verbose "Résultats récupérés du cache pour $FilePath"
            return $cachedResult
        }
    }
    
    # Analyser le fichier
    Write-Verbose "Analyse du fichier $FilePath..."
    $result = Invoke-FileAnalysis -FilePath $FilePath
    
    # Stocker les résultats dans le cache si activé
    if ($UseCache -and $null -ne $cache) {
        $cache.SetItem($cacheKey, $result, (New-TimeSpan -Hours 24))
        Write-Verbose "Résultats stockés dans le cache pour $FilePath"
    }
    
    return $result
}
```

### Exemple 2 : Détection de format

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
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Warning "Le fichier n'existe pas: $FilePath"
        return $null
    }
    
    # Obtenir les informations sur le fichier
    $fileInfo = Get-Item -Path $FilePath
    
    # Créer un cache si demandé
    $cache = $null
    if ($UseCache) {
        $cache = New-PRAnalysisCache -MaxMemoryItems 1000
        $cachePath = Join-Path -Path $env:TEMP -ChildPath "FormatDetectionCache"
        if (-not (Test-Path -Path $cachePath)) {
            New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
        }
        $cache.DiskCachePath = $cachePath
    }
    
    # Générer une clé de cache unique basée sur le chemin du fichier et sa date de modification
    $cacheKey = "FormatDetection:$($FilePath):$($fileInfo.LastWriteTimeUtc.Ticks)"
    
    # Vérifier le cache si activé
    if ($UseCache -and -not $ForceRefresh -and $null -ne $cache) {
        $cachedResult = $cache.GetItem($cacheKey)
        if ($null -ne $cachedResult) {
            Write-Verbose "Résultats de détection de format récupérés du cache pour $FilePath"
            return $cachedResult
        }
    }
    
    # Détecter le format du fichier
    Write-Verbose "Détection du format du fichier $FilePath..."
    $result = Invoke-FormatDetection -FilePath $FilePath
    
    # Stocker les résultats dans le cache si activé
    if ($UseCache -and $null -ne $cache) {
        $cache.SetItem($cacheKey, $result, (New-TimeSpan -Hours 24))
        Write-Verbose "Résultats de détection de format stockés dans le cache pour $FilePath"
    }
    
    return $result
}
```

## Dépannage

### Problèmes courants

#### Le cache ne fonctionne pas

- Vérifiez que le module PRAnalysisCache est correctement importé
- Vérifiez que le cache est correctement initialisé
- Vérifiez que le chemin du cache sur disque existe et est accessible en écriture
- Vérifiez que la clé de cache est correctement générée

#### Les résultats du cache sont obsolètes

- Vérifiez que la clé de cache inclut la date de modification des fichiers
- Utilisez le paramètre `ForceRefresh` pour forcer l'actualisation du cache
- Vérifiez que la durée de vie des éléments est adaptée à la fréquence de changement des données

#### Le cache utilise trop de mémoire

- Réduisez la valeur de `MaxMemoryItems`
- Utilisez des durées de vie plus courtes pour les éléments du cache
- Videz régulièrement le cache avec la méthode `Clear`

### Journalisation et débogage

Pour faciliter le débogage, ajoutez des messages de journalisation détaillés :

```powershell
# Activer la journalisation détaillée
$VerbosePreference = "Continue"

# Créer un cache
$cache = New-PRAnalysisCache -MaxMemoryItems 1000
$cachePath = Join-Path -Path $env:TEMP -ChildPath "DebugCache"
if (-not (Test-Path -Path $cachePath)) {
    New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
}
$cache.DiskCachePath = $cachePath

Write-Verbose "Cache initialisé avec 1000 éléments maximum en mémoire et stockage sur disque dans $cachePath"

# Ajouter un élément au cache
$cache.SetItem("TestKey", "TestValue", (New-TimeSpan -Hours 1))
Write-Verbose "Élément ajouté au cache: TestKey -> TestValue (durée de vie: 1 heure)"

# Récupérer un élément du cache
$value = $cache.GetItem("TestKey")
Write-Verbose "Élément récupéré du cache: TestKey -> $value"

# Vérifier les fichiers de cache sur disque
$diskCacheFiles = Get-ChildItem -Path $cachePath -Filter "*.xml"
Write-Verbose "Nombre de fichiers de cache sur disque: $($diskCacheFiles.Count)"
```

### Vérification de l'intégrité du cache

Pour vérifier l'intégrité du cache, utilisez le script `Test-PRCacheIntegration.ps1` :

```powershell
# Exécuter les tests d'intégration
.\Test-PRCacheIntegration.ps1 -TestType All
```

Ce script effectue des tests d'intégration pour vérifier que le système de cache fonctionne correctement avec différents types d'analyses.
