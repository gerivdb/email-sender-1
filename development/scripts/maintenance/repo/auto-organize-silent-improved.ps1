# Script pour organiser automatiquement les fichiers en mode silencieux
# Ce script peut ÃƒÂªtre exÃƒÂ©cutÃƒÂ© pÃƒÂ©riodiquement via une tÃƒÂ¢che planifiÃƒÂ©e sans interaction utilisateur
# Version amÃƒÂ©liorÃƒÂ©e avec gestion des conflits de hooks Git

# Obtenir le chemin racine du projet (oÃƒÂ¹ se trouve ce script)
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Set-Location $projectRoot

# CrÃƒÂ©er un fichier de log
$logFile = "$projectRoot\logs\auto-organize-$(Get-Date -Format 'yyyy-MM-dd').log"
$logFolder = Split-Path $logFile -Parent

if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
}

# Fonction pour ÃƒÂ©crire dans le log
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    Add-Content -Path $logFile -Value $logMessage
}

Write-Log "DÃƒÂ©but de l'organisation automatique des fichiers"

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
    @("*.log", "logs", "Fichiers de logs"),
    @("*.env", "config", "Fichiers d'environnement"),
    @("*.config", "config", "Fichiers de configuration"),
    @("start-*.cmd", "tools", "Scripts de dÃƒÂ©marrage"),
    @("*.cmd", "cmd", "Fichiers de commande Windows (sauf standards GitHub)"),
    @("*.py", "src", "Scripts Python")
)

# Fichiers ÃƒÂ  conserver ÃƒÂ  la racine
$keepFiles = @(
    "README.md",
    ".gitignore",
    ".gitattributes",
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
        Write-Log "Dossier $destination crÃƒÂ©ÃƒÂ©"
    }
}

# Fonction pour dÃƒÂ©placer un fichier automatiquement
function Move-FileAutomatically {
    param (
        [string]$SourcePath,
        [string]$DestinationFolder,
        [string]$Description
    )

    $fileName = Split-Path $SourcePath -Leaf
    $destinationPath = Join-Path $DestinationFolder $fileName

    # Ne pas dÃƒÂ©placer les fichiers ÃƒÂ  conserver ÃƒÂ  la racine
    if ($keepFiles -contains $fileName) {
        Write-Log "Fichier $fileName conservÃƒÂ© ÃƒÂ  la racine (fichier essentiel)"
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
            try {
                Move-Item -Path $SourcePath -Destination $destinationPath -Force
                Write-Log "Fichier $fileName dÃƒÂ©placÃƒÂ© vers $DestinationFolder (plus rÃƒÂ©cent)"
            }
            catch {
                Write-Log "Erreur lors du dÃƒÂ©placement de $fileName : $_" -Level "ERROR"
            }
        }
    } else {
        # Le fichier n'existe pas ÃƒÂ  destination
        try {
            Move-Item -Path $SourcePath -Destination $destinationPath
            Write-Log "Fichier $fileName dÃƒÂ©placÃƒÂ© vers $DestinationFolder"
        }
        catch {
            Write-Log "Erreur lors du dÃƒÂ©placement de $fileName : $_" -Level "ERROR"
        }
    }
}

# Rechercher et organiser les fichiers
Write-Log "Recherche de fichiers ÃƒÂ  organiser..."

foreach ($rule in $autoOrganizeRules) {
    $pattern = $rule[0]
    $destination = $rule[1]
    $description = $rule[2]

    # Trouver les fichiers correspondant au pattern ÃƒÂ  la racine
    $files = Get-ChildItem -Path $projectRoot -Filter $pattern -File |
             Where-Object { $_.DirectoryName -eq $projectRoot }

    if ($files.Count -gt 0) {
        Write-Log "Traitement des fichiers $description ($pattern) - $($files.Count) fichier(s) trouvÃƒÂ©(s)"

        foreach ($file in $files) {
            Move-FileAutomatically -SourcePath $file.FullName -DestinationFolder $destination -Description $description
        }
    }
}

# Organiser les fichiers de logs
$logFiles = Get-ChildItem -Path $projectRoot -Recurse -Include "*.log" -File |
            Where-Object { $_.DirectoryName -ne "$projectRoot\logs" }

if ($logFiles.Count -gt 0) {
    Write-Log "Traitement des fichiers de logs - $($logFiles.Count) fichier(s) de logs trouvÃƒÂ©(s)"

    foreach ($file in $logFiles) {
        Move-FileAutomatically -SourcePath $file.FullName -DestinationFolder "logs" -Description "Fichiers de logs"
    }
}

Write-Log "Organisation automatique terminÃƒÂ©e"

# Fonction pour vÃƒÂ©rifier si un fichier est verrouillÃƒÂ©
function Test-FileLock {
    param (
        [parameter(Mandatory = $true)]
        [string]$Path
    )

    $locked = $false

    if (Test-Path -Path $Path) {
        try {
            $fileStream = [System.IO.File]::Open($Path, 'Open', 'Write')
            $fileStream.Close()
            $fileStream.Dispose()
            $locked = $false
        }
        catch {
            $locked = $true
        }
    }

    return $locked
}

# CrÃƒÂ©er un hook Git pour organiser automatiquement les fichiers lors des commits
$gitHooksDir = "$projectRoot\.git\hooks"
if (Test-Path "$projectRoot\.git") {
    if (-not (Test-Path $gitHooksDir)) {
        try {
            New-Item -ItemType Directory -Path $gitHooksDir -Force | Out-Null
            Write-Log "Dossier de hooks Git crÃƒÂ©ÃƒÂ©"
        }
        catch {
            Write-Log "Erreur lors de la crÃƒÂ©ation du dossier de hooks Git : $_" -Level "ERROR"
        }
    }

    $preCommitHookPath = "$gitHooksDir\pre-commit"

    # VÃƒÂ©rifier si le fichier pre-commit est verrouillÃƒÂ©
    $isLocked = Test-FileLock -Path $preCommitHookPath

    if ($isLocked) {
        Write-Log "Le fichier pre-commit hook est actuellement verrouillÃƒÂ© ou utilisÃƒÂ© par un autre processus" -Level "WARNING"
        Write-Log "Le hook Git pre-commit n'a pas ÃƒÂ©tÃƒÂ© mis ÃƒÂ  jour"
    }
    else {
        # CrÃƒÂ©er un fichier temporaire pour le hook
        $tempHookPath = "$gitHooksDir\pre-commit.tmp"

        $preCommitHookContent = @"
#!/bin/sh
# Pre-commit hook amÃƒÂ©liorÃƒÂ© pour organiser automatiquement les fichiers

echo "Organisation automatique des fichiers avant commit..."

# Obtenir le chemin du rÃƒÂ©pertoire Git
GIT_DIR=$(git rev-parse --git-dir)
PROJECT_ROOT=$(git rev-parse --show-toplevel)

# DÃƒÂ©finir le chemin relatif du script
SCRIPT_PATH="\$PROJECT_ROOT/development/scripts/maintenance/auto-organize-silent-improved.ps1"

# VÃƒÂ©rifier si le script existe
if [ -f "\$SCRIPT_PATH" ]; then
    # ExÃƒÂ©cuter le script amÃƒÂ©liorÃƒÂ© qui gÃƒÂ¨re les conflits de fichiers
    powershell -ExecutionPolicy Bypass -File "\$SCRIPT_PATH"
    SCRIPT_EXIT_CODE=\$?

    if [ \$SCRIPT_EXIT_CODE -ne 0 ]; then
        echo "Avertissement: Le script d'organisation a rencontrÃƒÂ© des problÃƒÂ¨mes, mais le commit continuera."
    fi
else
    echo "Avertissement: Script d'organisation non trouvÃƒÂ© ÃƒÂ  \$SCRIPT_PATH"
    echo "Le commit continuera sans organisation automatique."
fi

# Ajouter les fichiers dÃƒÂ©placÃƒÂ©s au commit
git add .

exit 0
"@

        try {
            # Ãƒâ€°crire d'abord dans un fichier temporaire
            Set-Content -Path $tempHookPath -Value $preCommitHookContent -NoNewline

            # Puis renommer le fichier temporaire (opÃƒÂ©ration atomique)
            if (Test-Path $preCommitHookPath) {
                Remove-Item -Path $preCommitHookPath -Force
            }
            Rename-Item -Path $tempHookPath -NewName (Split-Path $preCommitHookPath -Leaf)

            Write-Log "Hook Git pre-commit configurÃƒÂ© pour l'organisation automatique"

            # Rendre le hook exÃƒÂ©cutable sous Unix
            if ($IsLinux -or $IsMacOS) {
                & chmod +x $preCommitHookPath
            }
        }
        catch {
            Write-Log "Erreur lors de la configuration du hook Git pre-commit : $_" -Level "ERROR"
        }
    }

    # Configurer ÃƒÂ©galement le hook pre-push
    $prePushHookPath = "$gitHooksDir\pre-push"

    # VÃƒÂ©rifier si le fichier pre-push est verrouillÃƒÂ©
    $isLocked = Test-FileLock -Path $prePushHookPath

    if ($isLocked) {
        Write-Log "Le fichier pre-push hook est actuellement verrouillÃƒÂ© ou utilisÃƒÂ© par un autre processus" -Level "WARNING"
        Write-Log "Le hook Git pre-push n'a pas ÃƒÂ©tÃƒÂ© mis ÃƒÂ  jour"
    }
    else {
        # CrÃƒÂ©er un fichier temporaire pour le hook
        $tempHookPath = "$gitHooksDir\pre-push.tmp"

        $prePushHookContent = @"
#!/bin/sh
# Pre-push hook amÃƒÂ©liorÃƒÂ© pour vÃƒÂ©rifier les changements avant push

echo "VÃƒÂ©rification des changements avant push..."

# Obtenir le chemin du rÃƒÂ©pertoire Git
GIT_DIR=$(git rev-parse --git-dir)
PROJECT_ROOT=$(git rev-parse --show-toplevel)

# DÃƒÂ©finir le chemin relatif du script
SCRIPT_PATH="\$PROJECT_ROOT/development/scripts/utils/git/git-pre-push-check.ps1"

# VÃƒÂ©rifier si le script existe
if [ -f "\$SCRIPT_PATH" ]; then
    # ExÃƒÂ©cuter le script de vÃƒÂ©rification
    powershell -ExecutionPolicy Bypass -File "\$SCRIPT_PATH"
    SCRIPT_EXIT_CODE=\$?

    # VÃƒÂ©rifier le code de sortie du script
    if [ \$SCRIPT_EXIT_CODE -ne 0 ]; then
        echo "VÃƒÂ©rification ÃƒÂ©chouÃƒÂ©e. Push annulÃƒÂ©."
        exit 1
    fi
else
    echo "Avertissement: Script de vÃƒÂ©rification non trouvÃƒÂ© ÃƒÂ  \$SCRIPT_PATH"
    echo "Le push continuera sans vÃƒÂ©rification."
fi

exit 0
"@

        try {
            # Ãƒâ€°crire d'abord dans un fichier temporaire
            Set-Content -Path $tempHookPath -Value $prePushHookContent -NoNewline

            # Puis renommer le fichier temporaire (opÃƒÂ©ration atomique)
            if (Test-Path $prePushHookPath) {
                Remove-Item -Path $prePushHookPath -Force
            }
            Rename-Item -Path $tempHookPath -NewName (Split-Path $prePushHookPath -Leaf)

            Write-Log "Hook Git pre-push configurÃƒÂ© pour la vÃƒÂ©rification avant push"

            # Rendre le hook exÃƒÂ©cutable sous Unix
            if ($IsLinux -or $IsMacOS) {
                & chmod +x $prePushHookPath
            }
        }
        catch {
            Write-Log "Erreur lors de la configuration du hook Git pre-push : $_" -Level "ERROR"
        }
    }
}