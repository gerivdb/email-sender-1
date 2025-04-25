# Script pour surveiller et organiser automatiquement les nouveaux fichiers
# Ce script surveille le dÃ©pÃ´t et organise automatiquement les nouveaux fichiers

# Importation des modules nÃ©cessaires
Add-Type -AssemblyName System.IO.FileSystem.Watcher

# DÃ©finition des rÃ¨gles d'organisation
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
    # Fichiers de redÃ©marrage
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

# Fonction pour dÃ©terminer la destination d'un fichier

# Script pour surveiller et organiser automatiquement les nouveaux fichiers
# Ce script surveille le dÃ©pÃ´t et organise automatiquement les nouveaux fichiers

# Importation des modules nÃ©cessaires
Add-Type -AssemblyName System.IO.FileSystem.Watcher

# DÃ©finition des rÃ¨gles d'organisation
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
    # Fichiers de redÃ©marrage
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

# Fonction pour dÃ©terminer la destination d'un fichier
function Get-FileDestination {
    param (
        [string]$FilePath
    )

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal

    
    $fileName = [System.IO.Path]::GetFileName($FilePath)
    $fileDir = [System.IO.Path]::GetDirectoryName($FilePath)
    
    # VÃ©rifier si le fichier correspond Ã  une rÃ¨gle
    foreach ($rule in $rules) {
        foreach ($pattern in $rule.Pattern) {
            if ($fileName -like $pattern) {
                # VÃ©rifier si le fichier est dans un dossier Ã  exclure
                if ($rule.Exclude -and $fileDir -like "*$($rule.Exclude)*") {
                    return $null
                }
                
                return $rule.Destination
            }
        }
    }
    
    # Aucune rÃ¨gle ne correspond
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
        
        # VÃ©rifier si le dossier de destination existe
        if (-not (Test-Path -Path $destination -PathType Container)) {
            New-Item -Path $destination -ItemType Directory -Force | Out-Null
        }
        
        # DÃ©placer le fichier
        if (-not (Test-Path -Path $destinationPath)) {
            Move-Item -Path $FilePath -Destination $destinationPath -Force
            Write-Host "Fichier $fileName dÃ©placÃ© vers $destination" -ForegroundColor Green
        }
    }
}

# Fonction pour gÃ©rer les Ã©vÃ©nements de crÃ©ation de fichier
function Handle-FileCreated {
    param (
        [System.IO.FileSystemEventArgs]$Event
    )
    
    $filePath = $Event.FullPath
    
    # VÃ©rifier si le fichier existe toujours (peut avoir Ã©tÃ© supprimÃ© entre-temps)
    if (Test-Path -Path $filePath -PathType Leaf) {
        Write-Host "Nouveau fichier dÃ©tectÃ©: $filePath" -ForegroundColor Yellow
        Organize-File -FilePath $filePath
    }
}

# Fonction pour dÃ©marrer la surveillance
function Start-FileWatcher {
    param (
        [string]$Path = ".",
        [switch]$Recursive = $true
    )
    
    # CrÃ©er un objet FileSystemWatcher
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = (Resolve-Path $Path).Path
    $watcher.IncludeSubdirectories = $Recursive
    
    # DÃ©finir les Ã©vÃ©nements Ã  surveiller
    $watcher.EnableRaisingEvents = $true
    
    # CrÃ©er les gestionnaires d'Ã©vÃ©nements
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
    
    # Enregistrer les gestionnaires d'Ã©vÃ©nements
    $handlers = . {
        Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action
    }
    
    Write-Host "Surveillance des fichiers dÃ©marrÃ©e dans $Path" -ForegroundColor Cyan
    Write-Host "Appuyez sur CTRL+C pour arrÃªter la surveillance" -ForegroundColor Cyan
    
    try {
        # Maintenir le script en cours d'exÃ©cution
        while ($true) {
            Start-Sleep -Seconds 1
        }
    }
    finally {
        # Nettoyer les gestionnaires d'Ã©vÃ©nements
        $handlers | ForEach-Object {
            Unregister-Event -SourceIdentifier $_.Name
        }
        $watcher.EnableRaisingEvents = $false
        $watcher.Dispose()
        Write-Host "Surveillance des fichiers arrÃªtÃ©e" -ForegroundColor Cyan
    }
}

# ExÃ©cution principale
if ($args.Count -gt 0) {
    $path = $args[0]
    Start-FileWatcher -Path $path
} else {
    Start-FileWatcher
}

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
