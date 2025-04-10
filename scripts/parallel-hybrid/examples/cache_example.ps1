#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'utilisation du cache distribué multi-langage.
.DESCRIPTION
    Ce script montre comment utiliser le cache distribué multi-langage
    pour partager des données entre PowerShell et Python.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
    Compatibilité: PowerShell 5.1 et supérieur, Python 3.6 et supérieur
#>

# Importer le module d'architecture hybride
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "ParallelHybrid.psm1"
Import-Module $modulePath -Force

# Créer un script Python pour tester le cache
$pythonScriptPath = Join-Path -Path $scriptPath -ChildPath "test_cache.py"
if (-not (Test-Path -Path $pythonScriptPath)) {
    $pythonScript = @"
#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import json
import argparse
import time
import random
from shared_cache import SharedCache

def test_cache(cache_path, operation, key=None, value=None, ttl=None, dependencies=None):
    """Teste les opérations du cache."""
    # Initialiser le cache
    cache = SharedCache(cache_path=cache_path)
    
    if operation == "get":
        # Récupérer une valeur du cache
        result = cache.get(key)
        return {
            "operation": "get",
            "key": key,
            "result": result,
            "found": result is not None
        }
    
    elif operation == "set":
        # Stocker une valeur dans le cache
        cache.set(key, value, ttl, dependencies)
        return {
            "operation": "set",
            "key": key,
            "value": value,
            "ttl": ttl,
            "dependencies": dependencies
        }
    
    elif operation == "remove":
        # Supprimer une valeur du cache
        cache.remove(key)
        return {
            "operation": "remove",
            "key": key
        }
    
    elif operation == "invalidate":
        # Invalider une valeur du cache et ses dépendances
        count = cache.invalidate(key)
        return {
            "operation": "invalidate",
            "key": key,
            "invalidated_count": count
        }
    
    elif operation == "stats":
        # Récupérer les statistiques du cache
        stats = cache.get_stats()
        return {
            "operation": "stats",
            "stats": stats
        }
    
    elif operation == "clear":
        # Vider le cache
        cache.clear()
        return {
            "operation": "clear"
        }
    
    else:
        return {
            "error": f"Opération inconnue : {operation}"
        }

def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description='Test du cache distribué multi-langage')
    parser.add_argument('--cache-path', required=True, help='Chemin vers le répertoire du cache')
    parser.add_argument('--operation', required=True, choices=['get', 'set', 'remove', 'invalidate', 'stats', 'clear'], help='Opération à effectuer')
    parser.add_argument('--key', help='Clé pour les opérations get, set, remove, invalidate')
    parser.add_argument('--value', help='Valeur pour l\'opération set')
    parser.add_argument('--ttl', type=int, help='Durée de vie pour l\'opération set')
    parser.add_argument('--dependencies', help='Dépendances pour l\'opération set (séparées par des virgules)')
    parser.add_argument('--output', required=True, help='Fichier de sortie JSON')
    
    args = parser.parse_args()
    
    # Convertir les dépendances en liste
    dependencies = None
    if args.dependencies:
        dependencies = args.dependencies.split(',')
    
    # Exécuter l'opération demandée
    result = test_cache(
        cache_path=args.cache_path,
        operation=args.operation,
        key=args.key,
        value=args.value,
        ttl=args.ttl,
        dependencies=dependencies
    )
    
    # Écrire le résultat
    try:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"Erreur lors de l'écriture du fichier de sortie : {e}", file=sys.stderr)
        sys.exit(1)
    
    sys.exit(0)

if __name__ == '__main__':
    main()
"@
    
    $pythonScript | Out-File -FilePath $pythonScriptPath -Encoding utf8
    Write-Host "Script Python de test du cache créé : $pythonScriptPath" -ForegroundColor Green
}

# Fonction pour exécuter une opération de cache via Python
function Invoke-PythonCacheOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CachePath,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("get", "set", "remove", "invalidate", "stats", "clear")]
        [string]$Operation,
        
        [Parameter(Mandatory = $false)]
        [string]$Key,
        
        [Parameter(Mandatory = $false)]
        [object]$Value,
        
        [Parameter(Mandatory = $false)]
        [int]$TTL,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Dependencies
    )
    
    # Créer des fichiers temporaires pour l'entrée et la sortie
    $outputFile = [System.IO.Path]::GetTempFileName()
    
    # Préparer les arguments pour le script Python
    $pythonArgs = @(
        $pythonScriptPath,
        "--cache-path", $CachePath,
        "--operation", $Operation,
        "--output", $outputFile
    )
    
    if ($Key) {
        $pythonArgs += @("--key", $Key)
    }
    
    if ($Value -ne $null) {
        $pythonArgs += @("--value", $Value.ToString())
    }
    
    if ($TTL) {
        $pythonArgs += @("--ttl", $TTL.ToString())
    }
    
    if ($Dependencies) {
        $pythonArgs += @("--dependencies", ($Dependencies -join ","))
    }
    
    # Exécuter le script Python
    try {
        $process = Start-Process -FilePath "python" -ArgumentList $pythonArgs -NoNewWindow -PassThru -Wait
        
        if ($process.ExitCode -ne 0) {
            Write-Error "Le script Python a échoué avec le code de sortie $($process.ExitCode)"
            return $null
        }
        
        # Lire le résultat
        $result = Get-Content -Path $outputFile -Raw | ConvertFrom-Json
        return $result
    }
    finally {
        # Nettoyer les fichiers temporaires
        if (Test-Path -Path $outputFile) {
            Remove-Item -Path $outputFile -Force
        }
    }
}

# Fonction pour exécuter une opération de cache via PowerShell
function Invoke-PowerShellCacheOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Cache,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("get", "set", "remove", "clear", "stats")]
        [string]$Operation,
        
        [Parameter(Mandatory = $false)]
        [string]$Key,
        
        [Parameter(Mandatory = $false)]
        [object]$Value,
        
        [Parameter(Mandatory = $false)]
        [int]$TTL
    )
    
    switch ($Operation) {
        "get" {
            $result = Get-SharedCacheItem -Cache $Cache -Key $Key
            return @{
                operation = "get"
                key = $Key
                result = $result
                found = $result -ne $null
            }
        }
        "set" {
            $result = Set-SharedCacheItem -Cache $Cache -Key $Key -Value $Value -TTL $TTL
            return @{
                operation = "set"
                key = $Key
                value = $Value
                ttl = $TTL
            }
        }
        "remove" {
            Remove-SharedCacheItem -Cache $Cache -Key $Key
            return @{
                operation = "remove"
                key = $Key
            }
        }
        "clear" {
            Clear-SharedCache -Cache $Cache
            return @{
                operation = "clear"
            }
        }
        "stats" {
            $stats = Get-SharedCacheStatistics -Cache $Cache
            return @{
                operation = "stats"
                stats = $stats
            }
        }
    }
}

# Fonction pour mesurer les performances
function Measure-Performance {
    param(
        [scriptblock]$ScriptBlock,
        [string]$Name = "Opération"
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & $ScriptBlock
    $stopwatch.Stop()
    
    Write-Host "$Name terminé en $($stopwatch.Elapsed.TotalSeconds) secondes" -ForegroundColor Cyan
    
    return $result
}

# Exemple 1 : Utilisation du cache distribué multi-langage
function Example-DistributedCache {
    Write-Host "`n=== Exemple 1 : Utilisation du cache distribué multi-langage ===" -ForegroundColor Yellow
    
    # Créer un répertoire pour le cache
    $cachePath = Join-Path -Path $scriptPath -ChildPath "cache"
    if (-not (Test-Path -Path $cachePath)) {
        New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
    }
    
    # Initialiser le cache partagé
    $cacheConfig = @{
        CachePath = $cachePath
        CacheType = "Hybrid"
        MaxMemorySize = 50
        MaxDiskSize = 100
        DefaultTTL = 3600
        EvictionPolicy = "LRU"
        Partitions = 4
        PreloadFactor = 0.2
    }
    
    $cache = Initialize-SharedCache -Config $cacheConfig
    Write-Host "Cache partagé initialisé : $($cache.CachePath)" -ForegroundColor Green
    
    # Stocker une valeur dans le cache depuis PowerShell
    $psResult = Measure-Performance -ScriptBlock {
        Invoke-PowerShellCacheOperation -Cache $cache -Operation "set" -Key "ps_key1" -Value "Valeur depuis PowerShell" -TTL 3600
    } -Name "Stockage depuis PowerShell"
    
    Write-Host "Résultat : $($psResult | ConvertTo-Json -Compress)" -ForegroundColor Green
    
    # Récupérer la valeur depuis Python
    $pyResult = Measure-Performance -ScriptBlock {
        Invoke-PythonCacheOperation -CachePath $cachePath -Operation "get" -Key "ps_key1"
    } -Name "Récupération depuis Python"
    
    Write-Host "Résultat : $($pyResult | ConvertTo-Json -Compress)" -ForegroundColor Green
    
    # Stocker une valeur dans le cache depuis Python
    $pyResult = Measure-Performance -ScriptBlock {
        Invoke-PythonCacheOperation -CachePath $cachePath -Operation "set" -Key "py_key1" -Value "Valeur depuis Python" -TTL 3600
    } -Name "Stockage depuis Python"
    
    Write-Host "Résultat : $($pyResult | ConvertTo-Json -Compress)" -ForegroundColor Green
    
    # Récupérer la valeur depuis PowerShell
    $psResult = Measure-Performance -ScriptBlock {
        Invoke-PowerShellCacheOperation -Cache $cache -Operation "get" -Key "py_key1"
    } -Name "Récupération depuis PowerShell"
    
    Write-Host "Résultat : $($psResult | ConvertTo-Json -Compress)" -ForegroundColor Green
    
    # Afficher les statistiques du cache
    $statsPs = Invoke-PowerShellCacheOperation -Cache $cache -Operation "stats"
    $statsPy = Invoke-PythonCacheOperation -CachePath $cachePath -Operation "stats"
    
    Write-Host "`nStatistiques du cache (PowerShell) :" -ForegroundColor Cyan
    $statsPs.stats | Format-Table -AutoSize
    
    Write-Host "`nStatistiques du cache (Python) :" -ForegroundColor Cyan
    $statsPy.stats | Format-Table -AutoSize
}

# Exemple 2 : Utilisation des dépendances et de l'invalidation sélective
function Example-DependenciesAndInvalidation {
    Write-Host "`n=== Exemple 2 : Utilisation des dépendances et de l'invalidation sélective ===" -ForegroundColor Yellow
    
    # Créer un répertoire pour le cache
    $cachePath = Join-Path -Path $scriptPath -ChildPath "cache"
    if (-not (Test-Path -Path $cachePath)) {
        New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
    }
    
    # Stocker des valeurs avec des dépendances
    Write-Host "Stockage de valeurs avec des dépendances..." -ForegroundColor Cyan
    
    # Stocker une valeur de base
    $result = Invoke-PythonCacheOperation -CachePath $cachePath -Operation "set" -Key "base_key" -Value "Valeur de base"
    Write-Host "Valeur de base stockée : $($result | ConvertTo-Json -Compress)" -ForegroundColor Green
    
    # Stocker des valeurs dépendantes
    $result = Invoke-PythonCacheOperation -CachePath $cachePath -Operation "set" -Key "dependent_key1" -Value "Valeur dépendante 1" -Dependencies @("base_key")
    Write-Host "Valeur dépendante 1 stockée : $($result | ConvertTo-Json -Compress)" -ForegroundColor Green
    
    $result = Invoke-PythonCacheOperation -CachePath $cachePath -Operation "set" -Key "dependent_key2" -Value "Valeur dépendante 2" -Dependencies @("base_key")
    Write-Host "Valeur dépendante 2 stockée : $($result | ConvertTo-Json -Compress)" -ForegroundColor Green
    
    # Stocker une valeur dépendante de niveau 2
    $result = Invoke-PythonCacheOperation -CachePath $cachePath -Operation "set" -Key "dependent_key3" -Value "Valeur dépendante 3" -Dependencies @("dependent_key1")
    Write-Host "Valeur dépendante 3 stockée : $($result | ConvertTo-Json -Compress)" -ForegroundColor Green
    
    # Vérifier que toutes les valeurs sont dans le cache
    Write-Host "`nVérification des valeurs dans le cache..." -ForegroundColor Cyan
    
    $result = Invoke-PythonCacheOperation -CachePath $cachePath -Operation "get" -Key "base_key"
    Write-Host "Valeur de base : $($result.result)" -ForegroundColor Green
    
    $result = Invoke-PythonCacheOperation -CachePath $cachePath -Operation "get" -Key "dependent_key1"
    Write-Host "Valeur dépendante 1 : $($result.result)" -ForegroundColor Green
    
    $result = Invoke-PythonCacheOperation -CachePath $cachePath -Operation "get" -Key "dependent_key2"
    Write-Host "Valeur dépendante 2 : $($result.result)" -ForegroundColor Green
    
    $result = Invoke-PythonCacheOperation -CachePath $cachePath -Operation "get" -Key "dependent_key3"
    Write-Host "Valeur dépendante 3 : $($result.result)" -ForegroundColor Green
    
    # Invalider la valeur de base
    Write-Host "`nInvalidation de la valeur de base..." -ForegroundColor Cyan
    
    $result = Invoke-PythonCacheOperation -CachePath $cachePath -Operation "invalidate" -Key "base_key"
    Write-Host "Résultat de l'invalidation : $($result | ConvertTo-Json -Compress)" -ForegroundColor Green
    Write-Host "Nombre d'éléments invalidés : $($result.invalidated_count)" -ForegroundColor Green
    
    # Vérifier que toutes les valeurs dépendantes ont été invalidées
    Write-Host "`nVérification des valeurs après invalidation..." -ForegroundColor Cyan
    
    $result = Invoke-PythonCacheOperation -CachePath $cachePath -Operation "get" -Key "base_key"
    Write-Host "Valeur de base : $($result.result)" -ForegroundColor ($result.found ? "Green" : "Red")
    
    $result = Invoke-PythonCacheOperation -CachePath $cachePath -Operation "get" -Key "dependent_key1"
    Write-Host "Valeur dépendante 1 : $($result.result)" -ForegroundColor ($result.found ? "Green" : "Red")
    
    $result = Invoke-PythonCacheOperation -CachePath $cachePath -Operation "get" -Key "dependent_key2"
    Write-Host "Valeur dépendante 2 : $($result.result)" -ForegroundColor ($result.found ? "Green" : "Red")
    
    $result = Invoke-PythonCacheOperation -CachePath $cachePath -Operation "get" -Key "dependent_key3"
    Write-Host "Valeur dépendante 3 : $($result.result)" -ForegroundColor ($result.found ? "Green" : "Red")
}

# Exemple 3 : Test de performance du cache distribué
function Example-CachePerformance {
    Write-Host "`n=== Exemple 3 : Test de performance du cache distribué ===" -ForegroundColor Yellow
    
    # Créer un répertoire pour le cache
    $cachePath = Join-Path -Path $scriptPath -ChildPath "cache"
    if (-not (Test-Path -Path $cachePath)) {
        New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
    }
    
    # Initialiser le cache partagé
    $cacheConfig = @{
        CachePath = $cachePath
        CacheType = "Hybrid"
        MaxMemorySize = 100
        MaxDiskSize = 200
        DefaultTTL = 3600
        EvictionPolicy = "LRU"
        Partitions = 8
        PreloadFactor = 0.2
    }
    
    $cache = Initialize-SharedCache -Config $cacheConfig
    
    # Vider le cache
    Clear-SharedCache -Cache $cache
    
    # Générer des données de test
    $numItems = 1000
    Write-Host "Génération de $numItems éléments de test..." -ForegroundColor Cyan
    
    $keys = 1..$numItems | ForEach-Object { "test_key_$_" }
    $values = 1..$numItems | ForEach-Object { "test_value_$_" }
    
    # Test d'écriture depuis PowerShell
    Write-Host "`nTest d'écriture depuis PowerShell..." -ForegroundColor Cyan
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    for ($i = 0; $i -lt $numItems; $i++) {
        Set-SharedCacheItem -Cache $cache -Key $keys[$i] -Value $values[$i]
    }
    
    $stopwatch.Stop()
    $writeTimePs = $stopwatch.Elapsed.TotalSeconds
    
    Write-Host "Temps d'écriture PowerShell : $writeTimePs secondes" -ForegroundColor Green
    Write-Host "Vitesse d'écriture PowerShell : $([Math]::Round($numItems / $writeTimePs, 2)) éléments/seconde" -ForegroundColor Green
    
    # Vider le cache
    Clear-SharedCache -Cache $cache
    
    # Test d'écriture depuis Python
    Write-Host "`nTest d'écriture depuis Python..." -ForegroundColor Cyan
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    for ($i = 0; $i -lt $numItems; $i++) {
        Invoke-PythonCacheOperation -CachePath $cachePath -Operation "set" -Key $keys[$i] -Value $values[$i] | Out-Null
    }
    
    $stopwatch.Stop()
    $writeTimePy = $stopwatch.Elapsed.TotalSeconds
    
    Write-Host "Temps d'écriture Python : $writeTimePy secondes" -ForegroundColor Green
    Write-Host "Vitesse d'écriture Python : $([Math]::Round($numItems / $writeTimePy, 2)) éléments/seconde" -ForegroundColor Green
    
    # Test de lecture depuis PowerShell
    Write-Host "`nTest de lecture depuis PowerShell..." -ForegroundColor Cyan
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    for ($i = 0; $i -lt $numItems; $i++) {
        $value = Get-SharedCacheItem -Cache $cache -Key $keys[$i]
    }
    
    $stopwatch.Stop()
    $readTimePs = $stopwatch.Elapsed.TotalSeconds
    
    Write-Host "Temps de lecture PowerShell : $readTimePs secondes" -ForegroundColor Green
    Write-Host "Vitesse de lecture PowerShell : $([Math]::Round($numItems / $readTimePs, 2)) éléments/seconde" -ForegroundColor Green
    
    # Test de lecture depuis Python
    Write-Host "`nTest de lecture depuis Python..." -ForegroundColor Cyan
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    for ($i = 0; $i -lt $numItems; $i++) {
        $value = Invoke-PythonCacheOperation -CachePath $cachePath -Operation "get" -Key $keys[$i] | Out-Null
    }
    
    $stopwatch.Stop()
    $readTimePy = $stopwatch.Elapsed.TotalSeconds
    
    Write-Host "Temps de lecture Python : $readTimePy secondes" -ForegroundColor Green
    Write-Host "Vitesse de lecture Python : $([Math]::Round($numItems / $readTimePy, 2)) éléments/seconde" -ForegroundColor Green
    
    # Afficher les statistiques du cache
    $stats = Get-SharedCacheStatistics -Cache $cache
    
    Write-Host "`nStatistiques du cache :" -ForegroundColor Cyan
    $stats | Format-Table -AutoSize
}

# Exécuter les exemples
try {
    # Installer les dépendances Python
    $installPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "install_dependencies.ps1"
    if (Test-Path -Path $installPath) {
        Write-Host "Installation des dépendances Python..." -ForegroundColor Yellow
        & $installPath
    }
    
    # Copier le module shared_cache.py dans le répertoire des exemples
    $sharedCachePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "python\shared_cache.py"
    $targetPath = Join-Path -Path $scriptPath -ChildPath "shared_cache.py"
    
    if (Test-Path -Path $sharedCachePath) {
        Copy-Item -Path $sharedCachePath -Destination $targetPath -Force
        Write-Host "Module shared_cache.py copié dans le répertoire des exemples." -ForegroundColor Green
    }
    
    # Exécuter les exemples
    Example-DistributedCache
    Example-DependenciesAndInvalidation
    Example-CachePerformance
}
catch {
    Write-Error "Erreur lors de l'exécution des exemples : $_"
}
finally {
    # Nettoyer les ressources
    Write-Host "`nNettoyage des ressources..." -ForegroundColor Yellow
    
    # Supprimer les fichiers temporaires
    Get-ChildItem -Path $env:TEMP -Filter "tmp*" | Where-Object { $_.CreationTime -gt (Get-Date).AddHours(-1) } | Remove-Item -Force
    
    Write-Host "Nettoyage terminé" -ForegroundColor Green
}
