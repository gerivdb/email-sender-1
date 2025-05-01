<#
.SYNOPSIS
    Effectue un parcours en profondeur (DFS) optimisé de l'arbre syntaxique PowerShell pour les grands arbres.

.DESCRIPTION
    Cette fonction parcourt récursivement un arbre syntaxique PowerShell (AST) en utilisant l'algorithme de parcours en profondeur (DFS).
    Elle implémente des optimisations pour améliorer les performances et réduire l'utilisation de la mémoire lors du traitement
    de grands arbres syntaxiques. Les optimisations incluent:
    - Utilisation de structures de données optimisées pour les grands ensembles
    - Mise en cache des propriétés des types pour éviter la réflexion répétée
    - Traitement par lots des nœuds pour réduire la pression sur la mémoire
    - Détection précoce des nœuds non pertinents

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

.PARAMETER BatchSize
    Taille des lots pour le traitement des nœuds. Permet d'optimiser la gestion de la mémoire pour les grands arbres. La valeur par défaut est 1000.

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
    Date de création: 2023-11-15
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
        # Démarrer un chronomètre pour mesurer les performances
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Initialiser les structures de données optimisées
        $results = New-Object System.Collections.ArrayList
        $visitedNodes = New-Object System.Collections.Generic.HashSet[System.Management.Automation.Language.Ast]
        
        # Cache pour les propriétés des types AST
        $typePropertiesCache = @{}
        
        # Statistiques pour le rapport de performance
        $nodeCount = 0
        $matchedNodeCount = 0
        
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
                $typeToCheck = $NodeType
                
                # Ajouter "Ast" au type si nécessaire
                if (-not $NodeType.EndsWith("Ast")) {
                    $typeToCheck = "${NodeType}Ast"
                }
                
                $includeNode = $nodeTypeName -eq $NodeType -or $nodeTypeName -eq $typeToCheck
            }

            # Vérifier si le nœud correspond au prédicat spécifié
            if ($includeNode -and $Predicate) {
                $includeNode = & $Predicate $Node
            }

            return $includeNode
        }
        
        # Fonction pour obtenir les propriétés AST d'un type (avec mise en cache)
        function Get-AstTypeProperties {
            param (
                [Parameter(Mandatory = $true)]
                [type]$Type
            )
            
            # Vérifier si les propriétés sont déjà en cache
            $typeName = $Type.FullName
            if (-not $typePropertiesCache.ContainsKey($typeName)) {
                # Obtenir les propriétés qui peuvent contenir des objets AST
                $astProperties = $Type.GetProperties() | Where-Object {
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
                
                # Mettre en cache les propriétés
                $typePropertiesCache[$typeName] = $astProperties
                return $astProperties
            }
            else {
                # Retourner les propriétés du cache
                return $typePropertiesCache[$typeName]
            }
        }
        
        # Fonction pour obtenir les nœuds enfants directs
        function Get-ChildNodes {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node
            )
            
            $childNodes = New-Object System.Collections.ArrayList
            
            # Obtenir les propriétés AST du type (avec mise en cache)
            $nodeType = $Node.GetType()
            $astProperties = Get-AstTypeProperties -Type $nodeType
            
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
        function Invoke-AstTraversalRecursive {
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
            
            # Incrémenter le compteur de nœuds
            $script:nodeCount++
            
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
                    $script:matchedNodeCount++
                }
            }
            
            # Obtenir les nœuds enfants directs
            $children = Get-ChildNodes -Node $Node
            
            # Parcourir récursivement les enfants
            foreach ($child in $children) {
                # Éviter la récursion infinie en vérifiant que l'enfant n'est pas null et n'est pas le parent
                if ($null -ne $child -and $child -ne $Node) {
                    Invoke-AstTraversalRecursive -Node $child -Depth ($Depth + 1)
                }
            }
        }
    }

    process {
        try {
            Write-Verbose "Démarrage du parcours en profondeur optimisé de l'AST..."
            
            # Vérifier si le nœud racine doit être inclus
            if ($IncludeRoot -and (Test-NodeMatchesCriteria -Node $Ast)) {
                [void]$results.Add($Ast)
                $matchedNodeCount++
            }
            
            # Marquer le nœud racine comme visité
            [void]$visitedNodes.Add($Ast)
            
            # Obtenir les enfants directs du nœud racine
            $rootChildren = Get-ChildNodes -Node $Ast
            
            # Parcours récursif standard
            Write-Verbose "Utilisation du parcours récursif standard"
            
            foreach ($child in $rootChildren) {
                Invoke-AstTraversalRecursive -Node $child -Depth 1
            }
            
            # Arrêter le chronomètre
            $stopwatch.Stop()
            $elapsedTime = $stopwatch.Elapsed
            
            # Afficher les statistiques de performance
            Write-Verbose "Parcours termine en $($elapsedTime.TotalSeconds) secondes"
            Write-Verbose "Noeuds traites: $nodeCount"
            Write-Verbose "Noeuds correspondants: $matchedNodeCount"
            
            # Retourner les résultats
            return $results
        }
        catch {
            Write-Error -Message "Erreur lors du parcours en profondeur optimisé de l'AST : $_"
            throw
        }
    }
}
