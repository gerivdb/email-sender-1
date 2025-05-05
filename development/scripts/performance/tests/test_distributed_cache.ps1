#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le cache distribuÃƒÂ© multi-langage.
.DESCRIPTION
    Ce script exÃƒÂ©cute des tests unitaires pour vÃƒÂ©rifier le bon fonctionnement
    du cache distribuÃƒÂ© multi-langage entre PowerShell et Python.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
    CompatibilitÃƒÂ©: PowerShell 5.1 et supÃƒÂ©rieur, Python 3.6 et supÃƒÂ©rieur
#>

# Importer le module Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installÃƒÂ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Importer le module d'architecture hybride
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "ParallelHybrid.psm1"
$cacheAdapterPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "CacheAdapter.psm1"

Import-Module $modulePath -Force
Import-Module $cacheAdapterPath -Force

# CrÃƒÂ©er un script Python pour tester le cache
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
import pickle

# Ajouter le rÃƒÂ©pertoire parent au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from python.shared_cache import SharedCache

def test_cache(cache_path, operation, key=None, value=None, ttl=None, dependencies=None):
    """Teste les opÃƒÂ©rations du cache."""
    # Initialiser le cache
    cache = SharedCache(cache_path=cache_path)
    
    if operation == "get":
        # RÃƒÂ©cupÃƒÂ©rer une valeur du cache
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
        # Invalider une valeur du cache et ses dÃƒÂ©pendances
        count = cache.invalidate(key)
        return {
            "operation": "invalidate",
            "key": key,
            "invalidated_count": count
        }
    
    elif operation == "stats":
        # RÃƒÂ©cupÃƒÂ©rer les statistiques du cache
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
            "error": f"OpÃƒÂ©ration inconnue : {operation}"
        }

def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description='Test du cache distribuÃƒÂ© multi-langage')
    parser.add_argument('--cache-path', required=True, help='Chemin vers le rÃƒÂ©pertoire du cache')
    parser.add_argument('--operation', required=True, choices=['get', 'set', 'remove', 'invalidate', 'stats', 'clear'], help='OpÃƒÂ©ration ÃƒÂ  effectuer')
    parser.add_argument('--key', help='ClÃƒÂ© pour les opÃƒÂ©rations get, set, remove, invalidate')
    parser.add_argument('--value', help='Valeur pour l\'opÃƒÂ©ration set')
    parser.add_argument('--ttl', type=int, help='DurÃƒÂ©e de vie pour l\'opÃƒÂ©ration set')
    parser.add_argument('--dependencies', help='DÃƒÂ©pendances pour l\'opÃƒÂ©ration set (sÃƒÂ©parÃƒÂ©es par des virgules)')
    parser.add_argument('--output', required=True, help='Fichier de sortie JSON')
    
    args = parser.parse_args()
    
    # Convertir les dÃƒÂ©pendances en liste
    dependencies = None
    if args.dependencies:
        dependencies = args.dependencies.split(',')
    
    # ExÃƒÂ©cuter l'opÃƒÂ©ration demandÃƒÂ©e
    result = test_cache(
        cache_path=args.cache_path,
        operation=args.operation,
        key=args.key,
        value=args.value,
        ttl=args.ttl,
        dependencies=dependencies
    )
    
    # Ãƒâ€°crire le rÃƒÂ©sultat
    try:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"Erreur lors de l'ÃƒÂ©criture du fichier de sortie : {e}", file=sys.stderr)
        sys.exit(1)
    
    sys.exit(0)

if __name__ == '__main__':
    main()
"@
    
    $pythonScript | Out-File -FilePath $pythonScriptPath -Encoding utf8
    Write-Host "Script Python de test du cache crÃƒÂ©ÃƒÂ© : $pythonScriptPath" -ForegroundColor Green
}

# Fonction pour exÃƒÂ©cuter une opÃƒÂ©ration de cache via Python
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
    
    # CrÃƒÂ©er des fichiers temporaires pour l'entrÃƒÂ©e et la sortie
    $outputFile = [System.IO.Path]::GetTempFileName()
    
    # PrÃƒÂ©parer les arguments pour le script Python
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
    
    # ExÃƒÂ©cuter le script Python
    try {
        $process = Start-Process -FilePath "python" -ArgumentList $pythonArgs -NoNewWindow -PassThru -Wait
        
        if ($process.ExitCode -ne 0) {
            Write-Error "Le script Python a ÃƒÂ©chouÃƒÂ© avec le code de sortie $($process.ExitCode)"
            return $null
        }
        
        # Lire le rÃƒÂ©sultat
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

# ExÃƒÂ©cuter les tests
Describe "Cache distribuÃƒÂ© multi-langage" {
    BeforeAll {
        # CrÃƒÂ©er un rÃƒÂ©pertoire de test pour le cache
        $testCachePath = Join-Path -Path $scriptPath -ChildPath "test_cache"
        if (-not (Test-Path -Path $testCachePath)) {
            New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null
        }
        
        # Configuration du cache
        $cacheConfig = @{
            CachePath = $testCachePath
            CacheType = "Hybrid"
            MaxMemorySize = 50
            MaxDiskSize = 100
            DefaultTTL = 3600
            EvictionPolicy = "LRU"
            Partitions = 4
            PreloadFactor = 0.2
        }
        
        # Initialiser le cache
        $cache = Initialize-SharedCache -Config $cacheConfig
        
        # Vider le cache
        Clear-SharedCache -Cache $cache
    }
    
    Context "OpÃƒÂ©rations de base du cache" {
        It "Devrait stocker et rÃƒÂ©cupÃƒÂ©rer une valeur depuis PowerShell" {
            # Stocker une valeur
            Set-SharedCacheItem -Cache $cache -Key "ps_test_key" -Value "test_value"
            
            # RÃƒÂ©cupÃƒÂ©rer la valeur
            $value = Get-SharedCacheItem -Cache $cache -Key "ps_test_key"
            
            # VÃƒÂ©rifier le rÃƒÂ©sultat
            $value | Should -Be "test_value"
        }
        
        It "Devrait stocker et rÃƒÂ©cupÃƒÂ©rer une valeur depuis Python" {
            # Stocker une valeur
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "set" -Key "py_test_key" -Value "test_value"
            
            # RÃƒÂ©cupÃƒÂ©rer la valeur
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "py_test_key"
            
            # VÃƒÂ©rifier le rÃƒÂ©sultat
            $result.result | Should -Be "test_value"
            $result.found | Should -Be $true
        }
        
        It "Devrait stocker depuis PowerShell et rÃƒÂ©cupÃƒÂ©rer depuis Python" {
            # Stocker une valeur depuis PowerShell
            Set-SharedCacheItem -Cache $cache -Key "ps_to_py_key" -Value "ps_to_py_value"
            
            # RÃƒÂ©cupÃƒÂ©rer la valeur depuis Python
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "ps_to_py_key"
            
            # VÃƒÂ©rifier le rÃƒÂ©sultat
            $result.result | Should -Be "ps_to_py_value"
            $result.found | Should -Be $true
        }
        
        It "Devrait stocker depuis Python et rÃƒÂ©cupÃƒÂ©rer depuis PowerShell" {
            # Stocker une valeur depuis Python
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "set" -Key "py_to_ps_key" -Value "py_to_ps_value"
            
            # RÃƒÂ©cupÃƒÂ©rer la valeur depuis PowerShell
            $value = Get-SharedCacheItem -Cache $cache -Key "py_to_ps_key"
            
            # VÃƒÂ©rifier le rÃƒÂ©sultat
            $value | Should -Be "py_to_ps_value"
        }
        
        It "Devrait supprimer une valeur depuis PowerShell" {
            # Stocker une valeur
            Set-SharedCacheItem -Cache $cache -Key "ps_remove_key" -Value "remove_value"
            
            # VÃƒÂ©rifier que la valeur existe
            $value = Get-SharedCacheItem -Cache $cache -Key "ps_remove_key"
            $value | Should -Be "remove_value"
            
            # Supprimer la valeur
            Remove-SharedCacheItem -Cache $cache -Key "ps_remove_key"
            
            # VÃƒÂ©rifier que la valeur n'existe plus
            $value = Get-SharedCacheItem -Cache $cache -Key "ps_remove_key"
            $value | Should -Be $null
        }
        
        It "Devrait supprimer une valeur depuis Python" {
            # Stocker une valeur
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "set" -Key "py_remove_key" -Value "remove_value"
            
            # VÃƒÂ©rifier que la valeur existe
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "py_remove_key"
            $result.result | Should -Be "remove_value"
            
            # Supprimer la valeur
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "remove" -Key "py_remove_key"
            
            # VÃƒÂ©rifier que la valeur n'existe plus
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "py_remove_key"
            $result.found | Should -Be $false
        }
        
        It "Devrait vider le cache depuis PowerShell" {
            # Stocker plusieurs valeurs
            Set-SharedCacheItem -Cache $cache -Key "clear_key1" -Value "clear_value1"
            Set-SharedCacheItem -Cache $cache -Key "clear_key2" -Value "clear_value2"
            
            # Vider le cache
            Clear-SharedCache -Cache $cache
            
            # VÃƒÂ©rifier que les valeurs n'existent plus
            $value1 = Get-SharedCacheItem -Cache $cache -Key "clear_key1"
            $value2 = Get-SharedCacheItem -Cache $cache -Key "clear_key2"
            
            $value1 | Should -Be $null
            $value2 | Should -Be $null
        }
        
        It "Devrait vider le cache depuis Python" {
            # Stocker plusieurs valeurs
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "set" -Key "py_clear_key1" -Value "clear_value1"
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "set" -Key "py_clear_key2" -Value "clear_value2"
            
            # Vider le cache
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "clear"
            
            # VÃƒÂ©rifier que les valeurs n'existent plus
            $result1 = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "py_clear_key1"
            $result2 = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "py_clear_key2"
            
            $result1.found | Should -Be $false
            $result2.found | Should -Be $false
        }
    }
    
    Context "DurÃƒÂ©e de vie (TTL) des ÃƒÂ©lÃƒÂ©ments" {
        It "Devrait respecter la durÃƒÂ©e de vie des ÃƒÂ©lÃƒÂ©ments" {
            # Stocker une valeur avec une durÃƒÂ©e de vie courte
            Set-SharedCacheItem -Cache $cache -Key "ttl_key" -Value "ttl_value" -TTL 1
            
            # VÃƒÂ©rifier que la valeur existe
            $value = Get-SharedCacheItem -Cache $cache -Key "ttl_key"
            $value | Should -Be "ttl_value"
            
            # Attendre que la durÃƒÂ©e de vie expire
            Start-Sleep -Seconds 2
            
            # VÃƒÂ©rifier que la valeur n'existe plus
            $value = Get-SharedCacheItem -Cache $cache -Key "ttl_key"
            $value | Should -Be $null
        }
        
        It "Devrait respecter la durÃƒÂ©e de vie des ÃƒÂ©lÃƒÂ©ments depuis Python" {
            # Stocker une valeur avec une durÃƒÂ©e de vie courte
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "set" -Key "py_ttl_key" -Value "ttl_value" -TTL 1
            
            # VÃƒÂ©rifier que la valeur existe
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "py_ttl_key"
            $result.result | Should -Be "ttl_value"
            
            # Attendre que la durÃƒÂ©e de vie expire
            Start-Sleep -Seconds 2
            
            # VÃƒÂ©rifier que la valeur n'existe plus
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "py_ttl_key"
            $result.found | Should -Be $false
        }
    }
    
    Context "DÃƒÂ©pendances et invalidation sÃƒÂ©lective" {
        It "Devrait invalider les ÃƒÂ©lÃƒÂ©ments dÃƒÂ©pendants" {
            # Stocker une valeur de base
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "set" -Key "base_key" -Value "base_value"
            
            # Stocker des valeurs dÃƒÂ©pendantes
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "set" -Key "dep_key1" -Value "dep_value1" -Dependencies @("base_key")
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "set" -Key "dep_key2" -Value "dep_value2" -Dependencies @("base_key")
            
            # VÃƒÂ©rifier que les valeurs existent
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "base_key"
            $result.result | Should -Be "base_value"
            
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "dep_key1"
            $result.result | Should -Be "dep_value1"
            
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "dep_key2"
            $result.result | Should -Be "dep_value2"
            
            # Invalider la valeur de base
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "invalidate" -Key "base_key"
            
            # VÃƒÂ©rifier que la valeur de base et les valeurs dÃƒÂ©pendantes n'existent plus
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "base_key"
            $result.found | Should -Be $false
            
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "dep_key1"
            $result.found | Should -Be $false
            
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "dep_key2"
            $result.found | Should -Be $false
        }
        
        It "Devrait invalider les dÃƒÂ©pendances en cascade" {
            # Stocker une valeur de base
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "set" -Key "cascade_base" -Value "base_value"
            
            # Stocker une valeur dÃƒÂ©pendante de niveau 1
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "set" -Key "cascade_level1" -Value "level1_value" -Dependencies @("cascade_base")
            
            # Stocker une valeur dÃƒÂ©pendante de niveau 2
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "set" -Key "cascade_level2" -Value "level2_value" -Dependencies @("cascade_level1")
            
            # VÃƒÂ©rifier que les valeurs existent
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "cascade_base"
            $result.result | Should -Be "base_value"
            
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "cascade_level1"
            $result.result | Should -Be "level1_value"
            
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "cascade_level2"
            $result.result | Should -Be "level2_value"
            
            # Invalider la valeur de base
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "invalidate" -Key "cascade_base"
            
            # VÃƒÂ©rifier que toutes les valeurs n'existent plus
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "cascade_base"
            $result.found | Should -Be $false
            
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "cascade_level1"
            $result.found | Should -Be $false
            
            $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key "cascade_level2"
            $result.found | Should -Be $false
        }
    }
    
    Context "Partitionnement et verrouillage" {
        It "Devrait gÃƒÂ©rer correctement les accÃƒÂ¨s concurrents" {
            # CrÃƒÂ©er un grand nombre de clÃƒÂ©s pour tester le partitionnement
            $numKeys = 100
            $keys = 1..$numKeys | ForEach-Object { "concurrent_key_$_" }
            $values = 1..$numKeys | ForEach-Object { "concurrent_value_$_" }
            
            # Stocker les valeurs en parallÃƒÂ¨le
            $jobs = @()
            for ($i = 0; $i -lt $numKeys; $i++) {
                $key = $keys[$i]
                $value = $values[$i]
                
                $jobs += Start-Job -ScriptBlock {
                    param($cachePath, $key, $value)
                    
                    # Importer le module
                    $scriptPath = "$cachePath\..\development\testing\tests"
                    $pythonScriptPath = Join-Path -Path $scriptPath -ChildPath "test_cache.py"
                    
                    # CrÃƒÂ©er des fichiers temporaires pour l'entrÃƒÂ©e et la sortie
                    $outputFile = [System.IO.Path]::GetTempFileName()
                    
                    # PrÃƒÂ©parer les arguments pour le script Python
                    $pythonArgs = @(
                        $pythonScriptPath,
                        "--cache-path", $cachePath,
                        "--operation", "set",
                        "--key", $key,
                        "--value", $value,
                        "--output", $outputFile
                    )
                    
                    # ExÃƒÂ©cuter le script Python
                    try {
                        $process = Start-Process -FilePath "python" -ArgumentList $pythonArgs -NoNewWindow -PassThru -Wait
                        
                        if ($process.ExitCode -ne 0) {
                            return $false
                        }
                        
                        return $true
                    }
                    finally {
                        # Nettoyer les fichiers temporaires
                        if (Test-Path -Path $outputFile) {
                            Remove-Item -Path $outputFile -Force
                        }
                    }
                } -ArgumentList $testCachePath, $key, $value
            }
            
            # Attendre que tous les jobs soient terminÃƒÂ©s
            $jobs | Wait-Job | Out-Null
            
            # VÃƒÂ©rifier les rÃƒÂ©sultats
            $results = $jobs | Receive-Job
            $successCount = ($results | Where-Object { $_ -eq $true }).Count
            
            # Nettoyer les jobs
            $jobs | Remove-Job
            
            # VÃƒÂ©rifier que toutes les opÃƒÂ©rations ont rÃƒÂ©ussi
            $successCount | Should -Be $numKeys
            
            # VÃƒÂ©rifier que toutes les valeurs sont correctement stockÃƒÂ©es
            $successCount = 0
            for ($i = 0; $i -lt $numKeys; $i++) {
                $key = $keys[$i]
                $value = $values[$i]
                
                $result = Invoke-PythonCacheOperation -CachePath $testCachePath -Operation "get" -Key $key
                if ($result.result -eq $value) {
                    $successCount++
                }
            }
            
            $successCount | Should -Be $numKeys
        }
    }
    
    AfterAll {
        # Nettoyer le rÃƒÂ©pertoire de test
        if (Test-Path -Path $testCachePath) {
            Remove-Item -Path $testCachePath -Recurse -Force
        }
    }
}
