# Script de test pour la fonction Invoke-AstTraversalBFS-Enhanced

# Importer le module AST Navigator
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\AstNavigator.psm1"
Import-Module $modulePath -Force

# CrÃ©er un script PowerShell de test
$sampleCode = @'
function Get-Example {
    param (
        [string]$Name,
        [int]$Count = 0
    )

    $result = @()
    for ($i = 0; $i -lt $Count; $i++) {
        $item = [PSCustomObject]@{
            Name = "$Name-$i"
            Value = $i
        }
        $result += $item
    }

    return $result
}

function Test-Example {
    param (
        [string]$Input
    )

    if ($Input -eq "Test") {
        return $true
    }
    else {
        return $false
    }
}

# Appeler les fonctions
$data = Get-Example -Name "Item" -Count 5
foreach ($item in $data) {
    $result = Test-Example -Input $item.Name
    Write-Output "$($item.Name): $result"
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Tester la fonction Invoke-AstTraversalBFS-Enhanced
Write-Host "=== Test de Invoke-AstTraversalBFS-Enhanced ===" -ForegroundColor Cyan
Write-Host "Recherche de toutes les fonctions :" -ForegroundColor Yellow

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$functions = Invoke-AstTraversalBFS-Enhanced -Ast $ast -NodeType "FunctionDefinition" -Verbose
$stopwatch.Stop()

Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
Write-Host "Temps d'execution: $($stopwatch.Elapsed.TotalMilliseconds) ms" -ForegroundColor Yellow

foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Tester avec une profondeur minimale
Write-Host "`n=== Test avec profondeur minimale ===" -ForegroundColor Cyan

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$variables = Invoke-AstTraversalBFS-Enhanced -Ast $ast -NodeType "VariableExpression" -MinDepth 3 -Verbose
$stopwatch.Stop()

Write-Host "Nombre de variables (profondeur >= 3): $($variables.Count)" -ForegroundColor Yellow
Write-Host "Temps d'execution: $($stopwatch.Elapsed.TotalMilliseconds) ms" -ForegroundColor Yellow

# Tester avec des types de nÅ“uds Ã  ignorer
Write-Host "`n=== Test avec types de nÅ“uds Ã  ignorer ===" -ForegroundColor Cyan

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$nodes = Invoke-AstTraversalBFS-Enhanced -Ast $ast -SkipNodeTypes "VariableExpression", "StringConstantExpression" -Verbose
$stopwatch.Stop()

Write-Host "Nombre de nÅ“uds (sans variables ni constantes string): $($nodes.Count)" -ForegroundColor Yellow
Write-Host "Temps d'execution: $($stopwatch.Elapsed.TotalMilliseconds) ms" -ForegroundColor Yellow

# Comparer avec la version originale
Write-Host "`n=== Comparaison avec Invoke-AstTraversalBFS ===" -ForegroundColor Cyan

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$originalFunctions = Invoke-AstTraversalBFS -Ast $ast -NodeType "FunctionDefinition"
$stopwatch.Stop()

Write-Host "Nombre de fonctions trouvees: $($originalFunctions.Count)" -ForegroundColor Yellow
Write-Host "Temps d'execution: $($stopwatch.Elapsed.TotalMilliseconds) ms" -ForegroundColor Yellow

Write-Host "`nTest termine avec succes!" -ForegroundColor Green
