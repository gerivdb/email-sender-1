<#
.SYNOPSIS
    Extrait les paramÃ¨tres d'un script ou d'une fonction PowerShell.

.DESCRIPTION
    Cette fonction extrait les paramÃ¨tres d'un script ou d'une fonction PowerShell en utilisant l'arbre syntaxique (AST).
    Elle permet de filtrer les paramÃ¨tres par nom et d'obtenir des informations dÃ©taillÃ©es sur chaque paramÃ¨tre.

.PARAMETER Ast
    L'arbre syntaxique PowerShell Ã  analyser. Peut Ãªtre obtenu via [System.Management.Automation.Language.Parser]::ParseFile() ou [System.Management.Automation.Language.Parser]::ParseInput().

.PARAMETER FunctionName
    Nom de la fonction dont on souhaite extraire les paramÃ¨tres. Si non spÃ©cifiÃ©, extrait les paramÃ¨tres du script.

.PARAMETER Name
    Nom du paramÃ¨tre Ã  rechercher. Peut contenir des caractÃ¨res gÃ©nÃ©riques.

.PARAMETER Detailed
    Si spÃ©cifiÃ©, retourne des informations dÃ©taillÃ©es sur chaque paramÃ¨tre (type, valeur par dÃ©faut, etc.).

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
            # Initialiser la liste des paramÃ¨tres
            $parameters = @()

            # Si un nom de fonction est spÃ©cifiÃ©, rechercher cette fonction
            if ($FunctionName) {
                $function = $Ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $args[0].Name -eq $FunctionName
                }, $true) | Select-Object -First 1

                if ($function) {
                    # Extraire les paramÃ¨tres de la fonction
                    $paramBlock = $function.Body.ParamBlock
                    if ($paramBlock) {
                        $parameters = $paramBlock.Parameters
                    }
                }
                else {
                    Write-Warning "Fonction '$FunctionName' non trouvÃ©e."
                    return @()
                }
            }
            else {
                # Extraire les paramÃ¨tres du script
                $paramBlock = $Ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.ParamBlockAst]
                }, $false) | Select-Object -First 1

                if ($paramBlock) {
                    $parameters = $paramBlock.Parameters
                }
            }

            # Filtrer par nom si spÃ©cifiÃ©
            if ($Name) {
                $parameters = $parameters | Where-Object { $_.Name.VariablePath.UserPath -like $Name }
            }

            # PrÃ©parer les rÃ©sultats
            $results = @()

            # Traiter chaque paramÃ¨tre
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

                    # DÃ©terminer si le paramÃ¨tre est obligatoire
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

                    # CrÃ©er l'objet rÃ©sultat dÃ©taillÃ©
                    $paramInfo = [PSCustomObject]@{
                        Name = $param.Name.VariablePath.UserPath
                        Type = if ($param.StaticType) { $param.StaticType.Name } else { "object" }
                        DefaultValue = if ($param.DefaultValue) { $param.DefaultValue.Extent.Text } else { $null }
                        Mandatory = $mandatory
                        Position = $null
                        Attributes = $attributes
                    }

                    # DÃ©terminer la position du paramÃ¨tre
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
                    # CrÃ©er l'objet rÃ©sultat simple
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
            Write-Error -Message "Erreur lors de l'extraction des paramÃ¨tres : $_"
            throw
        }
    }
}
