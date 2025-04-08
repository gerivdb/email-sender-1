# Update-Roadmap-Direct.ps1
# Script pour mettre Ã  jour directement la roadmap personnelle

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

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $dataPath)) {
    Write-Error "Fichier de donnÃ©es non trouvÃ©: $dataPath"
    exit 1
}

# Charger les donnÃ©es JSON
try {
    $roadmapData = Get-Content -Path $dataPath -Raw | ConvertFrom-Json
}
catch {
    Write-Error "Erreur lors du chargement des donnÃ©es JSON: $_"
    exit 1
}

# Fonction pour mettre Ã  jour une tÃ¢che
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
                    Write-Host "TÃ¢che $Id marquÃ©e comme terminÃ©e."
                }
                
                if ($MarkStart -and -not $task.startDate) {
                    $task.startDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
                    Write-Host "TÃ¢che $Id marquÃ©e comme dÃ©marrÃ©e."
                }
                
                if ($TaskNote) {
                    $task.notes = $TaskNote
                    Write-Host "Note ajoutÃ©e Ã  la tÃ¢che $Id."
                }
                
                # Mettre Ã  jour le pourcentage de progression de la catÃ©gorie
                $totalTasks = $category.tasks.Count
                $completedTasks = ($category.tasks | Where-Object { $_.completed -eq $true }).Count
                $category.progress = [math]::Round(($completedTasks / $totalTasks) * 100)
            }
        }
    }
    
    if (-not $taskFound) {
        Write-Error "TÃ¢che avec ID '$Id' non trouvÃ©e."
        return $false
    }
    
    return $true
}

# Si un ID de tÃ¢che est spÃ©cifiÃ©, mettre Ã  jour cette tÃ¢che
if ($TaskId) {
    $success = Update-Task -Id $TaskId -MarkComplete:$Complete -MarkStart:$Start -TaskNote $Note
    if (-not $success) { exit 1 }
}

# Mettre Ã  jour la date de derniÃ¨re modification
$roadmapData.lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")

# Sauvegarder les donnÃ©es JSON
$roadmapData | ConvertTo-Json -Depth 10 | Set-Content -Path $dataPath

# GÃ©nÃ©rer le contenu Markdown
$markdown = @"
# Roadmap personnelle d'amÃ©lioration du projet

## Vue d'ensemble des tÃ¢ches par prioritÃ© et complexitÃ©

Ce document prÃ©sente une feuille de route organisÃ©e par ordre de complexitÃ© croissante, avec une estimation du temps nÃ©cessaire pour chaque ensemble de tÃ¢ches.

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
        $markdown += "- $checkbox $($task.description) ($($task.estimatedDays) jours)"
        
        if ($task.startDate -and -not $task.completionDate) {
            $startDate = [DateTime]::Parse($task.startDate)
            $markdown += " - *DÃ©marrÃ© le $(Get-Date $startDate -Format 'dd/MM/yyyy')*"
        }
        
        if ($task.completionDate) {
            $completionDate = [DateTime]::Parse($task.completionDate)
            $markdown += " - *TerminÃ© le $(Get-Date $completionDate -Format 'dd/MM/yyyy')*"
        }
        
        $markdown += "`n"
        
        if ($task.notes) {
            $markdown += "  > *Note: $($task.notes)*`n"
        }
    }
}

$markdown += @"

## Plan d'implÃ©mentation recommandÃ©

Pour maximiser l'efficacitÃ© et obtenir des rÃ©sultats tangibles rapidement, voici une approche progressive recommandÃ©e:

1. **Semaine 1**: 
   - Documenter les problÃ¨mes actuels et leurs solutions
   - Commencer l'implÃ©mentation des utilitaires de normalisation des chemins

2. **Semaine 2-3**:
   - Finaliser les outils de gestion des chemins
   - Standardiser les scripts pour la compatibilitÃ© multi-terminaux

3. **Semaine 4-5**:
   - AmÃ©liorer les hooks Git
   - Commencer la documentation sur l'authentification

4. **Semaine 6-8**:
   - ImplÃ©menter le systÃ¨me amÃ©liorÃ© d'authentification
   - Commencer l'exploration des alternatives MCP

5. **Semaine 9+**:
   - DÃ©velopper des solutions MCP personnalisÃ©es
   - Finaliser l'ensemble de la documentation

Cette approche progressive permet d'obtenir des amÃ©liorations visibles rapidement tout en prÃ©parant le terrain pour les tÃ¢ches plus complexes Ã  long terme.

---
*DerniÃ¨re mise Ã  jour: $(Get-Date -Format 'dd/MM/yyyy HH:mm')*
"@

# Sauvegarder le fichier Markdown avec encodage UTF-8 avec BOM
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($roadmapPath, $markdown, $utf8WithBom)

Write-Host "Roadmap mise Ã  jour avec succÃ¨s."
