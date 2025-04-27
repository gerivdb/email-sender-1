<#
.SYNOPSIS
    Fournit des mÃ©canismes de reprise aprÃ¨s erreur (retry logic) pour les opÃ©rations sujettes aux Ã©checs temporaires.

.DESCRIPTION
    Ce script implÃ©mente diffÃ©rentes stratÃ©gies de reprise aprÃ¨s erreur pour les opÃ©rations
    qui peuvent Ã©chouer temporairement en raison de problÃ¨mes de rÃ©seau, de verrouillage de ressources,
    ou d'autres conditions transitoires. Il prend en charge plusieurs stratÃ©gies de temporisation
    (fixe, exponentielle, alÃ©atoire) et permet de spÃ©cifier des conditions personnalisÃ©es pour les reprises.

.EXAMPLE
    . .\RetryLogic.ps1
    $result = Invoke-WithRetry -ScriptBlock { Invoke-RestMethod -Uri "https://api.example.com/data" } -MaxRetries 5 -DelaySeconds 2 -BackoffMultiplier 2

.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 07/04/2025
    Version: 1.0
#>

# DÃ©finir les stratÃ©gies de temporisation
enum RetryBackoffStrategy {
    Fixed = 0       # DÃ©lai fixe entre les tentatives
    Linear = 1      # DÃ©lai augmentant linÃ©airement (dÃ©lai * numÃ©ro de tentative)
    Exponential = 2 # DÃ©lai augmentant exponentiellement (dÃ©lai * (multiplicateur ^ numÃ©ro de tentative))
    Random = 3      # DÃ©lai alÃ©atoire entre min et max
}

# Fonction principale pour exÃ©cuter une opÃ©ration avec reprise
function Invoke-WithRetry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3,
        
        [Parameter(Mandatory = $false)]
        [double]$DelaySeconds = 1.0,
        
        [Parameter(Mandatory = $false)]
        [RetryBackoffStrategy]$BackoffStrategy = [RetryBackoffStrategy]::Exponential,
        
        [Parameter(Mandatory = $false)]
        [double]$BackoffMultiplier = 2.0,
        
        [Parameter(Mandatory = $false)]
        [double]$MinRandomDelaySeconds = 0.5,
        
        [Parameter(Mandatory = $false)]
        [double]$MaxRandomDelaySeconds = 5.0,
        
        [Parameter(Mandatory = $false)]
        [double]$MaxTotalDelaySeconds = 60.0,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$RetryCondition = { $true },
        
        [Parameter(Mandatory = $false)]
        [string[]]$RetryOnExceptionTypes = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$RetryOnExceptionMessages = @(),
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$OnRetry = { param($exception, $retryCount, $delaySeconds) Write-Verbose "Retry $retryCount after $delaySeconds seconds due to: $($exception.Exception.Message)" },
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure = $true
    )
    
    $attempt = 0
    $totalDelay = 0
    $lastException = $null
    
    do {
        $attempt++
        
        try {
            # ExÃ©cuter le bloc de script
            $result = & $ScriptBlock
            
            # Si nous arrivons ici, l'opÃ©ration a rÃ©ussi
            return $result
        }
        catch {
            $lastException = $_
            $shouldRetry = $false
            
            # VÃ©rifier si nous devons rÃ©essayer en fonction du type d'exception
            if ($RetryOnExceptionTypes.Count -gt 0) {
                $exceptionType = $_.Exception.GetType().FullName
                $shouldRetry = $RetryOnExceptionTypes | Where-Object { $exceptionType -match $_ } | Select-Object -First 1
            }
            
            # VÃ©rifier si nous devons rÃ©essayer en fonction du message d'exception
            if (-not $shouldRetry -and $RetryOnExceptionMessages.Count -gt 0) {
                $exceptionMessage = $_.Exception.Message
                $shouldRetry = $RetryOnExceptionMessages | Where-Object { $exceptionMessage -match $_ } | Select-Object -First 1
            }
            
            # VÃ©rifier la condition de reprise personnalisÃ©e
            if (-not $shouldRetry -and $RetryOnExceptionTypes.Count -eq 0 -and $RetryOnExceptionMessages.Count -eq 0) {
                $shouldRetry = & $RetryCondition -Exception $_
            }
            
            # Si nous ne devons pas rÃ©essayer ou si nous avons atteint le nombre maximal de tentatives, lever l'exception
            if (-not $shouldRetry -or $attempt -ge $MaxRetries) {
                if ($ThrowOnFailure) {
                    throw
                }
                else {
                    return $null
                }
            }
            
            # Calculer le dÃ©lai avant la prochaine tentative
            $delay = switch ($BackoffStrategy) {
                ([RetryBackoffStrategy]::Fixed) {
                    $DelaySeconds
                }
                ([RetryBackoffStrategy]::Linear) {
                    $DelaySeconds * $attempt
                }
                ([RetryBackoffStrategy]::Exponential) {
                    $DelaySeconds * [Math]::Pow($BackoffMultiplier, $attempt - 1)
                }
                ([RetryBackoffStrategy]::Random) {
                    Get-Random -Minimum $MinRandomDelaySeconds -Maximum $MaxRandomDelaySeconds
                }
                default {
                    $DelaySeconds
                }
            }
            
            # Limiter le dÃ©lai au maximum spÃ©cifiÃ©
            $delay = [Math]::Min($delay, $MaxTotalDelaySeconds - $totalDelay)
            
            # Si le dÃ©lai est nÃ©gatif ou nul, ne pas attendre
            if ($delay -le 0) {
                if ($ThrowOnFailure) {
                    throw
                }
                else {
                    return $null
                }
            }
            
            # Mettre Ã  jour le dÃ©lai total
            $totalDelay += $delay
            
            # ExÃ©cuter le bloc OnRetry
            & $OnRetry -Exception $_ -RetryCount $attempt -DelaySeconds $delay
            
            # Attendre avant la prochaine tentative
            Start-Sleep -Seconds $delay
        }
    } while ($attempt -lt $MaxRetries)
    
    # Si nous arrivons ici, toutes les tentatives ont Ã©chouÃ©
    if ($ThrowOnFailure) {
        throw $lastException
    }
    else {
        return $null
    }
}

# Fonction pour exÃ©cuter une opÃ©ration avec reprise et journalisation
function Invoke-WithRetryAndLogging {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3,
        
        [Parameter(Mandatory = $false)]
        [double]$DelaySeconds = 1.0,
        
        [Parameter(Mandatory = $false)]
        [RetryBackoffStrategy]$BackoffStrategy = [RetryBackoffStrategy]::Exponential,
        
        [Parameter(Mandatory = $false)]
        [double]$BackoffMultiplier = 2.0,
        
        [Parameter(Mandatory = $false)]
        [string]$OperationName = "Operation",
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure = $true
    )
    
    # VÃ©rifier si le module de journalisation est disponible
    $loggerAvailable = $false
    $loggerPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "CentralizedLogger.ps1"
    
    if (Test-Path -Path $loggerPath -PathType Leaf) {
        try {
            . $loggerPath
            $loggerAvailable = $true
        }
        catch {
            Write-Warning "Impossible de charger le module de journalisation: $_"
        }
    }
    
    # DÃ©finir le bloc OnRetry avec journalisation
    $onRetryBlock = {
        param($exception, $retryCount, $delaySeconds)
        
        $message = "Tentative $retryCount/$MaxRetries pour '$OperationName' aprÃ¨s $delaySeconds secondes. Erreur: $($exception.Exception.Message)"
        
        if ($loggerAvailable) {
            Write-LogWarning -Message $message -Source "RetryLogic"
        }
        else {
            Write-Warning $message
        }
    }
    
    # ExÃ©cuter l'opÃ©ration avec reprise
    try {
        if ($loggerAvailable) {
            Write-LogInfo -Message "DÃ©marrage de l'opÃ©ration '$OperationName' avec $MaxRetries tentatives maximum" -Source "RetryLogic"
        }
        else {
            Write-Verbose "DÃ©marrage de l'opÃ©ration '$OperationName' avec $MaxRetries tentatives maximum"
        }
        
        $result = Invoke-WithRetry -ScriptBlock $ScriptBlock -MaxRetries $MaxRetries -DelaySeconds $DelaySeconds -BackoffStrategy $BackoffStrategy -BackoffMultiplier $BackoffMultiplier -OnRetry $onRetryBlock -ThrowOnFailure $ThrowOnFailure
        
        if ($loggerAvailable) {
            Write-LogInfo -Message "OpÃ©ration '$OperationName' rÃ©ussie" -Source "RetryLogic"
        }
        else {
            Write-Verbose "OpÃ©ration '$OperationName' rÃ©ussie"
        }
        
        return $result
    }
    catch {
        if ($loggerAvailable) {
            Write-LogError -Message "Ã‰chec de l'opÃ©ration '$OperationName' aprÃ¨s $MaxRetries tentatives" -Source "RetryLogic" -ErrorRecord $_
        }
        else {
            Write-Error "Ã‰chec de l'opÃ©ration '$OperationName' aprÃ¨s $MaxRetries tentatives: $_"
        }
        
        if ($ThrowOnFailure) {
            throw
        }
        else {
            return $null
        }
    }
}

# Fonction pour exÃ©cuter une opÃ©ration avec reprise sur des exceptions spÃ©cifiques
function Invoke-WithRetryOnException {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExceptionTypes = @(
            "System.Net.WebException",
            "System.IO.IOException",
            "System.TimeoutException"
        ),
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExceptionMessages = @(
            "timed out",
            "timeout",
            "connection failure",
            "network error",
            "temporarily unavailable",
            "service unavailable",
            "too many requests",
            "rate limit",
            "throttled",
            "connection reset",
            "connection refused",
            "connection closed",
            "socket error",
            "EOF",
            "broken pipe",
            "locked",
            "deadlock",
            "contention",
            "concurrency",
            "conflict"
        ),
        
        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 5,
        
        [Parameter(Mandatory = $false)]
        [double]$DelaySeconds = 1.0,
        
        [Parameter(Mandatory = $false)]
        [RetryBackoffStrategy]$BackoffStrategy = [RetryBackoffStrategy]::Exponential,
        
        [Parameter(Mandatory = $false)]
        [double]$BackoffMultiplier = 2.0,
        
        [Parameter(Mandatory = $false)]
        [string]$OperationName = "Operation",
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure = $true
    )
    
    # ExÃ©cuter l'opÃ©ration avec reprise sur les exceptions spÃ©cifiÃ©es
    return Invoke-WithRetryAndLogging -ScriptBlock $ScriptBlock -MaxRetries $MaxRetries -DelaySeconds $DelaySeconds -BackoffStrategy $BackoffStrategy -BackoffMultiplier $BackoffMultiplier -OperationName $OperationName -ThrowOnFailure $ThrowOnFailure
}

# Fonction pour exÃ©cuter une opÃ©ration avec reprise et circuit breaker
function Invoke-WithRetryAndCircuitBreaker {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3,
        
        [Parameter(Mandatory = $false)]
        [double]$DelaySeconds = 1.0,
        
        [Parameter(Mandatory = $false)]
        [RetryBackoffStrategy]$BackoffStrategy = [RetryBackoffStrategy]::Exponential,
        
        [Parameter(Mandatory = $false)]
        [double]$BackoffMultiplier = 2.0,
        
        [Parameter(Mandatory = $false)]
        [string]$OperationName = "Operation",
        
        [Parameter(Mandatory = $false)]
        [int]$CircuitBreakerThreshold = 5,
        
        [Parameter(Mandatory = $false)]
        [double]$CircuitBreakerResetSeconds = 60.0,
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure = $true
    )
    
    # Variables statiques pour le circuit breaker (partagÃ©es entre les appels)
    if (-not [PSCustomObject].Assembly.GetType("RetryLogic.CircuitBreaker")) {
        Add-Type -TypeDefinition @"
namespace RetryLogic {
    public static class CircuitBreaker {
        public static int FailureCount = 0;
        public static System.DateTime LastFailureTime = System.DateTime.MinValue;
        public static bool IsOpen = false;
    }
}
"@
    }
    
    # VÃ©rifier si le circuit breaker est ouvert
    if ([RetryLogic.CircuitBreaker]::IsOpen) {
        $timeSinceLastFailure = (Get-Date) - [RetryLogic.CircuitBreaker]::LastFailureTime
        
        if ($timeSinceLastFailure.TotalSeconds -ge $CircuitBreakerResetSeconds) {
            # RÃ©initialiser le circuit breaker aprÃ¨s le dÃ©lai de rÃ©initialisation
            [RetryLogic.CircuitBreaker]::IsOpen = $false
            [RetryLogic.CircuitBreaker]::FailureCount = 0
            Write-Verbose "Circuit breaker rÃ©initialisÃ© pour l'opÃ©ration '$OperationName'"
        }
        else {
            # Le circuit breaker est toujours ouvert
            $message = "Circuit breaker ouvert pour l'opÃ©ration '$OperationName'. RÃ©essayez dans $([Math]::Ceiling($CircuitBreakerResetSeconds - $timeSinceLastFailure.TotalSeconds)) secondes."
            Write-Warning $message
            
            if ($ThrowOnFailure) {
                throw [System.InvalidOperationException]::new($message)
            }
            else {
                return $null
            }
        }
    }
    
    # ExÃ©cuter l'opÃ©ration avec reprise
    try {
        $result = Invoke-WithRetryAndLogging -ScriptBlock $ScriptBlock -MaxRetries $MaxRetries -DelaySeconds $DelaySeconds -BackoffStrategy $BackoffStrategy -BackoffMultiplier $BackoffMultiplier -OperationName $OperationName -ThrowOnFailure $ThrowOnFailure
        
        # RÃ©initialiser le compteur d'Ã©checs en cas de succÃ¨s
        [RetryLogic.CircuitBreaker]::FailureCount = 0
        
        return $result
    }
    catch {
        # IncrÃ©menter le compteur d'Ã©checs
        [RetryLogic.CircuitBreaker]::FailureCount++
        [RetryLogic.CircuitBreaker]::LastFailureTime = Get-Date
        
        # VÃ©rifier si le seuil du circuit breaker est atteint
        if ([RetryLogic.CircuitBreaker]::FailureCount -ge $CircuitBreakerThreshold) {
            [RetryLogic.CircuitBreaker]::IsOpen = $true
            $message = "Circuit breaker ouvert pour l'opÃ©ration '$OperationName' aprÃ¨s $([RetryLogic.CircuitBreaker]::FailureCount) Ã©checs consÃ©cutifs."
            Write-Warning $message
        }
        
        if ($ThrowOnFailure) {
            throw
        }
        else {
            return $null
        }
    }
}

# Fonction pour exÃ©cuter une opÃ©ration avec reprise et timeout
function Invoke-WithRetryAndTimeout {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3,
        
        [Parameter(Mandatory = $false)]
        [double]$DelaySeconds = 1.0,
        
        [Parameter(Mandatory = $false)]
        [RetryBackoffStrategy]$BackoffStrategy = [RetryBackoffStrategy]::Exponential,
        
        [Parameter(Mandatory = $false)]
        [double]$BackoffMultiplier = 2.0,
        
        [Parameter(Mandatory = $false)]
        [string]$OperationName = "Operation",
        
        [Parameter(Mandatory = $false)]
        [double]$TimeoutSeconds = 30.0,
        
        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure = $true
    )
    
    # CrÃ©er un bloc de script qui exÃ©cute l'opÃ©ration avec timeout
    $scriptBlockWithTimeout = {
        $timeoutMilliseconds = $TimeoutSeconds * 1000
        
        # CrÃ©er un objet de synchronisation pour la communication entre les threads
        $sync = [System.Collections.Hashtable]::Synchronized(@{
            Result = $null
            Error = $null
            Completed = $false
        })
        
        # CrÃ©er un thread pour exÃ©cuter l'opÃ©ration
        $thread = [System.Threading.Thread]::new([System.Threading.ThreadStart]{
            try {
                $sync.Result = & $ScriptBlock
                $sync.Completed = $true
            }
            catch {
                $sync.Error = $_
                $sync.Completed = $true
            }
        })
        
        # DÃ©marrer le thread
        $thread.Start()
        
        # Attendre que le thread se termine ou que le timeout soit atteint
        $completed = $thread.Join($timeoutMilliseconds)
        
        if (-not $completed) {
            # Le timeout a Ã©tÃ© atteint, essayer d'arrÃªter le thread
            try {
                $thread.Abort()
            }
            catch {
                Write-Warning "Impossible d'arrÃªter le thread: $_"
            }
            
            throw [System.TimeoutException]::new("L'opÃ©ration '$OperationName' a dÃ©passÃ© le dÃ©lai d'attente de $TimeoutSeconds secondes.")
        }
        
        # VÃ©rifier si une erreur s'est produite
        if ($sync.Error -ne $null) {
            throw $sync.Error
        }
        
        # Retourner le rÃ©sultat
        return $sync.Result
    }
    
    # ExÃ©cuter l'opÃ©ration avec reprise et timeout
    return Invoke-WithRetryAndLogging -ScriptBlock $scriptBlockWithTimeout -MaxRetries $MaxRetries -DelaySeconds $DelaySeconds -BackoffStrategy $BackoffStrategy -BackoffMultiplier $BackoffMultiplier -OperationName $OperationName -ThrowOnFailure $ThrowOnFailure
}

# Exporter les fonctions
Export-ModuleMember -Function Invoke-WithRetry, Invoke-WithRetryAndLogging, Invoke-WithRetryOnException, Invoke-WithRetryAndCircuitBreaker, Invoke-WithRetryAndTimeout
