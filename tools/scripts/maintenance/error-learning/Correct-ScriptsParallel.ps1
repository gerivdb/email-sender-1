<#
.SYNOPSIS
    Corrects multiple PowerShell scripts in parallel using efficient Runspace Pools.
.DESCRIPTION
    This script leverages PowerShell Runspace Pools for high-performance parallel processing
    of PowerShell script files (.ps1). It identifies common patterns (like hardcoded paths,
    missing error handling, Write-Host usage) and applies predefined corrections.
    Creates backups (.bak) before modifying files unless -WhatIf is used.
    Compatible with PowerShell 5.1 and later.
.PARAMETER ScriptPaths
    An array of paths to the PowerShell script files (.ps1) to be corrected.
    Relative paths are resolved based on the current working directory.
.PARAMETER MaxThreads
    The maximum number of concurrent threads (runspaces) to use for processing.
    Defaults to 5. Adjust based on your system's core count and workload.
.PARAMETER ErrorPatterns
    Optional. A custom array of hashtables defining error patterns and their corrections.
    If not provided, uses built-in defaults. Each hashtable should have:
    - Name (string): A unique name for the pattern.
    - Pattern (string): A RegEx pattern to search for in the script content.
    - Description (string): A user-friendly description of the issue.
    - Correction (scriptblock): A scriptblock that takes the matched line string as input
      and returns the corrected line string. Use param($Line) inside the scriptblock.
.EXAMPLE
    .\Correct-ScriptsParallel.ps1 -ScriptPaths ".\script1.ps1", ".\subdir\script2.ps1" -MaxThreads 8 -Verbose
.EXAMPLE
    Get-ChildItem -Path "C:\MyProject\Scripts" -Filter *.ps1 -Recurse | .\Correct-ScriptsParallel.ps1 -WhatIf
.EXAMPLE
    $customPatterns = @(
        @{
            Name = "OldCmdlet"
            Pattern = 'Resolve-DnsName' # Example: Find an old cmdlet
            Description = "Utilisation de Resolve-DnsName détectée"
            Correction = { param($Line) $Line -replace 'Resolve-DnsName', 'AlternativeCmdlet' }
        }
    )
    .\Correct-ScriptsParallel.ps1 -ScriptPaths ".\myscript.ps1" -ErrorPatterns $customPatterns
.NOTES
    Author: Augment Agent
    Version: 2.0 (Runspace Pool Implementation)
    Requires PowerShell 5.1 or higher.
    Ensure you have appropriate permissions to read/write the target script files.
    Review backups and changes carefully.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    [string[]]$ScriptPaths,

    [Parameter(Mandatory = $false)]
    [int]$MaxThreads = 5,

    [Parameter(Mandatory = $false)]
    [array]$ErrorPatterns
)

#region Default Error Patterns Definition
if ($null -eq $ErrorPatterns) {
    Write-Verbose "Using default error patterns."
    $ErrorPatterns = @(
        @{
            Name        = "HardcodedPath"
            # Improved regex: Looks for drive letter or UNC path, avoids escaped quotes. Handles single/double quotes.
            Pattern     = '(?<![\\])(["''])((?:[A-Za-z]:[\\/]|\\\\)[^''"]+)\1'
            Description = "Chemin absolu codé en dur détecté"
            Correction  = {
                param($Line)
                # Extract the matched path for potential smarter replacement later
                $match = [regex]::Match($Line, '(?<![\\])(["''])((?:[A-Za-z]:[\\/]|\\\\)[^''"]+)\1')
                if ($match.Success) {
                    $quote = $match.Groups[1].Value
                    $hardcodedPath = $match.Groups[2].Value
                    Write-Warning "Hardcoded path '$hardcodedPath' found on line. Replacing with placeholder."
                    # Simple placeholder replacement; more sophisticated logic could try to make it relative
                    return $Line -replace [regex]::Escape($match.Value), "$quote(Join-Path -Path `$PSScriptRoot -ChildPath ""CHEMIN_RELATIF_A_DETERMINER"")$quote"
                }
                return $Line # Should not happen if pattern matched, but safety first
            }
        },
        @{
            Name        = "PotentialNoErrorHandling"
            # Look for common IO/Web cmdlets without -ErrorAction explicitly set
            Pattern     = '(?<!try\s*\{\s*)(?<!\s*\|\s*catch\s*\{\s*)(?:\b(Get-Content|Set-Content|Copy-Item|Move-Item|Remove-Item|Invoke-WebRequest|Invoke-RestMethod))\b(?![^`n]*?-ErrorAction)'
            Description = "Gestion d'erreurs potentiellement manquante pour un cmdlet I/O ou Web"
            Correction  = {
                param($Line)
                # Append -ErrorAction Stop (or potentially SilentlyContinue based on context, but Stop is safer default)
                return $Line -replace '(\b(Get-Content|Set-Content|Copy-Item|Move-Item|Remove-Item|Invoke-WebRequest|Invoke-RestMethod)\b(?![^`n]*?-ErrorAction))', '$1 -ErrorAction Stop'
            }
        },
        @{
            Name        = "WriteHostForOutput"
            Pattern     = '\bWrite-Host\b'
            Description = "Utilisation de Write-Host détectée (préférer Write-Output pour les données, Write-Verbose/Information pour le statut)"
            Correction  = {
                param($Line)
                # Recommend specific alternative based on context would be ideal, but simple switch is often okay.
                # Consider adding -NoNewline if the original Write-Host had it.
                Write-Warning "Replacing Write-Host with Write-Output. Review if Write-Verbose/Warning/Information is more appropriate."
                return $Line -replace '\bWrite-Host\b', 'Write-Output'
            }
        }
        # Add more patterns here as needed
    )
}
#endregion

#region Input Validation and Path Resolution
Write-Verbose "Validating and resolving script paths..."
$resolvedPaths = @()
foreach ($path in $ScriptPaths) {
    try {
        $resolved = Resolve-Path -LiteralPath $path -ErrorAction Stop
        if ($resolved | Where-Object { $_.Provider.Name -eq 'FileSystem' -and $_.Path -like '*.ps1' }) {
            if (Test-Path -LiteralPath $resolved.ProviderPath -PathType Leaf) {
                $resolvedPaths += $resolved.ProviderPath
                Write-Verbose "Validated and added: $($resolved.ProviderPath)"
            } else {
                 Write-Warning "Path exists but is not a file: $($resolved.ProviderPath)"
            }
        } else {
            Write-Warning "Path is not a .ps1 file or not on the filesystem: $path"
        }
    }
    catch {
        Write-Warning "Cannot resolve or access path '$path'. Error: $($_.Exception.Message)"
    }
}

if ($resolvedPaths.Count -eq 0) {
    Write-Error "No valid PowerShell script files (.ps1) found to process."
    exit 1
}

$totalFiles = $resolvedPaths.Count
Write-Host "Preparing to correct $totalFiles script(s) using up to $MaxThreads threads..."
#endregion

#region The Core Script Correction Logic (to be run in each thread)
$scriptBlock = {
    param($scriptPath, $patternsToUse, $useWhatIf)

    $result = [PSCustomObject]@{
        ScriptPath        = $scriptPath
        Success           = $false
        IssuesFound       = 0
        CorrectionsMade   = 0
        CorrectionsSkipped = 0
        Errors            = @()
        HadModifications  = $false
        BackupPath        = ''
    }

    try {
        # Read lines for processing and full content for regex matching
        # Explicit UTF8. Consider detecting encoding if needed.
        Write-Verbose "[Thread $($[System.Threading.Thread]::CurrentThread.ManagedThreadId)] Processing: $scriptPath"
        $scriptLines = Get-Content -LiteralPath $scriptPath -Encoding UTF8 -ErrorAction Stop
        $scriptContent = $scriptLines -join "`n" # Rejoin with newline for multi-line regex context

        $detectedIssues = [System.Collections.Generic.List[object]]::new()

        # --- Issue Detection Phase ---
        foreach ($patternInfo in $patternsToUse) {
            try {
                $regex = [regex]::new($patternInfo.Pattern)
                $regexMatches = $regex.Matches($scriptContent)

                if ($regexMatches.Count -gt 0) {
                    foreach ($match in $regexMatches) {
                        # Find the line number more reliably
                        $charIndex = $match.Index
                        $lineNumber = 1
                        $currentPos = 0
                        for ($i = 0; $i -lt $scriptLines.Count; $i++) {
                            $lineLength = $scriptLines[$i].Length + 1 # +1 for the newline character
                            if ($charIndex -ge $currentPos -and $charIndex -lt ($currentPos + $lineLength)) {
                                $lineNumber = $i + 1
                                break
                            }
                            $currentPos += $lineLength
                        }

                        $issue = @{
                            Name         = $patternInfo.Name
                            Description  = $patternInfo.Description
                            LineNumber   = $lineNumber
                            Index        = $match.Index
                            Length       = $match.Length
                            OriginalLine = $scriptLines[$lineNumber - 1]
                            MatchedValue = $match.Value
                            CorrectionSB = $patternInfo.Correction # Pass the scriptblock itself
                        }
                        $detectedIssues.Add([PSCustomObject]$issue)
                        $result.IssuesFound++
                    }
                }
            }
            catch {
                $errMsg = "[Thread $($[System.Threading.Thread]::CurrentThread.ManagedThreadId)] Error matching pattern '$($patternInfo.Name)' in '$scriptPath': $($_.Exception.Message)"
                Write-Warning $errMsg
                $result.Errors += $errMsg
            }
        }

        # --- Correction Phase ---
        if ($detectedIssues.Count -gt 0) {
            # Sort issues by line number DESCENDING to avoid index shifting during modification
            $sortedIssues = $detectedIssues | Sort-Object -Property LineNumber -Descending

            # Create backup only if modifying and not -WhatIf
            if (-not $useWhatIf) {
                $result.BackupPath = "$scriptPath.bak"
                Write-Verbose "[Thread $($[System.Threading.Thread]::CurrentThread.ManagedThreadId)] Backing up '$scriptPath' to '$($result.BackupPath)'"
                Copy-Item -LiteralPath $scriptPath -Destination $result.BackupPath -Force -ErrorAction Stop
            } else {
                 Write-Host "[Thread $($[System.Threading.Thread]::CurrentThread.ManagedThreadId)] WhatIf: Skipping backup for '$scriptPath'"
            }

            # Create a copy of lines to modify
            $modifiedLines = $scriptLines.Clone()
            $linesModifiedInThisRun = $false

            foreach ($issue in $sortedIssues) {
                $lineIndex = $issue.LineNumber - 1
                # Use the potentially already modified line from $modifiedLines for subsequent fixes on the same line
                $currentLineContent = $modifiedLines[$lineIndex]

                try {
                    # Execute the correction scriptblock
                    $newLineContent = & $issue.CorrectionSB $currentLineContent

                    if ($currentLineContent -ne $newLineContent) {
                        if ($useWhatIf) {
                            Write-Host "[Thread $($[System.Threading.Thread]::CurrentThread.ManagedThreadId)] WhatIf: Apply correction '$($issue.Name)' to line $($issue.LineNumber) in '$scriptPath'"
                            Write-Host "[Thread $($[System.Threading.Thread]::CurrentThread.ManagedThreadId)]   < $($currentLineContent)"
                            Write-Host "[Thread $($[System.Threading.Thread]::CurrentThread.ManagedThreadId)]   > $($newLineContent)"
                            # Simulate change for counting purposes in WhatIf
                            $modifiedLines[$lineIndex] = $newLineContent
                            $result.CorrectionsMade++
                            $linesModifiedInThisRun = $true # Mark that a change *would* have happened
                        } else {
                            Write-Verbose "[Thread $($[System.Threading.Thread]::CurrentThread.ManagedThreadId)] Applying correction '$($issue.Name)' to line $($issue.LineNumber) in '$scriptPath'"
                            $modifiedLines[$lineIndex] = $newLineContent
                            $result.CorrectionsMade++
                            $linesModifiedInThisRun = $true
                        }
                    } else {
                         Write-Verbose "[Thread $($[System.Threading.Thread]::CurrentThread.ManagedThreadId)] Correction '$($issue.Name)' for line $($issue.LineNumber) resulted in no change."
                         $result.CorrectionsSkipped++
                    }
                }
                catch {
                    $errMsg = "[Thread $($[System.Threading.Thread]::CurrentThread.ManagedThreadId)] Error applying correction '$($issue.Name)' to line $($issue.LineNumber) in '$scriptPath': $($_.Exception.Message)"
                    Write-Warning $errMsg
                    $result.Errors += $errMsg
                    $result.CorrectionsSkipped++
                }
            } # End foreach issue

            # Save the modified script if changes were made and not -WhatIf
            if ($linesModifiedInThisRun -and (-not $useWhatIf)) {
                Write-Verbose "[Thread $($[System.Threading.Thread]::CurrentThread.ManagedThreadId)] Saving corrected file: $scriptPath"
                # Use Out-File with explicit encoding
                $modifiedLines | Out-File -LiteralPath $scriptPath -Encoding UTF8 -Force -ErrorAction Stop
                $result.HadModifications = $true
            } elseif ($linesModifiedInThisRun -and $useWhatIf) {
                 $result.HadModifications = $true # Indicate changes *would* have been saved
            }

        } else {
             Write-Verbose "[Thread $($[System.Threading.Thread]::CurrentThread.ManagedThreadId)] No issues detected needing correction in '$scriptPath'."
        }

        $result.Success = $true # Mark as success if no exceptions were thrown at this level

    } catch {
        $errMsg = "[Thread $($[System.Threading.Thread]::CurrentThread.ManagedThreadId)] Failed to process '$scriptPath': $($_.Exception.Message) at line $($_.InvocationInfo.ScriptLineNumber)"
        Write-Error $errMsg # Use Write-Error here as it's a failure for the whole file
        $result.Errors += $errMsg
        $result.Success = $false
    }

    # Return the detailed result object
    return $result
}
#endregion

#region Runspace Pool Setup and Execution
$startTime = Get-Date
Write-Verbose "Setting up Runspace Pool with $MaxThreads threads."

# Initial Session State allows defining variables, modules etc. available to all threads
$iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
# Example: If you needed functions/variables available in all runspaces:
# $iss.Variables.Add((New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry('SharedVariable', $someValue, 'Constant')))
# $iss.ImportPSModule(@('MyRequiredModule')) # If ErrorLearningSystem *was* needed

# Create and open the pool
$runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxThreads, $iss, $Host)
$runspacePool.Open()

$tasks = [System.Collections.Generic.List[hashtable]]::new()
$allResults = [System.Collections.Generic.List[object]]::new()

$filesProcessed = 0

Write-Host "Starting parallel processing..."

# Submit tasks
foreach ($filePath in $resolvedPaths) {
    # Create a PowerShell instance for the task
    $psInstance = [powershell]::Create().AddScript($scriptBlock).AddParameters(@{
        scriptPath   = $filePath
        patternsToUse = $ErrorPatterns # Pass the patterns array
        useWhatIf    = $PSCmdlet.ShouldProcess($filePath, "Correct Script") # Evaluate ShouldProcess *here*
    })

    # Associate with the pool
    $psInstance.RunspacePool = $runspacePool

    # BeginInvoke returns an IAsyncResult (handle)
    $asyncHandle = $psInstance.BeginInvoke()

    # Store the handle and the PS instance together
    $tasks.Add(@{
        Handle     = $asyncHandle
        Instance   = $psInstance
        ScriptPath = $filePath # Keep path for context
    })

    Write-Verbose "Submitted task for: $filePath"

    # Throttle submission slightly if pool is very busy (optional, helps prevent overwhelming system resources)
    while ($runspacePool.GetAvailableRunspaces() -eq 0) {
        Start-Sleep -Milliseconds 100
    }
}

# Wait for and collect results
$totalTasks = $tasks.Count
while ($tasks.Count -gt 0) {
    # Wait for *any* task to complete
    $completedIndex = [System.Threading.WaitHandle]::WaitAny($tasks.Handle, [timespan]::FromSeconds(1)) # Timeout helps keep UI responsive

    if ($completedIndex -ne [System.Threading.WaitHandle]::WaitTimeout) {
        $completedTask = $tasks[$completedIndex]
        $psInstance = $completedTask.Instance
        $handle = $completedTask.Handle

        try {
            # EndInvoke gets the result(s) and re-throws exceptions from the runspace
            $taskResult = $psInstance.EndInvoke($handle)
            if ($null -ne $taskResult) {
                $allResults.Add($taskResult)
            } else {
                # Task might have failed catastrophically before returning result object
                 $allResults.Add([PSCustomObject]@{
                    ScriptPath = $completedTask.ScriptPath
                    Success = $false
                    Errors = @("Task completed but returned null result, likely due to unhandled exception.")
                 })
            }
             $filesProcessed++
        }
        catch {
            # Catch exceptions thrown by EndInvoke (errors from the scriptblock)
            Write-Warning "Exception collecting result for '$($completedTask.ScriptPath)': $($_.Exception.Message)"
             $allResults.Add([PSCustomObject]@{
                ScriptPath = $completedTask.ScriptPath
                Success    = $false
                Errors     = @("Error during EndInvoke: $($_.Exception.ToString())") # Capture full exception
            })
             $filesProcessed++ # Count as processed even if failed
        }
        finally {
            # Clean up the PowerShell instance and remove from tracking list
            $psInstance.Dispose()
            $tasks.RemoveAt($completedIndex)
        }
    }

    # Update Progress
    $remaining = $tasks.Count
    Write-Progress -Activity "Correcting Scripts in Parallel" -Status "Processing... ($($filesProcessed)/$totalTasks completed, $remaining pending)" -PercentComplete (($filesProcessed / $totalTasks) * 100)

} # End while tasks remain

Write-Progress -Activity "Correcting Scripts in Parallel" -Completed
Write-Host "All tasks completed."

#endregion

#region Cleanup and Summary Reporting
Write-Verbose "Closing Runspace Pool..."
$runspacePool.Close()
$runspacePool.Dispose()
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n--- Correction Summary ---"
Write-Host "Processed $($allResults.Count) / $totalFiles files."
Write-Host "Duration: $($duration.ToString('g'))"

$successfulRuns = $allResults | Where-Object { $_.Success }
$failedRuns = $allResults | Where-Object { -not $_.Success }
$modifiedFiles = $allResults | Where-Object { $_.HadModifications }

$totalIssues = ($allResults | Measure-Object -Property IssuesFound -Sum).Sum
$totalCorrectionsMade = ($allResults | Measure-Object -Property CorrectionsMade -Sum).Sum
$totalCorrectionsSkipped = ($allResults | Measure-Object -Property CorrectionsSkipped -Sum).Sum

Write-Host "Successful runs: $($successfulRuns.Count)"
Write-Host "Failed runs: $($failedRuns.Count)"
Write-Host "Files with changes applied (or WhatIf): $($modifiedFiles.Count)"
Write-Host "Total issues detected: $totalIssues"
Write-Host "Total corrections applied (or WhatIf): $totalCorrectionsMade"
Write-Host "Total corrections skipped (no change or error): $totalCorrectionsSkipped"

if ($failedRuns.Count -gt 0) {
    Write-Warning "`nFailures occurred during processing:"
    $failedRuns | ForEach-Object {
        Write-Warning "- $($_.ScriptPath):"
        $_.Errors | ForEach-Object { Write-Warning "  - $_" }
    }
}

# Optionally list modified files
if ($VerbosePreference -eq 'Continue' -and $modifiedFiles.Count -gt 0) {
     Write-Verbose "`nFiles potentially modified:"
     $modifiedFiles.ScriptPath | Out-String | Write-Verbose
}

Write-Host "`nProcessing finished."
#endregion
