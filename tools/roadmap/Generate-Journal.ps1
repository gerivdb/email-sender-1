# Generate-Journal.ps1
# Script simplifiÃ© pour gÃ©nÃ©rer une entrÃ©e de journal pour une phase terminÃ©e

param (
    [Parameter(Mandatory = $true)]
    [string]$PhaseId,

    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = ".\roadmap_perso.md",

    [Parameter(Mandatory = $false)]
    [string]$JournalPath = ".\journal\journal.md"
)

# Verifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier roadmap '$RoadmapPath' n'existe pas."
    exit 1
}

# Creer le dossier du journal s'il n'existe pas
$journalFolder = Split-Path -Parent $JournalPath
if (-not (Test-Path -Path $journalFolder)) {
    New-Item -Path $journalFolder -ItemType Directory -Force | Out-Null
    Write-Output "Le dossier du journal '$journalFolder' a ete cree."
}

# Lire le contenu de la roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# Extraire les informations de la phase
$lines = $roadmapContent -split "`n"
$inPhase = $false
$phaseName = ""
$tasks = @()
$completedTasks = @()
$inProgressTasks = @()
$pendingTasks = @()

foreach ($line in $lines) {
    # DÃ©tecter la catÃ©gorie
    if ($line -match "^## (\d+)\. (.+)") {
        $categoryId = $matches[1]
        $categoryName = $matches[2]
        $inPhase = ($categoryId -eq $PhaseId)

        if ($inPhase) {
            $phaseName = "$categoryId. $categoryName"
        }

        continue
    }

    # Si on n'est pas dans la phase recherchÃ©e, passer Ã  la ligne suivante
    if (-not $inPhase) {
        continue
    }

    # DÃ©tecter les tÃ¢ches
    if ($line -match "^- \[([ x])\] (.+?) \((.+?)\)") {
        $completed = ($matches[1] -eq "x")
        $description = $matches[2]
        $estimation = $matches[3]

        $task = @{
            Description = $description
            Estimation = $estimation
            Completed = $completed
        }

        $tasks += $task

        if ($completed) {
            $completedTasks += $task
        }
        elseif ($line -match "Demarre le") {
            $inProgressTasks += $task
        }
        else {
            $pendingTasks += $task
        }
    }
}

# Verifier si la phase existe
if ([string]::IsNullOrEmpty($phaseName)) {
    Write-Error "La phase avec l'ID '$PhaseId' n'a pas ete trouvee dans la roadmap."
    exit 1
}

# Verifier si la phase est terminee
$isCompleted = ($tasks.Count -gt 0) -and ($completedTasks.Count -eq $tasks.Count)

if (-not $isCompleted) {
    Write-Output "La phase '$phaseName' n'est pas encore terminee ($($completedTasks.Count)/$($tasks.Count) taches terminees)."
    exit 0
}

# Generer l'analyse de la phase
$analysis = "# Analyse de la phase : $phaseName`n`n"
$analysis += "## Resume`n`n"
$analysis += "- **Taches totales** : $($tasks.Count)`n"
$analysis += "- **Taches terminees** : $($completedTasks.Count)`n"
$analysis += "- **Taches en cours** : $($inProgressTasks.Count)`n"
$analysis += "- **Taches en attente** : $($pendingTasks.Count)`n"

$completionPercentage = if ($tasks.Count -gt 0) {
    [math]::Round(($completedTasks.Count / $tasks.Count) * 100)
} else {
    0
}

$analysis += "- **Progression** : $completionPercentage%`n`n"

$analysis += "## Taches terminees`n`n"
if ($completedTasks.Count -gt 0) {
    foreach ($task in $completedTasks) {
        $analysis += "- [OK] $($task.Description) ($($task.Estimation))`n"
    }
} else {
    $analysis += "Aucune tache terminee.`n"
}

$analysis += "`n## Taches en cours`n`n"
if ($inProgressTasks.Count -gt 0) {
    foreach ($task in $inProgressTasks) {
        $analysis += "- [EN COURS] $($task.Description) ($($task.Estimation))`n"
    }
} else {
    $analysis += "Aucune tache en cours.`n"
}

$analysis += "`n## Taches en attente`n`n"
if ($pendingTasks.Count -gt 0) {
    foreach ($task in $pendingTasks) {
        $analysis += "- [ATTENTE] $($task.Description) ($($task.Estimation))`n"
    }
} else {
    $analysis += "Aucune tache en attente.`n"
}

$analysis += "`n## Lecons apprises`n`n"
$analysis += "- A completer manuellement`n"

$analysis += "`n## Prochaines etapes`n`n"
$analysis += "- A completer manuellement`n"

# Generer l'entree du journal
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$journalEntry = "# Entree du $timestamp`n`n$analysis"

# Verifier si le fichier du journal existe
$journalExists = Test-Path -Path $JournalPath

if ($journalExists) {
    # Lire le contenu du journal
    $journalContent = Get-Content -Path $JournalPath -Raw

    # Ajouter l'entrÃ©e au dÃ©but du journal
    $updatedContent = "$journalEntry`n`n---`n`n$journalContent"

    # Sauvegarder le journal
    $updatedContent | Out-File -FilePath $JournalPath -Encoding ascii
} else {
    # Creer un nouveau fichier journal
    $journalContent = "# Journal de developpement`n`n$journalEntry"

    # Sauvegarder le journal
    $journalContent | Out-File -FilePath $JournalPath -Encoding ascii
}

Write-Output "L'analyse de la phase '$phaseName' a ete generee et ajoutee au journal."
