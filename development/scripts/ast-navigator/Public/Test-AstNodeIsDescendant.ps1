<#
.SYNOPSIS
    VÃ©rifie si un noeud est descendant d'un autre noeud dans l'arbre syntaxique PowerShell.

.DESCRIPTION
    Cette fonction vÃ©rifie si un noeud est descendant d'un autre noeud dans l'arbre syntaxique PowerShell (AST).
    Un noeud est considÃ©rÃ© comme descendant d'un autre noeud s'il est un enfant, un petit-enfant, etc. de ce noeud.

.PARAMETER Node
    Le noeud AST Ã  vÃ©rifier.

.PARAMETER Ancestor
    Le noeud AST ancÃªtre potentiel.

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    $functionNode = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)[0]
    $variableNode = $functionNode.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)[0]
    Test-AstNodeIsDescendant -Node $variableNode -Ancestor $functionNode

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de creation: 2023-11-15
#>
function Test-AstNodeIsDescendant {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Node,

        [Parameter(Mandatory = $true, Position = 1)]
        [System.Management.Automation.Language.Ast]$Ancestor
    )

    process {
        try {
            # Si les noeuds sont identiques, retourner $false
            if ($Node -eq $Ancestor) {
                return $false
            }

            # Remonter l'arbre depuis le noeud jusqu'Ã  la racine
            $currentNode = $Node
            while ($null -ne $currentNode.Parent) {
                $currentNode = $currentNode.Parent
                
                # Si on trouve l'ancÃªtre, retourner $true
                if ($currentNode -eq $Ancestor) {
                    return $true
                }
            }

            # Si on a atteint la racine sans trouver l'ancÃªtre, retourner $false
            return $false
        }
        catch {
            Write-Error -Message "Erreur lors de la vÃ©rification de la relation de descendance : $_"
            throw
        }
    }
}
