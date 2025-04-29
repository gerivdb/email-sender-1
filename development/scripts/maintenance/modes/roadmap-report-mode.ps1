<#
.SYNOPSIS
    Script pour gÃ©nÃ©rer des rapports sur l'Ã©tat des roadmaps (Mode ROADMAP-REPORT).

.DESCRIPTION
    Ce script permet de gÃ©nÃ©rer des rapports dÃ©taillÃ©s sur l'Ã©tat d'avancement des roadmaps.
    Il implÃ©mente le mode ROADMAP-REPORT qui est conÃ§u pour fournir des informations
    sur l'Ã©tat d'avancement des tÃ¢ches, les tendances, les prÃ©visions, etc.

.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap Ã  analyser.

.PARAMETER OutputPath
    Chemin vers le rÃ©pertoire de sortie pour les rapports. Si non spÃ©cifiÃ©, le script utilisera
    les valeurs de la configuration.

.PARAMETER ReportFormat
    Format des rapports Ã  gÃ©nÃ©rer. Valeurs possibles : "HTML", "JSON", "CSV", "Markdown", "All".
    Par dÃ©faut : "HTML".

.PARAMETER IncludeCharts
    Indique si les rapports doivent inclure des graphiques.
    Par dÃ©faut : $true.

.PARAMETER IncludeTrends
    Indique si les rapports doivent inclure des analyses de tendances.
    Par dÃ©faut : $true.

.PARAMETER IncludePredictions
    Indique si les rapports doivent inclure des prÃ©visions.
    Par dÃ©faut : $true.

.PARAMETER DaysToAnalyze
    Nombre de jours Ã  analyser pour les tendances et les prÃ©visions.
    Par dÃ©faut : 30.

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration unifiÃ©e.
    Par dÃ©faut : "development\config\unified-config.json".

.EXAMPLE
    .\roadmap-report-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -OutputPath "reports\roadmap"

.EXAMPLE
    .\roadmap-report-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "All" -IncludeCharts -IncludeTrends -IncludePredictions

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("HTML", "JSON", "CSV", "Markdown", "All")]
    [string]$ReportFormat = "HTML",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeCharts = $true,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeTrends = $true,

    [Parameter(Mandatory = $false)]
    [switch]$IncludePredictions = $true,

    [Parameter(Mandatory = $false)]
    [int]$DaysToAnalyze = 30,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "development\config\unified-config.json"
)

# DÃ©terminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and 
       -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de dÃ©terminer le chemin du projet."
        exit 1
    }
}

# Charger la configuration unifiÃ©e
$configPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath
if (Test-Path -Path $configPath) {
    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement de la configuration : $_"
        exit 1
    }
} else {
    Write-Warning "Le fichier de configuration est introuvable : $configPath"
    Write-Warning "Tentative de recherche d'un fichier de configuration alternatif..."
    
    # Essayer de trouver un fichier de configuration alternatif
    $alternativePaths = @(
        "development\config\unified-config.json",
        "development\roadmap\parser\config\modes-config.json",
        "development\roadmap\parser\config\config.json"
    )
    
    foreach ($path in $alternativePaths) {
        $fullPath = Join-Path -Path $projectRoot -ChildPath $path
        if (Test-Path -Path $fullPath) {
            Write-Host "Fichier de configuration trouvÃ© Ã  l'emplacement : $fullPath" -ForegroundColor Green
            $configPath = $fullPath
            try {
                $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                break
            } catch {
                Write-Warning "Erreur lors du chargement de la configuration : $_"
            }
        }
    }
    
    if (-not $config) {
        Write-Error "Aucun fichier de configuration valide trouvÃ©."
        exit 1
    }
}

# Utiliser les valeurs de la configuration si les paramÃ¨tres ne sont pas spÃ©cifiÃ©s
if (-not $RoadmapPath) {
    if ($config.Roadmaps.Main.Path) {
        $RoadmapPath = Join-Path -Path $projectRoot -ChildPath $config.Roadmaps.Main.Path
    } elseif ($config.General.RoadmapPath) {
        $RoadmapPath = Join-Path -Path $projectRoot -ChildPath $config.General.RoadmapPath
    } else {
        Write-Error "Aucun chemin de roadmap spÃ©cifiÃ© et aucun chemin par dÃ©faut trouvÃ© dans la configuration."
        exit 1
    }
}

if (-not $OutputPath) {
    if ($config.Roadmaps.Main.ReportPath) {
        $OutputPath = Join-Path -Path $projectRoot -ChildPath $config.Roadmaps.Main.ReportPath
    } elseif ($config.roadmap-manager.ReportsFolder) {
        $OutputPath = Join-Path -Path $projectRoot -ChildPath $config.roadmap-manager.ReportsFolder
    } elseif ($config.General.ReportPath) {
        $OutputPath = Join-Path -Path $projectRoot -ChildPath $config.General.ReportPath
    } else {
        $OutputPath = Join-Path -Path $projectRoot -ChildPath "reports\roadmap"
    }
}

# Convertir les chemins relatifs en chemins absolus
if (-not [System.IO.Path]::IsPathRooted($RoadmapPath)) {
    $RoadmapPath = Join-Path -Path $projectRoot -ChildPath $RoadmapPath
}

if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path -Path $projectRoot -ChildPath $OutputPath
}

# VÃ©rifier que le fichier de roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier de roadmap spÃ©cifiÃ© n'existe pas : $RoadmapPath"
    exit 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Importer le module RoadmapParser
$modulePath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\RoadmapParser.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Le module RoadmapParser est introuvable : $modulePath"
    exit 1
}

# Afficher les paramÃ¨tres
Write-Host "Mode ROADMAP-REPORT - GÃ©nÃ©ration de rapports sur l'Ã©tat des roadmaps" -ForegroundColor Cyan
Write-Host "Fichier de roadmap : $RoadmapPath" -ForegroundColor Gray
Write-Host "RÃ©pertoire de sortie : $OutputPath" -ForegroundColor Gray
Write-Host "Format des rapports : $ReportFormat" -ForegroundColor Gray
Write-Host "Inclure des graphiques : $IncludeCharts" -ForegroundColor Gray
Write-Host "Inclure des analyses de tendances : $IncludeTrends" -ForegroundColor Gray
Write-Host "Inclure des prÃ©visions : $IncludePredictions" -ForegroundColor Gray
Write-Host "Nombre de jours Ã  analyser : $DaysToAnalyze" -ForegroundColor Gray
Write-Host ""

# Fonction pour analyser la roadmap
function Get-RoadmapAnalysis {
    param (
        [string]$RoadmapPath
    )
    
    # Lire le contenu du fichier de roadmap
    $roadmapContent = Get-Content -Path $RoadmapPath -Encoding UTF8 -Raw
    
    # Analyser le contenu pour extraire les tÃ¢ches
    $tasks = @()
    $lines = $roadmapContent -split "`n"
    $currentTask = $null
    $currentSubTasks = @()
    
    foreach ($line in $lines) {
        # DÃ©tecter les tÃ¢ches principales (lignes commenÃ§ant par "## ")
        if ($line -match "^## (.+)") {
            # Si une tÃ¢che est en cours de traitement, l'ajouter Ã  la liste
            if ($currentTask) {
                $currentTask.SubTasks = $currentSubTasks
                $tasks += $currentTask
                $currentSubTasks = @()
            }
            
            # CrÃ©er une nouvelle tÃ¢che
            $currentTask = @{
                Title = $matches[1].Trim()
                Id = ""
                Description = ""
                Status = "NotStarted"
                SubTasks = @()
            }
        }
        # DÃ©tecter les descriptions (lignes commenÃ§ant par "### Description")
        elseif ($line -match "^### Description" -and $currentTask) {
            $descriptionLines = @()
            $i = [array]::IndexOf($lines, $line) + 1
            
            while ($i -lt $lines.Length -and -not $lines[$i].StartsWith("###")) {
                $descriptionLines += $lines[$i]
                $i++
            }
            
            $currentTask.Description = ($descriptionLines -join "`n").Trim()
        }
        # DÃ©tecter les sous-tÃ¢ches (lignes commenÃ§ant par "- [ ]" ou "- [x]")
        elseif ($line -match "^- \[([ x])\] (?:\*\*([0-9.]+)\*\* )?(.+)" -and $currentTask) {
            $isChecked = $matches[1] -eq "x"
            $id = if ($matches[2]) { $matches[2] } else { "" }
            $title = $matches[3].Trim()
            
            $subTask = @{
                Title = $title
                Id = $id
                Status = if ($isChecked) { "Completed" } else { "NotStarted" }
            }
            
            $currentSubTasks += $subTask
        }
    }
    
    # Ajouter la derniÃ¨re tÃ¢che
    if ($currentTask) {
        $currentTask.SubTasks = $currentSubTasks
        $tasks += $currentTask
    }
    
    # Calculer les statistiques
    $totalTasks = 0
    $completedTasks = 0
    $taskGroups = @{}
    
    foreach ($task in $tasks) {
        $groupName = $task.Title
        $taskGroups[$groupName] = @{
            Total = 0
            Completed = 0
            Percentage = 0
        }
        
        foreach ($subTask in $task.SubTasks) {
            $totalTasks++
            $taskGroups[$groupName].Total++
            
            if ($subTask.Status -eq "Completed") {
                $completedTasks++
                $taskGroups[$groupName].Completed++
            }
        }
        
        if ($taskGroups[$groupName].Total -gt 0) {
            $taskGroups[$groupName].Percentage = [math]::Round(($taskGroups[$groupName].Completed / $taskGroups[$groupName].Total) * 100, 2)
        }
    }
    
    $completionPercentage = if ($totalTasks -gt 0) { [math]::Round(($completedTasks / $totalTasks) * 100, 2) } else { 0 }
    
    # CrÃ©er l'objet d'analyse
    $analysis = @{
        RoadmapPath = $RoadmapPath
        TotalTasks = $totalTasks
        CompletedTasks = $completedTasks
        CompletionPercentage = $completionPercentage
        TaskGroups = $taskGroups
        Tasks = $tasks
        AnalysisDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    }
    
    return $analysis
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-HtmlReport {
    param (
        [hashtable]$Analysis,
        [string]$OutputPath,
        [bool]$IncludeCharts,
        [bool]$IncludeTrends,
        [bool]$IncludePredictions
    )
    
    $reportPath = Join-Path -Path $OutputPath -ChildPath "roadmap-report.html"
    
    # CrÃ©er le contenu HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de Roadmap</title>
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
        h3 {
            color: #3498db;
            margin-top: 20px;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 20px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .progress-bar {
            background-color: #f1f1f1;
            border-radius: 5px;
            height: 20px;
            width: 100%;
            margin-bottom: 10px;
        }
        .progress {
            background-color: #4CAF50;
            border-radius: 5px;
            height: 20px;
            text-align: center;
            color: white;
            line-height: 20px;
        }
        .summary {
            background-color: #f8f9fa;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .chart-container {
            width: 100%;
            height: 400px;
            margin-bottom: 20px;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Rapport de Roadmap</h1>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p><strong>Fichier de roadmap :</strong> $($Analysis.RoadmapPath)</p>
        <p><strong>Date d'analyse :</strong> $($Analysis.AnalysisDate)</p>
        <p><strong>TÃ¢ches totales :</strong> $($Analysis.TotalTasks)</p>
        <p><strong>TÃ¢ches complÃ©tÃ©es :</strong> $($Analysis.CompletedTasks)</p>
        <p><strong>Pourcentage de complÃ©tion :</strong> $($Analysis.CompletionPercentage)%</p>
        
        <div class="progress-bar">
            <div class="progress" style="width: $($Analysis.CompletionPercentage)%">$($Analysis.CompletionPercentage)%</div>
        </div>
    </div>
    
    <h2>Progression par groupe de tÃ¢ches</h2>
    <table>
        <tr>
            <th>Groupe</th>
            <th>TÃ¢ches totales</th>
            <th>TÃ¢ches complÃ©tÃ©es</th>
            <th>Pourcentage</th>
            <th>Progression</th>
        </tr>
"@

    foreach ($group in $Analysis.TaskGroups.GetEnumerator()) {
        $html += @"
        <tr>
            <td>$($group.Key)</td>
            <td>$($group.Value.Total)</td>
            <td>$($group.Value.Completed)</td>
            <td>$($group.Value.Percentage)%</td>
            <td>
                <div class="progress-bar">
                    <div class="progress" style="width: $($group.Value.Percentage)%">$($group.Value.Percentage)%</div>
                </div>
            </td>
        </tr>
"@
    }

    $html += @"
    </table>
    
    <h2>DÃ©tails des tÃ¢ches</h2>
"@

    foreach ($task in $Analysis.Tasks) {
        $completedSubTasks = ($task.SubTasks | Where-Object { $_.Status -eq "Completed" }).Count
        $totalSubTasks = $task.SubTasks.Count
        $percentage = if ($totalSubTasks -gt 0) { [math]::Round(($completedSubTasks / $totalSubTasks) * 100, 2) } else { 0 }
        
        $html += @"
    <h3>$($task.Title)</h3>
    <p>$($task.Description)</p>
    <p><strong>Progression :</strong> $completedSubTasks / $totalSubTasks ($percentage%)</p>
    <div class="progress-bar">
        <div class="progress" style="width: $percentage%">$percentage%</div>
    </div>
    
    <table>
        <tr>
            <th>ID</th>
            <th>Titre</th>
            <th>Statut</th>
        </tr>
"@

        foreach ($subTask in $task.SubTasks) {
            $status = if ($subTask.Status -eq "Completed") { "ComplÃ©tÃ©" } else { "En cours" }
            $statusColor = if ($subTask.Status -eq "Completed") { "#4CAF50" } else { "#FFC107" }
            
            $html += @"
        <tr>
            <td>$($subTask.Id)</td>
            <td>$($subTask.Title)</td>
            <td style="color: $statusColor">$status</td>
        </tr>
"@
        }

        $html += @"
    </table>
"@
    }

    if ($IncludeCharts) {
        $html += @"
    <h2>Graphiques</h2>
    
    <h3>Progression globale</h3>
    <div class="chart-container">
        <canvas id="progressChart"></canvas>
    </div>
    
    <h3>Progression par groupe de tÃ¢ches</h3>
    <div class="chart-container">
        <canvas id="groupsChart"></canvas>
    </div>
    
    <script>
        // Graphique de progression globale
        var progressCtx = document.getElementById('progressChart').getContext('2d');
        var progressChart = new Chart(progressCtx, {
            type: 'pie',
            data: {
                labels: ['ComplÃ©tÃ©', 'En cours'],
                datasets: [{
                    data: [$($Analysis.CompletedTasks), $($Analysis.TotalTasks - $Analysis.CompletedTasks)],
                    backgroundColor: ['#4CAF50', '#FFC107']
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                title: {
                    display: true,
                    text: 'Progression globale'
                }
            }
        });
        
        // Graphique de progression par groupe de tÃ¢ches
        var groupsCtx = document.getElementById('groupsChart').getContext('2d');
        var groupsChart = new Chart(groupsCtx, {
            type: 'bar',
            data: {
                labels: [$(($Analysis.TaskGroups.GetEnumerator() | ForEach-Object { "'$($_.Key)'" }) -join ", ")],
                datasets: [{
                    label: 'Pourcentage de complÃ©tion',
                    data: [$(($Analysis.TaskGroups.GetEnumerator() | ForEach-Object { $_.Value.Percentage }) -join ", ")],
                    backgroundColor: '#3498db'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100
                    }
                },
                title: {
                    display: true,
                    text: 'Progression par groupe de tÃ¢ches'
                }
            }
        });
    </script>
"@
    }

    if ($IncludeTrends) {
        $html += @"
    <h2>Analyse des tendances</h2>
    <p>Cette section prÃ©sente une analyse des tendances basÃ©e sur les donnÃ©es historiques des $DaysToAnalyze derniers jours.</p>
    <p><em>Note : Cette fonctionnalitÃ© nÃ©cessite des donnÃ©es historiques qui ne sont pas disponibles dans cette version du rapport.</em></p>
"@
    }

    if ($IncludePredictions) {
        $html += @"
    <h2>PrÃ©visions</h2>
    <p>Cette section prÃ©sente des prÃ©visions basÃ©es sur les tendances actuelles.</p>
    <p><em>Note : Cette fonctionnalitÃ© nÃ©cessite des donnÃ©es historiques qui ne sont pas disponibles dans cette version du rapport.</em></p>
"@
    }

    $html += @"
</body>
</html>
"@

    # Enregistrer le rapport HTML
    Set-Content -Path $reportPath -Value $html -Encoding UTF8
    
    return $reportPath
}

# Fonction pour gÃ©nÃ©rer un rapport JSON
function New-JsonReport {
    param (
        [hashtable]$Analysis,
        [string]$OutputPath
    )
    
    $reportPath = Join-Path -Path $OutputPath -ChildPath "roadmap-report.json"
    
    # Convertir l'analyse en JSON
    $json = ConvertTo-Json -InputObject $Analysis -Depth 10
    
    # Enregistrer le rapport JSON
    Set-Content -Path $reportPath -Value $json -Encoding UTF8
    
    return $reportPath
}

# Fonction pour gÃ©nÃ©rer un rapport CSV
function New-CsvReport {
    param (
        [hashtable]$Analysis,
        [string]$OutputPath
    )
    
    $reportPath = Join-Path -Path $OutputPath -ChildPath "roadmap-report.csv"
    
    # CrÃ©er un tableau d'objets pour le CSV
    $csvData = @()
    
    foreach ($task in $Analysis.Tasks) {
        foreach ($subTask in $task.SubTasks) {
            $csvData += [PSCustomObject]@{
                TaskGroup = $task.Title
                TaskDescription = $task.Description
                SubTaskId = $subTask.Id
                SubTaskTitle = $subTask.Title
                Status = $subTask.Status
                CompletionDate = if ($subTask.Status -eq "Completed") { Get-Date -Format "yyyy-MM-dd" } else { "" }
            }
        }
    }
    
    # Exporter vers CSV
    $csvData | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
    
    return $reportPath
}

# Fonction pour gÃ©nÃ©rer un rapport Markdown
function New-MarkdownReport {
    param (
        [hashtable]$Analysis,
        [string]$OutputPath
    )
    
    $reportPath = Join-Path -Path $OutputPath -ChildPath "roadmap-report.md"
    
    # CrÃ©er le contenu Markdown
    $markdown = "# Rapport de Roadmap`n`n"
    
    $markdown += "## RÃ©sumÃ©`n`n"
    $markdown += "- **Fichier de roadmap :** $($Analysis.RoadmapPath)`n"
    $markdown += "- **Date d'analyse :** $($Analysis.AnalysisDate)`n"
    $markdown += "- **TÃ¢ches totales :** $($Analysis.TotalTasks)`n"
    $markdown += "- **TÃ¢ches complÃ©tÃ©es :** $($Analysis.CompletedTasks)`n"
    $markdown += "- **Pourcentage de complÃ©tion :** $($Analysis.CompletionPercentage)%`n`n"
    
    $markdown += "## Progression par groupe de tÃ¢ches`n`n"
    $markdown += "| Groupe | TÃ¢ches totales | TÃ¢ches complÃ©tÃ©es | Pourcentage |`n"
    $markdown += "| ------ | ------------- | ----------------- | ----------- |`n"
    
    foreach ($group in $Analysis.TaskGroups.GetEnumerator()) {
        $markdown += "| $($group.Key) | $($group.Value.Total) | $($group.Value.Completed) | $($group.Value.Percentage)% |`n"
    }
    
    $markdown += "`n## DÃ©tails des tÃ¢ches`n`n"
    
    foreach ($task in $Analysis.Tasks) {
        $completedSubTasks = ($task.SubTasks | Where-Object { $_.Status -eq "Completed" }).Count
        $totalSubTasks = $task.SubTasks.Count
        $percentage = if ($totalSubTasks -gt 0) { [math]::Round(($completedSubTasks / $totalSubTasks) * 100, 2) } else { 0 }
        
        $markdown += "### $($task.Title)`n`n"
        $markdown += "$($task.Description)`n`n"
        $markdown += "**Progression :** $completedSubTasks / $totalSubTasks ($percentage%)`n`n"
        
        $markdown += "| ID | Titre | Statut |`n"
        $markdown += "| -- | ----- | ------ |`n"
        
        foreach ($subTask in $task.SubTasks) {
            $status = if ($subTask.Status -eq "Completed") { "ComplÃ©tÃ©" } else { "En cours" }
            $markdown += "| $($subTask.Id) | $($subTask.Title) | $status |`n"
        }
        
        $markdown += "`n"
    }
    
    # Enregistrer le rapport Markdown
    Set-Content -Path $reportPath -Value $markdown -Encoding UTF8
    
    return $reportPath
}

# Analyser la roadmap
$analysis = Get-RoadmapAnalysis -RoadmapPath $RoadmapPath

# GÃ©nÃ©rer les rapports en fonction du format spÃ©cifiÃ©
$generatedReports = @()

if ($ReportFormat -eq "HTML" -or $ReportFormat -eq "All") {
    $htmlReportPath = New-HtmlReport -Analysis $analysis -OutputPath $OutputPath -IncludeCharts $IncludeCharts -IncludeTrends $IncludeTrends -IncludePredictions $IncludePredictions
    $generatedReports += $htmlReportPath
    Write-Host "Rapport HTML gÃ©nÃ©rÃ© : $htmlReportPath" -ForegroundColor Green
}

if ($ReportFormat -eq "JSON" -or $ReportFormat -eq "All") {
    $jsonReportPath = New-JsonReport -Analysis $analysis -OutputPath $OutputPath
    $generatedReports += $jsonReportPath
    Write-Host "Rapport JSON gÃ©nÃ©rÃ© : $jsonReportPath" -ForegroundColor Green
}

if ($ReportFormat -eq "CSV" -or $ReportFormat -eq "All") {
    $csvReportPath = New-CsvReport -Analysis $analysis -OutputPath $OutputPath
    $generatedReports += $csvReportPath
    Write-Host "Rapport CSV gÃ©nÃ©rÃ© : $csvReportPath" -ForegroundColor Green
}

if ($ReportFormat -eq "Markdown" -or $ReportFormat -eq "All") {
    $markdownReportPath = New-MarkdownReport -Analysis $analysis -OutputPath $OutputPath
    $generatedReports += $markdownReportPath
    Write-Host "Rapport Markdown gÃ©nÃ©rÃ© : $markdownReportPath" -ForegroundColor Green
}

# Afficher un message de fin
Write-Host "`nExÃ©cution du mode ROADMAP-REPORT terminÃ©e." -ForegroundColor Cyan
Write-Host "Rapports gÃ©nÃ©rÃ©s : $($generatedReports.Count)" -ForegroundColor Cyan

# Retourner un rÃ©sultat
return @{
    RoadmapPath = $RoadmapPath
    OutputPath = $OutputPath
    ReportFormat = $ReportFormat
    GeneratedReports = $generatedReports
    Analysis = $analysis
}

