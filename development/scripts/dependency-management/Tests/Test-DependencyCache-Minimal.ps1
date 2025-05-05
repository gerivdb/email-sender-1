# Test minimal pour le systÃ¨me de cache des dÃ©pendances
# Ce test vÃ©rifie que le cache fonctionne correctement

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$moduleFile = Join-Path -Path $modulePath -ChildPath "ModuleDependencyAnalyzer-Fixed.psm1"

try {
    # Importer le module
    Import-Module -Name $moduleFile -Force -ErrorAction Stop
    Write-Host "Module importÃ© avec succÃ¨s" -ForegroundColor Green

    # Vider le cache
    Clear-DependencyCache
    Write-Host "Cache vidÃ©" -ForegroundColor Green
    
    # VÃ©rifier que le cache est vide
    $initialCache = Get-DependencyCache
    Write-Host "Cache initial: $($initialCache | ConvertTo-Json -Depth 1)" -ForegroundColor Green
    
    # RÃ©soudre le chemin d'une fonction
    $result = Resolve-ExternalFunctionPath -FunctionName "Get-Date"
    Write-Host "Fonction rÃ©solue: $($result.FunctionName) du module $($result.ModuleName)" -ForegroundColor Green
    
    # VÃ©rifier que le cache est rempli
    $cacheAfterAnalysis = Get-DependencyCache
    Write-Host "Cache aprÃ¨s analyse: $($cacheAfterAnalysis | ConvertTo-Json -Depth 1)" -ForegroundColor Green
    
    # Vider le cache
    Clear-DependencyCache
    Write-Host "Cache vidÃ© Ã  nouveau" -ForegroundColor Green
    
    # VÃ©rifier que le cache est vide
    $cacheAfterClear = Get-DependencyCache
    Write-Host "Cache aprÃ¨s vidage: $($cacheAfterClear | ConvertTo-Json -Depth 1)" -ForegroundColor Green

    # Tout est OK
    Write-Host "`nTest terminÃ© avec succÃ¨s !" -ForegroundColor Green
    exit 0
} catch {
    # Une erreur s'est produite
    Write-Host "Erreur : $_" -ForegroundColor Red
    exit 1
}
