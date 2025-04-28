<#
.SYNOPSIS
    Valide les paramÃ¨tres utilisÃ©s dans les fonctions du module RoadmapParser.

.DESCRIPTION
    La fonction Test-RoadmapParameter valide les paramÃ¨tres selon diffÃ©rentes rÃ¨gles
    et critÃ¨res. Elle permet de s'assurer que les paramÃ¨tres fournis aux fonctions
    du module RoadmapParser sont valides et conformes aux attentes.

.PARAMETER Value
    La valeur du paramÃ¨tre Ã  valider.

.PARAMETER Type
    Le type de validation Ã  effectuer. Valeurs possibles :
    - FilePath : VÃ©rifie que le chemin de fichier existe et est accessible
    - DirectoryPath : VÃ©rifie que le rÃ©pertoire existe et est accessible
    - RoadmapObject : VÃ©rifie que l'objet est une roadmap valide
    - TaskId : VÃ©rifie que l'identifiant de tÃ¢che est valide
    - Status : VÃ©rifie que le statut est valide
    - NonEmptyString : VÃ©rifie que la chaÃ®ne n'est pas vide
    - PositiveInteger : VÃ©rifie que l'entier est positif
    - Custom : Utilise une validation personnalisÃ©e

.PARAMETER CustomValidation
    Une expression scriptblock pour une validation personnalisÃ©e.
    UtilisÃ© uniquement lorsque Type est "Custom".

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la validation.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER Roadmap
    L'objet roadmap Ã  utiliser pour la validation (requis pour certains types de validation).

.PARAMETER AllowNull
    Indique si la valeur null est autorisÃ©e.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la validation.

.EXAMPLE
    Test-RoadmapParameter -Value "C:\path\to\file.md" -Type FilePath -ThrowOnFailure
    VÃ©rifie que le chemin de fichier existe et est accessible, et lÃ¨ve une exception si ce n'est pas le cas.

.EXAMPLE
    Test-RoadmapParameter -Value "Task-123" -Type TaskId -Roadmap $roadmap
    VÃ©rifie que l'identifiant de tÃ¢che existe dans la roadmap spÃ©cifiÃ©e.

.OUTPUTS
    [bool] Indique si la validation a rÃ©ussi.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-10
#>
function Test-RoadmapParameter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [AllowNull()]
        $Value,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("FilePath", "DirectoryPath", "RoadmapObject", "TaskId", "Status", "NonEmptyString", "PositiveInteger", "Custom")]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomValidation,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Roadmap,

        [Parameter(Mandatory = $false)]
        [switch]$AllowNull,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # VÃ©rifier si la valeur est null
    if ($null -eq $Value) {
        if ($AllowNull) {
            return $true
        } else {
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
    }

    # Effectuer la validation selon le type
    $isValid = $true
    $validationMessage = $ErrorMessage

    switch ($Type) {
        "FilePath" {
            $isValid = Test-Path -Path $Value -PathType Leaf
            if ([string]::IsNullOrEmpty($validationMessage) -and -not $isValid) {
                $validationMessage = "Le fichier '$Value' n'existe pas ou n'est pas accessible."
            }
        }
        "DirectoryPath" {
            $isValid = Test-Path -Path $Value -PathType Container
            if ([string]::IsNullOrEmpty($validationMessage) -and -not $isValid) {
                $validationMessage = "Le rÃ©pertoire '$Value' n'existe pas ou n'est pas accessible."
            }
        }
        "RoadmapObject" {
            $isValid = $null -ne $Value -and 
                       $Value.PSObject.Properties.Name -contains "Sections" -and 
                       $Value.PSObject.Properties.Name -contains "AllTasks"
            if ([string]::IsNullOrEmpty($validationMessage) -and -not $isValid) {
                $validationMessage = "L'objet fourni n'est pas une roadmap valide."
            }
        }
        "TaskId" {
            if ($null -eq $Roadmap) {
                $isValid = $false
                if ([string]::IsNullOrEmpty($validationMessage)) {
                    $validationMessage = "L'objet roadmap est requis pour valider un identifiant de tÃ¢che."
                }
            } else {
                $isValid = $Roadmap.AllTasks.ContainsKey($Value)
                if ([string]::IsNullOrEmpty($validationMessage) -and -not $isValid) {
                    $validationMessage = "La tÃ¢che avec l'identifiant '$Value' n'existe pas dans la roadmap."
                }
            }
        }
        "Status" {
            $validStatuses = @("Complete", "Incomplete", "InProgress", "Blocked", "All")
            $isValid = $validStatuses -contains $Value
            if ([string]::IsNullOrEmpty($validationMessage) -and -not $isValid) {
                $validationMessage = "Le statut '$Value' n'est pas valide. Valeurs autorisÃ©es : $($validStatuses -join ', ')"
            }
        }
        "NonEmptyString" {
            $isValid = -not [string]::IsNullOrWhiteSpace($Value)
            if ([string]::IsNullOrEmpty($validationMessage) -and -not $isValid) {
                $validationMessage = "La chaÃ®ne ne peut pas Ãªtre vide ou ne contenir que des espaces."
            }
        }
        "PositiveInteger" {
            $isValid = $Value -is [int] -and $Value -ge 0
            if ([string]::IsNullOrEmpty($validationMessage) -and -not $isValid) {
                $validationMessage = "La valeur doit Ãªtre un entier positif ou nul."
            }
        }
        "Custom" {
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
