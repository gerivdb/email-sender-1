#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour vÃ©rifier l'intÃ©gration avec des outils d'analyse tiers.
.DESCRIPTION
    Ce script teste l'intÃ©gration avec des outils d'analyse tiers en exÃ©cutant
    une analyse sur un fichier de test, puis en convertissant les rÃ©sultats
    vers diffÃ©rents formats et en vÃ©rifiant que les fichiers de sortie sont gÃ©nÃ©rÃ©s.
#>

[CmdletBinding()]
param ()

# DÃ©finir les chemins des scripts Ã  tester
$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$startCodeAnalysisPath = Join-Path -Path $scriptRoot -ChildPath "Start-CodeAnalysis.ps1"
$integrateThirdPartyToolsPath = Join-Path -Path $scriptRoot -ChildPath "Integrate-ThirdPartyTools.ps1"
$fixHtmlReportEncodingPath = Join-Path -Path $scriptRoot -ChildPath "Fix-HtmlReportEncoding.ps1"

# VÃ©rifier que les scripts existent
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

# CrÃ©er un fichier PowerShell de test avec des erreurs connues
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

# Ã‰crire le contenu du fichier de test
Set-Content -Path $testScriptPath -Value $testScriptContent -Force
Write-Host "Fichier de test crÃ©Ã©: '$testScriptPath'" -ForegroundColor Green

# ExÃ©cuter l'analyse de code
$resultsDir = Join-Path -Path $PSScriptRoot -ChildPath "results"
if (-not (Test-Path -Path $resultsDir -PathType Container)) {
    New-Item -Path $resultsDir -ItemType Directory -Force | Out-Null
}

$outputPath = Join-Path -Path $resultsDir -ChildPath "test-analysis-results.json"
$htmlPath = Join-Path -Path $resultsDir -ChildPath "test-analysis-results.html"

Write-Host "ExÃ©cution de l'analyse de code..." -ForegroundColor Cyan
& $startCodeAnalysisPath -Path $testScriptPath -Tools PSScriptAnalyzer, TodoAnalyzer -OutputPath $outputPath -GenerateHtmlReport

# VÃ©rifier que les fichiers de sortie ont Ã©tÃ© gÃ©nÃ©rÃ©s
if (Test-Path -Path $outputPath -PathType Leaf) {
    Write-Host "Fichier de rÃ©sultats JSON gÃ©nÃ©rÃ©: '$outputPath'" -ForegroundColor Green
} else {
    Write-Error "Le fichier de rÃ©sultats JSON n'a pas Ã©tÃ© gÃ©nÃ©rÃ©."
    return
}

if (Test-Path -Path $htmlPath -PathType Leaf) {
    Write-Host "Fichier de rapport HTML gÃ©nÃ©rÃ©: '$htmlPath'" -ForegroundColor Green
} else {
    Write-Error "Le fichier de rapport HTML n'a pas Ã©tÃ© gÃ©nÃ©rÃ©."
    return
}

# Corriger l'encodage du rapport HTML
Write-Host "Correction de l'encodage du rapport HTML..." -ForegroundColor Cyan
& $fixHtmlReportEncodingPath -Path $htmlPath

# IntÃ©grer les rÃ©sultats avec diffÃ©rents outils tiers
$formats = @("GitHub", "SonarQube", "AzureDevOps")
foreach ($format in $formats) {
    $formatOutputPath = Join-Path -Path $resultsDir -ChildPath "test-analysis-results-$format.json"
    
    Write-Host "Conversion des rÃ©sultats vers le format $format..." -ForegroundColor Cyan
    if ($format -eq "SonarQube") {
        & $integrateThirdPartyToolsPath -Path $outputPath -Tool $format -OutputPath $formatOutputPath -ProjectKey "test-project"
    } else {
        & $integrateThirdPartyToolsPath -Path $outputPath -Tool $format -OutputPath $formatOutputPath
    }
    
    # VÃ©rifier que le fichier de sortie a Ã©tÃ© gÃ©nÃ©rÃ©
    if (Test-Path -Path $formatOutputPath -PathType Leaf) {
        Write-Host "Fichier de rÃ©sultats $format gÃ©nÃ©rÃ©: '$formatOutputPath'" -ForegroundColor Green
    } else {
        Write-Error "Le fichier de rÃ©sultats $format n'a pas Ã©tÃ© gÃ©nÃ©rÃ©."
    }
}

Write-Host "`nTests d'intÃ©gration terminÃ©s avec succÃ¨s!" -ForegroundColor Green
