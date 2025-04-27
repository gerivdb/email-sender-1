# --- Use the Improved Script from the Previous Answer ---
# (Pasting it here again for completeness)

#Requires -Version 5.1
#Requires -Modules PSCacheManager, PSParallelUtils # Adjust PSParallelUtils if your parallel function is elsewhere

<#
.SYNOPSIS
    Performs large-scale, parallel analysis of PowerShell scripts using AST parsing and caching.
.DESCRIPTION
    This script efficiently analyzes a directory structure containing PowerShell scripts (.ps1, .psm1, *.psd1). # Added psd1
    It leverages PowerShell's Abstract Syntax Tree (AST) for accurate metric extraction
    (functions, cmdlets, complexity, etc.). Parallel execution via Runspace Pools significantly
    speeds up the process on multi-core systems. Results are cached using PSCacheManager
    to avoid re-analyzing unchanged files.
.PARAMETER ScriptsPath
    The root directory path containing the PowerShell scripts to analyze. Defaults to three levels above the script's location.
.PARAMETER OutputPath
    The directory path where the JSON analysis results file will be saved. Defaults to a 'results' subdirectory.
.PARAMETER FilePatterns
    An array of file patterns (like *.ps1, *.psm1, *.psd1) to include in the analysis.
.PARAMETER MaxParallelTasks
    The maximum number of scripts to analyze concurrently using Runspace Pools.
    Defaults to the number of logical processors.
.PARAMETER ForceNoCache
    If specified, bypasses the cache and forces re-analysis of all scripts.
.PARAMETER CacheName
    Specifies a custom name for the PSCacheManager instance used.
.EXAMPLE
    .\Analyze-PowerShellScripts-AST.ps1 -ScriptsPath "C:\Projects\MyPowerShellRepo" -OutputPath "C:\AnalysisOutput" -Verbose
    # Analyzes scripts in the specified repo, saves results, shows verbose output.

.EXAMPLE
    .\Analyze-PowerShellScripts-AST.ps1 -MaxParallelTasks 4 -ForceNoCache -FilePatterns "*.ps1","*.psm1"
    # Analyzes only .ps1 and .psm1 files using a maximum of 4 parallel tasks, ignoring any cached results.
.NOTES
    Version: 2.1 (Adapted from previous improved version)
    Author: Augment Agent (Improved by AI)
    Date: 2023-10-27
    Requires: PowerShell 5.1+, PSCacheManager module (v2.0+ recommended), PSParallelUtils module (or similar providing Invoke-OptimizedParallel).

    Improvements:
    - Uses robust PowerShell AST parsing (not regex/Python).
    - Implemented true parallel analysis using Runspace Pools (via Invoke-OptimizedParallel).
    - Integrated enhanced PSCacheManager for persistent and intelligent caching.
    - Added comprehensive analysis metrics (Commands, Variables, Parameters, Complexity).
    - Improved error handling per file.
    - Enhanced output summary and structured JSON results.
    - Added configuration for parallelism and cache bypass.
    - Included *.psd1 in default patterns (though AST parsing is less relevant for psd1 data files).
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]$ScriptsPath = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..")), # Resolve to absolute path

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "results"),

    [Parameter(Mandatory = $false)]
    [string[]]$FilePatterns = @("*.ps1", "*.psm1", "*.psd1"), # Included psd1

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 128)]
    [int]$MaxParallelTasks = [System.Environment]::ProcessorCount,

    [Parameter(Mandatory = $false)]
    [switch]$ForceNoCache,

    [Parameter(Mandatory=$false)]
    [string]$CacheName = "PowerShellScriptAnalysisCache_v3" # Incremented cache version
)

#region Initialization and Setup

# Import required modules (adjust path/name if necessary)
try {
    Import-Module PSCacheManager -ErrorAction Stop
    Import-Module PSParallelUtils -ErrorAction Stop # Assumes Invoke-OptimizedParallel is here
} catch {
    Write-Error "Failed to import required modules (PSCacheManager, PSParallelUtils). Ensure they are installed and available. Error: $($_.Exception.Message)"
    return
}


# Create/Validate Output Path
if (-not (Test-Path -Path $OutputPath)) {
    Write-Verbose "Creating output directory: $OutputPath"
    try {
        $null = New-Item -Path $OutputPath -ItemType Directory -Force -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to create output directory '$OutputPath'. Error: $($_.Exception.Message)"
        return
    }
}
elseif (-not (Test-Path -Path $OutputPath -PathType Container)) {
    Write-Error "Output path '$OutputPath' exists but is not a directory."
    return
}

# Initialize Cache
Write-Verbose "Initializing analysis cache '$CacheName'."
$analysisCache = New-PSCache -Name $CacheName -DefaultTTLSeconds (30 * 86400) # Cache for 30 days unless file changes
if (-not $analysisCache) {
    Write-Error "Failed to initialize PSCacheManager. Ensure the module is correctly installed."
    return
}

#endregion

#region Helper Functions

function Find-PowerShellScripts {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath,

        [Parameter(Mandatory = $true)]
        [string[]]$Patterns
    )

    $files = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    Write-Verbose "Searching for scripts matching patterns: $($Patterns -join ', ') in '$RootPath'"
    try {
        foreach ($pattern in $Patterns) {
            # Use -File parameter for efficiency
            $found = Get-ChildItem -Path $RootPath -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
            if($null -ne $found) {
                $files.AddRange($found)
            }
        }
        # Return unique FileInfo objects using FullName for comparison
        return $files | Sort-Object -Property FullName -Unique
    }
    catch {
        Write-Error "Error finding script files in '$RootPath'. Error: $($_.Exception.Message)"
        return @() # Return empty array on error
    }
}

#endregion

#region Core Analysis Logic (ScriptBlock for Parallel Execution)

$analysisScriptBlock = {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$FileInfo,
        [Parameter(Mandatory = $true)]
        [string]$CacheManagerName,
        [Parameter(Mandatory = $true)]
        [bool]$BypassCache
    )

    # --- Re-initialize cache access within the runspace ---
    $cache = $null
    try {
        Import-Module PSCacheManager -ErrorAction Stop
        $cache = New-PSCache -Name $CacheManagerName -ErrorAction SilentlyContinue # Attempt to get handle
    } catch {
         # Cannot use cache if module fails to load in runspace
         Write-Warning "Failed to load PSCacheManager in runspace for $($FileInfo.Name). Cache disabled for this item."
    }


    # Define Cache Key (Includes file path, mod time, and analysis version)
    $cacheKey = "ScriptAnalysis_V3:$($FileInfo.FullName):$($FileInfo.LastWriteTimeUtc.Ticks)"
    $result = $null

    # --- Cache Check ---
    if (-not $BypassCache -and $null -ne $cache) {
        try {
             $result = Get-PSCacheItem -Cache $cache -Key $cacheKey -ErrorAction SilentlyContinue
        } catch {
             Write-Warning "Error accessing cache for $($FileInfo.Name) (Key: $cacheKey). Error: $($_.Exception.Message)"
        }
    }

    # --- Perform Analysis if not found in cache ---
    if ($null -eq $result) {
        $metrics = @{
            # File Info
            file_path         = $FileInfo.FullName
            file_name         = $FileInfo.Name
            file_extension    = $FileInfo.Extension
            file_size_bytes   = $FileInfo.Length
            last_modified_utc = $FileInfo.LastWriteTimeUtc
            # Analysis Status
            analysis_status   = 'Pending' # Will be 'Success', 'ParseError', 'AnalysisError'
            error_message     = $null
            parse_errors      = $null
            # Basic Metrics
            total_lines       = 0
            blank_lines       = 0
            comment_lines     = 0
            code_lines        = 0
            # AST-Derived Metrics
            functions_count   = 0
            functions         = @()
            cmdlets_ext_count = 0 # External commands/cmdlets used
            # cmdlets_int_count = 0 # Internal functions called (can be noisy/complex)
            variables_count   = 0 # Unique variable names used (approx)
            parameters_count  = 0 # Parameters defined in functions/script
            complexity_score  = 0 # Cyclomatic complexity approximation
            requires_modules  = @() # Modules listed in #Requires -Modules
            dot_sources       = @() # Files included via dot-sourcing
        }
        $stopProcessing = $false

        # --- Handle PSD1 Files Differently (No AST Parsing) ---
        if ($FileInfo.Extension -eq '.psd1') {
             $metrics.analysis_status = 'Success (PSD1)'
             $metrics.complexity_score = 1 # Assign minimal complexity
             try {
                 $content = Get-Content -Path $FileInfo.FullName -Raw -Encoding Default -ErrorAction Stop
                  # Check for UTF8 BOM explicitly if Default failed or seems wrong
                 if ($content -match '[^\u0000-\u007F]') { try { $contentUtf8 = Get-Content -Path $FileInfo.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue; if ($contentUtf8) { $content = $contentUtf8 } } catch {}}
                 $lines = $content -split '\r?\n'
                 $metrics.total_lines = $lines.Count
                 $metrics.comment_lines = ($lines | Where-Object { $_.TrimStart() -match '^#' }).Count
                 $metrics.blank_lines = ($lines | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count
                 $metrics.code_lines = $metrics.total_lines - $metrics.comment_lines - $metrics.blank_lines # Treat data as 'code' lines here

                 # Extract #Requires -Modules from PSD1
                 $requiresMatches = $content | Select-String -Pattern '^\s*#Requires\s+-Modules?\s+(@\(.*?\)|[^\s]+)' -AllMatches
                 if ($requiresMatches) {
                      $metrics.requires_modules = $requiresMatches.Matches.Groups[1].Value -replace "@\(|\)|'", "" -split '\s*,\s*' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
                 }

             } catch {
                 $metrics.analysis_status = 'AnalysisError'
                 $metrics.error_message = "Error reading PSD1 file: $($_.Exception.Message)"
             }
             $result = [PSCustomObject]$metrics
             $stopProcessing = $true # Don't attempt AST parse on PSD1
        }

        # --- Process PS1/PSM1 Files ---
        if (-not $stopProcessing) {
            $parseErrors = $null
            $tokens = $null
            $ast = $null

            try {
                # --- Read File Content ---
                $content = Get-Content -Path $FileInfo.FullName -Raw -Encoding Default -ErrorAction Stop
                # Check for UTF8 BOM explicitly if Default failed or seems wrong
                if ($content -match '[^\u0000-\u007F]') { try { $contentUtf8 = Get-Content -Path $FileInfo.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue; if ($contentUtf8) { $content = $contentUtf8 } } catch {}}

                # --- Line Counts ---
                $lines = $content -split '\r?\n'
                $metrics.total_lines = $lines.Count
                $metrics.comment_lines = ($lines | Where-Object { $_.TrimStart() -match '^#' }).Count
                $metrics.blank_lines = ($lines | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count
                $metrics.code_lines = $metrics.total_lines - $metrics.comment_lines - $metrics.blank_lines

                # --- AST Parsing ---
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$parseErrors)

                if ($parseErrors.Count -gt 0) {
                    $metrics.analysis_status = 'ParseError'
                    $metrics.parse_errors = $parseErrors | ForEach-Object { "$($_.Message) at $($_.Extent.StartLineNumber):$($_.Extent.StartColumnNumber)" }
                    # Continue analysis despite parse errors if possible
                } else {
                     $metrics.analysis_status = 'Success'
                }

                # --- Extract Metrics using AST ---
                # Functions
                $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
                $metrics.functions_count = $functions.Count
                $metrics.functions = $functions.Name | Sort-Object -Unique

                # Cmdlets/Commands (approximation: CommandAst that isn't a function defined in *this* script)
                $definedFunctions = $metrics.functions # Assumes function names are unique identifiers
                $commands = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
                # Count unique external command names (typically Verb-Noun)
                $metrics.cmdlets_ext_count = ($commands | Where-Object { $_.CommandElements[0].Extent.Text -notin $definedFunctions -and $_.CommandElements[0].Extent.Text -match '^[A-Za-z]+-' } | Select-Object @{N='CommandName'; E={$_.GetCommandName()}} -Unique).Count

                # Variables (unique names used, excluding automatic variables like $this, $_, etc.)
                $automaticVars = 'this', '_', 'args', 'true', 'false', 'null', 'input', 'error', 'psitem', 'psscriptroot', 'pwd', 'home' # Common ones
                $variables = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)
                $metrics.variables_count = ($variables | Where-Object { $_.VariablePath.UserPath -notin $automaticVars } | Select-Object -ExpandProperty VariablePath | Select-Object -ExpandProperty UserPath -Unique).Count

                # Parameters (defined in functions or param blocks)
                $parameters = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ParameterAst] }, $true)
                $metrics.parameters_count = $parameters.Count

                # Complexity Score (Sum of control flow statements + logical operators)
                $complexityNodes = $ast.FindAll({
                    $node = $args[0]
                    # Control Flow Statements
                    $node -is [System.Management.Automation.Language.IfStatementAst] -or
                    $node -is [System.Management.Automation.Language.ForEachStatementAst] -or
                    $node -is [System.Management.Automation.Language.ForStatementAst] -or
                    $node -is [System.Management.Automation.Language.WhileStatementAst] -or
                    $node -is [System.Management.Automation.Language.SwitchStatementAst] -or
                    $node -is [System.Management.Automation.Language.TryStatementAst] -or
                    $node -is [System.Management.Automation.Language.CatchClauseAst] -or
                    # Logical Operators in conditions also add complexity paths
                    ($node -is [System.Management.Automation.Language.BinaryExpressionAst] -and $node.Operator -match 'and|or|xor')
                }, $true)
                $metrics.complexity_score = 1 + $complexityNodes.Count # Start with 1 for the entry point

                # #Requires -Modules
                $requiresAst = $ast.ScriptRequirements
                if($requiresAst -and $requiresAst.RequiredModules) {
                     $metrics.requires_modules = $requiresAst.RequiredModules | Select-Object -ExpandProperty ModuleName -Unique
                }

                # Dot-Sourcing
                $dotSourceCommands = $commands | Where-Object { $_.CommandElements[0].Extent.Text -eq '.' }
                $metrics.dot_sources = $dotSourceCommands | ForEach-Object {
                    # Try to resolve the path argument (can be complex)
                    $pathElement = $_.CommandElements | Select-Object -Skip 1 -First 1
                    if ($pathElement -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                        $pathElement.Value
                    } elseif ($pathElement -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
                         $pathElement.Extent.Text # Cannot resolve dynamic paths reliably here
                    } elseif ($pathElement -is [System.Management.Automation.Language.VariableExpressionAst]) {
                         '$(' + $pathElement.VariablePath.UserPath + ')' # Indicate variable path
                    } else {
                         $pathElement.Extent.Text # Best guess extent
                    }
                } | Select-Object -Unique


                $result = [PSCustomObject]$metrics

            } catch {
                $metrics.analysis_status = 'AnalysisError'
                $metrics.error_message = "Error during analysis: $($_.Exception.Message). Position: $($_.InvocationInfo.PositionMessage)"
                $result = [PSCustomObject]$metrics # Return partial metrics with error
            }
        } # End PS1/PSM1 Processing

        # --- Store in Cache ---
        if (-not $BypassCache -and $null -ne $cache -and $null -ne $result) {
            try {
                 Set-PSCacheItem -Cache $cache -Key $cacheKey -Value $result -ErrorAction SilentlyContinue
            } catch {
                 Write-Warning "Error setting cache for $($FileInfo.Name) (Key: $cacheKey). Error: $($_.Exception.Message)"
            }
        }
    } # End Cache Miss Processing

    # Output the result (from cache or newly generated)
    return $result
}

#endregion

#region Main Execution Logic

Write-Host "Starting PowerShell Script Analysis (v3)..." -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Find scripts
$scriptFileInfos = Find-PowerShellScripts -RootPath $ScriptsPath -Patterns $FilePatterns
$totalScriptsFound = $scriptFileInfos.Count
Write-Host "Found $totalScriptsFound scripts to analyze." -ForegroundColor Green

if ($totalScriptsFound -eq 0) {
    Write-Warning "No scripts found matching the specified patterns in '$ScriptsPath'. Exiting."
    return
}

# Prepare arguments for the parallel scriptblock
$invokeParallelArgs = @{
    InputObject = $scriptFileInfos
    ScriptBlock = $analysisScriptBlock
    MaxTasks = $MaxParallelTasks
    ArgumentList = @( # Pass necessary context to each task
        $analysisCache.Name # Pass cache name
        $ForceNoCache.IsPresent
    )
    # Import necessary modules into each runspace
    ModulesToImport = @('PSCacheManager') # Ensure cache cmdlets are available
    Verbose = $PSBoundParameters['Verbose'].IsPresent
    ErrorAction = 'SilentlyContinue' # Capture errors within results object
}

# Execute analysis in parallel
Write-Host "Analyzing $totalScriptsFound scripts using up to $MaxParallelTasks parallel tasks... (Cache enabled: $(!$ForceNoCache.IsPresent))"
$allResults = Invoke-OptimizedParallel @invokeParallelArgs

$stopwatch.Stop()
Write-Host "Parallel analysis completed in $($stopwatch.Elapsed.ToString('g'))" -ForegroundColor Green

# Process Results
if ($null -eq $allResults -or $allResults.Count -eq 0) {
     Write-Error "No results returned from parallel analysis. Check Invoke-OptimizedParallel function and runspace errors."
     return
}

$validResults = $allResults | Where-Object { $null -ne $_ -and ($_.analysis_status -eq 'Success' -or $_.analysis_status -eq 'Success (PSD1)') }
$errorResults = $allResults | Where-Object { $null -ne $_.analysis_status -and $_.analysis_status -match 'Error' }
$parseErrorResults = $allResults | Where-Object { $_.analysis_status -eq 'ParseError' }

$totalProcessed = $allResults.Count
$totalSuccess = $validResults.Count
$totalFailed = $errorResults.Count
$totalWithParseErrors = $parseErrorResults.Count

Write-Host "`nAnalysis Summary:" -ForegroundColor Yellow
Write-Host "  Total Scripts Processed: $totalProcessed / $totalScriptsFound"
Write-Host "  Successful Analyses:     $totalSuccess"
Write-Host "  Analyses with Errors:    $totalFailed"
Write-Host "  Files with Parse Errors: $totalWithParseErrors" -ForegroundColor DarkYellow

if ($totalFailed -gt 0) {
    Write-Warning "$totalFailed scripts encountered analysis errors. Check the results file for details."
    # Optionally list failed files:
    # $errorResults | Select-Object file_name, error_message | Format-Table -Wrap -AutoSize
}
if ($totalWithParseErrors -gt 0) {
    Write-Warning "$totalWithParseErrors files could not be fully parsed. Metrics may be incomplete. Check the results file for details."
     # Optionally list files with parse errors:
    # $parseErrorResults | Select-Object file_name, @{N='FirstError';E={$_.parse_errors[0]}} | Format-Table -Wrap -AutoSize
}


# Aggregate Statistics from successful results
if ($totalSuccess -gt 0) {
    # Filter out PSD1 files for metrics that don't apply (e.g., complexity, functions)
    $scriptResults = $validResults | Where-Object { $_.file_extension -ne '.psd1' }
    $psd1Count = ($validResults | Where-Object { $_.file_extension -eq '.psd1' }).Count

    $totalLines = ($validResults | Measure-Object -Property total_lines -Sum -ErrorAction SilentlyContinue).Sum
    $totalCodeLines = ($validResults | Measure-Object -Property code_lines -Sum -ErrorAction SilentlyContinue).Sum
    $totalCommentLines = ($validResults | Measure-Object -Property comment_lines -Sum -ErrorAction SilentlyContinue).Sum
    $totalFunctions = ($scriptResults | Measure-Object -Property functions_count -Sum -ErrorAction SilentlyContinue).Sum
    $avgComplexity = ($scriptResults | Measure-Object -Property complexity_score -Average -ErrorAction SilentlyContinue).Average
    $avgFileSize = ($validResults | Measure-Object -Property file_size_bytes -Average -ErrorAction SilentlyContinue).Average

    Write-Host "`nAggregated Metrics (Successful Analyses):" -ForegroundColor Yellow
    Write-Host ("  Total Lines:        {0:N0}" -f $totalLines)
    Write-Host ("  Total Code Lines:   {0:N0} ({1:P1} of total)" -f $totalCodeLines, (if($totalLines -gt 0) {$totalCodeLines / $totalLines} else {0}))
    Write-Host ("  Total Comment Lines:{0:N0}" -f $totalCommentLines)
    if($scriptResults.Count -gt 0) {
        Write-Host ("  Total Functions:    {0:N0} (in {1} scripts)" -f $totalFunctions, $scriptResults.Count)
        Write-Host ("  Avg Complexity:     {0:N2} (scripts only)" -f $avgComplexity)
    }
    Write-Host ("  PSD1 Files Analyzed:{0:N0}" -f $psd1Count)
    Write-Host ("  Avg File Size:      {0:N2} KB" -f ($avgFileSize / 1KB))

    # Identify most complex files (excluding PSD1)
    $complexFiles = $scriptResults | Where-Object { $_.complexity_score -gt 0 } | Sort-Object -Property complexity_score -Descending | Select-Object -First 10
    if ($complexFiles) {
        Write-Host "`nTop 10 Most Complex Scripts (Successfully Analyzed):" -ForegroundColor Yellow
        $complexFiles | Format-Table -Property @{N='Complexity';E={$_.complexity_score}}, file_name -AutoSize
    }
} else {
     Write-Warning "No scripts were analyzed successfully."
}

# Save Results
$resultsFileName = "ScriptAnalysisResults_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$resultsPath = Join-Path -Path $OutputPath -ChildPath $resultsFileName

Write-Host "`nSaving detailed results ($($allResults.Count) items) to '$resultsPath'..." -ForegroundColor Green
try {
    # Ensure PSCustomObjects are preserved correctly
    $jsonOutput = $allResults | ConvertTo-Json -Depth 10
    $jsonOutput | Out-File -FilePath $resultsPath -Encoding utf8 -ErrorAction Stop
    Write-Host "Results saved successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to save results to '$resultsPath'. Error: $($_.Exception.Message)"
}

# Optional: Clear cache expired items if needed
# if ($PSCmdlet.ShouldProcess("cache '$($analysisCache.Name)'", "Clear expired items")) {
#    Clear-PSCache -Cache $analysisCache -ExpiredOnly
# }

Write-Host "`nScript Analysis Finished." -ForegroundColor Cyan

#endregion
