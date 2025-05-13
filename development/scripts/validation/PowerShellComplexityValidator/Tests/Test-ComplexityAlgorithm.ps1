#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour l'algorithme amélioré de calcul de la complexité cyclomatique.
.DESCRIPTION
    Ce script teste l'algorithme amélioré de calcul de la complexité cyclomatique
    du module PowerShellComplexityValidator.
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
        [double]$ExpectedComplexity = 1.0
    )

    Write-Host "Test du scénario : $Name" -ForegroundColor Cyan

    # Créer le fichier de test
    $filePath = New-TestFile -Name "$Name.ps1" -Content $Content

    # Exécuter le validateur
    $results = Test-PowerShellComplexity -Path $filePath -Metrics "CyclomaticComplexity"

    # Vérifier les résultats
    if ($null -eq $results -or $results.Count -eq 0) {
        Write-Host "  Aucun résultat retourné" -ForegroundColor Red
        return $null
    }

    $functionResults = $results | Where-Object { $_.Function -ne "<Script>" }

    if ($functionResults.Count -eq 0) {
        Write-Host "  Aucune fonction trouvée" -ForegroundColor Red
        return $null
    }

    $complexity = $functionResults[0].Value

    if ($complexity -eq $ExpectedComplexity) {
        Write-Host "  Complexité correcte : $complexity" -ForegroundColor Green
    } else {
        Write-Host "  Complexité incorrecte. Attendu : $ExpectedComplexity, Obtenu : $complexity" -ForegroundColor Red
    }

    # Afficher les détails de la complexité
    $complexityDetails = $functionResults[0].ComplexityDetails
    if ($null -ne $complexityDetails) {
        Write-Host "  Détails de la complexité :" -ForegroundColor Yellow
        Write-Host "    Score de base : $($complexityDetails.BaseScore)" -ForegroundColor Gray

        if ($complexityDetails.StructureContributions.Count -gt 0) {
            Write-Host "    Structures détectées :" -ForegroundColor Gray
            foreach ($type in $complexityDetails.StructureContributions.Keys) {
                $count = $complexityDetails.StructureContributions[$type]
                $weight = $complexityDetails.WeightedStructures[$type] / $count
                Write-Host "      $type : $count (poids : $weight)" -ForegroundColor Gray
            }
        }

        if ($complexityDetails.NestingPenalty -gt 0) {
            Write-Host "    Pénalité d'imbrication : $($complexityDetails.NestingPenalty)" -ForegroundColor Gray
        }

        Write-Host "    Score total : $($complexityDetails.TotalScore)" -ForegroundColor Gray
    }

    return $results
}

# Test 1: Fonction simple sans complexité
$test1Content = @'
function Test-SimpleFunction {
    param (
        [string]$Parameter1
    )

    Write-Output "Test: $Parameter1"
}
'@

$test1Results = Test-Scenario -Name "FonctionSimple" -Content $test1Content -ExpectedComplexity 1.0

# Test 2: Fonction avec une instruction if
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

$test2Results = Test-Scenario -Name "FonctionIf" -Content $test2Content -ExpectedComplexity 2.0

# Test 3: Fonction avec une boucle for
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

$test3Results = Test-Scenario -Name "FonctionFor" -Content $test3Content -ExpectedComplexity 1.0

# Test 4: Fonction avec une instruction switch
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

$test4Results = Test-Scenario -Name "FonctionSwitch" -Content $test4Content -ExpectedComplexity 3.0

# Test 5: Fonction avec des structures imbriquées
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

$test5Results = Test-Scenario -Name "FonctionImbrication" -Content $test5Content -ExpectedComplexity 6.6

# Test 6: Fonction avec des opérateurs logiques
$test6Content = @'
function Test-LogicalOperators {
    param (
        [string]$Parameter1,
        [int]$Parameter2
    )

    if (($Parameter1 -eq "Test" -and $Parameter2 -gt 0) -or ($Parameter1 -eq "Debug" -and $Parameter2 -lt 0)) {
        Write-Output "Complex condition satisfied"
    }
}
'@

$test6Results = Test-Scenario -Name "FonctionOperateursLogiques" -Content $test6Content -ExpectedComplexity 5.0

# Test 7: Fonction très complexe
$test7Content = @'
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

$test7Results = Test-Scenario -Name "FonctionTresComplexe" -Content $test7Content -ExpectedComplexity 22.0

# Afficher un résumé des résultats
Write-Host "`nRésumé des résultats :" -ForegroundColor Yellow
$allResults = @($test1Results, $test2Results, $test3Results, $test4Results, $test5Results, $test6Results, $test7Results) | Where-Object { $null -ne $_ }
$allResults | Format-Table -Property Function, Value, Threshold, Severity, Message -AutoSize

# Nettoyer les fichiers temporaires
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
    Write-Verbose "Dossier temporaire supprimé : $tempDir"
}

Write-Host "`nTests terminés." -ForegroundColor Yellow
