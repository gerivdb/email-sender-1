<#
.SYNOPSIS
    Effectue un parcours en profondeur (DFS) amélioré de l'arbre syntaxique PowerShell.

.DESCRIPTION
    Cette fonction parcourt récursivement un arbre syntaxique PowerShell (AST) en utilisant l'algorithme de parcours en profondeur (DFS).
    Elle implémente une logique de parcours récursif optimisée avec une gestion efficace des nœuds enfants.
    Cette version améliorée offre de meilleures performances et une meilleure gestion de la mémoire pour les grands arbres syntaxiques.

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
    Date de création: 2023-11-15
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
        # Initialiser les structures de données
        $results = New-Object System.Collections.ArrayList
        $visitedNodes = New-Object System.Collections.Generic.HashSet[System.Management.Automation.Language.Ast]
        
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
        
        # Fonction pour obtenir les nœuds enfants directs
        function Get-ChildNodes {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node
            )
            
            $childNodes = New-Object System.Collections.ArrayList
            
            # Utiliser la réflexion pour obtenir les propriétés qui contiennent des objets Ast
            $astProperties = $Node.GetType().GetProperties() | Where-Object {
                $propInfo = $_
                
                # Vérifier si la propriété est de type Ast ou une collection d'Ast
                $propType = $propInfo.PropertyType
                $isAstType = $propType.IsSubclassOf([System.Management.Automation.Language.Ast]) -or 
                             $propType -eq [System.Management.Automation.Language.Ast]
                
                $isAstCollection = $false
                if (-not $isAstType -and 
                    [System.Collections.IEnumerable].IsAssignableFrom($propType) -and 
                    $propType -ne [string]) {
                    # Pour les collections, vérifier si elles peuvent contenir des Ast
                    $isAstCollection = $true
                }
                
                return $isAstType -or $isAstCollection
            }
            
            # Extraire les enfants Ast des propriétés
            foreach ($prop in $astProperties) {
                try {
                    $propValue = $prop.GetValue($Node)
                    
                    # Ignorer les valeurs nulles
                    if ($null -eq $propValue) {
                        continue
                    }
                    
                    # Si la propriété est un Ast, l'ajouter aux enfants
                    if ($propValue -is [System.Management.Automation.Language.Ast]) {
                        [void]$childNodes.Add($propValue)
                    }
                    # Si la propriété est une collection, ajouter chaque élément Ast
                    elseif ($propValue -is [System.Collections.IEnumerable] -and $propValue -isnot [string]) {
                        foreach ($item in $propValue) {
                            if ($item -is [System.Management.Automation.Language.Ast]) {
                                [void]$childNodes.Add($item)
                            }
                        }
                    }
                }
                catch {
                    # Ignorer les erreurs d'accès aux propriétés
                    Write-Verbose "Erreur lors de l'accès à la propriété $($prop.Name): $_"
                }
            }
            
            return $childNodes
        }
        
        # Fonction récursive pour parcourir l'arbre
        function Traverse-AstRecursively {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node,
                
                [Parameter(Mandatory = $true)]
                [int]$Depth
            )
            
            # Vérifier si le nœud est null
            if ($null -eq $Node) {
                return
            }
            
            # Vérifier si le nœud a déjà été visité pour éviter les boucles infinies
            if ($visitedNodes.Contains($Node)) {
                return
            }
            
            # Ajouter le nœud à l'ensemble des nœuds visités
            [void]$visitedNodes.Add($Node)
            
            # Vérifier si la profondeur maximale est atteinte
            if ($MaxDepth -gt 0 -and $Depth -gt $MaxDepth) {
                return
            }
            
            # Vérifier si le nœud doit être inclus dans les résultats
            if (($Depth -eq 0 -and $IncludeRoot) -or $Depth -gt 0) {
                # Vérifier si le nœud correspond aux critères
                if (Test-NodeMatchesCriteria -Node $Node) {
                    [void]$results.Add($Node)
                }
            }
            
            # Obtenir les nœuds enfants directs
            $children = Get-ChildNodes -Node $Node
            
            # Parcourir récursivement les enfants
            foreach ($child in $children) {
                # Éviter la récursion infinie en vérifiant que l'enfant n'est pas null et n'est pas le parent
                if ($null -ne $child -and $child -ne $Node) {
                    Traverse-AstRecursively -Node $child -Depth ($Depth + 1)
                }
            }
        }
    }

    process {
        try {
            # Parcourir l'arbre récursivement
            Traverse-AstRecursively -Node $Ast -Depth 0
            
            # Retourner les résultats
            return $results
        }
        catch {
            Write-Error -Message "Erreur lors du parcours en profondeur de l'AST : $_"
            throw
        }
    }
}
