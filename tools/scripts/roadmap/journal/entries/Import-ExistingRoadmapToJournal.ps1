#Requires -Version 5.1
<#
.SYNOPSIS
    Importe la roadmap existante dans le système de journalisation.
.DESCRIPTION
    Ce script analyse le fichier Markdown de la roadmap et convertit les tâches
    en entrées JSON pour le système de journalisation.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-16
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

# Fonction pour extraire les tâches du fichier Markdown
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
        
        # Détecter les en-têtes de tâches (### X.X.X)
        if ($line -match '^###\s+(\d+(\.\d+)*)\s+(.+)$') {
            $taskId = $matches[1]
            $taskTitle = $matches[3]
            
            # Créer une nouvelle tâche
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
        
        # Si nous sommes dans une section de tâche, extraire les métadonnées
        if ($inTaskSection -and $currentTask) {
            # Complexité
            if ($line -match '\*\*Complexité\*\*:\s+(.+)$') {
                $complexity = switch ($matches[1]) {
                    "Faible" { 1 }
                    "Moyenne" { 3 }
                    "Élevée" { 5 }
                    default { 0 }
                }
                $currentTask.Metadata.complexity = $complexity
            }
            
            # Temps estimé
            elseif ($line -match '\*\*Temps estimé\*\*:\s+(.+)$') {
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
                
                # Déterminer le statut
                $currentTask.Status = switch ($status) {
                    "À commencer" { "NotStarted" }
                    "En cours" { "InProgress" }
                    "Terminé" { "Completed" }
                    default { "NotStarted" }
                }
            }
            
            # Date de début
            elseif ($line -match '\*\*Date de début\*\*:\s+(.+)$' -and $matches[1] -ne "-") {
                try {
                    $startDate = [DateTime]::ParseExact($matches[1], "dd/MM/yyyy", $null)
                    $currentTask.Metadata.startDate = $startDate.ToString("o")
                }
                catch {
                    Write-Warning "Impossible de parser la date de début: $($matches[1])"
                }
            }
            
            # Date d'achèvement prévue
            elseif ($line -match '\*\*Date d''achèvement prévue\*\*:\s+(.+)$' -and $matches[1] -ne "-") {
                try {
                    $dueDate = [DateTime]::ParseExact($matches[1], "dd/MM/yyyy", $null)
                    $currentTask.Metadata.dueDate = $dueDate.ToString("o")
                }
                catch {
                    Write-Warning "Impossible de parser la date d'achèvement prévue: $($matches[1])"
                }
            }
            
            # Date d'achèvement réelle
            elseif ($line -match '\*\*Date d''achèvement\*\*:\s+(.+)$' -and $matches[1] -ne "-") {
                try {
                    $completionDate = [DateTime]::ParseExact($matches[1], "dd/MM/yyyy", $null)
                    $currentTask.Metadata.completionDate = $completionDate.ToString("o")
                }
                catch {
                    Write-Warning "Impossible de parser la date d'achèvement: $($matches[1])"
                }
            }
            
            # Objectif (description)
            elseif ($line -match '\*\*Objectif\*\*:\s+(.+)$') {
                $currentTask.Description = $matches[1]
            }
            
            # Sous-tâches (détectées par les en-têtes de niveau inférieur)
            elseif ($line -match '^####\s+\w+\.\s+(.+)$') {
                # Nous sommes dans une section de sous-tâches, mais nous ne les traitons pas ici
                # car elles sont généralement des groupes et non des tâches individuelles
            }
            
            # Détecter la fin de la section de tâche (un nouvel en-tête de même niveau ou supérieur)
            elseif ($line -match '^#{1,3}\s+' -and $i -gt 0) {
                if ($currentTask) {
                    $tasks += $currentTask
                    $currentTask = $null
                    $inTaskSection = $false
                }
            }
        }
    }
    
    # Ajouter la dernière tâche si elle existe
    if ($currentTask) {
        $tasks += $currentTask
    }
    
    # Établir les relations parent-enfant
    foreach ($task in $tasks) {
        $taskIdParts = $task.Id -split '\.'
        
        if ($taskIdParts.Count -gt 1) {
            # Construire l'ID du parent en supprimant le dernier segment
            $parentIdParts = $taskIdParts[0..($taskIdParts.Count - 2)]
            $parentId = $parentIdParts -join '.'
            
            # Vérifier si le parent existe
            $parent = $tasks | Where-Object { $_.Id -eq $parentId }
            
            if ($parent) {
                $task.ParentId = $parentId
                $parent.SubTasks += $task.Id
            }
        }
    }
    
    return $tasks
}

# Vérifier si le fichier de roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier de roadmap '$RoadmapPath' n'existe pas."
    exit 1
}

# Lire le contenu du fichier de roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# Extraire les tâches
$tasks = Get-TasksFromMarkdown -MarkdownContent $roadmapContent

# Afficher un résumé des tâches trouvées
Write-Host "Tâches trouvées dans la roadmap: $($tasks.Count)"
Write-Host "Statuts: NotStarted=$($tasks | Where-Object { $_.Status -eq 'NotStarted' } | Measure-Object).Count, InProgress=$($tasks | Where-Object { $_.Status -eq 'InProgress' } | Measure-Object).Count, Completed=$($tasks | Where-Object { $_.Status -eq 'Completed' } | Measure-Object).Count"

# Demander confirmation avant d'importer
if (-not $Force) {
    $confirmation = Read-Host "Voulez-vous importer ces tâches dans le système de journalisation? (O/N)"
    if ($confirmation -ne "O") {
        Write-Host "Importation annulée."
        exit 0
    }
}

# Importer les tâches
$importedCount = 0
$errorCount = 0

foreach ($task in $tasks) {
    $result = New-RoadmapJournalEntry -Id $task.Id -Title $task.Title -Status $task.Status -Description $task.Description -Metadata $task.Metadata -SubTasks $task.SubTasks -ParentId $task.ParentId
    
    if ($result) {
        $importedCount++
    }
    else {
        $errorCount++
        Write-Warning "Échec de l'importation de la tâche $($task.Id): $($task.Title)"
    }
}

# Afficher le résultat
Write-Host "Importation terminée: $importedCount tâches importées, $errorCount erreurs."

# Mettre à jour le statut global
Get-RoadmapJournalStatus | Out-Null

Write-Host "Le système de journalisation de la roadmap a été initialisé avec succès."
