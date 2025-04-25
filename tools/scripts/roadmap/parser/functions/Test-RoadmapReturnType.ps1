<#
.SYNOPSIS
    Valide les types de retour des fonctions du module RoadmapParser.

.DESCRIPTION
    La fonction Test-RoadmapReturnType valide les types de retour des fonctions
    du module RoadmapParser. Elle vérifie que les objets retournés par les fonctions
    ont la structure attendue et contiennent les propriétés requises.

.PARAMETER Value
    L'objet à valider.

.PARAMETER Type
    Le type de validation à effectuer. Valeurs possibles :
    - Roadmap : Vérifie que l'objet est une roadmap valide
    - Section : Vérifie que l'objet est une section valide
    - Task : Vérifie que l'objet est une tâche valide
    - ValidationResult : Vérifie que l'objet est un résultat de validation valide
    - DependencyResult : Vérifie que l'objet est un résultat de dépendance valide
    - JsonString : Vérifie que la chaîne est un JSON valide
    - Custom : Utilise une validation personnalisée

.PARAMETER CustomValidation
    Une expression scriptblock pour une validation personnalisée.
    Utilisé uniquement lorsque Type est "Custom".

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la validation.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER RequiredProperties
    Un tableau de noms de propriétés requises pour l'objet.
    Si non spécifié, les propriétés par défaut pour le type seront utilisées.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la validation.

.EXAMPLE
    $roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md"
    Test-RoadmapReturnType -Value $roadmap -Type Roadmap -ThrowOnFailure
    Vérifie que l'objet est une roadmap valide, et lève une exception si ce n'est pas le cas.

.EXAMPLE
    $json = Export-RoadmapToJson -Roadmap $roadmap
    Test-RoadmapReturnType -Value $json -Type JsonString
    Vérifie que la chaîne est un JSON valide.

.OUTPUTS
    [bool] Indique si la validation a réussi.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-10
#>
function Test-RoadmapReturnType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowNull()]
        $Value,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Roadmap", "Section", "Task", "ValidationResult", "DependencyResult", "JsonString", "Custom")]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomValidation,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [string[]]$RequiredProperties,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Vérifier si la valeur est null
    if ($null -eq $Value) {
        $message = $ErrorMessage
        if ([string]::IsNullOrEmpty($message)) {
            $message = "La valeur ne peut pas être null."
        }

        if ($ThrowOnFailure) {
            throw $message
        } else {
            Write-Warning $message
            return $false
        }
    }

    # Définir les propriétés requises par défaut pour chaque type
    $defaultRequiredProperties = @{
        "Roadmap"          = @("Title", "Description", "Sections", "AllTasks")
        "Section"          = @("Title", "Tasks")
        "Task"             = @("Id", "Title", "Status", "SubTasks")
        "ValidationResult" = @("IsValid", "Errors", "Warnings")
        "DependencyResult" = @("DependencyCount", "ExplicitDependencies", "ImplicitDependencies")
    }

    # Utiliser les propriétés requises spécifiées ou les propriétés par défaut
    $propertiesToCheck = $RequiredProperties
    if ($null -eq $propertiesToCheck -and $defaultRequiredProperties.ContainsKey($Type)) {
        $propertiesToCheck = $defaultRequiredProperties[$Type]
    }

    # Effectuer la validation selon le type
    $isValid = $true
    $validationMessage = $ErrorMessage

    switch ($Type) {
        "Roadmap" {
            # Vérifier que l'objet a les propriétés requises
            foreach ($prop in $propertiesToCheck) {
                if (-not $Value.PSObject.Properties.Name -contains $prop) {
                    $isValid = $false
                    if ([string]::IsNullOrEmpty($validationMessage)) {
                        $validationMessage = "L'objet roadmap ne contient pas la propriété requise '$prop'."
                    }
                    break
                }
            }

            # Vérifier que les sections sont un tableau
            if ($isValid -and -not ($Value.Sections -is [System.Collections.IEnumerable] -and -not ($Value.Sections -is [string]))) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriété 'Sections' de l'objet roadmap n'est pas un tableau."
                }
            }

            # Vérifier que AllTasks est un dictionnaire
            if ($isValid -and -not ($Value.AllTasks -is [System.Collections.IDictionary])) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriété 'AllTasks' de l'objet roadmap n'est pas un dictionnaire."
                }
            }
        }
        "Section" {
            # Vérifier que l'objet a les propriétés requises
            foreach ($prop in $propertiesToCheck) {
                if (-not $Value.PSObject.Properties.Name -contains $prop) {
                    $isValid = $false
                    if ([string]::IsNullOrEmpty($validationMessage)) {
                        $validationMessage = "L'objet section ne contient pas la propriété requise '$prop'."
                    }
                    break
                }
            }

            # Vérifier que Tasks est un tableau
            if ($isValid -and -not ($Value.Tasks -is [System.Collections.IEnumerable] -and -not ($Value.Tasks -is [string]))) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriété 'Tasks' de l'objet section n'est pas un tableau."
                }
            }
        }
        "Task" {
            # Vérifier que l'objet a les propriétés requises
            foreach ($prop in $propertiesToCheck) {
                if (-not $Value.PSObject.Properties.Name -contains $prop) {
                    $isValid = $false
                    if ([string]::IsNullOrEmpty($validationMessage)) {
                        $validationMessage = "L'objet tâche ne contient pas la propriété requise '$prop'."
                    }
                    break
                }
            }

            # Vérifier que SubTasks est un tableau
            if ($isValid -and -not ($Value.SubTasks -is [System.Collections.IEnumerable] -and -not ($Value.SubTasks -is [string]))) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriété 'SubTasks' de l'objet tâche n'est pas un tableau."
                }
            }

            # Vérifier que Status est une valeur valide
            if ($isValid -and -not (@("Complete", "Incomplete", "InProgress", "Blocked") -contains $Value.Status)) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriété 'Status' de l'objet tâche n'est pas une valeur valide."
                }
            }
        }
        "ValidationResult" {
            # Vérifier que l'objet a les propriétés requises
            foreach ($prop in $propertiesToCheck) {
                if (-not $Value.PSObject.Properties.Name -contains $prop) {
                    $isValid = $false
                    if ([string]::IsNullOrEmpty($validationMessage)) {
                        $validationMessage = "L'objet résultat de validation ne contient pas la propriété requise '$prop'."
                    }
                    break
                }
            }

            # Vérifier que IsValid est un booléen
            if ($isValid -and -not ($Value.IsValid -is [bool])) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriété 'IsValid' de l'objet résultat de validation n'est pas un booléen."
                }
            }

            # Vérifier que Errors et Warnings sont des tableaux
            if ($isValid -and -not ($Value.Errors -is [System.Collections.IEnumerable] -and -not ($Value.Errors -is [string]))) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriété 'Errors' de l'objet résultat de validation n'est pas un tableau."
                }
            }

            if ($isValid -and -not ($Value.Warnings -is [System.Collections.IEnumerable] -and -not ($Value.Warnings -is [string]))) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriété 'Warnings' de l'objet résultat de validation n'est pas un tableau."
                }
            }
        }
        "DependencyResult" {
            # Vérifier que l'objet a les propriétés requises
            foreach ($prop in $propertiesToCheck) {
                if (-not $Value.PSObject.Properties.Name -contains $prop) {
                    $isValid = $false
                    if ([string]::IsNullOrEmpty($validationMessage)) {
                        $validationMessage = "L'objet résultat de dépendance ne contient pas la propriété requise '$prop'."
                    }
                    break
                }
            }

            # Vérifier que DependencyCount est un entier
            if ($isValid -and -not ($Value.DependencyCount -is [int])) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriété 'DependencyCount' de l'objet résultat de dépendance n'est pas un entier."
                }
            }

            # Vérifier que ExplicitDependencies et ImplicitDependencies sont des tableaux
            if ($isValid -and -not ($Value.ExplicitDependencies -is [System.Collections.IEnumerable] -and -not ($Value.ExplicitDependencies -is [string]))) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriété 'ExplicitDependencies' de l'objet résultat de dépendance n'est pas un tableau."
                }
            }

            if ($isValid -and -not ($Value.ImplicitDependencies -is [System.Collections.IEnumerable] -and -not ($Value.ImplicitDependencies -is [string]))) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriété 'ImplicitDependencies' de l'objet résultat de dépendance n'est pas un tableau."
                }
            }
        }
        "JsonString" {
            # Vérifier que la valeur est une chaîne
            if (-not ($Value -is [string])) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La valeur n'est pas une chaîne JSON."
                }
            } else {
                # Vérifier que la chaîne est un JSON valide
                try {
                    $null = $Value | ConvertFrom-Json
                } catch {
                    $isValid = $false
                    if ([string]::IsNullOrEmpty($validationMessage)) {
                        $validationMessage = "La chaîne n'est pas un JSON valide : $_"
                    }
                }
            }
        }
        "Custom" {
            # Vérifier d'abord les propriétés requises si spécifiées
            if ($null -ne $propertiesToCheck -and $propertiesToCheck.Count -gt 0) {
                foreach ($prop in $propertiesToCheck) {
                    if (-not ($Value | Get-Member -Name $prop -MemberType Properties)) {
                        $isValid = $false
                        if ([string]::IsNullOrEmpty($validationMessage)) {
                            $validationMessage = "L'objet ne contient pas la propriété requise '$prop'."
                        }
                        break
                    }
                }
            }

            # Si les propriétés sont valides, exécuter la validation personnalisée
            if ($isValid) {
                if ($null -eq $CustomValidation) {
                    $isValid = $false
                    if ([string]::IsNullOrEmpty($validationMessage)) {
                        $validationMessage = "Une validation personnalisée est requise lorsque le type est 'Custom'."
                    }
                } else {
                    try {
                        $isValid = & $CustomValidation $Value
                        if ([string]::IsNullOrEmpty($validationMessage) -and -not $isValid) {
                            $validationMessage = "La validation personnalisée a échoué."
                        }
                    } catch {
                        $isValid = $false
                        if ([string]::IsNullOrEmpty($validationMessage)) {
                            $validationMessage = "Erreur lors de la validation personnalisée : $_"
                        }
                    }
                }
            }
        }
    }

    # Gérer l'échec de la validation
    if (-not $isValid) {
        if ($ThrowOnFailure) {
            throw $validationMessage
        } else {
            Write-Warning $validationMessage
        }
    }

    return $isValid
}
