#Requires -Version 5.1
<#
.SYNOPSIS
    Test des performances de l'analyse avec et sans cache.
.DESCRIPTION
    Ce script teste les performances de l'analyse de scripts PowerShell avec et sans cache.
.PARAMETER Path
    Chemin du répertoire contenant les scripts PowerShell à analyser.
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

# Vérifier si le répertoire existe
if (-not (Test-Path -Path $Path -PathType Container)) {
    Write-Error "Le répertoire n'existe pas: $Path"
    exit 1
}

# Chemin du script d'analyse
$analyzerPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Invoke-CachedPSScriptAnalyzer.ps1"

if (-not (Test-Path -Path $analyzerPath)) {
    Write-Error "Script Invoke-CachedPSScriptAnalyzer.ps1 non trouvé à l'emplacement: $analyzerPath"
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

# Premier passage sans cache
Write-Host "`n=== Premier passage (sans cache) ===" -ForegroundColor Cyan
$firstPassResult = Measure-ExecutionTime -ScriptBlock {
    & $analyzerPath -Path $Path -UseCache:$false -Recurse
} -Description "Analyse sans cache"

# Deuxième passage avec cache
Write-Host "`n=== Deuxième passage (avec cache) ===" -ForegroundColor Cyan
$secondPassResult = Measure-ExecutionTime -ScriptBlock {
    & $analyzerPath -Path $Path -UseCache -Recurse
} -Description "Analyse avec cache (premier accès)"

# Troisième passage avec cache
Write-Host "`n=== Troisième passage (avec cache) ===" -ForegroundColor Cyan
$thirdPassResult = Measure-ExecutionTime -ScriptBlock {
    & $analyzerPath -Path $Path -UseCache -Recurse
} -Description "Analyse avec cache (deuxième accès)"

# Afficher les statistiques
Write-Host "`n=== Statistiques ===" -ForegroundColor Cyan
Write-Host "Temps sans cache: $($firstPassResult.ElapsedMilliseconds) ms" -ForegroundColor White
Write-Host "Temps avec cache (premier accès): $($secondPassResult.ElapsedMilliseconds) ms" -ForegroundColor White
Write-Host "Temps avec cache (deuxième accès): $($thirdPassResult.ElapsedMilliseconds) ms" -ForegroundColor White

$speedup1 = [math]::Round(($firstPassResult.ElapsedMilliseconds / $secondPassResult.ElapsedMilliseconds), 2)
$speedup2 = [math]::Round(($firstPassResult.ElapsedMilliseconds / $thirdPassResult.ElapsedMilliseconds), 2)

Write-Host "Accélération (premier accès au cache): ${speedup1}x" -ForegroundColor Green
Write-Host "Accélération (deuxième accès au cache): ${speedup2}x" -ForegroundColor Green

# Vérifier que le cache fonctionne correctement
if ($thirdPassResult.ElapsedMilliseconds -lt $firstPassResult.ElapsedMilliseconds) {
    Write-Host "Test réussi: Le cache améliore les performances." -ForegroundColor Green
}
else {
    Write-Host "Test échoué: Le cache n'améliore pas les performances." -ForegroundColor Red
}

# Afficher les statistiques du cache
$cacheFiles = Get-ChildItem -Path $cachePath -Filter "*.xml" -Recurse | Measure-Object
Write-Host "`n=== Statistiques du cache ===" -ForegroundColor Cyan
Write-Host "Nombre de fichiers de cache: $($cacheFiles.Count)" -ForegroundColor White
Write-Host "Taille totale du cache: $([math]::Round((Get-ChildItem -Path $cachePath -Recurse | Measure-Object -Property Length -Sum).Sum / 1KB, 2)) KB" -ForegroundColor White
