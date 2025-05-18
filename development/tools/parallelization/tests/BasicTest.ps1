# Test basique pour le module UnifiedParallel
Write-Host "Test basique du module UnifiedParallel" -ForegroundColor Cyan

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
$config = Initialize-UnifiedParallel
Write-Host "Module initialisé avec succès" -ForegroundColor Green
Write-Host "Configuration: $($config | ConvertTo-Json -Depth 3)" -ForegroundColor Gray

# Tester Invoke-UnifiedParallel avec un petit ensemble de données
$testData = 1..5
Write-Host "`nTest de Invoke-UnifiedParallel avec 5 éléments" -ForegroundColor Yellow

$startTime = [datetime]::Now
$results = Invoke-UnifiedParallel -ScriptBlock {
    param($item)
    Start-Sleep -Milliseconds 100
    return "Traitement de l'élément $item terminé"
} -InputObject $testData -MaxThreads 2 -UseRunspacePool -NoProgress
$endTime = [datetime]::Now
$duration = ($endTime - $startTime).TotalMilliseconds

Write-Host "Durée d'exécution: $duration ms" -ForegroundColor White
Write-Host "Nombre de résultats: $($results.Count)" -ForegroundColor White

foreach ($result in $results) {
    Write-Host "  - $($result.Value)" -ForegroundColor Green
}

# Nettoyer
Clear-UnifiedParallel
Write-Host "`nTest terminé." -ForegroundColor Cyan
