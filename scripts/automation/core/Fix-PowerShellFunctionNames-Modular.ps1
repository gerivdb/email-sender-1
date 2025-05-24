#requires -Version 5.1

<#
.SYNOPSIS
    Modular PowerShell Function Name Validator and Corrector.

.DESCRIPTION
    This modular version of the PowerShell function name validator uses separate modules
    for verb mapping and validation logic, providing better maintainability and reusability.

.PARAMETER Path
    Root path to analyze. Defaults to current directory.

.PARAMETER FixIssues
    Apply automatic corrections where possible.

.PARAMETER DryRun
    Show what would be changed without making actual changes.

.PARAMETER MaxParallelism
    Maximum number of files to process in parallel.

.PARAMETER Detailed
    Show detailed violation information.

.EXAMPLE
    .\Fix-PowerShellFunctionNames-Modular.ps1 -Path "." -DryRun
    .\Fix-PowerShellFunctionNames-Modular.ps1 -Path "." -FixIssues -Detailed
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
    [int]$MaxParallelism = 5,
    
    [Parameter(Mandatory = $false)]
    [switch]$Detailed
)

#region Module Imports

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import PowerShell Verb Mapping Module
$VerbMappingModulePath = Join-Path $ScriptPath "modules\PowerShellVerbMapping\PowerShellVerbMapping.psm1"
if (-not (Test-Path $VerbMappingModulePath)) {
    Write-Error "PowerShell Verb Mapping module not found at: $VerbMappingModulePath"
    exit 1
}

Import-Module $VerbMappingModulePath -Force -Verbose:$false

# Import PowerShell Function Validator Module
$ValidatorModulePath = Join-Path $ScriptPath "modules\PowerShellFunctionValidator\PowerShellFunctionValidator.psm1"
if (-not (Test-Path $ValidatorModulePath)) {
    Write-Error "PowerShell Function Validator module not found at: $ValidatorModulePath"
    exit 1
}

Import-Module $ValidatorModulePath -Force -Verbose:$false

#endregion

#region Helper Functions

function Write-ValidationHeader {
    param([string]$RootPath, [string]$Mode)
    
    Write-Host "🚀 PowerShell Function Name Validator (Modular)" -ForegroundColor Magenta
    Write-Host "=" * 60 -ForegroundColor Magenta
    Write-Host "📍 Root Path: $RootPath" -ForegroundColor Cyan
    Write-Host "🔧 Mode: $Mode" -ForegroundColor Cyan
    Write-Host "📦 Using Modular Architecture" -ForegroundColor Green
    Write-Host ""
}

function Write-ViolationDetails {
    param([array]$Violations, [string]$RootPath)
    
    if ($Violations.Count -eq 0) {
        return
    }
    
    # Group violations by file
    $violationsByFile = $Violations | Group-Object File
    
    foreach ($fileGroup in $violationsByFile) {
        $relativePath = [System.IO.Path]::GetRelativePath($RootPath, $fileGroup.Name)
        
        Write-Host "📄 $relativePath" -ForegroundColor White
        Write-Host "   Found $($fileGroup.Count) violation$(if($fileGroup.Count -gt 1){'s'})" -ForegroundColor Yellow
        
        foreach ($violation in $fileGroup.Group) {
            $color = if ($violation.Severity -eq "Error") { "Red" } else { "Yellow" }
            Write-Host "   Line $($violation.LineNumber): $($violation.Issue)" -ForegroundColor $color
            
            if ($Detailed) {
                Write-Host "     Function: $($violation.FunctionName)" -ForegroundColor Gray
                Write-Host "     Code: $($violation.Line)" -ForegroundColor Gray
            }
            
            if ($violation.SuggestedFunction) {
                Write-Host "   💡 Suggestion: $($violation.FunctionName) → $($violation.SuggestedFunction)" -ForegroundColor Green
            }
        }
        Write-Host ""
    }
}

function Write-SummaryReport {
    param([PSCustomObject]$Results)
    
    Write-Host "📊 VALIDATION SUMMARY" -ForegroundColor Magenta
    Write-Host "=" * 30 -ForegroundColor Magenta
    Write-Host "Total files processed: $($Results.TotalFiles)" -ForegroundColor Cyan
    Write-Host "Files with violations: $($Results.FilesWithIssues)" -ForegroundColor Yellow
    Write-Host "Total violations found: $($Results.Violations.Count)" -ForegroundColor Red
    
    if ($Results.Summary.HasIssues) {
        Write-Host ""
        Write-Host "🔍 BREAKDOWN BY TYPE:" -ForegroundColor Cyan
        foreach ($group in $Results.ViolationsByType) {
            Write-Host "  $($group.Name): $($group.Count)" -ForegroundColor White
        }
        
        if ($Results.Summary.MostCommonUnapprovedVerbs) {
            Write-Host ""
            Write-Host "🚫 MOST COMMON UNAPPROVED VERBS:" -ForegroundColor Red
            foreach ($verb in $Results.Summary.MostCommonUnapprovedVerbs) {
                $suggestion = Get-VerbSuggestion -Verb $verb.Name
                Write-Host "  $($verb.Name) ($($verb.Count) occurrences)" -ForegroundColor Red -NoNewline
                if ($suggestion) {
                    Write-Host " → Suggested: $suggestion" -ForegroundColor Green
                } else {
                    Write-Host " → No automatic suggestion" -ForegroundColor Yellow
                }
            }
        }
        
        Write-Host ""
        Write-Host "💡 RECOMMENDATIONS:" -ForegroundColor Magenta
        foreach ($recommendation in $Results.Summary.Recommendations) {
            Write-Host "  $recommendation" -ForegroundColor White
        }
    }
}

function Invoke-FileCorrections {
    param([array]$Violations, [string]$RootPath, [bool]$IsDryRun)
    
    $correctedFiles = 0
    $violationsByFile = $Violations | Group-Object File
    
    foreach ($fileGroup in $violationsByFile) {
        $filePath = $fileGroup.Name
        $fileViolations = $fileGroup.Group | Where-Object { $_.SuggestedFunction }
        
        if ($fileViolations.Count -eq 0) {
            continue
        }
        
        try {
            $content = Get-Content -Path $filePath -Raw -Encoding UTF8
            $correction = Repair-PowerShellFunctionNames -Content $content -Violations $fileViolations -FilePath $filePath
            
            if ($correction.HasChanges) {
                $relativePath = [System.IO.Path]::GetRelativePath($RootPath, $filePath)
                
                if (-not $IsDryRun) {
                    # Create backup
                    $backupPath = "$filePath.bak"
                    if (-not (Test-Path $backupPath)) {
                        Copy-Item -Path $filePath -Destination $backupPath -Force
                    }
                    
                    # Apply corrections
                    Set-Content -Path $filePath -Value $correction.Content -Encoding UTF8 -Force
                    Write-Host "  ✅ Applied $($correction.Corrections.Count) corrections to: $relativePath" -ForegroundColor Green
                } else {
                    Write-Host "  🔍 [DRY RUN] Would apply $($correction.Corrections.Count) corrections to: $relativePath" -ForegroundColor Cyan
                }
                
                if ($Detailed) {
                    foreach ($corr in $correction.Corrections) {
                        Write-Host "    Line $($corr.LineNumber): $($corr.Original) → $($corr.Corrected)" -ForegroundColor Gray
                    }
                }
                
                $correctedFiles++
            }
        }
        catch {
            Write-Warning "Failed to apply corrections to ${filePath} - $($_.Exception.Message)"
        }
    }
    
    return $correctedFiles
}

#endregion#region Main Execution

function Start-ModularValidation {
    param([string]$RootPath, [string]$Mode)
    
    Write-ValidationHeader -RootPath $RootPath -Mode $Mode
    
    # Display module information
    Write-Host "📦 MODULE INFORMATION:" -ForegroundColor Cyan
    try {
        $verbMappings = Get-VerbMappings
        $approvedVerbs = Get-ApprovedVerbs
        Write-Host "  • Verb mappings available: $($verbMappings.Count)" -ForegroundColor White
        Write-Host "  • Approved verbs total: $($approvedVerbs.Count)" -ForegroundColor White
    } catch {
        Write-Warning "Could not load module information: $($_.Exception.Message)"
    }
    
    Write-Host ""
    Write-Host "🔍 Scanning for PowerShell files..." -ForegroundColor Cyan
    
    try {
        # Find PowerShell files
        $files = Find-PowerShellFiles -Path $RootPath
        Write-Host "📁 Found $($files.Count) PowerShell files to analyze" -ForegroundColor Green
        
        if ($files.Count -eq 0) {
            Write-Host "ℹ️  No PowerShell files found in the specified path." -ForegroundColor Yellow
            return
        }
        
        Write-Host "⚡ Analyzing function names..." -ForegroundColor Cyan
        
        # Perform bulk validation
        $results = Invoke-BulkFunctionValidation -Files $files -MaxParallelism $MaxParallelism
        
        # Display detailed violations if requested
        if ($Detailed -and $results.Violations.Count -gt 0) {
            Write-Host ""
            Write-Host "🔍 DETAILED VIOLATION REPORT:" -ForegroundColor Magenta
            Write-ViolationDetails -Violations $results.Violations -RootPath $RootPath
        }
        
        # Apply corrections if requested
        $correctedFiles = 0
        if (($FixIssues -or $DryRun) -and $results.Violations.Count -gt 0) {
            Write-Host "🔧 APPLYING CORRECTIONS:" -ForegroundColor Magenta
            $correctedFiles = Invoke-FileCorrections -Violations $results.Violations -RootPath $RootPath -IsDryRun $DryRun
        }
        
        # Display summary
        Write-Host ""
        Write-SummaryReport -Results $results
        
        # Display completion message
        Write-Host ""
        if ($results.Violations.Count -eq 0) {
            Write-Host "🎉 No function naming violations found!" -ForegroundColor Green
            Write-Host "✨ All function names follow PowerShell best practices." -ForegroundColor Green
        } else {
            if ($correctedFiles -gt 0) {
                Write-Host "✅ Applied corrections to $correctedFiles file$(if($correctedFiles -gt 1){'s'})" -ForegroundColor Green
            }
            
            Write-Host ""
            Write-Host "💡 NEXT STEPS:" -ForegroundColor Magenta
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
        
        if ($results.Violations.Count -eq 0) {
            Write-Host "✅ Validation completed successfully - no issues found!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Validation completed - $($results.Violations.Count) issue$(if($results.Violations.Count -gt 1){'s'}) found" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Error "Error during file analysis: $($_.Exception.Message)"
        Write-Host ""
        Write-Host "🔧 TROUBLESHOOTING:" -ForegroundColor Yellow
        Write-Host "  • Ensure both modules are properly installed" -ForegroundColor White
        Write-Host "  • Check file permissions in the target directory" -ForegroundColor White
        Write-Host "  • Verify PowerShell execution policy allows module loading" -ForegroundColor White
        throw
    }
}

#endregion

#region Script Parameters Validation and Execution

# Resolve the path
try {
    $ResolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
} catch {
    Write-Error "Path '$Path' does not exist or is not accessible - $($_.Exception.Message)"
    exit 1
}

# Validate parameters
if ($FixIssues -and $DryRun) {
    Write-Error "Cannot specify both -FixIssues and -DryRun. Choose one."
    exit 1
}

# Determine the mode
$Mode = if ($FixIssues) { "FIX" } elseif ($DryRun) { "DRY RUN" } else { "VALIDATE ONLY" }

# Start the modular validation process
try {
    Start-ModularValidation -RootPath $ResolvedPath.Path -Mode $Mode
} catch {
    Write-Error "Fatal error during modular validation - $($_.Exception.Message)"
    Write-Host ""
    Write-Host "📦 MODULE INFORMATION:" -ForegroundColor Cyan
    Write-Host "  • PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
    Write-Host "  • Execution Policy: $(Get-ExecutionPolicy)" -ForegroundColor White
    Write-Host "  • Script Path: $PSScriptRoot" -ForegroundColor White
    exit 2
}

#endregion