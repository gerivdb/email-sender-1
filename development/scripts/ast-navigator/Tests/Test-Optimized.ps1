# Script de test pour la fonction Invoke-AstTraversalDFS-Optimized

# Importer le module AST Navigator
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\AstNavigator.psm1"
Import-Module $modulePath -Force

# Créer un script PowerShell de test
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

# Tester la fonction Invoke-AstTraversalDFS-Optimized
Write-Host "=== Test de Invoke-AstTraversalDFS-Optimized ===" -ForegroundColor Cyan
Write-Host "Recherche de toutes les fonctions :" -ForegroundColor Yellow

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$functions = Invoke-AstTraversalDFS-Optimized -Ast $ast -NodeType "FunctionDefinition"
$stopwatch.Stop()

Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
Write-Host "Temps d'execution: $($stopwatch.Elapsed.TotalMilliseconds) ms" -ForegroundColor Yellow

foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Tester avec le traitement par lots
Write-Host "`n=== Test avec traitement par lots ===" -ForegroundColor Cyan

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$functions = Invoke-AstTraversalDFS-Optimized -Ast $ast -NodeType "FunctionDefinition" -BatchSize 10
$stopwatch.Stop()

Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
Write-Host "Temps d'execution: $($stopwatch.Elapsed.TotalMilliseconds) ms" -ForegroundColor Yellow

# Tester avec le traitement parallèle (si PowerShell 7+)
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Write-Host "`n=== Test avec traitement parallele ===" -ForegroundColor Cyan

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $functions = Invoke-AstTraversalDFS-Optimized -Ast $ast -NodeType "FunctionDefinition" -UseParallelProcessing
    $stopwatch.Stop()

    Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
    Write-Host "Temps d'execution: $($stopwatch.Elapsed.TotalMilliseconds) ms" -ForegroundColor Yellow
}

# Comparer avec la version précédente
Write-Host "`n=== Comparaison avec Invoke-AstTraversalDFS-Enhanced ===" -ForegroundColor Cyan

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$functions = Invoke-AstTraversalDFS-Enhanced -Ast $ast -NodeType "FunctionDefinition"
$stopwatch.Stop()

Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
Write-Host "Temps d'execution: $($stopwatch.Elapsed.TotalMilliseconds) ms" -ForegroundColor Yellow

Write-Host "`nTest termine avec succes!" -ForegroundColor Green
