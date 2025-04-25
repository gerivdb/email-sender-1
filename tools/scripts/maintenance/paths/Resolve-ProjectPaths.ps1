#Requires -Version 5.1
<#
.SYNOPSIS
    Résout et valide les chemins du projet en utilisant le module PathResolver.
.DESCRIPTION
    Ce script résout et valide les chemins du projet en utilisant le module PathResolver,
    et affiche des statistiques sur les chemins résolus.
.PARAMETER ConfigPath
    Chemin du fichier de configuration contenant les mappings de chemins.
.PARAMETER PathsToResolve
    Liste des chemins à résoudre et valider.
.PARAMETER OutputFormat
    Format de sortie des résultats. Valeurs possibles : "Console", "CSV", "JSON".
.PARAMETER OutputPath
    Chemin du fichier de sortie pour les formats CSV et JSON.
.EXAMPLE
    .\Resolve-ProjectPaths.ps1 -PathsToResolve "scripts\maintenance\paths\PathResolver.psm1", "config.json"
.EXAMPLE
    .\Resolve-ProjectPaths.ps1 -ConfigPath "paths_config.json" -OutputFormat CSV -OutputPath "C:\Temp\ResolvedPaths.csv"
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2025-04-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory = $false)]
    [string[]]$PathsToResolve,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "CSV", "JSON")]
    [string]$OutputFormat = "Console",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

# Importer le module PathResolver
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "PathResolver.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module PathResolver non trouvé: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Charger la configuration si spécifiée
if ($ConfigPath) {
    if (Test-Path -Path $ConfigPath) {
        try {
            $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            
            # Initialiser le module avec les paramètres de configuration
            $initParams = @{}
            
            if ($config.SearchPaths) {
                $initParams.AdditionalSearchPaths = $config.SearchPaths
            }
            
            if ($config.PathMappings) {
                $mappings = @{}
                foreach ($mapping in $config.PathMappings) {
                    $mappings[$mapping.Prefix] = $mapping.Target
                }
                $initParams.PathMappings = $mappings
            }
            
            if ($config.CacheMaxAgeHours) {
                $initParams.CacheMaxAgeHours = $config.CacheMaxAgeHours
            }
            
            if ($config.DisableCache) {
                $initParams.DisableCache = $config.DisableCache
            }
            
            Initialize-PathResolver @initParams
            
            Write-Host "Configuration chargée depuis '$ConfigPath'" -ForegroundColor Green
        }
        catch {
            Write-Error "Erreur lors du chargement de la configuration: $($_.Exception.Message)"
            exit 1
        }
    }
    else {
        Write-Error "Fichier de configuration non trouvé: $ConfigPath"
        exit 1
    }
}

# Si aucun chemin n'est spécifié, utiliser des chemins par défaut
if (-not $PathsToResolve) {
    $PathsToResolve = @(
        "scripts\maintenance\paths\PathResolver.psm1",
        "scripts\maintenance\encoding\Detect-VariableReferences.ps1",
        "scripts\maintenance\performance\PerformanceCounterManager.psm1",
        "config.json",
        "nonexistent_file.txt"
    )
}

# Résoudre et valider les chemins
$results = @()

foreach ($path in $PathsToResolve) {
    Write-Host "Résolution du chemin '$path'..." -ForegroundColor Cyan
    
    $resolvedPath = Get-ScriptPath -Path $path -UseCache
    $isValid = Test-ScriptPath -Path $path -RequiredPermissions "Read"
    
    $result = [PSCustomObject]@{
        OriginalPath = $path
        ResolvedPath = $resolvedPath
        Exists = $null -ne $resolvedPath
        IsValid = $isValid
        FileType = if ($resolvedPath) { [System.IO.Path]::GetExtension($resolvedPath).TrimStart('.') } else { $null }
        Size = if ($resolvedPath -and (Test-Path -Path $resolvedPath -PathType Leaf)) { (Get-Item -Path $resolvedPath).Length } else { $null }
    }
    
    $results += $result
    
    # Afficher le résultat dans la console
    if ($OutputFormat -eq "Console") {
        Write-Host "  Chemin original: $($result.OriginalPath)" -ForegroundColor White
        Write-Host "  Chemin résolu: $($result.ResolvedPath)" -ForegroundColor $(if ($result.Exists) { "Green" } else { "Red" })
        Write-Host "  Existe: $($result.Exists)" -ForegroundColor $(if ($result.Exists) { "Green" } else { "Red" })
        Write-Host "  Valide: $($result.IsValid)" -ForegroundColor $(if ($result.IsValid) { "Green" } else { "Red" })
        
        if ($result.Exists) {
            Write-Host "  Type de fichier: $($result.FileType)" -ForegroundColor White
            Write-Host "  Taille: $($result.Size) octets" -ForegroundColor White
        }
        
        Write-Host ""
    }
}

# Afficher les statistiques du cache
$statistics = Get-PathStatistics
Write-Host "Statistiques du cache:" -ForegroundColor Cyan
Write-Host "  Entrées dans le cache: $($statistics.CacheEntries)" -ForegroundColor White
Write-Host "  Âge moyen du cache: $($statistics.AverageAgeMinutes) minutes" -ForegroundColor White
Write-Host "  Cache activé: $($statistics.CacheEnabled)" -ForegroundColor White
Write-Host "  Âge maximum du cache: $($statistics.MaxCacheAgeHours) heures" -ForegroundColor White

Write-Host "`nChemins de recherche:" -ForegroundColor Cyan
foreach ($searchPath in $statistics.SearchPaths) {
    Write-Host "  $searchPath" -ForegroundColor White
}

Write-Host "`nMappings de chemins:" -ForegroundColor Cyan
foreach ($prefix in $statistics.PathMappings.Keys) {
    Write-Host "  $prefix -> $($statistics.PathMappings[$prefix])" -ForegroundColor White
}

# Exporter les résultats si nécessaire
if ($OutputFormat -ne "Console") {
    if (-not $OutputPath) {
        $OutputPath = Join-Path -Path $env:TEMP -ChildPath "ResolvedPaths.$($OutputFormat.ToLower())"
    }
    
    switch ($OutputFormat) {
        "CSV" {
            $results | Export-Csv -Path $OutputPath -NoTypeInformation
            Write-Host "`nDonnées exportées au format CSV: $OutputPath" -ForegroundColor Green
        }
        "JSON" {
            $results | ConvertTo-Json | Out-File -FilePath $OutputPath
            Write-Host "`nDonnées exportées au format JSON: $OutputPath" -ForegroundColor Green
        }
    }
}

# Retourner les résultats
return $results
