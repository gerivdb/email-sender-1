<#
.SYNOPSIS
    Script de test pour comparer les performances des diffÃ©rentes implÃ©mentations de parcours AST.

.DESCRIPTION
    Ce script gÃ©nÃ¨re un grand arbre syntaxique PowerShell et compare les performances des diffÃ©rentes
    implÃ©mentations de parcours AST (DFS, DFS-Enhanced, DFS-Optimized, BFS).

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de crÃ©ation: 2023-11-15
#>

# Importer le module AST Navigator
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\AstNavigator.psm1"
Import-Module $modulePath -Force

# Fonction pour gÃ©nÃ©rer un script PowerShell complexe
function New-ComplexPowerShellScript {
    param (
        [int]$FunctionCount = 50,
        [int]$NestedBlockDepth = 5,
        [int]$StatementsPerBlock = 10
    )

    $script = @"
# Script PowerShell complexe gÃ©nÃ©rÃ© pour les tests de performance
# Contient $FunctionCount fonctions avec des blocs imbriquÃ©s jusqu'Ã  une profondeur de $NestedBlockDepth

"@

    # GÃ©nÃ©rer des fonctions
    for ($i = 1; $i -le $FunctionCount; $i++) {
        $functionName = "Function-$i"
        $script += @"

function $functionName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$false)]
        [string]`$Param1,

        [Parameter(Mandatory = `$false)]
        [int]`$Param2 = 0,

        [Parameter(Mandatory = `$false)]
        [switch]`$Flag
    )

    # Corps de la fonction
    `$localVar1 = "Test"
    `$localVar2 = 42

    # Bloc conditionnel
$(New-NestedBlock -Depth $NestedBlockDepth -StatementsPerBlock $StatementsPerBlock -Indent 4)
}

"@
    }

    return $script
}

# Fonction pour gÃ©nÃ©rer des blocs imbriquÃ©s
function New-NestedBlock {
    param (
        [int]$Depth,
        [int]$StatementsPerBlock,
        [int]$Indent
    )

    $indentStr = " " * $Indent
    $block = ""

    if ($Depth -le 0) {
        # GÃ©nÃ©rer des instructions simples
        for ($i = 1; $i -le $StatementsPerBlock; $i++) {
            $block += "$indentStr`$var$i = `$Param2 + $i`n"
            $block += "$indentStr[PSCustomObject]@{ Name = `$Param1; Value = `$var$i }`n"
        }
    } else {
        # GÃ©nÃ©rer un bloc if
        $block += "$indentStr" + "if (`$Param2 -gt $(Get-Random -Minimum 0 -Maximum 100)) {`n"
        $block += New-NestedBlock -Depth ($Depth - 1) -StatementsPerBlock $StatementsPerBlock -Indent ($Indent + 4)
        $block += "$indentStr}`n"

        # GÃ©nÃ©rer un bloc else
        $block += "$indentStr" + "else {`n"
        $block += New-NestedBlock -Depth ($Depth - 1) -StatementsPerBlock $StatementsPerBlock -Indent ($Indent + 4)
        $block += "$indentStr}`n"

        # GÃ©nÃ©rer un bloc foreach
        $block += "$indentStr" + "foreach (`$item in @(1..$(Get-Random -Minimum 3 -Maximum 10))) {`n"
        $block += New-NestedBlock -Depth ($Depth - 1) -StatementsPerBlock $StatementsPerBlock -Indent ($Indent + 4)
        $block += "$indentStr}`n"

        # GÃ©nÃ©rer un bloc switch
        $block += "$indentStr" + "switch (`$Param2) {`n"
        for ($i = 1; $i -le 3; $i++) {
            $block += "$indentStr    $i {`n"
            $block += New-NestedBlock -Depth ($Depth - 1) -StatementsPerBlock ($StatementsPerBlock / 2) -Indent ($Indent + 8)
            $block += "$indentStr    }`n"
        }
        $block += "$indentStr    default {`n"
        $block += New-NestedBlock -Depth ($Depth - 1) -StatementsPerBlock ($StatementsPerBlock / 2) -Indent ($Indent + 8)
        $block += "$indentStr    }`n"
        $block += "$indentStr}`n"

        # GÃ©nÃ©rer un bloc try-catch
        $block += "$indentStr" + "try {`n"
        $block += New-NestedBlock -Depth ($Depth - 1) -StatementsPerBlock $StatementsPerBlock -Indent ($Indent + 4)
        $block += "$indentStr}`n"
        $block += "$indentStr" + "catch {`n"
        $block += New-NestedBlock -Depth ($Depth - 1) -StatementsPerBlock $StatementsPerBlock -Indent ($Indent + 4)
        $block += "$indentStr}`n"
        $block += "$indentStr" + "finally {`n"
        $block += New-NestedBlock -Depth ($Depth - 1) -StatementsPerBlock $StatementsPerBlock -Indent ($Indent + 4)
        $block += "$indentStr}`n"
    }

    return $block
}

# Fonction pour exÃ©cuter un test de performance
function Test-AstTraversalPerformance {
    param (
        [string]$FunctionName,
        [System.Management.Automation.Language.Ast]$Ast,
        [string]$NodeType = $null,
        [int]$MaxDepth = 0,
        [scriptblock]$Predicate = $null,
        [switch]$IncludeRoot,
        [int]$BatchSize = 0,
        [switch]$UseParallelProcessing,
        [int]$MaxThreads = 0
    )

    Write-Host "Test de performance pour $FunctionName" -ForegroundColor Cyan

    # PrÃ©parer les paramÃ¨tres
    $params = @{
        Ast = $Ast
    }

    if ($NodeType) {
        $params.NodeType = $NodeType
    }

    if ($MaxDepth -gt 0) {
        $params.MaxDepth = $MaxDepth
    }

    if ($Predicate) {
        $params.Predicate = $Predicate
    }

    if ($IncludeRoot) {
        $params.IncludeRoot = $true
    }

    if ($BatchSize -gt 0 -and $FunctionName -eq "Invoke-AstTraversalDFS-Optimized") {
        $params.BatchSize = $BatchSize
    }

    if ($UseParallelProcessing -and $FunctionName -eq "Invoke-AstTraversalDFS-Optimized") {
        $params.UseParallelProcessing = $true

        if ($MaxThreads -gt 0) {
            $params.MaxThreads = $MaxThreads
        }
    }

    # ExÃ©cuter le test
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $results = & $FunctionName @params
    $stopwatch.Stop()

    # Afficher les rÃ©sultats
    $elapsedTime = $stopwatch.Elapsed
    Write-Host "  Temps d'exÃ©cution: $($elapsedTime.TotalSeconds) secondes" -ForegroundColor Yellow
    Write-Host "  Nombre de nÅ“uds trouvÃ©s: $($results.Count)" -ForegroundColor Yellow

    return [PSCustomObject]@{
        FunctionName = $FunctionName
        ElapsedTime  = $elapsedTime.TotalSeconds
        ResultCount  = $results.Count
    }
}

# GÃ©nÃ©rer un script PowerShell complexe
Write-Host "GÃ©nÃ©ration d'un script PowerShell complexe pour les tests..." -ForegroundColor Green
$complexScript = New-ComplexPowerShellScript -FunctionCount 50 -NestedBlockDepth 5 -StatementsPerBlock 10

# Analyser le script avec l'AST
Write-Host "Analyse du script avec l'AST..." -ForegroundColor Green
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($complexScript, [ref]$tokens, [ref]$errors)

# VÃ©rifier s'il y a des erreurs de parsing
if ($errors.Count -gt 0) {
    Write-Host "Erreurs de parsing dÃ©tectÃ©es:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  $error" -ForegroundColor Red
    }
    exit
}

# ExÃ©cuter les tests de performance
Write-Host "`nExÃ©cution des tests de performance..." -ForegroundColor Green

# Test 1: Recherche de toutes les fonctions sans limite de profondeur
Write-Host "`nTest 1: Recherche de toutes les fonctions sans limite de profondeur" -ForegroundColor Magenta
$predicate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }

$results = @()
$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalDFS" -Ast $ast -NodeType "FunctionDefinitionAst"
$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalDFS-Enhanced" -Ast $ast -NodeType "FunctionDefinitionAst"
$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalDFS-Optimized" -Ast $ast -NodeType "FunctionDefinitionAst"
$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalDFS-Optimized" -Ast $ast -NodeType "FunctionDefinitionAst" -BatchSize 100
$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalDFS-Optimized" -Ast $ast -NodeType "FunctionDefinitionAst" -UseParallelProcessing
$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalBFS" -Ast $ast -NodeType "FunctionDefinitionAst"

# Test 2: Recherche de tous les nÅ“uds de type VariableExpressionAst avec une limite de profondeur
Write-Host "`nTest 2: Recherche de tous les nÅ“uds de type VariableExpressionAst avec une limite de profondeur" -ForegroundColor Magenta
$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalDFS" -Ast $ast -NodeType "VariableExpressionAst" -MaxDepth 10
$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalDFS-Enhanced" -Ast $ast -NodeType "VariableExpressionAst" -MaxDepth 10
$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalDFS-Optimized" -Ast $ast -NodeType "VariableExpressionAst" -MaxDepth 10
$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalDFS-Optimized" -Ast $ast -NodeType "VariableExpressionAst" -MaxDepth 10 -BatchSize 100
$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalDFS-Optimized" -Ast $ast -NodeType "VariableExpressionAst" -MaxDepth 10 -UseParallelProcessing
$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalBFS" -Ast $ast -NodeType "VariableExpressionAst" -MaxDepth 10

# Test 3: Recherche avec prÃ©dicat personnalisÃ©
Write-Host "`nTest 3: Recherche avec prÃ©dicat personnalisÃ©" -ForegroundColor Magenta
$customPredicate = { $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and $args[0].VariablePath.UserPath -like "var*" }

$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalDFS" -Ast $ast -Predicate $customPredicate
$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalDFS-Enhanced" -Ast $ast -Predicate $customPredicate
$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalDFS-Optimized" -Ast $ast -Predicate $customPredicate
$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalDFS-Optimized" -Ast $ast -Predicate $customPredicate -BatchSize 100
$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalDFS-Optimized" -Ast $ast -Predicate $customPredicate -UseParallelProcessing
$results += Test-AstTraversalPerformance -FunctionName "Invoke-AstTraversalBFS" -Ast $ast -Predicate $customPredicate

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des rÃ©sultats de performance:" -ForegroundColor Green
$results | Format-Table -Property FunctionName, ElapsedTime, ResultCount -AutoSize

# Afficher un graphique de comparaison des performances
Write-Host "`nComparaison des performances (temps d'execution en secondes):" -ForegroundColor Green
$results | Group-Object -Property FunctionName | ForEach-Object {
    $functionName = $_.Name
    $avgTime = ($_.Group | Measure-Object -Property ElapsedTime -Average).Average

    $bar = "=" * [Math]::Min(100, [Math]::Round($avgTime * 10))
    Write-Host ("{0,-30} {1,10:N3} {2}" -f $functionName, $avgTime, $bar) -ForegroundColor Yellow
}

# Afficher les amÃ©liorations de performance
Write-Host "`nAmÃ©liorations de performance par rapport Ã  Invoke-AstTraversalDFS:" -ForegroundColor Green
$baselineResults = $results | Where-Object { $_.FunctionName -eq "Invoke-AstTraversalDFS" }
$baselineAvgTime = ($baselineResults | Measure-Object -Property ElapsedTime -Average).Average

$results | Where-Object { $_.FunctionName -ne "Invoke-AstTraversalDFS" } | Group-Object -Property FunctionName | ForEach-Object {
    $functionName = $_.Name
    $avgTime = ($_.Group | Measure-Object -Property ElapsedTime -Average).Average
    $improvement = (1 - ($avgTime / $baselineAvgTime)) * 100

    Write-Host ("{0,-30} {1,10:N2}%" -f $functionName, $improvement) -ForegroundColor $(if ($improvement -gt 0) { "Green" } else { "Red" })
}
