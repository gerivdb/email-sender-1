#Requires -Version 5.1
<#
.SYNOPSIS
    Profile le code PowerShell pour identifier les goulots d'étranglement.
.DESCRIPTION
    Utilise les outils de profilage PowerShell pour analyser les performances du code
    et identifier les fonctions et lignes de code qui prennent le plus de temps.
.PARAMETER ScriptPath
    Chemin vers le script PowerShell à profiler.
.PARAMETER FunctionName
    Nom de la fonction à profiler dans le script. Si non spécifié, profile tout le script.
.PARAMETER Parameters
    Paramètres à passer au script ou à la fonction lors du profilage.
.PARAMETER Iterations
    Nombre d'itérations à exécuter pour le profilage. Par défaut: 5.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats du profilage. Par défaut: "./profiling-results.json".
.PARAMETER GenerateReport
    Si spécifié, génère un rapport HTML des résultats du profilage.
.EXAMPLE
    .\Start-CodeProfiling.ps1 -ScriptPath ".\MyScript.ps1" -FunctionName "Process-Data" -Parameters @{InputFile="data.csv"; MaxItems=1000}
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,

    [Parameter(Mandatory = $false)]
    [string]$FunctionName,

    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters = @{},

    [Parameter(Mandatory = $false)]
    [int]$Iterations = 5,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./profiling-results.json",

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Fonction pour profiler une ligne de code
function Measure-LineExecution {
    param (
        [string]$ScriptContent,
        [hashtable]$Parameters = @{}
    )

    # Diviser le script en lignes
    $lines = $ScriptContent -split "`n"
    $lineResults = @()

    # Créer un script temporaire pour chaque ligne
    $tempScriptPath = [System.IO.Path]::GetTempFileName() + ".ps1"

    try {
        # Ajouter les paramètres au début du script temporaire
        $paramBlock = ""
        if ($Parameters.Count -gt 0) {
            $paramBlock = "param ("
            $paramEntries = @()

            foreach ($key in $Parameters.Keys) {
                $value = $Parameters[$key]
                $valueType = $value.GetType().Name

                $paramEntries += "    [Parameter()]`n    [$valueType]`$$key = '$value'"
            }

            $paramBlock += $paramEntries -join ",`n"
            $paramBlock += "`n)`n"
        }

        # Analyser chaque ligne significative
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]

            # Ignorer les lignes vides ou les commentaires
            if ([string]::IsNullOrWhiteSpace($line) -or $line.Trim().StartsWith("#")) {
                continue
            }

            # Créer un script temporaire avec cette ligne
            $tempScript = $paramBlock + $line
            $tempScript | Set-Content -Path $tempScriptPath -Encoding UTF8

            # Mesurer l'exécution
            try {
                $result = Measure-Command {
                    & $tempScriptPath @Parameters
                }

                $lineResults += [PSCustomObject]@{
                    LineNumber    = $i + 1
                    Content       = $line
                    ExecutionTime = $result.TotalMilliseconds
                }
            } catch {
                # Ignorer les erreurs, car certaines lignes peuvent ne pas être exécutables individuellement
            }
        }
    } finally {
        # Nettoyer
        if (Test-Path -Path $tempScriptPath) {
            Remove-Item -Path $tempScriptPath -Force
        }
    }

    return $lineResults | Sort-Object -Property ExecutionTime -Descending
}

# Fonction pour profiler un script ou une fonction
function Start-Profiling {
    param (
        [string]$ScriptPath,
        [string]$FunctionName,
        [hashtable]$Parameters,
        [int]$Iterations
    )

    # Vérifier que le script existe
    if (-not (Test-Path -Path $ScriptPath)) {
        throw "Le script n'existe pas: $ScriptPath"
    }

    # Charger le script
    $scriptContent = Get-Content -Path $ScriptPath -Raw

    # Créer un script temporaire pour le profilage
    $tempScriptPath = [System.IO.Path]::GetTempFileName() + ".ps1"

    try {
        # Si une fonction spécifique est demandée, extraire cette fonction
        if ($FunctionName) {
            # Utiliser une expression régulière pour extraire la fonction
            $functionRegex = "function\s+$FunctionName\s*{[^{}]*(?:{[^{}]*}[^{}]*)*}"
            $functionMatch = [regex]::Match($scriptContent, $functionRegex, [System.Text.RegularExpressions.RegexOptions]::Singleline)

            if (-not $functionMatch.Success) {
                throw "Fonction '$FunctionName' non trouvée dans le script."
            }

            $functionContent = $functionMatch.Value

            # Créer un script temporaire avec juste cette fonction
            $tempScript = @"
$functionContent

# Appeler la fonction avec les paramètres spécifiés
$FunctionName @Parameters
"@
            $tempScript | Set-Content -Path $tempScriptPath -Encoding UTF8
        } else {
            # Utiliser le script complet
            $scriptContent | Set-Content -Path $tempScriptPath -Encoding UTF8
        }

        # Profiler avec Trace-Command
        $traceResults = @()

        for ($i = 1; $i -le $Iterations; $i++) {
            Write-Host "Exécution de l'itération $i sur $Iterations..." -ForegroundColor Cyan

            $traceFile = [System.IO.Path]::GetTempFileName()

            try {
                # Utiliser Trace-Command pour profiler
                Trace-Command -Name ParameterBinding, Command, Provider -PSHost -FilePath $traceFile {
                    & $tempScriptPath @Parameters
                }

                # Lire les résultats de trace
                $traceContent = Get-Content -Path $traceFile -Raw
                $traceResults += $traceContent
            } finally {
                if (Test-Path -Path $traceFile) {
                    Remove-Item -Path $traceFile -Force
                }
            }
        }

        # Mesurer le temps d'exécution global
        $executionTimes = @()

        # Ajouter le paramètre OutputPath s'il n'est pas déjà fourni
        if (-not $Parameters.ContainsKey("OutputPath")) {
            $Parameters["OutputPath"] = [System.IO.Path]::GetTempFileName() + ".json"
        }

        for ($i = 1; $i -le $Iterations; $i++) {
            Write-Host "Mesure du temps d'exécution, itération $i sur $Iterations..." -ForegroundColor Cyan

            $result = Measure-Command {
                & $tempScriptPath @Parameters
            }

            $executionTimes += $result.TotalMilliseconds
        }

        # Profiler les lignes individuelles
        Write-Host "Analyse des lignes de code..." -ForegroundColor Cyan
        $lineResults = Measure-LineExecution -ScriptContent $scriptContent -Parameters $Parameters

        # Analyser les résultats
        $avgExecutionTime = ($executionTimes | Measure-Object -Average).Average
        $minExecutionTime = ($executionTimes | Measure-Object -Minimum).Minimum
        $maxExecutionTime = ($executionTimes | Measure-Object -Maximum).Maximum

        # Préparer les résultats
        $profilingResults = [PSCustomObject]@{
            Timestamp            = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ScriptPath           = $ScriptPath
            FunctionName         = $FunctionName
            Parameters           = $Parameters
            Iterations           = $Iterations
            ExecutionTimes       = $executionTimes
            AverageExecutionTime = $avgExecutionTime
            MinExecutionTime     = $minExecutionTime
            MaxExecutionTime     = $maxExecutionTime
            HotspotLines         = $lineResults | Select-Object -First 10
            TraceResults         = $traceResults
        }

        return $profilingResults
    } finally {
        # Nettoyer
        if (Test-Path -Path $tempScriptPath) {
            Remove-Item -Path $tempScriptPath -Force
        }
    }
}

# Fonction pour générer un rapport HTML
function New-ProfilingReport {
    param (
        [object]$ProfilingResults,
        [string]$OutputPath
    )

    $hotspotRows = ""
    foreach ($line in $ProfilingResults.HotspotLines) {
        $hotspotRows += @"
        <tr>
            <td>$($line.LineNumber)</td>
            <td><pre><code>$($line.Content)</code></pre></td>
            <td>$([Math]::Round($line.ExecutionTime, 2)) ms</td>
        </tr>
"@
    }

    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de profilage de code</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 1px solid #eee;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .metric-card {
            background-color: #f8f9fa;
            border-radius: 8px;
            padding: 15px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .metric-title {
            font-size: 0.9em;
            color: #6c757d;
            margin-bottom: 5px;
        }
        .metric-value {
            font-size: 1.8em;
            font-weight: bold;
            color: #2c3e50;
        }
        .metric-unit {
            font-size: 0.8em;
            color: #6c757d;
        }
        .section {
            margin-bottom: 40px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        pre {
            background-color: #f8f9fa;
            padding: 10px;
            border-radius: 4px;
            overflow-x: auto;
        }
        code {
            font-family: Consolas, Monaco, 'Andale Mono', monospace;
            font-size: 0.9em;
        }
        .footer {
            text-align: center;
            margin-top: 50px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #6c757d;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Rapport de profilage de code</h1>
        <p>Généré le $($ProfilingResults.Timestamp)</p>
    </div>

    <div class="section">
        <h2>Résumé</h2>
        <div class="summary">
            <div class="metric-card">
                <div class="metric-title">Script</div>
                <div class="metric-value">$([System.IO.Path]::GetFileName($ProfilingResults.ScriptPath))</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Fonction</div>
                <div class="metric-value">$(if ($null -ne $ProfilingResults.FunctionName -and $ProfilingResults.FunctionName -ne "") { $ProfilingResults.FunctionName } else { "Script complet" })</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Temps d'exécution moyen</div>
                <div class="metric-value">$([Math]::Round($ProfilingResults.AverageExecutionTime, 2))<span class="metric-unit">ms</span></div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Temps d'exécution min</div>
                <div class="metric-value">$([Math]::Round($ProfilingResults.MinExecutionTime, 2))<span class="metric-unit">ms</span></div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Temps d'exécution max</div>
                <div class="metric-value">$([Math]::Round($ProfilingResults.MaxExecutionTime, 2))<span class="metric-unit">ms</span></div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Itérations</div>
                <div class="metric-value">$($ProfilingResults.Iterations)</div>
            </div>
        </div>
    </div>

    <div class="section">
        <h2>Points chauds (Hotspots)</h2>
        <p>Les lignes de code qui prennent le plus de temps à s'exécuter :</p>
        <table>
            <tr>
                <th>Ligne</th>
                <th>Code</th>
                <th>Temps d'exécution</th>
            </tr>
            $hotspotRows
        </table>
    </div>

    <div class="section">
        <h2>Recommandations</h2>
        <p>Basé sur l'analyse de performance, voici quelques recommandations :</p>
        <ul>
            <li>Concentrez-vous sur l'optimisation des lignes identifiées comme points chauds.</li>
            <li>Envisagez d'utiliser des structures de données plus efficaces pour les opérations fréquentes.</li>
            <li>Réduisez les appels redondants aux fonctions coûteuses.</li>
            <li>Utilisez des techniques de mise en cache pour les opérations répétitives.</li>
            <li>Envisagez la parallélisation pour les tâches indépendantes.</li>
        </ul>
    </div>

    <div class="footer">
        <p>Rapport généré par Start-CodeProfiling.ps1</p>
    </div>
</body>
</html>
"@

    $html | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "Rapport HTML généré: $OutputPath" -ForegroundColor Green
}

# Fonction principale
function Main {
    # Vérifier que le répertoire de sortie existe
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        Write-Host "Répertoire de sortie créé: $outputDir" -ForegroundColor Cyan
    }

    # Exécuter le profilage
    Write-Host "Démarrage du profilage..." -ForegroundColor Cyan
    Write-Host "  Script: $ScriptPath"
    if ($FunctionName) {
        Write-Host "  Fonction: $FunctionName"
    }
    Write-Host "  Itérations: $Iterations"

    # Préparer les paramètres pour le script à profiler
    # Ajouter un paramètre OutputPath temporaire si le script est Simple-PRLoadTest.ps1
    $scriptParams = $Parameters.Clone()
    if ([System.IO.Path]::GetFileName($ScriptPath) -eq "Simple-PRLoadTest.ps1" -and -not $scriptParams.ContainsKey("OutputPath")) {
        $scriptParams["OutputPath"] = [System.IO.Path]::GetTempFileName() + ".json"
    }

    try {
        $results = Start-Profiling -ScriptPath $ScriptPath -FunctionName $FunctionName -Parameters $scriptParams -Iterations $Iterations

        # Enregistrer les résultats
        $results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
        Write-Host "Résultats du profilage enregistrés: $OutputPath" -ForegroundColor Green

        # Générer un rapport HTML si demandé
        if ($GenerateReport) {
            $reportPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
            New-ProfilingReport -ProfilingResults $results -OutputPath $reportPath
        }

        # Afficher un résumé
        Write-Host "`nRésumé du profilage:" -ForegroundColor Cyan
        Write-Host "===================" -ForegroundColor Cyan
        Write-Host "Temps d'exécution moyen: $([Math]::Round($results.AverageExecutionTime, 2)) ms"
        Write-Host "Temps d'exécution min: $([Math]::Round($results.MinExecutionTime, 2)) ms"
        Write-Host "Temps d'exécution max: $([Math]::Round($results.MaxExecutionTime, 2)) ms"

        Write-Host "`nPoints chauds (Top 5):" -ForegroundColor Yellow
        $results.HotspotLines | Select-Object -First 5 | ForEach-Object {
            Write-Host "  Ligne $($_.LineNumber): $([Math]::Round($_.ExecutionTime, 2)) ms"
            Write-Host "    $($_.Content)" -ForegroundColor Gray
        }

        return $results
    } catch {
        Write-Error "Erreur lors du profilage: $_"
    }
}

# Exécuter le script
Main
