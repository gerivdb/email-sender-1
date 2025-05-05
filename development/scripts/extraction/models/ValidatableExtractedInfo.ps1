using namespace System.Collections.Generic

<#
.SYNOPSIS
    Classe pour les informations extraites validables.
.DESCRIPTION
    Ã‰tend la classe SerializableExtractedInfo en implÃ©mentant l'interface IValidatable
    pour permettre la validation des donnÃ©es selon diffÃ©rentes rÃ¨gles.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

# Importer les dÃ©pendances
. "$PSScriptRoot\SerializableExtractedInfo.ps1"
. "$PSScriptRoot\ValidationRule.ps1"
. "$PSScriptRoot\..\interfaces\IValidatable.ps1"

class ValidatableExtractedInfo : SerializableExtractedInfo, IValidatable {
    # PropriÃ©tÃ©s spÃ©cifiques Ã  la validation
    hidden [Dictionary[string, List[ValidationRule]]]$ValidationRules
    hidden [Dictionary[string, List[string]]]$ValidationErrors

    # Constructeur par dÃ©faut
    ValidatableExtractedInfo() : base() {
        $this.InitializeValidation()
    }

    # Constructeur avec source
    ValidatableExtractedInfo([string]$source) : base($source) {
        $this.InitializeValidation()
    }

    # Constructeur avec source et extracteur
    ValidatableExtractedInfo([string]$source, [string]$extractorName) : base($source, $extractorName) {
        $this.InitializeValidation()
    }

    # MÃ©thode d'initialisation de la validation
    hidden [void] InitializeValidation() {
        $this.ValidationRules = [Dictionary[string, List[ValidationRule]]]::new()
        $this.ValidationErrors = [Dictionary[string, List[string]]]::new()
        
        # Ajouter les rÃ¨gles de validation par dÃ©faut
        $this.AddDefaultValidationRules()
    }

    # MÃ©thode pour ajouter les rÃ¨gles de validation par dÃ©faut
    hidden [void] AddDefaultValidationRules() {
        # Validation de l'ID
        $this.AddValidationRule("Id", {
            param($target, $value)
            return -not [string]::IsNullOrWhiteSpace($value)
        }, "L'ID ne peut pas Ãªtre vide")

        # Validation de la source
        $this.AddValidationRule("Source", {
            param($target, $value)
            return -not [string]::IsNullOrWhiteSpace($value)
        }, "La source ne peut pas Ãªtre vide")

        # Validation de la date d'extraction
        $this.AddValidationRule("ExtractedAt", {
            param($target, $value)
            return $value -ne $null -and $value -is [datetime] -and $value -le [datetime]::Now
        }, "La date d'extraction doit Ãªtre valide et ne pas Ãªtre dans le futur")

        # Validation du score de confiance
        $this.AddValidationRule("ConfidenceScore", {
            param($target, $value)
            return $value -ge 0 -and $value -le 100
        }, "Le score de confiance doit Ãªtre compris entre 0 et 100")

        # Validation de l'Ã©tat de traitement
        $this.AddValidationRule("ProcessingState", {
            param($target, $value)
            $validStates = @("Raw", "Processed", "Validated", "Normalized", "Enriched")
            return $validStates -contains $value
        }, "L'Ã©tat de traitement doit Ãªtre l'une des valeurs suivantes: Raw, Processed, Validated, Normalized, Enriched")
    }

    # ImplÃ©mentation de l'interface IValidatable

    # MÃ©thode pour valider l'objet
    [bool] Validate() {
        # RÃ©initialiser les erreurs de validation
        $this.ValidationErrors.Clear()
        
        $isValid = $true
        
        # Parcourir toutes les rÃ¨gles de validation
        foreach ($propertyName in $this.ValidationRules.Keys) {
            $rules = $this.ValidationRules[$propertyName]
            
            # Trier les rÃ¨gles par prioritÃ©
            $sortedRules = $rules | Sort-Object -Property Priority -Descending
            
            foreach ($rule in $sortedRules) {
                if (-not $rule.Evaluate($this)) {
                    $isValid = $false
                    
                    # Ajouter l'erreur de validation
                    if (-not $this.ValidationErrors.ContainsKey($propertyName)) {
                        $this.ValidationErrors[$propertyName] = [List[string]]::new()
                    }
                    $this.ValidationErrors[$propertyName].Add($rule.ErrorMessage)
                }
            }
        }
        
        # Mettre Ã  jour la propriÃ©tÃ© IsValid
        $this.IsValid = $isValid
        
        return $isValid
    }

    # MÃ©thode pour valider l'objet avec des rÃ¨gles personnalisÃ©es
    [bool] ValidateWithRules([hashtable]$rules) {
        # Sauvegarder les rÃ¨gles actuelles
        $originalRules = $this.ValidationRules.Clone()
        
        try {
            # Effacer les rÃ¨gles existantes
            $this.ClearValidationRules()
            
            # Ajouter les rÃ¨gles personnalisÃ©es
            foreach ($propertyName in $rules.Keys) {
                $propertyRules = $rules[$propertyName]
                
                foreach ($ruleInfo in $propertyRules) {
                    $this.AddValidationRule(
                        $propertyName,
                        $ruleInfo.Condition,
                        $ruleInfo.ErrorMessage
                    )
                }
            }
            
            # Valider avec les nouvelles rÃ¨gles
            return $this.Validate()
        }
        finally {
            # Restaurer les rÃ¨gles originales
            $this.ValidationRules = $originalRules
        }
    }

    # MÃ©thode pour obtenir les erreurs de validation
    [string[]] GetValidationErrors() {
        $allErrors = [List[string]]::new()
        
        foreach ($propertyName in $this.ValidationErrors.Keys) {
            $errors = $this.ValidationErrors[$propertyName]
            foreach ($error in $errors) {
                $allErrors.Add("[$propertyName] $error")
            }
        }
        
        return $allErrors.ToArray()
    }

    # MÃ©thode pour vÃ©rifier si une propriÃ©tÃ© spÃ©cifique est valide
    [bool] IsPropertyValid([string]$propertyName) {
        # Si la propriÃ©tÃ© n'a pas de rÃ¨gles, elle est considÃ©rÃ©e comme valide
        if (-not $this.ValidationRules.ContainsKey($propertyName)) {
            return $true
        }
        
        # Si la propriÃ©tÃ© a des erreurs, elle n'est pas valide
        if ($this.ValidationErrors.ContainsKey($propertyName) -and $this.ValidationErrors[$propertyName].Count -gt 0) {
            return $false
        }
        
        return $true
    }

    # MÃ©thode pour obtenir les erreurs de validation pour une propriÃ©tÃ© spÃ©cifique
    [string[]] GetPropertyValidationErrors([string]$propertyName) {
        if ($this.ValidationErrors.ContainsKey($propertyName)) {
            return $this.ValidationErrors[$propertyName].ToArray()
        }
        
        return @()
    }

    # MÃ©thode pour ajouter une rÃ¨gle de validation
    [void] AddValidationRule([string]$propertyName, [scriptblock]$rule, [string]$errorMessage) {
        if (-not $this.ValidationRules.ContainsKey($propertyName)) {
            $this.ValidationRules[$propertyName] = [List[ValidationRule]]::new()
        }
        
        $validationRule = [ValidationRule]::new($propertyName, $rule, $errorMessage)
        $this.ValidationRules[$propertyName].Add($validationRule)
    }

    # MÃ©thode pour supprimer une rÃ¨gle de validation
    [void] RemoveValidationRule([string]$propertyName, [int]$ruleIndex) {
        if ($this.ValidationRules.ContainsKey($propertyName) -and 
            $ruleIndex -ge 0 -and 
            $ruleIndex -lt $this.ValidationRules[$propertyName].Count) {
            $this.ValidationRules[$propertyName].RemoveAt($ruleIndex)
        }
    }

    # MÃ©thode pour effacer toutes les rÃ¨gles de validation
    [void] ClearValidationRules() {
        $this.ValidationRules.Clear()
    }

    # MÃ©thode pour obtenir toutes les rÃ¨gles de validation
    [ValidationRule[]] GetAllValidationRules() {
        $allRules = [List[ValidationRule]]::new()
        
        foreach ($propertyName in $this.ValidationRules.Keys) {
            $rules = $this.ValidationRules[$propertyName]
            foreach ($rule in $rules) {
                $allRules.Add($rule)
            }
        }
        
        return $allRules.ToArray()
    }

    # MÃ©thode pour obtenir les rÃ¨gles de validation pour une propriÃ©tÃ© spÃ©cifique
    [ValidationRule[]] GetPropertyValidationRules([string]$propertyName) {
        if ($this.ValidationRules.ContainsKey($propertyName)) {
            return $this.ValidationRules[$propertyName].ToArray()
        }
        
        return @()
    }

    # Surcharge de la mÃ©thode Clone pour retourner un ValidatableExtractedInfo
    [ValidatableExtractedInfo] Clone() {
        $clone = [ValidatableExtractedInfo]::new()
        $clone.Id = $this.Id
        $clone.Source = $this.Source
        $clone.ExtractedAt = $this.ExtractedAt
        $clone.ExtractorName = $this.ExtractorName
        $clone.ProcessingState = $this.ProcessingState
        $clone.ConfidenceScore = $this.ConfidenceScore
        $clone.IsValid = $this.IsValid
        
        # Cloner les mÃ©tadonnÃ©es
        foreach ($key in $this.Metadata.Keys) {
            $clone.Metadata[$key] = $this.Metadata[$key]
        }
        
        # Cloner les rÃ¨gles de validation
        foreach ($propertyName in $this.ValidationRules.Keys) {
            $rules = $this.ValidationRules[$propertyName]
            
            foreach ($rule in $rules) {
                $clonedRule = $rule.Clone()
                
                if (-not $clone.ValidationRules.ContainsKey($propertyName)) {
                    $clone.ValidationRules[$propertyName] = [List[ValidationRule]]::new()
                }
                
                $clone.ValidationRules[$propertyName].Add($clonedRule)
            }
        }
        
        return $clone
    }
}
