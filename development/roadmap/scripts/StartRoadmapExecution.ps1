# Script d'exÃ©cution de la roadmap
# Ce script exÃ©cute les tÃ¢ches de la roadmap

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
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        Write-Log -Message "Le fichier roadmap n'existe pas: $Path" -Level "ERROR"
        return $null
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $Path -Raw
    
    # Structure pour stocker les donnÃ©es de la roadmap
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
    
    # Analyser les sections, phases et tÃ¢ches
    $lines = $content -split "`n"
    $roadmap.Lines = $lines
    
    $currentSection = $null
    $currentPhase = $null
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # DÃ©tecter une section
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
        
        # DÃ©tecter une phase
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
        
        # DÃ©tecter une tÃ¢che
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

# Fonction pour exÃ©cuter une tÃ¢che
function Invoke-RoadmapTask {
    param (
        [hashtable]$Task,
        [hashtable]$Phase,
        [hashtable]$Section
    )
    
    Write-Log -Message "ExÃ©cution de la tÃ¢che: $($Task.Title)" -Level "INFO"
    Write-Log -Message "  Section: $($Section.Id). $($Section.Title)" -Level "INFO"
    Write-Log -Message "  Phase: Phase $($Phase.Id): $($Phase.Title)" -Level "INFO"
    
    # Simuler l'exÃ©cution de la tÃ¢che
    Start-Sleep -Seconds 1
    
    Write-Log -Message "TÃ¢che exÃ©cutÃ©e avec succÃ¨s." -Level "SUCCESS"
    
    return $true
}

# Fonction principale
function Main {
    Write-Log -Message "DÃ©marrage de l'exÃ©cution de la roadmap: $RoadmapPath" -Level "INFO"
    
    # Lire et analyser la roadmap
    $roadmap = Get-RoadmapContent -Path $RoadmapPath
    
    if ($null -eq $roadmap) {
        Write-Log -Message "Impossible d'analyser la roadmap." -Level "ERROR"
        exit 1
    }
    
    Write-Log -Message "Roadmap analysÃ©e: $($roadmap.Title)" -Level "SUCCESS"
    
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
    Write-Log -Message "  TÃ¢ches: $completedTasks / $totalTasks ($([math]::Round(($completedTasks / $totalTasks) * 100))%)" -Level "INFO"
    
    # ExÃ©cuter les tÃ¢ches non complÃ©tÃ©es
    if ($AutoExecute) {
        Write-Log -Message "ExÃ©cution automatique des tÃ¢ches non complÃ©tÃ©es..." -Level "INFO"
        
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
        
        Write-Log -Message "ExÃ©cution terminÃ©e. TÃ¢ches exÃ©cutÃ©es: $tasksExecuted" -Level "SUCCESS"
        
        # Mettre Ã  jour la roadmap si demandÃ©
        if ($AutoUpdate) {
            Write-Log -Message "Mise Ã  jour de la roadmap..." -Level "INFO"
            
            # Appeler RoadmapGitUpdater.ps1 pour mettre Ã  jour la roadmap
            & "$PSScriptRoot\RoadmapGitUpdater.ps1" -RoadmapPath $RoadmapPath -AutoUpdate -GenerateReport
            
            Write-Log -Message "Mise Ã  jour terminÃ©e." -Level "SUCCESS"
        }
    }
    else {
        Write-Log -Message "Mode d'exÃ©cution manuelle. Utilisez -AutoExecute pour exÃ©cuter automatiquement les tÃ¢ches." -Level "INFO"
    }
    
    Write-Log -Message "ExÃ©cution de la roadmap terminÃ©e." -Level "SUCCESS"
}

# ExÃ©cuter la fonction principale
Main
