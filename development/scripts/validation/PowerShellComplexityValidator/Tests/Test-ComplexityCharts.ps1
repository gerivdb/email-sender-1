# -*- coding: utf-8 -*-
#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour les graphiques de distribution de complexité.
.DESCRIPTION
    Ce script teste les graphiques de distribution de complexité dans les rapports HTML
    générés par le module PowerShellComplexityValidator.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

[CmdletBinding()]
param()

# Importer les modules à tester
$complexityModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\PowerShellComplexityValidator.psm1'
$htmlReportModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\HtmlReportGenerator.psm1'

Import-Module -Name $complexityModulePath -Force
Import-Module -Name $htmlReportModulePath -Force

# Créer un dossier temporaire pour les tests
$tempDir = Join-Path -Path $PSScriptRoot -ChildPath 'temp'
if (-not (Test-Path -Path $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    Write-Verbose "Dossier temporaire créé : $tempDir"
}

# Fonction pour créer un fichier de test
function New-TestFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    $filePath = Join-Path -Path $tempDir -ChildPath $Name
    $Content | Out-File -FilePath $filePath -Encoding utf8
    return $filePath
}

# Créer plusieurs fichiers de test avec différentes complexités
$testFiles = @()

# Fichier 1: Fonction simple
$test1Content = @'
function Test-SimpleFunction {
    param (
        [string]$Parameter1
    )
    
    Write-Output "Test: $Parameter1"
}
'@

$testFiles += New-TestFile -Name "TestSimpleFunction.ps1" -Content $test1Content

# Fichier 2: Fonction avec une instruction if
$test2Content = @'
function Test-IfFunction {
    param (
        [string]$Parameter1
    )
    
    if ($Parameter1 -eq "Test") {
        Write-Output "Test"
    }
    else {
        Write-Output "Not Test"
    }
}
'@

$testFiles += New-TestFile -Name "TestIfFunction.ps1" -Content $test2Content

# Fichier 3: Fonction avec une boucle for
$test3Content = @'
function Test-ForFunction {
    param (
        [int]$Count
    )
    
    for ($i = 0; $i -lt $Count; $i++) {
        Write-Output "Iteration: $i"
    }
}
'@

$testFiles += New-TestFile -Name "TestForFunction.ps1" -Content $test3Content

# Fichier 4: Fonction avec une instruction switch
$test4Content = @'
function Test-SwitchFunction {
    param (
        [string]$Parameter1
    )
    
    switch ($Parameter1) {
        "Test" { Write-Output "Test" }
        "Debug" { Write-Output "Debug" }
        "Release" { Write-Output "Release" }
        default { Write-Output "Unknown" }
    }
}
'@

$testFiles += New-TestFile -Name "TestSwitchFunction.ps1" -Content $test4Content

# Fichier 5: Fonction avec des structures imbriquées
$test5Content = @'
function Test-NestedStructures {
    param (
        [int]$Depth,
        [int]$Count
    )
    
    if ($Depth -gt 0) {
        if ($Depth -gt 1) {
            if ($Depth -gt 2) {
                if ($Depth -gt 3) {
                    for ($i = 0; $i -lt $Count; $i++) {
                        Write-Output "Deep iteration: $i"
                    }
                }
            }
        }
    }
}
'@

$testFiles += New-TestFile -Name "TestNestedStructures.ps1" -Content $test5Content

# Fichier 6: Fonction très complexe
$test6Content = @'
function Test-VeryComplexFunction {
    param (
        [string]$Parameter1,
        [int]$Parameter2,
        [bool]$Parameter3
    )
    
    if ($Parameter1 -eq "Test") {
        if ($Parameter2 -gt 0) {
            for ($i = 0; $i -lt $Parameter2; $i++) {
                if ($i % 2 -eq 0) {
                    Write-Output "Even: $i"
                }
                else {
                    Write-Output "Odd: $i"
                }
            }
        }
        elseif ($Parameter2 -lt 0) {
            for ($i = $Parameter2; $i -lt 0; $i++) {
                Write-Output "Negative: $i"
            }
        }
        else {
            Write-Output "Zero"
        }
    }
    elseif ($Parameter1 -eq "Debug") {
        switch ($Parameter3) {
            $true {
                try {
                    Write-Output "Debug mode enabled"
                }
                catch {
                    Write-Error "Error in debug mode"
                }
            }
            $false {
                Write-Output "Debug mode disabled"
            }
            default {
                Write-Output "Unknown debug mode"
            }
        }
    }
    else {
        if (($Parameter2 -gt 10 -and $Parameter3) -or ($Parameter2 -lt -10 -and -not $Parameter3)) {
            Write-Output "Complex condition satisfied"
        }
    }
}
'@

$testFiles += New-TestFile -Name "TestVeryComplexFunction.ps1" -Content $test6Content

# Analyser la complexité cyclomatique des fichiers de test
Write-Host "Analyse de la complexité cyclomatique..." -ForegroundColor Cyan
$allResults = @()
foreach ($file in $testFiles) {
    $results = Test-PowerShellComplexity -Path $file -Metrics "CyclomaticComplexity"
    $allResults += $results
}

if ($null -eq $allResults -or $allResults.Count -eq 0) {
    Write-Error "Aucun résultat d'analyse de complexité n'a été retourné."
    exit 1
}

# Générer un rapport HTML global
Write-Host "Génération du rapport HTML global..." -ForegroundColor Cyan
$reportPath = Join-Path -Path $tempDir -ChildPath "ComplexityChartsReport.html"
$generatedReportPath = New-ComplexityHtmlReport -Results $allResults -OutputPath $reportPath -Title "Rapport de test des graphiques de complexité"

if (-not (Test-Path -Path $generatedReportPath)) {
    Write-Error "Le rapport HTML global n'a pas été généré."
    exit 1
}

Write-Host "Rapport HTML global généré : $generatedReportPath" -ForegroundColor Green

# Générer un rapport HTML pour une fonction spécifique
Write-Host "Génération du rapport HTML de fonction..." -ForegroundColor Cyan
$functionResult = $allResults | Where-Object { $_.Function -eq "Test-VeryComplexFunction" } | Select-Object -First 1

if ($null -eq $functionResult) {
    Write-Error "La fonction Test-VeryComplexFunction n'a pas été trouvée dans les résultats d'analyse."
    exit 1
}

$functionReportPath = Join-Path -Path $tempDir -ChildPath "FunctionChartsReport.html"
$generatedFunctionReportPath = New-FunctionComplexityReport -Result $functionResult -SourceCode $test6Content -OutputPath $functionReportPath -Title "Rapport de graphiques de fonction"

if (-not (Test-Path -Path $generatedFunctionReportPath)) {
    Write-Error "Le rapport HTML de fonction n'a pas été généré."
    exit 1
}

Write-Host "Rapport HTML de fonction généré : $generatedFunctionReportPath" -ForegroundColor Green

# Vérifier le contenu des rapports HTML
Write-Host "Vérification du contenu des rapports HTML..." -ForegroundColor Cyan

$globalReportContent = Get-Content -Path $generatedReportPath -Raw
$functionReportContent = Get-Content -Path $generatedFunctionReportPath -Raw

$testsPassed = $true

# Vérifier que le rapport global contient les graphiques
if (-not $globalReportContent.Contains("complexityDistributionChart")) {
    Write-Error "Le rapport global ne contient pas le graphique de distribution de complexité."
    $testsPassed = $false
}

if (-not $globalReportContent.Contains("structureTypesChart")) {
    Write-Error "Le rapport global ne contient pas le graphique des types de structures."
    $testsPassed = $false
}

if (-not $globalReportContent.Contains("topComplexFunctionsChart")) {
    Write-Error "Le rapport global ne contient pas le graphique des fonctions les plus complexes."
    $testsPassed = $false
}

# Vérifier que le rapport de fonction contient les graphiques
if (-not $functionReportContent.Contains("structureTypesChart")) {
    Write-Error "Le rapport de fonction ne contient pas le graphique des types de structures."
    $testsPassed = $false
}

if (-not $functionReportContent.Contains("structureImpactChart")) {
    Write-Error "Le rapport de fonction ne contient pas le graphique d'impact des structures."
    $testsPassed = $false
}

if (-not $functionReportContent.Contains("nestingLevelsChart")) {
    Write-Error "Le rapport de fonction ne contient pas le graphique des niveaux d'imbrication."
    $testsPassed = $false
}

# Afficher les résultats des tests
if ($testsPassed) {
    Write-Host "Tous les tests ont réussi !" -ForegroundColor Green
    
    # Ouvrir les rapports HTML dans le navigateur par défaut
    Write-Host "Ouverture des rapports HTML dans le navigateur par défaut..." -ForegroundColor Cyan
    Start-Process $generatedReportPath
    Start-Process $generatedFunctionReportPath
}
else {
    Write-Error "Certains tests ont échoué."
}

# Nettoyer les fichiers temporaires
# Commenter cette ligne pour conserver les fichiers temporaires pour inspection
# Remove-Item -Path $tempDir -Recurse -Force

Write-Host "Tests terminés." -ForegroundColor Yellow
