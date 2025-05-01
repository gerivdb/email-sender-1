<#
.SYNOPSIS
    Effectue un parcours en largeur (BFS) de l'arbre syntaxique PowerShell.

.DESCRIPTION
    Cette fonction parcourt un arbre syntaxique PowerShell (AST) en utilisant l'algorithme de parcours en largeur (BFS).
    Elle permet de filtrer les nœuds par type, de limiter la profondeur de parcours et d'optimiser la gestion de la mémoire.

.PARAMETER Ast
    L'arbre syntaxique PowerShell à parcourir. Peut être obtenu via [System.Management.Automation.Language.Parser]::ParseFile() ou [System.Management.Automation.Language.Parser]::ParseInput().

.PARAMETER NodeType
    Type de nœud AST à filtrer. Si spécifié, seuls les nœuds de ce type seront inclus dans les résultats.

.PARAMETER MaxDepth
    Profondeur maximale de parcours. Si 0 ou non spécifié, aucune limite de profondeur n'est appliquée.

.PARAMETER Predicate
    Prédicat (ScriptBlock) pour filtrer les nœuds. Si spécifié, seuls les nœuds pour lesquels le prédicat retourne $true seront inclus dans les résultats.

.PARAMETER IncludeRoot
    Si spécifié, inclut le nœud racine dans les résultats.

.PARAMETER BatchSize
    Taille des lots pour le traitement des nœuds. Permet d'optimiser la gestion de la mémoire pour les grands arbres. La valeur par défaut est 100.

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Invoke-AstTraversalBFS -Ast $ast

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Invoke-AstTraversalBFS -Ast $ast -NodeType "FunctionDefinitionAst" -MaxDepth 3

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Invoke-AstTraversalBFS -Ast $ast -Predicate { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -like "Get-*" }

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de création: 2023-11-15
#>
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
        [switch]$IncludeRoot,

        [Parameter(Mandatory = $false)]
        [int]$BatchSize = 100
    )

    begin {
        # Initialiser la liste des résultats
        $results = New-Object System.Collections.ArrayList

        # Créer une file d'attente pour le parcours en largeur
        $queue = New-Object System.Collections.Queue
    }

    process {
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

            # Compteur pour le traitement par lots
            $batchCounter = 0
            $currentBatch = New-Object System.Collections.ArrayList

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

                    # Gestion de la mémoire par lots
                    $batchCounter++
                    if ($batchCounter -ge $BatchSize) {
                        # Réinitialiser le compteur
                        $batchCounter = 0
                        
                        # Libérer la mémoire
                        [System.GC]::Collect()
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
    }

    end {
        # Libérer la mémoire
        $queue.Clear()
        [System.GC]::Collect()
    }
}
