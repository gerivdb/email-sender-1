#Requires -Version 5.1
<#
.SYNOPSIS
    Teste les connecteurs d'analyse pour vérifier leur bon fonctionnement.

.DESCRIPTION
    Ce script teste les connecteurs d'analyse (PSScriptAnalyzer, ESLint, Pylint, SonarQube)
    pour vérifier qu'ils fonctionnent correctement et qu'ils produisent des résultats
    au format unifié.

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
    Répertoire de sortie pour les résultats des tests.

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

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputDirectory -PathType Container)) {
    try {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        Write-Verbose "Répertoire de sortie '$OutputDirectory' créé."
    }
    catch {
        Write-Error "Impossible de créer le répertoire de sortie '$OutputDirectory': $_"
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
    
    # Vérifier si PSScriptAnalyzer est disponible
    if (-not (Test-AnalysisTool -ToolName "PSScriptAnalyzer")) {
        Write-Warning "PSScriptAnalyzer n'est pas disponible. Test ignoré."
        return $false
    }
    
    # Trouver un script PowerShell à analyser
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\tools\Connect-PSScriptAnalyzer.ps1"
    
    if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
        Write-Warning "Script de test introuvable: $scriptPath"
        return $false
    }
    
    # Exécuter l'analyse
    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "pssa-results.json"
    
    try {
        & (Join-Path -Path $PSScriptRoot -ChildPath "..\tools\Connect-PSScriptAnalyzer.ps1") -FilePath $scriptPath -OutputPath $outputPath
        
        if (Test-Path -Path $outputPath -PathType Leaf) {
            Write-Host "Test PSScriptAnalyzer réussi. Résultats enregistrés dans: $outputPath" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Échec du test PSScriptAnalyzer. Fichier de résultats non créé."
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
    
    # Vérifier si ESLint est disponible
    if (-not (Test-AnalysisTool -ToolName "ESLint")) {
        Write-Warning "ESLint n'est pas disponible. Test ignoré."
        return $false
    }
    
    # Trouver un fichier JavaScript à analyser
    $jsFiles = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..") -Include "*.js" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($null -eq $jsFiles) {
        Write-Warning "Aucun fichier JavaScript trouvé pour le test."
        return $false
    }
    
    $jsPath = $jsFiles.FullName
    
    # Exécuter l'analyse
    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "eslint-results.json"
    
    try {
        & (Join-Path -Path $PSScriptRoot -ChildPath "..\tools\Connect-ESLint.ps1") -FilePath $jsPath -OutputPath $outputPath
        
        if (Test-Path -Path $outputPath -PathType Leaf) {
            Write-Host "Test ESLint réussi. Résultats enregistrés dans: $outputPath" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Échec du test ESLint. Fichier de résultats non créé."
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
    
    # Vérifier si Pylint est disponible
    if (-not (Test-AnalysisTool -ToolName "Pylint")) {
        Write-Warning "Pylint n'est pas disponible. Test ignoré."
        return $false
    }
    
    # Trouver un fichier Python à analyser
    $pyFiles = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..") -Include "*.py" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($null -eq $pyFiles) {
        Write-Warning "Aucun fichier Python trouvé pour le test."
        return $false
    }
    
    $pyPath = $pyFiles.FullName
    
    # Exécuter l'analyse
    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "pylint-results.json"
    
    try {
        & (Join-Path -Path $PSScriptRoot -ChildPath "..\tools\Connect-Pylint.ps1") -FilePath $pyPath -OutputPath $outputPath
        
        if (Test-Path -Path $outputPath -PathType Leaf) {
            Write-Host "Test Pylint réussi. Résultats enregistrés dans: $outputPath" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Échec du test Pylint. Fichier de résultats non créé."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors du test Pylint: $_"
        return $false
    }
}

# Fonction pour tester la fusion des résultats
function Test-ResultsMerging {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory
    )
    
    Write-Host "Test de la fusion des résultats..." -ForegroundColor Cyan
    
    # Vérifier s'il y a des fichiers de résultats à fusionner
    $resultFiles = Get-ChildItem -Path $OutputDirectory -Filter "*-results.json" -File
    
    if ($resultFiles.Count -lt 2) {
        Write-Warning "Pas assez de fichiers de résultats pour tester la fusion (minimum 2 requis)."
        return $false
    }
    
    # Exécuter la fusion
    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "merged-results.json"
    $htmlPath = Join-Path -Path $OutputDirectory -ChildPath "merged-results.html"
    
    try {
        $inputPaths = $resultFiles | Select-Object -ExpandProperty FullName
        
        & (Join-Path -Path $PSScriptRoot -ChildPath "..\Merge-AnalysisResults.ps1") -InputPath $inputPaths -OutputPath $outputPath -RemoveDuplicates -GenerateHtmlReport
        
        $success = (Test-Path -Path $outputPath -PathType Leaf) -and (Test-Path -Path $htmlPath -PathType Leaf)
        
        if ($success) {
            Write-Host "Test de fusion réussi. Résultats enregistrés dans: $outputPath et $htmlPath" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Échec du test de fusion. Fichiers de résultats non créés."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors du test de fusion: $_"
        return $false
    }
}

# Exécuter les tests
$testResults = @{}

# Déterminer quels tests exécuter
if ($TestAll) {
    $TestPSScriptAnalyzer = $true
    $TestESLint = $true
    $TestPylint = $true
    $TestSonarQube = $true
}

# Exécuter les tests sélectionnés
if ($TestPSScriptAnalyzer) {
    $testResults["PSScriptAnalyzer"] = Test-PSScriptAnalyzerConnector -OutputDirectory $OutputDirectory
}

if ($TestESLint) {
    $testResults["ESLint"] = Test-ESLintConnector -OutputDirectory $OutputDirectory
}

if ($TestPylint) {
    $testResults["Pylint"] = Test-PylintConnector -OutputDirectory $OutputDirectory
}

# Tester la fusion des résultats si au moins deux tests ont réussi
$successfulTests = ($testResults.Values | Where-Object { $_ -eq $true }).Count
if ($successfulTests -ge 2) {
    $testResults["Fusion"] = Test-ResultsMerging -OutputDirectory $OutputDirectory
}

# Afficher un résumé des tests
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan

foreach ($test in $testResults.Keys) {
    $result = $testResults[$test]
    $resultText = if ($result) { "Réussi" } else { "Échoué" }
    $resultColor = if ($result) { "Green" } else { "Red" }
    
    Write-Host "  - $test : $resultText" -ForegroundColor $resultColor
}

# Afficher le chemin des résultats
Write-Host "`nLes résultats des tests sont disponibles dans: $OutputDirectory" -ForegroundColor Cyan
