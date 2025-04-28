<#
.SYNOPSIS
    Tests the performance of different parallel processing approaches.
.DESCRIPTION
    This script creates test files and compares the performance of sequential processing,
    Jobs PowerShell, and Runspace Pools for script analysis and correction.
.PARAMETER TestFileCount
    The number of test files to create for the performance test.
.PARAMETER TestIterations
    The number of iterations to run for each approach to get more accurate timing.
.EXAMPLE
    .\Test-ParallelPerformance.ps1 -TestFileCount 20 -TestIterations 3
    Creates 20 test files and runs 3 iterations of each approach.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Requires PowerShell 5.1 or higher.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [int]$TestFileCount = 10,

    [Parameter(Mandatory = $false)]
    [int]$TestIterations = 2
)

# Create a temporary directory for test files
$testDir = Join-Path -Path $env:TEMP -ChildPath "ParallelPerformanceTest_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

Write-Host "Creating $TestFileCount test files in $testDir..."

# Create test files with known issues
for ($i = 1; $i -le $TestFileCount; $i++) {
    $filePath = Join-Path -Path $testDir -ChildPath "TestScript$i.ps1"

    # Create a script with various issues to detect and correct
    $scriptContent = @"
# Test script $i with various issues

# Hardcoded paths
`$logPath = "C:\Logs\application$i.log"
`$configPath = "D:\Config\settings$i.xml"

# Missing error handling
`$content = Get-Content -Path `$logPath
`$config = Get-Content -Path `$configPath

# Write-Host usage
Write-Host "Processing file `$logPath..."
Write-Host "Configuration loaded from `$configPath"

# Function with hardcoded paths and missing error handling
function Process-Data {
    param(`$inputFile)

    `$outputPath = "E:\Output\processed$i.csv"
    `$data = Get-Content -Path `$inputFile
    Set-Content -Path `$outputPath -Value `$data
    Write-Host "Data processed and saved to `$outputPath"
}

# Call the function
Process-Data -inputFile "C:\Data\input$i.txt"
"@

    Set-Content -Path $filePath -Value $scriptContent -Force
}

Write-Host "Test files created successfully."

# Define the error patterns for testing
$errorPatterns = @(
    @{
        Name        = "HardcodedPath"
        Pattern     = '(?<![\\])(["''])((?:[A-Za-z]:[\\/]|\\\\)[^''"]+)\1'
        Description = "Chemin absolu codÃ© en dur dÃ©tectÃ©"
        Correction  = {
            param($Line)
            $match = [regex]::Match($Line, '(?<![\\])(["''])((?:[A-Za-z]:[\\/]|\\\\)[^''"]+)\1')
            if ($match.Success) {
                $quote = $match.Groups[1].Value
                return $Line -replace [regex]::Escape($match.Value), "$quote(Join-Path -Path `$PSScriptRoot -ChildPath ""CHEMIN_RELATIF"")$quote"
            }
            return $Line
        }
    },
    @{
        Name        = "NoErrorHandling"
        Pattern     = '(?<!try\s*\{\s*)(?<!\s*\|\s*catch\s*\{\s*)(?:\b(Get-Content|Set-Content))\b(?![^`n]*?-ErrorAction)'
        Description = "Gestion d'erreurs manquante"
        Correction  = {
            param($Line)
            return $Line -replace '(\b(Get-Content|Set-Content)\b(?![^`n]*?-ErrorAction))', '$1 -ErrorAction Stop'
        }
    },
    @{
        Name        = "WriteHostUsage"
        Pattern     = '\bWrite-Host\b'
        Description = "Utilisation de Write-Host dÃ©tectÃ©e"
        Correction  = {
            param($Line)
            return $Line -replace '\bWrite-Host\b', 'Write-Output'
        }
    }
)

# Get all test files
$testFiles = Get-ChildItem -Path $testDir -Filter "*.ps1" | Select-Object -ExpandProperty FullName

# Function to test sequential processing
function Test-SequentialProcessing {
    param($files, $patterns)

    $results = @()

    foreach ($file in $files) {
        $result = @{
            FilePath = $file
            IssuesFound = 0
            CorrectionsMade = 0
        }

        # Read the file
        $content = Get-Content -Path $file -Raw
        $lines = Get-Content -Path $file

        # Detect issues
        foreach ($pattern in $patterns) {
            $regexMatches = [regex]::Matches($content, $pattern.Pattern)
            $result.IssuesFound += $regexMatches.Count

            # Simulate corrections (don't actually modify files)
            foreach ($match in $regexMatches) {
                $lineNumber = ($content.Substring(0, $match.Index).Split("`n")).Length
                $lineIndex = $lineNumber - 1
                $line = $lines[$lineIndex]

                try {
                    $newLine = & $pattern.Correction $line
                    if ($line -ne $newLine) {
                        $result.CorrectionsMade++
                    }
                }
                catch {
                    # Ignore errors in this test
                }
            }
        }

        $results += [PSCustomObject]$result
    }

    return $results
}

# Function to test Jobs PowerShell processing
function Test-JobsProcessing {
    param($files, $patterns)

    $jobs = @()
    $results = @()

    # Create a script block for the job
    $scriptBlock = {
        param($file, $patterns)

        $result = @{
            FilePath = $file
            IssuesFound = 0
            CorrectionsMade = 0
        }

        # Read the file
        $content = Get-Content -Path $file -Raw
        $lines = Get-Content -Path $file

        # Detect issues
        foreach ($pattern in $patterns) {
            $regexMatches = [regex]::Matches($content, $pattern.Pattern)
            $result.IssuesFound += $regexMatches.Count

            # Simulate corrections (don't actually modify files)
            foreach ($match in $regexMatches) {
                $lineNumber = ($content.Substring(0, $match.Index).Split("`n")).Length
                $lineIndex = $lineNumber - 1
                $line = $lines[$lineIndex]

                try {
                    $newLine = & $pattern.Correction $line
                    if ($line -ne $newLine) {
                        $result.CorrectionsMade++
                    }
                }
                catch {
                    # Ignore errors in this test
                }
            }
        }

        return [PSCustomObject]$result
    }

    # Start jobs
    foreach ($file in $files) {
        $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $file, $patterns
        $jobs += $job
    }

    # Wait for all jobs to complete
    $jobs | Wait-Job | Out-Null

    # Get results
    foreach ($job in $jobs) {
        $jobResult = Receive-Job -Job $job
        $results += $jobResult
        Remove-Job -Job $job
    }

    return $results
}

# Function to test Runspace Pool processing
function Test-RunspacePoolProcessing {
    param($files, $patterns, $maxThreads = 5)

    # Create and open the runspace pool
    $runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $maxThreads)
    $runspacePool.Open()

    $scriptBlock = {
        param($file, $patterns)

        $result = @{
            FilePath = $file
            IssuesFound = 0
            CorrectionsMade = 0
        }

        # Read the file
        $content = Get-Content -Path $file -Raw
        $lines = Get-Content -Path $file

        # Detect issues
        foreach ($pattern in $patterns) {
            $regexMatches = [regex]::Matches($content, $pattern.Pattern)
            $result.IssuesFound += $regexMatches.Count

            # Simulate corrections (don't actually modify files)
            foreach ($match in $regexMatches) {
                $lineNumber = ($content.Substring(0, $match.Index).Split("`n")).Length
                $lineIndex = $lineNumber - 1
                $line = $lines[$lineIndex]

                try {
                    $newLine = & $pattern.Correction $line
                    if ($line -ne $newLine) {
                        $result.CorrectionsMade++
                    }
                }
                catch {
                    # Ignore errors in this test
                }
            }
        }

        return [PSCustomObject]$result
    }

    # Create runspaces
    $runspaces = @()
    foreach ($file in $files) {
        $powershell = [powershell]::Create().AddScript($scriptBlock).AddParameters(@{
            file = $file
            patterns = $patterns
        })
        $powershell.RunspacePool = $runspacePool

        $runspaces += @{
            PowerShell = $powershell
            Handle = $powershell.BeginInvoke()
        }
    }

    # Wait for all runspaces to complete
    $results = @()
    foreach ($runspace in $runspaces) {
        $results += $runspace.PowerShell.EndInvoke($runspace.Handle)
        $runspace.PowerShell.Dispose()
    }

    # Close the runspace pool
    $runspacePool.Close()
    $runspacePool.Dispose()

    return $results
}

# Run performance tests
$results = @()

Write-Host "`nRunning performance tests..."

for ($i = 1; $i -le $TestIterations; $i++) {
    Write-Host "`nIteration $i of $TestIterations"

    # Test sequential processing
    Write-Host "Testing sequential processing..."
    $startTime = Get-Date
    $sequentialResults = Test-SequentialProcessing -files $testFiles -patterns $errorPatterns
    $endTime = Get-Date
    $sequentialDuration = ($endTime - $startTime).TotalSeconds

    $results += [PSCustomObject]@{
        Iteration = $i
        Approach = "Sequential"
        Duration = $sequentialDuration
        FilesProcessed = $sequentialResults.Count
        IssuesFound = ($sequentialResults | Measure-Object -Property IssuesFound -Sum).Sum
        CorrectionsMade = ($sequentialResults | Measure-Object -Property CorrectionsMade -Sum).Sum
    }

    Write-Host "Sequential processing completed in $sequentialDuration seconds."

    # Test Jobs PowerShell processing
    Write-Host "Testing Jobs PowerShell processing..."
    $startTime = Get-Date
    $jobsResults = Test-JobsProcessing -files $testFiles -patterns $errorPatterns
    $endTime = Get-Date
    $jobsDuration = ($endTime - $startTime).TotalSeconds

    $results += [PSCustomObject]@{
        Iteration = $i
        Approach = "Jobs"
        Duration = $jobsDuration
        FilesProcessed = $jobsResults.Count
        IssuesFound = ($jobsResults | Measure-Object -Property IssuesFound -Sum).Sum
        CorrectionsMade = ($jobsResults | Measure-Object -Property CorrectionsMade -Sum).Sum
    }

    Write-Host "Jobs PowerShell processing completed in $jobsDuration seconds."

    # Test Runspace Pool processing
    Write-Host "Testing Runspace Pool processing..."
    $startTime = Get-Date
    $runspaceResults = Test-RunspacePoolProcessing -files $testFiles -patterns $errorPatterns -maxThreads 5
    $endTime = Get-Date
    $runspaceDuration = ($endTime - $startTime).TotalSeconds

    $results += [PSCustomObject]@{
        Iteration = $i
        Approach = "RunspacePool"
        Duration = $runspaceDuration
        FilesProcessed = $runspaceResults.Count
        IssuesFound = ($runspaceResults | Measure-Object -Property IssuesFound -Sum).Sum
        CorrectionsMade = ($runspaceResults | Measure-Object -Property CorrectionsMade -Sum).Sum
    }

    Write-Host "Runspace Pool processing completed in $runspaceDuration seconds."
}

# Calculate average durations
$averages = $results | Group-Object -Property Approach | ForEach-Object {
    $approach = $_.Name
    $avgDuration = ($_.Group | Measure-Object -Property Duration -Average).Average
    $speedup = ($results | Where-Object { $_.Approach -eq "Sequential" -and $_.Iteration -eq 1 }).Duration / $avgDuration

    [PSCustomObject]@{
        Approach = $approach
        AverageDuration = $avgDuration
        SpeedupFactor = $speedup
        FilesProcessed = $TestFileCount
        IssuesFound = ($_.Group | Where-Object { $_.Iteration -eq 1 }).IssuesFound
        CorrectionsMade = ($_.Group | Where-Object { $_.Iteration -eq 1 }).CorrectionsMade
    }
}

# Display results
Write-Host "`n--- Performance Test Results ---"
Write-Host "Test Configuration: $TestFileCount files, $TestIterations iterations"

$averages | Format-Table -Property Approach, @{
    Label = "Avg Duration (s)"
    Expression = { [math]::Round($_.AverageDuration, 2) }
}, @{
    Label = "Speedup vs Sequential"
    Expression = { [math]::Round($_.SpeedupFactor, 2) }
}, FilesProcessed, IssuesFound, CorrectionsMade

# Clean up test files
Write-Host "`nCleaning up test files..."
Remove-Item -Path $testDir -Recurse -Force

Write-Host "Performance test completed."
