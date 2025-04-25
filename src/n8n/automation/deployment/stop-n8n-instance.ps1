<#
.SYNOPSIS
    Script d'arrêt propre d'une instance n8n en utilisant le PID.

.DESCRIPTION
    Ce script arrête proprement une instance n8n en utilisant le PID enregistré dans un fichier.

.PARAMETER InstanceName
    Nom de l'instance n8n à arrêter (par défaut: "default").

.PARAMETER Force
    Force l'arrêt du processus si l'arrêt normal échoue.

.EXAMPLE
    .\stop-n8n-instance.ps1 -InstanceName "dev" -Force

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [string]$InstanceName = "default",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false
)

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$instancesPath = Join-Path -Path $n8nPath -ChildPath "instances"
$instancePath = Join-Path -Path $instancesPath -ChildPath $InstanceName
$PidFile = Join-Path -Path $instancePath -ChildPath "n8n-$InstanceName.pid"

# Vérifier si le dossier de l'instance existe
if (-not (Test-Path -Path $instancePath)) {
    Write-Error "Le dossier de l'instance n'existe pas: $instancePath"
    exit 1
}

# Vérifier si le fichier PID existe
if (-not (Test-Path -Path $PidFile)) {
    Write-Error "Le fichier PID n'existe pas: $PidFile"
    Write-Host "n8n (instance: $InstanceName) n'est peut-être pas en cours d'exécution ou a été démarré sans gestion du PID." -ForegroundColor Yellow
    
    # Tenter de trouver et arrêter les processus n8n
    $n8nProcesses = Get-Process | Where-Object { $_.ProcessName -eq "node" -and $_.CommandLine -like "*n8n*" }
    
    if ($n8nProcesses.Count -gt 0) {
        Write-Host "Processus n8n trouvés sans fichier PID. Tentative d'arrêt..." -ForegroundColor Yellow
        
        foreach ($process in $n8nProcesses) {
            Write-Host "Arrêt du processus n8n (PID: $($process.Id))..." -ForegroundColor Yellow
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "Processus n8n arrêtés." -ForegroundColor Green
    } else {
        Write-Host "Aucun processus n8n trouvé." -ForegroundColor Yellow
    }
    
    exit 1
}

# Lire le PID
$pid = Get-Content -Path $PidFile

# Vérifier si le processus existe
try {
    $process = Get-Process -Id $pid -ErrorAction Stop
    
    Write-Host "Arrêt de n8n (instance: $InstanceName, PID: $pid)..." -ForegroundColor Yellow
    
    # Tenter d'arrêter proprement le processus
    $process.CloseMainWindow() | Out-Null
    
    # Attendre que le processus se termine
    $maxWaitTime = 30  # secondes
    $waitTime = 0
    $interval = 1  # secondes
    
    while (-not $process.HasExited -and $waitTime -lt $maxWaitTime) {
        Start-Sleep -Seconds $interval
        $waitTime += $interval
        $process.Refresh()
    }
    
    # Si le processus ne s'est pas terminé et que Force est spécifié, le forcer à s'arrêter
    if (-not $process.HasExited) {
        if ($Force) {
            Write-Host "Le processus ne répond pas. Arrêt forcé..." -ForegroundColor Yellow
            $process.Kill()
        } else {
            Write-Warning "Le processus ne répond pas. Utilisez -Force pour forcer l'arrêt."
            exit 1
        }
    }
    
    Write-Host "n8n (instance: $InstanceName) arrêté avec succès." -ForegroundColor Green
    
    # Supprimer le fichier PID
    Remove-Item -Path $PidFile -Force
} catch {
    Write-Warning "Le processus avec le PID $pid n'existe pas ou ne peut pas être arrêté: $_"
    
    # Supprimer le fichier PID obsolète
    Remove-Item -Path $PidFile -Force
    
    # Tenter de trouver et arrêter les processus n8n
    $n8nProcesses = Get-Process | Where-Object { $_.ProcessName -eq "node" -and $_.CommandLine -like "*n8n*" }
    
    if ($n8nProcesses.Count -gt 0) {
        Write-Host "Processus n8n trouvés. Tentative d'arrêt..." -ForegroundColor Yellow
        
        foreach ($process in $n8nProcesses) {
            Write-Host "Arrêt du processus n8n (PID: $($process.Id))..." -ForegroundColor Yellow
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "Processus n8n arrêtés." -ForegroundColor Green
    } else {
        Write-Host "Aucun processus n8n trouvé." -ForegroundColor Yellow
    }
}
