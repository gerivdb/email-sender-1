#Requires -Version 5.1
<#
.SYNOPSIS
    Test de débogage pour le module PowerShellComplexityValidator.
.DESCRIPTION
    Ce script teste les fonctionnalités du module PowerShellComplexityValidator
    et identifie les problèmes potentiels.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

[CmdletBinding()]
param()

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\PowerShellComplexityValidator.psm1'
Import-Module -Name $modulePath -Force

# Créer un dossier temporaire pour les tests
$tempDir = Join-Path -Path $PSScriptRoot -ChildPath 'temp'
if (-not (Test-Path -Path $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    Write-Verbose "Dossier temporaire créé : $tempDir"
}

# Créer un fichier de test simple
$testFilePath = Join-Path -Path $tempDir -ChildPath 'TestFile.ps1'
$testFileContent = @'
function Test-SimpleFunction {
    param (
        [string]$Parameter1
    )

    Write-Output "Test: $Parameter1"
}

function Test-ComplexFunction {
    param (
        [string]$Parameter1,
        [int]$Parameter2,
        [bool]$Parameter3
    )

    if ($Parameter1 -eq "Test") {
        Write-Output "Test"
    }
    elseif ($Parameter1 -eq "Debug") {
        Write-Output "Debug"
    }
    else {
        Write-Output "Unknown"
    }

    for ($i = 0; $i -lt $Parameter2; $i++) {
        if ($i % 2 -eq 0) {
            Write-Output "Even: $i"
        }
        else {
            Write-Output "Odd: $i"
        }
    }

    switch ($Parameter3) {
        $true { Write-Output "True" }
        $false { Write-Output "False" }
        default { Write-Output "Unknown" }
    }
}
'@

$testFileContent | Out-File -FilePath $testFilePath -Encoding utf8

# Fonction pour exécuter un test et afficher les résultats
function Test-Function {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    Write-Host "Test: $Name" -ForegroundColor Cyan

    try {
        $result = & $ScriptBlock
        Write-Host "  Réussi" -ForegroundColor Green
        return $result
    } catch {
        Write-Host "  Échoué: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Test 1: Vérifier que le module est chargé
Test-Function -Name "Vérifier que le module est chargé" -ScriptBlock {
    $moduleLoaded = $null -ne (Get-Module -Name "PowerShellComplexityValidator")
    if (-not $moduleLoaded) {
        throw "Le module n'est pas chargé"
    }
}

# Test 2: Vérifier que les fonctions sont exportées
Test-Function -Name "Vérifier que les fonctions sont exportées" -ScriptBlock {
    $expectedFunctions = @(
        "Test-PowerShellComplexity",
        "New-PowerShellComplexityReport"
    )

    $exportedFunctions = (Get-Module -Name "PowerShellComplexityValidator").ExportedFunctions.Keys
    $missingFunctions = $expectedFunctions | Where-Object { $_ -notin $exportedFunctions }

    if ($missingFunctions.Count -gt 0) {
        throw "Fonctions manquantes: $($missingFunctions -join ', ')"
    }
}

# Test 3: Vérifier que la fonction Test-PowerShellComplexity fonctionne
$results = Test-Function -Name "Vérifier que la fonction Test-PowerShellComplexity fonctionne" -ScriptBlock {
    $results = Test-PowerShellComplexity -Path $testFilePath -Metrics "CyclomaticComplexity", "NestingDepth" -Verbose
    return $results
}

Write-Host "Résultats de Test-PowerShellComplexity:" -ForegroundColor Yellow
if ($null -eq $results) {
    Write-Host "  Aucun résultat (attendu car les métriques ne sont pas encore implémentées)" -ForegroundColor Gray
} else {
    $results | Format-Table -AutoSize
}

# Test 4: Vérifier que la fonction New-PowerShellComplexityReport fonctionne
$reportPath = Join-Path -Path $tempDir -ChildPath "ComplexityReport.html"

# Créer des résultats de test fictifs pour la génération du rapport
$mockResults = @(
    [PSCustomObject]@{
        Path      = $testFilePath
        Line      = 10
        Function  = "Test-SimpleFunction"
        Metric    = "CyclomaticComplexity"
        Value     = 1
        Threshold = 10
        Severity  = "Information"
        Message   = "Complexité cyclomatique acceptable"
        Rule      = "CyclomaticComplexity_LowComplexity"
    },
    [PSCustomObject]@{
        Path      = $testFilePath
        Line      = 20
        Function  = "Test-ComplexFunction"
        Metric    = "CyclomaticComplexity"
        Value     = 8
        Threshold = 10
        Severity  = "Information"
        Message   = "Complexité cyclomatique acceptable"
        Rule      = "CyclomaticComplexity_LowComplexity"
    },
    [PSCustomObject]@{
        Path      = $testFilePath
        Line      = 20
        Function  = "Test-ComplexFunction"
        Metric    = "NestingDepth"
        Value     = 3
        Threshold = 5
        Severity  = "Information"
        Message   = "Profondeur d'imbrication acceptable"
        Rule      = "NestingDepth_LowNesting"
    }
)

Test-Function -Name "Vérifier que la fonction New-PowerShellComplexityReport fonctionne" -ScriptBlock {
    New-PowerShellComplexityReport -Results $mockResults -Format HTML -OutputPath $reportPath

    if (-not (Test-Path -Path $reportPath)) {
        throw "Le rapport HTML n'a pas été généré"
    }

    $reportContent = Get-Content -Path $reportPath -Raw
    if (-not ($reportContent -match "<html")) {
        throw "Le rapport ne contient pas de HTML valide"
    }
}

Write-Host "Contenu du rapport HTML:" -ForegroundColor Yellow
if (Test-Path -Path $reportPath) {
    $reportContent = Get-Content -Path $reportPath -Raw
    Write-Host "  Longueur du rapport HTML: $($reportContent.Length) caractères" -ForegroundColor Gray
    Write-Host "  Début du rapport HTML:" -ForegroundColor Gray
    Write-Host $reportContent.Substring(0, [Math]::Min(200, $reportContent.Length)) -ForegroundColor Gray
    Write-Host "  ..." -ForegroundColor Gray
}

# Test 5: Vérifier que la fonction New-PowerShellComplexityReport génère un rapport JSON
Test-Function -Name "Vérifier que la fonction New-PowerShellComplexityReport génère un rapport JSON" -ScriptBlock {
    $jsonReport = New-PowerShellComplexityReport -Results $mockResults -Format JSON

    if ([string]::IsNullOrEmpty($jsonReport)) {
        throw "Le rapport JSON est vide"
    }

    try {
        $jsonObject = $jsonReport | ConvertFrom-Json
        if ($jsonObject.Count -ne 3) {
            throw "Le rapport JSON ne contient pas le bon nombre d'éléments"
        }
    } catch {
        throw "Le rapport JSON n'est pas valide: $($_.Exception.Message)"
    }
}

# Test 6: Vérifier que la fonction New-PowerShellComplexityReport filtre les métriques
Test-Function -Name "Vérifier que la fonction New-PowerShellComplexityReport filtre les métriques" -ScriptBlock {
    $jsonReport = New-PowerShellComplexityReport -Results $mockResults -Format JSON -IncludeMetrics "CyclomaticComplexity"
    $jsonObject = $jsonReport | ConvertFrom-Json

    if ($jsonObject.Count -ne 2) {
        throw "Le rapport JSON ne contient pas le bon nombre d'éléments après filtrage"
    }

    if ($jsonObject[0].Metric -ne "CyclomaticComplexity" -or $jsonObject[1].Metric -ne "CyclomaticComplexity") {
        throw "Le rapport JSON ne contient pas les bonnes métriques après filtrage"
    }
}

# Nettoyer les fichiers temporaires
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
    Write-Verbose "Dossier temporaire supprimé : $tempDir"
}

Write-Host "`nTests de débogage terminés." -ForegroundColor Yellow
