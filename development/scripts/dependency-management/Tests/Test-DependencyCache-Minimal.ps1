# Test minimal pour le système de cache des dépendances
# Ce test vérifie que le cache fonctionne correctement

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$moduleFile = Join-Path -Path $modulePath -ChildPath "ModuleDependencyAnalyzer-Fixed.psm1"

try {
    # Importer le module
    Import-Module -Name $moduleFile -Force -ErrorAction Stop
    Write-Host "Module importé avec succès" -ForegroundColor Green

    # Vider le cache
    Clear-DependencyCache
    Write-Host "Cache vidé" -ForegroundColor Green
    
    # Vérifier que le cache est vide
    $initialCache = Get-DependencyCache
    Write-Host "Cache initial: $($initialCache | ConvertTo-Json -Depth 1)" -ForegroundColor Green
    
    # Résoudre le chemin d'une fonction
    $result = Resolve-ExternalFunctionPath -FunctionName "Get-Date"
    Write-Host "Fonction résolue: $($result.FunctionName) du module $($result.ModuleName)" -ForegroundColor Green
    
    # Vérifier que le cache est rempli
    $cacheAfterAnalysis = Get-DependencyCache
    Write-Host "Cache après analyse: $($cacheAfterAnalysis | ConvertTo-Json -Depth 1)" -ForegroundColor Green
    
    # Vider le cache
    Clear-DependencyCache
    Write-Host "Cache vidé à nouveau" -ForegroundColor Green
    
    # Vérifier que le cache est vide
    $cacheAfterClear = Get-DependencyCache
    Write-Host "Cache après vidage: $($cacheAfterClear | ConvertTo-Json -Depth 1)" -ForegroundColor Green

    # Tout est OK
    Write-Host "`nTest terminé avec succès !" -ForegroundColor Green
    exit 0
} catch {
    # Une erreur s'est produite
    Write-Host "Erreur : $_" -ForegroundColor Red
    exit 1
}
