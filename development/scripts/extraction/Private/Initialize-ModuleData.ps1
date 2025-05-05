<#
.SYNOPSIS
    Initialise les donnÃ©es du module.
.DESCRIPTION
    Fonction interne qui initialise les donnÃ©es globales du module.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

function Initialize-ModuleData {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Initialisation des donnÃ©es du module"
    
    # Initialiser les donnÃ©es globales du module
    $script:ModuleData = @{
        # Compteurs
        Counters = @{
            InfoCreated = 0
            CollectionCreated = 0
            ValidationRulesCreated = 0
        }
        
        # Cache
        Cache = @{
            ValidationRules = @{}
            DefaultValidationRules = @{}
        }
        
        # Configuration
        Config = @{
            DefaultSerializationFormat = "Json"
            DefaultValidationEnabled = $true
            DefaultConfidenceThreshold = 75
            DefaultLanguage = "fr"
        }
        
        # Statistiques
        Stats = @{
            StartTime = [datetime]::Now
            OperationsPerformed = @{}
        }
    }
    
    # Initialiser les rÃ¨gles de validation par dÃ©faut
    Initialize-DefaultValidationRules
    
    Write-Verbose "DonnÃ©es du module initialisÃ©es avec succÃ¨s"
}

function Initialize-DefaultValidationRules {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Initialisation des rÃ¨gles de validation par dÃ©faut"
    
    # RÃ¨gles pour les informations de base
    $script:ModuleData.DefaultValidationRules.Base = @(
        @{
            PropertyName = "Id"
            Condition = { param($target, $value) -not [string]::IsNullOrWhiteSpace($value) }
            ErrorMessage = "L'ID ne peut pas Ãªtre vide"
        },
        @{
            PropertyName = "Source"
            Condition = { param($target, $value) -not [string]::IsNullOrWhiteSpace($value) }
            ErrorMessage = "La source ne peut pas Ãªtre vide"
        },
        @{
            PropertyName = "ExtractedAt"
            Condition = { param($target, $value) $value -ne $null -and $value -is [datetime] -and $value -le [datetime]::Now }
            ErrorMessage = "La date d'extraction doit Ãªtre valide et ne pas Ãªtre dans le futur"
        },
        @{
            PropertyName = "ProcessingState"
            Condition = { param($target, $value) @("Raw", "Processed", "Validated", "Normalized", "Enriched") -contains $value }
            ErrorMessage = "L'Ã©tat de traitement doit Ãªtre l'une des valeurs suivantes: Raw, Processed, Validated, Normalized, Enriched"
        },
        @{
            PropertyName = "ConfidenceScore"
            Condition = { param($target, $value) $value -ge 0 -and $value -le 100 }
            ErrorMessage = "Le score de confiance doit Ãªtre compris entre 0 et 100"
        }
    )
    
    # RÃ¨gles pour les informations textuelles
    $script:ModuleData.DefaultValidationRules.Text = @(
        @{
            PropertyName = "Text"
            Condition = { param($target, $value) -not [string]::IsNullOrEmpty($value) }
            ErrorMessage = "Le texte ne peut pas Ãªtre vide"
        },
        @{
            PropertyName = "Language"
            Condition = { param($target, $value) @("fr", "en", "es", "de", "it") -contains $value }
            ErrorMessage = "La langue doit Ãªtre l'une des valeurs suivantes: fr, en, es, de, it"
        }
    )
    
    # RÃ¨gles pour les informations structurÃ©es
    $script:ModuleData.DefaultValidationRules.StructuredData = @(
        @{
            PropertyName = "Data"
            Condition = { param($target, $value) $null -ne $value }
            ErrorMessage = "Les donnÃ©es ne peuvent pas Ãªtre null"
        },
        @{
            PropertyName = "DataFormat"
            Condition = { param($target, $value) @("Hashtable", "PSObject", "Dictionary", "Array", "Json", "Xml", "Csv") -contains $value }
            ErrorMessage = "Le format de donnÃ©es doit Ãªtre l'un des suivants: Hashtable, PSObject, Dictionary, Array, Json, Xml, Csv"
        }
    )
    
    # RÃ¨gles pour les informations mÃ©dias
    $script:ModuleData.DefaultValidationRules.Media = @(
        @{
            PropertyName = "MediaPath"
            Condition = { param($target, $value) -not [string]::IsNullOrEmpty($value) }
            ErrorMessage = "Le chemin du mÃ©dia ne peut pas Ãªtre vide"
        },
        @{
            PropertyName = "MediaType"
            Condition = { param($target, $value) @("Image", "Audio", "Video", "Document", "Other") -contains $value }
            ErrorMessage = "Le type de mÃ©dia doit Ãªtre l'un des suivants: Image, Audio, Video, Document, Other"
        },
        @{
            PropertyName = "FileSize"
            Condition = { param($target, $value) $value -ge 0 }
            ErrorMessage = "La taille du fichier doit Ãªtre positive ou nulle"
        }
    )
    
    Write-Verbose "RÃ¨gles de validation par dÃ©faut initialisÃ©es avec succÃ¨s"
}
