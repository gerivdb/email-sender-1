using namespace System.Collections.Generic

<#
.SYNOPSIS
    Classe reprÃ©sentant une rÃ¨gle de validation.
.DESCRIPTION
    DÃ©finit une rÃ¨gle de validation avec une condition, un message d'erreur
    et des mÃ©tadonnÃ©es associÃ©es.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

class ValidationRule {
    # PropriÃ©tÃ©s
    [string]$PropertyName
    [scriptblock]$Condition
    [string]$ErrorMessage
    [string]$RuleId
    [hashtable]$Metadata
    [int]$Priority = 0
    [bool]$IsEnabled = $true

    # Constructeur par dÃ©faut
    ValidationRule() {
        $this.RuleId = [guid]::NewGuid().ToString()
        $this.Metadata = @{}
    }

    # Constructeur avec propriÃ©tÃ© et condition
    ValidationRule([string]$propertyName, [scriptblock]$condition) {
        $this.PropertyName = $propertyName
        $this.Condition = $condition
        $this.RuleId = [guid]::NewGuid().ToString()
        $this.Metadata = @{}
        $this.ErrorMessage = "La propriÃ©tÃ© '$propertyName' n'est pas valide"
    }

    # Constructeur complet
    ValidationRule([string]$propertyName, [scriptblock]$condition, [string]$errorMessage) {
        $this.PropertyName = $propertyName
        $this.Condition = $condition
        $this.ErrorMessage = $errorMessage
        $this.RuleId = [guid]::NewGuid().ToString()
        $this.Metadata = @{}
    }

    # MÃ©thode pour Ã©valuer la rÃ¨gle
    [bool] Evaluate([object]$target) {
        if (-not $this.IsEnabled) {
            return $true
        }

        if ($null -eq $this.Condition) {
            return $true
        }

        try {
            # CrÃ©er un contexte d'Ã©valuation avec la cible et la propriÃ©tÃ©
            $context = @{
                Target = $target
                PropertyName = $this.PropertyName
                PropertyValue = if ([string]::IsNullOrEmpty($this.PropertyName)) { $target } else { $target.$($this.PropertyName) }
            }

            # Ã‰valuer la condition dans ce contexte
            return & $this.Condition $context.Target $context.PropertyValue
        }
        catch {
            # En cas d'erreur, considÃ©rer la rÃ¨gle comme Ã©chouÃ©e
            $this.Metadata["LastError"] = $_.Exception.Message
            return $false
        }
    }

    # MÃ©thode pour activer/dÃ©sactiver la rÃ¨gle
    [void] SetEnabled([bool]$enabled) {
        $this.IsEnabled = $enabled
    }

    # MÃ©thode pour dÃ©finir la prioritÃ©
    [void] SetPriority([int]$priority) {
        $this.Priority = $priority
    }

    # MÃ©thode pour ajouter des mÃ©tadonnÃ©es
    [void] AddMetadata([string]$key, [object]$value) {
        $this.Metadata[$key] = $value
    }

    # MÃ©thode pour cloner la rÃ¨gle
    [ValidationRule] Clone() {
        $clone = [ValidationRule]::new()
        $clone.PropertyName = $this.PropertyName
        $clone.Condition = $this.Condition
        $clone.ErrorMessage = $this.ErrorMessage
        $clone.RuleId = $this.RuleId
        $clone.Priority = $this.Priority
        $clone.IsEnabled = $this.IsEnabled
        
        # Cloner les mÃ©tadonnÃ©es
        foreach ($key in $this.Metadata.Keys) {
            $clone.Metadata[$key] = $this.Metadata[$key]
        }
        
        return $clone
    }

    # MÃ©thode ToString() surchargÃ©e
    [string] ToString() {
        $status = if ($this.IsEnabled) { "ActivÃ©e" } else { "DÃ©sactivÃ©e" }
        return "RÃ¨gle '$($this.RuleId)' pour '$($this.PropertyName)' - $status (PrioritÃ©: $($this.Priority))"
    }
}
