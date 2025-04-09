# Update-RoadmapCheckboxes.ps1
# Script pour mettre à jour les cases à cocher de la roadmap et analyser les phases terminées

param (
    [Parameter(Mandatory = $false)]
    [string]$TaskId,
    
    [Parameter(Mandatory = $false)]
    [string]$PhaseId,
    
    [Parameter(Mandatory = $false)]
    [switch]$Complete,
    
    [Parameter(Mandatory = $false)]
    [switch]$Start,
    
    [Parameter(Mandatory = $false)]
    [string]$Note,
    
    [Parameter(Mandatory = $false)]
    [switch]$AnalyzePhase,
    
    [Parameter(Mandatory = $false)]
    [switch]$UpdateStructure
)

# Chemins des fichiers
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$roadmapPath = "Roadmap\roadmap_perso.md"""
$journalPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "journal\journal.md"
$updateMarkdownPath = Join-Path -Path $scriptPath -ChildPath "Update-Markdown.ps1"
$updateStructurePath = Join-Path -Path $scriptPath -ChildPath "Update-RoadmapStructure.ps1"
$analyzePhaseCompletionPath = Join-Path -Path $scriptPath -ChildPath "Analyze-PhaseCompletion.ps1"

# Vérifier si les fichiers nécessaires existent
if (-not (Test-Path -Path $roadmapPath)) {
    Write-Error "Fichier roadmap non trouvé: $roadmapPath"
    exit 1
}

if (-not (Test-Path -Path $updateMarkdownPath)) {
    Write-Error "Script Update-Markdown.ps1 non trouvé: $updateMarkdownPath"
    exit 1
}

if (-not (Test-Path -Path $updateStructurePath)) {
    Write-Error "Script Update-RoadmapStructure.ps1 non trouvé: $updateStructurePath"
    exit 1
}

if (-not (Test-Path -Path $analyzePhaseCompletionPath)) {
    Write-Error "Script Analyze-PhaseCompletion.ps1 non trouvé: $analyzePhaseCompletionPath"
    exit 1
}

# Fonction pour vérifier si une phase est terminée
function Test-PhaseCompletion {
    param (
        [string]$PhaseId
    )
    
    # Lire le contenu de la roadmap
    $content = Get-Content -Path $roadmapPath -Raw
    
    # Extraire les informations de la phase
    $lines = $content -split "`n"
    $inPhase = $false
    $totalTasks = 0
    $completedTasks = 0
    
    foreach ($line in $lines) {
        # Détecter la catégorie
        if ($line -match "^## (\d+)\. (.+)") {
            $categoryId = $matches[1]
            $inPhase = ($categoryId -eq $PhaseId)
            continue
        }
        
        # Si on n'est pas dans la phase recherchée, passer à la ligne suivante
        if (-not $inPhase) {
            continue
        }
        
        # Détecter les tâches
        if ($line -match "^- \[([ x])\] (.+?) \((.+?)\)") {
            $completed = ($matches[1] -eq "x")
            $totalTasks++
            
            if ($completed) {
                $completedTasks++
            }
        }
    }
    
    # Vérifier si la phase est terminée
    $isCompleted = ($totalTasks -gt 0) -and ($completedTasks -eq $totalTasks)
    
    return @{
        IsCompleted = $isCompleted
        TotalTasks = $totalTasks
        CompletedTasks = $completedTasks
    }
}

# Fonction pour mettre à jour une tâche
function Update-Task {
    param (
        [string]$TaskId,
        [switch]$Complete,
        [switch]$Start,
        [string]$Note
    )
    
    # Construire les paramètres pour Update-Markdown.ps1
    $params = @()
    
    if ($TaskId) {
        $params += "-TaskId"
        $params += $TaskId
    }
    
    if ($Complete) {
        $params += "-Complete"
    }
    
    if ($Start) {
        $params += "-Start"
    }
    
    if ($Note) {
        $params += "-Note"
        $params += $Note
    }
    
    # Exécuter Update-Markdown.ps1
    & $updateMarkdownPath @params
    
    # Vérifier si la tâche fait partie d'une phase
    if ($TaskId -match "^(\d+)\.") {
        $phaseId = $matches[1]
        $phaseCompletion = Test-PhaseCompletion -PhaseId $phaseId
        
        if ($phaseCompletion.IsCompleted) {
            Write-Output "La phase $phaseId est terminée ($($phaseCompletion.CompletedTasks)/$($phaseCompletion.TotalTasks) tâches terminées)."
            
            # Analyser la phase terminée
            & $analyzePhaseCompletionPath -PhaseId $phaseId -RoadmapPath $roadmapPath -JournalPath $journalPath
        }
    }
}

# Fonction pour mettre à jour la structure de la roadmap
function Update-Structure {
    # Exécuter Update-RoadmapStructure.ps1
    & $updateStructurePath -RoadmapPath $roadmapPath
}

# Fonction pour analyser une phase
function Analyze-Phase {
    param (
        [string]$PhaseId
    )
    
    # Exécuter Analyze-PhaseCompletion.ps1
    & $analyzePhaseCompletionPath -PhaseId $PhaseId -RoadmapPath $roadmapPath -JournalPath $journalPath
}

# Fonction principale
function Main {
    # Mettre à jour la structure si demandé
    if ($UpdateStructure) {
        Update-Structure
        return
    }
    
    # Analyser une phase si demandé
    if ($AnalyzePhase -and $PhaseId) {
        Analyze-Phase -PhaseId $PhaseId
        return
    }
    
    # Mettre à jour une tâche
    if ($TaskId) {
        Update-Task -TaskId $TaskId -Complete:$Complete -Start:$Start -Note $Note
        return
    }
}

# Exécuter la fonction principale
Main
