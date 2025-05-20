# Version minimale requise : PowerShell 5.1 pour le support des classes et des Runspace Pools
# Compatible avec PowerShell Desktop (Windows PowerShell) et Core (PowerShell 7+)
# Note: Certaines fonctionnalités de surveillance des ressources système peuvent nécessiter des privilèges d'administrateur
# pour accéder à toutes les métriques système, mais le module de base fonctionne sans privilèges élevés.
#Requires -Version 5.1
#Requires -PSEdition Desktop, Core
<#
.SYNOPSIS
    Module unifié de parallélisation pour PowerShell.

.DESCRIPTION
    Ce module fournit une interface standardisée pour la parallélisation des tâches
    dans PowerShell, avec une compatibilité entre PowerShell 5.1 et PowerShell 7+.
    Il offre des fonctionnalités avancées comme la gestion des ressources système,
    le throttling adaptatif, les files d'attente prioritaires et la gestion robuste des erreurs.

.NOTES
    Nom: UnifiedParallel
    Auteur: Augment Agent
    Version: 1.0
    Date de création: 2025-05-17
    Compatibilité: PowerShell 5.1 et PowerShell 7+

    Exigences minimales:
    - PowerShell 5.1 : Requis pour le support des classes .NET et des Runspace Pools
    - Compatible avec Windows PowerShell (Desktop) et PowerShell Core (7+)

    Raisons de la version minimale:
    - Les classes .NET ont été introduites dans PowerShell 5.0
    - Les Runspace Pools sont plus stables à partir de PowerShell 5.1
    - PowerShell 5.1 est largement déployé et disponible sur la plupart des systèmes Windows

    Différences de comportement entre PowerShell 5.1 et PowerShell 7+:
    - PowerShell 5.1 utilise les Runspace Pools pour la parallélisation
    - PowerShell 7+ peut utiliser ForEach-Object -Parallel pour une meilleure performance

.EXAMPLE
    # Exemple d'utilisation basique
    Import-Module UnifiedParallel
    $items = 1..10
    $results = Invoke-UnifiedParallel -ScriptBlock {
        param($item)
        # Traitement de l'élément
        return "Résultat: $item"
    } -InputObject $items -MaxThreads 4

.LINK
    https://github.com/PowerShell/PowerShell
#>

# Constantes du module
Set-Variable -Name 'DEFAULT_CONFIG_PATH' -Value (Join-Path -Path $PSScriptRoot -ChildPath "config/parallel_config.json") -Option Constant -Scope Script
Set-Variable -Name 'DEFAULT_LOG_PATH' -Value (Join-Path -Path $PSScriptRoot -ChildPath "logs") -Option Constant -Scope Script
Set-Variable -Name 'MAX_QUEUE_SIZE' -Value 10000 -Option Constant -Scope Script
Set-Variable -Name 'DEFAULT_TIMEOUT_SECONDS' -Value 300 -Option Constant -Scope Script
Set-Variable -Name 'MODULE_VERSION' -Value '1.1.0' -Option Constant -Scope Script

# Variables globales du module
# Note: Ce module est conçu pour fonctionner de manière autonome, sans dépendances externes.
# Les modules complémentaires (ResourceMonitor.psm1, BackpressureManager.psm1, etc.) seront chargés
# dynamiquement lorsqu'ils seront nécessaires, mais ne sont pas requis pour les fonctionnalités de base.

# Configuration du module - Stocke les paramètres de configuration chargés depuis le fichier JSON
$script:Config = $null

# Moniteur de ressources - Surveille l'utilisation CPU, mémoire, disque et réseau
$script:ResourceMonitor = $null

# Gestionnaire de backpressure - Contrôle la charge du système et limite les nouvelles tâches si nécessaire
$script:BackpressureManager = $null

# Gestionnaire de throttling - Ajuste dynamiquement le nombre de threads en fonction de la charge
$script:ThrottlingManager = $null

# État d'initialisation du module
$script:IsInitialized = $false

# Compteur de tâches pour générer des IDs uniques
$script:TaskCounter = 0

# Cache des pools de runspaces pour optimiser leur réutilisation
# Clé = hash de la configuration du pool, Valeur = objet contenant le pool et ses métadonnées
$script:RunspacePoolCache = @{}

# Cache des résultats pour les tableaux vides
# Clé = identifiant unique basé sur les paramètres, Valeur = objet résultat précalculé
$script:EmptyResultsCache = @{}

# Structures de données internes
class ParallelResult {
    [string]$Id
    [object]$Value
    [bool]$Success
    [System.Management.Automation.ErrorRecord]$Error
    [datetime]$StartTime
    [datetime]$EndTime
    [timespan]$Duration
    [int]$ThreadId
    [int]$RunspaceId
    [hashtable]$Metadata
    [object]$SyncRoot
    [int]$Priority
    [string]$Status
    [string]$TaskType
    [string]$CorrelationId
    [System.Collections.Generic.Dictionary[string, object]]$Tags

    ParallelResult() {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Success = $true
        $this.StartTime = [datetime]::Now
        $this.SyncRoot = [System.Object]::new()
        $this.Status = "Pending"
        $this.Priority = 1
        $this.TaskType = "Default"
        $this.Tags = [System.Collections.Generic.Dictionary[string, object]]::new()
    }

    ParallelResult([string]$id) {
        $this.Id = $id
        $this.Success = $true
        $this.StartTime = [datetime]::Now
        $this.SyncRoot = [System.Object]::new()
        $this.Status = "Pending"
        $this.Priority = 1
        $this.TaskType = "Default"
        $this.Tags = [System.Collections.Generic.Dictionary[string, object]]::new()
    }

    [void] Complete([object]$value) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.Value = $value
            $this.EndTime = [datetime]::Now
            $this.Duration = $this.EndTime - $this.StartTime
            $this.Status = "Completed"
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] MarkFailed([System.Management.Automation.ErrorRecord]$errorRecord) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.Success = $false
            $this.Error = $errorRecord
            $this.EndTime = [datetime]::Now
            $this.Duration = $this.EndTime - $this.StartTime
            $this.Status = "Failed"
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] AddTag([string]$key, [object]$value) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.Tags[$key] = $value
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] RemoveTag([string]$key) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.Tags.Remove($key)
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [object] GetTag([string]$key) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            if ($this.Tags.ContainsKey($key)) {
                return $this.Tags[$key]
            }
            return $null
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] SetMetadata([hashtable]$metadata) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.Metadata = $metadata.Clone()
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] UpdateMetadata([string]$key, [object]$value) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            if ($null -eq $this.Metadata) {
                $this.Metadata = @{}
            }
            $this.Metadata[$key] = $value
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] SetPriority([int]$priority) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.Priority = $priority
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] SetTaskType([string]$taskType) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.TaskType = $taskType
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] SetCorrelationId([string]$correlationId) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.CorrelationId = $correlationId
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [string] ToString() {
        return "[$($this.Status)] ID: $($this.Id), Success: $($this.Success), Duration: $($this.Duration.TotalMilliseconds) ms"
    }
}

class ParallelErrorInfo {
    [string]$Id
    [System.Management.Automation.ErrorRecord]$Error
    [string]$Category
    [int]$Severity
    [bool]$IsRetryable
    [int]$RetryCount
    [string]$Source
    [hashtable]$Context
    [object]$SyncRoot
    [datetime]$Timestamp
    [string]$CorrelationId
    [string]$ErrorCode
    [System.Collections.Generic.Dictionary[string, object]]$Tags

    ParallelErrorInfo([System.Management.Automation.ErrorRecord]$errorRecord) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Error = $errorRecord
        $this.Category = "Unknown"
        $this.Severity = 1
        $this.IsRetryable = $false
        $this.RetryCount = 0
        $this.SyncRoot = [System.Object]::new()
        $this.Timestamp = [datetime]::Now
        $this.Tags = [System.Collections.Generic.Dictionary[string, object]]::new()

        # Essayer d'extraire un code d'erreur
        if ($errorRecord.Exception -is [System.Management.Automation.RuntimeException]) {
            $this.ErrorCode = "Runtime"
        } elseif ($errorRecord.Exception -is [System.IO.IOException]) {
            $this.ErrorCode = "IO"
        } elseif ($errorRecord.Exception -is [System.Net.WebException]) {
            $this.ErrorCode = "Network"
        } elseif ($errorRecord.Exception -is [System.ArgumentException]) {
            $this.ErrorCode = "Argument"
        } else {
            $this.ErrorCode = "General"
        }
    }

    [void] IncrementRetryCount() {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.RetryCount++
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] SetRetryable([bool]$isRetryable) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.IsRetryable = $isRetryable
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] SetCategory([string]$category) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.Category = $category
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] SetSeverity([int]$severity) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.Severity = $severity
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] SetSource([string]$source) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.Source = $source
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] SetContext([hashtable]$context) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.Context = $context.Clone()
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] UpdateContext([string]$key, [object]$value) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            if ($null -eq $this.Context) {
                $this.Context = @{}
            }
            $this.Context[$key] = $value
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] SetCorrelationId([string]$correlationId) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.CorrelationId = $correlationId
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] AddTag([string]$key, [object]$value) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.Tags[$key] = $value
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] RemoveTag([string]$key) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.Tags.Remove($key)
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [object] GetTag([string]$key) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            if ($this.Tags.ContainsKey($key)) {
                return $this.Tags[$key]
            }
            return $null
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [string] ToString() {
        return "[$($this.Category)] [$($this.ErrorCode)] $($this.Error.Exception.Message) | Retries: $($this.RetryCount)"
    }
}

class ParallelMetrics {
    [int]$TotalTasks
    [int]$CompletedTasks
    [int]$FailedTasks
    [int]$ActiveThreads
    [int]$MaxThreadsUsed
    [timespan]$TotalDuration
    [timespan]$AverageDuration
    [timespan]$MinDuration
    [timespan]$MaxDuration
    [hashtable]$ResourceUsage
    [System.Collections.Generic.List[double]]$ThreadEfficiency
    [object]$SyncRoot
    [datetime]$StartTime
    [datetime]$EndTime
    [System.Collections.Generic.Dictionary[string, object]]$CustomMetrics
    [System.Collections.Generic.Dictionary[int, int]]$ThreadDistribution
    [System.Collections.Generic.Dictionary[string, int]]$StatusDistribution
    [System.Collections.Generic.Dictionary[string, timespan]]$TaskTypePerformance

    ParallelMetrics() {
        $this.TotalTasks = 0
        $this.CompletedTasks = 0
        $this.FailedTasks = 0
        $this.ActiveThreads = 0
        $this.MaxThreadsUsed = 0
        $this.TotalDuration = [timespan]::Zero
        $this.ResourceUsage = @{}
        $this.ThreadEfficiency = [System.Collections.Generic.List[double]]::new()
        $this.SyncRoot = [System.Object]::new()
        $this.StartTime = [datetime]::Now
        $this.CustomMetrics = [System.Collections.Generic.Dictionary[string, object]]::new()
        $this.ThreadDistribution = [System.Collections.Generic.Dictionary[int, int]]::new()
        $this.StatusDistribution = [System.Collections.Generic.Dictionary[string, int]]::new()
        $this.TaskTypePerformance = [System.Collections.Generic.Dictionary[string, timespan]]::new()
    }

    [void] UpdateFromResults([System.Collections.Generic.List[ParallelResult]]$results) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.TotalTasks = $results.Count
            $this.CompletedTasks = ($results | Where-Object { $_.Success }).Count
            $this.FailedTasks = ($results | Where-Object { -not $_.Success }).Count

            $durations = $results | Where-Object { $_.EndTime -gt [datetime]::MinValue } | ForEach-Object { $_.Duration }
            if ($durations -and $durations.Count -gt 0) {
                $this.TotalDuration = [timespan]::FromTicks(($durations | Measure-Object -Property Ticks -Sum).Sum)
                $this.AverageDuration = [timespan]::FromTicks(($durations | Measure-Object -Property Ticks -Average).Average)
                $this.MinDuration = [timespan]::FromTicks(($durations | Measure-Object -Property Ticks -Minimum).Minimum)
                $this.MaxDuration = [timespan]::FromTicks(($durations | Measure-Object -Property Ticks -Maximum).Maximum)
            }

            # Mettre à jour la distribution des threads
            $this.ThreadDistribution.Clear()
            foreach ($result in $results) {
                if ($result.ThreadId -gt 0) {
                    if ($this.ThreadDistribution.ContainsKey($result.ThreadId)) {
                        $this.ThreadDistribution[$result.ThreadId]++
                    } else {
                        $this.ThreadDistribution[$result.ThreadId] = 1
                    }
                }
            }

            # Mettre à jour la distribution des statuts
            $this.StatusDistribution.Clear()
            foreach ($result in $results) {
                if (-not [string]::IsNullOrEmpty($result.Status)) {
                    if ($this.StatusDistribution.ContainsKey($result.Status)) {
                        $this.StatusDistribution[$result.Status]++
                    } else {
                        $this.StatusDistribution[$result.Status] = 1
                    }
                }
            }

            # Mettre à jour les performances par type de tâche
            $this.TaskTypePerformance.Clear()
            $taskTypes = $results | Group-Object -Property TaskType
            foreach ($taskType in $taskTypes) {
                if (-not [string]::IsNullOrEmpty($taskType.Name)) {
                    $typeDurations = $taskType.Group | Where-Object { $_.EndTime -gt [datetime]::MinValue } | ForEach-Object { $_.Duration }
                    if ($typeDurations -and $typeDurations.Count -gt 0) {
                        $avgDuration = [timespan]::FromTicks(($typeDurations | Measure-Object -Property Ticks -Average).Average)
                        $this.TaskTypePerformance[$taskType.Name] = $avgDuration
                    }
                }
            }

            # Mettre à jour l'heure de fin
            $this.EndTime = [datetime]::Now
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] AddCustomMetric([string]$name, [object]$value) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.CustomMetrics[$name] = $value
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] RemoveCustomMetric([string]$name) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.CustomMetrics.Remove($name)
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [object] GetCustomMetric([string]$name) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            if ($this.CustomMetrics.ContainsKey($name)) {
                return $this.CustomMetrics[$name]
            }
            return $null
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] UpdateResourceUsage([string]$resource, [double]$usage) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.ResourceUsage[$resource] = $usage
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] AddThreadEfficiency([double]$efficiency) {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.ThreadEfficiency.Add($efficiency)
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] IncrementActiveThreads() {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $this.ActiveThreads++
            if ($this.ActiveThreads -gt $this.MaxThreadsUsed) {
                $this.MaxThreadsUsed = $this.ActiveThreads
            }
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [void] DecrementActiveThreads() {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            if ($this.ActiveThreads -gt 0) {
                $this.ActiveThreads--
            }
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [hashtable] GetSummary() {
        [System.Threading.Monitor]::Enter($this.SyncRoot)
        try {
            $summary = @{
                TotalTasks          = $this.TotalTasks
                CompletedTasks      = $this.CompletedTasks
                FailedTasks         = $this.FailedTasks
                SuccessRate         = if ($this.TotalTasks -gt 0) { [Math]::Round(($this.CompletedTasks / $this.TotalTasks) * 100, 2) } else { 0 }
                TotalDuration       = $this.TotalDuration
                AverageDuration     = $this.AverageDuration
                MinDuration         = $this.MinDuration
                MaxDuration         = $this.MaxDuration
                MaxThreadsUsed      = $this.MaxThreadsUsed
                ThreadDistribution  = $this.ThreadDistribution
                StatusDistribution  = $this.StatusDistribution
                TaskTypePerformance = $this.TaskTypePerformance
                StartTime           = $this.StartTime
                EndTime             = $this.EndTime
                ElapsedTime         = if ($this.EndTime -gt [datetime]::MinValue) { $this.EndTime - $this.StartTime } else { [timespan]::Zero }
            }
            return $summary
        } finally {
            [System.Threading.Monitor]::Exit($this.SyncRoot)
        }
    }

    [string] ToString() {
        $summary = $this.GetSummary()
        return "Tasks: $($summary.TotalTasks) total, $($summary.CompletedTasks) completed, $($summary.FailedTasks) failed, $($summary.SuccessRate)% success rate, Avg: $($summary.AverageDuration.TotalMilliseconds) ms"
    }
}

# Fonction d'initialisation du module
function Initialize-UnifiedParallel {
    <#
    .SYNOPSIS
        Initialise le module UnifiedParallel avec les paramètres spécifiés.

    .DESCRIPTION
        Cette fonction initialise le module UnifiedParallel en chargeant la configuration,
        en initialisant les gestionnaires de ressources, de backpressure et de throttling.

        Elle peut être configurée pour activer ou désactiver certaines fonctionnalités
        comme le backpressure (contrôle de flux) et le throttling (limitation dynamique).

    .PARAMETER ConfigPath
        Chemin vers le fichier de configuration JSON. Si non spécifié, utilise le chemin par défaut.

    .PARAMETER StartResourceMonitor
        Indique si le moniteur de ressources doit être démarré lors de l'initialisation.

    .PARAMETER Force
        Force la réinitialisation du module même s'il est déjà initialisé.

    .PARAMETER DefaultTimeout
        Timeout par défaut en secondes pour les opérations parallèles.

    .PARAMETER LogPath
        Chemin vers le répertoire où les logs seront stockés.

    .PARAMETER EnableBackpressure
        Active le mécanisme de backpressure qui permet de contrôler le flux des tâches
        en fonction de la charge du système. Si désactivé, aucune limitation ne sera appliquée.

    .PARAMETER EnableThrottling
        Active le mécanisme de throttling qui permet d'ajuster dynamiquement le nombre
        de threads en fonction de la charge du système. Si désactivé, le nombre de threads
        restera constant.

    .EXAMPLE
        Initialize-UnifiedParallel

        Initialise le module avec les paramètres par défaut.

    .EXAMPLE
        Initialize-UnifiedParallel -ConfigPath "C:\config\parallel_config.json" -StartResourceMonitor

        Initialise le module en chargeant la configuration depuis le fichier spécifié
        et en démarrant le moniteur de ressources.

    .EXAMPLE
        Initialize-UnifiedParallel -EnableBackpressure:$false -EnableThrottling:$false

        Initialise le module en désactivant les mécanismes de backpressure et de throttling.

    .OUTPUTS
        System.Management.Automation.PSObject

        Retourne l'objet de configuration du module.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le fichier de configuration JSON")]
        [string]$ConfigPath = $script:DEFAULT_CONFIG_PATH,

        [Parameter(Mandatory = $false, HelpMessage = "Démarrer le moniteur de ressources")]
        [switch]$StartResourceMonitor,

        [Parameter(Mandatory = $false, HelpMessage = "Forcer la réinitialisation du module")]
        [switch]$Force,

        [Parameter(Mandatory = $false, HelpMessage = "Timeout par défaut en secondes")]
        [int]$DefaultTimeout = $script:DEFAULT_TIMEOUT_SECONDS,

        [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le répertoire des logs")]
        [string]$LogPath = $script:DEFAULT_LOG_PATH,

        [Parameter(Mandatory = $false, HelpMessage = "Activer le mécanisme de backpressure")]
        [bool]$EnableBackpressure = $true,

        [Parameter(Mandatory = $false, HelpMessage = "Activer le mécanisme de throttling")]
        [bool]$EnableThrottling = $true
    )

    begin {
        Write-Verbose "Initialisation du module UnifiedParallel..."

        # Configurer l'encodage UTF-8 pour la console et les fichiers
        $encodingResult = Initialize-EncodingSettings -UseBOM $true -ConfigureConsole $true -ConfigureDefaultParameters $true -Force:$Force
        if ($encodingResult.Success) {
            Write-Verbose "Encodage UTF-8 configuré avec succès pour la console et les fichiers"
            if ($encodingResult.ConfiguredConsole) {
                Write-Verbose "Encodage de la console configuré avec succès"
            }
            if ($encodingResult.ConfiguredParameters) {
                Write-Verbose "Paramètres par défaut configurés avec succès pour l'encodage"
            }
        } else {
            Write-Warning "Impossible de configurer l'encodage UTF-8 pour la console et les fichiers"
            if ($encodingResult.Errors.Count -gt 0) {
                foreach ($error in $encodingResult.Errors) {
                    Write-Warning "Erreur d'encodage: $error"
                }
            }
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess("Module UnifiedParallel", "Initialiser")) {
            # Vérifier si le module est déjà initialisé
            if ((Get-ModuleInitialized) -and -not $Force) {
                Write-Verbose "Le module est déjà initialisé. Utilisez -Force pour réinitialiser."
                return (Get-ModuleConfig)
            }

            # Réinitialiser le compteur de tâches
            $script:TaskCounter = 0

            # Créer le répertoire de logs s'il n'existe pas
            if (-not (Test-Path -Path $LogPath -PathType Container)) {
                try {
                    $null = New-Item -Path $LogPath -ItemType Directory -Force
                    Write-Verbose "Répertoire de logs créé: $LogPath"
                } catch {
                    $errorParams = @{
                        Message        = "Impossible de créer le répertoire de logs"
                        Source         = "Initialize-UnifiedParallel"
                        ErrorRecord    = $_
                        Category       = [System.Management.Automation.ErrorCategory]::ResourceUnavailable
                        AdditionalInfo = @{
                            "LogPath" = $LogPath
                            "Action"  = "Création du répertoire de logs"
                        }
                    }
                    New-UnifiedError @errorParams -WriteError
                }
            }

            # Charger la configuration
            if (Test-Path -Path $ConfigPath) {
                try {
                    $script:Config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
                    Write-Verbose "Configuration chargée depuis $ConfigPath"

                    # Ajouter les paramètres supplémentaires à la configuration
                    $script:Config | Add-Member -NotePropertyName 'DefaultTimeout' -NotePropertyValue $DefaultTimeout -Force
                    $script:Config | Add-Member -NotePropertyName 'LogPath' -NotePropertyValue $LogPath -Force
                    $script:Config | Add-Member -NotePropertyName 'ModuleVersion' -NotePropertyValue $script:MODULE_VERSION -Force
                } catch {
                    $errorParams = @{
                        Message        = "Erreur lors du chargement de la configuration"
                        Source         = "Initialize-UnifiedParallel"
                        ErrorRecord    = $_
                        Category       = [System.Management.Automation.ErrorCategory]::InvalidData
                        AdditionalInfo = @{
                            "ConfigPath"     = $ConfigPath
                            "Action"         = "Chargement de la configuration"
                            "FallbackAction" = "Utilisation de la configuration par défaut"
                        }
                    }
                    New-UnifiedError @errorParams

                    Write-Warning "Utilisation de la configuration par défaut suite à une erreur de chargement"
                    # Utiliser la configuration par défaut
                    $script:Config = [PSCustomObject]@{
                        DefaultMaxThreads    = [Environment]::ProcessorCount
                        DefaultThrottleLimit = [Environment]::ProcessorCount + 2
                        DefaultTimeout       = $DefaultTimeout
                        LogPath              = $LogPath
                        ModuleVersion        = $script:MODULE_VERSION
                        ResourceThresholds   = @{
                            CPU     = 80
                            Memory  = 80
                            DiskIO  = 70
                            Network = 70
                        }
                        BackpressureSettings = @{
                            Enabled            = $true
                            QueueSizeWarning   = 100
                            QueueSizeCritical  = 500
                            RejectionThreshold = [Math]::Min(1000, $script:MAX_QUEUE_SIZE)
                        }
                        ErrorHandling        = @{
                            RetryCount              = 3
                            RetryDelay              = 1000
                            CircuitBreakerThreshold = 5
                        }
                        AdvancedSettings     = @{
                            EnableDynamicScaling    = $true
                            MinThreads              = 1
                            MaxThreads              = [Environment]::ProcessorCount * 2
                            ThreadIdleTimeoutMs     = 30000
                            EnablePrioritization    = $true
                            EnableMetricsCollection = $true
                        }
                    }
                }
            } else {
                Write-Verbose "Fichier de configuration non trouvé. Utilisation des valeurs par défaut."
                # Configuration par défaut
                $script:Config = [PSCustomObject]@{
                    DefaultMaxThreads    = [Environment]::ProcessorCount
                    DefaultThrottleLimit = [Environment]::ProcessorCount + 2
                    DefaultTimeout       = $DefaultTimeout
                    LogPath              = $LogPath
                    ModuleVersion        = $script:MODULE_VERSION
                    ResourceThresholds   = @{
                        CPU     = 80
                        Memory  = 80
                        DiskIO  = 70
                        Network = 70
                    }
                    BackpressureSettings = @{
                        Enabled            = $true
                        QueueSizeWarning   = 100
                        QueueSizeCritical  = 500
                        RejectionThreshold = [Math]::Min(1000, $script:MAX_QUEUE_SIZE)
                    }
                    ErrorHandling        = @{
                        RetryCount              = 3
                        RetryDelay              = 1000
                        CircuitBreakerThreshold = 5
                    }
                    AdvancedSettings     = @{
                        EnableDynamicScaling    = $true
                        MinThreads              = 1
                        MaxThreads              = [Environment]::ProcessorCount * 2
                        ThreadIdleTimeoutMs     = 30000
                        EnablePrioritization    = $true
                        EnableMetricsCollection = $true
                    }
                }
            }

            # Initialiser le moniteur de ressources si demandé
            if ($StartResourceMonitor) {
                # Cette fonction sera implémentée dans ResourceMonitor.psm1
                # Pour l'instant, on simule son comportement
                $script:ResourceMonitor = [PSCustomObject]@{
                    IsActive       = $true
                    StartTime      = Get-Date
                    Metrics        = @{}
                    WarningLevels  = $script:Config.ResourceThresholds
                    SamplingRateMs = 1000
                    History        = [System.Collections.ArrayList]::new()
                }
                Write-Verbose "Moniteur de ressources démarré"
            }

            # Mettre à jour la configuration avec les paramètres EnableBackpressure et EnableThrottling
            if ($script:Config.BackpressureSettings -is [PSCustomObject]) {
                $script:Config.BackpressureSettings.Enabled = $EnableBackpressure
            } elseif ($script:Config.BackpressureSettings -is [hashtable]) {
                $script:Config.BackpressureSettings['Enabled'] = $EnableBackpressure
            } else {
                # Créer la propriété si elle n'existe pas
                $script:Config | Add-Member -NotePropertyName 'BackpressureSettings' -NotePropertyValue @{
                    Enabled            = $EnableBackpressure
                    QueueSizeWarning   = 100
                    QueueSizeCritical  = 500
                    RejectionThreshold = [Math]::Min(1000, $script:MAX_QUEUE_SIZE)
                } -Force
            }

            if ($script:Config.AdvancedSettings -is [PSCustomObject]) {
                $script:Config.AdvancedSettings.EnableDynamicScaling = $EnableThrottling
            } elseif ($script:Config.AdvancedSettings -is [hashtable]) {
                $script:Config.AdvancedSettings['EnableDynamicScaling'] = $EnableThrottling
            } else {
                # Créer la propriété si elle n'existe pas
                $script:Config | Add-Member -NotePropertyName 'AdvancedSettings' -NotePropertyValue @{
                    EnableDynamicScaling    = $EnableThrottling
                    MinThreads              = 1
                    MaxThreads              = [Environment]::ProcessorCount * 2
                    ThreadIdleTimeoutMs     = 30000
                    EnablePrioritization    = $true
                    EnableMetricsCollection = $true
                } -Force
            }

            # Initialiser le gestionnaire de backpressure
            $script:BackpressureManager = [PSCustomObject]@{
                IsActive           = $EnableBackpressure -and $script:Config.BackpressureSettings.Enabled
                QueueSizeWarning   = $script:Config.BackpressureSettings.QueueSizeWarning
                QueueSizeCritical  = $script:Config.BackpressureSettings.QueueSizeCritical
                RejectionThreshold = $script:Config.BackpressureSettings.RejectionThreshold
                CurrentQueueSize   = 0
                RejectedTasks      = 0
                LastWarningTime    = [datetime]::MinValue
                Status             = "Normal" # Normal, Warning, Critical, Rejecting
            }
            Write-Verbose "Gestionnaire de backpressure initialisé (Activé: $($script:BackpressureManager.IsActive))"

            # Initialiser le gestionnaire de throttling
            $script:ThrottlingManager = [PSCustomObject]@{
                IsActive             = $EnableThrottling -and $script:Config.AdvancedSettings.EnableDynamicScaling
                MinThreads           = $script:Config.AdvancedSettings.MinThreads
                MaxThreads           = $script:Config.AdvancedSettings.MaxThreads
                CurrentThreadLimit   = $script:Config.DefaultMaxThreads
                LastAdjustmentTime   = [datetime]::Now
                AdjustmentIntervalMs = 5000
                ScalingFactor        = 1.0
                ThreadUtilization    = @{}
            }
            Write-Verbose "Gestionnaire de throttling initialisé (Activé: $($script:ThrottlingManager.IsActive))"

            # Marquer le module comme initialisé
            Set-ModuleInitialized -Value $true

            Write-Verbose "Module UnifiedParallel initialisé avec succès (version $($script:MODULE_VERSION))"
            return (Get-ModuleConfig)
        }
    }

    end {
        Write-Verbose "Initialisation du module UnifiedParallel terminée"
    }
}

# Fonction de nettoyage du module
function Clear-UnifiedParallel {
    <#
    .SYNOPSIS
        Nettoie les ressources utilisées par le module UnifiedParallel.

    .DESCRIPTION
        Cette fonction nettoie toutes les ressources utilisées par le module UnifiedParallel,
        y compris les pools de runspaces, les gestionnaires de ressources, et les variables globales.
        Elle permet de libérer la mémoire et de réinitialiser l'état du module.

        La fonction prend en charge ShouldProcess, ce qui permet d'utiliser -WhatIf et -Confirm
        pour contrôler son exécution.

    .PARAMETER KeepLogs
        Indique si les fichiers de log doivent être conservés lors du nettoyage.
        Par défaut, les logs sont supprimés.

    .EXAMPLE
        Clear-UnifiedParallel

        Nettoie toutes les ressources utilisées par le module UnifiedParallel.

    .EXAMPLE
        Clear-UnifiedParallel -KeepLogs

        Nettoie toutes les ressources utilisées par le module UnifiedParallel, mais conserve les fichiers de log.

    .EXAMPLE
        Clear-UnifiedParallel -WhatIf

        Affiche ce qui serait nettoyé sans effectuer le nettoyage.

    .OUTPUTS
        None

        Cette fonction ne retourne aucune valeur.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Conserver les fichiers de log lors du nettoyage")]
        [switch]$KeepLogs
    )

    begin {
        Write-Verbose "Nettoyage du module UnifiedParallel..."

        # Vérifier si le module est initialisé
        if (-not (Get-ModuleInitialized)) {
            Write-Verbose "Le module n'est pas initialisé. Rien à nettoyer."
            return
        }
    }

    process {
        if ($PSCmdlet.ShouldProcess("Module UnifiedParallel", "Nettoyer")) {
            # Arrêter le moniteur de ressources s'il est actif
            if ($script:ResourceMonitor -and $script:ResourceMonitor.IsActive) {
                # Cette fonction sera implémentée dans ResourceMonitor.psm1
                # Pour l'instant, on simule son comportement
                $script:ResourceMonitor.IsActive = $false
                Write-Verbose "Moniteur de ressources arrêté"

                # Sauvegarder les métriques dans un fichier de log si demandé
                $config = Get-ModuleConfig
                if (-not $KeepLogs -and $config -and $config.LogPath) {
                    $logFile = Join-Path -Path $config.LogPath -ChildPath "resource_metrics_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
                    try {
                        if ($script:ResourceMonitor.History -and $script:ResourceMonitor.History.Count -gt 0) {
                            $script:ResourceMonitor.History | ConvertTo-Json -Depth 3 | Out-File -FilePath $logFile -Encoding utf8
                            Write-Verbose "Métriques de ressources sauvegardées dans $logFile"
                        }
                    } catch {
                        Write-Warning "Impossible de sauvegarder les métriques de ressources: $_"
                    }
                }
            }

            # Désactiver le gestionnaire de backpressure s'il est actif
            if ($script:BackpressureManager -and $script:BackpressureManager.IsActive) {
                $script:BackpressureManager.IsActive = $false
                Write-Verbose "Gestionnaire de backpressure désactivé"
            }

            # Désactiver le gestionnaire de throttling s'il est actif
            if ($script:ThrottlingManager -and $script:ThrottlingManager.IsActive) {
                $script:ThrottlingManager.IsActive = $false
                Write-Verbose "Gestionnaire de throttling désactivé"
            }

            # Nettoyer le cache des pools de runspaces
            Clear-RunspacePoolCache -Force
            Write-Verbose "Cache des pools de runspaces nettoyé"

            # Réinitialiser les variables globales
            $script:Config = $null
            $script:ResourceMonitor = $null
            $script:BackpressureManager = $null
            $script:ThrottlingManager = $null
            $script:RunspacePoolCache = @{}
            $script:TaskCounter = 0
            Set-ModuleInitialized -Value $false

            Write-Verbose "Variables globales réinitialisées"

            # Forcer le garbage collector à libérer la mémoire
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            Write-Verbose "Garbage collection effectuée"
        }
    }

    end {
        Write-Verbose "Nettoyage du module UnifiedParallel terminé"
    }
}

# Fonctions d'aide internes

# Fonction de validation des paramètres
function Test-ParameterValid {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowNull()]
        [object]$Value,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet('NotNull', 'NotNullOrEmpty', 'GreaterThanZero', 'PositiveOrZero', 'ValidPath', 'ValidScriptBlock', 'ValidArray')]
        [string[]]$ValidationTypes = @('NotNull'),

        [Parameter(Mandatory = $false)]
        [string]$ParameterName = 'Parameter',

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure,

        [Parameter(Mandatory = $false)]
        [string]$CustomMessage
    )

    begin {
        $isValid = $true
        $errorMessage = $null
    }

    process {
        foreach ($validationType in $ValidationTypes) {
            switch ($validationType) {
                'NotNull' {
                    if ($null -eq $Value) {
                        $isValid = $false
                        $errorMessage = "Le paramètre '$ParameterName' ne peut pas être null."
                        break
                    }
                }
                'NotNullOrEmpty' {
                    if ([string]::IsNullOrEmpty($Value) -or [string]::IsNullOrWhiteSpace($Value)) {
                        $isValid = $false
                        $errorMessage = "Le paramètre '$ParameterName' ne peut pas être null, vide ou composé uniquement d'espaces."
                        break
                    }
                }
                'GreaterThanZero' {
                    if ($null -eq $Value -or $Value -le 0) {
                        $isValid = $false
                        $errorMessage = "Le paramètre '$ParameterName' doit être supérieur à zéro."
                        break
                    }
                }
                'PositiveOrZero' {
                    if ($null -eq $Value -or $Value -lt 0) {
                        $isValid = $false
                        $errorMessage = "Le paramètre '$ParameterName' doit être positif ou zéro."
                        break
                    }
                }
                'ValidPath' {
                    if ([string]::IsNullOrEmpty($Value) -or -not (Test-Path -Path $Value -IsValid)) {
                        $isValid = $false
                        $errorMessage = "Le paramètre '$ParameterName' doit être un chemin valide."
                        break
                    }
                }
                'ValidScriptBlock' {
                    if ($null -eq $Value -or $Value -isnot [scriptblock]) {
                        $isValid = $false
                        $errorMessage = "Le paramètre '$ParameterName' doit être un bloc de script valide."
                        break
                    }
                }
                'ValidArray' {
                    if ($null -eq $Value -or $Value -isnot [array] -or $Value.Count -eq 0) {
                        $isValid = $false
                        $errorMessage = "Le paramètre '$ParameterName' doit être un tableau non vide."
                        break
                    }
                }
            }

            if (-not $isValid) {
                break
            }
        }

        if (-not $isValid -and $ThrowOnFailure) {
            $exceptionMessage = if ($CustomMessage) { $CustomMessage } else { $errorMessage }
            throw [System.ArgumentException]::new($exceptionMessage, $ParameterName)
        }
    }

    end {
        return $isValid
    }
}

# Fonction de gestion des erreurs
function Write-ParallelError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet('Error', 'Warning', 'Debug', 'Verbose')]
        [string]$Level = 'Error',

        [Parameter(Mandatory = $false)]
        [string]$Source = 'UnifiedParallel',

        [Parameter(Mandatory = $false)]
        [string]$Context,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru,

        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )

    begin {
        $errorInfo = [ParallelErrorInfo]::new($ErrorRecord)
        $errorInfo.Source = $Source

        if ($Context) {
            $errorInfo.Context = @{ Context = $Context }
        }

        $formattedError = "[$Source] $($ErrorRecord.Exception.Message)"
        if ($Context) {
            $formattedError += " | Contexte: $Context"
        }

        $formattedError += "`nDétails: $($ErrorRecord.Exception.ToString())"
        $formattedError += "`nEmplacement: $($ErrorRecord.InvocationInfo.PositionMessage)"
    }

    process {
        if (-not $Silent) {
            switch ($Level) {
                'Error' {
                    Write-Error -Message $formattedError -ErrorId $errorInfo.Id -Category $ErrorRecord.CategoryInfo.Category
                }
                'Warning' {
                    Write-Warning -Message $formattedError
                }
                'Debug' {
                    Write-Debug -Message $formattedError
                }
                'Verbose' {
                    Write-Verbose -Message $formattedError
                }
            }
        }

        # Journaliser l'erreur si le logging est activé
        $config = Get-ModuleConfig
        if ($config -and $config.LogPath) {
            try {
                $logEntry = [PSCustomObject]@{
                    Timestamp  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
                    Level      = 'ERROR'
                    Source     = $Source
                    Context    = $Context
                    Message    = $ErrorRecord.Exception.Message
                    Details    = $ErrorRecord.Exception.ToString()
                    StackTrace = $ErrorRecord.ScriptStackTrace
                    ErrorId    = $errorInfo.Id
                    Category   = $ErrorRecord.CategoryInfo.Category
                }

                $logFile = Join-Path -Path $config.LogPath -ChildPath "errors_$(Get-Date -Format 'yyyyMMdd').json"
                $logEntry | ConvertTo-Json -Depth 3 | Out-File -FilePath $logFile -Encoding utf8 -Append
            } catch {
                # Éviter les erreurs en cascade lors de la journalisation
                Write-Verbose "Erreur lors de la journalisation: $_"
            }
        }
    }

    end {
        if ($PassThru) {
            return $errorInfo
        }
    }
}

# Fonction pour récupérer l'état d'initialisation du module
function Get-ModuleInitialized {
    <#
    .SYNOPSIS
        Récupère l'état d'initialisation du module UnifiedParallel.

    .DESCRIPTION
        Cette fonction permet de vérifier si le module UnifiedParallel a été initialisé
        via la fonction Initialize-UnifiedParallel. Elle retourne la valeur de la variable
        script $script:IsInitialized.

        L'état d'initialisation est important pour déterminer si les fonctionnalités
        du module sont disponibles et si les ressources nécessaires ont été allouées.
        De nombreuses fonctions du module vérifient cet état avant d'exécuter leurs
        opérations pour éviter des erreurs.

    .EXAMPLE
        Get-ModuleInitialized
        # Retourne $true si le module est initialisé, $false sinon

    .EXAMPLE
        if (Get-ModuleInitialized) {
            # Le module est initialisé, on peut utiliser ses fonctionnalités
            Invoke-UnifiedParallel -ScriptBlock { "Hello World" }
        } else {
            # Le module n'est pas initialisé, on doit l'initialiser d'abord
            Initialize-UnifiedParallel
        }

    .OUTPUTS
        System.Boolean

        Retourne $true si le module est initialisé, $false sinon.

    .NOTES
        Cette fonction est utilisée en interne par de nombreuses autres fonctions
        du module pour vérifier l'état d'initialisation avant d'exécuter leurs opérations.

        Si la fonction retourne $false, vous devez appeler Initialize-UnifiedParallel
        avant d'utiliser les fonctionnalités du module.

    .LINK
        Initialize-UnifiedParallel
        Set-ModuleInitialized
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return $script:IsInitialized
}

# Fonction pour définir l'état d'initialisation du module
function Set-ModuleInitialized {
    <#
    .SYNOPSIS
        Définit l'état d'initialisation du module UnifiedParallel.

    .DESCRIPTION
        Cette fonction permet de définir manuellement l'état d'initialisation du module UnifiedParallel.
        Elle modifie la valeur de la variable script $script:IsInitialized.

        ATTENTION: Cette fonction est principalement destinée à un usage interne ou pour des
        scénarios de test. L'utilisation incorrecte de cette fonction peut entraîner des
        comportements inattendus dans le module. Dans la plupart des cas, vous devriez
        utiliser Initialize-UnifiedParallel et Clear-UnifiedParallel pour gérer l'état
        d'initialisation du module.

    .PARAMETER Value
        Valeur booléenne indiquant si le module doit être considéré comme initialisé.
        - $true: Marque le module comme initialisé
        - $false: Marque le module comme non initialisé

    .EXAMPLE
        Set-ModuleInitialized -Value $true
        # Marque le module comme initialisé

    .EXAMPLE
        Set-ModuleInitialized -Value $false
        # Marque le module comme non initialisé

    .EXAMPLE
        # Scénario de test
        # Sauvegarder l'état actuel
        $originalState = Get-ModuleInitialized

        # Modifier l'état pour le test
        Set-ModuleInitialized -Value $true

        # Exécuter le test
        # ...

        # Restaurer l'état original
        Set-ModuleInitialized -Value $originalState

    .OUTPUTS
        System.Boolean

        Retourne la valeur qui a été définie.

    .NOTES
        Cette fonction modifie uniquement l'état d'initialisation du module sans
        effectuer les opérations d'initialisation ou de nettoyage normalement
        effectuées par Initialize-UnifiedParallel et Clear-UnifiedParallel.

        Utilisez cette fonction avec précaution, car elle peut entraîner des
        incohérences dans l'état du module si elle est mal utilisée.

    .LINK
        Get-ModuleInitialized
        Initialize-UnifiedParallel
        Clear-UnifiedParallel
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [bool]$Value
    )

    $script:IsInitialized = $Value
    return $Value
}

# Fonction pour récupérer la configuration du module
function Get-ModuleConfig {
    <#
    .SYNOPSIS
        Récupère la configuration du module UnifiedParallel.

    .DESCRIPTION
        Cette fonction permet d'accéder à la configuration actuelle du module UnifiedParallel.
        Elle retourne l'objet de configuration stocké dans la variable script $script:Config.
        Si le module n'est pas initialisé, elle retourne $null et affiche un avertissement.

        L'objet de configuration contient des paramètres tels que:
        - DefaultMaxThreads: Nombre maximum de threads par défaut
        - DefaultThrottleLimit: Limite de throttling par défaut
        - DefaultTimeout: Timeout par défaut en secondes
        - LogPath: Chemin vers le répertoire des logs
        - ModuleVersion: Version du module
        - ResourceThresholds: Seuils d'utilisation des ressources (CPU, mémoire, etc.)
        - BackpressureSettings: Paramètres de backpressure
        - ErrorHandling: Paramètres de gestion des erreurs

    .EXAMPLE
        $config = Get-ModuleConfig
        $config.DefaultMaxThreads
        # Affiche le nombre maximum de threads par défaut

    .EXAMPLE
        $config = Get-ModuleConfig
        if ($config) {
            Write-Host "Chemin des logs: $($config.LogPath)"
            Write-Host "Version du module: $($config.ModuleVersion)"
        }

    .EXAMPLE
        # Modifier temporairement la configuration
        $config = Get-ModuleConfig
        $originalMaxThreads = $config.DefaultMaxThreads
        $config.DefaultMaxThreads = 16
        Set-ModuleConfig -Value $config

        # Utiliser la nouvelle configuration
        # ...

        # Restaurer la configuration d'origine
        $config = Get-ModuleConfig
        $config.DefaultMaxThreads = $originalMaxThreads
        Set-ModuleConfig -Value $config

    .OUTPUTS
        System.Management.Automation.PSObject

        Un objet contenant la configuration du module, ou $null si le module n'est pas initialisé.

    .NOTES
        Cette fonction vérifie si le module est initialisé avant de retourner la configuration.
        Si le module n'est pas initialisé, elle affiche un avertissement et retourne $null.

        La modification directe de l'objet de configuration retourné par cette fonction
        n'affecte pas la configuration du module. Pour appliquer les modifications,
        vous devez utiliser Set-ModuleConfig.

    .LINK
        Initialize-UnifiedParallel
        Set-ModuleConfig
        Get-ModuleInitialized
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param()

    if (-not (Get-ModuleInitialized)) {
        Write-Warning "Le module n'est pas initialisé. Utilisez Initialize-UnifiedParallel pour initialiser le module."
        return $null
    }

    return $script:Config
}

# Fonction pour définir la configuration du module
function Set-ModuleConfig {
    <#
    .SYNOPSIS
        Définit la configuration du module UnifiedParallel.

    .DESCRIPTION
        Cette fonction permet de modifier la configuration du module UnifiedParallel.
        Elle remplace l'objet de configuration stocké dans la variable script $script:Config.

        ATTENTION: Cette fonction est principalement destinée à un usage interne ou pour
        des scénarios de test. L'utilisation incorrecte de cette fonction peut entraîner
        des comportements inattendus dans le module. Dans la plupart des cas, vous devriez
        utiliser Initialize-UnifiedParallel avec les paramètres appropriés pour configurer
        le module.

        La modification de la configuration peut affecter le comportement de toutes les
        fonctions du module qui utilisent cette configuration.

    .PARAMETER Value
        Objet de configuration à utiliser pour le module. Cet objet doit contenir
        toutes les propriétés nécessaires au bon fonctionnement du module, notamment:
        - DefaultMaxThreads: Nombre maximum de threads par défaut
        - DefaultThrottleLimit: Limite de throttling par défaut
        - DefaultTimeout: Timeout par défaut en secondes
        - LogPath: Chemin vers le répertoire des logs
        - ModuleVersion: Version du module
        - ResourceThresholds: Seuils d'utilisation des ressources
        - BackpressureSettings: Paramètres de backpressure
        - ErrorHandling: Paramètres de gestion des erreurs

    .EXAMPLE
        $config = Get-ModuleConfig
        $config.DefaultMaxThreads = 16
        Set-ModuleConfig -Value $config
        # Modifie le nombre maximum de threads par défaut

    .EXAMPLE
        # Modifier temporairement la configuration pour un test
        $config = Get-ModuleConfig
        $originalConfig = $config.PSObject.Copy()  # Créer une copie pour restauration

        # Modifier la configuration
        $config.DefaultTimeout = 120
        $config.BackpressureSettings.Enabled = $false
        Set-ModuleConfig -Value $config

        # Exécuter le test avec la nouvelle configuration
        # ...

        # Restaurer la configuration d'origine
        Set-ModuleConfig -Value $originalConfig

    .OUTPUTS
        System.Management.Automation.PSObject

        L'objet de configuration qui a été défini, ou $null si le module n'est pas initialisé.

    .NOTES
        Cette fonction vérifie si le module est initialisé avant de modifier la configuration.
        Si le module n'est pas initialisé, elle affiche un avertissement et retourne $null.

        Il est recommandé de créer une copie de la configuration actuelle avant de la modifier,
        afin de pouvoir la restaurer en cas de problème.

    .LINK
        Initialize-UnifiedParallel
        Get-ModuleConfig
        Get-ModuleInitialized
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [PSObject]$Value
    )

    if (-not (Get-ModuleInitialized)) {
        Write-Warning "Le module n'est pas initialisé. Utilisez Initialize-UnifiedParallel pour initialiser le module."
        return $null
    }

    $script:Config = $Value
    return $script:Config
}

# Fonction de logging
function Write-ParallelLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet('Information', 'Warning', 'Error', 'Debug', 'Verbose')]
        [string]$Level = 'Information',

        [Parameter(Mandatory = $false)]
        [string]$Source = 'UnifiedParallel',

        [Parameter(Mandatory = $false)]
        [hashtable]$Data,

        [Parameter(Mandatory = $false)]
        [switch]$NoConsole,

        [Parameter(Mandatory = $false)]
        [switch]$NoFile
    )

    begin {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        $logEntry = [PSCustomObject]@{
            Timestamp = $timestamp
            Level     = $Level.ToUpper()
            Source    = $Source
            Message   = $Message
            Data      = $Data
            ThreadId  = [System.Threading.Thread]::CurrentThread.ManagedThreadId
        }
    }

    process {
        # Afficher dans la console si demandé
        if (-not $NoConsole) {
            $consoleMessage = "[$timestamp] [$($Level.ToUpper())] [$Source] $Message"

            switch ($Level) {
                'Information' {
                    Write-Host $consoleMessage -ForegroundColor Cyan
                }
                'Warning' {
                    Write-Warning $consoleMessage
                }
                'Error' {
                    Write-Error $consoleMessage
                }
                'Debug' {
                    Write-Debug $consoleMessage
                }
                'Verbose' {
                    Write-Verbose $consoleMessage
                }
            }
        }

        # Journaliser dans un fichier si demandé et si la configuration est disponible
        $config = Get-ModuleConfig
        if (-not $NoFile -and $config -and $config.LogPath) {
            try {
                $logFile = Join-Path -Path $config.LogPath -ChildPath "parallel_$(Get-Date -Format 'yyyyMMdd').json"
                $logEntry | ConvertTo-Json -Depth 3 | Out-File -FilePath $logFile -Encoding utf8 -Append
            } catch {
                # Éviter les erreurs en cascade lors de la journalisation
                Write-Verbose "Erreur lors de la journalisation: $_"
            }
        }
    }
}

# Fonction de mesure des performances
function Measure-ExecutionTime {
    [CmdletBinding()]
    [OutputType([timespan])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [object[]]$ArgumentList,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru,

        [Parameter(Mandatory = $false)]
        [string]$Label,

        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )

    begin {
        $startTime = [datetime]::Now
        $result = $null
        $success = $false
        $errorRecord = $null
    }

    process {
        try {
            if ($ArgumentList) {
                $result = & $ScriptBlock @ArgumentList
            } else {
                $result = & $ScriptBlock
            }
            $success = $true
        } catch {
            $errorRecord = $_
            $success = $false
        } finally {
            $endTime = [datetime]::Now
            $duration = $endTime - $startTime
        }

        if (-not $Silent) {
            $labelText = if ($Label) { "[$Label] " } else { "" }
            if ($success) {
                Write-Verbose "$($labelText)Exécution terminée en $($duration.TotalMilliseconds) ms"
            } else {
                Write-Warning "$($labelText)Exécution échouée après $($duration.TotalMilliseconds) ms: $($errorRecord.Exception.Message)"
            }
        }
    }

    end {
        if ($PassThru) {
            [PSCustomObject]@{
                Duration  = $duration
                Result    = $result
                Success   = $success
                Error     = $errorRecord
                Label     = $Label
                StartTime = $startTime
                EndTime   = $endTime
            }
        } else {
            return $duration
        }
    }
}

# Fonction principale d'exécution parallèle
function Invoke-UnifiedParallel {
    <#
    .SYNOPSIS
        Exécute des tâches en parallèle sur une collection d'objets.

    .DESCRIPTION
        Cette fonction exécute un script block ou une commande en parallèle sur chaque élément
        d'une collection d'objets. Elle supporte différentes méthodes de parallélisation :
        - Runspace Pool (compatible PowerShell 5.1 et 7+)
        - ForEach-Object -Parallel (PowerShell 7+ uniquement)

        Elle offre de nombreuses options pour contrôler l'exécution parallèle, comme le nombre
        de threads, le timeout, la gestion des erreurs, etc.

    .PARAMETER ScriptBlock
        Script block à exécuter pour chaque élément. Le script block doit accepter un paramètre
        qui recevra l'élément courant.

        Exemple : { param($item) "Traitement de $item" }

    .PARAMETER InputObject
        Collection d'objets à traiter en parallèle. Chaque élément sera passé au script block.
        Ce paramètre accepte les entrées du pipeline.

    .PARAMETER MaxThreads
        Nombre maximum de threads à utiliser. Si 0, le nombre optimal est déterminé automatiquement
        en fonction du type de tâche et du nombre de processeurs.

        Par défaut : 0 (automatique)

    .PARAMETER ThrottleLimit
        Limite de throttling pour contrôler le nombre maximum de tâches en attente.
        Si 0, la valeur par défaut du module est utilisée.

        Par défaut : 0 (valeur du module)

    .PARAMETER TimeoutSeconds
        Nombre de secondes maximum pour l'exécution de toutes les tâches.
        Si 0, aucun timeout n'est appliqué.

        Par défaut : 0 (pas de timeout)

    .PARAMETER SharedVariables
        Table de hachage des variables à partager avec les runspaces.
        Clé = nom de la variable, Valeur = valeur de la variable.

        Exemple : @{ "Config" = $config; "Logger" = $logger }

    .PARAMETER TaskType
        Type de tâche à exécuter, utilisé pour optimiser le nombre de threads.
        - Default : Utilise les paramètres par défaut
        - CPU : Optimisé pour les tâches intensives en calcul
        - IO : Optimisé pour les tâches intensives en entrées/sorties
        - Mixed : Optimisé pour les tâches mixtes CPU/IO
        - LowPriority : Utilise moins de ressources
        - HighPriority : Utilise plus de ressources

        Par défaut : 'Default'

    .PARAMETER Priority
        Priorité de la tâche (0-3). Utilisé pour ajuster les ressources allouées.
        - 0 : Priorité très basse
        - 1 : Priorité normale
        - 2 : Priorité élevée
        - 3 : Priorité très élevée

        Par défaut : 1 (normale)

    .PARAMETER NoProgress
        Si spécifié, n'affiche pas de barre de progression.

        Par défaut : $false (affiche une barre de progression)

    .PARAMETER PassThru
        Si spécifié, retourne un objet détaillé avec les résultats et les métriques.
        Sinon, retourne uniquement la liste des résultats.

        Par défaut : $false (retourne uniquement les résultats)

    .PARAMETER Wait
        Si spécifié, attend que toutes les tâches soient terminées avant de retourner.
        Sinon, retourne immédiatement et les tâches continuent en arrière-plan.

        Par défaut : $false (ne pas attendre)

    .PARAMETER IgnoreErrors
        Si spécifié, les erreurs dans les tâches individuelles ne font pas échouer l'ensemble.
        Les erreurs sont toujours enregistrées dans les résultats.

        Par défaut : $false (les erreurs font échouer l'ensemble)

    .PARAMETER UseRunspacePool
        Si spécifié, utilise un pool de runspaces pour l'exécution parallèle.
        Cette méthode est compatible avec PowerShell 5.1 et 7+.

        Par défaut : $false (utilise ForEach-Object -Parallel si disponible)

    .PARAMETER UseForeachParallel
        Si spécifié, utilise ForEach-Object -Parallel pour l'exécution parallèle.
        Cette méthode n'est disponible qu'à partir de PowerShell 7.

        Par défaut : $false (déterminé automatiquement)

    .PARAMETER Command
        Nom de la commande à exécuter pour chaque élément.
        Ce paramètre est utilisé avec le jeu de paramètres 'Command'.

        Exemple : "Get-Process"

    .PARAMETER ArgumentList
        Table de hachage des arguments à passer à la commande.
        Ce paramètre est utilisé avec le jeu de paramètres 'Command'.

        Exemple : @{ "Name" = "powershell"; "ErrorAction" = "SilentlyContinue" }

    .PARAMETER ActivityName
        Nom de l'activité à afficher dans la barre de progression.

        Par défaut : "Traitement parallèle"

    .PARAMETER EnableBackpressure
        Si spécifié, active le mécanisme de backpressure pour éviter de surcharger le système.
        Le backpressure ralentit l'ajout de nouvelles tâches si le système est surchargé.

        Par défaut : $false (pas de backpressure)

    .PARAMETER EnableThrottling
        Si spécifié, active le mécanisme de throttling pour limiter le nombre de tâches simultanées.
        Le throttling limite le nombre de tâches en fonction des ressources disponibles.

        Par défaut : $false (pas de throttling)

    .PARAMETER EnableMetrics
        Si spécifié, collecte des métriques détaillées sur l'exécution parallèle.
        Ces métriques sont incluses dans les résultats si PassThru est spécifié.

        Par défaut : $false (pas de métriques)

    .PARAMETER LogPrefix
        Préfixe à ajouter aux messages de log.
        Utile pour identifier les logs de différentes exécutions parallèles.

        Par défaut : "" (pas de préfixe)

    .PARAMETER CleanupOnTimeout
        Si spécifié, nettoie les ressources (runspaces, etc.) en cas de timeout.
        Cela permet d'éviter les fuites de mémoire.

        Par défaut : $false (pas de nettoyage automatique)

    .PARAMETER SleepMilliseconds
        Nombre de millisecondes à attendre entre chaque vérification des runspaces.
        Une valeur plus élevée réduit l'utilisation du CPU mais augmente la latence.

        Par défaut : 50 ms

    .EXAMPLE
        $results = 1..10 | Invoke-UnifiedParallel -ScriptBlock { param($item) "Item: $item" }

        Exécute le script block sur les nombres de 1 à 10 en parallèle.

    .EXAMPLE
        $results = Invoke-UnifiedParallel -ScriptBlock { param($item) Get-Process -Id $item } -InputObject (1..10) -TaskType 'IO' -MaxThreads 8

        Exécute Get-Process pour chaque ID de processus en parallèle, avec 8 threads maximum.

    .EXAMPLE
        $results = Invoke-UnifiedParallel -Command "Get-Process" -ArgumentList @{ "Name" = "powershell" } -InputObject (1..5) -PassThru

        Exécute la commande Get-Process pour chaque élément et retourne des résultats détaillés.

    .OUTPUTS
        System.Collections.Generic.List[PSObject] ou PSObject

        Si PassThru est spécifié, retourne un objet avec les propriétés suivantes :
        - Results : Liste des résultats de chaque tâche
        - Errors : Liste des erreurs survenues
        - TotalItems : Nombre total d'éléments traités
        - ProcessedItems : Nombre d'éléments traités avec succès
        - Duration : Durée totale de l'exécution
        - StartTime : Heure de début de l'exécution
        - EndTime : Heure de fin de l'exécution
        - MaxThreads : Nombre maximum de threads utilisés
        - Metrics : Métriques détaillées (si EnableMetrics est spécifié)

        Sinon, retourne uniquement la liste des résultats.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ScriptBlock')]
    [OutputType([System.Collections.Generic.List[PSObject]], [PSObject])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'ScriptBlock', HelpMessage = "Script block à exécuter pour chaque élément")]
        [ValidateNotNull()]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ScriptBlock', HelpMessage = "Collection d'objets à traiter en parallèle")]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Command', HelpMessage = "Collection d'objets à traiter en parallèle")]
        [AllowEmptyCollection()]
        [object[]]$InputObject,

        [Parameter(Mandatory = $false, HelpMessage = "Nombre maximum de threads à utiliser (0 = automatique)")]
        [ValidateRange(0, 1024)]
        [int]$MaxThreads = 0,

        [Parameter(Mandatory = $false, HelpMessage = "Limite de throttling (0 = valeur par défaut du module)")]
        [ValidateRange(0, 1024)]
        [int]$ThrottleLimit = 0,

        [Parameter(Mandatory = $false, HelpMessage = "Timeout en secondes (0 = pas de timeout)")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$TimeoutSeconds = 0,

        [Parameter(Mandatory = $false, HelpMessage = "Variables à partager avec les runspaces")]
        [hashtable]$SharedVariables,

        [Parameter(Mandatory = $false, HelpMessage = "Type de tâche à exécuter")]
        [ValidateSet('Default', 'CPU', 'IO', 'Mixed', 'LowPriority', 'HighPriority')]
        [string]$TaskType = 'Default',

        [Parameter(Mandatory = $false, HelpMessage = "Priorité de la tâche (0-3)")]
        [ValidateRange(0, 3)]
        [int]$Priority = 1,

        [Parameter(Mandatory = $false, HelpMessage = "Ne pas afficher de barre de progression")]
        [switch]$NoProgress,

        [Parameter(Mandatory = $false, HelpMessage = "Retourner un objet détaillé avec les résultats et les métriques")]
        [switch]$PassThru,

        [Parameter(Mandatory = $false, HelpMessage = "Attendre que toutes les tâches soient terminées")]
        [switch]$Wait,

        [Parameter(Mandatory = $false, HelpMessage = "Ignorer les erreurs dans les tâches individuelles")]
        [switch]$IgnoreErrors,

        [Parameter(Mandatory = $false, HelpMessage = "Utiliser un pool de runspaces (compatible PS 5.1 et 7+)")]
        [switch]$UseRunspacePool,

        [Parameter(Mandatory = $false, HelpMessage = "Utiliser ForEach-Object -Parallel (PS 7+ uniquement)")]
        [switch]$UseForeachParallel,

        [Parameter(Mandatory = $true, ParameterSetName = 'Command', HelpMessage = "Nom de la commande à exécuter")]
        [ValidateNotNullOrEmpty()]
        [string]$Command,

        [Parameter(Mandatory = $false, ParameterSetName = 'Command', HelpMessage = "Arguments à passer à la commande")]
        [hashtable]$ArgumentList,

        [Parameter(Mandatory = $false, HelpMessage = "Nom de l'activité pour la barre de progression")]
        [string]$ActivityName = "Traitement parallèle",

        [Parameter(Mandatory = $false, HelpMessage = "Activer le mécanisme de backpressure")]
        [switch]$EnableBackpressure,

        [Parameter(Mandatory = $false, HelpMessage = "Activer le mécanisme de throttling")]
        [switch]$EnableThrottling,

        [Parameter(Mandatory = $false, HelpMessage = "Collecter des métriques détaillées")]
        [switch]$EnableMetrics,

        [Parameter(Mandatory = $false, HelpMessage = "Préfixe à ajouter aux messages de log")]
        [string]$LogPrefix,

        [Parameter(Mandatory = $false, HelpMessage = "Nettoyer les ressources en cas de timeout")]
        [switch]$CleanupOnTimeout,

        [Parameter(Mandatory = $false, HelpMessage = "Millisecondes à attendre entre chaque vérification")]
        [ValidateRange(1, 1000)]
        [int]$SleepMilliseconds = 50
    )

    begin {
        # Vérifier si le module est initialisé
        if (-not (Get-ModuleInitialized)) {
            Write-Verbose "Le module n'est pas initialisé. Initialisation automatique..."
            Initialize-UnifiedParallel
        }

        # Déterminer le nombre optimal de threads
        if ($MaxThreads -le 0) {
            if ($TaskType -eq 'IO') {
                # Pour les tâches IO-bound, utiliser plus de threads
                $MaxThreads = [Math]::Min([Environment]::ProcessorCount * 3, 32)
            } elseif ($TaskType -eq 'CPU') {
                # Pour les tâches CPU-bound, utiliser le nombre de cœurs
                $MaxThreads = [Environment]::ProcessorCount
            } elseif ($TaskType -eq 'Mixed') {
                # Pour les tâches mixtes, utiliser un nombre intermédiaire
                $MaxThreads = [Environment]::ProcessorCount * 2
            } elseif ($TaskType -eq 'LowPriority') {
                # Pour les tâches de faible priorité, limiter les ressources
                $MaxThreads = [Math]::Max(1, [Environment]::ProcessorCount / 2)
            } elseif ($TaskType -eq 'HighPriority') {
                # Pour les tâches de haute priorité, utiliser plus de ressources
                $MaxThreads = [Math]::Min([Environment]::ProcessorCount * 4, 64)
            } else {
                # Par défaut, utiliser la configuration du module
                $config = Get-ModuleConfig
                $MaxThreads = $config.DefaultMaxThreads
            }
        }

        # Déterminer la limite de throttling
        if ($ThrottleLimit -le 0) {
            $config = Get-ModuleConfig
            $ThrottleLimit = if ($config.DefaultThrottleLimit -gt 0) {
                $config.DefaultThrottleLimit
            } else {
                $MaxThreads + 2
            }
        }

        # Déterminer le timeout
        if ($TimeoutSeconds -le 0) {
            $config = Get-ModuleConfig
            $TimeoutSeconds = $config.DefaultTimeout
        }

        # Initialiser les collections pour les résultats et les erreurs
        $results = [System.Collections.Generic.List[object]]::new()
        $errors = [System.Collections.Generic.List[object]]::new()
        $runspaces = [System.Collections.Generic.List[object]]::new()
        $runspacePool = $null

        # Initialiser les métriques si demandé
        if ($EnableMetrics) {
            $metrics = [ParallelMetrics]::new()
            $metrics.MaxThreadsUsed = $MaxThreads
        }

        # Déterminer la méthode de parallélisation à utiliser
        $useForEachParallel = $false
        if ($PSVersionTable.PSVersion.Major -ge 7 -and -not $UseRunspacePool) {
            # PowerShell 7+ supporte ForEach-Object -Parallel
            $useForEachParallel = $true
            if ($UseForeachParallel) {
                $useForEachParallel = $true
            }
        }

        # Créer un pool de runspaces si nécessaire
        if (-not $useForEachParallel) {
            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

            # Ajouter les variables partagées au session state
            if ($SharedVariables) {
                foreach ($key in $SharedVariables.Keys) {
                    $sessionVariable = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new(
                        $key, $SharedVariables[$key], "Variable partagée: $key"
                    )
                    $sessionState.Variables.Add($sessionVariable)
                }
            }

            # Utiliser le cache de pools de runspaces pour optimiser les performances
            $runspacePool = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces $MaxThreads -SessionState $sessionState -ThreadOptions "ReuseThread" -ApartmentState "MTA" -Verbose:$VerbosePreference

            Write-Verbose "Pool de runspaces créé avec $MaxThreads threads maximum"
        } else {
            Write-Verbose "Utilisation de ForEach-Object -Parallel avec $MaxThreads threads maximum"
        }

        # Initialiser la barre de progression
        if (-not $NoProgress) {
            $progressParams = @{
                Activity        = $ActivityName
                Status          = "Préparation des tâches..."
                PercentComplete = 0
            }
            Write-Progress @progressParams
        }

        # Initialiser les compteurs
        $totalItems = 0
        $processedItems = 0
        $startTime = [datetime]::Now

        # Initialiser les variables pour la gestion optimisée de la progression
        $script:LastProgressUpdate = 0
        $script:ProgressIterationCounter = 0

        # Préparer le script block à exécuter
        if ($PSCmdlet.ParameterSetName -eq 'Command') {
            # Convertir la commande en script block
            $commandScript = {
                param($Item, $Command, $ArgumentList)

                $invokeParams = @{}
                if ($ArgumentList) {
                    $invokeParams = $ArgumentList.Clone()
                }

                # Ajouter l'élément courant aux arguments
                if ($invokeParams.ContainsKey('InputObject')) {
                    if ($invokeParams.InputObject -is [array]) {
                        $invokeParams.InputObject += $Item
                    } else {
                        $invokeParams.InputObject = @($invokeParams.InputObject, $Item)
                    }
                } else {
                    $invokeParams.InputObject = $Item
                }

                # Exécuter la commande
                & $Command @invokeParams
            }

            $ScriptBlock = $commandScript
        }

        # Vérifier la validité du script block
        if (-not (Test-ParameterValid -Value $ScriptBlock -ValidationTypes 'ValidScriptBlock' -ParameterName 'ScriptBlock')) {
            throw "Le script block fourni n'est pas valide."
        }

        # Collecter les éléments d'entrée si on utilise le pipeline
        $inputItems = [System.Collections.Generic.List[object]]::new()
    }

    process {
        # Ajouter les éléments d'entrée à la liste
        foreach ($item in $InputObject) {
            $inputItems.Add($item)
        }
    }

    end {
        $totalItems = $inputItems.Count

        if ($totalItems -eq 0) {
            Write-Warning "Aucun élément à traiter."
            return $results
        }

        Write-Verbose "Traitement de $totalItems éléments en parallèle avec $MaxThreads threads"

        # Traiter les éléments en parallèle
        if ($useForEachParallel) {
            # Utiliser ForEach-Object -Parallel (PowerShell 7+)
            try {
                $parallelParams = @{
                    ThrottleLimit = $MaxThreads
                }

                if ($TimeoutSeconds -gt 0) {
                    $parallelParams.TimeoutSeconds = $TimeoutSeconds
                }

                $foreachResults = $inputItems | ForEach-Object -Parallel {
                    $item = $_
                    $result = [PSCustomObject]@{
                        Item      = $item
                        Output    = $null
                        Success   = $true
                        Error     = $null
                        StartTime = [datetime]::Now
                        EndTime   = $null
                        Duration  = $null
                        ThreadId  = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                    }

                    try {
                        # Exécuter le script block avec l'élément courant
                        if ($using:SharedVariables) {
                            $sharedVars = $using:SharedVariables
                            foreach ($key in $sharedVars.Keys) {
                                Set-Variable -Name $key -Value $sharedVars[$key]
                            }
                        }

                        $output = if ($using:PSCmdlet.ParameterSetName -eq 'Command') {
                            & $using:ScriptBlock $item $using:Command $using:ArgumentList
                        } else {
                            & $using:ScriptBlock $item
                        }

                        $result.Output = $output
                        $result.Success = $true
                    } catch {
                        $result.Success = $false
                        $result.Error = $_
                    } finally {
                        $result.EndTime = [datetime]::Now
                        $result.Duration = $result.EndTime - $result.StartTime
                    }

                    $result
                } @parallelParams

                # Convertir les résultats en objets ParallelResult
                foreach ($foreachResult in $foreachResults) {
                    # Créer un objet résultat simple
                    $resultObject = [PSCustomObject]@{
                        Value     = $foreachResult.Output
                        Success   = $foreachResult.Success
                        Error     = $foreachResult.Error
                        StartTime = $foreachResult.StartTime
                        EndTime   = $foreachResult.EndTime
                        Duration  = $foreachResult.Duration
                        ThreadId  = $foreachResult.ThreadId
                    }

                    # Ajouter le résultat à la liste
                    $results.Add($resultObject)

                    # Si c'est une erreur, l'ajouter à la liste des erreurs
                    if (-not $foreachResult.Success) {
                        $errors.Add($foreachResult.Error)
                    }
                    $processedItems++

                    # Mettre à jour la barre de progression par lots pour réduire l'overhead
                    if (-not $NoProgress -and $totalItems -gt 0) {
                        # Mettre à jour la barre de progression seulement si des éléments ont été traités
                        # ou toutes les 10 éléments pour montrer que le traitement est toujours en cours
                        $updateProgress = $false

                        # Mettre à jour si des éléments ont été traités ou tous les 10 éléments
                        if ($processedItems -gt $script:LastProgressUpdate -or $processedItems % 10 -eq 0) {
                            $updateProgress = $true
                            $script:LastProgressUpdate = $processedItems
                        }

                        if ($updateProgress) {
                            $percentComplete = [Math]::Min(100, [Math]::Floor(($processedItems / $totalItems) * 100))
                            $progressParams = @{
                                Activity        = $ActivityName
                                Status          = "Traitement de l'élément $processedItems sur $totalItems"
                                PercentComplete = $percentComplete
                            }
                            Write-Progress @progressParams
                        }
                    }
                }
            } catch {
                Write-Error "Erreur lors de l'exécution parallèle: $_"
                if (-not $IgnoreErrors) {
                    throw
                }
            }
        } else {
            # Utiliser les runspaces (compatible PowerShell 5.1 et 7+)
            try {
                # Créer et démarrer les runspaces en batch pour réduire l'overhead
                # Préparer le script wrapper
                $wrapperScriptBlock = {
                    param($Item, $ScriptBlock, $Command, $ArgumentList, $PSCmdlet_ParameterSetName)

                    $result = [PSCustomObject]@{
                        Item      = $Item
                        Output    = $null
                        Success   = $true
                        Error     = $null
                        StartTime = [datetime]::Now
                        EndTime   = $null
                        Duration  = $null
                        ThreadId  = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                    }

                    try {
                        # Exécuter le script block avec l'élément courant
                        $output = if ($PSCmdlet_ParameterSetName -eq 'Command') {
                            & $ScriptBlock $Item $Command $ArgumentList
                        } else {
                            & $ScriptBlock $Item
                        }

                        $result.Output = $output
                        $result.Success = $true
                    } catch {
                        $result.Success = $false
                        $result.Error = $_
                    } finally {
                        $result.EndTime = [datetime]::Now
                        $result.Duration = $result.EndTime - $result.StartTime
                    }

                    $result
                }

                # Déterminer la taille optimale du batch en fonction du nombre d'éléments
                $optimalBatchSize = [Math]::Min(20, [Math]::Max(5, [Math]::Ceiling($inputItems.Count / 10)))
                Write-Verbose "Utilisation d'une taille de batch optimale de $optimalBatchSize pour $($inputItems.Count) éléments"

                # Créer les runspaces en batch
                $batchParams = @{
                    RunspacePool  = $runspacePool
                    ScriptBlock   = $wrapperScriptBlock
                    InputObjects  = $inputItems
                    BatchSize     = $optimalBatchSize
                    ParameterName = "Item"
                    ArgumentList  = @{
                        ScriptBlock               = $ScriptBlock
                        Command                   = $Command
                        ArgumentList              = $ArgumentList
                        PSCmdlet_ParameterSetName = $PSCmdlet.ParameterSetName
                    }
                }

                $runspaces = New-RunspaceBatch @batchParams

                # Attendre et récupérer les résultats
                $activeRunspaces = $runspaces.Count
                $timeout = if ($TimeoutSeconds -gt 0) {
                    $startTime.AddSeconds($TimeoutSeconds)
                } else {
                    [datetime]::MaxValue
                }

                while ($activeRunspaces -gt 0 -and [datetime]::Now -lt $timeout) {
                    # Vérifier les runspaces terminés
                    for ($i = 0; $i -lt $runspaces.Count; $i++) {
                        $runspace = $runspaces[$i]

                        if ($runspace.Handle.IsCompleted) {
                            # Récupérer le résultat
                            $runspaceResult = $runspace.PowerShell.EndInvoke($runspace.Handle)

                            if ($runspaceResult) {
                                # Créer un objet résultat simple
                                $resultObject = [PSCustomObject]@{
                                    Value     = $runspaceResult.Output
                                    Success   = $runspaceResult.Success
                                    Error     = $runspaceResult.Error
                                    StartTime = $runspaceResult.StartTime
                                    EndTime   = $runspaceResult.EndTime
                                    Duration  = $runspaceResult.Duration
                                    ThreadId  = $runspaceResult.ThreadId
                                }

                                # Ajouter le résultat à la liste
                                $results.Add($resultObject)

                                # Si c'est une erreur, l'ajouter à la liste des erreurs
                                if (-not $runspaceResult.Success) {
                                    $errors.Add($runspaceResult.Error)
                                }
                            }

                            # Nettoyer le runspace
                            $runspace.PowerShell.Dispose()
                            $runspaces.RemoveAt($i)
                            $i--
                            $activeRunspaces--
                            $processedItems++

                            # Ne pas mettre à jour la barre de progression ici pour éviter trop d'appels à Write-Progress
                            # La mise à jour sera faite en lot après la boucle
                        }
                    }

                    # Mettre à jour la barre de progression par lots pour réduire l'overhead
                    if (-not $NoProgress -and $totalItems -gt 0) {
                        # Mettre à jour la barre de progression seulement si des éléments ont été traités
                        # ou toutes les 10 itérations pour montrer que le traitement est toujours en cours
                        $updateProgress = $false

                        # Incrémenter le compteur d'itérations
                        if (-not $script:ProgressIterationCounter) {
                            $script:ProgressIterationCounter = 0
                        }
                        $script:ProgressIterationCounter++

                        # Mettre à jour si des éléments ont été traités ou toutes les 10 itérations
                        if ($processedItems -gt $script:LastProgressUpdate -or $script:ProgressIterationCounter % 10 -eq 0) {
                            $updateProgress = $true
                            $script:LastProgressUpdate = $processedItems
                        }

                        if ($updateProgress) {
                            $percentComplete = [Math]::Min(100, [Math]::Floor(($processedItems / $totalItems) * 100))
                            $progressParams = @{
                                Activity        = $ActivityName
                                Status          = "Traitement de l'élément $processedItems sur $totalItems"
                                PercentComplete = $percentComplete
                            }
                            Write-Progress @progressParams
                        }
                    }

                    # Pause pour éviter de surcharger le CPU
                    Start-Sleep -Milliseconds $SleepMilliseconds

                    # Vérifier si on a atteint le timeout
                    if ([datetime]::Now -ge $timeout -and $activeRunspaces -gt 0) {
                        Write-Warning "Timeout atteint. Arrêt forcé des runspaces restants."

                        # Arrêter les runspaces restants
                        if ($CleanupOnTimeout) {
                            Write-Verbose "Nettoyage des runspaces non complétés après timeout..."
                            foreach ($runspace in $runspaces) {
                                if ($runspace -and $runspace.PowerShell) {
                                    try {
                                        # Arrêter le runspace s'il est toujours en cours d'exécution
                                        if (-not $runspace.Handle.IsCompleted) {
                                            $runspace.PowerShell.Stop()
                                        }
                                        $runspace.PowerShell.Dispose()
                                    } catch {
                                        Write-Warning "Erreur lors du nettoyage du runspace: $_"
                                    }
                                }
                            }
                            Write-Verbose "Nettoyage des runspaces terminé."
                        } else {
                            # Comportement par défaut : arrêter les runspaces sans nettoyage complet
                            foreach ($runspace in $runspaces) {
                                $runspace.PowerShell.Dispose()
                            }
                        }

                        $runspaces.Clear()
                        $activeRunspaces = 0
                    }
                }
            } catch {
                $errorParams = @{
                    Message        = "Erreur lors de l'exécution parallèle"
                    Source         = "Invoke-UnifiedParallel"
                    ErrorRecord    = $_
                    Category       = [System.Management.Automation.ErrorCategory]::OperationStopped
                    AdditionalInfo = @{
                        "InputObjectCount" = $totalItems
                        "ProcessedItems"   = $processedItems
                        "Method"           = "RunspacePool"
                    }
                }

                if (-not $IgnoreErrors) {
                    New-UnifiedError @errorParams -WriteError -ThrowError
                } else {
                    New-UnifiedError @errorParams -WriteError
                }
            } finally {
                # Nettoyer les ressources
                # Ne pas fermer ou disposer le pool de runspaces car il est géré par le cache
                # Le pool sera réutilisé pour les prochaines exécutions

                # Nettoyer les runspaces individuels
                foreach ($runspace in $runspaces) {
                    if ($runspace.PowerShell) {
                        $runspace.PowerShell.Dispose()
                    }
                }
            }
        }

        # Terminer la barre de progression
        if (-not $NoProgress) {
            Write-Progress -Activity $ActivityName -Completed
        }

        # Mettre à jour les métriques si demandé
        if ($EnableMetrics) {
            $metrics.UpdateFromResults($results)
            $metrics.TotalTasks = $totalItems
            $metrics.CompletedTasks = $results.Count
            $metrics.FailedTasks = $errors.Count

            # Journaliser les métriques si le logging est activé
            if ($script:Config -and $script:Config.LogPath) {
                try {
                    $logFile = Join-Path -Path $script:Config.LogPath -ChildPath "metrics_$(Get-Date -Format 'yyyyMMdd').json"
                    $metrics | ConvertTo-Json -Depth 3 | Out-File -FilePath $logFile -Encoding utf8 -Append
                } catch {
                    Write-Verbose "Erreur lors de la journalisation des métriques: $_"
                }
            }
        }

        # Afficher un résumé
        $endTime = [datetime]::Now
        $duration = $endTime - $startTime
        Write-Verbose "Traitement terminé en $($duration.TotalSeconds) secondes. $($results.Count) éléments traités, $($errors.Count) erreurs."

        # Retourner les résultats
        if ($PassThru) {
            [PSCustomObject]@{
                Results        = $results
                Errors         = $errors
                TotalItems     = $totalItems
                ProcessedItems = $processedItems
                Duration       = $duration
                StartTime      = $startTime
                EndTime        = $endTime
                MaxThreads     = $MaxThreads
                Metrics        = if ($EnableMetrics) { $metrics } else { $null }
            }
        } else {
            $results
        }
    }
}

# Fonctions auxiliaires pour l'exécution parallèle

# Fonction d'attente des runspaces complétés
function Wait-ForCompletedRunspace {
    <#
    .SYNOPSIS
        Attend que les runspaces spécifiés soient complétés.

    .DESCRIPTION
        Cette fonction attend que les runspaces spécifiés soient complétés.
        Elle peut attendre tous les runspaces ou seulement le premier complété.
        Elle supporte également un timeout pour éviter d'attendre indéfiniment.

        La fonction retourne une liste des runspaces complétés et modifie la liste
        d'entrée en supprimant les runspaces complétés.

        Elle inclut un mécanisme de timeout interne pour détecter et arrêter les runspaces
        individuels qui sont bloqués, ainsi qu'une détection de deadlock pour libérer
        automatiquement les ressources.

    .PARAMETER Runspaces
        Liste des runspaces à attendre. Chaque élément doit être un objet avec les propriétés
        PowerShell (instance PowerShell) et Handle (IAsyncResult).

        Cette liste est modifiée par la fonction : les runspaces complétés sont supprimés.

        Ce paramètre accepte différents types de collections qui seront automatiquement convertis :
        - System.Collections.Generic.List<PSObject>
        - System.Collections.ArrayList
        - Array ou System.Array
        - Object[]
        - Tout objet implémentant IEnumerable

        La fonction effectue automatiquement la conversion appropriée en fonction du type d'entrée.

    .PARAMETER TimeoutSeconds
        Nombre de secondes à attendre avant d'abandonner l'opération complète. Si 0, attend indéfiniment.

        Par défaut : 0 (pas de timeout global)

    .PARAMETER RunspaceTimeoutSeconds
        Nombre de secondes à attendre avant de considérer qu'un runspace individuel est bloqué.
        Si 0, utilise la valeur de TimeoutSeconds. Si les deux sont à 0, aucun timeout n'est appliqué.

        Par défaut : 0 (utilise TimeoutSeconds)

    .PARAMETER WaitForAll
        Si spécifié, attend que tous les runspaces soient complétés.
        Sinon, retourne dès qu'un runspace est complété.

        Par défaut : $false (attend seulement le premier runspace)

    .PARAMETER NoProgress
        Si spécifié, n'affiche pas de barre de progression.

        Par défaut : $false (affiche une barre de progression)

    .PARAMETER ActivityName
        Nom de l'activité à afficher dans la barre de progression.

        Par défaut : "Attente des runspaces"

    .PARAMETER CleanupOnTimeout
        Si spécifié, nettoie les runspaces qui n'ont pas été complétés avant le timeout.
        Cela permet d'éviter les fuites de mémoire.

        Par défaut : $false (ne nettoie pas les runspaces)

    .PARAMETER SleepMilliseconds
        Nombre de millisecondes à attendre entre chaque vérification des runspaces.
        Une valeur plus élevée réduit l'utilisation du CPU mais augmente la latence.

        Par défaut : 50 ms

    .PARAMETER DeadlockDetectionSeconds
        Nombre de secondes sans progression avant de considérer qu'un deadlock s'est produit.
        Si 0, la détection de deadlock est désactivée.

        Par défaut : 30 secondes

    .EXAMPLE
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll

        Attend que tous les runspaces dans $runspaces soient complétés.

    .EXAMPLE
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -TimeoutSeconds 30

        Attend qu'un runspace soit complété, avec un timeout global de 30 secondes.

    .EXAMPLE
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -RunspaceTimeoutSeconds 10 -TimeoutSeconds 60

        Attend les runspaces avec un timeout individuel de 10 secondes par runspace et un timeout global de 60 secondes.

    .EXAMPLE
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -NoProgress -CleanupOnTimeout -TimeoutSeconds 10

        Attend qu'un runspace soit complété, sans afficher de barre de progression,
        avec un timeout de 10 secondes et en nettoyant les runspaces non complétés.

    .EXAMPLE
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -DeadlockDetectionSeconds 15

        Attend les runspaces avec détection de deadlock après 15 secondes sans progression.

    .EXAMPLE
        $emptyRunspaces = @()
        $result = Wait-ForCompletedRunspace -Runspaces $emptyRunspaces -WaitForAll

        Gère correctement un tableau vide. Par défaut (ReturnFormat="Object"), la fonction retourne un objet
        personnalisé avec une propriété Results contenant une liste vide.

    .EXAMPLE
        $emptyRunspaces = @()
        $result = Wait-ForCompletedRunspace -Runspaces $emptyRunspaces -WaitForAll -ReturnFormat "Array"

        Gère un tableau vide avec le format de retour "Array". Dans ce cas, la fonction retourne un tableau vide (@()).
        Ce format est utile pour la compatibilité avec du code existant qui attend un tableau.

    .EXAMPLE
        $runspaces = @(...)  # Tableau de runspaces
        $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -ReturnFormat "Object"

        # Accès aux résultats via les propriétés et méthodes de l'objet
        $count = $result.Count
        $firstResult = $result.GetFirst()
        $allResults = $result.GetList()
        $hasTimeout = $result.HasTimeout()

    .EXAMPLE
        $runspaces = @(...)  # Tableau de runspaces
        $results = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -ReturnFormat "Array"

        # Accès direct aux résultats comme un tableau
        $count = $results.Count
        $firstResult = $results[0]
        foreach ($item in $results) {
            # Traitement de chaque résultat
        }

    .OUTPUTS
        PSCustomObject ou System.Object[]

        Le type de retour dépend du paramètre ReturnFormat :

        Avec ReturnFormat="Object" (par défaut) :
        - La fonction retourne un objet personnalisé (PSCustomObject) avec les propriétés et méthodes suivantes :
          - Results : System.Collections.Generic.List<object> contenant les runspaces complétés
          - Count : Nombre de runspaces complétés
          - GetList() : Méthode pour obtenir la List<object> des runspaces complétés
          - GetArrayList() : Méthode obsolète pour la compatibilité, utiliser GetList() à la place
          - GetFirst() : Méthode pour obtenir le premier runspace complété
          - [index] : Indexeur pour accéder aux runspaces par leur index
          - TimeoutOccurred : Indique si un timeout s'est produit
          - DeadlockDetected : Indique si un deadlock a été détecté
          - StoppedRunspaces : Liste des runspaces arrêtés en raison d'un timeout ou d'un deadlock
          - HasTimeout() : Méthode pour vérifier si un timeout s'est produit
          - HasDeadlock() : Méthode pour vérifier si un deadlock a été détecté

        Avec ReturnFormat="Array" :
        - La fonction retourne un tableau (System.Object[]) contenant directement les runspaces complétés
        - Pour les tableaux vides, elle retourne un tableau vide (@())

        L'objet personnalisé encapsule une List<object> pour éviter les problèmes de conversion de type
        lors du retour de la fonction. Le format Array est utile pour la compatibilité avec du code existant
        qui attend un tableau standard.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Liste des runspaces à attendre")]
        [ValidateNotNull()]
        [object]$Runspaces,

        [Parameter(Mandatory = $false, HelpMessage = "Nombre de secondes à attendre avant d'abandonner l'opération complète (0 = pas de timeout global)")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$TimeoutSeconds = 0,

        [Parameter(Mandatory = $false, HelpMessage = "Nombre de secondes à attendre avant de considérer qu'un runspace individuel est bloqué")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$RunspaceTimeoutSeconds = 0,

        [Parameter(Mandatory = $false, HelpMessage = "Attendre que tous les runspaces soient complétés")]
        [switch]$WaitForAll,

        [Parameter(Mandatory = $false, HelpMessage = "Ne pas afficher de barre de progression")]
        [switch]$NoProgress,

        [Parameter(Mandatory = $false, HelpMessage = "Nom de l'activité à afficher dans la barre de progression")]
        [string]$ActivityName = "Attente des runspaces",

        [Parameter(Mandatory = $false, HelpMessage = "Nettoyer les runspaces non complétés après timeout")]
        [switch]$CleanupOnTimeout,

        [Parameter(Mandatory = $false, HelpMessage = "Millisecondes à attendre entre chaque vérification")]
        [ValidateRange(1, 1000)]
        [int]$SleepMilliseconds = 50,

        [Parameter(Mandatory = $false, HelpMessage = "Nombre de secondes sans progression avant de considérer qu'un deadlock s'est produit")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$DeadlockDetectionSeconds = 30,

        [Parameter(Mandatory = $false, HelpMessage = "Format de retour souhaité: Object (objet standardisé) ou Array (tableau)")]
        [ValidateSet("Object", "Array")]
        [string]$ReturnFormat = "Object"
    )

    begin {
        $startTime = [datetime]::Now
        $completedRunspaces = [System.Collections.Generic.List[object]]::new()
        $stoppedRunspaces = [System.Collections.Generic.List[object]]::new()

        # Déterminer le timeout global
        $timeout = if ($TimeoutSeconds -gt 0) {
            $startTime.AddSeconds($TimeoutSeconds)
        } else {
            [datetime]::MaxValue
        }

        # Déterminer le timeout individuel des runspaces
        $runspaceTimeout = if ($RunspaceTimeoutSeconds -gt 0) {
            $RunspaceTimeoutSeconds
        } elseif ($TimeoutSeconds -gt 0) {
            $TimeoutSeconds
        } else {
            0 # Pas de timeout individuel
        }

        # Variables pour la détection de deadlock
        $lastProgressTime = [datetime]::Now
        $lastCompletedCount = 0
        $deadlockDetected = $false
        $timeoutOccurred = $false

        # Convertir Runspaces en List<PSObject> si ce n'est pas déjà le cas
        $runspacesToProcess = $null

        # Détection rapide des tableaux vides ou null en une seule étape
        if ($null -eq $Runspaces -or
            (($Runspaces -is [array] -or $Runspaces -is [System.Array]) -and $Runspaces.Count -eq 0) -or
            ($Runspaces.PSObject.Properties.Match('Count').Count -gt 0 -and $Runspaces.Count -eq 0)) {

            Write-Verbose "Détection rapide: Runspaces est null ou vide. Aucun runspace à traiter."

            # Utiliser une liste vide préallouée pour optimiser les performances
            $runspacesToProcess = [System.Collections.Generic.List[PSObject]]::new(0)

            # Marquer que nous avons détecté un tableau vide pour optimiser le traitement ultérieur
            $isEmptyInput = $true
        }
        # Vérifier le type de Runspaces et effectuer la conversion appropriée
        elseif ($Runspaces -is [System.Collections.Generic.List[PSObject]]) {
            Write-Verbose "Runspaces est déjà une List<PSObject>. Aucune conversion nécessaire."
            $runspacesToProcess = $Runspaces
        } elseif ($Runspaces -is [System.Collections.ArrayList]) {
            Write-Verbose "Runspaces est un ArrayList. Conversion en List<PSObject>."
            $runspacesToProcess = [System.Collections.Generic.List[PSObject]]::new()
            foreach ($runspace in $Runspaces) {
                $runspacesToProcess.Add($runspace)
            }
        } elseif ($Runspaces -is [array] -or $Runspaces -is [System.Array]) {
            Write-Verbose "Runspaces est un tableau. Conversion en List<PSObject>."
            $runspacesToProcess = [System.Collections.Generic.List[PSObject]]::new()
            foreach ($runspace in $Runspaces) {
                $runspacesToProcess.Add($runspace)
            }
        } elseif ($Runspaces.GetType().Name -eq 'Object[]') {
            Write-Verbose "Runspaces est un tableau d'objets. Conversion en List<PSObject>."
            $runspacesToProcess = [System.Collections.Generic.List[PSObject]]::new()
            foreach ($runspace in $Runspaces) {
                $runspacesToProcess.Add($runspace)
            }
        } elseif ($Runspaces.GetType().GetInterfaces().Name -contains 'IEnumerable') {
            Write-Verbose "Runspaces implémente IEnumerable. Conversion en List<PSObject>."
            $runspacesToProcess = [System.Collections.Generic.List[PSObject]]::new()
            foreach ($runspace in $Runspaces) {
                $runspacesToProcess.Add($runspace)
            }
        } else {
            # Si c'est un objet unique ou un autre type, créer une nouvelle liste
            Write-Verbose "Runspaces est d'un type non reconnu. Création d'une nouvelle List<PSObject>."
            $runspacesToProcess = [System.Collections.Generic.List[PSObject]]::new()
            if ($null -ne $Runspaces) {
                $runspacesToProcess.Add($Runspaces)
            }
        }

        # Ajouter des propriétés de suivi à chaque runspace
        for ($i = 0; $i -lt $runspacesToProcess.Count; $i++) {
            $runspace = $runspacesToProcess[$i]
            if ($null -ne $runspace) {
                # Ajouter un timestamp de début pour le suivi du timeout individuel
                Add-Member -InputObject $runspace -MemberType NoteProperty -Name "StartTime" -Value ([datetime]::Now) -Force
                # Ajouter un ID unique pour le suivi
                Add-Member -InputObject $runspace -MemberType NoteProperty -Name "RunspaceId" -Value $i -Force
                # Ajouter un statut pour le suivi
                Add-Member -InputObject $runspace -MemberType NoteProperty -Name "Status" -Value "Running" -Force
            }
        }

        $totalRunspaces = $runspacesToProcess.Count
        $processedRunspaces = 0

        Write-Verbose "Nombre total de runspaces à traiter après conversion : $totalRunspaces"
        if ($runspaceTimeout -gt 0) {
            Write-Verbose "Timeout individuel des runspaces configuré à $runspaceTimeout secondes"
        }
        if ($DeadlockDetectionSeconds -gt 0) {
            Write-Verbose "Détection de deadlock activée avec un seuil de $DeadlockDetectionSeconds secondes sans progression"
        }
    }

    process {
        # Optimisation: Utiliser la détection rapide des tableaux vides
        if ($isEmptyInput -or $null -eq $runspacesToProcess -or $runspacesToProcess.Count -eq 0) {
            Write-Verbose "Optimisation: Traitement rapide d'un tableau vide ou null."

            # Utiliser des listes vides préallouées pour optimiser les performances
            $completedRunspaces = [System.Collections.Generic.List[object]]::new(0)
            $stoppedRunspaces = [System.Collections.Generic.List[object]]::new(0)

            # Vérifier si nous avons un résultat en cache pour les tableaux vides
            $cacheKey = "EmptyArray_${ReturnFormat}"
            if ($script:EmptyResultsCache -and $script:EmptyResultsCache.ContainsKey($cacheKey)) {
                Write-Verbose "Utilisation du cache pour les tableaux vides avec ReturnFormat=$ReturnFormat"
                $resultObject = $script:EmptyResultsCache[$cacheKey]
                return $resultObject
            }

            Write-Verbose "Création d'un objet de résultat optimisé pour tableau vide."
            # Créer un objet de résultat vide mais correctement formaté
            $resultObject = [PSCustomObject]@{
                Results          = $completedRunspaces
                TimeoutOccurred  = $false
                DeadlockDetected = $false
                StoppedRunspaces = $stoppedRunspaces
                DeadlockAnalysis = $null
                # Ajouter la propriété Count directement dans l'objet pour éviter les problèmes avec ScriptProperty
                Count            = 0
            }

            Write-Verbose "Propriétés de l'objet résultat pour tableau vide:"
            $resultObject.PSObject.Properties | ForEach-Object {
                Write-Verbose "  $($_.Name): $($_.Value)"
            }
            Write-Verbose "Type de l'objet résultat: $($resultObject.GetType().FullName)"
            Write-Verbose "Count: $($resultObject.Count)"
            Write-Verbose "Results.Count: $($resultObject.Results.Count)"

            # Ajouter les méthodes standard
            $resultObject | Add-Member -MemberType ScriptMethod -Name "GetList" -Value {
                return $this.Results
            } -Force

            $resultObject | Add-Member -MemberType ScriptMethod -Name "GetArrayList" -Value {
                Write-Warning "La méthode GetArrayList est obsolète. Utilisez GetList à la place."
                return $this.Results
            } -Force

            $resultObject | Add-Member -MemberType ScriptMethod -Name "GetFirst" -Value {
                if ($this.Results.Count -gt 0) {
                    return $this.Results[0]
                }
                return $null
            } -Force

            # Ajouter la propriété Count qui retourne le nombre d'éléments dans Results
            # Pour un tableau vide, cela retournera 0
            # Vérifier si la propriété Count existe déjà
            if (-not $resultObject.PSObject.Properties.Match('Count').Count) {
                $resultObject | Add-Member -MemberType ScriptProperty -Name "Count" -Value {
                    return $this.Results.Count
                } -Force
            }

            $resultObject | Add-Member -MemberType ScriptMethod -Name "get_Item" -Value {
                param($index)
                return $this.Results[$index]
            } -Force

            $resultObject | Add-Member -MemberType ScriptMethod -Name "HasTimeout" -Value {
                return $this.TimeoutOccurred
            } -Force

            $resultObject | Add-Member -MemberType ScriptMethod -Name "HasDeadlock" -Value {
                return $this.DeadlockDetected
            } -Force

            # Ajouter une méthode pour obtenir un rapport de deadlock
            $resultObject | Add-Member -MemberType ScriptMethod -Name "GetDeadlockReport" -Value {
                if (-not $this.DeadlockDetected) {
                    return "Aucun deadlock détecté."
                }

                $report = "Rapport de deadlock:`n"
                if ($null -ne $this.DeadlockAnalysis) {
                    $report += "- Seuil de détection: $($this.DeadlockAnalysis.DetectionThreshold) secondes`n"
                    $report += "- Temps écoulé depuis le dernier progrès: $($this.DeadlockAnalysis.TimeSinceLastProgress) secondes`n"
                    $report += "- Runspaces complétés: $($this.DeadlockAnalysis.CompletedCount) / $($this.DeadlockAnalysis.TotalCount)`n"
                    $report += "- Runspaces arrêtés: $($this.DeadlockAnalysis.StoppedCount)`n"

                    if ($this.DeadlockAnalysis.DeadlockedRunspaces.Count -gt 0) {
                        $report += "- Runspaces en deadlock:`n"
                        foreach ($runspace in $this.DeadlockAnalysis.DeadlockedRunspaces) {
                            $report += "  - ID: $($runspace.RunspaceId), Temps d'exécution: $($runspace.RunningTime.TotalSeconds) secondes`n"
                        }
                    }
                } else {
                    $report += "- Aucune analyse de deadlock disponible.`n"
                }

                return $report
            } -Force

            # Convertir le résultat au format demandé si nécessaire
            if ($ReturnFormat -eq "Array") {
                Write-Verbose "Conversion du résultat en tableau selon le paramètre ReturnFormat=Array"
                # Pour un tableau vide, retourner un tableau vide
                return @()
            }

            return $resultObject
        }

        Write-Verbose "Attente de $($runspacesToProcess.Count) runspaces..."

        # Initialiser la barre de progression
        if (-not $NoProgress) {
            $progressParams = @{
                Activity        = $ActivityName
                Status          = "Attente des runspaces..."
                PercentComplete = 0
            }
            Write-Progress @progressParams
        }

        # Attendre les runspaces
        $activeRunspaces = $runspacesToProcess.Count

        # Variables pour le délai adaptatif
        $currentSleepMilliseconds = $SleepMilliseconds
        $minSleepMilliseconds = 10
        $maxSleepMilliseconds = 200
        $noProgressCount = 0

        # Utiliser la taille de lot spécifiée dans la variable globale si elle existe
        if ($null -ne $script:BatchSizeOverride) {
            $batchSize = $script:BatchSizeOverride
            Write-Verbose "Utilisation de la taille de lot spécifiée: $batchSize"
        } else {
            $batchSize = [Math]::Max(1, [Math]::Min(10, [Math]::Ceiling($activeRunspaces / 10)))
        }

        Write-Verbose "Délai initial: $currentSleepMilliseconds ms, taille de lot: $batchSize"

        # Variables pour la détection de deadlock
        $lastProgressTime = [datetime]::Now
        $lastCompletedCount = 0
        $deadlockDetected = $false
        $timeoutOccurred = $false

        while ($activeRunspaces -gt 0 -and [datetime]::Now -lt $timeout) {
            $completedInThisIteration = 0
            $batchProcessed = 0
            $currentTime = [datetime]::Now

            # Vérifier les runspaces terminés par lots pour réduire les itérations
            for ($i = 0; $i -lt $runspacesToProcess.Count; $i++) {
                $runspace = $runspacesToProcess[$i]

                # Vérification optimisée avec court-circuit pour éviter les vérifications inutiles
                $isCompleted = $null -ne $runspace -and $null -ne $runspace.Handle -and $runspace.Handle.IsCompleted

                # Vérifier le timeout individuel du runspace si configuré
                if ($runspaceTimeout -gt 0 -and -not $isCompleted -and $null -ne $runspace -and $null -ne $runspace.StartTime) {
                    $runningTime = $currentTime - $runspace.StartTime
                    if ($runningTime.TotalSeconds -gt $runspaceTimeout) {
                        Write-Warning "Timeout individuel atteint pour le runspace $($runspace.RunspaceId) après $($runningTime.TotalSeconds) secondes."

                        try {
                            # Marquer le runspace comme ayant expiré
                            $runspace.Status = "TimedOut"

                            # Arrêter le runspace s'il est toujours en cours d'exécution
                            if ($null -ne $runspace.PowerShell -and $null -ne $runspace.Handle -and -not $runspace.Handle.IsCompleted) {
                                $runspace.PowerShell.Stop()
                                Write-Verbose "Runspace $($runspace.RunspaceId) arrêté en raison du timeout individuel"

                                # Ajouter à la liste des runspaces arrêtés
                                $stoppedRunspaces.Add($runspace)

                                # Supprimer de la liste des runspaces actifs
                                $runspacesToProcess.RemoveAt($i)
                                $i--
                                $activeRunspaces--
                                $timeoutOccurred = $true

                                # Continuer à la prochaine itération
                                continue
                            }
                        } catch {
                            # Utiliser New-UnifiedError pour une gestion standardisée des erreurs
                            $errorParams = @{
                                Message        = "Erreur lors de l'arrêt du runspace après timeout individuel"
                                Source         = "Wait-ForCompletedRunspace"
                                ErrorRecord    = $_
                                Category       = [System.Management.Automation.ErrorCategory]::OperationStopped
                                AdditionalInfo = @{
                                    "RunspaceId"  = $runspace.RunspaceId
                                    "RunningTime" = $runningTime.TotalSeconds
                                    "Action"      = "StopOnTimeout"
                                }
                            }
                            New-UnifiedError @errorParams
                        }
                    }
                }

                if ($isCompleted) {
                    # Ajouter à la liste des runspaces complétés
                    $completedRunspaces.Add($runspace)

                    # Supprimer de la liste des runspaces actifs
                    $runspacesToProcess.RemoveAt($i)
                    $i--
                    $activeRunspaces--
                    $processedRunspaces++
                    $completedInThisIteration++

                    # Ne pas mettre à jour la barre de progression ici pour éviter trop d'appels à Write-Progress
                    # La mise à jour sera faite en lot après la boucle

                    # Si on n'attend pas tous les runspaces, retourner immédiatement
                    if (-not $WaitForAll) {
                        if (-not $NoProgress) {
                            Write-Progress -Activity $ActivityName -Completed
                        }

                        # Forcer la sortie de la boucle
                        break
                    }
                }

                # Traiter par lots pour réduire la charge CPU
                $batchProcessed++
                if ($batchProcessed -ge $batchSize) {
                    break
                }
            }

            # Détection de deadlock
            if ($DeadlockDetectionSeconds -gt 0 -and $activeRunspaces -gt 0) {
                if ($completedInThisIteration -gt 0) {
                    # Réinitialiser le compteur de deadlock si des runspaces ont été complétés
                    $lastProgressTime = $currentTime
                    $lastCompletedCount = $processedRunspaces
                } else {
                    # Vérifier si aucun progrès n'a été fait pendant la période de détection de deadlock
                    $timeSinceLastProgress = $currentTime - $lastProgressTime
                    if ($timeSinceLastProgress.TotalSeconds -gt $DeadlockDetectionSeconds -and $lastCompletedCount -eq $processedRunspaces) {
                        Write-Warning "Deadlock détecté: Aucun runspace complété depuis $($timeSinceLastProgress.TotalSeconds) secondes."
                        $deadlockDetected = $true

                        # Libérer les ressources des runspaces bloqués
                        Write-Verbose "Libération des ressources des runspaces bloqués..."

                        # Créer un tableau pour suivre les runspaces qui ont été traités
                        $processedIndices = [System.Collections.Generic.HashSet[int]]::new()

                        for ($i = 0; $i -lt $runspacesToProcess.Count; $i++) {
                            $runspace = $runspacesToProcess[$i]

                            # Vérification robuste pour les objets null ou incomplets
                            if ($null -eq $runspace) {
                                $processedIndices.Add($i)
                                continue
                            }

                            try {
                                # Marquer le runspace comme étant en deadlock
                                $runspace.Status = "Deadlocked"

                                # Essayer de récupérer des résultats partiels si possible
                                $hasPartialResults = $false
                                if ($null -ne $runspace.PowerShell -and $null -ne $runspace.Handle) {
                                    try {
                                        # Vérifier si des résultats partiels sont disponibles dans le pipeline de sortie
                                        if ($runspace.PowerShell.HadErrors) {
                                            Write-Verbose "Le runspace $($runspace.RunspaceId) a généré des erreurs avant le deadlock"
                                            $runspace.Errors = $runspace.PowerShell.Streams.Error
                                        }

                                        # Ajouter des informations de diagnostic
                                        Add-Member -InputObject $runspace -MemberType NoteProperty -Name "DeadlockTime" -Value ([datetime]::Now) -Force
                                        Add-Member -InputObject $runspace -MemberType NoteProperty -Name "RunningTime" -Value (([datetime]::Now) - $runspace.StartTime) -Force
                                        Add-Member -InputObject $runspace -MemberType NoteProperty -Name "DeadlockReason" -Value "Aucune progression pendant $($timeSinceLastProgress.TotalSeconds) secondes" -Force

                                        # Marquer que nous avons récupéré des informations partielles
                                        $hasPartialResults = $true
                                    } catch {
                                        Write-Verbose "Impossible de récupérer des résultats partiels pour le runspace $($runspace.RunspaceId): $_"
                                    }
                                }

                                # Arrêter le runspace s'il est toujours en cours d'exécution
                                if ($null -ne $runspace.PowerShell -and $null -ne $runspace.Handle -and -not $runspace.Handle.IsCompleted) {
                                    $runspace.PowerShell.Stop()
                                    Write-Verbose "Runspace $($runspace.RunspaceId) arrêté en raison d'un deadlock"

                                    # Ajouter à la liste des runspaces arrêtés
                                    $stoppedRunspaces.Add($runspace)
                                    $processedIndices.Add($i)

                                    # Essayer de libérer les ressources du runspace
                                    try {
                                        # Vider les flux de sortie pour libérer la mémoire
                                        if ($null -ne $runspace.PowerShell.Streams) {
                                            $runspace.PowerShell.Streams.ClearStreams()
                                        }

                                        # Si nous avons des résultats partiels, ne pas disposer le PowerShell tout de suite
                                        if (-not $hasPartialResults) {
                                            $runspace.PowerShell.Dispose()
                                            Write-Verbose "Ressources du runspace $($runspace.RunspaceId) libérées avec succès"
                                        }
                                    } catch {
                                        Write-Verbose "Erreur lors de la libération des ressources du runspace $($runspace.RunspaceId): $_"
                                    }
                                }
                            } catch {
                                # Utiliser New-UnifiedError pour une gestion standardisée des erreurs
                                $errorParams = @{
                                    Message        = "Erreur lors de l'arrêt du runspace en deadlock"
                                    Source         = "Wait-ForCompletedRunspace"
                                    ErrorRecord    = $_
                                    Category       = [System.Management.Automation.ErrorCategory]::OperationStopped
                                    AdditionalInfo = @{
                                        "RunspaceId" = if ($null -ne $runspace -and $null -ne $runspace.RunspaceId) { $runspace.RunspaceId } else { "Inconnu" }
                                        "Action"     = "StopOnDeadlock"
                                    }
                                }
                                New-UnifiedError @errorParams
                            }
                        }

                        # Supprimer les runspaces traités de la liste (en commençant par la fin pour éviter les problèmes d'index)
                        for ($i = $runspacesToProcess.Count - 1; $i -ge 0; $i--) {
                            if ($processedIndices.Contains($i)) {
                                $runspacesToProcess.RemoveAt($i)
                            }
                        }

                        # Mettre à jour le nombre de runspaces actifs
                        $activeRunspaces = $runspacesToProcess.Count

                        # Si tous les runspaces ont été traités, sortir de la boucle
                        if ($activeRunspaces -eq 0) {
                            break
                        }

                        # Réinitialiser le compteur de deadlock pour éviter de détecter continuellement le même deadlock
                        $lastProgressTime = [datetime]::Now
                        $lastCompletedCount = $processedRunspaces
                    }
                }
            }

            # Ajuster le délai en fonction du nombre de runspaces complétés
            if ($completedInThisIteration -gt 0) {
                # Si des runspaces ont été complétés, réduire le délai pour traiter plus rapidement
                $currentSleepMilliseconds = [Math]::Max($minSleepMilliseconds,
                    $currentSleepMilliseconds * 0.8)
                $noProgressCount = 0
            } else {
                # Si aucun runspace n'a été complété, augmenter progressivement le délai
                $noProgressCount++
                if ($noProgressCount -gt 3) {
                    $currentSleepMilliseconds = [Math]::Min($maxSleepMilliseconds,
                        $currentSleepMilliseconds * 1.2)
                }
            }

            # Ajuster la taille du lot en fonction du nombre de runspaces actifs
            if ($null -eq $script:BatchSizeOverride) {
                $batchSize = [Math]::Max(1, [Math]::Min(20, [Math]::Ceiling($activeRunspaces / 5)))
            }

            # Mettre à jour la barre de progression par lots pour réduire l'overhead
            if (-not $NoProgress -and $totalRunspaces -gt 0 -and $completedInThisIteration -gt 0) {
                $percentComplete = [Math]::Min(100, [Math]::Floor(($processedRunspaces / $totalRunspaces) * 100))
                $progressParams = @{
                    Activity        = $ActivityName
                    Status          = "Runspace $processedRunspaces sur $totalRunspaces complété"
                    PercentComplete = $percentComplete
                }
                Write-Progress @progressParams
            }

            # Pause adaptative pour éviter de surcharger le CPU
            Start-Sleep -Milliseconds $currentSleepMilliseconds

            # Vérifier si on a atteint le timeout global
            if ([datetime]::Now -ge $timeout -and $activeRunspaces -gt 0) {
                Write-Warning "Timeout global atteint. $activeRunspaces runspaces toujours actifs."
                $timeoutOccurred = $true

                # Nettoyer les runspaces non complétés (toujours effectué après timeout pour éviter les fuites de mémoire)
                # Le paramètre CleanupOnTimeout est maintenant obsolète mais conservé pour la compatibilité
                Write-Verbose "Nettoyage des runspaces non complétés après timeout global..."

                # Compteurs pour les statistiques
                $stoppedCount = 0
                $disposedCount = 0
                $errorCount = 0

                for ($i = 0; $i -lt $runspacesToProcess.Count; $i++) {
                    $runspace = $runspacesToProcess[$i]

                    # Vérification robuste pour les objets null ou incomplets
                    if ($null -eq $runspace) {
                        Write-Verbose "Runspace à l'index $i est null, ignoré"
                        continue
                    }

                    try {
                        # Marquer le runspace comme ayant expiré
                        $runspace.Status = "TimedOut"

                        # Vérification robuste pour PowerShell null
                        if ($null -eq $runspace.PowerShell) {
                            Write-Verbose "PowerShell est null pour le runspace à l'index $i, ignoré"
                            continue
                        }

                        # Arrêter le runspace s'il est toujours en cours d'exécution
                        # Vérification complète pour Handle null ou incomplet
                        if ($null -ne $runspace.Handle) {
                            try {
                                if (-not $runspace.Handle.IsCompleted) {
                                    $runspace.PowerShell.Stop()
                                    $stoppedCount++
                                    Write-Verbose "Runspace à l'index $i arrêté avec succès"

                                    # Ajouter à la liste des runspaces arrêtés
                                    $stoppedRunspaces.Add($runspace)
                                }
                            } catch {
                                # Utiliser New-UnifiedError pour une gestion standardisée des erreurs
                                $errorParams = @{
                                    Message        = "Erreur lors de l'arrêt du runspace"
                                    Source         = "Wait-ForCompletedRunspace"
                                    ErrorRecord    = $_
                                    Category       = [System.Management.Automation.ErrorCategory]::OperationStopped
                                    AdditionalInfo = @{
                                        "RunspaceIndex" = $i
                                        "Action"        = "Stop"
                                    }
                                }
                                New-UnifiedError @errorParams
                                $errorCount++
                            }
                        } else {
                            Write-Verbose "Handle est null pour le runspace à l'index $i"
                        }

                        # Toujours essayer de disposer le PowerShell, même si Handle est null
                        try {
                            $runspace.PowerShell.Dispose()
                            $disposedCount++
                            Write-Verbose "PowerShell à l'index $i disposé avec succès"
                        } catch {
                            # Utiliser New-UnifiedError pour une gestion standardisée des erreurs
                            $errorParams = @{
                                Message        = "Erreur lors de la libération des ressources du runspace"
                                Source         = "Wait-ForCompletedRunspace"
                                ErrorRecord    = $_
                                Category       = [System.Management.Automation.ErrorCategory]::ResourceUnavailable
                                AdditionalInfo = @{
                                    "RunspaceIndex" = $i
                                    "Action"        = "Dispose"
                                }
                            }
                            New-UnifiedError @errorParams
                            $errorCount++
                        }
                    } catch {
                        # Capture des erreurs inattendues
                        $errorParams = @{
                            Message        = "Erreur inattendue lors du nettoyage du runspace"
                            Source         = "Wait-ForCompletedRunspace"
                            ErrorRecord    = $_
                            Category       = [System.Management.Automation.ErrorCategory]::NotSpecified
                            AdditionalInfo = @{
                                "RunspaceIndex" = $i
                                "Action"        = "Cleanup"
                            }
                        }
                        New-UnifiedError @errorParams
                        $errorCount++
                    }
                }

                # Statistiques de nettoyage
                Write-Verbose "Nettoyage des runspaces terminé: $stoppedCount arrêtés, $disposedCount libérés, $errorCount erreurs"

                # Vider la liste des runspaces à traiter
                $runspacesToProcess.Clear()
                $activeRunspaces = 0

                break
            }
        }

        # Terminer la barre de progression
        if (-not $NoProgress) {
            Write-Progress -Activity $ActivityName -Completed
        }
    }

    end {
        Write-Verbose "$($completedRunspaces.Count) runspaces complétés sur $totalRunspaces."
        if ($stoppedRunspaces.Count -gt 0) {
            Write-Verbose "$($stoppedRunspaces.Count) runspaces arrêtés en raison de timeout ou deadlock."
        }

        # Vérifier si nous avons déjà créé un objet de résultat pour un tableau vide
        if ($null -ne $resultObject) {
            Write-Verbose "Objet de résultat déjà créé pour un tableau vide. Utilisation de cet objet."
            return $resultObject
        }

        # Analyser les deadlocks si détectés
        $deadlockAnalysis = $null
        if ($deadlockDetected) {
            $deadlockAnalysis = [PSCustomObject]@{
                DetectionTime         = [datetime]::Now
                DetectionThreshold    = $DeadlockDetectionSeconds
                TimeSinceLastProgress = if ($null -ne $lastProgressTime) { ([datetime]::Now - $lastProgressTime).TotalSeconds } else { 0 }
                CompletedCount        = $processedRunspaces
                TotalCount            = $totalRunspaces
                StoppedCount          = $stoppedRunspaces.Count
                RemainingCount        = $runspacesToProcess.Count
                DeadlockedRunspaces   = @()
            }

            # Ajouter des informations détaillées sur chaque runspace en deadlock
            foreach ($runspace in $stoppedRunspaces) {
                if ($runspace.Status -eq "Deadlocked") {
                    $runspaceInfo = [PSCustomObject]@{
                        RunspaceId     = $runspace.RunspaceId
                        StartTime      = $runspace.StartTime
                        RunningTime    = if ($null -ne $runspace.RunningTime) { $runspace.RunningTime } else { ([datetime]::Now - $runspace.StartTime) }
                        DeadlockTime   = if ($null -ne $runspace.DeadlockTime) { $runspace.DeadlockTime } else { [datetime]::Now }
                        DeadlockReason = if ($null -ne $runspace.DeadlockReason) { $runspace.DeadlockReason } else { "Détection de deadlock standard" }
                        HasErrors      = if ($null -ne $runspace.PowerShell) { $runspace.PowerShell.HadErrors } else { $false }
                        ErrorCount     = if ($null -ne $runspace.Errors) { $runspace.Errors.Count } else { 0 }
                    }
                    $deadlockAnalysis.DeadlockedRunspaces += $runspaceInfo
                }
            }

            Write-Verbose "Analyse de deadlock: $($deadlockAnalysis.StoppedCount) runspaces en deadlock après $($deadlockAnalysis.TimeSinceLastProgress) secondes sans progression."
        }

        # Créer une nouvelle List<object> avec les résultats
        $finalResult = [System.Collections.Generic.List[object]]::new()

        # Ajouter chaque élément individuellement pour s'assurer que nous avons une List<object>
        foreach ($item in $completedRunspaces) {
            $finalResult.Add($item)
        }

        # Si on n'attend pas tous les runspaces, on ne devrait retourner qu'un seul élément
        if (-not $WaitForAll -and $finalResult.Count -gt 1) {
            Write-Warning "Le résultat contient $($finalResult.Count) éléments au lieu de 1. Correction."
            $singleResult = [System.Collections.Generic.List[object]]::new(1)
            if ($finalResult.Count -gt 0) {
                $singleResult.Add($finalResult[0])
            }

            # Vérifier explicitement que nous avons une List<object> avec un seul élément
            Write-Verbose "Type de retour final: $($singleResult.GetType().FullName), Count: $($singleResult.Count)"

            # Retourner explicitement la List<object> en l'encapsulant dans un PSCustomObject
            $resultObject = [PSCustomObject]@{
                Results          = $singleResult
                TimeoutOccurred  = $timeoutOccurred
                DeadlockDetected = $deadlockDetected
                StoppedRunspaces = $stoppedRunspaces
                DeadlockAnalysis = $deadlockAnalysis
            }
        } else {
            # Vérifier explicitement que nous avons une List<object>
            Write-Verbose "Type de retour final: $($finalResult.GetType().FullName), Count: $($finalResult.Count)"

            # Retourner explicitement la List<object> en l'encapsulant dans un PSCustomObject
            $resultObject = [PSCustomObject]@{
                Results          = $finalResult
                TimeoutOccurred  = $timeoutOccurred
                DeadlockDetected = $deadlockDetected
                StoppedRunspaces = $stoppedRunspaces
                DeadlockAnalysis = $deadlockAnalysis
            }
        }

        # Ajouter une méthode pour accéder à la List<object>
        $resultObject | Add-Member -MemberType ScriptMethod -Name "GetList" -Value {
            return $this.Results
        } -Force

        # Maintenir la compatibilité avec l'ancienne méthode GetArrayList
        $resultObject | Add-Member -MemberType ScriptMethod -Name "GetArrayList" -Value {
            Write-Warning "La méthode GetArrayList est obsolète. Utilisez GetList à la place."
            return $this.Results
        } -Force

        # Ajouter une méthode pour accéder au premier élément
        $resultObject | Add-Member -MemberType ScriptMethod -Name "GetFirst" -Value {
            if ($this.Results.Count -gt 0) {
                return $this.Results[0]
            }
            return $null
        } -Force

        # Ajouter une propriété Count seulement si elle n'existe pas déjà
        # ou si elle n'est pas définie correctement pour les tableaux vides
        if (-not $resultObject.PSObject.Properties.Match('Count').Count -or
            ($resultObject.Results.Count -eq 0 -and $resultObject.Count -ne 0)) {

            # Pour les tableaux vides, définir Count à 0 explicitement
            if ($resultObject.Results.Count -eq 0) {
                Write-Verbose "Définition de Count=0 pour un tableau vide"
                $resultObject.PSObject.Properties.Remove('Count')
                $resultObject | Add-Member -MemberType NoteProperty -Name "Count" -Value 0 -Force
            } else {
                # Pour les autres cas, utiliser une ScriptProperty qui retourne le nombre d'éléments dans Results
                Write-Verbose "Définition de Count comme ScriptProperty pour un tableau non-vide"
                $resultObject | Add-Member -MemberType ScriptProperty -Name "Count" -Value {
                    return $this.Results.Count
                } -Force
            }
        } else {
            Write-Verbose "La propriété Count existe déjà avec la valeur: $($resultObject.Count)"
        }

        # Ajouter un indexeur
        $resultObject | Add-Member -MemberType ScriptMethod -Name "get_Item" -Value {
            param($index)
            return $this.Results[$index]
        } -Force

        # Ajouter une méthode pour vérifier si un timeout s'est produit
        $resultObject | Add-Member -MemberType ScriptMethod -Name "HasTimeout" -Value {
            return $this.TimeoutOccurred
        } -Force

        # Ajouter une méthode pour vérifier si un deadlock a été détecté
        $resultObject | Add-Member -MemberType ScriptMethod -Name "HasDeadlock" -Value {
            return $this.DeadlockDetected
        } -Force

        # Ajouter une méthode pour obtenir un rapport de deadlock
        $resultObject | Add-Member -MemberType ScriptMethod -Name "GetDeadlockReport" -Value {
            if (-not $this.DeadlockDetected) {
                return "Aucun deadlock détecté."
            }

            $report = "Rapport de deadlock:`n"
            if ($null -ne $this.DeadlockAnalysis) {
                $report += "- Seuil de détection: $($this.DeadlockAnalysis.DetectionThreshold) secondes`n"
                $report += "- Temps écoulé depuis le dernier progrès: $($this.DeadlockAnalysis.TimeSinceLastProgress) secondes`n"
                $report += "- Runspaces complétés: $($this.DeadlockAnalysis.CompletedCount) / $($this.DeadlockAnalysis.TotalCount)`n"
                $report += "- Runspaces arrêtés: $($this.DeadlockAnalysis.StoppedCount)`n"

                if ($this.DeadlockAnalysis.DeadlockedRunspaces.Count -gt 0) {
                    $report += "- Runspaces en deadlock:`n"
                    foreach ($runspace in $this.DeadlockAnalysis.DeadlockedRunspaces) {
                        $report += "  - ID: $($runspace.RunspaceId), Temps d'exécution: $($runspace.RunningTime.TotalSeconds) secondes`n"
                    }
                }
            } else {
                $report += "- Aucune analyse de deadlock disponible.`n"
            }

            return $report
        } -Force

        # Ajouter une méthode pour obtenir les runspaces arrêtés
        $resultObject | Add-Member -MemberType ScriptMethod -Name "GetStoppedRunspaces" -Value {
            return $this.StoppedRunspaces
        } -Force

        # Ajouter une méthode pour obtenir l'analyse des deadlocks
        $resultObject | Add-Member -MemberType ScriptMethod -Name "GetDeadlockAnalysis" -Value {
            return $this.DeadlockAnalysis
        } -Force

        # Si on n'attend pas tous les runspaces, on doit s'assurer que Runspaces ne contient que les runspaces restants
        if (-not $WaitForAll) {
            # Supprimer tous les runspaces complétés de la liste originale
            # Vérifier le type de collection pour utiliser la méthode appropriée
            if ($Runspaces -is [System.Collections.Generic.List[PSObject]] -or
                $Runspaces -is [System.Collections.Generic.List[object]]) {
                # Pour List<T>, utiliser RemoveAt
                for ($i = $Runspaces.Count - 1; $i -ge 0; $i--) {
                    $runspace = $Runspaces[$i]
                    if ($null -ne $runspace -and $null -ne $runspace.Handle -and $runspace.Handle.IsCompleted) {
                        $Runspaces.RemoveAt($i)
                    }
                }
            } elseif ($Runspaces -is [System.Collections.ArrayList]) {
                # Pour ArrayList, utiliser RemoveAt
                for ($i = $Runspaces.Count - 1; $i -ge 0; $i--) {
                    $runspace = $Runspaces[$i]
                    if ($null -ne $runspace -and $null -ne $runspace.Handle -and $runspace.Handle.IsCompleted) {
                        $Runspaces.RemoveAt($i)
                    }
                }
            } elseif ($Runspaces -is [array] -or $Runspaces -is [System.Array]) {
                # Pour les tableaux, créer un nouveau tableau filtré
                # Note: Les tableaux sont immuables, donc on ne peut pas les modifier directement
                Write-Verbose "Runspaces est un tableau immuable. Création d'un nouveau tableau filtré."
                $filteredRunspaces = $Runspaces | Where-Object {
                    $null -eq $_ -or $null -eq $_.Handle -or -not $_.Handle.IsCompleted
                }
                # Remplacer la référence au tableau original (ne fonctionne que si $Runspaces est une variable)
                # Cette opération n'est pas idéale car elle dépend du contexte d'appel
                # Mais c'est la meilleure solution pour les tableaux immuables
                try {
                    $Runspaces = $filteredRunspaces
                } catch {
                    Write-Warning "Impossible de mettre à jour la référence au tableau Runspaces: $_"
                }
            }
        }

        # Mettre en cache le résultat pour les futures utilisations si c'est un tableau vide
        if ($finalResult.Count -eq 0) {
            $cacheKey = "EmptyArray_$ReturnFormat"
            if (-not $script:EmptyResultsCache.ContainsKey($cacheKey)) {
                Write-Verbose "Mise en cache du résultat pour les tableaux vides avec ReturnFormat=$ReturnFormat"
                $script:EmptyResultsCache[$cacheKey] = $resultObject
            }
        }

        # Convertir le résultat au format demandé
        if ($ReturnFormat -eq "Array" -and $resultObject.GetType().Name -eq "PSCustomObject") {
            Write-Verbose "Conversion du résultat en tableau selon le paramètre ReturnFormat=Array"
            # Convertir l'objet en tableau
            $arrayResult = @()
            foreach ($item in $resultObject.Results) {
                $arrayResult += $item
            }
            return $arrayResult
        } else {
            # Retourner l'objet tel quel
            return $resultObject
        }
    }
}

# Fonction de traitement des runspaces complétés
function Invoke-RunspaceProcessor {
    <#
    .SYNOPSIS
        Traite les runspaces complétés et récupère leurs résultats.

    .DESCRIPTION
        Cette fonction traite les runspaces complétés, récupère leurs résultats et nettoie les ressources.
        Elle gère également les erreurs qui peuvent survenir lors de l'exécution des runspaces.

        La fonction accepte différents types de collections pour le paramètre CompletedRunspaces
        et effectue automatiquement les conversions nécessaires.

    .PARAMETER CompletedRunspaces
        Liste des runspaces complétés à traiter. Chaque élément doit être un objet avec les propriétés
        PowerShell (instance PowerShell) et Handle (IAsyncResult).

        Ce paramètre accepte différents types de collections qui seront automatiquement convertis en List<object> :
        - System.Collections.Generic.List<object> (aucune conversion nécessaire)
        - System.Collections.ArrayList
        - System.Collections.Concurrent.ConcurrentBag<object>
        - Array ou System.Array
        - Object[]
        - Tout objet implémentant IEnumerable
        - Tout objet avec les propriétés Count et Item
        - Un objet unique (sera ajouté à une nouvelle List<object>)

        La fonction effectue automatiquement la conversion appropriée en fonction du type d'entrée.

    .PARAMETER IgnoreErrors
        Si spécifié, les erreurs survenues lors du traitement des runspaces ne sont pas affichées
        dans la console, mais sont toujours incluses dans les résultats.

        Par défaut : $false (les erreurs sont affichées)

    .PARAMETER NoProgress
        Si spécifié, n'affiche pas de barre de progression.

        Par défaut : $false (affiche une barre de progression)

    .PARAMETER ActivityName
        Nom de l'activité à afficher dans la barre de progression.

        Par défaut : "Traitement des résultats"

    .PARAMETER SimpleResults
        Si spécifié, retourne uniquement la liste des résultats sans les métriques.
        Sinon, retourne un objet détaillé incluant les résultats, les erreurs et les métriques.

        Par défaut : $false (retourne les résultats détaillés)

    .EXAMPLE
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll
        $results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces

        Traite tous les runspaces complétés et retourne les résultats détaillés.
        $results.Results contient les résultats individuels.
        $results.Errors contient les erreurs éventuelles.
        $results.SuccessCount indique le nombre de runspaces traités avec succès.

    .EXAMPLE
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll
        $results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces -IgnoreErrors -NoProgress

        Traite tous les runspaces complétés sans afficher les erreurs ni la barre de progression.

    .EXAMPLE
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll
        $simpleResults = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces -SimpleResults

        Traite tous les runspaces complétés et retourne uniquement la liste des résultats.
        $simpleResults est une List<object> contenant directement les objets résultats.

    .OUTPUTS
        System.Management.Automation.PSObject

        Un objet avec les propriétés et méthodes suivantes :
        - Results : Liste des résultats de chaque runspace (System.Collections.Generic.List<object>)
        - Errors : Liste des erreurs survenues
        - TotalProcessed : Nombre total de runspaces traités
        - SuccessCount : Nombre de runspaces traités avec succès
        - ErrorCount : Nombre de runspaces ayant généré une erreur
        - Count : Nombre de résultats (propriété)
        - GetList() : Méthode pour obtenir la List<object> des résultats
        - GetFirst() : Méthode pour obtenir le premier résultat
        - [index] : Indexeur pour accéder aux résultats par leur index

        Ce format est standardisé pour être cohérent avec le format de retour de Wait-ForCompletedRunspace,
        ce qui facilite l'utilisation des deux fonctions ensemble.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Liste des runspaces complétés à traiter")]
        [AllowNull()]
        [object]$CompletedRunspaces,

        [Parameter(Mandatory = $false, HelpMessage = "Ignorer les erreurs lors du traitement")]
        [switch]$IgnoreErrors,

        [Parameter(Mandatory = $false, HelpMessage = "Ne pas afficher de barre de progression")]
        [switch]$NoProgress,

        [Parameter(Mandatory = $false, HelpMessage = "Nom de l'activité à afficher dans la barre de progression")]
        [string]$ActivityName = "Traitement des résultats",

        [Parameter(Mandatory = $false, HelpMessage = "Retourner uniquement la liste des résultats sans les métriques")]
        [switch]$SimpleResults
    )

    begin {
        # Initialiser les collections de résultats avec ConcurrentBag pour thread-safety
        $results = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
        $errors = [System.Collections.Concurrent.ConcurrentBag[object]]::new()

        # Convertir CompletedRunspaces en List<T> pour de meilleures performances
        $runspacesToProcess = [System.Collections.Generic.List[object]]::new()

        # Vérifier le type de CompletedRunspaces et effectuer la conversion appropriée
        if ($null -eq $CompletedRunspaces) {
            Write-Verbose "CompletedRunspaces est null. Aucun runspace à traiter."
            return
        }

        # Vérifier si CompletedRunspaces est un objet retourné par Wait-ForCompletedRunspace
        elseif ($CompletedRunspaces.PSObject.Properties.Match('Results').Count -gt 0 -and
            $CompletedRunspaces.PSObject.Properties.Match('GetList').Count -gt 0) {
            Write-Verbose "CompletedRunspaces est un objet retourné par Wait-ForCompletedRunspace. Utilisation de la propriété Results."

            # Utiliser la méthode GetList() pour obtenir la List<object>
            try {
                $runspacesCollection = $CompletedRunspaces.GetList()
                Write-Verbose "Méthode GetList() utilisée avec succès. Type: $($runspacesCollection.GetType().FullName)"

                # Filtrer les éléments null
                $filteredList = [System.Collections.Generic.List[object]]::new()
                foreach ($item in $runspacesCollection) {
                    if ($null -ne $item) {
                        $filteredList.Add($item)
                    }
                }
                $runspacesToProcess = $filteredList
            }
            # Si GetList() échoue, essayer d'utiliser la propriété Results directement
            catch {
                Write-Verbose "Méthode GetList() a échoué: $_. Utilisation de la propriété Results directement."
                $runspacesCollection = $CompletedRunspaces.Results

                # Filtrer les éléments null
                $filteredList = [System.Collections.Generic.List[object]]::new()
                foreach ($item in $runspacesCollection) {
                    if ($null -ne $item) {
                        $filteredList.Add($item)
                    }
                }
                $runspacesToProcess = $filteredList
            }
        }

        elseif ($CompletedRunspaces -is [System.Collections.Generic.List[object]]) {
            Write-Verbose "CompletedRunspaces est déjà une List<object>. Aucune conversion nécessaire."
            # Filtrer les éléments null
            $filteredList = [System.Collections.Generic.List[object]]::new()
            foreach ($item in $CompletedRunspaces) {
                if ($null -ne $item) {
                    $filteredList.Add($item)
                }
            }
            $runspacesToProcess = $filteredList
        }

        elseif ($CompletedRunspaces -is [System.Collections.ArrayList]) {
            Write-Verbose "CompletedRunspaces est un ArrayList. Conversion en List<object>."
            foreach ($runspace in $CompletedRunspaces) {
                if ($null -ne $runspace) {
                    $runspacesToProcess.Add($runspace)
                }
            }
        }

        elseif ($CompletedRunspaces -is [System.Collections.Concurrent.ConcurrentBag[object]]) {
            Write-Verbose "CompletedRunspaces est un ConcurrentBag. Conversion en List<object>."
            foreach ($runspace in $CompletedRunspaces) {
                if ($null -ne $runspace) {
                    $runspacesToProcess.Add($runspace)
                }
            }
        }

        elseif ($CompletedRunspaces -is [array] -or $CompletedRunspaces -is [System.Array]) {
            Write-Verbose "CompletedRunspaces est un tableau. Conversion en List<object>."
            # Optimisation: préallouer la capacité si possible
            if ($CompletedRunspaces.Length -gt 0) {
                $runspacesToProcess = [System.Collections.Generic.List[object]]::new($CompletedRunspaces.Length)
            }
            foreach ($runspace in $CompletedRunspaces) {
                if ($null -ne $runspace) {
                    $runspacesToProcess.Add($runspace)
                }
            }
        }

        elseif ($CompletedRunspaces.GetType().Name -eq 'Object[]') {
            Write-Verbose "CompletedRunspaces est un tableau d'objets. Conversion en List<object>."
            # Optimisation: préallouer la capacité si possible
            if ($CompletedRunspaces.Length -gt 0) {
                $runspacesToProcess = [System.Collections.Generic.List[object]]::new($CompletedRunspaces.Length)
            }
            foreach ($runspace in $CompletedRunspaces) {
                if ($null -ne $runspace) {
                    $runspacesToProcess.Add($runspace)
                }
            }
        }

        elseif ($CompletedRunspaces.GetType().GetInterfaces().Name -contains 'IEnumerable') {
            Write-Verbose "CompletedRunspaces implémente IEnumerable. Conversion en List<object>."
            foreach ($runspace in $CompletedRunspaces) {
                if ($null -ne $runspace) {
                    $runspacesToProcess.Add($runspace)
                }
            }
        }

        elseif ($CompletedRunspaces.PSObject.Properties.Match('Count').Count -gt 0 -and
            $CompletedRunspaces.PSObject.Properties.Match('Item').Count -gt 0) {
            Write-Verbose "CompletedRunspaces semble être une collection. Conversion en List<object>."
            # Optimisation: préallouer la capacité si possible
            if ($CompletedRunspaces.Count -gt 0) {
                $runspacesToProcess = [System.Collections.Generic.List[object]]::new($CompletedRunspaces.Count)
            }
            for ($i = 0; $i -lt $CompletedRunspaces.Count; $i++) {
                $item = $CompletedRunspaces.Item($i)
                if ($null -ne $item) {
                    $runspacesToProcess.Add($item)
                }
            }
        }

        else {
            # Si c'est un objet unique, l'ajouter directement
            Write-Verbose "CompletedRunspaces est un objet unique. Ajout à la List<object>."
            if ($null -ne $CompletedRunspaces) {
                $runspacesToProcess.Add($CompletedRunspaces)
            }
        }

        $totalRunspaces = $runspacesToProcess.Count
        $processedRunspaces = 0

        Write-Verbose "Nombre total de runspaces à traiter après conversion : $totalRunspaces"
    }

    process {
        if ($null -eq $runspacesToProcess -or $runspacesToProcess.Count -eq 0) {
            Write-Verbose "Aucun runspace à traiter."
            return [PSCustomObject]@{
                Results        = $results
                Errors         = $errors
                TotalProcessed = 0
                SuccessCount   = 0
                ErrorCount     = 0
            }
        }

        Write-Verbose "Traitement de $($runspacesToProcess.Count) runspaces complétés..."

        # Initialiser la barre de progression
        if (-not $NoProgress) {
            $progressParams = @{
                Activity        = $ActivityName
                Status          = "Traitement des résultats..."
                PercentComplete = 0
            }
            Write-Progress @progressParams
        }

        # Traiter les runspaces complétés
        foreach ($runspace in $runspacesToProcess) {
            try {
                # Vérifier si le runspace est valide
                if ($null -eq $runspace) {
                    Write-Debug "Runspace null détecté. Ignoré."
                    continue
                }

                # Vérifier si c'est un objet de test ou un objet simple
                if ($null -eq $runspace.PowerShell -or $null -eq $runspace.Handle) {
                    # Déterminer si c'est un objet de test avec Value ou Item
                    $hasValue = $runspace.PSObject.Properties.Match('Value').Count -gt 0
                    $hasItem = $runspace.PSObject.Properties.Match('Item').Count -gt 0

                    if ($hasValue -or $hasItem) {
                        # C'est un objet de test ou un objet simple, traiter directement
                        $resultObject = [PSCustomObject]@{
                            Value     = if ($hasValue) { $runspace.Value } elseif ($hasItem) { $runspace.Item } else { $null }
                            Success   = $true
                            Error     = $null
                            StartTime = [datetime]::Now
                            EndTime   = [datetime]::Now
                            Duration  = [timespan]::Zero
                            ThreadId  = -1
                            Item      = if ($hasItem) { $runspace.Item } else { $null }
                        }

                        # Ajouter le résultat à la ConcurrentBag
                        $results.Add($resultObject)
                        Write-Debug "Objet simple traité: Value=$($resultObject.Value), Item=$($resultObject.Item)"
                        continue
                    } else {
                        # Objet invalide sans propriétés utiles
                        Write-Debug "Objet invalide sans propriétés Value ou Item. Type: $($runspace.GetType().FullName)"
                        continue
                    }
                }

                # Vérifier si le handle est complété
                if (-not $runspace.Handle.IsCompleted) {
                    Write-Debug "Runspace non complété détecté. Ignoré."
                    continue
                }

                # Récupérer le résultat
                $runspaceResult = $runspace.PowerShell.EndInvoke($runspace.Handle)

                # Créer un objet résultat simple
                $resultObject = [PSCustomObject]@{
                    Value     = if ($runspaceResult -and $runspaceResult.PSObject.Properties.Match('Output').Count) { $runspaceResult.Output } else { $runspaceResult }
                    Success   = if ($runspaceResult -and $runspaceResult.PSObject.Properties.Match('Success').Count) { $runspaceResult.Success } else { $true }
                    Error     = if ($runspaceResult -and $runspaceResult.PSObject.Properties.Match('Error').Count) { $runspaceResult.Error } else { $null }
                    StartTime = if ($runspaceResult -and $runspaceResult.PSObject.Properties.Match('StartTime').Count) { $runspaceResult.StartTime } else { [datetime]::Now }
                    EndTime   = if ($runspaceResult -and $runspaceResult.PSObject.Properties.Match('EndTime').Count) { $runspaceResult.EndTime } else { [datetime]::Now }
                    Duration  = if ($runspaceResult -and $runspaceResult.PSObject.Properties.Match('Duration').Count) { $runspaceResult.Duration } else { [timespan]::Zero }
                    ThreadId  = if ($runspaceResult -and $runspaceResult.PSObject.Properties.Match('ThreadId').Count) { $runspaceResult.ThreadId } else { -1 }
                    Item      = if ($runspace.PSObject.Properties.Match('Item').Count) { $runspace.Item } else { $null }
                }

                # Ajouter le résultat à la ConcurrentBag
                $results.Add($resultObject)

                # Si c'est une erreur, l'ajouter à la ConcurrentBag des erreurs
                if (-not $resultObject.Success -and $resultObject.Error) {
                    $errors.Add($resultObject.Error)
                }
            } catch {
                $errorParams = @{
                    Message        = "Erreur lors du traitement du runspace"
                    Source         = "Invoke-RunspaceProcessor"
                    ErrorRecord    = $_
                    Category       = [System.Management.Automation.ErrorCategory]::OperationStopped
                    AdditionalInfo = @{
                        "RunspaceType"   = if ($runspace) { $runspace.GetType().FullName } else { "Unknown" }
                        "ProcessedItems" = $processedRunspaces
                        "TotalItems"     = $totalRunspaces
                    }
                }

                if (-not $IgnoreErrors) {
                    New-UnifiedError @errorParams -WriteError
                } else {
                    New-UnifiedError @errorParams
                }

                # Créer un résultat d'erreur
                $resultObject = [PSCustomObject]@{
                    Value     = $null
                    Success   = $false
                    Error     = $_
                    StartTime = [datetime]::Now
                    EndTime   = [datetime]::Now
                    Duration  = [timespan]::Zero
                    ThreadId  = -1
                    Item      = if ($runspace -and $runspace.PSObject.Properties.Match('Item').Count) { $runspace.Item } else { $null }
                }
                $results.Add($resultObject)
                $errors.Add($_)
            } finally {
                # Nettoyer le runspace
                if ($runspace -and $runspace.PowerShell) {
                    $runspace.PowerShell.Dispose()
                }

                $processedRunspaces++

                # Mettre à jour la barre de progression
                if (-not $NoProgress -and $totalRunspaces -gt 0) {
                    $percentComplete = [Math]::Min(100, [Math]::Floor(($processedRunspaces / $totalRunspaces) * 100))
                    $progressParams = @{
                        Activity        = $ActivityName
                        Status          = "Traitement du résultat $processedRunspaces sur $totalRunspaces"
                        PercentComplete = $percentComplete
                    }
                    Write-Progress @progressParams
                }
            }
        }

        # Terminer la barre de progression
        if (-not $NoProgress) {
            Write-Progress -Activity $ActivityName -Completed
        }
    }

    end {
        # Convertir les ConcurrentBag en List<T> pour le retour
        $resultsList = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $results) {
            $resultsList.Add($item)
        }

        $errorsList = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $errors) {
            $errorsList.Add($item)
        }

        $successCount = ($resultsList | Where-Object { $_.Success }).Count
        $errorCount = $errorsList.Count

        Write-Verbose "$($resultsList.Count) résultats traités, $errorCount erreurs."

        # Retourner les résultats selon le paramètre SimpleResults
        if ($SimpleResults) {
            return $resultsList
        } else {
            # Créer l'objet de résultats détaillés avec un format standardisé
            $detailedResults = [PSCustomObject]@{
                Results        = $resultsList
                Errors         = $errorsList
                TotalProcessed = $processedRunspaces
                SuccessCount   = $successCount
                ErrorCount     = $errorCount
            }

            # Ajouter des méthodes et propriétés pour standardiser le format de retour
            # et assurer la compatibilité avec Wait-ForCompletedRunspace

            # Ajouter une méthode pour accéder à la List<object>
            $detailedResults | Add-Member -MemberType ScriptMethod -Name "GetList" -Value {
                return $this.Results
            }

            # Ajouter une propriété Count
            $detailedResults | Add-Member -MemberType ScriptProperty -Name "Count" -Value {
                return $this.Results.Count
            } -Force

            # Ajouter un indexeur
            $detailedResults | Add-Member -MemberType ScriptMethod -Name "get_Item" -Value {
                param($index)
                return $this.Results[$index]
            }

            # Ajouter une méthode pour obtenir le premier élément
            $detailedResults | Add-Member -MemberType ScriptMethod -Name "GetFirst" -Value {
                if ($this.Results.Count -gt 0) {
                    return $this.Results[0]
                }
                return $null
            }

            return $detailedResults
        }
    }
}

# Fonction de détermination du nombre optimal de threads
function Get-OptimalThreadCount {
    <#
    .SYNOPSIS
        Détermine le nombre optimal de threads à utiliser pour les opérations parallèles.

    .DESCRIPTION
        Cette fonction calcule le nombre optimal de threads à utiliser pour les opérations parallèles
        en fonction du type de tâche, de la charge système actuelle et d'autres facteurs.

        Elle prend en compte différents types de tâches (CPU, IO, Mixed, etc.) et peut ajuster
        dynamiquement le nombre de threads en fonction de la charge système actuelle.

    .PARAMETER TaskType
        Spécifie le type de tâche à exécuter. Les valeurs possibles sont :
        - Default : Utilise un facteur d'ajustement de 1.0 (équivalent à CPU)
        - CPU : Optimisé pour les tâches intensives en calcul (facteur 1.0)
        - IO : Optimisé pour les tâches intensives en entrées/sorties (facteur 3.0)
        - Mixed : Optimisé pour les tâches mixtes CPU/IO (facteur 2.0)
        - LowPriority : Utilise moins de ressources (facteur 0.5)
        - HighPriority : Utilise plus de ressources (facteur 4.0)

    .PARAMETER SystemLoadPercent
        Spécifie la charge système actuelle en pourcentage (0-100).
        Cette valeur est utilisée pour ajuster le nombre de threads si le paramètre Dynamic est spécifié.

    .PARAMETER ConsiderMemory
        Indique si la fonction doit prendre en compte l'utilisation de la mémoire pour ajuster le nombre de threads.

    .PARAMETER ConsiderDiskIO
        Indique si la fonction doit prendre en compte l'utilisation des E/S disque pour ajuster le nombre de threads.
        Particulièrement utile pour les tâches de type IO.

    .PARAMETER ConsiderNetworkIO
        Indique si la fonction doit prendre en compte l'utilisation du réseau pour ajuster le nombre de threads.
        Particulièrement utile pour les tâches de type IO.

    .PARAMETER Dynamic
        Indique si la fonction doit ajuster dynamiquement le nombre de threads en fonction de la charge système.
        Si ce paramètre est spécifié, le nombre de threads sera réduit lorsque la charge système est élevée.

    .EXAMPLE
        Get-OptimalThreadCount -TaskType 'CPU'

        Retourne le nombre optimal de threads pour les tâches intensives en calcul.

    .EXAMPLE
        Get-OptimalThreadCount -TaskType 'IO' -ConsiderDiskIO -Dynamic

        Retourne le nombre optimal de threads pour les tâches intensives en E/S,
        en tenant compte de l'utilisation du disque et en ajustant dynamiquement
        en fonction de la charge système.

    .EXAMPLE
        Get-OptimalThreadCount -TaskType 'Mixed' -SystemLoadPercent 75 -Dynamic

        Retourne le nombre optimal de threads pour les tâches mixtes,
        en tenant compte d'une charge système de 75% et en ajustant dynamiquement.

    .OUTPUTS
        System.Int32

        Retourne le nombre optimal de threads à utiliser.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Type de tâche à exécuter (CPU, IO, Mixed, etc.)")]
        [ValidateSet('Default', 'CPU', 'IO', 'Mixed', 'LowPriority', 'HighPriority')]
        [string]$TaskType = 'Default',

        [Parameter(Mandatory = $false, HelpMessage = "Charge système actuelle en pourcentage (0-100)")]
        [ValidateRange(0, 100)]
        [int]$SystemLoadPercent = 0,

        [Parameter(Mandatory = $false, HelpMessage = "Prendre en compte l'utilisation de la mémoire")]
        [switch]$ConsiderMemory,

        [Parameter(Mandatory = $false, HelpMessage = "Prendre en compte l'utilisation des E/S disque")]
        [switch]$ConsiderDiskIO,

        [Parameter(Mandatory = $false, HelpMessage = "Prendre en compte l'utilisation du réseau")]
        [switch]$ConsiderNetworkIO,

        [Parameter(Mandatory = $false, HelpMessage = "Ajuster dynamiquement en fonction de la charge système")]
        [switch]$Dynamic
    )

    begin {
        # Obtenir le nombre de processeurs logiques
        $processorCount = [Environment]::ProcessorCount
        $optimalThreads = $processorCount

        # Facteurs d'ajustement selon le type de tâche
        $taskTypeFactors = @{
            'Default'      = 1.0
            'CPU'          = 1.0
            'IO'           = 3.0
            'Mixed'        = 2.0
            'LowPriority'  = 0.5
            'HighPriority' = 4.0
        }

        # Obtenir les métriques système si disponibles
        $cpuUsage = 0
        $memoryUsage = 0
        $diskIOUsage = 0
        $networkIOUsage = 0

        if ($script:ResourceMonitor -and $script:ResourceMonitor.IsActive) {
            # Utiliser les métriques du moniteur de ressources
            if ($script:ResourceMonitor.Metrics.ContainsKey('CPU')) {
                $cpuUsage = $script:ResourceMonitor.Metrics['CPU']
            }

            if ($ConsiderMemory -and $script:ResourceMonitor.Metrics.ContainsKey('Memory')) {
                $memoryUsage = $script:ResourceMonitor.Metrics['Memory']
            }

            if ($ConsiderDiskIO -and $script:ResourceMonitor.Metrics.ContainsKey('DiskIO')) {
                $diskIOUsage = $script:ResourceMonitor.Metrics['DiskIO']
            }

            if ($ConsiderNetworkIO -and $script:ResourceMonitor.Metrics.ContainsKey('NetworkIO')) {
                $networkIOUsage = $script:ResourceMonitor.Metrics['NetworkIO']
            }
        } else {
            # Utiliser la charge système spécifiée
            $cpuUsage = $SystemLoadPercent
        }
    }

    process {
        # Calculer le nombre optimal de threads selon le type de tâche
        $taskFactor = $taskTypeFactors[$TaskType]
        $baseThreads = [Math]::Ceiling($processorCount * $taskFactor)

        # Ajuster selon la charge système
        if ($Dynamic) {
            # Plus la charge CPU est élevée, moins on utilise de threads
            $cpuFactor = [Math]::Max(0.1, 1.0 - ($cpuUsage / 100.0))
            $baseThreads = [Math]::Ceiling($baseThreads * $cpuFactor)

            # Ajuster selon la mémoire si demandé
            if ($ConsiderMemory) {
                $memoryFactor = [Math]::Max(0.1, 1.0 - ($memoryUsage / 100.0))
                $baseThreads = [Math]::Ceiling($baseThreads * $memoryFactor)
            }

            # Ajuster selon l'IO disque si demandé
            if ($ConsiderDiskIO -and $TaskType -eq 'IO') {
                $diskFactor = [Math]::Max(0.1, 1.0 - ($diskIOUsage / 100.0))
                $baseThreads = [Math]::Ceiling($baseThreads * $diskFactor)
            }

            # Ajuster selon l'IO réseau si demandé
            if ($ConsiderNetworkIO -and $TaskType -eq 'IO') {
                $networkFactor = [Math]::Max(0.1, 1.0 - ($networkIOUsage / 100.0))
                $baseThreads = [Math]::Ceiling($baseThreads * $networkFactor)
            }
        }

        # Limites minimales et maximales
        $minThreads = 1
        $maxThreads = switch ($TaskType) {
            'CPU' { $processorCount * 2 }
            'IO' { $processorCount * 8 }
            'Mixed' { $processorCount * 4 }
            'LowPriority' { $processorCount }
            'HighPriority' { $processorCount * 16 }
            default { $processorCount * 4 }
        }

        # Appliquer les limites
        $optimalThreads = [Math]::Max($minThreads, [Math]::Min($baseThreads, $maxThreads))
    }

    end {
        Write-Verbose "Nombre optimal de threads pour le type de tâche '$TaskType': $optimalThreads"
        return $optimalThreads
    }
}

# Fonction pour créer des runspaces en batch
function New-RunspaceBatch {
    <#
    .SYNOPSIS
        Crée un lot de runspaces pour l'exécution parallèle.

    .DESCRIPTION
        Cette fonction crée un lot de runspaces pour l'exécution parallèle, ce qui réduit
        l'overhead lié à la création individuelle des runspaces. Elle prend en charge
        différentes configurations et options pour personnaliser les runspaces créés.

    .PARAMETER RunspacePool
        Pool de runspaces à utiliser pour les runspaces créés.
        Ce paramètre est obligatoire.

    .PARAMETER ScriptBlock
        Script block à exécuter dans chaque runspace.
        Ce paramètre est obligatoire si Command n'est pas spécifié.

    .PARAMETER Command
        Commande à exécuter dans chaque runspace.
        Ce paramètre est obligatoire si ScriptBlock n'est pas spécifié.

    .PARAMETER InputObjects
        Collection d'objets à traiter en parallèle. Chaque objet sera passé à un runspace.
        Ce paramètre est obligatoire.

    .PARAMETER ArgumentList
        Table de hachage des arguments supplémentaires à passer à chaque runspace.
        Clé = nom du paramètre, Valeur = valeur du paramètre.

    .PARAMETER BatchSize
        Nombre de runspaces à créer par lot. Une valeur plus élevée peut améliorer les performances
        mais augmente l'utilisation de la mémoire.

        Par défaut : 10

    .PARAMETER ParameterName
        Nom du paramètre à utiliser pour passer l'objet d'entrée au script block ou à la commande.

        Par défaut : "Item"

    .PARAMETER ThrottleLimit
        Limite de throttling pour contrôler le nombre maximum de runspaces à créer.
        Si 0, aucune limite n'est appliquée.

        Par défaut : 0 (pas de limite)

    .EXAMPLE
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4)
        $runspacePool.Open()
        $scriptBlock = { param($item) "Traitement de $item" }
        $inputObjects = 1..100
        $runspaces = New-RunspaceBatch -RunspacePool $runspacePool -ScriptBlock $scriptBlock -InputObjects $inputObjects -BatchSize 20

        Crée 100 runspaces en lots de 20 pour traiter les nombres de 1 à 100.

    .EXAMPLE
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4)
        $runspacePool.Open()
        $runspaces = New-RunspaceBatch -RunspacePool $runspacePool -Command "Get-Process" -InputObjects @("powershell", "explorer") -ParameterName "Name" -ArgumentList @{ "ErrorAction" = "SilentlyContinue" }

        Crée 2 runspaces pour exécuter Get-Process sur les processus "powershell" et "explorer".

    .OUTPUTS
        System.Collections.Generic.List[PSObject]

        Une liste d'objets représentant les runspaces créés. Chaque objet a les propriétés suivantes :
        - PowerShell : Instance PowerShell du runspace
        - Handle : Handle d'exécution asynchrone
        - Item : Objet d'entrée associé au runspace
        - StartTime : Heure de début de l'exécution
        - BatchIndex : Index du lot auquel appartient le runspace
    #>
    [CmdletBinding(DefaultParameterSetName = "ScriptBlock")]
    [OutputType([System.Collections.Generic.List[PSObject]])]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Pool de runspaces à utiliser")]
        [ValidateNotNull()]
        [System.Management.Automation.Runspaces.RunspacePool]$RunspacePool,

        [Parameter(Mandatory = $true, ParameterSetName = "ScriptBlock", Position = 1, HelpMessage = "Script block à exécuter")]
        [ValidateNotNull()]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $true, ParameterSetName = "Command", Position = 1, HelpMessage = "Commande à exécuter")]
        [ValidateNotNullOrEmpty()]
        [string]$Command,

        [Parameter(Mandatory = $true, Position = 2, HelpMessage = "Collection d'objets à traiter")]
        [ValidateNotNull()]
        [object[]]$InputObjects,

        [Parameter(Mandatory = $false, HelpMessage = "Arguments supplémentaires à passer")]
        [hashtable]$ArgumentList = @{},

        [Parameter(Mandatory = $false, HelpMessage = "Nombre de runspaces à créer par lot")]
        [ValidateRange(1, 1000)]
        [int]$BatchSize = 10,

        [Parameter(Mandatory = $false, HelpMessage = "Nom du paramètre pour l'objet d'entrée")]
        [ValidateNotNullOrEmpty()]
        [string]$ParameterName = "Item",

        [Parameter(Mandatory = $false, HelpMessage = "Limite de throttling")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$ThrottleLimit = 0
    )

    begin {
        # Vérifier que le pool de runspaces est ouvert
        if ($RunspacePool.RunspacePoolStateInfo.State -ne [System.Management.Automation.Runspaces.RunspacePoolState]::Opened) {
            throw "Le pool de runspaces n'est pas ouvert. État actuel : $($RunspacePool.RunspacePoolStateInfo.State)"
        }

        # Créer une liste pour stocker les runspaces
        $runspaces = [System.Collections.Generic.List[PSObject]]::new()

        # Calculer le nombre total d'objets à traiter
        $totalObjects = $InputObjects.Count
        Write-Verbose "Création de runspaces pour $totalObjects objets en lots de $BatchSize"

        # Appliquer la limite de throttling si spécifiée
        $effectiveTotal = if ($ThrottleLimit -gt 0 -and $ThrottleLimit -lt $totalObjects) {
            Write-Verbose "Limite de throttling appliquée : $ThrottleLimit sur $totalObjects objets"
            $ThrottleLimit
        } else {
            $totalObjects
        }

        # Calculer le nombre de lots
        $batchCount = [Math]::Ceiling($effectiveTotal / $BatchSize)
        Write-Verbose "Nombre de lots à créer : $batchCount"
    }

    process {
        # Créer les runspaces par lots
        for ($batchIndex = 0; $batchIndex -lt $batchCount; $batchIndex++) {
            $startIndex = $batchIndex * $BatchSize
            $endIndex = [Math]::Min($startIndex + $BatchSize - 1, $effectiveTotal - 1)
            $batchSize = $endIndex - $startIndex + 1

            Write-Verbose "Création du lot $($batchIndex + 1)/$batchCount : objets $startIndex à $endIndex"

            # Créer les runspaces pour ce lot
            for ($i = $startIndex; $i -le $endIndex; $i++) {
                $item = $InputObjects[$i]

                # Créer une nouvelle instance PowerShell
                $powershell = [powershell]::Create()
                $powershell.RunspacePool = $RunspacePool

                # Configurer le script ou la commande
                if ($PSCmdlet.ParameterSetName -eq "ScriptBlock") {
                    [void]$powershell.AddScript($ScriptBlock.ToString())
                    # Ajouter le paramètre principal (l'objet d'entrée) pour le script block
                    [void]$powershell.AddParameter($ParameterName, $item)
                } else {
                    # Pour les commandes, utiliser AddArgument au lieu de AddParameter pour éviter les problèmes de formatage
                    [void]$powershell.AddCommand($Command)
                    [void]$powershell.AddArgument($item)
                }

                # Ajouter les arguments supplémentaires
                foreach ($key in $ArgumentList.Keys) {
                    [void]$powershell.AddParameter($key, $ArgumentList[$key])
                }

                # Démarrer l'exécution asynchrone
                $handle = $powershell.BeginInvoke()

                # Ajouter à la liste des runspaces
                $runspaces.Add([PSCustomObject]@{
                        PowerShell = $powershell
                        Handle     = $handle
                        Item       = $item
                        StartTime  = [datetime]::Now
                        BatchIndex = $batchIndex
                    })
            }
        }
    }

    end {
        Write-Verbose "$($runspaces.Count) runspaces créés en $batchCount lots"
        return $runspaces
    }
}

# Fonction pour gérer le cache des pools de runspaces
function Get-RunspacePoolFromCache {
    <#
    .SYNOPSIS
        Récupère un pool de runspaces du cache ou en crée un nouveau si nécessaire.

    .DESCRIPTION
        Cette fonction recherche un pool de runspaces dans le cache en fonction des paramètres
        spécifiés. Si un pool correspondant est trouvé et est disponible, il est retourné.
        Sinon, un nouveau pool est créé, ajouté au cache et retourné.

    .PARAMETER MinRunspaces
        Nombre minimum de runspaces dans le pool.
        Par défaut : 1

    .PARAMETER MaxRunspaces
        Nombre maximum de runspaces dans le pool.
        Par défaut : Nombre de processeurs logiques

    .PARAMETER ApartmentState
        État d'appartement des runspaces (STA ou MTA).
        Par défaut : MTA

    .PARAMETER ThreadOptions
        Options de thread pour les runspaces.
        Par défaut : ReuseThread

    .PARAMETER SessionState
        État de session initial pour les runspaces.
        Par défaut : État de session par défaut

    .PARAMETER HostObject
        Objet hôte à utiliser pour les runspaces.
        Par défaut : Hôte PowerShell actuel

    .PARAMETER CreateNew
        Crée un nouveau pool de runspaces même si un pool correspondant existe dans le cache.
        Par défaut : $false

    .PARAMETER MaxCacheSize
        Nombre maximum de pools de runspaces à conserver dans le cache.
        Par défaut : 10

    .PARAMETER MaxIdleTimeMinutes
        Temps maximum en minutes pendant lequel un pool peut rester inactif avant d'être supprimé du cache.
        Par défaut : 30 minutes

    .EXAMPLE
        $pool = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 4

        Récupère un pool de runspaces avec 1 à 4 runspaces du cache ou en crée un nouveau.

    .EXAMPLE
        $pool = Get-RunspacePoolFromCache -MinRunspaces 1 -MaxRunspaces 8 -CreateNew $true

        Crée un nouveau pool de runspaces avec 1 à 8 runspaces, ignorant le cache.

    .OUTPUTS
        System.Management.Automation.Runspaces.RunspacePool

        Le pool de runspaces récupéré ou créé.
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Runspaces.RunspacePool])]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Nombre minimum de runspaces")]
        [ValidateRange(1, 1000)]
        [int]$MinRunspaces = 1,

        [Parameter(Mandatory = $false, HelpMessage = "Nombre maximum de runspaces")]
        [ValidateRange(1, 5000)]
        [int]$MaxRunspaces = (Get-OptimalThreadCount),

        [Parameter(Mandatory = $false, HelpMessage = "État d'appartement des runspaces")]
        [ValidateSet("STA", "MTA")]
        [string]$ApartmentState = "MTA",

        [Parameter(Mandatory = $false, HelpMessage = "Options de thread pour les runspaces")]
        [ValidateSet("Default", "ReuseThread", "UseNewThread")]
        [string]$ThreadOptions = "ReuseThread",

        [Parameter(Mandatory = $false, HelpMessage = "État de session initial pour les runspaces")]
        [System.Management.Automation.Runspaces.InitialSessionState]$SessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault(),

        [Parameter(Mandatory = $false, HelpMessage = "Objet hôte à utiliser pour les runspaces")]
        [System.Management.Automation.Host.PSHost]$HostObject = $Host,

        [Parameter(Mandatory = $false, HelpMessage = "Crée un nouveau pool même si un pool correspondant existe dans le cache")]
        [bool]$CreateNew = $false,

        [Parameter(Mandatory = $false, HelpMessage = "Nombre maximum de pools dans le cache")]
        [ValidateRange(1, 100)]
        [int]$MaxCacheSize = 10,

        [Parameter(Mandatory = $false, HelpMessage = "Temps maximum en minutes pendant lequel un pool peut rester inactif")]
        [ValidateRange(1, 1440)]
        [int]$MaxIdleTimeMinutes = 30
    )

    begin {
        # Nettoyer le cache des pools inactifs
        Clear-RunspacePoolCache -MaxIdleTimeMinutes $MaxIdleTimeMinutes -MaxCacheSize $MaxCacheSize
    }

    process {
        # Générer une clé de cache unique basée sur les paramètres du pool
        $cacheKey = "Min=$MinRunspaces;Max=$MaxRunspaces;Apt=$ApartmentState;Opt=$ThreadOptions"

        # Si on demande explicitement un nouveau pool, on le crée sans consulter le cache
        if ($CreateNew) {
            Write-Verbose "Création d'un nouveau pool de runspaces (création forcée) avec la configuration : $cacheKey"
            return New-CachedRunspacePool -MinRunspaces $MinRunspaces -MaxRunspaces $MaxRunspaces -ApartmentState $ApartmentState -ThreadOptions $ThreadOptions -SessionState $SessionState -HostObject $HostObject -CacheKey $cacheKey
        }

        # Vérifier si un pool correspondant existe dans le cache
        if ($script:RunspacePoolCache.ContainsKey($cacheKey)) {
            $cachedPool = $script:RunspacePoolCache[$cacheKey]

            # Vérifier si le pool est toujours valide et disponible
            if ($cachedPool.Pool.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspacePoolState]::Opened) {
                Write-Verbose "Pool de runspaces trouvé dans le cache avec la configuration : $cacheKey"

                # Mettre à jour les métadonnées du pool
                $cachedPool.LastUsed = [datetime]::Now
                $cachedPool.UseCount++

                return $cachedPool.Pool
            } else {
                # Le pool n'est plus valide, le supprimer du cache
                Write-Verbose "Pool de runspaces trouvé dans le cache mais non valide (état : $($cachedPool.Pool.RunspacePoolStateInfo.State)). Suppression et création d'un nouveau."
                $script:RunspacePoolCache.Remove($cacheKey)

                # Essayer de nettoyer le pool
                try {
                    if ($cachedPool.Pool.RunspacePoolStateInfo.State -ne [System.Management.Automation.Runspaces.RunspacePoolState]::Closed) {
                        $cachedPool.Pool.Close()
                    }
                    $cachedPool.Pool.Dispose()
                } catch {
                    Write-Verbose "Erreur lors du nettoyage du pool : $_"
                }
            }
        }

        # Aucun pool valide trouvé dans le cache, en créer un nouveau
        Write-Verbose "Aucun pool de runspaces valide trouvé dans le cache. Création d'un nouveau avec la configuration : $cacheKey"
        return New-CachedRunspacePool -MinRunspaces $MinRunspaces -MaxRunspaces $MaxRunspaces -ApartmentState $ApartmentState -ThreadOptions $ThreadOptions -SessionState $SessionState -HostObject $HostObject -CacheKey $cacheKey
    }
}

function New-CachedRunspacePool {
    <#
    .SYNOPSIS
        Crée un nouveau pool de runspaces et l'ajoute au cache.

    .DESCRIPTION
        Fonction interne utilisée par Get-RunspacePoolFromCache pour créer un nouveau pool
        de runspaces et l'ajouter au cache.
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Runspaces.RunspacePool])]
    param(
        [Parameter(Mandatory = $true)]
        [int]$MinRunspaces,

        [Parameter(Mandatory = $true)]
        [int]$MaxRunspaces,

        [Parameter(Mandatory = $true)]
        [string]$ApartmentState,

        [Parameter(Mandatory = $true)]
        [string]$ThreadOptions,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.InitialSessionState]$SessionState,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Host.PSHost]$HostObject,

        [Parameter(Mandatory = $true)]
        [string]$CacheKey
    )

    # Créer le pool de runspaces
    $pool = [runspacefactory]::CreateRunspacePool($MinRunspaces, $MaxRunspaces, $SessionState, $HostObject)

    # Définir l'état d'appartement
    if ($ApartmentState -eq "STA") {
        $pool.ApartmentState = "STA"
    } else {
        $pool.ApartmentState = "MTA"
    }

    # Définir les options de thread
    switch ($ThreadOptions) {
        "Default" { $pool.ThreadOptions = "Default" }
        "ReuseThread" { $pool.ThreadOptions = "ReuseThread" }
        "UseNewThread" { $pool.ThreadOptions = "UseNewThread" }
        default { $pool.ThreadOptions = "ReuseThread" }
    }

    # Ouvrir le pool
    $pool.Open()

    # Ajouter le pool au cache
    $script:RunspacePoolCache[$CacheKey] = [PSCustomObject]@{
        Pool         = $pool
        Created      = [datetime]::Now
        LastUsed     = [datetime]::Now
        UseCount     = 1
        Key          = $CacheKey
        MinRunspaces = $MinRunspaces
        MaxRunspaces = $MaxRunspaces
    }

    return $pool
}

function Clear-RunspacePoolCache {
    <#
    .SYNOPSIS
        Nettoie le cache des pools de runspaces.

    .DESCRIPTION
        Cette fonction supprime les pools de runspaces inactifs du cache en fonction
        du temps d'inactivité et de la taille maximale du cache.

    .PARAMETER MaxIdleTimeMinutes
        Temps maximum en minutes pendant lequel un pool peut rester inactif avant d'être supprimé du cache.
        Par défaut : 30 minutes

    .PARAMETER MaxCacheSize
        Nombre maximum de pools de runspaces à conserver dans le cache.
        Par défaut : 10

    .PARAMETER Force
        Force la suppression de tous les pools du cache, même s'ils sont actifs.
        Par défaut : $false

    .EXAMPLE
        Clear-RunspacePoolCache -MaxIdleTimeMinutes 15 -MaxCacheSize 5

        Nettoie le cache en supprimant les pools inactifs depuis plus de 15 minutes
        et en limitant la taille du cache à 5 pools.

    .EXAMPLE
        Clear-RunspacePoolCache -Force

        Supprime tous les pools du cache, même s'ils sont actifs.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Temps maximum en minutes pendant lequel un pool peut rester inactif")]
        [ValidateRange(1, 1440)]
        [int]$MaxIdleTimeMinutes = 30,

        [Parameter(Mandatory = $false, HelpMessage = "Nombre maximum de pools dans le cache")]
        [ValidateRange(1, 100)]
        [int]$MaxCacheSize = 10,

        [Parameter(Mandatory = $false, HelpMessage = "Force la suppression de tous les pools du cache")]
        [switch]$Force
    )

    # Si le cache est vide, rien à faire
    if ($script:RunspacePoolCache.Count -eq 0) {
        Write-Verbose "Le cache des pools de runspaces est vide."
        return
    }

    # Si on force la suppression, vider complètement le cache
    if ($Force) {
        Write-Verbose "Suppression forcée de tous les pools du cache ($($script:RunspacePoolCache.Count) pools)."

        # Fermer et disposer tous les pools
        foreach ($key in @($script:RunspacePoolCache.Keys)) {
            $pool = $script:RunspacePoolCache[$key].Pool
            try {
                if ($pool.RunspacePoolStateInfo.State -ne [System.Management.Automation.Runspaces.RunspacePoolState]::Closed) {
                    $pool.Close()
                }
                $pool.Dispose()
            } catch {
                Write-Verbose "Erreur lors de la fermeture du pool '$key' : $_"
            }
        }

        # Vider le cache
        $script:RunspacePoolCache.Clear()
        return
    }

    # Calculer le seuil d'inactivité
    $idleThreshold = [datetime]::Now.AddMinutes(-$MaxIdleTimeMinutes)

    # Identifier les pools inactifs
    $inactivePools = @($script:RunspacePoolCache.Keys | Where-Object {
            $cachedPool = $script:RunspacePoolCache[$_]
            $cachedPool.LastUsed -lt $idleThreshold
        })

    if ($inactivePools.Count -gt 0) {
        Write-Verbose "Suppression de $($inactivePools.Count) pools inactifs du cache."

        # Supprimer les pools inactifs
        foreach ($key in $inactivePools) {
            $pool = $script:RunspacePoolCache[$key].Pool
            try {
                if ($pool.RunspacePoolStateInfo.State -ne [System.Management.Automation.Runspaces.RunspacePoolState]::Closed) {
                    $pool.Close()
                }
                $pool.Dispose()
            } catch {
                Write-Verbose "Erreur lors de la fermeture du pool inactif '$key' : $_"
            }
            $script:RunspacePoolCache.Remove($key)
        }
    }

    # Si le cache dépasse toujours la taille maximale, supprimer les pools les moins utilisés
    if ($script:RunspacePoolCache.Count -gt $MaxCacheSize) {
        Write-Verbose "Le cache contient $($script:RunspacePoolCache.Count) pools, ce qui dépasse la limite de $MaxCacheSize. Suppression des pools les moins utilisés."

        # Trier les pools par nombre d'utilisations (du moins utilisé au plus utilisé)
        $poolsToRemove = @($script:RunspacePoolCache.Keys |
                Sort-Object { $script:RunspacePoolCache[$_].UseCount } |
                Select-Object -First ($script:RunspacePoolCache.Count - $MaxCacheSize))

        foreach ($key in $poolsToRemove) {
            $pool = $script:RunspacePoolCache[$key].Pool
            try {
                if ($pool.RunspacePoolStateInfo.State -ne [System.Management.Automation.Runspaces.RunspacePoolState]::Closed) {
                    $pool.Close()
                }
                $pool.Dispose()
            } catch {
                Write-Verbose "Erreur lors de la fermeture du pool peu utilisé '$key' : $_"
            }
            $script:RunspacePoolCache.Remove($key)
        }
    }

    Write-Verbose "Le cache contient maintenant $($script:RunspacePoolCache.Count) pools de runspaces."
}

function Get-RunspacePoolCacheInfo {
    <#
    .SYNOPSIS
        Affiche des informations sur le cache des pools de runspaces.

    .DESCRIPTION
        Cette fonction retourne des informations détaillées sur les pools de runspaces
        actuellement stockés dans le cache. Elle permet de surveiller l'utilisation
        du cache, d'identifier les pools inactifs ou surchargés, et de diagnostiquer
        les problèmes de performance liés aux pools de runspaces.

        Les informations retournées incluent le nombre total de pools, le nombre total
        de runspaces, l'âge du pool le plus ancien, la date de dernière utilisation
        du pool le plus récemment utilisé, et le nombre d'utilisations du pool le plus
        utilisé. Si le paramètre Detailed est spécifié, des informations détaillées
        sur chaque pool sont également retournées.

    .PARAMETER Detailed
        Affiche des informations détaillées sur chaque pool dans le cache, notamment
        la clé du pool, sa date de création, sa date de dernière utilisation, son nombre
        d'utilisations, le nombre minimum et maximum de runspaces, son état, le nombre
        de runspaces disponibles et le nombre de runspaces en cours d'utilisation.

        Par défaut : $false

    .EXAMPLE
        Get-RunspacePoolCacheInfo

        Affiche un résumé du cache des pools de runspaces, incluant le nombre total de pools,
        le nombre total de runspaces, et d'autres statistiques globales.

    .EXAMPLE
        Get-RunspacePoolCacheInfo -Detailed

        Affiche des informations détaillées sur chaque pool dans le cache, y compris
        leur état, leur utilisation, et leurs caractéristiques.

    .EXAMPLE
        $cacheInfo = Get-RunspacePoolCacheInfo -Detailed
        $cacheInfo.Pools | Where-Object { $_.State -eq 'Opened' -and $_.InUseRunspaces -eq 0 }

        Récupère des informations détaillées sur le cache et filtre les pools ouverts
        mais non utilisés, ce qui peut être utile pour identifier les pools inactifs
        qui pourraient être fermés pour libérer des ressources.

    .OUTPUTS
        PSCustomObject

        Un objet contenant des informations sur le cache des pools de runspaces avec les propriétés suivantes:
        - TotalPools: Nombre total de pools dans le cache
        - TotalRunspaces: Nombre total de runspaces dans tous les pools
        - OldestPool: Date de création du pool le plus ancien
        - MostRecentlyUsed: Date de dernière utilisation du pool le plus récemment utilisé
        - MostUsedPool: Nombre d'utilisations du pool le plus utilisé
        - Pools: Liste détaillée des pools (uniquement si Detailed est spécifié)
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Affiche des informations détaillées sur chaque pool")]
        [switch]$Detailed
    )

    # Créer un résumé du cache
    $summary = [PSCustomObject]@{
        TotalPools       = $script:RunspacePoolCache.Count
        TotalRunspaces   = ($script:RunspacePoolCache.Values | Measure-Object -Property MaxRunspaces -Sum).Sum
        OldestPool       = if ($script:RunspacePoolCache.Count -gt 0) {
            ($script:RunspacePoolCache.Values | Sort-Object -Property Created | Select-Object -First 1).Created
        } else {
            $null
        }
        MostRecentlyUsed = if ($script:RunspacePoolCache.Count -gt 0) {
            ($script:RunspacePoolCache.Values | Sort-Object -Property LastUsed -Descending | Select-Object -First 1).LastUsed
        } else {
            $null
        }
        MostUsedPool     = if ($script:RunspacePoolCache.Count -gt 0) {
            ($script:RunspacePoolCache.Values | Sort-Object -Property UseCount -Descending | Select-Object -First 1).UseCount
        } else {
            0
        }
        Pools            = if ($Detailed) {
            $script:RunspacePoolCache.Values | ForEach-Object {
                [PSCustomObject]@{
                    Key                = $_.Key
                    Created            = $_.Created
                    LastUsed           = $_.LastUsed
                    UseCount           = $_.UseCount
                    MinRunspaces       = $_.MinRunspaces
                    MaxRunspaces       = $_.MaxRunspaces
                    State              = $_.Pool.RunspacePoolStateInfo.State
                    AvailableRunspaces = $_.Pool.GetAvailableRunspaces()
                    InUseRunspaces     = $_.MaxRunspaces - $_.Pool.GetAvailableRunspaces()
                }
            }
        } else {
            $null
        }
    }

    return $summary
}

# Fonction pour initialiser les paramètres d'encodage
function Initialize-EncodingSettings {
    <#
    .SYNOPSIS
        Configure l'encodage UTF-8 pour la console PowerShell et les fichiers.

    .DESCRIPTION
        Cette fonction configure l'encodage UTF-8 pour la console PowerShell,
        en tenant compte des différences entre PowerShell 5.1 et PowerShell 7.x.
        Elle permet d'assurer un affichage correct des caractères accentués
        dans la console et dans les fichiers générés.

        La fonction configure également les paramètres par défaut pour les cmdlets
        qui utilisent l'encodage, comme Out-File, Set-Content et Add-Content.

    .PARAMETER UseBOM
        Indique si l'encodage UTF-8 doit inclure un BOM (Byte Order Mark).
        Par défaut, la valeur est $true pour assurer une compatibilité maximale.

    .PARAMETER ConfigureConsole
        Indique si l'encodage de la console doit être configuré.
        Par défaut, la valeur est $true.

    .PARAMETER ConfigureDefaultParameters
        Indique si les paramètres par défaut des cmdlets doivent être configurés.
        Par défaut, la valeur est $true.

    .PARAMETER Force
        Force la configuration de l'encodage même si elle est déjà configurée.
        Par défaut, la valeur est $false.

    .EXAMPLE
        Initialize-EncodingSettings
        Configure l'encodage UTF-8 avec BOM pour la console PowerShell et les fichiers.

    .EXAMPLE
        Initialize-EncodingSettings -UseBOM $false
        Configure l'encodage UTF-8 sans BOM pour la console PowerShell et les fichiers.

    .EXAMPLE
        Initialize-EncodingSettings -ConfigureConsole $true -ConfigureDefaultParameters $false
        Configure uniquement l'encodage de la console, sans modifier les paramètres par défaut des cmdlets.

    .NOTES
        Cette fonction doit être appelée au début de chaque script ou module
        qui manipule des caractères accentués ou des caractères spéciaux.

        Différences entre PowerShell 5.1 et 7.x :
        - PowerShell 5.1 : Nécessite de configurer $OutputEncoding et [Console]::OutputEncoding
        - PowerShell 7.x : Utilise UTF-8 par défaut, mais il est recommandé de configurer explicitement

        PowerShell 5.1 utilise des noms d'encodage différents de PowerShell 7.x :
        - PowerShell 5.1 : 'utf8' pour UTF-8 avec BOM
        - PowerShell 7.x : 'utf8BOM' pour UTF-8 avec BOM, 'utf8NoBOM' pour UTF-8 sans BOM
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Indique si l'encodage UTF-8 doit inclure un BOM")]
        [bool]$UseBOM = $true,

        [Parameter(Mandatory = $false, HelpMessage = "Indique si l'encodage de la console doit être configuré")]
        [bool]$ConfigureConsole = $true,

        [Parameter(Mandatory = $false, HelpMessage = "Indique si les paramètres par défaut des cmdlets doivent être configurés")]
        [bool]$ConfigureDefaultParameters = $true,

        [Parameter(Mandatory = $false, HelpMessage = "Force la configuration de l'encodage même si elle est déjà configurée")]
        [switch]$Force
    )

    # Créer un objet pour stocker les informations d'encodage
    $encodingInfo = [PSCustomObject]@{
        PSVersion               = $PSVersionTable.PSVersion
        PreviousOutputEncoding  = $OutputEncoding
        PreviousConsoleEncoding = [Console]::OutputEncoding
        CurrentOutputEncoding   = $null
        CurrentConsoleEncoding  = $null
        DefaultParametersSet    = $false
        Success                 = $false
        UsedBOM                 = $UseBOM
        ConfiguredConsole       = $false
        ConfiguredParameters    = $false
        Errors                  = @()
    }

    try {
        # Déterminer si nous sommes sur PowerShell 7.x ou 5.1
        $isPowerShell7 = $PSVersionTable.PSVersion.Major -ge 7

        # Configurer l'encodage de sortie pour la console
        if ($ConfigureConsole) {
            try {
                $OutputEncoding = [System.Text.Encoding]::UTF8
                [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

                # Configurer l'encodage d'entrée de la console si possible
                try {
                    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
                } catch {
                    $encodingInfo.Errors += "Impossible de configurer l'encodage d'entrée de la console: $_"
                    Write-Verbose "Impossible de configurer l'encodage d'entrée de la console: $_"
                }

                $encodingInfo.ConfiguredConsole = $true
                Write-Verbose "Encodage de la console configuré avec succès pour UTF-8"
            } catch {
                $encodingInfo.Errors += "Erreur lors de la configuration de l'encodage de la console: $_"
                Write-Warning "Erreur lors de la configuration de l'encodage de la console: $_"
            }
        }

        # Configurer les paramètres par défaut pour les cmdlets qui utilisent l'encodage
        if ($ConfigureDefaultParameters) {
            try {
                if ($isPowerShell7) {
                    # PowerShell 7.x utilise utf8NoBOM par défaut
                    if ($UseBOM) {
                        $encodingValue = 'utf8BOM'
                    } else {
                        $encodingValue = 'utf8NoBOM'
                    }
                } else {
                    # PowerShell 5.1 utilise des noms d'encodage différents
                    # Note: Dans PowerShell 5.1, 'utf8' signifie UTF-8 avec BOM
                    $encodingValue = 'utf8'
                }

                # Configurer les paramètres par défaut pour les cmdlets qui utilisent l'encodage
                $PSDefaultParameterValues['Out-File:Encoding'] = $encodingValue
                $PSDefaultParameterValues['Set-Content:Encoding'] = $encodingValue
                $PSDefaultParameterValues['Add-Content:Encoding'] = $encodingValue
                $PSDefaultParameterValues['Export-Csv:Encoding'] = $encodingValue
                $PSDefaultParameterValues['Export-Clixml:Encoding'] = $encodingValue
                $PSDefaultParameterValues['Export-PSSession:Encoding'] = $encodingValue

                $encodingInfo.ConfiguredParameters = $true
                Write-Verbose "Paramètres par défaut configurés avec succès pour l'encodage $encodingValue"
            } catch {
                $encodingInfo.Errors += "Erreur lors de la configuration des paramètres par défaut: $_"
                Write-Warning "Erreur lors de la configuration des paramètres par défaut: $_"
            }
        }

        # Mettre à jour les informations d'encodage
        $encodingInfo.CurrentOutputEncoding = $OutputEncoding
        $encodingInfo.CurrentConsoleEncoding = [Console]::OutputEncoding
        $encodingInfo.Success = $encodingInfo.ConfiguredConsole -or $encodingInfo.ConfiguredParameters

        # Afficher un message de succès
        if ($encodingInfo.Success) {
            Write-Verbose "Encodage configuré avec succès pour UTF-8 $(if ($UseBOM) { 'avec BOM' } else { 'sans BOM' })"
        } else {
            Write-Warning "La configuration de l'encodage a échoué. Consultez les erreurs pour plus de détails."
        }
    } catch {
        $encodingInfo.Errors += "Erreur générale lors de la configuration de l'encodage: $_"
        Write-Error "Erreur lors de la configuration de l'encodage: $_"
        $encodingInfo.Success = $false
    }

    return $encodingInfo
}

# Fonction pour créer des objets d'erreur standardisés
function New-UnifiedError {
    <#
    .SYNOPSIS
        Crée un objet d'erreur standardisé pour le module UnifiedParallel.

    .DESCRIPTION
        Cette fonction crée un objet d'erreur standardisé pour le module UnifiedParallel.
        Elle permet de générer des erreurs cohérentes dans tout le module, avec des
        informations détaillées et des options pour écrire l'erreur dans le flux d'erreur
        ou la lancer comme exception.

        L'objet d'erreur contient des informations comme le message, la source, l'exception,
        la catégorie, etc. Il peut être utilisé pour générer des rapports d'erreur détaillés
        et faciliter le débogage.

    .PARAMETER Message
        Le message d'erreur principal.

    .PARAMETER Source
        La source de l'erreur (généralement le nom de la fonction qui a généré l'erreur).
        Par défaut, "UnifiedParallel".

    .PARAMETER Exception
        L'exception qui a causé l'erreur. Si non spécifiée, une nouvelle exception sera créée
        avec le message fourni.

    .PARAMETER Category
        La catégorie d'erreur PowerShell. Par défaut, NotSpecified.
        Valeurs possibles : NotSpecified, OpenError, CloseError, DeviceError, DeadlockDetected,
        InvalidArgument, InvalidData, InvalidOperation, InvalidResult, InvalidType, MetadataError,
        NotImplemented, NotInstalled, ObjectNotFound, OperationStopped, OperationTimeout,
        SyntaxError, ParserError, PermissionDenied, ResourceBusy, ResourceExists, ResourceUnavailable,
        ReadError, WriteError, FromStdErr, SecurityError, ProtocolError, ConnectionError,
        AuthenticationError, LimitsExceeded, QuotaExceeded, NotEnabled.

    .PARAMETER ErrorId
        L'identifiant de l'erreur. Si non spécifié, un GUID sera généré.

    .PARAMETER TargetObject
        L'objet cible de l'erreur.

    .PARAMETER WriteError
        Indique si l'erreur doit être écrite dans le flux d'erreur avec Write-Error.

    .PARAMETER ThrowError
        Indique si l'erreur doit être lancée comme exception avec throw.

    .PARAMETER ErrorAction
        L'action à effectuer en cas d'erreur lors de l'appel à Write-Error.
        Par défaut, Continue.

    .PARAMETER ErrorRecord
        Un enregistrement d'erreur existant à utiliser comme base pour le nouvel objet d'erreur.
        Si spécifié, les autres paramètres (Message, Exception, Category, etc.) seront ignorés.

    .PARAMETER AdditionalInfo
        Informations supplémentaires à inclure dans l'objet d'erreur.
        Doit être un hashtable avec des paires clé-valeur.

    .EXAMPLE
        New-UnifiedError -Message "Le fichier n'existe pas" -Source "Get-ConfigFile" -Category ObjectNotFound -WriteError

        Crée un objet d'erreur avec le message "Le fichier n'existe pas", la source "Get-ConfigFile",
        la catégorie ObjectNotFound, et écrit l'erreur dans le flux d'erreur.

    .EXAMPLE
        try {
            # Code qui peut générer une erreur
        } catch {
            New-UnifiedError -ErrorRecord $_ -Source "Initialize-UnifiedParallel" -WriteError
        }

        Capture une erreur et crée un objet d'erreur standardisé à partir de l'enregistrement d'erreur,
        avec la source "Initialize-UnifiedParallel", et écrit l'erreur dans le flux d'erreur.

    .EXAMPLE
        $error = New-UnifiedError -Message "Opération non autorisée" -Category PermissionDenied -ThrowError

        Crée un objet d'erreur avec le message "Opération non autorisée", la catégorie PermissionDenied,
        et lance l'erreur comme exception.

    .NOTES
        Cette fonction est conçue pour être utilisée dans tout le module UnifiedParallel afin
        de standardiser la gestion des erreurs et faciliter le débogage.

        Elle est compatible avec PowerShell 5.1 et PowerShell 7.x.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Message")]
        [string]$Message,

        [Parameter(Mandatory = $false, ParameterSetName = "Message")]
        [Parameter(Mandatory = $false, ParameterSetName = "ErrorRecord")]
        [string]$Source = "UnifiedParallel",

        [Parameter(Mandatory = $false, ParameterSetName = "Message")]
        [System.Exception]$Exception = $null,

        [Parameter(Mandatory = $false, ParameterSetName = "Message")]
        [System.Management.Automation.ErrorCategory]$Category = [System.Management.Automation.ErrorCategory]::NotSpecified,

        [Parameter(Mandatory = $false, ParameterSetName = "Message")]
        [string]$ErrorId = [System.Guid]::NewGuid().ToString(),

        [Parameter(Mandatory = $false, ParameterSetName = "Message")]
        [object]$TargetObject = $null,

        [Parameter(Mandatory = $false, ParameterSetName = "Message")]
        [Parameter(Mandatory = $false, ParameterSetName = "ErrorRecord")]
        [switch]$WriteError,

        [Parameter(Mandatory = $false, ParameterSetName = "Message")]
        [Parameter(Mandatory = $false, ParameterSetName = "ErrorRecord")]
        [switch]$ThrowError,

        [Parameter(Mandatory = $false, ParameterSetName = "Message")]
        [Parameter(Mandatory = $false, ParameterSetName = "ErrorRecord")]
        [System.Management.Automation.ActionPreference]$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Continue,

        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "ErrorRecord")]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory = $false, ParameterSetName = "Message")]
        [Parameter(Mandatory = $false, ParameterSetName = "ErrorRecord")]
        [hashtable]$AdditionalInfo = @{}
    )

    begin {
        # Créer l'objet d'erreur standardisé
        $errorObject = [PSCustomObject]@{
            Id             = $ErrorId
            Message        = $Message
            Source         = $Source
            Timestamp      = [datetime]::Now
            PSVersion      = $PSVersionTable.PSVersion
            Category       = $Category
            Exception      = $Exception
            ErrorRecord    = $null
            TargetObject   = $TargetObject
            AdditionalInfo = $AdditionalInfo
            CallStack      = (Get-PSCallStack | Select-Object -Skip 1)
            CorrelationId  = [System.Guid]::NewGuid().ToString()
        }

        # Si un ErrorRecord est fourni, l'utiliser comme base
        if ($PSCmdlet.ParameterSetName -eq "ErrorRecord") {
            $errorObject.Message = $ErrorRecord.Exception.Message
            $errorObject.Exception = $ErrorRecord.Exception
            $errorObject.Category = $ErrorRecord.CategoryInfo.Category
            $errorObject.ErrorRecord = $ErrorRecord
            $errorObject.TargetObject = $ErrorRecord.TargetObject
            $errorObject.Id = $ErrorRecord.FullyQualifiedErrorId
        } else {
            # Créer une exception si aucune n'est fournie
            if ($null -eq $Exception) {
                $errorObject.Exception = [System.Exception]::new($Message)
            }

            # Créer un ErrorRecord
            $errorObject.ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                $errorObject.Exception,
                $errorObject.Id,
                $errorObject.Category,
                $errorObject.TargetObject
            )
        }
    }

    process {
        # Écrire l'erreur dans le flux d'erreur si demandé
        if ($WriteError) {
            $writeErrorParams = @{
                Message      = "[$Source] $($errorObject.Message)"
                ErrorRecord  = $errorObject.ErrorRecord
                ErrorAction  = $ErrorActionPreference
                Category     = $errorObject.Category
                ErrorId      = $errorObject.Id
                TargetObject = $errorObject.TargetObject
            }

            # Ajouter des informations supplémentaires au message si disponibles
            if ($AdditionalInfo.Count -gt 0) {
                $additionalInfoString = "`nInformations supplémentaires:"
                foreach ($key in $AdditionalInfo.Keys) {
                    $additionalInfoString += "`n- $key : $($AdditionalInfo[$key])"
                }
                $writeErrorParams.Message += $additionalInfoString
            }

            Write-Error @writeErrorParams
        }

        # Lancer l'erreur comme exception si demandé
        if ($ThrowError) {
            throw $errorObject.ErrorRecord
        }
    }

    end {
        # Retourner l'objet d'erreur
        return $errorObject
    }
}

# Fonction pour récupérer la version du module
function Get-UnifiedParallelVersion {
    <#
    .SYNOPSIS
        Récupère la version du module UnifiedParallel.

    .DESCRIPTION
        Cette fonction retourne la version actuelle du module UnifiedParallel.
        Elle peut également fournir des informations détaillées sur le module,
        comme la date de compilation, les fonctionnalités disponibles et les
        dépendances.

    .PARAMETER Detailed
        Indique si des informations détaillées doivent être retournées.
        Par défaut : $false

    .EXAMPLE
        Get-UnifiedParallelVersion
        # Retourne la version du module (ex: "1.1.0")

    .EXAMPLE
        Get-UnifiedParallelVersion -Detailed
        # Retourne un objet avec des informations détaillées sur le module

    .OUTPUTS
        System.String ou System.Management.Automation.PSObject

        Si le paramètre Detailed n'est pas spécifié, retourne une chaîne de caractères
        contenant la version du module.

        Si le paramètre Detailed est spécifié, retourne un objet PSCustomObject avec
        les propriétés suivantes:
        - Version: Version du module
        - PSVersion: Version de PowerShell
        - IsInitialized: État d'initialisation du module
        - Features: Fonctionnalités disponibles
        - BuildDate: Date de compilation (si disponible)
        - Path: Chemin du module
    #>
    [CmdletBinding()]
    [OutputType([string], [PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    begin {
        Write-Verbose "Récupération de la version du module UnifiedParallel"
    }

    process {
        if ($Detailed) {
            # Récupérer des informations détaillées sur le module
            $moduleInfo = [PSCustomObject]@{
                Version       = $script:MODULE_VERSION
                PSVersion     = $PSVersionTable.PSVersion
                IsInitialized = Get-ModuleInitialized
                Features      = [PSCustomObject]@{
                    BackpressureEnabled = $false
                    ThrottlingEnabled   = $false
                    ResourceMonitoring  = $false
                    ErrorHandling       = $true
                    RunspacePoolCache   = $true
                }
                BuildDate     = $null
                Path          = $PSScriptRoot
            }

            # Vérifier si le module est initialisé pour obtenir plus d'informations
            if (Get-ModuleInitialized) {
                $config = Get-ModuleConfig
                if ($config) {
                    $moduleInfo.Features.BackpressureEnabled = $config.BackpressureSettings.Enabled
                    $moduleInfo.Features.ThrottlingEnabled = $true
                    $moduleInfo.Features.ResourceMonitoring = $true
                }
            }

            # Essayer de récupérer la date de compilation à partir des métadonnées du fichier
            try {
                $moduleFile = Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "UnifiedParallel.psm1")
                $moduleInfo.BuildDate = $moduleFile.LastWriteTime
            } catch {
                Write-Verbose "Impossible de récupérer la date de compilation: $_"
            }

            return $moduleInfo
        } else {
            # Retourner simplement la version
            return $script:MODULE_VERSION
        }
    }

    end {
        Write-Verbose "Récupération de la version du module UnifiedParallel terminée"
    }
}

# Fonctions pour la conversion de types d'énumération

# Cache des types d'énumération pour optimiser les performances
$script:EnumTypeCache = @{}

# Fonction pour obtenir les informations sur un type d'énumération
function Get-EnumTypeInfo {
    <#
    .SYNOPSIS
        Récupère les informations sur un type d'énumération.

    .DESCRIPTION
        Cette fonction récupère les informations sur un type d'énumération, comme ses noms, ses valeurs,
        et son type sous-jacent. Elle utilise un cache pour optimiser les performances.

    .PARAMETER EnumType
        Le type d'énumération pour lequel récupérer les informations.

    .PARAMETER NoCache
        Indique si le cache doit être ignoré. Si $true, les informations sont toujours récupérées
        directement depuis le type d'énumération, sans utiliser le cache.

    .EXAMPLE
        Get-EnumTypeInfo -EnumType ([System.IO.FileAccess])
        Récupère les informations sur le type d'énumération System.IO.FileAccess.

    .OUTPUTS
        [PSCustomObject] Un objet contenant les informations sur le type d'énumération.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$EnumType,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    # Vérifier que le type est bien une énumération
    if (-not $EnumType.IsEnum) {
        throw [System.ArgumentException]::new("Le type spécifié n'est pas une énumération.", "EnumType")
    }

    # Clé de cache pour ce type d'énumération
    $cacheKey = $EnumType.FullName

    # Vérifier si les informations sont déjà dans le cache
    if (-not $NoCache -and $script:EnumTypeCache.ContainsKey($cacheKey)) {
        Write-Verbose "Utilisation des informations en cache pour le type d'énumération '$cacheKey'"
        return $script:EnumTypeCache[$cacheKey]
    }

    # Récupérer les informations sur le type d'énumération
    $enumNames = [Enum]::GetNames($EnumType)
    $enumValues = [Enum]::GetValues($EnumType)
    $underlyingType = [Enum]::GetUnderlyingType($EnumType)
    $isFlagsEnum = $EnumType.GetCustomAttributes([System.FlagsAttribute], $false).Length -gt 0

    # Créer un dictionnaire des noms et valeurs
    $nameValueMap = @{}
    $valueNameMap = @{}
    for ($i = 0; $i -lt $enumNames.Length; $i++) {
        $name = $enumNames[$i]
        $value = $enumValues[$i]
        $nameValueMap[$name] = $value
        $valueNameMap[$value] = $name
    }

    # Créer l'objet d'informations
    $enumInfo = [PSCustomObject]@{
        Type           = $EnumType
        FullName       = $EnumType.FullName
        UnderlyingType = $underlyingType
        IsFlags        = $isFlagsEnum
        Names          = $enumNames
        Values         = $enumValues
        NameValueMap   = $nameValueMap
        ValueNameMap   = $valueNameMap
    }

    # Ajouter les informations au cache si le cache n'est pas désactivé
    if (-not $NoCache) {
        $script:EnumTypeCache[$cacheKey] = $enumInfo
        Write-Verbose "Informations sur le type d'énumération '$cacheKey' ajoutées au cache"
    }

    return $enumInfo
}

# Fonction pour convertir une valeur en type d'énumération
function ConvertTo-Enum {
    <#
    .SYNOPSIS
        Convertit une chaîne en valeur d'énumération.

    .DESCRIPTION
        Cette fonction convertit une chaîne en valeur d'énumération du type spécifié.
        Elle vérifie que le type est bien une énumération et lance une exception si la conversion échoue.
        Elle utilise un cache pour optimiser les performances.

    .PARAMETER Value
        La chaîne à convertir en valeur d'énumération.

    .PARAMETER EnumType
        Le type d'énumération cible.

    .PARAMETER DefaultValue
        La valeur par défaut à retourner en cas d'échec de la conversion.
        Si ce paramètre est spécifié, aucune exception ne sera lancée en cas d'échec.

    .PARAMETER NoCache
        Indique si le cache doit être ignoré. Si $true, les informations sont toujours récupérées
        directement depuis le type d'énumération, sans utiliser le cache.

    .EXAMPLE
        ConvertTo-Enum -Value "ReadWrite" -EnumType ([System.IO.FileAccess])
        Convertit la chaîne "ReadWrite" en valeur d'énumération System.IO.FileAccess.ReadWrite.

    .EXAMPLE
        ConvertTo-Enum -Value "InvalidValue" -EnumType ([System.IO.FileAccess]) -DefaultValue ([System.IO.FileAccess]::Read)
        Tente de convertir la chaîne "InvalidValue" en valeur d'énumération System.IO.FileAccess.
        Comme la conversion échoue, retourne la valeur par défaut System.IO.FileAccess.Read.

    .OUTPUTS
        La valeur d'énumération convertie ou la valeur par défaut en cas d'échec.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter(Mandatory = $true, Position = 1)]
        [type]$EnumType,

        [Parameter(Mandatory = $false)]
        [object]$DefaultValue,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    # Vérifier si la valeur par défaut est spécifiée
    $hasDefaultValue = $PSBoundParameters.ContainsKey('DefaultValue')

    # Vérifier que le type est bien une énumération
    if (-not $EnumType.IsEnum) {
        if ($hasDefaultValue) {
            return $DefaultValue
        } else {
            throw [System.ArgumentException]::new("Le type spécifié n'est pas une énumération.", "EnumType")
        }
    }

    # Utiliser le cache pour optimiser les performances
    try {
        # Récupérer les informations sur le type d'énumération
        $enumInfo = Get-EnumTypeInfo -EnumType $EnumType -NoCache:$NoCache

        # Vérifier si la valeur est un nom valide pour l'énumération (insensible à la casse)
        $valueLower = $Value.ToLower()
        foreach ($name in $enumInfo.Names) {
            if ($name -eq $Value -or $name.ToLower() -eq $valueLower) {
                return $enumInfo.NameValueMap[$name]
            }
        }

        # La valeur n'est pas un nom valide pour l'énumération
        if ($hasDefaultValue) {
            return $DefaultValue
        } else {
            throw [System.ArgumentException]::new("Impossible de convertir la valeur '$Value' en énumération de type '$($EnumType.FullName)'.", "Value")
        }
    } catch {
        # En cas d'erreur, utiliser la méthode standard
        if (-not $hasDefaultValue) {
            try {
                return [Enum]::Parse($EnumType, $Value, $true)
            } catch {
                throw [System.ArgumentException]::new("Impossible de convertir la valeur '$Value' en énumération de type '$($EnumType.FullName)'.", "Value")
            }
        } else {
            try {
                return [Enum]::Parse($EnumType, $Value, $true)
            } catch {
                return $DefaultValue
            }
        }
    }
}

# Fonction pour convertir une valeur d'énumération en chaîne
function ConvertFrom-Enum {
    <#
    .SYNOPSIS
        Convertit une valeur d'énumération en chaîne.

    .DESCRIPTION
        Cette fonction convertit une valeur d'énumération en chaîne.
        Elle vérifie que la valeur est bien une énumération et lance une exception si la conversion échoue.
        Elle utilise un cache pour optimiser les performances.

    .PARAMETER EnumValue
        La valeur d'énumération à convertir en chaîne.

    .PARAMETER NoCache
        Indique si le cache doit être ignoré. Si $true, les informations sont toujours récupérées
        directement depuis le type d'énumération, sans utiliser le cache.

    .EXAMPLE
        ConvertFrom-Enum -EnumValue ([System.IO.FileAccess]::ReadWrite)
        Convertit la valeur d'énumération System.IO.FileAccess.ReadWrite en chaîne "ReadWrite".

    .OUTPUTS
        La chaîne représentant la valeur d'énumération.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [object]$EnumValue,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    if ($null -eq $EnumValue) {
        throw [System.ArgumentNullException]::new("EnumValue", "La valeur d'énumération ne peut pas être null.")
    }

    $enumType = $EnumValue.GetType()
    if (-not $enumType.IsEnum) {
        throw [System.ArgumentException]::new("La valeur spécifiée n'est pas une énumération.", "EnumValue")
    }

    # Utiliser le cache pour optimiser les performances
    try {
        # Récupérer les informations sur le type d'énumération
        $enumInfo = Get-EnumTypeInfo -EnumType $enumType -NoCache:$NoCache

        # Vérifier si la valeur est dans le dictionnaire des valeurs
        if ($enumInfo.ValueNameMap.ContainsKey($EnumValue)) {
            return $enumInfo.ValueNameMap[$EnumValue]
        }
    } catch {
        # En cas d'erreur, utiliser la méthode standard
        Write-Verbose "Erreur lors de l'utilisation du cache pour la conversion d'énumération : $_"
    }

    # Utiliser la méthode standard si le cache n'a pas fonctionné
    return $EnumValue.ToString()
}

# Fonction pour valider une valeur d'énumération
function Test-EnumValue {
    <#
    .SYNOPSIS
        Vérifie si une valeur est une valeur valide pour un type d'énumération.

    .DESCRIPTION
        Cette fonction vérifie si une valeur est une valeur valide pour un type d'énumération.
        Elle peut vérifier une chaîne ou une valeur numérique.
        Elle utilise un cache pour optimiser les performances.

    .PARAMETER Value
        La valeur à vérifier.

    .PARAMETER EnumType
        Le type d'énumération cible.

    .PARAMETER IgnoreCase
        Indique si la comparaison des chaînes doit être insensible à la casse.
        Par défaut, la valeur est $true.

    .PARAMETER NoCache
        Indique si le cache doit être ignoré. Si $true, les informations sont toujours récupérées
        directement depuis le type d'énumération, sans utiliser le cache.

    .EXAMPLE
        Test-EnumValue -Value "ReadWrite" -EnumType ([System.IO.FileAccess])
        Vérifie si "ReadWrite" est une valeur valide pour l'énumération System.IO.FileAccess.

    .EXAMPLE
        Test-EnumValue -Value 2 -EnumType ([System.IO.FileAccess])
        Vérifie si 2 est une valeur valide pour l'énumération System.IO.FileAccess.

    .OUTPUTS
        [bool] $true si la valeur est valide, $false sinon.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowNull()]
        [object]$Value,

        [Parameter(Mandatory = $true, Position = 1)]
        [type]$EnumType,

        [Parameter(Mandatory = $false)]
        [bool]$IgnoreCase = $true,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    # Vérifier que le type est bien une énumération
    if (-not $EnumType.IsEnum) {
        throw [System.ArgumentException]::new("Le type spécifié n'est pas une énumération.", "EnumType")
    }

    # Vérifier si la valeur est null
    if ($null -eq $Value) {
        return $false
    }

    # Vérifier si la valeur est déjà du type d'énumération
    if ($Value.GetType() -eq $EnumType) {
        return $true
    }

    # Utiliser le cache pour optimiser les performances
    try {
        # Récupérer les informations sur le type d'énumération
        $enumInfo = Get-EnumTypeInfo -EnumType $EnumType -NoCache:$NoCache

        # Vérifier si la valeur est une chaîne
        if ($Value -is [string]) {
            # Vérifier si la chaîne est un nom valide pour l'énumération
            if ($IgnoreCase) {
                $valueLower = $Value.ToLower()
                foreach ($name in $enumInfo.Names) {
                    if ($name -eq $Value -or $name.ToLower() -eq $valueLower) {
                        return $true
                    }
                }
            } else {
                return $enumInfo.NameValueMap.ContainsKey($Value)
            }
            return $false
        }

        # Vérifier si la valeur est un nombre
        if ($Value -is [int] -or $Value -is [long] -or $Value -is [byte] -or $Value -is [short]) {
            # Vérifier si le nombre est une valeur valide pour l'énumération
            foreach ($enumValue in $enumInfo.Values) {
                if ([int]$enumValue -eq $Value) {
                    return $true
                }
            }
            return $false
        }

        # La valeur n'est pas valide
        return $false
    } catch {
        # En cas d'erreur, utiliser la méthode standard
        Write-Verbose "Erreur lors de l'utilisation du cache pour la validation d'énumération : $_"

        # Vérifier si la valeur est une chaîne
        if ($Value -is [string]) {
            # Vérifier si la chaîne est un nom valide pour l'énumération
            return [Enum]::GetNames($EnumType) | Where-Object {
                if ($IgnoreCase) {
                    $_ -eq $Value -or $_.ToLower() -eq $Value.ToLower()
                } else {
                    $_ -eq $Value
                }
            } | Select-Object -First 1 | ForEach-Object { $true } | Select-Object -First 1 -ErrorAction SilentlyContinue
        }

        # Vérifier si la valeur est un nombre
        if ($Value -is [int] -or $Value -is [long] -or $Value -is [byte] -or $Value -is [short]) {
            # Vérifier si le nombre est une valeur valide pour l'énumération
            return [Enum]::GetValues($EnumType) | ForEach-Object { [int]$_ } | Where-Object { $_ -eq $Value } | Select-Object -First 1 | ForEach-Object { $true } | Select-Object -First 1 -ErrorAction SilentlyContinue
        }

        # La valeur n'est pas valide
        return $false
    }
}

# Fonction pour convertir une chaîne en valeur d'énumération ApartmentState
function ConvertTo-ApartmentState {
    <#
    .SYNOPSIS
        Convertit une chaîne en valeur d'énumération ApartmentState.

    .DESCRIPTION
        Cette fonction convertit une chaîne en valeur d'énumération System.Threading.ApartmentState.
        Elle vérifie que la valeur est valide et lance une exception si la conversion échoue.
        Elle utilise un cache pour optimiser les performances.

    .PARAMETER Value
        La chaîne à convertir en valeur d'énumération ApartmentState.
        Valeurs valides : "STA" (Single-Threaded Apartment) ou "MTA" (Multi-Threaded Apartment).

    .PARAMETER DefaultValue
        La valeur par défaut à retourner en cas d'échec de la conversion.
        Si ce paramètre est spécifié, aucune exception ne sera lancée en cas d'échec.

    .PARAMETER NoCache
        Indique si le cache doit être ignoré. Si $true, les informations sont toujours récupérées
        directement depuis le type d'énumération, sans utiliser le cache.

    .EXAMPLE
        ConvertTo-ApartmentState -Value "STA"
        Convertit la chaîne "STA" en valeur d'énumération System.Threading.ApartmentState.STA.

    .EXAMPLE
        ConvertTo-ApartmentState -Value "InvalidValue" -DefaultValue ([System.Threading.ApartmentState]::MTA)
        Tente de convertir la chaîne "InvalidValue" en valeur d'énumération System.Threading.ApartmentState.
        Comme la conversion échoue, retourne la valeur par défaut System.Threading.ApartmentState.MTA.

    .OUTPUTS
        System.Threading.ApartmentState
        La valeur d'énumération ApartmentState convertie ou la valeur par défaut en cas d'échec.
    #>
    [CmdletBinding()]
    [OutputType([System.Threading.ApartmentState])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter(Mandatory = $false)]
        [System.Threading.ApartmentState]$DefaultValue,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    # Vérifier si la valeur par défaut est spécifiée
    $hasDefaultValue = $PSBoundParameters.ContainsKey('DefaultValue')

    # Utiliser la fonction générique ConvertTo-Enum
    try {
        return ConvertTo-Enum -Value $Value -EnumType ([System.Threading.ApartmentState]) -DefaultValue $DefaultValue -NoCache:$NoCache
    } catch {
        if ($hasDefaultValue) {
            return $DefaultValue
        } else {
            throw [System.ArgumentException]::new("Impossible de convertir la valeur '$Value' en énumération ApartmentState. Valeurs valides : STA, MTA.", "Value")
        }
    }
}

# Fonction pour convertir une valeur d'énumération ApartmentState en chaîne
function ConvertFrom-ApartmentState {
    <#
    .SYNOPSIS
        Convertit une valeur d'énumération ApartmentState en chaîne.

    .DESCRIPTION
        Cette fonction convertit une valeur d'énumération System.Threading.ApartmentState en chaîne.
        Elle vérifie que la valeur est bien une énumération ApartmentState et lance une exception si la conversion échoue.
        Elle utilise un cache pour optimiser les performances.

    .PARAMETER EnumValue
        La valeur d'énumération ApartmentState à convertir en chaîne.

    .PARAMETER NoCache
        Indique si le cache doit être ignoré. Si $true, les informations sont toujours récupérées
        directement depuis le type d'énumération, sans utiliser le cache.

    .EXAMPLE
        ConvertFrom-ApartmentState -EnumValue ([System.Threading.ApartmentState]::STA)
        Convertit la valeur d'énumération System.Threading.ApartmentState.STA en chaîne "STA".

    .OUTPUTS
        System.String
        La chaîne représentant la valeur d'énumération ApartmentState.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Threading.ApartmentState]$EnumValue,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    # Utiliser la fonction générique ConvertFrom-Enum
    try {
        return ConvertFrom-Enum -EnumValue $EnumValue -NoCache:$NoCache
    } catch {
        throw [System.ArgumentException]::new("Impossible de convertir la valeur d'énumération ApartmentState en chaîne.", "EnumValue")
    }
}

# Fonction pour valider une valeur d'énumération ApartmentState
function Test-ApartmentState {
    <#
    .SYNOPSIS
        Vérifie si une valeur est une valeur valide pour l'énumération ApartmentState.

    .DESCRIPTION
        Cette fonction vérifie si une valeur est une valeur valide pour l'énumération System.Threading.ApartmentState.
        Elle peut vérifier une chaîne ou une valeur numérique.
        Elle utilise un cache pour optimiser les performances.

    .PARAMETER Value
        La valeur à vérifier.

    .PARAMETER IgnoreCase
        Indique si la comparaison des chaînes doit être insensible à la casse.
        Par défaut, la valeur est $true.

    .PARAMETER NoCache
        Indique si le cache doit être ignoré. Si $true, les informations sont toujours récupérées
        directement depuis le type d'énumération, sans utiliser le cache.

    .EXAMPLE
        Test-ApartmentState -Value "STA"
        Vérifie si "STA" est une valeur valide pour l'énumération System.Threading.ApartmentState.

    .EXAMPLE
        Test-ApartmentState -Value 0
        Vérifie si 0 est une valeur valide pour l'énumération System.Threading.ApartmentState.

    .OUTPUTS
        System.Boolean
        $true si la valeur est valide, $false sinon.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowNull()]
        [object]$Value,

        [Parameter(Mandatory = $false)]
        [bool]$IgnoreCase = $true,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    # Utiliser la fonction générique Test-EnumValue
    return Test-EnumValue -Value $Value -EnumType ([System.Threading.ApartmentState]) -IgnoreCase $IgnoreCase -NoCache:$NoCache
}

# Fonction pour convertir une chaîne en valeur d'énumération PSThreadOptions
function ConvertTo-PSThreadOptions {
    <#
    .SYNOPSIS
        Convertit une chaîne en valeur d'énumération PSThreadOptions.

    .DESCRIPTION
        Cette fonction convertit une chaîne en valeur d'énumération System.Management.Automation.Runspaces.PSThreadOptions.
        Elle vérifie que la valeur est valide et lance une exception si la conversion échoue.
        Elle utilise un cache pour optimiser les performances.

    .PARAMETER Value
        La chaîne à convertir en valeur d'énumération PSThreadOptions.
        Valeurs valides : "Default", "UseNewThread", "ReuseThread".

    .PARAMETER DefaultValue
        La valeur par défaut à retourner en cas d'échec de la conversion.
        Si ce paramètre est spécifié, aucune exception ne sera lancée en cas d'échec.

    .PARAMETER NoCache
        Indique si le cache doit être ignoré. Si $true, les informations sont toujours récupérées
        directement depuis le type d'énumération, sans utiliser le cache.

    .EXAMPLE
        ConvertTo-PSThreadOptions -Value "ReuseThread"
        Convertit la chaîne "ReuseThread" en valeur d'énumération System.Management.Automation.Runspaces.PSThreadOptions.ReuseThread.

    .EXAMPLE
        ConvertTo-PSThreadOptions -Value "InvalidValue" -DefaultValue ([System.Management.Automation.Runspaces.PSThreadOptions]::Default)
        Tente de convertir la chaîne "InvalidValue" en valeur d'énumération System.Management.Automation.Runspaces.PSThreadOptions.
        Comme la conversion échoue, retourne la valeur par défaut System.Management.Automation.Runspaces.PSThreadOptions.Default.

    .OUTPUTS
        System.Management.Automation.Runspaces.PSThreadOptions
        La valeur d'énumération PSThreadOptions convertie ou la valeur par défaut en cas d'échec.
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Runspaces.PSThreadOptions])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.Runspaces.PSThreadOptions]$DefaultValue,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    # Vérifier si la valeur par défaut est spécifiée
    $hasDefaultValue = $PSBoundParameters.ContainsKey('DefaultValue')

    # Utiliser la fonction générique ConvertTo-Enum
    try {
        return ConvertTo-Enum -Value $Value -EnumType ([System.Management.Automation.Runspaces.PSThreadOptions]) -DefaultValue $DefaultValue -NoCache:$NoCache
    } catch {
        if ($hasDefaultValue) {
            return $DefaultValue
        } else {
            throw [System.ArgumentException]::new("Impossible de convertir la valeur '$Value' en énumération PSThreadOptions. Valeurs valides : Default, UseNewThread, ReuseThread.", "Value")
        }
    }
}

# Fonction pour convertir une valeur d'énumération PSThreadOptions en chaîne
function ConvertFrom-PSThreadOptions {
    <#
    .SYNOPSIS
        Convertit une valeur d'énumération PSThreadOptions en chaîne.

    .DESCRIPTION
        Cette fonction convertit une valeur d'énumération System.Management.Automation.Runspaces.PSThreadOptions en chaîne.
        Elle vérifie que la valeur est bien une énumération PSThreadOptions et lance une exception si la conversion échoue.
        Elle utilise un cache pour optimiser les performances.

    .PARAMETER EnumValue
        La valeur d'énumération PSThreadOptions à convertir en chaîne.

    .PARAMETER NoCache
        Indique si le cache doit être ignoré. Si $true, les informations sont toujours récupérées
        directement depuis le type d'énumération, sans utiliser le cache.

    .EXAMPLE
        ConvertFrom-PSThreadOptions -EnumValue ([System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread)
        Convertit la valeur d'énumération System.Management.Automation.Runspaces.PSThreadOptions.ReuseThread en chaîne "ReuseThread".

    .OUTPUTS
        System.String
        La chaîne représentant la valeur d'énumération PSThreadOptions.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.Runspaces.PSThreadOptions]$EnumValue,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    # Utiliser la fonction générique ConvertFrom-Enum
    try {
        return ConvertFrom-Enum -EnumValue $EnumValue -NoCache:$NoCache
    } catch {
        throw [System.ArgumentException]::new("Impossible de convertir la valeur d'énumération PSThreadOptions en chaîne.", "EnumValue")
    }
}

# Fonction pour valider une valeur d'énumération PSThreadOptions
function Test-PSThreadOptions {
    <#
    .SYNOPSIS
        Vérifie si une valeur est une valeur valide pour l'énumération PSThreadOptions.

    .DESCRIPTION
        Cette fonction vérifie si une valeur est une valeur valide pour l'énumération System.Management.Automation.Runspaces.PSThreadOptions.
        Elle peut vérifier une chaîne ou une valeur numérique.
        Elle utilise un cache pour optimiser les performances.

    .PARAMETER Value
        La valeur à vérifier.

    .PARAMETER IgnoreCase
        Indique si la comparaison des chaînes doit être insensible à la casse.
        Par défaut, la valeur est $true.

    .PARAMETER NoCache
        Indique si le cache doit être ignoré. Si $true, les informations sont toujours récupérées
        directement depuis le type d'énumération, sans utiliser le cache.

    .EXAMPLE
        Test-PSThreadOptions -Value "ReuseThread"
        Vérifie si "ReuseThread" est une valeur valide pour l'énumération System.Management.Automation.Runspaces.PSThreadOptions.

    .EXAMPLE
        Test-PSThreadOptions -Value 0
        Vérifie si 0 est une valeur valide pour l'énumération System.Management.Automation.Runspaces.PSThreadOptions.

    .OUTPUTS
        System.Boolean
        $true si la valeur est valide, $false sinon.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowNull()]
        [object]$Value,

        [Parameter(Mandatory = $false)]
        [bool]$IgnoreCase = $true,

        [Parameter(Mandatory = $false)]
        [switch]$NoCache
    )

    # Utiliser la fonction générique Test-EnumValue
    return Test-EnumValue -Value $Value -EnumType ([System.Management.Automation.Runspaces.PSThreadOptions]) -IgnoreCase $IgnoreCase -NoCache:$NoCache
}

# Fonction pour obtenir les informations sur la version de PowerShell
function Get-PowerShellVersionInfo {
    <#
    .SYNOPSIS
        Récupère les informations détaillées sur la version de PowerShell en cours d'exécution.

    .DESCRIPTION
        Cette fonction récupère des informations détaillées sur la version de PowerShell en cours d'exécution,
        y compris la version majeure, mineure, la build, la révision, l'édition (Desktop ou Core),
        et d'autres informations utiles pour adapter le comportement des fonctions.

    .PARAMETER Refresh
        Si spécifié, force la récupération des informations même si elles sont déjà en cache.

    .EXAMPLE
        $psInfo = Get-PowerShellVersionInfo
        $psInfo.Version
        # Affiche la version complète de PowerShell

    .EXAMPLE
        $psInfo = Get-PowerShellVersionInfo
        if ($psInfo.IsCore) {
            # Code spécifique à PowerShell Core
        } else {
            # Code spécifique à Windows PowerShell
        }

    .OUTPUTS
        PSCustomObject
        Un objet personnalisé contenant les informations sur la version de PowerShell.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Refresh
    )

    # Vérifier si les informations sont déjà en cache et si on ne force pas la récupération
    if ($script:PowerShellVersionInfo -and -not $Refresh) {
        return $script:PowerShellVersionInfo
    }

    # Récupérer les informations sur la version de PowerShell
    $psVersion = $PSVersionTable.PSVersion
    $currentEdition = if ($PSVersionTable.ContainsKey('PSEdition')) { $PSVersionTable.PSEdition } else { 'Desktop' }
    $isCorePowerShell = $currentEdition -eq 'Core'
    $isWindowsOS = if ($isCorePowerShell) { $IsWindows } else { $true }
    $isLinuxOS = if ($isCorePowerShell) { $IsLinux } else { $false }
    $isMacOSPlatform = if ($isCorePowerShell) { $IsMacOS } else { $false }

    # Créer l'objet d'informations
    $script:PowerShellVersionInfo = [PSCustomObject]@{
        Version                      = $psVersion
        Major                        = $psVersion.Major
        Minor                        = $psVersion.Minor
        Build                        = if ($psVersion.PSObject.Properties.Name -contains 'Build') { $psVersion.Build } else { 0 }
        Revision                     = if ($psVersion.PSObject.Properties.Name -contains 'Revision') { $psVersion.Revision } else { 0 }
        Edition                      = $currentEdition
        IsCore                       = $isCorePowerShell
        IsDesktop                    = -not $isCorePowerShell
        IsWindows                    = $isWindowsOS
        IsLinux                      = $isLinuxOS
        IsMacOS                      = $isMacOSPlatform
        Is64Bit                      = [System.Environment]::Is64BitProcess
        CLRVersion                   = [System.Environment]::Version
        HasForEachParallel           = $isCorePowerShell -and $psVersion.Major -ge 7
        HasRunspaces                 = $true # Toutes les versions de PowerShell supportent les Runspaces
        HasThreadJobs                = $isCorePowerShell -or ($psVersion.Major -ge 5 -and $psVersion.Minor -ge 1)
        SupportsUTF8NoBOM            = $isCorePowerShell -or ($psVersion.Major -ge 5 -and $psVersion.Minor -ge 1)
        OptimalParallelizationMethod = if ($isCorePowerShell -and $psVersion.Major -ge 7) { 'ForEachParallel' } else { 'RunspacePool' }
    }

    return $script:PowerShellVersionInfo
}

# Fonction pour journaliser les problèmes de conversion
function Write-ConversionLog {
    <#
    .SYNOPSIS
        Journalise les problèmes de conversion d'énumérations.

    .DESCRIPTION
        Cette fonction journalise les problèmes de conversion d'énumérations dans un fichier de log
        ou dans la console, selon la configuration. Elle permet de suivre les problèmes de conversion
        et de les analyser pour améliorer les fonctions de conversion.

    .PARAMETER Message
        Le message à journaliser.

    .PARAMETER Level
        Le niveau de journalisation. Valeurs possibles : 'Info', 'Warning', 'Error'.
        Par défaut, la valeur est 'Warning'.

    .PARAMETER EnumType
        Le type d'énumération concerné par le problème de conversion.

    .PARAMETER Value
        La valeur qui a posé problème lors de la conversion.

    .PARAMETER Exception
        L'exception qui a été levée lors de la conversion, le cas échéant.

    .PARAMETER LogToFile
        Indique si le message doit être journalisé dans un fichier.
        Par défaut, la valeur est déterminée par la configuration du module.

    .PARAMETER LogToConsole
        Indique si le message doit être affiché dans la console.
        Par défaut, la valeur est déterminée par la configuration du module.

    .PARAMETER LogFilePath
        Le chemin du fichier de log. Si non spécifié, utilise le chemin par défaut
        défini dans la configuration du module.

    .EXAMPLE
        Write-ConversionLog -Message "Impossible de convertir la valeur" -Level Error -EnumType ([System.Threading.ApartmentState]) -Value "InvalidValue" -Exception $_.Exception

    .EXAMPLE
        Write-ConversionLog -Message "Conversion réussie avec valeur par défaut" -Level Info -EnumType ([System.Threading.ApartmentState]) -Value "InvalidValue"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Warning',

        [Parameter(Mandatory = $false)]
        [type]$EnumType,

        [Parameter(Mandatory = $false)]
        [object]$Value,

        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception,

        [Parameter(Mandatory = $false)]
        [bool]$LogToFile,

        [Parameter(Mandatory = $false)]
        [bool]$LogToConsole,

        [Parameter(Mandatory = $false)]
        [string]$LogFilePath
    )

    # Récupérer la configuration du module
    $config = Get-ModuleConfig

    # Déterminer si on doit journaliser dans un fichier
    if (-not $PSBoundParameters.ContainsKey('LogToFile')) {
        $LogToFile = $config.Logging.EnableFileLogging
    }

    # Déterminer si on doit journaliser dans la console
    if (-not $PSBoundParameters.ContainsKey('LogToConsole')) {
        $LogToConsole = $config.Logging.EnableConsoleLogging
    }

    # Déterminer le chemin du fichier de log
    if (-not $PSBoundParameters.ContainsKey('LogFilePath')) {
        $LogFilePath = $config.Logging.LogFilePath
    }

    # Créer le message de log
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level]"

    # Ajouter les informations sur l'énumération
    if ($EnumType) {
        $logMessage += " [Enum: $($EnumType.FullName)]"
    }

    # Ajouter les informations sur la valeur
    if ($null -ne $Value) {
        $logMessage += " [Value: $Value]"
    }

    # Ajouter le message principal
    $logMessage += " $Message"

    # Ajouter les informations sur l'exception
    if ($Exception) {
        $logMessage += " [Exception: $($Exception.GetType().Name)] $($Exception.Message)"
    }

    # Journaliser dans la console si demandé
    if ($LogToConsole) {
        $foregroundColor = switch ($Level) {
            'Info' { 'White' }
            'Warning' { 'Yellow' }
            'Error' { 'Red' }
            default { 'White' }
        }
        Write-Host $logMessage -ForegroundColor $foregroundColor
    }

    # Journaliser dans un fichier si demandé
    if ($LogToFile -and $LogFilePath) {
        try {
            # Créer le dossier parent si nécessaire
            $logFolder = Split-Path -Path $LogFilePath -Parent
            if (-not (Test-Path -Path $logFolder -PathType Container)) {
                New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
            }

            # Ajouter le message au fichier de log
            Add-Content -Path $LogFilePath -Value $logMessage -Encoding UTF8
        } catch {
            # En cas d'erreur lors de l'écriture dans le fichier, afficher un message dans la console
            Write-Host "Erreur lors de l'écriture dans le fichier de log: $_" -ForegroundColor Red
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-UnifiedParallel, Clear-UnifiedParallel, Invoke-UnifiedParallel, Get-OptimalThreadCount, Wait-ForCompletedRunspace, Invoke-RunspaceProcessor, Get-ModuleInitialized, Set-ModuleInitialized, Get-ModuleConfig, Set-ModuleConfig, New-RunspaceBatch, Get-RunspacePoolFromCache, Clear-RunspacePoolCache, Get-RunspacePoolCacheInfo, Initialize-EncodingSettings, New-UnifiedError, Get-UnifiedParallelVersion, ConvertTo-Enum, ConvertFrom-Enum, Test-EnumValue, Get-EnumTypeInfo, ConvertTo-ApartmentState, ConvertFrom-ApartmentState, Test-ApartmentState, ConvertTo-PSThreadOptions, ConvertFrom-PSThreadOptions, Test-PSThreadOptions, Get-PowerShellVersionInfo, Write-ConversionLog
