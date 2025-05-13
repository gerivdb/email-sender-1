# -*- coding: utf-8 -*-
#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour la coloration des structures selon leur impact.
.DESCRIPTION
    Ce script teste la coloration des structures selon leur impact dans les rapports HTML
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
'@

$testFilePath = New-TestFile -Name "TestNestedStructures.ps1" -Content $testContent

# Analyser la complexité cyclomatique du fichier de test
Write-Host "Analyse de la complexité cyclomatique..." -ForegroundColor Cyan
$results = Test-PowerShellComplexity -Path $testFilePath -Metrics "CyclomaticComplexity"

if ($null -eq $results -or $results.Count -eq 0) {
    Write-Error "Aucun résultat d'analyse de complexité n'a été retourné."
    exit 1
}

# Générer un rapport HTML pour la fonction
Write-Host "Génération du rapport HTML de fonction..." -ForegroundColor Cyan
$functionResult = $results | Where-Object { $_.Function -eq "Test-NestedStructures" } | Select-Object -First 1

if ($null -eq $functionResult) {
    Write-Error "La fonction Test-NestedStructures n'a pas été trouvée dans les résultats d'analyse."
    exit 1
}

$functionReportPath = Join-Path -Path $tempDir -ChildPath "StructureColorationReport.html"
$generatedFunctionReportPath = New-FunctionComplexityReport -Result $functionResult -SourceCode $testContent -OutputPath $functionReportPath -Title "Rapport de coloration des structures"

if (-not (Test-Path -Path $generatedFunctionReportPath)) {
    Write-Error "Le rapport HTML de fonction n'a pas été généré."
    exit 1
}

Write-Host "Rapport HTML de fonction généré : $generatedFunctionReportPath" -ForegroundColor Green

# Vérifier le contenu du rapport HTML
Write-Host "Vérification du contenu du rapport HTML..." -ForegroundColor Cyan

$reportContent = Get-Content -Path $generatedFunctionReportPath -Raw

$testsPassed = $true

# Vérifier que le rapport contient les classes d'impact
if (-not $reportContent.Contains("impact-none")) {
    Write-Error "Le rapport ne contient pas la classe impact-none."
    $testsPassed = $false
}

if (-not $reportContent.Contains("impact-low")) {
    Write-Error "Le rapport ne contient pas la classe impact-low."
    $testsPassed = $false
}

if (-not $reportContent.Contains("impact-medium")) {
    Write-Error "Le rapport ne contient pas la classe impact-medium."
    $testsPassed = $false
}

if (-not $reportContent.Contains("impact-high")) {
    Write-Error "Le rapport ne contient pas la classe impact-high."
    $testsPassed = $false
}

if (-not $reportContent.Contains("impact-critical")) {
    Write-Error "Le rapport ne contient pas la classe impact-critical."
    $testsPassed = $false
}

# Vérifier que le rapport contient la légende des couleurs
if (-not $reportContent.Contains("color-legend")) {
    Write-Error "Le rapport ne contient pas la légende des couleurs."
    $testsPassed = $false
}

# Vérifier que le rapport contient le filtre des structures
if (-not $reportContent.Contains("structure-filter")) {
    Write-Error "Le rapport ne contient pas le filtre des structures."
    $testsPassed = $false
}

# Vérifier que le rapport contient des tooltips
if (-not $reportContent.Contains("structure-tooltip")) {
    Write-Error "Le rapport ne contient pas de tooltips."
    $testsPassed = $false
}

# Afficher les résultats des tests
if ($testsPassed) {
    Write-Host "Tous les tests ont réussi !" -ForegroundColor Green

    # Ouvrir le rapport HTML dans le navigateur par défaut
    Write-Host "Ouverture du rapport HTML dans le navigateur par défaut..." -ForegroundColor Cyan
    Start-Process $generatedFunctionReportPath
} else {
    Write-Error "Certains tests ont échoué."
}

# Nettoyer les fichiers temporaires
# Commenter cette ligne pour conserver les fichiers temporaires pour inspection
# Remove-Item -Path $tempDir -Recurse -Force

Write-Host "Tests terminés." -ForegroundColor Yellow
