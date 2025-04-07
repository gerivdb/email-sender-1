# Script pour organiser automatiquement les fichiers en mode silencieux
# Ce script peut Ãªtre exÃ©cutÃ© pÃ©riodiquement via une tÃ¢che planifiÃ©e sans interaction utilisateur

# Obtenir le chemin racine du projet (oÃ¹ se trouve ce script)
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Set-Location $projectRoot

# CrÃ©er un fichier de log
$logFile = "$projectRoot\logs\auto-organize-$(Get-Date -Format 'yyyy-MM-dd').log"
$logFolder = Split-Path $logFile -Parent

if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
}

# Fonction pour Ã©crire dans le log
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    Add-Content -Path $logFile -Value $logMessage
}

Write-Log "DÃ©but de l'organisation automatique des fichiers"

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
        Write-Log "Dossier $destination crÃ©Ã©"
    }
}

# Fonction pour dÃ©placer un fichier automatiquement
function Move-FileAutomatically {
    param (
        [string]$SourcePath,
        [string]$DestinationFolder,
        [string]$Description
    )

    $fileName = Split-Path $SourcePath -Leaf
    $destinationPath = Join-Path $DestinationFolder $fileName

    # Ne pas dÃ©placer les fichiers Ã  conserver Ã  la racine
    if ($keepFiles -contains $fileName) {
        Write-Log "Fichier $fileName conservÃ© Ã  la racine (fichier essentiel)"
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
            Write-Log "Fichier $fileName dÃ©placÃ© vers $DestinationFolder (plus rÃ©cent)"
        }
    } else {
        # Le fichier n'existe pas Ã  destination
        Move-Item -Path $SourcePath -Destination $destinationPath
        Write-Log "Fichier $fileName dÃ©placÃ© vers $DestinationFolder"
    }
}

# Rechercher et organiser les fichiers
Write-Log "Recherche de fichiers Ã  organiser..."

foreach ($rule in $autoOrganizeRules) {
    $pattern = $rule[0]
    $destination = $rule[1]
    $description = $rule[2]

    # Trouver les fichiers correspondant au pattern Ã  la racine
    $files = Get-ChildItem -Path $projectRoot -Filter $pattern -File |
             Where-Object { $_.DirectoryName -eq $projectRoot }

    if ($files.Count -gt 0) {
        Write-Log "Traitement des fichiers $description ($pattern) - $($files.Count) fichier(s) trouvÃ©(s)"

        foreach ($file in $files) {
            Move-FileAutomatically -SourcePath $file.FullName -DestinationFolder $destination -Description $description
        }
    }
}

# Organiser les fichiers de logs
$logFiles = Get-ChildItem -Path $projectRoot -Recurse -Include "*.log" -File |
            Where-Object { $_.DirectoryName -ne "$projectRoot\logs" }

if ($logFiles.Count -gt 0) {
    Write-Log "Traitement des fichiers de logs - $($logFiles.Count) fichier(s) de logs trouvÃ©(s)"

    foreach ($file in $logFiles) {
        Move-FileAutomatically -SourcePath $file.FullName -DestinationFolder "logs" -Description "Fichiers de logs"
    }
}

Write-Log "Organisation automatique terminÃ©e"

# CrÃ©er un hook Git pour organiser automatiquement les fichiers lors des commits
$gitHooksDir = "$projectRoot\.git\hooks"
if (Test-Path "$projectRoot\.git") {
    if (-not (Test-Path $gitHooksDir)) {
        New-Item -ItemType Directory -Path $gitHooksDir -Force | Out-Null
    }

    $preCommitHookPath = "$gitHooksDir\pre-commit"
    $preCommitHookContent = @"
#!/bin/sh
# Pre-commit hook pour organiser automatiquement les fichiers

echo "Organisation automatique des fichiers avant commit..."
powershell -ExecutionPolicy Bypass -File "$projectRoot\scripts\maintenance\auto-organize-silent.ps1"

# Ajouter les fichiers dÃ©placÃ©s au commit
git add .

exit 0
"@

    Set-Content -Path $preCommitHookPath -Value $preCommitHookContent -NoNewline

    # Rendre le hook exÃ©cutable sous Unix
    if ($IsLinux -or $IsMacOS) {
        & chmod +x $preCommitHookPath
    }

    Write-Log "Hook Git pre-commit configurÃ© pour l'organisation automatique"
}

