#Requires -Version 5.1
<#
.SYNOPSIS
    DÃ©tecte et configure automatiquement les serveurs MCP.
.DESCRIPTION
    Ce script dÃ©tecte et configure automatiquement les serveurs MCP (Model Control Plane)
    pour une intÃ©gration transparente avec les outils d'IA.
.PARAMETER ConfigPath
    Chemin du fichier de configuration MCP.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour la configuration dÃ©tectÃ©e.
.PARAMETER Scan
    Effectue un scan complet du rÃ©seau pour dÃ©tecter les serveurs MCP.
.PARAMETER Force
    Force la dÃ©tection mÃªme si une configuration existe dÃ©jÃ .
.EXAMPLE
    .\Detect-MCPServers.ps1 -ConfigPath ".\mcp-servers\config.json" -OutputPath ".\mcp-servers\detected.json"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-17
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = ".\.augment\config.json",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\mcp-servers\detected.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$Scan,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour Ã©crire dans le journal
function Write-Log {
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

# Fonction pour dÃ©tecter les serveurs MCP locaux
function Find-LocalMCPServers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Scan
    )
    
    Write-Log "Recherche des serveurs MCP locaux..." -Level "INFO"
    
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
                Write-Log "Port $port ouvert sur $localhost" -Level "INFO"
                
                # Tester si c'est un serveur MCP
                $isMCP = Test-MCPServer -Host $localhost -Port $port
                
                if ($isMCP) {
                    $servers += [PSCustomObject]@{
                        Host = $localhost
                        Port = $port
                        Type = $isMCP.Type
                        Version = $isMCP.Version
                        Status = "Active"
                    }
                    
                    Write-Log "Serveur MCP dÃ©tectÃ©: $($isMCP.Type) v$($isMCP.Version) sur $localhost:$port" -Level "SUCCESS"
                }
            }
            
            $tcpClient.Close()
        }
        catch {
            Write-Log "Erreur lors de la vÃ©rification du port $port: $_" -Level "WARNING"
        }
    }
    
    # Si le scan est activÃ©, rechercher sur le rÃ©seau local
    if ($Scan) {
        Write-Log "Scan du rÃ©seau local pour les serveurs MCP..." -Level "INFO"
        
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
                            Write-Log "Port $port ouvert sur $ip" -Level "INFO"
                            
                            # Tester si c'est un serveur MCP
                            $isMCP = Test-MCPServer -Host $ip -Port $port
                            
                            if ($isMCP) {
                                $servers += [PSCustomObject]@{
                                    Host = $ip
                                    Port = $port
                                    Type = $isMCP.Type
                                    Version = $isMCP.Version
                                    Status = "Active"
                                }
                                
                                Write-Log "Serveur MCP dÃ©tectÃ©: $($isMCP.Type) v$($isMCP.Version) sur $ip:$port" -Level "SUCCESS"
                            }
                        }
                        
                        $tcpClient.Close()
                    }
                    catch {
                        # Ignorer les erreurs de connexion
                    }
                }
            }
            
            Write-Progress -Activity "Scan du rÃ©seau" -Completed
        }
        else {
            Write-Log "Impossible de dÃ©terminer l'adresse IP locale pour le scan rÃ©seau." -Level "WARNING"
        }
    }
    
    return $servers
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
                Type = "n8n"
                Version = $response.version
            }
        }
    }
    catch {
        # Ignorer les erreurs
    }
    
    # 2. Tester Augment
    try {
        $url = "http://$Host`:$Port/api/health"
        $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 2 -ErrorAction Stop
        
        if ($response.status -eq "ok" -and $response.service -eq "augment") {
            return @{
                Type = "augment"
                Version = $response.version
            }
        }
    }
    catch {
        # Ignorer les erreurs
    }
    
    # 3. Tester Deepsite
    try {
        $url = "http://$Host`:$Port/api/status"
        $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 2 -ErrorAction Stop
        
        if ($response.status -eq "ok" -and $response.service -eq "deepsite") {
            return @{
                Type = "deepsite"
                Version = $response.version
            }
        }
    }
    catch {
        # Ignorer les erreurs
    }
    
    # 4. Tester crewAI
    try {
        $url = "http://$Host`:$Port/api/v1/status"
        $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 2 -ErrorAction Stop
        
        if ($response.status -eq "ok" -and $response.service -eq "crewai") {
            return @{
                Type = "crewai"
                Version = $response.version
            }
        }
    }
    catch {
        # Ignorer les erreurs
    }
    
    # Aucun serveur MCP dÃ©tectÃ©
    return $null
}

# Fonction pour dÃ©tecter les serveurs MCP cloud
function Find-CloudMCPServers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath
    )
    
    Write-Log "Recherche des serveurs MCP cloud..." -Level "INFO"
    
    $servers = @()
    
    # VÃ©rifier si le fichier de configuration existe
    if (-not (Test-Path -Path $ConfigPath)) {
        Write-Log "Fichier de configuration introuvable: $ConfigPath" -Level "WARNING"
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
                    Write-Log "VÃ©rification des serveurs MCP sur GCP (projet: $gcpProjectId)..." -Level "INFO"
                    
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
                                                    Host = $externalIP
                                                    Port = $port
                                                    Type = $isMCP.Type
                                                    Version = $isMCP.Version
                                                    Status = "Active"
                                                    Provider = "GCP"
                                                    InstanceName = $instance.name
                                                    InstanceId = $instance.id
                                                    Zone = $instance.zone
                                                }
                                                
                                                Write-Log "Serveur MCP dÃ©tectÃ© sur GCP: $($isMCP.Type) v$($isMCP.Version) sur $externalIP:$port (instance: $($instance.name))" -Level "SUCCESS"
                                            }
                                        }
                                        
                                        $tcpClient.Close()
                                    }
                                    catch {
                                        # Ignorer les erreurs de connexion
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    Write-Log "gcloud n'est pas installÃ©. Impossible de vÃ©rifier les serveurs MCP sur GCP." -Level "WARNING"
                }
            }
        }
        
        # VÃ©rifier les serveurs GitHub
        if ($config.mcp_servers.github.enabled) {
            Write-Log "VÃ©rification des serveurs MCP sur GitHub..." -Level "INFO"
            
            # Cette partie nÃ©cessiterait l'API GitHub pour vÃ©rifier les GitHub Actions
            # ou d'autres services hÃ©bergÃ©s sur GitHub
        }
    }
    catch {
        Write-Log "Erreur lors de la recherche des serveurs MCP cloud: $_" -Level "ERROR"
    }
    
    return $servers
}

# Fonction principale
function Start-MCPServerDetection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Scan,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    Write-Log "DÃ©marrage de la dÃ©tection des serveurs MCP..." -Level "TITLE"
    Write-Log "Fichier de configuration: $ConfigPath"
    Write-Log "Fichier de sortie: $OutputPath"
    
    # VÃ©rifier si le fichier de sortie existe dÃ©jÃ 
    if ((Test-Path -Path $OutputPath) -and -not $Force) {
        Write-Log "Le fichier de sortie existe dÃ©jÃ . Utilisez -Force pour Ã©craser." -Level "WARNING"
        
        try {
            $existingServers = Get-Content -Path $OutputPath -Raw | ConvertFrom-Json
            Write-Log "Serveurs MCP dÃ©jÃ  dÃ©tectÃ©s: $($existingServers.Count)" -Level "INFO"
            
            foreach ($server in $existingServers) {
                Write-Log "- $($server.Type) v$($server.Version) sur $($server.Host):$($server.Port) ($($server.Status))" -Level "INFO"
            }
            
            return $existingServers
        }
        catch {
            Write-Log "Erreur lors de la lecture du fichier existant: $_" -Level "ERROR"
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
        
        Write-Log "Serveurs MCP dÃ©tectÃ©s: $($allServers.Count)" -Level "SUCCESS"
        Write-Log "RÃ©sultats enregistrÃ©s dans: $OutputPath" -Level "SUCCESS"
    }
    else {
        Write-Log "Aucun serveur MCP dÃ©tectÃ©." -Level "WARNING"
    }
    
    return $allServers
}

# ExÃ©cuter la fonction principale
Start-MCPServerDetection -ConfigPath $ConfigPath -OutputPath $OutputPath -Scan:$Scan -Force:$Force
