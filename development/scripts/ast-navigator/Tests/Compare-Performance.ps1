# Script de comparaison de performance très simple

# Importer le module AST Navigator
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\AstNavigator.psm1"
Import-Module $modulePath -Force

# Créer un script PowerShell simple
$sampleCode = @'
function Test-Function1 {
    param (
        [string]$Name
    )
    
    return "Hello, $Name!"
}

function Test-Function2 {
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

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Tester Invoke-AstTraversalDFS
Write-Host "Test de Invoke-AstTraversalDFS" -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$functions = Invoke-AstTraversalDFS -Ast $ast -NodeType "FunctionDefinition"
$stopwatch.Stop()
Write-Host "  Temps d'execution: $($stopwatch.Elapsed.TotalMilliseconds) ms" -ForegroundColor Yellow
Write-Host "  Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "    $($function.Name)" -ForegroundColor Green
}

# Tester Invoke-AstTraversalDFS-Enhanced
Write-Host "`nTest de Invoke-AstTraversalDFS-Enhanced" -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$functions = Invoke-AstTraversalDFS-Enhanced -Ast $ast -NodeType "FunctionDefinition"
$stopwatch.Stop()
Write-Host "  Temps d'execution: $($stopwatch.Elapsed.TotalMilliseconds) ms" -ForegroundColor Yellow
Write-Host "  Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "    $($function.Name)" -ForegroundColor Green
}

# Tester Invoke-AstTraversalDFS-Optimized
Write-Host "`nTest de Invoke-AstTraversalDFS-Optimized" -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$functions = Invoke-AstTraversalDFS-Optimized -Ast $ast -NodeType "FunctionDefinition"
$stopwatch.Stop()
Write-Host "  Temps d'execution: $($stopwatch.Elapsed.TotalMilliseconds) ms" -ForegroundColor Yellow
Write-Host "  Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "    $($function.Name)" -ForegroundColor Green
}

# Tester Invoke-AstTraversalBFS
Write-Host "`nTest de Invoke-AstTraversalBFS" -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$functions = Invoke-AstTraversalBFS -Ast $ast -NodeType "FunctionDefinition"
$stopwatch.Stop()
Write-Host "  Temps d'execution: $($stopwatch.Elapsed.TotalMilliseconds) ms" -ForegroundColor Yellow
Write-Host "  Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "    $($function.Name)" -ForegroundColor Green
}

Write-Host "`nTests termines avec succes!" -ForegroundColor Green
