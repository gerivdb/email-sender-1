<#
.SYNOPSIS
    Gère les erreurs et les exceptions dans le module RoadmapParser.

.DESCRIPTION
    Ce fichier contient des fonctions pour gérer les erreurs et les exceptions dans le module RoadmapParser.
    Il inclut des fonctions pour journaliser les erreurs, les catégoriser, déterminer leur sévérité,
    et implémenter des stratégies de nouvelle tentative.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-15
#>

<#
.SYNOPSIS
    Gère une erreur en la journalisant et en effectuant des actions appropriées.

.DESCRIPTION
    Cette fonction prend un enregistrement d'erreur, le journalise et effectue des actions
    en fonction des paramètres spécifiés.

.PARAMETER ErrorRecord
    L'enregistrement d'erreur à gérer.

.PARAMETER ErrorMessage
    Un message d'erreur personnalisé à journaliser.

.PARAMETER Context
    Informations contextuelles supplémentaires sur l'erreur.

.PARAMETER LogFile
    Le chemin du fichier de journal où enregistrer l'erreur.

.PARAMETER Category
    La catégorie de l'erreur (par exemple, "IO", "Parsing", etc.).

.PARAMETER Severity
    La sévérité de l'erreur (1-5, où 5 est la plus sévère).

.PARAMETER ExitCode
    Le code de sortie à utiliser si ExitOnError est vrai.

.PARAMETER ExitOnError
    Indique si le script doit se terminer après avoir géré l'erreur.

.PARAMETER ThrowException
    Indique si l'exception doit être relancée après avoir été journalisée.

.EXAMPLE
    try {
        # Code qui peut générer une erreur
    } catch {
        Handle-Error -ErrorRecord $_ -ErrorMessage "Erreur lors du traitement du fichier" -Context "Traitement de données" -LogFile ".\logs\app.log"
    }

.NOTES
    Cette fonction est conçue pour standardiser la gestion des erreurs dans le module.
#>
function Handle-Error {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = "Une erreur s'est produite",

        [Parameter(Mandatory = $false)]
        [hashtable]$Context = @{},

        [Parameter(Mandatory = $false)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [string]$Category = "General",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [int]$Severity = 3,

        [Parameter(Mandatory = $false)]
        [int]$ExitCode = 1,

        [Parameter(Mandatory = $false)]
        [switch]$ExitOnError,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowException
    )

    # Enrichir l'erreur avec des informations contextuelles
    $exceptionInfo = Get-ExceptionInfo -Exception $ErrorRecord.Exception -Context $Context -IncludeStackTrace $true

    # Déterminer la catégorie de l'erreur si non spécifiée
    if ($Category -eq "General") {
        $Category = Get-ExceptionCategory -Exception $ErrorRecord.Exception
    }

    # Déterminer la sévérité de l'erreur si non spécifiée
    if ($Severity -eq 3) {
        $Severity = Get-ExceptionSeverity -Exception $ErrorRecord.Exception -Category $Category
    }

    # Construire le message d'erreur complet
    $fullErrorMessage = @"
$ErrorMessage
Type: $($exceptionInfo.Type)
Message: $($exceptionInfo.Message)
Catégorie: $Category
Sévérité: $Severity
"@

    # Ajouter des informations contextuelles si disponibles
    if ($Context.Count -gt 0) {
        $fullErrorMessage += "`nContexte:"
        foreach ($key in $Context.Keys) {
            $fullErrorMessage += "`n  ${key}: $($Context[$key])"
        }
    }

    # Journaliser l'erreur
    Write-LogError -Message $fullErrorMessage

    # Journaliser dans un fichier si spécifié
    if ($LogFile) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] ERROR: $fullErrorMessage`n"
        Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
    }

    # Gérer l'erreur selon les paramètres
    if ($ThrowException) {
        throw $ErrorRecord
    }

    if ($ExitOnError) {
        exit $ExitCode
    }
}

<#
.SYNOPSIS
    Exécute une action avec des tentatives en cas d'échec.

.DESCRIPTION
    Cette fonction exécute un bloc de script et réessaie en cas d'échec,
    selon une stratégie de nouvelle tentative spécifiée.

.PARAMETER ScriptBlock
    Le bloc de script à exécuter.

.PARAMETER MaxRetries
    Le nombre maximum de nouvelles tentatives.

.PARAMETER RetryDelaySeconds
    Le délai en secondes entre les tentatives.

.PARAMETER RetryStrategy
    La stratégie de nouvelle tentative à utiliser (Fixed, Exponential, ExponentialWithJitter).

.PARAMETER ExceptionTypes
    Les types d'exceptions pour lesquels réessayer.

.PARAMETER OnRetry
    Un bloc de script à exécuter avant chaque nouvelle tentative.

.PARAMETER OnSuccess
    Un bloc de script à exécuter en cas de succès.

.PARAMETER OnFailure
    Un bloc de script à exécuter en cas d'échec final.

.EXAMPLE
    $result = Invoke-WithRetry -ScriptBlock { Invoke-RestMethod -Uri $url } -MaxRetries 5 -RetryStrategy "ExponentialWithJitter"

.NOTES
    Cette fonction est utile pour les opérations qui peuvent échouer temporairement, comme les appels réseau.
#>
function Invoke-WithRetry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3,

        [Parameter(Mandatory = $false)]
        [int]$RetryDelaySeconds = 2,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Fixed", "Exponential", "ExponentialWithJitter")]
        [string]$RetryStrategy = "ExponentialWithJitter",

        [Parameter(Mandatory = $false)]
        [Type[]]$ExceptionTypes = @([System.Exception]),

        [Parameter(Mandatory = $false)]
        [scriptblock]$OnRetry = $null,

        [Parameter(Mandatory = $false)]
        [scriptblock]$OnSuccess = $null,

        [Parameter(Mandatory = $false)]
        [scriptblock]$OnFailure = $null
    )

    $retryCount = 0
    $success = $false
    $result = $null
    $lastException = $null

    do {
        try {
            $result = & $ScriptBlock
            $success = $true

            # Exécuter le script de succès si fourni
            if ($OnSuccess -ne $null) {
                & $OnSuccess -Result $result
            }

            break
        }
        catch {
            $lastException = $_
            $shouldRetry = $false

            # Vérifier si l'exception est d'un type pour lequel on doit réessayer
            foreach ($exceptionType in $ExceptionTypes) {
                if ($_.Exception -is $exceptionType) {
                    $shouldRetry = $true
                    break
                }
            }

            if (-not $shouldRetry -or $retryCount -ge $MaxRetries) {
                # Exécuter le script d'échec si fourni
                if ($OnFailure -ne $null) {
                    & $OnFailure -Exception $lastException -RetryCount $retryCount
                }
                throw
            }

            $retryCount++

            # Calculer le délai selon la stratégie choisie
            $delay = switch ($RetryStrategy) {
                "Fixed" { $RetryDelaySeconds }
                "Exponential" { [math]::Pow(2, $retryCount - 1) * $RetryDelaySeconds }
                "ExponentialWithJitter" {
                    $baseDelay = [math]::Pow(2, $retryCount - 1) * $RetryDelaySeconds
                    $jitter = Get-Random -Minimum 0 -Maximum $baseDelay
                    $baseDelay + $jitter
                }
            }

            # Exécuter le script de nouvelle tentative si fourni
            if ($OnRetry -ne $null) {
                & $OnRetry -Exception $lastException -RetryCount $retryCount -Delay $delay
            }

            Write-LogWarning -Message "Tentative $retryCount/$MaxRetries a échoué. Nouvelle tentative dans $delay secondes..."
            Start-Sleep -Seconds $delay
        }
    } while ($retryCount -le $MaxRetries)

    return $result
}

<#
.SYNOPSIS
    Capture et enrichit les informations d'une exception.

.DESCRIPTION
    Cette fonction capture les détails d'une exception et les enrichit avec des informations contextuelles.

.PARAMETER Exception
    L'exception à analyser.

.PARAMETER Context
    Informations contextuelles supplémentaires.

.PARAMETER IncludeStackTrace
    Indique si la pile d'appels doit être incluse.

.PARAMETER IncludeInnerExceptions
    Indique si les exceptions internes doivent être incluses.

.EXAMPLE
    $exceptionInfo = Get-ExceptionInfo -Exception $_.Exception -IncludeStackTrace $true

.NOTES
    Cette fonction est utile pour standardiser la capture d'informations d'exception.
#>
function Get-ExceptionInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Exception]$Exception,

        [Parameter(Mandatory = $false)]
        [hashtable]$Context = @{},

        [Parameter(Mandatory = $false)]
        [bool]$IncludeStackTrace = $true,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeInnerExceptions = $true
    )

    $exceptionInfo = [ordered]@{
        Type = $Exception.GetType().FullName
        Message = $Exception.Message
        HResult = $Exception.HResult
        Source = $Exception.Source
        Data = @{}
    }

    # Ajouter les données de l'exception
    foreach ($key in $Exception.Data.Keys) {
        $exceptionInfo.Data[$key] = $Exception.Data[$key]
    }

    # Ajouter la pile d'appels si demandé
    if ($IncludeStackTrace) {
        $exceptionInfo.StackTrace = if ($Exception.StackTrace) { $Exception.StackTrace } else { "No stack trace available" }
    }

    # Ajouter les exceptions internes si demandé
    if ($IncludeInnerExceptions -and $Exception.InnerException) {
        $innerExceptions = @()
        $currentException = $Exception.InnerException

        while ($currentException -ne $null) {
            $innerExceptionInfo = [ordered]@{
                Type = $currentException.GetType().FullName
                Message = $currentException.Message
                HResult = $currentException.HResult
                Source = $currentException.Source
            }

            if ($IncludeStackTrace -and $currentException.StackTrace) {
                $innerExceptionInfo.StackTrace = $currentException.StackTrace
            }

            $innerExceptions += $innerExceptionInfo
            $currentException = $currentException.InnerException
        }

        $exceptionInfo.InnerExceptions = $innerExceptions
    }

    # Ajouter le contexte
    if ($Context.Count -gt 0) {
        $exceptionInfo.Context = $Context
    }

    return $exceptionInfo
}

<#
.SYNOPSIS
    Catégorise une exception en fonction de son type et de son message.

.DESCRIPTION
    Cette fonction analyse une exception et la classe dans une catégorie prédéfinie.

.PARAMETER Exception
    L'exception à catégoriser.

.PARAMETER DefaultCategory
    La catégorie par défaut si aucune correspondance n'est trouvée.

.EXAMPLE
    $category = Get-ExceptionCategory -Exception $_.Exception

.NOTES
    Cette fonction aide à standardiser la catégorisation des erreurs pour une meilleure analyse.
#>
function Get-ExceptionCategory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Exception]$Exception,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Syntax", "Runtime", "Configuration", "Permission", "Resource", "Data", "External", "Unknown")]
        [string]$DefaultCategory = "Unknown"
    )

    # Définir les mappages de types d'exceptions vers des catégories
    $typeMappings = @{
        [System.ArgumentException] = "Syntax"
        [System.ArgumentNullException] = "Syntax"
        [System.ArgumentOutOfRangeException] = "Syntax"
        [System.FormatException] = "Syntax"
        [System.InvalidOperationException] = "Runtime"
        [System.NotImplementedException] = "Runtime"
        [System.NotSupportedException] = "Runtime"
        [System.IO.IOException] = "Resource"
        [System.IO.FileNotFoundException] = "Resource"
        [System.IO.DirectoryNotFoundException] = "Resource"
        [System.IO.PathTooLongException] = "Resource"
        [System.Security.SecurityException] = "Permission"
        [System.UnauthorizedAccessException] = "Permission"
        [System.Net.WebException] = "External"
    }

    # Définir les mappages de mots-clés dans les messages d'erreur vers des catégories
    $messageMappings = @{
        "permission denied" = "Permission"
        "access is denied" = "Permission"
        "unauthorized" = "Permission"
        "not found" = "Resource"
        "does not exist" = "Resource"
        "timeout" = "External"
        "timed out" = "External"
        "connection" = "External"
        "network" = "External"
        "invalid format" = "Syntax"
        "invalid argument" = "Syntax"
        "null reference" = "Runtime"
        "configuration" = "Configuration"
        "setting" = "Configuration"
        "data" = "Data"
        "database" = "Data"
        "sql" = "Data"
    }

    # Vérifier d'abord le type d'exception
    foreach ($type in $typeMappings.Keys) {
        if ($Exception -is $type) {
            return $typeMappings[$type]
        }
    }

    # Ensuite, vérifier le message d'erreur
    $message = $Exception.Message.ToLower()
    foreach ($keyword in $messageMappings.Keys) {
        if ($message -match $keyword) {
            return $messageMappings[$keyword]
        }
    }

    # Si aucune correspondance n'est trouvée, retourner la catégorie par défaut
    return $DefaultCategory
}

<#
.SYNOPSIS
    Détermine la sévérité d'une exception en fonction de son type et de son impact.

.DESCRIPTION
    Cette fonction analyse une exception et détermine sa sévérité sur une échelle de 1 à 5.

.PARAMETER Exception
    L'exception à évaluer.

.PARAMETER Category
    La catégorie de l'exception.

.PARAMETER DefaultSeverity
    La sévérité par défaut si aucune correspondance n'est trouvée.

.EXAMPLE
    $severity = Get-ExceptionSeverity -Exception $_.Exception -Category "Permission"

.NOTES
    Cette fonction aide à prioriser les erreurs en fonction de leur impact.
#>
function Get-ExceptionSeverity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Exception]$Exception,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Syntax", "Runtime", "Configuration", "Permission", "Resource", "Data", "External", "Unknown")]
        [string]$Category = "Unknown",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [int]$DefaultSeverity = 3
    )

    # Définir les sévérités par catégorie (1 = faible, 5 = critique)
    $categorySeverities = @{
        "Syntax" = 2        # Erreurs de syntaxe, généralement faciles à corriger
        "Runtime" = 3       # Erreurs d'exécution, peuvent indiquer des bugs
        "Configuration" = 3 # Erreurs de configuration, généralement corrigeables
        "Permission" = 5    # Erreurs de permission, peuvent bloquer des fonctionnalités
        "Resource" = 4      # Erreurs de ressources, peuvent indiquer des problèmes système
        "Data" = 4          # Erreurs de données, peuvent indiquer une corruption
        "External" = 3      # Erreurs externes, dépendent de services tiers
        "Unknown" = 3       # Erreurs inconnues, sévérité moyenne par défaut
    }

    # Définir les sévérités par type d'exception
    $typeSeverities = @{
        "System.OutOfMemoryException" = 5
        "System.StackOverflowException" = 5
        "System.Threading.ThreadAbortException" = 5
        "System.AccessViolationException" = 5
        "System.IO.FileNotFoundException" = 3
        "System.ArgumentException" = 2
        "System.FormatException" = 2
    }

    # Définir les sévérités par mots-clés dans les messages
    $messageSeverities = @{
        "critical" = 5
        "fatal" = 5
        "crash" = 5
        "corrupted" = 4
        "cannot proceed" = 4
        "error: operation failed" = 4
        "critical error: system crash" = 5
        "warning: potential problem" = 3
        "notice: minor issue" = 2
        "failed" = 3
        "warning" = 2
        "deprecated" = 2
        "note" = 1
    }

    # Vérifier d'abord le type d'exception
    foreach ($type in $typeSeverities.Keys) {
        try {
            $typeObj = [type]$type
            if ($Exception -is $typeObj) {
                return $typeSeverities[$type]
            }
        } catch {
            # Ignorer les erreurs de conversion de type
            Write-Verbose "Impossible de convertir '$type' en type: $_"
        }
    }

    # Ensuite, vérifier le message d'erreur
    $message = $Exception.Message.ToLower()
    foreach ($keyword in $messageSeverities.Keys) {
        if ($message -match $keyword) {
            return $messageSeverities[$keyword]
        }
    }

    # Si aucune correspondance par type ou message, utiliser la catégorie
    if ($categorySeverities.ContainsKey($Category)) {
        return $categorySeverities[$Category]
    }

    # Si tout échoue, retourner la sévérité par défaut
    return $DefaultSeverity
}
