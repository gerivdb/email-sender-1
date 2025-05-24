#Requires -Version 5.1

<#
.SYNOPSIS
    Simple PowerShell Function Name Validator and Corrector.

.DESCRIPTION
    Validates and corrects PowerShell function names for approved verb compliance.

.PARAMETER Path
    Root path to analyze.

.PARAMETER Fix
    Apply corrections.

.PARAMETER DryRun  
    Show changes without applying them.
#>

param(
    [string]$Path = ".",
    [switch]$Fix,
    [switch]$DryRun
)

# Approved verbs and mappings
$ApprovedVerbs = @(
    'Add', 'Clear', 'Close', 'Copy', 'Enter', 'Exit', 'Find', 'Format', 'Get', 'Hide', 'Join', 'Lock', 'Move', 'New', 'Open', 'Optimize', 'Pop', 'Push', 'Redo', 'Remove', 'Rename', 'Reset', 'Resize', 'Search', 'Select', 'Set', 'Show', 'Skip', 'Sort', 'Split', 'Step', 'Switch', 'Undo', 'Unlock', 'Watch',
    'Backup', 'Checkpoint', 'Compare', 'Compress', 'Convert', 'ConvertFrom', 'ConvertTo', 'Dismount', 'Edit', 'Expand', 'Export', 'Group', 'Import', 'Initialize', 'Limit', 'Merge', 'Mount', 'Out', 'Publish', 'Restore', 'Save', 'Sync', 'Unpublish', 'Update',
    'Approve', 'Assert', 'Complete', 'Confirm', 'Deny', 'Disable', 'Enable', 'Install', 'Invoke', 'Register', 'Request', 'Restart', 'Resume', 'Start', 'Stop', 'Submit', 'Suspend', 'Uninstall', 'Unregister', 'Wait',
    'Debug', 'Measure', 'Ping', 'Repair', 'Resolve', 'Test', 'Trace',
    'Connect', 'Disconnect', 'Read', 'Receive', 'Send', 'Write',
    'Block', 'Grant', 'Protect', 'Revoke', 'Unblock', 'Unprotect'
)

$VerbMappings = @{
    'Analyze'       = 'Test'
    'Check'         = 'Test'
    'Create'        = 'New'
    'Extract'       = 'Export'
    'Fix'           = 'Repair'
    'Generate'      = 'New'
    'Manage'        = 'Set'
    'Process'       = 'Invoke'
    'Pull'          = 'Get'
    'Release'       = 'Publish'
    'Clone'         = 'Copy'
    'Detect'        = 'Find'
    'Handle'        = 'Invoke'
    'Run'           = 'Start'
    'Execute'       = 'Invoke'
    'Build'         = 'New'
    'Save'          = 'Export'
    'Load'          = 'Import'
    'Delete'        = 'Remove'
    'Navigate'      = 'Move'
    'Query'         = 'Get'
    'Fetch'         = 'Get'
    'Collect'       = 'Get'
    'Ensure'        = 'Confirm'
    'Apply'         = 'Set'
    'Configure'     = 'Set'
    'Setup'         = 'Initialize'
    'Validate'      = 'Test'
    'Verify'        = 'Confirm'
    # Additional mappings for common violations
    'Filter'        = 'Select'
    'Normalize'     = 'ConvertTo'
    'Transform'     = 'ConvertTo'
    'Parse'         = 'ConvertFrom'
    'Calculate'     = 'Measure'
    'Organize'      = 'Set'
    'Replace'       = 'Set'
    'Inspect'       = 'Test'
    'Evaluate'      = 'Test'
    'Count'         = 'Measure'
    'Example'       = 'Show'
    'Cleanup'       = 'Clear'
    'Archive'       = 'Compress'
    'Identify'      = 'Find'
    'Compile'       = 'New'
    'Define'        = 'Set'
    'Rank'          = 'Sort'
    'Document'      = 'Write'
    'Rerun'         = 'Restart'
    'Rebuild'       = 'Update'
    'Log'           = 'Write'
    'Modify'        = 'Set'
    'Mock'          = 'New'
    'Capture'       = 'Get'
    'Demo'          = 'Show'
    'Learn'         = 'Get'
    'Inner'         = 'Get'
    'Commit'        = 'Submit'
    'Unused'        = 'Get'
    'Record'        = 'Write'
    'Standardize'   = 'ConvertTo'
    'Substitute'    = 'Set'
    'Improve'       = 'Update'
    'Implement'     = 'Install'
    'Should'        = 'Test'
    'Migrate'       = 'Move'
    'Clean'         = 'Clear'
    'Reorganize'    = 'Set'
    'Rotate'        = 'Move'
    'Draw'          = 'Show'
    'Index'         = 'Add'
    'Use'           = 'Invoke'
    'List'          = 'Get'
    'Discover'      = 'Find'
    'Subscribe'     = 'Register'
    'Unsubscribe'   = 'Unregister'
    'DFS'           = 'Find'
    'Tarjan'        = 'Find'
    'Introduce'     = 'Add'
    'Increment'     = 'Add'
    'Access'        = 'Get'
    'Iterate'       = 'Invoke'
    'Demonstrate'   = 'Show'
    'Simulate'      = 'Test'
    'Shorten'       = 'Limit'
    'Helper'        = 'Get'
    'Throw'         = 'Write'
    'Infer'         = 'Get'
    'Rechercher'    = 'Search'
    'Afficher'      = 'Show'
    'Retry'         = 'Restart'
    'Monitor'       = 'Watch'
    'Schedule'      = 'Register'
    'Recalculate'   = 'Update'
    'Truncate'      = 'Limit'
    'Share'         = 'Publish'
    'Integrate'     = 'Add'
    'Track'         = 'Trace'
    'Activate'      = 'Enable'
    'Propagate'     = 'Copy'
    'Plan'          = 'New'
    'Determine'     = 'Find'
    'mcp'           = 'Invoke'
    'auto'          = 'Start'
    'Assign'        = 'Set'
    'Categorize'    = 'Group'
    'Estimate'      = 'Measure'
    'Mark'          = 'Set'
    'Internal'      = 'Get'
    'Traverse'      = 'Search'
}

function Find-PowerShellFiles {
    param([string]$SearchPath)
    
    Write-Host "Scanning for PowerShell files in: $SearchPath" -ForegroundColor Cyan
    
    $files = Get-ChildItem -Path $SearchPath -Recurse -Include "*.ps1", "*.psm1" -File |
        Where-Object { 
            $_.FullName -notlike "*\.git\*" -and 
            $_.FullName -notlike "*\node_modules\*"
        }
    
    Write-Host "Found $($files.Count) PowerShell files" -ForegroundColor Green
    return $files
}

function Find-FunctionIssues {
    param([string]$FilePath)
    
    $issues = @()
    
    try {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        $lines = $content -split "`n"
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            $lineNumber = $i + 1
            
            if ($line -match '^\s*function\s+([A-Za-z0-9_-]+)') {
                $functionName = $Matches[1]
                
                if ($functionName -match '^([A-Za-z]+)-([A-Za-z0-9]+)$') {
                    $verb = $Matches[1]
                    $noun = $Matches[2]
                    
                    if ($verb -notin $ApprovedVerbs) {
                        $suggestedVerb = $VerbMappings[$verb]
                        $issues += [PSCustomObject]@{
                            File = $FilePath
                            LineNumber = $lineNumber
                            FunctionName = $functionName
                            Verb = $verb
                            Noun = $noun
                            Issue = "Unapproved verb: $verb"
                            SuggestedVerb = $suggestedVerb
                            SuggestedFunction = if ($suggestedVerb) { "$suggestedVerb-$noun" } else { $null }
                            Severity = "Error"
                        }
                    }
                } else {
                    $issues += [PSCustomObject]@{
                        File = $FilePath
                        LineNumber = $lineNumber
                        FunctionName = $functionName
                        Verb = $null
                        Noun = $null
                        Issue = "Invalid naming format (should be Verb-Noun)"
                        SuggestedVerb = $null
                        SuggestedFunction = $null
                        Severity = "Warning"
                    }
                }
            }
        }
    }
    catch {
        Write-Warning "Failed to process $FilePath : $_"
    }
    
    return $issues
}

function Repair-FunctionNames {
    param([string]$FilePath, [array]$Issues)
    
    if (-not $Issues -or $Issues.Count -eq 0) {
        return $false
    }
    
    try {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        $originalContent = $content
        
        foreach ($issue in $Issues) {
            if ($issue.SuggestedFunction) {
                $oldFunction = $issue.FunctionName
                $newFunction = $issue.SuggestedFunction
                
                Write-Host "  Correcting: $oldFunction -> $newFunction" -ForegroundColor Yellow
                
                # Replace function definition
                $pattern = "function\s+$([regex]::Escape($oldFunction))\b"
                $content = $content -replace $pattern, "function $newFunction"
                
                # Replace function calls
                $pattern = "\b$([regex]::Escape($oldFunction))\b"
                $content = $content -replace $pattern, $newFunction
            }
        }
        
        if ($content -ne $originalContent) {
            if (-not $DryRun) {
                # Create backup
                $backupPath = "$FilePath.bak"
                if (-not (Test-Path $backupPath)) {
                    Copy-Item -Path $FilePath -Destination $backupPath -Force
                }
                
                Set-Content -Path $FilePath -Value $content -Encoding UTF8 -Force
                Write-Host "  Applied corrections to: $FilePath" -ForegroundColor Green
            } else {
                Write-Host "  [DRY RUN] Would apply corrections to: $FilePath" -ForegroundColor Cyan
            }
            return $true
        }
    }
    catch {
        Write-Warning "Failed to apply corrections to $FilePath : $_"
    }
    
    return $false
}

# Main script
Write-Host "PowerShell Function Name Validation" -ForegroundColor Magenta
Write-Host "Path: $Path" -ForegroundColor Cyan
Write-Host "Mode: $(if ($Fix) { 'FIX' } elseif ($DryRun) { 'DRY RUN' } else { 'VALIDATE' })" -ForegroundColor Cyan
Write-Host ""

$files = Find-PowerShellFiles -SearchPath $Path
$allIssues = @()
$correctedFiles = 0

foreach ($file in $files) {
    $issues = Find-FunctionIssues -FilePath $file.FullName
    
    if ($issues.Count -gt 0) {
        $relativePath = [System.IO.Path]::GetRelativePath($Path, $file.FullName)
        
        Write-Host "File: $relativePath" -ForegroundColor White
        Write-Host "  Found $($issues.Count) issue(s)" -ForegroundColor Yellow
        
        foreach ($issue in $issues) {
            $color = if ($issue.Severity -eq "Error") { "Red" } else { "Yellow" }
            Write-Host "  Line $($issue.LineNumber): $($issue.Issue)" -ForegroundColor $color
            if ($issue.SuggestedFunction) {
                Write-Host "  Suggestion: $($issue.FunctionName) -> $($issue.SuggestedFunction)" -ForegroundColor Green
            }
        }
        
        if ($Fix -or $DryRun) {
            $corrected = Repair-FunctionNames -FilePath $file.FullName -Issues $issues
            if ($corrected) {
                $correctedFiles++
            }
        }
        
        Write-Host ""
        $allIssues += $issues
    }
}

# Summary
Write-Host "SUMMARY" -ForegroundColor Magenta
Write-Host "=======" -ForegroundColor Magenta
Write-Host "Files processed: $($files.Count)" -ForegroundColor Cyan
Write-Host "Files with issues: $(($allIssues | Group-Object File).Count)" -ForegroundColor Yellow
Write-Host "Total issues: $($allIssues.Count)" -ForegroundColor Red

if ($Fix -or $DryRun) {
    Write-Host "Files corrected: $correctedFiles" -ForegroundColor Green
}

# Most common issues
$unapprovedVerbs = $allIssues | Where-Object { $_.Verb } | Group-Object Verb | Sort-Object Count -Descending
if ($unapprovedVerbs) {
    Write-Host "`nMost common unapproved verbs:" -ForegroundColor Red
    $unapprovedVerbs | Select-Object -First 10 | ForEach-Object {
        $suggestion = $VerbMappings[$_.Name]
        Write-Host "  $($_.Name) ($($_.Count) times)" -ForegroundColor Red -NoNewline
        if ($suggestion) {
            Write-Host " -> $suggestion" -ForegroundColor Green
        } else {
            Write-Host ""
        }
    }
}

if ($allIssues.Count -eq 0) {
    Write-Host "`nNo function naming violations found!" -ForegroundColor Green
} else {
    Write-Host "`nNext steps:" -ForegroundColor Magenta
    if (-not $Fix -and -not $DryRun) {
        Write-Host "1. Run with -DryRun to see proposed changes" -ForegroundColor White
        Write-Host "2. Run with -Fix to apply corrections" -ForegroundColor White
    } elseif ($DryRun) {
        Write-Host "1. Review proposed changes above" -ForegroundColor White
        Write-Host "2. Run with -Fix to apply corrections" -ForegroundColor White
    }
}
