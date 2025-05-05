<#
.SYNOPSIS
    Module principal pour la gestion des informations extraites.
.DESCRIPTION
    Fournit des fonctions pour crÃ©er, manipuler, valider et convertir
    des informations extraites de diffÃ©rentes sources.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

# Module variables
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = "1.0.0"
$script:ModuleName = "ExtractedInfoModule"
$script:ModuleData = @{
    Counters = @{
        InfoCreated       = 0
        CollectionCreated = 0
    }
    Config   = @{
        DefaultFormat   = "Json"
        DefaultLanguage = "en"
    }
}

# Fonction d'initialisation du module
function Initialize-Module {
    [CmdletBinding()]
    param()

    Write-Verbose "Initialisation du module $script:ModuleName v$script:ModuleVersion"

    # Initialiser les donnÃ©es du module
    $script:ModuleData = @{
        # Compteurs
        Counters = @{
            InfoCreated            = 0
            CollectionCreated      = 0
            ValidationRulesCreated = 0
        }

        # Cache
        Cache    = @{
            ValidationRules        = @{}
            DefaultValidationRules = @{}
        }

        # Configuration
        Config   = @{
            DefaultSerializationFormat = "Json"
            DefaultValidationEnabled   = $true
            DefaultConfidenceThreshold = 75
            DefaultLanguage            = "fr"
        }

        # Statistiques
        Stats    = @{
            StartTime           = [datetime]::Now
            OperationsPerformed = @{}
        }
    }

    # Charger les fonctions de base (uniquement celles qui existent)
    $baseFunctions = @(
        "New-BaseExtractedInfo.ps1",
        "Add-ExtractedInfoMetadata.ps1",
        "Get-ExtractedInfoMetadata.ps1",
        "Remove-ExtractedInfoMetadata.ps1",
        "Get-ExtractedInfoSummary.ps1",
        "Copy-ExtractedInfo.ps1"
    )

    foreach ($function in $baseFunctions) {
        $path = "$script:ModuleRoot\Public\Base\$function"
        if (Test-Path $path) {
            Write-Verbose "Chargement de $path"
            . $path
        }
    }

    # Charger les fonctions de collection (uniquement celles qui existent)
    $collectionFunctions = @(
        "New-ExtractedInfoCollection.ps1",
        "Add-ExtractedInfoToCollection.ps1",
        "Remove-ExtractedInfoFromCollection.ps1",
        "Get-ExtractedInfoFromCollection.ps1",
        "Get-ExtractedInfoCollectionStatistics.ps1"
    )

    foreach ($function in $collectionFunctions) {
        $path = "$script:ModuleRoot\Public\Collection\$function"
        if (Test-Path $path) {
            Write-Verbose "Chargement de $path"
            . $path
        }
    }

    Write-Verbose "Module $script:ModuleName initialisÃ© avec succÃ¨s"
}

# Exporter les fonctions publiques
Export-ModuleMember -Function @(
    # Fonctions de base
    'New-BaseExtractedInfo',
    'Add-ExtractedInfoMetadata',
    'Get-ExtractedInfoMetadata',
    'Remove-ExtractedInfoMetadata',
    'Get-ExtractedInfoSummary',
    'Copy-ExtractedInfo',

    # Fonctions de collection
    'New-ExtractedInfoCollection',
    'Add-ExtractedInfoToCollection',
    'Remove-ExtractedInfoFromCollection',
    'Get-ExtractedInfoFromCollection',
    'Get-ExtractedInfoCollectionStatistics'
)

# Initialiser le module
Initialize-Module
