# Example-KernelDensityEstimateLoggingConfig.ps1
# Example of using the logging configuration functions for kernel density estimation

# Import the required modules
. ..\KernelDensityEstimateLoggingConfig.ps1

# Example 1: Using predefined configurations
Write-Host "Example 1: Using predefined configurations" -ForegroundColor Cyan
Write-Host "-------------------" -ForegroundColor Cyan

# Minimal configuration
Write-Host "`nMinimal configuration:" -ForegroundColor Yellow
$minimalConfig = Set-KernelDensityEstimateLogging -ConfigurationType "Minimal"
Write-Host "  LogLevel: $($script:LogLevelNames[$minimalConfig.LogLevel])" -ForegroundColor Green
Write-Host "  LogToConsole: $($minimalConfig.LogToConsole)" -ForegroundColor Green
Write-Host "  LogToFile: $($minimalConfig.LogToFile)" -ForegroundColor Green
Write-Host "  LogFilePath: $($minimalConfig.LogFilePath)" -ForegroundColor Green
Write-Host "  PerformanceLogging: $($minimalConfig.PerformanceLogging)" -ForegroundColor Green
Write-Host "  PerformanceReportPath: $($minimalConfig.PerformanceReportPath)" -ForegroundColor Green

# Normal configuration
Write-Host "`nNormal configuration:" -ForegroundColor Yellow
$normalConfig = Set-KernelDensityEstimateLogging -ConfigurationType "Normal"
Write-Host "  LogLevel: $($script:LogLevelNames[$normalConfig.LogLevel])" -ForegroundColor Green
Write-Host "  LogToConsole: $($normalConfig.LogToConsole)" -ForegroundColor Green
Write-Host "  LogToFile: $($normalConfig.LogToFile)" -ForegroundColor Green
Write-Host "  LogFilePath: $($normalConfig.LogFilePath)" -ForegroundColor Green
Write-Host "  PerformanceLogging: $($normalConfig.PerformanceLogging)" -ForegroundColor Green
Write-Host "  PerformanceReportPath: $($normalConfig.PerformanceReportPath)" -ForegroundColor Green

# Verbose configuration
Write-Host "`nVerbose configuration:" -ForegroundColor Yellow
$verboseConfig = Set-KernelDensityEstimateLogging -ConfigurationType "Verbose"
Write-Host "  LogLevel: $($script:LogLevelNames[$verboseConfig.LogLevel])" -ForegroundColor Green
Write-Host "  LogToConsole: $($verboseConfig.LogToConsole)" -ForegroundColor Green
Write-Host "  LogToFile: $($verboseConfig.LogToFile)" -ForegroundColor Green
Write-Host "  LogFilePath: $($verboseConfig.LogFilePath)" -ForegroundColor Green
Write-Host "  PerformanceLogging: $($verboseConfig.PerformanceLogging)" -ForegroundColor Green
Write-Host "  PerformanceReportPath: $($verboseConfig.PerformanceReportPath)" -ForegroundColor Green

# Debug configuration
Write-Host "`nDebug configuration:" -ForegroundColor Yellow
$debugConfig = Set-KernelDensityEstimateLogging -ConfigurationType "Debug"
Write-Host "  LogLevel: $($script:LogLevelNames[$debugConfig.LogLevel])" -ForegroundColor Green
Write-Host "  LogToConsole: $($debugConfig.LogToConsole)" -ForegroundColor Green
Write-Host "  LogToFile: $($debugConfig.LogToFile)" -ForegroundColor Green
Write-Host "  LogFilePath: $($debugConfig.LogFilePath)" -ForegroundColor Green
Write-Host "  PerformanceLogging: $($debugConfig.PerformanceLogging)" -ForegroundColor Green
Write-Host "  PerformanceReportPath: $($debugConfig.PerformanceReportPath)" -ForegroundColor Green

# Performance configuration
Write-Host "`nPerformance configuration:" -ForegroundColor Yellow
$performanceConfig = Set-KernelDensityEstimateLogging -ConfigurationType "Performance"
Write-Host "  LogLevel: $($script:LogLevelNames[$performanceConfig.LogLevel])" -ForegroundColor Green
Write-Host "  LogToConsole: $($performanceConfig.LogToConsole)" -ForegroundColor Green
Write-Host "  LogToFile: $($performanceConfig.LogToFile)" -ForegroundColor Green
Write-Host "  LogFilePath: $($performanceConfig.LogFilePath)" -ForegroundColor Green
Write-Host "  PerformanceLogging: $($performanceConfig.PerformanceLogging)" -ForegroundColor Green
Write-Host "  PerformanceReportPath: $($performanceConfig.PerformanceReportPath)" -ForegroundColor Green

# Full configuration
Write-Host "`nFull configuration:" -ForegroundColor Yellow
$fullConfig = Set-KernelDensityEstimateLogging -ConfigurationType "Full"
Write-Host "  LogLevel: $($script:LogLevelNames[$fullConfig.LogLevel])" -ForegroundColor Green
Write-Host "  LogToConsole: $($fullConfig.LogToConsole)" -ForegroundColor Green
Write-Host "  LogToFile: $($fullConfig.LogToFile)" -ForegroundColor Green
Write-Host "  LogFilePath: $($fullConfig.LogFilePath)" -ForegroundColor Green
Write-Host "  PerformanceLogging: $($fullConfig.PerformanceLogging)" -ForegroundColor Green
Write-Host "  PerformanceReportPath: $($fullConfig.PerformanceReportPath)" -ForegroundColor Green

# Example 2: Creating a custom configuration
Write-Host "`nExample 2: Creating a custom configuration" -ForegroundColor Cyan
Write-Host "-------------------" -ForegroundColor Cyan

# Create a custom configuration
$customConfig = New-LoggingConfiguration -LogLevel $script:LogLevelDebug -LogToConsole $true -LogToFile $true -LogFilePath "$env:TEMP\KernelDensityEstimate\Custom.log" -PerformanceLogging $true -PerformanceReportPath "$env:TEMP\KernelDensityEstimate\Reports\CustomPerformance.txt"

# Apply the custom configuration
Set-LoggingConfiguration -Configuration $customConfig

Write-Host "Custom configuration:" -ForegroundColor Yellow
Write-Host "  LogLevel: $($script:LogLevelNames[$customConfig.LogLevel])" -ForegroundColor Green
Write-Host "  LogToConsole: $($customConfig.LogToConsole)" -ForegroundColor Green
Write-Host "  LogToFile: $($customConfig.LogToFile)" -ForegroundColor Green
Write-Host "  LogFilePath: $($customConfig.LogFilePath)" -ForegroundColor Green
Write-Host "  PerformanceLogging: $($customConfig.PerformanceLogging)" -ForegroundColor Green
Write-Host "  PerformanceReportPath: $($customConfig.PerformanceReportPath)" -ForegroundColor Green

# Example 3: Exporting and importing a configuration
Write-Host "`nExample 3: Exporting and importing a configuration" -ForegroundColor Cyan
Write-Host "-------------------" -ForegroundColor Cyan

# Export the custom configuration to a file
$configFilePath = "$env:TEMP\KernelDensityEstimate\Config\CustomConfig.json"
Export-LoggingConfiguration -Configuration $customConfig -Path $configFilePath

Write-Host "Configuration exported to: $configFilePath" -ForegroundColor Yellow

# Import the configuration from the file
$importedConfig = Import-LoggingConfiguration -Path $configFilePath

# Apply the imported configuration
Set-LoggingConfiguration -Configuration $importedConfig

Write-Host "Imported configuration:" -ForegroundColor Yellow
Write-Host "  LogLevel: $($script:LogLevelNames[$importedConfig.LogLevel])" -ForegroundColor Green
Write-Host "  LogToConsole: $($importedConfig.LogToConsole)" -ForegroundColor Green
Write-Host "  LogToFile: $($importedConfig.LogToFile)" -ForegroundColor Green
Write-Host "  LogFilePath: $($importedConfig.LogFilePath)" -ForegroundColor Green
Write-Host "  PerformanceLogging: $($importedConfig.PerformanceLogging)" -ForegroundColor Green
Write-Host "  PerformanceReportPath: $($importedConfig.PerformanceReportPath)" -ForegroundColor Green

# Example 4: Using the configuration with kernel density estimation
Write-Host "`nExample 4: Using the configuration with kernel density estimation" -ForegroundColor Cyan
Write-Host "-------------------" -ForegroundColor Cyan

# Set a performance configuration
Set-KernelDensityEstimateLogging -ConfigurationType "Performance"

# Create some sample data
$data = 1..10 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }

# Write some log messages
Write-InfoLog "Starting kernel density estimation with performance logging"
Write-DebugLog "Data: $($data -join ', ')"

# Start performance measurement
$performanceMeasurement = Start-PerformanceMeasurement -OperationName "KernelDensityEstimation" -MeasureMemory

# Add a checkpoint
Add-PerformanceCheckpoint -PerformanceMeasurement $performanceMeasurement -CheckpointName "DataValidation"

# Add another checkpoint
Add-PerformanceCheckpoint -PerformanceMeasurement $performanceMeasurement -CheckpointName "CalculationStart"

# Simulate some work
Start-Sleep -Seconds 1

# Add a final checkpoint
Add-PerformanceCheckpoint -PerformanceMeasurement $performanceMeasurement -CheckpointName "CalculationComplete"

# Stop performance measurement
$performanceMeasurement = Stop-PerformanceMeasurement -PerformanceMeasurement $performanceMeasurement

# Display the performance measurement
Write-Host "`nPerformance measurement:" -ForegroundColor Yellow
$performanceString = Format-PerformanceMeasurement -PerformanceMeasurement $performanceMeasurement -IncludeCheckpoints
Write-Host $performanceString -ForegroundColor Gray

# Write a final log message
Write-InfoLog "Kernel density estimation completed"
