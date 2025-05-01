<#
.SYNOPSIS
    Recherche des nœuds AST par type avec des options de filtrage avancées.

.DESCRIPTION
    Cette fonction recherche des nœuds dans un arbre syntaxique PowerShell (AST) en fonction de leur type,
    avec des options de filtrage avancées comme l'inclusion/exclusion de types spécifiques,
    la correspondance par expression régulière, et la possibilité de spécifier plusieurs types à la fois.

.PARAMETER Ast
    L'arbre syntaxique PowerShell à parcourir. Peut être obtenu via [System.Management.Automation.Language.Parser]::ParseFile() ou [System.Management.Automation.Language.Parser]::ParseInput().

.PARAMETER NodeType
    Type de nœud AST à rechercher. Peut être un nom de type exact ou un tableau de noms de types.
    Les noms de types peuvent être spécifiés avec ou sans le suffixe "Ast".

.PARAMETER RegexPattern
    Expression régulière pour filtrer les types de nœuds. Si spécifiée, seuls les nœuds dont le type correspond à l'expression régulière seront inclus.

.PARAMETER ExcludeType
    Type(s) de nœud AST à exclure des résultats. Peut être un nom de type exact ou un tableau de noms de types.

.PARAMETER IncludeBaseTypes
    Si spécifié, inclut également les nœuds dont le type est une classe de base des types spécifiés.

.PARAMETER MaxDepth
    Profondeur maximale de recherche. Si 0 ou non spécifié, aucune limite de profondeur n'est appliquée.

.PARAMETER Predicate
    Prédicat (ScriptBlock) supplémentaire pour filtrer les nœuds. Si spécifié, seuls les nœuds pour lesquels le prédicat retourne $true seront inclus.

.PARAMETER IncludeRoot
    Si spécifié, inclut le nœud racine dans les résultats.

.PARAMETER MaxResults
    Nombre maximum de résultats à retourner. Si 0 ou non spécifié, tous les résultats sont retournés.

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Find-AstNodeByType -Ast $ast -NodeType "FunctionDefinition"

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Find-AstNodeByType -Ast $ast -NodeType @("FunctionDefinition", "CommandAst") -MaxDepth 3

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Find-AstNodeByType -Ast $ast -RegexPattern ".*Statement" -ExcludeType "IfStatement"

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de création: 2023-11-15
#>
function Find-AstNodeByType {
    [CmdletBinding(DefaultParameterSetName = 'ByType')]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $false, ParameterSetName = 'ByType')]
        [object[]]$NodeType,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByRegex')]
        [string]$RegexPattern,

        [Parameter(Mandatory = $false)]
        [object[]]$ExcludeType,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeBaseTypes,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 0,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Predicate,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeRoot,

        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 0
    )

    begin {
        # Initialiser la liste des résultats
        $results = New-Object System.Collections.ArrayList
        
        # Normaliser les types de nœuds à rechercher
        $normalizedNodeTypes = @()
        if ($PSCmdlet.ParameterSetName -eq 'ByType' -and $null -ne $NodeType) {
            foreach ($type in $NodeType) {
                if ($type -is [string]) {
                    # Ajouter le type avec et sans le suffixe "Ast"
                    if ($type -match "Ast$") {
                        $normalizedNodeTypes += $type
                    }
                    else {
                        $normalizedNodeTypes += $type
                        $normalizedNodeTypes += "${type}Ast"
                    }
                }
                elseif ($type -is [type]) {
                    # Si c'est un objet Type, utiliser son nom
                    $normalizedNodeTypes += $type.Name
                }
            }
        }
        
        # Normaliser les types de nœuds à exclure
        $normalizedExcludeTypes = @()
        if ($null -ne $ExcludeType) {
            foreach ($type in $ExcludeType) {
                if ($type -is [string]) {
                    # Ajouter le type avec et sans le suffixe "Ast"
                    if ($type -match "Ast$") {
                        $normalizedExcludeTypes += $type
                    }
                    else {
                        $normalizedExcludeTypes += $type
                        $normalizedExcludeTypes += "${type}Ast"
                    }
                }
                elseif ($type -is [type]) {
                    # Si c'est un objet Type, utiliser son nom
                    $normalizedExcludeTypes += $type.Name
                }
            }
        }
        
        # Fonction pour vérifier si un nœud correspond aux critères de type
        function Test-NodeTypeMatch {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node
            )
            
            $nodeTypeName = $Node.GetType().Name
            
            # Vérifier si le type est exclu
            if ($normalizedExcludeTypes.Count -gt 0 -and $normalizedExcludeTypes -contains $nodeTypeName) {
                return $false
            }
            
            # Vérifier si le type correspond à l'expression régulière
            if ($PSCmdlet.ParameterSetName -eq 'ByRegex') {
                return $nodeTypeName -match $RegexPattern
            }
            
            # Vérifier si le type correspond à l'un des types spécifiés
            if ($normalizedNodeTypes.Count -gt 0) {
                if ($normalizedNodeTypes -contains $nodeTypeName) {
                    return $true
                }
                
                # Vérifier les types de base si demandé
                if ($IncludeBaseTypes) {
                    $nodeType = $Node.GetType()
                    $baseType = $nodeType.BaseType
                    
                    while ($null -ne $baseType -and $baseType -ne [object]) {
                        if ($normalizedNodeTypes -contains $baseType.Name) {
                            return $true
                        }
                        $baseType = $baseType.BaseType
                    }
                }
                
                return $false
            }
            
            # Si aucun type n'est spécifié, inclure tous les nœuds
            return $true
        }
        
        # Fonction pour calculer la profondeur d'un nœud
        function Get-NodeDepth {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node
            )
            
            $depth = 0
            $current = $Node
            
            while ($null -ne $current.Parent) {
                $depth++
                $current = $current.Parent
            }
            
            return $depth
        }
    }

    process {
        try {
            # Créer le prédicat de recherche en fonction des paramètres
            $searchPredicate = {
                param($node)
                
                # Vérifier si le nœud correspond aux critères de type
                $typeMatch = Test-NodeTypeMatch -Node $node
                
                if (-not $typeMatch) {
                    return $false
                }
                
                # Vérifier si le nœud correspond au prédicat spécifié
                if ($null -ne $Predicate) {
                    return & $Predicate $node
                }
                
                return $true
            }
            
            # Utiliser la méthode FindAll de l'AST pour rechercher les nœuds correspondants
            $foundNodes = $Ast.FindAll($searchPredicate, $true)
            
            # Filtrer le nœud racine si nécessaire
            if (-not $IncludeRoot) {
                $foundNodes = $foundNodes | Where-Object { $_ -ne $Ast }
            }
            
            # Limiter la profondeur si nécessaire
            if ($MaxDepth -gt 0) {
                $foundNodes = $foundNodes | Where-Object {
                    $depth = Get-NodeDepth -Node $_
                    return $depth -le $MaxDepth
                }
            }
            
            # Limiter le nombre de résultats si spécifié
            if ($MaxResults -gt 0 -and $foundNodes.Count -gt $MaxResults) {
                $foundNodes = $foundNodes | Select-Object -First $MaxResults
            }
            
            # Ajouter les nœuds trouvés aux résultats
            foreach ($node in $foundNodes) {
                [void]$results.Add($node)
            }
            
            # Retourner les résultats
            return $results
        }
        catch {
            Write-Error -Message "Erreur lors de la recherche de noeuds par type : $_"
            throw
        }
    }
}
