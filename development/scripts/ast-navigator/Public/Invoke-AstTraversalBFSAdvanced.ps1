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

    # Initialiser les structures de donnÃ©es
    $results = New-Object System.Collections.ArrayList
    $visitedNodes = New-Object System.Collections.Generic.HashSet[System.Management.Automation.Language.Ast]
    $queue = New-Object System.Collections.Generic.Queue[PSObject]

    try {
        # Structure pour stocker les nÅ“uds avec leur profondeur
        $nodeInfo = [PSCustomObject]@{
            Node = $Ast
            Depth = 0
        }
        
        # Ajouter le nÅ“ud racine Ã  la file d'attente
        $queue.Enqueue($nodeInfo)
        [void]$visitedNodes.Add($Ast)
        
        # VÃ©rifier si le nÅ“ud racine doit Ãªtre inclus
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
            # RÃ©cupÃ©rer le prochain nÅ“ud de la file d'attente
            $currentNodeInfo = $queue.Dequeue()
            $currentNode = $currentNodeInfo.Node
            $currentDepth = $currentNodeInfo.Depth
            
            # VÃ©rifier la profondeur maximale
            if ($MaxDepth -gt 0 -and $currentDepth -ge $MaxDepth) {
                continue
            }
            
            # VÃ©rifier la profondeur minimale
            $checkDepth = $MinDepth -eq 0 -or $currentDepth -ge $MinDepth
            
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
                        Depth = $currentDepth + 1
                    }
                    
                    # Ajouter le nÅ“ud enfant Ã  la file d'attente
                    $queue.Enqueue($childInfo)
                    
                    # VÃ©rifier si le nÅ“ud enfant correspond aux critÃ¨res
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
        
        # Retourner les rÃ©sultats
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
