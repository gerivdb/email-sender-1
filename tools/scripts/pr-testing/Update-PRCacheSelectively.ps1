#Requires -Version 5.1
<#
.SYNOPSIS
    Met Ã  jour sÃ©lectivement le cache d'analyse des pull requests.

.DESCRIPTION
    Ce script permet de mettre Ã  jour ou d'invalider sÃ©lectivement des Ã©lÃ©ments
    du cache d'analyse des pull requests, en fonction de modÃ¨les ou de clÃ©s spÃ©cifiques.

.PARAMETER CachePath
    Le chemin du cache Ã  mettre Ã  jour.
    Par dÃ©faut: "cache\pr-analysis"

.PARAMETER Pattern
    Un modÃ¨le pour sÃ©lectionner les clÃ©s Ã  mettre Ã  jour.
    Exemple: "PR:*", "File:*.ps1"

.PARAMETER Keys
    Un tableau de clÃ©s spÃ©cifiques Ã  mettre Ã  jour.

.PARAMETER RemoveMatching
    Indique s'il faut supprimer les Ã©lÃ©ments correspondants au lieu de les mettre Ã  jour.
    Par dÃ©faut: $false

.PARAMETER Force
    Indique s'il faut forcer la mise Ã  jour sans confirmation.
    Par dÃ©faut: $false

.EXAMPLE
    .\Update-PRCacheSelectively.ps1 -Pattern "PR:42:*"
    Met Ã  jour tous les Ã©lÃ©ments du cache liÃ©s Ã  la pull request #42.

.EXAMPLE
    .\Update-PRCacheSelectively.ps1 -Keys "PR:42:File:script.ps1", "PR:42:File:module.psm1" -RemoveMatching
    Supprime les Ã©lÃ©ments spÃ©cifiÃ©s du cache.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding(DefaultParameterSetName = "ByPattern")]
param(
    [Parameter()]
    [string]$CachePath = "cache\pr-analysis",

    [Parameter(Mandatory = $true, ParameterSetName = "ByPattern")]
    [string]$Pattern,

    [Parameter(Mandatory = $true, ParameterSetName = "ByKeys")]
    [string[]]$Keys,

    [Parameter()]
    [switch]$RemoveMatching,

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

# Fonction pour mettre Ã  jour le cache
function Update-Cache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Cache,
        
        [Parameter(Mandatory = $true, ParameterSetName = "ByPattern")]
        [string]$PatternToMatch,
        
        [Parameter(Mandatory = $true, ParameterSetName = "ByKeys")]
        [string[]]$KeysToUpdate,
        
        [Parameter(Mandatory = $true)]
        [bool]$Remove,
        
        [Parameter(Mandatory = $true)]
        [bool]$ForceUpdate
    )

    try {
        # DÃ©terminer les Ã©lÃ©ments Ã  mettre Ã  jour
        $itemsToProcess = @()
        
        if ($PSCmdlet.ParameterSetName -eq "ByPattern") {
            Write-Host "Recherche des Ã©lÃ©ments correspondant au modÃ¨le: $PatternToMatch" -ForegroundColor Cyan
            
            # Utiliser la fonction du module pour mettre Ã  jour par modÃ¨le
            $count = Update-PRCacheSelectively -Cache $Cache -Pattern $PatternToMatch -RemoveMatching:$Remove
            
            Write-Host "$count Ã©lÃ©ments traitÃ©s." -ForegroundColor Green
            return $count
        } else {
            Write-Host "Traitement des clÃ©s spÃ©cifiÃ©es: $($KeysToUpdate.Count) clÃ©s" -ForegroundColor Cyan
            
            # Utiliser la fonction du module pour mettre Ã  jour par clÃ©s
            $count = Update-PRCacheSelectively -Cache $Cache -Keys $KeysToUpdate -RemoveMatching:$Remove
            
            Write-Host "$count Ã©lÃ©ments traitÃ©s." -ForegroundColor Green
            return $count
        }
    } catch {
        Write-Error "Erreur lors de la mise Ã  jour du cache: $_"
        return 0
    }
}

# Point d'entrÃ©e principal
try {
    # RÃ©soudre le chemin complet du cache
    $fullCachePath = $CachePath
    if (-not [System.IO.Path]::IsPathRooted($CachePath)) {
        $fullCachePath = Join-Path -Path $PWD -ChildPath $CachePath
    }

    # VÃ©rifier si le cache existe
    if (-not (Test-Path -Path $fullCachePath)) {
        Write-Error "Le rÃ©pertoire du cache n'existe pas: $fullCachePath"
        exit 1
    }

    # CrÃ©er le cache
    $cache = New-PRAnalysisCache -Name "PRAnalysisCache" -CachePath $fullCachePath
    if ($null -eq $cache) {
        Write-Error "Impossible de crÃ©er le cache."
        exit 1
    }

    # Afficher un avertissement si RemoveMatching est spÃ©cifiÃ©
    if ($RemoveMatching -and -not $Force) {
        $action = if ($PSCmdlet.ParameterSetName -eq "ByPattern") {
            "supprimer tous les Ã©lÃ©ments correspondant au modÃ¨le '$Pattern'"
        } else {
            "supprimer ${Keys.Count} Ã©lÃ©ments spÃ©cifiÃ©s"
        }
        
        $confirmation = Read-Host "ÃŠtes-vous sÃ»r de vouloir $action ? (O/N)"
        if ($confirmation -ne "O") {
            Write-Host "OpÃ©ration annulÃ©e." -ForegroundColor Yellow
            exit 0
        }
    }

    # Mettre Ã  jour le cache
    if ($PSCmdlet.ParameterSetName -eq "ByPattern") {
        $count = Update-Cache -Cache $cache -PatternToMatch $Pattern -Remove $RemoveMatching.IsPresent -ForceUpdate $Force.IsPresent
    } else {
        $count = Update-Cache -Cache $cache -KeysToUpdate $Keys -Remove $RemoveMatching.IsPresent -ForceUpdate $Force.IsPresent
    }

    # Afficher un rÃ©sumÃ©
    $action = if ($RemoveMatching) { "supprimÃ©s" } else { "mis Ã  jour" }
    Write-Host "`nRÃ©sumÃ© de l'opÃ©ration:" -ForegroundColor Cyan
    Write-Host "  Chemin du cache: $fullCachePath" -ForegroundColor White
    Write-Host "  Ã‰lÃ©ments $action: $count" -ForegroundColor White
    
    # Obtenir les statistiques du cache aprÃ¨s la mise Ã  jour
    $stats = Get-PRCacheStatistics -Cache $cache
    Write-Host "`nStatistiques du cache aprÃ¨s mise Ã  jour:" -ForegroundColor Cyan
    Write-Host "  Ã‰lÃ©ments en mÃ©moire: $($stats.ItemCount)" -ForegroundColor White
    Write-Host "  Ã‰lÃ©ments sur disque: $($stats.DiskItemCount)" -ForegroundColor White
    Write-Host "  Ratio de hits: $($stats.HitRatio)%" -ForegroundColor White
    
    return $count
} catch {
    Write-Error "Erreur lors de la mise Ã  jour sÃ©lective du cache: $_"
    exit 1
}
