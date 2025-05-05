<#
.SYNOPSIS
    Obtient les nÅ“uds frÃ¨res (siblings) d'un nÅ“ud donnÃ© dans l'arbre syntaxique PowerShell.

.DESCRIPTION
    Cette fonction retourne les nÅ“uds frÃ¨res (siblings) d'un nÅ“ud donnÃ© dans l'arbre syntaxique PowerShell (AST).
    Les nÅ“uds frÃ¨res sont les nÅ“uds qui partagent le mÃªme parent que le nÅ“ud donnÃ©.

.PARAMETER Node
    Le nÅ“ud AST pour lequel on souhaite obtenir les frÃ¨res.

.PARAMETER IncludeSelf
    Si spÃ©cifiÃ©, inclut le nÅ“ud lui-mÃªme dans les rÃ©sultats.

.PARAMETER SiblingType
    Type de nÅ“ud frÃ¨re Ã  filtrer. Si spÃ©cifiÃ©, seuls les frÃ¨res de ce type seront inclus dans les rÃ©sultats.

.PARAMETER Predicate
    PrÃ©dicat (ScriptBlock) pour filtrer les nÅ“uds frÃ¨res. Si spÃ©cifiÃ©, seuls les frÃ¨res pour lesquels le prÃ©dicat retourne $true seront inclus dans les rÃ©sultats.

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
    Date de crÃ©ation: 2023-11-15
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
        # Initialiser la liste des rÃ©sultats
        $results = New-Object System.Collections.ArrayList

        # Fonction pour vÃ©rifier si un nÅ“ud correspond au type spÃ©cifiÃ©
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
            # VÃ©rifier si le nÅ“ud a un parent
            if ($null -eq $Node.Parent) {
                Write-Verbose "Le noeud n'a pas de parent, donc pas de freres."
                return $results
            }

            # Obtenir le parent du nÅ“ud
            $parent = $Node.Parent

            # Obtenir tous les nÅ“uds enfants du parent
            $siblings = $parent.FindAll({ $true }, $false)

            # Parcourir les frÃ¨res
            foreach ($sibling in $siblings) {
                # VÃ©rifier si le frÃ¨re est le nÅ“ud lui-mÃªme
                if (-not $IncludeSelf -and $sibling -eq $Node) {
                    continue
                }

                # VÃ©rifier si le frÃ¨re correspond au type spÃ©cifiÃ©
                if ($SiblingType -and -not (Test-NodeType -Node $sibling -Type $SiblingType)) {
                    continue
                }

                # VÃ©rifier si le frÃ¨re correspond au prÃ©dicat spÃ©cifiÃ©
                if ($Predicate -and -not (& $Predicate $sibling)) {
                    continue
                }

                # Ajouter le frÃ¨re aux rÃ©sultats
                [void]$results.Add($sibling)
            }

            # Retourner les rÃ©sultats
            return $results
        } catch {
            Write-Error -Message "Erreur lors de la recherche des freres du noeud : $_"
            throw
        }
    }
}
