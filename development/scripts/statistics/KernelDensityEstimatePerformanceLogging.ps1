# KernelDensityEstimatePerformanceLogging.ps1
# Performance logging functions for kernel density estimation

# Import the simple logging module
. .\KernelDensityEstimateSimpleLogging.ps1

# Function to start performance measurement
function Start-PerformanceMeasurement {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OperationName = "Operation",
        
        [Parameter(Mandatory = $false)]
        [switch]$MeasureMemory = $true
    )
    
    # Get the start time
    $startTime = Get-Date
    
    # Get the initial memory usage
    $initialMemory = $null
    if ($MeasureMemory) {
        $initialMemory = [System.GC]::GetTotalMemory($true)
    }
    
    # Create the performance measurement object
    $performanceMeasurement = [PSCustomObject]@{
        OperationName = $OperationName
        StartTime = $startTime
        EndTime = $null
        ElapsedTime = $null
        InitialMemory = $initialMemory
        FinalMemory = $null
        MemoryUsed = $null
        MeasureMemory = $MeasureMemory
        Checkpoints = @()
    }
    
    # Log the start of the performance measurement
    Write-InfoLog "Starting performance measurement for '$OperationName'"
    
    return $performanceMeasurement
}

# Function to add a checkpoint to a performance measurement
function Add-PerformanceCheckpoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PerformanceMeasurement,
        
        [Parameter(Mandatory = $true)]
        [string]$CheckpointName
    )
    
    # Get the checkpoint time
    $checkpointTime = Get-Date
    
    # Calculate the elapsed time since the start
    $elapsedTime = $checkpointTime - $PerformanceMeasurement.StartTime
    
    # Get the memory usage at the checkpoint
    $checkpointMemory = $null
    if ($PerformanceMeasurement.MeasureMemory) {
        $checkpointMemory = [System.GC]::GetTotalMemory($true)
    }
    
    # Create the checkpoint object
    $checkpoint = [PSCustomObject]@{
        CheckpointName = $CheckpointName
        CheckpointTime = $checkpointTime
        ElapsedTime = $elapsedTime
        Memory = $checkpointMemory
    }
    
    # Add the checkpoint to the performance measurement
    $PerformanceMeasurement.Checkpoints += $checkpoint
    
    # Log the checkpoint
    Write-DebugLog "Performance checkpoint '$CheckpointName' for '$($PerformanceMeasurement.OperationName)': $($elapsedTime.TotalSeconds) seconds"
    
    return $checkpoint
}

# Function to stop performance measurement
function Stop-PerformanceMeasurement {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PerformanceMeasurement
    )
    
    # Get the end time
    $endTime = Get-Date
    
    # Calculate the elapsed time
    $elapsedTime = $endTime - $PerformanceMeasurement.StartTime
    
    # Get the final memory usage
    $finalMemory = $null
    $memoryUsed = $null
    if ($PerformanceMeasurement.MeasureMemory) {
        $finalMemory = [System.GC]::GetTotalMemory($true)
        $memoryUsed = $finalMemory - $PerformanceMeasurement.InitialMemory
    }
    
    # Update the performance measurement object
    $PerformanceMeasurement.EndTime = $endTime
    $PerformanceMeasurement.ElapsedTime = $elapsedTime
    $PerformanceMeasurement.FinalMemory = $finalMemory
    $PerformanceMeasurement.MemoryUsed = $memoryUsed
    
    # Log the end of the performance measurement
    Write-InfoLog "Performance measurement for '$($PerformanceMeasurement.OperationName)' completed in $($elapsedTime.TotalSeconds) seconds"
    if ($PerformanceMeasurement.MeasureMemory) {
        Write-DebugLog "Memory used for '$($PerformanceMeasurement.OperationName)': $($memoryUsed / 1MB) MB"
    }
    
    return $PerformanceMeasurement
}

# Function to format a performance measurement as a string
function Format-PerformanceMeasurement {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PerformanceMeasurement,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeCheckpoints = $true
    )
    
    # Create the formatted string
    $formattedString = "Performance measurement for '$($PerformanceMeasurement.OperationName)':`n"
    $formattedString += "  Start time: $($PerformanceMeasurement.StartTime)`n"
    $formattedString += "  End time: $($PerformanceMeasurement.EndTime)`n"
    $formattedString += "  Elapsed time: $($PerformanceMeasurement.ElapsedTime.TotalSeconds) seconds`n"
    
    if ($PerformanceMeasurement.MeasureMemory) {
        $formattedString += "  Initial memory: $($PerformanceMeasurement.InitialMemory / 1MB) MB`n"
        $formattedString += "  Final memory: $($PerformanceMeasurement.FinalMemory / 1MB) MB`n"
        $formattedString += "  Memory used: $($PerformanceMeasurement.MemoryUsed / 1MB) MB`n"
    }
    
    if ($IncludeCheckpoints -and $PerformanceMeasurement.Checkpoints.Count -gt 0) {
        $formattedString += "  Checkpoints:`n"
        foreach ($checkpoint in $PerformanceMeasurement.Checkpoints) {
            $formattedString += "    $($checkpoint.CheckpointName): $($checkpoint.ElapsedTime.TotalSeconds) seconds"
            if ($PerformanceMeasurement.MeasureMemory) {
                $formattedString += ", $($checkpoint.Memory / 1MB) MB"
            }
            $formattedString += "`n"
        }
    }
    
    return $formattedString
}

# Function to measure the performance of a script block
function Measure-ScriptBlockPerformance {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [string]$OperationName = "ScriptBlock",
        
        [Parameter(Mandatory = $false)]
        [switch]$MeasureMemory = $true
    )
    
    # Start performance measurement
    $performanceMeasurement = Start-PerformanceMeasurement -OperationName $OperationName -MeasureMemory:$MeasureMemory
    
    # Execute the script block
    try {
        $result = & $ScriptBlock
    } catch {
        # Stop performance measurement
        Stop-PerformanceMeasurement -PerformanceMeasurement $performanceMeasurement | Out-Null
        
        # Re-throw the exception
        throw
    }
    
    # Stop performance measurement
    $performanceMeasurement = Stop-PerformanceMeasurement -PerformanceMeasurement $performanceMeasurement
    
    # Create the result object
    $resultObject = [PSCustomObject]@{
        Result = $result
        Performance = $performanceMeasurement
    }
    
    return $resultObject
}

# Function to create a performance report
function New-PerformanceReport {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$PerformanceMeasurements,
        
        [Parameter(Mandatory = $false)]
        [string]$ReportName = "Performance Report",
        
        [Parameter(Mandatory = $false)]
        [string]$ReportFilePath = $null
    )
    
    # Create the report object
    $report = [PSCustomObject]@{
        ReportName = $ReportName
        ReportTime = Get-Date
        PerformanceMeasurements = $PerformanceMeasurements
    }
    
    # Format the report as a string
    $reportString = "Performance Report: $ReportName`n"
    $reportString += "Report Time: $($report.ReportTime)`n"
    $reportString += "Number of Performance Measurements: $($PerformanceMeasurements.Count)`n`n"
    
    foreach ($measurement in $PerformanceMeasurements) {
        $reportString += Format-PerformanceMeasurement -PerformanceMeasurement $measurement -IncludeCheckpoints
        $reportString += "`n"
    }
    
    # Write the report to a file if a file path is provided
    if ($ReportFilePath) {
        try {
            # Create the report file directory if it doesn't exist
            $reportDir = Split-Path -Path $ReportFilePath -Parent
            if (-not [string]::IsNullOrEmpty($reportDir) -and -not (Test-Path -Path $reportDir)) {
                New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
            }
            
            # Write the report to the file
            Set-Content -Path $ReportFilePath -Value $reportString -Encoding UTF8
            
            Write-InfoLog "Performance report written to '$ReportFilePath'"
        } catch {
            Write-ErrorLog "Failed to write performance report to '$ReportFilePath': $($_.Exception.Message)"
        }
    }
    
    # Add the report string to the report object
    $report | Add-Member -MemberType NoteProperty -Name "ReportString" -Value $reportString
    
    return $report
}
