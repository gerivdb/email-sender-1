<#
.SYNOPSIS
    Extrait les paramètres d'un script ou d'une fonction PowerShell.

.DESCRIPTION
    Cette fonction extrait les paramètres d'un script ou d'une fonction PowerShell en utilisant l'arbre syntaxique (AST).
    Elle permet de filtrer les paramètres par nom et d'obtenir des informations détaillées sur chaque paramètre.

.PARAMETER Ast
    L'arbre syntaxique PowerShell à analyser. Peut être obtenu via [System.Management.Automation.Language.Parser]::ParseFile() ou [System.Management.Automation.Language.Parser]::ParseInput().

.PARAMETER FunctionName
    Nom de la fonction dont on souhaite extraire les paramètres. Si non spécifié, extrait les paramètres du script.

.PARAMETER Name
    Nom du paramètre à rechercher. Peut contenir des caractères génériques.

.PARAMETER Detailed
    Si spécifié, retourne des informations détaillées sur chaque paramètre (type, valeur par défaut, etc.).

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Get-AstParameters -Ast $ast

.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\path\to\script.ps1", [ref]$null, [ref]$null)
    Get-AstParameters -Ast $ast -FunctionName "Get-Example" -Detailed

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de creation: 2023-11-15
#>
function Get-AstParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $false)]
        [string]$FunctionName,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    process {
        try {
            # Initialiser la liste des paramètres
            $parameters = @()

            # Si un nom de fonction est spécifié, rechercher cette fonction
            if ($FunctionName) {
                $function = $Ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $args[0].Name -eq $FunctionName
                }, $true) | Select-Object -First 1

                if ($function) {
                    # Extraire les paramètres de la fonction
                    $paramBlock = $function.Body.ParamBlock
                    if ($paramBlock) {
                        $parameters = $paramBlock.Parameters
                    }
                }
                else {
                    Write-Warning "Fonction '$FunctionName' non trouvée."
                    return @()
                }
            }
            else {
                # Extraire les paramètres du script
                $paramBlock = $Ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.ParamBlockAst]
                }, $false) | Select-Object -First 1

                if ($paramBlock) {
                    $parameters = $paramBlock.Parameters
                }
            }

            # Filtrer par nom si spécifié
            if ($Name) {
                $parameters = $parameters | Where-Object { $_.Name.VariablePath.UserPath -like $Name }
            }

            # Préparer les résultats
            $results = @()

            # Traiter chaque paramètre
            foreach ($param in $parameters) {
                if ($Detailed) {
                    # Extraire les attributs
                    $attributes = @()
                    foreach ($attr in $param.Attributes) {
                        $attrInfo = [PSCustomObject]@{
                            Name = $attr.TypeName.Name
                            Arguments = $attr.PositionalArguments | ForEach-Object { $_.Extent.Text }
                            NamedArguments = $attr.NamedArguments | ForEach-Object {
                                [PSCustomObject]@{
                                    Name = $_.ArgumentName
                                    Value = $_.Argument.Extent.Text
                                }
                            }
                        }
                        $attributes += $attrInfo
                    }

                    # Déterminer si le paramètre est obligatoire
                    $mandatory = $false
                    foreach ($attr in $param.Attributes) {
                        if ($attr -is [System.Management.Automation.Language.AttributeAst] -and $attr.TypeName.Name -eq "Parameter") {
                            foreach ($namedArg in $attr.NamedArguments) {
                                if ($namedArg.ArgumentName -eq "Mandatory") {
                                    $mandatory = $namedArg.Argument.SafeGetValue() -eq $true
                                    break
                                }
                            }
                        }
                    }

                    # Créer l'objet résultat détaillé
                    $paramInfo = [PSCustomObject]@{
                        Name = $param.Name.VariablePath.UserPath
                        Type = if ($param.StaticType) { $param.StaticType.Name } else { "object" }
                        DefaultValue = if ($param.DefaultValue) { $param.DefaultValue.Extent.Text } else { $null }
                        Mandatory = $mandatory
                        Position = $null
                        Attributes = $attributes
                    }

                    # Déterminer la position du paramètre
                    foreach ($attr in $param.Attributes) {
                        if ($attr -is [System.Management.Automation.Language.AttributeAst] -and $attr.TypeName.Name -eq "Parameter") {
                            foreach ($namedArg in $attr.NamedArguments) {
                                if ($namedArg.ArgumentName -eq "Position") {
                                    $paramInfo.Position = $namedArg.Argument.SafeGetValue()
                                    break
                                }
                            }
                        }
                    }

                    $results += $paramInfo
                }
                else {
                    # Créer l'objet résultat simple
                    $paramInfo = [PSCustomObject]@{
                        Name = $param.Name.VariablePath.UserPath
                        Type = if ($param.StaticType) { $param.StaticType.Name } else { "object" }
                        DefaultValue = if ($param.DefaultValue) { $param.DefaultValue.Extent.Text } else { $null }
                    }

                    $results += $paramInfo
                }
            }

            return $results
        }
        catch {
            Write-Error -Message "Erreur lors de l'extraction des paramètres : $_"
            throw
        }
    }
}
