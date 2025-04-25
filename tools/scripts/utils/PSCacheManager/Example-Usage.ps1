<#
.SYNOPSIS
    Demonstrates usage of the improved PSCacheManager module v2.0.
.DESCRIPTION
    Shows how to create caches with different configurations (LRU/LFU, TTL),
    use Get-PSCacheItem with -GenerateValue for costly operations,
    utilize tags, remove items, and view statistics.
.EXAMPLE
    .\Example-Usage.ps1 -Verbose
.NOTES
    Author: Augment Agent (Improved by AI)
    Version: 2.0
    Requires: PSCacheManager.psm1 (v2.0+) in the same directory or PowerShell module path.
    Compatibilité: PowerShell 5.1 et supérieur
#>

param(
    [switch]$RunWithVerbose # Add switch to easily enable verbose output from cache module
)

# Construct the path to the module file relative to this script
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "PSCacheManager.psm1"

# Import the module
try {
    Write-Host "Importing PSCacheManager module from '$modulePath'..." -ForegroundColor Gray
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Host "Module imported successfully." -ForegroundColor Gray
}
catch {
    Write-Error "Failed to import PSCacheManager module at '$modulePath'. Please ensure the file exists. Error: $($_.Exception.Message)"
    exit 1
}

# --- Cache Initialization ---
Write-Host "`nInitializing Caches..." -ForegroundColor Cyan

# Cache for script analysis results (LRU, 1 hour TTL)
$scriptCache = New-PSCache -Name "ScriptAnalysis" -MaxMemoryItems 50 -DefaultTTLSeconds 3600 # Smaller size for demo

# Cache for encoding detection results (LFU, long TTL, extends on access)
$encodingCache = New-PSCache -Name "EncodingDetection" -MaxMemoryItems 100 -DefaultTTLSeconds 86400 -EvictionPolicy LFU -ExtendTtlOnAccess:$true

if (-not $scriptCache -or -not $encodingCache) {
    Write-Error "Failed to initialize one or more caches. Exiting."
    exit 1
}

Write-Host "Caches '$($scriptCache.Name)' and '$($encodingCache.Name)' initialized." -ForegroundColor Green

# --- Helper Functions Using Cache ---

# Function to analyze a script PowerShell using cache
function Test-ScriptWithCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$CacheInstance, # Should be a CacheManager object

        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    # Validate input file
    $scriptFileInfo = Get-Item -Path $ScriptPath -ErrorAction SilentlyContinue
    if (-not $scriptFileInfo) {
        Write-Error "Script file not found: $ScriptPath"
        return $null
    }

    # Cache key incorporates file path and last write time for automatic invalidation on change
    $cacheKey = "ScriptAnalysis:$($scriptFileInfo.FullName):$($scriptFileInfo.LastWriteTimeUtc.Ticks)"
    $cacheArgs = @{
        Cache = $CacheInstance
        Key   = $cacheKey
        GenerateValue = {
            # Capture variables from parent scope
            $Path = $ScriptPath
            $FileInfo = $scriptFileInfo

            # Use Write-Host or Write-Verbose inside GenerateValue for feedback
            Write-Host " -> Generating analysis for '$($FileInfo.Name)' (Cache Miss)..." -ForegroundColor Yellow
            # Simulate expensive operation
            Start-Sleep -Milliseconds (Get-Random -Minimum 200 -Maximum 600)

            $content = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
            if ($null -eq $content) { return $null } # Handle read error

            $tokens = $null
            $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$parseErrors)

            $commands = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
            $variables = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)
            $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

            return [PSCustomObject]@{
                ScriptPath      = $Path
                ScriptName      = $FileInfo.Name
                LastModifiedUtc = $FileInfo.LastWriteTimeUtc
                SizeBytes       = $FileInfo.Length
                LineCount       = ($content -split "`r?`n").Count # Robust line count
                CommandCount    = $commands.Count
                VariableCount   = $variables.Count
                FunctionCount   = $functions.Count
                HasParseErrors  = $parseErrors.Count -gt 0
                ParseErrors     = if ($parseErrors.Count -gt 0) { $parseErrors } else { $null }
                AnalysisTime    = Get-Date
            }
        }
        # Override default TTL for this specific item if needed
        # TTLSeconds = 7200
        Tags = @("Analysis", "Script", $scriptFileInfo.Extension) # Add relevant tags
    }
    # Add Verbose preference if the main script was called with -Verbose
    if($PSBoundParameters['RunWithVerbose']) { $cacheArgs.Verbose = $true }

    $analysisResult = Get-PSCacheItem @cacheArgs

    if ($null -ne $analysisResult) {
         Write-Host " -> Analysis retrieved for '$($scriptFileInfo.Name)' (Cache Hit)" -ForegroundColor Green
    }

    return $analysisResult
}

# Function to detect file encoding using cache
function Get-FileEncodingWithCache {
     [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$CacheInstance, # Should be a CacheManager object

        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

     # Validate input file
    $fileInfo = Get-Item -Path $FilePath -ErrorAction SilentlyContinue
    if (-not $fileInfo) {
        Write-Error "File not found: $FilePath"
        return $null
    }

    # Cache key based on path and modification time
    $cacheKey = "EncodingDetection:$($fileInfo.FullName):$($fileInfo.LastWriteTimeUtc.Ticks)"
    $cacheArgs = @{
        Cache = $CacheInstance
        Key   = $cacheKey
        GenerateValue = {
            # Capture variables from parent scope
            $Path = $FilePath
            $FileInfo = $fileInfo

            Write-Host " -> Detecting encoding for '$($FileInfo.Name)' (Cache Miss)..." -ForegroundColor Yellow
            # Simulate detection time
            Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 250)

            $encoding = [System.Text.Encoding]::Default # Start with a default
            $hasBOM = $false
            try {
                 # Use StreamReader for robust detection (handles BOMs automatically)
                 $reader = [System.IO.StreamReader]::new($Path, $true) # $true detects encoding from BOM
                 $encoding = $reader.CurrentEncoding
                 # Check if BOM was actually present
                 $bomBytes = $encoding.GetPreamble()
                 if ($bomBytes.Length -gt 0) {
                     $fileBytes = [System.IO.File]::ReadAllBytes($Path)
                     if ($fileBytes.Length -ge $bomBytes.Length) {
                         $prefix = $fileBytes[0..($bomBytes.Length - 1)]
                         if ([System.Linq.Enumerable]::SequenceEqual($prefix, $bomBytes)) {
                             $hasBOM = $true
                         }
                     }
                 }
                 $reader.Dispose()
            } catch {
                 Write-Warning "Error reading file '$Path' for encoding detection: $($_.Exception.Message)"
                 # Fallback or return error? Let's return unknown.
                 return [PSCustomObject]@{
                    FilePath         = $Path
                    FileName         = $FileInfo.Name
                    EncodingName     = "Error Reading File"
                    EncodingCodepage = -1
                    HasBOM           = $false
                    DetectionTime    = Get-Date
                 }
            }

             return [PSCustomObject]@{
                FilePath         = $Path
                FileName         = $FileInfo.Name
                EncodingName     = $encoding.EncodingName
                EncodingCodepage = $encoding.CodePage
                HasBOM           = $hasBOM
                DetectionTime    = Get-Date
            }
        }
        Tags = @("Encoding", "FileMeta", $fileInfo.Extension)
    }
    if($PSBoundParameters['RunWithVerbose']) { $cacheArgs.Verbose = $true }

    $encodingResult = Get-PSCacheItem @cacheArgs

     if ($null -ne $encodingResult -and $encodingResult.EncodingCodepage -ne -1) {
         Write-Host " -> Encoding retrieved for '$($fileInfo.Name)' (Cache Hit)" -ForegroundColor Green
    }

    return $encodingResult
}

# --- Demonstration ---
Write-Host "`n--- PSCacheManager Demonstration ---" -ForegroundColor Cyan

# Target file for tests (use the module itself)
$testFilePath = $modulePath

# == Script Analysis Demo ==
Write-Host "`n1. Script Analysis Caching (Cache: $($scriptCache.Name))" -ForegroundColor Yellow

# First call (Miss)
Write-Host "`n[Call 1 - Expect Cache Miss]"
$sw1 = [System.Diagnostics.Stopwatch]::StartNew()
$analysis1 = Test-ScriptWithCache -CacheInstance $scriptCache -ScriptPath $testFilePath
$sw1.Stop()
Write-Host "Execution Time: $($sw1.ElapsedMilliseconds) ms"

# Second call (Hit)
Write-Host "`n[Call 2 - Expect Cache Hit]"
$sw2 = [System.Diagnostics.Stopwatch]::StartNew()
$analysis2 = Test-ScriptWithCache -CacheInstance $scriptCache -ScriptPath $testFilePath

# Compare results to verify cache consistency
Write-Host "Verification: Results identical? $($analysis1.CommandCount -eq $analysis2.CommandCount -and $analysis1.VariableCount -eq $analysis2.VariableCount)"
$sw2.Stop()
Write-Host "Execution Time: $($sw2.ElapsedMilliseconds) ms"

# Display some analysis results
if ($analysis1) {
    Write-Host "`nSample Analysis Results ('$($analysis1.ScriptName)'):"
    Write-Host "  Commands: $($analysis1.CommandCount)"
    Write-Host "  Functions: $($analysis1.FunctionCount)"
    Write-Host "  Variables: $($analysis1.VariableCount)"
    Write-Host "  Last Modified (UTC): $($analysis1.LastModifiedUtc)"
} else { Write-Warning "Analysis failed." }

# == Encoding Detection Demo ==
Write-Host "`n2. Encoding Detection Caching (Cache: $($encodingCache.Name))" -ForegroundColor Yellow

# First call (Miss)
Write-Host "`n[Call 1 - Expect Cache Miss]"
$sw3 = [System.Diagnostics.Stopwatch]::StartNew()
$encoding1 = Get-FileEncodingWithCache -CacheInstance $encodingCache -FilePath $testFilePath
$sw3.Stop()
Write-Host "Execution Time: $($sw3.ElapsedMilliseconds) ms"

# Second call (Hit)
Write-Host "`n[Call 2 - Expect Cache Hit]"
$sw4 = [System.Diagnostics.Stopwatch]::StartNew()
$encoding2 = Get-FileEncodingWithCache -CacheInstance $encodingCache -FilePath $testFilePath

# Compare results to verify cache consistency
Write-Host "Verification: Encodings identical? $($encoding1.Encoding -eq $encoding2.Encoding -and $encoding1.HasBOM -eq $encoding2.HasBOM)"
$sw4.Stop()
Write-Host "Execution Time: $($sw4.ElapsedMilliseconds) ms"

# Display encoding results
if ($encoding1) {
    Write-Host "`nSample Encoding Results ('$($encoding1.FileName)'):"
    Write-Host "  Encoding Name: $($encoding1.EncodingName)"
    Write-Host "  CodePage: $($encoding1.EncodingCodepage)"
    Write-Host "  Has BOM: $($encoding1.HasBOM)"
} else { Write-Warning "Encoding detection failed." }

# == Test-PSCacheItem Demo ==
Write-Host "`n3. Testing Cache Key Existence" -ForegroundColor Yellow
$testKey = "TestKey_$(Get-Random)"
Write-Host "Testing if key '$testKey' exists before adding it..."
$existsBefore = Test-PSCacheItem -Cache $scriptCache -Key $testKey
Write-Host "Key '$testKey' exists before adding: $existsBefore"

Write-Host "Adding item with key '$testKey'..."
Set-PSCacheItem -Cache $scriptCache -Key $testKey -Value "Test value" -TTLSeconds 60 -Tags "Test", "Demo" -Verbose:$RunWithVerbose

Write-Host "Testing if key '$testKey' exists after adding it..."
$existsAfter = Test-PSCacheItem -Cache $scriptCache -Key $testKey
Write-Host "Key '$testKey' exists after adding: $existsAfter"

# == Tag Removal Demo ==
Write-Host "`n4. Tag-Based Removal Demo" -ForegroundColor Yellow
$tempDataKey = "TempData_$(Get-Random)"
Write-Host "Adding temporary item with tag 'Temporary': $tempDataKey"
Set-PSCacheItem -Cache $scriptCache -Key $tempDataKey -Value "This is temporary" -TTLSeconds 60 -Tags "Temporary", "Demo" -Verbose:$RunWithVerbose
Write-Host "Item count before removal: $((Get-PSCacheStatistics -Cache $scriptCache).MemoryItemCount)"
Write-Host "Removing items with tag 'Temporary'..."
Remove-PSCacheItem -Cache $scriptCache -Tag "Temporary" -Confirm:$false # Use -Confirm:$false for automation
Write-Host "Item count after removal: $((Get-PSCacheStatistics -Cache $scriptCache).MemoryItemCount)"


# == Statistics Display ==
Write-Host "`n5. Cache Statistics" -ForegroundColor Cyan
Write-Host "`n--- $($scriptCache.Name) Statistics ---" -ForegroundColor Yellow
Get-PSCacheStatistics -Cache $scriptCache | Format-List
Write-Host "`n--- $($encodingCache.Name) Statistics ---" -ForegroundColor Yellow
Get-PSCacheStatistics -Cache $encodingCache | Format-List


# == Cleanup (Optional) ==
# Write-Host "`nClearing expired items..."
# Clear-PSCache -Cache $scriptCache -ExpiredOnly
# Clear-PSCache -Cache $encodingCache -ExpiredOnly

# Write-Host "`nCompletely clearing caches..."
# Clear-PSCache -Cache $scriptCache
# Clear-PSCache -Cache $encodingCache

Write-Host "`n--- Demonstration Complete ---" -ForegroundColor Cyan