# Script de test simple pour le module RoadmapParserCore

# DÃ©finir le chemin du module
$modulePath = Split-Path -Parent $PSScriptRoot
$moduleName = "RoadmapParserCore"
$moduleManifestPath = Join-Path -Path $modulePath -ChildPath "$moduleName.psd1"

Write-Host "Test du module $moduleName" -ForegroundColor Cyan
Write-Host "Chemin du manifeste: $moduleManifestPath" -ForegroundColor Cyan

# VÃ©rifier que le fichier manifeste existe
if (Test-Path -Path $moduleManifestPath) {
    Write-Host "Le fichier manifeste existe." -ForegroundColor Green
} else {
    Write-Host "Le fichier manifeste n'existe pas." -ForegroundColor Red
    exit
}

# Importer le module
try {
    Import-Module -Name $moduleManifestPath -Force -Verbose
    Write-Host "Module importÃ© avec succÃ¨s." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'importation du module: $_" -ForegroundColor Red
    exit
}

# Obtenir les fonctions exportÃ©es
$exportedFunctions = Get-Command -Module $moduleName
Write-Host "Nombre de fonctions exportÃ©es: $($exportedFunctions.Count)" -ForegroundColor Cyan

if ($exportedFunctions.Count -gt 0) {
    Write-Host "PremiÃ¨res fonctions exportÃ©es:" -ForegroundColor Cyan
    $exportedFunctions | Select-Object -First 5 | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "Aucune fonction n'est exportÃ©e par le module." -ForegroundColor Red
}

# Tester une fonction spÃ©cifique
if (Get-Command -Name "ConvertFrom-MarkdownToRoadmap" -Module $moduleName -ErrorAction SilentlyContinue) {
    Write-Host "La fonction ConvertFrom-MarkdownToRoadmap est disponible." -ForegroundColor Green
} else {
    Write-Host "La fonction ConvertFrom-MarkdownToRoadmap n'est pas disponible." -ForegroundColor Red
}

# Afficher les variables exportÃ©es
$exportedVariables = Get-Variable -Scope Global | Where-Object { $_.Module -eq $moduleName }
Write-Host "Nombre de variables exportÃ©es: $($exportedVariables.Count)" -ForegroundColor Cyan

# Afficher les alias exportÃ©s
$exportedAliases = Get-Alias | Where-Object { $_.ModuleName -eq $moduleName }
Write-Host "Nombre d'alias exportÃ©s: $($exportedAliases.Count)" -ForegroundColor Cyan

Write-Host "Test terminÃ©." -ForegroundColor Cyan
