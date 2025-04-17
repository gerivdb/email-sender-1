#Requires -Version 5.1
<#
.SYNOPSIS
    Met à jour le roadmap avec les tâches implémentées.
.DESCRIPTION
    Ce script met à jour le fichier roadmap en marquant les tâches implémentées
    et en ajoutant des informations sur l'implémentation.
.PARAMETER RoadmapPath
    Chemin du fichier roadmap.
.PARAMETER TaskIds
    IDs des tâches à marquer comme implémentées.
.PARAMETER ImplementationInfo
    Informations sur l'implémentation (date, version, etc.).
.PARAMETER ArchiveCompleted
    Archive les tâches complétées dans un fichier séparé.
.EXAMPLE
    .\Update-Roadmap.ps1 -RoadmapPath ".\roadmap_complete.md" -TaskIds @("1.1.1", "1.1.2") -ImplementationInfo "Implémenté le 2025-05-25"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-25
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = ".\roadmap_complete.md",
    
    [Parameter(Mandatory = $true)]
    [string[]]$TaskIds,
    
    [Parameter(Mandatory = $false)]
    [string]$ImplementationInfo = "Implémenté le $(Get-Date -Format 'yyyy-MM-dd')",
    
    [Parameter(Mandatory = $false)]
    [switch]$ArchiveCompleted
)

# Fonction pour écrire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

# Vérifier si le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Log "Le fichier roadmap n'existe pas: $RoadmapPath" -Level "ERROR"
    exit 1
}

# Lire le contenu du roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# Créer un fichier d'archive si nécessaire
$archivePath = ""
if ($ArchiveCompleted) {
    $archivePath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($RoadmapPath), "completed_tasks.md")
    
    if (-not (Test-Path -Path $archivePath)) {
        @"
# Tâches complétées

Ce fichier contient les tâches complétées du roadmap.

"@ | Out-File -FilePath $archivePath -Encoding utf8
    }
}

# Mettre à jour les tâches
$updatedContent = $roadmapContent
$completedTasks = @()

foreach ($taskId in $TaskIds) {
    # Échapper les caractères spéciaux dans l'ID de tâche pour la regex
    $escapedTaskId = [regex]::Escape($taskId)
    
    # Rechercher la tâche dans le roadmap
    $taskRegex = "(\s*-\s*\[[ x]\]\s*\($escapedTaskId\)\s*)(.*?)(\r?\n)"
    $taskMatch = [regex]::Match($roadmapContent, $taskRegex)
    
    if ($taskMatch.Success) {
        $taskPrefix = $taskMatch.Groups[1].Value
        $taskDescription = $taskMatch.Groups[2].Value
        $taskSuffix = $taskMatch.Groups[3].Value
        
        # Vérifier si la tâche est déjà marquée comme complétée
        if ($taskPrefix -match "\[\s*x\s*\]") {
            Write-Log "La tâche $taskId est déjà marquée comme complétée." -Level "WARNING"
            continue
        }
        
        # Mettre à jour la tâche
        $updatedTaskPrefix = $taskPrefix -replace "\[\s*\]", "[x]"
        $updatedTaskDescription = "$taskDescription - $ImplementationInfo"
        
        $updatedContent = $updatedContent -replace [regex]::Escape($taskMatch.Value), "$updatedTaskPrefix$updatedTaskDescription$taskSuffix"
        
        Write-Log "Tâche $taskId marquée comme complétée." -Level "SUCCESS"
        
        # Ajouter à la liste des tâches complétées
        $completedTasks += [PSCustomObject]@{
            Id = $taskId
            Description = $taskDescription.Trim()
            ImplementationInfo = $ImplementationInfo
        }
    }
    else {
        Write-Log "Tâche $taskId non trouvée dans le roadmap." -Level "WARNING"
    }
}

# Enregistrer le roadmap mis à jour
$updatedContent | Out-File -FilePath $RoadmapPath -Encoding utf8

Write-Log "Roadmap mis à jour: $RoadmapPath" -Level "SUCCESS"

# Archiver les tâches complétées si demandé
if ($ArchiveCompleted -and $completedTasks.Count -gt 0) {
    $archiveContent = Get-Content -Path $archivePath -Raw
    
    $newArchiveContent = $archiveContent
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $newArchiveContent += "`n## Tâches complétées le $timestamp`n`n"
    
    foreach ($task in $completedTasks) {
        $newArchiveContent += "- ($($task.Id)) $($task.Description) - $($task.ImplementationInfo)`n"
    }
    
    $newArchiveContent | Out-File -FilePath $archivePath -Encoding utf8
    
    Write-Log "Tâches archivées: $archivePath" -Level "SUCCESS"
}

# Afficher un résumé
Write-Log "`nRésumé de la mise à jour du roadmap:" -Level "INFO"
Write-Log "  Tâches mises à jour: $($completedTasks.Count)" -Level "INFO"
Write-Log "  Tâches non trouvées: $($TaskIds.Count - $completedTasks.Count)" -Level "INFO"

if ($completedTasks.Count -gt 0) {
    Write-Log "`nTâches complétées:" -Level "INFO"
    foreach ($task in $completedTasks) {
        Write-Log "  ($($task.Id)) $($task.Description)" -Level "SUCCESS"
    }
}

if ($TaskIds.Count -gt $completedTasks.Count) {
    Write-Log "`nTâches non trouvées:" -Level "WARNING"
    foreach ($taskId in $TaskIds) {
        if (-not ($completedTasks | Where-Object { $_.Id -eq $taskId })) {
            Write-Log "  $taskId" -Level "WARNING"
        }
    }
}
