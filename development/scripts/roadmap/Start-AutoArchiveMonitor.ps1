# Start-AutoArchiveMonitor.ps1
# Script pour surveiller et archiver automatiquement les tâches terminées de la roadmap
# Version: 1.0
# Date: 2025-05-03

[CmdletBinding()]
param (
    [Parameter()]
    [string]$RoadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\active\roadmap_active.md",
    
    [Parameter()]
    [int]$IntervalMinutes = 20,
    
    [Parameter()]
    [string]$IDEProcessName = "Code",
    
    [Parameter()]
    [switch]$UpdateVectorDB,
    
    [Parameter()]
    [switch]$Force
)

# Importer les modules communs
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$commonPath = Join-Path -Path $scriptPath -ChildPath "..\common"
$modulePath = Join-Path -Path $commonPath -ChildPath "RoadmapModule.psm1"

if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module commun introuvable: $modulePath"
    exit 1
}

# Vérifier si le fichier de roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
    exit 1
}

# Fonction pour vérifier si l'IDE est ouvert
function Test-IDERunning {
    param (
        [string]$ProcessName
    )
    
    $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    return $null -ne $process
}

# Fonction pour vérifier si le fichier a été modifié depuis la dernière vérification
function Test-FileChanged {
    param (
        [string]$FilePath,
        [datetime]$LastCheckTime
    )
    
    if (-not (Test-Path -Path $FilePath)) {
        return $false
    }
    
    $lastWriteTime = (Get-Item -Path $FilePath).LastWriteTime
    return $lastWriteTime -gt $LastCheckTime
}

# Fonction pour archiver les tâches terminées
function Invoke-ArchiveCompletedTasks {
    param (
        [string]$RoadmapPath,
        [bool]$UpdateVectorDB,
        [bool]$Force
    )
    
    $archiveScriptPath = Join-Path -Path $scriptPath -ChildPath "Archive-CompletedTasks.ps1"
    
    if (-not (Test-Path -Path $archiveScriptPath)) {
        Write-Log "Script d'archivage introuvable: $archiveScriptPath" -Level Error
        return $false
    }
    
    # Construire les paramètres pour le script d'archivage
    $params = @{
        RoadmapPath = $RoadmapPath
    }
    
    if ($UpdateVectorDB) {
        $params.Add("UpdateVectorDB", $true)
    }
    
    if ($Force) {
        $params.Add("Force", $true)
    }
    
    # Convertir les paramètres en chaîne de commande
    $paramString = ""
    foreach ($key in $params.Keys) {
        $value = $params[$key]
        if ($value -is [bool] -and $value) {
            $paramString += " -$key"
        } else {
            $paramString += " -$key `"$value`""
        }
    }
    
    # Exécuter le script d'archivage
    $command = "& `"$archiveScriptPath`"$paramString"
    Write-Log "Exécution de la commande: $command" -Level Info
    
    try {
        Invoke-Expression $command
        Write-Log "Archivage automatique exécuté avec succès." -Level Success
        return $true
    } catch {
        Write-Log "Erreur lors de l'archivage automatique: $_" -Level Error
        return $false
    }
}

# Fonction principale pour surveiller et archiver
function Start-Monitor {
    $intervalSeconds = $IntervalMinutes * 60
    $lastCheckTime = [datetime]::MinValue
    $lastArchiveTime = [datetime]::MinValue
    
    Write-Host "Démarrage du moniteur d'archivage automatique..."
    Write-Host "Intervalle: $IntervalMinutes minutes"
    Write-Host "Fichier de roadmap: $RoadmapPath"
    Write-Host "Processus IDE: $IDEProcessName"
    Write-Host "Mise à jour de la base vectorielle: $UpdateVectorDB"
    Write-Host "Mode forcé: $Force"
    Write-Host "Appuyez sur Ctrl+C pour arrêter le moniteur."
    
    try {
        while ($true) {
            $currentTime = Get-Date
            
            # Vérifier si l'IDE est ouvert
            $ideRunning = Test-IDERunning -ProcessName $IDEProcessName
            
            if ($ideRunning) {
                # Vérifier si le fichier a été modifié
                $fileChanged = Test-FileChanged -FilePath $RoadmapPath -LastCheckTime $lastCheckTime
                
                # Mettre à jour le temps de dernière vérification
                $lastCheckTime = $currentTime
                
                # Vérifier si l'intervalle d'archivage est écoulé
                $timeElapsed = $currentTime - $lastArchiveTime
                $intervalElapsed = $timeElapsed.TotalSeconds -ge $intervalSeconds
                
                if ($fileChanged -and $intervalElapsed) {
                    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Fichier modifié et intervalle écoulé, exécution de l'archivage automatique..."
                    
                    # Archiver les tâches terminées
                    $result = Invoke-ArchiveCompletedTasks -RoadmapPath $RoadmapPath -UpdateVectorDB $UpdateVectorDB -Force $Force
                    
                    if ($result) {
                        # Mettre à jour le temps de dernier archivage
                        $lastArchiveTime = $currentTime
                    }
                } else {
                    if (-not $fileChanged) {
                        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Aucune modification détectée dans le fichier de roadmap."
                    }
                    
                    if (-not $intervalElapsed) {
                        $remainingMinutes = [math]::Ceiling(($intervalSeconds - $timeElapsed.TotalSeconds) / 60)
                        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Prochain archivage possible dans $remainingMinutes minutes."
                    }
                }
            } else {
                Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - IDE ($IDEProcessName) non détecté, surveillance en pause."
            }
            
            # Attendre avant la prochaine vérification (30 secondes)
            Start-Sleep -Seconds 30
        }
    } catch {
        Write-Host "Erreur dans la boucle de surveillance: $_" -ForegroundColor Red
    } finally {
        Write-Host "Arrêt du moniteur d'archivage automatique."
    }
}

# Démarrer le moniteur
Start-Monitor
