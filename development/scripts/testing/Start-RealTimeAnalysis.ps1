#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute une analyse en temps rÃ©el pendant l'Ã©dition des fichiers.

.DESCRIPTION
    Ce script surveille les fichiers d'un rÃ©pertoire et exÃ©cute une analyse en temps rÃ©el
    lorsqu'un fichier est modifiÃ©, avec un mÃ©canisme de notification pour alerter l'utilisateur
    des problÃ¨mes dÃ©tectÃ©s.

.PARAMETER WatchPath
    Chemin du rÃ©pertoire Ã  surveiller.

.PARAMETER Filter
    Filtre pour les types de fichiers Ã  surveiller.

.PARAMETER NotificationType
    Type de notification Ã  utiliser (Console, Toast, Popup).

.PARAMETER DebounceTime
    Temps en millisecondes Ã  attendre aprÃ¨s une modification avant d'exÃ©cuter l'analyse.

.PARAMETER UseCache
    Indique s'il faut utiliser le cache pour amÃ©liorer les performances.

.EXAMPLE
    .\Start-RealTimeAnalysis.ps1 -WatchPath "C:\Repos\MyProject" -Filter "*.ps1"

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WatchPath,
    
    [Parameter()]
    [string]$Filter = "*.*",
    
    [Parameter()]
    [ValidateSet("Console", "Toast", "Popup")]
    [string]$NotificationType = "Console",
    
    [Parameter()]
    [int]$DebounceTime = 500,
    
    [Parameter()]
    [switch]$UseCache
)

# Importer les modules nÃ©cessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
Import-Module "$modulesPath\FileContentIndexer.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$modulesPath\SyntaxAnalyzer.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$modulesPath\PRAnalysisCache.psm1" -Force -ErrorAction SilentlyContinue

# CrÃ©er un cache si demandÃ©
$cache = if ($UseCache) { New-PRAnalysisCache -MaxMemoryItems 1000 } else { $null }

# CrÃ©er un analyseur de syntaxe
$analyzer = New-SyntaxAnalyzer -UseCache $UseCache -Cache $cache

# Dictionnaire pour stocker les derniÃ¨res modifications
$lastModifications = @{}

# Dictionnaire pour stocker les timers de debounce
$debounceTimers = @{}

# Fonction pour afficher une notification
function Show-Notification {
    param(
        [string]$Title,
        [string]$Message,
        [string]$Type
    )
    
    switch ($Type) {
        "Console" {
            Write-Host "[$Title] $Message" -ForegroundColor Yellow
        }
        "Toast" {
            Add-Type -AssemblyName System.Windows.Forms
            $global:balloon = New-Object System.Windows.Forms.NotifyIcon
            $path = (Get-Process -id $pid).Path
            $balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
            $balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
            $balloon.BalloonTipTitle = $Title
            $balloon.BalloonTipText = $Message
            $balloon.Visible = $true
            $balloon.ShowBalloonTip(5000)
        }
        "Popup" {
            Add-Type -AssemblyName PresentationFramework
            [System.Windows.MessageBox]::Show($Message, $Title, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        }
    }
}

# Fonction pour analyser un fichier
function Invoke-FileAnalysis {
    param(
        [string]$FilePath
    )
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Warning "Le fichier n'existe pas: $FilePath"
        return $null
    }
    
    # Obtenir le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    
    if ($null -eq $content) {
        Write-Warning "Impossible de lire le contenu du fichier: $FilePath"
        return $null
    }
    
    # VÃ©rifier si le fichier a Ã©tÃ© modifiÃ© depuis la derniÃ¨re analyse
    $lastWrite = (Get-Item -Path $FilePath).LastWriteTime
    
    if ($lastModifications.ContainsKey($FilePath) -and $lastModifications[$FilePath] -eq $lastWrite) {
        Write-Verbose "Le fichier n'a pas Ã©tÃ© modifiÃ© depuis la derniÃ¨re analyse: $FilePath"
        return $null
    }
    
    # Mettre Ã  jour la date de derniÃ¨re modification
    $lastModifications[$FilePath] = $lastWrite
    
    # Analyser le fichier
    try {
        # Analyser le fichier
        $issues = $analyzer.AnalyzeFile($FilePath)
        
        # CrÃ©er un objet rÃ©sultat
        $result = [PSCustomObject]@{
            FilePath = $FilePath
            Issues = $issues
            AnalyzedAt = Get-Date
            Success = $true
            Error = $null
        }
        
        return $result
    } catch {
        Write-Error "Erreur lors de l'analyse du fichier $FilePath : $_"
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Issues = @()
            AnalyzedAt = Get-Date
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Fonction pour traiter les Ã©vÃ©nements de modification de fichier
function Invoke-FileChangeEvent {
    param(
        [string]$FilePath
    )
    
    # VÃ©rifier si un timer de debounce existe dÃ©jÃ  pour ce fichier
    if ($debounceTimers.ContainsKey($FilePath)) {
        # ArrÃªter et supprimer le timer existant
        $debounceTimers[$FilePath].Dispose()
        $debounceTimers.Remove($FilePath)
    }
    
    # CrÃ©er un nouveau timer
    $timer = New-Object System.Timers.Timer
    $timer.Interval = $DebounceTime
    $timer.AutoReset = $false
    
    # DÃ©finir l'action Ã  exÃ©cuter lorsque le timer expire
    $action = {
        param($FilePath)
        
        # Analyser le fichier
        $result = Invoke-FileAnalysis -FilePath $FilePath
        
        if ($result -and $result.Success) {
            # Afficher les rÃ©sultats
            $issueCount = $result.Issues.Count
            
            if ($issueCount -gt 0) {
                $message = "DÃ©tectÃ© $issueCount problÃ¨me(s) dans le fichier $FilePath"
                Show-Notification -Title "Analyse en temps rÃ©el" -Message $message -Type $NotificationType
                
                # Afficher les problÃ¨mes
                foreach ($issue in $result.Issues) {
                    Write-Host "  Ligne $($issue.Line), Colonne $($issue.Column): $($issue.Message)" -ForegroundColor $(
                        switch ($issue.Severity) {
                            "Error" { "Red" }
                            "Warning" { "Yellow" }
                            default { "Cyan" }
                        }
                    )
                }
            } else {
                Write-Host "Aucun problÃ¨me dÃ©tectÃ© dans le fichier $FilePath" -ForegroundColor Green
            }
        }
    }
    
    # Configurer le timer
    $timer.Elapsed.Add({
        param($sender, $e)
        
        # ExÃ©cuter l'action
        & $action $FilePath
        
        # Supprimer le timer
        $debounceTimers.Remove($FilePath)
        $sender.Dispose()
    })
    
    # DÃ©marrer le timer
    $debounceTimers[$FilePath] = $timer
    $timer.Start()
}

# CrÃ©er un observateur de fichiers
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $WatchPath
$watcher.Filter = $Filter
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Configurer les gestionnaires d'Ã©vÃ©nements
$onChange = Register-ObjectEvent -InputObject $watcher -EventName Changed -Action {
    $filePath = $Event.SourceEventArgs.FullPath
    Invoke-FileChangeEvent -FilePath $filePath
}

$onCreated = Register-ObjectEvent -InputObject $watcher -EventName Created -Action {
    $filePath = $Event.SourceEventArgs.FullPath
    Invoke-FileChangeEvent -FilePath $filePath
}

$onRenamed = Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action {
    $filePath = $Event.SourceEventArgs.FullPath
    Invoke-FileChangeEvent -FilePath $filePath
}

# Afficher un message de dÃ©marrage
Write-Host "Analyse en temps rÃ©el dÃ©marrÃ©e pour $WatchPath" -ForegroundColor Green
Write-Host "Surveillance des fichiers correspondant au filtre: $Filter" -ForegroundColor Green
Write-Host "Type de notification: $NotificationType" -ForegroundColor Green
Write-Host "Temps de debounce: $DebounceTime ms" -ForegroundColor Green
Write-Host "Utilisation du cache: $UseCache" -ForegroundColor Green
Write-Host ""
Write-Host "Appuyez sur Ctrl+C pour arrÃªter l'analyse en temps rÃ©el" -ForegroundColor Yellow

try {
    # Boucle infinie pour maintenir le script en cours d'exÃ©cution
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    # Nettoyer les ressources
    Unregister-Event -SourceIdentifier $onChange.Name
    Unregister-Event -SourceIdentifier $onCreated.Name
    Unregister-Event -SourceIdentifier $onRenamed.Name
    $watcher.Dispose()
    
    # Nettoyer les timers
    foreach ($timer in $debounceTimers.Values) {
        $timer.Dispose()
    }
    
    Write-Host "Analyse en temps rÃ©el arrÃªtÃ©e" -ForegroundColor Green
}

