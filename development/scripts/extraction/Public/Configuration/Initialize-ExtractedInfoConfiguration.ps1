<#
.SYNOPSIS
    Initialise la configuration du module avec des valeurs par défaut.
.DESCRIPTION
    Cette fonction initialise la configuration du module avec des valeurs par défaut,
    puis tente de charger la configuration depuis un fichier et/ou des variables d'environnement.
.PARAMETER ConfigPath
    Chemin du fichier de configuration à charger. Si non spécifié, utilise le chemin par défaut.
.PARAMETER EnvPrefix
    Préfixe des variables d'environnement à considérer. Si non spécifié, utilise le préfixe par défaut.
.PARAMETER SkipFileLoad
    Si spécifié, ne tente pas de charger la configuration depuis un fichier.
.PARAMETER SkipEnvLoad
    Si spécifié, ne tente pas de charger la configuration depuis des variables d'environnement.
.PARAMETER PassThru
    Si spécifié, retourne la configuration initialisée.
.EXAMPLE
    Initialize-ExtractedInfoConfiguration
    Initialise la configuration avec les valeurs par défaut et tente de charger depuis un fichier et des variables d'environnement.
.EXAMPLE
    Initialize-ExtractedInfoConfiguration -ConfigPath "custom-config.json" -SkipEnvLoad -PassThru
    Initialise la configuration, charge depuis le fichier spécifié, ignore les variables d'environnement et retourne la configuration.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-05-15
#>
function Initialize-ExtractedInfoConfiguration {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Position = 0)]
        [string]$ConfigPath = "",
        
        [Parameter(Position = 1)]
        [string]$EnvPrefix = "EXTRACTEDINFO_",
        
        [Parameter()]
        [switch]$SkipFileLoad,
        
        [Parameter()]
        [switch]$SkipEnvLoad,
        
        [Parameter()]
        [switch]$PassThru
    )
    
    try {
        # Définir les valeurs par défaut
        $defaultConfig = @{
            # Configuration générale
            DefaultSerializationFormat = "Json"
            DefaultValidationEnabled   = $true
            DefaultConfidenceThreshold = 75
            DefaultLanguage            = "fr"
            
            # Options avancées
            AdvancedOptions = @{
                # Options de performance
                Performance = @{
                    EnableParallelProcessing = $false
                    MaxParallelJobs          = 4
                    UseRunspacePools         = $false
                    MaxRunspaces             = 10
                    EnableCaching            = $true
                    CacheExpirationMinutes   = 60
                }
                
                # Options de journalisation
                Logging = @{
                    Enabled           = $true
                    Level             = "Info"  # Debug, Info, Warning, Error
                    LogToFile         = $false
                    LogFilePath       = "logs/extractedinfo.log"
                    MaxLogSizeMB      = 10
                    MaxLogFiles       = 5
                    IncludeTimestamp  = $true
                    IncludeSource     = $true
                    LogFormat         = "Text"  # Text, Json
                }
                
                # Options de validation
                Validation = @{
                    StrictMode                = $false
                    ValidateBeforeSerialization = $true
                    AutoCorrectInvalidValues  = $false
                    CustomValidationRulesPath = ""
                }
                
                # Options de sérialisation
                Serialization = @{
                    Compression            = "None"  # None, GZip, Deflate
                    IncludeTypeInformation = $true
                    MaxDepth               = 10
                    Formatting             = "Indented"  # Indented, None
                    DateTimeFormat         = "o"
                }
                
                # Options d'extraction
                Extraction = @{
                    DefaultExtractors      = @("Text", "StructuredData", "Media")
                    EnabledExtractors      = @("Text", "StructuredData", "Media")
                    ExtractorTimeout       = 30  # secondes
                    MaxExtractorRetries    = 3
                    ExtractorRetryDelay    = 5   # secondes
                }
                
                # Options de stockage
                Storage = @{
                    DefaultStorageProvider = "FileSystem"
                    FileSystemStoragePath  = "data/extractedinfo"
                    DatabaseConnectionString = ""
                    CloudStorageProvider   = "None"  # None, Azure, AWS, GCP
                    CloudStorageConfig     = @{}
                }
            }
        }
        
        # Initialiser la configuration avec les valeurs par défaut
        $script:ModuleData.Config = $defaultConfig.Clone()
        
        Write-Verbose "Configuration initialisée avec les valeurs par défaut"
        
        # Déterminer le chemin du fichier de configuration par défaut si non spécifié
        if ([string]::IsNullOrEmpty($ConfigPath)) {
            $ConfigPath = Join-Path -Path $script:ModuleRoot -ChildPath "config.json"
        }
        
        # Charger la configuration depuis un fichier si demandé
        if (-not $SkipFileLoad -and (Test-Path -Path $ConfigPath -PathType Leaf)) {
            try {
                Import-ExtractedInfoConfiguration -Path $ConfigPath -Merge
                Write-Verbose "Configuration chargée depuis le fichier $ConfigPath"
            }
            catch {
                Write-Warning "Erreur lors du chargement de la configuration depuis le fichier: $_"
            }
        }
        
        # Charger la configuration depuis les variables d'environnement si demandé
        if (-not $SkipEnvLoad) {
            try {
                Import-ExtractedInfoConfigurationFromEnv -Prefix $EnvPrefix -Merge
                Write-Verbose "Configuration chargée depuis les variables d'environnement"
            }
            catch {
                Write-Warning "Erreur lors du chargement de la configuration depuis les variables d'environnement: $_"
            }
        }
        
        # Ajouter un timestamp d'initialisation
        $script:ModuleData.Config["_InitializedAt"] = [datetime]::Now.ToString("o")
        
        # Retourner la configuration si PassThru est spécifié
        if ($PassThru) {
            return $script:ModuleData.Config
        }
    }
    catch {
        Write-Error "Erreur lors de l'initialisation de la configuration: $_"
        return $null
    }
}
