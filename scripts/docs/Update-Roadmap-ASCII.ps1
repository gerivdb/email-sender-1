# Update-Roadmap-ASCII.ps1
# Script pour mettre à jour la roadmap personnelle avec encodage ASCII

param (
    [Parameter(Mandatory = $false)]
    [string]$TaskId,

    [Parameter(Mandatory = $false)]
    [switch]$Complete,

    [Parameter(Mandatory = $false)]
    [switch]$Start,

    [Parameter(Mandatory = $false)]
    [string]$Note
)

# Chemins des fichiers
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataPath = Join-Path -Path $scriptPath -ChildPath "roadmap-data.json"
$roadmapPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "roadmap_perso.md"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $dataPath)) {
    Write-Error "Fichier de données non trouvé: $dataPath"
    exit 1
}

# Charger les données JSON
try {
    $roadmapData = Get-Content -Path $dataPath -Raw | ConvertFrom-Json
}
catch {
    Write-Error "Erreur lors du chargement des données JSON: $_"
    exit 1
}

# Fonction pour mettre à jour une tâche
function Update-Task {
    param (
        [string]$Id,
        [switch]$MarkComplete,
        [switch]$MarkStart,
        [string]$TaskNote
    )

    $taskFound = $false

    foreach ($category in $roadmapData.categories) {
        foreach ($task in $category.tasks) {
            if ($task.id -eq $Id) {
                $taskFound = $true

                if ($MarkComplete) {
                    $task.completed = $true
                    $task.completionDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
                    Write-Host "Tâche $Id marquée comme terminée."
                }

                if ($MarkStart -and -not $task.startDate) {
                    $task.startDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
                    Write-Host "Tâche $Id marquée comme démarrée."
                }

                if ($TaskNote) {
                    $task.notes = $TaskNote
                    Write-Host "Note ajoutée à la tâche $Id."
                }

                # Mettre à jour le pourcentage de progression de la catégorie
                $totalTasks = $category.tasks.Count
                $completedTasks = ($category.tasks | Where-Object { $_.completed -eq $true }).Count
                $category.progress = [math]::Round(($completedTasks / $totalTasks) * 100)
            }
        }
    }

    if (-not $taskFound) {
        Write-Error "Tâche avec ID '$Id' non trouvée."
        return $false
    }

    return $true
}

# Si un ID de tâche est spécifié, mettre à jour cette tâche
if ($TaskId) {
    $success = Update-Task -Id $TaskId -MarkComplete:$Complete -MarkStart:$Start -TaskNote $Note
    if (-not $success) { exit 1 }
}

# Mettre à jour la date de dernière modification
$roadmapData.lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")

# Mettre à jour les pourcentages de progression de toutes les catégories
foreach ($category in $roadmapData.categories) {
    $totalTasks = $category.tasks.Count
    $completedTasks = ($category.tasks | Where-Object { $_.completed -eq $true }).Count
    $category.progress = [math]::Round(($completedTasks / $totalTasks) * 100)
}

# Sauvegarder les données JSON
$roadmapData | ConvertTo-Json -Depth 10 | Set-Content -Path $dataPath

# Générer le contenu Markdown en ASCII
$markdown = @"
# Roadmap personnelle d'amelioration du projet

## Vue d'ensemble des taches par priorite et complexite

Ce document presente une feuille de route organisee par ordre de complexite croissante, avec une estimation du temps necessaire pour chaque ensemble de taches.

"@

foreach ($category in $roadmapData.categories) {
    $markdown += @"

## $($category.id). $($category.name)
**ComplexitÃ©**: $($category.complexity)  
**Temps estimÃ©**: $($category.estimatedDays) jours
**Progression**: $($category.progress)%

"@

    foreach ($task in $category.tasks) {
        $checkbox = if ($task.completed) { "[x]" } else { "[ ]" }
        $markdown += "- $checkbox $description ($($task.estimatedDays) jours)"

        if ($task.startDate -and -not $task.completionDate) {
            $startDate = [DateTime]::Parse($task.startDate)
            $markdown += " - *Demarre le $(Get-Date $startDate -Format 'dd/MM/yyyy')*"
        }

        if ($task.completionDate) {
            $completionDate = [DateTime]::Parse($task.completionDate)
            $markdown += " - *Termine le $(Get-Date $completionDate -Format 'dd/MM/yyyy')*"
        }

        $markdown += "`n"

        if ($task.notes) {
            $markdown += "  > *Note: $notes*`n"
        }
    }
}

$markdown += @"

## Plan d'implementation recommande

Pour maximiser l'efficacite et obtenir des resultats tangibles rapidement, voici une approche progressive recommandee:

1. **Semaine 1**:
   - Documenter les problemes actuels et leurs solutions
   - Commencer l'implementation des utilitaires de normalisation des chemins

2. **Semaine 2-3**:
   - Finaliser les outils de gestion des chemins
   - Standardiser les scripts pour la compatibilite multi-terminaux

3. **Semaine 4-5**:
   - Ameliorer les hooks Git
   - Commencer la documentation sur l'authentification

4. **Semaine 6-8**:
   - Implementer le systeme ameliore d'authentification
   - Commencer l'exploration des alternatives MCP

5. **Semaine 9+**:
   - Developper des solutions MCP personnalisees
   - Finaliser l'ensemble de la documentation

Cette approche progressive permet d'obtenir des ameliorations visibles rapidement tout en preparant le terrain pour les taches plus complexes a long terme.

---
*Derniere mise a jour: $(Get-Date -Format 'dd/MM/yyyy HH:mm')*
"@

# Sauvegarder le fichier Markdown avec encodage ASCII
$markdown | Out-File -FilePath $roadmapPath -Encoding ascii

Write-Host "Roadmap mise à jour avec succès."

