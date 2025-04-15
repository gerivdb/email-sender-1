#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute une analyse en temps réel pendant l'édition des fichiers.

.DESCRIPTION
    Ce script surveille les fichiers d'un répertoire et exécute une analyse en temps réel
    lorsqu'un fichier est modifié, avec un mécanisme de notification pour alerter l'utilisateur
    des problèmes détectés.

.PARAMETER WatchPath
    Chemin du répertoire à surveiller.

.PARAMETER Filter
    Filtre pour les types de fichiers à surveiller.

.PARAMETER NotificationType
    Type de notification à utiliser (Console, Toast, Popup).

.PARAMETER DebounceTime
    Temps en millisecondes à attendre après une modification avant d'exécuter l'analyse.

.PARAMETER UseCache
    Indique s'il faut utiliser le cache pour améliorer les performances.

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

# Importer les modules nécessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
Import-Module "$modulesPath\FileContentIndexer.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$modulesPath\SyntaxAnalyzer.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$modulesPath\PRAnalysisCache.psm1" -Force -ErrorAction SilentlyContinue

# Créer un cache si demandé
$cache = if ($UseCache) { New-PRAnalysisCache -MaxMemoryItems 1000 } else { $null }

# Créer un analyseur de syntaxe
$analyzer = New-SyntaxAnalyzer -UseCache $UseCache -Cache $cache

# Dictionnaire pour stocker les dernières modifications
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
    
    # Vérifier si le fichier existe
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
    
    # Vérifier si le fichier a été modifié depuis la dernière analyse
    $lastWrite = (Get-Item -Path $FilePath).LastWriteTime
    
    if ($lastModifications.ContainsKey($FilePath) -and $lastModifications[$FilePath] -eq $lastWrite) {
        Write-Verbose "Le fichier n'a pas été modifié depuis la dernière analyse: $FilePath"
        return $null
    }
    
    # Mettre à jour la date de dernière modification
    $lastModifications[$FilePath] = $lastWrite
    
    # Analyser le fichier
    try {
        # Analyser le fichier
        $issues = $analyzer.AnalyzeFile($FilePath)
        
        # Créer un objet résultat
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

# Fonction pour traiter les événements de modification de fichier
function Process-FileChangeEvent {
    param(
        [string]$FilePath
    )
    
    # Vérifier si un timer de debounce existe déjà pour ce fichier
    if ($debounceTimers.ContainsKey($FilePath)) {
        # Arrêter et supprimer le timer existant
        $debounceTimers[$FilePath].Dispose()
        $debounceTimers.Remove($FilePath)
    }
    
    # Créer un nouveau timer
    $timer = New-Object System.Timers.Timer
    $timer.Interval = $DebounceTime
    $timer.AutoReset = $false
    
    # Définir l'action à exécuter lorsque le timer expire
    $action = {
        param($FilePath)
        
        # Analyser le fichier
        $result = Invoke-FileAnalysis -FilePath $FilePath
        
        if ($result -and $result.Success) {
            # Afficher les résultats
            $issueCount = $result.Issues.Count
            
            if ($issueCount -gt 0) {
                $message = "Détecté $issueCount problème(s) dans le fichier $FilePath"
                Show-Notification -Title "Analyse en temps réel" -Message $message -Type $NotificationType
                
                # Afficher les problèmes
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
                Write-Host "Aucun problème détecté dans le fichier $FilePath" -ForegroundColor Green
            }
        }
    }
    
    # Configurer le timer
    $timer.Elapsed.Add({
        param($sender, $e)
        
        # Exécuter l'action
        & $action $FilePath
        
        # Supprimer le timer
        $debounceTimers.Remove($FilePath)
        $sender.Dispose()
    })
    
    # Démarrer le timer
    $debounceTimers[$FilePath] = $timer
    $timer.Start()
}

# Créer un observateur de fichiers
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $WatchPath
$watcher.Filter = $Filter
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Configurer les gestionnaires d'événements
$onChange = Register-ObjectEvent -InputObject $watcher -EventName Changed -Action {
    $filePath = $Event.SourceEventArgs.FullPath
    Process-FileChangeEvent -FilePath $filePath
}

$onCreated = Register-ObjectEvent -InputObject $watcher -EventName Created -Action {
    $filePath = $Event.SourceEventArgs.FullPath
    Process-FileChangeEvent -FilePath $filePath
}

$onRenamed = Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action {
    $filePath = $Event.SourceEventArgs.FullPath
    Process-FileChangeEvent -FilePath $filePath
}

# Afficher un message de démarrage
Write-Host "Analyse en temps réel démarrée pour $WatchPath" -ForegroundColor Green
Write-Host "Surveillance des fichiers correspondant au filtre: $Filter" -ForegroundColor Green
Write-Host "Type de notification: $NotificationType" -ForegroundColor Green
Write-Host "Temps de debounce: $DebounceTime ms" -ForegroundColor Green
Write-Host "Utilisation du cache: $UseCache" -ForegroundColor Green
Write-Host ""
Write-Host "Appuyez sur Ctrl+C pour arrêter l'analyse en temps réel" -ForegroundColor Yellow

try {
    # Boucle infinie pour maintenir le script en cours d'exécution
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
    
    Write-Host "Analyse en temps réel arrêtée" -ForegroundColor Green
}
