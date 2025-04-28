# Script de redÃ©marrage Augment
# Ce script permet de relancer Augment en cas d'Ã©chec

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

# Fonction pour Ã©crire dans le journal
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Ã‰crire dans le fichier journal
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

# Fonction pour exÃ©cuter Augment avec plusieurs tentatives
function Invoke-AugmentWithRetry {
    param (
        [string]$Task
    )
    
    $retryCount = 0
    $success = $false
    
    while (-not $success -and $retryCount -lt $MaxRetries) {
        try {
            Write-Log "Tentative d'exÃ©cution #$($retryCount + 1)" "INFO"
            
            # ExÃ©cuter le script Augment
            & $augmentExecutorPath -Task $Task
            
            $success = $true
            Write-Log "ExÃ©cution rÃ©ussie" "SUCCESS"
        }
        catch {
            $retryCount++
            Write-Log "Ã‰chec de l'exÃ©cution: $_" "ERROR"
            
            if ($retryCount -lt $MaxRetries) {
                Write-Log "Nouvelle tentative dans $RetryDelay secondes..." "WARNING"
                Start-Sleep -Seconds $RetryDelay
            }
        }
    }
    
    return $success
}

# Fonction pour mettre Ã  jour la roadmap
function Update-RoadmapTask {
    param (
        [string]$Task
    )
    
    try {
        Write-Log "Mise Ã  jour de la roadmap pour la tÃ¢che: $Task" "INFO"
        
        # ExÃ©cuter le script d'administration de la roadmap
        & $roadmapAdminPath -RoadmapPath $RoadmapPath -AutoUpdate
        
        Write-Log "Roadmap mise Ã  jour avec succÃ¨s" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Ã‰chec de la mise Ã  jour de la roadmap: $_" "ERROR"
        return $false
    }
}

# Fonction principale
function Restart-Augment {
    # ExÃ©cuter Augment avec plusieurs tentatives
    $success = Invoke-AugmentWithRetry -Task $Task
    
    # Mettre Ã  jour la roadmap si demandÃ© et si l'exÃ©cution a rÃ©ussi
    if ($UpdateRoadmap -and $success) {
        Update-RoadmapTask -Task $Task
    }
    
    return $success
}

# DÃ©marrer le script
Write-Log "DÃ©marrage du script de redÃ©marrage Augment" "INFO"
Write-Log "TÃ¢che: $Task" "INFO"
$success = Restart-Augment
Write-Log "Fin du script de redÃ©marrage Augment (SuccÃ¨s: $success)" "INFO"

return $success
