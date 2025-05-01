<#
.SYNOPSIS
    Extrait les variables d'un script PowerShell.

.DESCRIPTION
    Cette fonction extrait les variables d'un script PowerShell en utilisant l'arbre syntaxique (AST).
    Elle permet de filtrer les variables par nom et d'obtenir des informations détaillées sur chaque variable.

.PARAMETER Ast
    L'arbre syntaxique PowerShell à analyser. Peut être obtenu via [System.Management.Automation.Language.Parser]::ParseFile() ou [System.Management.Automation.Language.Parser]::ParseInput().

.PARAMETER Name
    Nom de la variable à rechercher. Peut contenir des caractères génériques.

.PARAMETER Scope
    Portée de la variable à rechercher (global, script, local, etc.).

.PARAMETER IncludeAssignments
    Si spécifié, inclut les informations sur les assignations de valeurs aux variables.

.PARAMETER ExcludeAutomaticVariables
    Si spécifié, exclut les variables automatiques ($_, $PSItem, $args, etc.).

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Get-AstVariables -Ast $ast

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Get-AstVariables -Ast $ast -Name "result*" -IncludeAssignments

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de creation: 2023-11-15
#>
function Get-AstVariables {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Global", "Script", "Local", "Private", "Using", "Workflow", "All")]
        [string]$Scope = "All",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeAssignments,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeAutomaticVariables
    )

    process {
        try {
            # Liste des variables automatiques à exclure si demandé
            $automaticVariables = @(
                "_", "PSItem", "args", "input", "PSCmdlet", "MyInvocation", "PSBoundParameters",
                "PSScriptRoot", "PSCommandPath", "PSVersionTable", "error", "StackTrace", "Host"
            )

            # Rechercher toutes les variables dans l'AST
            $variables = $Ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.VariableExpressionAst]
            }, $true)

            # Filtrer par nom si spécifié
            if ($Name) {
                $variables = $variables | Where-Object { $_.VariablePath.UserPath -like $Name }
            }

            # Filtrer par portée si spécifiée
            if ($Scope -ne "All") {
                $variables = $variables | Where-Object { $_.VariablePath.DriveName -eq $Scope }
            }

            # Exclure les variables automatiques si demandé
            if ($ExcludeAutomaticVariables) {
                $variables = $variables | Where-Object { $automaticVariables -notcontains $_.VariablePath.UserPath }
            }

            # Rechercher les assignations si demandé
            $assignments = @{}
            if ($IncludeAssignments) {
                $assignmentAsts = $Ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.AssignmentStatementAst]
                }, $true)

                foreach ($assignment in $assignmentAsts) {
                    if ($assignment.Left -is [System.Management.Automation.Language.VariableExpressionAst]) {
                        $varName = $assignment.Left.VariablePath.UserPath
                        if (-not $assignments.ContainsKey($varName)) {
                            $assignments[$varName] = @()
                        }
                        $assignments[$varName] += [PSCustomObject]@{
                            Value = $assignment.Right.Extent.Text
                            Line = $assignment.Extent.StartLineNumber
                            Column = $assignment.Extent.StartColumnNumber
                        }
                    }
                }
            }

            # Créer une liste unique de variables
            $uniqueVars = @{}
            foreach ($var in $variables) {
                $varName = $var.VariablePath.UserPath
                $varScope = $var.VariablePath.DriveName
                $key = "$varScope`:$varName"

                if (-not $uniqueVars.ContainsKey($key)) {
                    $uniqueVars[$key] = [PSCustomObject]@{
                        Name = $varName
                        Scope = $varScope
                        FirstUsage = [PSCustomObject]@{
                            Line = $var.Extent.StartLineNumber
                            Column = $var.Extent.StartColumnNumber
                        }
                        Assignments = if ($IncludeAssignments -and $assignments.ContainsKey($varName)) {
                            $assignments[$varName]
                        } else {
                            $null
                        }
                    }
                }
            }

            # Retourner les résultats
            return $uniqueVars.Values
        }
        catch {
            Write-Error -Message "Erreur lors de l'extraction des variables : $_"
            throw
        }
    }
}
