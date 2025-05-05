#Requires -Version 5.1
<#
.SYNOPSIS
    Teste les connecteurs d'analyse pour vÃƒÂ©rifier leur bon fonctionnement.

.DESCRIPTION
    Ce script teste les connecteurs d'analyse (PSScriptAnalyzer, ESLint, Pylint, SonarQube)
    pour vÃƒÂ©rifier qu'ils fonctionnent correctement et qu'ils produisent des rÃƒÂ©sultats
    au format unifiÃƒÂ©.

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
    RÃƒÂ©pertoire de sortie pour les rÃƒÂ©sultats des tests.

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

# CrÃƒÂ©er le rÃƒÂ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputDirectory -PathType Container)) {
    try {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        Write-Verbose "RÃƒÂ©pertoire de sortie '$OutputDirectory' crÃƒÂ©ÃƒÂ©."
    }
    catch {
        Write-Error "Impossible de crÃƒÂ©er le rÃƒÂ©pertoire de sortie '$OutputDirectory': $_"
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
    
    # VÃƒÂ©rifier si PSScriptAnalyzer est disponible
    if (-not (Test-AnalysisTool -ToolName "PSScriptAnalyzer")) {
        Write-Warning "PSScriptAnalyzer n'est pas disponible. Test ignorÃƒÂ©."
        return $false
    }
    
    # Trouver un script PowerShell ÃƒÂ  analyser
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\tools\Connect-PSScriptAnalyzer.ps1"
    
    if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
        Write-Warning "Script de test introuvable: $scriptPath"
        return $false
    }
    
    # ExÃƒÂ©cuter l'analyse
    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "pssa-results.json"
    
    try {
        & (Join-Path -Path $PSScriptRoot -ChildPath "..\development\tools\Connect-PSScriptAnalyzer.ps1") -FilePath $scriptPath -OutputPath $outputPath
        
        if (Test-Path -Path $outputPath -PathType Leaf) {
            Write-Host "Test PSScriptAnalyzer rÃƒÂ©ussi. RÃƒÂ©sultats enregistrÃƒÂ©s dans: $outputPath" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Ãƒâ€°chec du test PSScriptAnalyzer. Fichier de rÃƒÂ©sultats non crÃƒÂ©ÃƒÂ©."
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
    
    # VÃƒÂ©rifier si ESLint est disponible
    if (-not (Test-AnalysisTool -ToolName "ESLint")) {
        Write-Warning "ESLint n'est pas disponible. Test ignorÃƒÂ©."
        return $false
    }
    
    # Trouver un fichier JavaScript ÃƒÂ  analyser
    $jsFiles = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..") -Include "*.js" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($null -eq $jsFiles) {
        Write-Warning "Aucun fichier JavaScript trouvÃƒÂ© pour le test."
        return $false
    }
    
    $jsPath = $jsFiles.FullName
    
    # ExÃƒÂ©cuter l'analyse
    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "eslint-results.json"
    
    try {
        & (Join-Path -Path $PSScriptRoot -ChildPath "..\development\tools\Connect-ESLint.ps1") -FilePath $jsPath -OutputPath $outputPath
        
        if (Test-Path -Path $outputPath -PathType Leaf) {
            Write-Host "Test ESLint rÃƒÂ©ussi. RÃƒÂ©sultats enregistrÃƒÂ©s dans: $outputPath" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Ãƒâ€°chec du test ESLint. Fichier de rÃƒÂ©sultats non crÃƒÂ©ÃƒÂ©."
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
    
    # VÃƒÂ©rifier si Pylint est disponible
    if (-not (Test-AnalysisTool -ToolName "Pylint")) {
        Write-Warning "Pylint n'est pas disponible. Test ignorÃƒÂ©."
        return $false
    }
    
    # Trouver un fichier Python ÃƒÂ  analyser
    $pyFiles = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..") -Include "*.py" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($null -eq $pyFiles) {
        Write-Warning "Aucun fichier Python trouvÃƒÂ© pour le test."
        return $false
    }
    
    $pyPath = $pyFiles.FullName
    
    # ExÃƒÂ©cuter l'analyse
    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "pylint-results.json"
    
    try {
        & (Join-Path -Path $PSScriptRoot -ChildPath "..\development\tools\Connect-Pylint.ps1") -FilePath $pyPath -OutputPath $outputPath
        
        if (Test-Path -Path $outputPath -PathType Leaf) {
            Write-Host "Test Pylint rÃƒÂ©ussi. RÃƒÂ©sultats enregistrÃƒÂ©s dans: $outputPath" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Ãƒâ€°chec du test Pylint. Fichier de rÃƒÂ©sultats non crÃƒÂ©ÃƒÂ©."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors du test Pylint: $_"
        return $false
    }
}

# Fonction pour tester la fusion des rÃƒÂ©sultats
function Test-ResultsMerging {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory
    )
    
    Write-Host "Test de la fusion des rÃƒÂ©sultats..." -ForegroundColor Cyan
    
    # VÃƒÂ©rifier s'il y a des fichiers de rÃƒÂ©sultats ÃƒÂ  fusionner
    $resultFiles = Get-ChildItem -Path $OutputDirectory -Filter "*-results.json" -File
    
    if ($resultFiles.Count -lt 2) {
        Write-Warning "Pas assez de fichiers de rÃƒÂ©sultats pour tester la fusion (minimum 2 requis)."
        return $false
    }
    
    # ExÃƒÂ©cuter la fusion
    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "merged-results.json"
    $htmlPath = Join-Path -Path $OutputDirectory -ChildPath "merged-results.html"
    
    try {
        $inputPaths = $resultFiles | Select-Object -ExpandProperty FullName
        
        & (Join-Path -Path $PSScriptRoot -ChildPath "..\Merge-AnalysisResults.ps1") -InputPath $inputPaths -OutputPath $outputPath -RemoveDuplicates -GenerateHtmlReport
        
        $success = (Test-Path -Path $outputPath -PathType Leaf) -and (Test-Path -Path $htmlPath -PathType Leaf)
        
        if ($success) {
            Write-Host "Test de fusion rÃƒÂ©ussi. RÃƒÂ©sultats enregistrÃƒÂ©s dans: $outputPath et $htmlPath" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Ãƒâ€°chec du test de fusion. Fichiers de rÃƒÂ©sultats non crÃƒÂ©ÃƒÂ©s."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors du test de fusion: $_"
        return $false
    }
}

# ExÃƒÂ©cuter les tests
$testResults = @{}

# DÃƒÂ©terminer quels tests exÃƒÂ©cuter
if ($TestAll) {
    $TestPSScriptAnalyzer = $true
    $TestESLint = $true
    $TestPylint = $true
    $TestSonarQube = $true
}

# ExÃƒÂ©cuter les tests sÃƒÂ©lectionnÃƒÂ©s
if ($TestPSScriptAnalyzer) {
    $testResults["PSScriptAnalyzer"] = Test-PSScriptAnalyzerConnector -OutputDirectory $OutputDirectory
}

if ($TestESLint) {
    $testResults["ESLint"] = Test-ESLintConnector -OutputDirectory $OutputDirectory
}

if ($TestPylint) {
    $testResults["Pylint"] = Test-PylintConnector -OutputDirectory $OutputDirectory
}

# Tester la fusion des rÃƒÂ©sultats si au moins deux tests ont rÃƒÂ©ussi
$successfulTests = ($testResults.Values | Where-Object { $_ -eq $true }).Count
if ($successfulTests -ge 2) {
    $testResults["Fusion"] = Test-ResultsMerging -OutputDirectory $OutputDirectory
}

# Afficher un rÃƒÂ©sumÃƒÂ© des tests
Write-Host "`nRÃƒÂ©sumÃƒÂ© des tests:" -ForegroundColor Cyan

foreach ($test in $testResults.Keys) {
    $result = $testResults[$test]
    $resultText = if ($result) { "RÃƒÂ©ussi" } else { "Ãƒâ€°chouÃƒÂ©" }
    $resultColor = if ($result) { "Green" } else { "Red" }
    
    Write-Host "  - $test : $resultText" -ForegroundColor $resultColor
}

# Afficher le chemin des rÃƒÂ©sultats
Write-Host "`nLes rÃƒÂ©sultats des tests sont disponibles dans: $OutputDirectory" -ForegroundColor Cyan
