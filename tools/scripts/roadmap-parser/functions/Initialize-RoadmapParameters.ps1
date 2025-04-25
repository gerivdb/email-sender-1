<#
.SYNOPSIS
    Initialise et valide les paramètres d'une fonction du module RoadmapParser.

.DESCRIPTION
    La fonction Initialize-RoadmapParameters initialise et valide les paramètres d'une fonction
    du module RoadmapParser. Elle applique les valeurs par défaut aux paramètres non spécifiés
    et valide les paramètres selon les règles définies.

.PARAMETER Parameters
    Un hashtable contenant les paramètres à initialiser et valider.

.PARAMETER FunctionName
    Le nom de la fonction pour laquelle initialiser et valider les paramètres.

.PARAMETER ValidationRules
    Un hashtable contenant les règles de validation pour chaque paramètre.
    Chaque règle est un hashtable avec les clés suivantes :
    - Type : Le type de validation à effectuer
    - ErrorMessage : Le message d'erreur à afficher en cas d'échec de la validation
    - CustomValidation : Une expression scriptblock pour une validation personnalisée
    - AllowNull : Indique si la valeur null est autorisée
    - ThrowOnFailure : Indique si une exception doit être levée en cas d'échec de la validation

.PARAMETER ConfigurationPath
    Le chemin vers un fichier de configuration contenant des valeurs par défaut personnalisées.
    Si non spécifié, les valeurs par défaut intégrées seront utilisées.

.EXAMPLE
    $params = @{
        FilePath = "C:\path\to\file.md"
        IncludeMetadata = $true
    }
    $validationRules = @{
        FilePath = @{
            Type = "FilePath"
            ThrowOnFailure = $true
        }
        IncludeMetadata = @{
            Type = "Custom"
            CustomValidation = { param($value) $value -is [bool] }
        }
    }
    $validatedParams = Initialize-RoadmapParameters -Parameters $params -FunctionName "ConvertFrom-MarkdownToRoadmapExtended" -ValidationRules $validationRules
    Initialise et valide les paramètres pour la fonction "ConvertFrom-MarkdownToRoadmapExtended".

.OUTPUTS
    [hashtable] Un hashtable contenant les paramètres initialisés et validés.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-10
#>
function Initialize-RoadmapParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Parameters,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$FunctionName,

        [Parameter(Mandatory = $true, Position = 2)]
        [hashtable]$ValidationRules,

        [Parameter(Mandatory = $false)]
        [string]$ConfigurationPath
    )

    # Les fonctions Test-RoadmapParameter et Get-RoadmapParameterDefault doivent être importées avant d'appeler cette fonction

    # Créer un hashtable pour les paramètres initialisés et validés
    $initializedParams = @{}

    # Parcourir les règles de validation
    foreach ($paramName in $ValidationRules.Keys) {
        $rule = $ValidationRules[$paramName]

        # Vérifier si le paramètre est spécifié
        if ($Parameters.ContainsKey($paramName)) {
            $paramValue = $Parameters[$paramName]

            # Valider le paramètre
            $isValid = $true
            if ($rule.ContainsKey("Type")) {
                $validationParams = @{
                    Value = $paramValue
                    Type  = $rule.Type
                }

                if ($rule.ContainsKey("ErrorMessage")) {
                    $validationParams["ErrorMessage"] = $rule.ErrorMessage
                }

                if ($rule.ContainsKey("CustomValidation")) {
                    $validationParams["CustomValidation"] = $rule.CustomValidation
                }

                if ($rule.ContainsKey("AllowNull")) {
                    $validationParams["AllowNull"] = $rule.AllowNull
                }

                if ($rule.ContainsKey("ThrowOnFailure")) {
                    $validationParams["ThrowOnFailure"] = $rule.ThrowOnFailure
                }

                if ($rule.ContainsKey("Roadmap") -and $Parameters.ContainsKey($rule.Roadmap)) {
                    $validationParams["Roadmap"] = $Parameters[$rule.Roadmap]
                }

                $isValid = Test-RoadmapParameter @validationParams
            }

            # Ajouter le paramètre s'il est valide
            if ($isValid) {
                $initializedParams[$paramName] = $paramValue
            }
        }
        # Si le paramètre n'est pas spécifié, utiliser la valeur par défaut
        else {
            $defaultValue = Get-RoadmapParameterDefault -ParameterName $paramName -FunctionName $FunctionName -ConfigurationPath $ConfigurationPath

            if ($null -ne $defaultValue) {
                $initializedParams[$paramName] = $defaultValue
            }
        }
    }

    return $initializedParams
}
