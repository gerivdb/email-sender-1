<#
.SYNOPSIS
    Initialise et valide les paramÃ¨tres d'une fonction du module RoadmapParser.

.DESCRIPTION
    La fonction Initialize-RoadmapParameters initialise et valide les paramÃ¨tres d'une fonction
    du module RoadmapParser. Elle applique les valeurs par dÃ©faut aux paramÃ¨tres non spÃ©cifiÃ©s
    et valide les paramÃ¨tres selon les rÃ¨gles dÃ©finies.

.PARAMETER Parameters
    Un hashtable contenant les paramÃ¨tres Ã  initialiser et valider.

.PARAMETER FunctionName
    Le nom de la fonction pour laquelle initialiser et valider les paramÃ¨tres.

.PARAMETER ValidationRules
    Un hashtable contenant les rÃ¨gles de validation pour chaque paramÃ¨tre.
    Chaque rÃ¨gle est un hashtable avec les clÃ©s suivantes :
    - Type : Le type de validation Ã  effectuer
    - ErrorMessage : Le message d'erreur Ã  afficher en cas d'Ã©chec de la validation
    - CustomValidation : Une expression scriptblock pour une validation personnalisÃ©e
    - AllowNull : Indique si la valeur null est autorisÃ©e
    - ThrowOnFailure : Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la validation

.PARAMETER ConfigurationPath
    Le chemin vers un fichier de configuration contenant des valeurs par dÃ©faut personnalisÃ©es.
    Si non spÃ©cifiÃ©, les valeurs par dÃ©faut intÃ©grÃ©es seront utilisÃ©es.

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
    Initialise et valide les paramÃ¨tres pour la fonction "ConvertFrom-MarkdownToRoadmapExtended".

.OUTPUTS
    [hashtable] Un hashtable contenant les paramÃ¨tres initialisÃ©s et validÃ©s.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-10
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

    # Les fonctions Test-RoadmapParameter et Get-RoadmapParameterDefault doivent Ãªtre importÃ©es avant d'appeler cette fonction

    # CrÃ©er un hashtable pour les paramÃ¨tres initialisÃ©s et validÃ©s
    $initializedParams = @{}

    # Parcourir les rÃ¨gles de validation
    foreach ($paramName in $ValidationRules.Keys) {
        $rule = $ValidationRules[$paramName]

        # VÃ©rifier si le paramÃ¨tre est spÃ©cifiÃ©
        if ($Parameters.ContainsKey($paramName)) {
            $paramValue = $Parameters[$paramName]

            # Valider le paramÃ¨tre
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

            # Ajouter le paramÃ¨tre s'il est valide
            if ($isValid) {
                $initializedParams[$paramName] = $paramValue
            }
        }
        # Si le paramÃ¨tre n'est pas spÃ©cifiÃ©, utiliser la valeur par dÃ©faut
        else {
            $defaultValue = Get-RoadmapParameterDefault -ParameterName $paramName -FunctionName $FunctionName -ConfigurationPath $ConfigurationPath

            if ($null -ne $defaultValue) {
                $initializedParams[$paramName] = $defaultValue
            }
        }
    }

    return $initializedParams
}
