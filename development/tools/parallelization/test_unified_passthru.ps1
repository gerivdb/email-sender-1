# Script de test pour Invoke-UnifiedParallel avec PassThru
Write-Host "Test de Invoke-UnifiedParallel avec PassThru"

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "UnifiedParallel.psm1"
Import-Module $modulePath -Force -Verbose

# Initialiser le module
Initialize-UnifiedParallel -Verbose

# Créer des données de test
$testData = 1..5

# Définir un script block de test
$scriptBlock = {
    param($item)
    # Simuler un traitement
    Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 300)
    
    # Simuler une erreur pour l'élément 3
    if ($item -eq 3) {
        throw "Erreur simulée pour l'élément $item"
    }
    
    return "Traitement de l'élément $item terminé"
}

# Tester Invoke-UnifiedParallel avec UseRunspacePool et PassThru
Write-Host "Test de Invoke-UnifiedParallel avec UseRunspacePool et PassThru..."
try {
    $results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $testData -MaxThreads 2 -UseRunspacePool -PassThru -Verbose
    
    # Afficher les résultats
    Write-Host "Nombre de résultats: $($results.Results.Count)"
    Write-Host "Nombre d'erreurs: $($results.Errors.Count)"
    Write-Host "Nombre total d'éléments: $($results.TotalItems)"
    Write-Host "Nombre d'éléments traités: $($results.ProcessedItems)"
    Write-Host "Durée totale: $($results.Duration.TotalSeconds) secondes"
    
    # Afficher les résultats individuels
    foreach ($result in $results.Results) {
        if ($result.Success) {
            Write-Host "Résultat: $($result.Value)" -ForegroundColor Green
        } else {
            Write-Host "Erreur: $($result.Error.Exception.Message)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

# Nettoyer
Clear-UnifiedParallel -Verbose

Write-Host "Test terminé."
