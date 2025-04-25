#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intégration minimaux pour le système de cache d'analyse des pull requests.
.DESCRIPTION
    Ce fichier contient des tests d'intégration minimaux pour le système de cache d'analyse
    des pull requests, vérifiant les fonctionnalités de base du cache.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Requires: Pester v5.0+, PRAnalysisCache.psm1
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRAnalysisCache.psm1"

# Vérifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Module PRAnalysisCache.psm1 non trouvé à l'emplacement: $modulePath"
}

# Importer le module
Import-Module $modulePath -Force

# Créer un répertoire de test
$testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRCacheMinimalTest"
if (-not (Test-Path -Path $testCachePath)) {
    New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null
} else {
    # Nettoyer le répertoire
    Get-ChildItem -Path $testCachePath -File | Remove-Item -Force
}

Describe "PRCache Minimal Integration Tests" {
    It "Exécute un flux de travail de base avec le cache" {
        # Créer un cache
        $cache = New-PRAnalysisCache -MaxMemoryItems 100
        $cache | Should -Not -BeNullOrEmpty
        $cache.DiskCachePath = $testCachePath
        
        # Ajouter un élément au cache
        $cache.SetItem("TestKey", "TestValue", (New-TimeSpan -Hours 1))
        
        # Vérifier que l'élément a été ajouté
        $cache.GetItem("TestKey") | Should -Be "TestValue"
        
        # Vérifier que le fichier de cache a été créé
        $cacheFile = Join-Path -Path $testCachePath -ChildPath "$($cache.NormalizeKey("TestKey")).xml"
        Test-Path -Path $cacheFile | Should -Be $true
        
        # Supprimer l'élément du cache
        $cache.RemoveItem("TestKey")
        
        # Vérifier que l'élément a été supprimé
        $cache.GetItem("TestKey") | Should -BeNullOrEmpty
        
        # Vérifier que le fichier de cache a été supprimé
        Test-Path -Path $cacheFile | Should -Be $false
    }
}
