# Script pour configurer l'automatisation de l'organisation des fichiers
# Ce script configure les hooks Git et les tâches planifiées

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
$organizeRepoPath = Join-Path -Path $projectPath -ChildPath "scripts\maintenance\repo\organize-repo-structure.ps1"
$autoOrganizeFoldersPath = Join-Path -Path $projectPath -ChildPath "scripts\utils\automation\auto-organize-folders.ps1"
$autoOrganizeWatcherPath = Join-Path -Path $projectPath -ChildPath "scripts\utils\automation\auto-organize-watcher.ps1"
$organizeDocsPath = Join-Path -Path $projectPath -ChildPath "scripts\utils\automation\organize-docs-fixed.ps1"
$manageLogsPath = Join-Path -Path $projectPath -ChildPath "scripts\utils\automation\manage-logs.ps1"

# Vérifier si les scripts existent
$missingScripts = @()

if (-not (Test-Path -Path $organizeRepoPath)) {
    $missingScripts += "organize-repo-structure.ps1"
}

if (-not (Test-Path -Path $autoOrganizeFoldersPath)) {
    $missingScripts += "auto-organize-folders.ps1"
}

if (-not (Test-Path -Path $autoOrganizeWatcherPath)) {
    $missingScripts += "auto-organize-watcher.ps1"
}

if (-not (Test-Path -Path $organizeDocsPath)) {
    $missingScripts += "organize-docs-fixed.ps1"
}

if (-not (Test-Path -Path $manageLogsPath)) {
    $missingScripts += "manage-logs.ps1"
}

if ($missingScripts.Count -gt 0) {
    Write-Host "Les scripts suivants sont manquants:" -ForegroundColor Red
    foreach ($script in $missingScripts) {
        Write-Host "  - $script" -ForegroundColor Red
    }
    Write-Host "Veuillez créer ces scripts avant de continuer." -ForegroundColor Red
    exit
}

# Fonction pour configurer les hooks Git
function Setup-GitHooks {
    $gitHooksDir = Join-Path -Path $projectPath -ChildPath ".git\hooks"
    $customHooksDir = Join-Path -Path $projectPath -ChildPath ".github\hooks"
    
    # Vérifier si le dossier .git existe
    if (-not (Test-Path -Path (Join-Path -Path $projectPath -ChildPath ".git"))) {
        Write-Host "Le dossier .git n'existe pas. Initialisation du dépôt Git..." -ForegroundColor Yellow
        git init
    }
    
    # Vérifier si le dossier .git\hooks existe
    if (-not (Test-Path -Path $gitHooksDir)) {
        Write-Host "Le dossier .git\hooks n'existe pas. Création du dossier..." -ForegroundColor Yellow
        New-Item -Path $gitHooksDir -ItemType Directory -Force | Out-Null
    }
    
    # Vérifier si le dossier .github\hooks existe
    if (-not (Test-Path -Path $customHooksDir)) {
        Write-Host "Le dossier .github\hooks n'existe pas. Création du dossier..." -ForegroundColor Yellow
        New-Item -Path $customHooksDir -ItemType Directory -Force | Out-Null
    }
    
    # Copier le hook pre-commit
    $preCommitSource = Join-Path -Path $customHooksDir -ChildPath "pre-commit"
    $preCommitDest = Join-Path -Path $gitHooksDir -ChildPath "pre-commit"
    
    if (Test-Path -Path $preCommitSource) {
        Write-Host "Copie du hook pre-commit..." -ForegroundColor Yellow
        Copy-Item -Path $preCommitSource -Destination $preCommitDest -Force
        
        # Rendre le hook exécutable
        if ($IsLinux -or $IsMacOS) {
            chmod +x $preCommitDest
        }
    } else {
        Write-Host "Le hook pre-commit n'existe pas dans $customHooksDir" -ForegroundColor Red
        
        # Créer un hook pre-commit basique
        $preCommitContent = @"
#!/bin/sh
#
# Pre-commit hook pour organiser automatiquement les fichiers

# Exécuter le script d'organisation de la structure du dépôt
powershell -File ./scripts/maintenance/repo/organize-repo-structure.ps1

# Ajouter les fichiers déplacés au commit
git add .

# Continuer avec le commit
exit 0
"@
        
        Set-Content -Path $preCommitDest -Value $preCommitContent
        
        # Rendre le hook exécutable
        if ($IsLinux -or $IsMacOS) {
            chmod +x $preCommitDest
        }
        
        Write-Host "Hook pre-commit créé dans $gitHooksDir" -ForegroundColor Green
    }
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
        "AtLogon" {
            $triggerParams = @{
                AtLogOn = $true
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

# Fonction pour créer un service Windows pour le watcher
function Create-WatcherService {
    $serviceName = "AutoOrganizeWatcher"
    $displayName = "Auto Organize Watcher"
    $description = "Service pour surveiller et organiser automatiquement les fichiers"
    
    # Vérifier si le service existe déjà
    $existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    
    if ($existingService) {
        Write-Host "Le service '$serviceName' existe déjà. Suppression du service existant..." -ForegroundColor Yellow
        Stop-Service -Name $serviceName -Force
        sc.exe delete $serviceName
    }
    
    # Créer un script wrapper pour le service
    $wrapperScriptPath = Join-Path -Path $projectPath -ChildPath "scripts\utils\automation\watcher-service-wrapper.ps1"
    $wrapperScriptContent = @"
# Script wrapper pour le service Auto Organize Watcher
Start-Transcript -Path "$projectPath\logs\watcher-service.log" -Append

# Exécuter le script de surveillance
& "$autoOrganizeWatcherPath" "$projectPath"
"@
    
    Set-Content -Path $wrapperScriptPath -Value $wrapperScriptContent
    
    # Créer le service avec NSSM (Non-Sucking Service Manager)
    # Note: NSSM doit être installé et disponible dans le PATH
    $nssmPath = "nssm.exe"
    
    try {
        # Vérifier si NSSM est disponible
        $nssmVersion = & $nssmPath version
        
        # Installer le service
        & $nssmPath install $serviceName powershell.exe
        & $nssmPath set $serviceName AppParameters "-NoProfile -ExecutionPolicy Bypass -File `"$wrapperScriptPath`""
        & $nssmPath set $serviceName DisplayName $displayName
        & $nssmPath set $serviceName Description $description
        & $nssmPath set $serviceName AppDirectory $projectPath
        & $nssmPath set $serviceName AppStdout "$projectPath\logs\watcher-service-stdout.log"
        & $nssmPath set $serviceName AppStderr "$projectPath\logs\watcher-service-stderr.log"
        & $nssmPath set $serviceName Start SERVICE_AUTO_START
        
        # Démarrer le service
        Start-Service -Name $serviceName
        
        Write-Host "Service '$serviceName' créé et démarré avec succès." -ForegroundColor Green
    }
    catch {
        Write-Host "Impossible de créer le service. NSSM n'est pas installé ou n'est pas disponible dans le PATH." -ForegroundColor Red
        Write-Host "Vous pouvez télécharger NSSM depuis http://nssm.cc/" -ForegroundColor Red
        Write-Host "Création d'une tâche planifiée à la place..." -ForegroundColor Yellow
        
        # Créer une tâche planifiée à la place
        Create-ScheduledTask -TaskName "AutoOrganizeWatcher" `
                            -ScriptPath $autoOrganizeWatcherPath `
                            -Arguments "$projectPath" `
                            -Trigger "AtLogon" `
                            -Description "Surveille et organise automatiquement les fichiers"
    }
}

# Exécution principale
Write-Host "Configuration de l'automatisation de l'organisation des fichiers..." -ForegroundColor Cyan

# Configurer les hooks Git
Write-Host "`nConfiguration des hooks Git..." -ForegroundColor Cyan
Setup-GitHooks

# Créer les tâches planifiées
Write-Host "`nConfiguration des tâches planifiées..." -ForegroundColor Cyan

# 1. Tâche pour organiser la structure du dépôt (quotidienne)
Create-ScheduledTask -TaskName "OrganizeRepoStructure" `
                    -ScriptPath $organizeRepoPath `
                    -Arguments "" `
                    -Trigger "Daily" `
                    -Description "Organise la structure du dépôt"

# 2. Tâche pour organiser les dossiers (quotidienne)
Create-ScheduledTask -TaskName "OrganizeFolders" `
                    -ScriptPath $autoOrganizeFoldersPath `
                    -Arguments "-MaxFilesPerFolder 15" `
                    -Trigger "Daily" `
                    -Description "Organise les dossiers contenant trop de fichiers"

# 3. Tâche pour organiser les documents (hebdomadaire)
Create-ScheduledTask -TaskName "OrganizeDocs" `
                    -ScriptPath $organizeDocsPath `
                    -Arguments "" `
                    -Trigger "Weekly" `
                    -Description "Organise les documents en sous-dossiers sémantiques"

# 4. Tâche pour gérer les logs (quotidienne)
Create-ScheduledTask -TaskName "ManageLogs" `
                    -ScriptPath $manageLogsPath `
                    -Arguments "daily-log scripts" `
                    -Trigger "Daily" `
                    -Description "Gère les logs par unité de temps"

# Créer le service de surveillance
Write-Host "`nConfiguration du service de surveillance..." -ForegroundColor Cyan
Create-WatcherService

Write-Host "`nConfiguration de l'automatisation terminée avec succès!" -ForegroundColor Green
Write-Host "Les tâches suivantes ont été créées:" -ForegroundColor Cyan
Write-Host "  - OrganizeRepoStructure: Exécution quotidienne (3h00)" -ForegroundColor Cyan
Write-Host "  - OrganizeFolders: Exécution quotidienne (3h00)" -ForegroundColor Cyan
Write-Host "  - OrganizeDocs: Exécution hebdomadaire (dimanche à 3h00)" -ForegroundColor Cyan
Write-Host "  - ManageLogs: Exécution quotidienne (3h00)" -ForegroundColor Cyan
Write-Host "  - AutoOrganizeWatcher: Service ou tâche au démarrage" -ForegroundColor Cyan

Write-Host "`nPour appliquer immédiatement l'organisation, exécutez:" -ForegroundColor Yellow
Write-Host "  powershell -File $organizeRepoPath" -ForegroundColor Yellow
