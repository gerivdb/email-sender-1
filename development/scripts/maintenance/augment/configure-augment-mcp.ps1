<#
.SYNOPSIS
    Script de configuration pour l'intégration MCP avec Augment Code.

.DESCRIPTION
    Ce script configure l'intégration MCP (Model Context Protocol) avec Augment Code,
    en créant les fichiers de configuration nécessaires et en démarrant les serveurs MCP.

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par défaut : "development\config\unified-config.json".

.PARAMETER StartServers
    Indique si les serveurs MCP doivent être démarrés après la configuration.

.EXAMPLE
    .\configure-augment-mcp.ps1
    # Configure l'intégration MCP avec Augment Code

.EXAMPLE
    .\configure-augment-mcp.ps1 -StartServers
    # Configure l'intégration MCP avec Augment Code et démarre les serveurs MCP

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$ConfigPath = "development\config\unified-config.json",

    [Parameter()]
    [switch]$StartServers
)

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
        exit 1
    }
}

# Charger la configuration unifiée
$configPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath
if (Test-Path -Path $configPath) {
    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement de la configuration : $_"
        exit 1
    }
} else {
    Write-Warning "Le fichier de configuration est introuvable : $configPath"
    # Créer une configuration par défaut
    $config = [PSCustomObject]@{
        Augment = [PSCustomObject]@{
            MCP = [PSCustomObject]@{
                Enabled = $true
                Servers = @(
                    [PSCustomObject]@{
                        Name = "memories"
                        Port = 7891
                        ScriptPath = "development\scripts\maintenance\augment\mcp-memories-server.ps1"
                    },
                    [PSCustomObject]@{
                        Name = "mode-manager"
                        Port = 7892
                        ScriptPath = "development\scripts\maintenance\augment\mcp-mode-manager-adapter.ps1"
                    }
                )
            }
        }
    }
}

# Créer le répertoire .augment s'il n'existe pas
$augmentDir = Join-Path -Path $projectRoot -ChildPath ".augment"
if (-not (Test-Path -Path $augmentDir -PathType Container)) {
    New-Item -Path $augmentDir -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire .augment créé." -ForegroundColor Green
}

# Créer le fichier de configuration MCP
$mcpConfigPath = Join-Path -Path $augmentDir -ChildPath "mcp-config.json"
$mcpConfig = @{
    "mcpServers" = @{
        "filesystem" = @{
            "command" = "npx"
            "args" = @(
                "-y"
                "@modelcontextprotocol/server-filesystem"
                $projectRoot.Replace("\", "\\")
            )
        }
        "memories" = @{
            "command" = "powershell"
            "args" = @(
                "-ExecutionPolicy"
                "Bypass"
                "-File"
                (Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\mcp-memories-server.ps1").Replace("\", "\\")
                "-Port"
                "7891"
            )
        }
        "mode-manager" = @{
            "command" = "powershell"
            "args" = @(
                "-ExecutionPolicy"
                "Bypass"
                "-File"
                (Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\mcp-mode-manager-adapter.ps1").Replace("\", "\\")
                "-Port"
                "7892"
            )
        }
    }
}

# Enregistrer le fichier de configuration MCP
$mcpConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $mcpConfigPath -Encoding UTF8
Write-Host "Fichier de configuration MCP créé : $mcpConfigPath" -ForegroundColor Green

# Créer le fichier de configuration VS Code pour Augment
$vscodeDir = Join-Path -Path $projectRoot -ChildPath ".vscode"
if (-not (Test-Path -Path $vscodeDir -PathType Container)) {
    New-Item -Path $vscodeDir -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire .vscode créé." -ForegroundColor Green
}

$vscodeSettingsPath = Join-Path -Path $vscodeDir -ChildPath "settings.json"
if (Test-Path -Path $vscodeSettingsPath) {
    try {
        $vscodeSettings = Get-Content -Path $vscodeSettingsPath -Raw | ConvertFrom-Json
    } catch {
        Write-Warning "Erreur lors du chargement des paramètres VS Code : $_"
        $vscodeSettings = [PSCustomObject]@{}
    }
} else {
    $vscodeSettings = [PSCustomObject]@{}
}

# Ajouter les paramètres MCP
$vscodeSettings | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value $mcpConfig.mcpServers -Force

# Ajouter les paramètres Augment
$vscodeSettings | Add-Member -MemberType NoteProperty -Name "augment.guidelines.maxLength" -Value 2000 -Force
$vscodeSettings | Add-Member -MemberType NoteProperty -Name "augment.input.maxSizeKB" -Value 5 -Force
$vscodeSettings | Add-Member -MemberType NoteProperty -Name "augment.input.recommendedSizeKB" -Value 4 -Force
$vscodeSettings | Add-Member -MemberType NoteProperty -Name "augment.segmentation.enabled" -Value $true -Force
$vscodeSettings | Add-Member -MemberType NoteProperty -Name "augment.segmentation.chunkSizeKB" -Value 3 -Force
$vscodeSettings | Add-Member -MemberType NoteProperty -Name "augment.context.maxTokens" -Value 200000 -Force

# Enregistrer les paramètres VS Code
$vscodeSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $vscodeSettingsPath -Encoding UTF8
Write-Host "Paramètres VS Code mis à jour : $vscodeSettingsPath" -ForegroundColor Green

# Créer le fichier .augmentignore
$augmentIgnorePath = Join-Path -Path $projectRoot -ChildPath ".augmentignore"
$augmentIgnoreContent = @"
# Fichiers et répertoires à ignorer par Augment Code

# Répertoires système
node_modules/
.git/
dist/
__pycache__/
*.pyc
logs/
cache/
temp/
tmp/

# Fichiers volumineux
*.zip
*.tar.gz
*.rar
*.7z
*.mp4
*.mp3
*.wav
*.avi
*.mov
*.pdf
*.psd
*.ai
*.sketch

# Fichiers de données
*.csv
*.xlsx
*.xls
*.db
*.sqlite
*.sqlite3

# Fichiers de configuration spécifiques
.env
.env.local
.env.development
.env.test
.env.production
"@

# Enregistrer le fichier .augmentignore
$augmentIgnoreContent | Out-File -FilePath $augmentIgnorePath -Encoding UTF8
Write-Host "Fichier .augmentignore créé : $augmentIgnorePath" -ForegroundColor Green

# Créer le fichier de configuration Augment
$augmentConfigPath = Join-Path -Path $augmentDir -ChildPath "config.json"
$augmentConfig = @{
    "browser_config" = @{
        "path" = ".augment/browser-config.json"
        "force_single_browser" = $true
    }
    "memories" = @{
        "sources" = @(
            @{
                "type" = "file"
                "path" = ".augment/memories/journal_memories.json"
                "format" = "json"
            }
        )
        "update_frequency" = "daily"
    }
    "exclude_patterns" = @(
        "node_modules/**"
        ".git/**"
        "**/*.min.js"
        "**/*.bundle.js"
        "**/*.map"
        "**/dist/**"
        "**/build/**"
        "**/.n8n/**"
    )
    "indexing" = @{
        "max_file_size_kb" = 5000
        "enable_incremental" = $true
        "mcp_integration" = $true
    }
    "mcp_servers" = @{
        "filesystem" = @{
            "enabled" = $true
            "root_path" = "`${workspace_root}"
        }
        "memories" = @{
            "enabled" = $true
            "port" = 7891
        }
        "mode_manager" = @{
            "enabled" = $true
            "port" = 7892
        }
    }
    "agent_auto" = @{
        "input_segmentation" = @{
            "enabled" = $true
            "max_input_size_kb" = 10
            "chunk_size_kb" = 5
            "preserve_lines" = $true
            "state_path" = "`${workspace_root}/cache/agent_auto_state.json"
        }
        "error_prevention" = @{
            "cycle_detection" = @{
                "enabled" = $true
                "max_recursion_depth" = 10
                "logs_path" = "`${workspace_root}/logs/cycles"
            }
        }
    }
}

# Enregistrer le fichier de configuration Augment
$augmentConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $augmentConfigPath -Encoding UTF8
Write-Host "Fichier de configuration Augment créé : $augmentConfigPath" -ForegroundColor Green

# Créer le répertoire pour les Memories
$memoriesDir = Join-Path -Path $augmentDir -ChildPath "memories"
if (-not (Test-Path -Path $memoriesDir -PathType Container)) {
    New-Item -Path $memoriesDir -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire pour les Memories créé : $memoriesDir" -ForegroundColor Green
}

# Optimiser les Memories
$optimizeMemoriesPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\optimize-augment-memories.ps1"
if (Test-Path -Path $optimizeMemoriesPath) {
    $memoriesPath = Join-Path -Path $memoriesDir -ChildPath "journal_memories.json"
    & $optimizeMemoriesPath -OutputPath $memoriesPath
} else {
    Write-Warning "Script d'optimisation des Memories introuvable : $optimizeMemoriesPath"
}

# Démarrer les serveurs MCP si demandé
if ($StartServers) {
    Write-Host "Démarrage des serveurs MCP..." -ForegroundColor Cyan

    # Démarrer le serveur MCP pour les Memories
    $memoriesServerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\mcp-memories-server.ps1"
    if (Test-Path -Path $memoriesServerPath) {
        Start-Process -FilePath "powershell" -ArgumentList "-ExecutionPolicy Bypass -File `"$memoriesServerPath`" -Port 7891" -WindowStyle Minimized
        Write-Host "Serveur MCP pour les Memories démarré sur le port 7891." -ForegroundColor Green
    } else {
        Write-Warning "Serveur MCP pour les Memories introuvable : $memoriesServerPath"
    }

    # Démarrer l'adaptateur MCP pour le gestionnaire de modes
    $modeManagerAdapterPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\mcp-mode-manager-adapter.ps1"
    if (Test-Path -Path $modeManagerAdapterPath) {
        Start-Process -FilePath "powershell" -ArgumentList "-ExecutionPolicy Bypass -File `"$modeManagerAdapterPath`" -Port 7892" -WindowStyle Minimized
        Write-Host "Adaptateur MCP pour le gestionnaire de modes démarré sur le port 7892." -ForegroundColor Green
    } else {
        Write-Warning "Adaptateur MCP pour le gestionnaire de modes introuvable : $modeManagerAdapterPath"
    }
}

Write-Host "Configuration de l'intégration MCP avec Augment Code terminée." -ForegroundColor Green
