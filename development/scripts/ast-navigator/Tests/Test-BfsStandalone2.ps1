# Script de test autonome pour la fonction de parcours en largeur (BFS) de l'AST

# DÃ©finir la fonction de parcours en largeur (BFS) de l'AST
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
        [switch]$IncludeRoot,

        [Parameter(Mandatory = $false)]
        [int]$BatchSize = 1000,

        [Parameter(Mandatory = $false)]
        [int]$MemoryLimit = 0,

        [Parameter(Mandatory = $false)]
        [string[]]$SkipNodeTypes,

        [Parameter(Mandatory = $false)]
        [int]$ProgressInterval = 0
    )

    # Initialiser les structures de donnÃ©es
    $results = New-Object System.Collections.ArrayList
    $visitedNodes = New-Object System.Collections.Generic.HashSet[System.Management.Automation.Language.Ast]
    $queue = New-Object System.Collections.Generic.Queue[PSObject]
    
    # Statistiques pour le rapport de performance
    $nodeCount = 0
    $matchedNodeCount = 0
    $batchCount = 0
    $memoryUsage = 0
    
    # DÃ©marrer un chronomÃ¨tre pour mesurer les performances
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

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
                $matchedNodeCount++
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
                # IncrÃ©menter le compteur de nÅ“uds
                $nodeCount++
                
                # VÃ©rifier si le nÅ“ud doit Ãªtre ignorÃ©
                $skipNode = $false
                if ($SkipNodeTypes) {
                    $childTypeName = $child.GetType().Name
                    foreach ($skipType in $SkipNodeTypes) {
                        $skipTypeToCheck = $skipType
                        if (-not $skipType.EndsWith("Ast")) {
                            $skipTypeToCheck = "${skipType}Ast"
                        }
                        if ($childTypeName -eq $skipType -or $childTypeName -eq $skipTypeToCheck) {
                            $skipNode = $true
                            break
                        }
                    }
                }
                
                if ($skipNode) {
                    continue
                }
                
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
                            $matchedNodeCount++
                        }
                    }
                }
                
                # Gestion de la mÃ©moire par lots
                if ($BatchSize -gt 0 -and $nodeCount % $BatchSize -eq 0) {
                    $batchCount++
                    
                    # Surveiller l'utilisation de la mÃ©moire
                    if ($MemoryLimit -gt 0) {
                        $process = Get-Process -Id $PID
                        $memoryUsageMB = [Math]::Round($process.WorkingSet64 / 1MB, 2)
                        
                        if ($memoryUsageMB -gt $MemoryLimit) {
                            Write-Verbose "Limite de mÃ©moire atteinte ($memoryUsageMB MB). Collecte des dÃ©chets..."
                            [System.GC]::Collect()
                            $memoryUsage = $memoryUsageMB
                        }
                    }
                    
                    # Afficher la progression
                    if ($ProgressInterval -gt 0 -and $nodeCount % $ProgressInterval -eq 0) {
                        Write-Progress -Activity "Parcours en largeur de l'AST" -Status "NÅ“uds traitÃ©s: $nodeCount" -PercentComplete -1
                    }
                }
            }
        }
        
        # ArrÃªter le chronomÃ¨tre
        $stopwatch.Stop()
        $elapsedTime = $stopwatch.Elapsed
        
        # Afficher les statistiques de performance
        Write-Verbose "Parcours terminÃ© en $($elapsedTime.TotalSeconds) secondes"
        Write-Verbose "NÅ“uds traitÃ©s: $nodeCount"
        Write-Verbose "NÅ“uds correspondants: $matchedNodeCount"
        Write-Verbose "Lots traitÃ©s: $batchCount"
        if ($memoryUsage -gt 0) {
            Write-Verbose "Utilisation maximale de la mÃ©moire: $memoryUsage MB"
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
        
        # ArrÃªter l'indicateur de progression
        if ($ProgressInterval -gt 0) {
            Write-Progress -Activity "Parcours en largeur de l'AST" -Completed
        }
    }
}

# DÃ©finir la fonction de parcours en largeur (BFS) originale pour comparaison
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

    # Initialiser la liste des rÃ©sultats
    $results = New-Object System.Collections.ArrayList

    # CrÃ©er une file d'attente pour le parcours en largeur
    $queue = New-Object System.Collections.Queue

    try {
        # Structure pour stocker les nÅ“uds avec leur profondeur
        $nodeInfo = @{
            Node = $Ast
            Depth = 0
        }

        # Ajouter le nÅ“ud racine Ã  la file d'attente
        $queue.Enqueue($nodeInfo)

        # VÃ©rifier si le nÅ“ud racine doit Ãªtre inclus
        if ($IncludeRoot) {
            # VÃ©rifier si le nÅ“ud racine correspond au type spÃ©cifiÃ©
            $includeRoot = $true
            
            if ($NodeType) {
                $rootTypeName = $Ast.GetType().Name
                $includeRoot = $rootTypeName -eq $NodeType -or $rootTypeName -eq "${NodeType}Ast"
            }

            # VÃ©rifier si le nÅ“ud racine correspond au prÃ©dicat spÃ©cifiÃ©
            if ($includeRoot -and $Predicate) {
                $includeRoot = & $Predicate $Ast
            }

            # Ajouter le nÅ“ud racine aux rÃ©sultats s'il correspond aux critÃ¨res
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

            # Ajouter les nÅ“uds enfants Ã  la file d'attente
            $children = $currentNode.FindAll({ $true }, $false)
            foreach ($child in $children) {
                $childInfo = @{
                    Node = $child
                    Depth = $currentDepth + 1
                }
                $queue.Enqueue($childInfo)

                # VÃ©rifier si le nÅ“ud enfant correspond au type spÃ©cifiÃ©
                $includeChild = $true
                
                if ($NodeType) {
                    $childTypeName = $child.GetType().Name
                    $includeChild = $childTypeName -eq $NodeType -or $childTypeName -eq "${NodeType}Ast"
                }

                # VÃ©rifier si le nÅ“ud enfant correspond au prÃ©dicat spÃ©cifiÃ©
                if ($includeChild -and $Predicate) {
                    $includeChild = & $Predicate $child
                }

                # Ajouter le nÅ“ud enfant aux rÃ©sultats s'il correspond aux critÃ¨res
                if ($includeChild) {
                    [void]$results.Add($child)
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
    }
}

# CrÃ©er un script PowerShell de test trÃ¨s simple
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
