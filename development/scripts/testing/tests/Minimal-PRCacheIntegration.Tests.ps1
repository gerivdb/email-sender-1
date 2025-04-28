#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intÃ©gration minimaux pour le systÃ¨me de cache d'analyse des pull requests.
.DESCRIPTION
    Ce fichier contient des tests d'intÃ©gration minimaux pour le systÃ¨me de cache d'analyse
    des pull requests, vÃ©rifiant les fonctionnalitÃ©s de base du cache.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Requires: Pester v5.0+, PRAnalysisCache.psm1
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemin du module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRAnalysisCache.psm1"

# VÃ©rifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Module PRAnalysisCache.psm1 non trouvÃ© Ã  l'emplacement: $modulePath"
}

# Importer le module
Import-Module $modulePath -Force

# CrÃ©er un rÃ©pertoire de test
$testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRCacheMinimalTest"
if (-not (Test-Path -Path $testCachePath)) {
    New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null
} else {
    # Nettoyer le rÃ©pertoire
    Get-ChildItem -Path $testCachePath -File | Remove-Item -Force
}

Describe "PRCache Minimal Integration Tests" {
    It "ExÃ©cute un flux de travail de base avec le cache" {
        # CrÃ©er un cache
        $cache = New-PRAnalysisCache -MaxMemoryItems 100
        $cache | Should -Not -BeNullOrEmpty
        $cache.DiskCachePath = $testCachePath
        
        # Ajouter un Ã©lÃ©ment au cache
        $cache.SetItem("TestKey", "TestValue", (New-TimeSpan -Hours 1))
        
        # VÃ©rifier que l'Ã©lÃ©ment a Ã©tÃ© ajoutÃ©
        $cache.GetItem("TestKey") | Should -Be "TestValue"
        
        # VÃ©rifier que le fichier de cache a Ã©tÃ© crÃ©Ã©
        $cacheFile = Join-Path -Path $testCachePath -ChildPath "$($cache.NormalizeKey("TestKey")).xml"
        Test-Path -Path $cacheFile | Should -Be $true
        
        # Supprimer l'Ã©lÃ©ment du cache
        $cache.RemoveItem("TestKey")
        
        # VÃ©rifier que l'Ã©lÃ©ment a Ã©tÃ© supprimÃ©
        $cache.GetItem("TestKey") | Should -BeNullOrEmpty
        
        # VÃ©rifier que le fichier de cache a Ã©tÃ© supprimÃ©
        Test-Path -Path $cacheFile | Should -Be $false
    }
}
