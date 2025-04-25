<#
.SYNOPSIS
    Définit les fonctions de trace pour le module RoadmapParser.

.DESCRIPTION
    Ce script définit les fonctions de trace utilisées par le module RoadmapParser.
    Il inclut des fonctions pour tracer l'entrée, la sortie et les étapes intermédiaires des fonctions.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-22
#>

# Importer le script des fonctions de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$loggingFunctionsPath = Join-Path -Path $scriptPath -ChildPath "LoggingFunctions.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $loggingFunctionsPath)) {
    throw "Le fichier LoggingFunctions.ps1 est introuvable à l'emplacement : $loggingFunctionsPath"
}

# Importer le script
. $loggingFunctionsPath

# Variables globales pour la gestion de la trace
$script:TracingEnabled = $true
$script:TracingLevel = $script:LogLevelDebug
$script:TracingIndentSize = 2
$script:TracingIndentChar = " "
$script:TracingCurrentDepth = 0
$script:TracingMaxDepth = 10
$script:TracingShowParameters = $true
$script:TracingParameterMaxLength = 50
$script:TracingParameterMaxCount = 10
$script:TracingShowTypes = $true
$script:TracingCategory = "Tracing"

<#
.SYNOPSIS
    Configure les options de trace.

.DESCRIPTION
    La fonction Set-TracingConfiguration configure les options de trace.
    Elle permet de définir les paramètres de trace tels que l'activation, le niveau, etc.

.PARAMETER Enabled
    Indique si la trace est activée.
    Par défaut, c'est $true.

.PARAMETER Level
    Le niveau de journalisation pour la trace.
    Par défaut, c'est LogLevelDebug.

.PARAMETER IndentSize
    La taille de l'indentation pour chaque niveau de profondeur.
    Par défaut, c'est 2.

.PARAMETER IndentChar
    Le caractère utilisé pour l'indentation.
    Par défaut, c'est un espace.

.PARAMETER MaxDepth
    La profondeur maximale de trace.
    Par défaut, c'est 10.

.PARAMETER ShowParameters
    Indique si les paramètres doivent être affichés dans la trace.
    Par défaut, c'est $true.

.PARAMETER ParameterMaxLength
    La longueur maximale des valeurs de paramètres à afficher.
    Par défaut, c'est 50.

.PARAMETER ParameterMaxCount
    Le nombre maximal de paramètres à afficher.
    Par défaut, c'est 10.

.PARAMETER ShowTypes
    Indique si les types doivent être affichés dans la trace.
    Par défaut, c'est $true.

.PARAMETER Category
    La catégorie à utiliser pour la journalisation.
    Par défaut, c'est "Tracing".

.EXAMPLE
    Set-TracingConfiguration -Enabled $true -Level $LogLevelDebug -IndentSize 4
    Configure la trace pour être activée, avec un niveau de débogage et une indentation de 4 espaces.

.OUTPUTS
    [void]
#>
function Set-TracingConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [bool]$Enabled = $true,

        [Parameter(Mandatory = $false)]
        [object]$Level = $script:LogLevelDebug,

        [Parameter(Mandatory = $false)]
        [int]$IndentSize = 2,

        [Parameter(Mandatory = $false)]
        [string]$IndentChar = " ",

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 10,

        [Parameter(Mandatory = $false)]
        [bool]$ShowParameters = $true,

        [Parameter(Mandatory = $false)]
        [int]$ParameterMaxLength = 50,

        [Parameter(Mandatory = $false)]
        [int]$ParameterMaxCount = 10,

        [Parameter(Mandatory = $false)]
        [bool]$ShowTypes = $true,

        [Parameter(Mandatory = $false)]
        [string]$Category = "Tracing"
    )

    # Valider le niveau de journalisation
    $script:TracingLevel = ConvertTo-LogLevel -Value $Level

    # Mettre à jour la configuration
    $script:TracingEnabled = $Enabled
    $script:TracingIndentSize = $IndentSize
    $script:TracingIndentChar = $IndentChar
    $script:TracingMaxDepth = $MaxDepth
    $script:TracingShowParameters = $ShowParameters
    $script:TracingParameterMaxLength = $ParameterMaxLength
    $script:TracingParameterMaxCount = $ParameterMaxCount
    $script:TracingShowTypes = $ShowTypes
    $script:TracingCategory = $Category
}

<#
.SYNOPSIS
    Obtient la configuration de trace.

.DESCRIPTION
    La fonction Get-TracingConfiguration obtient la configuration de trace.
    Elle retourne un objet contenant les paramètres de trace actuels.

.EXAMPLE
    Get-TracingConfiguration
    Obtient la configuration de trace.

.OUTPUTS
    [PSCustomObject] Un objet contenant la configuration de trace.
#>
function Get-TracingConfiguration {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    return [PSCustomObject]@{
        Enabled            = $script:TracingEnabled
        Level              = $script:TracingLevel
        LevelName          = Get-LogLevelName -LogLevel $script:TracingLevel
        IndentSize         = $script:TracingIndentSize
        IndentChar         = $script:TracingIndentChar
        CurrentDepth       = $script:TracingCurrentDepth
        MaxDepth           = $script:TracingMaxDepth
        ShowParameters     = $script:TracingShowParameters
        ParameterMaxLength = $script:TracingParameterMaxLength
        ParameterMaxCount  = $script:TracingParameterMaxCount
        ShowTypes          = $script:TracingShowTypes
        Category           = $script:TracingCategory
    }
}

<#
.SYNOPSIS
    Obtient l'indentation actuelle pour la trace.

.DESCRIPTION
    La fonction Get-TracingIndent obtient l'indentation actuelle pour la trace.
    Elle calcule l'indentation en fonction de la profondeur actuelle.

.EXAMPLE
    Get-TracingIndent
    Obtient l'indentation actuelle pour la trace.

.OUTPUTS
    [string] L'indentation actuelle.
#>
function Get-TracingIndent {
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    $indent = ""
    for ($i = 0; $i -lt $script:TracingCurrentDepth; $i++) {
        $indent += $script:TracingIndentChar * $script:TracingIndentSize
    }

    return $indent
}

<#
.SYNOPSIS
    Formate les paramètres pour la trace.

.DESCRIPTION
    La fonction Format-TracingParameters formate les paramètres pour la trace.
    Elle prend en charge la limitation de la longueur et du nombre de paramètres.

.PARAMETER Parameters
    Les paramètres à formater.

.EXAMPLE
    Format-TracingParameters -Parameters $PSBoundParameters
    Formate les paramètres liés pour la trace.

.OUTPUTS
    [string] Les paramètres formatés.
#>
function Format-TracingParameters {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Collections.IDictionary]$Parameters
    )

    if (-not $script:TracingShowParameters -or $null -eq $Parameters -or $Parameters.Count -eq 0) {
        return ""
    }

    $formattedParams = @()
    $count = 0

    foreach ($key in $Parameters.Keys) {
        if ($count -ge $script:TracingParameterMaxCount) {
            $formattedParams += "..."
            break
        }

        $value = $Parameters[$key]
        $valueStr = ""

        if ($null -eq $value) {
            $valueStr = "null"
        } elseif ($value -is [string]) {
            if ($value.Length -gt $script:TracingParameterMaxLength) {
                $valueStr = "'$($value.Substring(0, $script:TracingParameterMaxLength))...'"
            } else {
                $valueStr = "'$value'"
            }
        } elseif ($value -is [bool] -or $value -is [int] -or $value -is [long] -or $value -is [double] -or $value -is [decimal]) {
            $valueStr = "$value"
        } elseif ($value -is [array] -or $value -is [System.Collections.ICollection]) {
            $valueStr = "[$($value.GetType().Name)][$($value.Count) items]"
        } else {
            $valueStr = "[$($value.GetType().Name)]"
        }

        if ($script:TracingShowTypes -and $null -ne $value) {
            $typeName = $value.GetType().Name
            $formattedParams += "$key = $valueStr [$typeName]"
        } else {
            $formattedParams += "$key = $valueStr"
        }

        $count++
    }

    return "(" + ($formattedParams -join ", ") + ")"
}

<#
.SYNOPSIS
    Trace l'entrée dans une fonction.

.DESCRIPTION
    La fonction Trace-FunctionEntry trace l'entrée dans une fonction.
    Elle enregistre le nom de la fonction et les paramètres d'entrée.

.PARAMETER FunctionName
    Le nom de la fonction.
    Par défaut, c'est le nom de la fonction appelante.

.PARAMETER Parameters
    Les paramètres de la fonction.
    Par défaut, ce sont les paramètres liés de la fonction appelante.

.PARAMETER CallerName
    Le nom de l'appelant.
    Par défaut, c'est déterminé automatiquement.

.PARAMETER IncreaseDepth
    Indique si la profondeur doit être augmentée après la trace.
    Par défaut, c'est $true.

.EXAMPLE
    Trace-FunctionEntry
    Trace l'entrée dans la fonction appelante.

.EXAMPLE
    Trace-FunctionEntry -FunctionName "Ma-Fonction" -Parameters $PSBoundParameters
    Trace l'entrée dans la fonction "Ma-Fonction" avec les paramètres spécifiés.

.OUTPUTS
    [void]
#>
function Trace-FunctionEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$FunctionName = (Get-PSCallStack)[1].Command,

        [Parameter(Mandatory = $false)]
        [System.Collections.IDictionary]$Parameters = (Get-Variable -Name PSBoundParameters -Scope 1 -ErrorAction SilentlyContinue).Value,

        [Parameter(Mandatory = $false)]
        [string]$CallerName,

        [Parameter(Mandatory = $false)]
        [switch]$IncreaseDepth = $true
    )

    # Vérifier si la trace est activée
    if (-not $script:TracingEnabled) {
        return
    }

    # Vérifier si la profondeur maximale est atteinte
    if ($script:TracingCurrentDepth -ge $script:TracingMaxDepth) {
        return
    }

    # Obtenir l'indentation actuelle
    $indent = Get-TracingIndent

    # Déterminer le nom de l'appelant si non spécifié
    if ([string]::IsNullOrEmpty($CallerName)) {
        $callStack = Get-PSCallStack
        if ($callStack.Count -gt 2) {
            $CallerName = $callStack[2].Command
        }
    }

    # Construire le message de trace
    $message = "${indent}ENTER: $FunctionName"

    # Ajouter l'appelant si disponible
    if (-not [string]::IsNullOrEmpty($CallerName)) {
        $message += " (called by $CallerName)"
    }

    # Ajouter les paramètres si disponibles
    if ($null -ne $Parameters -and $Parameters.Count -gt 0) {
        $formattedParams = Format-TracingParameters -Parameters $Parameters
        $message += " $formattedParams"
    }

    # Écrire le message de trace
    Write-Log -Message $message -Level $script:TracingLevel -Source $script:TracingCategory

    # Augmenter la profondeur si demandé
    if ($IncreaseDepth) {
        $script:TracingCurrentDepth++
    }
}

<#
.SYNOPSIS
    Trace la sortie d'une fonction.

.DESCRIPTION
    La fonction Trace-FunctionExit trace la sortie d'une fonction.
    Elle enregistre le nom de la fonction et la valeur de retour.

.PARAMETER FunctionName
    Le nom de la fonction.
    Par défaut, c'est le nom de la fonction appelante.

.PARAMETER ReturnValue
    La valeur de retour de la fonction.

.PARAMETER DecreaseDepth
    Indique si la profondeur doit être diminuée avant la trace.
    Par défaut, c'est $true.

.EXAMPLE
    Trace-FunctionExit
    Trace la sortie de la fonction appelante.

.EXAMPLE
    Trace-FunctionExit -FunctionName "Ma-Fonction" -ReturnValue $result
    Trace la sortie de la fonction "Ma-Fonction" avec la valeur de retour spécifiée.

.OUTPUTS
    [void]
#>
function Trace-FunctionExit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$FunctionName = (Get-PSCallStack)[1].Command,

        [Parameter(Mandatory = $false)]
        [object]$ReturnValue,

        [Parameter(Mandatory = $false)]
        [switch]$DecreaseDepth = $true
    )

    # Vérifier si la trace est activée
    if (-not $script:TracingEnabled) {
        return
    }

    # Diminuer la profondeur si demandé
    if ($DecreaseDepth) {
        $script:TracingCurrentDepth = [Math]::Max(0, $script:TracingCurrentDepth - 1)
    }

    # Obtenir l'indentation actuelle
    $indent = Get-TracingIndent

    # Construire le message de trace
    $message = "${indent}EXIT: $FunctionName"

    # Ajouter la valeur de retour si disponible
    if ($PSBoundParameters.ContainsKey('ReturnValue')) {
        if ($null -eq $ReturnValue) {
            $message += " => null"
        } elseif ($ReturnValue -is [string]) {
            if ($ReturnValue.Length -gt $script:TracingParameterMaxLength) {
                $message += " => '$($ReturnValue.Substring(0, $script:TracingParameterMaxLength))...'"
            } else {
                $message += " => '$ReturnValue'"
            }
        } elseif ($ReturnValue -is [bool] -or $ReturnValue -is [int] -or $ReturnValue -is [long] -or $ReturnValue -is [double] -or $ReturnValue -is [decimal]) {
            $message += " => $ReturnValue"
        } elseif ($ReturnValue -is [array] -or $ReturnValue -is [System.Collections.ICollection]) {
            $message += " => [$($ReturnValue.GetType().Name)][$($ReturnValue.Count) items]"
        } else {
            $message += " => [$($ReturnValue.GetType().Name)]"
        }

        # Ajouter le type si demandé
        if ($script:TracingShowTypes -and $null -ne $ReturnValue) {
            $typeName = $ReturnValue.GetType().Name
            $message += " [$typeName]"
        }
    }

    # Écrire le message de trace
    Write-Log -Message $message -Level $script:TracingLevel -Source $script:TracingCategory
}

<#
.SYNOPSIS
    Trace une étape intermédiaire dans une fonction.

.DESCRIPTION
    La fonction Trace-FunctionStep trace une étape intermédiaire dans une fonction.
    Elle enregistre le nom de l'étape et les données associées.

.PARAMETER StepName
    Le nom de l'étape.

.PARAMETER StepData
    Les données associées à l'étape.

.PARAMETER FunctionName
    Le nom de la fonction.
    Par défaut, c'est le nom de la fonction appelante.

.EXAMPLE
    Trace-FunctionStep -StepName "Validation des données"
    Trace l'étape "Validation des données" dans la fonction appelante.

.EXAMPLE
    Trace-FunctionStep -StepName "Traitement" -StepData $data
    Trace l'étape "Traitement" avec les données spécifiées dans la fonction appelante.

.OUTPUTS
    [void]
#>
function Trace-FunctionStep {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$StepName,

        [Parameter(Mandatory = $false, Position = 1)]
        [object]$StepData,

        [Parameter(Mandatory = $false)]
        [string]$FunctionName = (Get-PSCallStack)[1].Command
    )

    # Vérifier si la trace est activée
    if (-not $script:TracingEnabled) {
        return
    }

    # Obtenir l'indentation actuelle
    $indent = Get-TracingIndent

    # Construire le message de trace
    $message = "${indent}STEP: [$FunctionName] $StepName"

    # Ajouter les données si disponibles
    if ($PSBoundParameters.ContainsKey('StepData')) {
        if ($null -eq $StepData) {
            $message += " => null"
        } elseif ($StepData -is [string]) {
            if ($StepData.Length -gt $script:TracingParameterMaxLength) {
                $message += " => '$($StepData.Substring(0, $script:TracingParameterMaxLength))...'"
            } else {
                $message += " => '$StepData'"
            }
        } elseif ($StepData -is [bool] -or $StepData -is [int] -or $StepData -is [long] -or $StepData -is [double] -or $StepData -is [decimal]) {
            $message += " => $StepData"
        } elseif ($StepData -is [array] -or $StepData -is [System.Collections.ICollection]) {
            $message += " => [$($StepData.GetType().Name)][$($StepData.Count) items]"
        } else {
            $message += " => [$($StepData.GetType().Name)]"
        }

        # Ajouter le type si demandé
        if ($script:TracingShowTypes -and $null -ne $StepData) {
            $typeName = $StepData.GetType().Name
            $message += " [$typeName]"
        }
    }

    # Écrire le message de trace
    Write-Log -Message $message -Level $script:TracingLevel -Source $script:TracingCategory
}

# Exporter les fonctions
Export-ModuleMember -Function Set-TracingConfiguration, Get-TracingConfiguration, Trace-FunctionEntry, Trace-FunctionExit, Trace-FunctionStep
