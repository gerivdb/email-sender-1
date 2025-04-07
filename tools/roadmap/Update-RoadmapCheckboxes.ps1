# Update-RoadmapCheckboxes.ps1
# Script pour mettre Ã  jour les cases Ã  cocher de la roadmap et analyser les phases terminÃ©es

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
$roadmapPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "roadmap_perso.md"
$journalPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "journal\journal.md"
$updateMarkdownPath = Join-Path -Path $scriptPath -ChildPath "Update-Markdown.ps1"
$updateStructurePath = Join-Path -Path $scriptPath -ChildPath "Update-RoadmapStructure.ps1"
$analyzePhaseCompletionPath = Join-Path -Path $scriptPath -ChildPath "Analyze-PhaseCompletion.ps1"

# VÃ©rifier si les fichiers nÃ©cessaires existent
if (-not (Test-Path -Path $roadmapPath)) {
    Write-Error "Fichier roadmap non trouvÃ©: $roadmapPath"
    exit 1
}

if (-not (Test-Path -Path $updateMarkdownPath)) {
    Write-Error "Script Update-Markdown.ps1 non trouvÃ©: $updateMarkdownPath"
    exit 1
}

if (-not (Test-Path -Path $updateStructurePath)) {
    Write-Error "Script Update-RoadmapStructure.ps1 non trouvÃ©: $updateStructurePath"
    exit 1
}

if (-not (Test-Path -Path $analyzePhaseCompletionPath)) {
    Write-Error "Script Analyze-PhaseCompletion.ps1 non trouvÃ©: $analyzePhaseCompletionPath"
    exit 1
}

# Fonction pour vÃ©rifier si une phase est terminÃ©e
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
        # DÃ©tecter la catÃ©gorie
        if ($line -match "^## (\d+)\. (.+)") {
            $categoryId = $matches[1]
            $inPhase = ($categoryId -eq $PhaseId)
            continue
        }
        
        # Si on n'est pas dans la phase recherchÃ©e, passer Ã  la ligne suivante
        if (-not $inPhase) {
            continue
        }
        
        # DÃ©tecter les tÃ¢ches
        if ($line -match "^- \[([ x])\] (.+?) \((.+?)\)") {
            $completed = ($matches[1] -eq "x")
            $totalTasks++
            
            if ($completed) {
                $completedTasks++
            }
        }
    }
    
    # VÃ©rifier si la phase est terminÃ©e
    $isCompleted = ($totalTasks -gt 0) -and ($completedTasks -eq $totalTasks)
    
    return @{
        IsCompleted = $isCompleted
        TotalTasks = $totalTasks
        CompletedTasks = $completedTasks
    }
}

# Fonction pour mettre Ã  jour une tÃ¢che
function Update-Task {
    param (
        [string]$TaskId,
        [switch]$Complete,
        [switch]$Start,
        [string]$Note
    )
    
    # Construire les paramÃ¨tres pour Update-Markdown.ps1
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
    
    # ExÃ©cuter Update-Markdown.ps1
    & $updateMarkdownPath @params
    
    # VÃ©rifier si la tÃ¢che fait partie d'une phase
    if ($TaskId -match "^(\d+)\.") {
        $phaseId = $matches[1]
        $phaseCompletion = Test-PhaseCompletion -PhaseId $phaseId
        
        if ($phaseCompletion.IsCompleted) {
            Write-Output "La phase $phaseId est terminÃ©e ($($phaseCompletion.CompletedTasks)/$($phaseCompletion.TotalTasks) tÃ¢ches terminÃ©es)."
            
            # Analyser la phase terminÃ©e
            & $analyzePhaseCompletionPath -PhaseId $phaseId -RoadmapPath $roadmapPath -JournalPath $journalPath
        }
    }
}

# Fonction pour mettre Ã  jour la structure de la roadmap
function Update-Structure {
    # ExÃ©cuter Update-RoadmapStructure.ps1
    & $updateStructurePath -RoadmapPath $roadmapPath
}

# Fonction pour analyser une phase
function Analyze-Phase {
    param (
        [string]$PhaseId
    )
    
    # ExÃ©cuter Analyze-PhaseCompletion.ps1
    & $analyzePhaseCompletionPath -PhaseId $PhaseId -RoadmapPath $roadmapPath -JournalPath $journalPath
}

# Fonction principale
function Main {
    # Mettre Ã  jour la structure si demandÃ©
    if ($UpdateStructure) {
        Update-Structure
        return
    }
    
    # Analyser une phase si demandÃ©
    if ($AnalyzePhase -and $PhaseId) {
        Analyze-Phase -PhaseId $PhaseId
        return
    }
    
    # Mettre Ã  jour une tÃ¢che
    if ($TaskId) {
        Update-Task -TaskId $TaskId -Complete:$Complete -Start:$Start -Note $Note
        return
    }
}

# ExÃ©cuter la fonction principale
Main
