<#
.SYNOPSIS
    Script pour vérifier les ports utilisés par n8n.

.DESCRIPTION
    Ce script vérifie les ports utilisés par n8n et trouve des ports disponibles.

.PARAMETER StartPort
    Port de départ pour la recherche de ports disponibles (par défaut: 5678).

.PARAMETER EndPort
    Port de fin pour la recherche de ports disponibles (par défaut: 5700).

.PARAMETER FindAvailable
    Nombre de ports disponibles à trouver (par défaut: 1).

.EXAMPLE
    .\check-n8n-ports.ps1 -StartPort 5678 -EndPort 5700 -FindAvailable 3

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [int]$StartPort = 5678,
    
    [Parameter(Mandatory=$false)]
    [int]$EndPort = 5700,
    
    [Parameter(Mandatory=$false)]
    [int]$FindAvailable = 1
)

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

# Fonction pour trouver des ports disponibles
function Find-AvailablePorts {
    param (
        [Parameter(Mandatory=$true)]
        [int]$StartPort,
        
        [Parameter(Mandatory=$true)]
        [int]$EndPort,
        
        [Parameter(Mandatory=$true)]
        [int]$Count
    )
    
    $availablePorts = @()
    $currentPort = $StartPort
    
    while ($currentPort -le $EndPort -and $availablePorts.Count -lt $Count) {
        if (-not (Test-PortInUse -Port $currentPort)) {
            $availablePorts += $currentPort
        }
        
        $currentPort++
    }
    
    return $availablePorts
}

# Vérifier les ports utilisés
Write-Host "`n=== Vérification des ports utilisés ===" -ForegroundColor Cyan
$usedPorts = @()
$availablePorts = @()

for ($port = $StartPort; $port -le $EndPort; $port++) {
    $inUse = Test-PortInUse -Port $port
    
    if ($inUse) {
        $usedPorts += $port
    } else {
        $availablePorts += $port
    }
}

# Afficher les ports utilisés
if ($usedPorts.Count -gt 0) {
    Write-Host "`nPorts utilisés:" -ForegroundColor Yellow
    foreach ($port in $usedPorts) {
        Write-Host "  - $port"
    }
} else {
    Write-Host "`nAucun port utilisé entre $StartPort et $EndPort." -ForegroundColor Green
}

# Trouver des ports disponibles
$portsToFind = [Math]::Min($FindAvailable, $availablePorts.Count)
$foundPorts = $availablePorts | Select-Object -First $portsToFind

# Afficher les ports disponibles
if ($foundPorts.Count -gt 0) {
    Write-Host "`nPorts disponibles:" -ForegroundColor Green
    foreach ($port in $foundPorts) {
        Write-Host "  - $port"
    }
} else {
    Write-Host "`nAucun port disponible entre $StartPort et $EndPort." -ForegroundColor Red
}

# Afficher le résumé
Write-Host "`n=== Résumé ===" -ForegroundColor Cyan
Write-Host "Plage de ports vérifiée: $StartPort - $EndPort"
Write-Host "Ports utilisés: $($usedPorts.Count)"
Write-Host "Ports disponibles: $($availablePorts.Count)"

# Retourner les ports disponibles
return $foundPorts
