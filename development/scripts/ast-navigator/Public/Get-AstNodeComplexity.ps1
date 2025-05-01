<#
.SYNOPSIS
    Calcule le niveau de complexité d'un noeud dans l'arbre syntaxique PowerShell.

.DESCRIPTION
    Cette fonction calcule le niveau de complexité d'un noeud dans l'arbre syntaxique PowerShell (AST).
    La complexité est calculée en fonction du nombre de noeuds enfants, de la profondeur de l'arbre,
    et de la présence de structures de contrôle (if, switch, for, foreach, while, etc.).

.PARAMETER Node
    Le noeud AST pour lequel on souhaite calculer la complexité.

.PARAMETER IncludeChildren
    Si spécifié, inclut la complexité des noeuds enfants dans le calcul.

.PARAMETER Detailed
    Si spécifié, retourne un objet détaillé avec les différentes mesures de complexité.

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    $functionNode = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)[0]
    Get-AstNodeComplexity -Node $functionNode

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    $functionNode = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)[0]
    Get-AstNodeComplexity -Node $functionNode -IncludeChildren -Detailed

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de creation: 2023-11-15
#>
function Get-AstNodeComplexity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Node,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeChildren,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    process {
        try {
            # Initialiser les compteurs de complexité
            $complexity = 0
            $childCount = 0
            $depth = 0
            $controlStructures = 0
            $operators = 0
            $expressions = 0

            # Fonction récursive pour calculer la complexité
            function Get-NodeComplexity {
                param (
                    [Parameter(Mandatory = $true)]
                    [System.Management.Automation.Language.Ast]$CurrentNode,

                    [Parameter(Mandatory = $true)]
                    [int]$CurrentDepth
                )

                # Mettre à jour la profondeur maximale
                if ($CurrentDepth -gt $depth) {
                    $script:depth = $CurrentDepth
                }

                # Incrémenter le compteur d'enfants
                $script:childCount++

                # Vérifier le type de noeud pour les structures de contrôle
                if ($CurrentNode -is [System.Management.Automation.Language.IfStatementAst] -or
                    $CurrentNode -is [System.Management.Automation.Language.SwitchStatementAst] -or
                    $CurrentNode -is [System.Management.Automation.Language.ForStatementAst] -or
                    $CurrentNode -is [System.Management.Automation.Language.ForEachStatementAst] -or
                    $CurrentNode -is [System.Management.Automation.Language.WhileStatementAst] -or
                    $CurrentNode -is [System.Management.Automation.Language.DoWhileStatementAst] -or
                    $CurrentNode -is [System.Management.Automation.Language.TryStatementAst] -or
                    $CurrentNode -is [System.Management.Automation.Language.CatchClauseAst]) {
                    $script:controlStructures++
                }

                # Vérifier le type de noeud pour les opérateurs
                if ($CurrentNode -is [System.Management.Automation.Language.BinaryExpressionAst] -or
                    $CurrentNode -is [System.Management.Automation.Language.UnaryExpressionAst]) {
                    $script:operators++
                }

                # Vérifier le type de noeud pour les expressions
                if ($CurrentNode -is [System.Management.Automation.Language.ExpressionAst]) {
                    $script:expressions++
                }

                # Parcourir récursivement les noeuds enfants si demandé
                if ($IncludeChildren) {
                    foreach ($child in $CurrentNode.FindAll({ $true }, $false)) {
                        Get-NodeComplexity -CurrentNode $child -CurrentDepth ($CurrentDepth + 1)
                    }
                }
            }

            # Calculer la complexité du noeud
            Get-NodeComplexity -CurrentNode $Node -CurrentDepth 0

            # Calculer la complexité totale
            $complexity = $childCount + $controlStructures * 2 + $operators + $expressions / 2

            # Retourner les résultats
            if ($Detailed) {
                return [PSCustomObject]@{
                    TotalComplexity = [Math]::Round($complexity, 2)
                    ChildCount = $childCount
                    MaxDepth = $depth
                    ControlStructures = $controlStructures
                    Operators = $operators
                    Expressions = $expressions
                }
            }
            else {
                return [Math]::Round($complexity, 2)
            }
        }
        catch {
            Write-Error -Message "Erreur lors du calcul de la complexité du noeud : $_"
            throw
        }
    }
}
