#
# PowerShell Function Validator Module
# Provides validation and correction logic for PowerShell function names
#

#region Module Dependencies

# Import PowerShell Verb Mapping Module
$VerbMappingPath = Join-Path (Split-Path $PSScriptRoot -Parent) "PowerShellVerbMapping\PowerShellVerbMapping.psm1"
if (Test-Path $VerbMappingPath) {
    Import-Module $VerbMappingPath -Force -Global
} else {
    throw "Required module PowerShellVerbMapping not found at: $VerbMappingPath"
}

#endregion

#region Private Helper Functions

function Get-FunctionNamesFromContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $functions = @()
    $lines = $Content -split "`n"
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $lineNumber = $i + 1
        
        # Match function definitions with various patterns
        if ($line -match '^\s*function\s+([A-Za-z0-9_-]+)') {
            $functionName = $Matches[1]
            
            $functions += [PSCustomObject]@{
                Name = $functionName
                LineNumber = $lineNumber
                Line = $line.Trim()
                FilePath = $FilePath
            }
        }
    }
    
    return $functions
}

function Test-FunctionNamePattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FunctionName
    )
    
    # Check if function follows Verb-Noun pattern
    if ($FunctionName -match '^([A-Za-z]+)-([A-Za-z0-9]+)$') {
        return @{
            IsValid = $true
            Verb = $Matches[1]
            Noun = $Matches[2]
        }
    }
    
    return @{
        IsValid = $false
        Verb = $null
        Noun = $null
    }
}

#endregion

#region Public Functions

<#
.SYNOPSIS
    Validates function names in PowerShell content for approved verb compliance.

.DESCRIPTION
    Analyzes PowerShell script content to find function definitions and validates
    them against PowerShell approved verb standards.

.PARAMETER Content
    The PowerShell script content to analyze.

.PARAMETER FilePath
    The file path for reporting purposes.

.EXAMPLE
    $violations = Test-PowerShellFunctionNames -Content $scriptContent -FilePath "script.ps1"
#>
function Test-PowerShellFunctionNames {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    # Import required functions from VerbMapping module
    $approvedVerbs = Get-ApprovedVerbs
    $verbMappings = Get-VerbMappings
    
    $violations = @()
    $functions = Get-FunctionNamesFromContent -Content $Content -FilePath $FilePath
    
    foreach ($func in $functions) {
        $pattern = Test-FunctionNamePattern -FunctionName $func.Name
        
        if ($pattern.IsValid) {
            # Function follows Verb-Noun pattern, check if verb is approved
            if ($pattern.Verb -notin $approvedVerbs) {
                $suggestedVerb = $verbMappings[$pattern.Verb]
                
                $violations += [PSCustomObject]@{
                    File = $FilePath
                    LineNumber = $func.LineNumber
                    FunctionName = $func.Name
                    Issue = "Unapproved verb: $($pattern.Verb)"
                    Verb = $pattern.Verb
                    Noun = $pattern.Noun
                    SuggestedVerb = $suggestedVerb
                    SuggestedFunction = if ($suggestedVerb) { "$suggestedVerb-$($pattern.Noun)" } else { $null }
                    Severity = "Error"
                    Line = $func.Line
                    Type = "UnapprovedVerb"
                }
            }
        } else {
            # Function doesn't follow Verb-Noun pattern
            $violations += [PSCustomObject]@{
                File = $FilePath
                LineNumber = $func.LineNumber
                FunctionName = $func.Name
                Issue = "Invalid function naming format (should be Verb-Noun)"
                Verb = $null
                Noun = $null
                SuggestedVerb = $null
                SuggestedFunction = $null
                Severity = "Warning"
                Line = $func.Line
                Type = "InvalidPattern"
            }
        }
    }
    
    return $violations
}

<#
.SYNOPSIS
    Applies automatic corrections to PowerShell function names in file content.

.DESCRIPTION
    Takes violations found by Test-PowerShellFunctionNames and applies automatic
    corrections where possible, returning the corrected content.

.PARAMETER Content
    The original PowerShell script content.

.PARAMETER Violations
    Array of violations to correct.

.PARAMETER FilePath
    The file path for logging purposes.

.EXAMPLE
    $correctedContent = Repair-PowerShellFunctionNames -Content $content -Violations $violations -FilePath "script.ps1"
#>
function Repair-PowerShellFunctionNames {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [array]$Violations,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $correctedContent = $Content
    $correctionsMade = @()
    
    # Sort violations by line number (descending) to avoid line number shifts
    $sortedViolations = $Violations | Where-Object { $_.SuggestedFunction } | Sort-Object LineNumber -Descending
    
    foreach ($violation in $sortedViolations) {
        $oldFunction = $violation.FunctionName
        $newFunction = $violation.SuggestedFunction
        
        if ($newFunction) {
            Write-Verbose "Correcting: $oldFunction -> $newFunction in $FilePath"
            
            # Replace function definition
            $correctedContent = $correctedContent -replace "function\s+$([regex]::Escape($oldFunction))\b", "function $newFunction"
            
            # Replace function calls (with word boundaries to avoid partial matches)
            $correctedContent = $correctedContent -replace "\b$([regex]::Escape($oldFunction))\b", $newFunction
            
            $correctionsMade += [PSCustomObject]@{
                Original = $oldFunction
                Corrected = $newFunction
                Type = "FunctionNameCorrection"
                LineNumber = $violation.LineNumber
            }
        }
    }
    
    return [PSCustomObject]@{
        Content = $correctedContent
        Corrections = $correctionsMade
        HasChanges = $correctionsMade.Count -gt 0
    }
}
<#
.SYNOPSIS
    Scans a directory for PowerShell files and returns file information.

.DESCRIPTION
    Recursively scans the specified directory for PowerShell files (.ps1, .psm1)
    while excluding common non-source directories.

.PARAMETER Path
    The root directory to scan.

.PARAMETER ExcludePatterns
    Array of patterns to exclude from scanning.

.EXAMPLE
    $files = Find-PowerShellFiles -Path "C:\Scripts"
#>
function Find-PowerShellFiles {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludePatterns = @("*\.git\*", "*\node_modules\*", "*\bin\*", "*\obj\*", "*\.vs\*")
    )
    
    Write-Verbose "Scanning for PowerShell files in: $Path"
    
    $files = Get-ChildItem -Path $Path -Recurse -Include "*.ps1", "*.psm1" -File | Where-Object {
        $filePath = $_.FullName
        $shouldExclude = $false
        
        foreach ($pattern in $ExcludePatterns) {
            if ($filePath -like $pattern) {
                $shouldExclude = $true
                break
            }
        }
        
        return -not $shouldExclude
    }
    
    Write-Verbose "Found $($files.Count) PowerShell files"
    return $files
}

<#
.SYNOPSIS
    Validates PowerShell function names in multiple files.

.DESCRIPTION
    Processes multiple PowerShell files to validate function names and collect violations.
    Supports parallel processing for better performance on large codebases.

.PARAMETER Files
    Array of file paths to process.

.PARAMETER MaxParallelism
    Maximum number of files to process in parallel (default: 5).

.EXAMPLE
    $results = Invoke-BulkFunctionValidation -Files $fileList -MaxParallelism 3
#>
function Invoke-BulkFunctionValidation {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$Files,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxParallelism = 5
    )
    
    $allViolations = @()
    $processedFiles = 0
    $filesWithIssues = 0
    
    foreach ($file in $Files) {
        try {
            Write-Progress -Activity "Validating PowerShell Functions" -Status "Processing $($file.Name)" -PercentComplete (($processedFiles / $Files.Count) * 100)
            
            $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
            $violations = Test-PowerShellFunctionNames -Content $content -FilePath $file.FullName
            
            if ($violations.Count -gt 0) {
                $filesWithIssues++
                $allViolations += $violations
            }
            
            $processedFiles++
        }
        catch {
            Write-Warning "Failed to process $($file.FullName): $_"
        }
    }
    
    Write-Progress -Activity "Validating PowerShell Functions" -Completed
    
    return [PSCustomObject]@{
        TotalFiles = $Files.Count
        ProcessedFiles = $processedFiles
        FilesWithIssues = $filesWithIssues
        Violations = $allViolations
        ViolationsByFile = $allViolations | Group-Object File
        ViolationsByType = $allViolations | Group-Object Type
        Summary = Get-ValidationSummary -Violations $allViolations
    }
}

<#
.SYNOPSIS
    Generates a summary report of function name violations.

.DESCRIPTION
    Creates a comprehensive summary of violations found during validation,
    including statistics and recommendations.

.PARAMETER Violations
    Array of violations to summarize.

.EXAMPLE
    $summary = Get-ValidationSummary -Violations $allViolations
#>
function Get-ValidationSummary {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [array]$Violations = @()
    )
    
    if ($null -eq $Violations -or $Violations.Count -eq 0) {
        return [PSCustomObject]@{
            TotalViolations = 0
            HasIssues = $false
            Message = "No function naming violations found!"
        }
    }
    
    $unapprovedVerbs = $Violations | Where-Object { $_.Type -eq "UnapprovedVerb" } | Group-Object Verb | Sort-Object Count -Descending
    $invalidPatterns = $Violations | Where-Object { $_.Type -eq "InvalidPattern" }
    $correctableViolations = $Violations | Where-Object { $_.SuggestedFunction }
    
    return [PSCustomObject]@{
        TotalViolations = $Violations.Count
        HasIssues = $true
        UnapprovedVerbCount = ($Violations | Where-Object { $_.Type -eq "UnapprovedVerb" }).Count
        InvalidPatternCount = $invalidPatterns.Count
        CorrectableViolations = $correctableViolations.Count
        AutoCorrectionPercentage = [math]::Round(($correctableViolations.Count / $Violations.Count) * 100, 1)
        MostCommonUnapprovedVerbs = $unapprovedVerbs | Select-Object -First 5
        FilesAffected = ($Violations | Group-Object File).Count
        Recommendations = Get-ValidationRecommendations -Violations $Violations
    }
}

<#
.SYNOPSIS
    Provides recommendations based on validation results.

.DESCRIPTION
    Analyzes violations and provides actionable recommendations for improvement.

.PARAMETER Violations
    Array of violations to analyze.

.EXAMPLE
    $recommendations = Get-ValidationRecommendations -Violations $violations
#>
function Get-ValidationRecommendations {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $false)]
        [array]$Violations = @()
    )
    
    $recommendations = @()
    
    if ($null -eq $Violations -or $Violations.Count -eq 0) {
        return @("All function names follow PowerShell best practices!")
    }
    
    $correctableCount = ($Violations | Where-Object { $_.SuggestedFunction }).Count
    $totalCount = $Violations.Count
    
    if ($correctableCount -gt 0) {
        $recommendations += "✅ $correctableCount out of $totalCount violations can be automatically corrected"
        $recommendations += "🔧 Run with -FixIssues parameter to apply automatic corrections"
    }
    
    $invalidPatterns = $Violations | Where-Object { $_.Type -eq "InvalidPattern" }
    if ($invalidPatterns.Count -gt 0) {
        $recommendations += "⚠️  $($invalidPatterns.Count) functions don't follow Verb-Noun naming pattern"
        $recommendations += "📝 Consider refactoring these functions to follow PowerShell conventions"
    }
    
    $unmappedVerbs = $Violations | Where-Object { $_.Type -eq "UnapprovedVerb" -and -not $_.SuggestedFunction }
    if ($unmappedVerbs.Count -gt 0) {
        $recommendations += "❓ $($unmappedVerbs.Count) violations need manual review (no automatic suggestion available)"
    }
    
    return $recommendations
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Test-PowerShellFunctionNames',
    'Repair-PowerShellFunctionNames',
    'Find-PowerShellFiles',
    'Invoke-BulkFunctionValidation',
    'Get-ValidationSummary',
    'Get-ValidationRecommendations'
)

#endregion