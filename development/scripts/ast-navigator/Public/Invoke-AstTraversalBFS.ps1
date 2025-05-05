<#
.SYNOPSIS
    Effectue un parcours en largeur (BFS) de l'arbre syntaxique PowerShell.

.DESCRIPTION
    Cette fonction parcourt un arbre syntaxique PowerShell (AST) en utilisant l'algorithme de parcours en largeur (BFS).
    Elle permet de filtrer les nÅ“uds par type, de limiter la profondeur de parcours et d'optimiser la gestion de la mÃ©moire.

.PARAMETER Ast
    L'arbre syntaxique PowerShell Ã  parcourir. Peut Ãªtre obtenu via [System.Management.Automation.Language.Parser]::ParseFile() ou [System.Management.Automation.Language.Parser]::ParseInput().

.PARAMETER NodeType
    Type de nÅ“ud AST Ã  filtrer. Si spÃ©cifiÃ©, seuls les nÅ“uds de ce type seront inclus dans les rÃ©sultats.

.PARAMETER MaxDepth
    Profondeur maximale de parcours. Si 0 ou non spÃ©cifiÃ©, aucune limite de profondeur n'est appliquÃ©e.

.PARAMETER Predicate
    PrÃ©dicat (ScriptBlock) pour filtrer les nÅ“uds. Si spÃ©cifiÃ©, seuls les nÅ“uds pour lesquels le prÃ©dicat retourne $true seront inclus dans les rÃ©sultats.

.PARAMETER IncludeRoot
    Si spÃ©cifiÃ©, inclut le nÅ“ud racine dans les rÃ©sultats.

.PARAMETER BatchSize
    Taille des lots pour le traitement des nÅ“uds. Permet d'optimiser la gestion de la mÃ©moire pour les grands arbres. La valeur par dÃ©faut est 100.

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
    Date de crÃ©ation: 2023-11-15
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
        # Initialiser la liste des rÃ©sultats
        $results = New-Object System.Collections.ArrayList

        # CrÃ©er une file d'attente pour le parcours en largeur
        $queue = New-Object System.Collections.Queue
    }

    process {
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

            # Compteur pour le traitement par lots
            $batchCounter = 0
            $currentBatch = New-Object System.Collections.ArrayList

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

                    # Gestion de la mÃ©moire par lots
                    $batchCounter++
                    if ($batchCounter -ge $BatchSize) {
                        # RÃ©initialiser le compteur
                        $batchCounter = 0
                        
                        # LibÃ©rer la mÃ©moire
                        [System.GC]::Collect()
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
    }

    end {
        # LibÃ©rer la mÃ©moire
        $queue.Clear()
        [System.GC]::Collect()
    }
}
