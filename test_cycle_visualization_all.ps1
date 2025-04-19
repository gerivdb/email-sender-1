# Script de test pour le module CycleVisualization

# Importer le module
Import-Module "$PSScriptRoot\modules\CycleVisualization.ps1" -Force

# Créer des données de test pour simuler un graphe de dépendances
$testData = [PSCustomObject]@{
    DependencyGraph = @{
        "ScriptA" = @("ScriptB", "ScriptC")
        "ScriptB" = @("ScriptD")
        "ScriptC" = @("ScriptE")
        "ScriptD" = @("ScriptF")
        "ScriptE" = @("ScriptA")  # Crée un cycle: ScriptA -> ScriptC -> ScriptE -> ScriptA
        "ScriptF" = @()
    }
    HasCycles = $true
    Cycles = @("ScriptA", "ScriptC", "ScriptE")
    NonCyclicScripts = @("ScriptB", "ScriptD", "ScriptF")
}

# Créer le répertoire de sortie s'il n'existe pas
$outputDir = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Tester les différents formats
Write-Host "Test de tous les formats de visualisation..."

# Tester le format HTML
$htmlPath = Export-CycleVisualization -CycleData $testData -Format "HTML" -OutputPath "$outputDir/test_html.html" -HighlightCycles -IncludeStatistics
Write-Host "Visualisation HTML générée: $htmlPath"

# Tester le format DOT
$dotPath = Export-CycleVisualization -CycleData $testData -Format "DOT" -OutputPath "$outputDir/test_dot.dot" -HighlightCycles -IncludeStatistics
Write-Host "Fichier DOT généré: $dotPath"

# Tester le format JSON
$jsonPath = Export-CycleVisualization -CycleData $testData -Format "JSON" -OutputPath "$outputDir/test_json.json" -HighlightCycles -IncludeStatistics
Write-Host "Fichier JSON généré: $jsonPath"

# Tester le format MERMAID
$mermaidPath = Export-CycleVisualization -CycleData $testData -Format "MERMAID" -OutputPath "$outputDir/test_mermaid.md" -HighlightCycles -IncludeStatistics
Write-Host "Diagramme Mermaid généré: $mermaidPath"

# Tester la fonction Show-CycleGraph
Write-Host "Ouverture du graphe dans le navigateur..."
$browserPath = Show-CycleGraph -CycleData $testData -HighlightCycles -IncludeStatistics -OutputPath "$outputDir/test_browser.html"
Write-Host "Graphe ouvert dans le navigateur: $browserPath"

Write-Host "Tests terminés avec succès!"
