#Requires -Version 5.1
<#
.SYNOPSIS
    Met à jour sélectivement le cache d'analyse des pull requests.

.DESCRIPTION
    Ce script permet de mettre à jour ou d'invalider sélectivement des éléments
    du cache d'analyse des pull requests, en fonction de modèles ou de clés spécifiques.

.PARAMETER CachePath
    Le chemin du cache à mettre à jour.
    Par défaut: "cache\pr-analysis"

.PARAMETER Pattern
    Un modèle pour sélectionner les clés à mettre à jour.
    Exemple: "PR:*", "File:*.ps1"

.PARAMETER Keys
    Un tableau de clés spécifiques à mettre à jour.

.PARAMETER RemoveMatching
    Indique s'il faut supprimer les éléments correspondants au lieu de les mettre à jour.
    Par défaut: $false

.PARAMETER Force
    Indique s'il faut forcer la mise à jour sans confirmation.
    Par défaut: $false

.EXAMPLE
    .\Update-PRCacheSelectively.ps1 -Pattern "PR:42:*"
    Met à jour tous les éléments du cache liés à la pull request #42.

.EXAMPLE
    .\Update-PRCacheSelectively.ps1 -Keys "PR:42:File:script.ps1", "PR:42:File:module.psm1" -RemoveMatching
    Supprime les éléments spécifiés du cache.

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
    Write-Error "Module PRAnalysisCache non trouvé à l'emplacement: $modulePath"
    exit 1
}

# Fonction pour mettre à jour le cache
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
        # Déterminer les éléments à mettre à jour
        $itemsToProcess = @()
        
        if ($PSCmdlet.ParameterSetName -eq "ByPattern") {
            Write-Host "Recherche des éléments correspondant au modèle: $PatternToMatch" -ForegroundColor Cyan
            
            # Utiliser la fonction du module pour mettre à jour par modèle
            $count = Update-PRCacheSelectively -Cache $Cache -Pattern $PatternToMatch -RemoveMatching:$Remove
            
            Write-Host "$count éléments traités." -ForegroundColor Green
            return $count
        } else {
            Write-Host "Traitement des clés spécifiées: $($KeysToUpdate.Count) clés" -ForegroundColor Cyan
            
            # Utiliser la fonction du module pour mettre à jour par clés
            $count = Update-PRCacheSelectively -Cache $Cache -Keys $KeysToUpdate -RemoveMatching:$Remove
            
            Write-Host "$count éléments traités." -ForegroundColor Green
            return $count
        }
    } catch {
        Write-Error "Erreur lors de la mise à jour du cache: $_"
        return 0
    }
}

# Point d'entrée principal
try {
    # Résoudre le chemin complet du cache
    $fullCachePath = $CachePath
    if (-not [System.IO.Path]::IsPathRooted($CachePath)) {
        $fullCachePath = Join-Path -Path $PWD -ChildPath $CachePath
    }

    # Vérifier si le cache existe
    if (-not (Test-Path -Path $fullCachePath)) {
        Write-Error "Le répertoire du cache n'existe pas: $fullCachePath"
        exit 1
    }

    # Créer le cache
    $cache = New-PRAnalysisCache -Name "PRAnalysisCache" -CachePath $fullCachePath
    if ($null -eq $cache) {
        Write-Error "Impossible de créer le cache."
        exit 1
    }

    # Afficher un avertissement si RemoveMatching est spécifié
    if ($RemoveMatching -and -not $Force) {
        $action = if ($PSCmdlet.ParameterSetName -eq "ByPattern") {
            "supprimer tous les éléments correspondant au modèle '$Pattern'"
        } else {
            "supprimer ${Keys.Count} éléments spécifiés"
        }
        
        $confirmation = Read-Host "Êtes-vous sûr de vouloir $action ? (O/N)"
        if ($confirmation -ne "O") {
            Write-Host "Opération annulée." -ForegroundColor Yellow
            exit 0
        }
    }

    # Mettre à jour le cache
    if ($PSCmdlet.ParameterSetName -eq "ByPattern") {
        $count = Update-Cache -Cache $cache -PatternToMatch $Pattern -Remove $RemoveMatching.IsPresent -ForceUpdate $Force.IsPresent
    } else {
        $count = Update-Cache -Cache $cache -KeysToUpdate $Keys -Remove $RemoveMatching.IsPresent -ForceUpdate $Force.IsPresent
    }

    # Afficher un résumé
    $action = if ($RemoveMatching) { "supprimés" } else { "mis à jour" }
    Write-Host "`nRésumé de l'opération:" -ForegroundColor Cyan
    Write-Host "  Chemin du cache: $fullCachePath" -ForegroundColor White
    Write-Host "  Éléments $action: $count" -ForegroundColor White
    
    # Obtenir les statistiques du cache après la mise à jour
    $stats = Get-PRCacheStatistics -Cache $cache
    Write-Host "`nStatistiques du cache après mise à jour:" -ForegroundColor Cyan
    Write-Host "  Éléments en mémoire: $($stats.ItemCount)" -ForegroundColor White
    Write-Host "  Éléments sur disque: $($stats.DiskItemCount)" -ForegroundColor White
    Write-Host "  Ratio de hits: $($stats.HitRatio)%" -ForegroundColor White
    
    return $count
} catch {
    Write-Error "Erreur lors de la mise à jour sélective du cache: $_"
    exit 1
}
