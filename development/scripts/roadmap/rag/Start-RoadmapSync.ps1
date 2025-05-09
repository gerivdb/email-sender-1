# Start-RoadmapSync.ps1
# Script pour synchroniser automatiquement les roadmaps avec Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "projet/roadmaps/active/roadmap_active.md",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "projet/roadmaps/analysis",
    
    [Parameter(Mandatory = $false)]
    [int]$IntervalMinutes = 20,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$NoPrompt
)

# Fonction de journalisation simplifiée
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedMessage = "[$timestamp] [$Level] $Message"
    
    Write-Host $formattedMessage -ForegroundColor $color
    
    # Ajouter au fichier de log
    $logPath = Join-Path -Path $OutputDirectory -ChildPath "sync_log.txt"
    Add-Content -Path $logPath -Value $formattedMessage
}

# Fonction pour vérifier si le fichier a été modifié
function Test-FileModified {
    param (
        [string]$FilePath,
        [datetime]$LastSyncTime
    )
    
    if (-not (Test-Path -Path $FilePath)) {
        Write-Log "Le fichier $FilePath n'existe pas." -Level "Error"
        return $false
    }
    
    $fileInfo = Get-Item -Path $FilePath
    return $fileInfo.LastWriteTime -gt $LastSyncTime
}

# Fonction pour vérifier si l'IDE est ouvert
function Test-IDEOpen {
    # Vérifier si VS Code est ouvert
    $vsCodeProcess = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    
    if ($vsCodeProcess) {
        return $true
    }
    
    # Vérifier si Visual Studio est ouvert
    $vsProcess = Get-Process -Name "devenv" -ErrorAction SilentlyContinue
    
    if ($vsProcess) {
        return $true
    }
    
    return $false
}

# Fonction pour exécuter l'analyse des roadmaps
function Invoke-RoadmapAnalysis {
    param (
        [string]$OutputDirectory,
        [switch]$Force
    )
    
    Write-Log "Exécution de l'analyse des roadmaps..." -Level "Info"
    
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Simple-RoadmapAnalysis.ps1"
    
    if (-not (Test-Path -Path $scriptPath)) {
        Write-Log "Le script $scriptPath n'existe pas." -Level "Error"
        return $false
    }
    
    $params = @{
        Action = "All"
        OutputDirectory = $OutputDirectory
    }
    
    if ($Force) {
        $params.Force = $true
    }
    
    & $scriptPath @params
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Analyse des roadmaps terminée avec succès." -Level "Success"
        return $true
    }
    else {
        Write-Log "Erreur lors de l'analyse des roadmaps." -Level "Error"
        return $false
    }
}

# Fonction pour vectoriser les roadmaps
function Invoke-RoadmapVectorization {
    param (
        [string]$InventoryPath,
        [switch]$Force
    )
    
    Write-Log "Vectorisation des roadmaps..." -Level "Info"
    
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-RoadmapRAG.ps1"
    
    if (-not (Test-Path -Path $scriptPath)) {
        Write-Log "Le script $scriptPath n'existe pas." -Level "Error"
        return $false
    }
    
    $params = @{
        Action = "Vectorize"
        InventoryPath = $InventoryPath
    }
    
    if ($Force) {
        $params.Force = $true
    }
    
    & $scriptPath @params
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Vectorisation des roadmaps terminée avec succès." -Level "Success"
        return $true
    }
    else {
        Write-Log "Erreur lors de la vectorisation des roadmaps." -Level "Error"
        return $false
    }
}

# Fonction pour archiver les tâches terminées
function Invoke-TaskArchiving {
    param (
        [string]$RoadmapPath
    )
    
    Write-Log "Archivage des tâches terminées..." -Level "Info"
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Log "Le fichier $RoadmapPath n'existe pas." -Level "Error"
        return $false
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $RoadmapPath -Raw
    
    # Identifier les tâches terminées
    $completedTasksCount = ([regex]::Matches($content, "\s*[-*+]\s*\[[xX]\]")).Count
    
    Write-Log "Trouvé $completedTasksCount tâches terminées." -Level "Info"
    
    # Pour l'instant, nous ne faisons pas d'archivage réel
    # Cette fonction sera implémentée ultérieurement
    
    return $true
}

# Fonction principale pour synchroniser les roadmaps
function Start-RoadmapSync {
    param (
        [string]$RoadmapPath,
        [string]$OutputDirectory,
        [int]$IntervalMinutes,
        [switch]$Force,
        [switch]$NoPrompt
    )
    
    Write-Log "Démarrage de la synchronisation automatique des roadmaps..." -Level "Info"
    Write-Log "  - Fichier roadmap: $RoadmapPath" -Level "Info"
    Write-Log "  - Dossier de sortie: $OutputDirectory" -Level "Info"
    Write-Log "  - Intervalle: $IntervalMinutes minutes" -Level "Info"
    
    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputDirectory)) {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    }
    
    # Demander confirmation si -NoPrompt n'est pas spécifié
    if (-not $NoPrompt) {
        $confirmation = Read-Host "Voulez-vous démarrer la synchronisation automatique des roadmaps ? (O/N)"
        if ($confirmation -ne "O") {
            Write-Log "Opération annulée." -Level "Info"
            return
        }
    }
    
    # Initialiser la dernière heure de synchronisation
    $lastSyncTime = [datetime]::MinValue
    
    # Boucle principale
    while ($true) {
        # Vérifier si l'IDE est ouvert
        if (-not (Test-IDEOpen)) {
            Write-Log "Aucun IDE n'est ouvert. En attente..." -Level "Info"
            Start-Sleep -Seconds 60
            continue
        }
        
        # Vérifier si le fichier a été modifié
        if (Test-FileModified -FilePath $RoadmapPath -LastSyncTime $lastSyncTime) {
            Write-Log "Le fichier $RoadmapPath a été modifié depuis la dernière synchronisation." -Level "Info"
            
            # Exécuter l'analyse des roadmaps
            $analysisSuccess = Invoke-RoadmapAnalysis -OutputDirectory $OutputDirectory -Force:$Force
            
            if ($analysisSuccess) {
                # Vectoriser les roadmaps
                $inventoryPath = Join-Path -Path $OutputDirectory -ChildPath "inventory.json"
                $vectorizationSuccess = Invoke-RoadmapVectorization -InventoryPath $inventoryPath -Force:$Force
                
                if ($vectorizationSuccess) {
                    # Archiver les tâches terminées
                    $archivingSuccess = Invoke-TaskArchiving -RoadmapPath $RoadmapPath
                    
                    if ($archivingSuccess) {
                        # Mettre à jour la dernière heure de synchronisation
                        $lastSyncTime = Get-Date
                        Write-Log "Synchronisation terminée avec succès." -Level "Success"
                    }
                }
            }
        }
        else {
            Write-Log "Aucune modification détectée depuis la dernière synchronisation." -Level "Info"
        }
        
        # Attendre l'intervalle spécifié
        Write-Log "En attente de la prochaine synchronisation dans $IntervalMinutes minutes..." -Level "Info"
        Start-Sleep -Seconds ($IntervalMinutes * 60)
    }
}

# Exécution principale
try {
    Start-RoadmapSync -RoadmapPath $RoadmapPath -OutputDirectory $OutputDirectory -IntervalMinutes $IntervalMinutes -Force:$Force -NoPrompt:$NoPrompt
}
catch {
    Write-Log "Erreur lors de la synchronisation des roadmaps : $_" -Level "Error"
    throw $_
}
