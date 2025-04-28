<#
.SYNOPSIS
    DÃ©finit les niveaux de journalisation pour le module RoadmapParser.

.DESCRIPTION
    Ce script dÃ©finit les niveaux de journalisation utilisÃ©s par le module RoadmapParser.
    Il inclut une Ã©numÃ©ration pour les niveaux de journalisation et des constantes pour
    faciliter leur utilisation.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-21
#>

# DÃ©finir l'Ã©numÃ©ration pour les niveaux de journalisation
Add-Type -TypeDefinition @"
    using System;
    
    namespace RoadmapParser.Logging {
        [Flags]
        public enum LogLevel {
            None = 0,
            Debug = 1,
            Verbose = 2,
            Information = 4,
            Warning = 8,
            Error = 16,
            Critical = 32,
            All = 63
        }
    }
"@ -ErrorAction SilentlyContinue

# DÃ©finir les constantes pour les niveaux de journalisation
$script:LogLevelNone = [RoadmapParser.Logging.LogLevel]::None
$script:LogLevelDebug = [RoadmapParser.Logging.LogLevel]::Debug
$script:LogLevelVerbose = [RoadmapParser.Logging.LogLevel]::Verbose
$script:LogLevelInformation = [RoadmapParser.Logging.LogLevel]::Information
$script:LogLevelWarning = [RoadmapParser.Logging.LogLevel]::Warning
$script:LogLevelError = [RoadmapParser.Logging.LogLevel]::Error
$script:LogLevelCritical = [RoadmapParser.Logging.LogLevel]::Critical
$script:LogLevelAll = [RoadmapParser.Logging.LogLevel]::All

# DÃ©finir un tableau des niveaux de journalisation disponibles
$script:AvailableLogLevels = @(
    $script:LogLevelNone,
    $script:LogLevelDebug,
    $script:LogLevelVerbose,
    $script:LogLevelInformation,
    $script:LogLevelWarning,
    $script:LogLevelError,
    $script:LogLevelCritical,
    $script:LogLevelAll
)

# DÃ©finir un dictionnaire pour mapper les niveaux de journalisation aux couleurs
$script:LogLevelColors = @{
    $script:LogLevelNone = "White"
    $script:LogLevelDebug = "Gray"
    $script:LogLevelVerbose = "Cyan"
    $script:LogLevelInformation = "Green"
    $script:LogLevelWarning = "Yellow"
    $script:LogLevelError = "Red"
    $script:LogLevelCritical = "Magenta"
    $script:LogLevelAll = "White"
}

# DÃ©finir un dictionnaire pour mapper les niveaux de journalisation aux prÃ©fixes
$script:LogLevelPrefixes = @{
    $script:LogLevelNone = ""
    $script:LogLevelDebug = "[DEBUG] "
    $script:LogLevelVerbose = "[VERBOSE] "
    $script:LogLevelInformation = "[INFO] "
    $script:LogLevelWarning = "[WARNING] "
    $script:LogLevelError = "[ERROR] "
    $script:LogLevelCritical = "[CRITICAL] "
    $script:LogLevelAll = ""
}

# DÃ©finir un dictionnaire pour mapper les niveaux de journalisation aux noms
$script:LogLevelNames = @{
    $script:LogLevelNone = "None"
    $script:LogLevelDebug = "Debug"
    $script:LogLevelVerbose = "Verbose"
    $script:LogLevelInformation = "Information"
    $script:LogLevelWarning = "Warning"
    $script:LogLevelError = "Error"
    $script:LogLevelCritical = "Critical"
    $script:LogLevelAll = "All"
}

<#
.SYNOPSIS
    Valide un niveau de journalisation.

.DESCRIPTION
    La fonction Test-LogLevel valide un niveau de journalisation.
    Elle vÃ©rifie si le niveau de journalisation est valide et retourne un boolÃ©en.

.PARAMETER LogLevel
    Le niveau de journalisation Ã  valider.

.EXAMPLE
    Test-LogLevel -LogLevel $LogLevelDebug
    Valide le niveau de journalisation Debug.

.OUTPUTS
    [bool] Indique si le niveau de journalisation est valide.
#>
function Test-LogLevel {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [object]$LogLevel
    )

    # VÃ©rifier si le niveau de journalisation est une instance de LogLevel
    if ($LogLevel -is [RoadmapParser.Logging.LogLevel]) {
        return $true
    }

    # VÃ©rifier si le niveau de journalisation est une chaÃ®ne de caractÃ¨res
    if ($LogLevel -is [string]) {
        # VÃ©rifier si la chaÃ®ne de caractÃ¨res peut Ãªtre convertie en LogLevel
        try {
            $null = [RoadmapParser.Logging.LogLevel]::Parse([RoadmapParser.Logging.LogLevel], $LogLevel)
            return $true
        } catch {
            return $false
        }
    }

    # VÃ©rifier si le niveau de journalisation est un entier
    if ($LogLevel -is [int]) {
        # VÃ©rifier si l'entier est une valeur valide pour LogLevel
        return [Enum]::IsDefined([RoadmapParser.Logging.LogLevel], $LogLevel)
    }

    return $false
}

<#
.SYNOPSIS
    Convertit une valeur en niveau de journalisation.

.DESCRIPTION
    La fonction ConvertTo-LogLevel convertit une valeur en niveau de journalisation.
    Elle prend en charge les chaÃ®nes de caractÃ¨res, les entiers et les instances de LogLevel.

.PARAMETER Value
    La valeur Ã  convertir en niveau de journalisation.

.PARAMETER DefaultValue
    La valeur par dÃ©faut Ã  utiliser si la conversion Ã©choue.
    Par dÃ©faut, c'est LogLevelInformation.

.EXAMPLE
    ConvertTo-LogLevel -Value "Debug"
    Convertit la chaÃ®ne de caractÃ¨res "Debug" en niveau de journalisation Debug.

.OUTPUTS
    [RoadmapParser.Logging.LogLevel] Le niveau de journalisation converti.
#>
function ConvertTo-LogLevel {
    [CmdletBinding()]
    [OutputType([RoadmapParser.Logging.LogLevel])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [object]$Value,

        [Parameter(Mandatory = $false)]
        [RoadmapParser.Logging.LogLevel]$DefaultValue = $script:LogLevelInformation
    )

    # Si la valeur est dÃ©jÃ  un niveau de journalisation, la retourner
    if ($Value -is [RoadmapParser.Logging.LogLevel]) {
        return $Value
    }

    # Si la valeur est une chaÃ®ne de caractÃ¨res, essayer de la convertir
    if ($Value -is [string]) {
        # VÃ©rifier si la chaÃ®ne de caractÃ¨res correspond Ã  un nom de niveau de journalisation
        foreach ($key in $script:LogLevelNames.Keys) {
            if ($script:LogLevelNames[$key] -eq $Value) {
                return $key
            }
        }

        # Essayer de convertir la chaÃ®ne de caractÃ¨res en niveau de journalisation
        try {
            return [RoadmapParser.Logging.LogLevel]::Parse([RoadmapParser.Logging.LogLevel], $Value)
        } catch {
            # Retourner la valeur par dÃ©faut si la conversion Ã©choue
            return $DefaultValue
        }
    }

    # Si la valeur est un entier, essayer de la convertir
    if ($Value -is [int]) {
        # VÃ©rifier si l'entier est une valeur valide pour LogLevel
        if ([Enum]::IsDefined([RoadmapParser.Logging.LogLevel], $Value)) {
            return [RoadmapParser.Logging.LogLevel]$Value
        } else {
            # Retourner la valeur par dÃ©faut si la conversion Ã©choue
            return $DefaultValue
        }
    }

    # Retourner la valeur par dÃ©faut si la conversion Ã©choue
    return $DefaultValue
}

<#
.SYNOPSIS
    Obtient le nom d'un niveau de journalisation.

.DESCRIPTION
    La fonction Get-LogLevelName obtient le nom d'un niveau de journalisation.
    Elle prend en charge les instances de LogLevel, les chaÃ®nes de caractÃ¨res et les entiers.

.PARAMETER LogLevel
    Le niveau de journalisation dont on veut obtenir le nom.

.EXAMPLE
    Get-LogLevelName -LogLevel $LogLevelDebug
    Obtient le nom du niveau de journalisation Debug.

.OUTPUTS
    [string] Le nom du niveau de journalisation.
#>
function Get-LogLevelName {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [object]$LogLevel
    )

    # Convertir la valeur en niveau de journalisation
    $logLevelValue = ConvertTo-LogLevel -Value $LogLevel

    # Retourner le nom du niveau de journalisation
    if ($script:LogLevelNames.ContainsKey($logLevelValue)) {
        return $script:LogLevelNames[$logLevelValue]
    } else {
        return $logLevelValue.ToString()
    }
}

<#
.SYNOPSIS
    Obtient la couleur d'un niveau de journalisation.

.DESCRIPTION
    La fonction Get-LogLevelColor obtient la couleur d'un niveau de journalisation.
    Elle prend en charge les instances de LogLevel, les chaÃ®nes de caractÃ¨res et les entiers.

.PARAMETER LogLevel
    Le niveau de journalisation dont on veut obtenir la couleur.

.EXAMPLE
    Get-LogLevelColor -LogLevel $LogLevelDebug
    Obtient la couleur du niveau de journalisation Debug.

.OUTPUTS
    [string] La couleur du niveau de journalisation.
#>
function Get-LogLevelColor {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [object]$LogLevel
    )

    # Convertir la valeur en niveau de journalisation
    $logLevelValue = ConvertTo-LogLevel -Value $LogLevel

    # Retourner la couleur du niveau de journalisation
    if ($script:LogLevelColors.ContainsKey($logLevelValue)) {
        return $script:LogLevelColors[$logLevelValue]
    } else {
        return "White"
    }
}

<#
.SYNOPSIS
    Obtient le prÃ©fixe d'un niveau de journalisation.

.DESCRIPTION
    La fonction Get-LogLevelPrefix obtient le prÃ©fixe d'un niveau de journalisation.
    Elle prend en charge les instances de LogLevel, les chaÃ®nes de caractÃ¨res et les entiers.

.PARAMETER LogLevel
    Le niveau de journalisation dont on veut obtenir le prÃ©fixe.

.EXAMPLE
    Get-LogLevelPrefix -LogLevel $LogLevelDebug
    Obtient le prÃ©fixe du niveau de journalisation Debug.

.OUTPUTS
    [string] Le prÃ©fixe du niveau de journalisation.
#>
function Get-LogLevelPrefix {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [object]$LogLevel
    )

    # Convertir la valeur en niveau de journalisation
    $logLevelValue = ConvertTo-LogLevel -Value $LogLevel

    # Retourner le prÃ©fixe du niveau de journalisation
    if ($script:LogLevelPrefixes.ContainsKey($logLevelValue)) {
        return $script:LogLevelPrefixes[$logLevelValue]
    } else {
        return ""
    }
}

# Exporter les fonctions et variables
Export-ModuleMember -Function Test-LogLevel, ConvertTo-LogLevel, Get-LogLevelName, Get-LogLevelColor, Get-LogLevelPrefix
Export-ModuleMember -Variable LogLevelNone, LogLevelDebug, LogLevelVerbose, LogLevelInformation, LogLevelWarning, LogLevelError, LogLevelCritical, LogLevelAll, AvailableLogLevels, LogLevelColors, LogLevelPrefixes, LogLevelNames
