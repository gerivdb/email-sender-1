#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiés pour l'architecture hybride PowerShell-Python.
.DESCRIPTION
    Ce script exécute des tests unitaires simplifiés pour vérifier le bon fonctionnement
    de l'architecture hybride PowerShell-Python et des cas d'usage implémentés.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
#>

# Chemin vers les scripts à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$analyzerPath = Join-Path -Path $scriptPath -ChildPath "..\examples\script-analyzer-simple.ps1"

# Autres scripts disponibles pour des tests futurs
# $validatorPath = Join-Path -Path $scriptPath -ChildPath "..\examples\standards-validator.ps1"
# $reportGeneratorPath = Join-Path -Path $scriptPath -ChildPath "..\examples\parallel-report-generator.ps1"

# Créer des scripts de test
$testScriptsPath = Join-Path -Path $scriptPath -ChildPath "test_scripts"
if (-not (Test-Path -Path $testScriptsPath)) {
    New-Item -Path $testScriptsPath -ItemType Directory -Force | Out-Null

    # Script simple
    $simpleScript = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test simple.
.DESCRIPTION
    Ce script est utilisé pour tester l'analyseur de scripts.
#>

# Fonction simple
function Test-Function {
    param(
        [Parameter(Mandatory = `$true)]
        [string]`$InputString
    )

    Write-Output `$InputString
}

# Appel de la fonction
Test-Function -InputString "Hello, World!"
"@

    $simpleScript | Out-File -FilePath (Join-Path -Path $testScriptsPath -ChildPath "simple.ps1") -Encoding utf8
}

# Créer un répertoire pour les résultats
$outputPath = Join-Path -Path $testScriptsPath -ChildPath "results"
if (-not (Test-Path -Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

# Fonction pour exécuter un test
function Test-ScriptExecution {
    param(
        [string]$Name,
        [string]$ScriptPath,
        [scriptblock]$TestBlock
    )

    Write-Host "`n=== Test : $Name ===" -ForegroundColor Yellow

    try {
        # Vérifier que le script existe
        if (-not (Test-Path -Path $ScriptPath)) {
            Write-Host "ÉCHEC : Le script n'existe pas : $ScriptPath" -ForegroundColor Red
            return $false
        }

        # Exécuter le test
        $result = & $TestBlock

        if ($result -eq $true) {
            Write-Host "SUCCÈS : $Name" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "ÉCHEC : $Name" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "ERREUR : $Name - $_" -ForegroundColor Red
        return $false
    }
}

# Test 1 : Analyseur de scripts
$test1 = Test-ScriptExecution -Name "Analyseur de scripts" -ScriptPath $analyzerPath -TestBlock {
    # Exécuter l'analyseur sur le script simple
    $scriptToAnalyze = Join-Path -Path $testScriptsPath -ChildPath "simple.ps1"

    Write-Host "Exécution de l'analyseur sur $scriptToAnalyze..." -ForegroundColor Cyan
    $result = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -FilePatterns "simple.ps1" -UseCache -Verbose

    # Afficher les détails du résultat pour le débogage
    Write-Host "Type de résultat : $($result.GetType().FullName)" -ForegroundColor Cyan
    Write-Host "Contenu du résultat : $result" -ForegroundColor Cyan

    # Vérifier les résultats
    if ($result) {
        Write-Host "Analyse réussie !" -ForegroundColor Green
        Write-Host "Nombre de lignes : $($result.total_lines)" -ForegroundColor Green
        Write-Host "Nombre de fonctions : $($result.functions_count)" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "L'analyse n'a pas produit de résultats." -ForegroundColor Red
        return $false
    }
}

# Test 2 : Cache de l'analyseur
$test2 = Test-ScriptExecution -Name "Cache de l'analyseur" -ScriptPath $analyzerPath -TestBlock {
    # Exécuter l'analyseur une première fois pour remplir le cache
    Write-Host "Première exécution pour remplir le cache..." -ForegroundColor Cyan
    $stopwatch1 = [System.Diagnostics.Stopwatch]::StartNew()
    $result1 = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -FilePatterns "simple.ps1" -UseCache -Verbose
    $stopwatch1.Stop()
    $time1 = $stopwatch1.Elapsed.TotalSeconds

    # Exécuter l'analyseur une deuxième fois pour utiliser le cache
    Write-Host "Deuxième exécution pour utiliser le cache..." -ForegroundColor Cyan
    $stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()
    $result2 = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -FilePatterns "simple.ps1" -UseCache -Verbose
    $stopwatch2.Stop()
    $time2 = $stopwatch2.Elapsed.TotalSeconds

    # Vérifier que les résultats sont identiques
    $resultsEqual = ($result1.total_lines -eq $result2.total_lines) -and ($result1.functions_count -eq $result2.functions_count)

    Write-Host "Temps de la première exécution : $time1 secondes" -ForegroundColor Cyan
    Write-Host "Temps de la deuxième exécution : $time2 secondes" -ForegroundColor Cyan

    if ($resultsEqual) {
        Write-Host "Les résultats sont identiques." -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "Les résultats sont différents." -ForegroundColor Red
        return $false
    }
}

# Afficher un résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Yellow
$totalTests = 2
$passedTests = @($test1, $test2).Where({ $_ -eq $true }).Count
$failedTests = $totalTests - $passedTests

Write-Host "Tests exécutés : $totalTests" -ForegroundColor Yellow
Write-Host "Tests réussis : $passedTests" -ForegroundColor Green
Write-Host "Tests échoués : $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Green" })

# Retourner le résultat global
return $passedTests -eq $totalTests
