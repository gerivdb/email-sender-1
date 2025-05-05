# Script pour surveiller en temps rÃƒÂ©el les nouveaux fichiers ÃƒÂ  la racine et les organiser automatiquement
# Ce script utilise FileSystemWatcher pour dÃƒÂ©tecter les nouveaux fichiers et les dÃƒÂ©placer automatiquement

Write-Host "=== Surveillance en temps rÃƒÂ©el des nouveaux fichiers ===" -ForegroundColor Cyan

# Obtenir le chemin racine du projet
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Set-Location $projectRoot

Write-Host "Surveillance du dossier: $projectRoot" -ForegroundColor Yellow

# RÃƒÂ¨gles d'organisation automatique
$autoOrganizeRules = @(
    # Format: [pattern, destination, description]
    @("*.json", "all-workflows/original", "Workflows n8n"),
    @("*.workflow.json", "all-workflows/original", "Workflows n8n"),
    @("mcp-*.cmd", "src/mcp/batch", "Fichiers batch MCP"),
    @("gateway.exe.cmd", "src/mcp/batch", "Fichier batch Gateway"),
    @("*.yaml", "src/mcp/config", "Fichiers config YAML"),
    @("mcp-config*.json", "src/mcp/config", "Fichiers config MCP"),
    @("*.ps1", "scripts", "Scripts PowerShell"),
    @("configure-*.ps1", "development/scripts/setup", "Scripts de configuration"),
    @("setup-*.ps1", "development/scripts/setup", "Scripts d'installation"),
    @("update-*.ps1", "development/scripts/maintenance", "Scripts de mise ÃƒÂ  jour"),
    @("cleanup-*.ps1", "development/scripts/maintenance", "Scripts de nettoyage"),
    @("check-*.ps1", "development/scripts/maintenance", "Scripts de vÃƒÂ©rification"),
    @("organize-*.ps1", "development/scripts/maintenance", "Scripts d'organisation"),
    @("GUIDE_*.md", "docs/guides", "Guides d'utilisation"),
    @("*.md", "md", "Fichiers Markdown (sauf standards GitHub)"),
    @("*.md", "md", "Fichiers Markdown (sauf standards GitHub)"),
    @("*.log", "logs", "Fichiers de logs"),
    @("*.env", "config", "Fichiers d'environnement"),
    @("*.config", "config", "Fichiers de configuration"),
    @("start-*.cmd", "tools", "Scripts de dÃƒÂ©marrage"),
    @("*.cmd", "cmd", "Fichiers de commande Windows (sauf standards GitHub)"),
    @("*.cmd", "cmd", "Fichiers de commande Windows (sauf standards GitHub)"),
    @("*.py", "src", "Scripts Python")
)

# Fichiers ÃƒÂ  conserver ÃƒÂ  la racine
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

# VÃƒÂ©rifier si les dossiers existent, sinon les crÃƒÂ©er
foreach ($rule in $autoOrganizeRules) {
    $destination = $rule[1]
    if (-not (Test-Path "$projectRoot\$destination")) {
        New-Item -ItemType Directory -Path "$projectRoot\$destination" -Force | Out-Null
        Write-Host "Dossier $destination crÃƒÂ©ÃƒÂ©" -ForegroundColor Green
    }
}

# Fonction pour dÃƒÂ©placer un fichier automatiquement

# Script pour surveiller en temps rÃƒÂ©el les nouveaux fichiers ÃƒÂ  la racine et les organiser automatiquement
# Ce script utilise FileSystemWatcher pour dÃƒÂ©tecter les nouveaux fichiers et les dÃƒÂ©placer automatiquement

Write-Host "=== Surveillance en temps rÃƒÂ©el des nouveaux fichiers ===" -ForegroundColor Cyan

# Obtenir le chemin racine du projet
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Set-Location $projectRoot

Write-Host "Surveillance du dossier: $projectRoot" -ForegroundColor Yellow

# RÃƒÂ¨gles d'organisation automatique
$autoOrganizeRules = @(
    # Format: [pattern, destination, description]
    @("*.json", "all-workflows/original", "Workflows n8n"),
    @("*.workflow.json", "all-workflows/original", "Workflows n8n"),
    @("mcp-*.cmd", "src/mcp/batch", "Fichiers batch MCP"),
    @("gateway.exe.cmd", "src/mcp/batch", "Fichier batch Gateway"),
    @("*.yaml", "src/mcp/config", "Fichiers config YAML"),
    @("mcp-config*.json", "src/mcp/config", "Fichiers config MCP"),
    @("*.ps1", "scripts", "Scripts PowerShell"),
    @("configure-*.ps1", "development/scripts/setup", "Scripts de configuration"),
    @("setup-*.ps1", "development/scripts/setup", "Scripts d'installation"),
    @("update-*.ps1", "development/scripts/maintenance", "Scripts de mise ÃƒÂ  jour"),
    @("cleanup-*.ps1", "development/scripts/maintenance", "Scripts de nettoyage"),
    @("check-*.ps1", "development/scripts/maintenance", "Scripts de vÃƒÂ©rification"),
    @("organize-*.ps1", "development/scripts/maintenance", "Scripts d'organisation"),
    @("GUIDE_*.md", "docs/guides", "Guides d'utilisation"),
    @("*.md", "md", "Fichiers Markdown (sauf standards GitHub)"),
    @("*.md", "md", "Fichiers Markdown (sauf standards GitHub)"),
    @("*.log", "logs", "Fichiers de logs"),
    @("*.env", "config", "Fichiers d'environnement"),
    @("*.config", "config", "Fichiers de configuration"),
    @("start-*.cmd", "tools", "Scripts de dÃƒÂ©marrage"),
    @("*.cmd", "cmd", "Fichiers de commande Windows (sauf standards GitHub)"),
    @("*.cmd", "cmd", "Fichiers de commande Windows (sauf standards GitHub)"),
    @("*.py", "src", "Scripts Python")
)

# Fichiers ÃƒÂ  conserver ÃƒÂ  la racine
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

# VÃƒÂ©rifier si les dossiers existent, sinon les crÃƒÂ©er
foreach ($rule in $autoOrganizeRules) {
    $destination = $rule[1]
    if (-not (Test-Path "$projectRoot\$destination")) {
        New-Item -ItemType Directory -Path "$projectRoot\$destination" -Force | Out-Null
        Write-Host "Dossier $destination crÃƒÂ©ÃƒÂ©" -ForegroundColor Green
    }
}

# Fonction pour dÃƒÂ©placer un fichier automatiquement
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
    
    # Ãƒâ€°crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃƒÂ©er le rÃƒÂ©pertoire de logs si nÃƒÂ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'ÃƒÂ©criture dans le journal
    }
}
try {
    # Script principal


    $fileName = Split-Path $SourcePath -Leaf
    $destinationPath = Join-Path $DestinationFolder $fileName

    # Ne pas dÃƒÂ©placer les fichiers ÃƒÂ  conserver ÃƒÂ  la racine
    if ($keepFiles -contains $fileName) {
        Write-Host "  [IGNORE] $fileName conservÃƒÂ© ÃƒÂ  la racine (fichier essentiel)" -ForegroundColor Blue
        return
    }

    # Ne pas dÃƒÂ©placer les fichiers dÃƒÂ©jÃƒÂ  dans le bon dossier
    $sourceDir = Split-Path $SourcePath -Parent
    $expectedPath = Join-Path $projectRoot $DestinationFolder
    if ($sourceDir -eq $expectedPath) {
        return
    }

    # VÃƒÂ©rifier si le fichier existe dÃƒÂ©jÃƒÂ  ÃƒÂ  destination
    if (Test-Path $destinationPath) {
        # Comparer les dates de modification
        $sourceFile = Get-Item $SourcePath
        $destFile = Get-Item $destinationPath

        if ($sourceFile.LastWriteTime -gt $destFile.LastWriteTime) {
            # Le fichier source est plus rÃƒÂ©cent
            Move-Item -Path $SourcePath -Destination $destinationPath -Force
            Write-Host "  [MAJ] $fileName dÃƒÂ©placÃƒÂ© vers $DestinationFolder (plus rÃƒÂ©cent)" -ForegroundColor Blue
        }
    } else {
        # Le fichier n'existe pas ÃƒÂ  destination
        Move-Item -Path $SourcePath -Destination $destinationPath
        Write-Host "  [OK] $fileName dÃƒÂ©placÃƒÂ© vers $DestinationFolder" -ForegroundColor Green
    }
}

# Fonction pour dÃƒÂ©terminer le dossier de destination d'un fichier
function Get-FileDestination {
    param (
        [string]$FilePath
    )

    $fileName = Split-Path $FilePath -Leaf

    # Ne pas dÃƒÂ©placer les fichiers ÃƒÂ  conserver ÃƒÂ  la racine
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

    # Si aucune rÃƒÂ¨gle ne correspond, retourner null
    return $null
}

# Fonction appelÃƒÂ©e lorsqu'un nouveau fichier est crÃƒÂ©ÃƒÂ©
function OnCreated {
    param(
        [System.IO.FileSystemEventArgs]$event
    )

    $filePath = $event.FullPath
    $fileName = Split-Path $filePath -Leaf

    # Attendre que le fichier soit complÃƒÂ¨tement ÃƒÂ©crit
    Start-Sleep -Seconds 1

    # VÃƒÂ©rifier si le fichier existe toujours (il pourrait avoir ÃƒÂ©tÃƒÂ© supprimÃƒÂ© ou dÃƒÂ©placÃƒÂ© entre-temps)
    if (-not (Test-Path $filePath)) {
        return
    }

    # VÃƒÂ©rifier si c'est un fichier (pas un dossier)
    if ((Get-Item $filePath) -is [System.IO.DirectoryInfo]) {
        return
    }

    # DÃƒÂ©terminer le dossier de destination
    $destination = Get-FileDestination -FilePath $filePath

    if ($destination -ne $null) {
        Write-Host "Nouveau fichier dÃƒÂ©tectÃƒÂ©: $fileName" -ForegroundColor Yellow

        # VÃƒÂ©rifier si le dossier de destination existe
        if (-not (Test-Path "$projectRoot\$destination")) {
            New-Item -ItemType Directory -Path "$projectRoot\$destination" -Force | Out-Null
            Write-Host "Dossier $destination crÃƒÂ©ÃƒÂ©" -ForegroundColor Green
        }

        # DÃƒÂ©placer le fichier
        Move-FileAutomatically -SourcePath $filePath -DestinationFolder $destination -Description ""
    }
}

# CrÃƒÂ©er un FileSystemWatcher pour surveiller la racine du projet
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $projectRoot
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

# DÃƒÂ©finir les ÃƒÂ©vÃƒÂ©nements ÃƒÂ  surveiller
$action = {
    OnCreated -event $Event
}

# Enregistrer l'ÃƒÂ©vÃƒÂ©nement pour la crÃƒÂ©ation de fichiers
$created = Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action

Write-Host "Surveillance en cours... Appuyez sur CTRL+C pour arrÃƒÂªter." -ForegroundColor Green

try {
    # Garder le script en cours d'exÃƒÂ©cution
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    # Nettoyer les ÃƒÂ©vÃƒÂ©nements enregistrÃƒÂ©s lors de l'arrÃƒÂªt du script
    Unregister-Event -SourceIdentifier $created.Name
    $watcher.Dispose()
    Write-Host "Surveillance arrÃƒÂªtÃƒÂ©e." -ForegroundColor Yellow
}


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃƒÂ©cution du script terminÃƒÂ©e."
}
