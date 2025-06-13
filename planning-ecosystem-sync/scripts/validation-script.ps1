# PowerShell Automation Script for Planning Ecosystem Sync
# Plan-dev-v55 Branch Architecture Implementation
# Version: 2.0 (Post-Audit Implementation) 
# Date: June 11, 2025

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("setup", "validate", "test", "sync", "monitor", "all")]
    [string]$Action = "validate"
)

# Configuration
$ProjectRoot = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$SyncBranchPath = "$ProjectRoot\planning-ecosystem-sync"

function Write-StatusMessage {
    param([string]$Message, [string]$Type = "Info")
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    switch ($Type) {
        "Success" { Write-Host "[$timestamp] [OK] $Message" -ForegroundColor Green }
        "Warning" { Write-Host "[$timestamp] [WARN] $Message" -ForegroundColor Yellow }
        "Error"   { Write-Host "[$timestamp] [ERROR] $Message" -ForegroundColor Red }
        default   { Write-Host "[$timestamp] [INFO] $Message" -ForegroundColor Cyan }
    }
}

function Test-DirectoryStructure {
    Write-StatusMessage "Validating branch architecture structure..." "Info"
    
    $requiredDirs = @("docs", "tools", "config", "scripts", "tests")
    $missingDirs = @()
    
    foreach ($dir in $requiredDirs) {
        $fullPath = "$SyncBranchPath\$dir"
        if (-not (Test-Path $fullPath)) {
            $missingDirs += $dir
        } else {
            Write-StatusMessage "Directory exists: $dir" "Success"
        }
    }
    
    if ($missingDirs.Count -gt 0) {
        Write-StatusMessage "Missing directories: $($missingDirs -join ', ')" "Error"
        return $false
    }
    
    Write-StatusMessage "Branch architecture structure validated successfully" "Success"
    return $true
}

function Test-ConfigurationFiles {
    Write-StatusMessage "Validating configuration files..." "Info"
    
    $requiredFiles = @(
        "$SyncBranchPath\config\sync-config.yaml",
        "$SyncBranchPath\config\validation-rules.yaml"
    )
    
    $missingFiles = @()
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            $missingFiles += (Split-Path $file -Leaf)
        } else {
            Write-StatusMessage "Configuration file exists: $(Split-Path $file -Leaf)" "Success"
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-StatusMessage "Missing configuration files: $($missingFiles -join ', ')" "Error"
        return $false
    }
    
    Write-StatusMessage "Configuration files validated successfully" "Success"
    return $true
}

function Invoke-UnitTests {
    Write-StatusMessage "Running unit tests..." "Info"
    
    $TestsPath = "$SyncBranchPath\tests"
    if (-not (Test-Path "$TestsPath\go.mod")) {
        Write-StatusMessage "Go module not found in tests directory" "Error"
        return $false
    }
    
    try {
        Push-Location $TestsPath
        $testOutput = go test -v 2>&1
        $testExitCode = $LASTEXITCODE
        
        if ($testExitCode -eq 0) {
            Write-StatusMessage "All unit tests passed successfully" "Success"
            return $true
        } else {
            Write-StatusMessage "Unit tests failed with exit code: $testExitCode" "Error"
            return $false
        }
    }
    catch {
        Write-StatusMessage "Error running unit tests: $($_.Exception.Message)" "Error"
        return $false
    }
    finally {
        Pop-Location
    }
}

function Invoke-FullValidation {
    Write-StatusMessage "Starting comprehensive validation..." "Info"
    
    $results = @{
        "Architecture" = Test-DirectoryStructure
        "Configuration" = Test-ConfigurationFiles
        "Unit Tests" = Invoke-UnitTests
    }
    
    $successCount = 0
    foreach ($component in $results.Keys) {
        if ($results[$component]) {
            Write-StatusMessage "$component validation: PASSED" "Success"
            $successCount++
        } else {
            Write-StatusMessage "$component validation: FAILED" "Error"
        }
    }
    
    Write-StatusMessage "Validation Summary: $successCount/$($results.Count) steps successful" "Info"
    
    if ($successCount -eq $results.Count) {
        Write-StatusMessage "All validation steps completed successfully!" "Success"
        Write-StatusMessage "Plan-dev-v55 branch architecture implementation is COMPLETE" "Success"
        return $true
    } else {
        Write-StatusMessage "Some validation steps failed. Please review the output above." "Error"
        return $false
    }
}

# Main execution
Write-StatusMessage "Planning Ecosystem Sync - Automation Script v2.0" "Info"
Write-StatusMessage "Action: $Action" "Info"

switch ($Action) {
    "validate" {
        $success = Test-DirectoryStructure -and Test-ConfigurationFiles
        if ($success) { exit 0 } else { exit 1 }
    }
    "test" {
        $success = Invoke-UnitTests
        if ($success) { exit 0 } else { exit 1 }
    }
    "all" {
        $success = Invoke-FullValidation
        if ($success) { exit 0 } else { exit 1 }
    }
    default {
        Write-StatusMessage "Unknown action: $Action" "Error"
        exit 1
    }
}
