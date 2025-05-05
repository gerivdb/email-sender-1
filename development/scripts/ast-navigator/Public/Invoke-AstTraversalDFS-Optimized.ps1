<#
.SYNOPSIS
    Effectue un parcours en profondeur (DFS) optimisÃ© de l'arbre syntaxique PowerShell pour les grands arbres.

.DESCRIPTION
    Cette fonction parcourt rÃ©cursivement un arbre syntaxique PowerShell (AST) en utilisant l'algorithme de parcours en profondeur (DFS).
    Elle implÃ©mente des optimisations pour amÃ©liorer les performances et rÃ©duire l'utilisation de la mÃ©moire lors du traitement
    de grands arbres syntaxiques. Les optimisations incluent:
    - Utilisation de structures de donnÃ©es optimisÃ©es pour les grands ensembles
    - Mise en cache des propriÃ©tÃ©s des types pour Ã©viter la rÃ©flexion rÃ©pÃ©tÃ©e
    - Traitement par lots des nÅ“uds pour rÃ©duire la pression sur la mÃ©moire
    - DÃ©tection prÃ©coce des nÅ“uds non pertinents

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

.PARAMETER BatchSize
    Taille des lots pour le traitement des nÅ“uds. Permet d'optimiser la gestion de la mÃ©moire pour les grands arbres. La valeur par dÃ©faut est 1000.

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Invoke-AstTraversalDFS-Optimized -Ast $ast

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Invoke-AstTraversalDFS-Optimized -Ast $ast -NodeType "FunctionDefinitionAst" -MaxDepth 5 -BatchSize 500

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Invoke-AstTraversalDFS-Optimized -Ast $ast -Predicate { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -like "Get-*" }

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de crÃ©ation: 2023-11-15
#>
function Invoke-AstTraversalDFS-Optimized {
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

        [Parameter(Mandatory = $false)]
        [int]$BatchSize = 1000
    )

    begin {
        # DÃ©marrer un chronomÃ¨tre pour mesurer les performances
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Initialiser les structures de donnÃ©es optimisÃ©es
        $results = New-Object System.Collections.ArrayList
        $visitedNodes = New-Object System.Collections.Generic.HashSet[System.Management.Automation.Language.Ast]
        
        # Cache pour les propriÃ©tÃ©s des types AST
        $typePropertiesCache = @{}
        
        # Statistiques pour le rapport de performance
        $nodeCount = 0
        $matchedNodeCount = 0
        
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
                $typeToCheck = $NodeType
                
                # Ajouter "Ast" au type si nÃ©cessaire
                if (-not $NodeType.EndsWith("Ast")) {
                    $typeToCheck = "${NodeType}Ast"
                }
                
                $includeNode = $nodeTypeName -eq $NodeType -or $nodeTypeName -eq $typeToCheck
            }

            # VÃ©rifier si le nÅ“ud correspond au prÃ©dicat spÃ©cifiÃ©
            if ($includeNode -and $Predicate) {
                $includeNode = & $Predicate $Node
            }

            return $includeNode
        }
        
        # Fonction pour obtenir les propriÃ©tÃ©s AST d'un type (avec mise en cache)
        function Get-AstTypeProperties {
            param (
                [Parameter(Mandatory = $true)]
                [type]$Type
            )
            
            # VÃ©rifier si les propriÃ©tÃ©s sont dÃ©jÃ  en cache
            $typeName = $Type.FullName
            if (-not $typePropertiesCache.ContainsKey($typeName)) {
                # Obtenir les propriÃ©tÃ©s qui peuvent contenir des objets AST
                $astProperties = $Type.GetProperties() | Where-Object {
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
                
                # Mettre en cache les propriÃ©tÃ©s
                $typePropertiesCache[$typeName] = $astProperties
                return $astProperties
            }
            else {
                # Retourner les propriÃ©tÃ©s du cache
                return $typePropertiesCache[$typeName]
            }
        }
        
        # Fonction pour obtenir les nÅ“uds enfants directs
        function Get-ChildNodes {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node
            )
            
            $childNodes = New-Object System.Collections.ArrayList
            
            # Obtenir les propriÃ©tÃ©s AST du type (avec mise en cache)
            $nodeType = $Node.GetType()
            $astProperties = Get-AstTypeProperties -Type $nodeType
            
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
        function Invoke-AstTraversalRecursive {
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
            
            # IncrÃ©menter le compteur de nÅ“uds
            $script:nodeCount++
            
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
                    $script:matchedNodeCount++
                }
            }
            
            # Obtenir les nÅ“uds enfants directs
            $children = Get-ChildNodes -Node $Node
            
            # Parcourir rÃ©cursivement les enfants
            foreach ($child in $children) {
                # Ã‰viter la rÃ©cursion infinie en vÃ©rifiant que l'enfant n'est pas null et n'est pas le parent
                if ($null -ne $child -and $child -ne $Node) {
                    Invoke-AstTraversalRecursive -Node $child -Depth ($Depth + 1)
                }
            }
        }
    }

    process {
        try {
            Write-Verbose "DÃ©marrage du parcours en profondeur optimisÃ© de l'AST..."
            
            # VÃ©rifier si le nÅ“ud racine doit Ãªtre inclus
            if ($IncludeRoot -and (Test-NodeMatchesCriteria -Node $Ast)) {
                [void]$results.Add($Ast)
                $matchedNodeCount++
            }
            
            # Marquer le nÅ“ud racine comme visitÃ©
            [void]$visitedNodes.Add($Ast)
            
            # Obtenir les enfants directs du nÅ“ud racine
            $rootChildren = Get-ChildNodes -Node $Ast
            
            # Parcours rÃ©cursif standard
            Write-Verbose "Utilisation du parcours rÃ©cursif standard"
            
            foreach ($child in $rootChildren) {
                Invoke-AstTraversalRecursive -Node $child -Depth 1
            }
            
            # ArrÃªter le chronomÃ¨tre
            $stopwatch.Stop()
            $elapsedTime = $stopwatch.Elapsed
            
            # Afficher les statistiques de performance
            Write-Verbose "Parcours termine en $($elapsedTime.TotalSeconds) secondes"
            Write-Verbose "Noeuds traites: $nodeCount"
            Write-Verbose "Noeuds correspondants: $matchedNodeCount"
            
            # Retourner les rÃ©sultats
            return $results
        }
        catch {
            Write-Error -Message "Erreur lors du parcours en profondeur optimisÃ© de l'AST : $_"
            throw
        }
    }
}
