<#
.SYNOPSIS
    Effectue un parcours en profondeur (DFS) de l'arbre syntaxique PowerShell avec une approche simplifiée.

.DESCRIPTION
    Cette fonction parcourt un arbre syntaxique PowerShell (AST) en utilisant l'algorithme de parcours en profondeur (DFS).
    Elle permet de filtrer les nœuds par type et de limiter la profondeur de parcours.
    Cette implémentation utilise directement la méthode FindAll de l'AST pour une meilleure performance.

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

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Invoke-AstTraversalDFS-Simple -Ast $ast

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Invoke-AstTraversalDFS-Simple -Ast $ast -NodeType "FunctionDefinitionAst" -MaxDepth 5

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Invoke-AstTraversalDFS-Simple -Ast $ast -Predicate { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -like "Get-*" }

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de création: 2023-11-15
#>
function Invoke-AstTraversalDFS-Simple {
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

    begin {
        # Fonction pour calculer la profondeur d'un nœud
        function Get-NodeDepth {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node
            )

            $depth = 0
            $current = $Node

            while ($null -ne $current.Parent) {
                $depth++
                $current = $current.Parent
            }

            return $depth
        }
    }

    process {
        try {
            # Créer le prédicat de recherche en fonction des paramètres
            $searchPredicate = {
                param($node)

                # Si aucun type n'est spécifié et aucun prédicat n'est fourni, inclure tous les nœuds
                if (-not $NodeType -and -not $Predicate) {
                    return $true
                }

                # Vérifier si le nœud correspond au type spécifié
                $includeNode = $true
                if ($NodeType) {
                    $nodeTypeName = $node.GetType().Name
                    $includeNode = $nodeTypeName -eq $NodeType -or $nodeTypeName -eq "${NodeType}Ast"
                }

                # Vérifier si le nœud correspond au prédicat spécifié
                if ($includeNode -and $Predicate) {
                    $includeNode = & $Predicate $node
                }

                return $includeNode
            }

            # Utiliser la méthode FindAll de l'AST pour rechercher les nœuds correspondants
            $results = $Ast.FindAll($searchPredicate, $true)

            # Limiter la profondeur si nécessaire
            if ($MaxDepth -gt 0) {
                $results = $results | Where-Object {
                    $depth = Get-NodeDepth -Node $_
                    return $depth -le $MaxDepth
                }
            }

            # Filtrer le nœud racine si nécessaire
            if (-not $IncludeRoot) {
                $results = $results | Where-Object { $_ -ne $Ast }
            }

            # Retourner les résultats
            return $results
        }
        catch {
            Write-Error -Message "Erreur lors du parcours en profondeur de l'AST : $_"
            throw
        }
    }
}
