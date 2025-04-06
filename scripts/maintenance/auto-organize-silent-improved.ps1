# Script pour organiser automatiquement les fichiers en mode silencieux
# Ce script peut être exécuté périodiquement via une tâche planifiée sans interaction utilisateur
# Version améliorée avec gestion des conflits de hooks Git

# Obtenir le chemin racine du projet (où se trouve ce script)
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Set-Location $projectRoot

# Créer un fichier de log
$logFile = "$projectRoot\logs\auto-organize-$(Get-Date -Format 'yyyy-MM-dd').log"
$logFolder = Split-Path $logFile -Parent

if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
}

# Fonction pour écrire dans le log
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    Add-Content -Path $logFile -Value $logMessage
}

Write-Log "Début de l'organisation automatique des fichiers"

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
    @("*.log", "logs", "Fichiers de logs"),
    @("*.env", "config", "Fichiers d'environnement"),
    @("*.config", "config", "Fichiers de configuration"),
    @("start-*.cmd", "tools", "Scripts de démarrage"),
    @("*.cmd", "cmd", "Fichiers de commande Windows (sauf standards GitHub)"),
    @("*.py", "src", "Scripts Python")
)

# Fichiers à conserver à la racine
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

# Vérifier si les dossiers existent, sinon les créer
foreach ($rule in $autoOrganizeRules) {
    $destination = $rule[1]
    if (-not (Test-Path "$projectRoot\$destination")) {
        New-Item -ItemType Directory -Path "$projectRoot\$destination" -Force | Out-Null
        Write-Log "Dossier $destination créé"
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
        Write-Log "Fichier $fileName conservé à la racine (fichier essentiel)"
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
            try {
                Move-Item -Path $SourcePath -Destination $destinationPath -Force
                Write-Log "Fichier $fileName déplacé vers $DestinationFolder (plus récent)"
            }
            catch {
                Write-Log "Erreur lors du déplacement de $fileName : $_" -Level "ERROR"
            }
        }
    } else {
        # Le fichier n'existe pas à destination
        try {
            Move-Item -Path $SourcePath -Destination $destinationPath
            Write-Log "Fichier $fileName déplacé vers $DestinationFolder"
        }
        catch {
            Write-Log "Erreur lors du déplacement de $fileName : $_" -Level "ERROR"
        }
    }
}

# Rechercher et organiser les fichiers
Write-Log "Recherche de fichiers à organiser..."

foreach ($rule in $autoOrganizeRules) {
    $pattern = $rule[0]
    $destination = $rule[1]
    $description = $rule[2]

    # Trouver les fichiers correspondant au pattern à la racine
    $files = Get-ChildItem -Path $projectRoot -Filter $pattern -File |
             Where-Object { $_.DirectoryName -eq $projectRoot }

    if ($files.Count -gt 0) {
        Write-Log "Traitement des fichiers $description ($pattern) - $($files.Count) fichier(s) trouvé(s)"

        foreach ($file in $files) {
            Move-FileAutomatically -SourcePath $file.FullName -DestinationFolder $destination -Description $description
        }
    }
}

# Organiser les fichiers de logs
$logFiles = Get-ChildItem -Path $projectRoot -Recurse -Include "*.log" -File |
            Where-Object { $_.DirectoryName -ne "$projectRoot\logs" }

if ($logFiles.Count -gt 0) {
    Write-Log "Traitement des fichiers de logs - $($logFiles.Count) fichier(s) de logs trouvé(s)"

    foreach ($file in $logFiles) {
        Move-FileAutomatically -SourcePath $file.FullName -DestinationFolder "logs" -Description "Fichiers de logs"
    }
}

Write-Log "Organisation automatique terminée"

# Fonction pour vérifier si un fichier est verrouillé
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

# Créer un hook Git pour organiser automatiquement les fichiers lors des commits
$gitHooksDir = "$projectRoot\.git\hooks"
if (Test-Path "$projectRoot\.git") {
    if (-not (Test-Path $gitHooksDir)) {
        try {
            New-Item -ItemType Directory -Path $gitHooksDir -Force | Out-Null
            Write-Log "Dossier de hooks Git créé"
        }
        catch {
            Write-Log "Erreur lors de la création du dossier de hooks Git : $_" -Level "ERROR"
        }
    }

    $preCommitHookPath = "$gitHooksDir\pre-commit"

    # Vérifier si le fichier pre-commit est verrouillé
    $isLocked = Test-FileLock -Path $preCommitHookPath

    if ($isLocked) {
        Write-Log "Le fichier pre-commit hook est actuellement verrouillé ou utilisé par un autre processus" -Level "WARNING"
        Write-Log "Le hook Git pre-commit n'a pas été mis à jour"
    }
    else {
        # Créer un fichier temporaire pour le hook
        $tempHookPath = "$gitHooksDir\pre-commit.tmp"

        $preCommitHookContent = @"
#!/bin/sh
# Pre-commit hook amélioré pour organiser automatiquement les fichiers

echo "Organisation automatique des fichiers avant commit..."

# Utiliser une variable pour le chemin du script
SCRIPT_PATH="$($projectRoot.Replace('\', '/'))/scripts/maintenance/auto-organize-silent-improved.ps1"

# Vérifier si le script existe
if [ -f "$SCRIPT_PATH" ]; then
    # Exécuter le script amélioré qui gère les conflits de fichiers
    powershell -ExecutionPolicy Bypass -File "$SCRIPT_PATH"
    SCRIPT_EXIT_CODE=\$?

    if [ \$SCRIPT_EXIT_CODE -ne 0 ]; then
        echo "Avertissement: Le script d'organisation a rencontré des problèmes, mais le commit continuera."
    fi
else
    echo "Avertissement: Script d'organisation non trouvé à $SCRIPT_PATH"
    echo "Le commit continuera sans organisation automatique."
fi

# Ajouter les fichiers déplacés au commit
git add .

exit 0
"@

        try {
            # Écrire d'abord dans un fichier temporaire
            Set-Content -Path $tempHookPath -Value $preCommitHookContent -NoNewline

            # Puis renommer le fichier temporaire (opération atomique)
            if (Test-Path $preCommitHookPath) {
                Remove-Item -Path $preCommitHookPath -Force
            }
            Rename-Item -Path $tempHookPath -NewName (Split-Path $preCommitHookPath -Leaf)

            Write-Log "Hook Git pre-commit configuré pour l'organisation automatique"

            # Rendre le hook exécutable sous Unix
            if ($IsLinux -or $IsMacOS) {
                & chmod +x $preCommitHookPath
            }
        }
        catch {
            Write-Log "Erreur lors de la configuration du hook Git pre-commit : $_" -Level "ERROR"
        }
    }

    # Configurer également le hook pre-push
    $prePushHookPath = "$gitHooksDir\pre-push"

    # Vérifier si le fichier pre-push est verrouillé
    $isLocked = Test-FileLock -Path $prePushHookPath

    if ($isLocked) {
        Write-Log "Le fichier pre-push hook est actuellement verrouillé ou utilisé par un autre processus" -Level "WARNING"
        Write-Log "Le hook Git pre-push n'a pas été mis à jour"
    }
    else {
        # Créer un fichier temporaire pour le hook
        $tempHookPath = "$gitHooksDir\pre-push.tmp"

        $prePushHookContent = @"
#!/bin/sh
# Pre-push hook amélioré pour vérifier les changements avant push

echo "Vérification des changements avant push..."

# Utiliser une variable pour le chemin du script
SCRIPT_PATH="$($projectRoot.Replace('\', '/'))/scripts/utils/git/git-pre-push-check.ps1"

# Vérifier si le script existe
if [ -f "$SCRIPT_PATH" ]; then
    # Exécuter le script de vérification
    powershell -ExecutionPolicy Bypass -File "$SCRIPT_PATH"
    SCRIPT_EXIT_CODE=\$?

    # Vérifier le code de sortie du script
    if [ \$SCRIPT_EXIT_CODE -ne 0 ]; then
        echo "Vérification échouée. Push annulé."
        exit 1
    fi
else
    echo "Avertissement: Script de vérification non trouvé à $SCRIPT_PATH"
    echo "Le push continuera sans vérification."
fi

exit 0
"@

        try {
            # Écrire d'abord dans un fichier temporaire
            Set-Content -Path $tempHookPath -Value $prePushHookContent -NoNewline

            # Puis renommer le fichier temporaire (opération atomique)
            if (Test-Path $prePushHookPath) {
                Remove-Item -Path $prePushHookPath -Force
            }
            Rename-Item -Path $tempHookPath -NewName (Split-Path $prePushHookPath -Leaf)

            Write-Log "Hook Git pre-push configuré pour la vérification avant push"

            # Rendre le hook exécutable sous Unix
            if ($IsLinux -or $IsMacOS) {
                & chmod +x $prePushHookPath
            }
        }
        catch {
            Write-Log "Erreur lors de la configuration du hook Git pre-push : $_" -Level "ERROR"
        }
    }
}