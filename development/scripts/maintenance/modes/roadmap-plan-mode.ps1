<#
.SYNOPSIS
    Script pour planifier les tâches futures en fonction de l'état actuel (Mode ROADMAP-PLAN).

.DESCRIPTION
    Ce script permet de planifier les tâches futures en fonction de l'état actuel de la roadmap.
    Il analyse l'état d'avancement, identifie les dépendances et propose un plan d'action.

.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap à analyser.

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour le plan. Si non spécifié, utilise la configuration.

.PARAMETER DaysToForecast
    Nombre de jours à prévoir dans le plan. Par défaut : 30.

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration unifiée.
    Par défaut : "development\config\unified-config.json".

.EXAMPLE
    .\roadmap-plan-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-06-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [int]$DaysToForecast = 30,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "development\config\unified-config.json"
)

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and 
       -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
        exit 1
    }
}

# Charger la configuration unifiée
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
    # Rechercher une configuration alternative
    $alternativePaths = @(
        "development\config\unified-config.json",
        "development\roadmap\parser\config\modes-config.json",
        "development\roadmap\parser\config\config.json"
    )
    
    foreach ($path in $alternativePaths) {
        $fullPath = Join-Path -Path $projectRoot -ChildPath $path
        if (Test-Path -Path $fullPath) {
            Write-Host "Fichier de configuration trouvé : $fullPath" -ForegroundColor Green
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
        Write-Error "Aucun fichier de configuration valide trouvé."
        exit 1
    }
}

# Utiliser les valeurs de la configuration si les paramètres ne sont pas spécifiés
if (-not $RoadmapPath) {
    if ($config.Roadmaps.Main.Path) {
        $RoadmapPath = Join-Path -Path $projectRoot -ChildPath $config.Roadmaps.Main.Path
    } elseif ($config.General.RoadmapPath) {
        $RoadmapPath = Join-Path -Path $projectRoot -ChildPath $config.General.RoadmapPath
    } else {
        Write-Error "Aucun chemin de roadmap spécifié et aucun chemin par défaut trouvé dans la configuration."
        exit 1
    }
}

if (-not $OutputPath) {
    $OutputPath = Join-Path -Path (Split-Path -Parent $RoadmapPath) -ChildPath "roadmap-plan.md"
}

# Convertir les chemins relatifs en chemins absolus
if (-not [System.IO.Path]::IsPathRooted($RoadmapPath)) {
    $RoadmapPath = Join-Path -Path $projectRoot -ChildPath $RoadmapPath
}

if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path -Path $projectRoot -ChildPath $OutputPath
}

# Vérifier que le fichier de roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier de roadmap spécifié n'existe pas : $RoadmapPath"
    exit 1
}

# Importer le module RoadmapParser
$modulePath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\RoadmapParser.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Le module RoadmapParser est introuvable : $modulePath"
    exit 1
}

# Afficher les paramètres
Write-Host "Mode ROADMAP-PLAN - Planification des tâches futures" -ForegroundColor Cyan
Write-Host "Fichier de roadmap : $RoadmapPath" -ForegroundColor Gray
Write-Host "Fichier de sortie : $OutputPath" -ForegroundColor Gray
Write-Host "Nombre de jours à prévoir : $DaysToForecast" -ForegroundColor Gray
Write-Host ""

# Fonction pour analyser la roadmap
function Get-RoadmapTasks {
    param (
        [string]$RoadmapPath
    )
    
    # Lire le contenu du fichier de roadmap
    $roadmapContent = Get-Content -Path $RoadmapPath -Encoding UTF8 -Raw
    
    # Analyser le contenu pour extraire les tâches
    $tasks = @()
    $lines = $roadmapContent -split "`n"
    $currentTask = $null
    $currentSubTasks = @()
    
    foreach ($line in $lines) {
        # Détecter les tâches principales (lignes commençant par "## ")
        if ($line -match "^## (.+)") {
            # Si une tâche est en cours de traitement, l'ajouter à la liste
            if ($currentTask) {
                $currentTask.SubTasks = $currentSubTasks
                $tasks += $currentTask
                $currentSubTasks = @()
            }
            
            # Créer une nouvelle tâche
            $currentTask = @{
                Title = $matches[1].Trim()
                Id = ""
                Description = ""
                SubTasks = @()
            }
        }
        # Détecter les descriptions (lignes commençant par "### Description")
        elseif ($line -match "^### Description" -and $currentTask) {
            $descriptionLines = @()
            $i = [array]::IndexOf($lines, $line) + 1
            
            while ($i -lt $lines.Length -and -not $lines[$i].StartsWith("###")) {
                $descriptionLines += $lines[$i]
                $i++
            }
            
            $currentTask.Description = ($descriptionLines -join "`n").Trim()
        }
        # Détecter les sous-tâches (lignes commençant par "- [ ]" ou "- [x]")
        elseif ($line -match "^- \[([ x])\] (?:\*\*([0-9.]+)\*\* )?(.+)" -and $currentTask) {
            $isChecked = $matches[1] -eq "x"
            $id = if ($matches[2]) { $matches[2] } else { "" }
            $title = $matches[3].Trim()
            
            $subTask = @{
                Title = $title
                Id = $id
                IsCompleted = $isChecked
            }
            
            $currentSubTasks += $subTask
        }
    }
    
    # Ajouter la dernière tâche
    if ($currentTask) {
        $currentTask.SubTasks = $currentSubTasks
        $tasks += $currentTask
    }
    
    return $tasks
}

# Fonction pour générer un plan d'action
function New-ActionPlan {
    param (
        [array]$Tasks,
        [int]$DaysToForecast
    )
    
    # Identifier les tâches non complétées
    $incompleteTasks = @()
    
    foreach ($task in $Tasks) {
        $incompleteSubTasks = $task.SubTasks | Where-Object { -not $_.IsCompleted }
        
        if ($incompleteSubTasks.Count -gt 0) {
            $incompleteTasks += @{
                Title = $task.Title
                Description = $task.Description
                SubTasks = $incompleteSubTasks
            }
        }
    }
    
    # Estimer le temps nécessaire pour chaque tâche (simulation)
    $today = Get-Date
    $endDate = $today.AddDays($DaysToForecast)
    $currentDate = $today
    $plan = @()
    
    foreach ($task in $incompleteTasks) {
        foreach ($subTask in $task.SubTasks) {
            # Simuler une estimation de temps (entre 1 et 5 jours)
            $estimatedDays = Get-Random -Minimum 1 -Maximum 6
            
            $planItem = @{
                TaskGroup = $task.Title
                SubTaskId = $subTask.Id
                SubTaskTitle = $subTask.Title
                StartDate = $currentDate.ToString("yyyy-MM-dd")
                EndDate = $currentDate.AddDays($estimatedDays).ToString("yyyy-MM-dd")
                EstimatedDays = $estimatedDays
            }
            
            $plan += $planItem
            $currentDate = $currentDate.AddDays($estimatedDays)
            
            # Si on dépasse la période de prévision, arrêter
            if ($currentDate -gt $endDate) {
                break
            }
        }
        
        # Si on dépasse la période de prévision, arrêter
        if ($currentDate -gt $endDate) {
            break
        }
    }
    
    return @{
        StartDate = $today.ToString("yyyy-MM-dd")
        EndDate = $endDate.ToString("yyyy-MM-dd")
        DaysToForecast = $DaysToForecast
        Tasks = $plan
    }
}

# Fonction pour générer un rapport de plan d'action
function New-PlanReport {
    param (
        [hashtable]$Plan,
        [string]$OutputPath
    )
    
    # Créer le contenu Markdown
    $markdown = "# Plan d'action pour la roadmap`n`n"
    
    $markdown += "## Période de planification`n`n"
    $markdown += "- **Date de début :** $($Plan.StartDate)`n"
    $markdown += "- **Date de fin :** $($Plan.EndDate)`n"
    $markdown += "- **Nombre de jours :** $($Plan.DaysToForecast)`n`n"
    
    $markdown += "## Tâches planifiées`n`n"
    $markdown += "| Groupe | ID | Tâche | Date de début | Date de fin | Jours estimés |`n"
    $markdown += "| ------ | -- | ----- | ------------- | ----------- | ------------- |`n"
    
    foreach ($task in $Plan.Tasks) {
        $markdown += "| $($task.TaskGroup) | $($task.SubTaskId) | $($task.SubTaskTitle) | $($task.StartDate) | $($task.EndDate) | $($task.EstimatedDays) |`n"
    }
    
    $markdown += "`n## Recommandations`n`n"
    $markdown += "1. Commencer par les tâches prioritaires`n"
    $markdown += "2. Vérifier régulièrement l'avancement`n"
    $markdown += "3. Mettre à jour la roadmap au fur et à mesure`n"
    $markdown += "4. Ajuster le plan si nécessaire`n`n"
    
    $markdown += "## Notes`n`n"
    $markdown += "Ce plan a été généré automatiquement par le mode ROADMAP-PLAN. Les estimations sont basées sur des simulations et peuvent ne pas refléter la réalité. Il est recommandé de l'ajuster en fonction de votre expérience et de vos contraintes.`n"
    
    # Enregistrer le rapport
    Set-Content -Path $OutputPath -Value $markdown -Encoding UTF8
    
    return $OutputPath
}

# Analyser la roadmap
$tasks = Get-RoadmapTasks -RoadmapPath $RoadmapPath

# Générer un plan d'action
$plan = New-ActionPlan -Tasks $tasks -DaysToForecast $DaysToForecast

# Générer un rapport de plan d'action
$reportPath = New-PlanReport -Plan $plan -OutputPath $OutputPath

# Afficher un message de fin
Write-Host "`nExécution du mode ROADMAP-PLAN terminée." -ForegroundColor Cyan
Write-Host "Plan d'action généré : $reportPath" -ForegroundColor Green

# Retourner un résultat
return @{
    RoadmapPath = $RoadmapPath
    OutputPath = $reportPath
    Plan = $plan
}
