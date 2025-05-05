<#
.SYNOPSIS
    Module de gestion des retours d'information pour le Process Manager.

.DESCRIPTION
    Ce module fournit des fonctions pour gÃ©rer les retours d'information
    dans le Process Manager, y compris les erreurs, avertissements, informations et succÃ¨s.

.NOTES
    Version: 1.0.0
    Auteur: Process Manager Team
    Date de crÃ©ation: 2025-05-15
#>

# DÃ©finition des types de retours d'information
enum FeedbackType {
    Error       # Erreurs critiques qui empÃªchent l'exÃ©cution normale
    Warning     # Avertissements qui n'empÃªchent pas l'exÃ©cution mais nÃ©cessitent attention
    Information # Informations gÃ©nÃ©rales sur le dÃ©roulement des opÃ©rations
    Success     # Notifications de succÃ¨s d'une opÃ©ration
    Debug       # Informations dÃ©taillÃ©es pour le dÃ©bogage
    Verbose     # Informations trÃ¨s dÃ©taillÃ©es pour le diagnostic
}

# DÃ©finition des niveaux de verbositÃ©
enum VerbosityLevel {
    None = 0  # Aucun message (silencieux)
    Minimal = 1  # Uniquement les erreurs critiques
    Normal = 2  # Erreurs et avertissements
    Detailed = 3  # Erreurs, avertissements et informations importantes
    Full = 4  # Tous les messages, y compris les succÃ¨s
    Debug = 5  # Tous les messages, y compris les messages de dÃ©bogage
}

# Structure de donnÃ©es pour les messages de feedback
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

    # MÃ©thode pour obtenir la sÃ©vÃ©ritÃ© par dÃ©faut en fonction du type
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

    # MÃ©thode pour obtenir le niveau de verbositÃ© par dÃ©faut en fonction du type
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

    # MÃ©thode pour convertir le message en chaÃ®ne formatÃ©e
    [string] ToString() {
        return "[$($this.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))] [$($this.Source)] [$($this.Type)] $($this.Message)"
    }

    # MÃ©thode pour convertir le message en objet JSON
    [string] ToJson() {
        return ConvertTo-Json -InputObject $this -Depth 3
    }

    # MÃ©thode pour vÃ©rifier si le message doit Ãªtre affichÃ© selon le niveau de verbositÃ©
    [bool] ShouldDisplay([VerbosityLevel]$CurrentVerbosity) {
        return [int]$CurrentVerbosity -ge [int]$this.MinimumVerbosity
    }
}

# MÃ©canismes de filtrage des messages
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

    # Constructeur par dÃ©faut
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

    # MÃ©thode pour vÃ©rifier si un message passe le filtre
    [bool] PassesFilter([FeedbackMessage]$Message) {
        # VÃ©rifier le type
        if ($this.IncludedTypes.Count -gt 0 -and $this.IncludedTypes -notcontains $Message.Type) {
            return $false
        }

        if ($this.ExcludedTypes -contains $Message.Type) {
            return $false
        }

        # VÃ©rifier la source
        if ($this.IncludedSources.Count -gt 0 -and $this.IncludedSources -notcontains $Message.Source) {
            return $false
        }

        if ($this.ExcludedSources -contains $Message.Source) {
            return $false
        }

        # VÃ©rifier la sÃ©vÃ©ritÃ©
        if ($Message.Severity -lt $this.MinimumSeverity -or $Message.Severity -gt $this.MaximumSeverity) {
            return $false
        }

        # VÃ©rifier l'horodatage
        if ($Message.Timestamp -lt $this.StartTime -or $Message.Timestamp -gt $this.EndTime) {
            return $false
        }

        # Appliquer le filtre personnalisÃ©
        return & $this.CustomFilter $Message
    }

    # MÃ©thode pour crÃ©er un filtre qui n'inclut que certains types
    static [FeedbackFilter] ForTypes([FeedbackType[]]$Types) {
        $filter = [FeedbackFilter]::new()
        $filter.IncludedTypes = $Types
        return $filter
    }

    # MÃ©thode pour crÃ©er un filtre qui n'inclut que certaines sources
    static [FeedbackFilter] ForSources([string[]]$Sources) {
        $filter = [FeedbackFilter]::new()
        $filter.IncludedSources = $Sources
        return $filter
    }

    # MÃ©thode pour crÃ©er un filtre basÃ© sur la sÃ©vÃ©ritÃ©
    static [FeedbackFilter] ForSeverity([int]$MinimumSeverity, [int]$MaximumSeverity) {
        $filter = [FeedbackFilter]::new()
        $filter.MinimumSeverity = $MinimumSeverity
        $filter.MaximumSeverity = $MaximumSeverity
        return $filter
    }

    # MÃ©thode pour crÃ©er un filtre basÃ© sur une pÃ©riode de temps
    static [FeedbackFilter] ForTimeRange([datetime]$StartTime, [datetime]$EndTime) {
        $filter = [FeedbackFilter]::new()
        $filter.StartTime = $StartTime
        $filter.EndTime = $EndTime
        return $filter
    }

    # MÃ©thode pour crÃ©er un filtre personnalisÃ©
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
        # CrÃ©er le message de feedback
        $feedbackMessage = $null

        if ($Severity -lt 0) {
            $feedbackMessage = [FeedbackMessage]::new($Type, $Message)
        } else {
            $feedbackMessage = [FeedbackMessage]::new($Type, $Message, $Source, $Severity, $Data, $MinimumVerbosity)
        }

        # Ajouter Ã  l'historique si demandÃ©
        if (-not $NoHistory) {
            Add-FeedbackToHistory -Message $feedbackMessage
        }

        # Envoyer aux canaux de sortie si demandÃ©
        if (-not $NoOutput) {
            Send-FeedbackToChannels -Message $feedbackMessage
        }

        # Retourner le message si demandÃ©
        if ($PassThru) {
            return $feedbackMessage
        }
    } catch {
        # En cas d'erreur, utiliser Write-Error pour ne pas crÃ©er de boucle infinie
        Write-Error "Erreur lors de l'envoi du feedback : $_"
    }
}

# Fonctions spÃ©cifiques par type de feedback
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

# Fonctions de gestion de la verbositÃ©
function Set-ProcessManagerVerbosity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [VerbosityLevel]$Level
    )

    $script:DefaultVerbosityLevel = $Level
    Send-ProcessManagerInformation -Message "Niveau de verbositÃ© dÃ©fini Ã  $Level" -MinimumVerbosity $Level
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

    # Ajouter le message Ã  l'historique
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

    # VÃ©rifier si le message doit Ãªtre affichÃ© selon le niveau de verbositÃ©
    if (-not $Message.ShouldDisplay($script:DefaultVerbosityLevel)) {
        return
    }

    # Si aucun canal n'est dÃ©fini, utiliser la sortie console par dÃ©faut
    if ($script:FeedbackChannels.Count -eq 0) {
        Write-FeedbackToConsole -Message $Message
    } else {
        # Envoyer le message Ã  tous les canaux enregistrÃ©s
        foreach ($channel in $script:FeedbackChannels) {
            try {
                & $channel $Message
            } catch {
                # Utiliser Write-Error pour Ã©viter une boucle infinie
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

    # DÃ©terminer la couleur en fonction du type
    $color = switch ($Message.Type) {
        "Error" { "Red" }
        "Warning" { "Yellow" }
        "Information" { "White" }
        "Success" { "Green" }
        "Debug" { "Cyan" }
        "Verbose" { "Gray" }
        default { "White" }
    }

    # Ã‰crire le message dans la console
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
