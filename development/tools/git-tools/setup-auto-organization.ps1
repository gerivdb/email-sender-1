# Script pour configurer l'automatisation de l'organisation des fichiers
# Ce script configure les hooks Git et les tÃƒÂ¢ches planifiÃƒÂ©es

# VÃƒÂ©rifier si le script est exÃƒÂ©cutÃƒÂ© en tant qu'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Ce script doit ÃƒÂªtre exÃƒÂ©cutÃƒÂ© en tant qu'administrateur pour crÃƒÂ©er des tÃƒÂ¢ches planifiÃƒÂ©es." -ForegroundColor Red
    Write-Host "Veuillez relancer le script avec des privilÃƒÂ¨ges d'administrateur." -ForegroundColor Red
    exit
}

# Obtenir le chemin absolu du rÃƒÂ©pertoire du projet
$projectPath = (Get-Location).Path

# CrÃƒÂ©er les chemins absolus vers les scripts
$organizeRepoPath = Join-Path -Path $projectPath -ChildPath "..\..\D"
$autoOrganizeFoldersPath = Join-Path -Path $projectPath -ChildPath "..\..\D"
$autoOrganizeWatcherPath = Join-Path -Path $projectPath -ChildPath "..\..\D"
$organizeDocsPath = Join-Path -Path $projectPath -ChildPath "..\..\D"
$manageLogsPath = Join-Path -Path $projectPath -ChildPath "..\..\D"

# VÃƒÂ©rifier si les scripts existent
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
    Write-Host "Veuillez crÃƒÂ©er ces scripts avant de continuer." -ForegroundColor Red
    exit
}

# Fonction pour configurer les hooks Git
function Initialize-GitHooks {
    param (
        [string]$ProjectRoot
    )
    $gitHooksDir = Join-Path -Path $ProjectRoot -ChildPath ".git\hooks"
    $customHooksDir = Join-Path -Path $ProjectRoot -ChildPath ".github\hooks"

    # VÃƒÂ©rifier si le dossier .git existe
    if (-not (Test-Path -Path (Join-Path -Path $ProjectRoot -ChildPath ".git"))) {
        Write-Host "Le dossier .git n'existe pas. Initialisation du dÃƒÂ©pÃƒÂ´t Git..." -ForegroundColor Yellow
        git init
    }

    # VÃƒÂ©rifier si le dossier .git\hooks existe
    if (-not (Test-Path -Path $gitHooksDir)) {
        Write-Host "Le dossier .git\hooks n'existe pas. CrÃƒÂ©ation du dossier..." -ForegroundColor Yellow
        New-Item -Path $gitHooksDir -ItemType Directory -Force | Out-Null
    }

    # VÃƒÂ©rifier si le dossier .github\hooks existe
    if (-not (Test-Path -Path $customHooksDir)) {
        Write-Host "Le dossier .github\hooks n'existe pas. CrÃƒÂ©ation du dossier..." -ForegroundColor Yellow
        New-Item -Path $customHooksDir -ItemType Directory -Force | Out-Null
    }

    # Copier le hook pre-commit
    $preCommitSource = Join-Path -Path $customHooksDir -ChildPath "pre-commit"
    $preCommitDest = Join-Path -Path $gitHooksDir -ChildPath "pre-commit"

    if (Test-Path -Path $preCommitSource) {
        Write-Host "Copie du hook pre-commit..." -ForegroundColor Yellow
        Copy-Item -Path $preCommitSource -Destination $preCommitDest -Force

        # Rendre le hook exÃƒÂ©cutable
        if ($IsLinux -or $IsMacOS) {
            chmod +x $preCommitDest
        }
    } else {
        Write-Host "Le hook pre-commit n'existe pas dans $customHooksDir" -ForegroundColor Red

        # CrÃƒÂ©er un hook pre-commit basique
        $preCommitContent = @"
#!/bin/sh
#
# Pre-commit hook pour organiser automatiquement les fichiers

# ExÃƒÂ©cuter le script d'organisation de la structure du dÃƒÂ©pÃƒÂ´t
powershell -File ./development/development/scripts/maintenance/repo/organize-repo-structure.ps1

# Ajouter les fichiers dÃƒÂ©placÃƒÂ©s au commit
git add .

# Continuer avec le commit
exit 0
"@

        Set-Content -Path $preCommitDest -Value $preCommitContent

        # Rendre le hook exÃƒÂ©cutable
        if ($IsLinux -or $IsMacOS) {
            chmod +x $preCommitDest
        }

        Write-Host "Hook pre-commit crÃƒÂ©ÃƒÂ© dans $gitHooksDir" -ForegroundColor Green
    }
}

# Fonction pour crÃƒÂ©er une tÃƒÂ¢che planifiÃƒÂ©e
function New-AutoOrganizeTask {
    param (
        [string]$TaskName,
        [string]$ScriptPath,
        [string]$Arguments,
        [string]$Trigger,
        [string]$Description
    )

    # VÃƒÂ©rifier si la tÃƒÂ¢che existe dÃƒÂ©jÃƒÂ 
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    if ($existingTask) {
        Write-Host "La tÃƒÂ¢che '$TaskName' existe dÃƒÂ©jÃƒÂ . Suppression de la tÃƒÂ¢che existante..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    # CrÃƒÂ©er l'action
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" $Arguments" -WorkingDirectory $projectPath

    # CrÃƒÂ©er le dÃƒÂ©clencheur
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
            # Ajouter une rÃƒÂ©pÃƒÂ©tition toutes les heures
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

    # Ajouter la rÃƒÂ©pÃƒÂ©tition si nÃƒÂ©cessaire
    if ($Trigger -eq "Hourly") {
        $scheduledTaskTrigger.Repetition = $repetitionParams
    }

    # CrÃƒÂ©er les paramÃƒÂ¨tres principaux
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # CrÃƒÂ©er les paramÃƒÂ¨tres
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -WakeToRun

    # CrÃƒÂ©er la tÃƒÂ¢che
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $scheduledTaskTrigger -Principal $principal -Settings $settings -Description $Description

    Write-Host "TÃƒÂ¢che planifiÃƒÂ©e '$TaskName' crÃƒÂ©ÃƒÂ©e avec succÃƒÂ¨s." -ForegroundColor Green
}

# Fonction pour crÃƒÂ©er un service Windows pour le watcher
function New-WatcherService {
    param (
        [string]$ServiceName,
        [string]$ScriptPath
    )

    try {
        # VÃ©rifier et utiliser la version de NSSM
        $nssmVersion = & $nssmPath version

        # Validation de version et logging
        if ($nssmVersion -match '(\d+\.\d+)') {
            $currentVersion = [version]$matches[1]
            Write-Host "Installation du service avec NSSM version $currentVersion" -ForegroundColor Green

            if ($currentVersion -lt [version]'2.24') {
                Write-Warning "Version NSSM $currentVersion dÃ©tectÃ©e. Version 2.24 ou supÃ©rieure recommandÃ©e."
            }
        }

        # VÃƒÂ©rifier si le service existe dÃƒÂ©jÃƒÂ 
        $existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

        if ($existingService) {
            Write-Host "Le service '$ServiceName' existe dÃƒÂ©jÃƒÂ . Suppression du service existant..." -ForegroundColor Yellow
            Stop-Service -Name $ServiceName -Force
            sc.exe delete $ServiceName
        }

        # CrÃƒÂ©er un script wrapper pour le service
        $wrapperScriptPath = Join-Path -Path $projectPath -ChildPath "scripts\utils\automation\watcher-service-wrapper.ps1"
        $wrapperScriptContent = @"
# Script wrapper pour le service Auto Organize Watcher
Start-Transcript -Path "$projectPath\logs\watcher-service.log" -Append

# ExÃƒÂ©cuter le script de surveillance
& "$autoOrganizeWatcherPath" "$projectPath"
"@

        Set-Content -Path $wrapperScriptPath -Value $wrapperScriptContent

        # CrÃƒÂ©er le service avec NSSM (Non-Sucking Service Manager)
        # Note: NSSM doit ÃƒÂªtre installÃƒÂ© et disponible dans le PATH
        $nssmPath = "nssm.exe"

        try {
            # VÃƒÂ©rifier si NSSM est disponible et stocker la version dans une variable utilisÃƒÂ©e
            $nssmVersion = & $nssmPath version
            Write-Host "Version NSSM dÃ©tectÃ©e : $nssmVersion" -ForegroundColor Green

            # Installer le service
            & $nssmPath install $ServiceName powershell.exe
            & $nssmPath set $ServiceName AppParameters "-NoProfile -ExecutionPolicy Bypass -File `"$wrapperScriptPath`""
            & $nssmPath set $ServiceName DisplayName $displayName
            & $nssmPath set $ServiceName Description $description
            & $nssmPath set $ServiceName AppDirectory $projectPath
            & $nssmPath set $ServiceName AppStdout "$projectPath\logs\watcher-service-stdout.log"
            & $nssmPath set $ServiceName AppStderr "$projectPath\logs\watcher-service-stderr.log"
            & $nssmPath set $ServiceName Start SERVICE_AUTO_START

            # DÃƒÂ©marrer le service
            Start-Service -Name $ServiceName

            Write-Host "Service '$ServiceName' crÃƒÂ©ÃƒÂ© et dÃƒÂ©marrÃƒÂ© avec succÃƒÂ¨s." -ForegroundColor Green
        }
        catch {
            Write-Host "Impossible de crÃƒÂ©er le service. NSSM n'est pas installÃƒÂ© ou n'est pas disponible dans le PATH." -ForegroundColor Red
            Write-Host "Vous pouvez tÃƒÂ©lÃƒÂ©charger NSSM depuis http://nssm.cc/" -ForegroundColor Red
            Write-Host "CrÃƒÂ©ation d'une tÃƒÂ¢che planifiÃƒÂ©e ÃƒÂ  la place..." -ForegroundColor Yellow

            # CrÃƒÂ©er une tÃƒÂ¢che planifiÃƒÂ©e ÃƒÂ  la place
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

# ExÃƒÂ©cution principale
Write-Host "Configuration de l'automatisation de l'organisation des fichiers..." -ForegroundColor Cyan

# Configurer les hooks Git
Write-Host "`nConfiguration des hooks Git..." -ForegroundColor Cyan
Initialize-GitHooks -ProjectRoot $projectPath

# CrÃƒÂ©er les tÃƒÂ¢ches planifiÃƒÂ©es
Write-Host "`nConfiguration des tÃƒÂ¢ches planifiÃƒÂ©es..." -ForegroundColor Cyan

# 1. TÃƒÂ¢che pour organiser la structure du dÃƒÂ©pÃƒÂ´t (quotidienne)
New-AutoOrganizeTask -TaskName "OrganizeRepoStructure" `
                    -ScriptPath $organizeRepoPath `
                    -Arguments "" `
                    -Trigger "Daily" `
                    -Description "Organise la structure du dÃƒÂ©pÃƒÂ´t"

# 2. TÃƒÂ¢che pour organiser les dossiers (quotidienne)
New-AutoOrganizeTask -TaskName "OrganizeFolders" `
                    -ScriptPath $autoOrganizeFoldersPath `
                    -Arguments "-MaxFilesPerFolder 15" `
                    -Trigger "Daily" `
                    -Description "Organise les dossiers contenant trop de fichiers"

# 3. TÃƒÂ¢che pour organiser les documents (hebdomadaire)
New-AutoOrganizeTask -TaskName "OrganizeDocs" `
                    -ScriptPath $organizeDocsPath `
                    -Arguments "" `
                    -Trigger "Weekly" `
                    -Description "Organise les documents en sous-dossiers sÃƒÂ©mantiques"

# 4. TÃƒÂ¢che pour gÃƒÂ©rer les logs (quotidienne)
New-AutoOrganizeTask -TaskName "ManageLogs" `
                    -ScriptPath $manageLogsPath `
                    -Arguments "daily-log scripts" `
                    -Trigger "Daily" `
                    -Description "GÃƒÂ¨re les logs par unitÃƒÂ© de temps"

# CrÃƒÂ©er le service de surveillance
Write-Host "`nConfiguration du service de surveillance..." -ForegroundColor Cyan
New-WatcherService -ServiceName "AutoOrganizeWatcher" -ScriptPath $autoOrganizeWatcherPath

Write-Host "`nConfiguration de l'automatisation terminÃƒÂ©e avec succÃƒÂ¨s!" -ForegroundColor Green
Write-Host "Les tÃƒÂ¢ches suivantes ont ÃƒÂ©tÃƒÂ© crÃƒÂ©ÃƒÂ©es:" -ForegroundColor Cyan
Write-Host "  - OrganizeRepoStructure: ExÃƒÂ©cution quotidienne (3h00)" -ForegroundColor Cyan
Write-Host "  - OrganizeFolders: ExÃƒÂ©cution quotidienne (3h00)" -ForegroundColor Cyan
Write-Host "  - OrganizeDocs: ExÃƒÂ©cution hebdomadaire (dimanche ÃƒÂ  3h00)" -ForegroundColor Cyan
Write-Host "  - ManageLogs: ExÃƒÂ©cution quotidienne (3h00)" -ForegroundColor Cyan
Write-Host "  - AutoOrganizeWatcher: Service ou tÃƒÂ¢che au dÃƒÂ©marrage" -ForegroundColor Cyan

Write-Host "`nPour appliquer immÃƒÂ©diatement l'organisation, exÃƒÂ©cutez:" -ForegroundColor Yellow
Write-Host "  powershell -File $organizeRepoPath" -ForegroundColor Yellow




