# Analyze-Phase.ps1
# Script simplifiÃ© pour analyser une phase terminÃ©e et mettre Ã  jour le journal

param (
    [Parameter(Mandatory = $true)]
    [string]$PhaseId
)

# Chemins des fichiers
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$analyzePhaseCompletionPath = Join-Path -Path $scriptPath -ChildPath "Analyze-PhaseCompletion.ps1"
$roadmapPath = "Roadmap\roadmap_perso.md"""
$journalPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "journal\journal.md"

# VÃ©rifier si le script Analyze-PhaseCompletion.ps1 existe
if (-not (Test-Path -Path $analyzePhaseCompletionPath)) {
    Write-Error "Script Analyze-PhaseCompletion.ps1 non trouvÃ©: $analyzePhaseCompletionPath"
    exit 1
}

# ExÃ©cuter le script Analyze-PhaseCompletion.ps1
& $analyzePhaseCompletionPath -PhaseId $PhaseId -RoadmapPath $roadmapPath -JournalPath $journalPath
