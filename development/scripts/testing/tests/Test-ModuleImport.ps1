# Script de test pour vÃ©rifier l'importation du module FileContentIndexer

# Chemin du module Ã  tester
$moduleToTest = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\pr-testing\modules\FileContentIndexer.psm1"

# VÃ©rifier que le module existe
if (-not (Test-Path -Path $moduleToTest)) {
    Write-Error "Module FileContentIndexer non trouvÃ© Ã  l'emplacement: $moduleToTest"
    exit 1
}

try {
    # Importer le module
    Write-Host "Tentative d'importation du module..." -ForegroundColor Cyan
    Import-Module $moduleToTest -Force -Verbose
    
    # VÃ©rifier si le module est importÃ©
    $module = Get-Module | Where-Object { $_.Path -eq $moduleToTest }
    if ($null -eq $module) {
        Write-Error "Le module n'a pas Ã©tÃ© importÃ© correctement."
        exit 1
    }
    
    Write-Host "Module importÃ© avec succÃ¨s!" -ForegroundColor Green
    
    # Essayer de crÃ©er un indexeur
    Write-Host "Tentative de crÃ©ation d'un indexeur..." -ForegroundColor Cyan
    $indexer = New-FileContentIndexer -IndexPath "$env:TEMP\TestIndex" -PersistIndices $false
    
    if ($null -eq $indexer) {
        Write-Error "Impossible de crÃ©er un indexeur."
        exit 1
    }
    
    Write-Host "Indexeur crÃ©Ã© avec succÃ¨s!" -ForegroundColor Green
    Write-Host "Type de l'indexeur: $($indexer.GetType().FullName)" -ForegroundColor Yellow
    
    # Afficher les propriÃ©tÃ©s de l'indexeur
    Write-Host "PropriÃ©tÃ©s de l'indexeur:" -ForegroundColor Cyan
    $indexer | Format-List
    
    Write-Host "Test rÃ©ussi!" -ForegroundColor Green
} catch {
    Write-Error "Erreur lors du test: $_"
    exit 1
}
