#Requires -Version 5.1
<#
.SYNOPSIS
    Compare les performances de l'analyse standard et de l'analyse avec cache.
.DESCRIPTION
    Ce script compare les performances de l'analyse standard (Start-CodeAnalysis.ps1)
    et de l'analyse avec cache (Start-CachedAnalysis.ps1).
.PARAMETER Path
    Chemin du rÃƒÂ©pertoire contenant les scripts PowerShell ÃƒÂ  analyser.
.EXAMPLE
    .\Compare-AnalysisPerformance.ps1 -Path ".\development\scripts"
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

# Chemins des scripts d'analyse
$scriptPath = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$standardAnalysisPath = Join-Path -Path $scriptPath -ChildPath "Start-CodeAnalysis.ps1"
$cachedAnalysisPath = Join-Path -Path $scriptPath -ChildPath "Start-CachedAnalysis.ps1"

if (-not (Test-Path -Path $standardAnalysisPath)) {
    Write-Error "Script Start-CodeAnalysis.ps1 non trouvÃƒÂ© ÃƒÂ  l'emplacement: $standardAnalysisPath"
    exit 1
}

if (-not (Test-Path -Path $cachedAnalysisPath)) {
    Write-Error "Script Start-CachedAnalysis.ps1 non trouvÃƒÂ© ÃƒÂ  l'emplacement: $cachedAnalysisPath"
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

# Analyse standard
Write-Host "`n=== Analyse standard ===" -ForegroundColor Cyan
$standardResult = Measure-ExecutionTime -ScriptBlock {
    & $standardAnalysisPath -Path $Path -Tools PSScriptAnalyzer -Recurse
} -Description "Analyse standard"

# Analyse avec cache (premier passage)
Write-Host "`n=== Analyse avec cache (premier passage) ===" -ForegroundColor Cyan
$cachedResult1 = Measure-ExecutionTime -ScriptBlock {
    & $cachedAnalysisPath -Path $Path -Tool PSScriptAnalyzer -UseCache -Recurse
} -Description "Analyse avec cache (premier passage)"

# Analyse avec cache (deuxiÃƒÂ¨me passage)
Write-Host "`n=== Analyse avec cache (deuxiÃƒÂ¨me passage) ===" -ForegroundColor Cyan
$cachedResult2 = Measure-ExecutionTime -ScriptBlock {
    & $cachedAnalysisPath -Path $Path -Tool PSScriptAnalyzer -UseCache -Recurse
} -Description "Analyse avec cache (deuxiÃƒÂ¨me passage)"

# Afficher les statistiques
Write-Host "`n=== Statistiques ===" -ForegroundColor Cyan
Write-Host "Temps d'analyse standard: $($standardResult.ElapsedMilliseconds) ms" -ForegroundColor White
Write-Host "Temps d'analyse avec cache (premier passage): $($cachedResult1.ElapsedMilliseconds) ms" -ForegroundColor White
Write-Host "Temps d'analyse avec cache (deuxiÃƒÂ¨me passage): $($cachedResult2.ElapsedMilliseconds) ms" -ForegroundColor White

$speedup1 = [math]::Round(($standardResult.ElapsedMilliseconds / $cachedResult1.ElapsedMilliseconds), 2)
$speedup2 = [math]::Round(($standardResult.ElapsedMilliseconds / $cachedResult2.ElapsedMilliseconds), 2)

Write-Host "AccÃƒÂ©lÃƒÂ©ration (premier passage): ${speedup1}x" -ForegroundColor Green
Write-Host "AccÃƒÂ©lÃƒÂ©ration (deuxiÃƒÂ¨me passage): ${speedup2}x" -ForegroundColor Green

# VÃƒÂ©rifier que les rÃƒÂ©sultats sont cohÃƒÂ©rents
$standardCount = $standardResult.Result.Count
$cachedCount1 = $cachedResult1.Result.Count
$cachedCount2 = $cachedResult2.Result.Count

Write-Host "`n=== CohÃƒÂ©rence des rÃƒÂ©sultats ===" -ForegroundColor Cyan
Write-Host "Nombre de problÃƒÂ¨mes trouvÃƒÂ©s (analyse standard): $standardCount" -ForegroundColor White
Write-Host "Nombre de problÃƒÂ¨mes trouvÃƒÂ©s (analyse avec cache, premier passage): $cachedCount1" -ForegroundColor White
Write-Host "Nombre de problÃƒÂ¨mes trouvÃƒÂ©s (analyse avec cache, deuxiÃƒÂ¨me passage): $cachedCount2" -ForegroundColor White

if ($cachedCount1 -eq $standardCount -and $cachedCount2 -eq $standardCount) {
    Write-Host "Les rÃƒÂ©sultats sont cohÃƒÂ©rents." -ForegroundColor Green
}
else {
    Write-Host "Les rÃƒÂ©sultats ne sont pas cohÃƒÂ©rents." -ForegroundColor Red
}

# Afficher les statistiques du cache
$cacheFiles = Get-ChildItem -Path $cachePath -Filter "*.xml" -Recurse | Measure-Object
Write-Host "`n=== Statistiques du cache ===" -ForegroundColor Cyan
Write-Host "Nombre de fichiers de cache: $($cacheFiles.Count)" -ForegroundColor White
Write-Host "Taille totale du cache: $([math]::Round((Get-ChildItem -Path $cachePath -Recurse | Measure-Object -Property Length -Sum).Sum / 1KB, 2)) KB" -ForegroundColor White
