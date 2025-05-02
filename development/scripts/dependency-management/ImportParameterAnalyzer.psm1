#Requires -Version 5.1
<#
.SYNOPSIS
    Module pour l'analyse des paramètres d'importation dans les scripts PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions pour analyser les paramètres d'importation dans les scripts PowerShell,
    en particulier pour les commandes Import-Module. Il permet de détecter les paramètres nommés,
    d'extraire les valeurs de paramètres, et de gérer les paramètres avec caractères spéciaux.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-12-15
#>

#region Private Functions

#endregion

#region Public Functions

function Get-ImportParameterTypes {
    <#
    .SYNOPSIS
        Analyse les différents types de paramètres d'importation dans une commande PowerShell.

    .DESCRIPTION
        Cette fonction analyse une commande PowerShell (généralement Import-Module) et identifie
        les différents types de paramètres utilisés : nommés, positionnels, switches, etc.

    .PARAMETER CommandAst
        L'objet AST de la commande à analyser.

    .EXAMPLE
        $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\script.ps1", [ref]$null, [ref]$null)
        $importCommands = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] -and 
                                        $args[0].CommandElements[0].Value -eq 'Import-Module' }, $true)
        $parameterTypes = Get-ImportParameterTypes -CommandAst $importCommands[0]

    .OUTPUTS
        PSCustomObject
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.CommandAst]$CommandAst
    )

    try {
        # Initialiser l'objet résultat
        $result = [PSCustomObject]@{
            NamedParameters = @{}
            PositionalParameters = @()
            SwitchParameters = @()
            HasNameParameter = $false
            HasPathParameter = $false
            HasVersionParameter = $false
            HasSpecialCharacters = $false
            OptionalParameters = @()
            RequiredParameters = @()
            AllParameters = @()
        }

        # Vérifier que c'est bien une commande Import-Module
        if ($CommandAst.CommandElements.Count -eq 0 -or 
            $CommandAst.CommandElements[0].Value -ne 'Import-Module') {
            Write-Warning "La commande analysée n'est pas une commande Import-Module."
            return $result
        }

        # Analyser les éléments de la commande
        $namedParameters = @{}
        $positionalParameters = @()
        $switchParameters = @()
        $allParameters = @()

        for ($i = 1; $i -lt $CommandAst.CommandElements.Count; $i++) {
            $element = $CommandAst.CommandElements[$i]

            # Vérifier si c'est un paramètre nommé
            if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
                $paramName = $element.ParameterName
                $allParameters += $paramName

                # Vérifier si le paramètre a une valeur associée
                if ($i + 1 -lt $CommandAst.CommandElements.Count -and
                    -not ($CommandAst.CommandElements[$i + 1] -is [System.Management.Automation.Language.CommandParameterAst])) {
                    $namedParameters[$paramName] = $CommandAst.CommandElements[$i + 1]
                    $i++  # Sauter l'élément suivant car c'est la valeur du paramètre
                } else {
                    # Paramètre switch sans valeur
                    $switchParameters += $paramName
                }
            } else {
                # Paramètre positionnel
                $positionalParameters += $element
            }
        }

        # Remplir l'objet résultat
        $result.NamedParameters = $namedParameters
        $result.PositionalParameters = $positionalParameters
        $result.SwitchParameters = $switchParameters
        $result.AllParameters = $allParameters

        # Vérifier les paramètres spécifiques
        $result.HasNameParameter = $namedParameters.ContainsKey("Name")
        $result.HasPathParameter = $namedParameters.ContainsKey("Path")
        $result.HasVersionParameter = $namedParameters.ContainsKey("RequiredVersion") -or 
                                     $namedParameters.ContainsKey("MinimumVersion") -or 
                                     $namedParameters.ContainsKey("MaximumVersion")

        # Vérifier les paramètres avec caractères spéciaux
        foreach ($param in $namedParameters.Keys) {
            $value = $namedParameters[$param]
            if ($value -is [System.Management.Automation.Language.StringConstantExpressionAst] -or 
                $value -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
                $valueText = $value.Extent.Text
                if ($valueText -match '[`~!@#$%^&*()+={}[\]|\\:;"''<>,.?/]') {
                    $result.HasSpecialCharacters = $true
                    break
                }
            }
        }

        # Déterminer les paramètres optionnels et requis
        # Pour Import-Module, seul le paramètre Name ou Path est requis (et ils sont mutuellement exclusifs)
        $requiredParams = @()
        $optionalParams = @()

        foreach ($param in $allParameters) {
            if ($param -eq "Name" -or $param -eq "Path") {
                $requiredParams += $param
            } else {
                $optionalParams += $param
            }
        }

        # Si aucun paramètre nommé Name ou Path n'est présent, le premier paramètre positionnel est considéré comme requis
        if ($requiredParams.Count -eq 0 -and $positionalParameters.Count -gt 0) {
            $requiredParams += "PositionalName"
        }

        $result.RequiredParameters = $requiredParams
        $result.OptionalParameters = $optionalParams

        return $result
    } catch {
        Write-Error "Erreur lors de l'analyse des paramètres d'importation : $_"
        return $null
    }
}

function Get-NamedParameters {
    <#
    .SYNOPSIS
        Détecte les paramètres nommés dans une commande PowerShell.

    .DESCRIPTION
        Cette fonction analyse une commande PowerShell et détecte tous les paramètres nommés
        (paramètres précédés d'un tiret, comme -Name, -Path, etc.).

    .PARAMETER CommandAst
        L'objet AST de la commande à analyser.

    .EXAMPLE
        $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\script.ps1", [ref]$null, [ref]$null)
        $importCommands = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] -and 
                                        $args[0].CommandElements[0].Value -eq 'Import-Module' }, $true)
        $namedParams = Get-NamedParameters -CommandAst $importCommands[0]

    .OUTPUTS
        Hashtable
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.CommandAst]$CommandAst
    )

    try {
        # Initialiser le hashtable pour les paramètres nommés
        $namedParameters = @{}

        # Parcourir les éléments de la commande
        for ($i = 1; $i -lt $CommandAst.CommandElements.Count; $i++) {
            $element = $CommandAst.CommandElements[$i]

            # Vérifier si c'est un paramètre nommé
            if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
                $paramName = $element.ParameterName

                # Vérifier si le paramètre a une valeur associée
                if ($i + 1 -lt $CommandAst.CommandElements.Count -and
                    -not ($CommandAst.CommandElements[$i + 1] -is [System.Management.Automation.Language.CommandParameterAst])) {
                    $namedParameters[$paramName] = @{
                        Value = $CommandAst.CommandElements[$i + 1]
                        Position = $i
                        HasValue = $true
                    }
                    $i++  # Sauter l'élément suivant car c'est la valeur du paramètre
                } else {
                    # Paramètre switch sans valeur
                    $namedParameters[$paramName] = @{
                        Value = $true
                        Position = $i
                        HasValue = $false
                    }
                }
            }
        }

        return $namedParameters
    } catch {
        Write-Error "Erreur lors de la détection des paramètres nommés : $_"
        return @{}
    }
}

function Get-ParameterValue {
    <#
    .SYNOPSIS
        Extrait la valeur d'un paramètre dans une commande PowerShell.

    .DESCRIPTION
        Cette fonction extrait la valeur d'un paramètre spécifié dans une commande PowerShell,
        en tenant compte des différents types de valeurs possibles (chaînes, variables, etc.).

    .PARAMETER CommandAst
        L'objet AST de la commande à analyser.

    .PARAMETER ParameterName
        Le nom du paramètre dont on veut extraire la valeur.

    .EXAMPLE
        $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\script.ps1", [ref]$null, [ref]$null)
        $importCommands = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] -and 
                                        $args[0].CommandElements[0].Value -eq 'Import-Module' }, $true)
        $nameValue = Get-ParameterValue -CommandAst $importCommands[0] -ParameterName "Name"

    .OUTPUTS
        System.Object
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.CommandAst]$CommandAst,

        [Parameter(Mandatory = $true)]
        [string]$ParameterName
    )

    try {
        # Obtenir les paramètres nommés
        $namedParameters = Get-NamedParameters -CommandAst $CommandAst

        # Vérifier si le paramètre existe
        if (-not $namedParameters.ContainsKey($ParameterName)) {
            # Si c'est le paramètre Name et qu'il n'est pas spécifié explicitement,
            # vérifier s'il y a un paramètre positionnel qui pourrait être le nom du module
            if ($ParameterName -eq "Name" -and $CommandAst.CommandElements.Count -gt 1) {
                for ($i = 1; $i -lt $CommandAst.CommandElements.Count; $i++) {
                    $element = $CommandAst.CommandElements[$i]
                    if (-not ($element -is [System.Management.Automation.Language.CommandParameterAst])) {
                        # C'est probablement un paramètre positionnel pour le nom du module
                        return ExtractParameterValue -Parameter $element
                    }
                }
            }
            return $null
        }

        # Extraire la valeur du paramètre
        $paramInfo = $namedParameters[$ParameterName]
        if ($paramInfo.HasValue) {
            return ExtractParameterValue -Parameter $paramInfo.Value
        } else {
            return $true  # Pour les paramètres switch
        }
    } catch {
        Write-Error "Erreur lors de l'extraction de la valeur du paramètre '$ParameterName' : $_"
        return $null
    }
}

function ExtractParameterValue {
    <#
    .SYNOPSIS
        Extrait la valeur d'un paramètre AST.

    .DESCRIPTION
        Cette fonction interne extrait la valeur d'un paramètre AST en fonction de son type.

    .PARAMETER Parameter
        Le paramètre AST à analyser.

    .OUTPUTS
        System.Object
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Parameter
    )

    if ($Parameter -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
        return $Parameter.Value
    } elseif ($Parameter -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
        return $Parameter.Value
    } elseif ($Parameter -is [System.Management.Automation.Language.VariableExpressionAst]) {
        return "$" + $Parameter.VariablePath.UserPath
    } elseif ($Parameter -is [bool]) {
        return $Parameter
    } else {
        return $Parameter.Extent.Text
    }
}

function Test-SpecialCharactersInParameter {
    <#
    .SYNOPSIS
        Vérifie si un paramètre contient des caractères spéciaux.

    .DESCRIPTION
        Cette fonction vérifie si la valeur d'un paramètre spécifié dans une commande PowerShell
        contient des caractères spéciaux qui pourraient nécessiter un traitement particulier.

    .PARAMETER CommandAst
        L'objet AST de la commande à analyser.

    .PARAMETER ParameterName
        Le nom du paramètre à vérifier.

    .EXAMPLE
        $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\script.ps1", [ref]$null, [ref]$null)
        $importCommands = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] -and 
                                        $args[0].CommandElements[0].Value -eq 'Import-Module' }, $true)
        $hasSpecialChars = Test-SpecialCharactersInParameter -CommandAst $importCommands[0] -ParameterName "Name"

    .OUTPUTS
        System.Boolean
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.CommandAst]$CommandAst,

        [Parameter(Mandatory = $true)]
        [string]$ParameterName
    )

    try {
        # Obtenir la valeur du paramètre
        $paramValue = Get-ParameterValue -CommandAst $CommandAst -ParameterName $ParameterName

        # Vérifier si la valeur contient des caractères spéciaux
        if ($paramValue -is [string]) {
            return $paramValue -match '[`~!@#$%^&*()+={}[\]|\\:;"''<>,.?/]'
        }

        return $false
    } catch {
        Write-Error "Erreur lors de la vérification des caractères spéciaux dans le paramètre '$ParameterName' : $_"
        return $false
    }
}

function Get-OptionalParameters {
    <#
    .SYNOPSIS
        Détecte les paramètres optionnels dans une commande Import-Module.

    .DESCRIPTION
        Cette fonction analyse une commande Import-Module et identifie tous les paramètres
        qui sont optionnels (non requis pour l'exécution de la commande).

    .PARAMETER CommandAst
        L'objet AST de la commande à analyser.

    .EXAMPLE
        $ast = [System.Management.Automation.Language.Parser]::ParseFile("C:\script.ps1", [ref]$null, [ref]$null)
        $importCommands = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] -and 
                                        $args[0].CommandElements[0].Value -eq 'Import-Module' }, $true)
        $optionalParams = Get-OptionalParameters -CommandAst $importCommands[0]

    .OUTPUTS
        System.String[]
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.CommandAst]$CommandAst
    )

    try {
        # Obtenir tous les paramètres de la commande
        $parameterTypes = Get-ImportParameterTypes -CommandAst $CommandAst

        # Retourner les paramètres optionnels
        return $parameterTypes.OptionalParameters
    } catch {
        Write-Error "Erreur lors de la détection des paramètres optionnels : $_"
        return @()
    }
}

#endregion

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-ImportParameterTypes, Get-NamedParameters, Get-ParameterValue, Test-SpecialCharactersInParameter, Get-OptionalParameters
