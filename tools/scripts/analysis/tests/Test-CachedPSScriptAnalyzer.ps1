#Requires -Version 5.1
<#
.SYNOPSIS
    Test des performances de l'analyse avec et sans cache.
.DESCRIPTION
    Ce script teste les performances de l'analyse de scripts PowerShell avec et sans cache.
.PARAMETER Path
    Chemin du rÃ©pertoire contenant les scripts PowerShell Ã  analyser.
.EXAMPLE
    .\Test-CachedPSScriptAnalyzer.ps1 -Path ".\scripts"
.NOTES
    Author: Augment Agent
    Version: 1.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

# VÃ©rifier si le rÃ©pertoire existe
if (-not (Test-Path -Path $Path -PathType Container)) {
    Write-Error "Le rÃ©pertoire n'existe pas: $Path"
    exit 1
}

# Chemin du script d'analyse
$analyzerPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Invoke-CachedPSScriptAnalyzer.ps1"

if (-not (Test-Path -Path $analyzerPath)) {
    Write-Error "Script Invoke-CachedPSScriptAnalyzer.ps1 non trouvÃ© Ã  l'emplacement: $analyzerPath"
    exit 1
}

# Fonction pour mesurer le temps d'exÃ©cution
function Measure-ExecutionTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [string]$Description = "OpÃ©ration"
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & $ScriptBlock
    $stopwatch.Stop()
    
    Write-Host "$Description terminÃ© en $($stopwatch.ElapsedMilliseconds) ms" -ForegroundColor Cyan
    
    return @{
        Result = $result
        ElapsedMilliseconds = $stopwatch.ElapsedMilliseconds
    }
}

# Nettoyer le cache avant le test
$cachePath = Join-Path -Path $env:TEMP -ChildPath "PSScriptAnalyzerCache"
if (Test-Path -Path $cachePath) {
    Write-Host "Nettoyage du cache..." -ForegroundColor Yellow
    Remove-Item -Path $cachePath -Recurse -Force
}

# Premier passage sans cache
Write-Host "`n=== Premier passage (sans cache) ===" -ForegroundColor Cyan
$firstPassResult = Measure-ExecutionTime -ScriptBlock {
    & $analyzerPath -Path $Path -UseCache:$false -Recurse
} -Description "Analyse sans cache"

# DeuxiÃ¨me passage avec cache
Write-Host "`n=== DeuxiÃ¨me passage (avec cache) ===" -ForegroundColor Cyan
$secondPassResult = Measure-ExecutionTime -ScriptBlock {
    & $analyzerPath -Path $Path -UseCache -Recurse
} -Description "Analyse avec cache (premier accÃ¨s)"

# TroisiÃ¨me passage avec cache
Write-Host "`n=== TroisiÃ¨me passage (avec cache) ===" -ForegroundColor Cyan
$thirdPassResult = Measure-ExecutionTime -ScriptBlock {
    & $analyzerPath -Path $Path -UseCache -Recurse
} -Description "Analyse avec cache (deuxiÃ¨me accÃ¨s)"

# Afficher les statistiques
Write-Host "`n=== Statistiques ===" -ForegroundColor Cyan
Write-Host "Temps sans cache: $($firstPassResult.ElapsedMilliseconds) ms" -ForegroundColor White
Write-Host "Temps avec cache (premier accÃ¨s): $($secondPassResult.ElapsedMilliseconds) ms" -ForegroundColor White
Write-Host "Temps avec cache (deuxiÃ¨me accÃ¨s): $($thirdPassResult.ElapsedMilliseconds) ms" -ForegroundColor White

$speedup1 = [math]::Round(($firstPassResult.ElapsedMilliseconds / $secondPassResult.ElapsedMilliseconds), 2)
$speedup2 = [math]::Round(($firstPassResult.ElapsedMilliseconds / $thirdPassResult.ElapsedMilliseconds), 2)

Write-Host "AccÃ©lÃ©ration (premier accÃ¨s au cache): ${speedup1}x" -ForegroundColor Green
Write-Host "AccÃ©lÃ©ration (deuxiÃ¨me accÃ¨s au cache): ${speedup2}x" -ForegroundColor Green

# VÃ©rifier que le cache fonctionne correctement
if ($thirdPassResult.ElapsedMilliseconds -lt $firstPassResult.ElapsedMilliseconds) {
    Write-Host "Test rÃ©ussi: Le cache amÃ©liore les performances." -ForegroundColor Green
}
else {
    Write-Host "Test Ã©chouÃ©: Le cache n'amÃ©liore pas les performances." -ForegroundColor Red
}

# Afficher les statistiques du cache
$cacheFiles = Get-ChildItem -Path $cachePath -Filter "*.xml" -Recurse | Measure-Object
Write-Host "`n=== Statistiques du cache ===" -ForegroundColor Cyan
Write-Host "Nombre de fichiers de cache: $($cacheFiles.Count)" -ForegroundColor White
Write-Host "Taille totale du cache: $([math]::Round((Get-ChildItem -Path $cachePath -Recurse | Measure-Object -Property Length -Sum).Sum / 1KB, 2)) KB" -ForegroundColor White
