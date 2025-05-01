# Script de test de performance simple pour les fonctions de parcours en largeur (BFS) de l'AST

# Importer le module AST Navigator
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\AstNavigator.psm1"
Import-Module $modulePath -Force

# CrÃ©er un script PowerShell simple pour les tests de performance
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
'@

# Analyser le script avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Test 1: Recherche de toutes les fonctions avec Invoke-AstTraversalBFS
Write-Host "Test 1: Recherche de toutes les fonctions avec Invoke-AstTraversalBFS" -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$functions = Invoke-AstTraversalBFS -Ast $ast -NodeType "FunctionDefinition"
$stopwatch.Stop()
Write-Host "  Temps d'execution: $($stopwatch.Elapsed.TotalMilliseconds) ms" -ForegroundColor Yellow
Write-Host "  Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "    $($function.Name)" -ForegroundColor Green
}

# Test 2: Recherche de toutes les fonctions avec Invoke-AstTraversalBFSAdvanced
Write-Host "`nTest 2: Recherche de toutes les fonctions avec Invoke-AstTraversalBFSAdvanced" -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$functions = Invoke-AstTraversalBFSAdvanced -Ast $ast -NodeType "FunctionDefinition"
$stopwatch.Stop()
Write-Host "  Temps d'execution: $($stopwatch.Elapsed.TotalMilliseconds) ms" -ForegroundColor Yellow
Write-Host "  Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "    $($function.Name)" -ForegroundColor Green
}

# Test 3: Recherche de toutes les variables avec Invoke-AstTraversalBFS
Write-Host "`nTest 3: Recherche de toutes les variables avec Invoke-AstTraversalBFS" -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$variables = Invoke-AstTraversalBFS -Ast $ast -NodeType "VariableExpression"
$stopwatch.Stop()
Write-Host "  Temps d'execution: $($stopwatch.Elapsed.TotalMilliseconds) ms" -ForegroundColor Yellow
Write-Host "  Nombre de variables trouvees: $($variables.Count)" -ForegroundColor Yellow

# Test 4: Recherche de toutes les variables avec Invoke-AstTraversalBFSAdvanced
Write-Host "`nTest 4: Recherche de toutes les variables avec Invoke-AstTraversalBFSAdvanced" -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$variables = Invoke-AstTraversalBFSAdvanced -Ast $ast -NodeType "VariableExpression"
$stopwatch.Stop()
Write-Host "  Temps d'execution: $($stopwatch.Elapsed.TotalMilliseconds) ms" -ForegroundColor Yellow
Write-Host "  Nombre de variables trouvees: $($variables.Count)" -ForegroundColor Yellow

Write-Host "`nTests termines avec succes!" -ForegroundColor Green
