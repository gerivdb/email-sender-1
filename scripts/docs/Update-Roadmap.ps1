# Update-Roadmap.ps1
# Script pour mettre à jour automatiquement la roadmap personnelle

param (
    [Parameter(Mandatory = $false)]
    [string]$Action = "update",

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

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $dataPath)) {
    Write-Error "Fichier de données non trouvé: $dataPath"
    exit 1
}

if (-not (Test-Path -Path $roadmapPath)) {
    Write-Error "Fichier roadmap non trouvé: $roadmapPath"
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

# Fonction pour générer le fichier Markdown
function New-MarkdownRoadmap {
    $markdown = "# Roadmap personnelle d'amélioration du projet`n`n"
    $markdown += "## Vue d'ensemble des tâches par priorité et complexité`n`n"
    $markdown += "Ce document présente une feuille de route organisée par ordre de complexité croissante, avec une estimation du temps nécessaire pour chaque ensemble de tâches.`n`n"

    foreach ($category in $roadmapData.categories) {
        $markdown += "## $($category.id). $($category.name)`n"
        $markdown += "**Complexité**: $($category.complexity)  `n"
        $markdown += "**Temps estimé**: $($category.estimatedDays) jours`n"
        $markdown += "**Progression**: $($category.progress)%`n`n"

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

        $markdown += "`n"
    }

    $markdown += "## Plan d'implémentation recommandé`n`n"
    $markdown += "Pour maximiser l'efficacité et obtenir des résultats tangibles rapidement, voici une approche progressive recommandée:`n`n"
    $markdown += "1. **Semaine 1**: `n"
    $markdown += "   - Documenter les problèmes actuels et leurs solutions`n"
    $markdown += "   - Commencer l'implémentation des utilitaires de normalisation des chemins`n`n"
    $markdown += "2. **Semaine 2-3**:`n"
    $markdown += "   - Finaliser les outils de gestion des chemins`n"
    $markdown += "   - Standardiser les scripts pour la compatibilité multi-terminaux`n`n"
    $markdown += "3. **Semaine 4-5**:`n"
    $markdown += "   - Améliorer les hooks Git`n"
    $markdown += "   - Commencer la documentation sur l'authentification`n`n"
    $markdown += "4. **Semaine 6-8**:`n"
    $markdown += "   - Implémenter le système amélioré d'authentification`n"
    $markdown += "   - Commencer l'exploration des alternatives MCP`n`n"
    $markdown += "5. **Semaine 9+**:`n"
    $markdown += "   - Développer des solutions MCP personnalisées`n"
    $markdown += "   - Finaliser l'ensemble de la documentation`n`n"
    $markdown += "Cette approche progressive permet d'obtenir des améliorations visibles rapidement tout en préparant le terrain pour les tâches plus complexes à long terme.`n`n"
    $markdown += "---`n"
    $markdown += "*Dernière mise à jour: $(Get-Date -Format 'dd/MM/yyyy HH:mm')*"

    return $markdown
}

# Traitement des actions
switch ($Action.ToLower()) {
    "update" {
        # Mettre à jour la date de dernière modification
        $roadmapData.lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")

        # Si un ID de tâche est spécifié, mettre à jour cette tâche
        if ($TaskId) {
            $success = Update-Task -Id $TaskId -MarkComplete:$Complete -MarkStart:$Start -TaskNote $Note
            if (-not $success) { exit 1 }
        }

        # Sauvegarder les données JSON
        $roadmapData | ConvertTo-Json -Depth 10 | Set-Content -Path $dataPath

        # Générer et sauvegarder le fichier Markdown
        $markdown = New-MarkdownRoadmap
        $utf8WithBom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($roadmapPath, $markdown, $utf8WithBom)

        Write-Host "Roadmap mise à jour avec succès."
    }

    "list" {
        Write-Host "Liste des tâches de la roadmap:"
        foreach ($category in $roadmapData.categories) {
            Write-Host "`n$($category.id). $($category.name) - Progression: $($category.progress)%"
            foreach ($task in $category.tasks) {
                $status = if ($task.completed) { "[TERMINÉ]" } elseif ($task.startDate) { "[EN COURS]" } else { "[À FAIRE]" }
                Write-Host "  $($task.id). $status $($task.description)"
            }
        }
    }

    "help" {
        Write-Host "Utilisation du script Update-Roadmap.ps1:"
        Write-Host "  .\Update-Roadmap.ps1 -Action <action> [-TaskId <id>] [-Complete] [-Start] [-Note <note>]"
        Write-Host ""
        Write-Host "Actions disponibles:"
        Write-Host "  update  : Met à jour la roadmap (action par défaut)"
        Write-Host "  list    : Affiche la liste des tâches"
        Write-Host "  help    : Affiche cette aide"
        Write-Host ""
        Write-Host "Paramètres:"
        Write-Host "  -TaskId   : ID de la tâche à mettre à jour (ex: 1.1, 2.3, etc.)"
        Write-Host "  -Complete : Marque la tâche comme terminée"
        Write-Host "  -Start    : Marque la tâche comme démarrée"
        Write-Host "  -Note     : Ajoute une note à la tâche"
        Write-Host ""
        Write-Host "Exemples:"
        Write-Host "  .\Update-Roadmap.ps1                                  # Met à jour la roadmap"
        Write-Host "  .\Update-Roadmap.ps1 -Action list                     # Liste toutes les tâches"
        Write-Host "  .\Update-Roadmap.ps1 -TaskId 1.1 -Start               # Marque la tâche 1.1 comme démarrée"
        Write-Host "  .\Update-Roadmap.ps1 -TaskId 1.1 -Complete            # Marque la tâche 1.1 comme terminée"
        Write-Host "  .\Update-Roadmap.ps1 -TaskId 1.1 -Note 'Mon commentaire' # Ajoute une note à la tâche 1.1"
    }

    default {
        Write-Error "Action non reconnue: $Action. Utilisez 'update', 'list' ou 'help'."
        exit 1
    }
}
