# Emergency-Diagnostic-v2.ps1
# Script de diagnostic et réparation complète pour Phase 0
# Réparation infrastructure, optimisation ressources, prévention freeze IDE

param(
    [switch]$RunDiagnostic,
    [switch]$RunRepair,
    [switch]$OptimizeResources,
    [switch]$EmergencyStop,
    [switch]$AllPhases,
    [switch]$StartMonitoring
)

# Configuration globale
$CONFIG = @{
    MaxCPUUsage       = 70        # Pourcentage max CPU
    MaxRAMUsageGB     = 6       # GB max RAM
    CriticalPorts     = @(8080, 5432, 6379, 6333, 3000, 9000)
    ServiceTimeoutSec = 30  # Timeout services
    LogFile           = "emergency-diagnostic.log"
    ProjectRoot       = $PWD.Path
}

# Couleurs pour output
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
    Write-Host "🔍 $Title" -ForegroundColor $Colors.Header
    Write-Host "="*80 -ForegroundColor $Colors.Header
}

function Test-ServiceHealth {
    param([string]$ServiceName, [int]$Port, [string]$HealthEndpoint = $null)
    
    try {
        # Test port accessibility
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect("localhost", $Port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne(3000, $false)
        
        if (!$wait) {
            $tcpClient.Close()
            return @{
                Name       = $ServiceName
                Port       = $Port
                Status     = "Port Timeout"
                Accessible = $false
                Details    = "Port connection timeout"
            }
        }
        
        try {
            $tcpClient.EndConnect($connect)
            $accessible = $true
        }
        catch {
            $accessible = $false
        }
        finally {
            $tcpClient.Close()
        }
        
        # Test HTTP health endpoint if provided
        if ($HealthEndpoint -and $accessible) {
            try {
                $webResponse = Invoke-RestMethod -Uri $HealthEndpoint -TimeoutSec 5 -ErrorAction Stop
                $healthStatus = "HTTP OK"
                $healthDetails = $webResponse
            }
            catch {
                $healthStatus = "HTTP Error"
                $healthDetails = $_.Exception.Message
            }
        }
        else {
            $healthStatus = if ($accessible) { "Port Open" } else { "Port Closed" }
            $healthDetails = "TCP connection test"
        }
        
        return @{
            Name       = $ServiceName
            Port       = $Port
            Status     = $healthStatus
            Accessible = $accessible
            Details    = $healthDetails
        }
    }
    catch {
        return @{
            Name       = $ServiceName
            Port       = $Port  
            Status     = "Error"
            Accessible = $false
            Details    = $_.Exception.Message
        }
    }
}function Get-SystemResourceUsage {
    try {
        # CPU Usage
        $cpuCounters = Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 2
        $cpuUsage = [Math]::Round((100 - ($cpuCounters.CounterSamples | Select-Object -Last 1).CookedValue), 2)
        
        # Memory Usage
        $memory = Get-CimInstance -ClassName Win32_OperatingSystem
        $totalMemoryGB = [Math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
        $freeMemoryGB = [Math]::Round($memory.FreePhysicalMemory / 1MB, 2)
        $usedMemoryGB = [Math]::Round($totalMemoryGB - $freeMemoryGB, 2)
        $memoryUsagePercent = [Math]::Round(($usedMemoryGB / $totalMemoryGB) * 100, 1)
        
        # Disk Usage
        $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
        $diskFreeGB = [Math]::Round($systemDrive.FreeSpace / 1GB, 2)
        $diskTotalGB = [Math]::Round($systemDrive.Size / 1GB, 2)
        $diskUsagePercent = [Math]::Round((($diskTotalGB - $diskFreeGB) / $diskTotalGB) * 100, 1)
        
        return @{
            CPU          = $cpuUsage
            Memory       = @{
                UsedGB       = $usedMemoryGB
                TotalGB      = $totalMemoryGB
                FreeGB       = $freeMemoryGB
                UsagePercent = $memoryUsagePercent
            }
            Disk         = @{
                FreeGB       = $diskFreeGB
                TotalGB      = $diskTotalGB
                UsagePercent = $diskUsagePercent
            }
            ProcessCount = (Get-Process).Count
        }
    }
    catch {
        Write-DiagnosticLog "Error getting system resources - $($_.Exception.Message)" "Error"
        return $null
    }
}

function Get-ProcessConflicts {
    $criticalProcesses = @("docker", "postgres", "redis", "node", "go", "python", "code")
    $conflicts = @()
    $heavyProcesses = @()
    
    foreach ($processName in $criticalProcesses) {
        $processes = Get-Process -Name "*$processName*" -ErrorAction SilentlyContinue
        
        if ($processes) {
            $totalCPU = 0
            $totalMemoryMB = 0
            
            foreach ($proc in $processes) {
                $totalCPU += if ($proc.CPU) { $proc.CPU } else { 0 }
                $totalMemoryMB += $proc.WorkingSet / 1MB
            }
            
            $processInfo = @{
                ProcessName   = $processName
                Count         = $processes.Count
                PIDs          = $processes.Id
                TotalCPUTime  = [Math]::Round($totalCPU, 2)
                TotalMemoryMB = [Math]::Round($totalMemoryMB, 2)
            }
            
            # Conflict if multiple instances
            if ($processes.Count -gt 1) {
                $conflicts += $processInfo
            }
            
            # Heavy process if using significant resources
            if ($totalMemoryMB -gt 500 -or $totalCPU -gt 10) {
                $heavyProcesses += $processInfo
            }
        }
    }
    
    return @{
        Conflicts      = $conflicts
        HeavyProcesses = $heavyProcesses
    }
}

function Test-CriticalServices {
    Write-SectionHeader "TESTING CRITICAL SERVICES"
    
    $services = @(
        @{ Name = "API Server"; Port = 8080; Health = "http://localhost:8080/health" },
        @{ Name = "PostgreSQL"; Port = 5432; Health = $null },
        @{ Name = "Redis"; Port = 6379; Health = $null },
        @{ Name = "Qdrant"; Port = 6333; Health = "http://localhost:6333/health" },
        @{ Name = "Development Server"; Port = 3000; Health = $null },
        @{ Name = "Monitoring"; Port = 9000; Health = $null }
    )
    
    $results = @()
    foreach ($service in $services) {
        $result = Test-ServiceHealth -ServiceName $service.Name -Port $service.Port -HealthEndpoint $service.Health
        $results += $result
        
        $statusColor = if ($result.Accessible) { $Colors.Success } else { $Colors.Error }
        $statusIcon = if ($result.Accessible) { "✅" } else { "❌" }
        
        Write-DiagnosticLog "$statusIcon $($service.Name) ($($service.Port)): $($result.Status)" $(if ($result.Accessible) { "Success" } else { "Error" })
    }
    
    return $results
}function Stop-OrphanedProcesses {
    Write-SectionHeader "CLEANING ORPHANED PROCESSES"
    
    # Patterns de processus à nettoyer avec précaution
    $orphanPatterns = @(
        @{ Pattern = "*email_sender*"; Safe = $false },
        @{ Pattern = "*cache_test*"; Safe = $false },
        @{ Pattern = "*debug*"; Safe = $true },
        @{ Pattern = "node*"; Safe = $true; Check = "inspect" }
    )
    
    $cleanedCount = 0
    
    foreach ($patternInfo in $orphanPatterns) {
        $processes = Get-Process | Where-Object { $_.Name -like $patternInfo.Pattern }
        
        foreach ($process in $processes) {
            $shouldKill = $false
            
            # Vérifications de sécurité
            if ($patternInfo.Safe -eq $false) {
                # Processus non-safe : vérifications additionnelles
                if ($process.Name -like "*email_sender*" -and $process.MainWindowTitle -eq "") {
                    $shouldKill = $true  # Background process sans UI
                }
                elseif ($process.Name -like "*cache_test*") {
                    $shouldKill = $true  # Tests cache généralement temporaires
                }
            }
            elseif ($patternInfo.Check) {
                # Vérification spéciale pour node inspect
                if ($process.StartInfo.Arguments -like "*--inspect*") {
                    $shouldKill = $true
                }
            }
            else {
                $shouldKill = $true  # Safe patterns
            }
            
            if ($shouldKill) {
                try {
                    Write-DiagnosticLog "Stopping orphaned process: $($process.Name) (PID: $($process.Id))" "Warning"
                    Stop-Process -Id $process.Id -Force -ErrorAction Stop
                    $cleanedCount++
                }
                catch {
                    Write-DiagnosticLog "Failed to stop process $($process.Id) - $($_.Exception.Message)" "Error"
                }
            }
        }
    }
    
    Write-DiagnosticLog "Cleaned $cleanedCount orphaned processes" "Success"
    return $cleanedCount
}

function Clear-PortConflicts {
    param([int[]]$Ports = $CONFIG.CriticalPorts)
    
    Write-SectionHeader "CLEARING PORT CONFLICTS"
    
    $clearedPorts = @()
    
    foreach ($port in $Ports) {
        try {
            $connections = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
            
            foreach ($connection in $connections) {
                if ($connection.State -eq "Listen") {
                    $processId = $connection.OwningProcess
                    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
                    
                    if ($process) {
                        Write-DiagnosticLog "Port $port occupied by $($process.Name) (PID: $processId)" "Warning"
                        
                        # Liste des services critiques à ne pas tuer
                        $criticalServices = @("docker", "postgres", "redis-server", "qdrant")
                        $isCritical = $false
                        
                        foreach ($critical in $criticalServices) {
                            if ($process.Name -like "*$critical*") {
                                $isCritical = $true
                                break
                            }
                        }
                        
                        if (-not $isCritical) {
                            try {
                                Write-DiagnosticLog "Stopping non-critical process on port $port" "Warning"
                                Stop-Process -Id $processId -Force
                                $clearedPorts += $port
                            }
                            catch {
                                Write-DiagnosticLog "Failed to stop process on port $port - $($_.Exception.Message)" "Error"
                            }
                        }
                        else {
                            Write-DiagnosticLog "Skipping critical service $($process.Name) on port $port" "Info"
                        }
                    }
                }
            }
        }
        catch {
            Write-DiagnosticLog "Error checking port $port - $($_.Exception.Message)" "Error"
        }
    }
    
    Write-DiagnosticLog "Cleared conflicts on $($clearedPorts.Count) ports: $($clearedPorts -join ', ')" "Success"
    return $clearedPorts
}function Repair-APIServer {
    Write-SectionHeader "API SERVER REPAIR"
    
    # Step 1: Identifier et arrêter processus défaillants
    $apiProcesses = Get-Process | Where-Object { 
        $_.Name -like "*api*" -or 
        $_.Name -like "*server*" -or
        ($_.StartInfo.Arguments -like "*8080*")
    }
    
    foreach ($proc in $apiProcesses) {
        if ($proc.MainWindowTitle -eq "" -and $proc.Responding -eq $false) {
            Write-DiagnosticLog "Stopping unresponsive API process: $($proc.Name)" "Warning"
            try {
                Stop-Process -Id $proc.Id -Force
            }
            catch {
                Write-DiagnosticLog "Failed to stop API process - $($_.Exception.Message)" "Error"
            }
        }
    }
    
    # Step 2: Clear port 8080
    $clearedPorts = Clear-PortConflicts -Ports @(8080)
    
    # Step 3: Tentative de démarrage avec ports de fallback
    $fallbackPorts = @(8080, 8081, 8082, 8083)
    $successfulPort = $null
    
    foreach ($port in $fallbackPorts) {
        Write-DiagnosticLog "Attempting to start API server on port $port..." "Info"
        
        try {
            # Rechercher le fichier main.go de l'API
            $apiMainFiles = @(
                "cmd\api\main.go",
                "cmd\infrastructure-api-server\main.go", 
                "cmd\server\main.go",
                "api\main.go"
            )
            
            $foundApiFile = $null
            foreach ($apiFile in $apiMainFiles) {
                $fullPath = Join-Path $CONFIG.ProjectRoot $apiFile
                if (Test-Path $fullPath) {
                    $foundApiFile = $fullPath
                    break
                }
            }
            
            if ($foundApiFile) {
                Write-DiagnosticLog "Found API file: $foundApiFile" "Info"
                
                # Démarrer le serveur API
                $startArgs = @("run", $foundApiFile)
                if ($port -ne 8080) {
                    $startArgs += "--port=$port"
                }
                
                $processInfo = Start-Process -FilePath "go" -ArgumentList $startArgs -PassThru -NoNewWindow -RedirectStandardError "api-error.log"
                Start-Sleep -Seconds 5
                
                # Tester si le port est accessible
                $healthCheck = Test-ServiceHealth -ServiceName "API Server" -Port $port -HealthEndpoint "http://localhost:$port/health"
                
                if ($healthCheck.Accessible) {
                    Write-DiagnosticLog "✅ API Server started successfully on port $port" "Success"
                    $successfulPort = $port
                    break
                }
                else {
                    Write-DiagnosticLog "API Server started but not accessible on port $port" "Warning"
                    if ($processInfo -and !$processInfo.HasExited) {
                        Stop-Process -Id $processInfo.Id -Force -ErrorAction SilentlyContinue
                    }
                }
            }
            else {
                Write-DiagnosticLog "No API main.go file found in common locations" "Error"
                break
            }
        }
        catch {
            Write-DiagnosticLog "Failed to start API server on port $port - $($_.Exception.Message)" "Error"
        }
    }
    
    if ($successfulPort) {
        Write-DiagnosticLog "🎉 API Server repair successful on port $successfulPort" "Success"
        return $successfulPort
    }
    else {
        Write-DiagnosticLog "❌ API Server repair failed on all attempted ports" "Error"
        return $null
    }
}

function Optimize-SystemResources {
    Write-SectionHeader "SYSTEM RESOURCE OPTIMIZATION"
    
    $resources = Get-SystemResourceUsage
    $optimizationActions = @()
    
    # CPU Optimization
    if ($resources.CPU -gt $CONFIG.MaxCPUUsage) {
        Write-DiagnosticLog "🔥 High CPU usage detected: $($resources.CPU)%" "Warning"
        
        # Réduire priorité des processus non-critiques
        $processesToOptimize = @("node", "go", "python", "Code")
        foreach ($procName in $processesToOptimize) {
            $processes = Get-Process -Name "*$procName*" -ErrorAction SilentlyContinue
            foreach ($process in $processes) {
                try {
                    $oldPriority = $process.PriorityClass
                    $process.PriorityClass = "BelowNormal"
                    Write-DiagnosticLog "Reduced priority for $($process.Name) from $oldPriority to BelowNormal" "Info"
                    $optimizationActions += "CPU priority reduced: $($process.Name)"
                }
                catch {
                    Write-DiagnosticLog "Failed to change priority for $($process.Name) - $($_.Exception.Message)" "Warning"
                }
            }
        }
    }    # Memory Optimization
    if ($resources.Memory.UsedGB -gt $CONFIG.MaxRAMUsageGB) {
        Write-DiagnosticLog "🔥 High RAM usage detected: $($resources.Memory.UsedGB)GB" "Warning"
        
        # Force garbage collection
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()
        $optimizationActions += "Forced .NET garbage collection"
        
        # Clear file system cache (Windows)
        try {
            $result = Invoke-Expression "echo 3 > /proc/sys/vm/drop_caches" 2>$null
            $optimizationActions += "Cleared file system cache"
        }
        catch {
            # Windows alternative
            Write-DiagnosticLog "File system cache clear not applicable on Windows" "Info"
        }
    }
    
    # Process affinity optimization (multiprocessor)
    $cpuInfo = Get-CimInstance -ClassName Win32_Processor
    $logicalProcessors = $cpuInfo.NumberOfLogicalProcessors
    
    if ($logicalProcessors -gt 4) {
        Write-DiagnosticLog "🚀 Optimizing process affinity for $logicalProcessors cores..." "Info"
        
        # Assigner processus lourds sur cores dédiés
        $heavyProcesses = Get-Process -Name "docker", "postgres", "qdrant" -ErrorAction SilentlyContinue
        $coreIndex = 0
        
        foreach ($process in $heavyProcesses) {
            try {
                $affinityMask = [Math]::Pow(2, $coreIndex % $logicalProcessors)
                $process.ProcessorAffinity = $affinityMask
                Write-DiagnosticLog "Set affinity for $($process.Name) to core $coreIndex" "Info"
                $optimizationActions += "Process affinity: $($process.Name) -> core $coreIndex"
                $coreIndex++
            }
            catch {
                Write-DiagnosticLog "Failed to set affinity for $($process.Name) - $($_.Exception.Message)" "Warning"
            }
        }
    }
    
    Write-DiagnosticLog "⚡ Resource optimization completed. Actions taken: $($optimizationActions.Count)" "Success"
    return $optimizationActions
}

function Test-VSCodePerformance {
    Write-SectionHeader "VSCODE PERFORMANCE CHECK"
    
    $vscodeProcesses = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    if (-not $vscodeProcesses) {
        Write-DiagnosticLog "VSCode is not running" "Warning"
        return @{ Running = $false }
    }
    
    $totalCPUTime = ($vscodeProcesses | Measure-Object -Property CPU -Sum).Sum
    $totalMemoryMB = ($vscodeProcesses | Measure-Object -Property WorkingSet -Sum).Sum / 1MB
    $processCount = $vscodeProcesses.Count
    
    Write-DiagnosticLog "VSCode Performance:" "Info"
    Write-DiagnosticLog "  - Processes: $processCount" "Info"
    Write-DiagnosticLog "  - Total CPU Time: $([Math]::Round($totalCPUTime, 2))s" "Info"
    Write-DiagnosticLog "  - Total Memory: $([Math]::Round($totalMemoryMB, 2))MB" "Info"
    
    # Déterminer la responsivité (heuristique)
    $responsive = $totalCPUTime -lt 50 -and $totalMemoryMB -lt 2000 -and $processCount -lt 10
    
    if ($responsive) {
        Write-DiagnosticLog "✅ VSCode appears responsive" "Success"
    }
    else {
        Write-DiagnosticLog "⚠️ VSCode may be experiencing performance issues" "Warning"
        
        # Suggestions d'optimisation
        if ($totalMemoryMB -gt 1500) {
            Write-DiagnosticLog "  → High memory usage - consider closing unused tabs/extensions" "Warning"
        }
        if ($processCount -gt 8) {
            Write-DiagnosticLog "  → Many processes - consider disabling unnecessary extensions" "Warning"
        }
    }
    
    return @{
        Running       = $true
        Responsive    = $responsive
        ProcessCount  = $processCount
        TotalCPUTime  = $totalCPUTime
        TotalMemoryMB = $totalMemoryMB
    }
}function Start-ResourceMonitoring {
    Write-SectionHeader "STARTING RESOURCE MONITORING"
    
    $monitoringScript = {
        param($maxCPU, $maxRAM, $logFile, $projectRoot)
        
        $alertCount = 0
        $startTime = Get-Date
        
        while ($true) {
            try {
                # CPU Check
                $cpuCounters = Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1
                $cpuUsage = [Math]::Round((100 - $cpuCounters.CounterSamples.CookedValue), 2)
                
                # Memory Check
                $memory = Get-CimInstance -ClassName Win32_OperatingSystem
                $ramUsedGB = [Math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 2)
                
                # Alert conditions
                $cpuAlert = $cpuUsage -gt $maxCPU
                $ramAlert = $ramUsedGB -gt $maxRAM
                
                if ($cpuAlert -or $ramAlert) {
                    $alertCount++
                    $alert = "ALERT #$alertCount : High resource usage - CPU: $cpuUsage%, RAM: $ramUsedGB GB"
                    Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [ALERT] $alert"
                    
                    # Emergency actions si usage critique
                    if ($cpuUsage -gt 90 -or $ramUsedGB -gt 8) {
                        Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [EMERGENCY] Critical resource usage detected"
                        
                        # Réduire priorité processus lourds
                        $heavyProcesses = Get-Process | Where-Object { $_.CPU -gt 10 } | Sort-Object CPU -Descending | Select-Object -First 3
                        foreach ($proc in $heavyProcesses) {
                            try {
                                $proc.PriorityClass = "BelowNormal"
                                Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [ACTION] Reduced priority: $($proc.Name)"
                            }
                            catch {
                                Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [ERROR] Failed to reduce priority: $($proc.Name)"
                            }
                        }
                    }
                }
                else {
                    # Periodic status update (every 10 minutes)
                    $elapsed = (Get-Date) - $startTime
                    if ($elapsed.TotalMinutes % 10 -eq 0) {
                        Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [STATUS] Monitoring OK - CPU: $cpuUsage%, RAM: $ramUsedGB GB"
                    }
                }
                
                Start-Sleep -Seconds 30
            }
            catch {
                Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [ERROR] Monitoring error: $($_.Exception.Message)"
                Start-Sleep -Seconds 60  # Wait longer on error
            }
        }
    }
    
    $job = Start-Job -ScriptBlock $monitoringScript -ArgumentList $CONFIG.MaxCPUUsage, $CONFIG.MaxRAMUsageGB, $CONFIG.LogFile, $CONFIG.ProjectRoot
    
    Write-DiagnosticLog "📊 Resource monitoring started (Job ID: $($job.Id))" "Success"
    Write-DiagnosticLog "Monitoring will alert if CPU > $($CONFIG.MaxCPUUsage)% or RAM > $($CONFIG.MaxRAMUsageGB)GB" "Info"
    
    return $job
}

function Invoke-EmergencyStop {
    Write-SectionHeader "🚨 EMERGENCY STOP INITIATED"
    
    Write-DiagnosticLog "🚨 EMERGENCY STOP - Stopping all non-critical processes" "Critical"
    
    # Arrêter tous les jobs de monitoring
    Get-Job | Where-Object { $_.Name -like "*monitoring*" -or $_.Name -like "*resource*" } | Stop-Job -PassThru | Remove-Job
    
    # Services à arrêter en ordre de priorité (moins critiques d'abord)
    $servicesToStop = @(
        @{ Name = "Development tools"; Patterns = @("node", "npm", "yarn", "webpack") },
        @{ Name = "Build tools"; Patterns = @("go", "python", "pip") },
        @{ Name = "Non-critical applications"; Patterns = @("chrome", "firefox", "slack") }
    )
    
    foreach ($serviceGroup in $servicesToStop) {
        Write-DiagnosticLog "Stopping $($serviceGroup.Name)..." "Warning"
        
        foreach ($pattern in $serviceGroup.Patterns) {
            $processes = Get-Process -Name "*$pattern*" -ErrorAction SilentlyContinue
            foreach ($process in $processes) {
                try {
                    Stop-Process -Id $process.Id -Force
                    Write-DiagnosticLog "Stopped: $($process.Name) (PID: $($process.Id))" "Warning"
                }
                catch {
                    Write-DiagnosticLog "Failed to stop: $($process.Name)" "Error"
                }
            }
        }
    }
    
    # Clear tous les ports critiques
    Clear-PortConflicts
    
    # Force garbage collection
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
    
    Write-DiagnosticLog "🚨 Emergency stop completed - System should be more responsive" "Critical"
}function Invoke-ComprehensiveDiagnostic {
    Write-SectionHeader "🔍 COMPREHENSIVE DIAGNOSTIC"
    
    $startTime = Get-Date
    Write-DiagnosticLog "Starting comprehensive diagnostic..." "Info"
    
    # Collect all diagnostic data
    $report = @{
        Timestamp         = $startTime
        ProjectRoot       = $CONFIG.ProjectRoot
        SystemResources   = Get-SystemResourceUsage
        ProcessAnalysis   = Get-ProcessConflicts
        ServiceHealth     = Test-CriticalServices
        VSCodePerformance = Test-VSCodePerformance
        Summary           = @{
            HealthyServices   = 0
            UnhealthyServices = 0
            ProcessConflicts  = 0
            ResourceIssues    = @()
            Recommendations   = @()
        }
    }
    
    # Analyze results
    $healthyServices = $report.ServiceHealth | Where-Object { $_.Accessible -eq $true }
    $unhealthyServices = $report.ServiceHealth | Where-Object { $_.Accessible -eq $false }
    
    $report.Summary.HealthyServices = $healthyServices.Count
    $report.Summary.UnhealthyServices = $unhealthyServices.Count
    $report.Summary.ProcessConflicts = $report.ProcessAnalysis.Conflicts.Count
    
    # Resource analysis
    if ($report.SystemResources.CPU -gt $CONFIG.MaxCPUUsage) {
        $report.Summary.ResourceIssues += "High CPU usage: $($report.SystemResources.CPU)%"
        $report.Summary.Recommendations += "Consider reducing CPU-intensive processes"
    }
    
    if ($report.SystemResources.Memory.UsedGB -gt $CONFIG.MaxRAMUsageGB) {
        $report.Summary.ResourceIssues += "High RAM usage: $($report.SystemResources.Memory.UsedGB)GB"
        $report.Summary.Recommendations += "Consider closing memory-intensive applications"
    }
    
    if ($report.ProcessAnalysis.HeavyProcesses.Count -gt 0) {
        $report.Summary.ResourceIssues += "Heavy processes detected: $($report.ProcessAnalysis.HeavyProcesses.Count)"
        $report.Summary.Recommendations += "Review and optimize heavy processes"
    }
    
    if (-not $report.VSCodePerformance.Responsive) {
        $report.Summary.ResourceIssues += "VSCode performance issues detected"
        $report.Summary.Recommendations += "Optimize VSCode extensions and tabs"
    }
    
    # Service-specific recommendations
    foreach ($service in $unhealthyServices) {
        if ($service.Name -eq "API Server") {
            $report.Summary.Recommendations += "API Server repair required - run with -RunRepair"
        }
        elseif ($service.Name -eq "PostgreSQL") {
            $report.Summary.Recommendations += "Database server may need restart"
        }
        elseif ($service.Name -eq "Redis") {
            $report.Summary.Recommendations += "Redis cache server may need restart"
        }
    }
    
    # Generate report file
    $reportJson = $report | ConvertTo-Json -Depth 10
    $reportFile = "diagnostic-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $reportJson | Out-File -FilePath $reportFile -Encoding UTF8
    
    # Display summary
    Write-SectionHeader "📋 DIAGNOSTIC SUMMARY"
    Write-DiagnosticLog "Diagnostic completed in $([Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)) seconds" "Info"
    Write-DiagnosticLog "Report saved to: $reportFile" "Success"
    
    Write-Host "`n📊 SYSTEM STATUS:" -ForegroundColor $Colors.Header
    Write-DiagnosticLog "CPU Usage: $($report.SystemResources.CPU)%" "Info"
    Write-DiagnosticLog "RAM Usage: $($report.SystemResources.Memory.UsedGB)GB ($($report.SystemResources.Memory.UsagePercent)%)" "Info"
    Write-DiagnosticLog "Disk Usage: $($report.SystemResources.Disk.UsagePercent)%" "Info"
    Write-DiagnosticLog "Running Processes: $($report.SystemResources.ProcessCount)" "Info"
    
    Write-Host "`n🔗 SERVICE STATUS:" -ForegroundColor $Colors.Header
    Write-DiagnosticLog "Healthy Services: $($report.Summary.HealthyServices)" "Success"
    Write-DiagnosticLog "Unhealthy Services: $($report.Summary.UnhealthyServices)" $(if ($report.Summary.UnhealthyServices -eq 0) { "Success" } else { "Error" })
    Write-DiagnosticLog "Process Conflicts: $($report.Summary.ProcessConflicts)" $(if ($report.Summary.ProcessConflicts -eq 0) { "Success" } else { "Warning" })
    
    if ($report.Summary.ResourceIssues.Count -gt 0) {
        Write-Host "`n⚠️ RESOURCE ISSUES:" -ForegroundColor $Colors.Warning
        foreach ($issue in $report.Summary.ResourceIssues) {
            Write-DiagnosticLog "• $issue" "Warning"
        }
    }
    
    if ($report.Summary.Recommendations.Count -gt 0) {
        Write-Host "`n💡 RECOMMENDATIONS:" -ForegroundColor $Colors.Info
        foreach ($recommendation in $report.Summary.Recommendations) {
            Write-DiagnosticLog "• $recommendation" "Info"
        }
    }
    
    # Overall health assessment
    $overallHealthy = ($report.Summary.UnhealthyServices -eq 0) -and 
                     ($report.Summary.ProcessConflicts -eq 0) -and 
                     ($report.Summary.ResourceIssues.Count -eq 0) -and
                     ($report.VSCodePerformance.Responsive)
    
    if ($overallHealthy) {
        Write-DiagnosticLog "`n✅ OVERALL STATUS: HEALTHY" "Success"
    }
    else {
        Write-DiagnosticLog "`n⚠️ OVERALL STATUS: NEEDS ATTENTION" "Warning"
        Write-DiagnosticLog "Consider running with -RunRepair to automatically fix issues" "Info"
    }
    
    return $report
}function Invoke-InfrastructureRepair {
    Write-SectionHeader "🔧 INFRASTRUCTURE REPAIR"
    
    $repairStartTime = Get-Date
    Write-DiagnosticLog "Starting infrastructure repair process..." "Info"
    
    $repairResults = @{
        StartTime           = $repairStartTime
        CleanedProcesses    = 0
        ClearedPorts        = @()
        APIServerPort       = $null
        OptimizationActions = @()
        Success             = $false
        Errors              = @()
    }
    
    try {
        # Phase 1: Cleanup
        Write-DiagnosticLog "Phase 1: Cleaning orphaned processes..." "Info"
        $repairResults.CleanedProcesses = Stop-OrphanedProcesses
        
        Write-DiagnosticLog "Phase 2: Clearing port conflicts..." "Info"
        $repairResults.ClearedPorts = Clear-PortConflicts
        
        # Phase 3: API Server repair
        Write-DiagnosticLog "Phase 3: Repairing API Server..." "Info"
        $repairResults.APIServerPort = Repair-APIServer
        
        # Phase 4: Resource optimization
        Write-DiagnosticLog "Phase 4: Optimizing system resources..." "Info"
        $repairResults.OptimizationActions = Optimize-SystemResources
        
        # Phase 5: Validation
        Write-DiagnosticLog "Phase 5: Validating repair..." "Info"
        Start-Sleep -Seconds 10  # Give services time to stabilize
        
        $postRepairDiagnostic = Invoke-ComprehensiveDiagnostic
        $repairResults.PostRepairReport = $postRepairDiagnostic
        
        # Determine success
        $apiHealthy = $repairResults.APIServerPort -ne $null
        $lowResourceUsage = $postRepairDiagnostic.SystemResources.CPU -lt $CONFIG.MaxCPUUsage -and 
        $postRepairDiagnostic.SystemResources.Memory.UsedGB -lt $CONFIG.MaxRAMUsageGB
        $fewConflicts = $postRepairDiagnostic.ProcessAnalysis.Conflicts.Count -lt 2
        
        $repairResults.Success = $apiHealthy -and $lowResourceUsage -and $fewConflicts
        
        # Summary
        $repairDuration = ((Get-Date) - $repairStartTime).TotalSeconds
        
        Write-SectionHeader "🔧 REPAIR SUMMARY"
        Write-DiagnosticLog "Repair completed in $([Math]::Round($repairDuration, 2)) seconds" "Info"
        Write-DiagnosticLog "Cleaned processes: $($repairResults.CleanedProcesses)" "Info"
        Write-DiagnosticLog "Cleared ports: $($repairResults.ClearedPorts -join ', ')" "Info"
        Write-DiagnosticLog "API Server: $(if ($repairResults.APIServerPort) { "Port $($repairResults.APIServerPort)" } else { "Failed" })" $(if ($repairResults.APIServerPort) { "Success" } else { "Error" })
        Write-DiagnosticLog "Optimization actions: $($repairResults.OptimizationActions.Count)" "Info"
        
        if ($repairResults.Success) {
            Write-DiagnosticLog "✅ REPAIR SUCCESSFUL - Infrastructure is healthy" "Success"
        }
        else {
            Write-DiagnosticLog "⚠️ REPAIR PARTIALLY SUCCESSFUL - Some issues may remain" "Warning"
        }
        
    }
    catch {
        $repairResults.Errors += $_.Exception.Message
        Write-DiagnosticLog "❌ REPAIR FAILED - $($_.Exception.Message)" "Error"
        $repairResults.Success = $false
    }
    
    return $repairResults
}

# === MAIN EXECUTION LOGIC ===

Write-Host "`n" + "🚨" * 30 -ForegroundColor $Colors.Critical
Write-Host "🚨 EMERGENCY DIAGNOSTIC & REPAIR SYSTEM v2.0" -ForegroundColor $Colors.Critical
Write-Host "🚨" * 30 + "`n" -ForegroundColor $Colors.Critical

Write-DiagnosticLog "Emergency Diagnostic Script Started" "Info"
Write-DiagnosticLog "Project Root: $($CONFIG.ProjectRoot)" "Info"
Write-DiagnosticLog "Log File: $($CONFIG.LogFile)" "Info"

# Emergency stop has highest priority
if ($EmergencyStop) {
    Invoke-EmergencyStop
    Write-DiagnosticLog "Emergency stop completed - Exiting" "Critical"
    exit 0
}

# Initialize results
$results = @{
    DiagnosticReport    = $null
    RepairResults       = $null
    MonitoringJob       = $null
    OptimizationActions = @()
}

# Run diagnostic (always run for -AllPhases or explicit -RunDiagnostic)
if ($RunDiagnostic -or $AllPhases) {
    Write-DiagnosticLog "Starting diagnostic phase..." "Info"
    $results.DiagnosticReport = Invoke-ComprehensiveDiagnostic
    
    # Auto-determine if repair is needed
    $needsRepair = $false
    $diagnosticReport = $results.DiagnosticReport
    
    if ($diagnosticReport.SystemResources.CPU -gt $CONFIG.MaxCPUUsage) {
        Write-DiagnosticLog "High CPU usage detected - repair recommended" "Warning"
        $needsRepair = $true
    }
    
    if ($diagnosticReport.SystemResources.Memory.UsedGB -gt $CONFIG.MaxRAMUsageGB) {
        Write-DiagnosticLog "High RAM usage detected - repair recommended" "Warning"
        $needsRepair = $true
    }
    
    $unhealthyServices = $diagnosticReport.ServiceHealth | Where-Object { $_.Accessible -eq $false }
    if ($unhealthyServices.Count -gt 0) {
        Write-DiagnosticLog "Unhealthy services detected - repair recommended" "Warning"
        $needsRepair = $true
    }
    
    if ($diagnosticReport.ProcessAnalysis.Conflicts.Count -gt 0) {
        Write-DiagnosticLog "Process conflicts detected - repair recommended" "Warning"
        $needsRepair = $true
    }
    
    # Auto-trigger repair if needed and requested
    if ($needsRepair -and ($RunRepair -or $AllPhases)) {
        Write-DiagnosticLog "Auto-triggering repair based on diagnostic results" "Warning"
        $results.RepairResults = Invoke-InfrastructureRepair
    }
    elseif ($needsRepair) {
        Write-DiagnosticLog "Issues detected - run with -RunRepair to fix automatically" "Warning"
    }
    else {
        Write-DiagnosticLog "No major issues detected - system appears healthy" "Success"
    }
}

# Run repair (if explicitly requested and not already run)
if ($RunRepair -and -not $results.RepairResults) {
    Write-DiagnosticLog "Starting repair phase..." "Info"
    $results.RepairResults = Invoke-InfrastructureRepair
}

# Run resource optimization (if requested or part of -AllPhases)
if ($OptimizeResources -or $AllPhases) {
    Write-DiagnosticLog "Starting resource optimization..." "Info"
    $results.OptimizationActions = Optimize-SystemResources
}

# Start monitoring (if requested)
if ($StartMonitoring -or $AllPhases) {
    Write-DiagnosticLog "Starting resource monitoring..." "Info"
    $results.MonitoringJob = Start-ResourceMonitoring
}

# Final summary
Write-SectionHeader "🏁 EXECUTION SUMMARY"
Write-DiagnosticLog "Emergency Diagnostic Script Completed" "Success"
Write-DiagnosticLog "Execution time: $([Math]::Round(((Get-Date) - (Get-Date)).TotalSeconds, 2)) seconds" "Info"
Write-DiagnosticLog "Check log file for details: $($CONFIG.LogFile)" "Info"

if ($results.DiagnosticReport) {
    $healthStatus = if ($results.DiagnosticReport.Summary.ResourceIssues.Count -eq 0) { "HEALTHY" } else { "NEEDS ATTENTION" }
    Write-DiagnosticLog "System Health: $healthStatus" $(if ($healthStatus -eq "HEALTHY") { "Success" } else { "Warning" })
}

if ($results.RepairResults) {
    $repairStatus = if ($results.RepairResults.Success) { "SUCCESSFUL" } else { "PARTIAL/FAILED" }
    Write-DiagnosticLog "Repair Status: $repairStatus" $(if ($results.RepairResults.Success) { "Success" } else { "Warning" })
}

if ($results.MonitoringJob) {
    Write-DiagnosticLog "Monitoring Job ID: $($results.MonitoringJob.Id) (running in background)" "Success"
    Write-DiagnosticLog "Use 'Receive-Job $($results.MonitoringJob.Id)' to check monitoring output" "Info"
}

Write-Host "`n💡 USAGE EXAMPLES:" -ForegroundColor $Colors.Info
Write-Host "  .\Emergency-Diagnostic-v2.ps1 -RunDiagnostic                    # Diagnostic only" -ForegroundColor $Colors.Info
Write-Host "  .\Emergency-Diagnostic-v2.ps1 -RunRepair                        # Repair only" -ForegroundColor $Colors.Info
Write-Host "  .\Emergency-Diagnostic-v2.ps1 -AllPhases                        # Full workflow" -ForegroundColor $Colors.Info
Write-Host "  .\Emergency-Diagnostic-v2.ps1 -EmergencyStop                    # Emergency stop" -ForegroundColor $Colors.Info
Write-Host "  .\Emergency-Diagnostic-v2.ps1 -StartMonitoring                  # Start monitoring" -ForegroundColor $Colors.Info

Write-DiagnosticLog "🎯 Phase 0 diagnostic and repair tools ready for use" "Success"