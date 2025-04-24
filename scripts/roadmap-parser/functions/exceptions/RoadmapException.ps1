<#
.SYNOPSIS
    Définit les classes d'exceptions personnalisées pour le module RoadmapParser.

.DESCRIPTION
    Ce script définit une hiérarchie d'exceptions personnalisées pour le module RoadmapParser.
    Ces exceptions permettent de gérer de manière spécifique les différentes erreurs qui peuvent
    survenir lors de l'utilisation du module.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-15
#>

# Classe d'exception de base pour toutes les exceptions du module RoadmapParser
class RoadmapException : System.Exception {
    [string]$Category
    [int]$ErrorCode
    [System.Collections.Hashtable]$AdditionalInfo

    RoadmapException([string]$message) : base($message) {
        $this.Category = "General"
        $this.ErrorCode = 1000
        $this.AdditionalInfo = @{}
    }

    RoadmapException([string]$message, [System.Exception]$innerException) : base($message, $innerException) {
        $this.Category = "General"
        $this.ErrorCode = 1000
        $this.AdditionalInfo = @{}
    }

    RoadmapException([string]$message, [string]$category, [int]$errorCode) : base($message) {
        $this.Category = $category
        $this.ErrorCode = $errorCode
        $this.AdditionalInfo = @{}
    }

    RoadmapException([string]$message, [string]$category, [int]$errorCode, [System.Exception]$innerException) : base($message, $innerException) {
        $this.Category = $category
        $this.ErrorCode = $errorCode
        $this.AdditionalInfo = @{}
    }

    RoadmapException([string]$message, [string]$category, [int]$errorCode, [System.Collections.Hashtable]$additionalInfo) : base($message) {
        $this.Category = $category
        $this.ErrorCode = $errorCode
        $this.AdditionalInfo = $additionalInfo
    }

    RoadmapException([string]$message, [string]$category, [int]$errorCode, [System.Collections.Hashtable]$additionalInfo, [System.Exception]$innerException) : base($message, $innerException) {
        $this.Category = $category
        $this.ErrorCode = $errorCode
        $this.AdditionalInfo = $additionalInfo
    }

    [string] GetDetailedMessage() {
        $detailedMessage = "[$($this.Category)] Error $($this.ErrorCode): $($this.Message)"

        if ($this.AdditionalInfo.Count -gt 0) {
            $detailedMessage += "`nAdditional Information:"
            foreach ($key in $this.AdditionalInfo.Keys) {
                $detailedMessage += "`n  - ${key}: $($this.AdditionalInfo[$key])"
            }
        }

        if ($this.InnerException) {
            $detailedMessage += "`nInner Exception: $($this.InnerException.Message)"
        }

        return $detailedMessage
    }
}

# Exception pour les erreurs de parsing
class RoadmapParsingException : RoadmapException {
    [int]$LineNumber
    [string]$LineContent

    RoadmapParsingException([string]$message) : base($message, "Parsing", 2000) {
        $this.LineNumber = 0
        $this.LineContent = ""
    }

    RoadmapParsingException([string]$message, [System.Exception]$innerException) : base($message, "Parsing", 2000, $innerException) {
        $this.LineNumber = 0
        $this.LineContent = ""
    }

    RoadmapParsingException([string]$message, [int]$lineNumber, [string]$lineContent) : base($message, "Parsing", 2000) {
        $this.LineNumber = $lineNumber
        $this.LineContent = $lineContent
    }

    RoadmapParsingException([string]$message, [int]$lineNumber, [string]$lineContent, [System.Exception]$innerException) : base($message, "Parsing", 2000, $innerException) {
        $this.LineNumber = $lineNumber
        $this.LineContent = $lineContent
    }

    [string] GetDetailedMessage() {
        $detailedMessage = "[$($this.Category)] Error $($this.ErrorCode): $($this.Message)"

        if ($this.LineNumber -gt 0) {
            $detailedMessage += "`nLine Number: $($this.LineNumber)"
        }

        if (-not [string]::IsNullOrEmpty($this.LineContent)) {
            $detailedMessage += "`nLine Content: $($this.LineContent)"
        }

        if ($this.AdditionalInfo.Count -gt 0) {
            $detailedMessage += "`nAdditional Information:"
            foreach ($key in $this.AdditionalInfo.Keys) {
                $detailedMessage += "`n  - ${key}: $($this.AdditionalInfo[$key])"
            }
        }

        if ($this.InnerException) {
            $detailedMessage += "`nInner Exception: $($this.InnerException.Message)"
        }

        return $detailedMessage
    }
}

# Exception pour les erreurs de validation
class RoadmapValidationException : RoadmapException {
    [string]$ValidationRule
    [object]$InvalidValue

    RoadmapValidationException([string]$message) : base($message, "Validation", 3000) {
        $this.ValidationRule = ""
        $this.InvalidValue = $null
    }

    RoadmapValidationException([string]$message, [System.Exception]$innerException) : base($message, "Validation", 3000, $innerException) {
        $this.ValidationRule = ""
        $this.InvalidValue = $null
    }

    RoadmapValidationException([string]$message, [string]$validationRule, [object]$invalidValue) : base($message, "Validation", 3000) {
        $this.ValidationRule = $validationRule
        $this.InvalidValue = $invalidValue
    }

    RoadmapValidationException([string]$message, [string]$validationRule, [object]$invalidValue, [System.Exception]$innerException) : base($message, "Validation", 3000, $innerException) {
        $this.ValidationRule = $validationRule
        $this.InvalidValue = $invalidValue
    }

    [string] GetDetailedMessage() {
        $detailedMessage = "[$($this.Category)] Error $($this.ErrorCode): $($this.Message)"

        if (-not [string]::IsNullOrEmpty($this.ValidationRule)) {
            $detailedMessage += "`nValidation Rule: $($this.ValidationRule)"
        }

        if ($null -ne $this.InvalidValue) {
            $detailedMessage += "`nInvalid Value: $($this.InvalidValue)"
        }

        if ($this.AdditionalInfo.Count -gt 0) {
            $detailedMessage += "`nAdditional Information:"
            foreach ($key in $this.AdditionalInfo.Keys) {
                $detailedMessage += "`n  - ${key}: $($this.AdditionalInfo[$key])"
            }
        }

        if ($this.InnerException) {
            $detailedMessage += "`nInner Exception: $($this.InnerException.Message)"
        }

        return $detailedMessage
    }
}

# Exception pour les erreurs d'IO
class RoadmapIOException : RoadmapException {
    [string]$FilePath
    [string]$Operation

    RoadmapIOException([string]$message) : base($message, "IO", 4000) {
        $this.FilePath = ""
        $this.Operation = ""
    }

    RoadmapIOException([string]$message, [System.Exception]$innerException) : base($message, "IO", 4000, $innerException) {
        $this.FilePath = ""
        $this.Operation = ""
    }

    RoadmapIOException([string]$message, [string]$filePath, [string]$operation) : base($message, "IO", 4000) {
        $this.FilePath = $filePath
        $this.Operation = $operation
    }

    RoadmapIOException([string]$message, [string]$filePath, [string]$operation, [System.Exception]$innerException) : base($message, "IO", 4000, $innerException) {
        $this.FilePath = $filePath
        $this.Operation = $operation
    }

    [string] GetDetailedMessage() {
        $detailedMessage = "[$($this.Category)] Error $($this.ErrorCode): $($this.Message)"

        if (-not [string]::IsNullOrEmpty($this.FilePath)) {
            $detailedMessage += "`nFile Path: $($this.FilePath)"
        }

        if (-not [string]::IsNullOrEmpty($this.Operation)) {
            $detailedMessage += "`nOperation: $($this.Operation)"
        }

        if ($this.AdditionalInfo.Count -gt 0) {
            $detailedMessage += "`nAdditional Information:"
            foreach ($key in $this.AdditionalInfo.Keys) {
                $detailedMessage += "`n  - ${key}: $($this.AdditionalInfo[$key])"
            }
        }

        if ($this.InnerException) {
            $detailedMessage += "`nInner Exception: $($this.InnerException.Message)"
        }

        return $detailedMessage
    }
}

# Exception pour les erreurs de dépendance
class RoadmapDependencyException : RoadmapException {
    [string]$SourceTaskId
    [string]$TargetTaskId
    [string]$DependencyType

    RoadmapDependencyException([string]$message) : base($message, "Dependency", 5000) {
        $this.SourceTaskId = ""
        $this.TargetTaskId = ""
        $this.DependencyType = ""
    }

    RoadmapDependencyException([string]$message, [System.Exception]$innerException) : base($message, "Dependency", 5000, $innerException) {
        $this.SourceTaskId = ""
        $this.TargetTaskId = ""
        $this.DependencyType = ""
    }

    RoadmapDependencyException([string]$message, [string]$sourceTaskId, [string]$targetTaskId, [string]$dependencyType) : base($message, "Dependency", 5000) {
        $this.SourceTaskId = $sourceTaskId
        $this.TargetTaskId = $targetTaskId
        $this.DependencyType = $dependencyType
    }

    RoadmapDependencyException([string]$message, [string]$sourceTaskId, [string]$targetTaskId, [string]$dependencyType, [System.Exception]$innerException) : base($message, "Dependency", 5000, $innerException) {
        $this.SourceTaskId = $sourceTaskId
        $this.TargetTaskId = $targetTaskId
        $this.DependencyType = $dependencyType
    }

    [string] GetDetailedMessage() {
        $detailedMessage = "[$($this.Category)] Error $($this.ErrorCode): $($this.Message)"

        if (-not [string]::IsNullOrEmpty($this.SourceTaskId)) {
            $detailedMessage += "`nSource Task ID: $($this.SourceTaskId)"
        }

        if (-not [string]::IsNullOrEmpty($this.TargetTaskId)) {
            $detailedMessage += "`nTarget Task ID: $($this.TargetTaskId)"
        }

        if (-not [string]::IsNullOrEmpty($this.DependencyType)) {
            $detailedMessage += "`nDependency Type: $($this.DependencyType)"
        }

        if ($this.AdditionalInfo.Count -gt 0) {
            $detailedMessage += "`nAdditional Information:"
            foreach ($key in $this.AdditionalInfo.Keys) {
                $detailedMessage += "`n  - ${key}: $($this.AdditionalInfo[$key])"
            }
        }

        if ($this.InnerException) {
            $detailedMessage += "`nInner Exception: $($this.InnerException.Message)"
        }

        return $detailedMessage
    }
}

# Exception pour les erreurs de configuration
class RoadmapConfigurationException : RoadmapException {
    [string]$ConfigKey
    [string]$ConfigValue

    RoadmapConfigurationException([string]$message) : base($message, "Configuration", 6000) {
        $this.ConfigKey = ""
        $this.ConfigValue = ""
    }

    RoadmapConfigurationException([string]$message, [System.Exception]$innerException) : base($message, "Configuration", 6000, $innerException) {
        $this.ConfigKey = ""
        $this.ConfigValue = ""
    }

    RoadmapConfigurationException([string]$message, [string]$configKey, [string]$configValue) : base($message, "Configuration", 6000) {
        $this.ConfigKey = $configKey
        $this.ConfigValue = $configValue
    }

    RoadmapConfigurationException([string]$message, [string]$configKey, [string]$configValue, [System.Exception]$innerException) : base($message, "Configuration", 6000, $innerException) {
        $this.ConfigKey = $configKey
        $this.ConfigValue = $configValue
    }

    [string] GetDetailedMessage() {
        $detailedMessage = "[$($this.Category)] Error $($this.ErrorCode): $($this.Message)"

        if (-not [string]::IsNullOrEmpty($this.ConfigKey)) {
            $detailedMessage += "`nConfiguration Key: $($this.ConfigKey)"
        }

        if (-not [string]::IsNullOrEmpty($this.ConfigValue)) {
            $detailedMessage += "`nConfiguration Value: $($this.ConfigValue)"
        }

        if ($this.AdditionalInfo.Count -gt 0) {
            $detailedMessage += "`nAdditional Information:"
            foreach ($key in $this.AdditionalInfo.Keys) {
                $detailedMessage += "`n  - ${key}: $($this.AdditionalInfo[$key])"
            }
        }

        if ($this.InnerException) {
            $detailedMessage += "`nInner Exception: $($this.InnerException.Message)"
        }

        return $detailedMessage
    }
}
