#Requires -Version 5.1
<#
.SYNOPSIS
    Module pour l'analyse des paramÃ¨tres d'importation dans les scripts PowerShell.

.DESCRIPTION
    Ce module fournit des fonctions pour analyser les paramÃ¨tres d'importation dans les scripts PowerShell,
    en particulier pour les commandes Import-Module. Il permet de dÃ©tecter les paramÃ¨tres nommÃ©s,
    d'extraire les valeurs de paramÃ¨tres, et de gÃ©rer les paramÃ¨tres avec caractÃ¨res spÃ©ciaux.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-12-15
#>

#region Private Functions

#endregion

#region Public Functions

function Get-ImportParameterTypes {
    <#
    .SYNOPSIS
        Analyse les diffÃ©rents types de paramÃ¨tres d'importation dans une commande PowerShell.

    .DESCRIPTION
        Cette fonction analyse une commande PowerShell (gÃ©nÃ©ralement Import-Module) et identifie
        les diffÃ©rents types de paramÃ¨tres utilisÃ©s : nommÃ©s, positionnels, switches, etc.

    .PARAMETER CommandAst
        L'objet AST de la commande Ã  analyser.

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
        # Initialiser l'objet rÃ©sultat
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

        # VÃ©rifier que c'est bien une commande Import-Module
        if ($CommandAst.CommandElements.Count -eq 0 -or 
            $CommandAst.CommandElements[0].Value -ne 'Import-Module') {
            Write-Warning "La commande analysÃ©e n'est pas une commande Import-Module."
            return $result
        }

        # Analyser les Ã©lÃ©ments de la commande
        $namedParameters = @{}
        $positionalParameters = @()
        $switchParameters = @()
        $allParameters = @()

        for ($i = 1; $i -lt $CommandAst.CommandElements.Count; $i++) {
            $element = $CommandAst.CommandElements[$i]

            # VÃ©rifier si c'est un paramÃ¨tre nommÃ©
            if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
                $paramName = $element.ParameterName
                $allParameters += $paramName

                # VÃ©rifier si le paramÃ¨tre a une valeur associÃ©e
                if ($i + 1 -lt $CommandAst.CommandElements.Count -and
                    -not ($CommandAst.CommandElements[$i + 1] -is [System.Management.Automation.Language.CommandParameterAst])) {
                    $namedParameters[$paramName] = $CommandAst.CommandElements[$i + 1]
                    $i++  # Sauter l'Ã©lÃ©ment suivant car c'est la valeur du paramÃ¨tre
                } else {
                    # ParamÃ¨tre switch sans valeur
                    $switchParameters += $paramName
                }
            } else {
                # ParamÃ¨tre positionnel
                $positionalParameters += $element
            }
        }

        # Remplir l'objet rÃ©sultat
        $result.NamedParameters = $namedParameters
        $result.PositionalParameters = $positionalParameters
        $result.SwitchParameters = $switchParameters
        $result.AllParameters = $allParameters

        # VÃ©rifier les paramÃ¨tres spÃ©cifiques
        $result.HasNameParameter = $namedParameters.ContainsKey("Name")
        $result.HasPathParameter = $namedParameters.ContainsKey("Path")
        $result.HasVersionParameter = $namedParameters.ContainsKey("RequiredVersion") -or 
                                     $namedParameters.ContainsKey("MinimumVersion") -or 
                                     $namedParameters.ContainsKey("MaximumVersion")

        # VÃ©rifier les paramÃ¨tres avec caractÃ¨res spÃ©ciaux
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

        # DÃ©terminer les paramÃ¨tres optionnels et requis
        # Pour Import-Module, seul le paramÃ¨tre Name ou Path est requis (et ils sont mutuellement exclusifs)
        $requiredParams = @()
        $optionalParams = @()

        foreach ($param in $allParameters) {
            if ($param -eq "Name" -or $param -eq "Path") {
                $requiredParams += $param
            } else {
                $optionalParams += $param
            }
        }

        # Si aucun paramÃ¨tre nommÃ© Name ou Path n'est prÃ©sent, le premier paramÃ¨tre positionnel est considÃ©rÃ© comme requis
        if ($requiredParams.Count -eq 0 -and $positionalParameters.Count -gt 0) {
            $requiredParams += "PositionalName"
        }

        $result.RequiredParameters = $requiredParams
        $result.OptionalParameters = $optionalParams

        return $result
    } catch {
        Write-Error "Erreur lors de l'analyse des paramÃ¨tres d'importation : $_"
        return $null
    }
}

function Get-NamedParameters {
    <#
    .SYNOPSIS
        DÃ©tecte les paramÃ¨tres nommÃ©s dans une commande PowerShell.

    .DESCRIPTION
        Cette fonction analyse une commande PowerShell et dÃ©tecte tous les paramÃ¨tres nommÃ©s
        (paramÃ¨tres prÃ©cÃ©dÃ©s d'un tiret, comme -Name, -Path, etc.).

    .PARAMETER CommandAst
        L'objet AST de la commande Ã  analyser.

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
        # Initialiser le hashtable pour les paramÃ¨tres nommÃ©s
        $namedParameters = @{}

        # Parcourir les Ã©lÃ©ments de la commande
        for ($i = 1; $i -lt $CommandAst.CommandElements.Count; $i++) {
            $element = $CommandAst.CommandElements[$i]

            # VÃ©rifier si c'est un paramÃ¨tre nommÃ©
            if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
                $paramName = $element.ParameterName

                # VÃ©rifier si le paramÃ¨tre a une valeur associÃ©e
                if ($i + 1 -lt $CommandAst.CommandElements.Count -and
                    -not ($CommandAst.CommandElements[$i + 1] -is [System.Management.Automation.Language.CommandParameterAst])) {
                    $namedParameters[$paramName] = @{
                        Value = $CommandAst.CommandElements[$i + 1]
                        Position = $i
                        HasValue = $true
                    }
                    $i++  # Sauter l'Ã©lÃ©ment suivant car c'est la valeur du paramÃ¨tre
                } else {
                    # ParamÃ¨tre switch sans valeur
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
        Write-Error "Erreur lors de la dÃ©tection des paramÃ¨tres nommÃ©s : $_"
        return @{}
    }
}

function Get-ParameterValue {
    <#
    .SYNOPSIS
        Extrait la valeur d'un paramÃ¨tre dans une commande PowerShell.

    .DESCRIPTION
        Cette fonction extrait la valeur d'un paramÃ¨tre spÃ©cifiÃ© dans une commande PowerShell,
        en tenant compte des diffÃ©rents types de valeurs possibles (chaÃ®nes, variables, etc.).

    .PARAMETER CommandAst
        L'objet AST de la commande Ã  analyser.

    .PARAMETER ParameterName
        Le nom du paramÃ¨tre dont on veut extraire la valeur.

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
        # Obtenir les paramÃ¨tres nommÃ©s
        $namedParameters = Get-NamedParameters -CommandAst $CommandAst

        # VÃ©rifier si le paramÃ¨tre existe
        if (-not $namedParameters.ContainsKey($ParameterName)) {
            # Si c'est le paramÃ¨tre Name et qu'il n'est pas spÃ©cifiÃ© explicitement,
            # vÃ©rifier s'il y a un paramÃ¨tre positionnel qui pourrait Ãªtre le nom du module
            if ($ParameterName -eq "Name" -and $CommandAst.CommandElements.Count -gt 1) {
                for ($i = 1; $i -lt $CommandAst.CommandElements.Count; $i++) {
                    $element = $CommandAst.CommandElements[$i]
                    if (-not ($element -is [System.Management.Automation.Language.CommandParameterAst])) {
                        # C'est probablement un paramÃ¨tre positionnel pour le nom du module
                        return ExtractParameterValue -Parameter $element
                    }
                }
            }
            return $null
        }

        # Extraire la valeur du paramÃ¨tre
        $paramInfo = $namedParameters[$ParameterName]
        if ($paramInfo.HasValue) {
            return ExtractParameterValue -Parameter $paramInfo.Value
        } else {
            return $true  # Pour les paramÃ¨tres switch
        }
    } catch {
        Write-Error "Erreur lors de l'extraction de la valeur du paramÃ¨tre '$ParameterName' : $_"
        return $null
    }
}

function ExtractParameterValue {
    <#
    .SYNOPSIS
        Extrait la valeur d'un paramÃ¨tre AST.

    .DESCRIPTION
        Cette fonction interne extrait la valeur d'un paramÃ¨tre AST en fonction de son type.

    .PARAMETER Parameter
        Le paramÃ¨tre AST Ã  analyser.

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
        VÃ©rifie si un paramÃ¨tre contient des caractÃ¨res spÃ©ciaux.

    .DESCRIPTION
        Cette fonction vÃ©rifie si la valeur d'un paramÃ¨tre spÃ©cifiÃ© dans une commande PowerShell
        contient des caractÃ¨res spÃ©ciaux qui pourraient nÃ©cessiter un traitement particulier.

    .PARAMETER CommandAst
        L'objet AST de la commande Ã  analyser.

    .PARAMETER ParameterName
        Le nom du paramÃ¨tre Ã  vÃ©rifier.

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
        # Obtenir la valeur du paramÃ¨tre
        $paramValue = Get-ParameterValue -CommandAst $CommandAst -ParameterName $ParameterName

        # VÃ©rifier si la valeur contient des caractÃ¨res spÃ©ciaux
        if ($paramValue -is [string]) {
            return $paramValue -match '[`~!@#$%^&*()+={}[\]|\\:;"''<>,.?/]'
        }

        return $false
    } catch {
        Write-Error "Erreur lors de la vÃ©rification des caractÃ¨res spÃ©ciaux dans le paramÃ¨tre '$ParameterName' : $_"
        return $false
    }
}

function Get-OptionalParameters {
    <#
    .SYNOPSIS
        DÃ©tecte les paramÃ¨tres optionnels dans une commande Import-Module.

    .DESCRIPTION
        Cette fonction analyse une commande Import-Module et identifie tous les paramÃ¨tres
        qui sont optionnels (non requis pour l'exÃ©cution de la commande).

    .PARAMETER CommandAst
        L'objet AST de la commande Ã  analyser.

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
        # Obtenir tous les paramÃ¨tres de la commande
        $parameterTypes = Get-ImportParameterTypes -CommandAst $CommandAst

        # Retourner les paramÃ¨tres optionnels
        return $parameterTypes.OptionalParameters
    } catch {
        Write-Error "Erreur lors de la dÃ©tection des paramÃ¨tres optionnels : $_"
        return @()
    }
}

#endregion

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-ImportParameterTypes, Get-NamedParameters, Get-ParameterValue, Test-SpecialCharactersInParameter, Get-OptionalParameters
