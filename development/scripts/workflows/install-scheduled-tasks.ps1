<#
.SYNOPSIS
    Script pour installer les tâches planifiées qui exécuteront automatiquement les workflows de gestion de roadmap.

.DESCRIPTION
    Ce script installe les tâches planifiées suivantes :
    1. Workflow quotidien : Exécuté tous les jours à 9h00
    2. Workflow hebdomadaire : Exécuté tous les vendredis à 16h00
    3. Workflow mensuel : Exécuté le premier jour de chaque mois à 10h00

.PARAMETER ProjectRoot
    Chemin vers la racine du projet.
    Par défaut : Le répertoire parent du répertoire du script.

.PARAMETER TaskPrefix
    Préfixe pour les noms des tâches planifiées.
    Par défaut : "RoadmapManager"

.PARAMETER Force
    Indique si les tâches existantes doivent être remplacées.
    Par défaut : $false

.EXAMPLE
    .\install-scheduled-tasks.ps1

.EXAMPLE
    .\install-scheduled-tasks.ps1 -TaskPrefix "MonProjet" -Force

.NOTES
    Auteur: Integrated Manager Team
    Version: 1.0
    Date de création: 2023-06-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot,

    [Parameter(Mandatory = $false)]
    [string]$TaskPrefix = "RoadmapManager",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Déterminer le chemin du projet
if (-not $ProjectRoot) {
    $ProjectRoot = $PSScriptRoot
    while (-not (Test-Path -Path (Join-Path -Path $ProjectRoot -ChildPath ".git") -PathType Container) -and 
           -not [string]::IsNullOrEmpty($ProjectRoot)) {
        $ProjectRoot = Split-Path -Path $ProjectRoot -Parent
    }

    if ([string]::IsNullOrEmpty($ProjectRoot) -or -not (Test-Path -Path (Join-Path -Path $ProjectRoot -ChildPath ".git") -PathType Container)) {
        $ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
        if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
            Write-Error "Impossible de déterminer le chemin du projet."
            exit 1
        }
    }
}

# Vérifier que le répertoire des workflows existe
$workflowsPath = Join-Path -Path $ProjectRoot -ChildPath "development\scripts\workflows"
if (-not (Test-Path -Path $workflowsPath -PathType Container)) {
    Write-Error "Le répertoire des workflows est introuvable : $workflowsPath"
    exit 1
}

# Vérifier que les scripts des workflows existent
$quotidienPath = Join-Path -Path $workflowsPath -ChildPath "workflow-quotidien.ps1"
$hebdomadairePath = Join-Path -Path $workflowsPath -ChildPath "workflow-hebdomadaire.ps1"
$mensuelPath = Join-Path -Path $workflowsPath -ChildPath "workflow-mensuel.ps1"

foreach ($path in @($quotidienPath, $hebdomadairePath, $mensuelPath)) {
    if (-not (Test-Path -Path $path -PathType Leaf)) {
        Write-Error "Le script de workflow est introuvable : $path"
        exit 1
    }
}

# Fonction pour créer une tâche planifiée
function New-ScheduledTaskWithOptions {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.ScheduledTaskTrigger]$Trigger,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si la tâche existe déjà
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    
    if ($existingTask) {
        if ($Force) {
            Write-Host "La tâche '$TaskName' existe déjà et sera remplacée." -ForegroundColor Yellow
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        } else {
            Write-Error "La tâche '$TaskName' existe déjà. Utilisez le paramètre -Force pour la remplacer."
            return $false
        }
    }
    
    # Créer l'action
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"" -WorkingDirectory $ProjectRoot
    
    # Créer les paramètres
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
    
    # Créer le principal (utilisateur qui exécute la tâche)
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType S4U -RunLevel Highest
    
    # Créer la tâche
    if ($PSCmdlet.ShouldProcess($TaskName, "Créer une tâche planifiée")) {
        $task = Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $action -Trigger $trigger -Settings $settings -Principal $principal
        
        if ($task) {
            Write-Host "La tâche '$TaskName' a été créée avec succès." -ForegroundColor Green
            return $true
        } else {
            Write-Error "Échec de la création de la tâche '$TaskName'."
            return $false
        }
    }
    
    return $false
}

# Créer les tâches planifiées
$tasks = @(
    @{
        Name = "$TaskPrefix-Quotidien"
        Description = "Exécute le workflow quotidien de gestion de roadmap"
        ScriptPath = $quotidienPath
        Trigger = New-ScheduledTaskTrigger -Daily -At 9am
    },
    @{
        Name = "$TaskPrefix-Hebdomadaire"
        Description = "Exécute le workflow hebdomadaire de gestion de roadmap"
        ScriptPath = $hebdomadairePath
        Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Friday -At 4pm
    },
    @{
        Name = "$TaskPrefix-Mensuel"
        Description = "Exécute le workflow mensuel de gestion de roadmap"
        ScriptPath = $mensuelPath
        Trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At 10am
    }
)

$results = @()

foreach ($task in $tasks) {
    Write-Host "Installation de la tâche planifiée '$($task.Name)'..." -ForegroundColor Cyan
    
    $success = New-ScheduledTaskWithOptions -TaskName $task.Name -Description $task.Description -ScriptPath $task.ScriptPath -Trigger $task.Trigger -Force:$Force
    
    $results += @{
        Name = $task.Name
        ScriptPath = $task.ScriptPath
        Success = $success
    }
}

# Afficher un résumé
Write-Host "`nRésumé de l'installation des tâches planifiées :" -ForegroundColor Cyan

foreach ($result in $results) {
    $status = if ($result.Success) { "Installée" } else { "Échec" }
    $color = if ($result.Success) { "Green" } else { "Red" }
    
    Write-Host "  - $($result.Name): $status" -ForegroundColor $color
    Write-Host "    Script: $($result.ScriptPath)" -ForegroundColor Gray
}

# Retourner un résultat
return @{
    ProjectRoot = $ProjectRoot
    TaskPrefix = $TaskPrefix
    Tasks = $results
    Success = ($results | Where-Object { -not $_.Success }).Count -eq 0
}
