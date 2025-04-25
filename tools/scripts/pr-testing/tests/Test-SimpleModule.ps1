# Script de test pour le module simplifié

# Chemin du module à tester
$moduleToTest = Join-Path -Path $PSScriptRoot -ChildPath "SimpleFileContentIndexer.psm1"

# Vérifier que le module existe
if (-not (Test-Path -Path $moduleToTest)) {
    Write-Error "Module SimpleFileContentIndexer non trouvé à l'emplacement: $moduleToTest"
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
    $indexer = New-SimpleFileContentIndexer -IndexPath "$env:TEMP\TestIndex" -PersistIndices $false
    
    if ($null -eq $indexer) {
        Write-Error "Impossible de créer un indexeur."
        exit 1
    }
    
    Write-Host "Indexeur créé avec succès!" -ForegroundColor Green
    
    # Créer un fichier de test
    $testFilePath = Join-Path -Path $env:TEMP -ChildPath "test_file.txt"
    "Ceci est un fichier de test" | Set-Content -Path $testFilePath
    
    # Indexer le fichier
    Write-Host "Tentative d'indexation d'un fichier..." -ForegroundColor Cyan
    $index = New-SimpleFileIndex -Indexer $indexer -FilePath $testFilePath
    
    if ($null -eq $index) {
        Write-Error "Impossible d'indexer le fichier."
        exit 1
    }
    
    Write-Host "Fichier indexé avec succès!" -ForegroundColor Green
    Write-Host "Propriétés de l'index:" -ForegroundColor Cyan
    $index | Format-List
    
    # Nettoyer
    Remove-Item -Path $testFilePath -Force
    
    Write-Host "Test réussi!" -ForegroundColor Green
} catch {
    Write-Error "Erreur lors du test: $_"
    exit 1
}
