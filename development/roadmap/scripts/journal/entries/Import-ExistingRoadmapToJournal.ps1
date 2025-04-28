#Requires -Version 5.1
<#
.SYNOPSIS
    Importe la roadmap existante dans le systÃ¨me de journalisation.
.DESCRIPTION
    Ce script analyse le fichier Markdown de la roadmap et convertit les tÃ¢ches
    en entrÃ©es JSON pour le systÃ¨me de journalisation.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-16
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$RoadmapPath = "Roadmap\roadmap_final.md",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Importer le module de gestion du journal
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\RoadmapJournalManager.psm1"
Import-Module $modulePath -Force

# Fonction pour extraire les tÃ¢ches du fichier Markdown
function Get-TasksFromMarkdown {
    param (
        [Parameter(Mandatory=$true)]
        [string]$MarkdownContent
    )
    
    $tasks = @()
    $lines = $MarkdownContent -split "`n"
    $currentTask = $null
    $inTaskSection = $false
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # DÃ©tecter les en-tÃªtes de tÃ¢ches (### X.X.X)
        if ($line -match '^###\s+(\d+(\.\d+)*)\s+(.+)$') {
            $taskId = $matches[1]
            $taskTitle = $matches[3]
            
            # CrÃ©er une nouvelle tÃ¢che
            $currentTask = @{
                Id = $taskId
                Title = $taskTitle
                Description = ""
                Status = "NotStarted"
                Metadata = @{
                    complexity = 0
                    estimatedHours = 0
                    progress = 0
                }
                SubTasks = @()
                ParentId = $null
            }
            
            $inTaskSection = $true
            continue
        }
        
        # Si nous sommes dans une section de tÃ¢che, extraire les mÃ©tadonnÃ©es
        if ($inTaskSection -and $currentTask) {
            # ComplexitÃ©
            if ($line -match '\*\*ComplexitÃ©\*\*:\s+(.+)$') {
                $complexity = switch ($matches[1]) {
                    "Faible" { 1 }
                    "Moyenne" { 3 }
                    "Ã‰levÃ©e" { 5 }
                    default { 0 }
                }
                $currentTask.Metadata.complexity = $complexity
            }
            
            # Temps estimÃ©
            elseif ($line -match '\*\*Temps estimÃ©\*\*:\s+(.+)$') {
                $timeStr = $matches[1]
                $hours = 0
                
                if ($timeStr -match '(\d+)-(\d+)\s+jours') {
                    # Prendre la moyenne des jours
                    $minDays = [int]$matches[1]
                    $maxDays = [int]$matches[2]
                    $avgDays = ($minDays + $maxDays) / 2
                    $hours = $avgDays * 8  # 8 heures par jour
                }
                elseif ($timeStr -match '(\d+)\s+jours') {
                    $days = [int]$matches[1]
                    $hours = $days * 8
                }
                elseif ($timeStr -match '(\d+)-(\d+)\s+heures') {
                    $minHours = [int]$matches[1]
                    $maxHours = [int]$matches[2]
                    $hours = ($minHours + $maxHours) / 2
                }
                elseif ($timeStr -match '(\d+)\s+heures') {
                    $hours = [int]$matches[1]
                }
                elseif ($timeStr -match '(\d+)\s+semaines') {
                    $weeks = [int]$matches[1]
                    $hours = $weeks * 40  # 40 heures par semaine
                }
                
                $currentTask.Metadata.estimatedHours = $hours
            }
            
            # Progression
            elseif ($line -match '\*\*Progression\*\*:\s+(\d+)%\s+-\s+\*(.+)\*$') {
                $progress = [int]$matches[1]
                $status = $matches[2]
                
                $currentTask.Metadata.progress = $progress
                
                # DÃ©terminer le statut
                $currentTask.Status = switch ($status) {
                    "Ã€ commencer" { "NotStarted" }
                    "En cours" { "InProgress" }
                    "TerminÃ©" { "Completed" }
                    default { "NotStarted" }
                }
            }
            
            # Date de dÃ©but
            elseif ($line -match '\*\*Date de dÃ©but\*\*:\s+(.+)$' -and $matches[1] -ne "-") {
                try {
                    $startDate = [DateTime]::ParseExact($matches[1], "dd/MM/yyyy", $null)
                    $currentTask.Metadata.startDate = $startDate.ToString("o")
                }
                catch {
                    Write-Warning "Impossible de parser la date de dÃ©but: $($matches[1])"
                }
            }
            
            # Date d'achÃ¨vement prÃ©vue
            elseif ($line -match '\*\*Date d''achÃ¨vement prÃ©vue\*\*:\s+(.+)$' -and $matches[1] -ne "-") {
                try {
                    $dueDate = [DateTime]::ParseExact($matches[1], "dd/MM/yyyy", $null)
                    $currentTask.Metadata.dueDate = $dueDate.ToString("o")
                }
                catch {
                    Write-Warning "Impossible de parser la date d'achÃ¨vement prÃ©vue: $($matches[1])"
                }
            }
            
            # Date d'achÃ¨vement rÃ©elle
            elseif ($line -match '\*\*Date d''achÃ¨vement\*\*:\s+(.+)$' -and $matches[1] -ne "-") {
                try {
                    $completionDate = [DateTime]::ParseExact($matches[1], "dd/MM/yyyy", $null)
                    $currentTask.Metadata.completionDate = $completionDate.ToString("o")
                }
                catch {
                    Write-Warning "Impossible de parser la date d'achÃ¨vement: $($matches[1])"
                }
            }
            
            # Objectif (description)
            elseif ($line -match '\*\*Objectif\*\*:\s+(.+)$') {
                $currentTask.Description = $matches[1]
            }
            
            # Sous-tÃ¢ches (dÃ©tectÃ©es par les en-tÃªtes de niveau infÃ©rieur)
            elseif ($line -match '^####\s+\w+\.\s+(.+)$') {
                # Nous sommes dans une section de sous-tÃ¢ches, mais nous ne les traitons pas ici
                # car elles sont gÃ©nÃ©ralement des groupes et non des tÃ¢ches individuelles
            }
            
            # DÃ©tecter la fin de la section de tÃ¢che (un nouvel en-tÃªte de mÃªme niveau ou supÃ©rieur)
            elseif ($line -match '^#{1,3}\s+' -and $i -gt 0) {
                if ($currentTask) {
                    $tasks += $currentTask
                    $currentTask = $null
                    $inTaskSection = $false
                }
            }
        }
    }
    
    # Ajouter la derniÃ¨re tÃ¢che si elle existe
    if ($currentTask) {
        $tasks += $currentTask
    }
    
    # Ã‰tablir les relations parent-enfant
    foreach ($task in $tasks) {
        $taskIdParts = $task.Id -split '\.'
        
        if ($taskIdParts.Count -gt 1) {
            # Construire l'ID du parent en supprimant le dernier segment
            $parentIdParts = $taskIdParts[0..($taskIdParts.Count - 2)]
            $parentId = $parentIdParts -join '.'
            
            # VÃ©rifier si le parent existe
            $parent = $tasks | Where-Object { $_.Id -eq $parentId }
            
            if ($parent) {
                $task.ParentId = $parentId
                $parent.SubTasks += $task.Id
            }
        }
    }
    
    return $tasks
}

# VÃ©rifier si le fichier de roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier de roadmap '$RoadmapPath' n'existe pas."
    exit 1
}

# Lire le contenu du fichier de roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# Extraire les tÃ¢ches
$tasks = Get-TasksFromMarkdown -MarkdownContent $roadmapContent

# Afficher un rÃ©sumÃ© des tÃ¢ches trouvÃ©es
Write-Host "TÃ¢ches trouvÃ©es dans la roadmap: $($tasks.Count)"
Write-Host "Statuts: NotStarted=$($tasks | Where-Object { $_.Status -eq 'NotStarted' } | Measure-Object).Count, InProgress=$($tasks | Where-Object { $_.Status -eq 'InProgress' } | Measure-Object).Count, Completed=$($tasks | Where-Object { $_.Status -eq 'Completed' } | Measure-Object).Count"

# Demander confirmation avant d'importer
if (-not $Force) {
    $confirmation = Read-Host "Voulez-vous importer ces tÃ¢ches dans le systÃ¨me de journalisation? (O/N)"
    if ($confirmation -ne "O") {
        Write-Host "Importation annulÃ©e."
        exit 0
    }
}

# Importer les tÃ¢ches
$importedCount = 0
$errorCount = 0

foreach ($task in $tasks) {
    $result = New-RoadmapJournalEntry -Id $task.Id -Title $task.Title -Status $task.Status -Description $task.Description -Metadata $task.Metadata -SubTasks $task.SubTasks -ParentId $task.ParentId
    
    if ($result) {
        $importedCount++
    }
    else {
        $errorCount++
        Write-Warning "Ã‰chec de l'importation de la tÃ¢che $($task.Id): $($task.Title)"
    }
}

# Afficher le rÃ©sultat
Write-Host "Importation terminÃ©e: $importedCount tÃ¢ches importÃ©es, $errorCount erreurs."

# Mettre Ã  jour le statut global
Get-RoadmapJournalStatus | Out-Null

Write-Host "Le systÃ¨me de journalisation de la roadmap a Ã©tÃ© initialisÃ© avec succÃ¨s."
