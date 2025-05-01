<#
.SYNOPSIS
    Effectue un parcours securise de l'arbre syntaxique PowerShell avec gestion des erreurs et des cas limites.

.DESCRIPTION
    Cette fonction parcourt un arbre syntaxique PowerShell (AST) de maniere securisee, en gerant les erreurs et les cas limites.
    Elle permet de specifier une strategie de gestion des erreurs, de definir des limites de ressources, et de recuperer des informations detaillees sur les erreurs rencontrees.

.PARAMETER Ast
    L'arbre syntaxique PowerShell a parcourir. Peut etre obtenu via [System.Management.Automation.Language.Parser]::ParseFile() ou [System.Management.Automation.Language.Parser]::ParseInput().

.PARAMETER NodeType
    Type de noeud AST a filtrer. Si specifie, seuls les noeuds de ce type seront inclus dans les resultats.

.PARAMETER MaxDepth
    Profondeur maximale de parcours. Si 0 ou non specifie, aucune limite de profondeur n'est appliquee.

.PARAMETER Predicate
    Predicat (ScriptBlock) pour filtrer les noeuds. Si specifie, seuls les noeuds pour lesquels le predicat retourne $true seront inclus dans les resultats.

.PARAMETER ErrorHandling
    Action a effectuer en cas d'erreur. Les valeurs possibles sont : Continue (continuer le parcours), Stop (arreter le parcours), SilentlyContinue (ignorer l'erreur), et Log (enregistrer l'erreur et continuer).

.PARAMETER TimeoutSeconds
    Delai d'expiration en secondes. Si le parcours prend plus de temps que cette valeur, il sera interrompu.

.PARAMETER MaxNodes
    Nombre maximum de noeuds a traiter. Si le parcours traite plus de noeuds que cette valeur, il sera interrompu.

.PARAMETER MaxResults
    Nombre maximum de resultats a retourner. Si le parcours trouve plus de resultats que cette valeur, il sera interrompu.

.PARAMETER IncludeErrors
    Si specifie, inclut les informations sur les erreurs rencontrees dans les resultats.

.PARAMETER TraversalMethod
    Methode de parcours a utiliser. Les valeurs possibles sont : DFS (parcours en profondeur) et BFS (parcours en largeur).

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Invoke-AstTraversalSafe -Ast $ast -NodeType "FunctionDefinition" -ErrorHandling Continue

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Invoke-AstTraversalSafe -Ast $ast -MaxDepth 5 -TimeoutSeconds 10 -MaxNodes 1000 -IncludeErrors

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de creation: 2023-11-15
#>
function Invoke-AstTraversalSafe {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $false)]
        [string]$NodeType,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 0,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Predicate,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Continue', 'Stop', 'SilentlyContinue', 'Log')]
        [string]$ErrorHandling = 'Continue',

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 0,

        [Parameter(Mandatory = $false)]
        [int]$MaxNodes = 0,

        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 0,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeErrors,

        [Parameter(Mandatory = $false)]
        [ValidateSet('DFS', 'BFS')]
        [string]$TraversalMethod = 'DFS'
    )

    begin {
        # Initialiser les structures de donnees
        $results = New-Object System.Collections.ArrayList
        $errors = New-Object System.Collections.ArrayList
        $visitedNodes = New-Object System.Collections.Generic.HashSet[System.Management.Automation.Language.Ast]
        $nodeCount = 0
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Fonction pour verifier si les limites sont atteintes
        function Test-Limits {
            param (
                [Parameter(Mandatory = $false)]
                [string]$LimitType = 'None'
            )

            # Verifier le delai d'expiration
            if ($TimeoutSeconds -gt 0 -and $stopwatch.Elapsed.TotalSeconds -gt $TimeoutSeconds) {
                $message = "Delai d'expiration atteint : $($stopwatch.Elapsed.TotalSeconds) secondes"
                if ($ErrorHandling -eq 'Stop') {
                    throw [System.TimeoutException]$message
                } elseif ($ErrorHandling -eq 'Log' -or $IncludeErrors) {
                    $errorInfo = [PSCustomObject]@{
                        Type        = 'Timeout'
                        Message     = $message
                        LimitType   = $LimitType
                        ElapsedTime = $stopwatch.Elapsed.TotalSeconds
                        NodeCount   = $nodeCount
                        ResultCount = $results.Count
                    }
                    [void]$errors.Add($errorInfo)
                }
                return $true
            }

            # Verifier le nombre maximum de noeuds
            if ($MaxNodes -gt 0 -and $nodeCount -gt $MaxNodes) {
                $message = "Nombre maximum de noeuds atteint : $nodeCount"
                if ($ErrorHandling -eq 'Stop') {
                    throw [System.InvalidOperationException]$message
                } elseif ($ErrorHandling -eq 'Log' -or $IncludeErrors) {
                    $errorInfo = [PSCustomObject]@{
                        Type        = 'MaxNodes'
                        Message     = $message
                        LimitType   = $LimitType
                        ElapsedTime = $stopwatch.Elapsed.TotalSeconds
                        NodeCount   = $nodeCount
                        ResultCount = $results.Count
                    }
                    [void]$errors.Add($errorInfo)
                }
                return $true
            }

            # Verifier le nombre maximum de resultats
            if ($MaxResults -gt 0 -and $results.Count -gt $MaxResults) {
                $message = "Nombre maximum de resultats atteint : $($results.Count)"
                if ($ErrorHandling -eq 'Stop') {
                    throw [System.InvalidOperationException]$message
                } elseif ($ErrorHandling -eq 'Log' -or $IncludeErrors) {
                    $errorInfo = [PSCustomObject]@{
                        Type        = 'MaxResults'
                        Message     = $message
                        LimitType   = $LimitType
                        ElapsedTime = $stopwatch.Elapsed.TotalSeconds
                        NodeCount   = $nodeCount
                        ResultCount = $results.Count
                    }
                    [void]$errors.Add($errorInfo)
                }
                return $true
            }

            return $false
        }

        # Fonction pour verifier si un noeud correspond aux criteres
        function Test-NodeMatchesCriteria {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node
            )

            try {
                # Si aucun type n'est specifie et aucun predicat n'est fourni, inclure tous les noeuds
                if (-not $NodeType -and -not $Predicate) {
                    return $true
                }

                # Verifier si le noeud correspond au type specifie
                $includeNode = $true
                if ($NodeType) {
                    $nodeTypeName = $Node.GetType().Name
                    $includeNode = $nodeTypeName -eq $NodeType -or $nodeTypeName -eq "${NodeType}Ast"
                }

                # Verifier si le noeud correspond au predicat specifie
                if ($includeNode -and $Predicate) {
                    $includeNode = & $Predicate $Node
                }

                return $includeNode
            } catch {
                $message = "Erreur lors de la verification des criteres : $_"
                if ($ErrorHandling -eq 'Stop') {
                    throw
                } elseif ($ErrorHandling -eq 'Log' -or $IncludeErrors) {
                    $errorInfo = [PSCustomObject]@{
                        Type        = 'Criteria'
                        Message     = $message
                        Exception   = $_
                        Node        = $Node
                        NodeType    = $Node.GetType().Name
                        ElapsedTime = $stopwatch.Elapsed.TotalSeconds
                        NodeCount   = $nodeCount
                        ResultCount = $results.Count
                    }
                    [void]$errors.Add($errorInfo)
                }

                return $false
            }
        }

        # Fonction pour calculer la profondeur d'un noeud
        function Get-NodeDepth {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node
            )

            try {
                $depth = 0
                $current = $Node

                while ($null -ne $current.Parent) {
                    $depth++
                    $current = $current.Parent
                }

                return $depth
            } catch {
                $message = "Erreur lors du calcul de la profondeur : $_"
                if ($ErrorHandling -eq 'Stop') {
                    throw
                } elseif ($ErrorHandling -eq 'Log' -or $IncludeErrors) {
                    $errorInfo = [PSCustomObject]@{
                        Type        = 'Depth'
                        Message     = $message
                        Exception   = $_
                        Node        = $Node
                        NodeType    = $Node.GetType().Name
                        ElapsedTime = $stopwatch.Elapsed.TotalSeconds
                        NodeCount   = $nodeCount
                        ResultCount = $results.Count
                    }
                    [void]$errors.Add($errorInfo)
                }

                return 0
            }
        }

        # Fonction pour obtenir les noeuds enfants directs
        function Get-ChildNodes {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node
            )

            try {
                $childNodes = New-Object System.Collections.ArrayList

                # Utiliser la methode FindAll pour obtenir les noeuds enfants directs
                $children = $Node.FindAll({ $true }, $false)

                foreach ($child in $children) {
                    if ($null -ne $child -and $child -ne $Node) {
                        [void]$childNodes.Add($child)
                    }
                }

                return $childNodes
            } catch {
                $message = "Erreur lors de l'obtention des noeuds enfants : $_"
                if ($ErrorHandling -eq 'Stop') {
                    throw
                } elseif ($ErrorHandling -eq 'Log' -or $IncludeErrors) {
                    $errorInfo = [PSCustomObject]@{
                        Type        = 'Children'
                        Message     = $message
                        Exception   = $_
                        Node        = $Node
                        NodeType    = $Node.GetType().Name
                        ElapsedTime = $stopwatch.Elapsed.TotalSeconds
                        NodeCount   = $nodeCount
                        ResultCount = $results.Count
                    }
                    [void]$errors.Add($errorInfo)
                }

                return New-Object System.Collections.ArrayList
            }
        }

        # Fonction pour parcourir l'arbre en profondeur (DFS)
        function Invoke-DFS {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node,

                [Parameter(Mandatory = $true)]
                [int]$Depth
            )

            try {
                # Verifier si les limites sont atteintes
                if (Test-Limits -LimitType 'DFS') {
                    return
                }

                # Incrementer le compteur de noeuds
                $script:nodeCount++

                # Verifier si le noeud est null
                if ($null -eq $Node) {
                    return
                }

                # Verifier si le noeud a deja ete visite pour eviter les boucles infinies
                if ($visitedNodes.Contains($Node)) {
                    return
                }

                # Ajouter le noeud a l'ensemble des noeuds visites
                [void]$visitedNodes.Add($Node)

                # Verifier si la profondeur maximale est atteinte
                if ($MaxDepth -gt 0 -and $Depth -gt $MaxDepth) {
                    return
                }

                # Verifier si le noeud correspond aux criteres
                if (Test-NodeMatchesCriteria -Node $Node) {
                    [void]$results.Add($Node)

                    # Verifier si le nombre maximum de resultats est atteint
                    if (Test-Limits -LimitType 'Results') {
                        return
                    }
                }

                # Obtenir les noeuds enfants directs
                $children = Get-ChildNodes -Node $Node

                # Parcourir recursivement les enfants
                foreach ($child in $children) {
                    Invoke-DFS -Node $child -Depth ($Depth + 1)
                }
            } catch {
                $message = "Erreur lors du parcours en profondeur : $_"
                if ($ErrorHandling -eq 'Stop') {
                    throw
                } elseif ($ErrorHandling -eq 'Log' -or $IncludeErrors) {
                    $errorInfo = [PSCustomObject]@{
                        Type        = 'DFS'
                        Message     = $message
                        Exception   = $_
                        Node        = $Node
                        NodeType    = $Node.GetType().Name
                        Depth       = $Depth
                        ElapsedTime = $stopwatch.Elapsed.TotalSeconds
                        NodeCount   = $nodeCount
                        ResultCount = $results.Count
                    }
                    [void]$errors.Add($errorInfo)
                }
            }
        }

        # Fonction pour parcourir l'arbre en largeur (BFS)
        function Invoke-BFS {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$RootNode
            )

            try {
                # Creer une file d'attente pour le parcours en largeur
                $queue = New-Object System.Collections.Queue

                # Structure pour stocker les noeuds avec leur profondeur
                $nodeInfo = @{
                    Node  = $RootNode
                    Depth = 0
                }

                # Ajouter le noeud racine a la file d'attente
                $queue.Enqueue($nodeInfo)

                # Ajouter le noeud racine a l'ensemble des noeuds visites
                [void]$visitedNodes.Add($RootNode)

                # Parcourir la file d'attente
                while ($queue.Count -gt 0) {
                    # Verifier si les limites sont atteintes
                    if (Test-Limits -LimitType 'BFS') {
                        return
                    }

                    # Recuperer le prochain noeud de la file d'attente
                    $currentNodeInfo = $queue.Dequeue()
                    $currentNode = $currentNodeInfo.Node
                    $currentDepth = $currentNodeInfo.Depth

                    # Incrementer le compteur de noeuds
                    $script:nodeCount++

                    # Verifier si la profondeur maximale est atteinte
                    if ($MaxDepth -gt 0 -and $currentDepth -gt $MaxDepth) {
                        continue
                    }

                    # Verifier si le noeud correspond aux criteres
                    if (Test-NodeMatchesCriteria -Node $currentNode) {
                        [void]$results.Add($currentNode)

                        # Verifier si le nombre maximum de resultats est atteint
                        if (Test-Limits -LimitType 'Results') {
                            return
                        }
                    }

                    # Obtenir les noeuds enfants directs
                    $children = Get-ChildNodes -Node $currentNode

                    # Ajouter les noeuds enfants a la file d'attente
                    foreach ($child in $children) {
                        if ($null -ne $child -and $child -ne $currentNode -and -not $visitedNodes.Contains($child)) {
                            $childInfo = @{
                                Node  = $child
                                Depth = $currentDepth + 1
                            }
                            $queue.Enqueue($childInfo)
                            [void]$visitedNodes.Add($child)
                        }
                    }
                }
            } catch {
                $message = "Erreur lors du parcours en largeur : $_"
                if ($ErrorHandling -eq 'Stop') {
                    throw
                } elseif ($ErrorHandling -eq 'Log' -or $IncludeErrors) {
                    $errorInfo = [PSCustomObject]@{
                        Type        = 'BFS'
                        Message     = $message
                        Exception   = $_
                        Node        = $RootNode
                        NodeType    = $RootNode.GetType().Name
                        ElapsedTime = $stopwatch.Elapsed.TotalSeconds
                        NodeCount   = $nodeCount
                        ResultCount = $results.Count
                    }
                    [void]$errors.Add($errorInfo)
                }
            }
        }
    }

    process {
        try {
            # Verifier si l'AST est null
            if ($null -eq $Ast) {
                $message = "L'AST fourni est null."
                if ($ErrorHandling -eq 'Stop') {
                    throw [System.ArgumentNullException]"Ast", $message
                } elseif ($ErrorHandling -eq 'Log' -or $IncludeErrors) {
                    $errorInfo = [PSCustomObject]@{
                        Type        = 'NullAst'
                        Message     = $message
                        ElapsedTime = $stopwatch.Elapsed.TotalSeconds
                        NodeCount   = $nodeCount
                        ResultCount = $results.Count
                    }
                    [void]$errors.Add($errorInfo)
                }

                # Retourner les resultats
                if ($IncludeErrors) {
                    return [PSCustomObject]@{
                        Results           = $results
                        Errors            = $errors
                        ElapsedTime       = $stopwatch.Elapsed.TotalSeconds
                        NodeCount         = $nodeCount
                        VisitedNodesCount = $visitedNodes.Count
                    }
                } else {
                    return $results
                }
            }

            # Parcourir l'arbre en fonction de la methode specifiee
            if ($TraversalMethod -eq 'DFS') {
                Invoke-DFS -Node $Ast -Depth 0
            } else {
                Invoke-BFS -Node $Ast
            }

            # Arreter le chronometre
            $stopwatch.Stop()

            # Retourner les resultats
            if ($IncludeErrors) {
                return [PSCustomObject]@{
                    Results           = $results
                    Errors            = $errors
                    ElapsedTime       = $stopwatch.Elapsed.TotalSeconds
                    NodeCount         = $nodeCount
                    VisitedNodesCount = $visitedNodes.Count
                }
            } else {
                return $results
            }
        } catch {
            # Arreter le chronometre
            $stopwatch.Stop()

            $message = "Erreur lors du parcours de l'AST : $_"
            if ($ErrorHandling -eq 'Stop') {
                throw
            } elseif ($ErrorHandling -eq 'Log' -or $IncludeErrors) {
                $errorInfo = [PSCustomObject]@{
                    Type        = 'Process'
                    Message     = $message
                    Exception   = $_
                    ElapsedTime = $stopwatch.Elapsed.TotalSeconds
                    NodeCount   = $nodeCount
                    ResultCount = $results.Count
                }
                [void]$errors.Add($errorInfo)
            }

            # Retourner les resultats
            if ($IncludeErrors) {
                return [PSCustomObject]@{
                    Results           = $results
                    Errors            = $errors
                    ElapsedTime       = $stopwatch.Elapsed.TotalSeconds
                    NodeCount         = $nodeCount
                    VisitedNodesCount = $visitedNodes.Count
                }
            } else {
                return $results
            }
        }
    }
}
