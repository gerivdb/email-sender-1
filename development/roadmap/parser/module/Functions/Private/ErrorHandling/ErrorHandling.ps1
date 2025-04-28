<#
.SYNOPSIS
    GÃ¨re les erreurs et les exceptions dans le module RoadmapParser.

.DESCRIPTION
    Ce fichier contient des fonctions pour gÃ©rer les erreurs et les exceptions dans le module RoadmapParser.
    Il inclut des fonctions pour journaliser les erreurs, les catÃ©goriser, dÃ©terminer leur sÃ©vÃ©ritÃ©,
    et implÃ©menter des stratÃ©gies de nouvelle tentative.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-15
#>

<#
.SYNOPSIS
    GÃ¨re une erreur en la journalisant et en effectuant des actions appropriÃ©es.

.DESCRIPTION
    Cette fonction prend un enregistrement d'erreur, le journalise et effectue des actions
    en fonction des paramÃ¨tres spÃ©cifiÃ©s.

.PARAMETER ErrorRecord
    L'enregistrement d'erreur Ã  gÃ©rer.

.PARAMETER ErrorMessage
    Un message d'erreur personnalisÃ© Ã  journaliser.

.PARAMETER Context
    Informations contextuelles supplÃ©mentaires sur l'erreur.

.PARAMETER LogFile
    Le chemin du fichier de journal oÃ¹ enregistrer l'erreur.

.PARAMETER Category
    La catÃ©gorie de l'erreur (par exemple, "IO", "Parsing", etc.).

.PARAMETER Severity
    La sÃ©vÃ©ritÃ© de l'erreur (1-5, oÃ¹ 5 est la plus sÃ©vÃ¨re).

.PARAMETER ExitCode
    Le code de sortie Ã  utiliser si ExitOnError est vrai.

.PARAMETER ExitOnError
    Indique si le script doit se terminer aprÃ¨s avoir gÃ©rÃ© l'erreur.

.PARAMETER ThrowException
    Indique si l'exception doit Ãªtre relancÃ©e aprÃ¨s avoir Ã©tÃ© journalisÃ©e.

.EXAMPLE
    try {
        # Code qui peut gÃ©nÃ©rer une erreur
    } catch {
        Handle-Error -ErrorRecord $_ -ErrorMessage "Erreur lors du traitement du fichier" -Context "Traitement de donnÃ©es" -LogFile ".\logs\app.log"
    }

.NOTES
    Cette fonction est conÃ§ue pour standardiser la gestion des erreurs dans le module.
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

    # DÃ©terminer la catÃ©gorie de l'erreur si non spÃ©cifiÃ©e
    if ($Category -eq "General") {
        $Category = Get-ExceptionCategory -Exception $ErrorRecord.Exception
    }

    # DÃ©terminer la sÃ©vÃ©ritÃ© de l'erreur si non spÃ©cifiÃ©e
    if ($Severity -eq 3) {
        $Severity = Get-ExceptionSeverity -Exception $ErrorRecord.Exception -Category $Category
    }

    # Construire le message d'erreur complet
    $fullErrorMessage = @"
$ErrorMessage
Type: $($exceptionInfo.Type)
Message: $($exceptionInfo.Message)
CatÃ©gorie: $Category
SÃ©vÃ©ritÃ©: $Severity
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

    # Journaliser dans un fichier si spÃ©cifiÃ©
    if ($LogFile) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] ERROR: $fullErrorMessage`n"
        Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
    }

    # GÃ©rer l'erreur selon les paramÃ¨tres
    if ($ThrowException) {
        throw $ErrorRecord
    }

    if ($ExitOnError) {
        exit $ExitCode
    }
}

<#
.SYNOPSIS
    ExÃ©cute une action avec des tentatives en cas d'Ã©chec.

.DESCRIPTION
    Cette fonction exÃ©cute un bloc de script et rÃ©essaie en cas d'Ã©chec,
    selon une stratÃ©gie de nouvelle tentative spÃ©cifiÃ©e.

.PARAMETER ScriptBlock
    Le bloc de script Ã  exÃ©cuter.

.PARAMETER MaxRetries
    Le nombre maximum de nouvelles tentatives.

.PARAMETER RetryDelaySeconds
    Le dÃ©lai en secondes entre les tentatives.

.PARAMETER RetryStrategy
    La stratÃ©gie de nouvelle tentative Ã  utiliser (Fixed, Exponential, ExponentialWithJitter).

.PARAMETER ExceptionTypes
    Les types d'exceptions pour lesquels rÃ©essayer.

.PARAMETER OnRetry
    Un bloc de script Ã  exÃ©cuter avant chaque nouvelle tentative.

.PARAMETER OnSuccess
    Un bloc de script Ã  exÃ©cuter en cas de succÃ¨s.

.PARAMETER OnFailure
    Un bloc de script Ã  exÃ©cuter en cas d'Ã©chec final.

.EXAMPLE
    $result = Invoke-WithRetry -ScriptBlock { Invoke-RestMethod -Uri $url } -MaxRetries 5 -RetryStrategy "ExponentialWithJitter"

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

            # Calculer le dÃ©lai selon la stratÃ©gie choisie
            $delay = switch ($RetryStrategy) {
                "Fixed" { $RetryDelaySeconds }
                "Exponential" { [math]::Pow(2, $retryCount - 1) * $RetryDelaySeconds }
                "ExponentialWithJitter" {
                    $baseDelay = [math]::Pow(2, $retryCount - 1) * $RetryDelaySeconds
                    $jitter = Get-Random -Minimum 0 -Maximum $baseDelay
                    $baseDelay + $jitter
                }
            }

            # ExÃ©cuter le script de nouvelle tentative si fourni
            if ($OnRetry -ne $null) {
                & $OnRetry -Exception $lastException -RetryCount $retryCount -Delay $delay
            }

            Write-LogWarning -Message "Tentative $retryCount/$MaxRetries a Ã©chouÃ©. Nouvelle tentative dans $delay secondes..."
            Start-Sleep -Seconds $delay
        }
    } while ($retryCount -le $MaxRetries)

    return $result
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
    if ($IncludeStackTrace) {
        $exceptionInfo.StackTrace = if ($Exception.StackTrace) { $Exception.StackTrace } else { "No stack trace available" }
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
    Cette fonction analyse une exception et la classe dans une catÃ©gorie prÃ©dÃ©finie.

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

    # DÃ©finir les mappages de types d'exceptions vers des catÃ©gories
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

    # DÃ©finir les mappages de mots-clÃ©s dans les messages d'erreur vers des catÃ©gories
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

    # VÃ©rifier d'abord le type d'exception
    foreach ($type in $typeMappings.Keys) {
        if ($Exception -is $type) {
            return $typeMappings[$type]
        }
    }

    # Ensuite, vÃ©rifier le message d'erreur
    $message = $Exception.Message.ToLower()
    foreach ($keyword in $messageMappings.Keys) {
        if ($message -match $keyword) {
            return $messageMappings[$keyword]
        }
    }

    # Si aucune correspondance n'est trouvÃ©e, retourner la catÃ©gorie par dÃ©faut
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

    # DÃ©finir les sÃ©vÃ©ritÃ©s par catÃ©gorie (1 = faible, 5 = critique)
    $categorySeverities = @{
        "Syntax" = 2        # Erreurs de syntaxe, gÃ©nÃ©ralement faciles Ã  corriger
        "Runtime" = 3       # Erreurs d'exÃ©cution, peuvent indiquer des bugs
        "Configuration" = 3 # Erreurs de configuration, gÃ©nÃ©ralement corrigeables
        "Permission" = 5    # Erreurs de permission, peuvent bloquer des fonctionnalitÃ©s
        "Resource" = 4      # Erreurs de ressources, peuvent indiquer des problÃ¨mes systÃ¨me
        "Data" = 4          # Erreurs de donnÃ©es, peuvent indiquer une corruption
        "External" = 3      # Erreurs externes, dÃ©pendent de services tiers
        "Unknown" = 3       # Erreurs inconnues, sÃ©vÃ©ritÃ© moyenne par dÃ©faut
    }

    # DÃ©finir les sÃ©vÃ©ritÃ©s par type d'exception
    $typeSeverities = @{
        "System.OutOfMemoryException" = 5
        "System.StackOverflowException" = 5
        "System.Threading.ThreadAbortException" = 5
        "System.AccessViolationException" = 5
        "System.IO.FileNotFoundException" = 3
        "System.ArgumentException" = 2
        "System.FormatException" = 2
    }

    # DÃ©finir les sÃ©vÃ©ritÃ©s par mots-clÃ©s dans les messages
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

    # VÃ©rifier d'abord le type d'exception
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

    # Ensuite, vÃ©rifier le message d'erreur
    $message = $Exception.Message.ToLower()
    foreach ($keyword in $messageSeverities.Keys) {
        if ($message -match $keyword) {
            return $messageSeverities[$keyword]
        }
    }

    # Si aucune correspondance par type ou message, utiliser la catÃ©gorie
    if ($categorySeverities.ContainsKey($Category)) {
        return $categorySeverities[$Category]
    }

    # Si tout Ã©choue, retourner la sÃ©vÃ©ritÃ© par dÃ©faut
    return $DefaultSeverity
}
