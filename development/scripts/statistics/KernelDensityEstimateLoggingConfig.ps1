# KernelDensityEstimateLoggingConfig.ps1
# Configuration functions for kernel density estimation logging

# Import the required modules
. .\KernelDensityEstimateSimpleLogging.ps1
. .\KernelDensityEstimatePerformanceLogging.ps1

# Define default configuration values
$script:DefaultLogLevel = $script:LogLevelInfo
$script:DefaultLogToConsole = $true
$script:DefaultLogToFile = $false
$script:DefaultLogFilePath = $null
$script:DefaultPerformanceLogging = $false
$script:DefaultPerformanceReportPath = $null

# Function to get the default log file path
function Get-DefaultLogFilePath {
    [CmdletBinding()]
    [OutputType([string])]
    param ()
    
    $logDir = Join-Path -Path $env:TEMP -ChildPath "KernelDensityEstimate"
    if (-not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    $logFilePath = Join-Path -Path $logDir -ChildPath "KernelDensityEstimate_$(Get-Date -Format 'yyyyMMdd').log"
    
    return $logFilePath
}

# Function to get the default performance report path
function Get-DefaultPerformanceReportPath {
    [CmdletBinding()]
    [OutputType([string])]
    param ()
    
    $reportDir = Join-Path -Path $env:TEMP -ChildPath "KernelDensityEstimate\Reports"
    if (-not (Test-Path -Path $reportDir)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }
    
    $reportFilePath = Join-Path -Path $reportDir -ChildPath "KernelDensityEstimatePerformance_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    return $reportFilePath
}

# Function to create a logging configuration
function New-LoggingConfiguration {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet(0, 1, 2, 3, 4, 5)]
        [int]$LogLevel = $script:DefaultLogLevel,
        
        [Parameter(Mandatory = $false)]
        [bool]$LogToConsole = $script:DefaultLogToConsole,
        
        [Parameter(Mandatory = $false)]
        [bool]$LogToFile = $script:DefaultLogToFile,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = $script:DefaultLogFilePath,
        
        [Parameter(Mandatory = $false)]
        [bool]$PerformanceLogging = $script:DefaultPerformanceLogging,
        
        [Parameter(Mandatory = $false)]
        [string]$PerformanceReportPath = $script:DefaultPerformanceReportPath
    )
    
    # If log to file is enabled but no log file path is provided, use the default
    if ($LogToFile -and [string]::IsNullOrEmpty($LogFilePath)) {
        $LogFilePath = Get-DefaultLogFilePath
    }
    
    # If performance logging is enabled but no performance report path is provided, use the default
    if ($PerformanceLogging -and [string]::IsNullOrEmpty($PerformanceReportPath)) {
        $PerformanceReportPath = Get-DefaultPerformanceReportPath
    }
    
    # Create the configuration object
    $configuration = [PSCustomObject]@{
        LogLevel = $LogLevel
        LogToConsole = $LogToConsole
        LogToFile = $LogToFile
        LogFilePath = $LogFilePath
        PerformanceLogging = $PerformanceLogging
        PerformanceReportPath = $PerformanceReportPath
    }
    
    return $configuration
}

# Function to apply a logging configuration
function Set-LoggingConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Configuration
    )
    
    # Initialize logging
    Initialize-Logging -Level $Configuration.LogLevel -LogFilePath $Configuration.LogFilePath -LogToConsole $Configuration.LogToConsole -LogToFile $Configuration.LogToFile
    
    # Log the configuration
    $levelName = $script:LogLevelNames[$Configuration.LogLevel]
    Write-InfoLog "Logging configuration applied: LogLevel=$levelName, LogToConsole=$($Configuration.LogToConsole), LogToFile=$($Configuration.LogToFile), LogFilePath=$($Configuration.LogFilePath), PerformanceLogging=$($Configuration.PerformanceLogging), PerformanceReportPath=$($Configuration.PerformanceReportPath)"
    
    return $Configuration
}

# Function to create a logging configuration from a JSON file
function Import-LoggingConfiguration {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    # Check if the file exists
    if (-not (Test-Path -Path $Path)) {
        throw "Configuration file not found: $Path"
    }
    
    # Read the configuration from the file
    try {
        $configJson = Get-Content -Path $Path -Raw | ConvertFrom-Json
    } catch {
        throw "Failed to parse configuration file: $($_.Exception.Message)"
    }
    
    # Create the configuration object
    $configuration = New-LoggingConfiguration
    
    # Update the configuration with values from the JSON
    if ($configJson.PSObject.Properties.Name -contains "LogLevel") {
        $configuration.LogLevel = $configJson.LogLevel
    }
    
    if ($configJson.PSObject.Properties.Name -contains "LogToConsole") {
        $configuration.LogToConsole = $configJson.LogToConsole
    }
    
    if ($configJson.PSObject.Properties.Name -contains "LogToFile") {
        $configuration.LogToFile = $configJson.LogToFile
    }
    
    if ($configJson.PSObject.Properties.Name -contains "LogFilePath") {
        $configuration.LogFilePath = $configJson.LogFilePath
    }
    
    if ($configJson.PSObject.Properties.Name -contains "PerformanceLogging") {
        $configuration.PerformanceLogging = $configJson.PerformanceLogging
    }
    
    if ($configJson.PSObject.Properties.Name -contains "PerformanceReportPath") {
        $configuration.PerformanceReportPath = $configJson.PerformanceReportPath
    }
    
    return $configuration
}

# Function to save a logging configuration to a JSON file
function Export-LoggingConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Configuration,
        
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    # Create the configuration directory if it doesn't exist
    $configDir = Split-Path -Path $Path -Parent
    if (-not [string]::IsNullOrEmpty($configDir) -and -not (Test-Path -Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }
    
    # Convert the configuration to JSON
    $configJson = $Configuration | ConvertTo-Json
    
    # Write the configuration to the file
    Set-Content -Path $Path -Value $configJson -Encoding UTF8
    
    Write-InfoLog "Logging configuration exported to: $Path"
    
    return $Path
}

# Function to create a predefined logging configuration
function New-PredefinedLoggingConfiguration {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Minimal", "Normal", "Verbose", "Debug", "Performance", "Full")]
        [string]$ConfigurationType
    )
    
    # Create the configuration based on the type
    switch ($ConfigurationType) {
        "Minimal" {
            # Minimal configuration: Only error messages to console
            $configuration = New-LoggingConfiguration -LogLevel $script:LogLevelError -LogToConsole $true -LogToFile $false -PerformanceLogging $false
        }
        "Normal" {
            # Normal configuration: Error and warning messages to console
            $configuration = New-LoggingConfiguration -LogLevel $script:LogLevelWarning -LogToConsole $true -LogToFile $false -PerformanceLogging $false
        }
        "Verbose" {
            # Verbose configuration: All messages to console
            $configuration = New-LoggingConfiguration -LogLevel $script:LogLevelVerbose -LogToConsole $true -LogToFile $false -PerformanceLogging $false
        }
        "Debug" {
            # Debug configuration: All messages to console and file
            $configuration = New-LoggingConfiguration -LogLevel $script:LogLevelDebug -LogToConsole $true -LogToFile $true -LogFilePath (Get-DefaultLogFilePath) -PerformanceLogging $false
        }
        "Performance" {
            # Performance configuration: Info messages to console, performance logging enabled
            $configuration = New-LoggingConfiguration -LogLevel $script:LogLevelInfo -LogToConsole $true -LogToFile $false -PerformanceLogging $true -PerformanceReportPath (Get-DefaultPerformanceReportPath)
        }
        "Full" {
            # Full configuration: All messages to console and file, performance logging enabled
            $configuration = New-LoggingConfiguration -LogLevel $script:LogLevelVerbose -LogToConsole $true -LogToFile $true -LogFilePath (Get-DefaultLogFilePath) -PerformanceLogging $true -PerformanceReportPath (Get-DefaultPerformanceReportPath)
        }
    }
    
    return $configuration
}

# Function to configure logging for kernel density estimation
function Set-KernelDensityEstimateLogging {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Minimal", "Normal", "Verbose", "Debug", "Performance", "Full")]
        [string]$ConfigurationType = "Normal",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet(0, 1, 2, 3, 4, 5)]
        [int]$LogLevel,
        
        [Parameter(Mandatory = $false)]
        [bool]$LogToConsole,
        
        [Parameter(Mandatory = $false)]
        [bool]$LogToFile,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath,
        
        [Parameter(Mandatory = $false)]
        [bool]$PerformanceLogging,
        
        [Parameter(Mandatory = $false)]
        [string]$PerformanceReportPath,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigurationFilePath
    )
    
    # Create the configuration
    if ($ConfigurationFilePath) {
        # Import the configuration from a file
        $configuration = Import-LoggingConfiguration -Path $ConfigurationFilePath
    } else {
        # Create a predefined configuration
        $configuration = New-PredefinedLoggingConfiguration -ConfigurationType $ConfigurationType
        
        # Override the configuration with the provided parameters
        if ($PSBoundParameters.ContainsKey('LogLevel')) {
            $configuration.LogLevel = $LogLevel
        }
        
        if ($PSBoundParameters.ContainsKey('LogToConsole')) {
            $configuration.LogToConsole = $LogToConsole
        }
        
        if ($PSBoundParameters.ContainsKey('LogToFile')) {
            $configuration.LogToFile = $LogToFile
        }
        
        if ($PSBoundParameters.ContainsKey('LogFilePath')) {
            $configuration.LogFilePath = $LogFilePath
        }
        
        if ($PSBoundParameters.ContainsKey('PerformanceLogging')) {
            $configuration.PerformanceLogging = $PerformanceLogging
        }
        
        if ($PSBoundParameters.ContainsKey('PerformanceReportPath')) {
            $configuration.PerformanceReportPath = $PerformanceReportPath
        }
    }
    
    # Apply the configuration
    Set-LoggingConfiguration -Configuration $configuration
    
    return $configuration
}
