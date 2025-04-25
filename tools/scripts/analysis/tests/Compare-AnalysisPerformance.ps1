#Requires -Version 5.1
<#
.SYNOPSIS
    Compare les performances de l'analyse standard et de l'analyse avec cache.
.DESCRIPTION
    Ce script compare les performances de l'analyse standard (Start-CodeAnalysis.ps1)
    et de l'analyse avec cache (Start-CachedAnalysis.ps1).
.PARAMETER Path
    Chemin du répertoire contenant les scripts PowerShell à analyser.
.EXAMPLE
    .\Compare-AnalysisPerformance.ps1 -Path ".\scripts"
.NOTES
    Author: Augment Agent
    Version: 1.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

# Vérifier si le répertoire existe
if (-not (Test-Path -Path $Path -PathType Container)) {
    Write-Error "Le répertoire n'existe pas: $Path"
    exit 1
}

# Chemins des scripts d'analyse
$scriptPath = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$standardAnalysisPath = Join-Path -Path $scriptPath -ChildPath "Start-CodeAnalysis.ps1"
$cachedAnalysisPath = Join-Path -Path $scriptPath -ChildPath "Start-CachedAnalysis.ps1"

if (-not (Test-Path -Path $standardAnalysisPath)) {
    Write-Error "Script Start-CodeAnalysis.ps1 non trouvé à l'emplacement: $standardAnalysisPath"
    exit 1
}

if (-not (Test-Path -Path $cachedAnalysisPath)) {
    Write-Error "Script Start-CachedAnalysis.ps1 non trouvé à l'emplacement: $cachedAnalysisPath"
    exit 1
}

# Fonction pour mesurer le temps d'exécution
function Measure-ExecutionTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [string]$Description = "Opération"
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & $ScriptBlock
    $stopwatch.Stop()
    
    Write-Host "$Description terminé en $($stopwatch.ElapsedMilliseconds) ms" -ForegroundColor Cyan
    
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

# Analyse avec cache (deuxième passage)
Write-Host "`n=== Analyse avec cache (deuxième passage) ===" -ForegroundColor Cyan
$cachedResult2 = Measure-ExecutionTime -ScriptBlock {
    & $cachedAnalysisPath -Path $Path -Tool PSScriptAnalyzer -UseCache -Recurse
} -Description "Analyse avec cache (deuxième passage)"

# Afficher les statistiques
Write-Host "`n=== Statistiques ===" -ForegroundColor Cyan
Write-Host "Temps d'analyse standard: $($standardResult.ElapsedMilliseconds) ms" -ForegroundColor White
Write-Host "Temps d'analyse avec cache (premier passage): $($cachedResult1.ElapsedMilliseconds) ms" -ForegroundColor White
Write-Host "Temps d'analyse avec cache (deuxième passage): $($cachedResult2.ElapsedMilliseconds) ms" -ForegroundColor White

$speedup1 = [math]::Round(($standardResult.ElapsedMilliseconds / $cachedResult1.ElapsedMilliseconds), 2)
$speedup2 = [math]::Round(($standardResult.ElapsedMilliseconds / $cachedResult2.ElapsedMilliseconds), 2)

Write-Host "Accélération (premier passage): ${speedup1}x" -ForegroundColor Green
Write-Host "Accélération (deuxième passage): ${speedup2}x" -ForegroundColor Green

# Vérifier que les résultats sont cohérents
$standardCount = $standardResult.Result.Count
$cachedCount1 = $cachedResult1.Result.Count
$cachedCount2 = $cachedResult2.Result.Count

Write-Host "`n=== Cohérence des résultats ===" -ForegroundColor Cyan
Write-Host "Nombre de problèmes trouvés (analyse standard): $standardCount" -ForegroundColor White
Write-Host "Nombre de problèmes trouvés (analyse avec cache, premier passage): $cachedCount1" -ForegroundColor White
Write-Host "Nombre de problèmes trouvés (analyse avec cache, deuxième passage): $cachedCount2" -ForegroundColor White

if ($cachedCount1 -eq $standardCount -and $cachedCount2 -eq $standardCount) {
    Write-Host "Les résultats sont cohérents." -ForegroundColor Green
}
else {
    Write-Host "Les résultats ne sont pas cohérents." -ForegroundColor Red
}

# Afficher les statistiques du cache
$cacheFiles = Get-ChildItem -Path $cachePath -Filter "*.xml" -Recurse | Measure-Object
Write-Host "`n=== Statistiques du cache ===" -ForegroundColor Cyan
Write-Host "Nombre de fichiers de cache: $($cacheFiles.Count)" -ForegroundColor White
Write-Host "Taille totale du cache: $([math]::Round((Get-ChildItem -Path $cachePath -Recurse | Measure-Object -Property Length -Sum).Sum / 1KB, 2)) KB" -ForegroundColor White
