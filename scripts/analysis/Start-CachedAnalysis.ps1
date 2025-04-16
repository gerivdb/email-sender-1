#Requires -Version 5.1
<#
.SYNOPSIS
    Wrapper pour l'analyse de code avec mise en cache des résultats.
.DESCRIPTION
    Ce script est un wrapper pour l'analyse de code qui utilise la mise en cache des résultats
    pour améliorer les performances lors des analyses ultérieures.
.PARAMETER Path
    Chemin du fichier ou du répertoire à analyser.
.PARAMETER Tool
    Outil d'analyse à utiliser. Valeurs possibles : PSScriptAnalyzer, All.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour les résultats de l'analyse.
.PARAMETER GenerateHtmlReport
    Indique si un rapport HTML doit être généré.
.PARAMETER Recurse
    Indique si les sous-répertoires doivent être analysés.
.PARAMETER UseCache
    Indique si le cache doit être utilisé pour améliorer les performances. Par défaut, le cache n'est pas utilisé.
.PARAMETER ForceRefresh
    Force l'actualisation du cache même si les résultats sont déjà en cache.
.EXAMPLE
    .\Start-CachedAnalysis.ps1 -Path ".\scripts" -Tool PSScriptAnalyzer -OutputPath "results.json" -GenerateHtmlReport -Recurse -UseCache
.NOTES
    Author: Augment Agent
    Version: 1.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter()]
    [ValidateSet("PSScriptAnalyzer", "All")]
    [string]$Tool = "PSScriptAnalyzer",

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [switch]$GenerateHtmlReport,

    [Parameter()]
    [switch]$Recurse,

    [Parameter()]
    [switch]$UseCache,

    [Parameter()]
    [switch]$ForceRefresh
)

# Chemin des scripts d'analyse
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$cachedPSScriptAnalyzerPath = Join-Path -Path $scriptPath -ChildPath "Invoke-CachedPSScriptAnalyzer.ps1"

if (-not (Test-Path -Path $cachedPSScriptAnalyzerPath)) {
    Write-Error "Script Invoke-CachedPSScriptAnalyzer.ps1 non trouvé à l'emplacement: $cachedPSScriptAnalyzerPath"
    exit 1
}

# Fonction pour générer un rapport HTML
function New-HtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Results,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'analyse de code</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .error { background-color: #ffdddd; }
        .warning { background-color: #ffffcc; }
        .information { background-color: #e6f3ff; }
        .summary { margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Rapport d'analyse de code</h1>
    <p>Généré le $(Get-Date)</p>

    <div class="summary">
        <h2>Résumé</h2>
        <p>Nombre total de problèmes: $($Results.Count)</p>
        <p>Erreurs: $($Results | Where-Object { $_.Severity -eq "Error" } | Measure-Object | Select-Object -ExpandProperty Count)</p>
        <p>Avertissements: $($Results | Where-Object { $_.Severity -eq "Warning" } | Measure-Object | Select-Object -ExpandProperty Count)</p>
        <p>Informations: $($Results | Where-Object { $_.Severity -eq "Information" } | Measure-Object | Select-Object -ExpandProperty Count)</p>
    </div>

    <h2>Détails</h2>
    <table>
        <tr>
            <th>Fichier</th>
            <th>Ligne</th>
            <th>Colonne</th>
            <th>Sévérité</th>
            <th>Règle</th>
            <th>Message</th>
        </tr>
"@

    foreach ($result in $Results) {
        $rowClass = switch ($result.Severity) {
            "Error" { "error" }
            "Warning" { "warning" }
            "Information" { "information" }
            default { "" }
        }

        $html += @"
        <tr class="$rowClass">
            <td>$($result.ScriptName)</td>
            <td>$($result.Line)</td>
            <td>$($result.Column)</td>
            <td>$($result.Severity)</td>
            <td>$($result.RuleName)</td>
            <td>$($result.Message)</td>
        </tr>
"@
    }

    $html += @"
    </table>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
}

# Mesurer le temps d'exécution
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Exécuter l'analyse en fonction de l'outil sélectionné
$results = @()

if ($Tool -eq "PSScriptAnalyzer" -or $Tool -eq "All") {
    Write-Host "Analyse avec PSScriptAnalyzer..." -ForegroundColor Cyan

    $params = @{
        Path         = $Path
        Recurse      = $Recurse
        UseCache     = $UseCache
        ForceRefresh = $ForceRefresh
    }

    $psaResults = & $cachedPSScriptAnalyzerPath @params
    $results += $psaResults
}

$stopwatch.Stop()
$elapsedTime = $stopwatch.Elapsed

# Afficher un résumé
Write-Host "Analyse terminée en $($elapsedTime.TotalSeconds) secondes." -ForegroundColor Green
Write-Host "Nombre total de problèmes trouvés: $($results.Count)" -ForegroundColor Yellow

# Grouper les résultats par sévérité
$resultsBySeverity = $results | Group-Object -Property Severity -NoElement
foreach ($group in $resultsBySeverity) {
    $color = switch ($group.Name) {
        "Error" { "Red" }
        "Warning" { "Yellow" }
        "Information" { "Cyan" }
        default { "White" }
    }

    Write-Host "$($group.Name): $($group.Count)" -ForegroundColor $color
}

# Enregistrer les résultats si demandé
if ($OutputPath) {
    $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Résultats enregistrés dans $OutputPath" -ForegroundColor Green

    # Générer un rapport HTML si demandé
    if ($GenerateHtmlReport) {
        $htmlPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
        New-HtmlReport -Results $results -OutputPath $htmlPath
        Write-Host "Rapport HTML généré dans $htmlPath" -ForegroundColor Green
    }
}

# Afficher les résultats
return $results
