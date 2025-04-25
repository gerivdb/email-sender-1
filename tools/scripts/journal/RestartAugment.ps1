# Script de redémarrage Augment
# Ce script permet de relancer Augment en cas d'échec

param (
    [Parameter(Mandatory = $true)]
    [string]$Task,
    [string]$RoadmapPath = ""Roadmap\roadmap_perso.md"",
    [switch]$UpdateRoadmap = $true,
    [int]$MaxRetries = 3,
    [int]$RetryDelay = 5
)

# Configuration
$logFile = "RestartAugment.log"
$augmentExecutorPath = "AugmentExecutor.ps1"
$roadmapAdminPath = "RoadmapAdmin.ps1"

# Fonction pour écrire dans le journal
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Écrire dans le fichier journal
    Add-Content -Path $logFile -Value $logEntry
    
    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        default { Write-Host $logEntry }
    }
}

# Fonction pour exécuter Augment avec plusieurs tentatives
function Invoke-AugmentWithRetry {
    param (
        [string]$Task
    )
    
    $retryCount = 0
    $success = $false
    
    while (-not $success -and $retryCount -lt $MaxRetries) {
        try {
            Write-Log "Tentative d'exécution #$($retryCount + 1)" "INFO"
            
            # Exécuter le script Augment
            & $augmentExecutorPath -Task $Task
            
            $success = $true
            Write-Log "Exécution réussie" "SUCCESS"
        }
        catch {
            $retryCount++
            Write-Log "Échec de l'exécution: $_" "ERROR"
            
            if ($retryCount -lt $MaxRetries) {
                Write-Log "Nouvelle tentative dans $RetryDelay secondes..." "WARNING"
                Start-Sleep -Seconds $RetryDelay
            }
        }
    }
    
    return $success
}

# Fonction pour mettre à jour la roadmap
function Update-RoadmapTask {
    param (
        [string]$Task
    )
    
    try {
        Write-Log "Mise à jour de la roadmap pour la tâche: $Task" "INFO"
        
        # Exécuter le script d'administration de la roadmap
        & $roadmapAdminPath -RoadmapPath $RoadmapPath -AutoUpdate
        
        Write-Log "Roadmap mise à jour avec succès" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Échec de la mise à jour de la roadmap: $_" "ERROR"
        return $false
    }
}

# Fonction principale
function Restart-Augment {
    # Exécuter Augment avec plusieurs tentatives
    $success = Invoke-AugmentWithRetry -Task $Task
    
    # Mettre à jour la roadmap si demandé et si l'exécution a réussi
    if ($UpdateRoadmap -and $success) {
        Update-RoadmapTask -Task $Task
    }
    
    return $success
}

# Démarrer le script
Write-Log "Démarrage du script de redémarrage Augment" "INFO"
Write-Log "Tâche: $Task" "INFO"
$success = Restart-Augment
Write-Log "Fin du script de redémarrage Augment (Succès: $success)" "INFO"

return $success
