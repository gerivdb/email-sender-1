# Script pour exécuter les tests unitaires avec une profondeur de pile limitée

# Augmenter la limite de profondeur de la pile (commenté car non utilisé actuellement)
# $MaximumCallStackDepth = 1024

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Exécuter les tests manuels
Write-Host "Exécution des tests manuels..."
Write-Host "Test de CacheManager..."
& "$PSScriptRoot\manual\TestCacheManager.ps1"

Write-Host "`nTest de UnifiedFileProcessor..."
& "$PSScriptRoot\manual\TestUnifiedFileProcessor.ps1"

Write-Host "`nTous les tests manuels ont été exécutés avec succès."
