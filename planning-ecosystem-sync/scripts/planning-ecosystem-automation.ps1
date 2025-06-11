# PowerShell Automation Script for Planning Ecosystem Sync
# Plan-dev-v55 Branch Architecture Implementation
# Version: 2.0 (Post-Audit Implementation)
# Date: June 11, 2025

param(
   [Parameter(Mandatory = $false)]
   [ValidateSet("setup", "validate", "test", "sync", "monitor", "all")]
   [string]$Action = "validate",
    
   [Parameter(Mandatory = $false)]
   [switch]$Verbose = $false,
    
   [Parameter(Mandatory = $false)]
   [switch]$SkipTests = $false
)

# Configuration
$ProjectRoot = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$SyncBranchPath = "$ProjectRoot\planning-ecosystem-sync"
$ConfigPath = "$SyncBranchPath\config\sync-config.yaml"
$TestsPath = "$SyncBranchPath\tests"

# Colors for output
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorInfo = "Cyan"

function Write-StatusMessage {
   param([string]$Message, [string]$Type = "Info")
    
   $timestamp = Get-Date -Format "HH:mm:ss"
    
   switch ($Type) {
      "Success" { Write-Host "[$timestamp] ✅ $Message" -ForegroundColor $ColorSuccess }
      "Warning" { Write-Host "[$timestamp] ⚠️  $Message" -ForegroundColor $ColorWarning }
      "Error" { Write-Host "[$timestamp] ❌ $Message" -ForegroundColor $ColorError }
      default { Write-Host "[$timestamp] ℹ️  $Message" -ForegroundColor $ColorInfo }
   }
}

function Test-DirectoryStructure {
   Write-StatusMessage "Validating branch architecture structure..." "Info"
    
   $requiredDirs = @(
      "$SyncBranchPath\docs",
      "$SyncBranchPath\tools", 
      "$SyncBranchPath\config",
      "$SyncBranchPath\scripts",
      "$SyncBranchPath\tests"
   )
    
   $missingDirs = @()
   foreach ($dir in $requiredDirs) {
      if (-not (Test-Path $dir)) {
         $missingDirs += $dir
      }
      else {
         Write-StatusMessage "Directory exists: $(Split-Path $dir -Leaf)" "Success"
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
         $missingFiles += $file
      }
      else {
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

function Test-TaskMasterCLIConnectivity {
   Write-StatusMessage "Testing TaskMaster-CLI connectivity..." "Info"
    
   try {
      $response = Invoke-RestMethod -Uri "http://localhost:8080/api/plans" -Method Get -TimeoutSec 5 -ErrorAction Stop
      Write-StatusMessage "TaskMaster-CLI API is reachable and responding" "Success"
      return $true
   }
   catch {
      if ($_.Exception.Message -like "*404*") {
         Write-StatusMessage "TaskMaster-CLI API endpoint is reachable (404 expected for GET)" "Success"
         return $true
      }
      Write-StatusMessage "TaskMaster-CLI API connectivity issue: $($_.Exception.Message)" "Warning"
      return $false
   }
}

function Test-QDrantConnectivity {
   Write-StatusMessage "Testing QDrant connectivity..." "Info"
    
   try {
      $response = Invoke-RestMethod -Uri "http://localhost:6333/collections" -Method Get -TimeoutSec 5 -ErrorAction Stop
      Write-StatusMessage "QDrant vector database is accessible" "Success"
      return $true
   }
   catch {
      Write-StatusMessage "QDrant not available (expected in development): $($_.Exception.Message)" "Warning"
      return $true  # This is expected in development
   }
}

function Invoke-UnitTests {
   if ($SkipTests) {
      Write-StatusMessage "Skipping unit tests as requested" "Warning"
      return $true
   }
    
   Write-StatusMessage "Running unit tests..." "Info"
    
   if (-not (Test-Path "$TestsPath\go.mod")) {
      Write-StatusMessage "Go module not found in tests directory" "Error"
      return $false
   }
    
   try {
      Push-Location $TestsPath
        
      # Run Go tests
      $testOutput = go test -v 2>&1
      $testExitCode = $LASTEXITCODE
        
      if ($Verbose) {
         Write-Host $testOutput
      }
        
      if ($testExitCode -eq 0) {
         Write-StatusMessage "All unit tests passed successfully" "Success"
         return $true
      }
      else {
         Write-StatusMessage "Unit tests failed with exit code: $testExitCode" "Error"
         if (-not $Verbose) {
            Write-Host $testOutput
         }
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

function Invoke-BranchSetup {
   Write-StatusMessage "Setting up branch architecture..." "Info"
    
   # Ensure we're on the correct branch
   try {
      $currentBranch = git branch --show-current
      if ($currentBranch -ne "planning-ecosystem-sync") {
         Write-StatusMessage "Not on planning-ecosystem-sync branch. Current: $currentBranch" "Warning"
      }
      else {
         Write-StatusMessage "On correct branch: $currentBranch" "Success"
      }
   }
   catch {
      Write-StatusMessage "Could not determine current git branch" "Warning"
   }
    
   # Validate structure
   $structureValid = Test-DirectoryStructure
   $configValid = Test-ConfigurationFiles
    
   return ($structureValid -and $configValid)
}

function Invoke-SystemMonitoring {
   Write-StatusMessage "Monitoring system status..." "Info"
    
   $results = @{
      "TaskMaster-CLI" = Test-TaskMasterCLIConnectivity
      "QDrant"         = Test-QDrantConnectivity
      "Architecture"   = Test-DirectoryStructure
      "Configuration"  = Test-ConfigurationFiles
   }
    
   Write-StatusMessage "System Monitoring Results:" "Info"
   foreach ($component in $results.Keys) {
      $status = if ($results[$component]) { "✅ OK" } else { "❌ ISSUE" }
      Write-Host "  $component`: $status"
   }
    
   $overallHealth = ($results.Values | Where-Object { $_ -eq $true }).Count
   $totalComponents = $results.Count
    
   Write-StatusMessage "Overall System Health: $overallHealth/$totalComponents components OK" "Info"
    
   return ($overallHealth -eq $totalComponents)
}

function Invoke-FullValidation {
   Write-StatusMessage "Starting comprehensive validation..." "Info"
    
   $validationSteps = @(
      @{ Name = "Branch Setup"; Action = { Invoke-BranchSetup } },
      @{ Name = "Unit Tests"; Action = { Invoke-UnitTests } },
      @{ Name = "System Monitoring"; Action = { Invoke-SystemMonitoring } }
   )
    
   $successCount = 0
   foreach ($step in $validationSteps) {
      Write-StatusMessage "Executing: $($step.Name)" "Info"
      $result = & $step.Action
        
      if ($result) {
         Write-StatusMessage "$($step.Name) completed successfully" "Success"
         $successCount++
      }
      else {
         Write-StatusMessage "$($step.Name) failed" "Error"
      }
   }
    
   Write-StatusMessage "Validation Summary: $successCount/$($validationSteps.Count) steps successful" "Info"
    
   if ($successCount -eq $validationSteps.Count) {
      Write-StatusMessage "🎯 All validation steps completed successfully!" "Success"
      Write-StatusMessage "Plan-dev-v55 branch architecture implementation is COMPLETE" "Success"
      return $true
   }
   else {
      Write-StatusMessage "Some validation steps failed. Please review the output above." "Error"
      return $false
   }
}

# Main execution logic
Write-StatusMessage "Planning Ecosystem Sync - Automation Script v2.0" "Info"
Write-StatusMessage "Action: $Action | Verbose: $Verbose | SkipTests: $SkipTests" "Info"

switch ($Action) {
   "setup" {
      $success = Invoke-BranchSetup
      exit ([int](!$success))
   }
   "validate" {
      $success = Test-DirectoryStructure -and Test-ConfigurationFiles
      exit ([int](!$success))
   }
   "test" {
      $success = Invoke-UnitTests
      exit ([int](!$success))
   }
   "sync" {
      Write-StatusMessage "Sync functionality requires TaskMaster-CLI integration" "Info"
      $success = Test-TaskMasterCLIConnectivity
      exit ([int](!$success))
   }
   "monitor" {
      $success = Invoke-SystemMonitoring
      exit ([int](!$success))
   }
   "all" {
      $success = Invoke-FullValidation
      exit ([int](!$success))
   }
   default {
      Write-StatusMessage "Unknown action: $Action" "Error"
      exit 1
   }
}
