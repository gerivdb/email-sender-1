# Script de test autonome pour les fonctions de parcours en largeur (BFS) de l'AST

# DÃ©finir la fonction de parcours en largeur (BFS) avancÃ©e
function Invoke-AstTraversalBFSAdvanced {
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,
        
        [Parameter(Mandatory = $false)]
        [string]$NodeType
    )
    
    $results = New-Object System.Collections.ArrayList
    $visitedNodes = New-Object System.Collections.Generic.HashSet[System.Management.Automation.Language.Ast]
    $queue = New-Object System.Collections.Generic.Queue[PSObject]
    
    # Structure pour stocker les nÅ“uds avec leur profondeur
    $nodeInfo = [PSCustomObject]@{
        Node = $Ast
        Depth = 0
    }
    
    # Ajouter le nÅ“ud racine Ã  la file d'attente
    $queue.Enqueue($nodeInfo)
    [void]$visitedNodes.Add($Ast)
    
    # Parcourir la file d'attente
    while ($queue.Count -gt 0) {
        # RÃ©cupÃ©rer le prochain nÅ“ud de la file d'attente
        $currentNodeInfo = $queue.Dequeue()
        $currentNode = $currentNodeInfo.Node
        
        # VÃ©rifier si le nÅ“ud correspond au type spÃ©cifiÃ©
        if ($NodeType) {
            $nodeTypeName = $currentNode.GetType().Name
            $typeToCheck = $NodeType
            if (-not $NodeType.EndsWith("Ast")) {
                $typeToCheck = "${NodeType}Ast"
            }
            if ($nodeTypeName -eq $NodeType -or $nodeTypeName -eq $typeToCheck) {
                [void]$results.Add($currentNode)
            }
        }
        else {
            [void]$results.Add($currentNode)
        }
        
        # Obtenir les nÅ“uds enfants
        $children = $currentNode.FindAll({ $true }, $false)
        
        # Ajouter les nÅ“uds enfants Ã  la file d'attente
        foreach ($child in $children) {
            # VÃ©rifier si le nÅ“ud a dÃ©jÃ  Ã©tÃ© visitÃ©
            if (-not $visitedNodes.Contains($child)) {
                # Marquer le nÅ“ud comme visitÃ©
                [void]$visitedNodes.Add($child)
                
                # CrÃ©er l'info du nÅ“ud enfant
                $childInfo = [PSCustomObject]@{
                    Node = $child
                    Depth = $currentNodeInfo.Depth + 1
                }
                
                # Ajouter le nÅ“ud enfant Ã  la file d'attente
                $queue.Enqueue($childInfo)
            }
        }
    }
    
    return $results
}

# DÃ©finir la fonction de parcours en largeur (BFS) originale
function Invoke-AstTraversalBFS {
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,
        
        [Parameter(Mandatory = $false)]
        [string]$NodeType
    )
    
    $results = New-Object System.Collections.ArrayList
    $queue = New-Object System.Collections.Queue
    
    # Ajouter le nÅ“ud racine Ã  la file d'attente
    $queue.Enqueue($Ast)
    
    # Parcourir la file d'attente
    while ($queue.Count -gt 0) {
        $currentNode = $queue.Dequeue()
        
        # VÃ©rifier si le nÅ“ud correspond au type spÃ©cifiÃ©
        if ($NodeType) {
            $nodeTypeName = $currentNode.GetType().Name
            $typeToCheck = $NodeType
            if (-not $NodeType.EndsWith("Ast")) {
                $typeToCheck = "${NodeType}Ast"
            }
            if ($nodeTypeName -eq $NodeType -or $nodeTypeName -eq $typeToCheck) {
                [void]$results.Add($currentNode)
            }
        }
        else {
            [void]$results.Add($currentNode)
        }
        
        # Ajouter les nÅ“uds enfants Ã  la file d'attente
        $children = $currentNode.FindAll({ $true }, $false)
        foreach ($child in $children) {
            $queue.Enqueue($child)
        }
    }
    
    return $results
}

# CrÃ©er un script PowerShell simple pour les tests
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
