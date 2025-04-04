# Script pour surveiller en temps réel les nouveaux fichiers à la racine et les organiser automatiquement
# Ce script utilise FileSystemWatcher pour détecter les nouveaux fichiers et les déplacer automatiquement

Write-Host "=== Surveillance en temps réel des nouveaux fichiers ===" -ForegroundColor Cyan

# Obtenir le chemin racine du projet
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Set-Location $projectRoot

Write-Host "Surveillance du dossier: $projectRoot" -ForegroundColor Yellow

# Règles d'organisation automatique
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
    @("update-*.ps1", "scripts/maintenance", "Scripts de mise à jour"),
    @("cleanup-*.ps1", "scripts/maintenance", "Scripts de nettoyage"),
    @("check-*.ps1", "scripts/maintenance", "Scripts de vérification"),
    @("organize-*.ps1", "scripts/maintenance", "Scripts d'organisation"),
    @("GUIDE_*.md", "docs/guides", "Guides d'utilisation"),
    @("*.md", "md", "Fichiers Markdown (sauf standards GitHub)"),
    @("*.md", "md", "Fichiers Markdown (sauf standards GitHub)"),
    @("*.log", "logs", "Fichiers de logs"),
    @("*.env", "config", "Fichiers d'environnement"),
    @("*.config", "config", "Fichiers de configuration"),
    @("start-*.cmd", "tools", "Scripts de démarrage"),
    @("*.cmd", "cmd", "Fichiers de commande Windows (sauf standards GitHub)"),
    @("*.cmd", "cmd", "Fichiers de commande Windows (sauf standards GitHub)"),
    @("*.py", "src", "Scripts Python")
)

# Fichiers à conserver à la racine
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

# Vérifier si les dossiers existent, sinon les créer
foreach ($rule in $autoOrganizeRules) {
    $destination = $rule[1]
    if (-not (Test-Path "$projectRoot\$destination")) {
        New-Item -ItemType Directory -Path "$projectRoot\$destination" -Force | Out-Null
        Write-Host "Dossier $destination créé" -ForegroundColor Green
    }
}

# Fonction pour déplacer un fichier automatiquement
function Move-FileAutomatically {
    param (
        [string]$SourcePath,
        [string]$DestinationFolder,
        [string]$Description
    )

    $fileName = Split-Path $SourcePath -Leaf
    $destinationPath = Join-Path $DestinationFolder $fileName

    # Ne pas déplacer les fichiers à conserver à la racine
    if ($keepFiles -contains $fileName) {
        Write-Host "  [IGNORE] $fileName conservé à la racine (fichier essentiel)" -ForegroundColor Blue
        return
    }

    # Ne pas déplacer les fichiers déjà dans le bon dossier
    $sourceDir = Split-Path $SourcePath -Parent
    $expectedPath = Join-Path $projectRoot $DestinationFolder
    if ($sourceDir -eq $expectedPath) {
        return
    }

    # Vérifier si le fichier existe déjà à destination
    if (Test-Path $destinationPath) {
        # Comparer les dates de modification
        $sourceFile = Get-Item $SourcePath
        $destFile = Get-Item $destinationPath

        if ($sourceFile.LastWriteTime -gt $destFile.LastWriteTime) {
            # Le fichier source est plus récent
            Move-Item -Path $SourcePath -Destination $destinationPath -Force
            Write-Host "  [MAJ] $fileName déplacé vers $DestinationFolder (plus récent)" -ForegroundColor Blue
        }
    } else {
        # Le fichier n'existe pas à destination
        Move-Item -Path $SourcePath -Destination $destinationPath
        Write-Host "  [OK] $fileName déplacé vers $DestinationFolder" -ForegroundColor Green
    }
}

# Fonction pour déterminer le dossier de destination d'un fichier
function Get-FileDestination {
    param (
        [string]$FilePath
    )

    $fileName = Split-Path $FilePath -Leaf

    # Ne pas déplacer les fichiers à conserver à la racine
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

    # Si aucune règle ne correspond, retourner null
    return $null
}

# Fonction appelée lorsqu'un nouveau fichier est créé
function OnCreated {
    param(
        [System.IO.FileSystemEventArgs]$event
    )

    $filePath = $event.FullPath
    $fileName = Split-Path $filePath -Leaf

    # Attendre que le fichier soit complètement écrit
    Start-Sleep -Seconds 1

    # Vérifier si le fichier existe toujours (il pourrait avoir été supprimé ou déplacé entre-temps)
    if (-not (Test-Path $filePath)) {
        return
    }

    # Vérifier si c'est un fichier (pas un dossier)
    if ((Get-Item $filePath) -is [System.IO.DirectoryInfo]) {
        return
    }

    # Déterminer le dossier de destination
    $destination = Get-FileDestination -FilePath $filePath

    if ($destination -ne $null) {
        Write-Host "Nouveau fichier détecté: $fileName" -ForegroundColor Yellow

        # Vérifier si le dossier de destination existe
        if (-not (Test-Path "$projectRoot\$destination")) {
            New-Item -ItemType Directory -Path "$projectRoot\$destination" -Force | Out-Null
            Write-Host "Dossier $destination créé" -ForegroundColor Green
        }

        # Déplacer le fichier
        Move-FileAutomatically -SourcePath $filePath -DestinationFolder $destination -Description ""
    }
}

# Créer un FileSystemWatcher pour surveiller la racine du projet
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $projectRoot
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

# Définir les événements à surveiller
$action = {
    OnCreated -event $Event
}

# Enregistrer l'événement pour la création de fichiers
$created = Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action

Write-Host "Surveillance en cours... Appuyez sur CTRL+C pour arrêter." -ForegroundColor Green

try {
    # Garder le script en cours d'exécution
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    # Nettoyer les événements enregistrés lors de l'arrêt du script
    Unregister-Event -SourceIdentifier $created.Name
    $watcher.Dispose()
    Write-Host "Surveillance arrêtée." -ForegroundColor Yellow
}

