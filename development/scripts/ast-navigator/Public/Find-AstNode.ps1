<#
.SYNOPSIS
    Recherche des nÅ“uds spÃ©cifiques dans l'arbre syntaxique PowerShell.

.DESCRIPTION
    Cette fonction recherche des nÅ“uds spÃ©cifiques dans un arbre syntaxique PowerShell (AST) en utilisant diffÃ©rents critÃ¨res de recherche.
    Elle permet de rechercher par type de nÅ“ud, par nom d'Ã©lÃ©ment, par position ou par motif.

.PARAMETER Ast
    L'arbre syntaxique PowerShell Ã  parcourir. Peut Ãªtre obtenu via [System.Management.Automation.Language.Parser]::ParseFile() ou [System.Management.Automation.Language.Parser]::ParseInput().

.PARAMETER NodeType
    Type de nÅ“ud AST Ã  rechercher. Si spÃ©cifiÃ©, seuls les nÅ“uds de ce type seront inclus dans les rÃ©sultats.

.PARAMETER Name
    Nom de l'Ã©lÃ©ment Ã  rechercher (fonction, variable, etc.). Peut contenir des caractÃ¨res gÃ©nÃ©riques.

.PARAMETER Line
    NumÃ©ro de ligne pour rechercher des nÅ“uds Ã  une position spÃ©cifique.

.PARAMETER Column
    NumÃ©ro de colonne pour rechercher des nÅ“uds Ã  une position spÃ©cifique.

.PARAMETER Pattern
    Motif de recherche pour le contenu du nÅ“ud. Peut contenir des caractÃ¨res gÃ©nÃ©riques.

.PARAMETER ParentType
    Type de nÅ“ud parent pour une recherche contextuelle.

.PARAMETER MaxResults
    Nombre maximum de rÃ©sultats Ã  retourner. Si 0 ou non spÃ©cifiÃ©, tous les rÃ©sultats sont retournÃ©s.

.PARAMETER Predicate
    PrÃ©dicat (ScriptBlock) personnalisÃ© pour filtrer les nÅ“uds. Si spÃ©cifiÃ©, seuls les nÅ“uds pour lesquels le prÃ©dicat retourne $true seront inclus dans les rÃ©sultats.

.PARAMETER First
    Si spÃ©cifiÃ©, retourne uniquement le premier rÃ©sultat trouvÃ©.

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
    Date de crÃ©ation: 2023-11-15
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

        # Fonction pour vÃ©rifier si un nÅ“ud correspond au nom spÃ©cifiÃ©
        function Test-NodeName {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node,

                [Parameter(Mandatory = $true)]
                [string]$NamePattern
            )

            # VÃ©rifier si le nÅ“ud a une propriÃ©tÃ© Name
            if ($Node.PSObject.Properties.Name -contains 'Name') {
                return $Node.Name -like $NamePattern
            }
            # VÃ©rifier si c'est une variable
            elseif ($Node -is [System.Management.Automation.Language.VariableExpressionAst]) {
                return $Node.VariablePath.UserPath -like $NamePattern
            }
            # VÃ©rifier si c'est une commande
            elseif ($Node -is [System.Management.Automation.Language.CommandAst]) {
                $commandName = $Node.CommandElements[0].Value
                return $commandName -like $NamePattern
            }

            return $false
        }

        # Fonction pour vÃ©rifier si un nÅ“ud est Ã  la position spÃ©cifiÃ©e
        function Test-NodePosition {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node,

                [Parameter(Mandatory = $true)]
                [int]$LineNumber,

                [Parameter(Mandatory = $false)]
                [int]$ColumnNumber = 0
            )

            # VÃ©rifier si le nÅ“ud est Ã  la ligne spÃ©cifiÃ©e
            if ($Node.Extent.StartLineNumber -le $LineNumber -and $Node.Extent.EndLineNumber -ge $LineNumber) {
                # Si la colonne est spÃ©cifiÃ©e, vÃ©rifier Ã©galement la colonne
                if ($ColumnNumber -gt 0) {
                    return ($Node.Extent.StartLineNumber -lt $LineNumber -or $Node.Extent.StartColumnNumber -le $ColumnNumber) -and
                           ($Node.Extent.EndLineNumber -gt $LineNumber -or $Node.Extent.EndColumnNumber -ge $ColumnNumber)
                }
                return $true
            }
            return $false
        }

        # Fonction pour vÃ©rifier si un nÅ“ud correspond au motif spÃ©cifiÃ©
        function Test-NodePattern {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node,

                [Parameter(Mandatory = $true)]
                [string]$PatternToMatch
            )

            # Obtenir le texte du nÅ“ud
            $nodeText = $Node.Extent.Text
            return $nodeText -like "*$PatternToMatch*"
        }

        # Fonction pour vÃ©rifier si un nÅ“ud a un parent du type spÃ©cifiÃ©
        function Test-NodeParentType {
            param (
                [Parameter(Mandatory = $true)]
                [System.Management.Automation.Language.Ast]$Node,

                [Parameter(Mandatory = $true)]
                [string]$Type
            )

            # Obtenir le parent du nÅ“ud
            $parent = $Node.Parent
            if ($null -eq $parent) {
                return $false
            }

            return Test-NodeType -Node $parent -Type $Type
        }
    }

    process {
        try {
            # CrÃ©er le prÃ©dicat de recherche en fonction des paramÃ¨tres
            $searchPredicate = {
                param($node)

                # VÃ©rifier le type de nÅ“ud si spÃ©cifiÃ©
                if ($NodeType -and -not (Test-NodeType -Node $node -Type $NodeType)) {
                    return $false
                }

                # VÃ©rifier le nom si spÃ©cifiÃ©
                if ($PSCmdlet.ParameterSetName -eq 'ByName' -and -not (Test-NodeName -Node $node -NamePattern $Name)) {
                    return $false
                }

                # VÃ©rifier la position si spÃ©cifiÃ©e
                if ($PSCmdlet.ParameterSetName -eq 'ByPosition' -and -not (Test-NodePosition -Node $node -LineNumber $Line -ColumnNumber $Column)) {
                    return $false
                }

                # VÃ©rifier le motif si spÃ©cifiÃ©
                if ($PSCmdlet.ParameterSetName -eq 'ByPattern' -and -not (Test-NodePattern -Node $node -PatternToMatch $Pattern)) {
                    return $false
                }

                # VÃ©rifier le type de parent si spÃ©cifiÃ©
                if ($PSCmdlet.ParameterSetName -eq 'ByContext' -and -not (Test-NodeParentType -Node $node -Type $ParentType)) {
                    return $false
                }

                # VÃ©rifier le prÃ©dicat personnalisÃ© si spÃ©cifiÃ©
                if ($Predicate -and -not (& $Predicate $node)) {
                    return $false
                }

                return $true
            }

            # Rechercher les nÅ“uds correspondants
            if ($First) {
                # Rechercher uniquement le premier nÅ“ud correspondant
                $result = $Ast.Find($searchPredicate, $true)
                if ($null -ne $result) {
                    [void]$results.Add($result)
                }
            } else {
                # Rechercher tous les nÅ“uds correspondants
                $foundNodes = $Ast.FindAll($searchPredicate, $true)

                # Limiter le nombre de rÃ©sultats si spÃ©cifiÃ©
                if ($MaxResults -gt 0 -and $foundNodes.Count -gt $MaxResults) {
                    $foundNodes = $foundNodes | Select-Object -First $MaxResults
                }

                # Ajouter les nÅ“uds trouvÃ©s aux rÃ©sultats
                foreach ($node in $foundNodes) {
                    [void]$results.Add($node)
                }
            }

            # Retourner les rÃ©sultats
            return $results
        } catch {
            Write-Error -Message "Erreur lors de la recherche de noeuds dans l'AST : $_"
            throw
        }
    }
}
