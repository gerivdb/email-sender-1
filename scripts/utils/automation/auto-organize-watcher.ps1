# Script pour surveiller et organiser automatiquement les nouveaux fichiers
# Ce script surveille le dépôt et organise automatiquement les nouveaux fichiers

# Importation des modules nécessaires
Add-Type -AssemblyName System.IO.FileSystem.Watcher

# Définition des règles d'organisation
$rules = @(
    # Fichiers de configuration JSON
    @{
        Pattern = "*.settings.json", "*_settings.json", "settings.json"
        Destination = "config\vscode"
        Exclude = ".github"
    },
    # Fichiers CMD
    @{
        Pattern = "*.cmd"
        Destination = "scripts\cmd\batch"
        Exclude = "scripts\cmd"
    },
    # Fichiers de redémarrage
    @{
        Pattern = "restart_*.cmd"
        Destination = "scripts\cmd\batch"
        Exclude = "scripts\cmd"
    },
    # Fichiers MCP
    @{
        Pattern = "mcp-*.cmd", "*-mcp-*.cmd"
        Destination = "scripts\cmd\mcp"
        Exclude = "scripts\cmd"
    },
    # Fichiers Augment
    @{
        Pattern = "augment-*.cmd"
        Destination = "scripts\cmd\augment"
        Exclude = "scripts\cmd"
    },
    # Fichiers de log
    @{
        Pattern = "*.log"
        Destination = "logs\daily"
        Exclude = "logs"
    },
    # Fichiers Markdown
    @{
        Pattern = "GUIDE_*.md", "guide_*.md"
        Destination = "docs\guides"
        Exclude = "docs"
    },
    # Fichiers de workflow
    @{
        Pattern = "*.workflow.json", "*_workflow.json"
        Destination = "workflows"
        Exclude = "workflows"
    }
)

# Fonction pour déterminer la destination d'un fichier
function Get-FileDestination {
    param (
        [string]$FilePath
    )
    
    $fileName = [System.IO.Path]::GetFileName($FilePath)
    $fileDir = [System.IO.Path]::GetDirectoryName($FilePath)
    
    # Vérifier si le fichier correspond à une règle
    foreach ($rule in $rules) {
        foreach ($pattern in $rule.Pattern) {
            if ($fileName -like $pattern) {
                # Vérifier si le fichier est dans un dossier à exclure
                if ($rule.Exclude -and $fileDir -like "*$($rule.Exclude)*") {
                    return $null
                }
                
                return $rule.Destination
            }
        }
    }
    
    # Aucune règle ne correspond
    return $null
}

# Fonction pour organiser un fichier
function Organize-File {
    param (
        [string]$FilePath
    )
    
    $destination = Get-FileDestination -FilePath $FilePath
    
    if ($destination) {
        $fileName = [System.IO.Path]::GetFileName($FilePath)
        $destinationPath = Join-Path -Path $destination -ChildPath $fileName
        
        # Vérifier si le dossier de destination existe
        if (-not (Test-Path -Path $destination -PathType Container)) {
            New-Item -Path $destination -ItemType Directory -Force | Out-Null
        }
        
        # Déplacer le fichier
        if (-not (Test-Path -Path $destinationPath)) {
            Move-Item -Path $FilePath -Destination $destinationPath -Force
            Write-Host "Fichier $fileName déplacé vers $destination" -ForegroundColor Green
        }
    }
}

# Fonction pour gérer les événements de création de fichier
function Handle-FileCreated {
    param (
        [System.IO.FileSystemEventArgs]$Event
    )
    
    $filePath = $Event.FullPath
    
    # Vérifier si le fichier existe toujours (peut avoir été supprimé entre-temps)
    if (Test-Path -Path $filePath -PathType Leaf) {
        Write-Host "Nouveau fichier détecté: $filePath" -ForegroundColor Yellow
        Organize-File -FilePath $filePath
    }
}

# Fonction pour démarrer la surveillance
function Start-FileWatcher {
    param (
        [string]$Path = ".",
        [switch]$Recursive = $true
    )
    
    # Créer un objet FileSystemWatcher
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = (Resolve-Path $Path).Path
    $watcher.IncludeSubdirectories = $Recursive
    
    # Définir les événements à surveiller
    $watcher.EnableRaisingEvents = $true
    
    # Créer les gestionnaires d'événements
    $action = {
        $event = $Event.SourceEventArgs
        $name = $event.Name
        $changeType = $event.ChangeType
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        if ($changeType -eq "Created") {
            Write-Host "[$timestamp] CREATED: $name" -ForegroundColor Green
            Handle-FileCreated -Event $event
        }
    }
    
    # Enregistrer les gestionnaires d'événements
    $handlers = . {
        Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action
    }
    
    Write-Host "Surveillance des fichiers démarrée dans $Path" -ForegroundColor Cyan
    Write-Host "Appuyez sur CTRL+C pour arrêter la surveillance" -ForegroundColor Cyan
    
    try {
        # Maintenir le script en cours d'exécution
        while ($true) {
            Start-Sleep -Seconds 1
        }
    }
    finally {
        # Nettoyer les gestionnaires d'événements
        $handlers | ForEach-Object {
            Unregister-Event -SourceIdentifier $_.Name
        }
        $watcher.EnableRaisingEvents = $false
        $watcher.Dispose()
        Write-Host "Surveillance des fichiers arrêtée" -ForegroundColor Cyan
    }
}

# Exécution principale
if ($args.Count -gt 0) {
    $path = $args[0]
    Start-FileWatcher -Path $path
} else {
    Start-FileWatcher
}
