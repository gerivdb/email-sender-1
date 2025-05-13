# -*- coding: utf-8 -*-
#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour les algorithmes de calcul de profondeur d'imbrication.
.DESCRIPTION
    Ce script teste les différents algorithmes de calcul de profondeur d'imbrication
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

$testFilePath = New-TestFile -Name "TestNestingAlgorithms.ps1" -Content $testContent

# Test 1: Vérifier les algorithmes de calcul de profondeur d'imbrication
Write-Host "Test 1: Vérification des algorithmes de calcul de profondeur d'imbrication..." -ForegroundColor Cyan

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

# Tester chaque algorithme
$algorithms = @("Simple", "Weighted", "Cognitive", "Hybrid")

foreach ($algorithm in $algorithms) {
    Write-Host "Test de l'algorithme '$algorithm'..." -ForegroundColor Yellow
    
    # Analyser la profondeur d'imbrication avec l'algorithme spécifié
    $results = Measure-NestingDepth -Ast $ast -ControlStructures $controlStructures -Algorithm $algorithm -Verbose
    
    # Afficher les résultats
    Write-Host "Résultats de l'analyse de profondeur d'imbrication avec l'algorithme '$algorithm' :" -ForegroundColor Yellow
    $results | Format-Table -Property Function, Value, Severity, Line, Algorithm -AutoSize
    
    # Vérifier que les résultats contiennent au moins un résultat avec une profondeur d'imbrication élevée
    $highNestingResult = $results | Where-Object { $_.Value -ge 5 } | Select-Object -First 1
    
    if ($null -eq $highNestingResult) {
        Write-Error "Aucun résultat avec une profondeur d'imbrication élevée n'a été trouvé avec l'algorithme '$algorithm'."
        exit 1
    }
    
    Write-Host "Profondeur d'imbrication maximale détectée avec l'algorithme '$algorithm' : $($highNestingResult.Value)" -ForegroundColor Green
}

Write-Host "Test 1 réussi !" -ForegroundColor Green

# Test 2: Comparer les résultats des différents algorithmes
Write-Host "Test 2: Comparaison des résultats des différents algorithmes..." -ForegroundColor Cyan

# Analyser la profondeur d'imbrication avec chaque algorithme
$simpleResults = Measure-NestingDepth -Ast $ast -ControlStructures $controlStructures -Algorithm "Simple"
$weightedResults = Measure-NestingDepth -Ast $ast -ControlStructures $controlStructures -Algorithm "Weighted"
$cognitiveResults = Measure-NestingDepth -Ast $ast -ControlStructures $controlStructures -Algorithm "Cognitive"
$hybridResults = Measure-NestingDepth -Ast $ast -ControlStructures $controlStructures -Algorithm "Hybrid"

# Créer un tableau de comparaison
$comparison = @()

foreach ($function in ($simpleResults | Select-Object -ExpandProperty Function -Unique)) {
    $simpleResult = $simpleResults | Where-Object { $_.Function -eq $function } | Select-Object -First 1
    $weightedResult = $weightedResults | Where-Object { $_.Function -eq $function } | Select-Object -First 1
    $cognitiveResult = $cognitiveResults | Where-Object { $_.Function -eq $function } | Select-Object -First 1
    $hybridResult = $hybridResults | Where-Object { $_.Function -eq $function } | Select-Object -First 1
    
    $comparison += [PSCustomObject]@{
        Function = $function
        Simple = $simpleResult.Value
        Weighted = $weightedResult.Value
        Cognitive = $cognitiveResult.Value
        Hybrid = $hybridResult.Value
    }
}

# Afficher le tableau de comparaison
Write-Host "Comparaison des résultats des différents algorithmes :" -ForegroundColor Yellow
$comparison | Format-Table -AutoSize

Write-Host "Test 2 réussi !" -ForegroundColor Green

# Afficher les résultats des tests
Write-Host "Tous les tests ont réussi !" -ForegroundColor Green

# Nettoyer les fichiers temporaires
# Commenter cette ligne pour conserver les fichiers temporaires pour inspection
# Remove-Item -Path $tempDir -Recurse -Force

Write-Host "Tests terminés." -ForegroundColor Yellow
