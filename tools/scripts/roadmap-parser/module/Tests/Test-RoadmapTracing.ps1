#
# Test-RoadmapTracing.ps1
#
# Script pour tester les fonctions publiques de trace
#

# Importer le module RoadmapParser
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$publicPath = Join-Path -Path $modulePath -ChildPath "Functions\Public"

# Importer les fonctions publiques
$publicFunctions = @(
    "Trace-RoadmapFunctionEntry.ps1",
    "Trace-RoadmapFunctionExit.ps1",
    "Trace-RoadmapFunctionStep.ps1"
)

foreach ($function in $publicFunctions) {
    $functionPath = Join-Path -Path $publicPath -ChildPath $function
    if (Test-Path -Path $functionPath) {
        . $functionPath
    } else {
        Write-Warning "La fonction $function est introuvable à l'emplacement : $functionPath"
    }
}

Write-Host "Début des tests des fonctions publiques de trace..." -ForegroundColor Cyan

# Test 1: Vérifier que les fonctions sont définies
Write-Host "`nTest 1: Vérifier que les fonctions sont définies" -ForegroundColor Cyan

$functions = @(
    "Trace-RoadmapFunctionEntry",
    "Trace-RoadmapFunctionExit",
    "Trace-RoadmapFunctionStep"
)

$successCount = 0
$failureCount = 0

foreach ($function in $functions) {
    $command = Get-Command -Name $function -ErrorAction SilentlyContinue
    $success = $null -ne $command

    $status = if ($success) { "Réussi" } else { "Échoué" }
    $color = if ($success) { "Green" } else { "Red" }

    Write-Host "  Vérification de la fonction $function : $status" -ForegroundColor $color

    if ($success) {
        $successCount++
    } else {
        $failureCount++
        Write-Host "    La fonction $function n'est pas définie" -ForegroundColor Red
    }
}

Write-Host "  Résultats: $successCount réussis, $failureCount échoués" -ForegroundColor $(if ($failureCount -eq 0) { "Green" } else { "Red" })

# Test 2: Tester la fonction Trace-RoadmapFunctionEntry
Write-Host "`nTest 2: Tester la fonction Trace-RoadmapFunctionEntry" -ForegroundColor Cyan

# Définir une fonction de test
function Test-RoadmapTraceFunction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Param1,

        [Parameter(Mandatory = $false)]
        [int]$Param2 = 42
    )

    # Tracer l'entrée dans la fonction
    Trace-RoadmapFunctionEntry

    # Tracer une étape intermédiaire
    Trace-RoadmapFunctionStep -StepName "Préparation" -StepData "Préparation des données"

    # Faire quelque chose
    $result = "$Param1 - $Param2"

    # Tracer une autre étape intermédiaire
    Trace-RoadmapFunctionStep -StepName "Traitement" -StepData $result

    # Tracer la sortie de la fonction
    Trace-RoadmapFunctionExit -ReturnValue $result

    return $result
}

# Appeler la fonction de test
Write-Host "  Appel de la fonction Test-RoadmapTraceFunction avec des paramètres simples:" -ForegroundColor Cyan
$result = Test-RoadmapTraceFunction -Param1 "Test"

# Vérifier le résultat
$success = $result -eq "Test - 42"

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Résultat de la fonction: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Test - 42" -ForegroundColor Red
    Write-Host "    Résultat obtenu: $result" -ForegroundColor Red
}

# Test 3: Tester la fonction Trace-RoadmapFunctionEntry avec des paramètres complexes
Write-Host "`nTest 3: Tester la fonction Trace-RoadmapFunctionEntry avec des paramètres complexes" -ForegroundColor Cyan

# Définir une fonction de test avec des paramètres complexes
function Test-RoadmapTraceFunctionComplex {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$ComplexParam,

        [Parameter(Mandatory = $false)]
        [array]$ArrayParam = @(1, 2, 3)
    )

    # Tracer l'entrée dans la fonction
    Trace-RoadmapFunctionEntry

    # Tracer une étape intermédiaire
    Trace-RoadmapFunctionStep -StepName "Analyse des paramètres" -StepData @{
        ComplexParamCount = $ComplexParam.Count
        ArrayParamCount   = $ArrayParam.Count
    }

    # Faire quelque chose
    $result = "$($ComplexParam.Count) - $($ArrayParam.Count)"

    # Tracer une autre étape intermédiaire
    Trace-RoadmapFunctionStep -StepName "Résultat" -StepData $result

    # Tracer la sortie de la fonction
    Trace-RoadmapFunctionExit -ReturnValue $result

    return $result
}

# Appeler la fonction de test avec des paramètres complexes
Write-Host "  Appel de la fonction Test-RoadmapTraceFunctionComplex avec des paramètres complexes:" -ForegroundColor Cyan
$complexParam = @{
    Key1 = "Value1"
    Key2 = 42
    Key3 = @{
        NestedKey = "NestedValue"
    }
}
$arrayParam = @("One", "Two", "Three", "Four")
$result = Test-RoadmapTraceFunctionComplex -ComplexParam $complexParam -ArrayParam $arrayParam

# Vérifier le résultat
$success = $result -eq "3 - 4"

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Résultat de la fonction: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: 3 - 4" -ForegroundColor Red
    Write-Host "    Résultat obtenu: $result" -ForegroundColor Red
}

Write-Host "`nTests des fonctions publiques de trace terminés." -ForegroundColor Cyan
