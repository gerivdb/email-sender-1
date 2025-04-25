<#
.SYNOPSIS
    Script pour lister toutes les instances n8n en cours d'exécution.

.DESCRIPTION
    Ce script liste toutes les instances n8n en cours d'exécution, avec leur PID, port et état.

.EXAMPLE
    .\list-n8n-instances.ps1

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

[CmdletBinding()]
param ()

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$instancesPath = Join-Path -Path $n8nPath -ChildPath "instances"

# Vérifier si le dossier instances existe
if (-not (Test-Path -Path $instancesPath)) {
    Write-Host "Le dossier des instances n'existe pas: $instancesPath" -ForegroundColor Yellow
    Write-Host "Aucune instance n8n trouvée." -ForegroundColor Yellow
    exit 0
}

# Fonction pour vérifier si un port est utilisé
function Test-PortInUse {
    param (
        [Parameter(Mandatory=$true)]
        [int]$Port
    )
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $result = $tcpClient.BeginConnect("127.0.0.1", $Port, $null, $null)
        $success = $result.AsyncWaitHandle.WaitOne(100)
        
        if ($success) {
            $tcpClient.EndConnect($result)
            $tcpClient.Close()
            return $true  # Port est utilisé
        } else {
            $tcpClient.Close()
            return $false  # Port n'est pas utilisé
        }
    } catch {
        return $false  # En cas d'erreur, on suppose que le port n'est pas utilisé
    }
}

# Fonction pour vérifier si l'API n8n est accessible
function Test-N8nApi {
    param (
        [Parameter(Mandatory=$true)]
        [int]$Port
    )
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:$Port/healthz" -Method Get -ErrorAction SilentlyContinue
        if ($response.status -eq "ok") {
            return $true
        } else {
            return $false
        }
    } catch {
        return $false
    }
}

# Obtenir la liste des instances
$instances = Get-ChildItem -Path $instancesPath -Directory

if ($instances.Count -eq 0) {
    Write-Host "Aucune instance n8n trouvée." -ForegroundColor Yellow
    exit 0
}

# Créer un tableau pour stocker les informations des instances
$instancesInfo = @()

# Parcourir les instances
foreach ($instance in $instances) {
    $instanceName = $instance.Name
    $instancePath = $instance.FullName
    $pidFile = Join-Path -Path $instancePath -ChildPath "n8n-$instanceName.pid"
    $envFile = Join-Path -Path $instancePath -ChildPath ".env"
    
    # Vérifier si le fichier PID existe
    $pidExists = Test-Path -Path $pidFile
    $pidValue = if ($pidExists) { Get-Content -Path $pidFile } else { "N/A" }
    
    # Vérifier si le processus existe
    $processExists = $false
    $processInfo = "N/A"
    
    if ($pidExists) {
        try {
            $process = Get-Process -Id $pidValue -ErrorAction SilentlyContinue
            if ($null -ne $process) {
                $processExists = $true
                $processInfo = "En cours d'exécution (Mémoire: $([Math]::Round($process.WorkingSet / 1MB, 2)) MB)"
            } else {
                $processInfo = "N'existe pas (PID obsolète)"
            }
        } catch {
            $processInfo = "Erreur lors de la vérification du processus: $_"
        }
    }
    
    # Obtenir le port depuis le fichier .env
    $port = 5678  # Port par défaut
    if (Test-Path -Path $envFile) {
        $envContent = Get-Content -Path $envFile
        foreach ($line in $envContent) {
            if ($line -match "N8N_PORT=(\d+)") {
                $port = [int]$matches[1]
                break
            }
        }
    }
    
    # Vérifier si le port est utilisé
    $portInUse = Test-PortInUse -Port $port
    $portStatus = if ($portInUse) { "Utilisé" } else { "Non utilisé" }
    
    # Vérifier si l'API n8n est accessible
    $apiAccessible = Test-N8nApi -Port $port
    $apiStatus = if ($apiAccessible) { "Accessible" } else { "Non accessible" }
    
    # Déterminer l'état global
    $globalStatus = if ($processExists -and $portInUse -and $apiAccessible) {
        "En cours d'exécution et accessible"
    } elseif ($processExists -and $portInUse) {
        "En cours d'exécution mais API non accessible"
    } elseif ($processExists) {
        "Processus en cours d'exécution mais port non utilisé"
    } elseif ($portInUse) {
        "Port utilisé mais processus n8n non trouvé"
    } else {
        "Non en cours d'exécution"
    }
    
    # Ajouter les informations de l'instance au tableau
    $instancesInfo += [PSCustomObject]@{
        Instance = $instanceName
        PID = $pidValue
        Port = $port
        ProcessStatus = $processInfo
        PortStatus = $portStatus
        ApiStatus = $apiStatus
        Status = $globalStatus
    }
}

# Afficher les informations des instances
Write-Host "`n=== Instances n8n ===" -ForegroundColor Cyan
$instancesInfo | Format-Table -AutoSize -Property Instance, PID, Port, Status

# Afficher les détails des instances en cours d'exécution
$runningInstances = $instancesInfo | Where-Object { $_.Status -like "En cours d'exécution*" }
if ($runningInstances.Count -gt 0) {
    Write-Host "`n=== Détails des instances en cours d'exécution ===" -ForegroundColor Cyan
    foreach ($instance in $runningInstances) {
        Write-Host "`nInstance: $($instance.Instance)" -ForegroundColor Green
        Write-Host "PID: $($instance.PID)"
        Write-Host "Port: $($instance.Port)"
        Write-Host "URL: http://localhost:$($instance.Port)/"
        Write-Host "Statut du processus: $($instance.ProcessStatus)"
        Write-Host "Statut du port: $($instance.PortStatus)"
        Write-Host "Statut de l'API: $($instance.ApiStatus)"
        Write-Host "Statut global: $($instance.Status)"
    }
}

# Afficher les instances non en cours d'exécution
$stoppedInstances = $instancesInfo | Where-Object { $_.Status -eq "Non en cours d'exécution" }
if ($stoppedInstances.Count -gt 0) {
    Write-Host "`n=== Instances arrêtées ===" -ForegroundColor Yellow
    $stoppedInstances | Format-Table -AutoSize -Property Instance, Port
}

# Afficher le nombre total d'instances
Write-Host "`nNombre total d'instances: $($instances.Count)" -ForegroundColor Cyan
Write-Host "Instances en cours d'exécution: $($runningInstances.Count)" -ForegroundColor Green
Write-Host "Instances arrêtées: $($stoppedInstances.Count)" -ForegroundColor Yellow
