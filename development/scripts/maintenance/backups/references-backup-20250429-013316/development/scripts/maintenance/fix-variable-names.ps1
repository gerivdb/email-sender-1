<#
.SYNOPSIS
    Corrige les noms de variables dans les fichiers.

.DESCRIPTION
    Ce script corrige les noms de variables dans les fichiers pour qu'ils soient conformes aux conventions de nommage.

.PARAMETER FilePath
    Chemin vers le fichier à corriger.

.EXAMPLE
    .\fix-variable-names.ps1 -FilePath "development\scripts\integrated-manager.ps1"
    Corrige les noms de variables dans le fichier integrated-manager.ps1.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath
)

# Vérifier que le fichier existe
if (-not (Test-Path -Path $FilePath)) {
    Write-Error "Le fichier est introuvable : $FilePath"
    exit 1
}

# Lire le contenu du fichier
$content = Get-Content -Path $FilePath -Raw

# Remplacer les noms de variables
$content = $content -replace '\$roadmap-managerPath', '$roadmapManagerPath'
$content = $content -replace '\$config\.roadmap-manager', '$config.roadmapManager'

# Écrire le contenu modifié dans le fichier
Set-Content -Path $FilePath -Value $content -Encoding UTF8

Write-Host "Les noms de variables ont été corrigés dans le fichier $FilePath." -ForegroundColor Green
