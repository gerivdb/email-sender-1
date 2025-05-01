# Script de test autonome pour la fonction de parcours en largeur (BFS) de l'AST

# Définir la fonction de parcours en largeur (BFS) de l'AST
function Invoke-AstTraversalBFSAdvanced {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $false)]
        [string]$NodeType,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 0,

        [Parameter(Mandatory = $false)]
        [int]$MinDepth = 0,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Predicate,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeRoot
    )

    # Initialiser les structures de données
    $results = New-Object System.Collections.ArrayList
    $visitedNodes = New-Object System.Collections.Generic.HashSet[System.Management.Automation.Language.Ast]
    $queue = New-Object System.Collections.Generic.Queue[PSObject]

    try {
        # Structure pour stocker les nœuds avec leur profondeur
        $nodeInfo = [PSCustomObject]@{
            Node = $Ast
            Depth = 0
        }
        
        # Ajouter le nœud racine à la file d'attente
        $queue.Enqueue($nodeInfo)
        [void]$visitedNodes.Add($Ast)
        
        # Vérifier si le nœud racine doit être inclus
        if ($IncludeRoot) {
            $includeRoot = $true
            
            if ($NodeType) {
                $rootTypeName = $Ast.GetType().Name
                $typeToCheck = $NodeType
                if (-not $NodeType.EndsWith("Ast")) {
                    $typeToCheck = "${NodeType}Ast"
                }
                $includeRoot = $rootTypeName -eq $NodeType -or $rootTypeName -eq $typeToCheck
            }
            
            if ($includeRoot -and $Predicate) {
                $includeRoot = & $Predicate $Ast
            }
            
            if ($includeRoot) {
                [void]$results.Add($Ast)
            }
        }
        
        # Parcourir la file d'attente
        while ($queue.Count -gt 0) {
            # Récupérer le prochain nœud de la file d'attente
            $currentNodeInfo = $queue.Dequeue()
            $currentNode = $currentNodeInfo.Node
            $currentDepth = $currentNodeInfo.Depth
            
            # Vérifier la profondeur maximale
            if ($MaxDepth -gt 0 -and $currentDepth -ge $MaxDepth) {
                continue
            }
            
            # Vérifier la profondeur minimale
            $checkDepth = $MinDepth -eq 0 -or $currentDepth -ge $MinDepth
            
            # Obtenir les nœuds enfants
            $children = $currentNode.FindAll({ $true }, $false)
            
            # Ajouter les nœuds enfants à la file d'attente
            foreach ($child in $children) {
                # Vérifier si le nœud a déjà été visité
                if (-not $visitedNodes.Contains($child)) {
                    # Marquer le nœud comme visité
                    [void]$visitedNodes.Add($child)
                    
                    # Créer l'info du nœud enfant
                    $childInfo = [PSCustomObject]@{
                        Node = $child
                        Depth = $currentDepth + 1
                    }
                    
                    # Ajouter le nœud enfant à la file d'attente
                    $queue.Enqueue($childInfo)
                    
                    # Vérifier si le nœud enfant correspond aux critères
                    if ($checkDepth) {
                        $includeNode = $true
                        
                        if ($NodeType) {
                            $childTypeName = $child.GetType().Name
                            $typeToCheck = $NodeType
                            if (-not $NodeType.EndsWith("Ast")) {
                                $typeToCheck = "${NodeType}Ast"
                            }
                            $includeNode = $childTypeName -eq $NodeType -or $childTypeName -eq $typeToCheck
                        }
                        
                        if ($includeNode -and $Predicate) {
                            $includeNode = & $Predicate $child
                        }
                        
                        if ($includeNode) {
                            [void]$results.Add($child)
                        }
                    }
                }
            }
        }
        
        # Retourner les résultats
        return $results
    }
    catch {
        Write-Error -Message "Erreur lors du parcours en largeur de l'AST : $_"
        throw
    }
    finally {
        # Nettoyer les ressources
        if ($null -ne $queue) {
            $queue.Clear()
        }
        
        if ($null -ne $visitedNodes) {
            $visitedNodes.Clear()
        }
    }
}

# Définir la fonction de parcours en largeur (BFS) originale pour comparaison
function Invoke-AstTraversalBFS {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $false)]
        [string]$NodeType,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 0,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Predicate,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeRoot
    )

    # Initialiser la liste des résultats
    $results = New-Object System.Collections.ArrayList

    # Créer une file d'attente pour le parcours en largeur
    $queue = New-Object System.Collections.Queue

    try {
        # Structure pour stocker les nœuds avec leur profondeur
        $nodeInfo = @{
            Node = $Ast
            Depth = 0
        }

        # Ajouter le nœud racine à la file d'attente
        $queue.Enqueue($nodeInfo)

        # Vérifier si le nœud racine doit être inclus
        if ($IncludeRoot) {
            # Vérifier si le nœud racine correspond au type spécifié
            $includeRoot = $true
            
            if ($NodeType) {
                $rootTypeName = $Ast.GetType().Name
                $includeRoot = $rootTypeName -eq $NodeType -or $rootTypeName -eq "${NodeType}Ast"
            }

            # Vérifier si le nœud racine correspond au prédicat spécifié
            if ($includeRoot -and $Predicate) {
                $includeRoot = & $Predicate $Ast
            }

            # Ajouter le nœud racine aux résultats s'il correspond aux critères
            if ($includeRoot) {
                [void]$results.Add($Ast)
            }
        }

        # Parcourir la file d'attente
        while ($queue.Count -gt 0) {
            # Récupérer le prochain nœud de la file d'attente
            $currentNodeInfo = $queue.Dequeue()
            $currentNode = $currentNodeInfo.Node
            $currentDepth = $currentNodeInfo.Depth

            # Vérifier la profondeur maximale
            if ($MaxDepth -gt 0 -and $currentDepth -ge $MaxDepth) {
                continue
            }

            # Ajouter les nœuds enfants à la file d'attente
            $children = $currentNode.FindAll({ $true }, $false)
            foreach ($child in $children) {
                $childInfo = @{
                    Node = $child
                    Depth = $currentDepth + 1
                }
                $queue.Enqueue($childInfo)

                # Vérifier si le nœud enfant correspond au type spécifié
                $includeChild = $true
                
                if ($NodeType) {
                    $childTypeName = $child.GetType().Name
                    $includeChild = $childTypeName -eq $NodeType -or $childTypeName -eq "${NodeType}Ast"
                }

                # Vérifier si le nœud enfant correspond au prédicat spécifié
                if ($includeChild -and $Predicate) {
                    $includeChild = & $Predicate $child
                }

                # Ajouter le nœud enfant aux résultats s'il correspond aux critères
                if ($includeChild) {
                    [void]$results.Add($child)
                }
            }
        }

        # Retourner les résultats
        return $results
    }
    catch {
        Write-Error -Message "Erreur lors du parcours en largeur de l'AST : $_"
        throw
    }
    finally {
        # Nettoyer les ressources
        if ($null -ne $queue) {
            $queue.Clear()
        }
    }
}

# Créer un script PowerShell de test très simple
$sampleCode = @'
function Test-Function {
    "Hello, World!"
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Tester la fonction Invoke-AstTraversalBFSAdvanced
Write-Host "=== Test de Invoke-AstTraversalBFSAdvanced ===" -ForegroundColor Cyan
$functions = Invoke-AstTraversalBFSAdvanced -Ast $ast -NodeType "FunctionDefinition"
Write-Host "Nombre de fonctions trouvees: $($functions.Count)" -ForegroundColor Yellow
foreach ($function in $functions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

# Comparer avec la version originale
Write-Host "`n=== Comparaison avec Invoke-AstTraversalBFS ===" -ForegroundColor Cyan
$originalFunctions = Invoke-AstTraversalBFS -Ast $ast -NodeType "FunctionDefinition"
Write-Host "Nombre de fonctions trouvees: $($originalFunctions.Count)" -ForegroundColor Yellow
foreach ($function in $originalFunctions) {
    Write-Host "  Fonction: $($function.Name) (Ligne $($function.Extent.StartLineNumber))" -ForegroundColor Green
}

Write-Host "`nTest termine avec succes!" -ForegroundColor Green
