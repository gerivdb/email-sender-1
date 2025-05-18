# Script de test simple pour Invoke-UnifiedParallel
Write-Host "Test simple de Invoke-UnifiedParallel"

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
    return "Traitement de l'élément $item terminé"
}

# Tester Invoke-UnifiedParallel avec UseRunspacePool
Write-Host "Test de Invoke-UnifiedParallel avec UseRunspacePool..."
try {
    $results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $testData -MaxThreads 2 -UseRunspacePool -Verbose
    
    # Afficher les résultats
    Write-Host "Nombre de résultats: $($results.Count)"
    foreach ($result in $results) {
        Write-Host "Résultat: $($result.Value) - Durée: $($result.Duration.TotalMilliseconds) ms"
    }
} catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

# Nettoyer
Clear-UnifiedParallel -Verbose

Write-Host "Test terminé."
