#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre un observateur de fichiers pour mettre Ã  jour automatiquement l'inventaire
.DESCRIPTION
    Ce script crÃ©e un observateur de fichiers (FileSystemWatcher) qui surveille
    les modifications de scripts et met Ã  jour automatiquement l'inventaire.
.PARAMETER Path
    Chemin du rÃ©pertoire Ã  surveiller
.PARAMETER Extensions
    Extensions de fichiers Ã  surveiller
.PARAMETER LogPath
    Chemin du fichier de log
.EXAMPLE
    .\Register-InventoryWatcher.ps1 -Path "C:\Scripts" -Extensions ".ps1",".psm1",".py"
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Tags: automation, watcher, inventaire
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [string[]]$Extensions = @(".ps1", ".psm1", ".py", ".cmd", ".bat"),
    
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "logs/inventory_watcher.log"
)

# Importer les modules nÃ©cessaires
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\ScriptInventoryManager.psm1"
Import-Module $modulePath -Force

# CrÃ©er le rÃ©pertoire de logs s'il n'existe pas
$logDir = Split-Path -Parent $LogPath
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    Write-Host "RÃ©pertoire de logs crÃ©Ã©: $logDir" -ForegroundColor Green
}

# Fonction pour Ã©crire dans le log
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Ã‰crire dans le fichier de log
    Add-Content -Path $LogPath -Value $logMessage -Encoding UTF8
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor White }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage }
    }
}

# Fonction pour mettre Ã  jour l'inventaire
function Update-InventoryWithLog {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ChangedFile = ""
    )
    
    try {
        Write-Log "Mise Ã  jour de l'inventaire..." -Level "INFO"
        Update-ScriptInventory -Path $Path
        Write-Log "Inventaire mis Ã  jour avec succÃ¨s." -Level "SUCCESS"
        
        if ($ChangedFile) {
            # RÃ©cupÃ©rer les informations sur le script modifiÃ©
            $scripts = Get-ScriptInventory
            $script = $scripts | Where-Object { $_.FullPath -eq $ChangedFile }
            
            if ($script) {
                Write-Log "Informations sur le script modifiÃ©:" -Level "INFO"
                Write-Log "- Nom: $($script.FileName)" -Level "INFO"
                Write-Log "- Langage: $($script.Language)" -Level "INFO"
                Write-Log "- CatÃ©gorie: $($script.Category)" -Level "INFO"
                Write-Log "- Auteur: $($script.Author)" -Level "INFO"
                Write-Log "- Version: $($script.Version)" -Level "INFO"
                Write-Log "- Lignes: $($script.LineCount)" -Level "INFO"
            }
        }
    }
    catch {
        Write-Log "Erreur lors de la mise Ã  jour de l'inventaire: $_" -Level "ERROR"
    }
}

# CrÃ©er l'observateur de fichiers
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $Path
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $false

# Filtrer les extensions
$filter = "*" + ($Extensions -join ",*")
$watcher.Filter = $filter

Write-Log "DÃ©marrage de l'observateur de fichiers..." -Level "INFO"
Write-Log "RÃ©pertoire surveillÃ©: $Path" -Level "INFO"
Write-Log "Extensions surveillÃ©es: $($Extensions -join ", ")" -Level "INFO"

# CrÃ©er les gestionnaires d'Ã©vÃ©nements
$onChange = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # VÃ©rifier l'extension du fichier
    $extension = [System.IO.Path]::GetExtension($path)
    if ($Extensions -contains $extension) {
        Write-Log "Fichier $changeType: $path" -Level "INFO"
        
        # Attendre un court instant pour s'assurer que le fichier est complÃ¨tement Ã©crit
        Start-Sleep -Seconds 1
        
        # Mettre Ã  jour l'inventaire
        Update-InventoryWithLog -ChangedFile $path
    }
}

$onRenamed = {
    $oldPath = $Event.SourceEventArgs.OldFullPath
    $newPath = $Event.SourceEventArgs.FullPath
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # VÃ©rifier l'extension du fichier
    $extension = [System.IO.Path]::GetExtension($newPath)
    if ($Extensions -contains $extension) {
        Write-Log "Fichier renommÃ©: $oldPath -> $newPath" -Level "INFO"
        
        # Mettre Ã  jour l'inventaire
        Update-InventoryWithLog
    }
}

$onDeleted = {
    $path = $Event.SourceEventArgs.FullPath
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # VÃ©rifier l'extension du fichier
    $extension = [System.IO.Path]::GetExtension($path)
    if ($Extensions -contains $extension) {
        Write-Log "Fichier supprimÃ©: $path" -Level "INFO"
        
        # Mettre Ã  jour l'inventaire
        Update-InventoryWithLog
    }
}

# Enregistrer les gestionnaires d'Ã©vÃ©nements
$handlers = @()
$handlers += Register-ObjectEvent -InputObject $watcher -EventName Created -Action $onChange
$handlers += Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $onChange
$handlers += Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $onRenamed
$handlers += Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $onDeleted

# Activer l'observateur
$watcher.EnableRaisingEvents = $true

Write-Log "Observateur de fichiers dÃ©marrÃ©. Appuyez sur Ctrl+C pour arrÃªter." -Level "SUCCESS"

try {
    # Mettre Ã  jour l'inventaire initial
    Update-InventoryWithLog
    
    # Boucle infinie pour maintenir le script en cours d'exÃ©cution
    while ($true) {
        Wait-Event -Timeout 1
        
        # VÃ©rifier si l'utilisateur a appuyÃ© sur Ctrl+C
        if ($Host.UI.RawUI.KeyAvailable) {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            if (($key.VirtualKeyCode -eq 67) -and ($key.ControlKeyState -match "LeftCtrlPressed|RightCtrlPressed")) {
                break
            }
        }
    }
}
finally {
    # Nettoyer les gestionnaires d'Ã©vÃ©nements
    $handlers | ForEach-Object { Unregister-Event -SourceIdentifier $_.Name }
    $handlers | ForEach-Object { Remove-Job -Id $_.Id -Force }
    
    # ArrÃªter l'observateur
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    
    Write-Log "Observateur de fichiers arrÃªtÃ©." -Level "INFO"
}
