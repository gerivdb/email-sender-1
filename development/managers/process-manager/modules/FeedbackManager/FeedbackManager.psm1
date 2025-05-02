<#
.SYNOPSIS
    Module de gestion des retours d'information pour le Process Manager.

.DESCRIPTION
    Ce module fournit des fonctions pour gérer les retours d'information
    dans le Process Manager, y compris les erreurs, avertissements, informations et succès.

.NOTES
    Version: 1.0.0
    Auteur: Process Manager Team
    Date de création: 2025-05-15
#>

# Définition des types de retours d'information
enum FeedbackType {
    Error       # Erreurs critiques qui empêchent l'exécution normale
    Warning     # Avertissements qui n'empêchent pas l'exécution mais nécessitent attention
    Information # Informations générales sur le déroulement des opérations
    Success     # Notifications de succès d'une opération
    Debug       # Informations détaillées pour le débogage
    Verbose     # Informations très détaillées pour le diagnostic
}

# Définition des niveaux de verbosité
enum VerbosityLevel {
    None = 0  # Aucun message (silencieux)
    Minimal = 1  # Uniquement les erreurs critiques
    Normal = 2  # Erreurs et avertissements
    Detailed = 3  # Erreurs, avertissements et informations importantes
    Full = 4  # Tous les messages, y compris les succès
    Debug = 5  # Tous les messages, y compris les messages de débogage
}

# Structure de données pour les messages de feedback
class FeedbackMessage {
    [FeedbackType]$Type
    [string]$Message
    [string]$Source
    [datetime]$Timestamp
    [int]$Severity
    [hashtable]$Data
    [string]$CorrelationId
    [VerbosityLevel]$MinimumVerbosity

    # Constructeur simple
    FeedbackMessage([FeedbackType]$Type, [string]$Message) {
        $this.Type = $Type
        $this.Message = $Message
        $this.Timestamp = Get-Date
        $this.Source = "ProcessManager"
        $this.Severity = $this.GetDefaultSeverity($Type)
        $this.Data = @{}
        $this.CorrelationId = [guid]::NewGuid().ToString()
        $this.MinimumVerbosity = $this.GetDefaultVerbosity($Type)
    }

    # Constructeur complet
    FeedbackMessage([FeedbackType]$Type, [string]$Message, [string]$Source, [int]$Severity, [hashtable]$Data, [VerbosityLevel]$MinimumVerbosity) {
        $this.Type = $Type
        $this.Message = $Message
        $this.Timestamp = Get-Date
        $this.Source = $Source
        $this.Severity = $Severity
        $this.Data = $Data
        $this.CorrelationId = [guid]::NewGuid().ToString()
        $this.MinimumVerbosity = $MinimumVerbosity
    }

    # Méthode pour obtenir la sévérité par défaut en fonction du type
    hidden [int] GetDefaultSeverity([FeedbackType]$Type) {
        switch ($Type) {
            ([FeedbackType]::Error) { return 1 }
            ([FeedbackType]::Warning) { return 2 }
            ([FeedbackType]::Information) { return 3 }
            ([FeedbackType]::Success) { return 3 }
            ([FeedbackType]::Debug) { return 4 }
            ([FeedbackType]::Verbose) { return 5 }
            default { return 3 }
        }
    }

    # Méthode pour obtenir le niveau de verbosité par défaut en fonction du type
    hidden [VerbosityLevel] GetDefaultVerbosity([FeedbackType]$Type) {
        switch ($Type) {
            ([FeedbackType]::Error) { return [VerbosityLevel]::Minimal }
            ([FeedbackType]::Warning) { return [VerbosityLevel]::Normal }
            ([FeedbackType]::Information) { return [VerbosityLevel]::Detailed }
            ([FeedbackType]::Success) { return [VerbosityLevel]::Full }
            ([FeedbackType]::Debug) { return [VerbosityLevel]::Debug }
            ([FeedbackType]::Verbose) { return [VerbosityLevel]::Debug }
            default { return [VerbosityLevel]::Normal }
        }
    }

    # Méthode pour convertir le message en chaîne formatée
    [string] ToString() {
        return "[$($this.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))] [$($this.Source)] [$($this.Type)] $($this.Message)"
    }

    # Méthode pour convertir le message en objet JSON
    [string] ToJson() {
        return ConvertTo-Json -InputObject $this -Depth 3
    }

    # Méthode pour vérifier si le message doit être affiché selon le niveau de verbosité
    [bool] ShouldDisplay([VerbosityLevel]$CurrentVerbosity) {
        return [int]$CurrentVerbosity -ge [int]$this.MinimumVerbosity
    }
}

# Mécanismes de filtrage des messages
class FeedbackFilter {
    [FeedbackType[]]$IncludedTypes
    [FeedbackType[]]$ExcludedTypes
    [string[]]$IncludedSources
    [string[]]$ExcludedSources
    [int]$MinimumSeverity
    [int]$MaximumSeverity
    [datetime]$StartTime
    [datetime]$EndTime
    [scriptblock]$CustomFilter

    # Constructeur par défaut
    FeedbackFilter() {
        $this.IncludedTypes = @([FeedbackType]::Error, [FeedbackType]::Warning, [FeedbackType]::Information, [FeedbackType]::Success)
        $this.ExcludedTypes = @()
        $this.IncludedSources = @()
        $this.ExcludedSources = @()
        $this.MinimumSeverity = 0
        $this.MaximumSeverity = [int]::MaxValue
        $this.StartTime = [datetime]::MinValue
        $this.EndTime = [datetime]::MaxValue
        $this.CustomFilter = { param($message) return $true }
    }

    # Méthode pour vérifier si un message passe le filtre
    [bool] PassesFilter([FeedbackMessage]$Message) {
        # Vérifier le type
        if ($this.IncludedTypes.Count -gt 0 -and $this.IncludedTypes -notcontains $Message.Type) {
            return $false
        }

        if ($this.ExcludedTypes -contains $Message.Type) {
            return $false
        }

        # Vérifier la source
        if ($this.IncludedSources.Count -gt 0 -and $this.IncludedSources -notcontains $Message.Source) {
            return $false
        }

        if ($this.ExcludedSources -contains $Message.Source) {
            return $false
        }

        # Vérifier la sévérité
        if ($Message.Severity -lt $this.MinimumSeverity -or $Message.Severity -gt $this.MaximumSeverity) {
            return $false
        }

        # Vérifier l'horodatage
        if ($Message.Timestamp -lt $this.StartTime -or $Message.Timestamp -gt $this.EndTime) {
            return $false
        }

        # Appliquer le filtre personnalisé
        return & $this.CustomFilter $Message
    }

    # Méthode pour créer un filtre qui n'inclut que certains types
    static [FeedbackFilter] ForTypes([FeedbackType[]]$Types) {
        $filter = [FeedbackFilter]::new()
        $filter.IncludedTypes = $Types
        return $filter
    }

    # Méthode pour créer un filtre qui n'inclut que certaines sources
    static [FeedbackFilter] ForSources([string[]]$Sources) {
        $filter = [FeedbackFilter]::new()
        $filter.IncludedSources = $Sources
        return $filter
    }

    # Méthode pour créer un filtre basé sur la sévérité
    static [FeedbackFilter] ForSeverity([int]$MinimumSeverity, [int]$MaximumSeverity) {
        $filter = [FeedbackFilter]::new()
        $filter.MinimumSeverity = $MinimumSeverity
        $filter.MaximumSeverity = $MaximumSeverity
        return $filter
    }

    # Méthode pour créer un filtre basé sur une période de temps
    static [FeedbackFilter] ForTimeRange([datetime]$StartTime, [datetime]$EndTime) {
        $filter = [FeedbackFilter]::new()
        $filter.StartTime = $StartTime
        $filter.EndTime = $EndTime
        return $filter
    }

    # Méthode pour créer un filtre personnalisé
    static [FeedbackFilter] Custom([scriptblock]$CustomFilter) {
        $filter = [FeedbackFilter]::new()
        $filter.CustomFilter = $CustomFilter
        return $filter
    }
}

# Variables globales du module
$script:DefaultVerbosityLevel = [VerbosityLevel]::Normal
$script:FeedbackHistory = @()
$script:FeedbackChannels = @()
$script:MaxHistorySize = 1000
$script:DefaultConfigPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent -Parent -Parent -Parent) -ChildPath "projet\config\managers\process-manager\feedback-manager.config.json"

# Fonction principale pour envoyer un feedback
function Send-ProcessManagerFeedback {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [FeedbackType]$Type,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = "ProcessManager",

        [Parameter(Mandatory = $false)]
        [int]$Severity = -1,

        [Parameter(Mandatory = $false)]
        [hashtable]$Data = @{},

        [Parameter(Mandatory = $false)]
        [VerbosityLevel]$MinimumVerbosity = [VerbosityLevel]::Normal,

        [Parameter(Mandatory = $false)]
        [switch]$NoOutput,

        [Parameter(Mandatory = $false)]
        [switch]$NoHistory,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    try {
        # Créer le message de feedback
        $feedbackMessage = $null

        if ($Severity -lt 0) {
            $feedbackMessage = [FeedbackMessage]::new($Type, $Message)
        } else {
            $feedbackMessage = [FeedbackMessage]::new($Type, $Message, $Source, $Severity, $Data, $MinimumVerbosity)
        }

        # Ajouter à l'historique si demandé
        if (-not $NoHistory) {
            Add-FeedbackToHistory -Message $feedbackMessage
        }

        # Envoyer aux canaux de sortie si demandé
        if (-not $NoOutput) {
            Send-FeedbackToChannels -Message $feedbackMessage
        }

        # Retourner le message si demandé
        if ($PassThru) {
            return $feedbackMessage
        }
    } catch {
        # En cas d'erreur, utiliser Write-Error pour ne pas créer de boucle infinie
        Write-Error "Erreur lors de l'envoi du feedback : $_"
    }
}

# Fonctions spécifiques par type de feedback
function Send-ProcessManagerError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = "ProcessManager",

        [Parameter(Mandatory = $false)]
        [int]$Severity = 1,

        [Parameter(Mandatory = $false)]
        [hashtable]$Data = @{},

        [Parameter(Mandatory = $false)]
        [VerbosityLevel]$MinimumVerbosity = [VerbosityLevel]::Minimal,

        [Parameter(Mandatory = $false)]
        [switch]$NoOutput,

        [Parameter(Mandatory = $false)]
        [switch]$NoHistory,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    $params = @{
        Type             = [FeedbackType]::Error
        Message          = $Message
        Source           = $Source
        Severity         = $Severity
        Data             = $Data
        MinimumVerbosity = $MinimumVerbosity
        NoOutput         = $NoOutput
        NoHistory        = $NoHistory
        PassThru         = $PassThru
    }

    return Send-ProcessManagerFeedback @params
}

function Send-ProcessManagerWarning {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = "ProcessManager",

        [Parameter(Mandatory = $false)]
        [int]$Severity = 2,

        [Parameter(Mandatory = $false)]
        [hashtable]$Data = @{},

        [Parameter(Mandatory = $false)]
        [VerbosityLevel]$MinimumVerbosity = [VerbosityLevel]::Normal,

        [Parameter(Mandatory = $false)]
        [switch]$NoOutput,

        [Parameter(Mandatory = $false)]
        [switch]$NoHistory,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    $params = @{
        Type             = [FeedbackType]::Warning
        Message          = $Message
        Source           = $Source
        Severity         = $Severity
        Data             = $Data
        MinimumVerbosity = $MinimumVerbosity
        NoOutput         = $NoOutput
        NoHistory        = $NoHistory
        PassThru         = $PassThru
    }

    return Send-ProcessManagerFeedback @params
}

function Send-ProcessManagerInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = "ProcessManager",

        [Parameter(Mandatory = $false)]
        [int]$Severity = 3,

        [Parameter(Mandatory = $false)]
        [hashtable]$Data = @{},

        [Parameter(Mandatory = $false)]
        [VerbosityLevel]$MinimumVerbosity = [VerbosityLevel]::Detailed,

        [Parameter(Mandatory = $false)]
        [switch]$NoOutput,

        [Parameter(Mandatory = $false)]
        [switch]$NoHistory,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    $params = @{
        Type             = [FeedbackType]::Information
        Message          = $Message
        Source           = $Source
        Severity         = $Severity
        Data             = $Data
        MinimumVerbosity = $MinimumVerbosity
        NoOutput         = $NoOutput
        NoHistory        = $NoHistory
        PassThru         = $PassThru
    }

    return Send-ProcessManagerFeedback @params
}

function Send-ProcessManagerSuccess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = "ProcessManager",

        [Parameter(Mandatory = $false)]
        [int]$Severity = 3,

        [Parameter(Mandatory = $false)]
        [hashtable]$Data = @{},

        [Parameter(Mandatory = $false)]
        [VerbosityLevel]$MinimumVerbosity = [VerbosityLevel]::Full,

        [Parameter(Mandatory = $false)]
        [switch]$NoOutput,

        [Parameter(Mandatory = $false)]
        [switch]$NoHistory,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    $params = @{
        Type             = [FeedbackType]::Success
        Message          = $Message
        Source           = $Source
        Severity         = $Severity
        Data             = $Data
        MinimumVerbosity = $MinimumVerbosity
        NoOutput         = $NoOutput
        NoHistory        = $NoHistory
        PassThru         = $PassThru
    }

    return Send-ProcessManagerFeedback @params
}

function Send-ProcessManagerDebug {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = "ProcessManager",

        [Parameter(Mandatory = $false)]
        [int]$Severity = 4,

        [Parameter(Mandatory = $false)]
        [hashtable]$Data = @{},

        [Parameter(Mandatory = $false)]
        [VerbosityLevel]$MinimumVerbosity = [VerbosityLevel]::Debug,

        [Parameter(Mandatory = $false)]
        [switch]$NoOutput,

        [Parameter(Mandatory = $false)]
        [switch]$NoHistory,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    $params = @{
        Type             = [FeedbackType]::Debug
        Message          = $Message
        Source           = $Source
        Severity         = $Severity
        Data             = $Data
        MinimumVerbosity = $MinimumVerbosity
        NoOutput         = $NoOutput
        NoHistory        = $NoHistory
        PassThru         = $PassThru
    }

    return Send-ProcessManagerFeedback @params
}

function Send-ProcessManagerVerbose {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = "ProcessManager",

        [Parameter(Mandatory = $false)]
        [int]$Severity = 5,

        [Parameter(Mandatory = $false)]
        [hashtable]$Data = @{},

        [Parameter(Mandatory = $false)]
        [VerbosityLevel]$MinimumVerbosity = [VerbosityLevel]::Debug,

        [Parameter(Mandatory = $false)]
        [switch]$NoOutput,

        [Parameter(Mandatory = $false)]
        [switch]$NoHistory,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    $params = @{
        Type             = [FeedbackType]::Verbose
        Message          = $Message
        Source           = $Source
        Severity         = $Severity
        Data             = $Data
        MinimumVerbosity = $MinimumVerbosity
        NoOutput         = $NoOutput
        NoHistory        = $NoHistory
        PassThru         = $PassThru
    }

    return Send-ProcessManagerFeedback @params
}

# Fonctions de gestion de la verbosité
function Set-ProcessManagerVerbosity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [VerbosityLevel]$Level
    )

    $script:DefaultVerbosityLevel = $Level
    Send-ProcessManagerInformation -Message "Niveau de verbosité défini à $Level" -MinimumVerbosity $Level
}

function Get-ProcessManagerVerbosity {
    [CmdletBinding()]
    param ()

    return $script:DefaultVerbosityLevel
}

# Fonctions internes pour la gestion de l'historique et des canaux
function Add-FeedbackToHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [FeedbackMessage]$Message
    )

    # Ajouter le message à l'historique
    $script:FeedbackHistory += $Message

    # Limiter la taille de l'historique
    if ($script:FeedbackHistory.Count -gt $script:MaxHistorySize) {
        $script:FeedbackHistory = $script:FeedbackHistory | Select-Object -Skip ($script:FeedbackHistory.Count - $script:MaxHistorySize)
    }
}

function Send-FeedbackToChannels {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [FeedbackMessage]$Message
    )

    # Vérifier si le message doit être affiché selon le niveau de verbosité
    if (-not $Message.ShouldDisplay($script:DefaultVerbosityLevel)) {
        return
    }

    # Si aucun canal n'est défini, utiliser la sortie console par défaut
    if ($script:FeedbackChannels.Count -eq 0) {
        Write-FeedbackToConsole -Message $Message
    } else {
        # Envoyer le message à tous les canaux enregistrés
        foreach ($channel in $script:FeedbackChannels) {
            try {
                & $channel $Message
            } catch {
                # Utiliser Write-Error pour éviter une boucle infinie
                Write-Error "Erreur lors de l'envoi du feedback au canal : $_"
            }
        }
    }
}

function Write-FeedbackToConsole {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [FeedbackMessage]$Message
    )

    # Déterminer la couleur en fonction du type
    $color = switch ($Message.Type) {
        "Error" { "Red" }
        "Warning" { "Yellow" }
        "Information" { "White" }
        "Success" { "Green" }
        "Debug" { "Cyan" }
        "Verbose" { "Gray" }
        default { "White" }
    }

    # Écrire le message dans la console
    Write-Host $Message.ToString() -ForegroundColor $color
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Send-ProcessManagerFeedback,
Send-ProcessManagerError,
Send-ProcessManagerWarning,
Send-ProcessManagerInformation,
Send-ProcessManagerSuccess,
Send-ProcessManagerDebug,
Send-ProcessManagerVerbose,
Set-ProcessManagerVerbosity,
Get-ProcessManagerVerbosity
