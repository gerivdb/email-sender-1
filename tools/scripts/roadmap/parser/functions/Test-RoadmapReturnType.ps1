<#
.SYNOPSIS
    Valide les types de retour des fonctions du module RoadmapParser.

.DESCRIPTION
    La fonction Test-RoadmapReturnType valide les types de retour des fonctions
    du module RoadmapParser. Elle vÃ©rifie que les objets retournÃ©s par les fonctions
    ont la structure attendue et contiennent les propriÃ©tÃ©s requises.

.PARAMETER Value
    L'objet Ã  valider.

.PARAMETER Type
    Le type de validation Ã  effectuer. Valeurs possibles :
    - Roadmap : VÃ©rifie que l'objet est une roadmap valide
    - Section : VÃ©rifie que l'objet est une section valide
    - Task : VÃ©rifie que l'objet est une tÃ¢che valide
    - ValidationResult : VÃ©rifie que l'objet est un rÃ©sultat de validation valide
    - DependencyResult : VÃ©rifie que l'objet est un rÃ©sultat de dÃ©pendance valide
    - JsonString : VÃ©rifie que la chaÃ®ne est un JSON valide
    - Custom : Utilise une validation personnalisÃ©e

.PARAMETER CustomValidation
    Une expression scriptblock pour une validation personnalisÃ©e.
    UtilisÃ© uniquement lorsque Type est "Custom".

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la validation.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER RequiredProperties
    Un tableau de noms de propriÃ©tÃ©s requises pour l'objet.
    Si non spÃ©cifiÃ©, les propriÃ©tÃ©s par dÃ©faut pour le type seront utilisÃ©es.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la validation.

.EXAMPLE
    $roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md"
    Test-RoadmapReturnType -Value $roadmap -Type Roadmap -ThrowOnFailure
    VÃ©rifie que l'objet est une roadmap valide, et lÃ¨ve une exception si ce n'est pas le cas.

.EXAMPLE
    $json = Export-RoadmapToJson -Roadmap $roadmap
    Test-RoadmapReturnType -Value $json -Type JsonString
    VÃ©rifie que la chaÃ®ne est un JSON valide.

.OUTPUTS
    [bool] Indique si la validation a rÃ©ussi.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-10
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

    # VÃ©rifier si la valeur est null
    if ($null -eq $Value) {
        $message = $ErrorMessage
        if ([string]::IsNullOrEmpty($message)) {
            $message = "La valeur ne peut pas Ãªtre null."
        }

        if ($ThrowOnFailure) {
            throw $message
        } else {
            Write-Warning $message
            return $false
        }
    }

    # DÃ©finir les propriÃ©tÃ©s requises par dÃ©faut pour chaque type
    $defaultRequiredProperties = @{
        "Roadmap"          = @("Title", "Description", "Sections", "AllTasks")
        "Section"          = @("Title", "Tasks")
        "Task"             = @("Id", "Title", "Status", "SubTasks")
        "ValidationResult" = @("IsValid", "Errors", "Warnings")
        "DependencyResult" = @("DependencyCount", "ExplicitDependencies", "ImplicitDependencies")
    }

    # Utiliser les propriÃ©tÃ©s requises spÃ©cifiÃ©es ou les propriÃ©tÃ©s par dÃ©faut
    $propertiesToCheck = $RequiredProperties
    if ($null -eq $propertiesToCheck -and $defaultRequiredProperties.ContainsKey($Type)) {
        $propertiesToCheck = $defaultRequiredProperties[$Type]
    }

    # Effectuer la validation selon le type
    $isValid = $true
    $validationMessage = $ErrorMessage

    switch ($Type) {
        "Roadmap" {
            # VÃ©rifier que l'objet a les propriÃ©tÃ©s requises
            foreach ($prop in $propertiesToCheck) {
                if (-not $Value.PSObject.Properties.Name -contains $prop) {
                    $isValid = $false
                    if ([string]::IsNullOrEmpty($validationMessage)) {
                        $validationMessage = "L'objet roadmap ne contient pas la propriÃ©tÃ© requise '$prop'."
                    }
                    break
                }
            }

            # VÃ©rifier que les sections sont un tableau
            if ($isValid -and -not ($Value.Sections -is [System.Collections.IEnumerable] -and -not ($Value.Sections -is [string]))) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriÃ©tÃ© 'Sections' de l'objet roadmap n'est pas un tableau."
                }
            }

            # VÃ©rifier que AllTasks est un dictionnaire
            if ($isValid -and -not ($Value.AllTasks -is [System.Collections.IDictionary])) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriÃ©tÃ© 'AllTasks' de l'objet roadmap n'est pas un dictionnaire."
                }
            }
        }
        "Section" {
            # VÃ©rifier que l'objet a les propriÃ©tÃ©s requises
            foreach ($prop in $propertiesToCheck) {
                if (-not $Value.PSObject.Properties.Name -contains $prop) {
                    $isValid = $false
                    if ([string]::IsNullOrEmpty($validationMessage)) {
                        $validationMessage = "L'objet section ne contient pas la propriÃ©tÃ© requise '$prop'."
                    }
                    break
                }
            }

            # VÃ©rifier que Tasks est un tableau
            if ($isValid -and -not ($Value.Tasks -is [System.Collections.IEnumerable] -and -not ($Value.Tasks -is [string]))) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriÃ©tÃ© 'Tasks' de l'objet section n'est pas un tableau."
                }
            }
        }
        "Task" {
            # VÃ©rifier que l'objet a les propriÃ©tÃ©s requises
            foreach ($prop in $propertiesToCheck) {
                if (-not $Value.PSObject.Properties.Name -contains $prop) {
                    $isValid = $false
                    if ([string]::IsNullOrEmpty($validationMessage)) {
                        $validationMessage = "L'objet tÃ¢che ne contient pas la propriÃ©tÃ© requise '$prop'."
                    }
                    break
                }
            }

            # VÃ©rifier que SubTasks est un tableau
            if ($isValid -and -not ($Value.SubTasks -is [System.Collections.IEnumerable] -and -not ($Value.SubTasks -is [string]))) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriÃ©tÃ© 'SubTasks' de l'objet tÃ¢che n'est pas un tableau."
                }
            }

            # VÃ©rifier que Status est une valeur valide
            if ($isValid -and -not (@("Complete", "Incomplete", "InProgress", "Blocked") -contains $Value.Status)) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriÃ©tÃ© 'Status' de l'objet tÃ¢che n'est pas une valeur valide."
                }
            }
        }
        "ValidationResult" {
            # VÃ©rifier que l'objet a les propriÃ©tÃ©s requises
            foreach ($prop in $propertiesToCheck) {
                if (-not $Value.PSObject.Properties.Name -contains $prop) {
                    $isValid = $false
                    if ([string]::IsNullOrEmpty($validationMessage)) {
                        $validationMessage = "L'objet rÃ©sultat de validation ne contient pas la propriÃ©tÃ© requise '$prop'."
                    }
                    break
                }
            }

            # VÃ©rifier que IsValid est un boolÃ©en
            if ($isValid -and -not ($Value.IsValid -is [bool])) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriÃ©tÃ© 'IsValid' de l'objet rÃ©sultat de validation n'est pas un boolÃ©en."
                }
            }

            # VÃ©rifier que Errors et Warnings sont des tableaux
            if ($isValid -and -not ($Value.Errors -is [System.Collections.IEnumerable] -and -not ($Value.Errors -is [string]))) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriÃ©tÃ© 'Errors' de l'objet rÃ©sultat de validation n'est pas un tableau."
                }
            }

            if ($isValid -and -not ($Value.Warnings -is [System.Collections.IEnumerable] -and -not ($Value.Warnings -is [string]))) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriÃ©tÃ© 'Warnings' de l'objet rÃ©sultat de validation n'est pas un tableau."
                }
            }
        }
        "DependencyResult" {
            # VÃ©rifier que l'objet a les propriÃ©tÃ©s requises
            foreach ($prop in $propertiesToCheck) {
                if (-not $Value.PSObject.Properties.Name -contains $prop) {
                    $isValid = $false
                    if ([string]::IsNullOrEmpty($validationMessage)) {
                        $validationMessage = "L'objet rÃ©sultat de dÃ©pendance ne contient pas la propriÃ©tÃ© requise '$prop'."
                    }
                    break
                }
            }

            # VÃ©rifier que DependencyCount est un entier
            if ($isValid -and -not ($Value.DependencyCount -is [int])) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriÃ©tÃ© 'DependencyCount' de l'objet rÃ©sultat de dÃ©pendance n'est pas un entier."
                }
            }

            # VÃ©rifier que ExplicitDependencies et ImplicitDependencies sont des tableaux
            if ($isValid -and -not ($Value.ExplicitDependencies -is [System.Collections.IEnumerable] -and -not ($Value.ExplicitDependencies -is [string]))) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriÃ©tÃ© 'ExplicitDependencies' de l'objet rÃ©sultat de dÃ©pendance n'est pas un tableau."
                }
            }

            if ($isValid -and -not ($Value.ImplicitDependencies -is [System.Collections.IEnumerable] -and -not ($Value.ImplicitDependencies -is [string]))) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La propriÃ©tÃ© 'ImplicitDependencies' de l'objet rÃ©sultat de dÃ©pendance n'est pas un tableau."
                }
            }
        }
        "JsonString" {
            # VÃ©rifier que la valeur est une chaÃ®ne
            if (-not ($Value -is [string])) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "La valeur n'est pas une chaÃ®ne JSON."
                }
            } else {
                # VÃ©rifier que la chaÃ®ne est un JSON valide
                try {
                    $null = $Value | ConvertFrom-Json
                } catch {
                    $isValid = $false
                    if ([string]::IsNullOrEmpty($validationMessage)) {
                        $validationMessage = "La chaÃ®ne n'est pas un JSON valide : $_"
                    }
                }
            }
        }
        "Custom" {
            # VÃ©rifier d'abord les propriÃ©tÃ©s requises si spÃ©cifiÃ©es
            if ($null -ne $propertiesToCheck -and $propertiesToCheck.Count -gt 0) {
                foreach ($prop in $propertiesToCheck) {
                    if (-not ($Value | Get-Member -Name $prop -MemberType Properties)) {
                        $isValid = $false
                        if ([string]::IsNullOrEmpty($validationMessage)) {
                            $validationMessage = "L'objet ne contient pas la propriÃ©tÃ© requise '$prop'."
                        }
                        break
                    }
                }
            }

            # Si les propriÃ©tÃ©s sont valides, exÃ©cuter la validation personnalisÃ©e
            if ($isValid) {
                if ($null -eq $CustomValidation) {
                    $isValid = $false
                    if ([string]::IsNullOrEmpty($validationMessage)) {
                        $validationMessage = "Une validation personnalisÃ©e est requise lorsque le type est 'Custom'."
                    }
                } else {
                    try {
                        $isValid = & $CustomValidation $Value
                        if ([string]::IsNullOrEmpty($validationMessage) -and -not $isValid) {
                            $validationMessage = "La validation personnalisÃ©e a Ã©chouÃ©."
                        }
                    } catch {
                        $isValid = $false
                        if ([string]::IsNullOrEmpty($validationMessage)) {
                            $validationMessage = "Erreur lors de la validation personnalisÃ©e : $_"
                        }
                    }
                }
            }
        }
    }

    # GÃ©rer l'Ã©chec de la validation
    if (-not $isValid) {
        if ($ThrowOnFailure) {
            throw $validationMessage
        } else {
            Write-Warning $validationMessage
        }
    }

    return $isValid
}
