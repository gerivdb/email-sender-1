# Emergency-Diagnostic-Test.ps1
# Version de test simplifiée pour validation

param(
   [switch]$AllPhases,
   [switch]$RunDiagnostic,
   [switch]$RunRepair,
   [switch]$EmergencyStop
)

# Configuration
$CONFIG = @{
   MaxCPUUsage   = 70
   MaxRAMUsageGB = 6
   LogFile       = "emergency-diagnostic.log"
}

$Colors = @{
   Error    = "Red"
   Warning  = "Yellow" 
   Success  = "Green"
   Info     = "Cyan"
   Critical = "Magenta"
   Header   = "Blue"
}

function Write-DiagnosticLog {
   param([string]$Message, [string]$Level = "Info")
    
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logEntry = "[$timestamp] [$Level] $Message"
    
   Write-Host $logEntry -ForegroundColor $Colors[$Level]
   Add-Content -Path $CONFIG.LogFile -Value $logEntry -ErrorAction SilentlyContinue
}

function Write-SectionHeader {
   param([string]$Title)
   Write-Host "`n" + "="*80 -ForegroundColor $Colors.Header
   Write-Host "*** $Title ***" -ForegroundColor $Colors.Header
   Write-Host "="*80 -ForegroundColor $Colors.Header
}

function Test-APIServerHealth {
   Write-SectionHeader "API SERVER HEALTH CHECK"
    
   try {
      Write-DiagnosticLog "Testing API Server on localhost:8080..." "Info"
      $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 5 -ErrorAction Stop
      Write-DiagnosticLog "API Server is responsive (Status: $($response.StatusCode))" "Success"
      return $true
   }
   catch {
      Write-DiagnosticLog "API Server health check failed: $($_.Exception.Message)" "Warning"
      return $false
   }
}

function Get-SystemResources {
   Write-SectionHeader "SYSTEM RESOURCE ANALYSIS"
    
   try {
      # Memory Usage
      $memory = Get-CimInstance -ClassName Win32_OperatingSystem
      $totalMemoryGB = [Math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
      $freeMemoryGB = [Math]::Round($memory.FreePhysicalMemory / 1MB, 2)
      $usedMemoryGB = [Math]::Round($totalMemoryGB - $freeMemoryGB, 2)
        
      Write-DiagnosticLog "Memory: $usedMemoryGB GB / $totalMemoryGB GB used" "Info"
        
      # Process count
      $processCount = (Get-Process).Count
      Write-DiagnosticLog "Running processes: $processCount" "Info"
        
      return @{
         MemoryUsedGB  = $usedMemoryGB
         MemoryTotalGB = $totalMemoryGB
         ProcessCount  = $processCount
      }
   }
   catch {
      Write-DiagnosticLog "Failed to get system resources: $($_.Exception.Message)" "Error"
      return $null
   }
}

function Invoke-BasicRepair {
   Write-SectionHeader "BASIC SYSTEM REPAIR"
    
   Write-DiagnosticLog "Starting basic repair procedures..." "Info"
    
   try {
      # Test API Server
      $apiHealthy = Test-APIServerHealth
      if (-not $apiHealthy) {
         Write-DiagnosticLog "API Server not responding - would attempt restart" "Warning"
      }
        
      Write-DiagnosticLog "Basic repair simulation completed" "Success"
      return $true
   }
   catch {
      Write-DiagnosticLog "Basic repair failed: $($_.Exception.Message)" "Error"
      return $false
   }
}

function Invoke-EmergencyStop {
   Write-SectionHeader "EMERGENCY STOP"
    
   Write-DiagnosticLog "Emergency stop initiated" "Critical"
   Write-DiagnosticLog "This would stop non-critical processes" "Info"
   Write-DiagnosticLog "Emergency stop simulation completed" "Success"
}

# Main execution logic
Write-SectionHeader "EMERGENCY DIAGNOSTIC v2.0 - TEST VERSION"

if ($EmergencyStop) {
   Invoke-EmergencyStop
   exit 0
}

$diagnosticResults = @{}

# Run diagnostic (default or explicit)
if ($AllPhases -or $RunDiagnostic -or (-not $RunRepair)) {
   Write-DiagnosticLog "Running diagnostic phase..." "Info"
    
   $apiHealth = Test-APIServerHealth
   $resources = Get-SystemResources
    
   $diagnosticResults.APIHealth = $apiHealth
   $diagnosticResults.Resources = $resources
    
   Write-DiagnosticLog "Diagnostic phase completed" "Success"
}

# Run repair if requested
if ($AllPhases -or $RunRepair) {
   Write-DiagnosticLog "Running repair phase..." "Info"
    
   $repairSuccess = Invoke-BasicRepair
   $diagnosticResults.RepairSuccess = $repairSuccess
    
   Write-DiagnosticLog "Repair phase completed" "Success"
}

# Summary
Write-SectionHeader "DIAGNOSTIC SUMMARY"
Write-DiagnosticLog "Emergency diagnostic test completed successfully" "Success"
Write-DiagnosticLog "Results saved to log file: $($CONFIG.LogFile)" "Info"

exit 0
