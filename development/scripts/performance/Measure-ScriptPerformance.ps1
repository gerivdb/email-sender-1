#Requires -Version 5.1
<#
.SYNOPSIS
    Mesure les performances d'exÃ©cution des scripts PowerShell.
.DESCRIPTION
    Ce script mesure les performances d'exÃ©cution des scripts PowerShell,
    y compris le temps d'exÃ©cution, l'utilisation CPU et mÃ©moire.
.PARAMETER ScriptPath
    Chemin du script Ã  mesurer.
.PARAMETER Arguments
    Arguments Ã  passer au script.
.PARAMETER Iterations
    Nombre d'itÃ©rations pour les tests de performance.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport.
.PARAMETER CompareWith
    Chemin d'un rapport de performance prÃ©cÃ©dent pour comparaison.
.EXAMPLE
    .\Measure-ScriptPerformance.ps1 -ScriptPath ".\development\scripts\example.ps1" -Iterations 5 -OutputPath ".\reports\performance.json"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-17
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

# Fonction pour Ã©crire dans le journal
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
    
    # VÃ©rifier si le script existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Log "Le script n'existe pas: $ScriptPath" -Level "ERROR"
        return $null
    }
    
    # VÃ©rifier si le module PSUtil est disponible pour les mesures de CPU et mÃ©moire
    $psUtilAvailable = $null -ne (Get-Module -ListAvailable -Name PSUtil -ErrorAction SilentlyContinue)
    
    if (-not $psUtilAvailable) {
        Write-Log "Le module PSUtil n'est pas disponible. Les mesures de CPU et mÃ©moire ne seront pas effectuÃ©es." -Level "WARNING"
    }
    
    # PrÃ©parer la commande
    $scriptCommand = "& '$ScriptPath'"
    
    if ($Arguments.Count -gt 0) {
        $scriptCommand += " " + ($Arguments -join " ")
    }
    
    # Tableau pour stocker les rÃ©sultats
    $results = @()
    
    # ExÃ©cuter les itÃ©rations
    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Log "ExÃ©cution $i/$Iterations..." -Level "INFO"
        
        # Mesurer le temps d'exÃ©cution
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Capturer les mÃ©triques de dÃ©but
        $startCPU = 0
        $startMemory = 0
        
        if ($psUtilAvailable) {
            $process = Get-Process -Id $PID
            $startCPU = $process.CPU
            $startMemory = $process.WorkingSet64
        }
        
        # ExÃ©cuter le script
        try {
            $output = Invoke-Expression $scriptCommand -ErrorVariable scriptError 2>&1
            $success = $true
        }
        catch {
            $output = $scriptError
            $success = $false
        }
        
        # ArrÃªter le chronomÃ¨tre
        $stopwatch.Stop()
        $executionTime = $stopwatch.Elapsed
        
        # Capturer les mÃ©triques de fin
        $endCPU = 0
        $endMemory = 0
        
        if ($psUtilAvailable) {
            $process = Get-Process -Id $PID
            $endCPU = $process.CPU
            $endMemory = $process.WorkingSet64
        }
        
        # Calculer les diffÃ©rences
        $cpuUsage = $endCPU - $startCPU
        $memoryUsage = $endMemory - $startMemory
        
        # Ajouter les rÃ©sultats
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
        
        # Afficher les rÃ©sultats
        Write-Log "Temps d'exÃ©cution: $($executionTime.TotalSeconds) secondes" -Level $(if ($success) { "SUCCESS" } else { "ERROR" })
        
        if ($psUtilAvailable) {
            Write-Log "Utilisation CPU: $cpuUsage" -Level "INFO"
            Write-Log "Utilisation mÃ©moire: $([math]::Round($memoryUsage / 1MB, 2)) MB" -Level "INFO"
        }
        
        # Attendre un peu entre les itÃ©rations
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
    
    # CrÃ©er le rapport
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
    
    # Calculer les diffÃ©rences
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
    
    # CrÃ©er le rapport de comparaison
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
    
    Write-Log "DÃ©marrage de la mesure de performance..." -Level "TITLE"
    Write-Log "Script: $ScriptPath"
    Write-Log "Arguments: $($Arguments -join ' ')"
    Write-Log "ItÃ©rations: $Iterations"
    
    # Mesurer les performances
    $report = Measure-ScriptPerformance -ScriptPath $ScriptPath -Arguments $Arguments -Iterations $Iterations
    
    if ($null -eq $report) {
        Write-Log "Ã‰chec de la mesure de performance." -Level "ERROR"
        return
    }
    
    # Afficher les statistiques
    Write-Log "RÃ©sultats:" -Level "TITLE"
    Write-Log "Temps d'exÃ©cution moyen: $([math]::Round($report.Statistics.AvgExecutionTimeSec, 3)) secondes" -Level "INFO"
    Write-Log "Temps d'exÃ©cution min: $([math]::Round($report.Statistics.MinExecutionTimeMs / 1000, 3)) secondes" -Level "INFO"
    Write-Log "Temps d'exÃ©cution max: $([math]::Round($report.Statistics.MaxExecutionTimeMs / 1000, 3)) secondes" -Level "INFO"
    Write-Log "Utilisation CPU moyenne: $([math]::Round($report.Statistics.AvgCPUUsage, 2))" -Level "INFO"
    Write-Log "Utilisation mÃ©moire moyenne: $($report.Statistics.AvgMemoryUsageMB) MB" -Level "INFO"
    Write-Log "Taux de rÃ©ussite: $([math]::Round($report.Statistics.SuccessRate, 2))%" -Level "INFO"
    
    # Comparer avec un rapport prÃ©cÃ©dent si demandÃ©
    if ($CompareWith -and (Test-Path -Path $CompareWith)) {
        Write-Log "Comparaison avec le rapport prÃ©cÃ©dent: $CompareWith" -Level "INFO"
        
        try {
            $previousReport = Get-Content -Path $CompareWith -Raw | ConvertFrom-Json
            $comparison = Compare-PerformanceReports -CurrentReport $report -PreviousReport $previousReport
            
            Write-Log "Comparaison:" -Level "TITLE"
            
            # Temps d'exÃ©cution
            $executionTimeChange = if ($comparison.ExecutionTime.Improved) { "amÃ©lioration" } else { "dÃ©gradation" }
            Write-Log "Temps d'exÃ©cution: $executionTimeChange de $([math]::Abs($comparison.ExecutionTime.PercentChange))%" -Level $(if ($comparison.ExecutionTime.Improved) { "SUCCESS" } else { "WARNING" })
            
            # Utilisation CPU
            $cpuUsageChange = if ($comparison.CPUUsage.Improved) { "amÃ©lioration" } else { "dÃ©gradation" }
            Write-Log "Utilisation CPU: $cpuUsageChange de $([math]::Abs($comparison.CPUUsage.PercentChange))%" -Level $(if ($comparison.CPUUsage.Improved) { "SUCCESS" } else { "WARNING" })
            
            # Utilisation mÃ©moire
            $memoryUsageChange = if ($comparison.MemoryUsage.Improved) { "amÃ©lioration" } else { "dÃ©gradation" }
            Write-Log "Utilisation mÃ©moire: $memoryUsageChange de $([math]::Abs($comparison.MemoryUsage.PercentChange))%" -Level $(if ($comparison.MemoryUsage.Improved) { "SUCCESS" } else { "WARNING" })
            
            # Taux de rÃ©ussite
            $successRateChange = if ($comparison.SuccessRate.Improved) { "amÃ©lioration" } else { "dÃ©gradation" }
            Write-Log "Taux de rÃ©ussite: $successRateChange de $([math]::Abs($comparison.SuccessRate.Difference))%" -Level $(if ($comparison.SuccessRate.Improved) { "SUCCESS" } else { "WARNING" })
            
            # Ajouter la comparaison au rapport
            $report | Add-Member -MemberType NoteProperty -Name "Comparison" -Value $comparison
        }
        catch {
            Write-Log "Erreur lors de la comparaison avec le rapport prÃ©cÃ©dent: $_" -Level "ERROR"
        }
    }
    
    # Enregistrer le rapport si demandÃ©
    if ($OutputPath) {
        try {
            # CrÃ©er le dossier de sortie s'il n'existe pas
            $outputDir = [System.IO.Path]::GetDirectoryName($OutputPath)
            
            if (-not (Test-Path -Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }
            
            # Enregistrer le rapport
            $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
            
            Write-Log "Rapport enregistrÃ©: $OutputPath" -Level "SUCCESS"
        }
        catch {
            Write-Log "Erreur lors de l'enregistrement du rapport: $_" -Level "ERROR"
        }
    }
    
    return $report
}

# ExÃ©cuter la fonction principale
Start-PerformanceMeasurement -ScriptPath $ScriptPath -Arguments $Arguments -Iterations $Iterations -OutputPath $OutputPath -CompareWith $CompareWith
