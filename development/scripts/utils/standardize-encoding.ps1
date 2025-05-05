<#
.SYNOPSIS
    Standardise l'encodage de tous les fichiers du projet.
.DESCRIPTION
    Ce script standardise l'encodage de tous les fichiers du projet en les convertissant en UTF-8 avec BOM.
.PARAMETER Path
    Chemin vers le rÃ©pertoire racine du projet.
.PARAMETER Filter
    Filtre Ã  appliquer aux fichiers (par dÃ©faut, "*.ps1,*.psm1,*.psd1,*.md,*.json,*.xml,*.yml,*.yaml").
.PARAMETER WhatIf
    Si spÃ©cifiÃ©, simule les actions sans les exÃ©cuter.
.EXAMPLE
    .\standardize-encoding.ps1 -Path "D:\Projets\MonProjet" -WhatIf
    Simule la standardisation de l'encodage de tous les fichiers du projet.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter()]
    [string]$Path = (Get-Location).Path,
    
    [Parameter()]
    [string]$Filter = "*.ps1,*.psm1,*.psd1,*.md,*.json,*.xml,*.yml,*.yaml"
)

# Importer le module d'encodage
$encodingModulePath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-parser\module\Functions\Private\Encoding\Standardize-Encoding.ps1"
if (-not (Test-Path -Path $encodingModulePath)) {
    Write-Error "Le module d'encodage est introuvable Ã  l'emplacement : $encodingModulePath"
    exit 1
}

. $encodingModulePath

# Afficher les informations de dÃ©marrage
Write-Host "Standardisation de l'encodage des fichiers du projet..." -ForegroundColor Cyan
Write-Host "RÃ©pertoire racine : $Path" -ForegroundColor Cyan
Write-Host "Filtre : $Filter" -ForegroundColor Cyan

# Convertir le filtre en tableau
$filterArray = $Filter -split ','

# Traiter chaque filtre
foreach ($filterItem in $filterArray) {
    Write-Host "Traitement des fichiers correspondant au filtre : $filterItem" -ForegroundColor Yellow
    
    # Standardiser l'encodage des fichiers
    Standardize-Encoding -Path $Path -Recurse -Filter $filterItem -Encoding "UTF8BOM" -Verbose:$VerbosePreference -WhatIf:$WhatIfPreference
}

Write-Host "Standardisation de l'encodage terminÃ©e." -ForegroundColor Green
