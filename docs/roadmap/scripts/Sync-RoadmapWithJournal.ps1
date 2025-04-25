#Requires -Version 5.1
<#
.SYNOPSIS
    Synchronise le fichier roadmap_complete.md avec le système de journalisation.
.DESCRIPTION
    Ce script synchronise le fichier roadmap_complete.md avec le système de journalisation,
    en mettant à jour les statuts des tâches dans le roadmap en fonction des entrées du journal.
.PARAMETER RoadmapPath
    Chemin du fichier roadmap.
.PARAMETER JournalPath
    Chemin du dossier journal.
.PARAMETER UpdateRoadmap
    Indique si le roadmap doit être mis à jour avec les informations du journal.
.PARAMETER UpdateJournal
    Indique si le journal doit être mis à jour avec les informations du roadmap.
.EXAMPLE
    .\Sync-RoadmapWithJournal.ps1 -RoadmapPath ".\roadmap_complete.md" -JournalPath ".\journal" -UpdateRoadmap
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-25
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete.md",
    
    [Parameter(Mandatory = $false)]
    [string]$JournalPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\journal",
    
    [Parameter(Mandatory = $false)]
    [switch]$UpdateRoadmap,
    
    [Parameter(Mandatory = $false)]
    [switch]$UpdateJournal
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

# Vérifier si les chemins existent
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Log "Le fichier roadmap n'existe pas: $RoadmapPath" -Level "ERROR"
    exit 1
}

if (-not (Test-Path -Path $JournalPath)) {
    Write-Log "Le dossier journal n'existe pas: $JournalPath" -Level "ERROR"
    exit 1
}

# Charger le fichier index.json
$indexPath = Join-Path -Path $JournalPath -ChildPath "index.json"
if (-not (Test-Path -Path $indexPath)) {
    Write-Log "Le fichier index.json n'existe pas: $indexPath" -Level "ERROR"
    exit 1
}

$indexJson = Get-Content -Path $indexPath -Raw | ConvertFrom-Json
$entries = $indexJson.entries

# Lire le contenu du roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# Mettre à jour le roadmap avec les informations du journal
if ($UpdateRoadmap) {
    Write-Log "Mise à jour du roadmap avec les informations du journal..." -Level "INFO"
    
    $updatedContent = $roadmapContent
    
    foreach ($entryKey in $entries.PSObject.Properties.Name) {
        $entryPath = $entries.$entryKey
        
        # Vérifier si le fichier d'entrée existe
        if (-not (Test-Path -Path $entryPath)) {
            Write-Log "Le fichier d'entrée n'existe pas: $entryPath" -Level "WARNING"
            continue
        }
        
        # Charger l'entrée
        $entryJson = Get-Content -Path $entryPath -Raw | ConvertFrom-Json
        
        # Vérifier si l'entrée est complétée
        if ($entryJson.status -eq "Completed") {
            # Échapper les caractères spéciaux dans l'ID de tâche pour la regex
            $escapedTaskId = [regex]::Escape($entryJson.id)
            
            # Rechercher la tâche dans le roadmap
            $taskRegex = "(\s*-\s*\[[ x]\]\s*\($escapedTaskId\)\s*)(.*?)(\r?\n)"
            $taskMatch = [regex]::Match($roadmapContent, $taskRegex)
            
            if ($taskMatch.Success) {
                $taskPrefix = $taskMatch.Groups[1].Value
                $taskDescription = $taskMatch.Groups[2].Value
                $taskSuffix = $taskMatch.Groups[3].Value
                
                # Vérifier si la tâche est déjà marquée comme complétée
                if ($taskPrefix -match "\[\s*x\s*\]") {
                    Write-Log "La tâche $($entryJson.id) est déjà marquée comme complétée dans le roadmap." -Level "INFO"
                    continue
                }
                
                # Mettre à jour la tâche
                $updatedTaskPrefix = $taskPrefix -replace "\[\s*\]", "[x]"
                $completionDate = if ($entryJson.metadata.completionDate) {
                    [DateTime]::Parse($entryJson.metadata.completionDate).ToString("yyyy-MM-dd")
                } else {
                    Get-Date -Format "yyyy-MM-dd"
                }
                $updatedTaskDescription = "$taskDescription - Implémenté le $completionDate"
                
                $updatedContent = $updatedContent -replace [regex]::Escape($taskMatch.Value), "$updatedTaskPrefix$updatedTaskDescription$taskSuffix"
                
                Write-Log "Tâche $($entryJson.id) marquée comme complétée dans le roadmap." -Level "SUCCESS"
            }
            else {
                Write-Log "Tâche $($entryJson.id) non trouvée dans le roadmap." -Level "WARNING"
            }
        }
    }
    
    # Enregistrer le roadmap mis à jour
    $updatedContent | Out-File -FilePath $RoadmapPath -Encoding utf8
    
    Write-Log "Roadmap mis à jour: $RoadmapPath" -Level "SUCCESS"
}

# Mettre à jour le journal avec les informations du roadmap
if ($UpdateJournal) {
    Write-Log "Mise à jour du journal avec les informations du roadmap..." -Level "INFO"
    
    # Rechercher toutes les tâches complétées dans le roadmap
    $taskRegex = "-\s*\[\s*x\s*\]\s*\(([^)]+)\)\s*(.*?)(?:\s*-\s*Implémenté le\s*(\d{4}-\d{2}-\d{2}))?"
    $taskMatches = [regex]::Matches($roadmapContent, $taskRegex)
    
    foreach ($taskMatch in $taskMatches) {
        $taskId = $taskMatch.Groups[1].Value
        $taskDescription = $taskMatch.Groups[2].Value.Trim()
        $completionDate = $taskMatch.Groups[3].Value
        
        # Vérifier si l'entrée existe déjà dans le journal
        if ($entries.PSObject.Properties.Name -contains $taskId) {
            $entryPath = $entries.$taskId
            
            # Vérifier si le fichier d'entrée existe
            if (Test-Path -Path $entryPath) {
                # Charger l'entrée
                $entryJson = Get-Content -Path $entryPath -Raw | ConvertFrom-Json
                
                # Vérifier si l'entrée est déjà complétée
                if ($entryJson.status -eq "Completed") {
                    Write-Log "L'entrée $taskId est déjà marquée comme complétée dans le journal." -Level "INFO"
                    continue
                }
                
                # Mettre à jour l'entrée
                $entryJson.status = "Completed"
                $entryJson.metadata.progress = 100
                if ($completionDate) {
                    $entryJson.metadata.completionDate = "$completionDate`T00:00:00.0000000"
                }
                else {
                    $entryJson.metadata.completionDate = (Get-Date -Format "yyyy-MM-dd") + "T00:00:00.0000000"
                }
                $entryJson.updatedAt = (Get-Date).ToString("o")
                
                # Enregistrer l'entrée mise à jour
                $entryJson | ConvertTo-Json -Depth 10 | Out-File -FilePath $entryPath -Encoding utf8
                
                Write-Log "Entrée $taskId mise à jour dans le journal." -Level "SUCCESS"
            }
            else {
                Write-Log "Le fichier d'entrée n'existe pas: $entryPath" -Level "WARNING"
            }
        }
        else {
            Write-Log "L'entrée $taskId n'existe pas dans le journal." -Level "WARNING"
            
            # Créer une nouvelle entrée
            $sectionMatch = [regex]::Match($taskId, "^(\d+)\.(\d+)")
            if ($sectionMatch.Success) {
                $sectionId = $sectionMatch.Groups[1].Value
                $subsectionId = $sectionMatch.Groups[2].Value
                
                $sectionPath = Join-Path -Path $JournalPath -ChildPath "sections"
                $sectionPath = Join-Path -Path $sectionPath -ChildPath "${sectionId}_section"
                
                # Créer le dossier de section s'il n'existe pas
                if (-not (Test-Path -Path $sectionPath)) {
                    New-Item -Path $sectionPath -ItemType Directory -Force | Out-Null
                }
                
                $entryPath = Join-Path -Path $sectionPath -ChildPath "$taskId.json"
                
                # Créer une nouvelle entrée
                $newEntry = @{
                    id = $taskId
                    title = $taskDescription
                    status = "Completed"
                    createdAt = (Get-Date).ToString("o")
                    updatedAt = (Get-Date).ToString("o")
                    metadata = @{
                        complexity = 3
                        estimatedHours = 24
                        progress = 100
                        completionDate = if ($completionDate) { "$completionDate`T00:00:00.0000000" } else { (Get-Date -Format "yyyy-MM-dd") + "T00:00:00.0000000" }
                        owner = "EMAIL_SENDER_1 Team"
                    }
                    description = $taskDescription
                    parentId = "$sectionId.$subsectionId"
                    files = @()
                    tags = @()
                }
                
                # Enregistrer la nouvelle entrée
                $newEntry | ConvertTo-Json -Depth 10 | Out-File -FilePath $entryPath -Encoding utf8
                
                # Mettre à jour l'index
                $entries | Add-Member -MemberType NoteProperty -Name $taskId -Value $entryPath
                $indexJson.entries = $entries
                $indexJson.statistics.totalEntries = $indexJson.statistics.totalEntries + 1
                $indexJson.statistics.completed = $indexJson.statistics.completed + 1
                $indexJson.lastUpdated = (Get-Date).ToString("o")
                
                $indexJson | ConvertTo-Json -Depth 10 | Out-File -FilePath $indexPath -Encoding utf8
                
                Write-Log "Nouvelle entrée $taskId créée dans le journal." -Level "SUCCESS"
            }
            else {
                Write-Log "Impossible de déterminer la section pour la tâche $taskId." -Level "ERROR"
            }
        }
    }
    
    Write-Log "Journal mis à jour." -Level "SUCCESS"
}

# Afficher un résumé
Write-Log "`nRésumé de la synchronisation:" -Level "INFO"
Write-Log "  Roadmap: $RoadmapPath" -Level "INFO"
Write-Log "  Journal: $JournalPath" -Level "INFO"
Write-Log "  Mise à jour du roadmap: $UpdateRoadmap" -Level "INFO"
Write-Log "  Mise à jour du journal: $UpdateJournal" -Level "INFO"
