<#
.SYNOPSIS
    Intègre les serveurs MCP d'Augment avec le MCP Manager existant.

.DESCRIPTION
    Ce script intègre les serveurs MCP d'Augment (mcp-memories-server et mcp-mode-manager-adapter)
    avec le MCP Manager existant, permettant une gestion centralisée de tous les serveurs MCP.

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration du MCP Manager.
    Par défaut : "src\mcp\modules\MCPManager.psm1".

.PARAMETER Force
    Force la mise à jour même si les serveurs sont déjà intégrés.

.EXAMPLE
    .\integrate-with-mcp-manager.ps1
    # Intègre les serveurs MCP d'Augment avec le MCP Manager existant

.EXAMPLE
    .\integrate-with-mcp-manager.ps1 -Force
    # Force l'intégration des serveurs MCP d'Augment avec le MCP Manager existant

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$ConfigPath = "src\mcp\modules\MCPManager.psm1",

    [Parameter()]
    [switch]$Force
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

# Chemin complet vers le fichier de configuration du MCP Manager
$mcpManagerPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath

# Vérifier si le fichier de configuration existe
if (-not (Test-Path -Path $mcpManagerPath)) {
    Write-Error "Fichier de configuration du MCP Manager introuvable : $mcpManagerPath"
    exit 1
}

# Chemins vers les serveurs MCP d'Augment
$memoriesServerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\mcp-memories-server.ps1"
$modeManagerAdapterPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\mcp-mode-manager-adapter.ps1"

# Vérifier si les serveurs MCP d'Augment existent
if (-not (Test-Path -Path $memoriesServerPath)) {
    Write-Error "Serveur MCP pour les Memories introuvable : $memoriesServerPath"
    exit 1
}

if (-not (Test-Path -Path $modeManagerAdapterPath)) {
    Write-Error "Adaptateur MCP pour le gestionnaire de modes introuvable : $modeManagerAdapterPath"
    exit 1
}

# Lire le contenu du fichier de configuration du MCP Manager
$mcpManagerContent = Get-Content -Path $mcpManagerPath -Raw

# Vérifier si les serveurs MCP d'Augment sont déjà intégrés
$alreadyIntegrated = $mcpManagerContent -match "augment-memories" -and $mcpManagerContent -match "augment-mode-manager"

if ($alreadyIntegrated -and -not $Force) {
    Write-Host "Les serveurs MCP d'Augment sont déjà intégrés avec le MCP Manager." -ForegroundColor Yellow
    Write-Host "Utilisez le paramètre -Force pour forcer la mise à jour." -ForegroundColor Yellow
    exit 0
}

# Trouver la section de configuration des serveurs MCP
$configSection = [regex]::Match($mcpManagerContent, '# Configuration de base\s+\$config = @\{[\s\S]*?\}')

if (-not $configSection.Success) {
    Write-Error "Impossible de trouver la section de configuration des serveurs MCP dans le fichier $mcpManagerPath"
    exit 1
}

# Extraire la configuration existante
$existingConfig = $configSection.Value

# Ajouter les serveurs MCP d'Augment à la configuration
$newConfig = $existingConfig -replace '(\s+\$config = @\{[\s\S]*?)(\s+\})', @"
`$1
    
    # Ajouter le serveur MCP pour les Memories d'Augment
    `$augmentMemoriesServer = Join-Path -Path `$script:ProjectRoot -ChildPath "development\scripts\maintenance\augment\mcp-memories-server.ps1"
    if (Test-Path -Path `$augmentMemoriesServer) {
        `$config.mcpServers."augment-memories" = @{
            command = "powershell"
            args    = @("-ExecutionPolicy", "Bypass", "-File", `$augmentMemoriesServer, "-Port", "7891")
        }
    }
    
    # Ajouter l'adaptateur MCP pour le gestionnaire de modes
    `$augmentModeManagerAdapter = Join-Path -Path `$script:ProjectRoot -ChildPath "development\scripts\maintenance\augment\mcp-mode-manager-adapter.ps1"
    if (Test-Path -Path `$augmentModeManagerAdapter) {
        `$config.mcpServers."augment-mode-manager" = @{
            command = "powershell"
            args    = @("-ExecutionPolicy", "Bypass", "-File", `$augmentModeManagerAdapter, "-Port", "7892")
        }
    }`$2
"@

# Mettre à jour le fichier de configuration du MCP Manager
$updatedContent = $mcpManagerContent.Replace($existingConfig, $newConfig)
$updatedContent | Out-File -FilePath $mcpManagerPath -Encoding UTF8

Write-Host "Les serveurs MCP d'Augment ont été intégrés avec succès au MCP Manager." -ForegroundColor Green

# Mettre à jour le fichier de configuration MCP global
$mcpConfigDir = Join-Path -Path $projectRoot -ChildPath "mcp-servers"
if (-not (Test-Path -Path $mcpConfigDir -PathType Container)) {
    New-Item -Path $mcpConfigDir -ItemType Directory -Force | Out-Null
}

$mcpConfigPath = Join-Path -Path $mcpConfigDir -ChildPath "mcp-config.json"
if (Test-Path -Path $mcpConfigPath) {
    try {
        $mcpConfig = Get-Content -Path $mcpConfigPath -Raw | ConvertFrom-Json
    } catch {
        Write-Warning "Erreur lors de la lecture du fichier de configuration MCP : $_"
        $mcpConfig = [PSCustomObject]@{
            mcpServers = [PSCustomObject]@{}
        }
    }
} else {
    $mcpConfig = [PSCustomObject]@{
        mcpServers = [PSCustomObject]@{}
    }
}

# Ajouter les serveurs MCP d'Augment à la configuration globale
$mcpConfig.mcpServers | Add-Member -MemberType NoteProperty -Name "augment-memories" -Value @{
    command = "powershell"
    args = @("-ExecutionPolicy", "Bypass", "-File", $memoriesServerPath, "-Port", "7891")
} -Force

$mcpConfig.mcpServers | Add-Member -MemberType NoteProperty -Name "augment-mode-manager" -Value @{
    command = "powershell"
    args = @("-ExecutionPolicy", "Bypass", "-File", $modeManagerAdapterPath, "-Port", "7892")
} -Force

# Enregistrer la configuration MCP globale
$mcpConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $mcpConfigPath -Encoding UTF8

Write-Host "La configuration MCP globale a été mise à jour avec succès." -ForegroundColor Green

# Mettre à jour le script de démarrage de tous les serveurs MCP
$startAllMcpServersPath = Join-Path -Path $projectRoot -ChildPath "src\mcp\utils\scripts\start-all-mcp-servers.ps1"
if (Test-Path -Path $startAllMcpServersPath) {
    $startAllMcpServersContent = Get-Content -Path $startAllMcpServersPath -Raw
    
    # Vérifier si les serveurs MCP d'Augment sont déjà inclus
    $alreadyIncluded = $startAllMcpServersContent -match "Augment Memories" -and $startAllMcpServersContent -match "Augment Mode Manager"
    
    if (-not $alreadyIncluded -or $Force) {
        # Trouver la dernière section de démarrage de serveur
        $lastServerSection = [regex]::Match($startAllMcpServersContent, '# \d+\. Démarrer le serveur MCP [^\r\n]+[\s\S]*?(?=# \d+\. |$)')
        
        if ($lastServerSection.Success) {
            $lastServerSectionValue = $lastServerSection.Value
            $lastServerNumber = [regex]::Match($lastServerSectionValue, '# (\d+)\. ').Groups[1].Value
            $nextServerNumber = [int]$lastServerNumber + 1
            
            # Créer la nouvelle section pour les serveurs MCP d'Augment
            $newServerSection = @"

# $nextServerNumber. Démarrer le serveur MCP Augment Memories
Write-Host "$nextServerNumber. Démarrage du serveur MCP Augment Memories..." -ForegroundColor Cyan
$memoriesServerPath = Join-Path -Path `$projectRoot -ChildPath "development\scripts\maintenance\augment\mcp-memories-server.ps1"
if (Test-Path -Path `$memoriesServerPath) {
    `$memoriesSuccess = Start-McpServer -Name "Augment Memories" -Command "powershell" -Arguments @("-ExecutionPolicy", "Bypass", "-File", `$memoriesServerPath, "-Port", "7891")
} else {
    Write-Warning "Serveur MCP Augment Memories introuvable : `$memoriesServerPath"
    `$memoriesSuccess = `$false
}

# $(($nextServerNumber + 1)). Démarrer l'adaptateur MCP pour le gestionnaire de modes
Write-Host "$(($nextServerNumber + 1)). Démarrage de l'adaptateur MCP pour le gestionnaire de modes..." -ForegroundColor Cyan
`$modeManagerAdapterPath = Join-Path -Path `$projectRoot -ChildPath "development\scripts\maintenance\augment\mcp-mode-manager-adapter.ps1"
if (Test-Path -Path `$modeManagerAdapterPath) {
    `$modeManagerSuccess = Start-McpServer -Name "Augment Mode Manager" -Command "powershell" -Arguments @("-ExecutionPolicy", "Bypass", "-File", `$modeManagerAdapterPath, "-Port", "7892")
} else {
    Write-Warning "Adaptateur MCP pour le gestionnaire de modes introuvable : `$modeManagerAdapterPath"
    `$modeManagerSuccess = `$false
}
"@
            
            # Mettre à jour le script de démarrage de tous les serveurs MCP
            $updatedStartAllMcpServersContent = $startAllMcpServersContent.Replace($lastServerSectionValue, $lastServerSectionValue + $newServerSection)
            $updatedStartAllMcpServersContent | Out-File -FilePath $startAllMcpServersPath -Encoding UTF8
            
            Write-Host "Le script de démarrage de tous les serveurs MCP a été mis à jour avec succès." -ForegroundColor Green
        } else {
            Write-Warning "Impossible de trouver la dernière section de démarrage de serveur dans le script $startAllMcpServersPath"
        }
    } else {
        Write-Host "Les serveurs MCP d'Augment sont déjà inclus dans le script de démarrage de tous les serveurs MCP." -ForegroundColor Yellow
    }
} else {
    Write-Warning "Script de démarrage de tous les serveurs MCP introuvable : $startAllMcpServersPath"
}

Write-Host "`nIntégration des serveurs MCP d'Augment avec le MCP Manager terminée." -ForegroundColor Green
Write-Host "Pour démarrer tous les serveurs MCP, exécutez : src\mcp\utils\scripts\start-all-mcp-servers.ps1" -ForegroundColor Yellow
