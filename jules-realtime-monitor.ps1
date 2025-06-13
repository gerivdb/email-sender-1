# =============================================================================
# Jules Bot Real-Time Monitoring System
# Surveillance en temps réel des contributions de google-labs-jules[bot]
# =============================================================================

param(
   [string]$Mode = "watch",
   [int]$IntervalSeconds = 30,
   [switch]$Silent,
   [switch]$LogToFile,
   [string]$LogFile = "logs\real-time-monitoring.log"
)

$ProjectPath = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$BotName = "google-labs-jules[bot]"

# Ensure logs directory exists
$LogDir = Split-Path (Join-Path $ProjectPath $LogFile) -Parent
if (!(Test-Path $LogDir)) {
   New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Write-MonitorLog {
   param([string]$Message, [string]$Level = "INFO")
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logEntry = "[$timestamp] [$Level] $Message"
    
   if (!$Silent) {
      $color = switch ($Level) {
         "SUCCESS" { "Green" }
         "ERROR" { "Red" }
         "WARNING" { "Yellow" }
         "ALERT" { "Magenta" }
         "ACTIVITY" { "Cyan" }
         default { "White" }
      }
      Write-Host $logEntry -ForegroundColor $color
   }
    
   if ($LogToFile) {
      Add-Content -Path (Join-Path $ProjectPath $LogFile) -Value $logEntry
   }
}

function Get-BotActivity {
   try {
      Set-Location $ProjectPath
        
      # Get recent bot commits (last 24 hours)
      $recentCommits = git log --author="$BotName" --since="24 hours ago" --oneline 2>$null
        
      # Get bot branches
      $botBranches = git branch -r | Where-Object { 
         $branch = $_.Trim()
         if ($branch -notmatch "HEAD") {
            try {
               $author = git log -1 --pretty=format:"%an" $branch 2>$null
               return $author -eq $BotName
            }
            catch {
               return $false
            }
         }
         return $false
      }
        
      # Get jules-google sub-branches
      $julesBranches = git branch -a | Where-Object { $_ -match "jules-google/" }
        
      return @{
         RecentCommits = $recentCommits
         BotBranches   = $botBranches
         JulesBranches = $julesBranches
         Timestamp     = Get-Date
      }
   }
   catch {
      Write-MonitorLog "Error getting bot activity: $_" "ERROR"
      return $null
   }
}

function Test-NewBotActivity {
   param($CurrentActivity, $PreviousActivity)
    
   if (!$PreviousActivity) {
      return $false
   }
    
   # Check for new commits
   $currentCommitCount = ($CurrentActivity.RecentCommits | Measure-Object).Count
   $previousCommitCount = ($PreviousActivity.RecentCommits | Measure-Object).Count
    
   # Check for new branches
   $currentBranchCount = ($CurrentActivity.BotBranches | Measure-Object).Count
   $previousBranchCount = ($PreviousActivity.BotBranches | Measure-Object).Count
    
   # Check for new jules-google branches
   $currentJulesCount = ($CurrentActivity.JulesBranches | Measure-Object).Count
   $previousJulesCount = ($PreviousActivity.JulesBranches | Measure-Object).Count
    
   return ($currentCommitCount -gt $previousCommitCount) -or 
           ($currentBranchCount -gt $previousBranchCount) -or
           ($currentJulesCount -gt $previousJulesCount)
}

function Invoke-AutoRedirect {
   Write-MonitorLog "🔄 Triggering automatic redirection..." "ACTIVITY"
    
   try {
      $redirectScript = "$ProjectPath\scripts\jules-bot-redirect.ps1"
        
      if (Test-Path $redirectScript) {
         & $redirectScript -Action "redirect" -Verbose
         Write-MonitorLog "✅ Auto-redirect completed" "SUCCESS"
         return $true
      }
      else {
         Write-MonitorLog "❌ Redirect script not found" "ERROR"
         return $false
      }
   }
   catch {
      Write-MonitorLog "❌ Auto-redirect failed: $_" "ERROR"
      return $false
   }
}

function Show-ActivitySummary {
   param($Activity)
    
   if (!$Activity) {
      Write-MonitorLog "No activity data available" "WARNING"
      return
   }
    
   $commitCount = ($Activity.RecentCommits | Measure-Object).Count
   $branchCount = ($Activity.BotBranches | Measure-Object).Count
   $julesCount = ($Activity.JulesBranches | Measure-Object).Count
    
   Write-MonitorLog "📊 Activity Summary:" "INFO"
   Write-MonitorLog "  Recent bot commits: $commitCount" "INFO"
   Write-MonitorLog "  Bot branches: $branchCount" "INFO"
   Write-MonitorLog "  Jules-google branches: $julesCount" "INFO"
    
   # Show recent commits if any
   if ($commitCount -gt 0) {
      Write-MonitorLog "Recent bot commits:" "ACTIVITY"
      $Activity.RecentCommits | Select-Object -First 3 | ForEach-Object {
         Write-MonitorLog "  $_" "INFO"
      }
   }
    
   # Show bot branches if any
   if ($branchCount -gt 0) {
      Write-MonitorLog "Bot branches found:" "ACTIVITY"
      $Activity.BotBranches | ForEach-Object {
         Write-MonitorLog "  $_" "INFO"
      }
   }
    
   # Show jules-google branches
   if ($julesCount -gt 0) {
      Write-MonitorLog "Jules-google branches:" "SUCCESS"
      $Activity.JulesBranches | ForEach-Object {
         Write-MonitorLog "  $_" "SUCCESS"
      }
   }
}

function Start-RealTimeMonitoring {
   Write-MonitorLog "🚀 Starting Jules Bot Real-Time Monitoring..." "ACTIVITY"
   Write-MonitorLog "Bot: $BotName" "INFO"
   Write-MonitorLog "Interval: $IntervalSeconds seconds" "INFO"
   Write-MonitorLog "Project: $ProjectPath" "INFO"
    
   if ($LogToFile) {
      Write-MonitorLog "Logging to: $LogFile" "INFO"
   }
    
   Write-MonitorLog "Press Ctrl+C to stop monitoring" "INFO"
   Write-MonitorLog "=" * 50 "INFO"
    
   $previousActivity = $null
   $cycleCount = 0
    
   try {
      while ($true) {
         $cycleCount++
            
         Write-MonitorLog "🔍 Monitoring cycle #$cycleCount" "ACTIVITY"
            
         # Get current activity
         $currentActivity = Get-BotActivity
            
         if ($currentActivity) {
            # Check for new activity
            $hasNewActivity = Test-NewBotActivity -CurrentActivity $currentActivity -PreviousActivity $previousActivity
                
            if ($hasNewActivity) {
               Write-MonitorLog "🚨 NEW BOT ACTIVITY DETECTED!" "ALERT"
               Show-ActivitySummary $currentActivity
                    
               # Trigger automatic redirection if bot branches exist
               if ($currentActivity.BotBranches -and ($currentActivity.BotBranches | Measure-Object).Count -gt 0) {
                  Invoke-AutoRedirect
               }
            }
            else {
               if ($cycleCount % 10 -eq 0) {
                  # Show summary every 10 cycles
                  Show-ActivitySummary $currentActivity
               }
               else {
                  Write-MonitorLog "No new bot activity detected" "INFO"
               }
            }
                
            $previousActivity = $currentActivity
         }
         else {
            Write-MonitorLog "Could not retrieve activity data" "WARNING"
         }
            
         # Wait for next cycle
         Start-Sleep -Seconds $IntervalSeconds
      }
   }
   catch [System.Management.Automation.PipelineStoppedException] {
      Write-MonitorLog "Monitoring stopped by user" "INFO"
   }
   catch {
      Write-MonitorLog "Monitoring error: $_" "ERROR"
   }
   finally {
      Write-MonitorLog "🛑 Jules Bot Monitoring stopped" "INFO"
   }
}

function Show-CurrentStatus {
   Write-MonitorLog "📊 Jules Bot Monitoring Status" "ACTIVITY"
   Write-MonitorLog "=" * 40 "INFO"
    
   $activity = Get-BotActivity
   if ($activity) {
      Show-ActivitySummary $activity
   }
    
   # Check if redirect system is available
   $redirectScript = "$ProjectPath\scripts\jules-bot-redirect.ps1"
   if (Test-Path $redirectScript) {
      Write-MonitorLog "✅ Redirect system available" "SUCCESS"
   }
   else {
      Write-MonitorLog "❌ Redirect system not found" "ERROR"
   }
    
   # Check if monitoring service is running
   $monitoringJobs = Get-Job | Where-Object { $_.Command -like "*jules*monitor*" }
   if ($monitoringJobs) {
      Write-MonitorLog "🔍 Background monitoring services:" "INFO"
      $monitoringJobs | ForEach-Object {
         Write-MonitorLog "  Job $($_.Id): $($_.State)" "INFO"
      }
   }
   else {
      Write-MonitorLog "No background monitoring services running" "INFO"
   }
}

function Test-AlertSystem {
   Write-MonitorLog "🧪 Testing alert system..." "ACTIVITY"
    
   # Simulate bot activity detection
   Write-MonitorLog "🚨 SIMULATED: New bot activity detected!" "ALERT"
   Write-MonitorLog "Branch: fix/test-alert-system" "ACTIVITY"
   Write-MonitorLog "Author: $BotName" "ACTIVITY"
   Write-MonitorLog "Action: Would trigger auto-redirect" "SUCCESS"
    
   Write-MonitorLog "✅ Alert system test completed" "SUCCESS"
}

# Main execution
switch ($Mode.ToLower()) {
   "watch" {
      Start-RealTimeMonitoring
   }
   "status" {
      Show-CurrentStatus
   }
   "test" {
      Test-AlertSystem
   }
   "once" {
      $activity = Get-BotActivity
      if ($activity) {
         Show-ActivitySummary $activity
      }
   }
   default {
      Write-Host "Jules Bot Real-Time Monitoring System"
      Write-Host ""
      Write-Host "Usage: .\jules-realtime-monitor.ps1 [Mode] [Options]"
      Write-Host ""
      Write-Host "Modes:"
      Write-Host "  watch     - Start continuous real-time monitoring (default)"
      Write-Host "  status    - Show current system status"
      Write-Host "  once      - Check activity once and exit"
      Write-Host "  test      - Test alert system"
      Write-Host ""
      Write-Host "Options:"
      Write-Host "  -IntervalSeconds  - Monitoring interval (default: 30)"
      Write-Host "  -Silent          - Suppress console output"
      Write-Host "  -LogToFile       - Enable file logging"
      Write-Host "  -LogFile         - Custom log file path"
      Write-Host ""
      Write-Host "Examples:"
      Write-Host "  .\jules-realtime-monitor.ps1 watch -LogToFile"
      Write-Host "  .\jules-realtime-monitor.ps1 status"
      Write-Host "  .\jules-realtime-monitor.ps1 watch -IntervalSeconds 60"
   }
}
