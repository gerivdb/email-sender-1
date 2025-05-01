<#
.SYNOPSIS
    Effectue un parcours en profondeur (DFS) récursif de l'arbre syntaxique PowerShell.

.DESCRIPTION
    Cette fonction parcourt récursivement un arbre syntaxique PowerShell (AST) en utilisant l'algorithme de parcours en profondeur (DFS).
    Elle permet de filtrer les nœuds par type et de limiter la profondeur de parcours.
    Contrairement à Invoke-AstTraversalDFS, cette fonction utilise une approche récursive pour le parcours.

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

.PARAMETER CurrentDepth
    Paramètre interne utilisé pour suivre la profondeur actuelle lors de la récursion. Ne pas utiliser directement.

.PARAMETER Results
    Paramètre interne utilisé pour accumuler les résultats lors de la récursion. Ne pas utiliser directement.

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
    Date de création: 2023-11-15
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
        # Initialiser la liste des résultats si c'est le premier appel
        if ($null -eq $Results) {
            $Results = New-Object System.Collections.ArrayList
        }

        # Fonction pour vérifier si un nœud correspond aux critères
        function Test-NodeMatchesCriteria {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node
            )

            # Si aucun type n'est spécifié et aucun prédicat n'est fourni, inclure tous les nœuds
            if (-not $NodeType -and -not $Predicate) {
                return $true
            }

            # Vérifier si le nœud correspond au type spécifié
            $includeNode = $true
            if ($NodeType) {
                $nodeTypeName = $Node.GetType().Name
                $includeNode = $nodeTypeName -eq $NodeType -or $nodeTypeName -eq "${NodeType}Ast"
            }

            # Vérifier si le nœud correspond au prédicat spécifié
            if ($includeNode -and $Predicate) {
                $includeNode = & $Predicate $Node
            }

            return $includeNode
        }
    }

    process {
        try {
            # Vérifier si la profondeur maximale est atteinte
            if ($MaxDepth -gt 0 -and $CurrentDepth -gt $MaxDepth) {
                return $Results
            }

            # Vérifier si le nœud racine doit être inclus
            if (($CurrentDepth -eq 0 -and $IncludeRoot) -or $CurrentDepth -gt 0) {
                # Vérifier si le nœud correspond aux critères
                if (Test-NodeMatchesCriteria -Node $Ast) {
                    [void]$Results.Add($Ast)
                }
            }

            # Parcourir récursivement les nœuds enfants directs
            # Utiliser une approche différente pour obtenir les enfants directs
            $children = @()

            # Obtenir les propriétés qui contiennent des objets Ast
            $astProperties = $Ast.GetType().GetProperties() | Where-Object {
                $propValue = $_.GetValue($Ast)

                # Vérifier si la propriété est de type Ast ou une collection d'Ast
                ($propValue -is [System.Management.Automation.Language.Ast]) -or
                ($propValue -is [System.Collections.IEnumerable] -and
                $propValue -isnot [string] -and
                $propValue | Where-Object { $_ -is [System.Management.Automation.Language.Ast] })
            }

            # Extraire les enfants Ast des propriétés
            foreach ($prop in $astProperties) {
                $propValue = $prop.GetValue($Ast)

                # Si la propriété est un Ast, l'ajouter aux enfants
                if ($propValue -is [System.Management.Automation.Language.Ast]) {
                    $children += $propValue
                }
                # Si la propriété est une collection, ajouter chaque élément Ast
                elseif ($propValue -is [System.Collections.IEnumerable] -and $propValue -isnot [string]) {
                    foreach ($item in $propValue) {
                        if ($item -is [System.Management.Automation.Language.Ast]) {
                            $children += $item
                        }
                    }
                }
            }

            # Parcourir récursivement les enfants
            foreach ($child in $children) {
                # Éviter la récursion infinie en vérifiant que l'enfant n'est pas le parent
                if ($child -ne $Ast) {
                    Invoke-AstTraversalDFS-Recursive -Ast $child -NodeType $NodeType -MaxDepth $MaxDepth -Predicate $Predicate -CurrentDepth ($CurrentDepth + 1) -Results $Results
                }
            }

            # Retourner les résultats si c'est le premier appel
            if ($CurrentDepth -eq 0) {
                return $Results
            }
        } catch {
            Write-Error -Message "Erreur lors du parcours en profondeur de l'AST : $_"
            throw
        }
    }
}
