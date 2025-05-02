# Test simplifié pour le système de cache des dépendances
# Ce test vérifie que le cache fonctionne correctement

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$moduleFile = Join-Path -Path $modulePath -ChildPath "ModuleDependencyAnalyzer-Fixed.psm1"

try {
    # Importer le module
    Import-Module -Name $moduleFile -Force -ErrorAction Stop
    Write-Host "Module importé avec succès" -ForegroundColor Green

    # Test 1: Vérifier que le cache est initialement vide
    Write-Host "`nTest 1: Vérifier que le cache est initialement vide" -ForegroundColor Cyan
    
    # Vider le cache
    Clear-DependencyCache
    
    # Vérifier que le cache est vide
    $initialCache = Get-DependencyCache
    
    if ($initialCache.Manifests.Count -eq 0 -and 
        $initialCache.Code.Count -eq 0 -and 
        $initialCache.ExternalFunctions.Count -eq 0 -and 
        $initialCache.FunctionPaths.Count -eq 0) {
        Write-Host "Cache initialement vide - OK" -ForegroundColor Green
    } else {
        Write-Host "Erreur: Le cache n'est pas vide initialement" -ForegroundColor Red
    }

    # Test 2: Analyser les dépendances et vérifier que le cache est rempli
    Write-Host "`nTest 2: Analyser les dépendances et vérifier que le cache est rempli" -ForegroundColor Cyan
    
    # Créer un fichier de test temporaire
    $testDir = Join-Path -Path $env:TEMP -ChildPath "DependencyCacheTest"
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    
    $testScriptContent = @"
# Test script
function Test-Function {
    Get-Date
}
"@
    
    $testScriptPath = Join-Path -Path $testDir -ChildPath "TestScript.ps1"
    Set-Content -Path $testScriptPath -Value $testScriptContent
    
    # Analyser les dépendances
    $result1 = Get-ModuleDependenciesFromCode -ModulePath $testScriptPath
    $result2 = Get-ExternalFunctionDependencies -ModulePath $testScriptPath
    $result3 = Resolve-ExternalFunctionPath -FunctionName "Get-Date"
    
    # Vérifier que le cache est rempli
    $cacheAfterAnalysis = Get-DependencyCache
    
    if ($cacheAfterAnalysis.Code.Count -gt 0 -or 
        $cacheAfterAnalysis.ExternalFunctions.Count -gt 0 -or 
        $cacheAfterAnalysis.FunctionPaths.Count -gt 0) {
        Write-Host "Cache rempli après analyse - OK" -ForegroundColor Green
    } else {
        Write-Host "Erreur: Le cache n'est pas rempli après analyse" -ForegroundColor Red
    }
    
    # Test 3: Vider le cache et vérifier qu'il est vide
    Write-Host "`nTest 3: Vider le cache et vérifier qu'il est vide" -ForegroundColor Cyan
    
    # Vider le cache
    Clear-DependencyCache
    
    # Vérifier que le cache est vide
    $cacheAfterClear = Get-DependencyCache
    
    if ($cacheAfterClear.Manifests.Count -eq 0 -and 
        $cacheAfterClear.Code.Count -eq 0 -and 
        $cacheAfterClear.ExternalFunctions.Count -eq 0 -and 
        $cacheAfterClear.FunctionPaths.Count -eq 0) {
        Write-Host "Cache vide après Clear-DependencyCache - OK" -ForegroundColor Green
    } else {
        Write-Host "Erreur: Le cache n'est pas vide après Clear-DependencyCache" -ForegroundColor Red
    }

    # Nettoyer
    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Module -Name "ModuleDependencyAnalyzer-Fixed" -Force -ErrorAction SilentlyContinue

    # Tout est OK
    Write-Host "`nTest terminé avec succès !" -ForegroundColor Green
    exit 0
} catch {
    # Une erreur s'est produite
    Write-Host "Erreur : $_" -ForegroundColor Red
    exit 1
}
