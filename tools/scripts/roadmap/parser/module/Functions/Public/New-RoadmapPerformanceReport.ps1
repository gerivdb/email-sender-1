<#
.SYNOPSIS
    GÃ©nÃ¨re un rapport de performance basÃ© sur les mesures collectÃ©es.

.DESCRIPTION
    La fonction New-RoadmapPerformanceReport gÃ©nÃ¨re un rapport dÃ©taillÃ© des performances
    basÃ© sur les mesures de temps d'exÃ©cution, d'utilisation de mÃ©moire et de comptage d'opÃ©rations.
    Le rapport peut Ãªtre gÃ©nÃ©rÃ© dans diffÃ©rents formats (texte, HTML, JSON, CSV) et peut Ãªtre
    enregistrÃ© dans un fichier ou retournÃ© sous forme d'objet.

.PARAMETER Format
    Le format du rapport. Les valeurs possibles sont : Text, HTML, JSON, CSV.
    Par dÃ©faut : Text.

.PARAMETER OutputPath
    Le chemin du fichier oÃ¹ enregistrer le rapport. Si non spÃ©cifiÃ©, le rapport est retournÃ©
    sous forme d'objet ou de chaÃ®ne de caractÃ¨res.

.PARAMETER IncludeExecutionTime
    Indique si les statistiques de temps d'exÃ©cution doivent Ãªtre incluses dans le rapport.
    Par dÃ©faut : $true.

.PARAMETER IncludeMemoryUsage
    Indique si les statistiques d'utilisation de mÃ©moire doivent Ãªtre incluses dans le rapport.
    Par dÃ©faut : $true.

.PARAMETER IncludeOperations
    Indique si les statistiques de comptage d'opÃ©rations doivent Ãªtre incluses dans le rapport.
    Par dÃ©faut : $true.

.PARAMETER TimerName
    Le nom du chronomÃ¨tre spÃ©cifique Ã  inclure dans le rapport. Si non spÃ©cifiÃ©, tous les chronomÃ¨tres sont inclus.

.PARAMETER MemoryName
    Le nom de la mesure de mÃ©moire spÃ©cifique Ã  inclure dans le rapport. Si non spÃ©cifiÃ©, toutes les mesures de mÃ©moire sont incluses.

.PARAMETER OperationName
    Le nom du compteur d'opÃ©rations spÃ©cifique Ã  inclure dans le rapport. Si non spÃ©cifiÃ©, tous les compteurs d'opÃ©rations sont inclus.

.PARAMETER Title
    Le titre du rapport. Par dÃ©faut : "Rapport de performance RoadmapParser".

.PARAMETER IncludeTimestamp
    Indique si l'horodatage doit Ãªtre inclus dans le rapport. Par dÃ©faut : $true.

.EXAMPLE
    New-RoadmapPerformanceReport -Format HTML -OutputPath "C:\Reports\performance_report.html"
    GÃ©nÃ¨re un rapport de performance au format HTML et l'enregistre dans le fichier spÃ©cifiÃ©.

.EXAMPLE
    New-RoadmapPerformanceReport -TimerName "ParseRoadmap" -IncludeMemoryUsage $false
    GÃ©nÃ¨re un rapport de performance au format texte pour le chronomÃ¨tre "ParseRoadmap" sans inclure les statistiques d'utilisation de mÃ©moire.

.OUTPUTS
    [string] ou [PSCustomObject] ou [void] selon le format et si un chemin de sortie est spÃ©cifiÃ©.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-24
#>
function New-RoadmapPerformanceReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "HTML", "JSON", "CSV")]
        [string]$Format = "Text",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeExecutionTime = $true,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeMemoryUsage = $true,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeOperations = $true,

        [Parameter(Mandatory = $false)]
        [string]$TimerName,

        [Parameter(Mandatory = $false)]
        [string]$MemoryName,

        [Parameter(Mandatory = $false)]
        [string]$OperationName,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport de performance RoadmapParser",

        [Parameter(Mandatory = $false)]
        [bool]$IncludeTimestamp = $true
    )

    # Importer les fonctions de mesure de performance
    $modulePath = $PSScriptRoot
    if ($modulePath -match '\\Functions\\Public$') {
        $modulePath = Split-Path -Parent (Split-Path -Parent $modulePath)
    }
    $privatePath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Performance"
    $performanceFunctionsPath = Join-Path -Path $privatePath -ChildPath "PerformanceMeasurementFunctions.ps1"

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $performanceFunctionsPath)) {
        throw "Le fichier PerformanceMeasurementFunctions.ps1 est introuvable Ã  l'emplacement : $performanceFunctionsPath"
    }

    # Importer les fonctions
    . $performanceFunctionsPath

    # Collecter les donnÃ©es de performance
    $performanceData = [PSCustomObject]@{
        GeneratedAt   = Get-Date
        Title         = $Title
        ExecutionTime = if ($IncludeExecutionTime) {
            if ($TimerName) {
                Get-PerformanceStatistics -Name $TimerName
            } else {
                Get-PerformanceStatistics
            }
        } else {
            $null
        }
        MemoryUsage   = if ($IncludeMemoryUsage) {
            if ($MemoryName) {
                Get-MemoryStatistics -Name $MemoryName
            } else {
                Get-MemoryStatistics
            }
        } else {
            $null
        }
        Operations    = if ($IncludeOperations) {
            if ($OperationName) {
                Get-OperationStatistics -Name $OperationName
            } else {
                Get-OperationStatistics
            }
        } else {
            $null
        }
    }

    # GÃ©nÃ©rer le rapport selon le format demandÃ©
    switch ($Format) {
        "Text" {
            $report = New-TextPerformanceReport -PerformanceData $performanceData -IncludeTimestamp $IncludeTimestamp
        }
        "HTML" {
            $report = New-HtmlPerformanceReport -PerformanceData $performanceData -IncludeTimestamp $IncludeTimestamp
        }
        "JSON" {
            $report = $performanceData | ConvertTo-Json -Depth 10
        }
        "CSV" {
            $report = New-CsvPerformanceReport -PerformanceData $performanceData
        }
    }

    # Enregistrer le rapport dans un fichier si un chemin est spÃ©cifiÃ©
    if ($OutputPath) {
        # CrÃ©er le dossier parent s'il n'existe pas
        $parentFolder = Split-Path -Parent $OutputPath
        if (-not [string]::IsNullOrEmpty($parentFolder) -and -not (Test-Path -Path $parentFolder)) {
            New-Item -ItemType Directory -Path $parentFolder -Force | Out-Null
        }

        # Enregistrer le rapport
        $report | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Log -Message "Rapport de performance enregistrÃ© dans : $OutputPath" -Level $script:LogLevelInfo -Source "PerformanceReport"
    } else {
        # Retourner le rapport
        return $report
    }
}

# Fonction privÃ©e pour gÃ©nÃ©rer un rapport au format texte
function New-TextPerformanceReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PerformanceData,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeTimestamp = $true
    )

    $sb = [System.Text.StringBuilder]::new()

    # Ajouter le titre
    [void]$sb.AppendLine("=" * 80)
    [void]$sb.AppendLine("  $($PerformanceData.Title)")
    [void]$sb.AppendLine("=" * 80)

    # Ajouter l'horodatage si demandÃ©
    if ($IncludeTimestamp) {
        [void]$sb.AppendLine("GÃ©nÃ©rÃ© le : $($PerformanceData.GeneratedAt)")
        [void]$sb.AppendLine("-" * 80)
    }

    # Ajouter les statistiques de temps d'exÃ©cution
    if ($PerformanceData.ExecutionTime) {
        [void]$sb.AppendLine("`nSTATISTIQUES DE TEMPS D'EXÃ‰CUTION")
        [void]$sb.AppendLine("-" * 80)
        [void]$sb.AppendLine("| Nom | ExÃ©cutions | Min (ms) | Max (ms) | Moyenne (ms) | Total (ms) | Dernier (ms) |")
        [void]$sb.AppendLine("|" + "-" * 78 + "|")

        foreach ($stat in $PerformanceData.ExecutionTime) {
            [void]$sb.AppendLine("| $($stat.Name.PadRight(20)) | $($stat.Count.ToString().PadRight(10)) | $($stat.MinDurationMs.ToString().PadRight(8)) | $($stat.MaxDurationMs.ToString().PadRight(8)) | $($stat.AverageDurationMs.ToString("F2").PadRight(12)) | $($stat.TotalDurationMs.ToString().PadRight(10)) | $($stat.LastDurationMs.ToString().PadRight(11)) |")
        }
    }

    # Ajouter les statistiques d'utilisation de mÃ©moire
    if ($PerformanceData.MemoryUsage) {
        [void]$sb.AppendLine("`nSTATISTIQUES D'UTILISATION DE MÃ‰MOIRE")
        [void]$sb.AppendLine("-" * 80)
        [void]$sb.AppendLine("| Nom | ExÃ©cutions | Min (octets) | Max (octets) | Moyenne (octets) | Total (octets) | Dernier (octets) |")
        [void]$sb.AppendLine("|" + "-" * 78 + "|")

        foreach ($stat in $PerformanceData.MemoryUsage) {
            [void]$sb.AppendLine("| $($stat.Name.PadRight(20)) | $($stat.Count.ToString().PadRight(10)) | $($stat.MinBytes.ToString().PadRight(12)) | $($stat.MaxBytes.ToString().PadRight(12)) | $($stat.AverageBytes.ToString("F2").PadRight(16)) | $($stat.TotalBytes.ToString().PadRight(14)) | $($stat.LastBytes.ToString().PadRight(15)) |")
        }
    }

    # Ajouter les statistiques de comptage d'opÃ©rations
    if ($PerformanceData.Operations) {
        [void]$sb.AppendLine("`nSTATISTIQUES DE COMPTAGE D'OPÃ‰RATIONS")
        [void]$sb.AppendLine("-" * 80)
        [void]$sb.AppendLine("| Nom | ExÃ©cutions | Min (ops) | Max (ops) | Moyenne (ops) | Total (ops) | Dernier (ops) | Actuel |")
        [void]$sb.AppendLine("|" + "-" * 78 + "|")

        foreach ($stat in $PerformanceData.Operations) {
            [void]$sb.AppendLine("| $($stat.Name.PadRight(20)) | $($stat.Count.ToString().PadRight(10)) | $($stat.MinOperations.ToString().PadRight(9)) | $($stat.MaxOperations.ToString().PadRight(9)) | $($stat.AverageOperations.ToString("F2").PadRight(13)) | $($stat.TotalOperations.ToString().PadRight(11)) | $($stat.LastOperations.ToString().PadRight(12)) | $($stat.CurrentValue.ToString()) |")
        }
    }

    return $sb.ToString()
}

# Fonction privÃ©e pour gÃ©nÃ©rer un rapport au format HTML
function New-HtmlPerformanceReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PerformanceData,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeTimestamp = $true
    )

    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$($PerformanceData.Title)</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1 {
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        h2 {
            color: #2980b9;
            margin-top: 30px;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 30px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
            font-weight: bold;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        tr:hover {
            background-color: #f1f1f1;
        }
        .timestamp {
            color: #7f8c8d;
            font-style: italic;
            margin-bottom: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>$($PerformanceData.Title)</h1>
"@

    # Ajouter l'horodatage si demandÃ©
    if ($IncludeTimestamp) {
        $html += @"
        <div class="timestamp">GÃ©nÃ©rÃ© le : $($PerformanceData.GeneratedAt)</div>
"@
    }

    # Ajouter les statistiques de temps d'exÃ©cution
    if ($PerformanceData.ExecutionTime) {
        $html += @"
        <h2>Statistiques de temps d'exÃ©cution</h2>
        <table>
            <thead>
                <tr>
                    <th>Nom</th>
                    <th>ExÃ©cutions</th>
                    <th>Min (ms)</th>
                    <th>Max (ms)</th>
                    <th>Moyenne (ms)</th>
                    <th>Total (ms)</th>
                    <th>Dernier (ms)</th>
                </tr>
            </thead>
            <tbody>
"@

        foreach ($stat in $PerformanceData.ExecutionTime) {
            $html += @"
                <tr>
                    <td>$($stat.Name)</td>
                    <td>$($stat.Count)</td>
                    <td>$($stat.MinDurationMs)</td>
                    <td>$($stat.MaxDurationMs)</td>
                    <td>$($stat.AverageDurationMs.ToString("F2"))</td>
                    <td>$($stat.TotalDurationMs)</td>
                    <td>$($stat.LastDurationMs)</td>
                </tr>
"@
        }

        $html += @"
            </tbody>
        </table>
"@
    }

    # Ajouter les statistiques d'utilisation de mÃ©moire
    if ($PerformanceData.MemoryUsage) {
        $html += @"
        <h2>Statistiques d'utilisation de mÃ©moire</h2>
        <table>
            <thead>
                <tr>
                    <th>Nom</th>
                    <th>ExÃ©cutions</th>
                    <th>Min (octets)</th>
                    <th>Max (octets)</th>
                    <th>Moyenne (octets)</th>
                    <th>Total (octets)</th>
                    <th>Dernier (octets)</th>
                </tr>
            </thead>
            <tbody>
"@

        foreach ($stat in $PerformanceData.MemoryUsage) {
            $html += @"
                <tr>
                    <td>$($stat.Name)</td>
                    <td>$($stat.Count)</td>
                    <td>$($stat.MinBytes)</td>
                    <td>$($stat.MaxBytes)</td>
                    <td>$($stat.AverageBytes.ToString("F2"))</td>
                    <td>$($stat.TotalBytes)</td>
                    <td>$($stat.LastBytes)</td>
                </tr>
"@
        }

        $html += @"
            </tbody>
        </table>
"@
    }

    # Ajouter les statistiques de comptage d'opÃ©rations
    if ($PerformanceData.Operations) {
        $html += @"
        <h2>Statistiques de comptage d'opÃ©rations</h2>
        <table>
            <thead>
                <tr>
                    <th>Nom</th>
                    <th>ExÃ©cutions</th>
                    <th>Min (ops)</th>
                    <th>Max (ops)</th>
                    <th>Moyenne (ops)</th>
                    <th>Total (ops)</th>
                    <th>Dernier (ops)</th>
                    <th>Actuel</th>
                </tr>
            </thead>
            <tbody>
"@

        foreach ($stat in $PerformanceData.Operations) {
            $html += @"
                <tr>
                    <td>$($stat.Name)</td>
                    <td>$($stat.Count)</td>
                    <td>$($stat.MinOperations)</td>
                    <td>$($stat.MaxOperations)</td>
                    <td>$($stat.AverageOperations.ToString("F2"))</td>
                    <td>$($stat.TotalOperations)</td>
                    <td>$($stat.LastOperations)</td>
                    <td>$($stat.CurrentValue)</td>
                </tr>
"@
        }

        $html += @"
            </tbody>
        </table>
"@
    }

    $html += @"
    </div>
</body>
</html>
"@

    return $html
}

# Fonction privÃ©e pour gÃ©nÃ©rer un rapport au format CSV
function New-CsvPerformanceReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PerformanceData
    )

    $csvData = @()

    # Ajouter les statistiques de temps d'exÃ©cution
    if ($PerformanceData.ExecutionTime) {
        foreach ($stat in $PerformanceData.ExecutionTime) {
            $csvData += [PSCustomObject]@{
                Type    = "ExecutionTime"
                Name    = $stat.Name
                Count   = $stat.Count
                Min     = $stat.MinDurationMs
                Max     = $stat.MaxDurationMs
                Average = $stat.AverageDurationMs
                Total   = $stat.TotalDurationMs
                Last    = $stat.LastDurationMs
                Current = "N/A"
            }
        }
    }

    # Ajouter les statistiques d'utilisation de mÃ©moire
    if ($PerformanceData.MemoryUsage) {
        foreach ($stat in $PerformanceData.MemoryUsage) {
            $csvData += [PSCustomObject]@{
                Type    = "MemoryUsage"
                Name    = $stat.Name
                Count   = $stat.Count
                Min     = $stat.MinBytes
                Max     = $stat.MaxBytes
                Average = $stat.AverageBytes
                Total   = $stat.TotalBytes
                Last    = $stat.LastBytes
                Current = "N/A"
            }
        }
    }

    # Ajouter les statistiques de comptage d'opÃ©rations
    if ($PerformanceData.Operations) {
        foreach ($stat in $PerformanceData.Operations) {
            $csvData += [PSCustomObject]@{
                Type    = "Operations"
                Name    = $stat.Name
                Count   = $stat.Count
                Min     = $stat.MinOperations
                Max     = $stat.MaxOperations
                Average = $stat.AverageOperations
                Total   = $stat.TotalOperations
                Last    = $stat.LastOperations
                Current = $stat.CurrentValue
            }
        }
    }

    # Convertir les donnÃ©es en CSV
    return $csvData | ConvertTo-Csv -NoTypeInformation
}

# Exporter la fonction
# Export-ModuleMember -Function New-RoadmapPerformanceReport
