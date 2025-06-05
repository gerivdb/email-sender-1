# ErrorManagerBridge.psm1
# PowerShell Bridge Module for ErrorManager Integration
# Section 1.4 - Implementation des Recommandations

#region Configuration

# Default configuration
$script:ErrorManagerConfig = @{
   BaseUrl        = $env:ERROR_MANAGER_URL -or "http://localhost:8081"
   ApiVersion     = "v1"
   Timeout        = 30
   MaxRetries     = 3
   RetryDelay     = 1000  # milliseconds
   EnableFallback = $true
   LogLevel       = "INFO"
}

#endregion

#region Core Functions

<#
.SYNOPSIS
    Processes an error through the centralized ErrorManager system.

.DESCRIPTION
    Sends PowerShell errors to the Go ErrorManager via REST API for 
    standardized error processing, cataloging, and recovery.

.PARAMETER ErrorMessage
    The error message to process.

.PARAMETER Component
    The component that generated the error (default: "powershell-module").

.PARAMETER Context
    Additional context information as a hashtable.

.PARAMETER Severity
    Error severity level: Low, Medium, High, Critical.

.PARAMETER Category
    Error category for classification.

.PARAMETER ScriptPath
    Path to the script that generated the error.

.PARAMETER Operation
    The operation that was being performed when the error occurred.

.EXAMPLE
    Invoke-ErrorManagerProcess -ErrorMessage "Database connection failed" -Component "data-access" -Severity "High"

.EXAMPLE
    $context = @{ ConnectionString = "Server=..."; RetryCount = 3 }
    Invoke-ErrorManagerProcess -ErrorMessage "Query timeout" -Context $context -Category "DATABASE"
#>
function Invoke-ErrorManagerProcess {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $true)]
      [string]$ErrorMessage,
        
      [Parameter(Mandatory = $false)]
      [string]$Component = "powershell-module",
        
      [Parameter(Mandatory = $false)]
      [hashtable]$Context = @{},
        
      [Parameter(Mandatory = $false)]
      [ValidateSet("Low", "Medium", "High", "Critical")]
      [string]$Severity = "Medium",
        
      [Parameter(Mandatory = $false)]
      [string]$Category = "GENERAL",
        
      [Parameter(Mandatory = $false)]
      [string]$ScriptPath = $MyInvocation.ScriptName,
        
      [Parameter(Mandatory = $false)]
      [string]$Operation = "unknown"
   )
    
   begin {
      Write-Verbose "Starting ErrorManager processing for: $ErrorMessage"
   }
    
   process {
      # Create error payload
      $errorPayload = @{
         error_message = $ErrorMessage
         component     = $Component
         context       = $Context
         severity      = $Severity.ToUpper()
         category      = $Category.ToUpper()
         script_path   = $ScriptPath
         operation     = $Operation
         timestamp     = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
         source        = "powershell"
         session_id    = $PID
         user          = $env:USERNAME
         machine       = $env:COMPUTERNAME
      }
        
      # Enhanced context
      $errorPayload.context.powershell_version = $PSVersionTable.PSVersion.ToString()
      $errorPayload.context.execution_policy = Get-ExecutionPolicy
      $errorPayload.context.current_location = Get-Location
        
      $jsonPayload = $errorPayload | ConvertTo-Json -Depth 5
        
      # Attempt to send to ErrorManager
      $result = Send-ErrorToManager -Payload $jsonPayload -ErrorMessage $ErrorMessage
        
      return $result
   }
    
   end {
      Write-Verbose "ErrorManager processing completed"
   }
}

<#
.SYNOPSIS
    Wraps a script block with ErrorManager error handling.

.DESCRIPTION
    Executes a script block and automatically processes any errors 
    through the ErrorManager system.

.PARAMETER ScriptBlock
    The script block to execute with error handling.

.PARAMETER Component
    The component name for error context.

.PARAMETER Context
    Additional context information.

.PARAMETER EnableRetry
    Whether to enable automatic retry on transient errors.

.PARAMETER MaxRetries
    Maximum number of retry attempts.

.EXAMPLE
    Invoke-ErrorManagerWrapper -Component "database" -ScriptBlock {
        Get-Content "nonexistent-file.txt"
    }

.EXAMPLE
    $result = Invoke-ErrorManagerWrapper -Component "api-call" -EnableRetry -ScriptBlock {
        Invoke-RestMethod -Uri "https://api.example.com/data" -Method GET
    }
#>
function Invoke-ErrorManagerWrapper {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $true)]
      [ScriptBlock]$ScriptBlock,
        
      [Parameter(Mandatory = $false)]
      [string]$Component = "powershell-wrapper",
        
      [Parameter(Mandatory = $false)]
      [hashtable]$Context = @{},
        
      [Parameter(Mandatory = $false)]
      [switch]$EnableRetry,
        
      [Parameter(Mandatory = $false)]
      [int]$MaxRetries = 3
   )
    
   $attempt = 1
   $lastError = $null
    
   do {
      try {
         Write-Verbose "Executing wrapped script block (attempt $attempt)"
         $result = & $ScriptBlock
         return $result
      }
      catch {
         $lastError = $_
         $errorContext = $Context.Clone()
         $errorContext.attempt = $attempt
         $errorContext.max_retries = $MaxRetries
         $errorContext.enable_retry = $EnableRetry.IsPresent
            
         # Process error through ErrorManager
         $errorResult = Invoke-ErrorManagerProcess `
            -ErrorMessage $_.Exception.Message `
            -Component $Component `
            -Context $errorContext `
            -Severity $(if ($attempt -eq $MaxRetries) { "High" } else { "Medium" }) `
            -Operation "wrapped_execution"
            
         if ($EnableRetry -and $attempt -lt $MaxRetries) {
            $retryDelay = [Math]::Pow(2, $attempt - 1) * $script:ErrorManagerConfig.RetryDelay
            Write-Verbose "Retrying in $retryDelay ms..."
            Start-Sleep -Milliseconds $retryDelay
            $attempt++
         }
         else {
            break
         }
      }
   } while ($EnableRetry -and $attempt -le $MaxRetries)
    
   # If we reach here, all retries failed
   throw $lastError
}

<#
.SYNOPSIS
    Configures the ErrorManager bridge settings.

.DESCRIPTION
    Updates the configuration for the PowerShell ErrorManager bridge.

.PARAMETER BaseUrl
    The base URL for the ErrorManager API.

.PARAMETER Timeout
    Request timeout in seconds.

.PARAMETER MaxRetries
    Maximum retry attempts for API calls.

.PARAMETER EnableFallback
    Whether to enable fallback logging when API is unavailable.

.EXAMPLE
    Set-ErrorManagerConfig -BaseUrl "http://localhost:8081" -Timeout 60
#>
function Set-ErrorManagerConfig {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $false)]
      [string]$BaseUrl,
        
      [Parameter(Mandatory = $false)]
      [int]$Timeout,
        
      [Parameter(Mandatory = $false)]
      [int]$MaxRetries,
        
      [Parameter(Mandatory = $false)]
      [bool]$EnableFallback,
        
      [Parameter(Mandatory = $false)]
      [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
      [string]$LogLevel
   )
    
   if ($BaseUrl) { $script:ErrorManagerConfig.BaseUrl = $BaseUrl }
   if ($Timeout) { $script:ErrorManagerConfig.Timeout = $Timeout }
   if ($MaxRetries) { $script:ErrorManagerConfig.MaxRetries = $MaxRetries }
   if ($PSBoundParameters.ContainsKey('EnableFallback')) { $script:ErrorManagerConfig.EnableFallback = $EnableFallback }
   if ($LogLevel) { $script:ErrorManagerConfig.LogLevel = $LogLevel }
    
   Write-Verbose "ErrorManager configuration updated"
}

<#
.SYNOPSIS
    Gets the current ErrorManager bridge configuration.

.DESCRIPTION
    Returns the current configuration settings for the ErrorManager bridge.

.EXAMPLE
    Get-ErrorManagerConfig
#>
function Get-ErrorManagerConfig {
   [CmdletBinding()]
   param()
    
   return $script:ErrorManagerConfig.Clone()
}

<#
.SYNOPSIS
    Tests connectivity to the ErrorManager API.

.DESCRIPTION
    Performs a health check against the ErrorManager API to verify connectivity.

.EXAMPLE
    Test-ErrorManagerConnectivity
#>
function Test-ErrorManagerConnectivity {
   [CmdletBinding()]
   param()
    
   try {
      $healthUrl = "$($script:ErrorManagerConfig.BaseUrl)/api/$($script:ErrorManagerConfig.ApiVersion)/health"
        
      $response = Invoke-RestMethod -Uri $healthUrl -Method GET -TimeoutSec $script:ErrorManagerConfig.Timeout
        
      return @{
         Success = $true
         Status  = $response.status
         Message = "ErrorManager API is reachable"
         Url     = $healthUrl
      }
   }
   catch {
      return @{
         Success = $false
         Status  = "error"
         Message = $_.Exception.Message
         Url     = $healthUrl
      }
   }
}

#endregion

#region Helper Functions

function Send-ErrorToManager {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $true)]
      [string]$Payload,
        
      [Parameter(Mandatory = $true)]
      [string]$ErrorMessage
   )
    
   $apiUrl = "$($script:ErrorManagerConfig.BaseUrl)/api/$($script:ErrorManagerConfig.ApiVersion)/errors"
   $attempt = 1
    
   do {
      try {
         Write-Verbose "Sending error to ErrorManager (attempt $attempt): $apiUrl"
            
         $response = Invoke-RestMethod -Uri $apiUrl `
            -Method POST `
            -Body $Payload `
            -ContentType "application/json" `
            -TimeoutSec $script:ErrorManagerConfig.Timeout
            
         Write-Verbose "ErrorManager processed error successfully"
         return @{
            Success        = $true
            ErrorId        = $response.error_id
            RecoveryAction = $response.recovery_action
            ProcessedAt    = $response.processed_at
            Message        = "Error processed by ErrorManager"
         }
      }
      catch {
         Write-Warning "Failed to send error to ErrorManager (attempt $attempt): $($_.Exception.Message)"
            
         if ($attempt -lt $script:ErrorManagerConfig.MaxRetries) {
            $delay = [Math]::Pow(2, $attempt - 1) * $script:ErrorManagerConfig.RetryDelay
            Write-Verbose "Retrying in $delay ms..."
            Start-Sleep -Milliseconds $delay
            $attempt++
         }
         else {
            # All retries failed, use fallback if enabled
            if ($script:ErrorManagerConfig.EnableFallback) {
               Write-FallbackError -ErrorMessage $ErrorMessage -ApiError $_.Exception.Message
            }
                
            return @{
               Success        = $false
               ErrorId        = $null
               RecoveryAction = "manual"
               ProcessedAt    = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
               Message        = "Failed to process via ErrorManager, used fallback logging"
            }
         }
      }
   } while ($attempt -le $script:ErrorManagerConfig.MaxRetries)
}

function Write-FallbackError {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $true)]
      [string]$ErrorMessage,
        
      [Parameter(Mandatory = $false)]
      [string]$ApiError
   )
    
   $fallbackEntry = @{
      timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
      level     = "ERROR"
      source    = "PowerShell-ErrorManager-Bridge"
      message   = $ErrorMessage
      api_error = $ApiError
      fallback  = $true
   }
    
   # Log to PowerShell error stream
   Write-Error "ErrorManager Bridge Fallback: $ErrorMessage"
    
   # Optionally log to file
   if ($env:ERROR_MANAGER_FALLBACK_LOG) {
      $fallbackEntry | ConvertTo-Json | Add-Content -Path $env:ERROR_MANAGER_FALLBACK_LOG
   }
}

#endregion

#region Module Initialization

# Initialize configuration from environment variables
if ($env:ERROR_MANAGER_URL) {
   $script:ErrorManagerConfig.BaseUrl = $env:ERROR_MANAGER_URL
}

if ($env:ERROR_MANAGER_TIMEOUT) {
   $script:ErrorManagerConfig.Timeout = [int]$env:ERROR_MANAGER_TIMEOUT
}

if ($env:ERROR_MANAGER_LOG_LEVEL) {
   $script:ErrorManagerConfig.LogLevel = $env:ERROR_MANAGER_LOG_LEVEL
}

Write-Verbose "ErrorManagerBridge module loaded with base URL: $($script:ErrorManagerConfig.BaseUrl)"

#endregion

#region Exports

Export-ModuleMember -Function @(
   'Invoke-ErrorManagerProcess',
   'Invoke-ErrorManagerWrapper', 
   'Set-ErrorManagerConfig',
   'Get-ErrorManagerConfig',
   'Test-ErrorManagerConnectivity'
)

#endregion
