#Requires -Version 5.1
<#
.SYNOPSIS
    Mesure les performances d'exÃƒÂ©cution des scripts PowerShell.
.DESCRIPTION
    Ce script mesure les performances d'exÃƒÂ©cution des scripts PowerShell,
    y compris le temps d'exÃƒÂ©cution, l'utilisation CPU et mÃƒÂ©moire.
.PARAMETER ScriptPath
    Chemin du script ÃƒÂ  mesurer.
.PARAMETER Arguments
    Arguments ÃƒÂ  passer au script.
.PARAMETER Iterations
    Nombre d'itÃƒÂ©rations pour les tests de performance.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport.
.PARAMETER CompareWith
    Chemin d'un rapport de performance prÃƒÂ©cÃƒÂ©dent pour comparaison.
.EXAMPLE
    .\Measure-ScriptPerformance.ps1 -ScriptPath ".\development\scripts\example.ps1" -Iterations 5 -OutputPath ".\reports\performance.json"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃƒÂ©ation: 2025-04-17
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,
    
    [Parameter(Mandatory = $false)]
    [string[]]$Arguments = @(),
    
    [Parameter(Mandatory = $false)]
    [int]$Iterations = 3,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "",
    
    [Parameter(Mandatory = $false)]
    [string]$CompareWith = ""
)

# Fonction pour ÃƒÂ©crire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "TITLE" { "Cyan" }
    }
    
    Write-Host "[$timestamp] " -NoNewline
    Write-Host "[$Level] " -NoNewline -ForegroundColor $color
    Write-Host $Message
}

# Fonction pour mesurer les performances d'un script
function Measure-ScriptPerformance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Arguments = @(),
        
        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3
    )
    
    # VÃƒÂ©rifier si le script existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Log "Le script n'existe pas: $ScriptPath" -Level "ERROR"
        return $null
    }
    
    # VÃƒÂ©rifier si le module PSUtil est disponible pour les mesures de CPU et mÃƒÂ©moire
    $psUtilAvailable = $null -ne (Get-Module -ListAvailable -Name PSUtil -ErrorAction SilentlyContinue)
    
    if (-not $psUtilAvailable) {
        Write-Log "Le module PSUtil n'est pas disponible. Les mesures de CPU et mÃƒÂ©moire ne seront pas effectuÃƒÂ©es." -Level "WARNING"
    }
    
    # PrÃƒÂ©parer la commande
    $scriptCommand = "& '$ScriptPath'"
    
    if ($Arguments.Count -gt 0) {
        $scriptCommand += " " + ($Arguments -join " ")
    }
    
    # Tableau pour stocker les rÃƒÂ©sultats
    $results = @()
    
    # ExÃƒÂ©cuter les itÃƒÂ©rations
    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Log "ExÃƒÂ©cution $i/$Iterations..." -Level "INFO"
        
        # Mesurer le temps d'exÃƒÂ©cution
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Capturer les mÃƒÂ©triques de dÃƒÂ©but
        $startCPU = 0
        $startMemory = 0
        
        if ($psUtilAvailable) {
            $process = Get-Process -Id $PID
            $startCPU = $process.CPU
            $startMemory = $process.WorkingSet64
        }
        
        # ExÃƒÂ©cuter le script
        try {
            $output = Invoke-Expression $scriptCommand -ErrorVariable scriptError 2>&1
            $success = $true
        }
        catch {
            $output = $scriptError
            $success = $false
        }
        
        # ArrÃƒÂªter le chronomÃƒÂ¨tre
        $stopwatch.Stop()
        $executionTime = $stopwatch.Elapsed
        
        # Capturer les mÃƒÂ©triques de fin
        $endCPU = 0
        $endMemory = 0
        
        if ($psUtilAvailable) {
            $process = Get-Process -Id $PID
            $endCPU = $process.CPU
            $endMemory = $process.WorkingSet64
        }
        
        # Calculer les diffÃƒÂ©rences
        $cpuUsage = $endCPU - $startCPU
        $memoryUsage = $endMemory - $startMemory
        
        # Ajouter les rÃƒÂ©sultats
        $results += [PSCustomObject]@{
            Iteration = $i
            ExecutionTimeMs = $executionTime.TotalMilliseconds
            ExecutionTimeSec = $executionTime.TotalSeconds
            CPUUsage = $cpuUsage
            MemoryUsageBytes = $memoryUsage
            MemoryUsageMB = [math]::Round($memoryUsage / 1MB, 2)
            Success = $success
            Output = $output
            Timestamp = (Get-Date).ToString("o")
        }
        
        # Afficher les rÃƒÂ©sultats
        Write-Log "Temps d'exÃƒÂ©cution: $($executionTime.TotalSeconds) secondes" -Level $(if ($success) { "SUCCESS" } else { "ERROR" })
        
        if ($psUtilAvailable) {
            Write-Log "Utilisation CPU: $cpuUsage" -Level "INFO"
            Write-Log "Utilisation mÃƒÂ©moire: $([math]::Round($memoryUsage / 1MB, 2)) MB" -Level "INFO"
        }
        
        # Attendre un peu entre les itÃƒÂ©rations
        if ($i -lt $Iterations) {
            Start-Sleep -Seconds 1
        }
    }
    
    # Calculer les statistiques
    $executionTimes = $results | ForEach-Object { $_.ExecutionTimeMs }
    $cpuUsages = $results | ForEach-Object { $_.CPUUsage }
    $memoryUsages = $results | ForEach-Object { $_.MemoryUsageBytes }
    
    $avgExecutionTime = ($executionTimes | Measure-Object -Average).Average
    $minExecutionTime = ($executionTimes | Measure-Object -Minimum).Minimum
    $maxExecutionTime = ($executionTimes | Measure-Object -Maximum).Maximum
    
    $avgCPUUsage = if ($psUtilAvailable) { ($cpuUsages | Measure-Object -Average).Average } else { 0 }
    $avgMemoryUsage = if ($psUtilAvailable) { ($memoryUsages | Measure-Object -Average).Average } else { 0 }
    
    # CrÃƒÂ©er le rapport
    $report = [PSCustomObject]@{
        ScriptPath = $ScriptPath
        Arguments = $Arguments
        Iterations = $Iterations
        Timestamp = (Get-Date).ToString("o")
        Statistics = [PSCustomObject]@{
            AvgExecutionTimeMs = $avgExecutionTime
            AvgExecutionTimeSec = $avgExecutionTime / 1000
            MinExecutionTimeMs = $minExecutionTime
            MaxExecutionTimeMs = $maxExecutionTime
            AvgCPUUsage = $avgCPUUsage
            AvgMemoryUsageBytes = $avgMemoryUsage
            AvgMemoryUsageMB = [math]::Round($avgMemoryUsage / 1MB, 2)
            SuccessRate = ($results | Where-Object { $_.Success } | Measure-Object).Count / $Iterations * 100
        }
        Results = $results
    }
    
    return $report
}

# Fonction pour comparer deux rapports de performance
function Compare-PerformanceReports {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$CurrentReport,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PreviousReport
    )
    
    # Calculer les diffÃƒÂ©rences
    $executionTimeDiff = $CurrentReport.Statistics.AvgExecutionTimeMs - $PreviousReport.Statistics.AvgExecutionTimeMs
    $executionTimePercent = if ($PreviousReport.Statistics.AvgExecutionTimeMs -ne 0) {
        ($executionTimeDiff / $PreviousReport.Statistics.AvgExecutionTimeMs) * 100
    } else {
        0
    }
    
    $cpuUsageDiff = $CurrentReport.Statistics.AvgCPUUsage - $PreviousReport.Statistics.AvgCPUUsage
    $cpuUsagePercent = if ($PreviousReport.Statistics.AvgCPUUsage -ne 0) {
        ($cpuUsageDiff / $PreviousReport.Statistics.AvgCPUUsage) * 100
    } else {
        0
    }
    
    $memoryUsageDiff = $CurrentReport.Statistics.AvgMemoryUsageBytes - $PreviousReport.Statistics.AvgMemoryUsageBytes
    $memoryUsagePercent = if ($PreviousReport.Statistics.AvgMemoryUsageBytes -ne 0) {
        ($memoryUsageDiff / $PreviousReport.Statistics.AvgMemoryUsageBytes) * 100
    } else {
        0
    }
    
    $successRateDiff = $CurrentReport.Statistics.SuccessRate - $PreviousReport.Statistics.SuccessRate
    
    # CrÃƒÂ©er le rapport de comparaison
    $comparison = [PSCustomObject]@{
        CurrentTimestamp = $CurrentReport.Timestamp
        PreviousTimestamp = $PreviousReport.Timestamp
        ExecutionTime = [PSCustomObject]@{
            Current = $CurrentReport.Statistics.AvgExecutionTimeMs
            Previous = $PreviousReport.Statistics.AvgExecutionTimeMs
            Difference = $executionTimeDiff
            PercentChange = [math]::Round($executionTimePercent, 2)
            Improved = $executionTimeDiff -lt 0
        }
        CPUUsage = [PSCustomObject]@{
            Current = $CurrentReport.Statistics.AvgCPUUsage
            Previous = $PreviousReport.Statistics.AvgCPUUsage
            Difference = $cpuUsageDiff
            PercentChange = [math]::Round($cpuUsagePercent, 2)
            Improved = $cpuUsageDiff -lt 0
        }
        MemoryUsage = [PSCustomObject]@{
            Current = $CurrentReport.Statistics.AvgMemoryUsageBytes
            Previous = $PreviousReport.Statistics.AvgMemoryUsageBytes
            Difference = $memoryUsageDiff
            PercentChange = [math]::Round($memoryUsagePercent, 2)
            Improved = $memoryUsageDiff -lt 0
        }
        SuccessRate = [PSCustomObject]@{
            Current = $CurrentReport.Statistics.SuccessRate
            Previous = $PreviousReport.Statistics.SuccessRate
            Difference = $successRateDiff
            Improved = $successRateDiff -ge 0
        }
    }
    
    return $comparison
}

# Fonction principale
function Start-PerformanceMeasurement {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Arguments = @(),
        
        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [string]$CompareWith = ""
    )
    
    Write-Log "DÃƒÂ©marrage de la mesure de performance..." -Level "TITLE"
    Write-Log "Script: $ScriptPath"
    Write-Log "Arguments: $($Arguments -join ' ')"
    Write-Log "ItÃƒÂ©rations: $Iterations"
    
    # Mesurer les performances
    $report = Measure-ScriptPerformance -ScriptPath $ScriptPath -Arguments $Arguments -Iterations $Iterations
    
    if ($null -eq $report) {
        Write-Log "Ãƒâ€°chec de la mesure de performance." -Level "ERROR"
        return
    }
    
    # Afficher les statistiques
    Write-Log "RÃƒÂ©sultats:" -Level "TITLE"
    Write-Log "Temps d'exÃƒÂ©cution moyen: $([math]::Round($report.Statistics.AvgExecutionTimeSec, 3)) secondes" -Level "INFO"
    Write-Log "Temps d'exÃƒÂ©cution min: $([math]::Round($report.Statistics.MinExecutionTimeMs / 1000, 3)) secondes" -Level "INFO"
    Write-Log "Temps d'exÃƒÂ©cution max: $([math]::Round($report.Statistics.MaxExecutionTimeMs / 1000, 3)) secondes" -Level "INFO"
    Write-Log "Utilisation CPU moyenne: $([math]::Round($report.Statistics.AvgCPUUsage, 2))" -Level "INFO"
    Write-Log "Utilisation mÃƒÂ©moire moyenne: $($report.Statistics.AvgMemoryUsageMB) MB" -Level "INFO"
    Write-Log "Taux de rÃƒÂ©ussite: $([math]::Round($report.Statistics.SuccessRate, 2))%" -Level "INFO"
    
    # Comparer avec un rapport prÃƒÂ©cÃƒÂ©dent si demandÃƒÂ©
    if ($CompareWith -and (Test-Path -Path $CompareWith)) {
        Write-Log "Comparaison avec le rapport prÃƒÂ©cÃƒÂ©dent: $CompareWith" -Level "INFO"
        
        try {
            $previousReport = Get-Content -Path $CompareWith -Raw | ConvertFrom-Json
            $comparison = Compare-PerformanceReports -CurrentReport $report -PreviousReport $previousReport
            
            Write-Log "Comparaison:" -Level "TITLE"
            
            # Temps d'exÃƒÂ©cution
            $executionTimeChange = if ($comparison.ExecutionTime.Improved) { "amÃƒÂ©lioration" } else { "dÃƒÂ©gradation" }
            Write-Log "Temps d'exÃƒÂ©cution: $executionTimeChange de $([math]::Abs($comparison.ExecutionTime.PercentChange))%" -Level $(if ($comparison.ExecutionTime.Improved) { "SUCCESS" } else { "WARNING" })
            
            # Utilisation CPU
            $cpuUsageChange = if ($comparison.CPUUsage.Improved) { "amÃƒÂ©lioration" } else { "dÃƒÂ©gradation" }
            Write-Log "Utilisation CPU: $cpuUsageChange de $([math]::Abs($comparison.CPUUsage.PercentChange))%" -Level $(if ($comparison.CPUUsage.Improved) { "SUCCESS" } else { "WARNING" })
            
            # Utilisation mÃƒÂ©moire
            $memoryUsageChange = if ($comparison.MemoryUsage.Improved) { "amÃƒÂ©lioration" } else { "dÃƒÂ©gradation" }
            Write-Log "Utilisation mÃƒÂ©moire: $memoryUsageChange de $([math]::Abs($comparison.MemoryUsage.PercentChange))%" -Level $(if ($comparison.MemoryUsage.Improved) { "SUCCESS" } else { "WARNING" })
            
            # Taux de rÃƒÂ©ussite
            $successRateChange = if ($comparison.SuccessRate.Improved) { "amÃƒÂ©lioration" } else { "dÃƒÂ©gradation" }
            Write-Log "Taux de rÃƒÂ©ussite: $successRateChange de $([math]::Abs($comparison.SuccessRate.Difference))%" -Level $(if ($comparison.SuccessRate.Improved) { "SUCCESS" } else { "WARNING" })
            
            # Ajouter la comparaison au rapport
            $report | Add-Member -MemberType NoteProperty -Name "Comparison" -Value $comparison
        }
        catch {
            Write-Log "Erreur lors de la comparaison avec le rapport prÃƒÂ©cÃƒÂ©dent: $_" -Level "ERROR"
        }
    }
    
    # Enregistrer le rapport si demandÃƒÂ©
    if ($OutputPath) {
        try {
            # CrÃƒÂ©er le dossier de sortie s'il n'existe pas
            $outputDir = [System.IO.Path]::GetDirectoryName($OutputPath)
            
            if (-not (Test-Path -Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }
            
            # Enregistrer le rapport
            $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
            
            Write-Log "Rapport enregistrÃƒÂ©: $OutputPath" -Level "SUCCESS"
        }
        catch {
            Write-Log "Erreur lors de l'enregistrement du rapport: $_" -Level "ERROR"
        }
    }
    
    return $report
}

# ExÃƒÂ©cuter la fonction principale
Start-PerformanceMeasurement -ScriptPath $ScriptPath -Arguments $Arguments -Iterations $Iterations -OutputPath $OutputPath -CompareWith $CompareWith
