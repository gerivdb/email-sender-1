# Test manuel pour l'analyseur de scripts
Write-Host "DÃ©marrage du test manuel pour l'analyseur de scripts..." -ForegroundColor Cyan

# Chemin vers le script Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$analyzerPath = Join-Path -Path $scriptPath -ChildPath "..\examples\script-analyzer-simple.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $analyzerPath)) {
    Write-Host "Le script d'analyse n'existe pas : $analyzerPath" -ForegroundColor Red
    exit 1
}

Write-Host "Script d'analyse trouvÃ© : $analyzerPath" -ForegroundColor Green

# CrÃ©er des scripts de test
$testScriptsPath = Join-Path -Path $scriptPath -ChildPath "test_scripts"
if (-not (Test-Path -Path $testScriptsPath)) {
    Write-Host "CrÃ©ation du rÃ©pertoire de scripts de test..." -ForegroundColor Yellow
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
    Write-Host "Script de test simple crÃ©Ã©." -ForegroundColor Green
}

# CrÃ©er un rÃ©pertoire pour les rÃ©sultats
$outputPath = Join-Path -Path $testScriptsPath -ChildPath "results"
if (-not (Test-Path -Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

# ExÃ©cuter l'analyseur sur le script simple
Write-Host "`nTest 1: Analyse d'un script simple" -ForegroundColor Yellow
try {
    $scriptToAnalyze = Join-Path -Path $testScriptsPath -ChildPath "simple.ps1"
    
    Write-Host "ExÃ©cution de l'analyseur sur $scriptToAnalyze..." -ForegroundColor Cyan
    $result = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -FilePatterns "simple.ps1"
    
    # VÃ©rifier les rÃ©sultats
    if ($result -and $result.Count -gt 0) {
        Write-Host "Analyse rÃ©ussie !" -ForegroundColor Green
        Write-Host "RÃ©sultats :"
        $result | Format-List
    } else {
        Write-Host "L'analyse n'a pas produit de rÃ©sultats." -ForegroundColor Red
    }
} catch {
    Write-Host "Erreur lors de l'analyse : $_" -ForegroundColor Red
}

# ExÃ©cuter l'analyseur avec cache
Write-Host "`nTest 2: Analyse avec cache" -ForegroundColor Yellow
try {
    $scriptToAnalyze = Join-Path -Path $testScriptsPath -ChildPath "simple.ps1"
    
    Write-Host "ExÃ©cution de l'analyseur avec cache..." -ForegroundColor Cyan
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -FilePatterns "simple.ps1" -UseCache
    $stopwatch.Stop()
    $timeWithCache = $stopwatch.Elapsed.TotalSeconds
    
    Write-Host "Analyse avec cache terminÃ©e en $timeWithCache secondes." -ForegroundColor Green
    
    # ExÃ©cuter une deuxiÃ¨me fois avec cache
    Write-Host "ExÃ©cution de l'analyseur avec cache (2Ã¨me fois)..." -ForegroundColor Cyan
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -FilePatterns "simple.ps1" -UseCache
    $stopwatch.Stop()
    $timeWithCacheSecondRun = $stopwatch.Elapsed.TotalSeconds
    
    Write-Host "Analyse avec cache (2Ã¨me fois) terminÃ©e en $timeWithCacheSecondRun secondes." -ForegroundColor Green
    
    # VÃ©rifier si le cache a amÃ©liorÃ© les performances
    if ($timeWithCacheSecondRun -lt $timeWithCache) {
        Write-Host "Le cache a amÃ©liorÃ© les performances !" -ForegroundColor Green
    } else {
        Write-Host "Le cache n'a pas amÃ©liorÃ© les performances." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Erreur lors de l'analyse avec cache : $_" -ForegroundColor Red
}

Write-Host "`nTests terminÃ©s." -ForegroundColor Cyan
