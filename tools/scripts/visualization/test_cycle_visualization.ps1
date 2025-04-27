# Script de test pour le module CycleVisualization

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules/CycleVisualization.psm1"
Import-Module $modulePath -Force

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

# Tester les diffÃ©rents formats
$outputDir = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Tester le format HTML
$htmlPath = Export-CycleVisualization -CycleData $testData -Format "HTML" -OutputPath "$outputDir/test_html.html" -HighlightCycles -IncludeStatistics
Write-Host "Visualisation HTML gÃ©nÃ©rÃ©e: $htmlPath"

# Tester le format DOT
$dotPath = Export-CycleVisualization -CycleData $testData -Format "DOT" -OutputPath "$outputDir/test_dot.dot" -HighlightCycles -IncludeStatistics
Write-Host "Fichier DOT gÃ©nÃ©rÃ©: $dotPath"

# Tester le format JSON
$jsonPath = Export-CycleVisualization -CycleData $testData -Format "JSON" -OutputPath "$outputDir/test_json.json" -HighlightCycles -IncludeStatistics
Write-Host "Fichier JSON gÃ©nÃ©rÃ©: $jsonPath"

# Tester le format MERMAID
$mermaidPath = Export-CycleVisualization -CycleData $testData -Format "MERMAID" -OutputPath "$outputDir/test_mermaid.md" -HighlightCycles -IncludeStatistics
Write-Host "Diagramme Mermaid gÃ©nÃ©rÃ©: $mermaidPath"

# Tester la fonction Show-CycleGraph
Write-Host "Ouverture du graphe dans le navigateur..."
Show-CycleGraph -CycleData $testData -HighlightCycles -IncludeStatistics -OutputPath "$outputDir/test_browser.html"

Write-Host "Tests terminÃ©s avec succÃ¨s!"
