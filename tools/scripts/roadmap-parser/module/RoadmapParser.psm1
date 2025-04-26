#
# RoadmapParser.psm1
#
# Main module file for the RoadmapParser module
#

# Module path
$script:ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Functions path
$script:FunctionsPath = Join-Path -Path $script:ModulePath -ChildPath "Functions"

# Private functions path
$script:PrivateFunctionsPath = Join-Path -Path $script:FunctionsPath -ChildPath "Private"

# Public functions path
$script:PublicFunctionsPath = Join-Path -Path $script:FunctionsPath -ChildPath "Public"

# Exceptions path
$script:ExceptionsPath = Join-Path -Path $script:FunctionsPath -ChildPath "Exceptions"

# Configuration path
$script:ConfigPath = Join-Path -Path $script:ModulePath -ChildPath "Config"

# Default configuration file
$script:DefaultConfigFile = Join-Path -Path $script:ConfigPath -ChildPath "RoadmapParser.config.json"

# Module configuration
$script:ModuleConfig = @{
    LogLevel          = "Info"
    LogPath           = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser.log"
    MaxRetryCount     = 3
    RetryDelaySeconds = 1
    DefaultEncoding   = "UTF8"
}

# Create module structure if it doesn't exist
if (-not (Test-Path -Path $script:FunctionsPath)) {
    New-Item -Path $script:FunctionsPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $script:PrivateFunctionsPath)) {
    New-Item -Path $script:PrivateFunctionsPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $script:PublicFunctionsPath)) {
    New-Item -Path $script:PublicFunctionsPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $script:ExceptionsPath)) {
    New-Item -Path $script:ExceptionsPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $script:ConfigPath)) {
    New-Item -Path $script:ConfigPath -ItemType Directory -Force | Out-Null
}

# Create default configuration file if it doesn't exist
if (-not (Test-Path -Path $script:DefaultConfigFile)) {
    $script:ModuleConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:DefaultConfigFile -Encoding utf8
}

# Load module configuration
if (Test-Path -Path $script:DefaultConfigFile) {
    try {
        $config = Get-Content -Path $script:DefaultConfigFile -Raw | ConvertFrom-Json

        # Update module configuration with values from config file
        foreach ($key in $config.PSObject.Properties.Name) {
            $script:ModuleConfig[$key] = $config.$key
        }
    } catch {
        Write-Warning "Failed to load module configuration: $_"
    }
}

# Import exceptions
if (Test-Path -Path $script:ExceptionsPath) {
    $exceptionFiles = Get-ChildItem -Path $script:ExceptionsPath -Filter "*.ps1" -File

    foreach ($file in $exceptionFiles) {
        try {
            . $file.FullName
            Write-Verbose "Imported exception file: $($file.Name)"
        } catch {
            Write-Warning "Failed to import exception file '$($file.Name)': $_"
        }
    }
}

# Import common functions
$script:CommonFunctionsPath = Join-Path -Path $script:FunctionsPath -ChildPath "Common"
if (Test-Path -Path $script:CommonFunctionsPath) {
    $commonFiles = Get-ChildItem -Path $script:CommonFunctionsPath -Filter "*.ps1" -File -Recurse

    foreach ($file in $commonFiles) {
        try {
            . $file.FullName
            Write-Verbose "Imported common function: $($file.Name)"
        } catch {
            Write-Warning "Failed to import common function file '$($file.Name)': $_"
        }
    }
}

# Import private functions
if (Test-Path -Path $script:PrivateFunctionsPath) {
    $privateFiles = Get-ChildItem -Path $script:PrivateFunctionsPath -Filter "*.ps1" -File -Recurse

    foreach ($file in $privateFiles) {
        try {
            . $file.FullName
            Write-Verbose "Imported private function: $($file.Name)"
        } catch {
            Write-Warning "Failed to import private function file '$($file.Name)': $_"
        }
    }
}

# Import public functions
if (Test-Path -Path $script:PublicFunctionsPath) {
    $publicFiles = Get-ChildItem -Path $script:PublicFunctionsPath -Filter "*.ps1" -File -Recurse

    foreach ($file in $publicFiles) {
        try {
            . $file.FullName
            Write-Verbose "Imported public function: $($file.Name)"
        } catch {
            Write-Warning "Failed to import public function file '$($file.Name)': $_"
        }
    }
}

# Export public functions
$publicFunctions = @(
    'ConvertFrom-MarkdownToRoadmap',
    'ConvertFrom-MarkdownToRoadmapExtended',
    'ConvertFrom-MarkdownToRoadmapOptimized',
    'ConvertFrom-MarkdownToRoadmapWithDependencies',
    'Test-MarkdownFormat',
    'Edit-RoadmapTask',
    'Find-DependencyCycle',
    'Get-TaskDependencies',
    'Export-RoadmapToJson',
    'Import-RoadmapFromJson',
    'Select-RoadmapTask',
    'Test-RoadmapParameter',
    'Get-RoadmapParameterDefault',
    'Initialize-RoadmapParameters',
    'Test-RoadmapReturnType',
    'Write-RoadmapLog',
    'Invoke-RoadmapErrorHandler',
    'Test-RoadmapInput',
    'ConvertTo-RoadmapFormat',
    'ConvertFrom-RoadmapFormat',
    'Format-RoadmapString',
    'Search-RoadmapString',
    'Measure-RoadmapString',
    'ConvertTo-NormalizedPath',
    'Test-PathValidity',
    'Resolve-PathToAbsolute',
    'Join-PathSegments',
    'Set-RoadmapLogLevel',
    'Get-RoadmapLogConfiguration',
    'Set-RoadmapLogDestination',
    'Set-RoadmapLogFormat',
    'Write-RoadmapDebug',
    'Write-RoadmapVerbose',
    'Write-RoadmapInformation',
    'Write-RoadmapWarning',
    'Write-RoadmapError',
    'Write-RoadmapCritical',
    'Inspect-Variable',
    # Points d'arrêt conditionnels
    'Set-RoadmapBreakpoint',
    'Test-RoadmapBreakpointCondition',
    'Invoke-RoadmapBreakpointAction',
    'Write-RoadmapBreakpointLog',
    'Set-RoadmapTimedBreakpoint',
    # Fonctions de gestion d'erreurs
    'Handle-Error',
    'Invoke-WithRetry',
    'Get-ExceptionInfo',
    'Get-ExceptionCategory',
    'Get-ExceptionSeverity',
    # Fonctions de journalisation
    'Set-LoggingConfiguration',
    'Write-LogDebug',
    'Write-LogInfo',
    'Write-LogWarning',
    'Write-LogError',
    'Get-LoggingConfiguration',
    'New-LogFile',
    # Fonctions de rotation des logs
    'Invoke-LogRotation',
    'Clear-OldLogFiles',
    'Compress-LogFile'
)

Export-ModuleMember -Function $publicFunctions

# Cleanup function that will be called when the module is removed
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    # Perform cleanup tasks here
    Write-Verbose "RoadmapParser module removed"
}

Write-Verbose "RoadmapParser module initialized"
