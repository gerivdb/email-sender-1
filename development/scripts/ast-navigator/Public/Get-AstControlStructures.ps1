<#
.SYNOPSIS
    Extrait les structures de contrÃ´le d'un script PowerShell.

.DESCRIPTION
    Cette fonction extrait les structures de contrÃ´le (if, switch, foreach, while, do, try/catch) d'un script PowerShell
    en utilisant l'arbre syntaxique (AST). Elle permet d'obtenir des informations dÃ©taillÃ©es sur chaque structure.

.PARAMETER Ast
    L'arbre syntaxique PowerShell Ã  analyser. Peut Ãªtre obtenu via [System.Management.Automation.Language.Parser]::ParseFile() ou [System.Management.Automation.Language.Parser]::ParseInput().

.PARAMETER Type
    Type de structure de contrÃ´le Ã  rechercher (If, Switch, Foreach, While, Do, Try, All).

.PARAMETER IncludeContent
    Si spÃ©cifiÃ©, inclut le contenu complet de chaque structure de contrÃ´le.

.PARAMETER AnalyzeComplexity
    Si spÃ©cifiÃ©, analyse la complexitÃ© de chaque structure de contrÃ´le.

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Get-AstControlStructures -Ast $ast

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Get-AstControlStructures -Ast $ast -Type "If" -AnalyzeComplexity

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de creation: 2023-11-15
#>
function Get-AstControlStructures {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $false)]
        [ValidateSet("If", "Switch", "Foreach", "While", "Do", "Try", "All")]
        [string]$Type = "All",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent,

        [Parameter(Mandatory = $false)]
        [switch]$AnalyzeComplexity
    )

    process {
        try {
            # Initialiser les rÃ©sultats
            $results = @()

            # Fonction pour calculer la complexitÃ© d'une structure
            function Get-StructureComplexity {
                param (
                    [Parameter(Mandatory = $true)]
                    [System.Management.Automation.Language.Ast]$Structure
                )

                $complexity = 1  # ComplexitÃ© de base

                # Ajouter de la complexitÃ© pour les conditions imbriquÃ©es
                $nestedConditions = $Structure.FindAll({
                    $args[0] -is [System.Management.Automation.Language.IfStatementAst] -or
                    $args[0] -is [System.Management.Automation.Language.SwitchStatementAst]
                }, $true)
                $complexity += $nestedConditions.Count

                # Ajouter de la complexitÃ© pour les boucles imbriquÃ©es
                $nestedLoops = $Structure.FindAll({
                    $args[0] -is [System.Management.Automation.Language.ForEachStatementAst] -or
                    $args[0] -is [System.Management.Automation.Language.WhileStatementAst] -or
                    $args[0] -is [System.Management.Automation.Language.DoWhileStatementAst] -or
                    $args[0] -is [System.Management.Automation.Language.ForStatementAst]
                }, $true)
                $complexity += $nestedLoops.Count * 2  # Les boucles ajoutent plus de complexitÃ©

                # Ajouter de la complexitÃ© pour les blocs try/catch imbriquÃ©s
                $nestedTryCatch = $Structure.FindAll({
                    $args[0] -is [System.Management.Automation.Language.TryStatementAst]
                }, $true)
                $complexity += $nestedTryCatch.Count

                # Ajouter de la complexitÃ© pour les opÃ©rateurs logiques dans les conditions
                $logicalOperators = $Structure.FindAll({
                    $args[0] -is [System.Management.Automation.Language.BinaryExpressionAst] -and
                    ($args[0].Operator -eq 'And' -or $args[0].Operator -eq 'Or')
                }, $true)
                $complexity += $logicalOperators.Count

                return $complexity
            }

            # Extraire les structures if
            if ($Type -eq "If" -or $Type -eq "All") {
                $ifStatements = $Ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.IfStatementAst]
                }, $true)

                foreach ($ifStatement in $ifStatements) {
                    $ifInfo = [PSCustomObject]@{
                        Type = "If"
                        StartLine = $ifStatement.Extent.StartLineNumber
                        EndLine = $ifStatement.Extent.EndLineNumber
                        Condition = $ifStatement.Condition.Extent.Text
                        HasElseIf = $ifStatement.ElseIfClauses.Count -gt 0
                        ElseIfCount = $ifStatement.ElseIfClauses.Count
                        HasElse = $ifStatement.ElseClause -ne $null
                        Content = if ($IncludeContent) { $ifStatement.Extent.Text } else { $null }
                        Complexity = if ($AnalyzeComplexity) { Get-StructureComplexity -Structure $ifStatement } else { $null }
                    }

                    $results += $ifInfo
                }
            }

            # Extraire les structures switch
            if ($Type -eq "Switch" -or $Type -eq "All") {
                $switchStatements = $Ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.SwitchStatementAst]
                }, $true)

                foreach ($switchStatement in $switchStatements) {
                    $switchInfo = [PSCustomObject]@{
                        Type = "Switch"
                        StartLine = $switchStatement.Extent.StartLineNumber
                        EndLine = $switchStatement.Extent.EndLineNumber
                        Condition = $switchStatement.Condition.Extent.Text
                        CaseCount = $switchStatement.Clauses.Count
                        HasDefault = $switchStatement.Default -ne $null
                        Content = if ($IncludeContent) { $switchStatement.Extent.Text } else { $null }
                        Complexity = if ($AnalyzeComplexity) { Get-StructureComplexity -Structure $switchStatement } else { $null }
                    }

                    $results += $switchInfo
                }
            }

            # Extraire les structures foreach
            if ($Type -eq "Foreach" -or $Type -eq "All") {
                $foreachStatements = $Ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.ForEachStatementAst]
                }, $true)

                foreach ($foreachStatement in $foreachStatements) {
                    $foreachInfo = [PSCustomObject]@{
                        Type = "Foreach"
                        StartLine = $foreachStatement.Extent.StartLineNumber
                        EndLine = $foreachStatement.Extent.EndLineNumber
                        Variable = $foreachStatement.Variable.Name.VariablePath.UserPath
                        Collection = $foreachStatement.Expression.Extent.Text
                        Content = if ($IncludeContent) { $foreachStatement.Extent.Text } else { $null }
                        Complexity = if ($AnalyzeComplexity) { Get-StructureComplexity -Structure $foreachStatement } else { $null }
                    }

                    $results += $foreachInfo
                }
            }

            # Extraire les structures while
            if ($Type -eq "While" -or $Type -eq "All") {
                $whileStatements = $Ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.WhileStatementAst]
                }, $true)

                foreach ($whileStatement in $whileStatements) {
                    $whileInfo = [PSCustomObject]@{
                        Type = "While"
                        StartLine = $whileStatement.Extent.StartLineNumber
                        EndLine = $whileStatement.Extent.EndLineNumber
                        Condition = $whileStatement.Condition.Extent.Text
                        Content = if ($IncludeContent) { $whileStatement.Extent.Text } else { $null }
                        Complexity = if ($AnalyzeComplexity) { Get-StructureComplexity -Structure $whileStatement } else { $null }
                    }

                    $results += $whileInfo
                }
            }

            # Extraire les structures do-while
            if ($Type -eq "Do" -or $Type -eq "All") {
                $doStatements = $Ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.DoWhileStatementAst] -or
                    $args[0] -is [System.Management.Automation.Language.DoUntilStatementAst]
                }, $true)

                foreach ($doStatement in $doStatements) {
                    $doType = if ($doStatement -is [System.Management.Automation.Language.DoWhileStatementAst]) { "DoWhile" } else { "DoUntil" }
                    $doInfo = [PSCustomObject]@{
                        Type = $doType
                        StartLine = $doStatement.Extent.StartLineNumber
                        EndLine = $doStatement.Extent.EndLineNumber
                        Condition = $doStatement.Condition.Extent.Text
                        Content = if ($IncludeContent) { $doStatement.Extent.Text } else { $null }
                        Complexity = if ($AnalyzeComplexity) { Get-StructureComplexity -Structure $doStatement } else { $null }
                    }

                    $results += $doInfo
                }
            }

            # Extraire les structures try/catch
            if ($Type -eq "Try" -or $Type -eq "All") {
                $tryStatements = $Ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.TryStatementAst]
                }, $true)

                foreach ($tryStatement in $tryStatements) {
                    $tryInfo = [PSCustomObject]@{
                        Type = "Try"
                        StartLine = $tryStatement.Extent.StartLineNumber
                        EndLine = $tryStatement.Extent.EndLineNumber
                        CatchCount = $tryStatement.CatchClauses.Count
                        HasFinally = $tryStatement.Finally -ne $null
                        Content = if ($IncludeContent) { $tryStatement.Extent.Text } else { $null }
                        Complexity = if ($AnalyzeComplexity) { Get-StructureComplexity -Structure $tryStatement } else { $null }
                    }

                    $results += $tryInfo
                }
            }

            return $results
        }
        catch {
            Write-Error -Message "Erreur lors de l'extraction des structures de contrÃ´le : $_"
            throw
        }
    }
}
