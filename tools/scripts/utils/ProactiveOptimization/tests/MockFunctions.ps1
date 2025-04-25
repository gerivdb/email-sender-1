<#
.SYNOPSIS
    Fonctions mock pour les tests unitaires.
.DESCRIPTION
    Ce script contient des fonctions mock pour les tests unitaires.
#>

# Fonction pour vérifier si un script utilise la parallélisation
function Test-ScriptUsesParallelization {
    param (
        [string]$ScriptPath
    )

    # Vérifier si le chemin existe
    if (-not (Test-Path -Path $ScriptPath)) {
        # Utiliser le mock pour les chemins de test
        if ($ScriptPath -like "*Test1.ps1" -or $ScriptPath -like "*Test3.ps1") {
            return $true
        }
        return $false
    }

    try {
        $content = Get-Content -Path $ScriptPath -Raw -ErrorAction Stop

        # Vérifier les patterns de parallélisation courants
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

# Fonction pour analyser un goulot d'étranglement parallèle
function Get-ParallelBottleneckAnalysis {
    param (
        [string]$ScriptPath,
        [PSCustomObject]$Bottleneck
    )

    # Simuler l'analyse d'un goulot d'étranglement
    if ($Bottleneck.SlowExecutions.Count -gt 0 -and
        $Bottleneck.SlowExecutions[0].ResourceUsage.CpuUsageEnd -gt 90) {
        return @{
            ParallelizationType = "ForEach-Object -Parallel (PowerShell 7+)"
            ProbableCause       = "Saturation du CPU"
            Recommendation      = "Réduire le nombre de threads parallèles"
        }
    }

    if ($Bottleneck.SlowExecutions.Count -gt 0 -and
        $Bottleneck.SlowExecutions[0].Parameters -and
        $Bottleneck.SlowExecutions[0].Parameters.InputData -and
        $Bottleneck.SlowExecutions[0].Parameters.InputData.Count -gt 1000) {
        return @{
            ParallelizationType = "ForEach-Object -Parallel (PowerShell 7+)"
            ProbableCause       = "Traitement de grands volumes de données"
            Recommendation      = "Optimiser la taille des lots (batch size)"
        }
    }

    return @{
        ParallelizationType = "ForEach-Object -Parallel (PowerShell 7+)"
        ProbableCause       = "Indéterminé"
        Recommendation      = "Analyse manuelle requise"
    }
}

# Fonction pour générer un rapport de goulots d'étranglement
function New-BottleneckReport {
    param (
        [array]$Bottlenecks,
        [string]$OutputPath
    )

    # Créer le dossier de rapport s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Générer le nom du fichier de rapport
    $reportFile = Join-Path -Path $OutputPath -ChildPath "bottleneck_report_$(Get-Date -Format 'yyyy-MM-dd').html"

    # Générer le contenu HTML du rapport
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Goulots d'Étranglement</title>
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
        <h1>Rapport de Goulots d'Étranglement</h1>
        <p>Rapport généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm:ss")</p>
"@

    if ($Bottlenecks.Count -gt 0) {
        $htmlContent += @"
        <h2>Goulots d'Étranglement Détectés</h2>
        <table>
            <tr>
                <th>Script</th>
                <th>Durée Moyenne (ms)</th>
                <th>Seuil de Lenteur (ms)</th>
                <th>Exécutions Lentes</th>
                <th>Total Exécutions</th>
                <th>% Exécutions Lentes</th>
                <th>Parallélisation</th>
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

        # Ajouter les détails pour les scripts parallèles
        $parallelBottlenecks = $Bottlenecks | Where-Object { $_.IsParallel -and $_.DetailedAnalysis }
        if ($parallelBottlenecks.Count -gt 0) {
            $htmlContent += @"
        <h2>Détails des Goulots d'Étranglement Parallèles</h2>
"@

            foreach ($bottleneck in $parallelBottlenecks) {
                $htmlContent += @"
        <h3>$($bottleneck.ScriptName)</h3>
        <ul>
            <li><strong>Type de Parallélisation:</strong> $($bottleneck.DetailedAnalysis.ParallelizationType)</li>
            <li><strong>Cause Probable:</strong> $($bottleneck.DetailedAnalysis.ProbableCause)</li>
            <li><strong>Recommandation:</strong> $($bottleneck.DetailedAnalysis.Recommendation)</li>
        </ul>
"@
            }
        }
    } else {
        $htmlContent += @"
        <div class="success-message">
            <h2>Aucun Goulot d'Étranglement Détecté</h2>
            <p>Aucun goulot d'étranglement n'a été détecté dans les scripts analysés.</p>
        </div>
"@
    }

    $htmlContent += @"
    </div>
</body>
</html>
"@

    # Écrire le contenu dans le fichier
    $htmlContent | Out-File -FilePath $reportFile -Encoding UTF8

    return $reportFile
}

# Fonction pour trouver les goulots d'étranglement dans les processus parallèles
function Find-ParallelProcessBottlenecks {
    param (
        [switch]$DetailedAnalysis
    )

    # Simuler la détection de goulots d'étranglement
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
                Recommendation      = "Réduire le nombre de threads parallèles"
            }
        }
    }

    return $bottlenecks
}
