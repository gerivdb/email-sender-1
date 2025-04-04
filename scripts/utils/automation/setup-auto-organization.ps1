# Script pour configurer l'organisation automatique des fichiers et dossiers
# Ce script configure des tâches planifiées pour organiser automatiquement les fichiers et dossiers

# Vérifier si le script est exécuté en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Ce script doit être exécuté en tant qu'administrateur pour créer des tâches planifiées." -ForegroundColor Red
    Write-Host "Veuillez relancer le script avec des privilèges d'administrateur." -ForegroundColor Red
    exit
}

# Obtenir le chemin absolu du répertoire du projet
$projectPath = (Get-Location).Path

# Créer les chemins absolus vers les scripts
$organizeScriptsPath = Join-Path -Path $projectPath -ChildPath "scripts\organize-scripts.ps1"
$autoOrganizeFoldersPath = Join-Path -Path $projectPath -ChildPath "scripts\utils\automation\auto-organize-folders.ps1"
$manageLogsPath = Join-Path -Path $projectPath -ChildPath "scripts\utils\automation\manage-logs.ps1"
$organizeDocsPath = Join-Path -Path $projectPath -ChildPath "scripts\utils\automation\organize-docs-fixed.ps1"

# Vérifier si les scripts existent
if (-not (Test-Path -Path $organizeScriptsPath)) {
    Write-Host "Le script 'organize-scripts.ps1' n'existe pas à l'emplacement: $organizeScriptsPath" -ForegroundColor Red
    exit
}

if (-not (Test-Path -Path $autoOrganizeFoldersPath)) {
    Write-Host "Le script 'auto-organize-folders.ps1' n'existe pas à l'emplacement: $autoOrganizeFoldersPath" -ForegroundColor Red
    exit
}

if (-not (Test-Path -Path $manageLogsPath)) {
    Write-Host "Le script 'manage-logs.ps1' n'existe pas à l'emplacement: $manageLogsPath" -ForegroundColor Red
    exit
}

if (-not (Test-Path -Path $organizeDocsPath)) {
    Write-Host "Le script 'organize-docs-fixed.ps1' n'existe pas à l'emplacement: $organizeDocsPath" -ForegroundColor Red
    exit
}

# Fonction pour créer une tâche planifiée
function Create-ScheduledTask {
    param (
        [string]$TaskName,
        [string]$ScriptPath,
        [string]$Arguments,
        [string]$Trigger,
        [string]$Description
    )

    # Vérifier si la tâche existe déjà
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    if ($existingTask) {
        Write-Host "La tâche '$TaskName' existe déjà. Suppression de la tâche existante..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    # Créer l'action
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" $Arguments" -WorkingDirectory $projectPath

    # Créer le déclencheur
    $triggerParams = @{}

    switch ($Trigger) {
        "Daily" {
            $triggerParams = @{
                Daily = $true
                At = "3:00AM"
            }
        }
        "Weekly" {
            $triggerParams = @{
                Weekly = $true
                At = "3:00AM"
                DaysOfWeek = "Sunday"
            }
        }
        "Monthly" {
            $triggerParams = @{
                Monthly = $true
                At = "3:00AM"
                DaysOfMonth = 1
            }
        }
        "Hourly" {
            $triggerParams = @{
                Daily = $true
                At = "12:00AM"
            }
            # Ajouter une répétition toutes les heures
            $repetitionParams = @{
                RepetitionInterval = (New-TimeSpan -Hours 1)
                RepetitionDuration = (New-TimeSpan -Hours 24)
            }
        }
        default {
            $triggerParams = @{
                Daily = $true
                At = "3:00AM"
            }
        }
    }

    $scheduledTaskTrigger = New-ScheduledTaskTrigger @triggerParams

    # Ajouter la répétition si nécessaire
    if ($Trigger -eq "Hourly") {
        $scheduledTaskTrigger.Repetition = $repetitionParams
    }

    # Créer les paramètres principaux
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # Créer les paramètres
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -WakeToRun

    # Créer la tâche
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $scheduledTaskTrigger -Principal $principal -Settings $settings -Description $Description

    Write-Host "Tâche planifiée '$TaskName' créée avec succès." -ForegroundColor Green
}

# Créer les tâches planifiées
Write-Host "Configuration des tâches planifiées pour l'organisation automatique..." -ForegroundColor Cyan

# 1. Tâche pour organiser les scripts (hebdomadaire)
Create-ScheduledTask -TaskName "OrganizeScripts" `
                    -ScriptPath $organizeScriptsPath `
                    -Arguments "" `
                    -Trigger "Weekly" `
                    -Description "Organise les scripts en sous-dossiers sémantiques"

# 2. Tâche pour organiser les dossiers (quotidienne)
Create-ScheduledTask -TaskName "OrganizeFolders" `
                    -ScriptPath $autoOrganizeFoldersPath `
                    -Arguments "-MaxFilesPerFolder 15" `
                    -Trigger "Daily" `
                    -Description "Organise les dossiers contenant trop de fichiers"

# 3. Tâche pour gérer les logs (quotidienne)
Create-ScheduledTask -TaskName "ManageLogs" `
                    -ScriptPath $manageLogsPath `
                    -Arguments "daily-log scripts" `
                    -Trigger "Daily" `
                    -Description "Gère les logs par unité de temps"

# 4. Tâche pour organiser les documents (hebdomadaire)
Create-ScheduledTask -TaskName "OrganizeDocs" `
                    -ScriptPath $organizeDocsPath `
                    -Arguments "" `
                    -Trigger "Weekly" `
                    -Description "Organise les documents en sous-dossiers sémantiques"

Write-Host "`nConfiguration des tâches planifiées terminée avec succès!" -ForegroundColor Green
Write-Host "Les tâches suivantes ont été créées:" -ForegroundColor Cyan
Write-Host "  - OrganizeScripts: Exécution hebdomadaire (dimanche à 3h00)" -ForegroundColor Cyan
Write-Host "  - OrganizeFolders: Exécution quotidienne (3h00)" -ForegroundColor Cyan
Write-Host "  - ManageLogs: Exécution quotidienne (3h00)" -ForegroundColor Cyan
Write-Host "  - OrganizeDocs: Exécution hebdomadaire (dimanche à 3h00)" -ForegroundColor Cyan
