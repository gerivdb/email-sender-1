# Script pour surveiller et organiser automatiquement les nouveaux fichiers
try {
    Write-Host "=== Organisation automatique des fichiers ===" -ForegroundColor Cyan

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
        @("configure-*.ps1", "development/scripts/setup", "Scripts de configuration"),
        @("setup-*.ps1", "development/scripts/setup", "Scripts d'installation"),
        @("update-*.ps1", "development/scripts/maintenance", "Scripts de mise à jour"),
        @("cleanup-*.ps1", "development/scripts/maintenance", "Scripts de nettoyage"),
        @("check-*.ps1", "development/scripts/maintenance", "Scripts de vérification"),
        @("organize-*.ps1", "development/scripts/maintenance", "Scripts d'organisation")
    )

    # Traitement des règles
    foreach ($rule in $autoOrganizeRules) {
        try {
            Process-OrganizationRule -Rule $rule
        }
        catch {
            Write-Error "Erreur lors du traitement de la règle : $_"
        }
    }

    Write-Host "`n=== Organisation automatique terminée ===" -ForegroundColor Cyan

    # Créer un hook Git pour organiser automatiquement les fichiers lors des commits
    $gitHooksDir = "$projectRoot\.git\hooks"
    if (Test-Path "$projectRoot\.git") {
        if (-not (Test-Path $gitHooksDir)) {
            New-Item -ItemType Directory -Path $gitHooksDir -Force | Out-Null
        }

        Set-GitHooks -HooksDir $gitHooksDir -ProjectRoot $projectRoot
    }
}
catch {
    Write-Error "Erreur lors de l'organisation automatique : $_"
    exit 1
}
finally {
    Write-Host "Fin du processus d'organisation automatique" -ForegroundColor Cyan
}

# Obtenir le chemin racine du projet (ou se trouve ce script)
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Set-Location $projectRoot

# Verifier si les dossiers existent, sinon les creer
try {
    foreach ($rule in $autoOrganizeRules) {
        $destination = $rule[1]
        if (-not (Test-Path "$projectRoot\$destination")) {
            New-Item -ItemType Directory -Path "$projectRoot\$destination" -Force | Out-Null
            Write-Host "Dossier $destination cree" -ForegroundColor Green
        }
    }
}
catch {
    Write-Error "Erreur lors de la création des dossiers : $_"
    exit 1
}

# Fonction pour deplacer un fichier automatiquement
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

    # Fichiers a conserver a la racine
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

    # Ne pas deplacer les fichiers a conserver a la racine
    if ($keepFiles -contains $fileName -and (Split-Path $SourcePath -Parent) -eq $projectRoot) {
        return
    }

    # Ne pas deplacer les fichiers deja dans le bon dossier
    $sourceDir = Split-Path $SourcePath -Parent
    $expectedPath = Join-Path $projectRoot $DestinationFolder
    if ($sourceDir -eq $expectedPath) {
        return
    }

    # Verifier si le fichier existe deja a destination
    if (Test-Path $destinationPath) {
        # Comparer les dates de modification
        $sourceFile = Get-Item $SourcePath
        $destFile = Get-Item $destinationPath

        if ($sourceFile.LastWriteTime -gt $destFile.LastWriteTime) {
            # Le fichier source est plus recent
            Move-Item -Path $SourcePath -Destination $destinationPath -Force
            Write-Host "  [MAJ] $fileName deplace vers $DestinationFolder (plus recent)" -ForegroundColor Blue
        }
    } else {
        # Le fichier n'existe pas a destination
        Move-Item -Path $SourcePath -Destination $destinationPath
        Write-Host "  [OK] $fileName deplace vers $DestinationFolder" -ForegroundColor Green
    }
}

# Rechercher et organiser les fichiers
Write-Host "`nRecherche de fichiers a organiser..." -ForegroundColor Yellow

try {
    foreach ($rule in $autoOrganizeRules) {
        $pattern = $rule[0]
        $destination = $rule[1]
        $description = $rule[2]

        # Trouver les fichiers correspondant au pattern a la racine
        $files = Get-ChildItem -Path $projectRoot -Filter $pattern -File |
                 Where-Object { $_.DirectoryName -eq $projectRoot }

        if ($files.Count -gt 0) {
            Write-Host "`nTraitement des fichiers $description ($pattern)..." -ForegroundColor Cyan
            Write-Host "  $($files.Count) fichier(s) trouve(s)" -ForegroundColor Yellow

            foreach ($file in $files) {
                Move-FileAutomatically -SourcePath $file.FullName -DestinationFolder $destination -Description $description
            }
        }
    }

    # Organiser les fichiers de logs
    $logFiles = Get-ChildItem -Path $projectRoot -Recurse -Include "*.log" -File |
                Where-Object { $_.DirectoryName -ne "$projectRoot\logs" }

    if ($logFiles.Count -gt 0) {
        Write-Host "`nTraitement des fichiers de logs..." -ForegroundColor Cyan
        Write-Host "  $($logFiles.Count) fichier(s) de logs trouve(s)" -ForegroundColor Yellow

        foreach ($file in $logFiles) {
            Move-FileAutomatically -SourcePath $file.FullName -DestinationFolder "logs" -Description "Fichiers de logs"
        }
    }

    Write-Host "`n=== Organisation automatique terminee ===" -ForegroundColor Cyan

    # Creer un fichier de hook Git pour organiser automatiquement les fichiers lors des commits
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
powershell -ExecutionPolicy Bypass -File "$projectRoot\scripts\maintenance\auto-organize.ps1"

# Ajouter les fichiers deplaces au commit
git add .
"@
        Set-Content -Path $preCommitHookPath -Value $preCommitHookContent -Encoding UTF8

        # Rendre le hook exécutable sous Unix/Linux
        if ($IsLinux -or $IsMacOS) {
            chmod +x $preCommitHookPath
        }
    }
}
catch {
    Write-Host "`nErreur lors de l'organisation des fichiers : $_" -ForegroundColor Red
    exit 1
}
finally {
    Write-Host "`nPour configurer l'organisation automatique periodique, vous pouvez creer une tache planifiee:"
    Write-Host "1. Ouvrez le Planificateur de taches Windows"
    Write-Host "2. Creez une nouvelle tache qui execute:"
    Write-Host "   powershell -ExecutionPolicy Bypass -File `"$projectRoot\scripts\maintenance\auto-organize.ps1`""
    Write-Host "3. Definissez la frequence souhaitee (par exemple, quotidienne)"
}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}






