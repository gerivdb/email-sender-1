# Script de test pour la fonction Get-AstNodeTypeCount

# Importer la fonction Get-AstNodeTypeCount
. "$PSScriptRoot\..\Public\Get-AstNodeTypeCount.ps1"

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
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Test 1: Compter les fonctions
Write-Host "Test 1: Compter les fonctions" -ForegroundColor Cyan
$functionCount = Get-AstNodeTypeCount -Ast $ast -NodeType "FunctionDefinition"
Write-Host "  Nombre de fonctions: $functionCount" -ForegroundColor Yellow

# Test 2: Compter les variables
Write-Host "`nTest 2: Compter les variables" -ForegroundColor Cyan
$variableCount = Get-AstNodeTypeCount -Ast $ast -NodeType "VariableExpression"
Write-Host "  Nombre de variables: $variableCount" -ForegroundColor Yellow

# Test 3: Compter les noeuds avec un predicat personnalise
Write-Host "`nTest 3: Compter les noeuds avec un predicat personnalise" -ForegroundColor Cyan
$customCount = Get-AstNodeTypeCount -Ast $ast -Predicate { $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and $args[0].VariablePath.UserPath -like "item*" }
Write-Host "  Nombre de variables 'item*': $customCount" -ForegroundColor Yellow

# Test 4: Obtenir un rapport detaille
Write-Host "`nTest 4: Obtenir un rapport detaille" -ForegroundColor Cyan
$detailedReport = Get-AstNodeTypeCount -Ast $ast -Detailed
Write-Host "  Nombre total de noeuds: $($detailedReport.TotalCount)" -ForegroundColor Yellow
Write-Host "  Repartition par type:" -ForegroundColor Yellow
$detailedReport.TypeCounts | Format-Table -AutoSize

Write-Host "`nTests termines avec succes!" -ForegroundColor Green
