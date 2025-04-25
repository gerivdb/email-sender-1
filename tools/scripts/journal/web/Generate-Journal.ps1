# Generate-Journal.ps1
# Script simplifié pour générer une entrée de journal pour une phase terminée


# Generate-Journal.ps1
# Script simplifié pour générer une entrée de journal pour une phase terminée

param (
    [Parameter(Mandatory = $true)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Écrire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # Créer le répertoire de logs si nécessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'écriture dans le journal
    }
}
try {
    # Script principal
]
    [string]$PhaseId,

    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = ".\"Roadmap\roadmap_perso.md"",

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
    # Détecter la catégorie
    if ($line -match "^## (\d+)\. (.+)") {
        $categoryId = $matches[1]
        $categoryName = $matches[2]
        $inPhase = ($categoryId -eq $PhaseId)

        if ($inPhase) {
            $phaseName = "$categoryId. $categoryName"
        }

        continue
    }

    # Si on n'est pas dans la phase recherchée, passer à la ligne suivante
    if (-not $inPhase) {
        continue
    }

    # Détecter les tâches
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

    # Ajouter l'entrée au début du journal
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

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "Exécution du script terminée."
}
