<#
.SYNOPSIS
    Fonctions de validation pour les modes RoadmapParser.

.DESCRIPTION
    Ce script contient des fonctions de validation utilisées par tous les modes de RoadmapParser.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

<#
.SYNOPSIS
    Vérifie si une chaîne est nulle ou vide.

.DESCRIPTION
    Cette fonction vérifie si une chaîne est nulle ou vide et lève une exception si c'est le cas.

.PARAMETER String
    Chaîne à vérifier.

.PARAMETER ParameterName
    Nom du paramètre pour le message d'erreur.

.PARAMETER ErrorMessage
    Message d'erreur personnalisé.

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
        [string]$ErrorMessage = "Le paramètre '$ParameterName' ne peut pas être nul ou vide."
    )
    
    if ([string]::IsNullOrEmpty($String)) {
        throw $ErrorMessage
    }
}

<#
.SYNOPSIS
    Vérifie si un chemin est valide.

.DESCRIPTION
    Cette fonction vérifie si un chemin est valide et lève une exception si ce n'est pas le cas.

.PARAMETER Path
    Chemin à vérifier.

.PARAMETER ParameterName
    Nom du paramètre pour le message d'erreur.

.PARAMETER ErrorMessage
    Message d'erreur personnalisé.

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
    
    # Vérifier si la chaîne est nulle ou vide
    Assert-NotNullOrEmpty -String $Path -ParameterName $ParameterName
    
    # Vérifier si le chemin contient des caractères invalides
    $invalidChars = [System.IO.Path]::GetInvalidPathChars()
    $invalidCharsFound = $invalidChars | Where-Object { $Path.Contains($_) }
    
    if ($invalidCharsFound) {
        throw $ErrorMessage
    }
}

<#
.SYNOPSIS
    Vérifie si un identifiant de tâche est valide.

.DESCRIPTION
    Cette fonction vérifie si un identifiant de tâche est valide et lève une exception si ce n'est pas le cas.

.PARAMETER TaskIdentifier
    Identifiant de tâche à vérifier.

.PARAMETER ParameterName
    Nom du paramètre pour le message d'erreur.

.PARAMETER ErrorMessage
    Message d'erreur personnalisé.

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
        [string]$ErrorMessage = "L'identifiant de tâche '$TaskIdentifier' n'est pas valide. Il doit être au format 'X.Y.Z'."
    )
    
    # Vérifier si la chaîne est nulle ou vide
    Assert-NotNullOrEmpty -String $TaskIdentifier -ParameterName $ParameterName
    
    # Vérifier si l'identifiant de tâche est au format X.Y.Z
    if (-not ($TaskIdentifier -match '^[0-9]+(\.[0-9]+)*$')) {
        throw $ErrorMessage
    }
}

<#
.SYNOPSIS
    Vérifie si un fichier existe et est du type attendu.

.DESCRIPTION
    Cette fonction vérifie si un fichier existe et est du type attendu.

.PARAMETER FilePath
    Chemin vers le fichier à vérifier.

.PARAMETER FileType
    Type de fichier attendu (extension).

.PARAMETER ParameterName
    Nom du paramètre pour le message d'erreur.

.PARAMETER ErrorMessage
    Message d'erreur personnalisé.

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
    
    # Vérifier si le chemin est valide
    Assert-ValidPath -Path $FilePath -ParameterName $ParameterName
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        if (-not $ErrorMessage) {
            $ErrorMessage = "Le fichier '$FilePath' n'existe pas."
        }
        throw $ErrorMessage
    }
    
    # Vérifier le type de fichier si spécifié
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
    Vérifie si un répertoire existe.

.DESCRIPTION
    Cette fonction vérifie si un répertoire existe et lève une exception si ce n'est pas le cas.

.PARAMETER DirectoryPath
    Chemin vers le répertoire à vérifier.

.PARAMETER ParameterName
    Nom du paramètre pour le message d'erreur.

.PARAMETER ErrorMessage
    Message d'erreur personnalisé.

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
    
    # Vérifier si le chemin est valide
    Assert-ValidPath -Path $DirectoryPath -ParameterName $ParameterName
    
    # Vérifier si le répertoire existe
    if (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
        if (-not $ErrorMessage) {
            $ErrorMessage = "Le répertoire '$DirectoryPath' n'existe pas."
        }
        throw $ErrorMessage
    }
}

<#
.SYNOPSIS
    Vérifie si une valeur est dans une plage.

.DESCRIPTION
    Cette fonction vérifie si une valeur est dans une plage et lève une exception si ce n'est pas le cas.

.PARAMETER Value
    Valeur à vérifier.

.PARAMETER Minimum
    Valeur minimale de la plage.

.PARAMETER Maximum
    Valeur maximale de la plage.

.PARAMETER ParameterName
    Nom du paramètre pour le message d'erreur.

.PARAMETER ErrorMessage
    Message d'erreur personnalisé.

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
            $ErrorMessage = "La valeur '$Value' du paramètre '$ParameterName' doit être comprise entre $Minimum et $Maximum."
        }
        throw $ErrorMessage
    }
}

<#
.SYNOPSIS
    Vérifie si une valeur est dans un ensemble de valeurs.

.DESCRIPTION
    Cette fonction vérifie si une valeur est dans un ensemble de valeurs et lève une exception si ce n'est pas le cas.

.PARAMETER Value
    Valeur à vérifier.

.PARAMETER ValidValues
    Ensemble de valeurs valides.

.PARAMETER ParameterName
    Nom du paramètre pour le message d'erreur.

.PARAMETER ErrorMessage
    Message d'erreur personnalisé.

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
            $ErrorMessage = "La valeur '$Value' du paramètre '$ParameterName' n'est pas valide. Les valeurs valides sont : $($ValidValues -join ', ')."
        }
        throw $ErrorMessage
    }
}

<#
.SYNOPSIS
    Vérifie si un objet est du type attendu.

.DESCRIPTION
    Cette fonction vérifie si un objet est du type attendu et lève une exception si ce n'est pas le cas.

.PARAMETER Object
    Objet à vérifier.

.PARAMETER Type
    Type attendu.

.PARAMETER ParameterName
    Nom du paramètre pour le message d'erreur.

.PARAMETER ErrorMessage
    Message d'erreur personnalisé.

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
            $ErrorMessage = "Le paramètre '$ParameterName' doit être de type '$Type'."
        }
        throw $ErrorMessage
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Assert-NotNullOrEmpty, Assert-ValidPath, Assert-ValidTaskIdentifier, Assert-ValidFile, Assert-ValidDirectory, Assert-InRange, Assert-ValidValue, Assert-ValidType
