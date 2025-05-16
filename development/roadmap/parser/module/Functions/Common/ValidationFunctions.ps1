<#
.SYNOPSIS
    Fonctions de validation pour les modes RoadmapParser.

.DESCRIPTION
    Ce script contient des fonctions de validation utilisÃ©es par tous les modes de RoadmapParser.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

<#
.SYNOPSIS
    VÃ©rifie si une chaÃ®ne est nulle ou vide.

.DESCRIPTION
    Cette fonction vÃ©rifie si une chaÃ®ne est nulle ou vide et lÃ¨ve une exception si c'est le cas.

.PARAMETER String
    ChaÃ®ne Ã  vÃ©rifier.

.PARAMETER ParameterName
    Nom du paramÃ¨tre pour le message d'erreur.

.PARAMETER ErrorMessage
    Message d'erreur personnalisÃ©.

.EXAMPLE
    Assert-NotNullOrEmpty -String $FilePath -ParameterName "FilePath"

.OUTPUTS
    None
#>
function Assert-NotNullOrEmpty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$String,

        [Parameter(Mandatory = $false)]
        [string]$ParameterName = "String",

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = "Le paramÃ¨tre '$ParameterName' ne peut pas Ãªtre nul ou vide."
    )

    if ([string]::IsNullOrEmpty($String)) {
        throw $ErrorMessage
    }
}

<#
.SYNOPSIS
    VÃ©rifie si un chemin est valide.

.DESCRIPTION
    Cette fonction vÃ©rifie si un chemin est valide et lÃ¨ve une exception si ce n'est pas le cas.

.PARAMETER Path
    Chemin Ã  vÃ©rifier.

.PARAMETER ParameterName
    Nom du paramÃ¨tre pour le message d'erreur.

.PARAMETER ErrorMessage
    Message d'erreur personnalisÃ©.

.EXAMPLE
    Assert-ValidPath -Path $FilePath -ParameterName "FilePath"

.OUTPUTS
    None
#>
function Assert-ValidPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$ParameterName = "Path",

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = "Le chemin '$Path' n'est pas valide."
    )

    # VÃ©rifier si la chaÃ®ne est nulle ou vide
    Assert-NotNullOrEmpty -String $Path -ParameterName $ParameterName

    # VÃ©rifier si le chemin contient des caractÃ¨res invalides
    $invalidChars = [System.IO.Path]::GetInvalidPathChars()
    $invalidCharsFound = $invalidChars | Where-Object { $Path.Contains($_) }

    if ($invalidCharsFound) {
        throw $ErrorMessage
    }
}

<#
.SYNOPSIS
    VÃ©rifie si un identifiant de tÃ¢che est valide.

.DESCRIPTION
    Cette fonction vÃ©rifie si un identifiant de tÃ¢che est valide et lÃ¨ve une exception si ce n'est pas le cas.

.PARAMETER TaskIdentifier
    Identifiant de tÃ¢che Ã  vÃ©rifier.

.PARAMETER ParameterName
    Nom du paramÃ¨tre pour le message d'erreur.

.PARAMETER ErrorMessage
    Message d'erreur personnalisÃ©.

.EXAMPLE
    Assert-ValidTaskIdentifier -TaskIdentifier "1.1" -ParameterName "TaskIdentifier"

.OUTPUTS
    None
#>
function Assert-ValidTaskIdentifier {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskIdentifier,

        [Parameter(Mandatory = $false)]
        [string]$ParameterName = "TaskIdentifier",

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = "L'identifiant de tÃ¢che '$TaskIdentifier' n'est pas valide. Il doit Ãªtre au format 'X.Y.Z'."
    )

    # VÃ©rifier si la chaÃ®ne est nulle ou vide
    Assert-NotNullOrEmpty -String $TaskIdentifier -ParameterName $ParameterName

    # VÃ©rifier si l'identifiant de tÃ¢che est au format X.Y.Z
    if (-not ($TaskIdentifier -match '^[0-9]+(\.[0-9]+)*$')) {
        throw $ErrorMessage
    }
}

<#
.SYNOPSIS
    VÃ©rifie si un fichier existe et est du type attendu.

.DESCRIPTION
    Cette fonction vÃ©rifie si un fichier existe et est du type attendu.

.PARAMETER FilePath
    Chemin vers le fichier Ã  vÃ©rifier.

.PARAMETER FileType
    Type de fichier attendu (extension).

.PARAMETER ParameterName
    Nom du paramÃ¨tre pour le message d'erreur.

.PARAMETER ErrorMessage
    Message d'erreur personnalisÃ©.

.EXAMPLE
    Assert-ValidFile -FilePath "roadmap.md" -FileType ".md" -ParameterName "FilePath"

.OUTPUTS
    None
#>
function Assert-ValidFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$FileType,

        [Parameter(Mandatory = $false)]
        [string]$ParameterName = "FilePath",

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage
    )

    # VÃ©rifier si le chemin est valide
    Assert-ValidPath -Path $FilePath -ParameterName $ParameterName

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        if (-not $ErrorMessage) {
            $ErrorMessage = "Le fichier '$FilePath' n'existe pas."
        }
        throw $ErrorMessage
    }

    # VÃ©rifier le type de fichier si spÃ©cifiÃ©
    if ($FileType) {
        $extension = [System.IO.Path]::GetExtension($FilePath)
        if ($extension -ne $FileType) {
            if (-not $ErrorMessage) {
                $ErrorMessage = "Le fichier '$FilePath' n'est pas du type attendu ($FileType)."
            }
            throw $ErrorMessage
        }
    }
}

<#
.SYNOPSIS
    VÃ©rifie si un rÃ©pertoire existe.

.DESCRIPTION
    Cette fonction vÃ©rifie si un rÃ©pertoire existe et lÃ¨ve une exception si ce n'est pas le cas.

.PARAMETER DirectoryPath
    Chemin vers le rÃ©pertoire Ã  vÃ©rifier.

.PARAMETER ParameterName
    Nom du paramÃ¨tre pour le message d'erreur.

.PARAMETER ErrorMessage
    Message d'erreur personnalisÃ©.

.EXAMPLE
    Assert-ValidDirectory -DirectoryPath "output" -ParameterName "OutputPath"

.OUTPUTS
    None
#>
function Assert-ValidDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath,

        [Parameter(Mandatory = $false)]
        [string]$ParameterName = "DirectoryPath",

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage
    )

    # VÃ©rifier si le chemin est valide
    Assert-ValidPath -Path $DirectoryPath -ParameterName $ParameterName

    # VÃ©rifier si le rÃ©pertoire existe
    if (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
        if (-not $ErrorMessage) {
            $ErrorMessage = "Le rÃ©pertoire '$DirectoryPath' n'existe pas."
        }
        throw $ErrorMessage
    }
}

<#
.SYNOPSIS
    VÃ©rifie si une valeur est dans une plage.

.DESCRIPTION
    Cette fonction vÃ©rifie si une valeur est dans une plage et lÃ¨ve une exception si ce n'est pas le cas.

.PARAMETER Value
    Valeur Ã  vÃ©rifier.

.PARAMETER Minimum
    Valeur minimale de la plage.

.PARAMETER Maximum
    Valeur maximale de la plage.

.PARAMETER ParameterName
    Nom du paramÃ¨tre pour le message d'erreur.

.PARAMETER ErrorMessage
    Message d'erreur personnalisÃ©.

.EXAMPLE
    Assert-InRange -Value 5 -Minimum 1 -Maximum 10 -ParameterName "Count"

.OUTPUTS
    None
#>
function Assert-InRange {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Value,

        [Parameter(Mandatory = $true)]
        [int]$Minimum,

        [Parameter(Mandatory = $true)]
        [int]$Maximum,

        [Parameter(Mandatory = $false)]
        [string]$ParameterName = "Value",

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage
    )

    if ($Value -lt $Minimum -or $Value -gt $Maximum) {
        if (-not $ErrorMessage) {
            $ErrorMessage = "La valeur '$Value' du paramÃ¨tre '$ParameterName' doit Ãªtre comprise entre $Minimum et $Maximum."
        }
        throw $ErrorMessage
    }
}

<#
.SYNOPSIS
    VÃ©rifie si une valeur est dans un ensemble de valeurs.

.DESCRIPTION
    Cette fonction vÃ©rifie si une valeur est dans un ensemble de valeurs et lÃ¨ve une exception si ce n'est pas le cas.

.PARAMETER Value
    Valeur Ã  vÃ©rifier.

.PARAMETER ValidValues
    Ensemble de valeurs valides.

.PARAMETER ParameterName
    Nom du paramÃ¨tre pour le message d'erreur.

.PARAMETER ErrorMessage
    Message d'erreur personnalisÃ©.

.EXAMPLE
    Assert-ValidValue -Value "INFO" -ValidValues @("ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG") -ParameterName "LogLevel"

.OUTPUTS
    None
#>
function Assert-ValidValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value,

        [Parameter(Mandatory = $true)]
        [string[]]$ValidValues,

        [Parameter(Mandatory = $false)]
        [string]$ParameterName = "Value",

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage
    )

    if ($ValidValues -notcontains $Value) {
        if (-not $ErrorMessage) {
            $ErrorMessage = "La valeur '$Value' du paramÃ¨tre '$ParameterName' n'est pas valide. Les valeurs valides sont : $($ValidValues -join ', ')."
        }
        throw $ErrorMessage
    }
}

<#
.SYNOPSIS
    VÃ©rifie si un objet est du type attendu.

.DESCRIPTION
    Cette fonction vÃ©rifie si un objet est du type attendu et lÃ¨ve une exception si ce n'est pas le cas.

.PARAMETER Object
    Objet Ã  vÃ©rifier.

.PARAMETER Type
    Type attendu.

.PARAMETER ParameterName
    Nom du paramÃ¨tre pour le message d'erreur.

.PARAMETER ErrorMessage
    Message d'erreur personnalisÃ©.

.EXAMPLE
    Assert-ValidType -Object $Config -Type "System.Collections.Hashtable" -ParameterName "Config"

.OUTPUTS
    None
#>
function Assert-ValidType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Object,

        [Parameter(Mandatory = $true)]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [string]$ParameterName = "Object",

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage
    )

    if ($Object -isnot $Type) {
        if (-not $ErrorMessage) {
            $ErrorMessage = "Le paramÃ¨tre '$ParameterName' doit Ãªtre de type '$Type'."
        }
        throw $ErrorMessage
    }
}

# Exporter les fonctions
if ($MyInvocation.ScriptName -ne '') {
    # Nous sommes dans un module
    Export-ModuleMember -Function Assert-NotNullOrEmpty, Assert-ValidPath, Assert-ValidTaskIdentifier, Assert-ValidFile, Assert-ValidDirectory, Assert-InRange, Assert-ValidValue, Assert-ValidType
}
