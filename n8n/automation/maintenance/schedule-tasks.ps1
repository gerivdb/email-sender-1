<#
.SYNOPSIS
    Script de planification des tâches de maintenance n8n.

.DESCRIPTION
    Ce script installe, désinstalle ou vérifie les tâches planifiées pour la maintenance de n8n.

.PARAMETER Action
    Action à effectuer (Install, Uninstall, Check).

.PARAMETER TaskPrefix
    Préfixe pour les noms des tâches planifiées (par défaut: N8N_).

.PARAMETER ProjectRoot
    Dossier racine du projet (par défaut: dossier parent du dossier n8n).

.PARAMETER NoInteractive
    Exécute le script en mode non interactif (sans demander de confirmation).

.EXAMPLE
    .\schedule-tasks.ps1 -Action Install
    Installe les tâches planifiées avec les paramètres par défaut.

.EXAMPLE
    .\schedule-tasks.ps1 -Action Uninstall -TaskPrefix "MyN8N_"
    Désinstalle les tâches planifiées avec le préfixe spécifié.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  27/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("Install", "Uninstall", "Check")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$TaskPrefix = "N8N_",
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectRoot = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$NoInteractive
)

# Fonction pour écrire dans le log
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console avec la couleur appropriée
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
    
    # Écrire dans le fichier de log de maintenance
    $logFolder = Join-Path -Path $ProjectRoot -ChildPath "n8n/logs"
    $maintenanceLogFile = Join-Path -Path $logFolder -ChildPath "maintenance.log"
    
    # Créer le dossier de log s'il n'existe pas
    if (-not (Test-Path -Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
    }
    
    Add-Content -Path $maintenanceLogFile -Value $logMessage
}

# Fonction pour obtenir le dossier racine du projet
function Get-ProjectRoot {
    param (
        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot = ""
    )
    
    if ([string]::IsNullOrEmpty($ProjectRoot)) {
        # Obtenir le dossier du script
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        
        # Obtenir le dossier parent du dossier n8n
        $ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))
    }
    
    return $ProjectRoot
}

# Fonction pour définir les tâches planifiées
function Get-ScheduledTasks {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ProjectRoot,
        
        [Parameter(Mandatory=$true)]
        [string]$TaskPrefix
    )
    
    # Chemin des scripts
    $maintenancePath = Join-Path -Path $ProjectRoot -ChildPath "n8n/automation/maintenance"
    
    # Définir les tâches planifiées
    $tasks = @(
        @{
            Name = "${TaskPrefix}RotateLogs"
            Description = "Rotation des logs n8n"
            Script = Join-Path -Path $maintenancePath -ChildPath "rotate-logs.ps1"
            Arguments = "-NoInteractive"
            Schedule = "DAILY"
            StartTime = "03:00"
            DaysInterval = 1
        },
        @{
            Name = "${TaskPrefix}BackupWorkflows"
            Description = "Sauvegarde des workflows n8n"
            Script = Join-Path -Path $maintenancePath -ChildPath "backup-workflows.ps1"
            Arguments = "-NoInteractive"
            Schedule = "DAILY"
            StartTime = "04:00"
            DaysInterval = 1
        },
        @{
            Name = "${TaskPrefix}CleanupTemp"
            Description = "Nettoyage des fichiers temporaires n8n"
            Script = Join-Path -Path $maintenancePath -ChildPath "cleanup-temp.ps1"
            Arguments = "-NoInteractive"
            Schedule = "WEEKLY"
            StartTime = "05:00"
            DaysOfWeek = "SUNDAY"
        },
        @{
            Name = "${TaskPrefix}Maintenance"
            Description = "Maintenance complète n8n"
            Script = Join-Path -Path $maintenancePath -ChildPath "maintenance.ps1"
            Arguments = "-NoInteractive"
            Schedule = "WEEKLY"
            StartTime = "02:00"
            DaysOfWeek = "SUNDAY"
        }
    )
    
    return $tasks
}

# Fonction pour installer les tâches planifiées
function Install-ScheduledTasks {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Tasks,
        
        [Parameter(Mandatory=$true)]
        [string]$ProjectRoot
    )
    
    $installedCount = 0
    $errorCount = 0
    
    foreach ($task in $Tasks) {
        Write-Log "Installation de la tâche planifiée: $($task.Name)" -Level "INFO"
        
        try {
            # Vérifier si la tâche existe déjà
            $existingTask = Get-ScheduledTask -TaskName $task.Name -ErrorAction SilentlyContinue
            
            if ($null -ne $existingTask) {
                Write-Log "La tâche $($task.Name) existe déjà, suppression..." -Level "WARNING"
                Unregister-ScheduledTask -TaskName $task.Name -Confirm:$false
            }
            
            # Créer l'action
            $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$($task.Script)`" $($task.Arguments)"
            
            # Créer le déclencheur
            $trigger = if ($task.Schedule -eq "DAILY") {
                New-ScheduledTaskTrigger -Daily -At $task.StartTime -DaysInterval $task.DaysInterval
            } elseif ($task.Schedule -eq "WEEKLY") {
                New-ScheduledTaskTrigger -Weekly -At $task.StartTime -DaysOfWeek $task.DaysOfWeek
            } else {
                throw "Type de planification non pris en charge: $($task.Schedule)"
            }
            
            # Créer les paramètres
            $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries
            
            # Créer la tâche
            Register-ScheduledTask -TaskName $task.Name -Action $action -Trigger $trigger -Settings $settings -Description $task.Description
            
            Write-Log "Tâche $($task.Name) installée avec succès" -Level "SUCCESS"
            $installedCount++
        } catch {
            Write-Log "Erreur lors de l'installation de la tâche $($task.Name): $_" -Level "ERROR"
            $errorCount++
        }
    }
    
    Write-Log "Installation des tâches planifiées terminée: $installedCount installées, $errorCount erreurs" -Level "INFO"
    
    return $installedCount -gt 0 -and $errorCount -eq 0
}

# Fonction pour désinstaller les tâches planifiées
function Uninstall-ScheduledTasks {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Tasks
    )
    
    $uninstalledCount = 0
    $errorCount = 0
    
    foreach ($task in $Tasks) {
        Write-Log "Désinstallation de la tâche planifiée: $($task.Name)" -Level "INFO"
        
        try {
            # Vérifier si la tâche existe
            $existingTask = Get-ScheduledTask -TaskName $task.Name -ErrorAction SilentlyContinue
            
            if ($null -ne $existingTask) {
                # Supprimer la tâche
                Unregister-ScheduledTask -TaskName $task.Name -Confirm:$false
                
                Write-Log "Tâche $($task.Name) désinstallée avec succès" -Level "SUCCESS"
                $uninstalledCount++
            } else {
                Write-Log "La tâche $($task.Name) n'existe pas" -Level "WARNING"
            }
        } catch {
            Write-Log "Erreur lors de la désinstallation de la tâche $($task.Name): $_" -Level "ERROR"
            $errorCount++
        }
    }
    
    Write-Log "Désinstallation des tâches planifiées terminée: $uninstalledCount désinstallées, $errorCount erreurs" -Level "INFO"
    
    return $uninstalledCount -gt 0 -and $errorCount -eq 0
}

# Fonction pour vérifier les tâches planifiées
function Check-ScheduledTasks {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Tasks
    )
    
    $existingCount = 0
    $missingCount = 0
    
    foreach ($task in $Tasks) {
        Write-Log "Vérification de la tâche planifiée: $($task.Name)" -Level "INFO"
        
        try {
            # Vérifier si la tâche existe
            $existingTask = Get-ScheduledTask -TaskName $task.Name -ErrorAction SilentlyContinue
            
            if ($null -ne $existingTask) {
                Write-Log "La tâche $($task.Name) existe" -Level "SUCCESS"
                $existingCount++
                
                # Afficher les détails de la tâche
                $taskInfo = Get-ScheduledTaskInfo -TaskName $task.Name
                Write-Log "  Dernier résultat: $($taskInfo.LastTaskResult)" -Level "INFO"
                Write-Log "  Prochaine exécution: $($taskInfo.NextRunTime)" -Level "INFO"
                Write-Log "  Dernière exécution: $($taskInfo.LastRunTime)" -Level "INFO"
            } else {
                Write-Log "La tâche $($task.Name) n'existe pas" -Level "WARNING"
                $missingCount++
            }
        } catch {
            Write-Log "Erreur lors de la vérification de la tâche $($task.Name): $_" -Level "ERROR"
            $missingCount++
        }
    }
    
    Write-Log "Vérification des tâches planifiées terminée: $existingCount existantes, $missingCount manquantes" -Level "INFO"
    
    return $existingCount -gt 0 -and $missingCount -eq 0
}

# Fonction principale
function Main {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Action,
        
        [Parameter(Mandatory=$true)]
        [string]$TaskPrefix,
        
        [Parameter(Mandatory=$true)]
        [string]$ProjectRoot,
        
        [Parameter(Mandatory=$true)]
        [bool]$NoInteractive
    )
    
    # Obtenir le dossier racine du projet
    $ProjectRoot = Get-ProjectRoot -ProjectRoot $ProjectRoot
    
    # Afficher les paramètres
    Write-Log "Paramètres:" -Level "INFO"
    Write-Log "  Action: $Action" -Level "INFO"
    Write-Log "  TaskPrefix: $TaskPrefix" -Level "INFO"
    Write-Log "  ProjectRoot: $ProjectRoot" -Level "INFO"
    
    # Vérifier si le dossier racine existe
    if (-not (Test-Path -Path $ProjectRoot)) {
        Write-Log "Dossier racine du projet non trouvé: $ProjectRoot" -Level "ERROR"
        return $false
    }
    
    # Vérifier si l'utilisateur a les droits d'administrateur
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Log "Ce script doit être exécuté en tant qu'administrateur" -Level "ERROR"
        return $false
    }
    
    # Obtenir les tâches planifiées
    $tasks = Get-ScheduledTasks -ProjectRoot $ProjectRoot -TaskPrefix $TaskPrefix
    
    # Demander confirmation si mode interactif
    if (-not $NoInteractive) {
        Write-Log "Action: $Action" -Level "INFO"
        Write-Log "Tâches planifiées:" -Level "INFO"
        
        foreach ($task in $tasks) {
            Write-Log "  $($task.Name): $($task.Description)" -Level "INFO"
        }
        
        $confirmation = Read-Host "Voulez-vous continuer? (O/N)"
        
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Opération annulée par l'utilisateur" -Level "WARNING"
            return $false
        }
    }
    
    # Exécuter l'action
    $success = switch ($Action) {
        "Install" { Install-ScheduledTasks -Tasks $tasks -ProjectRoot $ProjectRoot }
        "Uninstall" { Uninstall-ScheduledTasks -Tasks $tasks }
        "Check" { Check-ScheduledTasks -Tasks $tasks }
        default { 
            Write-Log "Action non reconnue: $Action" -Level "ERROR"
            $false
        }
    }
    
    return $success
}

# Exécuter la fonction principale
if ($MyInvocation.InvocationName -ne ".") {
    $success = Main -Action $Action -TaskPrefix $TaskPrefix -ProjectRoot $ProjectRoot -NoInteractive $NoInteractive
    
    if ($success) {
        exit 0
    } else {
        exit 1
    }
}
