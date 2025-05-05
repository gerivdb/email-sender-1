<#
.SYNOPSIS
    Effectue un parcours en profondeur (DFS) de l'arbre syntaxique PowerShell avec une approche simplifiÃ©e.

.DESCRIPTION
    Cette fonction parcourt un arbre syntaxique PowerShell (AST) en utilisant l'algorithme de parcours en profondeur (DFS).
    Elle permet de filtrer les nÅ“uds par type et de limiter la profondeur de parcours.
    Cette implÃ©mentation utilise directement la mÃ©thode FindAll de l'AST pour une meilleure performance.

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
    Date de crÃ©ation: 2023-11-15
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
        # Fonction pour calculer la profondeur d'un nÅ“ud
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
            # CrÃ©er le prÃ©dicat de recherche en fonction des paramÃ¨tres
            $searchPredicate = {
                param($node)

                # Si aucun type n'est spÃ©cifiÃ© et aucun prÃ©dicat n'est fourni, inclure tous les nÅ“uds
                if (-not $NodeType -and -not $Predicate) {
                    return $true
                }

                # VÃ©rifier si le nÅ“ud correspond au type spÃ©cifiÃ©
                $includeNode = $true
                if ($NodeType) {
                    $nodeTypeName = $node.GetType().Name
                    $includeNode = $nodeTypeName -eq $NodeType -or $nodeTypeName -eq "${NodeType}Ast"
                }

                # VÃ©rifier si le nÅ“ud correspond au prÃ©dicat spÃ©cifiÃ©
                if ($includeNode -and $Predicate) {
                    $includeNode = & $Predicate $node
                }

                return $includeNode
            }

            # Utiliser la mÃ©thode FindAll de l'AST pour rechercher les nÅ“uds correspondants
            $results = $Ast.FindAll($searchPredicate, $true)

            # Limiter la profondeur si nÃ©cessaire
            if ($MaxDepth -gt 0) {
                $results = $results | Where-Object {
                    $depth = Get-NodeDepth -Node $_
                    return $depth -le $MaxDepth
                }
            }

            # Filtrer le nÅ“ud racine si nÃ©cessaire
            if (-not $IncludeRoot) {
                $results = $results | Where-Object { $_ -ne $Ast }
            }

            # Retourner les rÃ©sultats
            return $results
        }
        catch {
            Write-Error -Message "Erreur lors du parcours en profondeur de l'AST : $_"
            throw
        }
    }
}
