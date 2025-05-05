<#
.SYNOPSIS
    Script pour planifier les tÃ¢ches futures en fonction de l'Ã©tat actuel (Mode ROADMAP-PLAN).

.DESCRIPTION
    Ce script permet de planifier les tÃ¢ches futures en fonction de l'Ã©tat actuel de la roadmap.
    Il analyse l'Ã©tat d'avancement, identifie les dÃ©pendances et propose un plan d'action.

.PARAMETER RoadmapPath
    Chemin vers le fichier de roadmap Ã  analyser.

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour le plan. Si non spÃ©cifiÃ©, utilise la configuration.

.PARAMETER DaysToForecast
    Nombre de jours Ã  prÃ©voir dans le plan. Par dÃ©faut : 30.

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration unifiÃ©e.
    Par dÃ©faut : "development\config\unified-config.json".

.EXAMPLE
    .\roadmap-plan-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"

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
    [int]$DaysToForecast = 30,

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
    # Rechercher une configuration alternative
    $alternativePaths = @(
        "development\config\unified-config.json",
        "development\roadmap\parser\config\modes-config.json",
        "development\roadmap\parser\config\config.json"
    )
    
    foreach ($path in $alternativePaths) {
        $fullPath = Join-Path -Path $projectRoot -ChildPath $path
        if (Test-Path -Path $fullPath) {
            Write-Host "Fichier de configuration trouvÃ© : $fullPath" -ForegroundColor Green
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
    $OutputPath = Join-Path -Path (Split-Path -Parent $RoadmapPath) -ChildPath "roadmap-plan.md"
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

# Importer le module RoadmapParser
$modulePath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\RoadmapParser.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Le module RoadmapParser est introuvable : $modulePath"
    exit 1
}

# Afficher les paramÃ¨tres
Write-Host "Mode ROADMAP-PLAN - Planification des tÃ¢ches futures" -ForegroundColor Cyan
Write-Host "Fichier de roadmap : $RoadmapPath" -ForegroundColor Gray
Write-Host "Fichier de sortie : $OutputPath" -ForegroundColor Gray
Write-Host "Nombre de jours Ã  prÃ©voir : $DaysToForecast" -ForegroundColor Gray
Write-Host ""

# Fonction pour analyser la roadmap
function Get-RoadmapTasks {
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
                IsCompleted = $isChecked
            }
            
            $currentSubTasks += $subTask
        }
    }
    
    # Ajouter la derniÃ¨re tÃ¢che
    if ($currentTask) {
        $currentTask.SubTasks = $currentSubTasks
        $tasks += $currentTask
    }
    
    return $tasks
}

# Fonction pour gÃ©nÃ©rer un plan d'action
function New-ActionPlan {
    param (
        [array]$Tasks,
        [int]$DaysToForecast
    )
    
    # Identifier les tÃ¢ches non complÃ©tÃ©es
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
    
    # Estimer le temps nÃ©cessaire pour chaque tÃ¢che (simulation)
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
            
            # Si on dÃ©passe la pÃ©riode de prÃ©vision, arrÃªter
            if ($currentDate -gt $endDate) {
                break
            }
        }
        
        # Si on dÃ©passe la pÃ©riode de prÃ©vision, arrÃªter
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

# Fonction pour gÃ©nÃ©rer un rapport de plan d'action
function New-PlanReport {
    param (
        [hashtable]$Plan,
        [string]$OutputPath
    )
    
    # CrÃ©er le contenu Markdown
    $markdown = "# Plan d'action pour la roadmap`n`n"
    
    $markdown += "## PÃ©riode de planification`n`n"
    $markdown += "- **Date de dÃ©but :** $($Plan.StartDate)`n"
    $markdown += "- **Date de fin :** $($Plan.EndDate)`n"
    $markdown += "- **Nombre de jours :** $($Plan.DaysToForecast)`n`n"
    
    $markdown += "## TÃ¢ches planifiÃ©es`n`n"
    $markdown += "| Groupe | ID | TÃ¢che | Date de dÃ©but | Date de fin | Jours estimÃ©s |`n"
    $markdown += "| ------ | -- | ----- | ------------- | ----------- | ------------- |`n"
    
    foreach ($task in $Plan.Tasks) {
        $markdown += "| $($task.TaskGroup) | $($task.SubTaskId) | $($task.SubTaskTitle) | $($task.StartDate) | $($task.EndDate) | $($task.EstimatedDays) |`n"
    }
    
    $markdown += "`n## Recommandations`n`n"
    $markdown += "1. Commencer par les tÃ¢ches prioritaires`n"
    $markdown += "2. VÃ©rifier rÃ©guliÃ¨rement l'avancement`n"
    $markdown += "3. Mettre Ã  jour la roadmap au fur et Ã  mesure`n"
    $markdown += "4. Ajuster le plan si nÃ©cessaire`n`n"
    
    $markdown += "## Notes`n`n"
    $markdown += "Ce plan a Ã©tÃ© gÃ©nÃ©rÃ© automatiquement par le mode ROADMAP-PLAN. Les estimations sont basÃ©es sur des simulations et peuvent ne pas reflÃ©ter la rÃ©alitÃ©. Il est recommandÃ© de l'ajuster en fonction de votre expÃ©rience et de vos contraintes.`n"
    
    # Enregistrer le rapport
    Set-Content -Path $OutputPath -Value $markdown -Encoding UTF8
    
    return $OutputPath
}

# Analyser la roadmap
$tasks = Get-RoadmapTasks -RoadmapPath $RoadmapPath

# GÃ©nÃ©rer un plan d'action
$plan = New-ActionPlan -Tasks $tasks -DaysToForecast $DaysToForecast

# GÃ©nÃ©rer un rapport de plan d'action
$reportPath = New-PlanReport -Plan $plan -OutputPath $OutputPath

# Afficher un message de fin
Write-Host "`nExÃ©cution du mode ROADMAP-PLAN terminÃ©e." -ForegroundColor Cyan
Write-Host "Plan d'action gÃ©nÃ©rÃ© : $reportPath" -ForegroundColor Green

# Retourner un rÃ©sultat
return @{
    RoadmapPath = $RoadmapPath
    OutputPath = $reportPath
    Plan = $plan
}
