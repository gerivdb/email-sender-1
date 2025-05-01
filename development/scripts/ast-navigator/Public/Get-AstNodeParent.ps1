<#
.SYNOPSIS
    Obtient le noeud parent d'un noeud donne dans l'arbre syntaxique PowerShell.

.DESCRIPTION
    Cette fonction retourne le noeud parent d'un noeud donne dans l'arbre syntaxique PowerShell (AST).
    Elle permet egalement de rechercher un parent d'un type specifique en remontant l'arbre.

.PARAMETER Node
    Le noeud AST pour lequel on souhaite obtenir le parent.

.PARAMETER ParentType
    Type de noeud parent a rechercher. Si specifie, la fonction remonte l'arbre jusqu'a trouver un parent de ce type.

.PARAMETER MaxLevels
    Nombre maximum de niveaux a remonter dans l'arbre. Si 0 ou non specifie, aucune limite n'est appliquee.

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    $functionNode = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)[0]
    Get-AstNodeParent -Node $functionNode

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    $variableNode = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)[0]
    Get-AstNodeParent -Node $variableNode -ParentType "FunctionDefinitionAst"

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de creation: 2023-11-15
#>
function Get-AstNodeParent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Node,

        [Parameter(Mandatory = $false)]
        [string]$ParentType,

        [Parameter(Mandatory = $false)]
        [int]$MaxLevels = 0
    )

    begin {
        # Fonction pour verifier si un noeud correspond au type specifie
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
            # Verifier si le noeud a un parent
            if ($null -eq $Node.Parent) {
                Write-Verbose "Le noeud n'a pas de parent."
                return $null
            }

            # Si aucun type de parent n'est specifie, retourner le parent direct
            if (-not $ParentType) {
                return $Node.Parent
            }

            # Rechercher un parent du type specifie
            $currentNode = $Node
            $level = 0

            while ($null -ne $currentNode.Parent) {
                # Verifier si le niveau maximum est atteint
                if ($MaxLevels -gt 0 -and $level -ge $MaxLevels) {
                    Write-Verbose "Niveau maximum atteint sans trouver de parent du type specifie."
                    return $null
                }

                # Passer au parent
                $currentNode = $currentNode.Parent
                $level++

                # Verifier si le parent correspond au type specifie
                if (Test-NodeType -Node $currentNode -Type $ParentType) {
                    return $currentNode
                }
            }

            # Aucun parent du type specifie n'a ete trouve
            Write-Verbose "Aucun parent du type '$ParentType' n'a ete trouve."
            return $null
        }
        catch {
            Write-Error -Message "Erreur lors de la recherche du parent du noeud : $_"
            throw
        }
    }
}
