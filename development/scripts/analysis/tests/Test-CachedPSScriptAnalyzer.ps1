#Requires -Version 5.1
<#
.SYNOPSIS
    Test des performances de l'analyse avec et sans cache.
.DESCRIPTION
    Ce script teste les performances de l'analyse de scripts PowerShell avec et sans cache.
.PARAMETER Path
    Chemin du rÃƒÂ©pertoire contenant les scripts PowerShell ÃƒÂ  analyser.
.EXAMPLE
    .\Test-CachedPSScriptAnalyzer.ps1 -Path ".\development\scripts"
.NOTES
    Author: Augment Agent
    Version: 1.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

# VÃƒÂ©rifier si le rÃƒÂ©pertoire existe
if (-not (Test-Path -Path $Path -PathType Container)) {
    Write-Error "Le rÃƒÂ©pertoire n'existe pas: $Path"
    exit 1
}

# Chemin du script d'analyse
$analyzerPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Invoke-CachedPSScriptAnalyzer.ps1"

if (-not (Test-Path -Path $analyzerPath)) {
    Write-Error "Script Invoke-CachedPSScriptAnalyzer.ps1 non trouvÃƒÂ© ÃƒÂ  l'emplacement: $analyzerPath"
    exit 1
}

# Fonction pour mesurer le temps d'exÃƒÂ©cution
function Measure-ExecutionTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [string]$Description = "OpÃƒÂ©ration"
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & $ScriptBlock
    $stopwatch.Stop()
    
    Write-Host "$Description terminÃƒÂ© en $($stopwatch.ElapsedMilliseconds) ms" -ForegroundColor Cyan
    
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

# DeuxiÃƒÂ¨me passage avec cache
Write-Host "`n=== DeuxiÃƒÂ¨me passage (avec cache) ===" -ForegroundColor Cyan
$secondPassResult = Measure-ExecutionTime -ScriptBlock {
    & $analyzerPath -Path $Path -UseCache -Recurse
} -Description "Analyse avec cache (premier accÃƒÂ¨s)"

# TroisiÃƒÂ¨me passage avec cache
Write-Host "`n=== TroisiÃƒÂ¨me passage (avec cache) ===" -ForegroundColor Cyan
$thirdPassResult = Measure-ExecutionTime -ScriptBlock {
    & $analyzerPath -Path $Path -UseCache -Recurse
} -Description "Analyse avec cache (deuxiÃƒÂ¨me accÃƒÂ¨s)"

# Afficher les statistiques
Write-Host "`n=== Statistiques ===" -ForegroundColor Cyan
Write-Host "Temps sans cache: $($firstPassResult.ElapsedMilliseconds) ms" -ForegroundColor White
Write-Host "Temps avec cache (premier accÃƒÂ¨s): $($secondPassResult.ElapsedMilliseconds) ms" -ForegroundColor White
Write-Host "Temps avec cache (deuxiÃƒÂ¨me accÃƒÂ¨s): $($thirdPassResult.ElapsedMilliseconds) ms" -ForegroundColor White

$speedup1 = [math]::Round(($firstPassResult.ElapsedMilliseconds / $secondPassResult.ElapsedMilliseconds), 2)
$speedup2 = [math]::Round(($firstPassResult.ElapsedMilliseconds / $thirdPassResult.ElapsedMilliseconds), 2)

Write-Host "AccÃƒÂ©lÃƒÂ©ration (premier accÃƒÂ¨s au cache): ${speedup1}x" -ForegroundColor Green
Write-Host "AccÃƒÂ©lÃƒÂ©ration (deuxiÃƒÂ¨me accÃƒÂ¨s au cache): ${speedup2}x" -ForegroundColor Green

# VÃƒÂ©rifier que le cache fonctionne correctement
if ($thirdPassResult.ElapsedMilliseconds -lt $firstPassResult.ElapsedMilliseconds) {
    Write-Host "Test rÃƒÂ©ussi: Le cache amÃƒÂ©liore les performances." -ForegroundColor Green
}
else {
    Write-Host "Test ÃƒÂ©chouÃƒÂ©: Le cache n'amÃƒÂ©liore pas les performances." -ForegroundColor Red
}

# Afficher les statistiques du cache
$cacheFiles = Get-ChildItem -Path $cachePath -Filter "*.xml" -Recurse | Measure-Object
Write-Host "`n=== Statistiques du cache ===" -ForegroundColor Cyan
Write-Host "Nombre de fichiers de cache: $($cacheFiles.Count)" -ForegroundColor White
Write-Host "Taille totale du cache: $([math]::Round((Get-ChildItem -Path $cachePath -Recurse | Measure-Object -Property Length -Sum).Sum / 1KB, 2)) KB" -ForegroundColor White
