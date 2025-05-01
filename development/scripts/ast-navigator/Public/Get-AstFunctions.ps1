<#
.SYNOPSIS
    Extrait les fonctions d'un script PowerShell.

.DESCRIPTION
    Cette fonction extrait les fonctions d'un script PowerShell en utilisant l'arbre syntaxique (AST).
    Elle permet de filtrer les fonctions par nom et d'obtenir des informations détaillées sur chaque fonction.

.PARAMETER Ast
    L'arbre syntaxique PowerShell à analyser. Peut être obtenu via [System.Management.Automation.Language.Parser]::ParseFile() ou [System.Management.Automation.Language.Parser]::ParseInput().

.PARAMETER Name
    Nom de la fonction à rechercher. Peut contenir des caractères génériques.

.PARAMETER Detailed
    Si spécifié, retourne des informations détaillées sur chaque fonction (paramètres, corps, etc.).

.PARAMETER IncludeContent
    Si spécifié, inclut le contenu complet de chaque fonction.

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Get-AstFunctions -Ast $ast

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Get-AstFunctions -Ast $ast -Name "Get-*" -Detailed

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de creation: 2023-11-15
#>
function Get-AstFunctions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent
    )

    process {
        try {
            # Rechercher toutes les fonctions dans l'AST
            $functions = $Ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true)

            # Filtrer par nom si spécifié
            if ($Name) {
                $functions = $functions | Where-Object { $_.Name -like $Name }
            }

            # Préparer les résultats
            $results = @()

            # Traiter chaque fonction
            foreach ($function in $functions) {
                if ($Detailed) {
                    # Extraire les paramètres
                    $parameters = @()
                    if ($function.Parameters) {
                        foreach ($param in $function.Parameters) {
                            $paramInfo = [PSCustomObject]@{
                                Name = $param.Name.VariablePath.UserPath
                                Type = if ($param.StaticType) { $param.StaticType.Name } else { "object" }
                                DefaultValue = if ($param.DefaultValue) { $param.DefaultValue.Extent.Text } else { $null }
                                Mandatory = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.Language.ParameterAst] } | ForEach-Object {
                                    $_.NamedArguments | Where-Object { $_.ArgumentName -eq "Mandatory" } | ForEach-Object {
                                        $_.Argument.SafeGetValue()
                                    }
                                } | Select-Object -First 1
                            }
                            $parameters += $paramInfo
                        }
                    }

                    # Créer l'objet résultat détaillé
                    $functionInfo = [PSCustomObject]@{
                        Name = $function.Name
                        Parameters = $parameters
                        ReturnType = if ($function.ReturnType) { $function.ReturnType.TypeName.Name } else { "void" }
                        StartLine = $function.Extent.StartLineNumber
                        EndLine = $function.Extent.EndLineNumber
                        Content = if ($IncludeContent) { $function.Extent.Text } else { $null }
                    }

                    $results += $functionInfo
                }
                else {
                    # Créer l'objet résultat simple
                    $functionInfo = [PSCustomObject]@{
                        Name = $function.Name
                        StartLine = $function.Extent.StartLineNumber
                        EndLine = $function.Extent.EndLineNumber
                        Content = if ($IncludeContent) { $function.Extent.Text } else { $null }
                    }

                    $results += $functionInfo
                }
            }

            return $results
        }
        catch {
            Write-Error -Message "Erreur lors de l'extraction des fonctions : $_"
            throw
        }
    }
}
