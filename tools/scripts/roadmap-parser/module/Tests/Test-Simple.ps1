# Script de test trÃ¨s simple pour le module RoadmapParserCore

# DÃ©finir le chemin du module
$modulePath = Split-Path -Parent $PSScriptRoot
$moduleName = "RoadmapParserCore"
$moduleManifestPath = Join-Path -Path $modulePath -ChildPath "$moduleName.psd1"

Write-Host "Test du module $moduleName" -ForegroundColor Cyan
Write-Host "Chemin du manifeste: $moduleManifestPath" -ForegroundColor Cyan

# Importer le module
Import-Module -Name $moduleManifestPath -Force

# VÃ©rifier si la fonction est disponible
if (Get-Command -Name "ConvertFrom-MarkdownToRoadmap" -ErrorAction SilentlyContinue) {
    Write-Host "La fonction ConvertFrom-MarkdownToRoadmap est disponible." -ForegroundColor Green
    
    # Tester la fonction
    $roadmapPath = Join-Path -Path $modulePath -ChildPath "..\..\..\Roadmap\roadmap_complete_converted.md"
    if (Test-Path -Path $roadmapPath) {
        Write-Host "Test de la fonction avec le fichier $roadmapPath" -ForegroundColor Cyan
        $roadmap = ConvertFrom-MarkdownToRoadmap -FilePath $roadmapPath
        Write-Host "Roadmap crÃ©Ã©e avec succÃ¨s." -ForegroundColor Green
    } else {
        Write-Host "Le fichier de roadmap n'existe pas: $roadmapPath" -ForegroundColor Red
    }
} else {
    Write-Host "La fonction ConvertFrom-MarkdownToRoadmap n'est pas disponible." -ForegroundColor Red
}

Write-Host "Test terminÃ©." -ForegroundColor Cyan
