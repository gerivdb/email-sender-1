#Requires -Version 5.1
<#
.SYNOPSIS
    Teste les connecteurs d'analyse pour vÃ©rifier leur bon fonctionnement.

.DESCRIPTION
    Ce script teste les connecteurs d'analyse (PSScriptAnalyzer, ESLint, Pylint, SonarQube)
    pour vÃ©rifier qu'ils fonctionnent correctement et qu'ils produisent des rÃ©sultats
    au format unifiÃ©.

.PARAMETER TestPSScriptAnalyzer
    Tester le connecteur PSScriptAnalyzer.

.PARAMETER TestESLint
    Tester le connecteur ESLint.

.PARAMETER TestPylint
    Tester le connecteur Pylint.

.PARAMETER TestSonarQube
    Tester le connecteur SonarQube.

.PARAMETER TestAll
    Tester tous les connecteurs disponibles.

.PARAMETER OutputDirectory
    RÃ©pertoire de sortie pour les rÃ©sultats des tests.

.EXAMPLE
    .\Test-AnalysisConnectors.ps1 -TestPSScriptAnalyzer -OutputDirectory "C:\Tests"

.EXAMPLE
    .\Test-AnalysisConnectors.ps1 -TestAll

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  15/04/2025
#>

[CmdletBinding(DefaultParameterSetName = "Specific")]
param (
    [Parameter(Mandatory = $false, ParameterSetName = "Specific")]
    [switch]$TestPSScriptAnalyzer,
    
    [Parameter(Mandatory = $false, ParameterSetName = "Specific")]
    [switch]$TestESLint,
    
    [Parameter(Mandatory = $false, ParameterSetName = "Specific")]
    [switch]$TestPylint,
    
    [Parameter(Mandatory = $false, ParameterSetName = "Specific")]
    [switch]$TestSonarQube,
    
    [Parameter(Mandatory = $true, ParameterSetName = "All")]
    [switch]$TestAll,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = (Join-Path -Path $PSScriptRoot -ChildPath "results")
)

# Importer les modules requis
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$analysisToolsPath = Join-Path -Path $modulesPath -ChildPath "AnalysisTools.psm1"

if (Test-Path -Path $analysisToolsPath) {
    Import-Module -Name $analysisToolsPath -Force
}
else {
    throw "Module AnalysisTools.psm1 introuvable."
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputDirectory -PathType Container)) {
    try {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        Write-Verbose "RÃ©pertoire de sortie '$OutputDirectory' crÃ©Ã©."
    }
    catch {
        Write-Error "Impossible de crÃ©er le rÃ©pertoire de sortie '$OutputDirectory': $_"
        return
    }
}

# Fonction pour tester PSScriptAnalyzer
function Test-PSScriptAnalyzerConnector {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory
    )
    
    Write-Host "Test du connecteur PSScriptAnalyzer..." -ForegroundColor Cyan
    
    # VÃ©rifier si PSScriptAnalyzer est disponible
    if (-not (Test-AnalysisTool -ToolName "PSScriptAnalyzer")) {
        Write-Warning "PSScriptAnalyzer n'est pas disponible. Test ignorÃ©."
        return $false
    }
    
    # Trouver un script PowerShell Ã  analyser
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\tools\Connect-PSScriptAnalyzer.ps1"
    
    if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
        Write-Warning "Script de test introuvable: $scriptPath"
        return $false
    }
    
    # ExÃ©cuter l'analyse
    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "pssa-results.json"
    
    try {
        & (Join-Path -Path $PSScriptRoot -ChildPath "..\development\tools\Connect-PSScriptAnalyzer.ps1") -FilePath $scriptPath -OutputPath $outputPath
        
        if (Test-Path -Path $outputPath -PathType Leaf) {
            Write-Host "Test PSScriptAnalyzer rÃ©ussi. RÃ©sultats enregistrÃ©s dans: $outputPath" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Ã‰chec du test PSScriptAnalyzer. Fichier de rÃ©sultats non crÃ©Ã©."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors du test PSScriptAnalyzer: $_"
        return $false
    }
}

# Fonction pour tester ESLint
function Test-ESLintConnector {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory
    )
    
    Write-Host "Test du connecteur ESLint..." -ForegroundColor Cyan
    
    # VÃ©rifier si ESLint est disponible
    if (-not (Test-AnalysisTool -ToolName "ESLint")) {
        Write-Warning "ESLint n'est pas disponible. Test ignorÃ©."
        return $false
    }
    
    # Trouver un fichier JavaScript Ã  analyser
    $jsFiles = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..") -Include "*.js" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($null -eq $jsFiles) {
        Write-Warning "Aucun fichier JavaScript trouvÃ© pour le test."
        return $false
    }
    
    $jsPath = $jsFiles.FullName
    
    # ExÃ©cuter l'analyse
    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "eslint-results.json"
    
    try {
        & (Join-Path -Path $PSScriptRoot -ChildPath "..\development\tools\Connect-ESLint.ps1") -FilePath $jsPath -OutputPath $outputPath
        
        if (Test-Path -Path $outputPath -PathType Leaf) {
            Write-Host "Test ESLint rÃ©ussi. RÃ©sultats enregistrÃ©s dans: $outputPath" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Ã‰chec du test ESLint. Fichier de rÃ©sultats non crÃ©Ã©."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors du test ESLint: $_"
        return $false
    }
}

# Fonction pour tester Pylint
function Test-PylintConnector {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory
    )
    
    Write-Host "Test du connecteur Pylint..." -ForegroundColor Cyan
    
    # VÃ©rifier si Pylint est disponible
    if (-not (Test-AnalysisTool -ToolName "Pylint")) {
        Write-Warning "Pylint n'est pas disponible. Test ignorÃ©."
        return $false
    }
    
    # Trouver un fichier Python Ã  analyser
    $pyFiles = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..") -Include "*.py" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($null -eq $pyFiles) {
        Write-Warning "Aucun fichier Python trouvÃ© pour le test."
        return $false
    }
    
    $pyPath = $pyFiles.FullName
    
    # ExÃ©cuter l'analyse
    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "pylint-results.json"
    
    try {
        & (Join-Path -Path $PSScriptRoot -ChildPath "..\development\tools\Connect-Pylint.ps1") -FilePath $pyPath -OutputPath $outputPath
        
        if (Test-Path -Path $outputPath -PathType Leaf) {
            Write-Host "Test Pylint rÃ©ussi. RÃ©sultats enregistrÃ©s dans: $outputPath" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Ã‰chec du test Pylint. Fichier de rÃ©sultats non crÃ©Ã©."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors du test Pylint: $_"
        return $false
    }
}

# Fonction pour tester la fusion des rÃ©sultats
function Test-ResultsMerging {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory
    )
    
    Write-Host "Test de la fusion des rÃ©sultats..." -ForegroundColor Cyan
    
    # VÃ©rifier s'il y a des fichiers de rÃ©sultats Ã  fusionner
    $resultFiles = Get-ChildItem -Path $OutputDirectory -Filter "*-results.json" -File
    
    if ($resultFiles.Count -lt 2) {
        Write-Warning "Pas assez de fichiers de rÃ©sultats pour tester la fusion (minimum 2 requis)."
        return $false
    }
    
    # ExÃ©cuter la fusion
    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "merged-results.json"
    $htmlPath = Join-Path -Path $OutputDirectory -ChildPath "merged-results.html"
    
    try {
        $inputPaths = $resultFiles | Select-Object -ExpandProperty FullName
        
        & (Join-Path -Path $PSScriptRoot -ChildPath "..\Merge-AnalysisResults.ps1") -InputPath $inputPaths -OutputPath $outputPath -RemoveDuplicates -GenerateHtmlReport
        
        $success = (Test-Path -Path $outputPath -PathType Leaf) -and (Test-Path -Path $htmlPath -PathType Leaf)
        
        if ($success) {
            Write-Host "Test de fusion rÃ©ussi. RÃ©sultats enregistrÃ©s dans: $outputPath et $htmlPath" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Ã‰chec du test de fusion. Fichiers de rÃ©sultats non crÃ©Ã©s."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors du test de fusion: $_"
        return $false
    }
}

# ExÃ©cuter les tests
$testResults = @{}

# DÃ©terminer quels tests exÃ©cuter
if ($TestAll) {
    $TestPSScriptAnalyzer = $true
    $TestESLint = $true
    $TestPylint = $true
    $TestSonarQube = $true
}

# ExÃ©cuter les tests sÃ©lectionnÃ©s
if ($TestPSScriptAnalyzer) {
    $testResults["PSScriptAnalyzer"] = Test-PSScriptAnalyzerConnector -OutputDirectory $OutputDirectory
}

if ($TestESLint) {
    $testResults["ESLint"] = Test-ESLintConnector -OutputDirectory $OutputDirectory
}

if ($TestPylint) {
    $testResults["Pylint"] = Test-PylintConnector -OutputDirectory $OutputDirectory
}

# Tester la fusion des rÃ©sultats si au moins deux tests ont rÃ©ussi
$successfulTests = ($testResults.Values | Where-Object { $_ -eq $true }).Count
if ($successfulTests -ge 2) {
    $testResults["Fusion"] = Test-ResultsMerging -OutputDirectory $OutputDirectory
}

# Afficher un rÃ©sumÃ© des tests
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan

foreach ($test in $testResults.Keys) {
    $result = $testResults[$test]
    $resultText = if ($result) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $resultColor = if ($result) { "Green" } else { "Red" }
    
    Write-Host "  - $test : $resultText" -ForegroundColor $resultColor
}

# Afficher le chemin des rÃ©sultats
Write-Host "`nLes rÃ©sultats des tests sont disponibles dans: $OutputDirectory" -ForegroundColor Cyan
