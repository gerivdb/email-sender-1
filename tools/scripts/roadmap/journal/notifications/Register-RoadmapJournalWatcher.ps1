﻿#Requires -Version 5.1
<#
.SYNOPSIS
    Surveille les modifications de la roadmap et met Ã  jour le journal.
.DESCRIPTION
    Ce script utilise FileSystemWatcher pour surveiller les modifications
    du fichier de roadmap et met Ã  jour automatiquement le journal.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-16
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$RoadmapPath = "Roadmap\roadmap_final.md",
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableNotifications,
    
    [Parameter(Mandatory=$false)]
    [int]$ThrottleSeconds = 10
)

# Importer le module de gestion du journal
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\RoadmapJournalManager.psm1"
Import-Module $modulePath -Force

# Chemins des fichiers et dossiers
$journalRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Roadmap\journal"
$indexPath = Join-Path -Path $journalRoot -ChildPath "index.json"
$metadataPath = Join-Path -Path $journalRoot -ChildPath "metadata.json"
$logsPath = Join-Path -Path $journalRoot -ChildPath "logs"

# CrÃ©er le dossier de logs si nÃ©cessaire
if (-not (Test-Path -Path $logsPath)) {
    New-Item -Path $logsPath -ItemType Directory -Force | Out-Null
}

# Fonction pour journaliser les Ã©vÃ©nements
function Write-WatcherLog {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    $logFile = Join-Path -Path $logsPath -ChildPath "watcher_$(Get-Date -Format 'yyyy-MM-dd').log"
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    
    # Afficher Ã©galement dans la console
    switch ($Level) {
        "Info" { Write-Host $logEntry -ForegroundColor Gray }
        "Warning" { Write-Host $logEntry -ForegroundColor Yellow }
        "Error" { Write-Host $logEntry -ForegroundColor Red }
    }
}

# Fonction pour envoyer une notification
function Send-Notification {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    if ($EnableNotifications) {
        # Utiliser BurntToast pour les notifications Windows 10/11
        if (Get-Module -ListAvailable -Name BurntToast) {
            Import-Module BurntToast
            New-BurntToastNotification -Text "Roadmap Journal", $Message
        }
        else {
            # Fallback pour les systÃ¨mes sans BurntToast
            [System.Windows.Forms.MessageBox]::Show($Message, "Roadmap Journal", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    }
}

# Fonction pour synchroniser la roadmap avec le journal
function Sync-RoadmapWithJournal {
    param (
        [Parameter(Mandatory=$true)]
        [string]$RoadmapPath
    )
    
    try {
        # VÃ©rifier si le fichier de roadmap existe
        if (-not (Test-Path -Path $RoadmapPath)) {
            Write-WatcherLog -Message "Le fichier de roadmap '$RoadmapPath' n'existe pas." -Level "Error"
            return $false
        }
        
        # ExÃ©cuter le script de synchronisation
        $syncScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Sync-RoadmapWithJournal.ps1"
        & $syncScriptPath -RoadmapPath $RoadmapPath -Direction "ToJournal" -CreateBackup
        
        # Mettre Ã  jour les mÃ©tadonnÃ©es
        $metadata = Get-Content -Path $metadataPath -Raw | ConvertFrom-Json
        $metadata.lastSync = (Get-Date).ToUniversalTime().ToString("o")
        $metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $metadataPath -Encoding utf8 -Force
        
        Write-WatcherLog -Message "Synchronisation rÃ©ussie avec le fichier '$RoadmapPath'." -Level "Info"
        Send-Notification -Message "La roadmap a Ã©tÃ© synchronisÃ©e avec succÃ¨s."
        
        return $true
    }
    catch {
        Write-WatcherLog -Message "Erreur lors de la synchronisation: $_" -Level "Error"
        Send-Notification -Message "Erreur lors de la synchronisation de la roadmap."
        return $false
    }
}

# VÃ©rifier si le fichier de roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-WatcherLog -Message "Le fichier de roadmap '$RoadmapPath' n'existe pas." -Level "Error"
    exit 1
}

# Obtenir le chemin absolu du fichier de roadmap
$roadmapFullPath = (Get-Item $RoadmapPath).FullName
$roadmapFolder = Split-Path -Path $roadmapFullPath -Parent
$roadmapFileName = Split-Path -Path $roadmapFullPath -Leaf

# CrÃ©er un FileSystemWatcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $roadmapFolder
$watcher.Filter = $roadmapFileName
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::FileName
$watcher.EnableRaisingEvents = $true

# Variables pour le throttling
$lastSyncTime = [DateTime]::MinValue
$syncPending = $false
$syncTimer = $null

# Fonction pour gÃ©rer le throttling
function Invoke-ThrottledSync {
    if (-not $syncPending) {
        $syncPending = $true
        
        # CrÃ©er un timer pour retarder la synchronisation
        $syncTimer = New-Object System.Timers.Timer
        $syncTimer.Interval = $ThrottleSeconds * 1000
        $syncTimer.AutoReset = $false
        
        # DÃ©finir l'action Ã  exÃ©cuter lorsque le timer expire
        $action = {
            Sync-RoadmapWithJournal -RoadmapPath $roadmapFullPath
            $script:lastSyncTime = Get-Date
            $script:syncPending = $false
        }
        
        $syncTimer.Add_Elapsed($action)
        $syncTimer.Start()
    }
}

# CrÃ©er les gestionnaires d'Ã©vÃ©nements
$changeAction = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    Write-WatcherLog -Message "Modification dÃ©tectÃ©e: $changeType - $path" -Level "Info"
    
    # VÃ©rifier si nous devons throttler
    $now = Get-Date
    $timeSinceLastSync = $now - $script:lastSyncTime
    
    if ($timeSinceLastSync.TotalSeconds -ge $script:ThrottleSeconds) {
        # Synchroniser immÃ©diatement
        Sync-RoadmapWithJournal -RoadmapPath $path
        $script:lastSyncTime = $now
    }
    else {
        # Throttler la synchronisation
        Invoke-ThrottledSync
    }
}

$renameAction = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    Write-WatcherLog -Message "Renommage dÃ©tectÃ©: $changeType - $path" -Level "Info"
    
    # Mettre Ã  jour le chemin surveillÃ© si le fichier a Ã©tÃ© renommÃ©
    if ($changeType -eq "Renamed") {
        $script:roadmapFullPath = $path
        $script:roadmapFolder = Split-Path -Path $path -Parent
        $script:roadmapFileName = Split-Path -Path $path -Leaf
        
        $script:watcher.Path = $script:roadmapFolder
        $script:watcher.Filter = $script:roadmapFileName
        
        Write-WatcherLog -Message "Mise Ã  jour du chemin surveillÃ©: $path" -Level "Info"
    }
}

# Enregistrer les gestionnaires d'Ã©vÃ©nements
$changeEvent = Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $changeAction
$renameEvent = Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $renameAction

# Afficher un message de dÃ©marrage
Write-Host "Surveillance du fichier '$roadmapFullPath' dÃ©marrÃ©e." -ForegroundColor Green
Write-Host "Appuyez sur Ctrl+C pour arrÃªter la surveillance." -ForegroundColor Yellow

# Effectuer une synchronisation initiale
Sync-RoadmapWithJournal -RoadmapPath $roadmapFullPath
$lastSyncTime = Get-Date

try {
    # Maintenir le script en cours d'exÃ©cution
    while ($true) {
        Start-Sleep -Seconds 1
    }
}
finally {
    # Nettoyer les ressources lors de l'arrÃªt
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    
    Unregister-Event -SourceIdentifier $changeEvent.Name
    Unregister-Event -SourceIdentifier $renameEvent.Name
    
    Write-Host "Surveillance arrÃªtÃ©e." -ForegroundColor Green
}
