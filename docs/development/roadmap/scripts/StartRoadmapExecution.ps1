# Script d'exécution de la roadmap
# Ce script exécute les tâches de la roadmap

param (
    [string]$RoadmapPath = "Roadmap\roadmap_perso.md",
    [switch]$AutoExecute,
    [switch]$AutoUpdate
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
        "INFO" { Write-Host $logEntry -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        default { Write-Host $logEntry }
    }
}

# Fonction pour lire et analyser la roadmap
function Get-RoadmapContent {
    param (
        [string]$Path
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        Write-Log -Message "Le fichier roadmap n'existe pas: $Path" -Level "ERROR"
        return $null
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $Path -Raw
    
    # Structure pour stocker les données de la roadmap
    $roadmap = @{
        Title    = ""
        Content  = $content
        Lines    = @()
        Sections = @()
    }
    
    # Extraire le titre
    if ($content -match "^# (.+)$") {
        $roadmap.Title = $Matches[1]
    }
    
    # Analyser les sections, phases et tâches
    $lines = $content -split "`n"
    $roadmap.Lines = $lines
    
    $currentSection = $null
    $currentPhase = $null
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Détecter une section
        if ($line -match "^## (\d+)\. (.+)$") {
            $sectionId = $Matches[1]
            $sectionTitle = $Matches[2]
            
            $currentSection = @{
                Id             = $sectionId
                Title          = $sectionTitle
                LineNumber     = $i
                Phases         = @()
                TotalPhases    = 0
                CompletedPhases = 0
                Progress       = 0
            }
            
            $roadmap.Sections += $currentSection
            $currentPhase = $null
        }
        
        # Détecter une phase
        elseif ($line -match "^  - \[([ x])\] \*\*Phase (\d+): (.+)\*\*$" -and $null -ne $currentSection) {
            $isCompleted = $Matches[1] -eq "x"
            $phaseId = $Matches[2]
            $phaseTitle = $Matches[3]
            
            $currentPhase = @{
                Id             = $phaseId
                Title          = $phaseTitle
                LineNumber     = $i
                IsCompleted    = $isCompleted
                Tasks          = @()
                TotalTasks     = 0
                CompletedTasks = 0
                Progress       = 0
            }
            
            $currentSection.Phases += $currentPhase
        }
        
        # Détecter une tâche
        elseif ($line -match "^    - \[([ x])\] (.+)$" -and $null -ne $currentPhase) {
            $isCompleted = $Matches[1] -eq "x"
            $taskTitle = $Matches[2]
            
            $task = @{
                Title       = $taskTitle
                LineNumber  = $i
                IsCompleted = $isCompleted
                Subtasks    = @()
            }
            
            $currentPhase.Tasks += $task
        }
    }
    
    # Calculer les statistiques
    foreach ($section in $roadmap.Sections) {
        $section.TotalPhases = $section.Phases.Count
        $section.CompletedPhases = ($section.Phases | Where-Object { $_.IsCompleted }).Count
        
        if ($section.TotalPhases -gt 0) {
            $section.Progress = [math]::Round(($section.CompletedPhases / $section.TotalPhases) * 100)
        }
        
        foreach ($phase in $section.Phases) {
            $phase.TotalTasks = $phase.Tasks.Count
            $phase.CompletedTasks = ($phase.Tasks | Where-Object { $_.IsCompleted }).Count
            
            if ($phase.TotalTasks -gt 0) {
                $phase.Progress = [math]::Round(($phase.CompletedTasks / $phase.TotalTasks) * 100)
            }
        }
    }
    
    return $roadmap
}

# Fonction pour exécuter une tâche
function Invoke-RoadmapTask {
    param (
        [hashtable]$Task,
        [hashtable]$Phase,
        [hashtable]$Section
    )
    
    Write-Log -Message "Exécution de la tâche: $($Task.Title)" -Level "INFO"
    Write-Log -Message "  Section: $($Section.Id). $($Section.Title)" -Level "INFO"
    Write-Log -Message "  Phase: Phase $($Phase.Id): $($Phase.Title)" -Level "INFO"
    
    # Simuler l'exécution de la tâche
    Start-Sleep -Seconds 1
    
    Write-Log -Message "Tâche exécutée avec succès." -Level "SUCCESS"
    
    return $true
}

# Fonction principale
function Main {
    Write-Log -Message "Démarrage de l'exécution de la roadmap: $RoadmapPath" -Level "INFO"
    
    # Lire et analyser la roadmap
    $roadmap = Get-RoadmapContent -Path $RoadmapPath
    
    if ($null -eq $roadmap) {
        Write-Log -Message "Impossible d'analyser la roadmap." -Level "ERROR"
        exit 1
    }
    
    Write-Log -Message "Roadmap analysée: $($roadmap.Title)" -Level "SUCCESS"
    
    # Afficher les statistiques
    Write-Log -Message "Statistiques de la roadmap:" -Level "INFO"
    Write-Log -Message "  Sections: $($roadmap.Sections.Count)" -Level "INFO"
    
    $totalPhases = 0
    $completedPhases = 0
    $totalTasks = 0
    $completedTasks = 0
    
    foreach ($section in $roadmap.Sections) {
        $totalPhases += $section.TotalPhases
        $completedPhases += $section.CompletedPhases
        
        foreach ($phase in $section.Phases) {
            $totalTasks += $phase.TotalTasks
            $completedTasks += $phase.CompletedTasks
        }
    }
    
    Write-Log -Message "  Phases: $completedPhases / $totalPhases ($([math]::Round(($completedPhases / $totalPhases) * 100))%)" -Level "INFO"
    Write-Log -Message "  Tâches: $completedTasks / $totalTasks ($([math]::Round(($completedTasks / $totalTasks) * 100))%)" -Level "INFO"
    
    # Exécuter les tâches non complétées
    if ($AutoExecute) {
        Write-Log -Message "Exécution automatique des tâches non complétées..." -Level "INFO"
        
        $tasksExecuted = 0
        
        foreach ($section in $roadmap.Sections) {
            foreach ($phase in $section.Phases) {
                foreach ($task in $phase.Tasks) {
                    if (-not $task.IsCompleted) {
                        $success = Invoke-RoadmapTask -Task $task -Phase $phase -Section $section
                        
                        if ($success) {
                            $tasksExecuted++
                        }
                    }
                }
            }
        }
        
        Write-Log -Message "Exécution terminée. Tâches exécutées: $tasksExecuted" -Level "SUCCESS"
        
        # Mettre à jour la roadmap si demandé
        if ($AutoUpdate) {
            Write-Log -Message "Mise à jour de la roadmap..." -Level "INFO"
            
            # Appeler RoadmapGitUpdater.ps1 pour mettre à jour la roadmap
            & "$PSScriptRoot\RoadmapGitUpdater.ps1" -RoadmapPath $RoadmapPath -AutoUpdate -GenerateReport
            
            Write-Log -Message "Mise à jour terminée." -Level "SUCCESS"
        }
    }
    else {
        Write-Log -Message "Mode d'exécution manuelle. Utilisez -AutoExecute pour exécuter automatiquement les tâches." -Level "INFO"
    }
    
    Write-Log -Message "Exécution de la roadmap terminée." -Level "SUCCESS"
}

# Exécuter la fonction principale
Main
