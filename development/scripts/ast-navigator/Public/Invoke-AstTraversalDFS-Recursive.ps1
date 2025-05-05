<#
.SYNOPSIS
    Effectue un parcours en profondeur (DFS) rÃ©cursif de l'arbre syntaxique PowerShell.

.DESCRIPTION
    Cette fonction parcourt rÃ©cursivement un arbre syntaxique PowerShell (AST) en utilisant l'algorithme de parcours en profondeur (DFS).
    Elle permet de filtrer les nÅ“uds par type et de limiter la profondeur de parcours.
    Contrairement Ã  Invoke-AstTraversalDFS, cette fonction utilise une approche rÃ©cursive pour le parcours.

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

.PARAMETER CurrentDepth
    ParamÃ¨tre interne utilisÃ© pour suivre la profondeur actuelle lors de la rÃ©cursion. Ne pas utiliser directement.

.PARAMETER Results
    ParamÃ¨tre interne utilisÃ© pour accumuler les rÃ©sultats lors de la rÃ©cursion. Ne pas utiliser directement.

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Invoke-AstTraversalDFS-Recursive -Ast $ast

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Invoke-AstTraversalDFS-Recursive -Ast $ast -NodeType "FunctionDefinitionAst" -MaxDepth 5

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Invoke-AstTraversalDFS-Recursive -Ast $ast -Predicate { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -like "Get-*" }

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de crÃ©ation: 2023-11-15
#>
function Invoke-AstTraversalDFS-Recursive {
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

        [Parameter(DontShow)]
        [int]$CurrentDepth = 0,

        [Parameter(DontShow)]
        [System.Collections.ArrayList]$Results = $null
    )

    begin {
        # Initialiser la liste des rÃ©sultats si c'est le premier appel
        if ($null -eq $Results) {
            $Results = New-Object System.Collections.ArrayList
        }

        # Fonction pour vÃ©rifier si un nÅ“ud correspond aux critÃ¨res
        function Test-NodeMatchesCriteria {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node
            )

            # Si aucun type n'est spÃ©cifiÃ© et aucun prÃ©dicat n'est fourni, inclure tous les nÅ“uds
            if (-not $NodeType -and -not $Predicate) {
                return $true
            }

            # VÃ©rifier si le nÅ“ud correspond au type spÃ©cifiÃ©
            $includeNode = $true
            if ($NodeType) {
                $nodeTypeName = $Node.GetType().Name
                $includeNode = $nodeTypeName -eq $NodeType -or $nodeTypeName -eq "${NodeType}Ast"
            }

            # VÃ©rifier si le nÅ“ud correspond au prÃ©dicat spÃ©cifiÃ©
            if ($includeNode -and $Predicate) {
                $includeNode = & $Predicate $Node
            }

            return $includeNode
        }
    }

    process {
        try {
            # VÃ©rifier si la profondeur maximale est atteinte
            if ($MaxDepth -gt 0 -and $CurrentDepth -gt $MaxDepth) {
                return $Results
            }

            # VÃ©rifier si le nÅ“ud racine doit Ãªtre inclus
            if (($CurrentDepth -eq 0 -and $IncludeRoot) -or $CurrentDepth -gt 0) {
                # VÃ©rifier si le nÅ“ud correspond aux critÃ¨res
                if (Test-NodeMatchesCriteria -Node $Ast) {
                    [void]$Results.Add($Ast)
                }
            }

            # Parcourir rÃ©cursivement les nÅ“uds enfants directs
            # Utiliser une approche diffÃ©rente pour obtenir les enfants directs
            $children = @()

            # Obtenir les propriÃ©tÃ©s qui contiennent des objets Ast
            $astProperties = $Ast.GetType().GetProperties() | Where-Object {
                $propValue = $_.GetValue($Ast)

                # VÃ©rifier si la propriÃ©tÃ© est de type Ast ou une collection d'Ast
                ($propValue -is [System.Management.Automation.Language.Ast]) -or
                ($propValue -is [System.Collections.IEnumerable] -and
                $propValue -isnot [string] -and
                $propValue | Where-Object { $_ -is [System.Management.Automation.Language.Ast] })
            }

            # Extraire les enfants Ast des propriÃ©tÃ©s
            foreach ($prop in $astProperties) {
                $propValue = $prop.GetValue($Ast)

                # Si la propriÃ©tÃ© est un Ast, l'ajouter aux enfants
                if ($propValue -is [System.Management.Automation.Language.Ast]) {
                    $children += $propValue
                }
                # Si la propriÃ©tÃ© est une collection, ajouter chaque Ã©lÃ©ment Ast
                elseif ($propValue -is [System.Collections.IEnumerable] -and $propValue -isnot [string]) {
                    foreach ($item in $propValue) {
                        if ($item -is [System.Management.Automation.Language.Ast]) {
                            $children += $item
                        }
                    }
                }
            }

            # Parcourir rÃ©cursivement les enfants
            foreach ($child in $children) {
                # Ã‰viter la rÃ©cursion infinie en vÃ©rifiant que l'enfant n'est pas le parent
                if ($child -ne $Ast) {
                    Invoke-AstTraversalDFS-Recursive -Ast $child -NodeType $NodeType -MaxDepth $MaxDepth -Predicate $Predicate -CurrentDepth ($CurrentDepth + 1) -Results $Results
                }
            }

            # Retourner les rÃ©sultats si c'est le premier appel
            if ($CurrentDepth -eq 0) {
                return $Results
            }
        } catch {
            Write-Error -Message "Erreur lors du parcours en profondeur de l'AST : $_"
            throw
        }
    }
}
