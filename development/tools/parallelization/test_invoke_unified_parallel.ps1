# Script de test pour Invoke-UnifiedParallel
# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel

# Créer des données de test
$testData = 1..10

# Définir un script block de test
$scriptBlock = {
    param($item)
    # Simuler un traitement
    Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 500)
    return "Traitement de l'élément $item terminé"
}

# Tester Invoke-UnifiedParallel
Write-Host "Test de Invoke-UnifiedParallel avec $($testData.Count) éléments..."
$results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $testData -MaxThreads 4

# Afficher les résultats
Write-Host "Nombre de résultats: $($results.Count)"
foreach ($result in $results) {
    Write-Host "Résultat: $($result.Value) - Durée: $($result.Duration.TotalMilliseconds) ms"
}

# Nettoyer
Clear-UnifiedParallel

Write-Host "Test terminé avec succès."
