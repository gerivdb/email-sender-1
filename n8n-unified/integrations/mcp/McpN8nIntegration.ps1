<#
.SYNOPSIS
    Script d'intégration entre n8n et les serveurs MCP.

.DESCRIPTION
    Ce script fournit des fonctions pour intégrer n8n avec les serveurs MCP,
    permettant d'accéder à différentes sources de données et services.
#>

#Requires -Version 5.1

# Paramètres globaux
param (
    [string]$N8nUrl = "http://localhost:5678",
    [string]$ApiKey = "",
    [string]$McpPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\mcp",
    [switch]$EnableDebug
)

# Variables globales
$script:N8nBaseUrl = $N8nUrl
$script:N8nApiKey = $ApiKey
$script:McpBasePath = $McpPath
$script:LogFile = Join-Path -Path $PSScriptRoot -ChildPath "logs\mcp-n8n-integration.log"
$script:ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "config\mcp-n8n-config.json"

# Création des dossiers nécessaires
$Dirs = @(
    (Split-Path -Path $script:LogFile -Parent),
    (Split-Path -Path $script:ConfigFile -Parent)
)

foreach ($Dir in $Dirs) {
    if (-not (Test-Path -Path $Dir)) {
        New-Item -Path $Dir -ItemType Directory -Force | Out-Null
    }
}

# Fonction pour écrire dans le journal
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )

    if ($Level -eq "DEBUG" -and -not $EnableDebug) { return }

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"

    Add-Content -Path $script:LogFile -Value $LogMessage -Encoding UTF8

    switch ($Level) {
        "INFO" { Write-Host $LogMessage -ForegroundColor White }
        "WARNING" { Write-Host $LogMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $LogMessage -ForegroundColor Red }
        "DEBUG" { Write-Host $LogMessage -ForegroundColor Gray }
    }
}

# Fonction pour charger la configuration
function Get-McpN8nConfig {
    try {
        if (Test-Path -Path $script:ConfigFile) {
            $Config = Get-Content -Path $script:ConfigFile -Raw | ConvertFrom-Json
            Write-Log -Message "Configuration chargée avec succès" -Level DEBUG
            return $Config
        } else {
            $Config = @{
                N8nUrl      = $script:N8nBaseUrl
                ApiKey      = $script:N8nApiKey
                McpPath     = $script:McpBasePath
                LastSync    = $null
                Servers     = @()
                Credentials = @()
            }

            $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile -Encoding UTF8
            Write-Log -Message "Configuration par défaut créée" -Level INFO
            return $Config
        }
    } catch {
        Write-Log -Message "Erreur lors du chargement de la configuration : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour sauvegarder la configuration
function Save-McpN8nConfig {
    param (
        [PSCustomObject]$Config
    )

    try {
        $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile -Encoding UTF8
        Write-Log -Message "Configuration sauvegardée avec succès" -Level DEBUG
    } catch {
        Write-Log -Message "Erreur lors de la sauvegarde de la configuration : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour tester la connexion à n8n
function Test-N8nConnection {
    try {
        $Config = Get-McpN8nConfig
        $Headers = @{ "Accept" = "application/json" }

        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }

        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/healthz" -Method Get -Headers $Headers

        if ($Response.status -eq "ok") {
            Write-Log -Message "Connexion à n8n réussie" -Level INFO
            return $true
        } else {
            Write-Log -Message "Connexion à n8n échouée : $($Response.status)" -Level ERROR
            return $false
        }
    } catch {
        Write-Log -Message "Erreur lors de la connexion à n8n : $_" -Level ERROR
        return $false
    }
}

# Fonction pour récupérer les workflows n8n
function Get-N8nWorkflows {
    try {
        $Config = Get-McpN8nConfig
        $Headers = @{ "Accept" = "application/json" }

        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }

        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/workflows" -Method Get -Headers $Headers

        Write-Log -Message "Récupération de $($Response.Count) workflows" -Level INFO
        return $Response
    } catch {
        Write-Log -Message "Erreur lors de la récupération des workflows : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour récupérer les identifiants n8n
function Get-N8nCredentials {
    try {
        $Config = Get-McpN8nConfig
        $Headers = @{ "Accept" = "application/json" }

        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }

        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/credentials" -Method Get -Headers $Headers

        Write-Log -Message "Récupération de $($Response.Count) identifiants" -Level INFO
        return $Response
    } catch {
        Write-Log -Message "Erreur lors de la récupération des identifiants : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour créer un identifiant n8n
function New-N8nCredential {
    param (
        [string]$Name,
        [string]$Type,
        [hashtable]$Data,
        [array]$NodesAccess = @()
    )

    try {
        $Config = Get-McpN8nConfig
        $Headers = @{
            "Accept"       = "application/json"
            "Content-Type" = "application/json"
        }

        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }

        $Body = @{
            name        = $Name
            type        = $Type
            data        = $Data
            nodesAccess = $NodesAccess
        } | ConvertTo-Json -Depth 10

        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/credentials" -Method Post -Headers $Headers -Body $Body

        Write-Log -Message "Création de l'identifiant $Name réussie (ID: $($Response.id))" -Level INFO
        return $Response
    } catch {
        Write-Log -Message "Erreur lors de la création de l'identifiant $Name : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour mettre à jour un identifiant n8n
function Update-N8nCredential {
    param (
        [string]$CredentialId,
        [string]$Name,
        [string]$Type,
        [hashtable]$Data,
        [array]$NodesAccess = @()
    )

    try {
        $Config = Get-McpN8nConfig
        $Headers = @{
            "Accept"       = "application/json"
            "Content-Type" = "application/json"
        }

        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }

        $Body = @{
            name        = $Name
            type        = $Type
            data        = $Data
            nodesAccess = $NodesAccess
        } | ConvertTo-Json -Depth 10

        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/credentials/$CredentialId" -Method Put -Headers $Headers -Body $Body

        Write-Log -Message "Mise à jour de l'identifiant $Name réussie (ID: $($Response.id))" -Level INFO
        return $Response
    } catch {
        Write-Log -Message "Erreur lors de la mise à jour de l'identifiant $Name : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour supprimer un identifiant n8n
function Remove-N8nCredential {
    param (
        [string]$CredentialId
    )

    try {
        $Config = Get-McpN8nConfig
        $Headers = @{ "Accept" = "application/json" }

        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }

        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/credentials/$CredentialId" -Method Delete -Headers $Headers

        Write-Log -Message "Suppression de l'identifiant $CredentialId réussie" -Level INFO
        return $Response
    } catch {
        Write-Log -Message "Erreur lors de la suppression de l'identifiant $CredentialId : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour récupérer les serveurs MCP disponibles
function Get-McpServers {
    try {
        $Config = Get-McpN8nConfig
        $McpPath = $Config.McpPath

        if (-not (Test-Path -Path $McpPath)) {
            Write-Log -Message "Le chemin MCP $McpPath n'existe pas" -Level ERROR
            return @()
        }

        $ServersPath = Join-Path -Path $McpPath -ChildPath "servers"
        if (-not (Test-Path -Path $ServersPath)) {
            Write-Log -Message "Le dossier des serveurs MCP $ServersPath n'existe pas" -Level ERROR
            return @()
        }

        $Servers = Get-ChildItem -Path $ServersPath -Directory | ForEach-Object {
            $ServerName = $_.Name
            $ServerPath = $_.FullName
            $ConfigPath = Join-Path -Path $ServerPath -ChildPath "config.json"

            $ServerConfig = $null
            if (Test-Path -Path $ConfigPath) {
                $ServerConfig = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            }

            [PSCustomObject]@{
                Name   = $ServerName
                Path   = $ServerPath
                Config = $ServerConfig
            }
        }

        Write-Log -Message "Récupération de $($Servers.Count) serveurs MCP" -Level INFO
        return $Servers
    } catch {
        Write-Log -Message "Erreur lors de la récupération des serveurs MCP : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour configurer les identifiants MCP dans n8n
function Set-McpCredentialsInN8n {
    try {
        $Config = Get-McpN8nConfig
        $McpPath = $Config.McpPath

        if (-not (Test-Path -Path $McpPath)) {
            Write-Log -Message "Le chemin MCP $McpPath n'existe pas" -Level ERROR
            return $false
        }

        # Récupérer les identifiants n8n existants
        $Credentials = Get-N8nCredentials

        # Récupérer les serveurs MCP
        $Servers = Get-McpServers

        # Pour chaque serveur MCP, créer ou mettre à jour l'identifiant correspondant dans n8n
        foreach ($Server in $Servers) {
            $ServerName = $Server.Name
            $ServerPath = $Server.Path
            $ServerConfig = $Server.Config

            if ($null -eq $ServerConfig) {
                Write-Log -Message "Pas de configuration pour le serveur MCP $ServerName" -Level WARNING
                continue
            }

            # Vérifier si l'identifiant existe déjà
            $Credential = $Credentials | Where-Object { $_.name -eq "MCP-$ServerName" }

            # Préparer les données de l'identifiant
            $CredentialData = @{
                server = $ServerName
                path   = $ServerPath
            }

            if ($ServerConfig.PSObject.Properties.Name -contains "api_key") {
                $CredentialData.api_key = $ServerConfig.api_key
            }

            if ($ServerConfig.PSObject.Properties.Name -contains "url") {
                $CredentialData.url = $ServerConfig.url
            }

            # Créer ou mettre à jour l'identifiant
            if ($null -eq $Credential) {
                $Result = New-N8nCredential -Name "MCP-$ServerName" -Type "mcpApi" -Data $CredentialData
                Write-Log -Message "Identifiant MCP-$ServerName créé (ID: $($Result.id))" -Level INFO
            } else {
                $Result = Update-N8nCredential -CredentialId $Credential.id -Name "MCP-$ServerName" -Type "mcpApi" -Data $CredentialData
                Write-Log -Message "Identifiant MCP-$ServerName mis à jour (ID: $($Result.id))" -Level INFO
            }
        }

        # Mettre à jour la configuration
        $Config.Servers = $Servers | Select-Object Name, Path
        $Config.Credentials = $Credentials | Select-Object id, name, type
        $Config.LastSync = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Save-McpN8nConfig -Config $Config

        Write-Log -Message "Configuration des identifiants MCP dans n8n réussie" -Level INFO
        return $true
    } catch {
        Write-Log -Message "Erreur lors de la configuration des identifiants MCP dans n8n : $_" -Level ERROR
        return $false
    }
}

# Fonction pour démarrer n8n avec les serveurs MCP
function Start-N8nWithMcp {
    param (
        [switch]$WaitForExit
    )

    try {
        $Config = Get-McpN8nConfig
        $McpPath = $Config.McpPath

        if (-not (Test-Path -Path $McpPath)) {
            Write-Log -Message "Le chemin MCP $McpPath n'existe pas" -Level ERROR
            return $false
        }

        # Chemin du script de démarrage de n8n avec MCP
        $StartScript = Join-Path -Path $McpPath -ChildPath "utils\commands\start-n8n-mcp.cmd"

        if (-not (Test-Path -Path $StartScript)) {
            Write-Log -Message "Le script de démarrage $StartScript n'existe pas" -Level ERROR
            return $false
        }

        # Démarrer n8n avec MCP
        Write-Log -Message "Démarrage de n8n avec les serveurs MCP..." -Level INFO

        if ($WaitForExit) {
            Start-Process -FilePath $StartScript -NoNewWindow -Wait
        } else {
            Start-Process -FilePath $StartScript -NoNewWindow
        }

        Write-Log -Message "n8n démarré avec les serveurs MCP" -Level INFO
        return $true
    } catch {
        Write-Log -Message "Erreur lors du démarrage de n8n avec les serveurs MCP : $_" -Level ERROR
        return $false
    }
}

# Fonction pour arrêter n8n
function Stop-N8n {
    try {
        $Config = Get-McpN8nConfig
        $McpPath = $Config.McpPath

        if (-not (Test-Path -Path $McpPath)) {
            Write-Log -Message "Le chemin MCP $McpPath n'existe pas" -Level ERROR
            return $false
        }

        # Chemin du script d'arrêt de n8n
        $StopScript = Join-Path -Path $McpPath -ChildPath "utils\commands\stop-n8n-mcp.cmd"

        if (-not (Test-Path -Path $StopScript)) {
            Write-Log -Message "Le script d'arrêt $StopScript n'existe pas" -Level ERROR
            return $false
        }

        # Arrêter n8n
        Write-Log -Message "Arrêt de n8n..." -Level INFO
        Start-Process -FilePath $StopScript -NoNewWindow -Wait

        Write-Log -Message "n8n arrêté" -Level INFO
        return $true
    } catch {
        Write-Log -Message "Erreur lors de l'arrêt de n8n : $_" -Level ERROR
        return $false
    }
}

# Fonction pour synchroniser les workflows avec les serveurs MCP
function Sync-WorkflowsWithMcp {
    try {
        $Config = Get-McpN8nConfig
        $McpPath = $Config.McpPath

        if (-not (Test-Path -Path $McpPath)) {
            Write-Log -Message "Le chemin MCP $McpPath n'existe pas" -Level ERROR
            return $false
        }

        # Récupérer les workflows n8n
        $Workflows = Get-N8nWorkflows

        # Récupérer les serveurs MCP
        $Servers = Get-McpServers

        # Pour chaque serveur MCP, synchroniser les workflows
        foreach ($Server in $Servers) {
            $ServerName = $Server.Name
            $ServerPath = $Server.Path
            $WorkflowsPath = Join-Path -Path $ServerPath -ChildPath "workflows"

            if (-not (Test-Path -Path $WorkflowsPath)) {
                New-Item -Path $WorkflowsPath -ItemType Directory -Force | Out-Null
            }

            # Filtrer les workflows qui utilisent ce serveur MCP
            $ServerWorkflows = $Workflows | Where-Object {
                $WorkflowJson = $_ | ConvertTo-Json -Depth 10
                $WorkflowJson -match "MCP-$ServerName"
            }

            # Sauvegarder les workflows dans le dossier du serveur
            foreach ($Workflow in $ServerWorkflows) {
                $WorkflowFile = Join-Path -Path $WorkflowsPath -ChildPath "$($Workflow.id).json"
                $Workflow | ConvertTo-Json -Depth 10 | Set-Content -Path $WorkflowFile -Encoding UTF8
            }

            Write-Log -Message "Synchronisation de $($ServerWorkflows.Count) workflows avec le serveur MCP $ServerName" -Level INFO
        }

        # Mettre à jour la configuration
        $Config.LastSync = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Save-McpN8nConfig -Config $Config

        Write-Log -Message "Synchronisation des workflows avec les serveurs MCP réussie" -Level INFO
        return $true
    } catch {
        Write-Log -Message "Erreur lors de la synchronisation des workflows avec les serveurs MCP : $_" -Level ERROR
        return $false
    }
}

# Fonction pour copier les identifiants MCP depuis le dossier MCP vers n8n
function Copy-McpCredentialsToN8n {
    param (
        [string]$SourcePath,
        [string]$DestinationPath
    )

    try {
        $Config = Get-McpN8nConfig

        if ([string]::IsNullOrEmpty($SourcePath)) {
            $SourcePath = Join-Path -Path $Config.McpPath -ChildPath "core\.n8n\credentials"
        }

        if ([string]::IsNullOrEmpty($DestinationPath)) {
            $DestinationPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\data\credentials"
        }

        if (-not (Test-Path -Path $SourcePath)) {
            Write-Log -Message "Le dossier source $SourcePath n'existe pas" -Level ERROR
            return $false
        }

        if (-not (Test-Path -Path $DestinationPath)) {
            New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
        }

        # Copier les fichiers d'identifiants
        $CredentialFiles = Get-ChildItem -Path $SourcePath -Filter "*.json"

        foreach ($File in $CredentialFiles) {
            $DestinationFile = Join-Path -Path $DestinationPath -ChildPath $File.Name
            Copy-Item -Path $File.FullName -Destination $DestinationFile -Force
        }

        Write-Log -Message "Copie de $($CredentialFiles.Count) fichiers d'identifiants MCP vers n8n" -Level INFO
        return $true
    } catch {
        Write-Log -Message "Erreur lors de la copie des identifiants MCP vers n8n : $_" -Level ERROR
        return $false
    }
}

# Fonction pour copier la base de données MCP depuis le dossier MCP vers n8n
function Copy-McpDatabaseToN8n {
    param (
        [string]$SourcePath,
        [string]$DestinationPath
    )

    try {
        $Config = Get-McpN8nConfig

        if ([string]::IsNullOrEmpty($SourcePath)) {
            $SourcePath = Join-Path -Path $Config.McpPath -ChildPath "core\.n8n"
        }

        if ([string]::IsNullOrEmpty($DestinationPath)) {
            $DestinationPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\data"
        }

        if (-not (Test-Path -Path $SourcePath)) {
            Write-Log -Message "Le dossier source $SourcePath n'existe pas" -Level ERROR
            return $false
        }

        if (-not (Test-Path -Path $DestinationPath)) {
            New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
        }

        # Copier les fichiers de base de données
        $DatabaseFiles = Get-ChildItem -Path $SourcePath -Filter "*.db"

        foreach ($File in $DatabaseFiles) {
            $DestinationFile = Join-Path -Path $DestinationPath -ChildPath $File.Name
            Copy-Item -Path $File.FullName -Destination $DestinationFile -Force
        }

        Write-Log -Message "Copie de $($DatabaseFiles.Count) fichiers de base de données MCP vers n8n" -Level INFO
        return $true
    } catch {
        Write-Log -Message "Erreur lors de la copie de la base de données MCP vers n8n : $_" -Level ERROR
        return $false
    }
}

# Fonction principale
function Start-McpN8nIntegration {
    param (
        [ValidateSet("Test", "Configure", "Start", "Stop", "Sync", "Copy")]
        [string]$Action = "Test"
    )

    try {
        Write-Log -Message "Démarrage de l'intégration MCP-n8n (Action: $Action)" -Level INFO

        # Exécuter l'action demandée
        switch ($Action) {
            "Test" {
                # Tester la connexion à n8n
                $Connected = Test-N8nConnection
                if (-not $Connected) {
                    Write-Log -Message "Impossible de se connecter à n8n. Vérifiez que n8n est en cours d'exécution et accessible." -Level ERROR
                    return $false
                }

                # Récupérer les serveurs MCP
                $Servers = Get-McpServers
                Write-Log -Message "Test réussi. $($Servers.Count) serveurs MCP trouvés." -Level INFO
                return $Servers
            }
            "Configure" {
                # Configurer les identifiants MCP dans n8n
                $Result = Set-McpCredentialsInN8n
                Write-Log -Message "Configuration des identifiants MCP terminée." -Level INFO
                return $Result
            }
            "Start" {
                # Démarrer n8n avec les serveurs MCP
                $Result = Start-N8nWithMcp
                Write-Log -Message "Démarrage de n8n avec les serveurs MCP terminé." -Level INFO
                return $Result
            }
            "Stop" {
                # Arrêter n8n
                $Result = Stop-N8n
                Write-Log -Message "Arrêt de n8n terminé." -Level INFO
                return $Result
            }
            "Sync" {
                # Synchroniser les workflows avec les serveurs MCP
                $Result = Sync-WorkflowsWithMcp
                Write-Log -Message "Synchronisation des workflows terminée." -Level INFO
                return $Result
            }
            "Copy" {
                # Copier les identifiants et la base de données MCP vers n8n
                $Result1 = Copy-McpCredentialsToN8n
                $Result2 = Copy-McpDatabaseToN8n
                Write-Log -Message "Copie des identifiants et de la base de données terminée." -Level INFO
                return $Result1 -and $Result2
            }
        }
    } catch {
        Write-Log -Message "Erreur lors de l'exécution de l'action $Action : $_" -Level ERROR
        throw $_
    }
}
