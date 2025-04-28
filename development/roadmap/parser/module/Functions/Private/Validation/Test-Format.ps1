<#
.SYNOPSIS
    Valide si une valeur correspond Ã  un format spÃ©cifique.

.DESCRIPTION
    La fonction Test-Format valide si une valeur correspond Ã  un format spÃ©cifique.
    Elle prend en charge diffÃ©rents formats courants et peut Ãªtre utilisÃ©e pour
    valider les entrÃ©es des fonctions du module RoadmapParser.

.PARAMETER Value
    La valeur Ã  valider.

.PARAMETER Format
    Le format Ã  valider. Valeurs possibles :
    - Email : VÃ©rifie que la valeur est une adresse email valide
    - URL : VÃ©rifie que la valeur est une URL valide
    - IPAddress : VÃ©rifie que la valeur est une adresse IP valide
    - PhoneNumber : VÃ©rifie que la valeur est un numÃ©ro de tÃ©lÃ©phone valide
    - ZipCode : VÃ©rifie que la valeur est un code postal valide
    - Date : VÃ©rifie que la valeur est une date valide
    - Time : VÃ©rifie que la valeur est une heure valide
    - DateTime : VÃ©rifie que la valeur est une date/heure valide
    - Guid : VÃ©rifie que la valeur est un GUID valide
    - FilePath : VÃ©rifie que la valeur est un chemin de fichier valide
    - DirectoryPath : VÃ©rifie que la valeur est un chemin de rÃ©pertoire valide
    - Custom : Utilise une expression rÃ©guliÃ¨re personnalisÃ©e

.PARAMETER Pattern
    L'expression rÃ©guliÃ¨re personnalisÃ©e Ã  utiliser pour la validation.
    UtilisÃ© uniquement lorsque Format est "Custom".

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la validation.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la validation.

.EXAMPLE
    Test-Format -Value "user@example.com" -Format Email
    VÃ©rifie que la valeur "user@example.com" est une adresse email valide.

.EXAMPLE
    Test-Format -Value "123-456-7890" -Format PhoneNumber -ThrowOnFailure
    VÃ©rifie que la valeur "123-456-7890" est un numÃ©ro de tÃ©lÃ©phone valide, et lÃ¨ve une exception si ce n'est pas le cas.

.EXAMPLE
    Test-Format -Value "abc123" -Format Custom -Pattern "^[a-z]+[0-9]+$"
    VÃ©rifie que la valeur "abc123" correspond Ã  l'expression rÃ©guliÃ¨re personnalisÃ©e.

.OUTPUTS
    [bool] Indique si la validation a rÃ©ussi.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-20
#>
function Test-Format {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Email", "URL", "IPAddress", "PhoneNumber", "ZipCode", "Date", "Time", "DateTime", "Guid", "FilePath", "DirectoryPath", "Custom")]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [string]$Pattern,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le rÃ©sultat de la validation
    $isValid = $false

    # DÃ©finir les expressions rÃ©guliÃ¨res pour chaque format
    $patterns = @{
        Email = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
        URL = "^(http|https)://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/[a-zA-Z0-9._~:/?#[\]@!$&'()*+,;=]*)?$"
        IPAddress = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
        PhoneNumber = "^\+?[0-9]{1,3}[-. ]?\(?[0-9]{1,3}\)?[-. ]?[0-9]{1,4}[-. ]?[0-9]{1,4}$"
        ZipCode = "^[0-9]{5}(?:-[0-9]{4})?$"
        Date = "^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/[0-9]{4}$"
        Time = "^([01][0-9]|2[0-3]):([0-5][0-9])(?::([0-5][0-9]))?$"
        DateTime = "^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/[0-9]{4} ([01][0-9]|2[0-3]):([0-5][0-9])(?::([0-5][0-9]))?$"
        Guid = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
        FilePath = "^(?:[a-zA-Z]:|\\\\[a-zA-Z0-9_.$-]+\\[a-zA-Z0-9_.$-]+)\\(?:[^\\/:*?""<>|\r\n]+\\)*[^\\/:*?""<>|\r\n]*$"
        DirectoryPath = "^(?:[a-zA-Z]:|\\\\[a-zA-Z0-9_.$-]+\\[a-zA-Z0-9_.$-]+)\\(?:[^\\/:*?""<>|\r\n]+\\)*$"
    }

    # Effectuer la validation selon le format
    switch ($Format) {
        "Custom" {
            if ([string]::IsNullOrEmpty($Pattern)) {
                throw "Le paramÃ¨tre Pattern est requis lorsque le format est Custom."
            }
            $isValid = $Value -match $Pattern
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur ne correspond pas au format personnalisÃ©."
            }
        }
        default {
            $isValid = $Value -match $patterns[$Format]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur ne correspond pas au format $Format."
            }
        }
    }

    # GÃ©rer l'Ã©chec de la validation
    if (-not $isValid) {
        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
        }
    }

    return $isValid
}
