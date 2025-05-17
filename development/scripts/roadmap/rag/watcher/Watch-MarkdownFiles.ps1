#Requires -Version 5.1
<#
.SYNOPSIS
    Surveille les fichiers Markdown pour détecter les modifications en temps réel.
.DESCRIPTION
    Ce script utilise FileSystemWatcher pour surveiller les modifications des fichiers
    Markdown et déclenche des actions spécifiques lorsque des changements sont détectés.
    Il fait partie du système de synchronisation bidirectionnelle entre les fichiers Markdown
    et la base vectorielle Qdrant.
.PARAMETER WatchPath
    Chemin du répertoire à surveiller. Par défaut, utilise le dossier "projet\roadmaps\plans".
.PARAMETER Filter
    Filtre pour les fichiers à surveiller. Par défaut, "*.md".
.PARAMETER IncludeSubdirectories
    Indique si les sous-répertoires doivent être surveillés. Par défaut, $true.
.PARAMETER DebounceTime
    Temps en millisecondes à attendre après une modification avant de traiter l'événement.
    Permet d'éviter les traitements multiples pour des modifications rapprochées.
    Par défaut, 500 ms.
.PARAMETER LogPath
    Chemin du fichier de log. Par défaut, "logs\markdown-watcher.log".
.PARAMETER EnableVerboseLogging
    Active la journalisation détaillée. Par défaut, $false.
.EXAMPLE
    .\Watch-MarkdownFiles.ps1 -WatchPath "projet\roadmaps\plans\consolidated"
    Surveille les fichiers Markdown dans le dossier spécifié.
.NOTES
    Nom: Watch-MarkdownFiles.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-06-10
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$WatchPath = "projet\roadmaps\plans",
    
    [Parameter(Mandatory = $false)]
    [string]$Filter = "*.md",
    
    [Parameter(Mandatory = $false)]
    [bool]$IncludeSubdirectories = $true,
    
    [Parameter(Mandatory = $false)]
    [int]$DebounceTime = 500,
    
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "logs\markdown-watcher.log",
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableVerboseLogging
)

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesPath = Join-Path -Path $scriptPath -ChildPath "..\modules"
$loggingModulePath = Join-Path -Path $modulesPath -ChildPath "Logging.psm1"

if (Test-Path -Path $loggingModulePath) {
    Import-Module $loggingModulePath -Force
} else {
    # Fonction de logging simplifiée si le module n'est pas disponible
    function Write-Log {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Message,
            
            [Parameter(Mandatory = $false)]
            [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "DEBUG")]
            [string]$Level = "INFO"
        )
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$Level] $Message"
        
        # Définir la couleur en fonction du niveau
        $color = switch ($Level) {
            "INFO" { "White" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            "SUCCESS" { "Green" }
            "DEBUG" { "Cyan" }
            default { "White" }
        }
        
        # Afficher le message dans la console
        Write-Host $logMessage -ForegroundColor $color
        
        # Enregistrer dans le fichier de log
        try {
            $logDir = Split-Path -Parent $LogPath
            if (-not (Test-Path -Path $logDir)) {
                New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            }
            
            Add-Content -Path $LogPath -Value $logMessage -Encoding UTF8
        } catch {
            Write-Host "Erreur lors de l'écriture dans le fichier de log: $_" -ForegroundColor Red
        }
    }
}

# Classe pour gérer les événements de modification de fichiers
class MarkdownFileWatcher {
    [string]$WatchPath
    [string]$Filter
    [bool]$IncludeSubdirectories
    [int]$DebounceTime
    [string]$LogPath
    [bool]$VerboseLogging
    [System.IO.FileSystemWatcher]$Watcher
    [hashtable]$DebounceTimers = @{}
    [System.Collections.Concurrent.ConcurrentDictionary[string, datetime]]$RecentEvents
    
    # Constructeur
    MarkdownFileWatcher(
        [string]$watchPath,
        [string]$filter,
        [bool]$includeSubdirectories,
        [int]$debounceTime,
        [string]$logPath,
        [bool]$verboseLogging
    ) {
        $this.WatchPath = $watchPath
        $this.Filter = $filter
        $this.IncludeSubdirectories = $includeSubdirectories
        $this.DebounceTime = $debounceTime
        $this.LogPath = $logPath
        $this.VerboseLogging = $verboseLogging
        $this.RecentEvents = [System.Collections.Concurrent.ConcurrentDictionary[string, datetime]]::new()
        
        # Vérifier que le chemin existe
        if (-not (Test-Path -Path $watchPath)) {
            Write-Log "Le chemin spécifié n'existe pas: $watchPath" -Level "ERROR"
            throw "Le chemin spécifié n'existe pas: $watchPath"
        }
        
        # Créer le watcher
        $this.Watcher = New-Object System.IO.FileSystemWatcher
        $this.Watcher.Path = (Resolve-Path $watchPath).Path
        $this.Watcher.Filter = $filter
        $this.Watcher.IncludeSubdirectories = $includeSubdirectories
        $this.Watcher.EnableRaisingEvents = $false
        
        Write-Log "Watcher créé pour le chemin: $($this.Watcher.Path)" -Level "INFO"
        Write-Log "Filtre: $($this.Watcher.Filter)" -Level "INFO"
        Write-Log "Inclure les sous-répertoires: $($this.Watcher.IncludeSubdirectories)" -Level "INFO"
    }
    
    # Méthode pour démarrer la surveillance
    [void] Start() {
        # Configurer les gestionnaires d'événements
        $this.RegisterEventHandlers()
        
        # Activer la surveillance
        $this.Watcher.EnableRaisingEvents = $true
        
        Write-Log "Surveillance démarrée" -Level "SUCCESS"
    }
    
    # Méthode pour arrêter la surveillance
    [void] Stop() {
        # Désactiver la surveillance
        $this.Watcher.EnableRaisingEvents = $false
        
        # Nettoyer les ressources
        foreach ($timer in $this.DebounceTimers.Values) {
            $timer.Dispose()
        }
        
        $this.DebounceTimers.Clear()
        $this.RecentEvents.Clear()
        
        Write-Log "Surveillance arrêtée" -Level "INFO"
    }
    
    # Méthode pour enregistrer les gestionnaires d'événements
    [void] RegisterEventHandlers() {
        # Gestionnaire pour les événements de création
        $onCreated = Register-ObjectEvent -InputObject $this.Watcher -EventName Created -Action {
            $path = $Event.SourceEventArgs.FullPath
            $changeType = $Event.SourceEventArgs.ChangeType
            $timeStamp = Get-Date
            
            # Vérifier si le fichier est un fichier Markdown
            if ($path -match '\.md$') {
                Write-Log "Fichier créé: $path" -Level "INFO"
                
                # Ajouter l'événement au dictionnaire
                $watcher = $Event.MessageData
                $watcher.RecentEvents[$path] = $timeStamp
                
                # Planifier le traitement de l'événement
                Start-ThreadJob -ScriptBlock {
                    param($watcher, $path, $timeStamp)
                    
                    # Attendre l'intervalle de debounce
                    Start-Sleep -Milliseconds $watcher.DebounceTime
                    
                    # Vérifier si l'événement est toujours le plus récent
                    $currentTimeStamp = $watcher.RecentEvents[$path]
                    if ($currentTimeStamp -eq $timeStamp) {
                        # Traiter l'événement
                        $watcher.HandleFileCreated($path)
                        
                        # Supprimer l'événement du dictionnaire
                        $watcher.RecentEvents.TryRemove($path, [ref]$null)
                    }
                } -ArgumentList $this, $path, $timeStamp
            }
        } -MessageData $this
        
        # Gestionnaire pour les événements de modification
        $onChanged = Register-ObjectEvent -InputObject $this.Watcher -EventName Changed -Action {
            $path = $Event.SourceEventArgs.FullPath
            $changeType = $Event.SourceEventArgs.ChangeType
            $timeStamp = Get-Date
            
            # Vérifier si le fichier est un fichier Markdown
            if ($path -match '\.md$') {
                Write-Log "Fichier modifié: $path" -Level "INFO"
                
                # Ajouter l'événement au dictionnaire
                $watcher = $Event.MessageData
                $watcher.RecentEvents[$path] = $timeStamp
                
                # Planifier le traitement de l'événement
                Start-ThreadJob -ScriptBlock {
                    param($watcher, $path, $timeStamp)
                    
                    # Attendre l'intervalle de debounce
                    Start-Sleep -Milliseconds $watcher.DebounceTime
                    
                    # Vérifier si l'événement est toujours le plus récent
                    $currentTimeStamp = $watcher.RecentEvents[$path]
                    if ($currentTimeStamp -eq $timeStamp) {
                        # Traiter l'événement
                        $watcher.HandleFileChanged($path)
                        
                        # Supprimer l'événement du dictionnaire
                        $watcher.RecentEvents.TryRemove($path, [ref]$null)
                    }
                } -ArgumentList $this, $path, $timeStamp
            }
        } -MessageData $this
        
        # Gestionnaire pour les événements de suppression
        $onDeleted = Register-ObjectEvent -InputObject $this.Watcher -EventName Deleted -Action {
            $path = $Event.SourceEventArgs.FullPath
            $changeType = $Event.SourceEventArgs.ChangeType
            $timeStamp = Get-Date
            
            # Vérifier si le fichier est un fichier Markdown
            if ($path -match '\.md$') {
                Write-Log "Fichier supprimé: $path" -Level "INFO"
                
                # Ajouter l'événement au dictionnaire
                $watcher = $Event.MessageData
                $watcher.RecentEvents[$path] = $timeStamp
                
                # Planifier le traitement de l'événement
                Start-ThreadJob -ScriptBlock {
                    param($watcher, $path, $timeStamp)
                    
                    # Attendre l'intervalle de debounce
                    Start-Sleep -Milliseconds $watcher.DebounceTime
                    
                    # Vérifier si l'événement est toujours le plus récent
                    $currentTimeStamp = $watcher.RecentEvents[$path]
                    if ($currentTimeStamp -eq $timeStamp) {
                        # Traiter l'événement
                        $watcher.HandleFileDeleted($path)
                        
                        # Supprimer l'événement du dictionnaire
                        $watcher.RecentEvents.TryRemove($path, [ref]$null)
                    }
                } -ArgumentList $this, $path, $timeStamp
            }
        } -MessageData $this
        
        # Gestionnaire pour les événements de renommage
        $onRenamed = Register-ObjectEvent -InputObject $this.Watcher -EventName Renamed -Action {
            $oldPath = $Event.SourceEventArgs.OldFullPath
            $newPath = $Event.SourceEventArgs.FullPath
            $changeType = $Event.SourceEventArgs.ChangeType
            $timeStamp = Get-Date
            
            # Vérifier si le fichier est un fichier Markdown
            if ($newPath -match '\.md$' -or $oldPath -match '\.md$') {
                Write-Log "Fichier renommé: $oldPath -> $newPath" -Level "INFO"
                
                # Ajouter l'événement au dictionnaire
                $watcher = $Event.MessageData
                $watcher.RecentEvents[$newPath] = $timeStamp
                
                # Planifier le traitement de l'événement
                Start-ThreadJob -ScriptBlock {
                    param($watcher, $oldPath, $newPath, $timeStamp)
                    
                    # Attendre l'intervalle de debounce
                    Start-Sleep -Milliseconds $watcher.DebounceTime
                    
                    # Vérifier si l'événement est toujours le plus récent
                    $currentTimeStamp = $watcher.RecentEvents[$newPath]
                    if ($currentTimeStamp -eq $timeStamp) {
                        # Traiter l'événement
                        $watcher.HandleFileRenamed($oldPath, $newPath)
                        
                        # Supprimer l'événement du dictionnaire
                        $watcher.RecentEvents.TryRemove($newPath, [ref]$null)
                    }
                } -ArgumentList $this, $oldPath, $newPath, $timeStamp
            }
        } -MessageData $this
    }
    
    # Méthode pour gérer la création d'un fichier
    [void] HandleFileCreated([string]$filePath) {
        Write-Log "Traitement de la création du fichier: $filePath" -Level "INFO"
        
        # TODO: Implémenter la logique de traitement pour les fichiers créés
        # Par exemple, indexer le nouveau fichier dans Qdrant
    }
    
    # Méthode pour gérer la modification d'un fichier
    [void] HandleFileChanged([string]$filePath) {
        Write-Log "Traitement de la modification du fichier: $filePath" -Level "INFO"
        
        # TODO: Implémenter la logique de traitement pour les fichiers modifiés
        # Par exemple, mettre à jour l'index dans Qdrant
    }
    
    # Méthode pour gérer la suppression d'un fichier
    [void] HandleFileDeleted([string]$filePath) {
        Write-Log "Traitement de la suppression du fichier: $filePath" -Level "INFO"
        
        # TODO: Implémenter la logique de traitement pour les fichiers supprimés
        # Par exemple, supprimer l'index dans Qdrant
    }
    
    # Méthode pour gérer le renommage d'un fichier
    [void] HandleFileRenamed([string]$oldPath, [string]$newPath) {
        Write-Log "Traitement du renommage du fichier: $oldPath -> $newPath" -Level "INFO"
        
        # TODO: Implémenter la logique de traitement pour les fichiers renommés
        # Par exemple, mettre à jour l'index dans Qdrant
    }
}

# Fonction principale
function Start-MarkdownWatcher {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$WatchPath = "projet\roadmaps\plans",
        
        [Parameter(Mandatory = $false)]
        [string]$Filter = "*.md",
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeSubdirectories = $true,
        
        [Parameter(Mandatory = $false)]
        [int]$DebounceTime = 500,
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath = "logs\markdown-watcher.log",
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableVerboseLogging
    )
    
    try {
        # Créer et démarrer le watcher
        $watcher = [MarkdownFileWatcher]::new(
            $WatchPath,
            $Filter,
            $IncludeSubdirectories,
            $DebounceTime,
            $LogPath,
            $EnableVerboseLogging
        )
        
        $watcher.Start()
        
        # Maintenir le script en cours d'exécution
        Write-Log "Appuyez sur Ctrl+C pour arrêter la surveillance..." -Level "INFO"
        
        try {
            while ($true) {
                Start-Sleep -Seconds 1
            }
        } finally {
            # Arrêter le watcher lorsque le script est interrompu
            $watcher.Stop()
        }
    } catch {
        Write-Log "Erreur lors du démarrage de la surveillance: $_" -Level "ERROR"
        throw $_
    }
}

# Exécuter la fonction principale avec les paramètres fournis
Start-MarkdownWatcher -WatchPath $WatchPath -Filter $Filter -IncludeSubdirectories $IncludeSubdirectories -DebounceTime $DebounceTime -LogPath $LogPath -EnableVerboseLogging:$EnableVerboseLogging
