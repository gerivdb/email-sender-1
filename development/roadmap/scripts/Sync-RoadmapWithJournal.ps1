#Requires -Version 5.1
<#
.SYNOPSIS
    Synchronise le fichier roadmap_complete.md avec le systÃ¨me de journalisation.
.DESCRIPTION
    Ce script synchronise le fichier roadmap_complete.md avec le systÃ¨me de journalisation,
    en mettant Ã  jour les statuts des tÃ¢ches dans le roadmap en fonction des entrÃ©es du journal.
.PARAMETER RoadmapPath
    Chemin du fichier roadmap.
.PARAMETER JournalPath
    Chemin du dossier journal.
.PARAMETER UpdateRoadmap
    Indique si le roadmap doit Ãªtre mis Ã  jour avec les informations du journal.
.PARAMETER UpdateJournal
    Indique si le journal doit Ãªtre mis Ã  jour avec les informations du roadmap.
.EXAMPLE
    .\Sync-RoadmapWithJournal.ps1 -RoadmapPath ".\roadmap_complete.md" -JournalPath ".\journal" -UpdateRoadmap
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-05-25
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

# VÃ©rifier si les chemins existent
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

# Mettre Ã  jour le roadmap avec les informations du journal
if ($UpdateRoadmap) {
    Write-Log "Mise Ã  jour du roadmap avec les informations du journal..." -Level "INFO"
    
    $updatedContent = $roadmapContent
    
    foreach ($entryKey in $entries.PSObject.Properties.Name) {
        $entryPath = $entries.$entryKey
        
        # VÃ©rifier si le fichier d'entrÃ©e existe
        if (-not (Test-Path -Path $entryPath)) {
            Write-Log "Le fichier d'entrÃ©e n'existe pas: $entryPath" -Level "WARNING"
            continue
        }
        
        # Charger l'entrÃ©e
        $entryJson = Get-Content -Path $entryPath -Raw | ConvertFrom-Json
        
        # VÃ©rifier si l'entrÃ©e est complÃ©tÃ©e
        if ($entryJson.status -eq "Completed") {
            # Ã‰chapper les caractÃ¨res spÃ©ciaux dans l'ID de tÃ¢che pour la regex
            $escapedTaskId = [regex]::Escape($entryJson.id)
            
            # Rechercher la tÃ¢che dans le roadmap
            $taskRegex = "(\s*-\s*\[[ x]\]\s*\($escapedTaskId\)\s*)(.*?)(\r?\n)"
            $taskMatch = [regex]::Match($roadmapContent, $taskRegex)
            
            if ($taskMatch.Success) {
                $taskPrefix = $taskMatch.Groups[1].Value
                $taskDescription = $taskMatch.Groups[2].Value
                $taskSuffix = $taskMatch.Groups[3].Value
                
                # VÃ©rifier si la tÃ¢che est dÃ©jÃ  marquÃ©e comme complÃ©tÃ©e
                if ($taskPrefix -match "\[\s*x\s*\]") {
                    Write-Log "La tÃ¢che $($entryJson.id) est dÃ©jÃ  marquÃ©e comme complÃ©tÃ©e dans le roadmap." -Level "INFO"
                    continue
                }
                
                # Mettre Ã  jour la tÃ¢che
                $updatedTaskPrefix = $taskPrefix -replace "\[\s*\]", "[x]"
                $completionDate = if ($entryJson.metadata.completionDate) {
                    [DateTime]::Parse($entryJson.metadata.completionDate).ToString("yyyy-MM-dd")
                } else {
                    Get-Date -Format "yyyy-MM-dd"
                }
                $updatedTaskDescription = "$taskDescription - ImplÃ©mentÃ© le $completionDate"
                
                $updatedContent = $updatedContent -replace [regex]::Escape($taskMatch.Value), "$updatedTaskPrefix$updatedTaskDescription$taskSuffix"
                
                Write-Log "TÃ¢che $($entryJson.id) marquÃ©e comme complÃ©tÃ©e dans le roadmap." -Level "SUCCESS"
            }
            else {
                Write-Log "TÃ¢che $($entryJson.id) non trouvÃ©e dans le roadmap." -Level "WARNING"
            }
        }
    }
    
    # Enregistrer le roadmap mis Ã  jour
    $updatedContent | Out-File -FilePath $RoadmapPath -Encoding utf8
    
    Write-Log "Roadmap mis Ã  jour: $RoadmapPath" -Level "SUCCESS"
}

# Mettre Ã  jour le journal avec les informations du roadmap
if ($UpdateJournal) {
    Write-Log "Mise Ã  jour du journal avec les informations du roadmap..." -Level "INFO"
    
    # Rechercher toutes les tÃ¢ches complÃ©tÃ©es dans le roadmap
    $taskRegex = "-\s*\[\s*x\s*\]\s*\(([^)]+)\)\s*(.*?)(?:\s*-\s*ImplÃ©mentÃ© le\s*(\d{4}-\d{2}-\d{2}))?"
    $taskMatches = [regex]::Matches($roadmapContent, $taskRegex)
    
    foreach ($taskMatch in $taskMatches) {
        $taskId = $taskMatch.Groups[1].Value
        $taskDescription = $taskMatch.Groups[2].Value.Trim()
        $completionDate = $taskMatch.Groups[3].Value
        
        # VÃ©rifier si l'entrÃ©e existe dÃ©jÃ  dans le journal
        if ($entries.PSObject.Properties.Name -contains $taskId) {
            $entryPath = $entries.$taskId
            
            # VÃ©rifier si le fichier d'entrÃ©e existe
            if (Test-Path -Path $entryPath) {
                # Charger l'entrÃ©e
                $entryJson = Get-Content -Path $entryPath -Raw | ConvertFrom-Json
                
                # VÃ©rifier si l'entrÃ©e est dÃ©jÃ  complÃ©tÃ©e
                if ($entryJson.status -eq "Completed") {
                    Write-Log "L'entrÃ©e $taskId est dÃ©jÃ  marquÃ©e comme complÃ©tÃ©e dans le journal." -Level "INFO"
                    continue
                }
                
                # Mettre Ã  jour l'entrÃ©e
                $entryJson.status = "Completed"
                $entryJson.metadata.progress = 100
                if ($completionDate) {
                    $entryJson.metadata.completionDate = "$completionDate`T00:00:00.0000000"
                }
                else {
                    $entryJson.metadata.completionDate = (Get-Date -Format "yyyy-MM-dd") + "T00:00:00.0000000"
                }
                $entryJson.updatedAt = (Get-Date).ToString("o")
                
                # Enregistrer l'entrÃ©e mise Ã  jour
                $entryJson | ConvertTo-Json -Depth 10 | Out-File -FilePath $entryPath -Encoding utf8
                
                Write-Log "EntrÃ©e $taskId mise Ã  jour dans le journal." -Level "SUCCESS"
            }
            else {
                Write-Log "Le fichier d'entrÃ©e n'existe pas: $entryPath" -Level "WARNING"
            }
        }
        else {
            Write-Log "L'entrÃ©e $taskId n'existe pas dans le journal." -Level "WARNING"
            
            # CrÃ©er une nouvelle entrÃ©e
            $sectionMatch = [regex]::Match($taskId, "^(\d+)\.(\d+)")
            if ($sectionMatch.Success) {
                $sectionId = $sectionMatch.Groups[1].Value
                $subsectionId = $sectionMatch.Groups[2].Value
                
                $sectionPath = Join-Path -Path $JournalPath -ChildPath "sections"
                $sectionPath = Join-Path -Path $sectionPath -ChildPath "${sectionId}_section"
                
                # CrÃ©er le dossier de section s'il n'existe pas
                if (-not (Test-Path -Path $sectionPath)) {
                    New-Item -Path $sectionPath -ItemType Directory -Force | Out-Null
                }
                
                $entryPath = Join-Path -Path $sectionPath -ChildPath "$taskId.json"
                
                # CrÃ©er une nouvelle entrÃ©e
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
                
                # Enregistrer la nouvelle entrÃ©e
                $newEntry | ConvertTo-Json -Depth 10 | Out-File -FilePath $entryPath -Encoding utf8
                
                # Mettre Ã  jour l'index
                $entries | Add-Member -MemberType NoteProperty -Name $taskId -Value $entryPath
                $indexJson.entries = $entries
                $indexJson.statistics.totalEntries = $indexJson.statistics.totalEntries + 1
                $indexJson.statistics.completed = $indexJson.statistics.completed + 1
                $indexJson.lastUpdated = (Get-Date).ToString("o")
                
                $indexJson | ConvertTo-Json -Depth 10 | Out-File -FilePath $indexPath -Encoding utf8
                
                Write-Log "Nouvelle entrÃ©e $taskId crÃ©Ã©e dans le journal." -Level "SUCCESS"
            }
            else {
                Write-Log "Impossible de dÃ©terminer la section pour la tÃ¢che $taskId." -Level "ERROR"
            }
        }
    }
    
    Write-Log "Journal mis Ã  jour." -Level "SUCCESS"
}

# Afficher un rÃ©sumÃ©
Write-Log "`nRÃ©sumÃ© de la synchronisation:" -Level "INFO"
Write-Log "  Roadmap: $RoadmapPath" -Level "INFO"
Write-Log "  Journal: $JournalPath" -Level "INFO"
Write-Log "  Mise Ã  jour du roadmap: $UpdateRoadmap" -Level "INFO"
Write-Log "  Mise Ã  jour du journal: $UpdateJournal" -Level "INFO"
