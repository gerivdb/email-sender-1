# Script de test pour le fichier Export-CycleVisualizationSimple.ps1

# Charger les fonctions
. "$PSScriptRoot\Export-CycleVisualizationSimple.ps1"

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

# Tester la fonction Export-CycleVisualizationHTML
$htmlPath = Export-CycleVisualizationHTML -CycleData $testData -OutputPath "$outputDir/test_html_simple.html" -HighlightCycles -IncludeStatistics -OpenInBrowser
Write-Host "Visualisation HTML générée: $htmlPath"

# Tester la fonction Show-CycleGraph
Write-Host "Ouverture du graphe dans le navigateur..."
$browserPath = Show-CycleGraph -CycleData $testData -HighlightCycles -IncludeStatistics -OutputPath "$outputDir/test_browser_simple.html"
Write-Host "Graphe ouvert dans le navigateur: $browserPath"

Write-Host "Tests terminés avec succès!"
