# Script de test pour le module simplifiÃ©

# Chemin du module Ã  tester
$moduleToTest = Join-Path -Path $PSScriptRoot -ChildPath "SimpleFileContentIndexer.psm1"

# VÃ©rifier que le module existe
if (-not (Test-Path -Path $moduleToTest)) {
    Write-Error "Module SimpleFileContentIndexer non trouvÃ© Ã  l'emplacement: $moduleToTest"
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
    $indexer = New-SimpleFileContentIndexer -IndexPath "$env:TEMP\TestIndex" -PersistIndices $false
    
    if ($null -eq $indexer) {
        Write-Error "Impossible de crÃ©er un indexeur."
        exit 1
    }
    
    Write-Host "Indexeur crÃ©Ã© avec succÃ¨s!" -ForegroundColor Green
    
    # CrÃ©er un fichier de test
    $testFilePath = Join-Path -Path $env:TEMP -ChildPath "test_file.txt"
    "Ceci est un fichier de test" | Set-Content -Path $testFilePath
    
    # Indexer le fichier
    Write-Host "Tentative d'indexation d'un fichier..." -ForegroundColor Cyan
    $index = New-SimpleFileIndex -Indexer $indexer -FilePath $testFilePath
    
    if ($null -eq $index) {
        Write-Error "Impossible d'indexer le fichier."
        exit 1
    }
    
    Write-Host "Fichier indexÃ© avec succÃ¨s!" -ForegroundColor Green
    Write-Host "PropriÃ©tÃ©s de l'index:" -ForegroundColor Cyan
    $index | Format-List
    
    # Nettoyer
    Remove-Item -Path $testFilePath -Force
    
    Write-Host "Test rÃ©ussi!" -ForegroundColor Green
} catch {
    Write-Error "Erreur lors du test: $_"
    exit 1
}
