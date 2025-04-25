# Script de test pour vérifier l'importation du module FileContentIndexer

# Chemin du module à tester
$moduleToTest = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\pr-testing\modules\FileContentIndexer.psm1"

# Vérifier que le module existe
if (-not (Test-Path -Path $moduleToTest)) {
    Write-Error "Module FileContentIndexer non trouvé à l'emplacement: $moduleToTest"
    exit 1
}

try {
    # Importer le module
    Write-Host "Tentative d'importation du module..." -ForegroundColor Cyan
    Import-Module $moduleToTest -Force -Verbose
    
    # Vérifier si le module est importé
    $module = Get-Module | Where-Object { $_.Path -eq $moduleToTest }
    if ($null -eq $module) {
        Write-Error "Le module n'a pas été importé correctement."
        exit 1
    }
    
    Write-Host "Module importé avec succès!" -ForegroundColor Green
    
    # Essayer de créer un indexeur
    Write-Host "Tentative de création d'un indexeur..." -ForegroundColor Cyan
    $indexer = New-FileContentIndexer -IndexPath "$env:TEMP\TestIndex" -PersistIndices $false
    
    if ($null -eq $indexer) {
        Write-Error "Impossible de créer un indexeur."
        exit 1
    }
    
    Write-Host "Indexeur créé avec succès!" -ForegroundColor Green
    Write-Host "Type de l'indexeur: $($indexer.GetType().FullName)" -ForegroundColor Yellow
    
    # Afficher les propriétés de l'indexeur
    Write-Host "Propriétés de l'indexeur:" -ForegroundColor Cyan
    $indexer | Format-List
    
    Write-Host "Test réussi!" -ForegroundColor Green
} catch {
    Write-Error "Erreur lors du test: $_"
    exit 1
}
