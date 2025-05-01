<#
.SYNOPSIS
    Recherche des nœuds spécifiques dans l'arbre syntaxique PowerShell.

.DESCRIPTION
    Cette fonction recherche des nœuds spécifiques dans un arbre syntaxique PowerShell (AST) en utilisant différents critères de recherche.
    Elle permet de rechercher par type de nœud, par nom d'élément, par position ou par motif.

.PARAMETER Ast
    L'arbre syntaxique PowerShell à parcourir. Peut être obtenu via [System.Management.Automation.Language.Parser]::ParseFile() ou [System.Management.Automation.Language.Parser]::ParseInput().

.PARAMETER NodeType
    Type de nœud AST à rechercher. Si spécifié, seuls les nœuds de ce type seront inclus dans les résultats.

.PARAMETER Name
    Nom de l'élément à rechercher (fonction, variable, etc.). Peut contenir des caractères génériques.

.PARAMETER Line
    Numéro de ligne pour rechercher des nœuds à une position spécifique.

.PARAMETER Column
    Numéro de colonne pour rechercher des nœuds à une position spécifique.

.PARAMETER Pattern
    Motif de recherche pour le contenu du nœud. Peut contenir des caractères génériques.

.PARAMETER ParentType
    Type de nœud parent pour une recherche contextuelle.

.PARAMETER MaxResults
    Nombre maximum de résultats à retourner. Si 0 ou non spécifié, tous les résultats sont retournés.

.PARAMETER Predicate
    Prédicat (ScriptBlock) personnalisé pour filtrer les nœuds. Si spécifié, seuls les nœuds pour lesquels le prédicat retourne $true seront inclus dans les résultats.

.PARAMETER First
    Si spécifié, retourne uniquement le premier résultat trouvé.

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Find-AstNode -Ast $ast -NodeType "FunctionDefinitionAst" -Name "Get-*"

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Find-AstNode -Ast $ast -Line 10 -Column 5

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Find-AstNode -Ast $ast -NodeType "VariableExpressionAst" -ParentType "AssignmentStatementAst"

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de création: 2023-11-15
#>
function Find-AstNode {
    [CmdletBinding(DefaultParameterSetName = 'ByType')]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $false, ParameterSetName = 'ByType')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ByName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ByPosition')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ByPattern')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ByContext')]
        [string]$NodeType,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [string]$Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByPosition')]
        [int]$Line,

        [Parameter(Mandatory = $false, ParameterSetName = 'ByPosition')]
        [int]$Column,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByPattern')]
        [string]$Pattern,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByContext')]
        [string]$ParentType,

        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 0,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Predicate,

        [Parameter(Mandatory = $false)]
        [switch]$First
    )

    begin {
        # Initialiser la liste des résultats
        $results = New-Object System.Collections.ArrayList

        # Fonction pour vérifier si un nœud correspond au type spécifié
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

        # Fonction pour vérifier si un nœud correspond au nom spécifié
        function Test-NodeName {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node,

                [Parameter(Mandatory = $true)]
                [string]$NamePattern
            )

            # Vérifier si le nœud a une propriété Name
            if ($Node.PSObject.Properties.Name -contains 'Name') {
                return $Node.Name -like $NamePattern
            }
            # Vérifier si c'est une variable
            elseif ($Node -is [System.Management.Automation.Language.VariableExpressionAst]) {
                return $Node.VariablePath.UserPath -like $NamePattern
            }
            # Vérifier si c'est une commande
            elseif ($Node -is [System.Management.Automation.Language.CommandAst]) {
                $commandName = $Node.CommandElements[0].Value
                return $commandName -like $NamePattern
            }

            return $false
        }

        # Fonction pour vérifier si un nœud est à la position spécifiée
        function Test-NodePosition {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node,

                [Parameter(Mandatory = $true)]
                [int]$LineNumber,

                [Parameter(Mandatory = $false)]
                [int]$ColumnNumber = 0
            )

            # Vérifier si le nœud est à la ligne spécifiée
            if ($Node.Extent.StartLineNumber -le $LineNumber -and $Node.Extent.EndLineNumber -ge $LineNumber) {
                # Si la colonne est spécifiée, vérifier également la colonne
                if ($ColumnNumber -gt 0) {
                    return ($Node.Extent.StartLineNumber -lt $LineNumber -or $Node.Extent.StartColumnNumber -le $ColumnNumber) -and
                           ($Node.Extent.EndLineNumber -gt $LineNumber -or $Node.Extent.EndColumnNumber -ge $ColumnNumber)
                }
                return $true
            }
            return $false
        }

        # Fonction pour vérifier si un nœud correspond au motif spécifié
        function Test-NodePattern {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node,

                [Parameter(Mandatory = $true)]
                [string]$PatternToMatch
            )

            # Obtenir le texte du nœud
            $nodeText = $Node.Extent.Text
            return $nodeText -like "*$PatternToMatch*"
        }

        # Fonction pour vérifier si un nœud a un parent du type spécifié
        function Test-NodeParentType {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node,

                [Parameter(Mandatory = $true)]
                [string]$Type
            )

            # Obtenir le parent du nœud
            $parent = $Node.Parent
            if ($null -eq $parent) {
                return $false
            }

            return Test-NodeType -Node $parent -Type $Type
        }
    }

    process {
        try {
            # Créer le prédicat de recherche en fonction des paramètres
            $searchPredicate = {
                param($node)

                # Vérifier le type de nœud si spécifié
                if ($NodeType -and -not (Test-NodeType -Node $node -Type $NodeType)) {
                    return $false
                }

                # Vérifier le nom si spécifié
                if ($PSCmdlet.ParameterSetName -eq 'ByName' -and -not (Test-NodeName -Node $node -NamePattern $Name)) {
                    return $false
                }

                # Vérifier la position si spécifiée
                if ($PSCmdlet.ParameterSetName -eq 'ByPosition' -and -not (Test-NodePosition -Node $node -LineNumber $Line -ColumnNumber $Column)) {
                    return $false
                }

                # Vérifier le motif si spécifié
                if ($PSCmdlet.ParameterSetName -eq 'ByPattern' -and -not (Test-NodePattern -Node $node -PatternToMatch $Pattern)) {
                    return $false
                }

                # Vérifier le type de parent si spécifié
                if ($PSCmdlet.ParameterSetName -eq 'ByContext' -and -not (Test-NodeParentType -Node $node -Type $ParentType)) {
                    return $false
                }

                # Vérifier le prédicat personnalisé si spécifié
                if ($Predicate -and -not (& $Predicate $node)) {
                    return $false
                }

                return $true
            }

            # Rechercher les nœuds correspondants
            if ($First) {
                # Rechercher uniquement le premier nœud correspondant
                $result = $Ast.Find($searchPredicate, $true)
                if ($null -ne $result) {
                    [void]$results.Add($result)
                }
            } else {
                # Rechercher tous les nœuds correspondants
                $foundNodes = $Ast.FindAll($searchPredicate, $true)

                # Limiter le nombre de résultats si spécifié
                if ($MaxResults -gt 0 -and $foundNodes.Count -gt $MaxResults) {
                    $foundNodes = $foundNodes | Select-Object -First $MaxResults
                }

                # Ajouter les nœuds trouvés aux résultats
                foreach ($node in $foundNodes) {
                    [void]$results.Add($node)
                }
            }

            # Retourner les résultats
            return $results
        } catch {
            Write-Error -Message "Erreur lors de la recherche de noeuds dans l'AST : $_"
            throw
        }
    }
}
