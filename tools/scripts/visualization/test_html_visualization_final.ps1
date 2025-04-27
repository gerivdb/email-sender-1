﻿# Script de test pour la fonction Export-CycleVisualizationHTML

# Charger la fonction
. "$PSScriptRoot\Export-CycleVisualizationHTML.ps1"

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

# Tester la fonction Export-CycleVisualizationHTML
$htmlPath = Export-CycleVisualizationHTML -CycleData $testData -OutputPath "$outputDir/test_html_final.html" -HighlightCycles -IncludeStatistics -OpenInBrowser
Write-Host "Visualisation HTML gÃ©nÃ©rÃ©e: $htmlPath"

Write-Host "Test terminÃ© avec succÃ¨s!"
