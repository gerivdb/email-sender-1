<#
.SYNOPSIS
    PowerShell Function Name Validator and Corrector with Approved Verbs.

.DESCRIPTION
    This script validates PowerShell function names for approved verb compliance and provides
    systematic corrections across the EMAIL_SENDER_1 project.

.PARAMETER Path
    Root path to analyze. Defaults to current directory.

.PARAMETER FixIssues
    Apply automatic corrections where possible.

.PARAMETER DryRun
    Show what would be changed without making actual changes.

.PARAMETER MaxParallelism
    Maximum number of files to process in parallel.

.EXAMPLE
    .\Fix-PowerShellFunctionNames.ps1 -Path "." -DryRun
    .\Fix-PowerShellFunctionNames.ps1 -Path "." -FixIssues
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = ".",
    
    [Parameter(Mandatory = $false)]
    [switch]$FixIssues,
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxParallelism = 5
)

#region Approved Verbs and Mappings

# Get official PowerShell approved verbs
$ApprovedVerbs = Get-Verb | Select-Object -ExpandProperty Verb

# Common verb mappings for corrections
$VerbMappings = @{
    'Analyze'   = 'Test'
    'Check'     = 'Test'
    'Create'    = 'New'
    'Extract'   = 'Export'
    'Fix'       = 'Repair'
    'Generate'  = 'New'
    'Manage'    = 'Set'
    'Process'   = 'Invoke'
    'Pull'      = 'Get'
    'Release'   = 'Publish'
    'Clone'     = 'Copy'
    'Detect'    = 'Find'
    'Handle'    = 'Invoke'
    'Run'       = 'Start'
    'Execute'   = 'Invoke'
    'Build'     = 'New'
    'Save'      = 'Export'
    'Load'      = 'Import'
    'Delete'    = 'Remove'
    'Destroy'   = 'Remove'
    'Kill'      = 'Stop'
    'Launch'    = 'Start'
    'Trigger'   = 'Invoke'
    'Validate'  = 'Test'
    'Verify'    = 'Confirm'
    'Navigate'  = 'Move'
    'Browse'    = 'Find'
    'Query'     = 'Get'
    'Fetch'     = 'Get'
    'Retrieve'  = 'Get'
    'Collect'   = 'Get'
    'Gather'    = 'Get'
    'Ensure'    = 'Confirm'
    'Apply'     = 'Set'
    'Configure' = 'Set'
    'Setup'     = 'Initialize'
    'Install'   = 'Install'
    'Deploy'    = 'Deploy'
}

#endregion

#region Helper Functions

function Get-PowerShellFiles {
    param([string]$SearchPath)
    
    Write-Host "🔍 Scanning for PowerShell files in: $SearchPath" -ForegroundColor Cyan
    
    $files = Get-ChildItem -Path $SearchPath -Recurse -Include "*.ps1", "*.psm1" -File |
        Where-Object { 
            $_.FullName -notlike "*\.git\*" -and 
            $_.FullName -notlike "*\node_modules\*" -and
            $_.FullName -notlike "*\bin\*" -and
            $_.FullName -notlike "*\obj\*"
        }
    
    Write-Host "📁 Found $($files.Count) PowerShell files" -ForegroundColor Green
    return $files
}

function Find-FunctionViolations {
    param(
        [string]$FilePath,
        [string]$Content
    )
    
    $violations = @()
    $lines = $Content -split "`n"
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $lineNumber = $i + 1
        
        # Find function definitions
        if ($line -match '^\s*function\s+([A-Za-z0-9_-]+)') {
            $functionName = $Matches[1]
            
            # Check if it follows Verb-Noun pattern
            if ($functionName -match '^([A-Za-z]+)-([A-Za-z0-9]+)$') {
                $verb = $Matches[1]
                $noun = $Matches[2]
                
                if ($verb -notin $ApprovedVerbs) {
                    $suggestedVerb = $VerbMappings[$verb]
                    $violations += [PSCustomObject]@{
                        File = $FilePath
                        LineNumber = $lineNumber
                        FunctionName = $functionName
                        Issue = "Unapproved verb: $verb"
                        Verb = $verb
                        Noun = $noun
                        SuggestedVerb = $suggestedVerb
                        SuggestedFunction = if ($suggestedVerb) { "$suggestedVerb-$noun" } else { $null }
                        Severity = "Error"
                        Line = $line.Trim()
                    }
                }
            } else {
                # Function doesn't follow Verb-Noun pattern
                $violations += [PSCustomObject]@{
                    File = $FilePath
                    LineNumber = $lineNumber
                    FunctionName = $functionName
                    Issue = "Invalid function naming format (should be Verb-Noun)"
                    Verb = $null
                    Noun = $null
                    SuggestedVerb = $null
                    SuggestedFunction = $null
                    Severity = "Warning"
                    Line = $line.Trim()
                }
            }
        }
    }
    
    return $violations
}

function Set-FunctionNameCorrections {
    param(
        [string]$FilePath,
        [array]$Violations
    )
    
    if (-not $Violations -or $Violations.Count -eq 0) {
        return $false
    }
    
    try {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        $originalContent = $content
        $correctionsMade = @()
        
        foreach ($violation in $Violations) {
            if ($violation.SuggestedFunction) {
                $oldFunction = $violation.FunctionName
                $newFunction = $violation.SuggestedFunction
                
                Write-Host "  🔧 Correcting: $oldFunction -> $newFunction" -ForegroundColor Yellow
                
                # Replace function definition
                $content = $content -replace "function\s+$([regex]::Escape($oldFunction))\b", "function $newFunction"
                
                # Replace function calls (be careful with word boundaries)
                $content = $content -replace "\b$([regex]::Escape($oldFunction))\b", $newFunction
                
                $correctionsMade += [PSCustomObject]@{
                    Original = $oldFunction
                    Corrected = $newFunction
                    Type = "Function Name Correction"
                }
            }
        }
        
        if ($content -ne $originalContent) {
            if (-not $DryRun) {
                # Create backup
                $backupPath = "$FilePath.bak"
                if (-not (Test-Path $backupPath)) {
                    Copy-Item -Path $FilePath -Destination $backupPath -Force
                }
                
                # Write corrected content
                Set-Content -Path $FilePath -Value $content -Encoding UTF8 -Force
                Write-Host "  ✅ Applied corrections to: $FilePath" -ForegroundColor Green
            } else {
                Write-Host "  🔍 [DRY RUN] Would apply corrections to: $FilePath" -ForegroundColor Cyan
            }
            
            return $true
        }
    }
    catch {
        Write-Warning "Failed to apply corrections to $FilePath`: $_"
        return $false
    }
    
    return $false
}

#endregion

#region Main Processing

function Start-FunctionNameValidation {
    param([string]$RootPath)
    
    Write-Host "🚀 Starting PowerShell Function Name Validation" -ForegroundColor Magenta
    Write-Host "📍 Root Path: $RootPath" -ForegroundColor Cyan
    Write-Host "🔧 Mode: $(if ($FixIssues) { 'FIX' } elseif ($DryRun) { 'DRY RUN' } else { 'VALIDATE ONLY' })" -ForegroundColor Cyan
    Write-Host ""
    
    $files = Get-PowerShellFiles -SearchPath $RootPath
    $allViolations = @()
    $correctedFiles = 0
    
    # Process files sequentially for now to avoid variable issues
    foreach ($file in $files) {
        $violations = @()
        
        try {
            $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
            $violations = Find-FunctionViolations -FilePath $file.FullName -Content $content
            
            if ($violations.Count -gt 0) {
                $relativePath = [System.IO.Path]::GetRelativePath($RootPath, $file.FullName)
                
                Write-Host "📄 $relativePath" -ForegroundColor White
                Write-Host "   Found $($violations.Count) violation$(if($violations.Count -gt 1){'s'})" -ForegroundColor Yellow
                
                foreach ($violation in $violations) {
                    $color = if ($violation.Severity -eq "Error") { "Red" } else { "Yellow" }
                    Write-Host "   Line $($violation.LineNumber): $($violation.Issue)" -ForegroundColor $color
                    if ($violation.SuggestedFunction) {
                        Write-Host "   Suggestion: $($violation.FunctionName) -> $($violation.SuggestedFunction)" -ForegroundColor Green
                    }
                }
                
                if ($FixIssues -or $DryRun) {
                    $corrected = Set-FunctionNameCorrections -FilePath $file.FullName -Violations $violations
                    if ($corrected) {
                        $correctedFiles++
                    }
                }
                
                Write-Host ""
            }
            
            $allViolations += $violations
        }
        catch {
            Write-Warning "Failed to process $($file.FullName): $_"
        }
    }
    
    # Summary report
    Write-Host "📊 SUMMARY REPORT" -ForegroundColor Magenta
    Write-Host "=================" -ForegroundColor Magenta
    Write-Host "Total files processed: $($files.Count)" -ForegroundColor Cyan
    Write-Host "Files with violations: $(($allViolations | Group-Object File).Count)" -ForegroundColor Yellow
    Write-Host "Total violations found: $($allViolations.Count)" -ForegroundColor Red
    
    if ($FixIssues -or $DryRun) {
        Write-Host "Files corrected: $correctedFiles" -ForegroundColor Green
    }
    
    # Group violations by type
    $violationsByType = $allViolations | Group-Object Issue
    Write-Host "`n🔍 VIOLATION BREAKDOWN:" -ForegroundColor Cyan
    foreach ($group in $violationsByType) {
        Write-Host "  $($group.Name): $($group.Count)" -ForegroundColor White
    }
    
    # Most common unapproved verbs
    $unapprovedVerbs = $allViolations | Where-Object { $_.Verb } | Group-Object Verb | Sort-Object Count -Descending
    if ($unapprovedVerbs) {
        Write-Host "`n🚫 MOST COMMON UNAPPROVED VERBS:" -ForegroundColor Red
        $unapprovedVerbs | Select-Object -First 10 | ForEach-Object {
            $suggestion = $VerbMappings[$_.Name]
            Write-Host "  $($_.Name) ($($_.Count) occurrences)" -ForegroundColor Red -NoNewline
            if ($suggestion) {
                Write-Host " -> Suggested: $suggestion" -ForegroundColor Green
            } else {
                Write-Host " -> No automatic suggestion" -ForegroundColor Yellow
            }
        }
    }
    
    return $allViolations
}

#endregion

#region Script Execution

# Resolve the path
$ResolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
if (-not $ResolvedPath) {
    Write-Error "Path '$Path' does not exist or is not accessible."
    exit 1
}

# Validate parameters
if ($FixIssues -and $DryRun) {
    Write-Error "Cannot specify both -FixIssues and -DryRun. Choose one."
    exit 1
}

# Start the validation process
try {
    $results = Start-FunctionNameValidation -RootPath $ResolvedPath.Path
    
    if ($results.Count -eq 0) {
        Write-Host "🎉 No function naming violations found!" -ForegroundColor Green
    } else {
        Write-Host "`n💡 NEXT STEPS:" -ForegroundColor Magenta
        if (-not $FixIssues -and -not $DryRun) {
            Write-Host "  1. Review violations above" -ForegroundColor White
            Write-Host "  2. Run with -DryRun to see proposed changes" -ForegroundColor White
            Write-Host "  3. Run with -FixIssues to apply automatic corrections" -ForegroundColor White
        } elseif ($DryRun) {
            Write-Host "  1. Review proposed changes above" -ForegroundColor White
            Write-Host "  2. Run with -FixIssues to apply corrections" -ForegroundColor White
        } else {
            Write-Host "  1. Test your scripts to ensure corrections work properly" -ForegroundColor White
            Write-Host "  2. Review .bak files if you need to revert changes" -ForegroundColor White
            Write-Host "  3. Run this script again to check for remaining issues" -ForegroundColor White
        }
    }
}
catch {
    Write-Error "Fatal error during validation: $_"
    exit 2
}

#endregion
