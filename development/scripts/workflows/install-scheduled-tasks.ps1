<#
.SYNOPSIS
    Script pour installer les tÃ¢ches planifiÃ©es qui exÃ©cuteront automatiquement les workflows de gestion de roadmap.

.DESCRIPTION
    Ce script installe les tÃ¢ches planifiÃ©es suivantes :
    1. Workflow quotidien : ExÃ©cutÃ© tous les jours Ã  9h00
    2. Workflow hebdomadaire : ExÃ©cutÃ© tous les vendredis Ã  16h00
    3. Workflow mensuel : ExÃ©cutÃ© le premier jour de chaque mois Ã  10h00

.PARAMETER ProjectRoot
    Chemin vers la racine du projet.
    Par dÃ©faut : Le rÃ©pertoire parent du rÃ©pertoire du script.

.PARAMETER TaskPrefix
    PrÃ©fixe pour les noms des tÃ¢ches planifiÃ©es.
    Par dÃ©faut : "roadmap-manager"

.PARAMETER Force
    Indique si les tÃ¢ches existantes doivent Ãªtre remplacÃ©es.
    Par dÃ©faut : $false

.EXAMPLE
    .\install-scheduled-tasks.ps1

.EXAMPLE
    .\install-scheduled-tasks.ps1 -TaskPrefix "MonProjet" -Force

.NOTES
    Auteur: Integrated Manager Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot,

    [Parameter(Mandatory = $false)]
    [string]$TaskPrefix = "roadmap-manager",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# DÃ©terminer le chemin du projet
if (-not $ProjectRoot) {
    $ProjectRoot = $PSScriptRoot
    while (-not (Test-Path -Path (Join-Path -Path $ProjectRoot -ChildPath ".git") -PathType Container) -and 
           -not [string]::IsNullOrEmpty($ProjectRoot)) {
        $ProjectRoot = Split-Path -Path $ProjectRoot -Parent
    }

    if ([string]::IsNullOrEmpty($ProjectRoot) -or -not (Test-Path -Path (Join-Path -Path $ProjectRoot -ChildPath ".git") -PathType Container)) {
        $ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
        if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
            Write-Error "Impossible de dÃ©terminer le chemin du projet."
            exit 1
        }
    }
}

# VÃ©rifier que le rÃ©pertoire des workflows existe
$workflowsPath = Join-Path -Path $ProjectRoot -ChildPath "development\scripts\workflows"
if (-not (Test-Path -Path $workflowsPath -PathType Container)) {
    Write-Error "Le rÃ©pertoire des workflows est introuvable : $workflowsPath"
    exit 1
}

# VÃ©rifier que les scripts des workflows existent
$quotidienPath = Join-Path -Path $workflowsPath -ChildPath "workflow-quotidien.ps1"
$hebdomadairePath = Join-Path -Path $workflowsPath -ChildPath "workflow-hebdomadaire.ps1"
$mensuelPath = Join-Path -Path $workflowsPath -ChildPath "workflow-mensuel.ps1"

foreach ($path in @($quotidienPath, $hebdomadairePath, $mensuelPath)) {
    if (-not (Test-Path -Path $path -PathType Leaf)) {
        Write-Error "Le script de workflow est introuvable : $path"
        exit 1
    }
}

# Fonction pour crÃ©er une tÃ¢che planifiÃ©e
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
    
    # VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    
    if ($existingTask) {
        if ($Force) {
            Write-Host "La tÃ¢che '$TaskName' existe dÃ©jÃ  et sera remplacÃ©e." -ForegroundColor Yellow
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        } else {
            Write-Error "La tÃ¢che '$TaskName' existe dÃ©jÃ . Utilisez le paramÃ¨tre -Force pour la remplacer."
            return $false
        }
    }
    
    # CrÃ©er l'action
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"" -WorkingDirectory $ProjectRoot
    
    # CrÃ©er les paramÃ¨tres
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
    
    # CrÃ©er le principal (utilisateur qui exÃ©cute la tÃ¢che)
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType S4U -RunLevel Highest
    
    # CrÃ©er la tÃ¢che
    if ($PSCmdlet.ShouldProcess($TaskName, "CrÃ©er une tÃ¢che planifiÃ©e")) {
        $task = Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $action -Trigger $trigger -Settings $settings -Principal $principal
        
        if ($task) {
            Write-Host "La tÃ¢che '$TaskName' a Ã©tÃ© crÃ©Ã©e avec succÃ¨s." -ForegroundColor Green
            return $true
        } else {
            Write-Error "Ã‰chec de la crÃ©ation de la tÃ¢che '$TaskName'."
            return $false
        }
    }
    
    return $false
}

# CrÃ©er les tÃ¢ches planifiÃ©es
$tasks = @(
    @{
        Name = "$TaskPrefix-Quotidien"
        Description = "ExÃ©cute le workflow quotidien de gestion de roadmap"
        ScriptPath = $quotidienPath
        Trigger = New-ScheduledTaskTrigger -Daily -At 9am
    },
    @{
        Name = "$TaskPrefix-Hebdomadaire"
        Description = "ExÃ©cute le workflow hebdomadaire de gestion de roadmap"
        ScriptPath = $hebdomadairePath
        Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Friday -At 4pm
    },
    @{
        Name = "$TaskPrefix-Mensuel"
        Description = "ExÃ©cute le workflow mensuel de gestion de roadmap"
        ScriptPath = $mensuelPath
        Trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At 10am
    }
)

$results = @()

foreach ($task in $tasks) {
    Write-Host "Installation de la tÃ¢che planifiÃ©e '$($task.Name)'..." -ForegroundColor Cyan
    
    $success = New-ScheduledTaskWithOptions -TaskName $task.Name -Description $task.Description -ScriptPath $task.ScriptPath -Trigger $task.Trigger -Force:$Force
    
    $results += @{
        Name = $task.Name
        ScriptPath = $task.ScriptPath
        Success = $success
    }
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de l'installation des tÃ¢ches planifiÃ©es :" -ForegroundColor Cyan

foreach ($result in $results) {
    $status = if ($result.Success) { "InstallÃ©e" } else { "Ã‰chec" }
    $color = if ($result.Success) { "Green" } else { "Red" }
    
    Write-Host "  - $($result.Name): $status" -ForegroundColor $color
    Write-Host "    Script: $($result.ScriptPath)" -ForegroundColor Gray
}

# Retourner un rÃ©sultat
return @{
    ProjectRoot = $ProjectRoot
    TaskPrefix = $TaskPrefix
    Tasks = $results
    Success = ($results | Where-Object { -not $_.Success }).Count -eq 0
}

