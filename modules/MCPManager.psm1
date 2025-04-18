#Requires -Version 5.1
<#
.SYNOPSIS
    Module de gestion des serveurs MCP (Model Context Protocol).
.DESCRIPTION
    Ce module fournit des fonctions pour détecter, configurer et gérer les serveurs MCP
    (Model Context Protocol) pour une intégration transparente avec les outils d'IA.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-17
#>

# Variables globales
$script:ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$script:MCPServersDir = Join-Path -Path $script:ProjectRoot -ChildPath "mcp-servers"
$script:ConfigPath = Join-Path -Path $script:MCPServersDir -ChildPath "mcp-config.json"
$script:DetectedServersPath = Join-Path -Path $script:MCPServersDir -ChildPath "detected.json"

# Fonction pour écrire dans le journal
function Write-MCPLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "TITLE")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "TITLE" { "Cyan" }
    }

    Write-Host "[$timestamp] " -NoNewline
    Write-Host "[$Level] " -NoNewline -ForegroundColor $color
    Write-Host $Message
}

# Fonction pour tester si un serveur est un MCP
function Test-MCPServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Host,

        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    # Tester différents types de serveurs MCP

    # 1. Tester n8n
    try {
        $url = "http://$Host`:$Port/api/v1/health"
        $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 2 -ErrorAction Stop

        if ($response.status -eq "ok" -and $response.version) {
            return @{
                Type    = "n8n"
                Version = $response.version
            }
        }
    } catch {
        # Ignorer les erreurs
    }

    # 2. Tester Augment
    try {
        $url = "http://$Host`:$Port/api/health"
        $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 2 -ErrorAction Stop

        if ($response.status -eq "ok" -and $response.service -eq "augment") {
            return @{
                Type    = "augment"
                Version = $response.version
            }
        }
    } catch {
        # Ignorer les erreurs
    }

    # 3. Tester Deepsite
    try {
        $url = "http://$Host`:$Port/api/status"
        $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 2 -ErrorAction Stop

        if ($response.status -eq "ok" -and $response.service -eq "deepsite") {
            return @{
                Type    = "deepsite"
                Version = $response.version
            }
        }
    } catch {
        # Ignorer les erreurs
    }

    # 4. Tester crewAI
    try {
        $url = "http://$Host`:$Port/api/v1/status"
        $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 2 -ErrorAction Stop

        if ($response.status -eq "ok" -and $response.service -eq "crewai") {
            return @{
                Type    = "crewai"
                Version = $response.version
            }
        }
    } catch {
        # Ignorer les erreurs
    }

    # Aucun serveur MCP détecté
    return $null
}

# Fonction pour détecter les serveurs MCP locaux
function Find-LocalMCPServers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Scan
    )

    Write-MCPLog "Recherche des serveurs MCP locaux..." -Level "INFO"

    $servers = @()

    # Vérifier les ports courants pour les serveurs MCP
    $ports = @(5678, 8080, 3000, 3001, 5000, 5001, 8000, 8888)
    $localhost = "localhost"

    foreach ($port in $ports) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $connectionTask = $tcpClient.ConnectAsync($localhost, $port)

            # Attendre la connexion avec un timeout
            if ($connectionTask.Wait(500)) {
                Write-MCPLog "Port $port ouvert sur $localhost" -Level "INFO"

                # Tester si c'est un serveur MCP
                $isMCP = Test-MCPServer -Host $localhost -Port $port

                if ($isMCP) {
                    $servers += [PSCustomObject]@{
                        Host    = $localhost
                        Port    = $port
                        Type    = $isMCP.Type
                        Version = $isMCP.Version
                        Status  = "Active"
                    }

                    Write-MCPLog "Serveur MCP détecté: $($isMCP.Type) v$($isMCP.Version) sur ${localhost}:${port}" -Level "SUCCESS"
                }
            }

            $tcpClient.Close()
        } catch {
            Write-MCPLog "Erreur lors de la vérification du port ${port}: ${_}" -Level "WARNING"
        }
    }

    # Si le scan est activé, rechercher sur le réseau local
    if ($Scan) {
        Write-MCPLog "Scan du réseau local pour les serveurs MCP..." -Level "INFO"

        # Obtenir l'adresse IP locale
        $localIP = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.PrefixOrigin -ne "WellKnown" } | Select-Object -First 1).IPAddress

        if ($localIP) {
            # Extraire le préfixe du réseau
            $networkPrefix = $localIP.Substring(0, $localIP.LastIndexOf(".") + 1)

            # Scanner les 254 adresses possibles
            for ($i = 1; $i -le 254; $i++) {
                $ip = "$networkPrefix$i"

                if ($ip -eq $localIP) {
                    continue  # Ignorer l'adresse locale
                }

                Write-Progress -Activity "Scan du réseau" -Status "Vérification de $ip" -PercentComplete (($i / 254) * 100)

                foreach ($port in $ports) {
                    try {
                        $tcpClient = New-Object System.Net.Sockets.TcpClient
                        $connectionTask = $tcpClient.ConnectAsync($ip, $port)

                        # Attendre la connexion avec un timeout
                        if ($connectionTask.Wait(200)) {
                            Write-MCPLog "Port $port ouvert sur $ip" -Level "INFO"

                            # Tester si c'est un serveur MCP
                            $isMCP = Test-MCPServer -Host $ip -Port $port

                            if ($isMCP) {
                                $servers += [PSCustomObject]@{
                                    Host    = $ip
                                    Port    = $port
                                    Type    = $isMCP.Type
                                    Version = $isMCP.Version
                                    Status  = "Active"
                                }

                                Write-MCPLog "Serveur MCP détecté: $($isMCP.Type) v$($isMCP.Version) sur ${ip}:${port}" -Level "SUCCESS"
                            }
                        }

                        $tcpClient.Close()
                    } catch {
                        # Ignorer les erreurs de connexion
                    }
                }
            }

            Write-Progress -Activity "Scan du réseau" -Completed
        } else {
            Write-MCPLog "Impossible de déterminer l'adresse IP locale pour le scan réseau." -Level "WARNING"
        }
    }

    return $servers
}

# Fonction pour détecter les serveurs MCP cloud
function Find-CloudMCPServers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = (Join-Path -Path $script:ProjectRoot -ChildPath ".augment\config.json")
    )

    Write-MCPLog "Recherche des serveurs MCP cloud..." -Level "INFO"

    $servers = @()

    # Vérifier si le fichier de configuration existe
    if (-not (Test-Path -Path $ConfigPath)) {
        Write-MCPLog "Fichier de configuration introuvable: $ConfigPath" -Level "WARNING"
        return $servers
    }

    try {
        # Charger la configuration
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

        # Vérifier les serveurs GCP
        if ($config.mcp_servers.gcp.enabled) {
            $gcpProjectId = $config.mcp_servers.gcp.project_id

            if ($gcpProjectId) {
                # Vérifier si gcloud est installé
                $gcloud = Get-Command gcloud -ErrorAction SilentlyContinue

                if ($gcloud) {
                    Write-MCPLog "Vérification des serveurs MCP sur GCP (projet: $gcpProjectId)..." -Level "INFO"

                    # Obtenir les instances GCP
                    $instances = & gcloud compute instances list --project $gcpProjectId --format json | ConvertFrom-Json

                    foreach ($instance in $instances) {
                        if ($instance.status -eq "RUNNING") {
                            $externalIP = $instance.networkInterfaces[0].accessConfigs[0].natIP

                            if ($externalIP) {
                                # Vérifier les ports courants
                                $ports = @(5678, 8080, 3000, 3001, 5000, 5001, 8000, 8888)

                                foreach ($port in $ports) {
                                    try {
                                        $tcpClient = New-Object System.Net.Sockets.TcpClient
                                        $connectionTask = $tcpClient.ConnectAsync($externalIP, $port)

                                        # Attendre la connexion avec un timeout
                                        if ($connectionTask.Wait(1000)) {
                                            # Tester si c'est un serveur MCP
                                            $isMCP = Test-MCPServer -Host $externalIP -Port $port

                                            if ($isMCP) {
                                                $servers += [PSCustomObject]@{
                                                    Host         = $externalIP
                                                    Port         = $port
                                                    Type         = $isMCP.Type
                                                    Version      = $isMCP.Version
                                                    Status       = "Active"
                                                    Provider     = "GCP"
                                                    InstanceName = $instance.name
                                                    InstanceId   = $instance.id
                                                    Zone         = $instance.zone
                                                }

                                                Write-MCPLog "Serveur MCP détecté sur GCP: $($isMCP.Type) v$($isMCP.Version) sur ${externalIP}:${port} (instance: $($instance.name))" -Level "SUCCESS"
                                            }
                                        }

                                        $tcpClient.Close()
                                    } catch {
                                        # Ignorer les erreurs de connexion
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Write-MCPLog "gcloud n'est pas installé. Impossible de vérifier les serveurs MCP sur GCP." -Level "WARNING"
                }
            }
        }

        # Vérifier les serveurs GitHub
        if ($config.mcp_servers.github.enabled) {
            Write-MCPLog "Vérification des serveurs MCP sur GitHub..." -Level "INFO"

            # Cette partie nécessiterait l'API GitHub pour vérifier les GitHub Actions
            # ou d'autres services hébergés sur GitHub
        }
    } catch {
        Write-MCPLog "Erreur lors de la recherche des serveurs MCP cloud: $_" -Level "ERROR"
    }

    return $servers
}

# Fonction pour détecter tous les serveurs MCP
function Find-MCPServers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = (Join-Path -Path $script:ProjectRoot -ChildPath ".augment\config.json"),

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = $script:DetectedServersPath,

        [Parameter(Mandatory = $false)]
        [switch]$Scan,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    Write-MCPLog "Démarrage de la détection des serveurs MCP..." -Level "TITLE"
    Write-MCPLog "Fichier de configuration: $ConfigPath"
    Write-MCPLog "Fichier de sortie: $OutputPath"

    # Vérifier si le fichier de sortie existe déjà
    if ((Test-Path -Path $OutputPath) -and -not $Force) {
        Write-MCPLog "Le fichier de sortie existe déjà. Utilisez -Force pour écraser." -Level "WARNING"

        try {
            $existingServers = Get-Content -Path $OutputPath -Raw | ConvertFrom-Json
            Write-MCPLog "Serveurs MCP déjà détectés: $($existingServers.Count)" -Level "INFO"

            foreach ($server in $existingServers) {
                Write-MCPLog "- $($server.Type) v$($server.Version) sur $($server.Host):$($server.Port) ($($server.Status))" -Level "INFO"
            }

            return $existingServers
        } catch {
            Write-MCPLog "Erreur lors de la lecture du fichier existant: $_" -Level "ERROR"
        }
    }

    # Détecter les serveurs MCP locaux
    $localServers = Find-LocalMCPServers -Scan:$Scan

    # Détecter les serveurs MCP cloud
    $cloudServers = Find-CloudMCPServers -ConfigPath $ConfigPath

    # Combiner les résultats
    $allServers = $localServers + $cloudServers

    # Enregistrer les résultats
    if ($allServers.Count -gt 0) {
        # Créer le dossier de sortie s'il n'existe pas
        $outputDir = [System.IO.Path]::GetDirectoryName($OutputPath)

        if (-not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Enregistrer les serveurs détectés
        $allServers | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8

        Write-MCPLog "Serveurs MCP détectés: $($allServers.Count)" -Level "SUCCESS"
        Write-MCPLog "Résultats enregistrés dans: $OutputPath" -Level "SUCCESS"
    } else {
        Write-MCPLog "Aucun serveur MCP détecté." -Level "WARNING"
    }

    return $allServers
}

# Fonction pour créer la configuration MCP
function New-MCPConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = $script:ConfigPath,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    Write-MCPLog "Création de la configuration MCP..." -Level "INFO"

    # Vérifier si le fichier existe déjà
    if ((Test-Path -Path $OutputPath) -and -not $Force) {
        Write-MCPLog "Le fichier de configuration existe déjà. Utilisez -Force pour écraser." -Level "WARNING"
        return $false
    }

    # Créer le dossier de sortie s'il n'existe pas
    $outputDir = [System.IO.Path]::GetDirectoryName($OutputPath)

    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Configuration de base
    $config = @{
        mcpServers = @{
            filesystem = @{
                command = "npx"
                args    = @("@modelcontextprotocol/server-filesystem", $script:ProjectRoot)
            }
        }
    }

    # Ajouter le serveur GitHub s'il est configuré
    $githubConfig = Join-Path -Path $script:MCPServersDir -ChildPath "github\config.json"
    if (Test-Path -Path $githubConfig) {
        $config.mcpServers.github = @{
            command = "npx"
            args    = @("@modelcontextprotocol/server-github", "--config", $githubConfig)
        }
    }

    # Ajouter le serveur GCP s'il est configuré
    $gcpToken = Join-Path -Path $script:MCPServersDir -ChildPath "gcp\token.json"
    if (Test-Path -Path $gcpToken) {
        $config.mcpServers.gcp = @{
            command = "npx"
            args    = @("gcp-mcp")
            env     = @{
                GOOGLE_APPLICATION_CREDENTIALS = $gcpToken
            }
        }
    }

    # Ajouter le serveur n8n
    $config.mcpServers.n8n = @{
        url = "http://localhost:5678/sse"
    }

    # Ajouter le serveur Augment
    $config.mcpServers.augment = @{
        url = "http://localhost:3000/api/health"
    }

    # Sauvegarder la configuration
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8

    Write-MCPLog "Configuration MCP créée à $OutputPath" -Level "SUCCESS"
    return $true
}

# Fonction pour démarrer le gestionnaire de serveurs MCP
function Start-MCPManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Agent,

        [Parameter(Mandatory = $false)]
        [string]$Query,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier si Python est installé
    $pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (-not $pythonPath) {
        Write-MCPLog "Python n'est pas installé ou n'est pas dans le PATH. Veuillez installer Python 3.11 ou supérieur." -Level "ERROR"
        return $false
    }

    # Vérifier la version de Python
    $pythonVersion = python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
    if ([version]$pythonVersion -lt [version]"3.11") {
        Write-MCPLog "Python 3.11 ou supérieur est requis. Version actuelle: $pythonVersion" -Level "ERROR"
        return $false
    }

    # Vérifier si les packages nécessaires sont installés
    $packages = @("mcp-use", "langchain-openai", "python-dotenv")
    foreach ($package in $packages) {
        $packageName = $package.Replace("-", "_")
        $installed = python -c "try: import $packageName; print('OK'); except ImportError: print('NOT_INSTALLED')" 2>$null
        if ($installed -ne "OK") {
            Write-MCPLog "Installation du package $package..." -Level "INFO"
            python -m pip install $package
            if ($LASTEXITCODE -ne 0) {
                Write-MCPLog "Échec de l'installation du package $package." -Level "ERROR"
                return $false
            }
            Write-MCPLog "Package $package installé avec succès." -Level "SUCCESS"
        }
    }

    # Créer le répertoire mcp-servers s'il n'existe pas
    if (-not (Test-Path $script:MCPServersDir)) {
        Write-MCPLog "Création du répertoire mcp-servers..." -Level "INFO"
        New-Item -Path $script:MCPServersDir -ItemType Directory -Force | Out-Null
        Write-MCPLog "Répertoire mcp-servers créé avec succès." -Level "SUCCESS"
    }

    # Créer le fichier .env s'il n'existe pas
    $envPath = Join-Path -Path $script:ProjectRoot -ChildPath ".env"
    if (-not (Test-Path $envPath)) {
        Write-MCPLog "Création du fichier .env..." -Level "INFO"
        $apiKey = Read-Host "Entrez votre clé API OpenAI (ou laissez vide pour configurer plus tard)"
        if ($apiKey) {
            "OPENAI_API_KEY=$apiKey" | Out-File -FilePath $envPath -Encoding utf8
            Write-MCPLog "Clé API OpenAI ajoutée au fichier .env." -Level "SUCCESS"
        } else {
            "# OPENAI_API_KEY=votre_clé_api" | Out-File -FilePath $envPath -Encoding utf8
            Write-MCPLog "Fichier .env créé sans clé API OpenAI." -Level "WARNING"
        }
    }

    # Créer la configuration MCP si elle n'existe pas
    if (-not (Test-Path $script:ConfigPath) -or $Force) {
        New-MCPConfiguration -Force:$Force
    }

    # Copier les scripts Python dans le répertoire du projet s'ils ne sont pas déjà présents
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $managerScript = Join-Path -Path $scriptDir -ChildPath "..\scripts\python\mcp_manager.py"
    $agentScript = Join-Path -Path $scriptDir -ChildPath "..\scripts\python\mcp_agent.py"

    $targetManagerScript = Join-Path -Path $script:ProjectRoot -ChildPath "mcp_manager.py"
    $targetAgentScript = Join-Path -Path $script:ProjectRoot -ChildPath "mcp_agent.py"

    if (-not (Test-Path $targetManagerScript) -and (Test-Path $managerScript)) {
        Write-MCPLog "Copie du script mcp_manager.py vers le répertoire du projet..." -Level "INFO"
        Copy-Item -Path $managerScript -Destination $targetManagerScript -Force
        Write-MCPLog "Script mcp_manager.py copié avec succès." -Level "SUCCESS"
    }

    if (-not (Test-Path $targetAgentScript) -and (Test-Path $agentScript)) {
        Write-MCPLog "Copie du script mcp_agent.py vers le répertoire du projet..." -Level "INFO"
        Copy-Item -Path $agentScript -Destination $targetAgentScript -Force
        Write-MCPLog "Script mcp_agent.py copié avec succès." -Level "SUCCESS"
    }

    # Exécuter le script approprié
    if ($Agent) {
        if ($Query) {
            Write-MCPLog "Exécution de l'agent MCP avec la requête: $Query" -Level "INFO"
            python "$script:ProjectRoot\mcp_agent.py" $Query
        } else {
            Write-MCPLog "Exécution de l'agent MCP..." -Level "INFO"
            python "$script:ProjectRoot\mcp_agent.py"
        }
    } else {
        Write-MCPLog "Démarrage du gestionnaire de serveurs MCP..." -Level "INFO"
        python "$script:ProjectRoot\mcp_manager.py"
    }

    # Vérifier si l'exécution a réussi
    if ($LASTEXITCODE -eq 0) {
        Write-MCPLog "Exécution terminée avec succès." -Level "SUCCESS"
        return $true
    } else {
        Write-MCPLog "Échec de l'exécution avec le code de sortie $LASTEXITCODE." -Level "ERROR"
        return $false
    }
}

# Fonction pour exécuter une commande MCP
function Invoke-MCPCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MCP,

        [Parameter(Mandatory = $false)]
        [string]$Args = ""
    )

    switch ($MCP) {
        "standard" {
            Write-MCPLog "Exécution du MCP Standard..." -Level "INFO"
            & "..\..\D" $Args
        }
        "notion" {
            Write-MCPLog "Exécution du MCP Notion..." -Level "INFO"
            & "..\..\D" $Args
        }
        "gateway" {
            Write-MCPLog "Exécution du MCP Gateway..." -Level "INFO"
            & "..\email\gateway.exe.cmd" $Args
        }
        "git-ingest" {
            Write-MCPLog "Exécution du MCP Git Ingest..." -Level "INFO"
            & "..\..\D" $Args
        }
        default {
            Write-MCPLog "MCP non reconnu : $MCP" -Level "ERROR"
            Write-MCPLog "MCPs disponibles : standard, notion, gateway, git-ingest" -Level "WARNING"
            return $false
        }
    }

    if ($LASTEXITCODE -eq 0) {
        Write-MCPLog "Exécution du MCP $MCP terminée avec succès." -Level "SUCCESS"
        return $true
    } else {
        Write-MCPLog "Échec de l'exécution du MCP $MCP avec le code de sortie $LASTEXITCODE." -Level "ERROR"
        return $false
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Find-MCPServers, New-MCPConfiguration, Start-MCPManager, Invoke-MCPCommand
