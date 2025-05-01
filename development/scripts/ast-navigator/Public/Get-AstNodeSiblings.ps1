<#
.SYNOPSIS
    Obtient les nœuds frères (siblings) d'un nœud donné dans l'arbre syntaxique PowerShell.

.DESCRIPTION
    Cette fonction retourne les nœuds frères (siblings) d'un nœud donné dans l'arbre syntaxique PowerShell (AST).
    Les nœuds frères sont les nœuds qui partagent le même parent que le nœud donné.

.PARAMETER Node
    Le nœud AST pour lequel on souhaite obtenir les frères.

.PARAMETER IncludeSelf
    Si spécifié, inclut le nœud lui-même dans les résultats.

.PARAMETER SiblingType
    Type de nœud frère à filtrer. Si spécifié, seuls les frères de ce type seront inclus dans les résultats.

.PARAMETER Predicate
    Prédicat (ScriptBlock) pour filtrer les nœuds frères. Si spécifié, seuls les frères pour lesquels le prédicat retourne $true seront inclus dans les résultats.

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    $functionNode = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)[0]
    Get-AstNodeSiblings -Node $functionNode

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    $variableNode = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)[0]
    Get-AstNodeSiblings -Node $variableNode -SiblingType "VariableExpressionAst"

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de création: 2023-11-15
#>
function Get-AstNodeSiblings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Node,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSelf,

        [Parameter(Mandatory = $false)]
        [string]$SiblingType,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Predicate
    )

    begin {
        # Initialiser la liste des résultats
        $results = New-Object System.Collections.ArrayList

        # Fonction pour vérifier si un nœud correspond au type spécifié
        function Test-NodeType {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node,

                [Parameter(Mandatory = $true)]
                [string]$Type
            )

            $nodeTypeName = $Node.GetType().Name
            return $nodeTypeName -eq $Type -or $nodeTypeName -eq "${Type}Ast"
        }
    }

    process {
        try {
            # Vérifier si le nœud a un parent
            if ($null -eq $Node.Parent) {
                Write-Verbose "Le noeud n'a pas de parent, donc pas de freres."
                return $results
            }

            # Obtenir le parent du nœud
            $parent = $Node.Parent

            # Obtenir tous les nœuds enfants du parent
            $siblings = $parent.FindAll({ $true }, $false)

            # Parcourir les frères
            foreach ($sibling in $siblings) {
                # Vérifier si le frère est le nœud lui-même
                if (-not $IncludeSelf -and $sibling -eq $Node) {
                    continue
                }

                # Vérifier si le frère correspond au type spécifié
                if ($SiblingType -and -not (Test-NodeType -Node $sibling -Type $SiblingType)) {
                    continue
                }

                # Vérifier si le frère correspond au prédicat spécifié
                if ($Predicate -and -not (& $Predicate $sibling)) {
                    continue
                }

                # Ajouter le frère aux résultats
                [void]$results.Add($sibling)
            }

            # Retourner les résultats
            return $results
        } catch {
            Write-Error -Message "Erreur lors de la recherche des freres du noeud : $_"
            throw
        }
    }
}
