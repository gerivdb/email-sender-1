# Script pour configurer l'organisation automatique des fichiers et dossiers
# Ce script configure des tÃ¢ches planifiÃ©es pour organiser automatiquement les fichiers et dossiers

# VÃ©rifier si le script est exÃ©cutÃ© en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Ce script doit Ãªtre exÃ©cutÃ© en tant qu'administrateur pour crÃ©er des tÃ¢ches planifiÃ©es." -ForegroundColor Red
    Write-Host "Veuillez relancer le script avec des privilÃ¨ges d'administrateur." -ForegroundColor Red
    exit
}

# Obtenir le chemin absolu du rÃ©pertoire du projet
$projectPath = (Get-Location).Path

# CrÃ©er les chemins absolus vers les scripts
$organizeScriptsPath = Join-Path -Path $projectPath -ChildPath "..\email\Organize-Scripts.ps1"
$autoOrganizeFoldersPath = Join-Path -Path $projectPath -ChildPath "..\..\D"
$manageLogsPath = Join-Path -Path $projectPath -ChildPath "..\..\D"
$organizeDocsPath = Join-Path -Path $projectPath -ChildPath "..\..\D"

# VÃ©rifier si les scripts existent
if (-not (Test-Path -Path $organizeScriptsPath)) {
    Write-Host "Le script 'organize-scripts.ps1' n'existe pas Ã  l'emplacement: $organizeScriptsPath" -ForegroundColor Red
    exit
}

if (-not (Test-Path -Path $autoOrganizeFoldersPath)) {
    Write-Host "Le script 'auto-organize-folders.ps1' n'existe pas Ã  l'emplacement: $autoOrganizeFoldersPath" -ForegroundColor Red
    exit
}

if (-not (Test-Path -Path $manageLogsPath)) {
    Write-Host "Le script 'manage-logs.ps1' n'existe pas Ã  l'emplacement: $manageLogsPath" -ForegroundColor Red
    exit
}

if (-not (Test-Path -Path $organizeDocsPath)) {
    Write-Host "Le script 'organize-docs-fixed.ps1' n'existe pas Ã  l'emplacement: $organizeDocsPath" -ForegroundColor Red
    exit
}

# Fonction pour crÃ©er une tÃ¢che planifiÃ©e
function Create-ScheduledTask {
    param (
        [string]$TaskName,
        [string]$ScriptPath,
        [string]$Arguments,
        [string]$Trigger,
        [string]$Description
    )

    # VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    if ($existingTask) {
        Write-Host "La tÃ¢che '$TaskName' existe dÃ©jÃ . Suppression de la tÃ¢che existante..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    # CrÃ©er l'action
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" $Arguments" -WorkingDirectory $projectPath

    # CrÃ©er le dÃ©clencheur
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
            # Ajouter une rÃ©pÃ©tition toutes les heures
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

    # Ajouter la rÃ©pÃ©tition si nÃ©cessaire
    if ($Trigger -eq "Hourly") {
        $scheduledTaskTrigger.Repetition = $repetitionParams
    }

    # CrÃ©er les paramÃ¨tres principaux
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # CrÃ©er les paramÃ¨tres
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -WakeToRun

    # CrÃ©er la tÃ¢che
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $scheduledTaskTrigger -Principal $principal -Settings $settings -Description $Description

    Write-Host "TÃ¢che planifiÃ©e '$TaskName' crÃ©Ã©e avec succÃ¨s." -ForegroundColor Green
}

# CrÃ©er les tÃ¢ches planifiÃ©es
Write-Host "Configuration des tÃ¢ches planifiÃ©es pour l'organisation automatique..." -ForegroundColor Cyan

# 1. TÃ¢che pour organiser les scripts (hebdomadaire)
Create-ScheduledTask -TaskName "OrganizeScripts" `
                    -ScriptPath $organizeScriptsPath `
                    -Arguments "" `
                    -Trigger "Weekly" `
                    -Description "Organise les scripts en sous-dossiers sÃ©mantiques"

# 2. TÃ¢che pour organiser les dossiers (quotidienne)
Create-ScheduledTask -TaskName "OrganizeFolders" `
                    -ScriptPath $autoOrganizeFoldersPath `
                    -Arguments "-MaxFilesPerFolder 15" `
                    -Trigger "Daily" `
                    -Description "Organise les dossiers contenant trop de fichiers"

# 3. TÃ¢che pour gÃ©rer les logs (quotidienne)
Create-ScheduledTask -TaskName "ManageLogs" `
                    -ScriptPath $manageLogsPath `
                    -Arguments "daily-log scripts" `
                    -Trigger "Daily" `
                    -Description "GÃ¨re les logs par unitÃ© de temps"

# 4. TÃ¢che pour organiser les documents (hebdomadaire)
Create-ScheduledTask -TaskName "OrganizeDocs" `
                    -ScriptPath $organizeDocsPath `
                    -Arguments "" `
                    -Trigger "Weekly" `
                    -Description "Organise les documents en sous-dossiers sÃ©mantiques"

Write-Host "`nConfiguration des tÃ¢ches planifiÃ©es terminÃ©e avec succÃ¨s!" -ForegroundColor Green
Write-Host "Les tÃ¢ches suivantes ont Ã©tÃ© crÃ©Ã©es:" -ForegroundColor Cyan
Write-Host "  - OrganizeScripts: ExÃ©cution hebdomadaire (dimanche Ã  3h00)" -ForegroundColor Cyan
Write-Host "  - OrganizeFolders: ExÃ©cution quotidienne (3h00)" -ForegroundColor Cyan
Write-Host "  - ManageLogs: ExÃ©cution quotidienne (3h00)" -ForegroundColor Cyan
Write-Host "  - OrganizeDocs: ExÃ©cution hebdomadaire (dimanche Ã  3h00)" -ForegroundColor Cyan

