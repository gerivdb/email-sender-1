#
# Test-TracingFunctions.ps1
#
# Script pour tester les fonctions de trace
#

# Importer le script des fonctions de trace
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$tracingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Logging\TracingFunctions.ps1"

# Créer le répertoire s'il n'existe pas
$tracingFunctionsDir = Split-Path -Parent $tracingFunctionsPath
if (-not (Test-Path -Path $tracingFunctionsDir)) {
    New-Item -Path $tracingFunctionsDir -ItemType Directory -Force | Out-Null
}

# Importer le script
. $tracingFunctionsPath

Write-Host "Début des tests des fonctions de trace..." -ForegroundColor Cyan

# Test 1: Vérifier que les fonctions sont définies
Write-Host "`nTest 1: Vérifier que les fonctions sont définies" -ForegroundColor Cyan

$functions = @(
    "Set-TracingConfiguration",
    "Get-TracingConfiguration",
    "Trace-FunctionEntry",
    "Trace-FunctionExit",
    "Trace-FunctionStep"
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

# Test 2: Tester la configuration de la trace
Write-Host "`nTest 2: Tester la configuration de la trace" -ForegroundColor Cyan

# Configurer la trace
Set-TracingConfiguration -Enabled $true -IndentSize 4 -IndentChar "-" -MaxDepth 5 -Category "TestTracing"

# Obtenir la configuration
$config = Get-TracingConfiguration

# Vérifier la configuration
$success = $config.Enabled -eq $true -and
$config.IndentSize -eq 4 -and
$config.IndentChar -eq "-" -and
$config.MaxDepth -eq 5 -and
$config.Category -eq "TestTracing"

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Configuration de la trace: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Configuration attendue: Enabled=True, IndentSize=4, IndentChar=-, MaxDepth=5, Category=TestTracing" -ForegroundColor Red
    Write-Host "    Configuration obtenue: Enabled=$($config.Enabled), IndentSize=$($config.IndentSize), IndentChar=$($config.IndentChar), MaxDepth=$($config.MaxDepth), Category=$($config.Category)" -ForegroundColor Red
}

# Test 3: Tester les fonctions de trace
Write-Host "`nTest 3: Tester les fonctions de trace" -ForegroundColor Cyan

# Définir une fonction de test
function Test-TraceFunction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Param1,

        [Parameter(Mandatory = $false)]
        [int]$Param2 = 42
    )

    # Tracer l'entrée dans la fonction
    Trace-FunctionEntry

    # Tracer une étape intermédiaire
    Trace-FunctionStep -StepName "Préparation" -StepData "Préparation des données"

    # Faire quelque chose
    $result = "$Param1 - $Param2"

    # Tracer une autre étape intermédiaire
    Trace-FunctionStep -StepName "Traitement" -StepData $result

    # Tracer la sortie de la fonction
    Trace-FunctionExit -ReturnValue $result

    return $result
}

# Configurer la trace pour afficher dans la console
Set-TracingConfiguration -Enabled $true -Level "Debug" -IndentSize 2 -IndentChar " " -Category "TestTracing"

# Appeler la fonction de test
Write-Host "  Appel de la fonction Test-TraceFunction avec des paramètres simples:" -ForegroundColor Cyan
$result = Test-TraceFunction -Param1 "Test"

# Vérifier le résultat
$success = $result -eq "Test - 42"

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Résultat de la fonction: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Test - 42" -ForegroundColor Red
    Write-Host "    Résultat obtenu: $result" -ForegroundColor Red
}

# Test 4: Tester la fonction Trace-FunctionEntry avec des paramètres complexes
Write-Host "`nTest 4: Tester la fonction Trace-FunctionEntry avec des paramètres complexes" -ForegroundColor Cyan

# Définir une fonction de test avec des paramètres complexes
function Test-TraceFunctionComplex {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$ComplexParam,

        [Parameter(Mandatory = $false)]
        [array]$ArrayParam = @(1, 2, 3)
    )

    # Tracer l'entrée dans la fonction
    Trace-FunctionEntry

    # Faire quelque chose
    $result = "$($ComplexParam.Count) - $($ArrayParam.Count)"

    # Tracer la sortie de la fonction
    Trace-FunctionExit -ReturnValue $result

    return $result
}

# Appeler la fonction de test avec des paramètres complexes
Write-Host "  Appel de la fonction Test-TraceFunctionComplex avec des paramètres complexes:" -ForegroundColor Cyan
$complexParam = @{
    Key1 = "Value1"
    Key2 = 42
    Key3 = @{
        NestedKey = "NestedValue"
    }
}
$arrayParam = @("One", "Two", "Three", "Four")
$result = Test-TraceFunctionComplex -ComplexParam $complexParam -ArrayParam $arrayParam

# Vérifier le résultat
$success = $result -eq "3 - 4"

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Résultat de la fonction: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: 3 - 4" -ForegroundColor Red
    Write-Host "    Résultat obtenu: $result" -ForegroundColor Red
}

# Test 5: Tester la gestion de la profondeur
Write-Host "`nTest 5: Tester la gestion de la profondeur" -ForegroundColor Cyan

# Définir des fonctions imbriquées
function Test-OuterFunction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Param
    )

    # Tracer l'entrée dans la fonction
    Trace-FunctionEntry

    # Appeler la fonction interne
    $result = Test-MiddleFunction -Param $Param

    # Faire quelque chose
    $finalResult = "Outer: $Param"

    # Tracer la sortie de la fonction
    Trace-FunctionExit -ReturnValue $finalResult

    return $finalResult
}

function Test-MiddleFunction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Param
    )

    # Tracer l'entrée dans la fonction
    Trace-FunctionEntry

    # Appeler la fonction interne
    $result = Test-InnerFunction -Param $Param

    # Faire quelque chose
    $finalResult = "Middle: $Param"

    # Tracer la sortie de la fonction
    Trace-FunctionExit -ReturnValue $finalResult

    return $finalResult
}

function Test-InnerFunction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Param
    )

    # Tracer l'entrée dans la fonction
    Trace-FunctionEntry

    # Faire quelque chose
    $result = "Inner: $Param"

    # Tracer la sortie de la fonction
    Trace-FunctionExit -ReturnValue $result

    return $result
}

# Configurer la trace pour afficher dans la console
Set-TracingConfiguration -Enabled $true -Level "Debug" -IndentSize 2 -IndentChar " " -MaxDepth 10 -Category "TestTracing"

# Appeler la fonction externe
Write-Host "  Appel de fonctions imbriquées avec gestion de la profondeur:" -ForegroundColor Cyan
$result = Test-OuterFunction -Param "DepthTest"

# Vérifier le résultat
$success = $result -eq "Outer: DepthTest"

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Résultat de la fonction: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Outer: DepthTest" -ForegroundColor Red
    Write-Host "    Résultat obtenu: $result" -ForegroundColor Red
}

# Test 6: Tester la limitation de profondeur
Write-Host "`nTest 6: Tester la limitation de profondeur" -ForegroundColor Cyan

# Configurer la trace avec une profondeur maximale de 1
Set-TracingConfiguration -Enabled $true -Level "Debug" -MaxDepth 1 -Category "TestTracing"

# Appeler la fonction externe
Write-Host "  Appel de fonctions imbriquées avec limitation de profondeur:" -ForegroundColor Cyan
$result = Test-OuterFunction -Param "DepthLimitTest"

# Vérifier le résultat
$success = $result -eq "Outer: DepthLimitTest"

$status = if ($success) { "Réussi" } else { "Échoué" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Résultat de la fonction: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    Résultat attendu: Outer: DepthLimitTest" -ForegroundColor Red
    Write-Host "    Résultat obtenu: $result" -ForegroundColor Red
}

# Réinitialiser la configuration
Set-TracingConfiguration -Enabled $true -Level "Debug" -IndentSize 2 -IndentChar " " -MaxDepth 10 -Category "Tracing"

Write-Host "`nTests des fonctions de trace terminés." -ForegroundColor Cyan
