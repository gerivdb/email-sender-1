<#
.SYNOPSIS
    Recherche des nÅ“uds AST par type avec des options de filtrage avancÃ©es.

.DESCRIPTION
    Cette fonction recherche des nÅ“uds dans un arbre syntaxique PowerShell (AST) en fonction de leur type,
    avec des options de filtrage avancÃ©es comme l'inclusion/exclusion de types spÃ©cifiques,
    la correspondance par expression rÃ©guliÃ¨re, et la possibilitÃ© de spÃ©cifier plusieurs types Ã  la fois.

.PARAMETER Ast
    L'arbre syntaxique PowerShell Ã  parcourir. Peut Ãªtre obtenu via [System.Management.Automation.Language.Parser]::ParseFile() ou [System.Management.Automation.Language.Parser]::ParseInput().

.PARAMETER NodeType
    Type de nÅ“ud AST Ã  rechercher. Peut Ãªtre un nom de type exact ou un tableau de noms de types.
    Les noms de types peuvent Ãªtre spÃ©cifiÃ©s avec ou sans le suffixe "Ast".

.PARAMETER RegexPattern
    Expression rÃ©guliÃ¨re pour filtrer les types de nÅ“uds. Si spÃ©cifiÃ©e, seuls les nÅ“uds dont le type correspond Ã  l'expression rÃ©guliÃ¨re seront inclus.

.PARAMETER ExcludeType
    Type(s) de nÅ“ud AST Ã  exclure des rÃ©sultats. Peut Ãªtre un nom de type exact ou un tableau de noms de types.

.PARAMETER IncludeBaseTypes
    Si spÃ©cifiÃ©, inclut Ã©galement les nÅ“uds dont le type est une classe de base des types spÃ©cifiÃ©s.

.PARAMETER MaxDepth
    Profondeur maximale de recherche. Si 0 ou non spÃ©cifiÃ©, aucune limite de profondeur n'est appliquÃ©e.

.PARAMETER Predicate
    PrÃ©dicat (ScriptBlock) supplÃ©mentaire pour filtrer les nÅ“uds. Si spÃ©cifiÃ©, seuls les nÅ“uds pour lesquels le prÃ©dicat retourne $true seront inclus.

.PARAMETER IncludeRoot
    Si spÃ©cifiÃ©, inclut le nÅ“ud racine dans les rÃ©sultats.

.PARAMETER MaxResults
    Nombre maximum de rÃ©sultats Ã  retourner. Si 0 ou non spÃ©cifiÃ©, tous les rÃ©sultats sont retournÃ©s.

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
    Date de crÃ©ation: 2023-11-15
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
        # Initialiser la liste des rÃ©sultats
        $results = New-Object System.Collections.ArrayList
        
        # Normaliser les types de nÅ“uds Ã  rechercher
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
        
        # Normaliser les types de nÅ“uds Ã  exclure
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
        
        # Fonction pour vÃ©rifier si un nÅ“ud correspond aux critÃ¨res de type
        function Test-NodeTypeMatch {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node
            )
            
            $nodeTypeName = $Node.GetType().Name
            
            # VÃ©rifier si le type est exclu
            if ($normalizedExcludeTypes.Count -gt 0 -and $normalizedExcludeTypes -contains $nodeTypeName) {
                return $false
            }
            
            # VÃ©rifier si le type correspond Ã  l'expression rÃ©guliÃ¨re
            if ($PSCmdlet.ParameterSetName -eq 'ByRegex') {
                return $nodeTypeName -match $RegexPattern
            }
            
            # VÃ©rifier si le type correspond Ã  l'un des types spÃ©cifiÃ©s
            if ($normalizedNodeTypes.Count -gt 0) {
                if ($normalizedNodeTypes -contains $nodeTypeName) {
                    return $true
                }
                
                # VÃ©rifier les types de base si demandÃ©
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
            
            # Si aucun type n'est spÃ©cifiÃ©, inclure tous les nÅ“uds
            return $true
        }
        
        # Fonction pour calculer la profondeur d'un nÅ“ud
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
            # CrÃ©er le prÃ©dicat de recherche en fonction des paramÃ¨tres
            $searchPredicate = {
                param($node)
                
                # VÃ©rifier si le nÅ“ud correspond aux critÃ¨res de type
                $typeMatch = Test-NodeTypeMatch -Node $node
                
                if (-not $typeMatch) {
                    return $false
                }
                
                # VÃ©rifier si le nÅ“ud correspond au prÃ©dicat spÃ©cifiÃ©
                if ($null -ne $Predicate) {
                    return & $Predicate $node
                }
                
                return $true
            }
            
            # Utiliser la mÃ©thode FindAll de l'AST pour rechercher les nÅ“uds correspondants
            $foundNodes = $Ast.FindAll($searchPredicate, $true)
            
            # Filtrer le nÅ“ud racine si nÃ©cessaire
            if (-not $IncludeRoot) {
                $foundNodes = $foundNodes | Where-Object { $_ -ne $Ast }
            }
            
            # Limiter la profondeur si nÃ©cessaire
            if ($MaxDepth -gt 0) {
                $foundNodes = $foundNodes | Where-Object {
                    $depth = Get-NodeDepth -Node $_
                    return $depth -le $MaxDepth
                }
            }
            
            # Limiter le nombre de rÃ©sultats si spÃ©cifiÃ©
            if ($MaxResults -gt 0 -and $foundNodes.Count -gt $MaxResults) {
                $foundNodes = $foundNodes | Select-Object -First $MaxResults
            }
            
            # Ajouter les nÅ“uds trouvÃ©s aux rÃ©sultats
            foreach ($node in $foundNodes) {
                [void]$results.Add($node)
            }
            
            # Retourner les rÃ©sultats
            return $results
        }
        catch {
            Write-Error -Message "Erreur lors de la recherche de noeuds par type : $_"
            throw
        }
    }
}
