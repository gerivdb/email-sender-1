# Script de test simple pour la fonction Invoke-AstTraversalBFSAdvanced

# CrÃ©er un script PowerShell de test trÃ¨s simple
$sampleCode = @'
function Test-Function {
    "Hello, World!"
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# DÃ©finir la fonction de parcours en largeur (BFS) avancÃ©e
function Invoke-AstTraversalBFSAdvanced {
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

# Tester la fonction Invoke-AstTraversalBFSAdvanced
Write-Host "=== Test de Invoke-AstTraversalBFSAdvanced ===" -ForegroundColor Cyan
$functions = Invoke-AstTraversalBFSAdvanced -Ast $ast -NodeType "FunctionDefinition"
Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

Write-Host "`nTest termine avec succes!" -ForegroundColor Green
