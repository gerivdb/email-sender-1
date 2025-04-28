#Requires -Version 5.1
<#
.SYNOPSIS
    Ajoute une nouvelle tÃ¢che au journal de la roadmap.
.DESCRIPTION
    Ce script permet d'ajouter interactivement une nouvelle tÃ¢che
    au journal de la roadmap et de la synchroniser avec le fichier Markdown.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-16
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$Id,
    
    [Parameter(Mandatory=$false)]
    [string]$Title,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("NotStarted", "InProgress", "Completed", "Blocked")]
    [string]$Status = "NotStarted",
    
    [Parameter(Mandatory=$false)]
    [string]$Description,
    
    [Parameter(Mandatory=$false)]
    [int]$Complexity,
    
    [Parameter(Mandatory=$false)]
    [double]$EstimatedHours,
    
    [Parameter(Mandatory=$false)]
    [int]$Progress = 0,
    
    [Parameter(Mandatory=$false)]
    [string]$ParentId,
    
    [Parameter(Mandatory=$false)]
    [switch]$Interactive
)

# Importer le module de gestion du journal
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\RoadmapJournalManager.psm1"
Import-Module $modulePath -Force

# Chemins des fichiers et dossiers
$journalRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Roadmap\journal"
$indexPath = Join-Path -Path $journalRoot -ChildPath "index.json"

# Charger l'index
$index = Get-Content -Path $indexPath -Raw | ConvertFrom-Json

# Fonction pour afficher les tÃ¢ches existantes
function Show-ExistingTasks {
    Write-Host "`nTÃ¢ches existantes:" -ForegroundColor Cyan
    
    $tasks = @()
    foreach ($entryId in $index.entries.PSObject.Properties.Name | Sort-Object) {
        $entryPath = $index.entries.$entryId
        $entry = Get-Content -Path $entryPath -Raw | ConvertFrom-Json
        
        $tasks += [PSCustomObject]@{
            Id = $entry.id
            Title = $entry.title
            Status = $entry.status
        }
    }
    
    $tasks | Format-Table -AutoSize
}

# Fonction pour suggÃ©rer un nouvel ID
function Get-NextAvailableId {
    param (
        [Parameter(Mandatory=$false)]
        [string]$ParentId
    )
    
    if ($ParentId) {
        # Trouver le prochain ID disponible sous le parent
        $childIds = @()
        foreach ($entryId in $index.entries.PSObject.Properties.Name) {
            if ($entryId -match "^$([regex]::Escape($ParentId))\.(\d+)$") {
                $childIds += [int]$matches[1]
            }
        }
        
        if ($childIds.Count -eq 0) {
            return "$ParentId.1"
        }
        else {
            $nextChildId = ($childIds | Measure-Object -Maximum).Maximum + 1
            return "$ParentId.$nextChildId"
        }
    }
    else {
        # Trouver le prochain ID de premier niveau disponible
        $topLevelIds = @()
        foreach ($entryId in $index.entries.PSObject.Properties.Name) {
            if ($entryId -match "^(\d+)(\.|$)") {
                $topLevelIds += [int]$matches[1]
            }
        }
        
        if ($topLevelIds.Count -eq 0) {
            return "1"
        }
        else {
            $nextTopLevelId = ($topLevelIds | Measure-Object -Maximum).Maximum + 1
            return "$nextTopLevelId"
        }
    }
}

# Fonction pour ajouter une tÃ¢che de maniÃ¨re interactive
function Add-TaskInteractive {
    # Afficher les tÃ¢ches existantes
    Show-ExistingTasks
    
    # Demander les informations de la nouvelle tÃ¢che
    Write-Host "`nAjout d'une nouvelle tÃ¢che:" -ForegroundColor Cyan
    
    # Demander l'ID parent (optionnel)
    $parentId = Read-Host "ID parent (laissez vide pour une tÃ¢che de premier niveau)"
    
    # SuggÃ©rer un ID
    $suggestedId = Get-NextAvailableId -ParentId $parentId
    $taskId = Read-Host "ID de la tÃ¢che [$suggestedId]"
    if (-not $taskId) {
        $taskId = $suggestedId
    }
    
    # VÃ©rifier si l'ID existe dÃ©jÃ 
    if ($index.entries.PSObject.Properties.Name -contains $taskId) {
        Write-Error "Une tÃ¢che avec l'ID '$taskId' existe dÃ©jÃ ."
        return $false
    }
    
    # Demander les autres informations
    $taskTitle = Read-Host "Titre de la tÃ¢che"
    if (-not $taskTitle) {
        Write-Error "Le titre de la tÃ¢che est obligatoire."
        return $false
    }
    
    $taskStatus = Read-Host "Statut (NotStarted, InProgress, Completed, Blocked) [NotStarted]"
    if (-not $taskStatus) {
        $taskStatus = "NotStarted"
    }
    
    $taskDescription = Read-Host "Description"
    
    $complexityStr = Read-Host "ComplexitÃ© (1-5) [3]"
    $taskComplexity = if ($complexityStr) { [int]$complexityStr } else { 3 }
    
    $estimatedHoursStr = Read-Host "Temps estimÃ© (heures) [8]"
    $taskEstimatedHours = if ($estimatedHoursStr) { [double]$estimatedHoursStr } else { 8 }
    
    $progressStr = Read-Host "Progression (0-100) [0]"
    $taskProgress = if ($progressStr) { [int]$progressStr } else { 0 }
    
    $startDateStr = Read-Host "Date de dÃ©but (yyyy-MM-dd) [aujourd'hui]"
    $taskStartDate = if ($startDateStr) {
        try {
            [DateTime]::ParseExact($startDateStr, "yyyy-MM-dd", $null).ToString("o")
        }
        catch {
            Write-Warning "Format de date invalide. La date de dÃ©but sera dÃ©finie Ã  aujourd'hui."
            (Get-Date).ToString("o")
        }
    }
    else {
        (Get-Date).ToString("o")
    }
    
    $dueDateStr = Read-Host "Date d'Ã©chÃ©ance (yyyy-MM-dd) [dans 30 jours]"
    $taskDueDate = if ($dueDateStr) {
        try {
            [DateTime]::ParseExact($dueDateStr, "yyyy-MM-dd", $null).ToString("o")
        }
        catch {
            Write-Warning "Format de date invalide. La date d'Ã©chÃ©ance sera dÃ©finie Ã  dans 30 jours."
            (Get-Date).AddDays(30).ToString("o")
        }
    }
    else {
        (Get-Date).AddDays(30).ToString("o")
    }
    
    $ownerStr = Read-Host "Responsable"
    
    # PrÃ©parer les mÃ©tadonnÃ©es
    $metadata = @{
        complexity = $taskComplexity
        estimatedHours = $taskEstimatedHours
        progress = $taskProgress
        startDate = $taskStartDate
        dueDate = $taskDueDate
    }
    
    if ($ownerStr) {
        $metadata.owner = $ownerStr
    }
    
    # Ajouter la tÃ¢che
    $result = New-RoadmapJournalEntry -Id $taskId -Title $taskTitle -Status $taskStatus -Description $taskDescription -Metadata $metadata -ParentId $parentId
    
    if ($result) {
        Write-Host "TÃ¢che ajoutÃ©e avec succÃ¨s." -ForegroundColor Green
        
        # Mettre Ã  jour le statut global
        Get-RoadmapJournalStatus | Out-Null
        
        # Synchroniser avec la roadmap
        $syncScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Sync-RoadmapWithJournal.ps1"
        & $syncScriptPath -Direction "ToRoadmap"
        
        return $true
    }
    else {
        Write-Error "Ã‰chec de l'ajout de la tÃ¢che."
        return $false
    }
}

# ExÃ©cution principale
if ($Interactive) {
    # Mode interactif
    Add-TaskInteractive
}
else {
    # Mode non interactif
    if (-not $Id) {
        Write-Error "L'ID de la tÃ¢che est requis en mode non interactif."
        exit 1
    }
    
    if (-not $Title) {
        Write-Error "Le titre de la tÃ¢che est requis en mode non interactif."
        exit 1
    }
    
    # VÃ©rifier si l'ID existe dÃ©jÃ 
    if ($index.entries.PSObject.Properties.Name -contains $Id) {
        Write-Error "Une tÃ¢che avec l'ID '$Id' existe dÃ©jÃ ."
        exit 1
    }
    
    # PrÃ©parer les mÃ©tadonnÃ©es
    $metadata = @{
        progress = $Progress
    }
    
    if ($PSBoundParameters.ContainsKey('Complexity')) {
        $metadata.complexity = $Complexity
    }
    
    if ($PSBoundParameters.ContainsKey('EstimatedHours')) {
        $metadata.estimatedHours = $EstimatedHours
    }
    
    # Ajouter la tÃ¢che
    $result = New-RoadmapJournalEntry -Id $Id -Title $Title -Status $Status -Description $Description -Metadata $metadata -ParentId $ParentId
    
    if ($result) {
        Write-Host "TÃ¢che ajoutÃ©e avec succÃ¨s." -ForegroundColor Green
        
        # Mettre Ã  jour le statut global
        Get-RoadmapJournalStatus | Out-Null
        
        # Synchroniser avec la roadmap
        $syncScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Sync-RoadmapWithJournal.ps1"
        & $syncScriptPath -Direction "ToRoadmap"
    }
    else {
        Write-Error "Ã‰chec de l'ajout de la tÃ¢che."
        exit 1
    }
}
