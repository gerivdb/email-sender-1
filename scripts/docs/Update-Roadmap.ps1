# Update-Roadmap.ps1
# Script pour mettre Ã  jour automatiquement la roadmap personnelle

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
$roadmapPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "roadmap_perso.md"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $dataPath)) {
    Write-Error "Fichier de donnÃ©es non trouvÃ©: $dataPath"
    exit 1
}

if (-not (Test-Path -Path $roadmapPath)) {
    Write-Error "Fichier roadmap non trouvÃ©: $roadmapPath"
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

# Fonction pour gÃ©nÃ©rer le fichier Markdown
function New-MarkdownRoadmap {
    $markdown = "# Roadmap personnelle d'amÃ©lioration du projet`n`n"
    $markdown += "## Vue d'ensemble des tÃ¢ches par prioritÃ© et complexitÃ©`n`n"
    $markdown += "Ce document prÃ©sente une feuille de route organisÃ©e par ordre de complexitÃ© croissante, avec une estimation du temps nÃ©cessaire pour chaque ensemble de tÃ¢ches.`n`n"

    foreach ($category in $roadmapData.categories) {
        $markdown += "## $($category.id). $($category.name)`n"
        $markdown += "**ComplexitÃ©**: $($category.complexity)  `n"
        $markdown += "**Temps estimÃ©**: $($category.estimatedDays) jours`n"
        $markdown += "**Progression**: $($category.progress)%`n`n"

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

        $markdown += "`n"
    }

    $markdown += "## Plan d'implÃ©mentation recommandÃ©`n`n"
    $markdown += "Pour maximiser l'efficacitÃ© et obtenir des rÃ©sultats tangibles rapidement, voici une approche progressive recommandÃ©e:`n`n"
    $markdown += "1. **Semaine 1**: `n"
    $markdown += "   - Documenter les problÃ¨mes actuels et leurs solutions`n"
    $markdown += "   - Commencer l'implÃ©mentation des utilitaires de normalisation des chemins`n`n"
    $markdown += "2. **Semaine 2-3**:`n"
    $markdown += "   - Finaliser les outils de gestion des chemins`n"
    $markdown += "   - Standardiser les scripts pour la compatibilitÃ© multi-terminaux`n`n"
    $markdown += "3. **Semaine 4-5**:`n"
    $markdown += "   - AmÃ©liorer les hooks Git`n"
    $markdown += "   - Commencer la documentation sur l'authentification`n`n"
    $markdown += "4. **Semaine 6-8**:`n"
    $markdown += "   - ImplÃ©menter le systÃ¨me amÃ©liorÃ© d'authentification`n"
    $markdown += "   - Commencer l'exploration des alternatives MCP`n`n"
    $markdown += "5. **Semaine 9+**:`n"
    $markdown += "   - DÃ©velopper des solutions MCP personnalisÃ©es`n"
    $markdown += "   - Finaliser l'ensemble de la documentation`n`n"
    $markdown += "Cette approche progressive permet d'obtenir des amÃ©liorations visibles rapidement tout en prÃ©parant le terrain pour les tÃ¢ches plus complexes Ã  long terme.`n`n"
    $markdown += "---`n"
    $markdown += "*DerniÃ¨re mise Ã  jour: $(Get-Date -Format 'dd/MM/yyyy HH:mm')*"

    return $markdown
}

# Traitement des actions
switch ($Action.ToLower()) {
    "update" {
        # Mettre Ã  jour la date de derniÃ¨re modification
        $roadmapData.lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")

        # Si un ID de tÃ¢che est spÃ©cifiÃ©, mettre Ã  jour cette tÃ¢che
        if ($TaskId) {
            $success = Update-Task -Id $TaskId -MarkComplete:$Complete -MarkStart:$Start -TaskNote $Note
            if (-not $success) { exit 1 }
        }

        # Sauvegarder les donnÃ©es JSON
        $roadmapData | ConvertTo-Json -Depth 10 | Set-Content -Path $dataPath

        # GÃ©nÃ©rer et sauvegarder le fichier Markdown
        $markdown = New-MarkdownRoadmap
        $utf8WithBom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($roadmapPath, $markdown, $utf8WithBom)

        Write-Host "Roadmap mise Ã  jour avec succÃ¨s."
    }

    "list" {
        Write-Host "Liste des tÃ¢ches de la roadmap:"
        foreach ($category in $roadmapData.categories) {
            Write-Host "`n$($category.id). $($category.name) - Progression: $($category.progress)%"
            foreach ($task in $category.tasks) {
                $status = if ($task.completed) { "[TERMINÃ‰]" } elseif ($task.startDate) { "[EN COURS]" } else { "[Ã€ FAIRE]" }
                Write-Host "  $($task.id). $status $($task.description)"
            }
        }
    }

    "help" {
        Write-Host "Utilisation du script Update-Roadmap.ps1:"
        Write-Host "  .\Update-Roadmap.ps1 -Action <action> [-TaskId <id>] [-Complete] [-Start] [-Note <note>]"
        Write-Host ""
        Write-Host "Actions disponibles:"
        Write-Host "  update  : Met Ã  jour la roadmap (action par dÃ©faut)"
        Write-Host "  list    : Affiche la liste des tÃ¢ches"
        Write-Host "  help    : Affiche cette aide"
        Write-Host ""
        Write-Host "ParamÃ¨tres:"
        Write-Host "  -TaskId   : ID de la tÃ¢che Ã  mettre Ã  jour (ex: 1.1, 2.3, etc.)"
        Write-Host "  -Complete : Marque la tÃ¢che comme terminÃ©e"
        Write-Host "  -Start    : Marque la tÃ¢che comme dÃ©marrÃ©e"
        Write-Host "  -Note     : Ajoute une note Ã  la tÃ¢che"
        Write-Host ""
        Write-Host "Exemples:"
        Write-Host "  .\Update-Roadmap.ps1                                  # Met Ã  jour la roadmap"
        Write-Host "  .\Update-Roadmap.ps1 -Action list                     # Liste toutes les tÃ¢ches"
        Write-Host "  .\Update-Roadmap.ps1 -TaskId 1.1 -Start               # Marque la tÃ¢che 1.1 comme dÃ©marrÃ©e"
        Write-Host "  .\Update-Roadmap.ps1 -TaskId 1.1 -Complete            # Marque la tÃ¢che 1.1 comme terminÃ©e"
        Write-Host "  .\Update-Roadmap.ps1 -TaskId 1.1 -Note 'Mon commentaire' # Ajoute une note Ã  la tÃ¢che 1.1"
    }

    default {
        Write-Error "Action non reconnue: $Action. Utilisez 'update', 'list' ou 'help'."
        exit 1
    }
}
