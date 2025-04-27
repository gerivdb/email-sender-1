#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiÃ©s pour l'architecture hybride PowerShell-Python.
.DESCRIPTION
    Ce script exÃ©cute des tests unitaires simplifiÃ©s pour vÃ©rifier le bon fonctionnement
    de l'architecture hybride PowerShell-Python et des cas d'usage implÃ©mentÃ©s.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
#>

# Chemin vers les scripts Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$analyzerPath = Join-Path -Path $scriptPath -ChildPath "..\examples\script-analyzer-simple.ps1"

# Autres scripts disponibles pour des tests futurs
# $validatorPath = Join-Path -Path $scriptPath -ChildPath "..\examples\standards-validator.ps1"
# $reportGeneratorPath = Join-Path -Path $scriptPath -ChildPath "..\examples\parallel-report-generator.ps1"

# CrÃ©er des scripts de test
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
    Ce script est utilisÃ© pour tester l'analyseur de scripts.
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

# CrÃ©er un rÃ©pertoire pour les rÃ©sultats
$outputPath = Join-Path -Path $testScriptsPath -ChildPath "results"
if (-not (Test-Path -Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

# Fonction pour exÃ©cuter un test
function Test-ScriptExecution {
    param(
        [string]$Name,
        [string]$ScriptPath,
        [scriptblock]$TestBlock
    )

    Write-Host "`n=== Test : $Name ===" -ForegroundColor Yellow

    try {
        # VÃ©rifier que le script existe
        if (-not (Test-Path -Path $ScriptPath)) {
            Write-Host "Ã‰CHEC : Le script n'existe pas : $ScriptPath" -ForegroundColor Red
            return $false
        }

        # ExÃ©cuter le test
        $result = & $TestBlock

        if ($result -eq $true) {
            Write-Host "SUCCÃˆS : $Name" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "Ã‰CHEC : $Name" -ForegroundColor Red
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
    # ExÃ©cuter l'analyseur sur le script simple
    $scriptToAnalyze = Join-Path -Path $testScriptsPath -ChildPath "simple.ps1"

    Write-Host "ExÃ©cution de l'analyseur sur $scriptToAnalyze..." -ForegroundColor Cyan
    $result = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -FilePatterns "simple.ps1" -UseCache -Verbose

    # Afficher les dÃ©tails du rÃ©sultat pour le dÃ©bogage
    Write-Host "Type de rÃ©sultat : $($result.GetType().FullName)" -ForegroundColor Cyan
    Write-Host "Contenu du rÃ©sultat : $result" -ForegroundColor Cyan

    # VÃ©rifier les rÃ©sultats
    if ($result) {
        Write-Host "Analyse rÃ©ussie !" -ForegroundColor Green
        Write-Host "Nombre de lignes : $($result.total_lines)" -ForegroundColor Green
        Write-Host "Nombre de fonctions : $($result.functions_count)" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "L'analyse n'a pas produit de rÃ©sultats." -ForegroundColor Red
        return $false
    }
}

# Test 2 : Cache de l'analyseur
$test2 = Test-ScriptExecution -Name "Cache de l'analyseur" -ScriptPath $analyzerPath -TestBlock {
    # ExÃ©cuter l'analyseur une premiÃ¨re fois pour remplir le cache
    Write-Host "PremiÃ¨re exÃ©cution pour remplir le cache..." -ForegroundColor Cyan
    $stopwatch1 = [System.Diagnostics.Stopwatch]::StartNew()
    $result1 = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -FilePatterns "simple.ps1" -UseCache -Verbose
    $stopwatch1.Stop()
    $time1 = $stopwatch1.Elapsed.TotalSeconds

    # ExÃ©cuter l'analyseur une deuxiÃ¨me fois pour utiliser le cache
    Write-Host "DeuxiÃ¨me exÃ©cution pour utiliser le cache..." -ForegroundColor Cyan
    $stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()
    $result2 = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -FilePatterns "simple.ps1" -UseCache -Verbose
    $stopwatch2.Stop()
    $time2 = $stopwatch2.Elapsed.TotalSeconds

    # VÃ©rifier que les rÃ©sultats sont identiques
    $resultsEqual = ($result1.total_lines -eq $result2.total_lines) -and ($result1.functions_count -eq $result2.functions_count)

    Write-Host "Temps de la premiÃ¨re exÃ©cution : $time1 secondes" -ForegroundColor Cyan
    Write-Host "Temps de la deuxiÃ¨me exÃ©cution : $time2 secondes" -ForegroundColor Cyan

    if ($resultsEqual) {
        Write-Host "Les rÃ©sultats sont identiques." -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "Les rÃ©sultats sont diffÃ©rents." -ForegroundColor Red
        return $false
    }
}

# Afficher un rÃ©sumÃ© des tests
Write-Host "`n=== RÃ©sumÃ© des tests ===" -ForegroundColor Yellow
$totalTests = 2
$passedTests = @($test1, $test2).Where({ $_ -eq $true }).Count
$failedTests = $totalTests - $passedTests

Write-Host "Tests exÃ©cutÃ©s : $totalTests" -ForegroundColor Yellow
Write-Host "Tests rÃ©ussis : $passedTests" -ForegroundColor Green
Write-Host "Tests Ã©chouÃ©s : $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Green" })

# Retourner le rÃ©sultat global
return $passedTests -eq $totalTests
