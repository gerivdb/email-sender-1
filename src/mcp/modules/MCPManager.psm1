#Requires -Version 5.1
<#
.SYNOPSIS
    Module de gestion des serveurs MCP (Model Context Protocol).
.DESCRIPTION
    Ce module fournit des fonctions pour dÃ©tecter, configurer et gÃ©rer les serveurs MCP
    (Model Context Protocol) pour une intÃ©gration transparente avec les outils d'IA.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-17
#>

# Variables globales
$script:ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$script:MCPServersDir = Join-Path -Path $script:ProjectRoot -ChildPath "mcp-servers"
$script:ConfigPath = Join-Path -Path $script:MCPServersDir -ChildPath "mcp-config.json"
$script:DetectedServersPath = Join-Path -Path $script:MCPServersDir -ChildPath "detected.json"

# Fonction pour Ã©crire dans le journal
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

    # Tester diffÃ©rents types de serveurs MCP

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

    # Aucun serveur MCP dÃ©tectÃ©
    return $null
}

# Fonction pour dÃ©tecter les serveurs MCP locaux
function Find-LocalMCPServers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Scan
    )

    Write-MCPLog "Recherche des serveurs MCP locaux..." -Level "INFO"

    $servers = @()

    # VÃ©rifier les ports courants pour les serveurs MCP
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

                    Write-MCPLog "Serveur MCP dÃ©tectÃ©: $($isMCP.Type) v$($isMCP.Version) sur ${localhost}:${port}" -Level "SUCCESS"
                }
            }

            $tcpClient.Close()
        } catch {
            Write-MCPLog "Erreur lors de la vÃ©rification du port ${port}: ${_}" -Level "WARNING"
        }
    }

    # Si le scan est activÃ©, rechercher sur le rÃ©seau local
    if ($Scan) {
        Write-MCPLog "Scan du rÃ©seau local pour les serveurs MCP..." -Level "INFO"

        # Obtenir l'adresse IP locale
        $localIP = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.PrefixOrigin -ne "WellKnown" } | Select-Object -First 1).IPAddress

        if ($localIP) {
            # Extraire le prÃ©fixe du rÃ©seau
            $networkPrefix = $localIP.Substring(0, $localIP.LastIndexOf(".") + 1)

            # Scanner les 254 adresses possibles
            for ($i = 1; $i -le 254; $i++) {
                $ip = "$networkPrefix$i"

                if ($ip -eq $localIP) {
                    continue  # Ignorer l'adresse locale
                }

                Write-Progress -Activity "Scan du rÃ©seau" -Status "VÃ©rification de $ip" -PercentComplete (($i / 254) * 100)

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

                                Write-MCPLog "Serveur MCP dÃ©tectÃ©: $($isMCP.Type) v$($isMCP.Version) sur ${ip}:${port}" -Level "SUCCESS"
                            }
                        }

                        $tcpClient.Close()
                    } catch {
                        # Ignorer les erreurs de connexion
                    }
                }
            }

            Write-Progress -Activity "Scan du rÃ©seau" -Completed
        } else {
            Write-MCPLog "Impossible de dÃ©terminer l'adresse IP locale pour le scan rÃ©seau." -Level "WARNING"
        }
    }

    return $servers
}

# Fonction pour dÃ©tecter les serveurs MCP cloud
function Find-CloudMCPServers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = (Join-Path -Path $script:ProjectRoot -ChildPath ".augment\config.json")
    )

    Write-MCPLog "Recherche des serveurs MCP cloud..." -Level "INFO"

    $servers = @()

    # VÃ©rifier si le fichier de configuration existe
    if (-not (Test-Path -Path $ConfigPath)) {
        Write-MCPLog "Fichier de configuration introuvable: $ConfigPath" -Level "WARNING"
        return $servers
    }

    try {
        # Charger la configuration
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

        # VÃ©rifier les serveurs GCP
        if ($config.mcp_servers.gcp.enabled) {
            $gcpProjectId = $config.mcp_servers.gcp.project_id

            if ($gcpProjectId) {
                # VÃ©rifier si gcloud est installÃ©
                $gcloud = Get-Command gcloud -ErrorAction SilentlyContinue

                if ($gcloud) {
                    Write-MCPLog "VÃ©rification des serveurs MCP sur GCP (projet: $gcpProjectId)..." -Level "INFO"

                    # Obtenir les instances GCP
                    $instances = & gcloud compute instances list --project $gcpProjectId --format json | ConvertFrom-Json

                    foreach ($instance in $instances) {
                        if ($instance.status -eq "RUNNING") {
                            $externalIP = $instance.networkInterfaces[0].accessConfigs[0].natIP

                            if ($externalIP) {
                                # VÃ©rifier les ports courants
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

                                                Write-MCPLog "Serveur MCP dÃ©tectÃ© sur GCP: $($isMCP.Type) v$($isMCP.Version) sur ${externalIP}:${port} (instance: $($instance.name))" -Level "SUCCESS"
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
                    Write-MCPLog "gcloud n'est pas installÃ©. Impossible de vÃ©rifier les serveurs MCP sur GCP." -Level "WARNING"
                }
            }
        }

        # VÃ©rifier les serveurs GitHub
        if ($config.mcp_servers.github.enabled) {
            Write-MCPLog "VÃ©rification des serveurs MCP sur GitHub..." -Level "INFO"

            # Cette partie nÃ©cessiterait l'API GitHub pour vÃ©rifier les GitHub Actions
            # ou d'autres services hÃ©bergÃ©s sur GitHub
        }
    } catch {
        Write-MCPLog "Erreur lors de la recherche des serveurs MCP cloud: $_" -Level "ERROR"
    }

    return $servers
}

# Fonction pour dÃ©tecter tous les serveurs MCP
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

    Write-MCPLog "DÃ©marrage de la dÃ©tection des serveurs MCP..." -Level "TITLE"
    Write-MCPLog "Fichier de configuration: $ConfigPath"
    Write-MCPLog "Fichier de sortie: $OutputPath"

    # VÃ©rifier si le fichier de sortie existe dÃ©jÃ 
    if ((Test-Path -Path $OutputPath) -and -not $Force) {
        Write-MCPLog "Le fichier de sortie existe dÃ©jÃ . Utilisez -Force pour Ã©craser." -Level "WARNING"

        try {
            $existingServers = Get-Content -Path $OutputPath -Raw | ConvertFrom-Json
            Write-MCPLog "Serveurs MCP dÃ©jÃ  dÃ©tectÃ©s: $($existingServers.Count)" -Level "INFO"

            foreach ($server in $existingServers) {
                Write-MCPLog "- $($server.Type) v$($server.Version) sur $($server.Host):$($server.Port) ($($server.Status))" -Level "INFO"
            }

            return $existingServers
        } catch {
            Write-MCPLog "Erreur lors de la lecture du fichier existant: $_" -Level "ERROR"
        }
    }

    # DÃ©tecter les serveurs MCP locaux
    $localServers = Find-LocalMCPServers -Scan:$Scan

    # DÃ©tecter les serveurs MCP cloud
    $cloudServers = Find-CloudMCPServers -ConfigPath $ConfigPath

    # Combiner les rÃ©sultats
    $allServers = $localServers + $cloudServers

    # Enregistrer les rÃ©sultats
    if ($allServers.Count -gt 0) {
        # CrÃ©er le dossier de sortie s'il n'existe pas
        $outputDir = [System.IO.Path]::GetDirectoryName($OutputPath)

        if (-not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Enregistrer les serveurs dÃ©tectÃ©s
        $allServers | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8

        Write-MCPLog "Serveurs MCP dÃ©tectÃ©s: $($allServers.Count)" -Level "SUCCESS"
        Write-MCPLog "RÃ©sultats enregistrÃ©s dans: $OutputPath" -Level "SUCCESS"
    } else {
        Write-MCPLog "Aucun serveur MCP dÃ©tectÃ©." -Level "WARNING"
    }

    return $allServers
}

# Fonction pour crÃ©er la configuration MCP
function New-MCPConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = $script:ConfigPath,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    Write-MCPLog "CrÃ©ation de la configuration MCP..." -Level "INFO"

    # VÃ©rifier si le fichier existe dÃ©jÃ 
    if ((Test-Path -Path $OutputPath) -and -not $Force) {
        Write-MCPLog "Le fichier de configuration existe dÃ©jÃ . Utilisez -Force pour Ã©craser." -Level "WARNING"
        return $false
    }

    # CrÃ©er le dossier de sortie s'il n'existe pas
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

    # Ajouter le serveur GitHub s'il est configurÃ©
    $githubConfig = Join-Path -Path $script:MCPServersDir -ChildPath "github\config.json"
    if (Test-Path -Path $githubConfig) {
        $config.mcpServers.github = @{
            command = "npx"
            args    = @("@modelcontextprotocol/server-github", "--config", $githubConfig)
        }
    }

    # Ajouter le serveur GCP s'il est configurÃ©
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

    Write-MCPLog "Configuration MCP crÃ©Ã©e Ã  $OutputPath" -Level "SUCCESS"
    return $true
}

# Fonction pour dÃ©marrer le gestionnaire de serveurs MCP
function mcp-manager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Agent,

        [Parameter(Mandatory = $false)]
        [string]$Query,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # VÃ©rifier si Python est installÃ©
    $pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (-not $pythonPath) {
        Write-MCPLog "Python n'est pas installÃ© ou n'est pas dans le PATH. Veuillez installer Python 3.11 ou supÃ©rieur." -Level "ERROR"
        return $false
    }

    # VÃ©rifier la version de Python
    $pythonVersion = python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
    if ([version]$pythonVersion -lt [version]"3.11") {
        Write-MCPLog "Python 3.11 ou supÃ©rieur est requis. Version actuelle: $pythonVersion" -Level "ERROR"
        return $false
    }

    # VÃ©rifier si les packages nÃ©cessaires sont installÃ©s
    $packages = @("mcp-use", "langchain-openai", "python-dotenv")
    foreach ($package in $packages) {
        $packageName = $package.Replace("-", "_")
        $installed = python -c "try: import $packageName; print('OK'); except ImportError: print('NOT_INSTALLED')" 2>$null
        if ($installed -ne "OK") {
            Write-MCPLog "Installation du package $package..." -Level "INFO"
            python -m pip install $package
            if ($LASTEXITCODE -ne 0) {
                Write-MCPLog "Ã‰chec de l'installation du package $package." -Level "ERROR"
                return $false
            }
            Write-MCPLog "Package $package installÃ© avec succÃ¨s." -Level "SUCCESS"
        }
    }

    # CrÃ©er le rÃ©pertoire mcp-servers s'il n'existe pas
    if (-not (Test-Path $script:MCPServersDir)) {
        Write-MCPLog "CrÃ©ation du rÃ©pertoire mcp-servers..." -Level "INFO"
        New-Item -Path $script:MCPServersDir -ItemType Directory -Force | Out-Null
        Write-MCPLog "RÃ©pertoire mcp-servers crÃ©Ã© avec succÃ¨s." -Level "SUCCESS"
    }

    # CrÃ©er le fichier .env s'il n'existe pas
    $envPath = Join-Path -Path $script:ProjectRoot -ChildPath ".env"
    if (-not (Test-Path $envPath)) {
        Write-MCPLog "CrÃ©ation du fichier .env..." -Level "INFO"
        $apiKey = Read-Host "Entrez votre clÃ© API OpenAI (ou laissez vide pour configurer plus tard)"
        if ($apiKey) {
            "OPENAI_API_KEY=$apiKey" | Out-File -FilePath $envPath -Encoding utf8
            Write-MCPLog "ClÃ© API OpenAI ajoutÃ©e au fichier .env." -Level "SUCCESS"
        } else {
            "# OPENAI_API_KEY=votre_clÃ©_api" | Out-File -FilePath $envPath -Encoding utf8
            Write-MCPLog "Fichier .env crÃ©Ã© sans clÃ© API OpenAI." -Level "WARNING"
        }
    }

    # CrÃ©er la configuration MCP si elle n'existe pas
    if (-not (Test-Path $script:ConfigPath) -or $Force) {
        New-MCPConfiguration -Force:$Force
    }

    # Copier les scripts Python dans le rÃ©pertoire du projet s'ils ne sont pas dÃ©jÃ  prÃ©sents
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $managerScript = Join-Path -Path $scriptDir -ChildPath "..\scripts\python\mcp_manager.py"
    $agentScript = Join-Path -Path $scriptDir -ChildPath "..\scripts\python\mcp_agent.py"

    $targetManagerScript = Join-Path -Path $script:ProjectRoot -ChildPath "mcp_manager.py"
    $targetAgentScript = Join-Path -Path $script:ProjectRoot -ChildPath "mcp_agent.py"

    if (-not (Test-Path $targetManagerScript) -and (Test-Path $managerScript)) {
        Write-MCPLog "Copie du script mcp_manager.py vers le rÃ©pertoire du projet..." -Level "INFO"
        Copy-Item -Path $managerScript -Destination $targetManagerScript -Force
        Write-MCPLog "Script mcp_manager.py copiÃ© avec succÃ¨s." -Level "SUCCESS"
    }

    if (-not (Test-Path $targetAgentScript) -and (Test-Path $agentScript)) {
        Write-MCPLog "Copie du script mcp_agent.py vers le rÃ©pertoire du projet..." -Level "INFO"
        Copy-Item -Path $agentScript -Destination $targetAgentScript -Force
        Write-MCPLog "Script mcp_agent.py copiÃ© avec succÃ¨s." -Level "SUCCESS"
    }

    # ExÃ©cuter le script appropriÃ©
    if ($Agent) {
        if ($Query) {
            Write-MCPLog "ExÃ©cution de l'agent MCP avec la requÃªte: $Query" -Level "INFO"
            python "$script:ProjectRoot\mcp_agent.py" $Query
        } else {
            Write-MCPLog "ExÃ©cution de l'agent MCP..." -Level "INFO"
            python "$script:ProjectRoot\mcp_agent.py"
        }
    } else {
        Write-MCPLog "DÃ©marrage du gestionnaire de serveurs MCP..." -Level "INFO"
        python "$script:ProjectRoot\mcp_manager.py"
    }

    # VÃ©rifier si l'exÃ©cution a rÃ©ussi
    if ($LASTEXITCODE -eq 0) {
        Write-MCPLog "ExÃ©cution terminÃ©e avec succÃ¨s." -Level "SUCCESS"
        return $true
    } else {
        Write-MCPLog "Ã‰chec de l'exÃ©cution avec le code de sortie $LASTEXITCODE." -Level "ERROR"
        return $false
    }
}

# Fonction pour exÃ©cuter une commande MCP
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
            Write-MCPLog "ExÃ©cution du MCP Standard..." -Level "INFO"
            & "..\..\D" $Args
        }
        "notion" {
            Write-MCPLog "ExÃ©cution du MCP Notion..." -Level "INFO"
            & "..\..\D" $Args
        }
        "gateway" {
            Write-MCPLog "ExÃ©cution du MCP Gateway..." -Level "INFO"
            & "..\email\gateway.exe.cmd" $Args
        }
        "git-ingest" {
            Write-MCPLog "ExÃ©cution du MCP Git Ingest..." -Level "INFO"
            & "..\..\D" $Args
        }
        default {
            Write-MCPLog "MCP non reconnu : $MCP" -Level "ERROR"
            Write-MCPLog "MCPs disponibles : standard, notion, gateway, git-ingest" -Level "WARNING"
            return $false
        }
    }
}

# VÃ©rifier le rÃ©sultat de l'exÃ©cution
if ($LASTEXITCODE -eq 0) {
    Write-MCPLog "ExÃ©cution du MCP $MCP terminÃ©e avec succÃ¨s." -Level "SUCCESS"
    return $true
} else {
    Write-MCPLog "Ã‰chec de l'exÃ©cution du MCP $MCP avec le code de sortie $LASTEXITCODE." -Level "ERROR"
    return $false
}

# Importer le module MCPClient
$mcpClientPath = Join-Path -Path $PSScriptRoot -ChildPath "MCPClient.psm1"
if (Test-Path -Path $mcpClientPath) {
    Import-Module -Name $mcpClientPath -Force -Global
    Write-MCPLog "Module MCPClient importÃ© avec succÃ¨s" -Level "SUCCESS"
} else {
    Write-MCPLog "Module MCPClient introuvable Ã  l'emplacement: $mcpClientPath" -Level "WARNING"
}

<#
.SYNOPSIS
    DÃ©marre un serveur MCP et initialise la connexion.
.DESCRIPTION
    Cette fonction dÃ©marre un serveur MCP et initialise la connexion avec le client MCP.
.PARAMETER ServerType
    Le type de serveur MCP Ã  dÃ©marrer (local, n8n, notion, gateway, git-ingest).
.PARAMETER Port
    Le port sur lequel dÃ©marrer le serveur MCP.
.PARAMETER Wait
    Indique s'il faut attendre que le serveur soit prÃªt avant de retourner.
.EXAMPLE
    Start-MCPServer -ServerType local -Port 8000
    DÃ©marre un serveur MCP local sur le port 8000.
#>
function Start-MCPServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("local", "n8n", "notion", "gateway", "git-ingest")]
        [string]$ServerType,

        [Parameter(Mandatory = $false)]
        [int]$Port = 8000,

        [Parameter(Mandatory = $false)]
        [switch]$Wait
    )

    Write-MCPLog "DÃ©marrage du serveur MCP de type $ServerType sur le port $Port..." -Level "INFO"

    # DÃ©marrer le serveur MCP en fonction du type
    switch ($ServerType) {
        "local" {
            # DÃ©marrer le serveur MCP local
            $serverScript = Join-Path -Path $script:ProjectRoot -ChildPath "scripts\mcp_project\server.py"

            if (Test-Path -Path $serverScript) {
                $process = Start-Process -FilePath "python" -ArgumentList "-m", "uvicorn", "server:app", "--host", "0.0.0.0", "--port", "$Port" -WorkingDirectory (Split-Path -Path $serverScript -Parent) -PassThru -NoNewWindow

                Write-MCPLog "Serveur MCP local dÃ©marrÃ© avec le PID $($process.Id)" -Level "SUCCESS"

                # Attendre que le serveur soit prÃªt
                if ($Wait) {
                    Write-MCPLog "Attente du dÃ©marrage du serveur..." -Level "INFO"
                    Start-Sleep -Seconds 5
                }

                # Initialiser la connexion avec le client MCP
                if (Get-Command -Name Initialize-MCPConnection -ErrorAction SilentlyContinue) {
                    Initialize-MCPConnection -ServerUrl "http://localhost:$Port"
                }

                return $process
            } else {
                Write-MCPLog "Script du serveur MCP local introuvable: $serverScript" -Level "ERROR"
                return $null
            }
        }
        "n8n" {
            # DÃ©marrer le serveur n8n
            $n8nPath = Join-Path -Path $script:ProjectRoot -ChildPath "scripts\mcp\n8n\start.cmd"

            if (Test-Path -Path $n8nPath) {
                $process = Start-Process -FilePath $n8nPath -PassThru -NoNewWindow

                Write-MCPLog "Serveur n8n dÃ©marrÃ© avec le PID $($process.Id)" -Level "SUCCESS"

                # Attendre que le serveur soit prÃªt
                if ($Wait) {
                    Write-MCPLog "Attente du dÃ©marrage du serveur..." -Level "INFO"
                    Start-Sleep -Seconds 10
                }

                # Initialiser la connexion avec le client MCP
                if (Get-Command -Name Initialize-MCPConnection -ErrorAction SilentlyContinue) {
                    Initialize-MCPConnection -ServerUrl "http://localhost:5678"
                }

                return $process
            } else {
                Write-MCPLog "Script de dÃ©marrage n8n introuvable: $n8nPath" -Level "ERROR"
                return $null
            }
        }
        # Autres types de serveurs...
        default {
            Write-MCPLog "Type de serveur MCP non pris en charge: $ServerType" -Level "ERROR"
            return $null
        }
    }
}

<#
.SYNOPSIS
    ArrÃªte un serveur MCP.
.DESCRIPTION
    Cette fonction arrÃªte un serveur MCP en cours d'exÃ©cution.
.PARAMETER Process
    Le processus du serveur MCP Ã  arrÃªter.
.PARAMETER ServerType
    Le type de serveur MCP Ã  arrÃªter (local, n8n, notion, gateway, git-ingest).
.PARAMETER Port
    Le port sur lequel le serveur MCP est en cours d'exÃ©cution.
.EXAMPLE
    Stop-MCPServer -Process $process
    ArrÃªte le serveur MCP spÃ©cifiÃ©.
.EXAMPLE
    Stop-MCPServer -ServerType local -Port 8000
    ArrÃªte le serveur MCP local en cours d'exÃ©cution sur le port 8000.
#>
function Stop-MCPServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = "Process")]
        [System.Diagnostics.Process]$Process,

        [Parameter(Mandatory = $true, ParameterSetName = "Type")]
        [ValidateSet("local", "n8n", "notion", "gateway", "git-ingest")]
        [string]$ServerType,

        [Parameter(Mandatory = $false, ParameterSetName = "Type")]
        [int]$Port = 8000
    )

    if ($PSCmdlet.ParameterSetName -eq "Process") {
        if ($Process -and -not $Process.HasExited) {
            Write-MCPLog "ArrÃªt du serveur MCP avec le PID $($Process.Id)..." -Level "INFO"

            try {
                $Process.Kill()
                Write-MCPLog "Serveur MCP arrÃªtÃ© avec succÃ¨s" -Level "SUCCESS"
                return $true
            } catch {
                Write-MCPLog "Erreur lors de l'arrÃªt du serveur MCP: $_" -Level "ERROR"
                return $false
            }
        } else {
            Write-MCPLog "Le processus spÃ©cifiÃ© n'est pas en cours d'exÃ©cution" -Level "WARNING"
            return $false
        }
    } else {
        # ArrÃªter le serveur en fonction du type
        switch ($ServerType) {
            "local" {
                # Trouver et arrÃªter le processus Python qui exÃ©cute le serveur
                $processes = Get-Process -Name python* | Where-Object { $_.CommandLine -like "*server:app*--port $Port*" }

                if ($processes) {
                    foreach ($proc in $processes) {
                        Write-MCPLog "ArrÃªt du serveur MCP local avec le PID $($proc.Id)..." -Level "INFO"

                        try {
                            $proc.Kill()
                            Write-MCPLog "Serveur MCP local arrÃªtÃ© avec succÃ¨s" -Level "SUCCESS"
                        } catch {
                            Write-MCPLog "Erreur lors de l'arrÃªt du serveur MCP local: $_" -Level "ERROR"
                        }
                    }

                    return $true
                } else {
                    Write-MCPLog "Aucun serveur MCP local trouvÃ© sur le port $Port" -Level "WARNING"
                    return $false
                }
            }
            "n8n" {
                # Trouver et arrÃªter le processus n8n
                $processes = Get-Process -Name node | Where-Object { $_.CommandLine -like "*n8n*" }

                if ($processes) {
                    foreach ($proc in $processes) {
                        Write-MCPLog "ArrÃªt du serveur n8n avec le PID $($proc.Id)..." -Level "INFO"

                        try {
                            $proc.Kill()
                            Write-MCPLog "Serveur n8n arrÃªtÃ© avec succÃ¨s" -Level "SUCCESS"
                        } catch {
                            Write-MCPLog "Erreur lors de l'arrÃªt du serveur n8n: $_" -Level "ERROR"
                        }
                    }

                    return $true
                } else {
                    Write-MCPLog "Aucun serveur n8n trouvÃ©" -Level "WARNING"
                    return $false
                }
            }
            # Autres types de serveurs...
            default {
                Write-MCPLog "Type de serveur MCP non pris en charge: $ServerType" -Level "ERROR"
                return $false
            }
        }
    }
}

<#
.SYNOPSIS
    Installe les dÃ©pendances nÃ©cessaires pour les serveurs MCP.
.DESCRIPTION
    Cette fonction installe les dÃ©pendances nÃ©cessaires pour les serveurs MCP.
.PARAMETER Force
    Force la rÃ©installation des dÃ©pendances mÃªme si elles sont dÃ©jÃ  installÃ©es.
.EXAMPLE
    Install-MCPDependencies
    Installe les dÃ©pendances nÃ©cessaires pour les serveurs MCP.
#>
function Install-MCPDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    Write-MCPLog "Installation des dÃ©pendances pour les serveurs MCP..." -Level "INFO"

    # VÃ©rifier si Python est installÃ©
    $pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (-not $pythonPath) {
        Write-MCPLog "Python n'est pas installÃ© ou n'est pas dans le PATH. Veuillez installer Python 3.11 ou supÃ©rieur." -Level "ERROR"
        return $false
    }

    # VÃ©rifier la version de Python
    $pythonVersion = python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
    if ([version]$pythonVersion -lt [version]"3.11") {
        Write-MCPLog "Python 3.11 ou supÃ©rieur est requis. Version actuelle: $pythonVersion" -Level "ERROR"
        return $false
    }

    # Installer les dÃ©pendances Python
    Write-MCPLog "Installation des dÃ©pendances Python..." -Level "INFO"
    $pythonDeps = @("fastapi", "uvicorn", "pydantic", "requests", "mcp")

    foreach ($dep in $pythonDeps) {
        # Tester si le module est dÃ©jÃ  installÃ©
        python -c "import $dep" 2>&1 | Out-Null
        if ($Force -or $LASTEXITCODE -ne 0) {
            Write-MCPLog "Installation de $dep..." -Level "INFO"
            python -m pip install $dep
        } else {
            Write-MCPLog "$dep est dÃ©jÃ  installÃ©" -Level "INFO"
        }
    }

    # VÃ©rifier si Node.js est installÃ©
    $nodePath = (Get-Command node -ErrorAction SilentlyContinue).Source
    if (-not $nodePath) {
        Write-MCPLog "Node.js n'est pas installÃ© ou n'est pas dans le PATH. Certains serveurs MCP nÃ©cessitent Node.js." -Level "WARNING"
    } else {
        # Installer les dÃ©pendances Node.js
        Write-MCPLog "Installation des dÃ©pendances Node.js..." -Level "INFO"
        $nodeDeps = @("@modelcontextprotocol/server-filesystem", "@modelcontextprotocol/server-github", "n8n-nodes-mcp")

        foreach ($dep in $nodeDeps) {
            # Tester si le package est dÃ©jÃ  installÃ©
            npm list -g $dep 2>&1 | Out-Null
            if ($Force -or $LASTEXITCODE -ne 0) {
                Write-MCPLog "Installation de $dep..." -Level "INFO"
                npm install -g $dep
            } else {
                Write-MCPLog "$dep est dÃ©jÃ  installÃ©" -Level "INFO"
            }
        }
    }

    Write-MCPLog "Installation des dÃ©pendances terminÃ©e" -Level "SUCCESS"
    return $true
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Find-MCPServers, New-MCPConfiguration, mcp-manager, Invoke-MCPCommand, Start-MCPServer, Stop-MCPServer, Install-MCPDependencies

