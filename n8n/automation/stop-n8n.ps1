<#
.SYNOPSIS
    Script pour arrêter n8n.

.DESCRIPTION
    Ce script arrête tous les processus n8n en cours d'exécution.

.EXAMPLE
    .\stop-n8n.ps1
#>

# Définir les chemins
$rootPath = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$configPath = Join-Path -Path $rootPath -ChildPath "config"
$n8nConfigPath = Join-Path -Path $configPath -ChildPath "n8n-config.json"

# Vérifier si le fichier de configuration existe
if (Test-Path -Path $n8nConfigPath) {
    # Lire la configuration
    $config = Get-Content -Path $n8nConfigPath -Raw | ConvertFrom-Json
    
    # Vérifier si n8n est en cours d'exécution
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$($config.port)/healthz" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "n8n est en cours d'exécution sur le port $($config.port)."
        } else {
            Write-Host "n8n n'est pas en cours d'exécution sur le port $($config.port)."
            exit 0
        }
    } catch {
        Write-Host "n8n n'est pas en cours d'exécution."
        exit 0
    }
}

# Arrêter tous les processus n8n
$n8nProcesses = Get-Process -Name "n8n" -ErrorAction SilentlyContinue
$nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*n8n*" }

$processesFound = $false

if ($n8nProcesses) {
    Write-Host "Arrêt des processus n8n..."
    $n8nProcesses | ForEach-Object {
        Write-Host "Arrêt du processus n8n (PID: $($_.Id))..."
        Stop-Process -Id $_.Id -Force
        $processesFound = $true
    }
}

if ($nodeProcesses) {
    Write-Host "Arrêt des processus node exécutant n8n..."
    $nodeProcesses | ForEach-Object {
        Write-Host "Arrêt du processus node (PID: $($_.Id))..."
        Stop-Process -Id $_.Id -Force
        $processesFound = $true
    }
}

if (-not $processesFound) {
    Write-Host "Aucun processus n8n trouvé."
} else {
    Write-Host "Tous les processus n8n ont été arrêtés."
}

# Vérifier si n8n est toujours en cours d'exécution
if (Test-Path -Path $n8nConfigPath) {
    # Lire la configuration
    $config = Get-Content -Path $n8nConfigPath -Raw | ConvertFrom-Json
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$($config.port)/healthz" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Warning "n8n est toujours en cours d'exécution sur le port $($config.port). Veuillez l'arrêter manuellement."
        } else {
            Write-Host "n8n a été arrêté avec succès."
        }
    } catch {
        Write-Host "n8n a été arrêté avec succès."
    }
}
