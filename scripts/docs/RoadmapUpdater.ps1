# Script pour mettre à jour automatiquement la roadmap
# Respecte les principes SOLID, DRY, KISS et Clean Code

# Configuration
$RoadmapConfig = @{
    # Chemin du fichier roadmap
    RoadmapPath = "Roadmap\roadmap_perso.md"""

    # Modèle de case à cocher non cochée
    UncheckedPattern = "- [ ]"

    # Modèle de case à cocher cochée
    CheckedPattern = "- [x]"

    # Modèle pour calculer la progression
    ProgressionPattern = "\*\*Progression\*\*: (\d+)%"

    # Journal des mises à jour
    UpdateLogPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap_updates.log"
}

# Fonction pour initialiser le module

# Script pour mettre à jour automatiquement la roadmap
# Respecte les principes SOLID, DRY, KISS et Clean Code

# Configuration
$RoadmapConfig = @{
    # Chemin du fichier roadmap
    RoadmapPath = "Roadmap\roadmap_perso.md"""

    # Modèle de case à cocher non cochée
    UncheckedPattern = "- [ ]"

    # Modèle de case à cocher cochée
    CheckedPattern = "- [x]"

    # Modèle pour calculer la progression
    ProgressionPattern = "\*\*Progression\*\*: (\d+)%"

    # Journal des mises à jour
    UpdateLogPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap_updates.log"
}

# Fonction pour initialiser le module
function Initialize-RoadmapUpdater {
    param (
        [string]$RoadmapPath = "",
        [string]$UpdateLogPath = ""
    )

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


    # Mettre à jour la configuration
    if (-not [string]::IsNullOrEmpty($RoadmapPath)) {
        $RoadmapConfig.RoadmapPath = $RoadmapPath
    }

    if (-not [string]::IsNullOrEmpty($UpdateLogPath)) {
        $RoadmapConfig.UpdateLogPath = $UpdateLogPath
    }

    # Vérifier si le fichier roadmap existe
    if (-not (Test-Path -Path $RoadmapConfig.RoadmapPath)) {
        Write-Error "Le fichier roadmap n'existe pas: $($RoadmapConfig.RoadmapPath)"
        return $false
    }

    # Créer le dossier du journal s'il n'existe pas
    $logFolder = Split-Path -Path $RoadmapConfig.UpdateLogPath -Parent
    if (-not (Test-Path -Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
    }

    return $RoadmapConfig
}

# Fonction pour analyser la structure de la roadmap
function Get-RoadmapStructure {
    # Lire le contenu du fichier roadmap
    $content = Get-Content -Path $RoadmapConfig.RoadmapPath -Raw

    # Diviser le contenu en sections
    $sections = [regex]::Matches($content, "(?m)^## \d+\. [^\r\n]+[\r\n]+(?:\*\*[^\r\n]+[\r\n]+)*(?:- \[[x ]\] .*?(?=^## \d+\.|$))", [System.Text.RegularExpressions.RegexOptions]::Singleline)

    $roadmapStructure = @()

    foreach ($section in $sections) {
        $sectionText = $section.Value

        # Extraire le titre de la section
        $sectionTitle = [regex]::Match($sectionText, "(?m)^## \d+\. ([^\r\n]+)").Groups[1].Value

        # Extraire la progression
        $progressionMatch = [regex]::Match($sectionText, $RoadmapConfig.ProgressionPattern)
        $progression = if ($progressionMatch.Success) { [int]$progressionMatch.Groups[1].Value } else { 0 }

        # Extraire les phases
        $phases = [regex]::Matches($sectionText, "(?m)^- \[([x ])\] \*\*Phase \d+: ([^\*]+)\*\*.*?(?=^- \[|$)", [System.Text.RegularExpressions.RegexOptions]::Singleline)

        $sectionPhases = @()

        foreach ($phase in $phases) {
            $phaseText = $phase.Value
            $phaseTitle = $phase.Groups[2].Value.Trim()
            $phaseChecked = $phase.Groups[1].Value -eq "x"

            # Extraire les tâches
            $tasks = [regex]::Matches($phaseText, "(?m)^  - \[([x ])\] ([^\r\n]+).*?(?=^  - \[|^- \[|$)", [System.Text.RegularExpressions.RegexOptions]::Singleline)

            $phaseTasks = @()

            foreach ($task in $tasks) {
                $taskText = $task.Value
                $taskTitle = $task.Groups[2].Value.Trim()
                $taskChecked = $task.Groups[1].Value -eq "x"

                # Extraire les sous-tâches
                $subtasks = [regex]::Matches($taskText, "(?m)^    - \[([x ])\] ([^\r\n]+)")

                $taskSubtasks = @()

                foreach ($subtask in $subtasks) {
                    $subtaskTitle = $subtask.Groups[2].Value.Trim()
                    $subtaskChecked = $subtask.Groups[1].Value -eq "x"

                    $taskSubtasks += [PSCustomObject]@{
                        Title = $subtaskTitle
                        Checked = $subtaskChecked
                    }
                }

                $phaseTasks += [PSCustomObject]@{
                    Title = $taskTitle
                    Checked = $taskChecked
                    Subtasks = $taskSubtasks
                    AllSubtasksChecked = ($taskSubtasks.Count -gt 0) -and ($taskSubtasks | Where-Object { -not $_.Checked } | Measure-Object).Count -eq 0
                }
            }

            $sectionPhases += [PSCustomObject]@{
                Title = $phaseTitle
                Checked = $phaseChecked
                Tasks = $phaseTasks
                AllTasksChecked = ($phaseTasks.Count -gt 0) -and ($phaseTasks | Where-Object { -not $_.Checked } | Measure-Object).Count -eq 0
            }
        }

        $roadmapStructure += [PSCustomObject]@{
            Title = $sectionTitle
            Progression = $progression
            Phases = $sectionPhases
            AllPhasesChecked = ($sectionPhases.Count -gt 0) -and ($sectionPhases | Where-Object { -not $_.Checked } | Measure-Object).Count -eq 0
        }
    }

    return $roadmapStructure
}

# Fonction pour mettre à jour les cases à cocher
function Update-RoadmapCheckboxes {
    # Analyser la structure de la roadmap
    $structure = Get-RoadmapStructure

    # Lire le contenu du fichier roadmap
    $content = Get-Content -Path $RoadmapConfig.RoadmapPath -Raw

    $changes = @()

    # Parcourir les sections
    foreach ($section in $structure) {
        # Parcourir les phases
        foreach ($phase in $section.Phases) {
            # Mettre à jour les cases à cocher des phases
            if ($phase.AllTasksChecked -and -not $phase.Checked) {
                $phasePattern = "(?m)^- \[ \] \*\*Phase \d+: $([regex]::Escape($phase.Title))\*\*"
                $phaseReplacement = "- [x] **Phase $(($phase.Title -split ":")[0])**: $($phase.Title)"
                $content = [regex]::Replace($content, $phasePattern, $phaseReplacement)
                $changes += "Coché la phase: $($phase.Title)"
            }

            # Parcourir les tâches
            foreach ($task in $phase.Tasks) {
                # Mettre à jour les cases à cocher des tâches
                if ($task.AllSubtasksChecked -and -not $task.Checked) {
                    $taskPattern = "(?m)^  - \[ \] $([regex]::Escape($task.Title))"
                    $taskReplacement = "  - [x] $($task.Title)"
                    $content = [regex]::Replace($content, $taskPattern, $taskReplacement)
                    $changes += "Coché la tâche: $($task.Title)"
                }
            }
        }

        # Mettre à jour la progression
        if ($section.Phases.Count -gt 0) {
            $checkedPhases = ($section.Phases | Where-Object { $_.Checked } | Measure-Object).Count
            $totalPhases = $section.Phases.Count
            $newProgression = [Math]::Round(($checkedPhases / $totalPhases) * 100)

            if ($newProgression -ne $section.Progression) {
                $progressionPattern = "(?m)(\*\*Progression\*\*: )\d+(%)"
                $progressionReplacement = "`${1}$newProgression`${2}"
                $content = [regex]::Replace($content, $progressionPattern, $progressionReplacement)
                $changes += "Mis à jour la progression de la section '$($section.Title)' à $newProgression%"
            }
        }
    }

    # Enregistrer les modifications
    if ($changes.Count -gt 0) {
        $content | Set-Content -Path $RoadmapConfig.RoadmapPath -Encoding UTF8

        # Journaliser les modifications
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] $($changes.Count) modifications apportées à la roadmap:`n$($changes -join "`n")`n"
        Add-Content -Path $RoadmapConfig.UpdateLogPath -Value $logEntry

        return $changes
    }

    return $null
}

# Fonction pour vérifier si toutes les sous-tâches d'une tâche sont terminées
function Test-TaskCompletion {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PhaseTitle,

        [Parameter(Mandatory = $true)]
        [string]$TaskTitle
    )

    # Analyser la structure de la roadmap
    $structure = Get-RoadmapStructure

    # Trouver la phase
    $phase = $structure.Phases | Where-Object { $_.Title -eq $PhaseTitle }

    if (-not $phase) {
        Write-Warning "Phase non trouvée: $PhaseTitle"
        return $false
    }

    # Trouver la tâche
    $task = $phase.Tasks | Where-Object { $_.Title -eq $TaskTitle }

    if (-not $task) {
        Write-Warning "Tâche non trouvée: $TaskTitle"
        return $false
    }

    # Vérifier si toutes les sous-tâches sont terminées
    return $task.AllSubtasksChecked
}

# Fonction pour marquer une tâche comme terminée
function Set-TaskCompleted {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PhaseTitle,

        [Parameter(Mandatory = $true)]
        [string]$TaskTitle,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Lire le contenu du fichier roadmap
    $content = Get-Content -Path $RoadmapConfig.RoadmapPath -Raw

    # Vérifier si toutes les sous-tâches sont terminées
    $allSubtasksCompleted = Test-TaskCompletion -PhaseTitle $PhaseTitle -TaskTitle $TaskTitle

    if ($allSubtasksCompleted -or $Force) {
        # Marquer la tâche comme terminée
        $taskPattern = "(?m)^  - \[ \] $([regex]::Escape($TaskTitle))"
        $taskReplacement = "  - [x] $TaskTitle"
        $newContent = [regex]::Replace($content, $taskPattern, $taskReplacement)

        if ($newContent -ne $content) {
            $newContent | Set-Content -Path $RoadmapConfig.RoadmapPath -Encoding UTF8

            # Journaliser la modification
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] Tâche marquée comme terminée: $TaskTitle`n"
            Add-Content -Path $RoadmapConfig.UpdateLogPath -Value $logEntry

            # Mettre à jour les cases à cocher
            Update-RoadmapCheckboxes

            return $true
        }
    }
    else {
        Write-Warning "Toutes les sous-tâches ne sont pas terminées. Utilisez -Force pour marquer la tâche comme terminée quand même."
    }

    return $false
}

# Fonction pour marquer une phase comme terminée
function Set-PhaseCompleted {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PhaseTitle,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Lire le contenu du fichier roadmap
    $content = Get-Content -Path $RoadmapConfig.RoadmapPath -Raw

    # Analyser la structure de la roadmap
    $structure = Get-RoadmapStructure

    # Trouver la phase
    $phase = $structure.Phases | Where-Object { $_.Title -eq $PhaseTitle }

    if (-not $phase) {
        Write-Warning "Phase non trouvée: $PhaseTitle"
        return $false
    }

    # Vérifier si toutes les tâches sont terminées
    $allTasksCompleted = $phase.AllTasksChecked

    if ($allTasksCompleted -or $Force) {
        # Marquer la phase comme terminée
        $phasePattern = "(?m)^- \[ \] \*\*Phase \d+: $([regex]::Escape($PhaseTitle))\*\*"
        $phaseReplacement = "- [x] **Phase $(($PhaseTitle -split ":")[0])**: $PhaseTitle"
        $newContent = [regex]::Replace($content, $phasePattern, $phaseReplacement)

        if ($newContent -ne $content) {
            $newContent | Set-Content -Path $RoadmapConfig.RoadmapPath -Encoding UTF8

            # Journaliser la modification
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] Phase marquée comme terminée: $PhaseTitle`n"
            Add-Content -Path $RoadmapConfig.UpdateLogPath -Value $logEntry

            # Mettre à jour les cases à cocher
            Update-RoadmapCheckboxes

            return $true
        }
    }
    else {
        Write-Warning "Toutes les tâches ne sont pas terminées. Utilisez -Force pour marquer la phase comme terminée quand même."
    }

    return $false
}

# Fonction pour mettre à jour la roadmap
function Update-Roadmap {
    param ()

    # Initialiser le module
    Initialize-RoadmapUpdater

    # Mettre à jour les cases à cocher
    $changes = Update-RoadmapCheckboxes

    if ($changes) {
        Write-Host "$($changes.Count) modifications apportées à la roadmap:"
        $changes | ForEach-Object { Write-Host "- $_" }
    }
    else {
        Write-Host "Aucune modification nécessaire."
    }

    return $changes
}

# Exporter les fonctions
# Note: Export-ModuleMember est commenté car ce script n'est pas un module formel
# Export-ModuleMember -Function Initialize-RoadmapUpdater, Update-Roadmap, Set-TaskCompleted, Set-PhaseCompleted

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "Exécution du script terminée."
}
