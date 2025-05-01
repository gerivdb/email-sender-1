# Script de test de performance simplifié

# Importer le module AST Navigator
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\AstNavigator.psm1"
Import-Module $modulePath -Force

# Créer un script PowerShell complexe
$complexScript = @'
# Script PowerShell complexe pour les tests de performance

function Get-Example1 {
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

function Get-Example2 {
    param (
        [string]$Name,
        [int]$Count = 0
    )

    $result = @()
    for ($i = 0; $i -lt $Count; $i++) {
        $item = [PSCustomObject]@{
            Name = "$Name-$i"
            Value = $i * 2
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

function Process-Data {
    param (
        [object[]]$Data
    )

    $processedData = @()
    foreach ($item in $Data) {
        $processed = [PSCustomObject]@{
            Name = $item.Name
            Value = $item.Value * 2
            IsValid = Test-Example -Input $item.Name
        }
        $processedData += $processed
    }

    return $processedData
}

# Appeler les fonctions
$data1 = Get-Example1 -Name "Item" -Count 5
$data2 = Get-Example2 -Name "Test" -Count 10
$processedData1 = Process-Data -Data $data1
$processedData2 = Process-Data -Data $data2

# Afficher les résultats
foreach ($item in $processedData1) {
    Write-Output "$($item.Name): $($item.Value) - $($item.IsValid)"
}

foreach ($item in $processedData2) {
    Write-Output "$($item.Name): $($item.Value) - $($item.IsValid)"
}
'@

# Analyser le script avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($complexScript, [ref]$tokens, [ref]$errors)

# Fonction pour exécuter un test de performance
function Test-Performance {
    param (
        [string]$FunctionName,
        [System.Management.Automation.Language.Ast]$Ast,
        [string]$NodeType = $null,
        [int]$MaxDepth = 0,
        [scriptblock]$Predicate = $null,
        [switch]$IncludeRoot,
        [int]$Iterations = 5
    )

    Write-Host "Test de performance pour $FunctionName" -ForegroundColor Cyan
    
    # Préparer les paramètres
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
    
    # Exécuter le test plusieurs fois pour obtenir une moyenne
    $times = @()
    $resultCount = 0
    
    for ($i = 0; $i -lt $Iterations; $i++) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $results = & $FunctionName @params
        $stopwatch.Stop()
        
        $times += $stopwatch.Elapsed.TotalMilliseconds
        $resultCount = $results.Count
    }
    
    # Calculer la moyenne
    $avgTime = ($times | Measure-Object -Average).Average
    
    # Afficher les résultats
    Write-Host "  Temps d'execution moyen: $($avgTime) ms" -ForegroundColor Yellow
    Write-Host "  Nombre de noeuds trouves: $resultCount" -ForegroundColor Yellow
    
    return [PSCustomObject]@{
        FunctionName = $FunctionName
        ElapsedTime = $avgTime
        ResultCount = $resultCount
    }
}

# Exécuter les tests de performance
Write-Host "`nExecution des tests de performance..." -ForegroundColor Green

# Test 1: Recherche de toutes les fonctions
Write-Host "`nTest 1: Recherche de toutes les fonctions" -ForegroundColor Magenta

$results = @()
$results += Test-Performance -FunctionName "Invoke-AstTraversalDFS" -Ast $ast -NodeType "FunctionDefinition"
$results += Test-Performance -FunctionName "Invoke-AstTraversalDFS-Enhanced" -Ast $ast -NodeType "FunctionDefinition"
$results += Test-Performance -FunctionName "Invoke-AstTraversalDFS-Optimized" -Ast $ast -NodeType "FunctionDefinition"
$results += Test-Performance -FunctionName "Invoke-AstTraversalBFS" -Ast $ast -NodeType "FunctionDefinition"

# Test 2: Recherche de tous les nœuds de type VariableExpressionAst
Write-Host "`nTest 2: Recherche de tous les noeuds de type VariableExpressionAst" -ForegroundColor Magenta

$results += Test-Performance -FunctionName "Invoke-AstTraversalDFS" -Ast $ast -NodeType "VariableExpressionAst"
$results += Test-Performance -FunctionName "Invoke-AstTraversalDFS-Enhanced" -Ast $ast -NodeType "VariableExpressionAst"
$results += Test-Performance -FunctionName "Invoke-AstTraversalDFS-Optimized" -Ast $ast -NodeType "VariableExpressionAst"
$results += Test-Performance -FunctionName "Invoke-AstTraversalBFS" -Ast $ast -NodeType "VariableExpressionAst"

# Test 3: Recherche avec prédicat personnalisé
Write-Host "`nTest 3: Recherche avec predicat personnalise" -ForegroundColor Magenta
$customPredicate = { $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and $args[0].VariablePath.UserPath -like "item*" }

$results += Test-Performance -FunctionName "Invoke-AstTraversalDFS" -Ast $ast -Predicate $customPredicate
$results += Test-Performance -FunctionName "Invoke-AstTraversalDFS-Enhanced" -Ast $ast -Predicate $customPredicate
$results += Test-Performance -FunctionName "Invoke-AstTraversalDFS-Optimized" -Ast $ast -Predicate $customPredicate
$results += Test-Performance -FunctionName "Invoke-AstTraversalBFS" -Ast $ast -Predicate $customPredicate

# Afficher un résumé des résultats
Write-Host "`nResume des resultats de performance:" -ForegroundColor Green
$results | Format-Table -Property FunctionName, ElapsedTime, ResultCount -AutoSize

# Afficher un graphique de comparaison des performances
Write-Host "`nComparaison des performances (temps d'execution en ms):" -ForegroundColor Green
$results | Group-Object -Property FunctionName | ForEach-Object {
    $functionName = $_.Name
    $avgTime = ($_.Group | Measure-Object -Property ElapsedTime -Average).Average
    
    $bar = "=" * [Math]::Min(100, [Math]::Round($avgTime / 10))
    Write-Host ("{0,-30} {1,10:N3} {2}" -f $functionName, $avgTime, $bar) -ForegroundColor Yellow
}

# Afficher les améliorations de performance
Write-Host "`nAmeliorations de performance par rapport a Invoke-AstTraversalDFS:" -ForegroundColor Green
$baselineResults = $results | Where-Object { $_.FunctionName -eq "Invoke-AstTraversalDFS" }
$baselineAvgTime = ($baselineResults | Measure-Object -Property ElapsedTime -Average).Average

$results | Where-Object { $_.FunctionName -ne "Invoke-AstTraversalDFS" } | Group-Object -Property FunctionName | ForEach-Object {
    $functionName = $_.Name
    $avgTime = ($_.Group | Measure-Object -Property ElapsedTime -Average).Average
    $improvement = (1 - ($avgTime / $baselineAvgTime)) * 100
    
    Write-Host ("{0,-30} {1,10:N2}%" -f $functionName, $improvement) -ForegroundColor $(if ($improvement -gt 0) { "Green" } else { "Red" })
}
