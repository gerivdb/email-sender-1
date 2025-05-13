#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour l'analyse de la complexité cyclomatique.
.DESCRIPTION
    Ce script teste les fonctionnalités d'analyse de la complexité cyclomatique
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
        [int]$ExpectedComplexity = 1
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

$test1Results = Test-Scenario -Name "FonctionSimple" -Content $test1Content -ExpectedComplexity 1

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

$test2Results = Test-Scenario -Name "FonctionIf" -Content $test2Content -ExpectedComplexity 2

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

$test3Results = Test-Scenario -Name "FonctionFor" -Content $test3Content -ExpectedComplexity 2

# Test 4: Fonction avec une boucle foreach
$test4Content = @'
function Test-ForEachFunction {
    param (
        [string[]]$Items
    )

    foreach ($item in $Items) {
        Write-Output "Item: $item"
    }
}
'@

$test4Results = Test-Scenario -Name "FonctionForEach" -Content $test4Content -ExpectedComplexity 2

# Test 5: Fonction avec une instruction switch
$test5Content = @'
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

$test5Results = Test-Scenario -Name "FonctionSwitch" -Content $test5Content -ExpectedComplexity 3

# Test 6: Fonction avec un bloc try/catch
$test6Content = @'
function Test-TryCatchFunction {
    param (
        [string]$Parameter1
    )

    try {
        Write-Output "Test: $Parameter1"
    }
    catch [System.Exception] {
        Write-Error "Une erreur s'est produite"
    }
    catch {
        Write-Error "Une erreur inconnue s'est produite"
    }
}
'@

$test6Results = Test-Scenario -Name "FonctionTryCatch" -Content $test6Content -ExpectedComplexity 3

# Test 7: Fonction avec des opérateurs logiques
$test7Content = @'
function Test-LogicalOperatorsFunction {
    param (
        [string]$Parameter1,
        [int]$Parameter2
    )

    if (($Parameter1 -eq "Test" -and $Parameter2 -gt 0) -or ($Parameter1 -eq "Debug" -and $Parameter2 -lt 0)) {
        Write-Output "Condition complexe satisfaite"
    }
    else {
        Write-Output "Condition complexe non satisfaite"
    }
}
'@

$test7Results = Test-Scenario -Name "FonctionOperateursLogiques" -Content $test7Content -ExpectedComplexity 5

# Test 8: Fonction avec une complexité élevée
$test8Content = @'
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
        $true {
            try {
                Write-Output "True"
            }
            catch {
                Write-Error "Error in True"
            }
        }
        $false {
            try {
                Write-Output "False"
            }
            catch {
                Write-Error "Error in False"
            }
        }
        default { Write-Output "Unknown" }
    }

    if (($Parameter1 -eq "Test" -and $Parameter2 -gt 0) -or ($Parameter1 -eq "Debug" -and $Parameter2 -lt 0)) {
        Write-Output "Complex condition satisfied"
    }
}
'@

$test8Results = Test-Scenario -Name "FonctionComplexe" -Content $test8Content -ExpectedComplexity 12

# Afficher un résumé des résultats
Write-Host "`nRésumé des résultats :" -ForegroundColor Yellow
$allResults = @($test1Results, $test2Results, $test3Results, $test4Results, $test5Results, $test6Results, $test7Results, $test8Results) | Where-Object { $null -ne $_ }
$allResults | Format-Table -Property Function, Value, Threshold, Severity, Message -AutoSize

# Nettoyer les fichiers temporaires
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
    Write-Verbose "Dossier temporaire supprimé : $tempDir"
}

Write-Host "`nTests terminés." -ForegroundColor Yellow
