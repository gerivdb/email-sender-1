#Requires -Version 5.1
<#
.SYNOPSIS
    Met Ã  jour le statut d'une tÃ¢che dans le journal de la roadmap.
.DESCRIPTION
    Ce script permet de mettre Ã  jour interactivement le statut d'une tÃ¢che
    dans le journal de la roadmap, ainsi que ses mÃ©tadonnÃ©es.
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

# Fonction pour afficher les tÃ¢ches disponibles
function Show-AvailableTasks {
    Write-Host "`nTÃ¢ches disponibles:" -ForegroundColor Cyan
    
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

# Fonction pour mettre Ã  jour une tÃ¢che de maniÃ¨re interactive
function Update-TaskInteractive {
    param (
        [Parameter(Mandatory=$true)]
        [string]$TaskId
    )
    
    # VÃ©rifier si la tÃ¢che existe
    if ($index.entries.PSObject.Properties.Name -notcontains $TaskId) {
        Write-Error "Aucune tÃ¢che avec l'ID '$TaskId' n'a Ã©tÃ© trouvÃ©e."
        return $false
    }
    
    # RÃ©cupÃ©rer la tÃ¢che
    $entryPath = $index.entries.$TaskId
    $entry = Get-Content -Path $entryPath -Raw | ConvertFrom-Json
    
    # Afficher les informations actuelles
    Write-Host "`nInformations actuelles de la tÃ¢che:" -ForegroundColor Cyan
    Write-Host "ID: $($entry.id)"
    Write-Host "Titre: $($entry.title)"
    Write-Host "Statut: $($entry.status)"
    Write-Host "Progression: $($entry.metadata.progress)%"
    Write-Host "ComplexitÃ©: $($entry.metadata.complexity)"
    Write-Host "Temps estimÃ©: $($entry.metadata.estimatedHours) heures"
    
    if ($entry.metadata.startDate) {
        Write-Host "Date de dÃ©but: $([DateTime]::Parse($entry.metadata.startDate).ToString("yyyy-MM-dd"))"
    }
    
    if ($entry.metadata.dueDate) {
        Write-Host "Date d'Ã©chÃ©ance: $([DateTime]::Parse($entry.metadata.dueDate).ToString("yyyy-MM-dd"))"
    }
    
    if ($entry.metadata.completionDate) {
        Write-Host "Date d'achÃ¨vement: $([DateTime]::Parse($entry.metadata.completionDate).ToString("yyyy-MM-dd"))"
    }
    
    if ($entry.description) {
        Write-Host "Description: $($entry.description)"
    }
    
    # Demander les nouvelles valeurs
    Write-Host "`nMise Ã  jour de la tÃ¢che:" -ForegroundColor Cyan
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
    $startDateStr = Read-Host "Date de dÃ©but (yyyy-MM-dd) [$(if ($entry.metadata.startDate) { [DateTime]::Parse($entry.metadata.startDate).ToString("yyyy-MM-dd") } else { "-" })]"
    if ($startDateStr -and $startDateStr -ne "-") {
        try {
            $newStartDate = [DateTime]::ParseExact($startDateStr, "yyyy-MM-dd", $null).ToString("o")
        }
        catch {
            Write-Warning "Format de date invalide. La date de dÃ©but ne sera pas mise Ã  jour."
        }
    }
    
    $newDueDate = $null
    $dueDateStr = Read-Host "Date d'Ã©chÃ©ance (yyyy-MM-dd) [$(if ($entry.metadata.dueDate) { [DateTime]::Parse($entry.metadata.dueDate).ToString("yyyy-MM-dd") } else { "-" })]"
    if ($dueDateStr -and $dueDateStr -ne "-") {
        try {
            $newDueDate = [DateTime]::ParseExact($dueDateStr, "yyyy-MM-dd", $null).ToString("o")
        }
        catch {
            Write-Warning "Format de date invalide. La date d'Ã©chÃ©ance ne sera pas mise Ã  jour."
        }
    }
    
    $newCompletionDate = $null
    if ($newStatus -eq "Completed") {
        $completionDateStr = Read-Host "Date d'achÃ¨vement (yyyy-MM-dd) [$(if ($entry.metadata.completionDate) { [DateTime]::Parse($entry.metadata.completionDate).ToString("yyyy-MM-dd") } else { "aujourd'hui" })]"
        if (-not $completionDateStr) {
            $newCompletionDate = (Get-Date).ToString("o")
        }
        elseif ($completionDateStr -ne "-") {
            try {
                $newCompletionDate = [DateTime]::ParseExact($completionDateStr, "yyyy-MM-dd", $null).ToString("o")
            }
            catch {
                Write-Warning "Format de date invalide. La date d'achÃ¨vement sera dÃ©finie Ã  aujourd'hui."
                $newCompletionDate = (Get-Date).ToString("o")
            }
        }
    }
    
    $newDescription = Read-Host "Description [$($entry.description)]"
    if (-not $newDescription) {
        $newDescription = $entry.description
    }
    
    # PrÃ©parer les mÃ©tadonnÃ©es Ã  mettre Ã  jour
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
    
    # Mettre Ã  jour la tÃ¢che
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
    
    # Effectuer la mise Ã  jour si des changements ont Ã©tÃ© demandÃ©s
    if ($updateParams.Count -gt 1) {
        $result = Update-RoadmapJournalEntry @updateParams
        
        if ($result) {
            Write-Host "TÃ¢che mise Ã  jour avec succÃ¨s." -ForegroundColor Green
            
            # Mettre Ã  jour le statut global
            Get-RoadmapJournalStatus | Out-Null
            
            # Synchroniser avec la roadmap
            $syncScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Sync-RoadmapWithJournal.ps1"
            & $syncScriptPath -Direction "ToRoadmap"
            
            return $true
        }
        else {
            Write-Error "Ã‰chec de la mise Ã  jour de la tÃ¢che."
            return $false
        }
    }
    else {
        Write-Host "Aucun changement demandÃ©. La tÃ¢che n'a pas Ã©tÃ© mise Ã  jour." -ForegroundColor Yellow
        return $true
    }
}

# ExÃ©cution principale
if ($Interactive) {
    # Mode interactif
    Show-AvailableTasks
    
    if (-not $Id) {
        $Id = Read-Host "Entrez l'ID de la tÃ¢che Ã  mettre Ã  jour"
    }
    
    Update-TaskInteractive -TaskId $Id
}
else {
    # Mode non interactif
    if (-not $Id) {
        Write-Error "L'ID de la tÃ¢che est requis en mode non interactif."
        exit 1
    }
    
    # VÃ©rifier si la tÃ¢che existe
    if ($index.entries.PSObject.Properties.Name -notcontains $Id) {
        Write-Error "Aucune tÃ¢che avec l'ID '$Id' n'a Ã©tÃ© trouvÃ©e."
        exit 1
    }
    
    # PrÃ©parer les paramÃ¨tres de mise Ã  jour
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
        
        # Si la tÃ¢che est marquÃ©e comme terminÃ©e, dÃ©finir la date d'achÃ¨vement
        if ($Status -eq "Completed") {
            $updateParams.Metadata.completionDate = (Get-Date).ToString("o")
        }
    }
    
    # Effectuer la mise Ã  jour
    $result = Update-RoadmapJournalEntry @updateParams
    
    if ($result) {
        Write-Host "TÃ¢che mise Ã  jour avec succÃ¨s." -ForegroundColor Green
        
        # Mettre Ã  jour le statut global
        Get-RoadmapJournalStatus | Out-Null
        
        # Synchroniser avec la roadmap
        $syncScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Sync-RoadmapWithJournal.ps1"
        & $syncScriptPath -Direction "ToRoadmap"
    }
    else {
        Write-Error "Ã‰chec de la mise Ã  jour de la tÃ¢che."
        exit 1
    }
}
