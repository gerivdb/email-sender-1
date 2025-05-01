<#
.SYNOPSIS
    Obtient la profondeur d'un noeud dans l'arbre syntaxique PowerShell.

.DESCRIPTION
    Cette fonction calcule la profondeur d'un noeud dans l'arbre syntaxique PowerShell (AST).
    La profondeur est le nombre de noeuds parents entre le noeud et la racine de l'arbre.

.PARAMETER Node
    Le noeud AST pour lequel on souhaite calculer la profondeur.

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    $functionNode = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)[0]
    Get-AstNodeDepth -Node $functionNode

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de creation: 2023-11-15
#>
function Get-AstNodeDepth {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Node
    )

    process {
        try {
            # Initialiser la profondeur
            $depth = 0

            # Remonter l'arbre jusqu'à la racine
            $currentNode = $Node
            while ($null -ne $currentNode.Parent) {
                $depth++
                $currentNode = $currentNode.Parent
            }

            return $depth
        }
        catch {
            Write-Error -Message "Erreur lors du calcul de la profondeur du noeud : $_"
            throw
        }
    }
}
