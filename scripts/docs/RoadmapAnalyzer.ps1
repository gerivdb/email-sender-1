# Script d'analyse de la roadmap
# Ce script analyse la roadmap et génère des rapports sur l'avancement

param (
    [string]$RoadmapPath = "roadmap_perso.md",
    [string]$OutputFolder = "Roadmap\Reports",
    [switch]$GenerateHtml = $true,
    [switch]$GenerateJson = $true,
    [switch]$GenerateChart = $true
)

# Configuration
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$htmlReportPath = "$OutputFolder\roadmap_report_$timestamp.html"
$jsonReportPath = "$OutputFolder\roadmap_report_$timestamp.json"
$chartPath = "$OutputFolder\roadmap_chart_$timestamp.html"

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    Write-Host "Dossier '$OutputFolder' créé." -ForegroundColor Green
}

# Fonction pour analyser la roadmap
function Parse-Roadmap {
    param (
        [string]$Path
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        Write-Host "Le fichier roadmap n'existe pas: $Path" -ForegroundColor Red
        return $null
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $Path -Raw
    
    # Structure pour stocker les données de la roadmap
    $roadmap = @{
        Title = ""
        LastUpdated = (Get-Item -Path $Path).LastWriteTime
        Sections = @()
    }
    
    # Extraire le titre
    if ($content -match "^# (.+)$") {
        $roadmap.Title = $Matches[1]
    }
    
    # Analyser les sections, phases et tâches
    $lines = $content -split "`n"
    $currentSection = $null
    $currentPhase = $null
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Détecter une section
        if ($line -match "^## (\d+)\. (.+)$") {
            $sectionId = $Matches[1]
            $sectionTitle = $Matches[2]
            
            $currentSection = @{
                Id = $sectionId
                Title = $sectionTitle
                LineNumber = $i
                Phases = @()
                Metadata = @{}
                TotalTasks = 0
                CompletedTasks = 0
                Progress = 0
            }
            
            $roadmap.Sections += $currentSection
            $currentPhase = $null
            
            # Extraire les métadonnées de la section
            $j = $i + 1
            while ($j -lt $lines.Count -and -not $lines[$j].StartsWith("- ")) {
                if ($lines[$j] -match "\*\*(.+)\*\*: (.+)") {
                    $metaKey = $Matches[1]
                    $metaValue = $Matches[2]
                    $currentSection.Metadata[$metaKey] = $metaValue
                }
                $j++
            }
        }
        
        # Détecter une phase
        elseif ($line -match "^  - \[([ x])\] \*\*Phase (\d+): (.+)\*\*$" -and $currentSection -ne $null) {
            $isCompleted = $Matches[1] -eq "x"
            $phaseId = $Matches[2]
            $phaseTitle = $Matches[3]
            
            $currentPhase = @{
                Id = $phaseId
                Title = $phaseTitle
                LineNumber = $i
                IsCompleted = $isCompleted
                Tasks = @()
                TotalTasks = 0
                CompletedTasks = 0
                Progress = 0
            }
            
            $currentSection.Phases += $currentPhase
        }
        
        # Détecter une tâche
        elseif ($line -match "^    - \[([ x])\] (.+)$" -and $currentPhase -ne $null) {
            $isCompleted = $Matches[1] -eq "x"
            $taskTitle = $Matches[2]
            
            $task = @{
                Title = $taskTitle
                LineNumber = $i
                IsCompleted = $isCompleted
                Subtasks = @()
                TotalSubtasks = 0
                CompletedSubtasks = 0
                Progress = 0
            }
            
            $currentPhase.Tasks += $task
            $currentPhase.TotalTasks++
            $currentSection.TotalTasks++
            
            if ($isCompleted) {
                $currentPhase.CompletedTasks++
                $currentSection.CompletedTasks++
            }
        }
        
        # Détecter une sous-tâche
        elseif ($line -match "^      - \[([ x])\] (.+)$" -and $currentPhase -ne $null -and $currentPhase.Tasks.Count -gt 0) {
            $isCompleted = $Matches[1] -eq "x"
            $subtaskTitle = $Matches[2]
            
            $subtask = @{
                Title = $subtaskTitle
                LineNumber = $i
                IsCompleted = $isCompleted
            }
            
            $currentPhase.Tasks[-1].Subtasks += $subtask
            $currentPhase.Tasks[-1].TotalSubtasks++
            
            if ($isCompleted) {
                $currentPhase.Tasks[-1].CompletedSubtasks++
            }
        }
    }
    
    # Calculer les pourcentages de progression
    foreach ($section in $roadmap.Sections) {
        if ($section.TotalTasks -gt 0) {
            $section.Progress = [math]::Round(($section.CompletedTasks / $section.TotalTasks) * 100, 2)
        }
        
        foreach ($phase in $section.Phases) {
            if ($phase.TotalTasks -gt 0) {
                $phase.Progress = [math]::Round(($phase.CompletedTasks / $phase.TotalTasks) * 100, 2)
            }
            
            foreach ($task in $phase.Tasks) {
                if ($task.TotalSubtasks -gt 0) {
                    $task.Progress = [math]::Round(($task.CompletedSubtasks / $task.TotalSubtasks) * 100, 2)
                }
                else {
                    $task.Progress = $task.IsCompleted ? 100 : 0
                }
            }
        }
    }
    
    return $roadmap
}

# Fonction pour générer un rapport HTML
function Generate-HtmlReport {
    param (
        [hashtable]$Roadmap
    )
    
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de la Roadmap - $($Roadmap.Title)</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2, h3, h4 {
            color: #0066cc;
        }
        .section {
            margin-bottom: 30px;
            border-left: 4px solid #0066cc;
            padding-left: 15px;
        }
        .phase {
            margin-bottom: 20px;
            border-left: 3px solid #16a085;
            padding-left: 15px;
            margin-left: 20px;
        }
        .task {
            margin-bottom: 10px;
            margin-left: 40px;
        }
        .subtask {
            margin-left: 60px;
            color: #666;
        }
        .metadata {
            background-color: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 15px;
        }
        .progress-container {
            width: 100%;
            background-color: #f3f3f3;
            border-radius: 5px;
            margin: 10px 0;
        }
        .progress-bar {
            height: 20px;
            background-color: #4CAF50;
            border-radius: 5px;
            text-align: center;
            line-height: 20px;
            color: white;
            font-size: 12px;
        }
        .completed {
            color: #27ae60;
        }
        .pending {
            color: #e74c3c;
        }
        .summary {
            background-color: #e8f4fc;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 30px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        .timestamp {
            font-style: italic;
            color: #666;
            margin-top: 5px;
        }
    </style>
</head>
<body>
    <h1>Rapport de la Roadmap - $($Roadmap.Title)</h1>
    <p class="timestamp">Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm:ss") | Dernière mise à jour de la roadmap : $($Roadmap.LastUpdated.ToString("dd/MM/yyyy à HH:mm:ss"))</p>
    
    <div class="summary">
        <h2>Résumé</h2>
"@
    
    # Calculer les statistiques globales
    $totalSections = $Roadmap.Sections.Count
    $totalPhases = ($Roadmap.Sections | ForEach-Object { $_.Phases.Count } | Measure-Object -Sum).Sum
    $totalTasks = ($Roadmap.Sections | ForEach-Object { $_.TotalTasks } | Measure-Object -Sum).Sum
    $completedTasks = ($Roadmap.Sections | ForEach-Object { $_.CompletedTasks } | Measure-Object -Sum).Sum
    $globalProgress = if ($totalTasks -gt 0) { [math]::Round(($completedTasks / $totalTasks) * 100, 2) } else { 0 }
    
    $html += @"
        <div class="progress-container">
            <div class="progress-bar" style="width: $globalProgress%">$globalProgress%</div>
        </div>
        
        <table>
            <tr>
                <th>Métrique</th>
                <th>Valeur</th>
            </tr>
            <tr>
                <td>Sections</td>
                <td>$totalSections</td>
            </tr>
            <tr>
                <td>Phases</td>
                <td>$totalPhases</td>
            </tr>
            <tr>
                <td>Tâches</td>
                <td>$completedTasks / $totalTasks ($globalProgress%)</td>
            </tr>
        </table>
    </div>
    
    <h2>Détails par section</h2>
"@
    
    foreach ($section in $Roadmap.Sections) {
        $html += @"
    <div class="section">
        <h3>$($section.Id). $($section.Title)</h3>
        
        <div class="progress-container">
            <div class="progress-bar" style="width: $($section.Progress)%">$($section.Progress)%</div>
        </div>
        
        <div class="metadata">
"@
        
        foreach ($key in $section.Metadata.Keys) {
            $html += @"
            <p><strong>$key:</strong> $($section.Metadata[$key])</p>
"@
        }
        
        $html += @"
        </div>
        
"@
        
        foreach ($phase in $section.Phases) {
            $phaseStatus = if ($phase.IsCompleted) { "completed" } else { "pending" }
            $html += @"
        <div class="phase">
            <h4 class="$phaseStatus">Phase $($phase.Id): $($phase.Title) ($($phase.Progress)%)</h4>
            
            <div class="progress-container">
                <div class="progress-bar" style="width: $($phase.Progress)%">$($phase.Progress)%</div>
            </div>
            
"@
            
            foreach ($task in $phase.Tasks) {
                $taskStatus = if ($task.IsCompleted) { "completed" } else { "pending" }
                $html += @"
            <div class="task">
                <p class="$taskStatus">$($task.Title) ($($task.Progress)%)</p>
                
"@
                
                if ($task.TotalSubtasks -gt 0) {
                    $html += @"
                <div class="progress-container">
                    <div class="progress-bar" style="width: $($task.Progress)%">$($task.Progress)%</div>
                </div>
                
"@
                    
                    foreach ($subtask in $task.Subtasks) {
                        $subtaskStatus = if ($subtask.IsCompleted) { "completed" } else { "pending" }
                        $html += @"
                <div class="subtask">
                    <p class="$subtaskStatus">$($subtask.Title)</p>
                </div>
"@
                    }
                }
                
                $html += @"
            </div>
"@
            }
            
            $html += @"
        </div>
"@
        }
        
        $html += @"
    </div>
"@
    }
    
    $html += @"
</body>
</html>
"@
    
    return $html
}

# Fonction pour générer un graphique de progression
function Generate-ProgressChart {
    param (
        [hashtable]$Roadmap
    )
    
    $chartData = @()
    
    foreach ($section in $Roadmap.Sections) {
        $chartData += @{
            name = "$($section.Id). $($section.Title)"
            progress = $section.Progress
            phases = @()
        }
        
        foreach ($phase in $section.Phases) {
            $chartData[-1].phases += @{
                name = "Phase $($phase.Id): $($phase.Title)"
                progress = $phase.Progress
                tasks = @()
            }
            
            foreach ($task in $phase.Tasks) {
                $chartData[-1].phases[-1].tasks += @{
                    name = $task.Title
                    progress = $task.Progress
                }
            }
        }
    }
    
    $chartDataJson = $chartData | ConvertTo-Json -Depth 10
    
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Graphique de progression - $($Roadmap.Title)</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2 {
            color: #0066cc;
        }
        .chart-container {
            position: relative;
            height: 400px;
            margin: 20px 0;
        }
        .timestamp {
            font-style: italic;
            color: #666;
            margin-top: 5px;
        }
        .tabs {
            display: flex;
            margin-bottom: 20px;
        }
        .tab {
            padding: 10px 20px;
            background-color: #f2f2f2;
            border: 1px solid #ddd;
            cursor: pointer;
            margin-right: 5px;
        }
        .tab.active {
            background-color: #0066cc;
            color: white;
            border-color: #0066cc;
        }
        .tab-content {
            display: none;
        }
        .tab-content.active {
            display: block;
        }
    </style>
</head>
<body>
    <h1>Graphique de progression - $($Roadmap.Title)</h1>
    <p class="timestamp">Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm:ss") | Dernière mise à jour de la roadmap : $($Roadmap.LastUpdated.ToString("dd/MM/yyyy à HH:mm:ss"))</p>
    
    <div class="tabs">
        <div class="tab active" onclick="showTab('overview')">Vue d'ensemble</div>
        <div class="tab" onclick="showTab('sections')">Sections</div>
        <div class="tab" onclick="showTab('phases')">Phases</div>
        <div class="tab" onclick="showTab('tasks')">Tâches</div>
    </div>
    
    <div id="overview" class="tab-content active">
        <h2>Vue d'ensemble</h2>
        <div class="chart-container">
            <canvas id="overviewChart"></canvas>
        </div>
    </div>
    
    <div id="sections" class="tab-content">
        <h2>Progression par section</h2>
        <div class="chart-container">
            <canvas id="sectionsChart"></canvas>
        </div>
    </div>
    
    <div id="phases" class="tab-content">
        <h2>Progression par phase</h2>
        <div class="chart-container">
            <canvas id="phasesChart"></canvas>
        </div>
    </div>
    
    <div id="tasks" class="tab-content">
        <h2>Progression par tâche</h2>
        <div class="chart-container">
            <canvas id="tasksChart"></canvas>
        </div>
    </div>
    
    <script>
        // Données du graphique
        const chartData = $chartDataJson;
        
        // Fonction pour afficher un onglet
        function showTab(tabId) {
            // Masquer tous les onglets
            document.querySelectorAll('.tab-content').forEach(tab => {
                tab.classList.remove('active');
            });
            
            // Désactiver tous les boutons d'onglet
            document.querySelectorAll('.tab').forEach(tab => {
                tab.classList.remove('active');
            });
            
            // Afficher l'onglet sélectionné
            document.getElementById(tabId).classList.add('active');
            
            // Activer le bouton d'onglet sélectionné
            document.querySelector(`.tab[onclick="showTab('${tabId}')"]`).classList.add('active');
        }
        
        // Créer le graphique de vue d'ensemble
        const overviewCtx = document.getElementById('overviewChart').getContext('2d');
        const overviewChart = new Chart(overviewCtx, {
            type: 'doughnut',
            data: {
                labels: ['Terminé', 'En cours'],
                datasets: [{
                    data: [$completedTasks, $totalTasks - $completedTasks],
                    backgroundColor: ['#27ae60', '#e74c3c']
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    title: {
                        display: true,
                        text: 'Progression globale: $globalProgress%'
                    },
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });
        
        // Créer le graphique des sections
        const sectionsCtx = document.getElementById('sectionsChart').getContext('2d');
        const sectionsChart = new Chart(sectionsCtx, {
            type: 'bar',
            data: {
                labels: chartData.map(section => section.name),
                datasets: [{
                    label: 'Progression (%)',
                    data: chartData.map(section => section.progress),
                    backgroundColor: '#0066cc'
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
                }
            }
        });
        
        // Créer le graphique des phases
        const phasesCtx = document.getElementById('phasesChart').getContext('2d');
        const phasesData = [];
        const phasesLabels = [];
        
        chartData.forEach(section => {
            section.phases.forEach(phase => {
                phasesLabels.push(`${section.name} - ${phase.name}`);
                phasesData.push(phase.progress);
            });
        });
        
        const phasesChart = new Chart(phasesCtx, {
            type: 'bar',
            data: {
                labels: phasesLabels,
                datasets: [{
                    label: 'Progression (%)',
                    data: phasesData,
                    backgroundColor: '#16a085'
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
                }
            }
        });
        
        // Créer le graphique des tâches
        const tasksCtx = document.getElementById('tasksChart').getContext('2d');
        const tasksData = [];
        const tasksLabels = [];
        
        chartData.forEach(section => {
            section.phases.forEach(phase => {
                phase.tasks.forEach(task => {
                    tasksLabels.push(`${phase.name} - ${task.name}`);
                    tasksData.push(task.progress);
                });
            });
        });
        
        const tasksChart = new Chart(tasksCtx, {
            type: 'bar',
            data: {
                labels: tasksLabels,
                datasets: [{
                    label: 'Progression (%)',
                    data: tasksData,
                    backgroundColor: '#e67e22'
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
                }
            }
        });
    </script>
</body>
</html>
"@
    
    return $html
}

# Analyser la roadmap
Write-Host "Analyse de la roadmap: $RoadmapPath" -ForegroundColor Cyan
$roadmap = Parse-Roadmap -Path $RoadmapPath

if ($roadmap -eq $null) {
    Write-Host "Impossible d'analyser la roadmap." -ForegroundColor Red
    exit 1
}

# Afficher les informations sur la roadmap
Write-Host "Roadmap: $($roadmap.Title)" -ForegroundColor Green
Write-Host "Sections: $($roadmap.Sections.Count)" -ForegroundColor Green

# Calculer les statistiques globales
$totalSections = $roadmap.Sections.Count
$totalPhases = ($roadmap.Sections | ForEach-Object { $_.Phases.Count } | Measure-Object -Sum).Sum
$totalTasks = ($roadmap.Sections | ForEach-Object { $_.TotalTasks } | Measure-Object -Sum).Sum
$completedTasks = ($roadmap.Sections | ForEach-Object { $_.CompletedTasks } | Measure-Object -Sum).Sum
$globalProgress = if ($totalTasks -gt 0) { [math]::Round(($completedTasks / $totalTasks) * 100, 2) } else { 0 }

Write-Host "Phases: $totalPhases" -ForegroundColor Green
Write-Host "Tâches: $completedTasks / $totalTasks ($globalProgress%)" -ForegroundColor Green

# Générer le rapport HTML
if ($GenerateHtml) {
    Write-Host "Génération du rapport HTML..." -ForegroundColor Cyan
    $htmlReport = Generate-HtmlReport -Roadmap $roadmap
    Set-Content -Path $htmlReportPath -Value $htmlReport -Encoding UTF8
    Write-Host "Rapport HTML généré: $htmlReportPath" -ForegroundColor Green
}

# Générer le rapport JSON
if ($GenerateJson) {
    Write-Host "Génération du rapport JSON..." -ForegroundColor Cyan
    $jsonReport = $roadmap | ConvertTo-Json -Depth 10
    Set-Content -Path $jsonReportPath -Value $jsonReport -Encoding UTF8
    Write-Host "Rapport JSON généré: $jsonReportPath" -ForegroundColor Green
}

# Générer le graphique de progression
if ($GenerateChart) {
    Write-Host "Génération du graphique de progression..." -ForegroundColor Cyan
    $chart = Generate-ProgressChart -Roadmap $roadmap
    Set-Content -Path $chartPath -Value $chart -Encoding UTF8
    Write-Host "Graphique de progression généré: $chartPath" -ForegroundColor Green
}

# Ouvrir le rapport HTML
if ($GenerateHtml) {
    Start-Process $htmlReportPath
}

# Ouvrir le graphique de progression
if ($GenerateChart) {
    Start-Process $chartPath
}

Write-Host "Analyse de la roadmap terminée !" -ForegroundColor Green
