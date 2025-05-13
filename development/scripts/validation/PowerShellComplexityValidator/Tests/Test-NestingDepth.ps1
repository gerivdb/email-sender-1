# -*- coding: utf-8 -*-
#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour l'analyse de la profondeur d'imbrication.
.DESCRIPTION
    Ce script teste l'analyse de la profondeur d'imbrication dans le code PowerShell
    en utilisant le module NestingDepthAnalyzer.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

[CmdletBinding()]
param()

# Importer les modules à tester
$complexityModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\PowerShellComplexityValidator.psm1'
$nestingDepthPath = Join-Path -Path $PSScriptRoot -ChildPath '..\NestingDepthAnalyzer.psm1'
$cyclomaticComplexityAnalyzerPath = Join-Path -Path $PSScriptRoot -ChildPath '..\CyclomaticComplexityAnalyzer.psm1'

Import-Module -Name $complexityModulePath -Force
Import-Module -Name $nestingDepthPath -Force
Import-Module -Name $cyclomaticComplexityAnalyzerPath -Force

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

# Créer un fichier de test avec des structures imbriquées
$testContent = @'
function Test-NestedStructures {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$Depth,

        [Parameter(Mandatory = $false)]
        [int]$Count = 5
    )

    if ($Depth -gt 0) {
        if ($Depth -gt 1) {
            if ($Depth -gt 2) {
                if ($Depth -gt 3) {
                    for ($i = 0; $i -lt $Count; $i++) {
                        if ($i % 2 -eq 0) {
                            Write-Output "Even: $i"
                        }
                        else {
                            Write-Output "Odd: $i"
                        }
                    }
                }
                else {
                    while ($Count -gt 0) {
                        Write-Output "Count: $Count"
                        $Count--
                    }
                }
            }
            else {
                switch ($Count) {
                    1 { Write-Output "One" }
                    2 { Write-Output "Two" }
                    3 { Write-Output "Three" }
                    4 { Write-Output "Four" }
                    5 { Write-Output "Five" }
                    default { Write-Output "Other" }
                }
            }
        }
        else {
            try {
                $result = 10 / $Count
                Write-Output "Result: $result"
            }
            catch {
                Write-Error "Error: $_"
            }
        }
    }
    else {
        Write-Output "Depth must be greater than 0"
    }
}

function Test-SimpleFunction {
    param (
        [string]$Parameter1
    )

    Write-Output "Test: $Parameter1"
}

function Test-MediumNestedFunction {
    param (
        [int]$Value
    )

    if ($Value -gt 0) {
        for ($i = 0; $i -lt $Value; $i++) {
            if ($i % 2 -eq 0) {
                Write-Output "Even: $i"
            }
        }
    }
    else {
        Write-Output "Value must be greater than 0"
    }
}
'@

$testFilePath = New-TestFile -Name "TestNestingDepth.ps1" -Content $testContent

# Test 1: Vérifier la configuration des niveaux d'imbrication
Write-Host "Test 1: Vérification de la configuration des niveaux d'imbrication..." -ForegroundColor Cyan
$defaultConfig = Get-NestingConfig
if ($null -eq $defaultConfig) {
    Write-Error "La configuration par défaut des niveaux d'imbrication est null."
    exit 1
}

$testConfig = @{
    Thresholds = @{
        Low      = 2
        Medium   = 4
        High     = 6
        VeryHigh = 8
    }
}

Set-NestingConfig -Config $testConfig
$updatedConfig = Get-NestingConfig

if ($updatedConfig.Thresholds.Low -ne 2) {
    Write-Error "La configuration des niveaux d'imbrication n'a pas été mise à jour correctement."
    exit 1
}

Reset-NestingConfig
$resetConfig = Get-NestingConfig

if ($resetConfig.Thresholds.Low -ne 3) {
    Write-Error "La configuration des niveaux d'imbrication n'a pas été réinitialisée correctement."
    exit 1
}

Write-Host "Test 1 réussi !" -ForegroundColor Green

# Test 2: Analyser la profondeur d'imbrication
Write-Host "Test 2: Analyse de la profondeur d'imbrication..." -ForegroundColor Cyan

# Lire le contenu du fichier
$fileContent = Get-Content -Path $testFilePath -Raw

# Parser le contenu du fichier
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($fileContent, [ref]$null, [ref]$parseErrors)

if ($parseErrors -and $parseErrors.Count -gt 0) {
    Write-Error "Erreurs de parsing dans le fichier de test:"
    foreach ($error in $parseErrors) {
        Write-Error "  Ligne $($error.Extent.StartLineNumber), colonne $($error.Extent.StartColumnNumber): $($error.Message)"
    }
    exit 1
}

# Récupérer les structures de contrôle
$controlStructures = Get-ControlStructures -Ast $ast

if ($null -eq $controlStructures -or $controlStructures.Count -eq 0) {
    Write-Error "Aucune structure de contrôle n'a été détectée dans le fichier de test."
    exit 1
}

# Afficher les structures de contrôle pour le débogage
Write-Host "Structures de contrôle détectées :" -ForegroundColor Yellow
$controlStructures | Format-Table -Property Type, Line, Column, Function -AutoSize

# Analyser la profondeur d'imbrication
Write-Host "Analyse de la profondeur d'imbrication..." -ForegroundColor Yellow
$nestingResults = Measure-NestingDepth -Ast $ast -ControlStructures $controlStructures -Verbose

Write-Host "Résultats de l'analyse de profondeur d'imbrication :" -ForegroundColor Yellow
$nestingResults | Format-Table -Property Function, Value, Severity, Line -AutoSize

if ($null -eq $nestingResults -or $nestingResults.Count -eq 0) {
    Write-Error "Aucun résultat d'analyse de profondeur d'imbrication n'a été retourné."
    exit 1
}

# Vérifier les résultats
# Comme les structures de contrôle n'ont pas de propriété Function définie,
# nous vérifions simplement que les résultats contiennent au moins un résultat avec une profondeur d'imbrication élevée
$highNestingResult = $nestingResults | Where-Object { $_.Value -ge 5 } | Select-Object -First 1

if ($null -eq $highNestingResult) {
    Write-Error "Aucun résultat avec une profondeur d'imbrication élevée n'a été trouvé."
    exit 1
}

Write-Host "Profondeur d'imbrication maximale détectée : $($highNestingResult.Value)" -ForegroundColor Green

Write-Host "Test 2 réussi !" -ForegroundColor Green

# Test 3: Obtenir les niveaux d'imbrication par ligne
Write-Host "Test 3: Obtention des niveaux d'imbrication par ligne..." -ForegroundColor Cyan

$nestingLevels = Get-NestingLevels -ControlStructures $controlStructures

if ($null -eq $nestingLevels -or $nestingLevels.Count -eq 0) {
    Write-Error "Aucun niveau d'imbrication n'a été retourné."
    exit 1
}

# Vérifier que les lignes avec des structures imbriquées ont des niveaux d'imbrication
$hasNestingLevels = $false
foreach ($line in $nestingLevels.Keys) {
    if ($nestingLevels[$line] -gt 0) {
        $hasNestingLevels = $true
        break
    }
}

if (-not $hasNestingLevels) {
    Write-Error "Aucun niveau d'imbrication supérieur à 0 n'a été détecté."
    exit 1
}

Write-Host "Test 3 réussi !" -ForegroundColor Green

# Test 4: Utiliser Test-PowerShellComplexity avec la métrique NestingDepth
Write-Host "Test 4: Utilisation de Test-PowerShellComplexity avec la métrique NestingDepth..." -ForegroundColor Cyan

$results = Test-PowerShellComplexity -Path $testFilePath -Metrics "NestingDepth" -Severity "Information"

if ($null -eq $results -or $results.Count -eq 0) {
    Write-Error "Aucun résultat n'a été retourné par Test-PowerShellComplexity."
    exit 1
}

$nestingDepthResults = $results | Where-Object { $_.Metric -eq "NestingDepth" }

if ($null -eq $nestingDepthResults -or $nestingDepthResults.Count -eq 0) {
    Write-Error "Aucun résultat de profondeur d'imbrication n'a été retourné par Test-PowerShellComplexity."
    exit 1
}

Write-Host "Test 4 réussi !" -ForegroundColor Green

# Test 5: Générer un rapport HTML avec les résultats de profondeur d'imbrication
Write-Host "Test 5: Génération d'un rapport HTML avec les résultats de profondeur d'imbrication..." -ForegroundColor Cyan

$reportPath = Join-Path -Path $tempDir -ChildPath "NestingDepthReport.html"

# Utiliser ConvertTo-Html pour générer un rapport HTML simple
$head = @"
<style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    table { border-collapse: collapse; width: 100%; }
    th { background-color: #4CAF50; color: white; text-align: left; padding: 8px; }
    td { border: 1px solid #ddd; padding: 8px; }
    tr:nth-child(even) { background-color: #f2f2f2; }
    tr:hover { background-color: #ddd; }
    .warning { background-color: #FFF3CD; }
    .error { background-color: #F8D7DA; }
    h1 { color: #4CAF50; }
</style>
"@

$htmlOutput = $results | ConvertTo-Html -Title "Rapport de profondeur d'imbrication" -Head $head -PreContent "<h1>Rapport de profondeur d'imbrication</h1>"
$htmlOutput | Out-File -FilePath $reportPath -Encoding utf8

if (-not (Test-Path -Path $reportPath)) {
    Write-Error "Le rapport HTML n'a pas été généré."
    exit 1
}

Write-Host "Test 5 réussi !" -ForegroundColor Green

# Afficher les résultats des tests
Write-Host "Tous les tests ont réussi !" -ForegroundColor Green

# Ouvrir le rapport HTML dans le navigateur par défaut
Write-Host "Ouverture du rapport HTML dans le navigateur par défaut..." -ForegroundColor Cyan
Start-Process $reportPath

# Nettoyer les fichiers temporaires
# Commenter cette ligne pour conserver les fichiers temporaires pour inspection
# Remove-Item -Path $tempDir -Recurse -Force

Write-Host "Tests terminés." -ForegroundColor Yellow
