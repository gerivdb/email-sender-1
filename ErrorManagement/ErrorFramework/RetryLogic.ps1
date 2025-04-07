<#
.SYNOPSIS
    Fournit des mécanismes de reprise après erreur (retry logic) pour les opérations sujettes aux échecs temporaires.

.DESCRIPTION
    Ce script implémente différentes stratégies de reprise après erreur pour les opérations
    qui peuvent échouer temporairement en raison de problèmes de réseau, de verrouillage de ressources,
    ou d'autres conditions transitoires. Il prend en charge plusieurs stratégies de temporisation
    (fixe, exponentielle, aléatoire) et permet de spécifier des conditions personnalisées pour les reprises.

.EXAMPLE
    . .\RetryLogic.ps1
    $result = Invoke-WithRetry -ScriptBlock { Invoke-RestMethod -Uri "https://api.example.com/data" } -MaxRetries 5 -DelaySeconds 2 -BackoffMultiplier 2

.NOTES
    Auteur: Système d'analyse d'erreurs
    Date de création: 07/04/2025
    Version: 1.0
#>

# Définir les stratégies de temporisation
enum RetryBackoffStrategy {
    Fixed = 0       # Délai fixe entre les tentatives
    Linear = 1      # Délai augmentant linéairement (délai * numéro de tentative)
    Exponential = 2 # Délai augmentant exponentiellement (délai * (multiplicateur ^ numéro de tentative))
    Random = 3      # Délai aléatoire entre min et max
}

# Fonction principale pour exécuter une opération avec reprise
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
            # Exécuter le bloc de script
            $result = & $ScriptBlock
            
            # Si nous arrivons ici, l'opération a réussi
            return $result
        }
        catch {
            $lastException = $_
            $shouldRetry = $false
            
            # Vérifier si nous devons réessayer en fonction du type d'exception
            if ($RetryOnExceptionTypes.Count -gt 0) {
                $exceptionType = $_.Exception.GetType().FullName
                $shouldRetry = $RetryOnExceptionTypes | Where-Object { $exceptionType -match $_ } | Select-Object -First 1
            }
            
            # Vérifier si nous devons réessayer en fonction du message d'exception
            if (-not $shouldRetry -and $RetryOnExceptionMessages.Count -gt 0) {
                $exceptionMessage = $_.Exception.Message
                $shouldRetry = $RetryOnExceptionMessages | Where-Object { $exceptionMessage -match $_ } | Select-Object -First 1
            }
            
            # Vérifier la condition de reprise personnalisée
            if (-not $shouldRetry -and $RetryOnExceptionTypes.Count -eq 0 -and $RetryOnExceptionMessages.Count -eq 0) {
                $shouldRetry = & $RetryCondition -Exception $_
            }
            
            # Si nous ne devons pas réessayer ou si nous avons atteint le nombre maximal de tentatives, lever l'exception
            if (-not $shouldRetry -or $attempt -ge $MaxRetries) {
                if ($ThrowOnFailure) {
                    throw
                }
                else {
                    return $null
                }
            }
            
            # Calculer le délai avant la prochaine tentative
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
            
            # Limiter le délai au maximum spécifié
            $delay = [Math]::Min($delay, $MaxTotalDelaySeconds - $totalDelay)
            
            # Si le délai est négatif ou nul, ne pas attendre
            if ($delay -le 0) {
                if ($ThrowOnFailure) {
                    throw
                }
                else {
                    return $null
                }
            }
            
            # Mettre à jour le délai total
            $totalDelay += $delay
            
            # Exécuter le bloc OnRetry
            & $OnRetry -Exception $_ -RetryCount $attempt -DelaySeconds $delay
            
            # Attendre avant la prochaine tentative
            Start-Sleep -Seconds $delay
        }
    } while ($attempt -lt $MaxRetries)
    
    # Si nous arrivons ici, toutes les tentatives ont échoué
    if ($ThrowOnFailure) {
        throw $lastException
    }
    else {
        return $null
    }
}

# Fonction pour exécuter une opération avec reprise et journalisation
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
    
    # Vérifier si le module de journalisation est disponible
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
    
    # Définir le bloc OnRetry avec journalisation
    $onRetryBlock = {
        param($exception, $retryCount, $delaySeconds)
        
        $message = "Tentative $retryCount/$MaxRetries pour '$OperationName' après $delaySeconds secondes. Erreur: $($exception.Exception.Message)"
        
        if ($loggerAvailable) {
            Write-LogWarning -Message $message -Source "RetryLogic"
        }
        else {
            Write-Warning $message
        }
    }
    
    # Exécuter l'opération avec reprise
    try {
        if ($loggerAvailable) {
            Write-LogInfo -Message "Démarrage de l'opération '$OperationName' avec $MaxRetries tentatives maximum" -Source "RetryLogic"
        }
        else {
            Write-Verbose "Démarrage de l'opération '$OperationName' avec $MaxRetries tentatives maximum"
        }
        
        $result = Invoke-WithRetry -ScriptBlock $ScriptBlock -MaxRetries $MaxRetries -DelaySeconds $DelaySeconds -BackoffStrategy $BackoffStrategy -BackoffMultiplier $BackoffMultiplier -OnRetry $onRetryBlock -ThrowOnFailure $ThrowOnFailure
        
        if ($loggerAvailable) {
            Write-LogInfo -Message "Opération '$OperationName' réussie" -Source "RetryLogic"
        }
        else {
            Write-Verbose "Opération '$OperationName' réussie"
        }
        
        return $result
    }
    catch {
        if ($loggerAvailable) {
            Write-LogError -Message "Échec de l'opération '$OperationName' après $MaxRetries tentatives" -Source "RetryLogic" -ErrorRecord $_
        }
        else {
            Write-Error "Échec de l'opération '$OperationName' après $MaxRetries tentatives: $_"
        }
        
        if ($ThrowOnFailure) {
            throw
        }
        else {
            return $null
        }
    }
}

# Fonction pour exécuter une opération avec reprise sur des exceptions spécifiques
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
    
    # Exécuter l'opération avec reprise sur les exceptions spécifiées
    return Invoke-WithRetryAndLogging -ScriptBlock $ScriptBlock -MaxRetries $MaxRetries -DelaySeconds $DelaySeconds -BackoffStrategy $BackoffStrategy -BackoffMultiplier $BackoffMultiplier -OperationName $OperationName -ThrowOnFailure $ThrowOnFailure
}

# Fonction pour exécuter une opération avec reprise et circuit breaker
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
    
    # Variables statiques pour le circuit breaker (partagées entre les appels)
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
    
    # Vérifier si le circuit breaker est ouvert
    if ([RetryLogic.CircuitBreaker]::IsOpen) {
        $timeSinceLastFailure = (Get-Date) - [RetryLogic.CircuitBreaker]::LastFailureTime
        
        if ($timeSinceLastFailure.TotalSeconds -ge $CircuitBreakerResetSeconds) {
            # Réinitialiser le circuit breaker après le délai de réinitialisation
            [RetryLogic.CircuitBreaker]::IsOpen = $false
            [RetryLogic.CircuitBreaker]::FailureCount = 0
            Write-Verbose "Circuit breaker réinitialisé pour l'opération '$OperationName'"
        }
        else {
            # Le circuit breaker est toujours ouvert
            $message = "Circuit breaker ouvert pour l'opération '$OperationName'. Réessayez dans $([Math]::Ceiling($CircuitBreakerResetSeconds - $timeSinceLastFailure.TotalSeconds)) secondes."
            Write-Warning $message
            
            if ($ThrowOnFailure) {
                throw [System.InvalidOperationException]::new($message)
            }
            else {
                return $null
            }
        }
    }
    
    # Exécuter l'opération avec reprise
    try {
        $result = Invoke-WithRetryAndLogging -ScriptBlock $ScriptBlock -MaxRetries $MaxRetries -DelaySeconds $DelaySeconds -BackoffStrategy $BackoffStrategy -BackoffMultiplier $BackoffMultiplier -OperationName $OperationName -ThrowOnFailure $ThrowOnFailure
        
        # Réinitialiser le compteur d'échecs en cas de succès
        [RetryLogic.CircuitBreaker]::FailureCount = 0
        
        return $result
    }
    catch {
        # Incrémenter le compteur d'échecs
        [RetryLogic.CircuitBreaker]::FailureCount++
        [RetryLogic.CircuitBreaker]::LastFailureTime = Get-Date
        
        # Vérifier si le seuil du circuit breaker est atteint
        if ([RetryLogic.CircuitBreaker]::FailureCount -ge $CircuitBreakerThreshold) {
            [RetryLogic.CircuitBreaker]::IsOpen = $true
            $message = "Circuit breaker ouvert pour l'opération '$OperationName' après $([RetryLogic.CircuitBreaker]::FailureCount) échecs consécutifs."
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

# Fonction pour exécuter une opération avec reprise et timeout
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
    
    # Créer un bloc de script qui exécute l'opération avec timeout
    $scriptBlockWithTimeout = {
        $timeoutMilliseconds = $TimeoutSeconds * 1000
        
        # Créer un objet de synchronisation pour la communication entre les threads
        $sync = [System.Collections.Hashtable]::Synchronized(@{
            Result = $null
            Error = $null
            Completed = $false
        })
        
        # Créer un thread pour exécuter l'opération
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
        
        # Démarrer le thread
        $thread.Start()
        
        # Attendre que le thread se termine ou que le timeout soit atteint
        $completed = $thread.Join($timeoutMilliseconds)
        
        if (-not $completed) {
            # Le timeout a été atteint, essayer d'arrêter le thread
            try {
                $thread.Abort()
            }
            catch {
                Write-Warning "Impossible d'arrêter le thread: $_"
            }
            
            throw [System.TimeoutException]::new("L'opération '$OperationName' a dépassé le délai d'attente de $TimeoutSeconds secondes.")
        }
        
        # Vérifier si une erreur s'est produite
        if ($sync.Error -ne $null) {
            throw $sync.Error
        }
        
        # Retourner le résultat
        return $sync.Result
    }
    
    # Exécuter l'opération avec reprise et timeout
    return Invoke-WithRetryAndLogging -ScriptBlock $scriptBlockWithTimeout -MaxRetries $MaxRetries -DelaySeconds $DelaySeconds -BackoffStrategy $BackoffStrategy -BackoffMultiplier $BackoffMultiplier -OperationName $OperationName -ThrowOnFailure $ThrowOnFailure
}

# Exporter les fonctions
Export-ModuleMember -Function Invoke-WithRetry, Invoke-WithRetryAndLogging, Invoke-WithRetryOnException, Invoke-WithRetryAndCircuitBreaker, Invoke-WithRetryAndTimeout
