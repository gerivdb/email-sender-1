# setup-desktop-commander-mcp.ps1
# Script pour installer et configurer le MCP Desktop Commander
# Version: 1.0
# Date: 2025-05-16

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Debug,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour écrire des logs
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Fonction pour vérifier si Node.js est installé
function Test-NodeInstalled {
    try {
        $nodeVersion = node --version
        Write-Log "Node.js version $nodeVersion est installé." -Level "INFO"
        return $true
    } catch {
        Write-Log "Node.js n'est pas installé ou n'est pas dans le PATH." -Level "ERROR"
        return $false
    }
}

# Fonction pour installer le package npm
function Install-DesktopCommander {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Debug
    )
    
    try {
        if ($Debug) {
            Write-Log "Installation de Desktop Commander en mode debug..." -Level "INFO"
            npm install -g @wonderwhy-er/desktop-commander
            npx @wonderwhy-er/desktop-commander setup --debug
        } else {
            Write-Log "Installation de Desktop Commander..." -Level "INFO"
            npm install -g @wonderwhy-er/desktop-commander
            npx @wonderwhy-er/desktop-commander setup
        }
        
        Write-Log "Desktop Commander installé avec succès." -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de l'installation de Desktop Commander: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour créer le fichier de configuration
function New-ConfigFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    if ((Test-Path -Path $ConfigPath) -and -not $Force) {
        Write-Log "Le fichier de configuration existe déjà. Utilisez -Force pour le remplacer." -Level "WARNING"
        return $false
    }
    
    $configContent = @{
        "enabled" = $true
        "description" = "MCP pour la manipulation de fichiers et l'exécution de commandes terminal"
        "port" = 8080
        "allowedDirectories" = @(
            "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1"
        )
        "blockedCommands" = @(
            "rm -rf /"
            "format"
            "deltree"
        )
        "defaultShell" = "powershell"
        "cacheEnabled" = $true
        "cacheTTL" = 3600
    }
    
    $configJson = $configContent | ConvertTo-Json -Depth 10
    
    try {
        $configJson | Set-Content -Path $ConfigPath -Encoding UTF8
        Write-Log "Fichier de configuration créé: $ConfigPath" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de la création du fichier de configuration: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour mettre à jour le fichier mcp-config.json
function Update-McpConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$McpConfigPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    if (-not (Test-Path -Path $McpConfigPath)) {
        Write-Log "Le fichier mcp-config.json n'existe pas: $McpConfigPath" -Level "ERROR"
        return $false
    }
    
    try {
        $mcpConfig = Get-Content -Path $McpConfigPath -Raw | ConvertFrom-Json
        
        # Vérifier si le serveur desktop-commander existe déjà
        if ($mcpConfig.mcpServers.PSObject.Properties.Name -contains "desktop-commander" -and -not $Force) {
            Write-Log "Le serveur desktop-commander existe déjà dans mcp-config.json. Utilisez -Force pour le remplacer." -Level "WARNING"
            return $false
        }
        
        # Ajouter ou mettre à jour le serveur desktop-commander
        $desktopCommanderConfig = @{
            "command" = "npx"
            "args" = @(
                "-y",
                "@wonderwhy-er/desktop-commander"
            )
            "enabled" = $true
            "configPath" = "config/servers/desktop-commander.json"
        }
        
        # Convertir en PSObject pour pouvoir le modifier
        if ($null -eq $mcpConfig.mcpServers) {
            $mcpConfig | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value ([PSCustomObject]@{})
        }
        
        # Ajouter ou mettre à jour le serveur desktop-commander
        $mcpConfig.mcpServers | Add-Member -MemberType NoteProperty -Name "desktop-commander" -Value $desktopCommanderConfig -Force
        
        # Convertir en JSON et écrire dans le fichier
        $mcpConfigJson = $mcpConfig | ConvertTo-Json -Depth 10
        $mcpConfigJson | Set-Content -Path $McpConfigPath -Encoding UTF8
        
        Write-Log "Fichier mcp-config.json mis à jour avec succès." -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de la mise à jour du fichier mcp-config.json: $_" -Level "ERROR"
        return $false
    }
}

# Fonction principale
function Main {
    Write-Log "Démarrage de l'installation du MCP Desktop Commander..." -Level "INFO"
    
    # Vérifier si Node.js est installé
    if (-not (Test-NodeInstalled)) {
        Write-Log "Node.js est requis pour installer Desktop Commander. Veuillez l'installer et réessayer." -Level "ERROR"
        return
    }
    
    # Installer Desktop Commander
    if (-not (Install-DesktopCommander -Debug:$Debug)) {
        Write-Log "L'installation de Desktop Commander a échoué. Veuillez vérifier les erreurs et réessayer." -Level "ERROR"
        return
    }
    
    # Créer le fichier de configuration
    $configPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\config\servers\desktop-commander.json"
    if (-not (New-ConfigFile -ConfigPath $configPath -Force:$Force)) {
        Write-Log "La création du fichier de configuration a échoué. Veuillez vérifier les erreurs et réessayer." -Level "WARNING"
    }
    
    # Mettre à jour le fichier mcp-config.json
    $mcpConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\config\mcp-config.json"
    if (-not (Update-McpConfig -McpConfigPath $mcpConfigPath -Force:$Force)) {
        Write-Log "La mise à jour du fichier mcp-config.json a échoué. Veuillez vérifier les erreurs et réessayer." -Level "WARNING"
    }
    
    Write-Log "Installation du MCP Desktop Commander terminée." -Level "SUCCESS"
    Write-Log "Redémarrez Claude Desktop pour appliquer les changements." -Level "INFO"
}

# Exécuter la fonction principale
Main
