# Optimize-ProjectResources.ps1
# Optimisation ciblée uniquement pour le projet EMAIL_SENDER_1

param(
    [switch]$KillOrphans,
    [switch]$OptimizePriorities,
    [switch]$CleanupCaches,
    [switch]$AllOptimizations
)

$PROJECT_ROOT = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$PROJECT_NAME = "EMAIL_SENDER_1"

Write-Host "🎯 PROJECT-FOCUSED OPTIMIZATION: $PROJECT_NAME" -ForegroundColor Cyan
Write-Host "📁 Project Root: $PROJECT_ROOT" -ForegroundColor Gray

function Get-ProjectRelatedProcesses {
    Write-Host "`n🔍 Identifying project-related processes..." -ForegroundColor Yellow
    
    $projectProcesses = @()
    
    # 1. VSCode processes dans notre workspace
    $vscodeProcesses = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    foreach ($proc in $vscodeProcesses) {
        if ($proc.MainWindowTitle -like "*EMAIL_SENDER*" -or 
            $proc.StartInfo.WorkingDirectory -like "*EMAIL_SENDER*") {
            $projectProcesses += @{
                Process = $proc
                Category = "VSCode-Project"
                Priority = "High"
            }
        }
    }
    
    # 2. Go processes dans notre répertoire
    $goProcesses = Get-Process -Name "go", "gopls" -ErrorAction SilentlyContinue
    foreach ($proc in $goProcesses) {
        try {
            $cmdLine = (Get-WmiObject Win32_Process -Filter "ProcessId = $($proc.Id)").CommandLine
            if ($cmdLine -like "*EMAIL_SENDER*" -or $cmdLine -like "*$PROJECT_ROOT*") {
                $projectProcesses += @{
                    Process = $proc
                    Category = "Go-Project"
                    Priority = "Medium"
                    CommandLine = $cmdLine
                }
            }
        } catch {
            # Si on ne peut pas récupérer la ligne de commande, on ignore
        }
    }
    
    # 3. Python processes du projet
    $pythonProcesses = Get-Process -Name "python", "pip" -ErrorAction SilentlyContinue
    foreach ($proc in $pythonProcesses) {
        try {
            $cmdLine = (Get-WmiObject Win32_Process -Filter "ProcessId = $($proc.Id)").CommandLine
            if ($cmdLine -like "*EMAIL_SENDER*" -or $cmdLine -like "*$PROJECT_ROOT*") {
                $projectProcesses += @{
                    Process = $proc
                    Category = "Python-Project"
                    Priority = "Medium"
                    CommandLine = $cmdLine
                }
            }
        } catch {
            # Si on ne peut pas récupérer la ligne de commande, on ignore
        }
    }
    
    # 4. Docker containers liés au projet
    try {
        $dockerContainers = docker ps --format "table {{.Names}}\t{{.Status}}" 2>$null
        if ($dockerContainers -like "*email*" -or $dockerContainers -like "*sender*") {
            Write-Host "📦 Docker containers detected for project" -ForegroundColor Cyan
        }
    } catch {
        # Docker non disponible
    }
    
    return $projectProcesses
}

function Show-ProjectProcessSummary {
    param([array]$ProjectProcesses)
    
    Write-Host "`n📊 PROJECT PROCESSES SUMMARY:" -ForegroundColor Green
    
    $categories = $ProjectProcesses | Group-Object -Property Category
    foreach ($category in $categories) {
        Write-Host "  $($category.Name): $($category.Count) processes" -ForegroundColor White
        
        foreach ($item in $category.Group) {
            $proc = $item.Process
            $cpuTime = if ($proc.CPU) { [Math]::Round($proc.CPU, 1) } else { "0" }
            $memoryMB = [Math]::Round($proc.WorkingSet / 1MB, 1)
            
            Write-Host "    - $($proc.Name) (PID: $($proc.Id)) - CPU: ${cpuTime}s, RAM: ${memoryMB}MB" -ForegroundColor Gray
        }
    }
}

function Optimize-ProjectProcessPriorities {
    param([array]$ProjectProcesses)
    
    Write-Host "`n⚡ Optimizing project process priorities..." -ForegroundColor Yellow
    
    $optimizedCount = 0
    
    foreach ($item in $ProjectProcesses) {
        $proc = $item.Process
        $category = $item.Category
        
        try {
            $currentPriority = $proc.PriorityClass
            $newPriority = switch ($category) {
                "VSCode-Project" { "Normal" }  # Garder VSCode normal
                "Go-Project" { "BelowNormal" } # Go peut être réduit
                "Python-Project" { "BelowNormal" } # Python peut être réduit
                default { "BelowNormal" }
            }
            
            if ($currentPriority -ne $newPriority) {
                $proc.PriorityClass = $newPriority
                Write-Host "  ✅ $($proc.Name): $currentPriority → $newPriority" -ForegroundColor Green
                $optimizedCount++
            }
        } catch {
            Write-Host "  ⚠️ Could not optimize $($proc.Name): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "📊 Optimized $optimizedCount project processes" -ForegroundColor Green
    return $optimizedCount
}

function Remove-ProjectOrphanProcesses {
    param([array]$ProjectProcesses)
    
    Write-Host "`n🧹 Cleaning project orphan processes..." -ForegroundColor Yellow
    
    $removedCount = 0
    $orphanPatterns = @(
        "*email_sender*test*",
        "*cache_test*",
        "*debug*main*",
        "*coverage*"
    )
    
    foreach ($item in $ProjectProcesses) {
        $proc = $item.Process
        $cmdLine = $item.CommandLine
        
        $isOrphan = $false
        foreach ($pattern in $orphanPatterns) {
            if ($proc.Name -like $pattern -or $cmdLine -like $pattern) {
                $isOrphan = $true
                break
            }
        }
        
        # Vérifier si c'est un processus de test qui tourne depuis longtemps
        if ($proc.Name -eq "go" -and $proc.CPU -gt 1000) {
            $isOrphan = $true
        }
        
        if ($isOrphan) {
            try {
                Write-Host "  🗑️ Removing orphan: $($proc.Name) (PID: $($proc.Id))" -ForegroundColor Red
                Stop-Process -Id $proc.Id -Force
                $removedCount++
            } catch {
                Write-Host "  ⚠️ Could not remove $($proc.Name): $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host "📊 Removed $removedCount orphan project processes" -ForegroundColor Green
    return $removedCount
}

function Clean-ProjectCaches {
    Write-Host "`n🧽 Cleaning project-specific caches..." -ForegroundColor Yellow
    
    $cachesCleaned = 0
    
    # Go module cache (seulement pour notre projet)
    try {
        Push-Location $PROJECT_ROOT
        $goCleanOutput = go clean -cache -modcache -testcache 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Go caches cleaned" -ForegroundColor Green
            $cachesCleaned++
        }
        Pop-Location
    } catch {
        Write-Host "  ⚠️ Go cache cleanup failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Python cache dans le projet
    $pycacheFiles = Get-ChildItem -Path $PROJECT_ROOT -Recurse -Name "__pycache__" -ErrorAction SilentlyContinue
    foreach ($cache in $pycacheFiles) {
        try {
            Remove-Item -Path (Join-Path $PROJECT_ROOT $cache) -Recurse -Force
            Write-Host "  ✅ Removed Python cache: $cache" -ForegroundColor Green
            $cachesCleaned++
        } catch {
            Write-Host "  ⚠️ Could not remove $cache" -ForegroundColor Yellow
        }
    }
    
    # Logs anciens du projet
    $oldLogs = Get-ChildItem -Path $PROJECT_ROOT -Name "*.log" -ErrorAction SilentlyContinue | 
               Where-Object { (Get-Item (Join-Path $PROJECT_ROOT $_)).LastWriteTime -lt (Get-Date).AddDays(-1) }
    
    foreach ($log in $oldLogs) {
        try {
            Remove-Item -Path (Join-Path $PROJECT_ROOT $log) -Force
            Write-Host "  ✅ Removed old log: $log" -ForegroundColor Green
            $cachesCleaned++
        } catch {
            Write-Host "  ⚠️ Could not remove $log" -ForegroundColor Yellow
        }
    }
    
    Write-Host "📊 Cleaned $cachesCleaned project cache items" -ForegroundColor Green
    return $cachesCleaned
}

function Get-ProjectResourceUsage {
    param([array]$ProjectProcesses)
    
    $totalCPU = 0
    $totalRAM = 0
    
    foreach ($item in $ProjectProcesses) {
        $proc = $item.Process
        $totalCPU += if ($proc.CPU) { $proc.CPU } else { 0 }
        $totalRAM += $proc.WorkingSet / 1MB
    }
    
    return @{
        TotalCPUTime = [Math]::Round($totalCPU, 1)
        TotalRAMMB = [Math]::Round($totalRAM, 1)
        ProcessCount = $ProjectProcesses.Count
    }
}

# === MAIN EXECUTION ===

# 1. Identifier les processus du projet
$projectProcesses = Get-ProjectRelatedProcesses

if ($projectProcesses.Count -eq 0) {
    Write-Host "ℹ️ No project-specific processes found" -ForegroundColor Gray
    exit 0
}

# 2. Afficher résumé
Show-ProjectProcessSummary -ProjectProcesses $projectProcesses

# 3. Mesurer usage initial
$initialUsage = Get-ProjectResourceUsage -ProjectProcesses $projectProcesses
Write-Host "`n📊 INITIAL PROJECT RESOURCE USAGE:" -ForegroundColor Cyan
Write-Host "  CPU Time: $($initialUsage.TotalCPUTime)s" -ForegroundColor White
Write-Host "  RAM: $($initialUsage.TotalRAMMB)MB" -ForegroundColor White
Write-Host "  Processes: $($initialUsage.ProcessCount)" -ForegroundColor White

# 4. Exécuter optimisations
$totalOptimizations = 0

if ($KillOrphans -or $AllOptimizations) {
    $totalOptimizations += Remove-ProjectOrphanProcesses -ProjectProcesses $projectProcesses
    # Rafraîchir la liste après suppression
    $projectProcesses = Get-ProjectRelatedProcesses
}

if ($OptimizePriorities -or $AllOptimizations) {
    $totalOptimizations += Optimize-ProjectProcessPriorities -ProjectProcesses $projectProcesses
}

if ($CleanupCaches -or $AllOptimizations) {
    $totalOptimizations += Clean-ProjectCaches
}

# 5. Mesurer usage final
Start-Sleep -Seconds 2
$projectProcesses = Get-ProjectRelatedProcesses  # Refresh
$finalUsage = Get-ProjectResourceUsage -ProjectProcesses $projectProcesses

Write-Host "`n📊 FINAL PROJECT RESOURCE USAGE:" -ForegroundColor Green
Write-Host "  CPU Time: $($finalUsage.TotalCPUTime)s" -ForegroundColor White
Write-Host "  RAM: $($finalUsage.TotalRAMMB)MB" -ForegroundColor White
Write-Host "  Processes: $($finalUsage.ProcessCount)" -ForegroundColor White

# 6. Calculer amélioration
$cpuImprovement = $initialUsage.TotalCPUTime - $finalUsage.TotalCPUTime
$ramImprovement = $initialUsage.TotalRAMMB - $finalUsage.TotalRAMMB

Write-Host "`n🎯 OPTIMIZATION RESULTS:" -ForegroundColor Cyan
Write-Host "  Total optimizations applied: $totalOptimizations" -ForegroundColor White
Write-Host "  CPU time change: $cpuImprovement seconds" -ForegroundColor $(if($cpuImprovement -gt 0){"Green"}else{"Gray"})
Write-Host "  RAM change: $([Math]::Round($ramImprovement, 1))MB" -ForegroundColor $(if($ramImprovement -gt 0){"Green"}else{"Gray"})

Write-Host "`n✅ Project optimization completed!" -ForegroundColor Green

# Usage examples:
# .\Optimize-ProjectResources.ps1 -AllOptimizations
# .\Optimize-ProjectResources.ps1 -KillOrphans -OptimizePriorities
# .\Optimize-ProjectResources.ps1 -CleanupCaches
