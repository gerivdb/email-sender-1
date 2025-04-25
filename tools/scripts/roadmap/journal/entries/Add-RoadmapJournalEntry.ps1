#Requires -Version 5.1
<#
.SYNOPSIS
    Ajoute une nouvelle tâche au journal de la roadmap.
.DESCRIPTION
    Ce script permet d'ajouter interactivement une nouvelle tâche
    au journal de la roadmap et de la synchroniser avec le fichier Markdown.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-16
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

# Fonction pour afficher les tâches existantes
function Show-ExistingTasks {
    Write-Host "`nTâches existantes:" -ForegroundColor Cyan
    
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

# Fonction pour suggérer un nouvel ID
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

# Fonction pour ajouter une tâche de manière interactive
function Add-TaskInteractive {
    # Afficher les tâches existantes
    Show-ExistingTasks
    
    # Demander les informations de la nouvelle tâche
    Write-Host "`nAjout d'une nouvelle tâche:" -ForegroundColor Cyan
    
    # Demander l'ID parent (optionnel)
    $parentId = Read-Host "ID parent (laissez vide pour une tâche de premier niveau)"
    
    # Suggérer un ID
    $suggestedId = Get-NextAvailableId -ParentId $parentId
    $taskId = Read-Host "ID de la tâche [$suggestedId]"
    if (-not $taskId) {
        $taskId = $suggestedId
    }
    
    # Vérifier si l'ID existe déjà
    if ($index.entries.PSObject.Properties.Name -contains $taskId) {
        Write-Error "Une tâche avec l'ID '$taskId' existe déjà."
        return $false
    }
    
    # Demander les autres informations
    $taskTitle = Read-Host "Titre de la tâche"
    if (-not $taskTitle) {
        Write-Error "Le titre de la tâche est obligatoire."
        return $false
    }
    
    $taskStatus = Read-Host "Statut (NotStarted, InProgress, Completed, Blocked) [NotStarted]"
    if (-not $taskStatus) {
        $taskStatus = "NotStarted"
    }
    
    $taskDescription = Read-Host "Description"
    
    $complexityStr = Read-Host "Complexité (1-5) [3]"
    $taskComplexity = if ($complexityStr) { [int]$complexityStr } else { 3 }
    
    $estimatedHoursStr = Read-Host "Temps estimé (heures) [8]"
    $taskEstimatedHours = if ($estimatedHoursStr) { [double]$estimatedHoursStr } else { 8 }
    
    $progressStr = Read-Host "Progression (0-100) [0]"
    $taskProgress = if ($progressStr) { [int]$progressStr } else { 0 }
    
    $startDateStr = Read-Host "Date de début (yyyy-MM-dd) [aujourd'hui]"
    $taskStartDate = if ($startDateStr) {
        try {
            [DateTime]::ParseExact($startDateStr, "yyyy-MM-dd", $null).ToString("o")
        }
        catch {
            Write-Warning "Format de date invalide. La date de début sera définie à aujourd'hui."
            (Get-Date).ToString("o")
        }
    }
    else {
        (Get-Date).ToString("o")
    }
    
    $dueDateStr = Read-Host "Date d'échéance (yyyy-MM-dd) [dans 30 jours]"
    $taskDueDate = if ($dueDateStr) {
        try {
            [DateTime]::ParseExact($dueDateStr, "yyyy-MM-dd", $null).ToString("o")
        }
        catch {
            Write-Warning "Format de date invalide. La date d'échéance sera définie à dans 30 jours."
            (Get-Date).AddDays(30).ToString("o")
        }
    }
    else {
        (Get-Date).AddDays(30).ToString("o")
    }
    
    $ownerStr = Read-Host "Responsable"
    
    # Préparer les métadonnées
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
    
    # Ajouter la tâche
    $result = New-RoadmapJournalEntry -Id $taskId -Title $taskTitle -Status $taskStatus -Description $taskDescription -Metadata $metadata -ParentId $parentId
    
    if ($result) {
        Write-Host "Tâche ajoutée avec succès." -ForegroundColor Green
        
        # Mettre à jour le statut global
        Get-RoadmapJournalStatus | Out-Null
        
        # Synchroniser avec la roadmap
        $syncScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Sync-RoadmapWithJournal.ps1"
        & $syncScriptPath -Direction "ToRoadmap"
        
        return $true
    }
    else {
        Write-Error "Échec de l'ajout de la tâche."
        return $false
    }
}

# Exécution principale
if ($Interactive) {
    # Mode interactif
    Add-TaskInteractive
}
else {
    # Mode non interactif
    if (-not $Id) {
        Write-Error "L'ID de la tâche est requis en mode non interactif."
        exit 1
    }
    
    if (-not $Title) {
        Write-Error "Le titre de la tâche est requis en mode non interactif."
        exit 1
    }
    
    # Vérifier si l'ID existe déjà
    if ($index.entries.PSObject.Properties.Name -contains $Id) {
        Write-Error "Une tâche avec l'ID '$Id' existe déjà."
        exit 1
    }
    
    # Préparer les métadonnées
    $metadata = @{
        progress = $Progress
    }
    
    if ($PSBoundParameters.ContainsKey('Complexity')) {
        $metadata.complexity = $Complexity
    }
    
    if ($PSBoundParameters.ContainsKey('EstimatedHours')) {
        $metadata.estimatedHours = $EstimatedHours
    }
    
    # Ajouter la tâche
    $result = New-RoadmapJournalEntry -Id $Id -Title $Title -Status $Status -Description $Description -Metadata $metadata -ParentId $ParentId
    
    if ($result) {
        Write-Host "Tâche ajoutée avec succès." -ForegroundColor Green
        
        # Mettre à jour le statut global
        Get-RoadmapJournalStatus | Out-Null
        
        # Synchroniser avec la roadmap
        $syncScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Sync-RoadmapWithJournal.ps1"
        & $syncScriptPath -Direction "ToRoadmap"
    }
    else {
        Write-Error "Échec de l'ajout de la tâche."
        exit 1
    }
}
