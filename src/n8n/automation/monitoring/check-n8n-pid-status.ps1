<#
.SYNOPSIS
    Script de vérification de l'état de n8n en utilisant le PID.

.DESCRIPTION
    Ce script vérifie si n8n est en cours d'exécution en utilisant le PID enregistré dans un fichier.

.PARAMETER PidFile
    Chemin du fichier contenant le PID (par défaut: n8n.pid).

.PARAMETER Port
    Port sur lequel n8n est censé être accessible (par défaut: 5678).

.EXAMPLE
    .\check-n8n-pid-status.ps1 -PidFile "custom.pid" -Port 5679

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$PidFile = "n8n.pid",

    [Parameter(Mandatory = $false)]
    [int]$Port = 5678
)

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$PidFile = Join-Path -Path $n8nPath -ChildPath $PidFile

# Fonction pour vérifier si le port est utilisé
function Test-PortInUse {
    param (
        [Parameter(Mandatory = $true)]
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

# Vérifier si le fichier PID existe
$pidFileExists = Test-Path -Path $PidFile
$pidStatus = if ($pidFileExists) { "Existe" } else { "N'existe pas" }

# Lire le PID si le fichier existe
$pidValue = if ($pidFileExists) { Get-Content -Path $PidFile } else { "N/A" }

# Vérifier si le processus existe
$processExists = $false
$processInfo = "N/A"

if ($pidFileExists) {
    try {
        $process = Get-Process -Id $pidValue -ErrorAction SilentlyContinue
        if ($null -ne $process) {
            $processExists = $true
            $processInfo = "En cours d'exécution (Nom: $($process.ProcessName), Mémoire: $([Math]::Round($process.WorkingSet / 1MB, 2)) MB)"
        } else {
            $processInfo = "N'existe pas (PID obsolète)"
        }
    } catch {
        $processInfo = "Erreur lors de la vérification du processus: $_"
    }
}

# Vérifier si le port est utilisé
$portInUse = Test-PortInUse -Port $Port
$portStatus = if ($portInUse) { "Utilisé" } else { "Non utilisé" }

# Vérifier si n8n est accessible via l'API
$apiAccessible = $false
$apiStatus = "N/A"

if ($portInUse) {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:$Port/healthz" -Method Get -ErrorAction SilentlyContinue
        if ($response.status -eq "ok") {
            $apiAccessible = $true
            $apiStatus = "Accessible (status: $($response.status))"
        } else {
            $apiStatus = "Accessible mais statut incorrect: $($response.status)"
        }
    } catch {
        $apiStatus = "Non accessible: $_"
    }
}

# Afficher les résultats
Write-Host "`n=== État de n8n ===" -ForegroundColor Cyan
Write-Host "Fichier PID: $pidStatus ($PidFile)" -ForegroundColor $(if ($pidFileExists) { "Green" } else { "Red" })
Write-Host "PID: $pidValue" -ForegroundColor $(if ($pidFileExists) { "Green" } else { "Gray" })
Write-Host "Processus: $processInfo" -ForegroundColor $(if ($processExists) { "Green" } else { "Red" })
Write-Host "Port $($Port): $portStatus" -ForegroundColor $(if ($portInUse) { "Green" } else { "Red" })
Write-Host "API: $apiStatus" -ForegroundColor $(if ($apiAccessible) { "Green" } else { "Red" })

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

Write-Host "`nÉtat global: $globalStatus" -ForegroundColor $(if ($processExists -and $portInUse -and $apiAccessible) { "Green" } else { "Red" })

# Retourner un code de sortie
if ($processExists -and $portInUse -and $apiAccessible) {
    exit 0  # Tout est OK
} else {
    exit 1  # Problème détecté
}
