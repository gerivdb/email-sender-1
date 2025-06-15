# Status-FullStack.ps1
# Script PowerShell pour afficher le statut détaillé de la stack EMAIL_SENDER_1
# Partie de la Phase 3 : Intégration IDE et Expérience Développeur

param(
   [switch]$Detailed,
   [switch]$Json,
   [switch]$Continuous,
   [int]$RefreshInterval = 5
)

$ErrorActionPreference = "Stop"

# Configuration
$PROJECT_ROOT = Split-Path -Parent $PSScriptRoot
$DOCKER_COMPOSE_FILE = Join-Path $PROJECT_ROOT "docker-compose.yml"

function Write-StatusMessage {
   param([string]$Message, [string]$Type = "INFO")
    
   if ($Json) { return }
    
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $color = switch ($Type) {
      "INFO" { "Cyan" }
      "SUCCESS" { "Green" }
      "WARNING" { "Yellow" }
      "ERROR" { "Red" }
      "HEADER" { "Magenta" }
      default { "White" }
   }
   Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

function Get-DockerServicesStatus {
   $services = @()
    
   try {
      if (Test-Path $DOCKER_COMPOSE_FILE) {
         $dockerOutput = docker-compose -f $DOCKER_COMPOSE_FILE ps --format json 2>$null
            
         if ($dockerOutput) {
            $containers = $dockerOutput | ForEach-Object {
               try {
                  $_ | ConvertFrom-Json
               }
               catch {
                  $null
               }
            } | Where-Object { $_ -ne $null }
                
            foreach ($container in $containers) {
               $services += @{
                  Name   = $container.Service
                  Status = $container.State
                  Health = if ($container.Health) { $container.Health } else { "unknown" }
                  Ports  = if ($container.Ports) { $container.Ports } else { "none" }
                  Type   = "Docker"
               }
            }
         }
      }
   }
   catch {
      Write-StatusMessage "Erreur lors de la récupération du statut Docker: $($_.Exception.Message)" "ERROR"
   }
    
   return $services
}

function Get-GoProcessesStatus {
   $processes = @()
    
   try {
      $goProcesses = Get-Process | Where-Object { 
         $_.ProcessName -like "*email*sender*" -or 
         $_.ProcessName -like "*smart*infrastructure*" -or
         $_.ProcessName -like "*qdrant*" -or
         $_.Path -like "*EMAIL_SENDER_1*"
      }
        
      foreach ($process in $goProcesses) {
         $processes += @{
            Name   = $process.ProcessName
            PID    = $process.Id
            Status = if ($process.Responding) { "running" } else { "not responding" }
            Memory = "$([math]::Round($process.WorkingSet64 / 1MB, 2)) MB"
            CPU    = "$($process.TotalProcessorTime.TotalSeconds)s"
            Type   = "Go Process"
         }
      }
   }
   catch {
      Write-StatusMessage "Erreur lors de la récupération des processus Go: $($_.Exception.Message)" "ERROR"
   }
    
   return $processes
}

function Get-NetworkPortsStatus {
   $ports = @()
   $targetPorts = @(8080, 8081, 6333, 6334, 5432, 6379, 9090, 3000)
    
   try {
      foreach ($port in $targetPorts) {
         $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
            
         if ($connection) {
            $process = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
                
            $ports += @{
               Port    = $port
               Status  = "listening"
               Process = if ($process) { $process.ProcessName } else { "unknown" }
               PID     = $connection.OwningProcess
               Service = switch ($port) {
                  8080 { "Smart Infrastructure API" }
                  8081 { "Infrastructure Monitoring" }
                  6333 { "Qdrant Vector DB" }
                  6334 { "Qdrant Admin" }
                  5432 { "PostgreSQL" }
                  6379 { "Redis" }
                  9090 { "Prometheus" }
                  3000 { "Grafana" }
                  default { "Unknown Service" }
               }
               Type    = "Network Port"
            }
         }
         else {
            $ports += @{
               Port    = $port
               Status  = "not listening"
               Process = $null
               PID     = $null
               Service = switch ($port) {
                  8080 { "Smart Infrastructure API" }
                  8081 { "Infrastructure Monitoring" }
                  6333 { "Qdrant Vector DB" }
                  6334 { "Qdrant Admin" }
                  5432 { "PostgreSQL" }
                  6379 { "Redis" }
                  9090 { "Prometheus" }
                  3000 { "Grafana" }
                  default { "Unknown Service" }
               }
               Type    = "Network Port"
            }
         }
      }
   }
   catch {
      Write-StatusMessage "Erreur lors de la vérification des ports: $($_.Exception.Message)" "ERROR"
   }
    
   return $ports
}

function Get-SystemResources {
   try {
      $cpu = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average
      $memory = Get-CimInstance -ClassName Win32_OperatingSystem
      $disk = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        
      return @{
         CPU    = @{
            Usage = "$([math]::Round($cpu.Average, 2))%"
            Cores = (Get-CimInstance -ClassName Win32_Processor).NumberOfCores
         }
         Memory = @{
            Total     = "$([math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)) GB"
            Available = "$([math]::Round($memory.FreePhysicalMemory / 1MB, 2)) GB"
            Usage     = "$([math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100, 2))%"
         }
         Disk   = @{
            Total = "$([math]::Round(($disk | Measure-Object -Property Size -Sum).Sum / 1GB, 2)) GB"
            Free  = "$([math]::Round(($disk | Measure-Object -Property FreeSpace -Sum).Sum / 1GB, 2)) GB"
         }
         Type   = "System Resources"
      }
   }
   catch {
      Write-StatusMessage "Erreur lors de la récupération des ressources système: $($_.Exception.Message)" "ERROR"
      return @{}
   }
}

function Show-ServiceStatus {
   param($Services, $Title)
    
   if ($Json) { return }
    
   Write-StatusMessage "=== $Title ===" "HEADER"
    
   if ($Services.Count -eq 0) {
      Write-StatusMessage "Aucun service trouvé" "WARNING"
      return
   }
    
   foreach ($service in $Services) {
      $statusColor = switch ($service.Status) {
         "running" { "SUCCESS" }
         "listening" { "SUCCESS" }
         "healthy" { "SUCCESS" }
         "unhealthy" { "ERROR" }
         "not listening" { "WARNING" }
         default { "WARNING" }
      }
        
      if ($Detailed) {
         Write-StatusMessage "Nom: $($service.Name)" "INFO"
         Write-StatusMessage "  Statut: $($service.Status)" $statusColor
         if ($service.PID) { Write-StatusMessage "  PID: $($service.PID)" "INFO" }
         if ($service.Port) { Write-StatusMessage "  Port: $($service.Port)" "INFO" }
         if ($service.Memory) { Write-StatusMessage "  Mémoire: $($service.Memory)" "INFO" }
         if ($service.Service) { Write-StatusMessage "  Service: $($service.Service)" "INFO" }
         Write-StatusMessage "" "INFO"
      }
      else {
         $name = if ($service.Name) { $service.Name } else { "Port $($service.Port)" }
         Write-StatusMessage "$name : $($service.Status)" $statusColor
      }
   }
   Write-StatusMessage "" "INFO"
}

function Show-SystemStatus {
   param($Resources)
    
   if ($Json) { return }
    
   Write-StatusMessage "=== RESSOURCES SYSTÈME ===" "HEADER"
   Write-StatusMessage "CPU: $($Resources.CPU.Usage) ($($Resources.CPU.Cores) cores)" "INFO"
   Write-StatusMessage "Mémoire: $($Resources.Memory.Usage) ($($Resources.Memory.Available) libre sur $($Resources.Memory.Total))" "INFO"
   Write-StatusMessage "Disque: $($Resources.Disk.Free) libre sur $($Resources.Disk.Total)" "INFO"
   Write-StatusMessage "" "INFO"
}

function Get-OverallStatus {
   param($Docker, $Go, $Ports)
    
   $runningServices = 0
   $totalServices = 0
    
   foreach ($service in $Docker) {
      $totalServices++
      if ($service.Status -eq "running") { $runningServices++ }
   }
    
   foreach ($service in $Go) {
      $totalServices++
      if ($service.Status -eq "running") { $runningServices++ }
   }
    
   $criticalPorts = $Ports | Where-Object { $_.Port -in @(8080, 6333, 5432) }
   $criticalPortsActive = ($criticalPorts | Where-Object { $_.Status -eq "listening" }).Count
    
   $healthPercentage = if ($totalServices -gt 0) { 
      [math]::Round(($runningServices / $totalServices) * 100, 2) 
   }
   else { 0 }
    
   $status = if ($healthPercentage -ge 80 -and $criticalPortsActive -eq 3) {
      "HEALTHY"
   }
   elseif ($healthPercentage -ge 50) {
      "DEGRADED"
   }
   else {
      "CRITICAL"
   }
    
   return @{
      Status              = $status
      HealthPercentage    = $healthPercentage
      RunningServices     = $runningServices
      TotalServices       = $totalServices
      CriticalPortsActive = $criticalPortsActive
      Timestamp           = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   }
}

function Show-StatusDisplay {
   Clear-Host
    
   $dockerServices = Get-DockerServicesStatus
   $goProcesses = Get-GoProcessesStatus
   $networkPorts = Get-NetworkPortsStatus
   $systemResources = Get-SystemResources
   $overallStatus = Get-OverallStatus -Docker $dockerServices -Go $goProcesses -Ports $networkPorts
    
   if ($Json) {
      $output = @{
         Overall         = $overallStatus
         Docker          = $dockerServices
         GoProcesses     = $goProcesses
         NetworkPorts    = $networkPorts
         SystemResources = $systemResources
         Project         = @{
            Name   = "EMAIL_SENDER_1"
            Branch = git branch --show-current
            Root   = $PROJECT_ROOT
         }
      }
        
      $output | ConvertTo-Json -Depth 10
      return
   }
    
   # Affichage textuel
   $statusColor = switch ($overallStatus.Status) {
      "HEALTHY" { "SUCCESS" }
      "DEGRADED" { "WARNING" }
      "CRITICAL" { "ERROR" }
   }
    
   Write-StatusMessage "========================================" "HEADER"
   Write-StatusMessage "    EMAIL_SENDER_1 - STACK STATUS" "HEADER"
   Write-StatusMessage "========================================" "HEADER"
   Write-StatusMessage "Statut Global: $($overallStatus.Status) ($($overallStatus.HealthPercentage)%)" $statusColor
   Write-StatusMessage "Services Actifs: $($overallStatus.RunningServices)/$($overallStatus.TotalServices)" "INFO"
   Write-StatusMessage "Branche Git: $(git branch --show-current)" "INFO"
   Write-StatusMessage "Timestamp: $($overallStatus.Timestamp)" "INFO"
   Write-StatusMessage "" "INFO"
    
   Show-SystemStatus -Resources $systemResources
   Show-ServiceStatus -Services $dockerServices -Title "SERVICES DOCKER"
   Show-ServiceStatus -Services $goProcesses -Title "PROCESSUS GO"
   Show-ServiceStatus -Services $networkPorts -Title "PORTS RÉSEAU"
    
   if ($Continuous) {
      Write-StatusMessage "Prochaine actualisation dans $RefreshInterval secondes... (Ctrl+C pour arrêter)" "INFO"
   }
}

# Script principal
try {
   Set-Location $PROJECT_ROOT
    
   if ($Continuous) {
      while ($true) {
         Show-StatusDisplay
         Start-Sleep -Seconds $RefreshInterval
      }
   }
   else {
      Show-StatusDisplay
   }
    
}
catch {
   if (-not $Json) {
      Write-StatusMessage "ERREUR: $($_.Exception.Message)" "ERROR"
   }
   exit 1
}
