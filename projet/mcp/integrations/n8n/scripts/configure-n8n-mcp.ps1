#Requires -Version 5.1
<#
.SYNOPSIS
    Configure n8n pour utiliser les serveurs MCP.
.DESCRIPTION
    Ce script configure n8n pour utiliser les serveurs MCP en créant
    les credentials nécessaires et en configurant les variables d'environnement.
.PARAMETER N8nRoot
    Chemin racine de l'installation n8n. Par défaut, le répertoire courant.
.PARAMETER Server
    Nom du serveur à configurer. Si non spécifié, tous les serveurs seront configurés.
.PARAMETER Force
    Force l'écrasement des credentials existants.
.EXAMPLE
    .\configure-n8n-mcp.ps1 -N8nRoot "D:\n8n"
    Configure n8n dans le répertoire spécifié.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$N8nRoot = ".",
    
    [Parameter(Mandatory = $false)]
    [string]$Server,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$integrationRoot = (Get-Item $scriptPath).Parent.FullName
$projectRoot = (Get-Item $integrationRoot).Parent.Parent.FullName
$credentialsTemplateDir = Join-Path -Path $integrationRoot -ChildPath "credentials"
$configPath = Join-Path -Path $projectRoot -ChildPath "config/mcp-config.json"
$N8nRoot = Resolve-Path $N8nRoot
$n8nCredentialsDir = Join-Path -Path $N8nRoot -ChildPath ".n8n\credentials"

# Fonctions d'aide
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "TITLE" { "Cyan" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function New-CredentialId {
    return [guid]::NewGuid().ToString("N")
}

function New-McpCredential {
    param (
        [string]$ServerName,
        [PSCustomObject]$ServerConfig,
        [string]$CredentialsDir
    )
    
    $credentialId = New-CredentialId
    $credentialPath = Join-Path -Path $CredentialsDir -ChildPath "$credentialId.json"
    
    $credential = @{
        name = "MCP $ServerName"
        type = "mcpClientApi"
        data = @{}
    }
    
    if ($ServerConfig.url) {
        # Serveur basé sur URL
        $credential.data.url = $ServerConfig.url
    }
    elseif ($ServerConfig.command) {
        # Serveur basé sur commande
        $credential.data.command = $ServerConfig.command
        $credential.data.args = $ServerConfig.args -join " "
        
        # Ajouter les variables d'environnement
        if ($ServerConfig.env) {
            $envVars = @()
            foreach ($key in $ServerConfig.env.PSObject.Properties.Name) {
                $value = $ServerConfig.env.$key
                $envVars += "$key=$value"
            }
            $credential.data.environments = $envVars -join ","
        }
        else {
            $credential.data.environments = "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true"
        }
    }
    else {
        Write-Log "Configuration invalide pour le serveur $ServerName: ni URL ni commande spécifiée" -Level "ERROR"
        return $null
    }
    
    # Convertir en JSON
    $credentialJson = $credential | ConvertTo-Json -Depth 5
    
    # Écrire le fichier
    if ($PSCmdlet.ShouldProcess($credentialPath, "Create credential")) {
        Set-Content -Path $credentialPath -Value $credentialJson
        Write-Log "Credential créé pour le serveur $ServerName: $credentialPath" -Level "SUCCESS"
    }
    
    return $credentialPath
}

function Set-N8nEnvironment {
    param (
        [string]$N8nRoot
    )
    
    $envPath = Join-Path -Path $N8nRoot -ChildPath ".env"
    $envContent = @"
# Configuration n8n pour MCP
N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
N8N_METRICS=true
N8N_DIAGNOSTICS_ENABLED=true
N8N_HIRING_BANNER_ENABLED=false
N8N_VERSION_NOTIFICATIONS_ENABLED=true
"@
    
    if ($PSCmdlet.ShouldProcess($envPath, "Create or update .env file")) {
        if (Test-Path $envPath) {
            $currentEnv = Get-Content -Path $envPath -Raw
            if ($currentEnv -notmatch "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE") {
                $envContent = $currentEnv + "`n" + $envContent
            }
            else {
                Write-Log "Variable N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE déjà configurée dans .env" -Level "INFO"
                $envContent = $currentEnv
            }
        }
        
        Set-Content -Path $envPath -Value $envContent -Force
        Write-Log "Fichier .env mis à jour: $envPath" -Level "SUCCESS"
    }
}

# Corps principal du script
try {
    Write-Log "Configuration de n8n pour MCP..." -Level "TITLE"
    
    # Vérifier si le fichier de configuration existe
    if (-not (Test-Path $configPath)) {
        Write-Log "Fichier de configuration non trouvé: $configPath" -Level "ERROR"
        exit 1
    }
    
    # Charger la configuration
    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    $servers = $config.mcpServers
    
    # Vérifier si des serveurs sont configurés
    if (-not $servers -or $servers.PSObject.Properties.Count -eq 0) {
        Write-Log "Aucun serveur MCP configuré dans $configPath" -Level "WARNING"
        exit 0
    }
    
    # Vérifier si le répertoire credentials n8n existe
    if (-not (Test-Path $n8nCredentialsDir)) {
        if ($PSCmdlet.ShouldProcess($n8nCredentialsDir, "Create directory")) {
            New-Item -Path $n8nCredentialsDir -ItemType Directory -Force | Out-Null
            Write-Log "Répertoire credentials n8n créé: $n8nCredentialsDir" -Level "SUCCESS"
        }
    }
    
    # Configurer les variables d'environnement n8n
    Set-N8nEnvironment -N8nRoot $N8nRoot
    
    # Créer les credentials
    $createdCredentials = @()
    
    foreach ($serverName in $servers.PSObject.Properties.Name) {
        # Ignorer les serveurs désactivés
        if ($servers.$serverName.enabled -eq $false) {
            Write-Log "Serveur $serverName désactivé, ignoré." -Level "INFO"
            continue
        }
        
        # Filtrer par serveur si spécifié
        if ($Server -and $serverName -ne $Server) {
            continue
        }
        
        $serverConfig = $servers.$serverName
        
        # Vérifier si un credential existe déjà pour ce serveur
        $existingCredentials = Get-ChildItem -Path $n8nCredentialsDir -Filter "*.json" | Where-Object {
            $content = Get-Content -Path $_.FullName -Raw | ConvertFrom-Json
            $content.name -eq "MCP $serverName"
        }
        
        if ($existingCredentials -and -not $Force) {
            Write-Log "Le credential pour le serveur $serverName existe déjà. Utilisez -Force pour l'écraser." -Level "WARNING"
            continue
        }
        
        # Créer le credential
        $credentialPath = New-McpCredential -ServerName $serverName -ServerConfig $serverConfig -CredentialsDir $n8nCredentialsDir
        
        if ($credentialPath) {
            $createdCredentials += @{
                ServerName = $serverName
                CredentialPath = $credentialPath
            }
        }
    }
    
    # Résumé
    if ($createdCredentials.Count -gt 0) {
        Write-Log "Credentials créés pour les serveurs suivants:" -Level "SUCCESS"
        foreach ($credential in $createdCredentials) {
            Write-Log "- $($credential.ServerName): $($credential.CredentialPath)" -Level "SUCCESS"
        }
    }
    else {
        Write-Log "Aucun credential créé." -Level "WARNING"
    }
    
    Write-Log "Configuration de n8n pour MCP terminée." -Level "SUCCESS"
} catch {
    Write-Log "Erreur lors de la configuration de n8n pour MCP: $_" -Level "ERROR"
    exit 1
}

