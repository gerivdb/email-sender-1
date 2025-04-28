# Script pour configurer l'automatisation de l'organisation des fichiers
# Ce script configure les hooks Git et les tÃ¢ches planifiÃ©es

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
$organizeRepoPath = Join-Path -Path $projectPath -ChildPath "..\..\D"
$autoOrganizeFoldersPath = Join-Path -Path $projectPath -ChildPath "..\..\D"
$autoOrganizeWatcherPath = Join-Path -Path $projectPath -ChildPath "..\..\D"
$organizeDocsPath = Join-Path -Path $projectPath -ChildPath "..\..\D"
$manageLogsPath = Join-Path -Path $projectPath -ChildPath "..\..\D"

# VÃ©rifier si les scripts existent
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
    Write-Host "Veuillez crÃ©er ces scripts avant de continuer." -ForegroundColor Red
    exit
}

# Fonction pour configurer les hooks Git
function Initialize-GitHooks {
    param (
        [string]$ProjectRoot
    )
    $gitHooksDir = Join-Path -Path $ProjectRoot -ChildPath ".git\hooks"
    $customHooksDir = Join-Path -Path $ProjectRoot -ChildPath ".github\hooks"

    # VÃ©rifier si le dossier .git existe
    if (-not (Test-Path -Path (Join-Path -Path $ProjectRoot -ChildPath ".git"))) {
        Write-Host "Le dossier .git n'existe pas. Initialisation du dÃ©pÃ´t Git..." -ForegroundColor Yellow
        git init
    }

    # VÃ©rifier si le dossier .git\hooks existe
    if (-not (Test-Path -Path $gitHooksDir)) {
        Write-Host "Le dossier .git\hooks n'existe pas. CrÃ©ation du dossier..." -ForegroundColor Yellow
        New-Item -Path $gitHooksDir -ItemType Directory -Force | Out-Null
    }

    # VÃ©rifier si le dossier .github\hooks existe
    if (-not (Test-Path -Path $customHooksDir)) {
        Write-Host "Le dossier .github\hooks n'existe pas. CrÃ©ation du dossier..." -ForegroundColor Yellow
        New-Item -Path $customHooksDir -ItemType Directory -Force | Out-Null
    }

    # Copier le hook pre-commit
    $preCommitSource = Join-Path -Path $customHooksDir -ChildPath "pre-commit"
    $preCommitDest = Join-Path -Path $gitHooksDir -ChildPath "pre-commit"

    if (Test-Path -Path $preCommitSource) {
        Write-Host "Copie du hook pre-commit..." -ForegroundColor Yellow
        Copy-Item -Path $preCommitSource -Destination $preCommitDest -Force

        # Rendre le hook exÃ©cutable
        if ($IsLinux -or $IsMacOS) {
            chmod +x $preCommitDest
        }
    } else {
        Write-Host "Le hook pre-commit n'existe pas dans $customHooksDir" -ForegroundColor Red

        # CrÃ©er un hook pre-commit basique
        $preCommitContent = @"
#!/bin/sh
#
# Pre-commit hook pour organiser automatiquement les fichiers

# ExÃ©cuter le script d'organisation de la structure du dÃ©pÃ´t
powershell -File ./development/development/scripts/maintenance/repo/organize-repo-structure.ps1

# Ajouter les fichiers dÃ©placÃ©s au commit
git add .

# Continuer avec le commit
exit 0
"@

        Set-Content -Path $preCommitDest -Value $preCommitContent

        # Rendre le hook exÃ©cutable
        if ($IsLinux -or $IsMacOS) {
            chmod +x $preCommitDest
        }

        Write-Host "Hook pre-commit crÃ©Ã© dans $gitHooksDir" -ForegroundColor Green
    }
}

# Fonction pour crÃ©er une tÃ¢che planifiÃ©e
function New-AutoOrganizeTask {
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

# Fonction pour crÃ©er un service Windows pour le watcher
function New-WatcherService {
    param (
        [string]$ServiceName,
        [string]$ScriptPath
    )

    try {
        # Vérifier et utiliser la version de NSSM
        $nssmVersion = & $nssmPath version

        # Validation de version et logging
        if ($nssmVersion -match '(\d+\.\d+)') {
            $currentVersion = [version]$matches[1]
            Write-Host "Installation du service avec NSSM version $currentVersion" -ForegroundColor Green

            if ($currentVersion -lt [version]'2.24') {
                Write-Warning "Version NSSM $currentVersion détectée. Version 2.24 ou supérieure recommandée."
            }
        }

        # VÃ©rifier si le service existe dÃ©jÃ 
        $existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

        if ($existingService) {
            Write-Host "Le service '$ServiceName' existe dÃ©jÃ . Suppression du service existant..." -ForegroundColor Yellow
            Stop-Service -Name $ServiceName -Force
            sc.exe delete $ServiceName
        }

        # CrÃ©er un script wrapper pour le service
        $wrapperScriptPath = Join-Path -Path $projectPath -ChildPath "scripts\utils\automation\watcher-service-wrapper.ps1"
        $wrapperScriptContent = @"
# Script wrapper pour le service Auto Organize Watcher
Start-Transcript -Path "$projectPath\logs\watcher-service.log" -Append

# ExÃ©cuter le script de surveillance
& "$autoOrganizeWatcherPath" "$projectPath"
"@

        Set-Content -Path $wrapperScriptPath -Value $wrapperScriptContent

        # CrÃ©er le service avec NSSM (Non-Sucking Service Manager)
        # Note: NSSM doit Ãªtre installÃ© et disponible dans le PATH
        $nssmPath = "nssm.exe"

        try {
            # VÃ©rifier si NSSM est disponible et stocker la version dans une variable utilisÃ©e
            $nssmVersion = & $nssmPath version
            Write-Host "Version NSSM détectée : $nssmVersion" -ForegroundColor Green

            # Installer le service
            & $nssmPath install $ServiceName powershell.exe
            & $nssmPath set $ServiceName AppParameters "-NoProfile -ExecutionPolicy Bypass -File `"$wrapperScriptPath`""
            & $nssmPath set $ServiceName DisplayName $displayName
            & $nssmPath set $ServiceName Description $description
            & $nssmPath set $ServiceName AppDirectory $projectPath
            & $nssmPath set $ServiceName AppStdout "$projectPath\logs\watcher-service-stdout.log"
            & $nssmPath set $ServiceName AppStderr "$projectPath\logs\watcher-service-stderr.log"
            & $nssmPath set $ServiceName Start SERVICE_AUTO_START

            # DÃ©marrer le service
            Start-Service -Name $ServiceName

            Write-Host "Service '$ServiceName' crÃ©Ã© et dÃ©marrÃ© avec succÃ¨s." -ForegroundColor Green
        }
        catch {
            Write-Host "Impossible de crÃ©er le service. NSSM n'est pas installÃ© ou n'est pas disponible dans le PATH." -ForegroundColor Red
            Write-Host "Vous pouvez tÃ©lÃ©charger NSSM depuis http://nssm.cc/" -ForegroundColor Red
            Write-Host "CrÃ©ation d'une tÃ¢che planifiÃ©e Ã  la place..." -ForegroundColor Yellow

            # CrÃ©er une tÃ¢che planifiÃ©e Ã  la place
            Register-CustomScheduledTask -TaskName "AutoOrganizeWatcher" `
                                -ScriptPath $autoOrganizeWatcherPath `
                                -Arguments "$projectPath" `
                                -Trigger "AtLogon" `
                                -Description "Surveille et organise automatiquement les fichiers"
        }
    }
    catch {
        Write-Error "Erreur lors de l'installation du service : $_"
        throw
    }
}

# ExÃ©cution principale
Write-Host "Configuration de l'automatisation de l'organisation des fichiers..." -ForegroundColor Cyan

# Configurer les hooks Git
Write-Host "`nConfiguration des hooks Git..." -ForegroundColor Cyan
Initialize-GitHooks -ProjectRoot $projectPath

# CrÃ©er les tÃ¢ches planifiÃ©es
Write-Host "`nConfiguration des tÃ¢ches planifiÃ©es..." -ForegroundColor Cyan

# 1. TÃ¢che pour organiser la structure du dÃ©pÃ´t (quotidienne)
New-AutoOrganizeTask -TaskName "OrganizeRepoStructure" `
                    -ScriptPath $organizeRepoPath `
                    -Arguments "" `
                    -Trigger "Daily" `
                    -Description "Organise la structure du dÃ©pÃ´t"

# 2. TÃ¢che pour organiser les dossiers (quotidienne)
New-AutoOrganizeTask -TaskName "OrganizeFolders" `
                    -ScriptPath $autoOrganizeFoldersPath `
                    -Arguments "-MaxFilesPerFolder 15" `
                    -Trigger "Daily" `
                    -Description "Organise les dossiers contenant trop de fichiers"

# 3. TÃ¢che pour organiser les documents (hebdomadaire)
New-AutoOrganizeTask -TaskName "OrganizeDocs" `
                    -ScriptPath $organizeDocsPath `
                    -Arguments "" `
                    -Trigger "Weekly" `
                    -Description "Organise les documents en sous-dossiers sÃ©mantiques"

# 4. TÃ¢che pour gÃ©rer les logs (quotidienne)
New-AutoOrganizeTask -TaskName "ManageLogs" `
                    -ScriptPath $manageLogsPath `
                    -Arguments "daily-log scripts" `
                    -Trigger "Daily" `
                    -Description "GÃ¨re les logs par unitÃ© de temps"

# CrÃ©er le service de surveillance
Write-Host "`nConfiguration du service de surveillance..." -ForegroundColor Cyan
New-WatcherService -ServiceName "AutoOrganizeWatcher" -ScriptPath $autoOrganizeWatcherPath

Write-Host "`nConfiguration de l'automatisation terminÃ©e avec succÃ¨s!" -ForegroundColor Green
Write-Host "Les tÃ¢ches suivantes ont Ã©tÃ© crÃ©Ã©es:" -ForegroundColor Cyan
Write-Host "  - OrganizeRepoStructure: ExÃ©cution quotidienne (3h00)" -ForegroundColor Cyan
Write-Host "  - OrganizeFolders: ExÃ©cution quotidienne (3h00)" -ForegroundColor Cyan
Write-Host "  - OrganizeDocs: ExÃ©cution hebdomadaire (dimanche Ã  3h00)" -ForegroundColor Cyan
Write-Host "  - ManageLogs: ExÃ©cution quotidienne (3h00)" -ForegroundColor Cyan
Write-Host "  - AutoOrganizeWatcher: Service ou tÃ¢che au dÃ©marrage" -ForegroundColor Cyan

Write-Host "`nPour appliquer immÃ©diatement l'organisation, exÃ©cutez:" -ForegroundColor Yellow
Write-Host "  powershell -File $organizeRepoPath" -ForegroundColor Yellow




