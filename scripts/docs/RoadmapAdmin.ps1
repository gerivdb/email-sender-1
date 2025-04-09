# Script d'administration de la roadmap
# Ce script permet d'inspecter la roadmap, vérifier l'avancement, mettre à jour les tâches
# et enchaîner automatiquement sur les tâches suivantes

param (
    [string]$RoadmapPath = ""Roadmap\roadmap_perso.md"",
    [switch]$AutoUpdate = $false,
    [switch]$AutoExecute = $false,
    [int]$MaxRetries = 3,
    [int]$RetryDelay = 5
)

# Configuration
$augmentScriptPath = "AugmentExecutor.ps1"
$backupFolder = "Roadmap_Backups"
$logFile = "RoadmapAdmin.log"

# Fonction pour écrire dans le journal
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Écrire dans le fichier journal
    Add-Content -Path $logFile -Value $logEntry

    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        default { Write-Host $logEntry }
    }
}

# Fonction pour créer une sauvegarde de la roadmap
function Backup-Roadmap {
    param (
        [string]$Path
    )

    # Créer le dossier de sauvegarde s'il n'existe pas
    if (-not (Test-Path -Path $backupFolder)) {
        New-Item -Path $backupFolder -ItemType Directory -Force | Out-Null
    }

    # Générer un nom de fichier avec horodatage
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path -Path $backupFolder -ChildPath "roadmap_$timestamp.md"

    # Copier le fichier
    Copy-Item -Path $Path -Destination $backupPath

    Write-Log "Sauvegarde créée: $backupPath" "INFO"

    return $backupPath
}

# Fonction pour analyser la roadmap
function Get-RoadmapContent {
    param (
        [string]$Path
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        Write-Log "Le fichier roadmap n'existe pas: $Path" "ERROR"
        return $null
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $Path -Raw

    # Structure pour stocker les données de la roadmap
    $roadmap = @{
        Title = ""
        Sections = @()
    }

    # Extraire le titre
    if ($content -match "^# (.+)$") {
        $roadmap.Title = $Matches[1]
    }

    # Analyser les sections, phases et tâches
    $lines = $content -split "`n"
    $currentSection = $null
    $currentPhase = $null

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Détecter une section
        if ($line -match "^## (\d+)\. (.+)$") {
            $sectionId = $Matches[1]
            $sectionTitle = $Matches[2]

            $currentSection = @{
                Id = $sectionId
                Title = $sectionTitle
                LineNumber = $i
                Phases = @()
                Metadata = @{}
            }

            $roadmap.Sections += $currentSection
            $currentPhase = $null

            # Extraire les métadonnées de la section
            $j = $i + 1
            while ($j -lt $lines.Count -and -not $lines[$j].StartsWith("- ")) {
                if ($lines[$j] -match "\*\*(.+)\*\*: (.+)") {
                    $metaKey = $Matches[1]
                    $metaValue = $Matches[2]
                    $currentSection.Metadata[$metaKey] = $metaValue
                }
                $j++
            }
        }

        # Détecter une phase
        elseif ($line -match "^  - \[([ x])\] \*\*Phase (\d+): (.+)\*\*$" -and $null -ne $currentSection) {
            $isCompleted = $Matches[1] -eq "x"
            $phaseId = $Matches[2]
            $phaseTitle = $Matches[3]

            $currentPhase = @{
                Id = $phaseId
                Title = $phaseTitle
                LineNumber = $i
                IsCompleted = $isCompleted
                Tasks = @()
            }

            $currentSection.Phases += $currentPhase
        }

        # Détecter une tâche
        elseif ($line -match "^    - \[([ x])\] (.+)$" -and $null -ne $currentPhase) {
            $isCompleted = $Matches[1] -eq "x"
            $taskTitle = $Matches[2]

            $task = @{
                Title = $taskTitle
                LineNumber = $i
                IsCompleted = $isCompleted
                Subtasks = @()
            }

            $currentPhase.Tasks += $task
        }

        # Détecter une sous-tâche
        elseif ($line -match "^      - \[([ x])\] (.+)$" -and $null -ne $currentPhase -and $currentPhase.Tasks.Count -gt 0) {
            $isCompleted = $Matches[1] -eq "x"
            $subtaskTitle = $Matches[2]

            $subtask = @{
                Title = $subtaskTitle
                LineNumber = $i
                IsCompleted = $isCompleted
            }

            $currentPhase.Tasks[-1].Subtasks += $subtask
        }
    }

    return $roadmap
}

# Fonction pour vérifier l'état d'avancement
function Get-RoadmapProgress {
    param (
        [hashtable]$Roadmap
    )

    $totalSections = $Roadmap.Sections.Count
    $completedSections = 0

    $totalPhases = 0
    $completedPhases = 0

    $totalTasks = 0
    $completedTasks = 0

    $totalSubtasks = 0
    $completedSubtasks = 0

    foreach ($section in $Roadmap.Sections) {
        $sectionCompleted = $true

        foreach ($phase in $section.Phases) {
            $totalPhases++

            if ($phase.IsCompleted) {
                $completedPhases++
            }
            else {
                $sectionCompleted = $false
            }

            foreach ($task in $phase.Tasks) {
                $totalTasks++

                if ($task.IsCompleted) {
                    $completedTasks++
                }
                else {
                    $sectionCompleted = $false
                }

                foreach ($subtask in $task.Subtasks) {
                    $totalSubtasks++

                    if ($subtask.IsCompleted) {
                        $completedSubtasks++
                    }
                    else {
                        $sectionCompleted = $false
                    }
                }
            }
        }

        if ($sectionCompleted) {
            $completedSections++
        }
    }

    $progress = @{
        Sections = @{
            Total = $totalSections
            Completed = $completedSections
            Percentage = if ($totalSections -gt 0) { [math]::Round(($completedSections / $totalSections) * 100, 2) } else { 0 }
        }
        Phases = @{
            Total = $totalPhases
            Completed = $completedPhases
            Percentage = if ($totalPhases -gt 0) { [math]::Round(($completedPhases / $totalPhases) * 100, 2) } else { 0 }
        }
        Tasks = @{
            Total = $totalTasks
            Completed = $completedTasks
            Percentage = if ($totalTasks -gt 0) { [math]::Round(($completedTasks / $totalTasks) * 100, 2) } else { 0 }
        }
        Subtasks = @{
            Total = $totalSubtasks
            Completed = $completedSubtasks
            Percentage = if ($totalSubtasks -gt 0) { [math]::Round(($completedSubtasks / $totalSubtasks) * 100, 2) } else { 0 }
        }
    }

    return $progress
}

# Fonction pour trouver la prochaine tâche à exécuter
function Find-NextTask {
    param (
        [hashtable]$Roadmap
    )

    foreach ($section in $Roadmap.Sections) {
        foreach ($phase in $section.Phases) {
            if (-not $phase.IsCompleted) {
                foreach ($task in $phase.Tasks) {
                    if (-not $task.IsCompleted) {
                        # Vérifier si au moins une sous-tâche n'est pas terminée
                        foreach ($subtask in $task.Subtasks) {
                            if (-not $subtask.IsCompleted) {
                                return @{
                                    Type = "Subtask"
                                    Section = $section
                                    Phase = $phase
                                    Task = $task
                                    Subtask = $subtask
                                    Path = "$($section.Title) > Phase $($phase.Id): $($phase.Title) > $($task.Title) > $($subtask.Title)"
                                }
                            }
                        }

                        # Si toutes les sous-tâches sont terminées ou s'il n'y a pas de sous-tâches
                        return @{
                            Type = "Task"
                            Section = $section
                            Phase = $phase
                            Task = $task
                            Path = "$($section.Title) > Phase $($phase.Id): $($phase.Title) > $($task.Title)"
                        }
                    }
                }

                # Si toutes les tâches sont terminées mais pas la phase
                return @{
                    Type = "Phase"
                    Section = $section
                    Phase = $phase
                    Path = "$($section.Title) > Phase $($phase.Id): $($phase.Title)"
                }
            }
        }
    }

    # Si tout est terminé
    return $null
}

# Fonction pour mettre à jour la roadmap
function Update-Roadmap {
    param (
        [string]$Path,
        [hashtable]$Item,
        [switch]$MarkCompleted
    )

    # Définir la valeur par défaut pour MarkCompleted
    if (-not $PSBoundParameters.ContainsKey('MarkCompleted')) {
        $MarkCompleted = $true
    }

    # Définir la valeur par défaut pour MarkCompleted
    if (-not $PSBoundParameters.ContainsKey('MarkCompleted')) {
        $MarkCompleted = $true
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $Path

    # Déterminer la ligne à modifier
    $lineNumber = -1
    $lineContent = ""

    switch ($Item.Type) {
        "Subtask" {
            $lineNumber = $Item.Subtask.LineNumber
            $lineContent = $content[$lineNumber]
            $newContent = $lineContent -replace "\[ \]", "[x]"
        }
        "Task" {
            $lineNumber = $Item.Task.LineNumber
            $lineContent = $content[$lineNumber]
            $newContent = $lineContent -replace "\[ \]", "[x]"
        }
        "Phase" {
            $lineNumber = $Item.Phase.LineNumber
            $lineContent = $content[$lineNumber]
            $newContent = $lineContent -replace "\[ \]", "[x]"
        }
    }

    # Mettre à jour le contenu
    if ($lineNumber -ge 0) {
        $content[$lineNumber] = $newContent
        Set-Content -Path $Path -Value $content

        Write-Log "Roadmap mise à jour: $($Item.Path) marqué comme terminé" "SUCCESS"
        return $true
    }
    else {
        Write-Log "Impossible de mettre à jour la roadmap: ligne non trouvée" "ERROR"
        return $false
    }
}

# Fonction pour exécuter une tâche avec Augment
function Invoke-AugmentTask {
    param (
        [hashtable]$Item
    )

    # Construire la commande pour Augment
    $taskDescription = ""

    switch ($Item.Type) {
        "Subtask" {
            $taskDescription = "Exécuter la sous-tâche '$($Item.Subtask.Title)' de la tâche '$($Item.Task.Title)' dans la phase '$($Item.Phase.Title)' de la section '$($Item.Section.Title)'"
        }
        "Task" {
            $taskDescription = "Exécuter la tâche '$($Item.Task.Title)' dans la phase '$($Item.Phase.Title)' de la section '$($Item.Section.Title)'"
        }
        "Phase" {
            $taskDescription = "Exécuter la phase '$($Item.Phase.Title)' de la section '$($Item.Section.Title)'"
        }
    }

    Write-Log "Exécution de la tâche: $($Item.Path)" "INFO"

    # Vérifier si le script Augment existe
    if (-not (Test-Path -Path $augmentScriptPath)) {
        Write-Log "Le script Augment n'existe pas: $augmentScriptPath" "ERROR"
        return $false
    }

    # Exécuter le script Augment
    $retryCount = 0
    $success = $false

    while (-not $success -and $retryCount -lt $MaxRetries) {
        try {
            Write-Log "Tentative d'exécution #$($retryCount + 1)" "INFO"

            # Exécuter le script Augment
            & $augmentScriptPath -Task $taskDescription

            $success = $true
            Write-Log "Exécution réussie" "SUCCESS"
        }
        catch {
            $retryCount++
            Write-Log "Échec de l'exécution: $_" "ERROR"

            if ($retryCount -lt $MaxRetries) {
                Write-Log "Nouvelle tentative dans $RetryDelay secondes..." "WARNING"
                Start-Sleep -Seconds $RetryDelay
            }
        }
    }

    return $success
}

# Fonction principale
function Start-RoadmapAdmin {
    # Vérifier si le fichier roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Log "Le fichier roadmap n'existe pas: $RoadmapPath" "ERROR"
        return
    }

    # Créer une sauvegarde
    [void] Backup-Roadmap -Path $RoadmapPath

    # Analyser la roadmap
    $roadmap = Get-RoadmapContent -Path $RoadmapPath

    if ($null -eq $roadmap) {
        Write-Log "Impossible d'analyser la roadmap" "ERROR"
        return
    }

    # Afficher les informations sur la roadmap
    Write-Log "Roadmap: $($roadmap.Title)" "INFO"
    Write-Log "Sections: $($roadmap.Sections.Count)" "INFO"

    # Calculer la progression
    $progress = Get-RoadmapProgress -Roadmap $roadmap

    Write-Log "Progression des sections: $($progress.Sections.Completed)/$($progress.Sections.Total) ($($progress.Sections.Percentage)%)" "INFO"
    Write-Log "Progression des phases: $($progress.Phases.Completed)/$($progress.Phases.Total) ($($progress.Phases.Percentage)%)" "INFO"
    Write-Log "Progression des tâches: $($progress.Tasks.Completed)/$($progress.Tasks.Total) ($($progress.Tasks.Percentage)%)" "INFO"
    Write-Log "Progression des sous-tâches: $($progress.Subtasks.Completed)/$($progress.Subtasks.Total) ($($progress.Subtasks.Percentage)%)" "INFO"

    # Trouver la prochaine tâche à exécuter
    $nextItem = Find-NextTask -Roadmap $roadmap

    if ($null -eq $nextItem) {
        Write-Log "Toutes les tâches sont terminées!" "SUCCESS"
        return
    }

    Write-Log "Prochaine tâche à exécuter: $($nextItem.Path)" "INFO"

    # Exécuter la tâche si demandé
    if ($AutoExecute) {
        $success = Invoke-AugmentTask -Item $nextItem

        # Mettre à jour la roadmap si demandé et si l'exécution a réussi
        if ($AutoUpdate -and $success) {
            Update-Roadmap -Path $RoadmapPath -Item $nextItem -MarkCompleted

            # Relancer le script pour la tâche suivante
            Write-Log "Relancement du script pour la tâche suivante..." "INFO"
            & $PSCommandPath -RoadmapPath $RoadmapPath -AutoUpdate:$AutoUpdate -AutoExecute:$AutoExecute -MaxRetries $MaxRetries -RetryDelay $RetryDelay
        }
    }
    elseif ($AutoUpdate) {
        # Demander confirmation
        $confirmation = Read-Host "Voulez-vous marquer cette tâche comme terminée? (O/N)"

        if ($confirmation -eq "O" -or $confirmation -eq "o") {
            Update-Roadmap -Path $RoadmapPath -Item $nextItem -MarkCompleted

            # Relancer le script pour la tâche suivante
            Write-Log "Relancement du script pour la tâche suivante..." "INFO"
            & $PSCommandPath -RoadmapPath $RoadmapPath -AutoUpdate:$AutoUpdate -AutoExecute:$AutoExecute -MaxRetries $MaxRetries -RetryDelay $RetryDelay
        }
    }
}

# Démarrer le script
Write-Log "Démarrage du script d'administration de la roadmap" "INFO"
Start-RoadmapAdmin
Write-Log "Fin du script d'administration de la roadmap" "INFO"









