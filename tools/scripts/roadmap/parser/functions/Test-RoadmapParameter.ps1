<#
.SYNOPSIS
    Valide les paramètres utilisés dans les fonctions du module RoadmapParser.

.DESCRIPTION
    La fonction Test-RoadmapParameter valide les paramètres selon différentes règles
    et critères. Elle permet de s'assurer que les paramètres fournis aux fonctions
    du module RoadmapParser sont valides et conformes aux attentes.

.PARAMETER Value
    La valeur du paramètre à valider.

.PARAMETER Type
    Le type de validation à effectuer. Valeurs possibles :
    - FilePath : Vérifie que le chemin de fichier existe et est accessible
    - DirectoryPath : Vérifie que le répertoire existe et est accessible
    - RoadmapObject : Vérifie que l'objet est une roadmap valide
    - TaskId : Vérifie que l'identifiant de tâche est valide
    - Status : Vérifie que le statut est valide
    - NonEmptyString : Vérifie que la chaîne n'est pas vide
    - PositiveInteger : Vérifie que l'entier est positif
    - Custom : Utilise une validation personnalisée

.PARAMETER CustomValidation
    Une expression scriptblock pour une validation personnalisée.
    Utilisé uniquement lorsque Type est "Custom".

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la validation.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER Roadmap
    L'objet roadmap à utiliser pour la validation (requis pour certains types de validation).

.PARAMETER AllowNull
    Indique si la valeur null est autorisée.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la validation.

.EXAMPLE
    Test-RoadmapParameter -Value "C:\path\to\file.md" -Type FilePath -ThrowOnFailure
    Vérifie que le chemin de fichier existe et est accessible, et lève une exception si ce n'est pas le cas.

.EXAMPLE
    Test-RoadmapParameter -Value "Task-123" -Type TaskId -Roadmap $roadmap
    Vérifie que l'identifiant de tâche existe dans la roadmap spécifiée.

.OUTPUTS
    [bool] Indique si la validation a réussi.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-10
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

    # Vérifier si la valeur est null
    if ($null -eq $Value) {
        if ($AllowNull) {
            return $true
        } else {
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
                $validationMessage = "Le répertoire '$Value' n'existe pas ou n'est pas accessible."
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
                    $validationMessage = "L'objet roadmap est requis pour valider un identifiant de tâche."
                }
            } else {
                $isValid = $Roadmap.AllTasks.ContainsKey($Value)
                if ([string]::IsNullOrEmpty($validationMessage) -and -not $isValid) {
                    $validationMessage = "La tâche avec l'identifiant '$Value' n'existe pas dans la roadmap."
                }
            }
        }
        "Status" {
            $validStatuses = @("Complete", "Incomplete", "InProgress", "Blocked", "All")
            $isValid = $validStatuses -contains $Value
            if ([string]::IsNullOrEmpty($validationMessage) -and -not $isValid) {
                $validationMessage = "Le statut '$Value' n'est pas valide. Valeurs autorisées : $($validStatuses -join ', ')"
            }
        }
        "NonEmptyString" {
            $isValid = -not [string]::IsNullOrWhiteSpace($Value)
            if ([string]::IsNullOrEmpty($validationMessage) -and -not $isValid) {
                $validationMessage = "La chaîne ne peut pas être vide ou ne contenir que des espaces."
            }
        }
        "PositiveInteger" {
            $isValid = $Value -is [int] -and $Value -ge 0
            if ([string]::IsNullOrEmpty($validationMessage) -and -not $isValid) {
                $validationMessage = "La valeur doit être un entier positif ou nul."
            }
        }
        "Custom" {
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
