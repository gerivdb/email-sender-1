# Start-QdrantContainer.ps1
# Script pour démarrer, arrêter ou vérifier l'état du conteneur Docker de Qdrant

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Start", "Stop", "Status", "Restart")]
    [string]$Action = "Start",
    
    [Parameter(Mandatory = $false)]
    [string]$ContainerName = "roadmap-qdrant",
    
    [Parameter(Mandatory = $false)]
    [string]$QdrantImage = "qdrant/qdrant:latest",
    
    [Parameter(Mandatory = $false)]
    [string]$DataPath = "projet\roadmaps\vectors\qdrant_data",
    
    [Parameter(Mandatory = $false)]
    [int]$HttpPort = 6333,
    
    [Parameter(Mandatory = $false)]
    [int]$GrpcPort = 6334,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour écrire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
}

# Fonction pour vérifier si Docker est installé et en cours d'exécution
function Test-DockerAvailable {
    try {
        $dockerVersion = docker --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Docker détecté: $dockerVersion" -Level Info
            
            # Vérifier si Docker est en cours d'exécution
            $dockerInfo = docker info 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Docker est en cours d'exécution." -Level Success
                return $true
            }
            else {
                Write-Log "Docker est installé mais n'est pas en cours d'exécution." -Level Error
                return $false
            }
        }
        else {
            Write-Log "Docker n'est pas correctement installé." -Level Error
            return $false
        }
    }
    catch {
        Write-Log "Docker n'est pas installé ou n'est pas dans le PATH." -Level Error
        return $false
    }
}

# Fonction pour vérifier si le conteneur Qdrant existe
function Test-QdrantContainerExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ContainerName
    )
    
    $containerExists = docker ps -a --filter "name=$ContainerName" --format "{{.Names}}" 2>&1
    
    if ($LASTEXITCODE -eq 0 -and $containerExists -eq $ContainerName) {
        return $true
    }
    else {
        return $false
    }
}

# Fonction pour vérifier si le conteneur Qdrant est en cours d'exécution
function Test-QdrantContainerRunning {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ContainerName
    )
    
    $containerRunning = docker ps --filter "name=$ContainerName" --format "{{.Names}}" 2>&1
    
    if ($LASTEXITCODE -eq 0 -and $containerRunning -eq $ContainerName) {
        return $true
    }
    else {
        return $false
    }
}

# Fonction pour démarrer le conteneur Qdrant
function Start-QdrantContainer {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ContainerName,
        
        [Parameter(Mandatory = $true)]
        [string]$QdrantImage,
        
        [Parameter(Mandatory = $true)]
        [string]$DataPath,
        
        [Parameter(Mandatory = $true)]
        [int]$HttpPort,
        
        [Parameter(Mandatory = $true)]
        [int]$GrpcPort,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si le conteneur existe déjà
    $containerExists = Test-QdrantContainerExists -ContainerName $ContainerName
    
    if ($containerExists) {
        # Vérifier si le conteneur est déjà en cours d'exécution
        $containerRunning = Test-QdrantContainerRunning -ContainerName $ContainerName
        
        if ($containerRunning) {
            Write-Log "Le conteneur $ContainerName est déjà en cours d'exécution." -Level Info
            return $true
        }
        else {
            # Démarrer le conteneur existant
            Write-Log "Démarrage du conteneur $ContainerName..." -Level Info
            docker start $ContainerName 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Le conteneur $ContainerName a été démarré avec succès." -Level Success
                return $true
            }
            else {
                Write-Log "Erreur lors du démarrage du conteneur $ContainerName." -Level Error
                return $false
            }
        }
    }
    else {
        # Créer le dossier de données s'il n'existe pas
        $absoluteDataPath = (Resolve-Path -Path (Split-Path -Parent $DataPath) -ErrorAction SilentlyContinue).Path
        if (-not $absoluteDataPath) {
            $absoluteDataPath = (New-Item -Path (Split-Path -Parent $DataPath) -ItemType Directory -Force).FullName
        }
        $absoluteDataPath = Join-Path -Path $absoluteDataPath -ChildPath (Split-Path -Leaf $DataPath)
        
        if (-not (Test-Path -Path $absoluteDataPath)) {
            New-Item -Path $absoluteDataPath -ItemType Directory -Force | Out-Null
            Write-Log "Dossier de données créé: $absoluteDataPath" -Level Info
        }
        
        # Créer et démarrer un nouveau conteneur
        Write-Log "Création et démarrage d'un nouveau conteneur $ContainerName..." -Level Info
        
        # Utiliser le chemin absolu pour le montage du volume
        $volumeMount = "${absoluteDataPath}:/qdrant/storage"
        
        # Créer et démarrer le conteneur
        docker run -d --name $ContainerName -p ${HttpPort}:6333 -p ${GrpcPort}:6334 -v $volumeMount $QdrantImage 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Le conteneur $ContainerName a été créé et démarré avec succès." -Level Success
            Write-Log "URL Qdrant: http://localhost:$HttpPort" -Level Info
            return $true
        }
        else {
            Write-Log "Erreur lors de la création et du démarrage du conteneur $ContainerName." -Level Error
            return $false
        }
    }
}

# Fonction pour arrêter le conteneur Qdrant
function Stop-QdrantContainer {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ContainerName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si le conteneur existe
    $containerExists = Test-QdrantContainerExists -ContainerName $ContainerName
    
    if (-not $containerExists) {
        Write-Log "Le conteneur $ContainerName n'existe pas." -Level Warning
        return $true
    }
    
    # Vérifier si le conteneur est en cours d'exécution
    $containerRunning = Test-QdrantContainerRunning -ContainerName $ContainerName
    
    if (-not $containerRunning) {
        Write-Log "Le conteneur $ContainerName n'est pas en cours d'exécution." -Level Info
        return $true
    }
    
    # Arrêter le conteneur
    Write-Log "Arrêt du conteneur $ContainerName..." -Level Info
    
    if ($Force) {
        docker kill $ContainerName 2>&1 | Out-Null
    }
    else {
        docker stop $ContainerName 2>&1 | Out-Null
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Le conteneur $ContainerName a été arrêté avec succès." -Level Success
        return $true
    }
    else {
        Write-Log "Erreur lors de l'arrêt du conteneur $ContainerName." -Level Error
        return $false
    }
}

# Fonction pour afficher l'état du conteneur Qdrant
function Get-QdrantContainerStatus {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ContainerName
    )
    
    # Vérifier si le conteneur existe
    $containerExists = Test-QdrantContainerExists -ContainerName $ContainerName
    
    if (-not $containerExists) {
        Write-Log "Le conteneur $ContainerName n'existe pas." -Level Warning
        return $false
    }
    
    # Vérifier si le conteneur est en cours d'exécution
    $containerRunning = Test-QdrantContainerRunning -ContainerName $ContainerName
    
    if ($containerRunning) {
        # Obtenir des informations détaillées sur le conteneur
        $containerInfo = docker inspect $ContainerName --format "{{json .}}" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $containerData = $containerInfo | ConvertFrom-Json
            
            $status = $containerData.State.Status
            $startedAt = $containerData.State.StartedAt
            $image = $containerData.Config.Image
            $ports = $containerData.NetworkSettings.Ports
            
            Write-Log "État du conteneur $ContainerName:" -Level Info
            Write-Log "  - Statut: $status" -Level Success
            Write-Log "  - Démarré le: $startedAt" -Level Info
            Write-Log "  - Image: $image" -Level Info
            
            # Afficher les ports exposés
            foreach ($port in $ports.PSObject.Properties) {
                $containerPort = $port.Name
                $hostPort = $port.Value.HostPort
                Write-Log "  - Port: $containerPort -> $hostPort" -Level Info
            }
            
            # Vérifier si l'API Qdrant est accessible
            try {
                $qdrantUrl = "http://localhost:$HttpPort/dashboard"
                $response = Invoke-WebRequest -Uri $qdrantUrl -Method Head -TimeoutSec 5 -ErrorAction SilentlyContinue
                
                if ($response.StatusCode -eq 200) {
                    Write-Log "  - API Qdrant: Accessible (http://localhost:$HttpPort)" -Level Success
                }
                else {
                    Write-Log "  - API Qdrant: Non accessible (http://localhost:$HttpPort)" -Level Warning
                }
            }
            catch {
                Write-Log "  - API Qdrant: Non accessible (http://localhost:$HttpPort)" -Level Warning
            }
            
            return $true
        }
        else {
            Write-Log "Erreur lors de la récupération des informations du conteneur $ContainerName." -Level Error
            return $false
        }
    }
    else {
        Write-Log "Le conteneur $ContainerName existe mais n'est pas en cours d'exécution." -Level Warning
        return $false
    }
}

# Fonction pour redémarrer le conteneur Qdrant
function Restart-QdrantContainer {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ContainerName
    )
    
    # Vérifier si le conteneur existe
    $containerExists = Test-QdrantContainerExists -ContainerName $ContainerName
    
    if (-not $containerExists) {
        Write-Log "Le conteneur $ContainerName n'existe pas." -Level Warning
        return $false
    }
    
    # Arrêter le conteneur
    Write-Log "Redémarrage du conteneur $ContainerName..." -Level Info
    docker restart $ContainerName 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Le conteneur $ContainerName a été redémarré avec succès." -Level Success
        return $true
    }
    else {
        Write-Log "Erreur lors du redémarrage du conteneur $ContainerName." -Level Error
        return $false
    }
}

# Fonction principale
function Main {
    # Vérifier si Docker est disponible
    if (-not (Test-DockerAvailable)) {
        Write-Log "Docker est requis pour ce script. Veuillez installer Docker et réessayer." -Level Error
        return $false
    }
    
    # Exécuter l'action demandée
    switch ($Action) {
        "Start" {
            return Start-QdrantContainer -ContainerName $ContainerName -QdrantImage $QdrantImage -DataPath $DataPath -HttpPort $HttpPort -GrpcPort $GrpcPort -Force:$Force
        }
        "Stop" {
            return Stop-QdrantContainer -ContainerName $ContainerName -Force:$Force
        }
        "Status" {
            return Get-QdrantContainerStatus -ContainerName $ContainerName
        }
        "Restart" {
            return Restart-QdrantContainer -ContainerName $ContainerName
        }
        default {
            Write-Log "Action non reconnue: $Action" -Level Error
            return $false
        }
    }
}

# Exécuter la fonction principale
Main
