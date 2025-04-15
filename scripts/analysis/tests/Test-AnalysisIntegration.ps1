#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour vérifier l'intégration avec des outils d'analyse tiers.
.DESCRIPTION
    Ce script teste l'intégration avec des outils d'analyse tiers en exécutant
    une analyse sur un fichier de test, puis en convertissant les résultats
    vers différents formats et en vérifiant que les fichiers de sortie sont générés.
#>

[CmdletBinding()]
param ()

# Définir les chemins des scripts à tester
$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$startCodeAnalysisPath = Join-Path -Path $scriptRoot -ChildPath "Start-CodeAnalysis.ps1"
$integrateThirdPartyToolsPath = Join-Path -Path $scriptRoot -ChildPath "Integrate-ThirdPartyTools.ps1"
$fixHtmlReportEncodingPath = Join-Path -Path $scriptRoot -ChildPath "Fix-HtmlReportEncoding.ps1"

# Vérifier que les scripts existent
$scriptsToCheck = @(
    $startCodeAnalysisPath,
    $integrateThirdPartyToolsPath,
    $fixHtmlReportEncodingPath
)

foreach ($script in $scriptsToCheck) {
    if (-not (Test-Path -Path $script -PathType Leaf)) {
        Write-Error "Le script '$script' n'existe pas."
        return
    }
}

# Créer un fichier PowerShell de test avec des erreurs connues
$testScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "test_script.ps1"
$testScriptContent = @'
# Test script with known issues
function Test-Function {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Parameter
    )
    
    # TODO: Add more robust error handling
    
    # This line has trailing whitespace    
    
    # FIXME: Fix performance issue
    
    Write-Host "This is a test message"
    
    # HACK: Temporary workaround for bug #123
    
    # NOTE: This function could be improved
}

# Missing BOM encoding
'@

# Écrire le contenu du fichier de test
Set-Content -Path $testScriptPath -Value $testScriptContent -Force
Write-Host "Fichier de test créé: '$testScriptPath'" -ForegroundColor Green

# Exécuter l'analyse de code
$resultsDir = Join-Path -Path $PSScriptRoot -ChildPath "results"
if (-not (Test-Path -Path $resultsDir -PathType Container)) {
    New-Item -Path $resultsDir -ItemType Directory -Force | Out-Null
}

$outputPath = Join-Path -Path $resultsDir -ChildPath "test-analysis-results.json"
$htmlPath = Join-Path -Path $resultsDir -ChildPath "test-analysis-results.html"

Write-Host "Exécution de l'analyse de code..." -ForegroundColor Cyan
& $startCodeAnalysisPath -Path $testScriptPath -Tools PSScriptAnalyzer, TodoAnalyzer -OutputPath $outputPath -GenerateHtmlReport

# Vérifier que les fichiers de sortie ont été générés
if (Test-Path -Path $outputPath -PathType Leaf) {
    Write-Host "Fichier de résultats JSON généré: '$outputPath'" -ForegroundColor Green
} else {
    Write-Error "Le fichier de résultats JSON n'a pas été généré."
    return
}

if (Test-Path -Path $htmlPath -PathType Leaf) {
    Write-Host "Fichier de rapport HTML généré: '$htmlPath'" -ForegroundColor Green
} else {
    Write-Error "Le fichier de rapport HTML n'a pas été généré."
    return
}

# Corriger l'encodage du rapport HTML
Write-Host "Correction de l'encodage du rapport HTML..." -ForegroundColor Cyan
& $fixHtmlReportEncodingPath -Path $htmlPath

# Intégrer les résultats avec différents outils tiers
$formats = @("GitHub", "SonarQube", "AzureDevOps")
foreach ($format in $formats) {
    $formatOutputPath = Join-Path -Path $resultsDir -ChildPath "test-analysis-results-$format.json"
    
    Write-Host "Conversion des résultats vers le format $format..." -ForegroundColor Cyan
    if ($format -eq "SonarQube") {
        & $integrateThirdPartyToolsPath -Path $outputPath -Tool $format -OutputPath $formatOutputPath -ProjectKey "test-project"
    } else {
        & $integrateThirdPartyToolsPath -Path $outputPath -Tool $format -OutputPath $formatOutputPath
    }
    
    # Vérifier que le fichier de sortie a été généré
    if (Test-Path -Path $formatOutputPath -PathType Leaf) {
        Write-Host "Fichier de résultats $format généré: '$formatOutputPath'" -ForegroundColor Green
    } else {
        Write-Error "Le fichier de résultats $format n'a pas été généré."
    }
}

Write-Host "`nTests d'intégration terminés avec succès!" -ForegroundColor Green
