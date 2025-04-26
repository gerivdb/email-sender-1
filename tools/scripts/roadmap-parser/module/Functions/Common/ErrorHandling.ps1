<#
.SYNOPSIS
    Fonctions de gestion des erreurs pour le module RoadmapParser.

.DESCRIPTION
    Ce fichier contient des fonctions pour gérer les erreurs de manière standardisée
    dans le module RoadmapParser, incluant la capture, l'enrichissement, la catégorisation
    et la journalisation des erreurs.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-04-26
#>

# Importer les fonctions de journalisation si elles ne sont pas déjà chargées
if (-not (Get-Command -Name "Write-LogError" -ErrorAction SilentlyContinue)) {
    $loggingPath = Join-Path -Path $PSScriptRoot -ChildPath "Logging.ps1"
    if (Test-Path -Path $loggingPath) {
        . $loggingPath
    }
}

<#
.SYNOPSIS
    Gère une erreur de manière standardisée.

.DESCRIPTION
    Cette fonction gère une erreur en l'enrichissant avec des informations contextuelles,
    en la journalisant et en décidant si le script doit s'arrêter ou continuer.

.PARAMETER ErrorRecord
    L'enregistrement d'erreur PowerShell à traiter.

.PARAMETER ErrorMessage
    Un message d'erreur personnalisé à afficher.

.PARAMETER ExitOnError
    Indique si le script doit s'arrêter après avoir traité l'erreur.

.PARAMETER ExitCode
    Le code de sortie à utiliser si ExitOnError est $true.

.PARAMETER LogFile
    Le chemin du fichier de journal où enregistrer l'erreur.

.PARAMETER Category
    La catégorie d'erreur pour la classification.

.PARAMETER Severity
    La sévérité de l'erreur (1-5, où 5 est la plus grave).

.PARAMETER Context
    Informations contextuelles supplémentaires sur l'erreur.

.EXAMPLE
    try {
        # Code qui peut générer une erreur
    } catch {
        Handle-Error -ErrorRecord $_ -ErrorMessage "Une erreur s'est produite lors du traitement" -ExitOnError $true
    }

.NOTES
    Cette fonction utilise Write-LogError si disponible, sinon elle utilise Write-Error.
#>
function Handle-Error {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = "Une erreur s'est produite",

        [Parameter(Mandatory = $false)]
        [bool]$ExitOnError = $false,

        [Parameter(Mandatory = $false)]
        [int]$ExitCode = 1,

        [Parameter(Mandatory = $false)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Syntax", "Runtime", "Configuration", "Permission", "Resource", "Data", "External", "Unknown")]
        [string]$Category = "Unknown",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [int]$Severity = 3,

        [Parameter(Mandatory = $false)]
        [hashtable]$Context = @{}
    )

    # Enrichir le message d'erreur avec des informations contextuelles
    $enrichedMessage = "$ErrorMessage`n"
    $enrichedMessage += "Exception: $($ErrorRecord.Exception.GetType().FullName)`n"
    $enrichedMessage += "Message: $($ErrorRecord.Exception.Message)`n"

    # Ajouter la pile d'appels si disponible
    if ($ErrorRecord.ScriptStackTrace) {
        $enrichedMessage += "Stack Trace:`n$($ErrorRecord.ScriptStackTrace)`n"
    }

    # Ajouter les informations de catégorie et de sévérité
    $enrichedMessage += "Catégorie: $Category`n"
    $enrichedMessage += "Sévérité: $Severity`n"

    # Ajouter les informations contextuelles
    if ($Context.Count -gt 0) {
        $enrichedMessage += "Contexte:`n"
        foreach ($key in $Context.Keys) {
            $enrichedMessage += "  ${key}: $($Context[$key])`n"
        }
    }

    # Journaliser l'erreur
    if (Get-Command -Name "Write-LogError" -ErrorAction SilentlyContinue) {
        if ($LogFile) {
            Write-LogError -Message $enrichedMessage -LogFile $LogFile
        } else {
            Write-LogError -Message $enrichedMessage
        }
    } else {
        Write-Error $enrichedMessage
    }

    # Sortir si demandé
    if ($ExitOnError) {
        if ($Host.Name -eq 'ConsoleHost') {
            exit $ExitCode
        } else {
            throw $ErrorRecord
        }
    }
}

<#
.SYNOPSIS
    Tente d'exécuter une commande avec des mécanismes de retry.

.DESCRIPTION
    Cette fonction exécute une commande et réessaie en cas d'échec selon la politique spécifiée.

.PARAMETER ScriptBlock
    Le bloc de script à exécuter.

.PARAMETER MaxRetries
    Le nombre maximum de tentatives.

.PARAMETER RetryDelaySeconds
    Le délai en secondes entre les tentatives.

.PARAMETER RetryStrategy
    La stratégie de retry à utiliser (Fixed, Exponential, ExponentialWithJitter).

.PARAMETER ExceptionTypes
    Les types d'exceptions pour lesquels réessayer.

.PARAMETER OnRetry
    Un script à exécuter avant chaque nouvelle tentative.

.PARAMETER OnSuccess
    Un script à exécuter en cas de succès.

.PARAMETER OnFailure
    Un script à exécuter en cas d'échec final.

.EXAMPLE
    $result = Invoke-WithRetry -ScriptBlock { Invoke-RestMethod -Uri "https://api.example.com" } -MaxRetries 3 -RetryDelaySeconds 2 -RetryStrategy "ExponentialWithJitter"

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

            # Calculer le délai selon la stratégie
            $delay = switch ($RetryStrategy) {
                "Fixed" { $RetryDelaySeconds }
                "Exponential" { [math]::Pow(2, $retryCount - 1) * $RetryDelaySeconds }
                "ExponentialWithJitter" {
                    $baseDelay = [math]::Pow(2, $retryCount - 1) * $RetryDelaySeconds
                    $jitter = Get-Random -Minimum 0 -Maximum ($baseDelay / 2)
                    $baseDelay + $jitter
                }
            }

            # Journaliser la tentative
            if (Get-Command -Name "Write-LogWarning" -ErrorAction SilentlyContinue) {
                Write-LogWarning -Message "Tentative $retryCount/$MaxRetries a échoué. Nouvelle tentative dans $delay secondes. Erreur: $($lastException.Exception.Message)"
            } else {
                Write-Warning "Tentative $retryCount/$MaxRetries a échoué. Nouvelle tentative dans $delay secondes. Erreur: $($lastException.Exception.Message)"
            }

            # Exécuter le script de retry si fourni
            if ($OnRetry -ne $null) {
                & $OnRetry -Exception $lastException -RetryCount $retryCount -Delay $delay
            }

            # Attendre avant la prochaine tentative
            Start-Sleep -Seconds $delay
        }
    } while ($retryCount -le $MaxRetries)

    if ($success) {
        return $result
    } else {
        throw $lastException
    }
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
    if ($IncludeStackTrace -and $Exception.StackTrace) {
        $exceptionInfo.StackTrace = $Exception.StackTrace
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
    Cette fonction analyse une exception et détermine sa catégorie en fonction de règles prédéfinies.

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

    # Définir les règles de catégorisation
    $categoryRules = @{
        Syntax = @(
            [System.Management.Automation.ParseException],
            [System.Management.Automation.IncompleteParseException],
            [System.FormatException]
        )
        Runtime = @(
            [System.InvalidOperationException],
            [System.NotImplementedException],
            [System.NotSupportedException],
            [System.ArgumentException],
            [System.ArgumentNullException],
            [System.ArgumentOutOfRangeException],
            [System.IndexOutOfRangeException]
        )
        Configuration = @(
            # Suppression des types non disponibles
        )
        Permission = @(
            [System.UnauthorizedAccessException],
            [System.Security.SecurityException]
        )
        Resource = @(
            [System.IO.IOException],
            [System.IO.FileNotFoundException],
            [System.IO.DirectoryNotFoundException],
            [System.IO.PathTooLongException],
            [System.IO.DriveNotFoundException]
        )
        Data = @(
            [System.Xml.XmlException],
            [System.Text.RegularExpressions.RegexMatchTimeoutException]
        )
        External = @(
            [System.Net.WebException],
            [System.Net.Sockets.SocketException]
        )
    }

    # Vérifier si l'exception correspond à une catégorie
    foreach ($category in $categoryRules.Keys) {
        foreach ($exceptionType in $categoryRules[$category]) {
            if ($Exception -is $exceptionType) {
                return $category
            }
        }
    }

    # Vérifier le message pour des indices supplémentaires
    $messagePatterns = @{
        Permission = @("access denied", "permission denied", "not authorized", "unauthorized")
        Configuration = @("configuration", "setting", "registry")
        Resource = @("file not found", "directory not found", "path not found", "resource not available")
        Data = @("data", "database", "query", "sql", "xml", "json")
        External = @("network", "connection", "timeout", "server", "remote", "url", "uri")
    }

    foreach ($category in $messagePatterns.Keys) {
        foreach ($pattern in $messagePatterns[$category]) {
            if ($Exception.Message -match $pattern) {
                return $category
            }
        }
    }

    # Retourner la catégorie par défaut si aucune correspondance n'est trouvée
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

    # Définir les règles de sévérité par catégorie
    $severityRules = @{
        Syntax = @{
            High = @([System.Management.Automation.ParseException])
            Medium = @([System.FormatException])
            Low = @()
        }
        Runtime = @{
            High = @([System.InvalidOperationException], [System.NotImplementedException])
            Medium = @([System.ArgumentException], [System.ArgumentNullException])
            Low = @([System.ArgumentOutOfRangeException], [System.IndexOutOfRangeException])
        }
        Configuration = @{
            High = @()
            Medium = @()
            Low = @()
        }
        Permission = @{
            High = @([System.Security.SecurityException])
            Medium = @([System.UnauthorizedAccessException])
            Low = @()
        }
        Resource = @{
            High = @([System.IO.DriveNotFoundException])
            Medium = @([System.IO.FileNotFoundException], [System.IO.DirectoryNotFoundException])
            Low = @([System.IO.PathTooLongException])
        }
        Data = @{
            High = @()
            Medium = @([System.Xml.XmlException])
            Low = @([System.Text.RegularExpressions.RegexMatchTimeoutException])
        }
        External = @{
            High = @()
            Medium = @([System.Net.WebException])
            Low = @([System.Net.Sockets.SocketException])
        }
    }

    # Vérifier si l'exception correspond à une sévérité
    if ($severityRules.ContainsKey($Category)) {
        foreach ($exceptionType in $severityRules[$Category].High) {
            if ($Exception -is $exceptionType) {
                return 5  # Sévérité élevée
            }
        }

        foreach ($exceptionType in $severityRules[$Category].Medium) {
            if ($Exception -is $exceptionType) {
                return 3  # Sévérité moyenne
            }
        }

        foreach ($exceptionType in $severityRules[$Category].Low) {
            if ($Exception -is $exceptionType) {
                return 1  # Sévérité faible
            }
        }
    }

    # Vérifier le message pour des indices supplémentaires
    $criticalPatterns = @("critical", "fatal", "crash", "corrupted", "security breach", "data loss")
    $highPatterns = @("error", "exception", "failed", "failure", "unable to")
    $mediumPatterns = @("warning", "problem", "issue", "incorrect")
    $lowPatterns = @("notice", "information", "hint", "suggestion")

    foreach ($pattern in $criticalPatterns) {
        if ($Exception.Message -match $pattern) {
            return 5  # Critique
        }
    }

    foreach ($pattern in $highPatterns) {
        if ($Exception.Message -match $pattern) {
            return 4  # Élevée
        }
    }

    foreach ($pattern in $mediumPatterns) {
        if ($Exception.Message -match $pattern) {
            return 3  # Moyenne
        }
    }

    foreach ($pattern in $lowPatterns) {
        if ($Exception.Message -match $pattern) {
            return 2  # Faible
        }
    }

    # Retourner la sévérité par défaut si aucune correspondance n'est trouvée
    return $DefaultSeverity
}

# Note: Les fonctions sont exportées lors de l'importation du module
# Handle-Error, Invoke-WithRetry, Get-ExceptionInfo, Get-ExceptionCategory, Get-ExceptionSeverity
