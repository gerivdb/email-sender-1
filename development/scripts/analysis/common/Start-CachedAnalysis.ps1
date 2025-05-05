#Requires -Version 5.1
<#
.SYNOPSIS
    Wrapper pour l'analyse de code avec mise en cache des rÃƒÂ©sultats.
.DESCRIPTION
    Ce script est un wrapper pour l'analyse de code qui utilise la mise en cache des rÃƒÂ©sultats
    pour amÃƒÂ©liorer les performances lors des analyses ultÃƒÂ©rieures.
.PARAMETER Path
    Chemin du fichier ou du rÃƒÂ©pertoire ÃƒÂ  analyser.
.PARAMETER Tool
    Outil d'analyse ÃƒÂ  utiliser. Valeurs possibles : PSScriptAnalyzer, All.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour les rÃƒÂ©sultats de l'analyse.
.PARAMETER GenerateHtmlReport
    Indique si un rapport HTML doit ÃƒÂªtre gÃƒÂ©nÃƒÂ©rÃƒÂ©.
.PARAMETER Recurse
    Indique si les sous-rÃƒÂ©pertoires doivent ÃƒÂªtre analysÃƒÂ©s.
.PARAMETER UseCache
    Indique si le cache doit ÃƒÂªtre utilisÃƒÂ© pour amÃƒÂ©liorer les performances. Par dÃƒÂ©faut, le cache n'est pas utilisÃƒÂ©.
.PARAMETER ForceRefresh
    Force l'actualisation du cache mÃƒÂªme si les rÃƒÂ©sultats sont dÃƒÂ©jÃƒÂ  en cache.
.EXAMPLE
    .\Start-CachedAnalysis.ps1 -Path ".\development\scripts" -Tool PSScriptAnalyzer -OutputPath "results.json" -GenerateHtmlReport -Recurse -UseCache
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
    Write-Error "Script Invoke-CachedPSScriptAnalyzer.ps1 non trouvÃƒÂ© ÃƒÂ  l'emplacement: $cachedPSScriptAnalyzerPath"
    exit 1
}

# Fonction pour gÃƒÂ©nÃƒÂ©rer un rapport HTML
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
    <p>GÃƒÂ©nÃƒÂ©rÃƒÂ© le $(Get-Date)</p>

    <div class="summary">
        <h2>RÃƒÂ©sumÃƒÂ©</h2>
        <p>Nombre total de problÃƒÂ¨mes: $($Results.Count)</p>
        <p>Erreurs: $($Results | Where-Object { $_.Severity -eq "Error" } | Measure-Object | Select-Object -ExpandProperty Count)</p>
        <p>Avertissements: $($Results | Where-Object { $_.Severity -eq "Warning" } | Measure-Object | Select-Object -ExpandProperty Count)</p>
        <p>Informations: $($Results | Where-Object { $_.Severity -eq "Information" } | Measure-Object | Select-Object -ExpandProperty Count)</p>
    </div>

    <h2>DÃƒÂ©tails</h2>
    <table>
        <tr>
            <th>Fichier</th>
            <th>Ligne</th>
            <th>Colonne</th>
            <th>SÃƒÂ©vÃƒÂ©ritÃƒÂ©</th>
            <th>RÃƒÂ¨gle</th>
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

# Mesurer le temps d'exÃƒÂ©cution
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# ExÃƒÂ©cuter l'analyse en fonction de l'outil sÃƒÂ©lectionnÃƒÂ©
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

# Afficher un rÃƒÂ©sumÃƒÂ©
Write-Host "Analyse terminÃƒÂ©e en $($elapsedTime.TotalSeconds) secondes." -ForegroundColor Green
Write-Host "Nombre total de problÃƒÂ¨mes trouvÃƒÂ©s: $($results.Count)" -ForegroundColor Yellow

# Grouper les rÃƒÂ©sultats par sÃƒÂ©vÃƒÂ©ritÃƒÂ©
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

# Enregistrer les rÃƒÂ©sultats si demandÃƒÂ©
if ($OutputPath) {
    $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "RÃƒÂ©sultats enregistrÃƒÂ©s dans $OutputPath" -ForegroundColor Green

    # GÃƒÂ©nÃƒÂ©rer un rapport HTML si demandÃƒÂ©
    if ($GenerateHtmlReport) {
        $htmlPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
        New-HtmlReport -Results $results -OutputPath $htmlPath
        Write-Host "Rapport HTML gÃƒÂ©nÃƒÂ©rÃƒÂ© dans $htmlPath" -ForegroundColor Green
    }
}

# Afficher les rÃƒÂ©sultats
return $results
