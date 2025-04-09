# Update-Roadmap-Temp.ps1
# Script pour mettre à jour la roadmap personnelle en utilisant un fichier temporaire

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
$roadmapPath = "Roadmap\roadmap_perso.md"""
$tempPath = Join-Path -Path $scriptPath -ChildPath "temp_roadmap.md"

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

# Sauvegarder les données JSON
$roadmapData | ConvertTo-Json -Depth 10 | Set-Content -Path $dataPath

# Générer le contenu Markdown dans un fichier temporaire
$markdown = @"
# Roadmap personnelle d'amélioration du projet

## Vue d'ensemble des tâches par priorité et complexité

Ce document présente une feuille de route organisée par ordre de complexité croissante, avec une estimation du temps nécessaire pour chaque ensemble de tâches.

"@

foreach ($category in $roadmapData.categories) {
    $markdown += @"

## $($category.id). $($category.name)
**Complexité**: $($category.complexity)  
**Temps estimé**: $($category.estimatedDays) jours
**Progression**: $($category.progress)%

"@
    
    foreach ($task in $category.tasks) {
        $checkbox = if ($task.completed) { "[x]" } else { "[ ]" }
        $markdown += "- $checkbox $($task.description) ($($task.estimatedDays) jours)"
        
        if ($task.startDate -and -not $task.completionDate) {
            $startDate = [DateTime]::Parse($task.startDate)
            $markdown += " - *Démarré le $(Get-Date $startDate -Format 'dd/MM/yyyy')*"
        }
        
        if ($task.completionDate) {
            $completionDate = [DateTime]::Parse($task.completionDate)
            $markdown += " - *Terminé le $(Get-Date $completionDate -Format 'dd/MM/yyyy')*"
        }
        
        $markdown += "`n"
        
        if ($task.notes) {
            $markdown += "  > *Note: $($task.notes)*`n"
        }
    }
}

$markdown += @"

## Plan d'implémentation recommandé

Pour maximiser l'efficacité et obtenir des résultats tangibles rapidement, voici une approche progressive recommandée:

1. **Semaine 1**: 
   - Documenter les problèmes actuels et leurs solutions
   - Commencer l'implémentation des utilitaires de normalisation des chemins

2. **Semaine 2-3**:
   - Finaliser les outils de gestion des chemins
   - Standardiser les scripts pour la compatibilité multi-terminaux

3. **Semaine 4-5**:
   - Améliorer les hooks Git
   - Commencer la documentation sur l'authentification

4. **Semaine 6-8**:
   - Implémenter le système amélioré d'authentification
   - Commencer l'exploration des alternatives MCP

5. **Semaine 9+**:
   - Développer des solutions MCP personnalisées
   - Finaliser l'ensemble de la documentation

Cette approche progressive permet d'obtenir des améliorations visibles rapidement tout en préparant le terrain pour les tâches plus complexes à long terme.

---
*Dernière mise à jour: $(Get-Date -Format 'dd/MM/yyyy HH:mm')*
"@

# Sauvegarder le fichier temporaire
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($tempPath, $markdown, $utf8WithBom)

# Copier le fichier temporaire vers le fichier final
Copy-Item -Path $tempPath -Destination $roadmapPath -Force

# Supprimer le fichier temporaire
Remove-Item -Path $tempPath -Force

Write-Host "Roadmap mise à jour avec succès."
