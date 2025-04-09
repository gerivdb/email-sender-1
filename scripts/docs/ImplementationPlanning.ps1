# Script pour la planification de l'implÃ©mentation

# Configuration
$PlanningConfig = @{
    # Dossier de stockage des documents de planification
    OutputFolder = Join-Path -Path $env:TEMP -ChildPath "ProjectPlanning"
    
    # Fichier des tÃ¢ches
    TasksFile = Join-Path -Path $env:TEMP -ChildPath "ProjectPlanning\tasks.json"
    
    # Fichier des ressources
    ResourcesFile = Join-Path -Path $env:TEMP -ChildPath "ProjectPlanning\resources.json"
    
    # Fichier du calendrier
    ScheduleFile = Join-Path -Path $env:TEMP -ChildPath "ProjectPlanning\schedule.json"
}

# Fonction pour initialiser la planification

# Script pour la planification de l'implÃ©mentation

# Configuration
$PlanningConfig = @{
    # Dossier de stockage des documents de planification
    OutputFolder = Join-Path -Path $env:TEMP -ChildPath "ProjectPlanning"
    
    # Fichier des tÃ¢ches
    TasksFile = Join-Path -Path $env:TEMP -ChildPath "ProjectPlanning\tasks.json"
    
    # Fichier des ressources
    ResourcesFile = Join-Path -Path $env:TEMP -ChildPath "ProjectPlanning\resources.json"
    
    # Fichier du calendrier
    ScheduleFile = Join-Path -Path $env:TEMP -ChildPath "ProjectPlanning\schedule.json"
}

# Fonction pour initialiser la planification
function Initialize-ImplementationPlanning {
    param (
        [string]$OutputFolder = "",
        [string]$TasksFile = "",
        [string]$ResourcesFile = "",
        [string]$ScheduleFile = ""
    )

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal

    
    # Mettre Ã  jour la configuration
    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $PlanningConfig.OutputFolder = $OutputFolder
    }
    
    if (-not [string]::IsNullOrEmpty($TasksFile)) {
        $PlanningConfig.TasksFile = $TasksFile
    }
    
    if (-not [string]::IsNullOrEmpty($ResourcesFile)) {
        $PlanningConfig.ResourcesFile = $ResourcesFile
    }
    
    if (-not [string]::IsNullOrEmpty($ScheduleFile)) {
        $PlanningConfig.ScheduleFile = $ScheduleFile
    }
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $PlanningConfig.OutputFolder)) {
        New-Item -Path $PlanningConfig.OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    # CrÃ©er les fichiers s'ils n'existent pas
    $files = @{
        $PlanningConfig.TasksFile = @{
            Tasks = @()
            LastUpdate = Get-Date -Format "o"
        }
        $PlanningConfig.ResourcesFile = @{
            Resources = @()
            LastUpdate = Get-Date -Format "o"
        }
        $PlanningConfig.ScheduleFile = @{
            Schedule = @{
                StartDate = Get-Date -Format "yyyy-MM-dd"
                EndDate = (Get-Date).AddMonths(3).ToString("yyyy-MM-dd")
                Milestones = @()
            }
            LastUpdate = Get-Date -Format "o"
        }
    }
    
    foreach ($file in $files.Keys) {
        if (-not (Test-Path -Path $file)) {
            $files[$file] | ConvertTo-Json -Depth 5 | Set-Content -Path $file
        }
    }
    
    return $PlanningConfig
}

# Fonction pour ajouter une tÃ¢che
function Add-ImplementationTask {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [int]$EstimatedHours = 0,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("High", "Medium", "Low")]
        [string]$Priority = "Medium",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Not Started", "In Progress", "Completed", "Blocked")]
        [string]$Status = "Not Started",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Dependencies = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$AssignedTo = @(),
        
        [Parameter(Mandatory = $false)]
        [string]$Component = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $PlanningConfig.TasksFile)) {
        Initialize-ImplementationPlanning
    }
    
    # Charger les tÃ¢ches existantes
    $tasksData = Get-Content -Path $PlanningConfig.TasksFile -Raw | ConvertFrom-Json
    
    # VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
    $existingTask = $tasksData.Tasks | Where-Object { $_.Name -eq $Name }
    
    if ($existingTask) {
        Write-Warning "Une tÃ¢che avec ce nom existe dÃ©jÃ ."
        return $null
    }
    
    # CrÃ©er la tÃ¢che
    $task = @{
        ID = [Guid]::NewGuid().ToString()
        Name = $Name
        Description = $Description
        EstimatedHours = $EstimatedHours
        Priority = $Priority
        Status = $Status
        Dependencies = $Dependencies
        AssignedTo = $AssignedTo
        Component = $Component
        Metadata = $Metadata
        CreatedAt = Get-Date -Format "o"
        UpdatedAt = Get-Date -Format "o"
        StartDate = $null
        EndDate = $null
        ActualHours = 0
    }
    
    # Ajouter la tÃ¢che
    $tasksData.Tasks += $task
    $tasksData.LastUpdate = Get-Date -Format "o"
    
    # Enregistrer les tÃ¢ches
    $tasksData | ConvertTo-Json -Depth 5 | Set-Content -Path $PlanningConfig.TasksFile
    
    return $task
}

# Fonction pour ajouter une ressource
function Add-ImplementationResource {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Developer", "Designer", "Tester", "Manager", "Other")]
        [string]$Role = "Developer",
        
        [Parameter(Mandatory = $false)]
        [int]$AvailableHoursPerWeek = 40,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Skills = @(),
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $PlanningConfig.ResourcesFile)) {
        Initialize-ImplementationPlanning
    }
    
    # Charger les ressources existantes
    $resourcesData = Get-Content -Path $PlanningConfig.ResourcesFile -Raw | ConvertFrom-Json
    
    # VÃ©rifier si la ressource existe dÃ©jÃ 
    $existingResource = $resourcesData.Resources | Where-Object { $_.Name -eq $Name }
    
    if ($existingResource) {
        Write-Warning "Une ressource avec ce nom existe dÃ©jÃ ."
        return $null
    }
    
    # CrÃ©er la ressource
    $resource = @{
        ID = [Guid]::NewGuid().ToString()
        Name = $Name
        Role = $Role
        AvailableHoursPerWeek = $AvailableHoursPerWeek
        Skills = $Skills
        Metadata = $Metadata
        CreatedAt = Get-Date -Format "o"
        UpdatedAt = Get-Date -Format "o"
    }
    
    # Ajouter la ressource
    $resourcesData.Resources += $resource
    $resourcesData.LastUpdate = Get-Date -Format "o"
    
    # Enregistrer les ressources
    $resourcesData | ConvertTo-Json -Depth 5 | Set-Content -Path $PlanningConfig.ResourcesFile
    
    return $resource
}

# Fonction pour ajouter un jalon
function Add-ImplementationMilestone {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $true)]
        [string]$Date,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Dependencies = @(),
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $PlanningConfig.ScheduleFile)) {
        Initialize-ImplementationPlanning
    }
    
    # Charger le calendrier
    $scheduleData = Get-Content -Path $PlanningConfig.ScheduleFile -Raw | ConvertFrom-Json
    
    # VÃ©rifier si le jalon existe dÃ©jÃ 
    $existingMilestone = $scheduleData.Schedule.Milestones | Where-Object { $_.Name -eq $Name }
    
    if ($existingMilestone) {
        Write-Warning "Un jalon avec ce nom existe dÃ©jÃ ."
        return $null
    }
    
    # CrÃ©er le jalon
    $milestone = @{
        ID = [Guid]::NewGuid().ToString()
        Name = $Name
        Description = $Description
        Date = $Date
        Dependencies = $Dependencies
        Metadata = $Metadata
        CreatedAt = Get-Date -Format "o"
        UpdatedAt = Get-Date -Format "o"
        Status = "Planned"
    }
    
    # Ajouter le jalon
    $scheduleData.Schedule.Milestones += $milestone
    $scheduleData.LastUpdate = Get-Date -Format "o"
    
    # Enregistrer le calendrier
    $scheduleData | ConvertTo-Json -Depth 5 | Set-Content -Path $PlanningConfig.ScheduleFile
    
    return $milestone
}

# Fonction pour planifier une tÃ¢che
function Set-TaskSchedule {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskID,
        
        [Parameter(Mandatory = $true)]
        [string]$StartDate,
        
        [Parameter(Mandatory = $true)]
        [string]$EndDate,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AssignedTo = @()
    )
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $PlanningConfig.TasksFile)) {
        Write-Error "Le fichier des tÃ¢ches n'existe pas."
        return $null
    }
    
    # Charger les tÃ¢ches
    $tasksData = Get-Content -Path $PlanningConfig.TasksFile -Raw | ConvertFrom-Json
    
    # Trouver la tÃ¢che
    $task = $tasksData.Tasks | Where-Object { $_.ID -eq $TaskID }
    
    if (-not $task) {
        Write-Error "La tÃ¢che avec l'ID '$TaskID' n'existe pas."
        return $null
    }
    
    # Mettre Ã  jour la tÃ¢che
    $task.StartDate = $StartDate
    $task.EndDate = $EndDate
    $task.UpdatedAt = Get-Date -Format "o"
    
    if ($AssignedTo.Count -gt 0) {
        $task.AssignedTo = $AssignedTo
    }
    
    # Enregistrer les tÃ¢ches
    $tasksData.LastUpdate = Get-Date -Format "o"
    $tasksData | ConvertTo-Json -Depth 5 | Set-Content -Path $PlanningConfig.TasksFile
    
    return $task
}

# Fonction pour gÃ©nÃ©rer un diagramme de Gantt
function New-GanttChart {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "Diagramme de Gantt",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeMilestones,
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenOutput
    )
    
    # Charger les donnÃ©es
    $tasksData = Get-Content -Path $PlanningConfig.TasksFile -Raw | ConvertFrom-Json
    $tasks = $tasksData.Tasks | Where-Object { $_.StartDate -and $_.EndDate }
    
    $milestones = @()
    if ($IncludeMilestones) {
        $scheduleData = Get-Content -Path $PlanningConfig.ScheduleFile -Raw | ConvertFrom-Json
        $milestones = $scheduleData.Schedule.Milestones
    }
    
    # DÃ©terminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "GanttChart-$timestamp.html"
        $OutputPath = Join-Path -Path $env:TEMP -ChildPath $fileName
    }
    
    # PrÃ©parer les donnÃ©es pour le diagramme
    $ganttTasks = @()
    
    foreach ($task in $tasks) {
        $color = switch ($task.Priority) {
            "High" { "#e74c3c" }
            "Medium" { "#3498db" }
            "Low" { "#2ecc71" }
            default { "#95a5a6" }
        }
        
        $ganttTasks += @{
            id = $task.ID
            name = $task.Name
            start = $task.StartDate
            end = $task.EndDate
            progress = if ($task.Status -eq "Completed") { 100 } elseif ($task.Status -eq "In Progress") { 50 } else { 0 }
            dependencies = $task.Dependencies
            custom_class = "task-" + $task.Priority.ToLower()
            color = $color
        }
    }
    
    foreach ($milestone in $milestones) {
        $ganttTasks += @{
            id = $milestone.ID
            name = $milestone.Name
            start = $milestone.Date
            end = $milestone.Date
            progress = if ($milestone.Status -eq "Completed") { 100 } else { 0 }
            dependencies = $milestone.Dependencies
            custom_class = "milestone"
            color = "#9b59b6"
        }
    }
    
    # GÃ©nÃ©rer le HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$Title</title>
    <script src="https://cdn.jsdelivr.net/npm/frappe-gantt@0.6.1/dist/frappe-gantt.min.js"></script>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/frappe-gantt@0.6.1/dist/frappe-gantt.min.css">
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        h1, h2, h3 {
            color: #2c3e50;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        
        .gantt-container {
            height: 500px;
            overflow-y: auto;
        }
        
        .task-high .bar {
            fill: #e74c3c !important;
        }
        
        .task-medium .bar {
            fill: #3498db !important;
        }
        
        .task-low .bar {
            fill: #2ecc71 !important;
        }
        
        .milestone .bar {
            fill: #9b59b6 !important;
        }
        
        .legend {
            display: flex;
            margin-top: 20px;
            flex-wrap: wrap;
        }
        
        .legend-item {
            display: flex;
            align-items: center;
            margin-right: 20px;
            margin-bottom: 10px;
        }
        
        .legend-color {
            width: 20px;
            height: 20px;
            margin-right: 5px;
        }
        
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 14px;
            color: #888;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$Title</h1>
            <div>
                <span>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
            </div>
        </div>
        
        <div class="gantt-container">
            <svg id="gantt"></svg>
        </div>
        
        <div class="legend">
            <div class="legend-item">
                <div class="legend-color" style="background-color: #e74c3c;"></div>
                <span>PrioritÃ© haute</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: #3498db;"></div>
                <span>PrioritÃ© moyenne</span>
            </div>
            <div class="legend-item">
                <div class="legend-color" style="background-color: #2ecc71;"></div>
                <span>PrioritÃ© basse</span>
            </div>
            $(if ($IncludeMilestones) {
                "<div class='legend-item'>
                    <div class='legend-color' style='background-color: #9b59b6;'></div>
                    <span>Jalon</span>
                </div>"
            })
        </div>
        
        <div class="footer">
            <p>Diagramme gÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
    </div>
    
    <script>
        // DonnÃ©es pour le diagramme
        const tasks = $(ConvertTo-Json -InputObject $ganttTasks -Depth 5);
        
        // CrÃ©er le diagramme de Gantt
        const gantt = new Gantt("#gantt", tasks, {
            header_height: 50,
            column_width: 30,
            step: 24,
            view_modes: ['Quarter Day', 'Half Day', 'Day', 'Week', 'Month'],
            bar_height: 20,
            bar_corner_radius: 3,
            arrow_curve: 5,
            padding: 18,
            view_mode: 'Week',
            date_format: 'YYYY-MM-DD',
            custom_popup_html: function(task) {
                return `
                    <div class="details-container">
                        <h5>${task.name}</h5>
                        <p>DÃ©but: ${task.start}</p>
                        <p>Fin: ${task.end}</p>
                        <p>Progression: ${task.progress}%</p>
                    </div>
                `;
            }
        });
    </script>
</body>
</html>
"@
    
    # Enregistrer le HTML
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    
    # Ouvrir le diagramme si demandÃ©
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Fonction pour gÃ©nÃ©rer un rapport de planification
function New-ImplementationPlanReport {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport de planification d'implÃ©mentation",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeResources,
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenOutput
    )
    
    # Charger les donnÃ©es
    $tasksData = Get-Content -Path $PlanningConfig.TasksFile -Raw | ConvertFrom-Json
    $scheduleData = Get-Content -Path $PlanningConfig.ScheduleFile -Raw | ConvertFrom-Json
    
    $tasks = $tasksData.Tasks
    $milestones = $scheduleData.Schedule.Milestones
    
    $resources = @()
    if ($IncludeResources) {
        $resourcesData = Get-Content -Path $PlanningConfig.ResourcesFile -Raw | ConvertFrom-Json
        $resources = $resourcesData.Resources
    }
    
    # DÃ©terminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "ImplementationPlan-$timestamp.html"
        $OutputPath = Join-Path -Path $env:TEMP -ChildPath $fileName
    }
    
    # Calculer les statistiques
    $totalEstimatedHours = ($tasks | Measure-Object -Property EstimatedHours -Sum).Sum
    $completedTasks = ($tasks | Where-Object { $_.Status -eq "Completed" } | Measure-Object).Count
    $inProgressTasks = ($tasks | Where-Object { $_.Status -eq "In Progress" } | Measure-Object).Count
    $notStartedTasks = ($tasks | Where-Object { $_.Status -eq "Not Started" } | Measure-Object).Count
    $blockedTasks = ($tasks | Where-Object { $_.Status -eq "Blocked" } | Measure-Object).Count
    
    $completionPercentage = if ($tasks.Count -gt 0) {
        [Math]::Round(($completedTasks / $tasks.Count) * 100, 1)
    }
    else {
        0
    }
    
    # GÃ©nÃ©rer le HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$Title</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        h1, h2, h3 {
            color: #2c3e50;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        
        .section {
            margin-bottom: 30px;
        }
        
        .summary {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .summary-card {
            background-color: #f8f9fa;
            border-radius: 8px;
            padding: 15px;
            flex: 1;
            min-width: 200px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .summary-card h3 {
            margin-top: 0;
            margin-bottom: 10px;
            font-size: 16px;
        }
        
        .summary-value {
            font-size: 24px;
            font-weight: bold;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        th {
            background-color: #4caf50;
            color: white;
        }
        
        tr:hover {
            background-color: #f5f5f5;
        }
        
        .priority-high {
            color: #e74c3c;
            font-weight: bold;
        }
        
        .priority-medium {
            color: #3498db;
        }
        
        .priority-low {
            color: #2ecc71;
        }
        
        .status-completed {
            color: #2ecc71;
            font-weight: bold;
        }
        
        .status-in-progress {
            color: #3498db;
            font-weight: bold;
        }
        
        .status-not-started {
            color: #95a5a6;
        }
        
        .status-blocked {
            color: #e74c3c;
            font-weight: bold;
        }
        
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 14px;
            color: #888;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$Title</h1>
            <div>
                <span>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
            </div>
        </div>
        
        <div class="summary">
            <div class="summary-card">
                <h3>TÃ¢ches totales</h3>
                <div class="summary-value">$($tasks.Count)</div>
            </div>
            
            <div class="summary-card">
                <h3>Heures estimÃ©es</h3>
                <div class="summary-value">$totalEstimatedHours</div>
            </div>
            
            <div class="summary-card">
                <h3>Progression</h3>
                <div class="summary-value">$completionPercentage%</div>
            </div>
            
            <div class="summary-card">
                <h3>Jalons</h3>
                <div class="summary-value">$($milestones.Count)</div>
            </div>
        </div>
        
        <div class="section">
            <h2>Jalons</h2>
            
            <table>
                <thead>
                    <tr>
                        <th>Nom</th>
                        <th>Date</th>
                        <th>Description</th>
                        <th>Statut</th>
                    </tr>
                </thead>
                <tbody>
                    $(foreach ($milestone in ($milestones | Sort-Object -Property Date)) {
                        $statusClass = "status-" + $milestone.Status.ToLower().Replace(" ", "-")
                        
                        "<tr>
                            <td>$($milestone.Name)</td>
                            <td>$($milestone.Date)</td>
                            <td>$($milestone.Description)</td>
                            <td class='$statusClass'>$($milestone.Status)</td>
                        </tr>"
                    })
                </tbody>
            </table>
        </div>
        
        <div class="section">
            <h2>TÃ¢ches</h2>
            
            <table>
                <thead>
                    <tr>
                        <th>Nom</th>
                        <th>PrioritÃ©</th>
                        <th>Heures estimÃ©es</th>
                        <th>Statut</th>
                        <th>DÃ©but</th>
                        <th>Fin</th>
                        <th>AssignÃ© Ã </th>
                    </tr>
                </thead>
                <tbody>
                    $(foreach ($task in ($tasks | Sort-Object -Property Priority, Name)) {
                        $priorityClass = "priority-" + $task.Priority.ToLower()
                        $statusClass = "status-" + $task.Status.ToLower().Replace(" ", "-")
                        $assignedTo = if ($task.AssignedTo.Count -gt 0) { $task.AssignedTo -join ", " } else { "Non assignÃ©" }
                        
                        "<tr>
                            <td>$($task.Name)</td>
                            <td class='$priorityClass'>$($task.Priority)</td>
                            <td>$($task.EstimatedHours)</td>
                            <td class='$statusClass'>$($task.Status)</td>
                            <td>$($task.StartDate)</td>
                            <td>$($task.EndDate)</td>
                            <td>$assignedTo</td>
                        </tr>"
                    })
                </tbody>
            </table>
        </div>
        
        $(if ($IncludeResources) {
            "<div class='section'>
                <h2>Ressources</h2>
                
                <table>
                    <thead>
                        <tr>
                            <th>Nom</th>
                            <th>RÃ´le</th>
                            <th>Heures disponibles</th>
                            <th>CompÃ©tences</th>
                        </tr>
                    </thead>
                    <tbody>
                        $(foreach ($resource in ($resources | Sort-Object -Property Role, Name)) {
                            $skills = if ($resource.Skills.Count -gt 0) { $resource.Skills -join ", " } else { "Non spÃ©cifiÃ©" }
                            
                            "<tr>
                                <td>$($resource.Name)</td>
                                <td>$($resource.Role)</td>
                                <td>$($resource.AvailableHoursPerWeek) h/semaine</td>
                                <td>$skills</td>
                            </tr>"
                        })
                    </tbody>
                </table>
            </div>"
        })
        
        <div class="footer">
            <p>Rapport gÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
    </div>
</body>
</html>
"@
    
    # Enregistrer le HTML
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    
    # Ouvrir le rapport si demandÃ©
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ImplementationPlanning, Add-ImplementationTask, Add-ImplementationResource
Export-ModuleMember -Function Add-ImplementationMilestone, Set-TaskSchedule, New-GanttChart, New-ImplementationPlanReport

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
