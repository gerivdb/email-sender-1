# Script pour organiser automatiquement les fichiers en mode silencieux
try {
    # Obtenir le chemin racine du projet
    $projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
    Set-Location $projectRoot

    # CrÃ©er un fichier de log
    $logFile = "$projectRoot\logs\auto-organize-$(Get-Date -Format 'yyyy-MM-dd').log"
    $logFolder = Split-Path $logFile -Parent

    if (-not (Test-Path $logFolder)) {
        New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
    }

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
        @("configure-*.ps1", "development/scripts/setup", "Scripts de configuration"),
        @("setup-*.ps1", "development/scripts/setup", "Scripts d'installation"),
        @("update-*.ps1", "development/scripts/maintenance", "Scripts de mise Ã  jour"),
        @("cleanup-*.ps1", "development/scripts/maintenance", "Scripts de nettoyage"),
        @("check-*.ps1", "development/scripts/maintenance", "Scripts de vÃ©rification"),
        @("organize-*.ps1", "development/scripts/maintenance", "Scripts d'organisation"),
        @("GUIDE_*.md", "docs/guides", "Guides d'utilisation"),
        @("*.md", "md", "Fichiers Markdown (sauf standards GitHub)"),
        @("*.log", "logs", "Fichiers de logs"),
        @("*.env", "config", "Fichiers d'environnement"),
        @("*.config", "config", "Fichiers de configuration"),
        @("start-*.cmd", "tools", "Scripts de dÃ©marrage"),
        @("*.cmd", "cmd", "Fichiers de commande Windows (sauf standards GitHub)"),
        @("*.py", "src", "Scripts Python")
    )

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

    # CrÃ©er un hook Git pour organiser automatiquement les fichiers lors des commits
    $gitHooksDir = "$projectRoot\.git\hooks"
    if (Test-Path "$projectRoot\.git") {
        if (-not (Test-Path $gitHooksDir)) {
            New-Item -ItemType Directory -Path $gitHooksDir -Force | Out-Null
        }

        Set-GitHooks -HooksDir $gitHooksDir -ProjectRoot $projectRoot
    }
}
catch {
    Write-Log "Erreur lors de l'organisation automatique : $_" -Level "ERROR"
    exit 1
}
finally {
    Write-Log "Organisation automatique terminÃ©e"
}

