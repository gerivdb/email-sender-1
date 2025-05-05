<#
.SYNOPSIS
    Effectue un parcours en profondeur (DFS) amÃ©liorÃ© de l'arbre syntaxique PowerShell.

.DESCRIPTION
    Cette fonction parcourt rÃ©cursivement un arbre syntaxique PowerShell (AST) en utilisant l'algorithme de parcours en profondeur (DFS).
    Elle implÃ©mente une logique de parcours rÃ©cursif optimisÃ©e avec une gestion efficace des nÅ“uds enfants.
    Cette version amÃ©liorÃ©e offre de meilleures performances et une meilleure gestion de la mÃ©moire pour les grands arbres syntaxiques.

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
    Invoke-AstTraversalDFS-Enhanced -Ast $ast

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Invoke-AstTraversalDFS-Enhanced -Ast $ast -NodeType "FunctionDefinitionAst" -MaxDepth 5

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Invoke-AstTraversalDFS-Enhanced -Ast $ast -Predicate { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -like "Get-*" }

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de crÃ©ation: 2023-11-15
#>
function Invoke-AstTraversalDFS-Enhanced {
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
        # Initialiser les structures de donnÃ©es
        $results = New-Object System.Collections.ArrayList
        $visitedNodes = New-Object System.Collections.Generic.HashSet[System.Management.Automation.Language.Ast]
        
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
        
        # Fonction pour obtenir les nÅ“uds enfants directs
        function Get-ChildNodes {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node
            )
            
            $childNodes = New-Object System.Collections.ArrayList
            
            # Utiliser la rÃ©flexion pour obtenir les propriÃ©tÃ©s qui contiennent des objets Ast
            $astProperties = $Node.GetType().GetProperties() | Where-Object {
                $propInfo = $_
                
                # VÃ©rifier si la propriÃ©tÃ© est de type Ast ou une collection d'Ast
                $propType = $propInfo.PropertyType
                $isAstType = $propType.IsSubclassOf([System.Management.Automation.Language.Ast]) -or 
                             $propType -eq [System.Management.Automation.Language.Ast]
                
                $isAstCollection = $false
                if (-not $isAstType -and 
                    [System.Collections.IEnumerable].IsAssignableFrom($propType) -and 
                    $propType -ne [string]) {
                    # Pour les collections, vÃ©rifier si elles peuvent contenir des Ast
                    $isAstCollection = $true
                }
                
                return $isAstType -or $isAstCollection
            }
            
            # Extraire les enfants Ast des propriÃ©tÃ©s
            foreach ($prop in $astProperties) {
                try {
                    $propValue = $prop.GetValue($Node)
                    
                    # Ignorer les valeurs nulles
                    if ($null -eq $propValue) {
                        continue
                    }
                    
                    # Si la propriÃ©tÃ© est un Ast, l'ajouter aux enfants
                    if ($propValue -is [System.Management.Automation.Language.Ast]) {
                        [void]$childNodes.Add($propValue)
                    }
                    # Si la propriÃ©tÃ© est une collection, ajouter chaque Ã©lÃ©ment Ast
                    elseif ($propValue -is [System.Collections.IEnumerable] -and $propValue -isnot [string]) {
                        foreach ($item in $propValue) {
                            if ($item -is [System.Management.Automation.Language.Ast]) {
                                [void]$childNodes.Add($item)
                            }
                        }
                    }
                }
                catch {
                    # Ignorer les erreurs d'accÃ¨s aux propriÃ©tÃ©s
                    Write-Verbose "Erreur lors de l'accÃ¨s Ã  la propriÃ©tÃ© $($prop.Name): $_"
                }
            }
            
            return $childNodes
        }
        
        # Fonction rÃ©cursive pour parcourir l'arbre
        function Traverse-AstRecursively {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node,
                
                [Parameter(Mandatory = $true)]
                [int]$Depth
            )
            
            # VÃ©rifier si le nÅ“ud est null
            if ($null -eq $Node) {
                return
            }
            
            # VÃ©rifier si le nÅ“ud a dÃ©jÃ  Ã©tÃ© visitÃ© pour Ã©viter les boucles infinies
            if ($visitedNodes.Contains($Node)) {
                return
            }
            
            # Ajouter le nÅ“ud Ã  l'ensemble des nÅ“uds visitÃ©s
            [void]$visitedNodes.Add($Node)
            
            # VÃ©rifier si la profondeur maximale est atteinte
            if ($MaxDepth -gt 0 -and $Depth -gt $MaxDepth) {
                return
            }
            
            # VÃ©rifier si le nÅ“ud doit Ãªtre inclus dans les rÃ©sultats
            if (($Depth -eq 0 -and $IncludeRoot) -or $Depth -gt 0) {
                # VÃ©rifier si le nÅ“ud correspond aux critÃ¨res
                if (Test-NodeMatchesCriteria -Node $Node) {
                    [void]$results.Add($Node)
                }
            }
            
            # Obtenir les nÅ“uds enfants directs
            $children = Get-ChildNodes -Node $Node
            
            # Parcourir rÃ©cursivement les enfants
            foreach ($child in $children) {
                # Ã‰viter la rÃ©cursion infinie en vÃ©rifiant que l'enfant n'est pas null et n'est pas le parent
                if ($null -ne $child -and $child -ne $Node) {
                    Traverse-AstRecursively -Node $child -Depth ($Depth + 1)
                }
            }
        }
    }

    process {
        try {
            # Parcourir l'arbre rÃ©cursivement
            Traverse-AstRecursively -Node $Ast -Depth 0
            
            # Retourner les rÃ©sultats
            return $results
        }
        catch {
            Write-Error -Message "Erreur lors du parcours en profondeur de l'AST : $_"
            throw
        }
    }
}
