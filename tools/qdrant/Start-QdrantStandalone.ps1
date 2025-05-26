# Start-QdrantStandalone.ps1
# Script pour gérer QDrant en mode standalone (sans Docker)

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Start", "Stop", "Status", "Restart", "Install")]
    [string]$Action = "Start",
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "config.yaml",
    
    [Parameter(Mandatory = $false)]
    [string]$DataPath = "..\..\data\qdrant",
    
    [Parameter(Mandatory = $false)]
    [int]$HttpPort = 6333,
    
    [Parameter(Mandatory = $false)]
    [int]$GrpcPort = 6334,
    
    [Parameter(Mandatory = $false)]
    [switch]$Background,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Variables globales
$script:QdrantPath = Join-Path $PSScriptRoot "qdrant.exe"
$script:QdrantProcessName = "qdrant"
$script:LogPath = Join-Path $PSScriptRoot "logs"

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
    
    # Écrire aussi dans un fichier de log
    if (-not (Test-Path $script:LogPath)) {
        New-Item -Path $script:LogPath -ItemType Directory -Force | Out-Null
    }
    
    $logFile = Join-Path $script:LogPath "qdrant-$(Get-Date -Format 'yyyy-MM-dd').log"
    $logMessage | Add-Content -Path $logFile -Encoding UTF8
}

# Fonction pour vérifier si QDrant est installé
function Test-QdrantInstalled {
    if (Test-Path $script:QdrantPath) {
        Write-Log "QDrant trouvé à: $script:QdrantPath" -Level Success
        return $true
    } else {
        Write-Log "QDrant non trouvé à: $script:QdrantPath" -Level Error
        return $false
    }
}

# Fonction pour vérifier si QDrant est en cours d'exécution
function Test-QdrantRunning {
    $processes = Get-Process -Name $script:QdrantProcessName -ErrorAction SilentlyContinue
    if ($processes) {
        Write-Log "QDrant en cours d'exécution (PID: $($processes[0].Id))" -Level Info
        return $true
    } else {
        Write-Log "QDrant n'est pas en cours d'exécution" -Level Info
        return $false
    }
}

# Fonction pour tester la connectivité QDrant
function Test-QdrantConnection {
    param (
        [Parameter(Mandatory = $false)]
        [int]$Port = $HttpPort,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 10
    )
      try {
        $url = "http://localhost:$Port/"
        $response = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec $TimeoutSeconds -ErrorAction SilentlyContinue
        
        if ($response.StatusCode -eq 200) {
            Write-Log "QDrant API accessible sur le port $Port" -Level Success
            return $true
        }
    } catch {
        Write-Log "QDrant API non accessible sur le port $Port" -Level Warning
    }
    
    return $false
}

# Fonction pour démarrer QDrant
function Start-QdrantStandalone {
    # Vérifier si QDrant est installé
    if (-not (Test-QdrantInstalled)) {
        Write-Log "QDrant n'est pas installé. Utilisez -Action Install d'abord." -Level Error
        return $false
    }
    
    # Vérifier si QDrant est déjà en cours d'exécution
    if (Test-QdrantRunning) {
        Write-Log "QDrant est déjà en cours d'exécution." -Level Warning
        return $true
    }
    
    # Créer le dossier de données s'il n'existe pas
    $fullDataPath = Join-Path $PSScriptRoot $DataPath
    if (-not (Test-Path $fullDataPath)) {
        New-Item -Path $fullDataPath -ItemType Directory -Force | Out-Null
        Write-Log "Dossier de données créé: $fullDataPath" -Level Info
    }
    
    # Créer le dossier de logs s'il n'existe pas
    if (-not (Test-Path $script:LogPath)) {
        New-Item -Path $script:LogPath -ItemType Directory -Force | Out-Null
    }
    
    # Préparer les arguments de démarrage
    $arguments = @()
    
    # Utiliser le fichier de configuration s'il existe
    $fullConfigPath = Join-Path $PSScriptRoot $ConfigPath
    if (Test-Path $fullConfigPath) {
        $arguments += "--config-path", $fullConfigPath
        Write-Log "Utilisation du fichier de configuration: $fullConfigPath" -Level Info
    } else {
        # Configuration par ligne de commande
        $arguments += "--storage-path", $fullDataPath
        $arguments += "--http-port", $HttpPort
        $arguments += "--grpc-port", $GrpcPort
        Write-Log "Utilisation de la configuration par ligne de commande" -Level Info
    }
    
    # Démarrer QDrant
    try {
        Write-Log "Démarrage de QDrant..." -Level Info
        
        if ($Background) {
            # Démarrage en arrière-plan
            $process = Start-Process -FilePath $script:QdrantPath -ArgumentList $arguments -NoNewWindow -PassThru
            Write-Log "QDrant démarré en arrière-plan (PID: $($process.Id))" -Level Success
        } else {
            # Démarrage en mode interactif
            Write-Log "Démarrage de QDrant en mode interactif..." -Level Info
            Write-Log "Appuyez sur Ctrl+C pour arrêter QDrant" -Level Info
            & $script:QdrantPath @arguments
        }
        
        # Attendre que le service soit prêt
        if ($Background) {
            Write-Log "Attente du démarrage du service..." -Level Info
            $maxRetries = 15
            $retryCount = 0
            
            while (-not (Test-QdrantConnection) -and $retryCount -lt $maxRetries) {
                Start-Sleep -Seconds 2
                $retryCount++
                Write-Log "Tentative $retryCount/$maxRetries..." -Level Info
            }
            
            if (Test-QdrantConnection) {
                Write-Log "QDrant démarré avec succès et accessible" -Level Success
                Write-Log "Dashboard disponible sur: http://localhost:$HttpPort/dashboard" -Level Info
                return $true
            } else {
                Write-Log "QDrant a démarré mais n'est pas accessible" -Level Warning
                return $false
            }
        }
        
        return $true
        
    } catch {
        Write-Log "Erreur lors du démarrage de QDrant: $_" -Level Error
        return $false
    }
}

# Fonction pour arrêter QDrant
function Stop-QdrantStandalone {
    $processes = Get-Process -Name $script:QdrantProcessName -ErrorAction SilentlyContinue
    
    if (-not $processes) {
        Write-Log "QDrant n'est pas en cours d'exécution" -Level Info
        return $true
    }
    
    try {
        foreach ($process in $processes) {
            if ($Force) {
                Write-Log "Arrêt forcé de QDrant (PID: $($process.Id))" -Level Warning
                $process.Kill()
            } else {
                Write-Log "Arrêt gracieux de QDrant (PID: $($process.Id))" -Level Info
                $process.CloseMainWindow()
                
                # Attendre l'arrêt gracieux
                if (-not $process.WaitForExit(10000)) {
                    Write-Log "Timeout atteint, arrêt forcé" -Level Warning
                    $process.Kill()
                }
            }
        }
        
        Write-Log "QDrant arrêté avec succès" -Level Success
        return $true
        
    } catch {
        Write-Log "Erreur lors de l'arrêt de QDrant: $_" -Level Error
        return $false
    }
}

# Fonction pour redémarrer QDrant
function Restart-QdrantStandalone {
    Write-Log "Redémarrage de QDrant..." -Level Info
    
    if (Stop-QdrantStandalone) {
        Start-Sleep -Seconds 2
        return Start-QdrantStandalone
    } else {
        Write-Log "Impossible d'arrêter QDrant pour le redémarrage" -Level Error
        return $false
    }
}

# Fonction pour afficher le statut de QDrant
function Get-QdrantStatus {
    Write-Log "=== Statut de QDrant ===" -Level Info
    
    # Vérifier l'installation
    if (Test-QdrantInstalled) {
        try {
            $version = & $script:QdrantPath --version 2>&1
            Write-Log "Version: $version" -Level Info
        } catch {
            Write-Log "Impossible de récupérer la version" -Level Warning
        }
    } else {
        Write-Log "QDrant non installé" -Level Error
        return $false
    }
    
    # Vérifier l'exécution
    if (Test-QdrantRunning) {
        $processes = Get-Process -Name $script:QdrantProcessName
        foreach ($process in $processes) {
            Write-Log "Processus QDrant:" -Level Info
            Write-Log "  - PID: $($process.Id)" -Level Info
            Write-Log "  - Démarré: $($process.StartTime)" -Level Info
            Write-Log "  - CPU: $([math]::Round($process.CPU, 2))s" -Level Info
            Write-Log "  - Mémoire: $([math]::Round($process.WorkingSet / 1MB, 2)) MB" -Level Info
        }
        
        # Tester la connectivité
        if (Test-QdrantConnection) {
            Write-Log "API accessible sur: http://localhost:$HttpPort" -Level Success
            Write-Log "Dashboard: http://localhost:$HttpPort/dashboard" -Level Success
        } else {
            Write-Log "API non accessible" -Level Warning
        }
    } else {
        Write-Log "QDrant n'est pas en cours d'exécution" -Level Warning
    }
    
    return $true
}

# Fonction principale
function Main {
    Write-Log "=== QDrant Standalone Manager ===" -Level Info
    
    switch ($Action.ToLower()) {
        "start" {
            return Start-QdrantStandalone
        }
        "stop" {
            return Stop-QdrantStandalone
        }
        "restart" {
            return Restart-QdrantStandalone
        }
        "status" {
            return Get-QdrantStatus
        }
        "install" {
            Write-Log "QDrant est déjà installé dans ce dossier" -Level Info
            return Get-QdrantStatus
        }
        default {
            Write-Log "Action non reconnue: $Action" -Level Error
            Write-Log "Actions disponibles: Start, Stop, Restart, Status, Install" -Level Info
            return $false
        }
    }
}

# Exécuter la fonction principale
$result = Main
exit ([int](!$result))
