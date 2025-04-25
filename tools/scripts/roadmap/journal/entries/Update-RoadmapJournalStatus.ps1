#Requires -Version 5.1
<#
.SYNOPSIS
    Met à jour le statut d'une tâche dans le journal de la roadmap.
.DESCRIPTION
    Ce script permet de mettre à jour interactivement le statut d'une tâche
    dans le journal de la roadmap, ainsi que ses métadonnées.
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
    [ValidateSet("NotStarted", "InProgress", "Completed", "Blocked")]
    [string]$Status,
    
    [Parameter(Mandatory=$false)]
    [int]$Progress,
    
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

# Fonction pour afficher les tâches disponibles
function Show-AvailableTasks {
    Write-Host "`nTâches disponibles:" -ForegroundColor Cyan
    
    $tasks = @()
    foreach ($entryId in $index.entries.PSObject.Properties.Name | Sort-Object) {
        $entryPath = $index.entries.$entryId
        $entry = Get-Content -Path $entryPath -Raw | ConvertFrom-Json
        
        $tasks += [PSCustomObject]@{
            Id = $entry.id
            Title = $entry.title
            Status = $entry.status
            Progress = $entry.metadata.progress
        }
    }
    
    $tasks | Format-Table -AutoSize
}

# Fonction pour mettre à jour une tâche de manière interactive
function Update-TaskInteractive {
    param (
        [Parameter(Mandatory=$true)]
        [string]$TaskId
    )
    
    # Vérifier si la tâche existe
    if ($index.entries.PSObject.Properties.Name -notcontains $TaskId) {
        Write-Error "Aucune tâche avec l'ID '$TaskId' n'a été trouvée."
        return $false
    }
    
    # Récupérer la tâche
    $entryPath = $index.entries.$TaskId
    $entry = Get-Content -Path $entryPath -Raw | ConvertFrom-Json
    
    # Afficher les informations actuelles
    Write-Host "`nInformations actuelles de la tâche:" -ForegroundColor Cyan
    Write-Host "ID: $($entry.id)"
    Write-Host "Titre: $($entry.title)"
    Write-Host "Statut: $($entry.status)"
    Write-Host "Progression: $($entry.metadata.progress)%"
    Write-Host "Complexité: $($entry.metadata.complexity)"
    Write-Host "Temps estimé: $($entry.metadata.estimatedHours) heures"
    
    if ($entry.metadata.startDate) {
        Write-Host "Date de début: $([DateTime]::Parse($entry.metadata.startDate).ToString("yyyy-MM-dd"))"
    }
    
    if ($entry.metadata.dueDate) {
        Write-Host "Date d'échéance: $([DateTime]::Parse($entry.metadata.dueDate).ToString("yyyy-MM-dd"))"
    }
    
    if ($entry.metadata.completionDate) {
        Write-Host "Date d'achèvement: $([DateTime]::Parse($entry.metadata.completionDate).ToString("yyyy-MM-dd"))"
    }
    
    if ($entry.description) {
        Write-Host "Description: $($entry.description)"
    }
    
    # Demander les nouvelles valeurs
    Write-Host "`nMise à jour de la tâche:" -ForegroundColor Cyan
    Write-Host "Laissez vide pour conserver la valeur actuelle."
    
    $newStatus = Read-Host "Nouveau statut (NotStarted, InProgress, Completed, Blocked) [$($entry.status)]"
    if (-not $newStatus) {
        $newStatus = $entry.status
    }
    
    $newProgress = Read-Host "Nouvelle progression (0-100) [$($entry.metadata.progress)]"
    if (-not $newProgress) {
        $newProgress = $entry.metadata.progress
    }
    else {
        $newProgress = [int]$newProgress
    }
    
    $newStartDate = $null
    $startDateStr = Read-Host "Date de début (yyyy-MM-dd) [$(if ($entry.metadata.startDate) { [DateTime]::Parse($entry.metadata.startDate).ToString("yyyy-MM-dd") } else { "-" })]"
    if ($startDateStr -and $startDateStr -ne "-") {
        try {
            $newStartDate = [DateTime]::ParseExact($startDateStr, "yyyy-MM-dd", $null).ToString("o")
        }
        catch {
            Write-Warning "Format de date invalide. La date de début ne sera pas mise à jour."
        }
    }
    
    $newDueDate = $null
    $dueDateStr = Read-Host "Date d'échéance (yyyy-MM-dd) [$(if ($entry.metadata.dueDate) { [DateTime]::Parse($entry.metadata.dueDate).ToString("yyyy-MM-dd") } else { "-" })]"
    if ($dueDateStr -and $dueDateStr -ne "-") {
        try {
            $newDueDate = [DateTime]::ParseExact($dueDateStr, "yyyy-MM-dd", $null).ToString("o")
        }
        catch {
            Write-Warning "Format de date invalide. La date d'échéance ne sera pas mise à jour."
        }
    }
    
    $newCompletionDate = $null
    if ($newStatus -eq "Completed") {
        $completionDateStr = Read-Host "Date d'achèvement (yyyy-MM-dd) [$(if ($entry.metadata.completionDate) { [DateTime]::Parse($entry.metadata.completionDate).ToString("yyyy-MM-dd") } else { "aujourd'hui" })]"
        if (-not $completionDateStr) {
            $newCompletionDate = (Get-Date).ToString("o")
        }
        elseif ($completionDateStr -ne "-") {
            try {
                $newCompletionDate = [DateTime]::ParseExact($completionDateStr, "yyyy-MM-dd", $null).ToString("o")
            }
            catch {
                Write-Warning "Format de date invalide. La date d'achèvement sera définie à aujourd'hui."
                $newCompletionDate = (Get-Date).ToString("o")
            }
        }
    }
    
    $newDescription = Read-Host "Description [$($entry.description)]"
    if (-not $newDescription) {
        $newDescription = $entry.description
    }
    
    # Préparer les métadonnées à mettre à jour
    $metadata = @{}
    
    if ($newProgress -ne $entry.metadata.progress) {
        $metadata.progress = $newProgress
    }
    
    if ($newStartDate) {
        $metadata.startDate = $newStartDate
    }
    
    if ($newDueDate) {
        $metadata.dueDate = $newDueDate
    }
    
    if ($newCompletionDate) {
        $metadata.completionDate = $newCompletionDate
    }
    
    # Mettre à jour la tâche
    $updateParams = @{
        Id = $TaskId
    }
    
    if ($newStatus -ne $entry.status) {
        $updateParams.Status = $newStatus
    }
    
    if ($newDescription -ne $entry.description) {
        $updateParams.Description = $newDescription
    }
    
    if ($metadata.Count -gt 0) {
        $updateParams.Metadata = $metadata
    }
    
    # Effectuer la mise à jour si des changements ont été demandés
    if ($updateParams.Count -gt 1) {
        $result = Update-RoadmapJournalEntry @updateParams
        
        if ($result) {
            Write-Host "Tâche mise à jour avec succès." -ForegroundColor Green
            
            # Mettre à jour le statut global
            Get-RoadmapJournalStatus | Out-Null
            
            # Synchroniser avec la roadmap
            $syncScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Sync-RoadmapWithJournal.ps1"
            & $syncScriptPath -Direction "ToRoadmap"
            
            return $true
        }
        else {
            Write-Error "Échec de la mise à jour de la tâche."
            return $false
        }
    }
    else {
        Write-Host "Aucun changement demandé. La tâche n'a pas été mise à jour." -ForegroundColor Yellow
        return $true
    }
}

# Exécution principale
if ($Interactive) {
    # Mode interactif
    Show-AvailableTasks
    
    if (-not $Id) {
        $Id = Read-Host "Entrez l'ID de la tâche à mettre à jour"
    }
    
    Update-TaskInteractive -TaskId $Id
}
else {
    # Mode non interactif
    if (-not $Id) {
        Write-Error "L'ID de la tâche est requis en mode non interactif."
        exit 1
    }
    
    # Vérifier si la tâche existe
    if ($index.entries.PSObject.Properties.Name -notcontains $Id) {
        Write-Error "Aucune tâche avec l'ID '$Id' n'a été trouvée."
        exit 1
    }
    
    # Préparer les paramètres de mise à jour
    $updateParams = @{
        Id = $Id
    }
    
    if ($PSBoundParameters.ContainsKey('Status')) {
        $updateParams.Status = $Status
    }
    
    if ($PSBoundParameters.ContainsKey('Progress')) {
        $updateParams.Metadata = @{
            progress = $Progress
        }
        
        # Si la tâche est marquée comme terminée, définir la date d'achèvement
        if ($Status -eq "Completed") {
            $updateParams.Metadata.completionDate = (Get-Date).ToString("o")
        }
    }
    
    # Effectuer la mise à jour
    $result = Update-RoadmapJournalEntry @updateParams
    
    if ($result) {
        Write-Host "Tâche mise à jour avec succès." -ForegroundColor Green
        
        # Mettre à jour le statut global
        Get-RoadmapJournalStatus | Out-Null
        
        # Synchroniser avec la roadmap
        $syncScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Sync-RoadmapWithJournal.ps1"
        & $syncScriptPath -Direction "ToRoadmap"
    }
    else {
        Write-Error "Échec de la mise à jour de la tâche."
        exit 1
    }
}
