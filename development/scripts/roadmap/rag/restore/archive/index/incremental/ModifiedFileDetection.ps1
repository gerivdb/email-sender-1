# ModifiedFileDetection.ps1
# Script implémentant la détection de fichiers modifiés pour l'indexation incrémentale
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$fileDetectionPath = Join-Path -Path $scriptPath -ChildPath "FileDetection.ps1"

if (Test-Path -Path $fileDetectionPath) {
    . $fileDetectionPath
} else {
    Write-Error "Le fichier FileDetection.ps1 est introuvable."
    exit 1
}

# Classe pour représenter un observateur de fichiers
class FileWatcher {
    # Détecteur de fichiers
    [FileDetector]$FileDetector
    
    # Observateur de système de fichiers
    [System.IO.FileSystemWatcher]$Watcher
    
    # Dictionnaire des événements récents
    [System.Collections.Concurrent.ConcurrentDictionary[string, DateTime]]$RecentEvents
    
    # Intervalle de débounce (en millisecondes)
    [int]$DebounceInterval
    
    # Constructeur par défaut
    FileWatcher() {
        $this.FileDetector = $null
        $this.Watcher = $null
        $this.RecentEvents = [System.Collections.Concurrent.ConcurrentDictionary[string, DateTime]]::new()
        $this.DebounceInterval = 500  # 500 ms
    }
    
    # Constructeur avec détecteur de fichiers
    FileWatcher([FileDetector]$fileDetector) {
        $this.FileDetector = $fileDetector
        $this.Watcher = $null
        $this.RecentEvents = [System.Collections.Concurrent.ConcurrentDictionary[string, DateTime]]::new()
        $this.DebounceInterval = 500  # 500 ms
    }
    
    # Constructeur complet
    FileWatcher([FileDetector]$fileDetector, [int]$debounceInterval) {
        $this.FileDetector = $fileDetector
        $this.Watcher = $null
        $this.RecentEvents = [System.Collections.Concurrent.ConcurrentDictionary[string, DateTime]]::new()
        $this.DebounceInterval = $debounceInterval
    }
    
    # Méthode pour démarrer l'observateur
    [void] Start() {
        if ($null -eq $this.FileDetector) {
            Write-Error "Le détecteur de fichiers n'est pas défini."
            return
        }
        
        if (-not (Test-Path -Path $this.FileDetector.RootDirectory -PathType Container)) {
            Write-Error "Le répertoire racine $($this.FileDetector.RootDirectory) n'existe pas."
            return
        }
        
        # Créer l'observateur
        $this.Watcher = [System.IO.FileSystemWatcher]::new()
        $this.Watcher.Path = $this.FileDetector.RootDirectory
        $this.Watcher.IncludeSubdirectories = $true
        $this.Watcher.EnableRaisingEvents = $false
        
        # Configurer les filtres
        if ($this.FileDetector.IncludeFilters.Count -eq 1) {
            $this.Watcher.Filter = $this.FileDetector.IncludeFilters[0]
        } else {
            $this.Watcher.Filter = "*"
        }
        
        # Configurer les événements
        Register-ObjectEvent -InputObject $this.Watcher -EventName Created -Action {
            $path = $Event.SourceEventArgs.FullPath
            $name = $Event.SourceEventArgs.Name
            $changeType = $Event.SourceEventArgs.ChangeType
            $timeStamp = Get-Date
            
            # Récupérer l'instance de FileWatcher
            $watcher = $Event.MessageData
            
            # Vérifier les filtres d'exclusion
            $excluded = $false
            foreach ($excludeFilter in $watcher.FileDetector.ExcludeFilters) {
                if ($path -like $excludeFilter) {
                    $excluded = $true
                    break
                }
            }
            
            if (-not $excluded) {
                # Ajouter l'événement au dictionnaire
                $watcher.RecentEvents[$path] = $timeStamp
                
                # Planifier le traitement de l'événement
                Start-ThreadJob -ScriptBlock {
                    param($watcher, $path, $timeStamp)
                    
                    # Attendre l'intervalle de débounce
                    Start-Sleep -Milliseconds $watcher.DebounceInterval
                    
                    # Vérifier si l'événement est toujours le plus récent
                    $currentTimeStamp = $watcher.RecentEvents[$path]
                    if ($currentTimeStamp -eq $timeStamp) {
                        # Traiter l'événement
                        $watcher.HandleFileCreated($path)
                        
                        # Supprimer l'événement du dictionnaire
                        $watcher.RecentEvents.TryRemove($path, [ref]$null)
                    }
                } -ArgumentList $watcher, $path, $timeStamp
            }
        } -MessageData $this
        
        Register-ObjectEvent -InputObject $this.Watcher -EventName Changed -Action {
            $path = $Event.SourceEventArgs.FullPath
            $name = $Event.SourceEventArgs.Name
            $changeType = $Event.SourceEventArgs.ChangeType
            $timeStamp = Get-Date
            
            # Récupérer l'instance de FileWatcher
            $watcher = $Event.MessageData
            
            # Vérifier les filtres d'exclusion
            $excluded = $false
            foreach ($excludeFilter in $watcher.FileDetector.ExcludeFilters) {
                if ($path -like $excludeFilter) {
                    $excluded = $true
                    break
                }
            }
            
            if (-not $excluded) {
                # Ajouter l'événement au dictionnaire
                $watcher.RecentEvents[$path] = $timeStamp
                
                # Planifier le traitement de l'événement
                Start-ThreadJob -ScriptBlock {
                    param($watcher, $path, $timeStamp)
                    
                    # Attendre l'intervalle de débounce
                    Start-Sleep -Milliseconds $watcher.DebounceInterval
                    
                    # Vérifier si l'événement est toujours le plus récent
                    $currentTimeStamp = $watcher.RecentEvents[$path]
                    if ($currentTimeStamp -eq $timeStamp) {
                        # Traiter l'événement
                        $watcher.HandleFileChanged($path)
                        
                        # Supprimer l'événement du dictionnaire
                        $watcher.RecentEvents.TryRemove($path, [ref]$null)
                    }
                } -ArgumentList $watcher, $path, $timeStamp
            }
        } -MessageData $this
        
        Register-ObjectEvent -InputObject $this.Watcher -EventName Deleted -Action {
            $path = $Event.SourceEventArgs.FullPath
            $name = $Event.SourceEventArgs.Name
            $changeType = $Event.SourceEventArgs.ChangeType
            $timeStamp = Get-Date
            
            # Récupérer l'instance de FileWatcher
            $watcher = $Event.MessageData
            
            # Vérifier les filtres d'exclusion
            $excluded = $false
            foreach ($excludeFilter in $watcher.FileDetector.ExcludeFilters) {
                if ($path -like $excludeFilter) {
                    $excluded = $true
                    break
                }
            }
            
            if (-not $excluded) {
                # Ajouter l'événement au dictionnaire
                $watcher.RecentEvents[$path] = $timeStamp
                
                # Planifier le traitement de l'événement
                Start-ThreadJob -ScriptBlock {
                    param($watcher, $path, $timeStamp)
                    
                    # Attendre l'intervalle de débounce
                    Start-Sleep -Milliseconds $watcher.DebounceInterval
                    
                    # Vérifier si l'événement est toujours le plus récent
                    $currentTimeStamp = $watcher.RecentEvents[$path]
                    if ($currentTimeStamp -eq $timeStamp) {
                        # Traiter l'événement
                        $watcher.HandleFileDeleted($path)
                        
                        # Supprimer l'événement du dictionnaire
                        $watcher.RecentEvents.TryRemove($path, [ref]$null)
                    }
                } -ArgumentList $watcher, $path, $timeStamp
            }
        } -MessageData $this
        
        Register-ObjectEvent -InputObject $this.Watcher -EventName Renamed -Action {
            $path = $Event.SourceEventArgs.FullPath
            $oldPath = $Event.SourceEventArgs.OldFullPath
            $name = $Event.SourceEventArgs.Name
            $oldName = $Event.SourceEventArgs.OldName
            $changeType = $Event.SourceEventArgs.ChangeType
            $timeStamp = Get-Date
            
            # Récupérer l'instance de FileWatcher
            $watcher = $Event.MessageData
            
            # Vérifier les filtres d'exclusion
            $excluded = $false
            foreach ($excludeFilter in $watcher.FileDetector.ExcludeFilters) {
                if ($path -like $excludeFilter -or $oldPath -like $excludeFilter) {
                    $excluded = $true
                    break
                }
            }
            
            if (-not $excluded) {
                # Ajouter l'événement au dictionnaire
                $watcher.RecentEvents[$path] = $timeStamp
                $watcher.RecentEvents[$oldPath] = $timeStamp
                
                # Planifier le traitement de l'événement
                Start-ThreadJob -ScriptBlock {
                    param($watcher, $path, $oldPath, $timeStamp)
                    
                    # Attendre l'intervalle de débounce
                    Start-Sleep -Milliseconds $watcher.DebounceInterval
                    
                    # Vérifier si l'événement est toujours le plus récent
                    $currentTimeStamp = $watcher.RecentEvents[$path]
                    $oldCurrentTimeStamp = $watcher.RecentEvents[$oldPath]
                    if ($currentTimeStamp -eq $timeStamp -and $oldCurrentTimeStamp -eq $timeStamp) {
                        # Traiter l'événement
                        $watcher.HandleFileRenamed($oldPath, $path)
                        
                        # Supprimer les événements du dictionnaire
                        $watcher.RecentEvents.TryRemove($path, [ref]$null)
                        $watcher.RecentEvents.TryRemove($oldPath, [ref]$null)
                    }
                } -ArgumentList $watcher, $path, $oldPath, $timeStamp
            }
        } -MessageData $this
        
        # Activer l'observateur
        $this.Watcher.EnableRaisingEvents = $true
    }
    
    # Méthode pour arrêter l'observateur
    [void] Stop() {
        if ($null -ne $this.Watcher) {
            $this.Watcher.EnableRaisingEvents = $false
            $this.Watcher.Dispose()
            $this.Watcher = $null
        }
    }
    
    # Méthode pour gérer la création d'un fichier
    [void] HandleFileCreated([string]$filePath) {
        if (-not (Test-Path -Path $filePath -PathType Leaf)) {
            return
        }
        
        # Créer une nouvelle signature
        $signature = [FileSignature]::new($filePath)
        $signature.CalculateMD5Hash()
        
        # Ajouter la signature au dictionnaire
        $this.FileDetector.FileSignatures[$filePath] = $signature
        
        # Enregistrer l'ajout si un gestionnaire de suivi est disponible
        if ($null -ne $this.FileDetector.ChangeTracker) {
            $this.FileDetector.ChangeTracker.TrackAdd($filePath, "system", "file_watcher")
        }
        
        # Sauvegarder les signatures
        $this.FileDetector.SaveSignatures()
    }
    
    # Méthode pour gérer la modification d'un fichier
    [void] HandleFileChanged([string]$filePath) {
        if (-not (Test-Path -Path $filePath -PathType Leaf)) {
            return
        }
        
        # Vérifier si le fichier est connu
        if ($this.FileDetector.FileSignatures.ContainsKey($filePath)) {
            # Récupérer la signature existante
            $signature = $this.FileDetector.FileSignatures[$filePath]
            
            # Mettre à jour la signature
            $signature.Update()
            $signature.CalculateMD5Hash()
            
            # Enregistrer la modification si un gestionnaire de suivi est disponible
            if ($null -ne $this.FileDetector.ChangeTracker) {
                $this.FileDetector.ChangeTracker.TrackUpdate($filePath, "system", "file_watcher")
            }
        } else {
            # Créer une nouvelle signature
            $signature = [FileSignature]::new($filePath)
            $signature.CalculateMD5Hash()
            
            # Ajouter la signature au dictionnaire
            $this.FileDetector.FileSignatures[$filePath] = $signature
            
            # Enregistrer l'ajout si un gestionnaire de suivi est disponible
            if ($null -ne $this.FileDetector.ChangeTracker) {
                $this.FileDetector.ChangeTracker.TrackAdd($filePath, "system", "file_watcher")
            }
        }
        
        # Sauvegarder les signatures
        $this.FileDetector.SaveSignatures()
    }
    
    # Méthode pour gérer la suppression d'un fichier
    [void] HandleFileDeleted([string]$filePath) {
        # Vérifier si le fichier est connu
        if ($this.FileDetector.FileSignatures.ContainsKey($filePath)) {
            # Supprimer la signature
            $this.FileDetector.FileSignatures.Remove($filePath)
            
            # Enregistrer la suppression si un gestionnaire de suivi est disponible
            if ($null -ne $this.FileDetector.ChangeTracker) {
                $this.FileDetector.ChangeTracker.TrackDelete($filePath, "system", "file_watcher")
            }
            
            # Sauvegarder les signatures
            $this.FileDetector.SaveSignatures()
        }
    }
    
    # Méthode pour gérer le renommage d'un fichier
    [void] HandleFileRenamed([string]$oldFilePath, [string]$newFilePath) {
        # Vérifier si le fichier est connu
        if ($this.FileDetector.FileSignatures.ContainsKey($oldFilePath)) {
            # Récupérer la signature existante
            $signature = $this.FileDetector.FileSignatures[$oldFilePath]
            
            # Supprimer l'ancienne signature
            $this.FileDetector.FileSignatures.Remove($oldFilePath)
            
            # Mettre à jour le chemin du fichier
            $signature.FilePath = $newFilePath
            
            # Mettre à jour la signature
            $signature.Update()
            $signature.CalculateMD5Hash()
            
            # Ajouter la nouvelle signature
            $this.FileDetector.FileSignatures[$newFilePath] = $signature
            
            # Enregistrer la suppression et l'ajout si un gestionnaire de suivi est disponible
            if ($null -ne $this.FileDetector.ChangeTracker) {
                $this.FileDetector.ChangeTracker.TrackDelete($oldFilePath, "system", "file_watcher")
                $this.FileDetector.ChangeTracker.TrackAdd($newFilePath, "system", "file_watcher")
            }
            
            # Sauvegarder les signatures
            $this.FileDetector.SaveSignatures()
        } else {
            # Traiter comme un nouveau fichier
            $this.HandleFileCreated($newFilePath)
        }
    }
}

# Fonction pour créer un observateur de fichiers
function New-FileWatcher {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [FileDetector]$FileDetector,
        
        [Parameter(Mandatory = $false)]
        [int]$DebounceInterval = 500
    )
    
    return [FileWatcher]::new($FileDetector, $DebounceInterval)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-FileWatcher
