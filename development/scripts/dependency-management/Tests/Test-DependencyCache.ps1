# Test pour le systÃ¨me de cache des dÃ©pendances
# Ce test vÃ©rifie que le cache fonctionne correctement

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$moduleFile = Join-Path -Path $modulePath -ChildPath "ModuleDependencyAnalyzer-Fixed.psm1"

try {
    # Importer le module
    Import-Module -Name $moduleFile -Force -ErrorAction Stop
    Write-Host "Module importÃ© avec succÃ¨s" -ForegroundColor Green

    # CrÃ©er un rÃ©pertoire temporaire pour les tests
    $testDir = Join-Path -Path $env:TEMP -ChildPath "DependencyCacheTest"
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

    # CrÃ©er un fichier de test
    $testScriptContent = @"
# DÃ©finition d'une fonction interne
function Test-InternalFunction {
    param (
        [string]`$Path
    )

    # Utilisation de fonctions internes
    Write-Output "Testing internal function"
}

# Appel Ã  des fonctions externes
Get-Date
Get-ChildItem
"@

    $testScriptPath = Join-Path -Path $testDir -ChildPath "TestScript.ps1"
    Set-Content -Path $testScriptPath -Value $testScriptContent

    # Test 1: VÃ©rifier que le cache est initialement vide
    Write-Host "`nTest 1: VÃ©rifier que le cache est initialement vide" -ForegroundColor Cyan
    $initialCache = Get-DependencyCache

    if ($initialCache.Manifests.Count -eq 0 -and
        $initialCache.Code.Count -eq 0 -and
        $initialCache.ExternalFunctions.Count -eq 0 -and
        $initialCache.FunctionPaths.Count -eq 0) {
        Write-Host "Cache initialement vide - OK" -ForegroundColor Green
    } else {
        Write-Host "Erreur: Le cache n'est pas vide initialement" -ForegroundColor Red
    }

    # Test 2: Analyser les dÃ©pendances et vÃ©rifier que le cache est rempli
    Write-Host "`nTest 2: Analyser les dÃ©pendances et vÃ©rifier que le cache est rempli" -ForegroundColor Cyan

    # Activer les messages de dÃ©bogage
    $VerbosePreference = "Continue"

    # Analyser les dÃ©pendances
    $result1 = Get-ModuleDependenciesFromCode -ModulePath $testScriptPath
    $result2 = Get-ExternalFunctionDependencies -ModulePath $testScriptPath
    $result3 = Resolve-ExternalFunctionPath -FunctionName "Get-Date"

    # DÃ©sactiver les messages de dÃ©bogage
    $VerbosePreference = "SilentlyContinue"

    # VÃ©rifier que le cache est rempli
    $cacheAfterAnalysis = Get-DependencyCache

    if ($cacheAfterAnalysis.Code.Count -gt 0 -and
        $cacheAfterAnalysis.ExternalFunctions.Count -gt 0 -and
        $cacheAfterAnalysis.FunctionPaths.Count -gt 0) {
        Write-Host "Cache rempli aprÃ¨s analyse - OK" -ForegroundColor Green
    } else {
        Write-Host "Erreur: Le cache n'est pas rempli aprÃ¨s analyse" -ForegroundColor Red
    }

    # Test 3: VÃ©rifier que les rÃ©sultats sont rÃ©cupÃ©rÃ©s du cache
    Write-Host "`nTest 3: VÃ©rifier que les rÃ©sultats sont rÃ©cupÃ©rÃ©s du cache" -ForegroundColor Cyan

    # Activer les messages de dÃ©bogage
    $VerbosePreference = "Continue"

    # Analyser les dÃ©pendances Ã  nouveau
    $result1Again = Get-ModuleDependenciesFromCode -ModulePath $testScriptPath
    $result2Again = Get-ExternalFunctionDependencies -ModulePath $testScriptPath
    $result3Again = Resolve-ExternalFunctionPath -FunctionName "Get-Date"

    # DÃ©sactiver les messages de dÃ©bogage
    $VerbosePreference = "SilentlyContinue"

    # VÃ©rifier que les rÃ©sultats sont identiques
    $test3Result = $true

    # VÃ©rifier si les rÃ©sultats sont null
    if ($null -eq $result1 -and $null -eq $result1Again) {
        Write-Host "RÃ©sultats de Get-ModuleDependenciesFromCode identiques (null) - OK" -ForegroundColor Green
    } elseif ($null -eq $result1 -or $null -eq $result1Again) {
        Write-Host "Erreur: Un des rÃ©sultats de Get-ModuleDependenciesFromCode est null" -ForegroundColor Red
        $test3Result = $false
    } elseif ($result1.Count -eq 0 -and $result1Again.Count -eq 0) {
        Write-Host "RÃ©sultats de Get-ModuleDependenciesFromCode identiques (vides) - OK" -ForegroundColor Green
    } else {
        # Comparer les objets
        $diff1 = Compare-Object -ReferenceObject $result1 -DifferenceObject $result1Again -ErrorAction SilentlyContinue
        if ($null -eq $diff1) {
            Write-Host "RÃ©sultats de Get-ModuleDependenciesFromCode identiques - OK" -ForegroundColor Green
        } else {
            Write-Host "Erreur: RÃ©sultats de Get-ModuleDependenciesFromCode diffÃ©rents" -ForegroundColor Red
            $test3Result = $false
        }
    }

    # VÃ©rifier si les rÃ©sultats sont null
    if ($null -eq $result2 -and $null -eq $result2Again) {
        Write-Host "RÃ©sultats de Get-ExternalFunctionDependencies identiques (null) - OK" -ForegroundColor Green
    } elseif ($null -eq $result2 -or $null -eq $result2Again) {
        Write-Host "Erreur: Un des rÃ©sultats de Get-ExternalFunctionDependencies est null" -ForegroundColor Red
        $test3Result = $false
    } elseif ($result2.Count -eq 0 -and $result2Again.Count -eq 0) {
        Write-Host "RÃ©sultats de Get-ExternalFunctionDependencies identiques (vides) - OK" -ForegroundColor Green
    } else {
        # Comparer les objets
        $diff2 = Compare-Object -ReferenceObject $result2 -DifferenceObject $result2Again -ErrorAction SilentlyContinue
        if ($null -eq $diff2) {
            Write-Host "RÃ©sultats de Get-ExternalFunctionDependencies identiques - OK" -ForegroundColor Green
        } else {
            Write-Host "Erreur: RÃ©sultats de Get-ExternalFunctionDependencies diffÃ©rents" -ForegroundColor Red
            $test3Result = $false
        }
    }

    if ($result3.FunctionName -eq $result3Again.FunctionName -and
        $result3.ModuleName -eq $result3Again.ModuleName) {
        Write-Host "RÃ©sultats de Resolve-ExternalFunctionPath identiques - OK" -ForegroundColor Green
    } else {
        Write-Host "Erreur: RÃ©sultats de Resolve-ExternalFunctionPath diffÃ©rents" -ForegroundColor Red
        $test3Result = $false
    }

    # Test 4: Vider le cache et vÃ©rifier qu'il est vide
    Write-Host "`nTest 4: Vider le cache et vÃ©rifier qu'il est vide" -ForegroundColor Cyan

    # Vider le cache
    Clear-DependencyCache

    # VÃ©rifier que le cache est vide
    $cacheAfterClear = Get-DependencyCache

    if ($cacheAfterClear.Manifests.Count -eq 0 -and
        $cacheAfterClear.Code.Count -eq 0 -and
        $cacheAfterClear.ExternalFunctions.Count -eq 0 -and
        $cacheAfterClear.FunctionPaths.Count -eq 0) {
        Write-Host "Cache vide aprÃ¨s Clear-DependencyCache - OK" -ForegroundColor Green
    } else {
        Write-Host "Erreur: Le cache n'est pas vide aprÃ¨s Clear-DependencyCache" -ForegroundColor Red
    }

    # Test 5: VÃ©rifier que l'option NoCache fonctionne
    Write-Host "`nTest 5: VÃ©rifier que l'option NoCache fonctionne" -ForegroundColor Cyan

    # Analyser les dÃ©pendances avec NoCache
    $result1NoCache = Get-ModuleDependenciesFromCode -ModulePath $testScriptPath
    $result2NoCache = Get-ExternalFunctionDependencies -ModulePath $testScriptPath
    $result3NoCache = Resolve-ExternalFunctionPath -FunctionName "Get-Date"

    # VÃ©rifier que le cache est rempli
    $cacheAfterNoCache = Get-DependencyCache

    if ($cacheAfterNoCache.Code.Count -gt 0 -and
        $cacheAfterNoCache.ExternalFunctions.Count -gt 0 -and
        $cacheAfterNoCache.FunctionPaths.Count -gt 0) {
        Write-Host "Cache rempli aprÃ¨s analyse sans NoCache - OK" -ForegroundColor Green
    } else {
        Write-Host "Erreur: Le cache n'est pas rempli aprÃ¨s analyse sans NoCache" -ForegroundColor Red
    }

    # Vider le cache
    Clear-DependencyCache

    # Analyser les dÃ©pendances avec NoCache
    $result1NoCache = Get-ModuleDependenciesFromCode -ModulePath $testScriptPath -NoCache
    $result2NoCache = Get-ExternalFunctionDependencies -ModulePath $testScriptPath -NoCache
    $result3NoCache = Resolve-ExternalFunctionPath -FunctionName "Get-Date" -NoCache

    # VÃ©rifier que le cache est toujours vide
    $cacheAfterNoCache = Get-DependencyCache

    if ($cacheAfterNoCache.Code.Count -eq 0 -and
        $cacheAfterNoCache.ExternalFunctions.Count -eq 0 -and
        $cacheAfterNoCache.FunctionPaths.Count -eq 0) {
        Write-Host "Cache toujours vide aprÃ¨s analyse avec NoCache - OK" -ForegroundColor Green
    } else {
        Write-Host "Erreur: Le cache n'est pas vide aprÃ¨s analyse avec NoCache" -ForegroundColor Red
    }

    # Nettoyer
    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Module -Name "ModuleDependencyAnalyzer-Fixed" -Force -ErrorAction SilentlyContinue

    # Tout est OK
    Write-Host "`nTest terminÃ© avec succÃ¨s !" -ForegroundColor Green
    exit 0
} catch {
    # Une erreur s'est produite
    Write-Host "Erreur : $_" -ForegroundColor Red
    exit 1
}
