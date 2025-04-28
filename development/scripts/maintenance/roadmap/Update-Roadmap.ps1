#Requires -Version 5.1
<#
.SYNOPSIS
    Met Ã  jour le roadmap avec les tÃ¢ches implÃ©mentÃ©es.
.DESCRIPTION
    Ce script met Ã  jour le fichier roadmap en marquant les tÃ¢ches implÃ©mentÃ©es
    et en ajoutant des informations sur l'implÃ©mentation.
.PARAMETER RoadmapPath
    Chemin du fichier roadmap.
.PARAMETER TaskIds
    IDs des tÃ¢ches Ã  marquer comme implÃ©mentÃ©es.
.PARAMETER ImplementationInfo
    Informations sur l'implÃ©mentation (date, version, etc.).
.PARAMETER ArchiveCompleted
    Archive les tÃ¢ches complÃ©tÃ©es dans un fichier sÃ©parÃ©.
.EXAMPLE
    .\Update-Roadmap.ps1 -RoadmapPath ".\roadmap_complete.md" -TaskIds @("1.1.1", "1.1.2") -ImplementationInfo "ImplÃ©mentÃ© le 2025-05-25"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-05-25
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = ".\roadmap_complete.md",
    
    [Parameter(Mandatory = $true)]
    [string[]]$TaskIds,
    
    [Parameter(Mandatory = $false)]
    [string]$ImplementationInfo = "ImplÃ©mentÃ© le $(Get-Date -Format 'yyyy-MM-dd')",
    
    [Parameter(Mandatory = $false)]
    [switch]$ArchiveCompleted
)

# Fonction pour Ã©crire dans le journal
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

# VÃ©rifier si le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Log "Le fichier roadmap n'existe pas: $RoadmapPath" -Level "ERROR"
    exit 1
}

# Lire le contenu du roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# CrÃ©er un fichier d'archive si nÃ©cessaire
$archivePath = ""
if ($ArchiveCompleted) {
    $archivePath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($RoadmapPath), "completed_tasks.md")
    
    if (-not (Test-Path -Path $archivePath)) {
        @"
# TÃ¢ches complÃ©tÃ©es

Ce fichier contient les tÃ¢ches complÃ©tÃ©es du roadmap.

"@ | Out-File -FilePath $archivePath -Encoding utf8
    }
}

# Mettre Ã  jour les tÃ¢ches
$updatedContent = $roadmapContent
$completedTasks = @()

foreach ($taskId in $TaskIds) {
    # Ã‰chapper les caractÃ¨res spÃ©ciaux dans l'ID de tÃ¢che pour la regex
    $escapedTaskId = [regex]::Escape($taskId)
    
    # Rechercher la tÃ¢che dans le roadmap
    $taskRegex = "(\s*-\s*\[[ x]\]\s*\($escapedTaskId\)\s*)(.*?)(\r?\n)"
    $taskMatch = [regex]::Match($roadmapContent, $taskRegex)
    
    if ($taskMatch.Success) {
        $taskPrefix = $taskMatch.Groups[1].Value
        $taskDescription = $taskMatch.Groups[2].Value
        $taskSuffix = $taskMatch.Groups[3].Value
        
        # VÃ©rifier si la tÃ¢che est dÃ©jÃ  marquÃ©e comme complÃ©tÃ©e
        if ($taskPrefix -match "\[\s*x\s*\]") {
            Write-Log "La tÃ¢che $taskId est dÃ©jÃ  marquÃ©e comme complÃ©tÃ©e." -Level "WARNING"
            continue
        }
        
        # Mettre Ã  jour la tÃ¢che
        $updatedTaskPrefix = $taskPrefix -replace "\[\s*\]", "[x]"
        $updatedTaskDescription = "$taskDescription - $ImplementationInfo"
        
        $updatedContent = $updatedContent -replace [regex]::Escape($taskMatch.Value), "$updatedTaskPrefix$updatedTaskDescription$taskSuffix"
        
        Write-Log "TÃ¢che $taskId marquÃ©e comme complÃ©tÃ©e." -Level "SUCCESS"
        
        # Ajouter Ã  la liste des tÃ¢ches complÃ©tÃ©es
        $completedTasks += [PSCustomObject]@{
            Id = $taskId
            Description = $taskDescription.Trim()
            ImplementationInfo = $ImplementationInfo
        }
    }
    else {
        Write-Log "TÃ¢che $taskId non trouvÃ©e dans le roadmap." -Level "WARNING"
    }
}

# Enregistrer le roadmap mis Ã  jour
$updatedContent | Out-File -FilePath $RoadmapPath -Encoding utf8

Write-Log "Roadmap mis Ã  jour: $RoadmapPath" -Level "SUCCESS"

# Archiver les tÃ¢ches complÃ©tÃ©es si demandÃ©
if ($ArchiveCompleted -and $completedTasks.Count -gt 0) {
    $archiveContent = Get-Content -Path $archivePath -Raw
    
    $newArchiveContent = $archiveContent
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $newArchiveContent += "`n## TÃ¢ches complÃ©tÃ©es le $timestamp`n`n"
    
    foreach ($task in $completedTasks) {
        $newArchiveContent += "- ($($task.Id)) $($task.Description) - $($task.ImplementationInfo)`n"
    }
    
    $newArchiveContent | Out-File -FilePath $archivePath -Encoding utf8
    
    Write-Log "TÃ¢ches archivÃ©es: $archivePath" -Level "SUCCESS"
}

# Afficher un rÃ©sumÃ©
Write-Log "`nRÃ©sumÃ© de la mise Ã  jour du roadmap:" -Level "INFO"
Write-Log "  TÃ¢ches mises Ã  jour: $($completedTasks.Count)" -Level "INFO"
Write-Log "  TÃ¢ches non trouvÃ©es: $($TaskIds.Count - $completedTasks.Count)" -Level "INFO"

if ($completedTasks.Count -gt 0) {
    Write-Log "`nTÃ¢ches complÃ©tÃ©es:" -Level "INFO"
    foreach ($task in $completedTasks) {
        Write-Log "  ($($task.Id)) $($task.Description)" -Level "SUCCESS"
    }
}

if ($TaskIds.Count -gt $completedTasks.Count) {
    Write-Log "`nTÃ¢ches non trouvÃ©es:" -Level "WARNING"
    foreach ($taskId in $TaskIds) {
        if (-not ($completedTasks | Where-Object { $_.Id -eq $taskId })) {
            Write-Log "  $taskId" -Level "WARNING"
        }
    }
}
