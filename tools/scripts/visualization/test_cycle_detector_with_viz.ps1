# Script de test pour le module CycleDetector.psm1 avec CycleViz.psm1

# Importer le module
Import-Module "$PSScriptRoot\modules\CycleDetector.psm1" -Force

# CrÃ©er des donnÃ©es de test pour simuler un graphe de dÃ©pendances
$testData = [PSCustomObject]@{
    DependencyGraph = @{
        "ScriptA" = @("ScriptB", "ScriptC")
        "ScriptB" = @("ScriptD")
        "ScriptC" = @("ScriptE")
        "ScriptD" = @("ScriptF")
        "ScriptE" = @("ScriptA")  # CrÃ©e un cycle: ScriptA -> ScriptC -> ScriptE -> ScriptA
        "ScriptF" = @()
    }
    HasCycles = $true
    Cycles = @("ScriptA", "ScriptC", "ScriptE")
    NonCyclicScripts = @("ScriptB", "ScriptD", "ScriptF")
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
$outputDir = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Tester la fonction Export-CycleVisualization
$htmlPath = Export-CycleVisualization -CycleData $testData -OutputPath "$outputDir/test_detector_viz.html" -HighlightCycles -IncludeStatistics -OpenInBrowser
Write-Host "Visualisation HTML gÃ©nÃ©rÃ©e: $htmlPath"

# Tester la fonction Show-CycleGraph
Write-Host "Ouverture du graphe dans le navigateur..."
$browserPath = Show-CycleGraph -CycleData $testData -HighlightCycles -IncludeStatistics -OutputPath "$outputDir/test_detector_browser.html"
Write-Host "Graphe ouvert dans le navigateur: $browserPath"

Write-Host "Tests terminÃ©s avec succÃ¨s!"
