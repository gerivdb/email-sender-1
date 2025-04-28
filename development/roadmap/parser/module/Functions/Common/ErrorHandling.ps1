<#
.SYNOPSIS
    Fonctions de gestion des erreurs pour le module RoadmapParser.

.DESCRIPTION
    Ce fichier contient des fonctions pour gÃ©rer les erreurs de maniÃ¨re standardisÃ©e
    dans le module RoadmapParser, incluant la capture, l'enrichissement, la catÃ©gorisation
    et la journalisation des erreurs.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-04-26
#>

# Importer les fonctions de journalisation si elles ne sont pas dÃ©jÃ  chargÃ©es
if (-not (Get-Command -Name "Write-LogError" -ErrorAction SilentlyContinue)) {
    $loggingPath = Join-Path -Path $PSScriptRoot -ChildPath "Logging.ps1"
    if (Test-Path -Path $loggingPath) {
        . $loggingPath
    }
}

<#
.SYNOPSIS
    GÃ¨re une erreur de maniÃ¨re standardisÃ©e.

.DESCRIPTION
    Cette fonction gÃ¨re une erreur en l'enrichissant avec des informations contextuelles,
    en la journalisant et en dÃ©cidant si le script doit s'arrÃªter ou continuer.

.PARAMETER ErrorRecord
    L'enregistrement d'erreur PowerShell Ã  traiter.

.PARAMETER ErrorMessage
    Un message d'erreur personnalisÃ© Ã  afficher.

.PARAMETER ExitOnError
    Indique si le script doit s'arrÃªter aprÃ¨s avoir traitÃ© l'erreur.

.PARAMETER ExitCode
    Le code de sortie Ã  utiliser si ExitOnError est $true.

.PARAMETER LogFile
    Le chemin du fichier de journal oÃ¹ enregistrer l'erreur.

.PARAMETER Category
    La catÃ©gorie d'erreur pour la classification.

.PARAMETER Severity
    La sÃ©vÃ©ritÃ© de l'erreur (1-5, oÃ¹ 5 est la plus grave).

.PARAMETER Context
    Informations contextuelles supplÃ©mentaires sur l'erreur.

.EXAMPLE
    try {
        # Code qui peut gÃ©nÃ©rer une erreur
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

    # Ajouter les informations de catÃ©gorie et de sÃ©vÃ©ritÃ©
    $enrichedMessage += "CatÃ©gorie: $Category`n"
    $enrichedMessage += "SÃ©vÃ©ritÃ©: $Severity`n"

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

    # Sortir si demandÃ©
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
    Tente d'exÃ©cuter une commande avec des mÃ©canismes de retry.

.DESCRIPTION
    Cette fonction exÃ©cute une commande et rÃ©essaie en cas d'Ã©chec selon la politique spÃ©cifiÃ©e.

.PARAMETER ScriptBlock
    Le bloc de script Ã  exÃ©cuter.

.PARAMETER MaxRetries
    Le nombre maximum de tentatives.

.PARAMETER RetryDelaySeconds
    Le dÃ©lai en secondes entre les tentatives.

.PARAMETER RetryStrategy
    La stratÃ©gie de retry Ã  utiliser (Fixed, Exponential, ExponentialWithJitter).

.PARAMETER ExceptionTypes
    Les types d'exceptions pour lesquels rÃ©essayer.

.PARAMETER OnRetry
    Un script Ã  exÃ©cuter avant chaque nouvelle tentative.

.PARAMETER OnSuccess
    Un script Ã  exÃ©cuter en cas de succÃ¨s.

.PARAMETER OnFailure
    Un script Ã  exÃ©cuter en cas d'Ã©chec final.

.EXAMPLE
    $result = Invoke-WithRetry -ScriptBlock { Invoke-RestMethod -Uri "https://api.example.com" } -MaxRetries 3 -RetryDelaySeconds 2 -RetryStrategy "ExponentialWithJitter"

.NOTES
    Cette fonction est utile pour les opÃ©rations qui peuvent Ã©chouer temporairement, comme les appels rÃ©seau.
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

            # ExÃ©cuter le script de succÃ¨s si fourni
            if ($OnSuccess -ne $null) {
                & $OnSuccess -Result $result
            }

            break
        }
        catch {
            $lastException = $_
            $shouldRetry = $false

            # VÃ©rifier si l'exception est d'un type pour lequel on doit rÃ©essayer
            foreach ($exceptionType in $ExceptionTypes) {
                if ($_.Exception -is $exceptionType) {
                    $shouldRetry = $true
                    break
                }
            }

            if (-not $shouldRetry -or $retryCount -ge $MaxRetries) {
                # ExÃ©cuter le script d'Ã©chec si fourni
                if ($OnFailure -ne $null) {
                    & $OnFailure -Exception $lastException -RetryCount $retryCount
                }
                throw
            }

            $retryCount++

            # Calculer le dÃ©lai selon la stratÃ©gie
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
                Write-LogWarning -Message "Tentative $retryCount/$MaxRetries a Ã©chouÃ©. Nouvelle tentative dans $delay secondes. Erreur: $($lastException.Exception.Message)"
            } else {
                Write-Warning "Tentative $retryCount/$MaxRetries a Ã©chouÃ©. Nouvelle tentative dans $delay secondes. Erreur: $($lastException.Exception.Message)"
            }

            # ExÃ©cuter le script de retry si fourni
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
    Cette fonction capture les dÃ©tails d'une exception et les enrichit avec des informations contextuelles.

.PARAMETER Exception
    L'exception Ã  analyser.

.PARAMETER Context
    Informations contextuelles supplÃ©mentaires.

.PARAMETER IncludeStackTrace
    Indique si la pile d'appels doit Ãªtre incluse.

.PARAMETER IncludeInnerExceptions
    Indique si les exceptions internes doivent Ãªtre incluses.

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

    # Ajouter les donnÃ©es de l'exception
    foreach ($key in $Exception.Data.Keys) {
        $exceptionInfo.Data[$key] = $Exception.Data[$key]
    }

    # Ajouter la pile d'appels si demandÃ©
    if ($IncludeStackTrace -and $Exception.StackTrace) {
        $exceptionInfo.StackTrace = $Exception.StackTrace
    }

    # Ajouter les exceptions internes si demandÃ©
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
    CatÃ©gorise une exception en fonction de son type et de son message.

.DESCRIPTION
    Cette fonction analyse une exception et dÃ©termine sa catÃ©gorie en fonction de rÃ¨gles prÃ©dÃ©finies.

.PARAMETER Exception
    L'exception Ã  catÃ©goriser.

.PARAMETER DefaultCategory
    La catÃ©gorie par dÃ©faut si aucune correspondance n'est trouvÃ©e.

.EXAMPLE
    $category = Get-ExceptionCategory -Exception $_.Exception

.NOTES
    Cette fonction aide Ã  standardiser la catÃ©gorisation des erreurs pour une meilleure analyse.
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

    # DÃ©finir les rÃ¨gles de catÃ©gorisation
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

    # VÃ©rifier si l'exception correspond Ã  une catÃ©gorie
    foreach ($category in $categoryRules.Keys) {
        foreach ($exceptionType in $categoryRules[$category]) {
            if ($Exception -is $exceptionType) {
                return $category
            }
        }
    }

    # VÃ©rifier le message pour des indices supplÃ©mentaires
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

    # Retourner la catÃ©gorie par dÃ©faut si aucune correspondance n'est trouvÃ©e
    return $DefaultCategory
}

<#
.SYNOPSIS
    DÃ©termine la sÃ©vÃ©ritÃ© d'une exception en fonction de son type et de son impact.

.DESCRIPTION
    Cette fonction analyse une exception et dÃ©termine sa sÃ©vÃ©ritÃ© sur une Ã©chelle de 1 Ã  5.

.PARAMETER Exception
    L'exception Ã  Ã©valuer.

.PARAMETER Category
    La catÃ©gorie de l'exception.

.PARAMETER DefaultSeverity
    La sÃ©vÃ©ritÃ© par dÃ©faut si aucune correspondance n'est trouvÃ©e.

.EXAMPLE
    $severity = Get-ExceptionSeverity -Exception $_.Exception -Category "Permission"

.NOTES
    Cette fonction aide Ã  prioriser les erreurs en fonction de leur impact.
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

    # DÃ©finir les rÃ¨gles de sÃ©vÃ©ritÃ© par catÃ©gorie
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

    # VÃ©rifier si l'exception correspond Ã  une sÃ©vÃ©ritÃ©
    if ($severityRules.ContainsKey($Category)) {
        foreach ($exceptionType in $severityRules[$Category].High) {
            if ($Exception -is $exceptionType) {
                return 5  # SÃ©vÃ©ritÃ© Ã©levÃ©e
            }
        }

        foreach ($exceptionType in $severityRules[$Category].Medium) {
            if ($Exception -is $exceptionType) {
                return 3  # SÃ©vÃ©ritÃ© moyenne
            }
        }

        foreach ($exceptionType in $severityRules[$Category].Low) {
            if ($Exception -is $exceptionType) {
                return 1  # SÃ©vÃ©ritÃ© faible
            }
        }
    }

    # VÃ©rifier le message pour des indices supplÃ©mentaires
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
            return 4  # Ã‰levÃ©e
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

    # Retourner la sÃ©vÃ©ritÃ© par dÃ©faut si aucune correspondance n'est trouvÃ©e
    return $DefaultSeverity
}

# Note: Les fonctions sont exportÃ©es lors de l'importation du module
# Handle-Error, Invoke-WithRetry, Get-ExceptionInfo, Get-ExceptionCategory, Get-ExceptionSeverity
