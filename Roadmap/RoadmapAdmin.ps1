# Script d'administration de la roadmap
# Ce script permet d'inspecter la roadmap, vÃ©rifier l'avancement, mettre Ã  jour les tÃ¢ches
# et enchaÃ®ner automatiquement sur les tÃ¢ches suivantes

param (
    [string]$RoadmapPath = "roadmap_perso.md",
    [switch]$AutoUpdate = $false,
    [switch]$AutoExecute = $false,
    [int]$MaxRetries = 3,
    [int]$RetryDelay = 5
)

# Configuration
$augmentScriptPath = "AugmentExecutor.ps1"
$backupFolder = "Roadmap_Backups"
$logFile = "RoadmapAdmin.log"

# Fonction pour Ã©crire dans le journal
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Ã‰crire dans le fichier journal
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

# Fonction pour crÃ©er une sauvegarde de la roadmap
function Backup-Roadmap {
    param (
        [string]$Path
    )

    # CrÃ©er le dossier de sauvegarde s'il n'existe pas
    if (-not (Test-Path -Path $backupFolder)) {
        New-Item -Path $backupFolder -ItemType Directory -Force | Out-Null
    }

    # GÃ©nÃ©rer un nom de fichier avec horodatage
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path -Path $backupFolder -ChildPath "roadmap_$timestamp.md"

    # Copier le fichier
    Copy-Item -Path $Path -Destination $backupPath

    Write-Log "Sauvegarde crÃ©Ã©e: $backupPath" "INFO"

    return $backupPath
}

# Fonction pour analyser la roadmap
function Get-RoadmapContent {
    param (
        [string]$Path
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        Write-Log "Le fichier roadmap n'existe pas: $Path" "ERROR"
        return $null
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $Path -Raw

    # Structure pour stocker les donnÃ©es de la roadmap
    $roadmap = @{
        Title = ""
        Sections = @()
    }

    # Extraire le titre
    if ($content -match "^# (.+)$") {
        $roadmap.Title = $Matches[1]
    }

    # Analyser les sections, phases et tÃ¢ches
    $lines = $content -split "`n"
    $currentSection = $null
    $currentPhase = $null

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # DÃ©tecter une section
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

            # Extraire les mÃ©tadonnÃ©es de la section
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

        # DÃ©tecter une phase
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

        # DÃ©tecter une tÃ¢che
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

        # DÃ©tecter une sous-tÃ¢che
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

# Fonction pour vÃ©rifier l'Ã©tat d'avancement
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

# Fonction pour trouver la prochaine tÃ¢che Ã  exÃ©cuter
function Find-NextTask {
    param (
        [hashtable]$Roadmap
    )

    foreach ($section in $Roadmap.Sections) {
        foreach ($phase in $section.Phases) {
            if (-not $phase.IsCompleted) {
                foreach ($task in $phase.Tasks) {
                    if (-not $task.IsCompleted) {
                        # VÃ©rifier si au moins une sous-tÃ¢che n'est pas terminÃ©e
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

                        # Si toutes les sous-tÃ¢ches sont terminÃ©es ou s'il n'y a pas de sous-tÃ¢ches
                        return @{
                            Type = "Task"
                            Section = $section
                            Phase = $phase
                            Task = $task
                            Path = "$($section.Title) > Phase $($phase.Id): $($phase.Title) > $($task.Title)"
                        }
                    }
                }

                # Si toutes les tÃ¢ches sont terminÃ©es mais pas la phase
                return @{
                    Type = "Phase"
                    Section = $section
                    Phase = $phase
                    Path = "$($section.Title) > Phase $($phase.Id): $($phase.Title)"
                }
            }
        }
    }

    # Si tout est terminÃ©
    return $null
}

# Fonction pour mettre Ã  jour la roadmap
function Update-Roadmap {
    param (
        [string]$Path,
        [hashtable]$Item,
        [switch]$MarkCompleted
    )

    # DÃ©finir la valeur par dÃ©faut pour MarkCompleted
    if (-not $PSBoundParameters.ContainsKey('MarkCompleted')) {
        $MarkCompleted = $true
    }

    # DÃ©finir la valeur par dÃ©faut pour MarkCompleted
    if (-not $PSBoundParameters.ContainsKey('MarkCompleted')) {
        $MarkCompleted = $true
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $Path

    # DÃ©terminer la ligne Ã  modifier
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

    # Mettre Ã  jour le contenu
    if ($lineNumber -ge 0) {
        $content[$lineNumber] = $newContent
        Set-Content -Path $Path -Value $content

        Write-Log "Roadmap mise Ã  jour: $($Item.Path) marquÃ© comme terminÃ©" "SUCCESS"
        return $true
    }
    else {
        Write-Log "Impossible de mettre Ã  jour la roadmap: ligne non trouvÃ©e" "ERROR"
        return $false
    }
}

# Fonction pour exÃ©cuter une tÃ¢che avec Augment
function Invoke-AugmentTask {
    param (
        [hashtable]$Item
    )

    # Construire la commande pour Augment
    $taskDescription = ""

    switch ($Item.Type) {
        "Subtask" {
            $taskDescription = "ExÃ©cuter la sous-tÃ¢che '$($Item.Subtask.Title)' de la tÃ¢che '$($Item.Task.Title)' dans la phase '$($Item.Phase.Title)' de la section '$($Item.Section.Title)'"
        }
        "Task" {
            $taskDescription = "ExÃ©cuter la tÃ¢che '$($Item.Task.Title)' dans la phase '$($Item.Phase.Title)' de la section '$($Item.Section.Title)'"
        }
        "Phase" {
            $taskDescription = "ExÃ©cuter la phase '$($Item.Phase.Title)' de la section '$($Item.Section.Title)'"
        }
    }

    Write-Log "ExÃ©cution de la tÃ¢che: $($Item.Path)" "INFO"

    # VÃ©rifier si le script Augment existe
    if (-not (Test-Path -Path $augmentScriptPath)) {
        Write-Log "Le script Augment n'existe pas: $augmentScriptPath" "ERROR"
        return $false
    }

    # ExÃ©cuter le script Augment
    $retryCount = 0
    $success = $false

    while (-not $success -and $retryCount -lt $MaxRetries) {
        try {
            Write-Log "Tentative d'exÃ©cution #$($retryCount + 1)" "INFO"

            # ExÃ©cuter le script Augment
            & $augmentScriptPath -Task $taskDescription

            $success = $true
            Write-Log "ExÃ©cution rÃ©ussie" "SUCCESS"
        }
        catch {
            $retryCount++
            Write-Log "Ã‰chec de l'exÃ©cution: $_" "ERROR"

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
    # VÃ©rifier si le fichier roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Log "Le fichier roadmap n'existe pas: $RoadmapPath" "ERROR"
        return
    }

    # CrÃ©er une sauvegarde
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
    Write-Log "Progression des tÃ¢ches: $($progress.Tasks.Completed)/$($progress.Tasks.Total) ($($progress.Tasks.Percentage)%)" "INFO"
    Write-Log "Progression des sous-tÃ¢ches: $($progress.Subtasks.Completed)/$($progress.Subtasks.Total) ($($progress.Subtasks.Percentage)%)" "INFO"

    # Trouver la prochaine tÃ¢che Ã  exÃ©cuter
    $nextItem = Find-NextTask -Roadmap $roadmap

    if ($null -eq $nextItem) {
        Write-Log "Toutes les tÃ¢ches sont terminÃ©es!" "SUCCESS"
        return
    }

    Write-Log "Prochaine tÃ¢che Ã  exÃ©cuter: $($nextItem.Path)" "INFO"

    # ExÃ©cuter la tÃ¢che si demandÃ©
    if ($AutoExecute) {
        $success = Invoke-AugmentTask -Item $nextItem

        # Mettre Ã  jour la roadmap si demandÃ© et si l'exÃ©cution a rÃ©ussi
        if ($AutoUpdate -and $success) {
            Update-Roadmap -Path $RoadmapPath -Item $nextItem -MarkCompleted

            # Relancer le script pour la tÃ¢che suivante
            Write-Log "Relancement du script pour la tÃ¢che suivante..." "INFO"
            & $PSCommandPath -RoadmapPath $RoadmapPath -AutoUpdate:$AutoUpdate -AutoExecute:$AutoExecute -MaxRetries $MaxRetries -RetryDelay $RetryDelay
        }
    }
    elseif ($AutoUpdate) {
        # Demander confirmation
        $confirmation = Read-Host "Voulez-vous marquer cette tÃ¢che comme terminÃ©e? (O/N)"

        if ($confirmation -eq "O" -or $confirmation -eq "o") {
            Update-Roadmap -Path $RoadmapPath -Item $nextItem -MarkCompleted

            # Relancer le script pour la tÃ¢che suivante
            Write-Log "Relancement du script pour la tÃ¢che suivante..." "INFO"
            & $PSCommandPath -RoadmapPath $RoadmapPath -AutoUpdate:$AutoUpdate -AutoExecute:$AutoExecute -MaxRetries $MaxRetries -RetryDelay $RetryDelay
        }
    }
}

# DÃ©marrer le script
Write-Log "DÃ©marrage du script d'administration de la roadmap" "INFO"
Start-RoadmapAdmin
Write-Log "Fin du script d'administration de la roadmap" "INFO"









