#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le module de génération de rapports HTML.
.DESCRIPTION
    Ce script teste le module de génération de rapports HTML pour la visualisation
    de la complexité cyclomatique.
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

# Créer un fichier de test avec une fonction complexe
$testContent = @'
function Test-ComplexFunction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Parameter1,
        
        [Parameter(Mandatory = $false)]
        [int]$Parameter2 = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$Parameter3
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

$testFilePath = New-TestFile -Name "TestComplexFunction.ps1" -Content $testContent

# Analyser la complexité cyclomatique du fichier de test
Write-Host "Analyse de la complexité cyclomatique..." -ForegroundColor Cyan
$results = Test-PowerShellComplexity -Path $testFilePath -Metrics "CyclomaticComplexity"

if ($null -eq $results -or $results.Count -eq 0) {
    Write-Error "Aucun résultat d'analyse de complexité n'a été retourné."
    exit 1
}

# Générer un rapport HTML global
Write-Host "Génération du rapport HTML global..." -ForegroundColor Cyan
$reportPath = Join-Path -Path $tempDir -ChildPath "ComplexityReport.html"
$generatedReportPath = New-ComplexityHtmlReport -Results $results -OutputPath $reportPath -Title "Rapport de test de complexité"

if (-not (Test-Path -Path $generatedReportPath)) {
    Write-Error "Le rapport HTML global n'a pas été généré."
    exit 1
}

Write-Host "Rapport HTML global généré : $generatedReportPath" -ForegroundColor Green

# Générer un rapport HTML pour une fonction spécifique
Write-Host "Génération du rapport HTML de fonction..." -ForegroundColor Cyan
$functionResult = $results | Where-Object { $_.Function -eq "Test-ComplexFunction" } | Select-Object -First 1

if ($null -eq $functionResult) {
    Write-Error "La fonction Test-ComplexFunction n'a pas été trouvée dans les résultats d'analyse."
    exit 1
}

$functionReportPath = Join-Path -Path $tempDir -ChildPath "FunctionReport.html"
$generatedFunctionReportPath = New-FunctionComplexityReport -Result $functionResult -SourceCode $testContent -OutputPath $functionReportPath -Title "Rapport de fonction"

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

# Vérifier que le rapport global contient les éléments essentiels
if (-not $globalReportContent.Contains("<title>Rapport de test de complexité</title>")) {
    Write-Error "Le rapport global ne contient pas le titre attendu."
    $testsPassed = $false
}

if (-not $globalReportContent.Contains("<h1>Rapport de test de complexité</h1>")) {
    Write-Error "Le rapport global ne contient pas l'en-tête H1 attendu."
    $testsPassed = $false
}

if (-not $globalReportContent.Contains("<td>Test-ComplexFunction</td>")) {
    Write-Error "Le rapport global ne contient pas la fonction Test-ComplexFunction."
    $testsPassed = $false
}

# Vérifier que le rapport de fonction contient les éléments essentiels
if (-not $functionReportContent.Contains("<title>Rapport de fonction - Test-ComplexFunction</title>")) {
    Write-Error "Le rapport de fonction ne contient pas le titre attendu."
    $testsPassed = $false
}

if (-not $functionReportContent.Contains("<h1>Rapport de fonction - Test-ComplexFunction</h1>")) {
    Write-Error "Le rapport de fonction ne contient pas l'en-tête H1 attendu."
    $testsPassed = $false
}

if (-not $functionReportContent.Contains("<pre class=`"code-block`">")) {
    Write-Error "Le rapport de fonction ne contient pas le bloc de code."
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
