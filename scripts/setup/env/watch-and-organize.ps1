# Script pour surveiller en temps rÃ©el les nouveaux fichiers Ã  la racine et les organiser automatiquement
# Ce script utilise FileSystemWatcher pour dÃ©tecter les nouveaux fichiers et les dÃ©placer automatiquement

Write-Host "=== Surveillance en temps rÃ©el des nouveaux fichiers ===" -ForegroundColor Cyan

# Obtenir le chemin racine du projet
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Set-Location $projectRoot

Write-Host "Surveillance du dossier: $projectRoot" -ForegroundColor Yellow

# RÃ¨gles d'organisation automatique
$autoOrganizeRules = @(
    # Format: [pattern, destination, description]
    @("*.json", "all-workflows/original", "Workflows n8n"),
    @("*.workflow.json", "all-workflows/original", "Workflows n8n"),
    @("mcp-*.cmd", "src/mcp/batch", "Fichiers batch MCP"),
    @("gateway.exe.cmd", "src/mcp/batch", "Fichier batch Gateway"),
    @("*.yaml", "src/mcp/config", "Fichiers config YAML"),
    @("mcp-config*.json", "src/mcp/config", "Fichiers config MCP"),
    @("*.ps1", "scripts", "Scripts PowerShell"),
    @("configure-*.ps1", "scripts/setup", "Scripts de configuration"),
    @("setup-*.ps1", "scripts/setup", "Scripts d'installation"),
    @("update-*.ps1", "scripts/maintenance", "Scripts de mise Ã  jour"),
    @("cleanup-*.ps1", "scripts/maintenance", "Scripts de nettoyage"),
    @("check-*.ps1", "scripts/maintenance", "Scripts de vÃ©rification"),
    @("organize-*.ps1", "scripts/maintenance", "Scripts d'organisation"),
    @("GUIDE_*.md", "docs/guides", "Guides d'utilisation"),
    @("*.md", "md", "Fichiers Markdown (sauf standards GitHub)"),
    @("*.md", "md", "Fichiers Markdown (sauf standards GitHub)"),
    @("*.log", "logs", "Fichiers de logs"),
    @("*.env", "config", "Fichiers d'environnement"),
    @("*.config", "config", "Fichiers de configuration"),
    @("start-*.cmd", "tools", "Scripts de dÃ©marrage"),
    @("*.cmd", "cmd", "Fichiers de commande Windows (sauf standards GitHub)"),
    @("*.cmd", "cmd", "Fichiers de commande Windows (sauf standards GitHub)"),
    @("*.py", "src", "Scripts Python")
)

# Fichiers Ã  conserver Ã  la racine
$keepFiles = @(
    "README.md",
    ".gitignore",
    "package.json",
    "package-lock.json",
    "CHANGELOG.md",
    "LICENSE",
    "CONTRIBUTING.md",
    "CODE_OF_CONDUCT.md"
)

# VÃ©rifier si les dossiers existent, sinon les crÃ©er
foreach ($rule in $autoOrganizeRules) {
    $destination = $rule[1]
    if (-not (Test-Path "$projectRoot\$destination")) {
        New-Item -ItemType Directory -Path "$projectRoot\$destination" -Force | Out-Null
        Write-Host "Dossier $destination crÃ©Ã©" -ForegroundColor Green
    }
}

# Fonction pour dÃ©placer un fichier automatiquement

# Script pour surveiller en temps rÃ©el les nouveaux fichiers Ã  la racine et les organiser automatiquement
# Ce script utilise FileSystemWatcher pour dÃ©tecter les nouveaux fichiers et les dÃ©placer automatiquement

Write-Host "=== Surveillance en temps rÃ©el des nouveaux fichiers ===" -ForegroundColor Cyan

# Obtenir le chemin racine du projet
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Set-Location $projectRoot

Write-Host "Surveillance du dossier: $projectRoot" -ForegroundColor Yellow

# RÃ¨gles d'organisation automatique
$autoOrganizeRules = @(
    # Format: [pattern, destination, description]
    @("*.json", "all-workflows/original", "Workflows n8n"),
    @("*.workflow.json", "all-workflows/original", "Workflows n8n"),
    @("mcp-*.cmd", "src/mcp/batch", "Fichiers batch MCP"),
    @("gateway.exe.cmd", "src/mcp/batch", "Fichier batch Gateway"),
    @("*.yaml", "src/mcp/config", "Fichiers config YAML"),
    @("mcp-config*.json", "src/mcp/config", "Fichiers config MCP"),
    @("*.ps1", "scripts", "Scripts PowerShell"),
    @("configure-*.ps1", "scripts/setup", "Scripts de configuration"),
    @("setup-*.ps1", "scripts/setup", "Scripts d'installation"),
    @("update-*.ps1", "scripts/maintenance", "Scripts de mise Ã  jour"),
    @("cleanup-*.ps1", "scripts/maintenance", "Scripts de nettoyage"),
    @("check-*.ps1", "scripts/maintenance", "Scripts de vÃ©rification"),
    @("organize-*.ps1", "scripts/maintenance", "Scripts d'organisation"),
    @("GUIDE_*.md", "docs/guides", "Guides d'utilisation"),
    @("*.md", "md", "Fichiers Markdown (sauf standards GitHub)"),
    @("*.md", "md", "Fichiers Markdown (sauf standards GitHub)"),
    @("*.log", "logs", "Fichiers de logs"),
    @("*.env", "config", "Fichiers d'environnement"),
    @("*.config", "config", "Fichiers de configuration"),
    @("start-*.cmd", "tools", "Scripts de dÃ©marrage"),
    @("*.cmd", "cmd", "Fichiers de commande Windows (sauf standards GitHub)"),
    @("*.cmd", "cmd", "Fichiers de commande Windows (sauf standards GitHub)"),
    @("*.py", "src", "Scripts Python")
)

# Fichiers Ã  conserver Ã  la racine
$keepFiles = @(
    "README.md",
    ".gitignore",
    "package.json",
    "package-lock.json",
    "CHANGELOG.md",
    "LICENSE",
    "CONTRIBUTING.md",
    "CODE_OF_CONDUCT.md"
)

# VÃ©rifier si les dossiers existent, sinon les crÃ©er
foreach ($rule in $autoOrganizeRules) {
    $destination = $rule[1]
    if (-not (Test-Path "$projectRoot\$destination")) {
        New-Item -ItemType Directory -Path "$projectRoot\$destination" -Force | Out-Null
        Write-Host "Dossier $destination crÃ©Ã©" -ForegroundColor Green
    }
}

# Fonction pour dÃ©placer un fichier automatiquement
function Move-FileAutomatically {
    param (
        [string]$SourcePath,
        [string]$DestinationFolder,
        [string]$Description
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


    $fileName = Split-Path $SourcePath -Leaf
    $destinationPath = Join-Path $DestinationFolder $fileName

    # Ne pas dÃ©placer les fichiers Ã  conserver Ã  la racine
    if ($keepFiles -contains $fileName) {
        Write-Host "  [IGNORE] $fileName conservÃ© Ã  la racine (fichier essentiel)" -ForegroundColor Blue
        return
    }

    # Ne pas dÃ©placer les fichiers dÃ©jÃ  dans le bon dossier
    $sourceDir = Split-Path $SourcePath -Parent
    $expectedPath = Join-Path $projectRoot $DestinationFolder
    if ($sourceDir -eq $expectedPath) {
        return
    }

    # VÃ©rifier si le fichier existe dÃ©jÃ  Ã  destination
    if (Test-Path $destinationPath) {
        # Comparer les dates de modification
        $sourceFile = Get-Item $SourcePath
        $destFile = Get-Item $destinationPath

        if ($sourceFile.LastWriteTime -gt $destFile.LastWriteTime) {
            # Le fichier source est plus rÃ©cent
            Move-Item -Path $SourcePath -Destination $destinationPath -Force
            Write-Host "  [MAJ] $fileName dÃ©placÃ© vers $DestinationFolder (plus rÃ©cent)" -ForegroundColor Blue
        }
    } else {
        # Le fichier n'existe pas Ã  destination
        Move-Item -Path $SourcePath -Destination $destinationPath
        Write-Host "  [OK] $fileName dÃ©placÃ© vers $DestinationFolder" -ForegroundColor Green
    }
}

# Fonction pour dÃ©terminer le dossier de destination d'un fichier
function Get-FileDestination {
    param (
        [string]$FilePath
    )

    $fileName = Split-Path $FilePath -Leaf

    # Ne pas dÃ©placer les fichiers Ã  conserver Ã  la racine
    if ($keepFiles -contains $fileName) {
        return $null
    }

    foreach ($rule in $autoOrganizeRules) {
        $pattern = $rule[0]
        $destination = $rule[1]

        if ($fileName -like $pattern) {
            return $destination
        }
    }

    # Si aucune rÃ¨gle ne correspond, retourner null
    return $null
}

# Fonction appelÃ©e lorsqu'un nouveau fichier est crÃ©Ã©
function OnCreated {
    param(
        [System.IO.FileSystemEventArgs]$event
    )

    $filePath = $event.FullPath
    $fileName = Split-Path $filePath -Leaf

    # Attendre que le fichier soit complÃ¨tement Ã©crit
    Start-Sleep -Seconds 1

    # VÃ©rifier si le fichier existe toujours (il pourrait avoir Ã©tÃ© supprimÃ© ou dÃ©placÃ© entre-temps)
    if (-not (Test-Path $filePath)) {
        return
    }

    # VÃ©rifier si c'est un fichier (pas un dossier)
    if ((Get-Item $filePath) -is [System.IO.DirectoryInfo]) {
        return
    }

    # DÃ©terminer le dossier de destination
    $destination = Get-FileDestination -FilePath $filePath

    if ($destination -ne $null) {
        Write-Host "Nouveau fichier dÃ©tectÃ©: $fileName" -ForegroundColor Yellow

        # VÃ©rifier si le dossier de destination existe
        if (-not (Test-Path "$projectRoot\$destination")) {
            New-Item -ItemType Directory -Path "$projectRoot\$destination" -Force | Out-Null
            Write-Host "Dossier $destination crÃ©Ã©" -ForegroundColor Green
        }

        # DÃ©placer le fichier
        Move-FileAutomatically -SourcePath $filePath -DestinationFolder $destination -Description ""
    }
}

# CrÃ©er un FileSystemWatcher pour surveiller la racine du projet
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $projectRoot
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

# DÃ©finir les Ã©vÃ©nements Ã  surveiller
$action = {
    OnCreated -event $Event
}

# Enregistrer l'Ã©vÃ©nement pour la crÃ©ation de fichiers
$created = Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action

Write-Host "Surveillance en cours... Appuyez sur CTRL+C pour arrÃªter." -ForegroundColor Green

try {
    # Garder le script en cours d'exÃ©cution
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    # Nettoyer les Ã©vÃ©nements enregistrÃ©s lors de l'arrÃªt du script
    Unregister-Event -SourceIdentifier $created.Name
    $watcher.Dispose()
    Write-Host "Surveillance arrÃªtÃ©e." -ForegroundColor Yellow
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
