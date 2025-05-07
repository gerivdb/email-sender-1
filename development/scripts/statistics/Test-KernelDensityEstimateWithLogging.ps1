# Test-KernelDensityEstimateWithLogging.ps1
# Script to test the kernel density estimation module with logging

# Import the required modules
Import-Module .\KernelDensityEstimateWithLogging.psm1 -Force

# Create a temporary log file
$tempLogFile = Join-Path -Path $env:TEMP -ChildPath "KDELoggingTest_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Write-Host "Using log file: $tempLogFile" -ForegroundColor Yellow

# Create the log file
New-Item -Path $tempLogFile -ItemType File -Force | Out-Null

# Function to test kernel density estimation with different log levels
function Test-KDEWithLogLevel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet(0, 1, 2, 3, 4, 5)]
        [int]$LogLevel,

        [Parameter(Mandatory = $true)]
        [string]$LogFilePath
    )

    $levelName = switch ($LogLevel) {
        $KDELogLevelNone { "None" }
        $KDELogLevelError { "Error" }
        $KDELogLevelWarning { "Warning" }
        $KDELogLevelInfo { "Info" }
        $KDELogLevelDebug { "Debug" }
        $KDELogLevelVerbose { "Verbose" }
        default { "Unknown" }
    }

    Write-Host "Testing kernel density estimation with log level set to $levelName ($LogLevel)" -ForegroundColor Cyan

    # Create some sample data
    $data = 1..10 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }

    # Clear the log file
    if (Test-Path -Path $LogFilePath) {
        Clear-Content -Path $LogFilePath
    } else {
        New-Item -Path $LogFilePath -ItemType File -Force | Out-Null
    }

    # Perform kernel density estimation with the specified log level
    $result = Get-KernelDensityEstimate -Data $data -LogLevel $LogLevel -LogFilePath $LogFilePath -LogToFile:$true -IncludePerformanceMetrics

    # Display the results
    Write-Host "Kernel density estimation successful!" -ForegroundColor Green
    Write-Host "  Data: $($result.Data -join ', ')" -ForegroundColor Green
    Write-Host "  Kernel type: $($result.KernelType)" -ForegroundColor Green
    Write-Host "  Bandwidth: $($result.Bandwidth)" -ForegroundColor Green
    Write-Host "  Number of evaluation points: $($result.EvaluationPoints.Count)" -ForegroundColor Green
    Write-Host "  Number of density estimates: $($result.DensityEstimates.Count)" -ForegroundColor Green
    Write-Host "  Elapsed time: $($result.ElapsedTime.TotalSeconds) seconds" -ForegroundColor Green
    Write-Host "  Calculation time: $($result.CalculationTime.TotalSeconds) seconds" -ForegroundColor Green
    Write-Host "  Memory used: $($result.MemoryUsedMB) MB" -ForegroundColor Green

    # Check the log file
    if (Test-Path -Path $LogFilePath) {
        $logContent = Get-Content -Path $LogFilePath
        Write-Host "Log file content ($($logContent.Count) lines):" -ForegroundColor Yellow

        # Display the first 10 lines and the last 10 lines
        if ($logContent.Count -gt 20) {
            $logContent | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            Write-Host "  ..." -ForegroundColor Gray
            $logContent | Select-Object -Last 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        } else {
            $logContent | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        }
    }
}

# Function to test kernel density estimation with different kernel types
function Test-KDEWithKernelType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular", "Uniform")]
        [string]$KernelType,

        [Parameter(Mandatory = $true)]
        [string]$LogFilePath
    )

    Write-Host "Testing kernel density estimation with kernel type set to $KernelType" -ForegroundColor Cyan

    # Create some sample data
    $data = 1..10 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }

    # Clear the log file
    if (Test-Path -Path $LogFilePath) {
        Clear-Content -Path $LogFilePath
    } else {
        New-Item -Path $LogFilePath -ItemType File -Force | Out-Null
    }

    # Perform kernel density estimation with the specified kernel type
    $result = Get-KernelDensityEstimate -Data $data -KernelType $KernelType -LogLevel $KDELogLevelDebug -LogFilePath $LogFilePath -LogToFile:$true -IncludePerformanceMetrics

    # Display the results
    Write-Host "Kernel density estimation successful!" -ForegroundColor Green
    Write-Host "  Data: $($result.Data -join ', ')" -ForegroundColor Green
    Write-Host "  Kernel type: $($result.KernelType)" -ForegroundColor Green
    Write-Host "  Bandwidth: $($result.Bandwidth)" -ForegroundColor Green
    Write-Host "  Number of evaluation points: $($result.EvaluationPoints.Count)" -ForegroundColor Green
    Write-Host "  Number of density estimates: $($result.DensityEstimates.Count)" -ForegroundColor Green
    Write-Host "  Elapsed time: $($result.ElapsedTime.TotalSeconds) seconds" -ForegroundColor Green
    Write-Host "  Calculation time: $($result.CalculationTime.TotalSeconds) seconds" -ForegroundColor Green
    Write-Host "  Memory used: $($result.MemoryUsedMB) MB" -ForegroundColor Green

    # Check the log file
    if (Test-Path -Path $LogFilePath) {
        $logContent = Get-Content -Path $LogFilePath
        Write-Host "Log file content ($($logContent.Count) lines):" -ForegroundColor Yellow

        # Display the first 10 lines and the last 10 lines
        if ($logContent.Count -gt 20) {
            $logContent | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            Write-Host "  ..." -ForegroundColor Gray
            $logContent | Select-Object -Last 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        } else {
            $logContent | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        }
    }
}

# Function to test kernel density estimation with error handling
function Test-KDEWithError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFilePath
    )

    Write-Host "Testing kernel density estimation with error handling" -ForegroundColor Cyan

    # Create some invalid data
    $data = @(1, 2, "invalid", 4, 5)

    # Clear the log file
    if (Test-Path -Path $LogFilePath) {
        Clear-Content -Path $LogFilePath
    } else {
        New-Item -Path $LogFilePath -ItemType File -Force | Out-Null
    }

    # Perform kernel density estimation with the invalid data
    try {
        # This should fail because of the invalid data
        $null = Get-KernelDensityEstimate -Data $data -LogLevel $KDELogLevelDebug -LogFilePath $LogFilePath -LogToFile:$true

        Write-Host "This should not be reached" -ForegroundColor Red
    } catch {
        Write-Host "Error caught as expected: $($_.Exception.Message)" -ForegroundColor Green
    }

    # Check the log file
    if (Test-Path -Path $LogFilePath) {
        $logContent = Get-Content -Path $LogFilePath
        Write-Host "Log file content ($($logContent.Count) lines):" -ForegroundColor Yellow

        # Display the first 10 lines and the last 10 lines
        if ($logContent.Count -gt 20) {
            $logContent | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            Write-Host "  ..." -ForegroundColor Gray
            $logContent | Select-Object -Last 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        } else {
            $logContent | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        }
    }
}

# Main test script
try {
    Write-Host "Starting kernel density estimation with logging tests..." -ForegroundColor Green

    # Test with different log levels
    Write-Host "`nTesting kernel density estimation with different log levels..." -ForegroundColor Green

    # Test with Debug level
    Test-KDEWithLogLevel -LogLevel $KDELogLevelDebug -LogFilePath $tempLogFile

    # Test with different kernel types
    Write-Host "`nTesting kernel density estimation with different kernel types..." -ForegroundColor Green

    # Test with Gaussian kernel
    Test-KDEWithKernelType -KernelType "Gaussian" -LogFilePath $tempLogFile

    # Test with error handling
    Write-Host "`nTesting kernel density estimation with error handling..." -ForegroundColor Green
    Test-KDEWithError -LogFilePath $tempLogFile

    Write-Host "`nAll tests completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error during testing: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Clean up
    if (Test-Path -Path $tempLogFile) {
        Remove-Item -Path $tempLogFile -Force
    }
}
