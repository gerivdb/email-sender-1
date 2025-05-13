#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le module PowerShellComplexityValidator.
.DESCRIPTION
    Ce script teste les fonctionnalités du module PowerShellComplexityValidator
    en validant différents scénarios d'analyse de complexité PowerShell.
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

# Fonction pour exécuter un test
function Test-Scenario {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [string[]]$Metrics = @("CyclomaticComplexity", "NestingDepth", "FunctionLength", "ParameterCount"),

        [Parameter(Mandatory = $false)]
        [int]$ExpectedResultCount = 0
    )

    Write-Host "Test du scénario : $Name" -ForegroundColor Cyan

    # Créer le fichier de test
    $filePath = New-TestFile -Name "$Name.ps1" -Content $Content

    # Exécuter le validateur
    $results = Test-PowerShellComplexity -Path $filePath -Metrics $Metrics

    # Vérifier les résultats
    $resultCount = if ($null -eq $results) { 0 } else { $results.Count }

    if ($resultCount -eq $ExpectedResultCount) {
        Write-Host "  Nombre de résultats correct : $resultCount" -ForegroundColor Green
    } else {
        Write-Host "  Nombre de résultats incorrect. Attendu : $ExpectedResultCount, Obtenu : $resultCount" -ForegroundColor Red
    }

    return $results
}

# Test 1: Fichier simple sans complexité
$test1Content = @'
function Test-SimpleFunction {
    param (
        [string]$Parameter1
    )

    Write-Output "Test: $Parameter1"
}
'@

Test-Scenario -Name "FichierSimple" -Content $test1Content -ExpectedResultCount 0

# Test 2: Fichier avec complexité cyclomatique
$test2Content = @'
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

Test-Scenario -Name "FichierComplexe" -Content $test2Content -ExpectedResultCount 0

# Test 3: Fichier avec imbrication profonde
$test3Content = @'
function Test-DeepNesting {
    param (
        [int]$Depth
    )

    if ($Depth -gt 0) {
        if ($Depth -gt 1) {
            if ($Depth -gt 2) {
                if ($Depth -gt 3) {
                    if ($Depth -gt 4) {
                        if ($Depth -gt 5) {
                            Write-Output "Very deep: $Depth"
                        }
                        else {
                            Write-Output "Deep: $Depth"
                        }
                    }
                    else {
                        Write-Output "Medium: $Depth"
                    }
                }
                else {
                    Write-Output "Shallow: $Depth"
                }
            }
            else {
                Write-Output "Very shallow: $Depth"
            }
        }
        else {
            Write-Output "Almost none: $Depth"
        }
    }
    else {
        Write-Output "No depth: $Depth"
    }
}
'@

Test-Scenario -Name "FichierImbrication" -Content $test3Content -ExpectedResultCount 0

# Test 4: Fichier avec fonction longue
$test4Content = @'
function Test-LongFunction {
    param (
        [int]$Count
    )

    $result = @()

    # Générer beaucoup de lignes
    for ($i = 0; $i -lt $Count; $i++) {
        $result += "Line $i"
        $result += "Line $i - 1"
        $result += "Line $i - 2"
        $result += "Line $i - 3"
        $result += "Line $i - 4"
        $result += "Line $i - 5"
        $result += "Line $i - 6"
        $result += "Line $i - 7"
        $result += "Line $i - 8"
        $result += "Line $i - 9"
    }

    return $result
}
'@

Test-Scenario -Name "FichierLong" -Content $test4Content -ExpectedResultCount 0

# Test 5: Fichier avec beaucoup de paramètres
$test5Content = @'
function Test-ManyParameters {
    param (
        [string]$Parameter1,
        [string]$Parameter2,
        [string]$Parameter3,
        [string]$Parameter4,
        [string]$Parameter5,
        [string]$Parameter6,
        [string]$Parameter7,
        [string]$Parameter8,
        [string]$Parameter9,
        [string]$Parameter10,
        [string]$Parameter11,
        [string]$Parameter12
    )

    Write-Output "Many parameters: $Parameter1, $Parameter2, ..."
}
'@

Test-Scenario -Name "FichierParametres" -Content $test5Content -ExpectedResultCount 0

# Test 6: Génération de rapport
$reportPath = Join-Path -Path $tempDir -ChildPath "ComplexityReport.html"

# Créer des résultats de test fictifs pour la génération du rapport
$mockResults = @(
    [PSCustomObject]@{
        Path      = "C:\Scripts\Test1.ps1"
        Line      = 10
        Function  = "Test-Function1"
        Metric    = "CyclomaticComplexity"
        Value     = 15
        Threshold = 10
        Severity  = "Warning"
        Message   = "Complexité cyclomatique élevée"
        Rule      = "CyclomaticComplexity_HighComplexity"
    },
    [PSCustomObject]@{
        Path      = "C:\Scripts\Test2.ps1"
        Line      = 20
        Function  = "Test-Function2"
        Metric    = "NestingDepth"
        Value     = 6
        Threshold = 5
        Severity  = "Warning"
        Message   = "Profondeur d'imbrication élevée"
        Rule      = "NestingDepth_DeepNesting"
    }
)

New-PowerShellComplexityReport -Results $mockResults -Format HTML -OutputPath $reportPath

if (Test-Path -Path $reportPath) {
    $reportContent = Get-Content -Path $reportPath -Raw
    if ($reportContent -match "<html.*>.*</html>") {
        Write-Host "Rapport HTML généré avec succès : $reportPath" -ForegroundColor Green
    } else {
        Write-Host "Le fichier de rapport existe mais ne contient pas de HTML valide" -ForegroundColor Red
    }
} else {
    Write-Host "Échec de la génération du rapport HTML" -ForegroundColor Red
}

# Nettoyer les fichiers temporaires
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
    Write-Verbose "Dossier temporaire supprimé : $tempDir"
}

Write-Host "`nTests terminés." -ForegroundColor Yellow
