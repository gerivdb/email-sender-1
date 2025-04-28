﻿#Requires -Version 5.1
<#
.SYNOPSIS
    Initialise la persistance du cache pour l'analyse des pull requests.

.DESCRIPTION
    Ce script configure et initialise un systÃ¨me de cache persistant pour
    l'analyse des pull requests, permettant de rÃ©utiliser les rÃ©sultats
    d'analyses prÃ©cÃ©dentes et d'amÃ©liorer les performances.

.PARAMETER CachePath
    Le chemin oÃ¹ stocker les fichiers du cache.
    Par dÃ©faut: "cache\pr-analysis"

.PARAMETER MaxMemoryItems
    Le nombre maximum d'Ã©lÃ©ments Ã  conserver en mÃ©moire.
    Par dÃ©faut: 1000

.PARAMETER DefaultTTLSeconds
    La durÃ©e de vie par dÃ©faut des Ã©lÃ©ments du cache en secondes.
    Par dÃ©faut: 86400 (1 jour)

.PARAMETER EvictionPolicy
    La politique d'Ã©viction Ã  utiliser pour le cache.
    Valeurs possibles: "LRU", "LFU"
    Par dÃ©faut: "LRU"

.PARAMETER Force
    Indique s'il faut rÃ©initialiser le cache existant.
    Par dÃ©faut: $false

.EXAMPLE
    .\Initialize-PRCachePersistence.ps1
    Initialise le cache avec les paramÃ¨tres par dÃ©faut.

.EXAMPLE
    .\Initialize-PRCachePersistence.ps1 -CachePath "D:\Cache\PR" -MaxMemoryItems 2000 -DefaultTTLSeconds 172800 -EvictionPolicy "LFU" -Force
    Initialise le cache avec des paramÃ¨tres personnalisÃ©s et force la rÃ©initialisation.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$CachePath = "cache\pr-analysis",

    [Parameter()]
    [int]$MaxMemoryItems = 1000,

    [Parameter()]
    [int]$DefaultTTLSeconds = 86400, # 1 jour

    [Parameter()]
    [ValidateSet("LRU", "LFU")]
    [string]$EvictionPolicy = "LRU",

    [Parameter()]
    [switch]$Force
)

# Importer le module de cache
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\PRAnalysisCache.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module PRAnalysisCache non trouvÃ© Ã  l'emplacement: $modulePath"
    exit 1
}

# Fonction pour initialiser le cache
function Initialize-Cache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [int]$MaxItems,
        
        [Parameter(Mandatory = $true)]
        [int]$TTL,
        
        [Parameter(Mandatory = $true)]
        [string]$Policy,
        
        [Parameter(Mandatory = $true)]
        [bool]$ForceReset
    )

    try {
        # CrÃ©er le rÃ©pertoire du cache s'il n'existe pas
        if (-not (Test-Path -Path $Path)) {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
            Write-Host "RÃ©pertoire du cache crÃ©Ã©: $Path" -ForegroundColor Green
        }

        # VÃ©rifier si le cache existe dÃ©jÃ 
        $cacheConfigPath = Join-Path -Path $Path -ChildPath "cache_config.json"
        $cacheExists = Test-Path -Path $cacheConfigPath

        # Si le cache existe et que Force n'est pas spÃ©cifiÃ©, utiliser le cache existant
        if ($cacheExists -and -not $ForceReset) {
            Write-Host "Utilisation du cache existant: $Path" -ForegroundColor Yellow
            
            # Charger la configuration existante
            $cacheConfig = Get-Content -Path $cacheConfigPath -Raw | ConvertFrom-Json
            
            # CrÃ©er le cache avec la configuration existante
            $cache = New-PRAnalysisCache -Name $cacheConfig.Name -CachePath $cacheConfig.CachePath -DefaultTTLSeconds $cacheConfig.DefaultTTLSeconds
            
            # Afficher les statistiques du cache
            $stats = Get-PRCacheStatistics -Cache $cache
            Write-Host "Statistiques du cache:" -ForegroundColor Cyan
            Write-Host "  Nom: $($stats.Name)" -ForegroundColor White
            Write-Host "  Ã‰lÃ©ments en mÃ©moire: $($stats.ItemCount)" -ForegroundColor White
            Write-Host "  Ã‰lÃ©ments sur disque: $($stats.DiskItemCount)" -ForegroundColor White
            Write-Host "  Hits: $($stats.Hits)" -ForegroundColor White
            Write-Host "  Misses: $($stats.Misses)" -ForegroundColor White
            Write-Host "  Ratio de hits: $($stats.HitRatio)%" -ForegroundColor White
            
            return $cache
        }

        # Si le cache n'existe pas ou que Force est spÃ©cifiÃ©, crÃ©er un nouveau cache
        if (-not $cacheExists -or $ForceReset) {
            if ($cacheExists -and $ForceReset) {
                Write-Host "RÃ©initialisation du cache: $Path" -ForegroundColor Yellow
                
                # Supprimer les fichiers du cache
                Get-ChildItem -Path $Path -File | Remove-Item -Force
            } else {
                Write-Host "CrÃ©ation d'un nouveau cache: $Path" -ForegroundColor Green
            }
            
            # CrÃ©er le cache
            $cache = New-PRAnalysisCache -Name "PRAnalysisCache" -CachePath $Path -DefaultTTLSeconds $TTL
            
            # Enregistrer la configuration
            $cacheConfig = [PSCustomObject]@{
                Name = "PRAnalysisCache"
                CachePath = $Path
                DefaultTTLSeconds = $TTL
                MaxMemoryItems = $MaxItems
                EvictionPolicy = $Policy
                CreatedAt = Get-Date
                LastResetAt = Get-Date
            }
            
            $cacheConfig | ConvertTo-Json | Set-Content -Path $cacheConfigPath -Encoding UTF8
            
            Write-Host "Cache initialisÃ© avec succÃ¨s." -ForegroundColor Green
            
            return $cache
        }
    } catch {
        Write-Error "Erreur lors de l'initialisation du cache: $_"
        return $null
    }
}

# Fonction pour valider le cache
function Test-CacheValidity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Cache,
        
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        # VÃ©rifier si le cache est valide
        $testKey = "CacheValidityTest_$(Get-Random)"
        $testValue = "Test value at $(Get-Date)"
        
        # Essayer d'Ã©crire dans le cache
        $Cache.Set($testKey, $testValue)
        
        # Essayer de lire du cache
        $retrievedValue = $Cache.Get($testKey)
        
        # Nettoyer
        $Cache.Remove($testKey)
        
        # VÃ©rifier si la valeur rÃ©cupÃ©rÃ©e correspond
        if ($retrievedValue -eq $testValue) {
            Write-Host "Test de validitÃ© du cache rÃ©ussi." -ForegroundColor Green
            return $true
        } else {
            Write-Host "Test de validitÃ© du cache Ã©chouÃ©: la valeur rÃ©cupÃ©rÃ©e ne correspond pas." -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Error "Erreur lors du test de validitÃ© du cache: $_"
        return $false
    }
}

# Point d'entrÃ©e principal
try {
    # RÃ©soudre le chemin complet du cache
    $fullCachePath = $CachePath
    if (-not [System.IO.Path]::IsPathRooted($CachePath)) {
        $fullCachePath = Join-Path -Path $PWD -ChildPath $CachePath
    }

    # Initialiser le cache
    $cache = Initialize-Cache -Path $fullCachePath -MaxItems $MaxMemoryItems -TTL $DefaultTTLSeconds -Policy $EvictionPolicy -ForceReset $Force.IsPresent

    if ($null -eq $cache) {
        Write-Error "Ã‰chec de l'initialisation du cache."
        exit 1
    }

    # Tester la validitÃ© du cache
    $isValid = Test-CacheValidity -Cache $cache -Path $fullCachePath

    if (-not $isValid) {
        Write-Error "Le cache n'est pas valide. Essayez de rÃ©initialiser le cache avec le paramÃ¨tre -Force."
        exit 1
    }

    # Afficher un rÃ©sumÃ©
    Write-Host "`nRÃ©sumÃ© de l'initialisation du cache:" -ForegroundColor Cyan
    Write-Host "  Chemin du cache: $fullCachePath" -ForegroundColor White
    Write-Host "  Ã‰lÃ©ments maximum en mÃ©moire: $MaxMemoryItems" -ForegroundColor White
    Write-Host "  TTL par dÃ©faut: $DefaultTTLSeconds secondes" -ForegroundColor White
    Write-Host "  Politique d'Ã©viction: $EvictionPolicy" -ForegroundColor White
    
    # Retourner le cache
    return $cache
} catch {
    Write-Error "Erreur lors de l'initialisation de la persistance du cache: $_"
    exit 1
}
