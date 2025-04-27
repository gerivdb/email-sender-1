<#
.SYNOPSIS
    Test simple du chargement du module RoadmapParserCore.

.DESCRIPTION
    Ce script teste le chargement du module RoadmapParserCore de maniÃ¨re simple.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# DÃ©finir le chemin du module
$modulePath = Split-Path -Parent $PSScriptRoot
$moduleName = "RoadmapParserCore"
$moduleManifestPath = Join-Path -Path $modulePath -ChildPath "$moduleName.psd1"

Write-Host "Test de chargement du module $moduleName"
Write-Host "Chemin du manifeste: $moduleManifestPath"

# VÃ©rifier que le fichier manifeste existe
if (Test-Path -Path $moduleManifestPath) {
    Write-Host "Le fichier manifeste du module existe" -ForegroundColor Green
} else {
    Write-Host "Le fichier manifeste du module n'existe pas" -ForegroundColor Red
    exit 1
}

# VÃ©rifier que le manifeste est valide
try {
    $manifest = Test-ModuleManifest -Path $moduleManifestPath -ErrorAction Stop
    Write-Host "Le manifeste du module est valide" -ForegroundColor Green
    Write-Host "Nom du module: $($manifest.Name)"
    Write-Host "Version du module: $($manifest.Version)"
} catch {
    Write-Host "Le manifeste du module n'est pas valide: $_" -ForegroundColor Red
    exit 1
}

# Essayer d'importer le module
try {
    Import-Module -Name $moduleManifestPath -Force -ErrorAction Stop
    Write-Host "Le module a Ã©tÃ© importÃ© avec succÃ¨s" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'importation du module: $_" -ForegroundColor Red
    exit 1
}

# VÃ©rifier que le module est chargÃ©
if (Get-Module -Name $moduleName) {
    Write-Host "Le module est chargÃ©" -ForegroundColor Green
} else {
    Write-Host "Le module n'est pas chargÃ©" -ForegroundColor Red
    exit 1
}

# Obtenir les fonctions exportÃ©es
$exportedFunctions = Get-Command -Module $moduleName
Write-Host "Nombre de fonctions exportÃ©es: $($exportedFunctions.Count)" -ForegroundColor Cyan

if ($exportedFunctions.Count -gt 0) {
    Write-Host "Le module exporte des fonctions" -ForegroundColor Green
    
    # Afficher les 10 premiÃ¨res fonctions
    Write-Host "PremiÃ¨res fonctions exportÃ©es:" -ForegroundColor Cyan
    $exportedFunctions | Select-Object -First 10 | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Cyan
    }
} else {
    Write-Host "Le module n'exporte aucune fonction" -ForegroundColor Red
    exit 1
}

# VÃ©rifier la structure des rÃ©pertoires
$expectedDirectories = @(
    (Join-Path -Path $modulePath -ChildPath "Functions"),
    (Join-Path -Path $modulePath -ChildPath "Functions\Common"),
    (Join-Path -Path $modulePath -ChildPath "Functions\Private"),
    (Join-Path -Path $modulePath -ChildPath "Functions\Public"),
    (Join-Path -Path $modulePath -ChildPath "Exceptions"),
    (Join-Path -Path $modulePath -ChildPath "Config"),
    (Join-Path -Path $modulePath -ChildPath "Resources"),
    (Join-Path -Path $modulePath -ChildPath "docs")
)

$allDirectoriesExist = $true
foreach ($directory in $expectedDirectories) {
    if (Test-Path -Path $directory -PathType Container) {
        Write-Host "Le rÃ©pertoire $directory existe" -ForegroundColor Green
    } else {
        Write-Host "Le rÃ©pertoire $directory n'existe pas" -ForegroundColor Red
        $allDirectoriesExist = $false
    }
}

if ($allDirectoriesExist) {
    Write-Host "Tous les rÃ©pertoires requis existent" -ForegroundColor Green
} else {
    Write-Host "Certains rÃ©pertoires requis n'existent pas" -ForegroundColor Red
    exit 1
}

Write-Host "Test de chargement du module terminÃ© avec succÃ¨s" -ForegroundColor Green
