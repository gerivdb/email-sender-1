<#
.SYNOPSIS
    Compte les noeuds d'un certain type dans l'arbre syntaxique PowerShell.

.DESCRIPTION
    Cette fonction compte les noeuds d'un certain type dans l'arbre syntaxique PowerShell (AST).
    Elle permet de specifier un type de noeud et un predicat pour filtrer les noeuds a compter.

.PARAMETER Ast
    L'arbre syntaxique PowerShell a analyser. Peut etre obtenu via [System.Management.Automation.Language.Parser]::ParseFile() ou [System.Management.Automation.Language.Parser]::ParseInput().

.PARAMETER NodeType
    Type de noeud AST a compter. Si specifie, seuls les noeuds de ce type seront comptes.

.PARAMETER Predicate
    Predicat (ScriptBlock) pour filtrer les noeuds. Si specifie, seuls les noeuds pour lesquels le predicat retourne $true seront comptes.

.PARAMETER Recurse
    Si specifie, effectue une recherche recursive dans l'arbre syntaxique. Sinon, seuls les noeuds enfants directs sont comptes.

.PARAMETER Detailed
    Si specifie, retourne un objet detaille avec le nombre de noeuds par type.

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Get-AstNodeTypeCount -Ast $ast -NodeType "FunctionDefinitionAst"

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Get-AstNodeTypeCount -Ast $ast -Predicate { $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and $args[0].VariablePath.UserPath -like "temp*" } -Recurse

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Get-AstNodeTypeCount -Ast $ast -Detailed

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de creation: 2023-11-15
#>
function Get-AstNodeTypeCount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $false)]
        [string]$NodeType,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Predicate,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    process {
        try {
            # Initialiser les compteurs
            $totalCount = 0
            $typeCounts = @{}

            # CrÃ©er le prÃ©dicat de recherche
            $searchPredicate = {
                param($node)

                # VÃ©rifier si le noeud correspond au type spÃ©cifiÃ©
                $includeNode = $true

                if ($NodeType) {
                    $nodeTypeName = $node.GetType().Name
                    $includeNode = $nodeTypeName -eq $NodeType -or $nodeTypeName -eq "${NodeType}Ast"
                }

                # VÃ©rifier si le noeud correspond au prÃ©dicat spÃ©cifiÃ©
                if ($includeNode -and $Predicate) {
                    $includeNode = & $Predicate $node
                }

                return $includeNode
            }

            # Utiliser FindAll pour trouver les noeuds correspondants
            $nodes = $Ast.FindAll($searchPredicate, $true)

            # Compter les noeuds et les types
            foreach ($node in $nodes) {
                $totalCount++

                if ($Detailed) {
                    $nodeType = $node.GetType().Name
                    if (-not $typeCounts.ContainsKey($nodeType)) {
                        $typeCounts[$nodeType] = 0
                    }
                    $typeCounts[$nodeType]++
                }
            }

            # Retourner les rÃ©sultats
            if ($Detailed) {
                # Convertir le hashtable en tableau d'objets
                $typeCountsArray = $typeCounts.GetEnumerator() | ForEach-Object {
                    [PSCustomObject]@{
                        Type  = $_.Key
                        Count = $_.Value
                    }
                } | Sort-Object -Property Count -Descending

                return [PSCustomObject]@{
                    TotalCount = $totalCount
                    TypeCounts = $typeCountsArray
                }
            } else {
                return $totalCount
            }
        } catch {
            Write-Error -Message "Erreur lors du comptage des noeuds : $_"
            throw
        }
    }
}
