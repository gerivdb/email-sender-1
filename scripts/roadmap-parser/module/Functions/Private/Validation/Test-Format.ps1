<#
.SYNOPSIS
    Valide si une valeur correspond à un format spécifique.

.DESCRIPTION
    La fonction Test-Format valide si une valeur correspond à un format spécifique.
    Elle prend en charge différents formats courants et peut être utilisée pour
    valider les entrées des fonctions du module RoadmapParser.

.PARAMETER Value
    La valeur à valider.

.PARAMETER Format
    Le format à valider. Valeurs possibles :
    - Email : Vérifie que la valeur est une adresse email valide
    - URL : Vérifie que la valeur est une URL valide
    - IPAddress : Vérifie que la valeur est une adresse IP valide
    - PhoneNumber : Vérifie que la valeur est un numéro de téléphone valide
    - ZipCode : Vérifie que la valeur est un code postal valide
    - Date : Vérifie que la valeur est une date valide
    - Time : Vérifie que la valeur est une heure valide
    - DateTime : Vérifie que la valeur est une date/heure valide
    - Guid : Vérifie que la valeur est un GUID valide
    - FilePath : Vérifie que la valeur est un chemin de fichier valide
    - DirectoryPath : Vérifie que la valeur est un chemin de répertoire valide
    - Custom : Utilise une expression régulière personnalisée

.PARAMETER Pattern
    L'expression régulière personnalisée à utiliser pour la validation.
    Utilisé uniquement lorsque Format est "Custom".

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la validation.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la validation.

.EXAMPLE
    Test-Format -Value "user@example.com" -Format Email
    Vérifie que la valeur "user@example.com" est une adresse email valide.

.EXAMPLE
    Test-Format -Value "123-456-7890" -Format PhoneNumber -ThrowOnFailure
    Vérifie que la valeur "123-456-7890" est un numéro de téléphone valide, et lève une exception si ce n'est pas le cas.

.EXAMPLE
    Test-Format -Value "abc123" -Format Custom -Pattern "^[a-z]+[0-9]+$"
    Vérifie que la valeur "abc123" correspond à l'expression régulière personnalisée.

.OUTPUTS
    [bool] Indique si la validation a réussi.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-20
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

    # Initialiser le résultat de la validation
    $isValid = $false

    # Définir les expressions régulières pour chaque format
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
                throw "Le paramètre Pattern est requis lorsque le format est Custom."
            }
            $isValid = $Value -match $Pattern
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur ne correspond pas au format personnalisé."
            }
        }
        default {
            $isValid = $Value -match $patterns[$Format]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur ne correspond pas au format $Format."
            }
        }
    }

    # Gérer l'échec de la validation
    if (-not $isValid) {
        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
        }
    }

    return $isValid
}
