<#
.SYNOPSIS
    Fonctions mock pour les tests unitaires.
.DESCRIPTION
    Ce script contient des fonctions mock pour les tests unitaires.
#>

# Fonction pour vÃ©rifier si un script utilise la parallÃ©lisation
function Test-ScriptUsesParallelization {
    param (
        [string]$ScriptPath
    )

    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $ScriptPath)) {
        # Utiliser le mock pour les chemins de test
        if ($ScriptPath -like "*Test1.ps1" -or $ScriptPath -like "*Test3.ps1") {
            return $true
        }
        return $false
    }

    try {
        $content = Get-Content -Path $ScriptPath -Raw -ErrorAction Stop

        # VÃ©rifier les patterns de parallÃ©lisation courants
        $parallelPatterns = @(
            'Invoke-Parallel',
            'Start-ThreadJob',
            'ForEach-Object -Parallel',
            'Invoke-OptimizedParallel',
            'RunspacePool',
            'System.Threading',
            'Parallel\s+processing',
            'MaxThreads',
            'MaxConcurrency',
            'ThreadPool',
            'Runspace',
            'BeginInvoke',
            'WaitHandle'
        )

        foreach ($pattern in $parallelPatterns) {
            if ($content -match $pattern) {
                return $true
            }
        }

        return $false
    } catch {
        # Utiliser le mock pour les chemins de test
        if ($ScriptPath -like "*Test1.ps1" -or $ScriptPath -like "*Test3.ps1") {
            return $true
        }
        return $false
    }
}

# Fonction pour analyser un goulot d'Ã©tranglement parallÃ¨le
function Get-ParallelBottleneckAnalysis {
    param (
        [string]$ScriptPath,
        [PSCustomObject]$Bottleneck
    )

    # Simuler l'analyse d'un goulot d'Ã©tranglement
    if ($Bottleneck.SlowExecutions.Count -gt 0 -and
        $Bottleneck.SlowExecutions[0].ResourceUsage.CpuUsageEnd -gt 90) {
        return @{
            ParallelizationType = "ForEach-Object -Parallel (PowerShell 7+)"
            ProbableCause       = "Saturation du CPU"
            Recommendation      = "RÃ©duire le nombre de threads parallÃ¨les"
        }
    }

    if ($Bottleneck.SlowExecutions.Count -gt 0 -and
        $Bottleneck.SlowExecutions[0].Parameters -and
        $Bottleneck.SlowExecutions[0].Parameters.InputData -and
        $Bottleneck.SlowExecutions[0].Parameters.InputData.Count -gt 1000) {
        return @{
            ParallelizationType = "ForEach-Object -Parallel (PowerShell 7+)"
            ProbableCause       = "Traitement de grands volumes de donnÃ©es"
            Recommendation      = "Optimiser la taille des lots (batch size)"
        }
    }

    return @{
        ParallelizationType = "ForEach-Object -Parallel (PowerShell 7+)"
        ProbableCause       = "IndÃ©terminÃ©"
        Recommendation      = "Analyse manuelle requise"
    }
}

# Fonction pour gÃ©nÃ©rer un rapport de goulots d'Ã©tranglement
function New-BottleneckReport {
    param (
        [array]$Bottlenecks,
        [string]$OutputPath
    )

    # CrÃ©er le dossier de rapport s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # GÃ©nÃ©rer le nom du fichier de rapport
    $reportFile = Join-Path -Path $OutputPath -ChildPath "bottleneck_report_$(Get-Date -Format 'yyyy-MM-dd').html"

    # GÃ©nÃ©rer le contenu HTML du rapport
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Goulots d'Ã‰tranglement</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 20px; }
        h1, h2, h3 { color: #2c3e50; }
        .container { max-width: 1200px; margin: 0 auto; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f8f9fa; }
        tr:hover { background-color: #f1f1f1; }
        .parallel { background-color: #d1ecf1; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de Goulots d'Ã‰tranglement</h1>
        <p>Rapport gÃ©nÃ©rÃ© le $(Get-Date -Format "dd/MM/yyyy Ã  HH:mm:ss")</p>
"@

    if ($Bottlenecks.Count -gt 0) {
        $htmlContent += @"
        <h2>Goulots d'Ã‰tranglement DÃ©tectÃ©s</h2>
        <table>
            <tr>
                <th>Script</th>
                <th>DurÃ©e Moyenne (ms)</th>
                <th>Seuil de Lenteur (ms)</th>
                <th>ExÃ©cutions Lentes</th>
                <th>Total ExÃ©cutions</th>
                <th>% ExÃ©cutions Lentes</th>
                <th>ParallÃ©lisation</th>
            </tr>
"@

        foreach ($bottleneck in $Bottlenecks) {
            $parallelClass = if ($bottleneck.IsParallel) { "parallel" } else { "" }
            $htmlContent += @"
            <tr class="$parallelClass">
                <td>$($bottleneck.ScriptName)</td>
                <td>$($bottleneck.AverageDuration)</td>
                <td>$($bottleneck.SlowThreshold)</td>
                <td>$($bottleneck.SlowExecutionsCount)</td>
                <td>$($bottleneck.TotalExecutionsCount)</td>
                <td>$($bottleneck.SlowExecutionPercentage)%</td>
                <td>$($bottleneck.IsParallel)</td>
            </tr>
"@
        }

        $htmlContent += @"
        </table>
"@

        # Ajouter les dÃ©tails pour les scripts parallÃ¨les
        $parallelBottlenecks = $Bottlenecks | Where-Object { $_.IsParallel -and $_.DetailedAnalysis }
        if ($parallelBottlenecks.Count -gt 0) {
            $htmlContent += @"
        <h2>DÃ©tails des Goulots d'Ã‰tranglement ParallÃ¨les</h2>
"@

            foreach ($bottleneck in $parallelBottlenecks) {
                $htmlContent += @"
        <h3>$($bottleneck.ScriptName)</h3>
        <ul>
            <li><strong>Type de ParallÃ©lisation:</strong> $($bottleneck.DetailedAnalysis.ParallelizationType)</li>
            <li><strong>Cause Probable:</strong> $($bottleneck.DetailedAnalysis.ProbableCause)</li>
            <li><strong>Recommandation:</strong> $($bottleneck.DetailedAnalysis.Recommendation)</li>
        </ul>
"@
            }
        }
    } else {
        $htmlContent += @"
        <div class="success-message">
            <h2>Aucun Goulot d'Ã‰tranglement DÃ©tectÃ©</h2>
            <p>Aucun goulot d'Ã©tranglement n'a Ã©tÃ© dÃ©tectÃ© dans les scripts analysÃ©s.</p>
        </div>
"@
    }

    $htmlContent += @"
    </div>
</body>
</html>
"@

    # Ã‰crire le contenu dans le fichier
    $htmlContent | Out-File -FilePath $reportFile -Encoding UTF8

    return $reportFile
}

# Fonction pour trouver les goulots d'Ã©tranglement dans les processus parallÃ¨les
function Find-ParallelProcessBottlenecks {
    param (
        [switch]$DetailedAnalysis
    )

    # Simuler la dÃ©tection de goulots d'Ã©tranglement
    $bottlenecks = @(
        [PSCustomObject]@{
            ScriptPath              = "C:\Scripts\Test1.ps1"
            ScriptName              = "Test1.ps1"
            AverageDuration         = 1000
            SlowThreshold           = 1500
            SlowExecutionsCount     = 5
            TotalExecutionsCount    = 10
            SlowExecutionPercentage = 50
            IsParallel              = $true
            SlowExecutions          = @(
                [PSCustomObject]@{
                    StartTime     = (Get-Date).AddHours(-1)
                    Duration      = [timespan]::FromMilliseconds(2000)
                    Success       = $true
                    Parameters    = @{ Param1 = "Value1" }
                    ResourceUsage = @{
                        CpuUsageStart    = 10
                        CpuUsageEnd      = 60
                        MemoryUsageStart = 100MB
                        MemoryUsageEnd   = 200MB
                    }
                }
            )
        }
    )

    if ($DetailedAnalysis) {
        foreach ($bottleneck in $bottlenecks) {
            $bottleneck | Add-Member -MemberType NoteProperty -Name "DetailedAnalysis" -Value @{
                ParallelizationType = "ForEach-Object -Parallel (PowerShell 7+)"
                ProbableCause       = "Saturation du CPU"
                Recommendation      = "RÃ©duire le nombre de threads parallÃ¨les"
            }
        }
    }

    return $bottlenecks
}
