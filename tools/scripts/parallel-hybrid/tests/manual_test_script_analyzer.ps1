# Test manuel pour l'analyseur de scripts
Write-Host "Démarrage du test manuel pour l'analyseur de scripts..." -ForegroundColor Cyan

# Chemin vers le script à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$analyzerPath = Join-Path -Path $scriptPath -ChildPath "..\examples\script-analyzer-simple.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $analyzerPath)) {
    Write-Host "Le script d'analyse n'existe pas : $analyzerPath" -ForegroundColor Red
    exit 1
}

Write-Host "Script d'analyse trouvé : $analyzerPath" -ForegroundColor Green

# Créer des scripts de test
$testScriptsPath = Join-Path -Path $scriptPath -ChildPath "test_scripts"
if (-not (Test-Path -Path $testScriptsPath)) {
    Write-Host "Création du répertoire de scripts de test..." -ForegroundColor Yellow
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
    Write-Host "Script de test simple créé." -ForegroundColor Green
}

# Créer un répertoire pour les résultats
$outputPath = Join-Path -Path $testScriptsPath -ChildPath "results"
if (-not (Test-Path -Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

# Exécuter l'analyseur sur le script simple
Write-Host "`nTest 1: Analyse d'un script simple" -ForegroundColor Yellow
try {
    $scriptToAnalyze = Join-Path -Path $testScriptsPath -ChildPath "simple.ps1"
    
    Write-Host "Exécution de l'analyseur sur $scriptToAnalyze..." -ForegroundColor Cyan
    $result = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -FilePatterns "simple.ps1"
    
    # Vérifier les résultats
    if ($result -and $result.Count -gt 0) {
        Write-Host "Analyse réussie !" -ForegroundColor Green
        Write-Host "Résultats :"
        $result | Format-List
    } else {
        Write-Host "L'analyse n'a pas produit de résultats." -ForegroundColor Red
    }
} catch {
    Write-Host "Erreur lors de l'analyse : $_" -ForegroundColor Red
}

# Exécuter l'analyseur avec cache
Write-Host "`nTest 2: Analyse avec cache" -ForegroundColor Yellow
try {
    $scriptToAnalyze = Join-Path -Path $testScriptsPath -ChildPath "simple.ps1"
    
    Write-Host "Exécution de l'analyseur avec cache..." -ForegroundColor Cyan
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -FilePatterns "simple.ps1" -UseCache
    $stopwatch.Stop()
    $timeWithCache = $stopwatch.Elapsed.TotalSeconds
    
    Write-Host "Analyse avec cache terminée en $timeWithCache secondes." -ForegroundColor Green
    
    # Exécuter une deuxième fois avec cache
    Write-Host "Exécution de l'analyseur avec cache (2ème fois)..." -ForegroundColor Cyan
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & $analyzerPath -ScriptsPath $testScriptsPath -OutputPath $outputPath -FilePatterns "simple.ps1" -UseCache
    $stopwatch.Stop()
    $timeWithCacheSecondRun = $stopwatch.Elapsed.TotalSeconds
    
    Write-Host "Analyse avec cache (2ème fois) terminée en $timeWithCacheSecondRun secondes." -ForegroundColor Green
    
    # Vérifier si le cache a amélioré les performances
    if ($timeWithCacheSecondRun -lt $timeWithCache) {
        Write-Host "Le cache a amélioré les performances !" -ForegroundColor Green
    } else {
        Write-Host "Le cache n'a pas amélioré les performances." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Erreur lors de l'analyse avec cache : $_" -ForegroundColor Red
}

Write-Host "`nTests terminés." -ForegroundColor Cyan
