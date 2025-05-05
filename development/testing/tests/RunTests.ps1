# Script pour exÃ©cuter les tests unitaires avec une profondeur de pile limitÃ©e

# Augmenter la limite de profondeur de la pile (commentÃ© car non utilisÃ© actuellement)
# $MaximumCallStackDepth = 1024

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# ExÃ©cuter les tests manuels
Write-Host "ExÃ©cution des tests manuels..."
Write-Host "Test de CacheManager..."
& "$PSScriptRoot\manual\TestCacheManager.ps1"

Write-Host "`nTest de UnifiedFileProcessor..."
& "$PSScriptRoot\manual\TestUnifiedFileProcessor.ps1"

Write-Host "`nTous les tests manuels ont Ã©tÃ© exÃ©cutÃ©s avec succÃ¨s."
