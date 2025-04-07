# Deploy-TaskDetection.ps1
# Script pour dÃ©ployer le systÃ¨me de dÃ©tection automatique des tÃ¢ches

param (
    [Parameter(Mandatory = $false)]
    [string]$ConversationsFolder = ".\conversations",

    [Parameter(Mandatory = $false)]
    [switch]$AutoStart,

    [Parameter(Mandatory = $false)]
    [switch]$AddToRoadmap,

    [Parameter(Mandatory = $false)]
    [switch]$CreateShortcuts,

    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Chemins des fichiers
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$integrateTaskDetectionPath = Join-Path -Path $scriptPath -ChildPath "Integrate-TaskDetection.ps1"
$watchConversationsPath = Join-Path -Path $scriptPath -ChildPath "Watch-Conversations.ps1"
$confirmTasksPath = Join-Path -Path $scriptPath -ChildPath "Confirm-Tasks.ps1"
$showTaskLogsPath = Join-Path -Path $scriptPath -ChildPath "Show-TaskLogs.ps1"
$runTestsPath = Join-Path -Path $scriptPath -ChildPath "Run-Tests.ps1"
$deploymentLogPath = Join-Path -Path $scriptPath -ChildPath "deployment-log.txt"

# Fonction pour journaliser une action
function Write-ActionLog {
    param (
        [string]$Action,
        [string]$Status,
        [string]$Details
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Action : $Status : $Details"

    if (-not (Test-Path -Path $deploymentLogPath)) {
        New-Item -Path $deploymentLogPath -ItemType File -Force | Out-Null
    }

    Add-Content -Path $deploymentLogPath -Value $logEntry

    switch ($Status) {
        "SUCCESS" { Write-Host "  $Action : $Details" -ForegroundColor Green }
        "WARNING" { Write-Host "  $Action : $Details" -ForegroundColor Yellow }
        "ERROR" { Write-Host "  $Action : $Details" -ForegroundColor Red }
        default { Write-Host "  $Action : $Details" }
    }
}

# Fonction pour vÃ©rifier les prÃ©requis
function Test-Prerequisites {
    $prerequisites = @(
        @{ Name = "PowerShell 5.1+"; Check = { $PSVersionTable.PSVersion.Major -ge 5 } },
        @{ Name = "AccÃ¨s en Ã©criture"; Check = { Test-Path -Path $scriptPath -PathType Container -IsValid } },
        @{ Name = "Scripts PowerShell"; Check = { Test-Path -Path $integrateTaskDetectionPath -PathType Leaf } }
    )

    $allPrerequisitesMet = $true

    Write-Host "VÃ©rification des prÃ©requis :"

    foreach ($prerequisite in $prerequisites) {
        $result = & $prerequisite.Check

        if ($result) {
            Write-ActionLog -Action "PrÃ©requis" -Status "SUCCESS" -Details "$($prerequisite.Name) : OK"
        }
        else {
            Write-ActionLog -Action "PrÃ©requis" -Status "ERROR" -Details "$($prerequisite.Name) : NON"
            $allPrerequisitesMet = $false
        }
    }

    return $allPrerequisitesMet
}

# Fonction pour crÃ©er les dossiers nÃ©cessaires
function New-RequiredFolders {
    $folders = @(
        @{ Path = $ConversationsFolder; Description = "Dossier de conversations" },
        @{ Path = (Join-Path -Path $scriptPath -ChildPath "tests"); Description = "Dossier de tests" }
    )

    Write-Host "CrÃ©ation des dossiers nÃ©cessaires :"

    foreach ($folder in $folders) {
        if (-not (Test-Path -Path $folder.Path)) {
            try {
                New-Item -Path $folder.Path -ItemType Directory -Force | Out-Null
                Write-ActionLog -Action "CrÃ©ation de dossier" -Status "SUCCESS" -Details "$($folder.Description) : $($folder.Path)"
            }
            catch {
                Write-ActionLog -Action "CrÃ©ation de dossier" -Status "ERROR" -Details "$($folder.Description) : $($folder.Path) : $_"
            }
        }
        else {
            Write-ActionLog -Action "CrÃ©ation de dossier" -Status "SUCCESS" -Details "$($folder.Description) : $($folder.Path) (dÃ©jÃ  existant)"
        }
    }
}

# Fonction pour intÃ©grer le systÃ¨me
function Initialize-System {
    Write-Host "IntÃ©gration du systÃ¨me :"

    $verboseParam = if ($Verbose) { "-Verbose" } else { "" }
    $processExistingParam = "-ProcessExisting"
    $addToRoadmapParam = if ($AddToRoadmap) { "-AddToRoadmap" } else { "" }

    $command = "powershell -ExecutionPolicy Bypass -File `"$integrateTaskDetectionPath`" -ConversationsFolder `"$ConversationsFolder`" $processExistingParam $addToRoadmapParam $verboseParam"

    try {
        Invoke-Expression $command
        Write-ActionLog -Action "IntÃ©gration" -Status "SUCCESS" -Details "SystÃ¨me intÃ©grÃ© avec succÃ¨s"
        return $true
    }
    catch {
        Write-ActionLog -Action "IntÃ©gration" -Status "ERROR" -Details "Erreur lors de l'intÃ©gration du systÃ¨me : $_"
        return $false
    }
}

# Fonction pour exÃ©cuter les tests
function Invoke-SystemTests {
    Write-Host "ExÃ©cution des tests :"

    $verboseParam = if ($Verbose) { "-Verbose" } else { "" }

    $command = "powershell -ExecutionPolicy Bypass -File `"$runTestsPath`" $verboseParam"

    try {
        Invoke-Expression $command
        Write-ActionLog -Action "Tests" -Status "SUCCESS" -Details "Tests exÃ©cutÃ©s avec succÃ¨s"
        return $true
    }
    catch {
        Write-ActionLog -Action "Tests" -Status "ERROR" -Details "Erreur lors de l'exÃ©cution des tests : $_"
        return $false
    }
}

# Fonction pour crÃ©er des raccourcis
function New-SystemShortcuts {
    if (-not $CreateShortcuts) {
        return
    }

    Write-Host "CrÃ©ation des raccourcis :"

    $shortcuts = @(
        @{ Name = "Surveiller les conversations"; Script = $watchConversationsPath; Arguments = "-ConversationsFolder `"$ConversationsFolder`" -AddToRoadmap" },
        @{ Name = "Confirmer les tÃ¢ches"; Script = $confirmTasksPath; Arguments = "" },
        @{ Name = "Afficher les journaux"; Script = $showTaskLogsPath; Arguments = "" }
    )

    $desktopPath = [System.Environment]::GetFolderPath("Desktop")

    foreach ($shortcut in $shortcuts) {
        $shortcutPath = Join-Path -Path $desktopPath -ChildPath "$($shortcut.Name).lnk"

        try {
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($shortcutPath)
            $Shortcut.TargetPath = "powershell.exe"
            $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$($shortcut.Script)`" $($shortcut.Arguments)"
            $Shortcut.WorkingDirectory = $scriptPath
            $Shortcut.Save()

            Write-ActionLog -Action "Raccourci" -Status "SUCCESS" -Details "$($shortcut.Name) : $shortcutPath"
        }
        catch {
            Write-ActionLog -Action "Raccourci" -Status "ERROR" -Details "$($shortcut.Name) : $shortcutPath : $_"
        }
    }
}

# Fonction pour dÃ©marrer automatiquement la surveillance
function Start-SystemWatcher {
    if (-not $AutoStart) {
        return
    }

    Write-Host "DÃ©marrage de la surveillance :"

    $verboseParam = if ($Verbose) { "-Verbose" } else { "" }
    $addToRoadmapParam = if ($AddToRoadmap) { "-AddToRoadmap" } else { "" }

    try {
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$watchConversationsPath`" -ConversationsFolder `"$ConversationsFolder`" $addToRoadmapParam $verboseParam"
        Write-ActionLog -Action "Surveillance" -Status "SUCCESS" -Details "Surveillance dÃ©marrÃ©e avec succÃ¨s"
    }
    catch {
        Write-ActionLog -Action "Surveillance" -Status "ERROR" -Details "Erreur lors du dÃ©marrage de la surveillance : $_"
    }
}

# Fonction pour afficher le rÃ©sumÃ© du dÃ©ploiement
function Show-DeploymentSummary {
    Write-Host ""
    Write-Host "RÃ©sumÃ© du dÃ©ploiement :"
    Write-Host "  Dossier de conversations : $ConversationsFolder"
    Write-Host "  Ajout automatique Ã  la roadmap : $AddToRoadmap"
    Write-Host "  DÃ©marrage automatique : $AutoStart"
    Write-Host "  CrÃ©ation de raccourcis : $CreateShortcuts"
    Write-Host ""
    Write-Host "Pour dÃ©marrer la surveillance des conversations :"
    Write-Host "  .\Watch-Conversations.ps1 -ConversationsFolder `"$ConversationsFolder`" -AddToRoadmap"
    Write-Host ""
    Write-Host "Pour confirmer les tÃ¢ches dÃ©tectÃ©es :"
    Write-Host "  .\Confirm-Tasks.ps1"
    Write-Host ""
    Write-Host "Pour afficher les journaux :"
    Write-Host "  .\Show-TaskLogs.ps1"
    Write-Host ""
    Write-Host "Journal de dÃ©ploiement : $deploymentLogPath"
}

# Fonction principale
function Main {
    Write-Host "DÃ©ploiement du systÃ¨me de dÃ©tection automatique des tÃ¢ches"
    Write-Host ""

    # VÃ©rifier les prÃ©requis
    $prerequisitesMet = Test-Prerequisites

    if (-not $prerequisitesMet) {
        Write-Host ""
        Write-Host "Certains prÃ©requis ne sont pas satisfaits. Veuillez les corriger avant de continuer." -ForegroundColor Red
        exit 1
    }

    Write-Host ""

    # CrÃ©er les dossiers nÃ©cessaires
    New-RequiredFolders

    Write-Host ""

    # IntÃ©grer le systÃ¨me
    $integrationSuccess = Initialize-System

    if (-not $integrationSuccess) {
        Write-Host ""
        Write-Host "L'intÃ©gration du systÃ¨me a Ã©chouÃ©. Veuillez consulter le journal de dÃ©ploiement pour plus de dÃ©tails." -ForegroundColor Red
        exit 1
    }

    Write-Host ""

    # ExÃ©cuter les tests
    $testsSuccess = Invoke-SystemTests

    if (-not $testsSuccess) {
        Write-Host ""
        Write-Host "Les tests ont Ã©chouÃ©. Veuillez consulter le journal de dÃ©ploiement pour plus de dÃ©tails." -ForegroundColor Yellow
    }

    Write-Host ""

    # CrÃ©er des raccourcis
    New-SystemShortcuts

    # DÃ©marrer automatiquement la surveillance
    Start-SystemWatcher

    # Afficher le rÃ©sumÃ© du dÃ©ploiement
    Show-DeploymentSummary
}

# ExÃ©cuter la fonction principale
Main
