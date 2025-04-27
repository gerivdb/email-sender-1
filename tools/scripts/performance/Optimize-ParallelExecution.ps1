#Requires -Version 5.1
<#
.SYNOPSIS
    Optimise l'exÃ©cution parallÃ¨le des scripts PowerShell.
.DESCRIPTION
    Ce script analyse et optimise l'exÃ©cution parallÃ¨le des scripts PowerShell
    en utilisant les Runspace Pools pour maximiser les performances.
.PARAMETER ScriptPath
    Chemin du script Ã  optimiser.
.PARAMETER InputData
    DonnÃ©es d'entrÃ©e pour le script (tableau d'objets).
.PARAMETER MaxThreads
    Nombre maximum de threads Ã  utiliser (0 = nombre de processeurs).
.PARAMETER ChunkSize
    Taille des lots pour le traitement par lots (0 = automatique).
.PARAMETER OutputPath
    Chemin du fichier de sortie pour les rÃ©sultats.
.PARAMETER Measure
    Mesure les performances avant et aprÃ¨s l'optimisation.
.EXAMPLE
    .\Optimize-ParallelExecution.ps1 -ScriptPath ".\scripts\process-data.ps1" -InputData $data -MaxThreads 8 -OutputPath ".\output\results.json"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-17
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,
    
    [Parameter(Mandatory = $true)]
    [object[]]$InputData,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxThreads = 0,
    
    [Parameter(Mandatory = $false)]
    [int]$ChunkSize = 0,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$Measure
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

# Fonction pour exÃ©cuter un script en sÃ©quentiel
function Invoke-SequentialExecution {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [object[]]$InputData
    )
    
    Write-Log "ExÃ©cution sÃ©quentielle..." -Level "INFO"
    
    $results = @()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    foreach ($item in $InputData) {
        try {
            $result = & $ScriptPath $item
            $results += $result
        }
        catch {
            Write-Log "Erreur lors de l'exÃ©cution sÃ©quentielle: $_" -Level "ERROR"
        }
    }
    
    $stopwatch.Stop()
    $executionTime = $stopwatch.Elapsed
    
    Write-Log "ExÃ©cution sÃ©quentielle terminÃ©e en $($executionTime.TotalSeconds) secondes" -Level "SUCCESS"
    
    return [PSCustomObject]@{
        Results = $results
        ExecutionTime = $executionTime
        ItemsProcessed = $InputData.Count
    }
}

# Fonction pour exÃ©cuter un script en parallÃ¨le avec ForEach-Object -Parallel (PowerShell 7+)
function Invoke-ParallelForeach {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [object[]]$InputData,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0
    )
    
    # VÃ©rifier si PowerShell 7+ est disponible
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Log "ForEach-Object -Parallel nÃ©cessite PowerShell 7+. Version actuelle: $($PSVersionTable.PSVersion)" -Level "ERROR"
        return $null
    }
    
    # DÃ©terminer le nombre de threads
    if ($MaxThreads -le 0) {
        $MaxThreads = [Environment]::ProcessorCount
    }
    
    Write-Log "ExÃ©cution parallÃ¨le avec ForEach-Object -Parallel (MaxThreads: $MaxThreads)..." -Level "INFO"
    
    $results = @()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $results = $InputData | ForEach-Object -ThrottleLimit $MaxThreads -Parallel {
            & $using:ScriptPath $_
        }
    }
    catch {
        Write-Log "Erreur lors de l'exÃ©cution parallÃ¨le avec ForEach-Object: $_" -Level "ERROR"
    }
    
    $stopwatch.Stop()
    $executionTime = $stopwatch.Elapsed
    
    Write-Log "ExÃ©cution parallÃ¨le avec ForEach-Object terminÃ©e en $($executionTime.TotalSeconds) secondes" -Level "SUCCESS"
    
    return [PSCustomObject]@{
        Results = $results
        ExecutionTime = $executionTime
        ItemsProcessed = $InputData.Count
        MaxThreads = $MaxThreads
    }
}

# Fonction pour exÃ©cuter un script en parallÃ¨le avec Runspace Pools
function Invoke-RunspacePoolExecution {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [object[]]$InputData,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0
    )
    
    # DÃ©terminer le nombre de threads
    if ($MaxThreads -le 0) {
        $MaxThreads = [Environment]::ProcessorCount
    }
    
    Write-Log "ExÃ©cution parallÃ¨le avec Runspace Pool (MaxThreads: $MaxThreads)..." -Level "INFO"
    
    $results = @()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # CrÃ©er le pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxThreads, $sessionState, $Host)
        $pool.Open()
        
        # CrÃ©er les runspaces
        $runspaces = @()
        
        foreach ($item in $InputData) {
            $powershell = [System.Management.Automation.PowerShell]::Create()
            $powershell.RunspacePool = $pool
            
            # Ajouter le script et les paramÃ¨tres
            [void]$powershell.AddScript("param(`$item) & '$ScriptPath' `$item")
            [void]$powershell.AddArgument($item)
            
            # DÃ©marrer l'exÃ©cution asynchrone
            $runspaces += [PSCustomObject]@{
                PowerShell = $powershell
                AsyncResult = $powershell.BeginInvoke()
                Item = $item
            }
        }
        
        # RÃ©cupÃ©rer les rÃ©sultats
        foreach ($runspace in $runspaces) {
            $result = $runspace.PowerShell.EndInvoke($runspace.AsyncResult)
            $results += $result
            $runspace.PowerShell.Dispose()
        }
        
        # Fermer le pool
        $pool.Close()
        $pool.Dispose()
    }
    catch {
        Write-Log "Erreur lors de l'exÃ©cution parallÃ¨le avec Runspace Pool: $_" -Level "ERROR"
    }
    
    $stopwatch.Stop()
    $executionTime = $stopwatch.Elapsed
    
    Write-Log "ExÃ©cution parallÃ¨le avec Runspace Pool terminÃ©e en $($executionTime.TotalSeconds) secondes" -Level "SUCCESS"
    
    return [PSCustomObject]@{
        Results = $results
        ExecutionTime = $executionTime
        ItemsProcessed = $InputData.Count
        MaxThreads = $MaxThreads
    }
}

# Fonction pour exÃ©cuter un script en parallÃ¨le avec traitement par lots
function Invoke-BatchParallelExecution {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [object[]]$InputData,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$ChunkSize = 0
    )
    
    # DÃ©terminer le nombre de threads
    if ($MaxThreads -le 0) {
        $MaxThreads = [Environment]::ProcessorCount
    }
    
    # DÃ©terminer la taille des lots
    if ($ChunkSize -le 0) {
        # Calculer une taille de lot optimale
        $itemCount = $InputData.Count
        $ChunkSize = [Math]::Max(1, [Math]::Ceiling($itemCount / ($MaxThreads * 2)))
    }
    
    Write-Log "ExÃ©cution parallÃ¨le par lots (MaxThreads: $MaxThreads, ChunkSize: $ChunkSize)..." -Level "INFO"
    
    $results = @()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # CrÃ©er le pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxThreads, $sessionState, $Host)
        $pool.Open()
        
        # Diviser les donnÃ©es en lots
        $batches = @()
        $batchCount = [Math]::Ceiling($InputData.Count / $ChunkSize)
        
        for ($i = 0; $i -lt $batchCount; $i++) {
            $start = $i * $ChunkSize
            $end = [Math]::Min(($i + 1) * $ChunkSize - 1, $InputData.Count - 1)
            $batch = $InputData[$start..$end]
            $batches += ,$batch
        }
        
        Write-Log "DonnÃ©es divisÃ©es en $($batches.Count) lots" -Level "INFO"
        
        # CrÃ©er les runspaces
        $runspaces = @()
        
        foreach ($batch in $batches) {
            $powershell = [System.Management.Automation.PowerShell]::Create()
            $powershell.RunspacePool = $pool
            
            # Ajouter le script et les paramÃ¨tres
            [void]$powershell.AddScript(@"
param(`$batch, `$scriptPath)
`$results = @()
foreach (`$item in `$batch) {
    `$result = & `$scriptPath `$item
    `$results += `$result
}
return `$results
"@)
            [void]$powershell.AddArgument($batch)
            [void]$powershell.AddArgument($ScriptPath)
            
            # DÃ©marrer l'exÃ©cution asynchrone
            $runspaces += [PSCustomObject]@{
                PowerShell = $powershell
                AsyncResult = $powershell.BeginInvoke()
                BatchSize = $batch.Count
            }
        }
        
        # RÃ©cupÃ©rer les rÃ©sultats
        foreach ($runspace in $runspaces) {
            $batchResults = $runspace.PowerShell.EndInvoke($runspace.AsyncResult)
            $results += $batchResults
            $runspace.PowerShell.Dispose()
        }
        
        # Fermer le pool
        $pool.Close()
        $pool.Dispose()
    }
    catch {
        Write-Log "Erreur lors de l'exÃ©cution parallÃ¨le par lots: $_" -Level "ERROR"
    }
    
    $stopwatch.Stop()
    $executionTime = $stopwatch.Elapsed
    
    Write-Log "ExÃ©cution parallÃ¨le par lots terminÃ©e en $($executionTime.TotalSeconds) secondes" -Level "SUCCESS"
    
    return [PSCustomObject]@{
        Results = $results
        ExecutionTime = $executionTime
        ItemsProcessed = $InputData.Count
        MaxThreads = $MaxThreads
        ChunkSize = $ChunkSize
        BatchCount = $batches.Count
    }
}

# Fonction pour analyser et optimiser l'exÃ©cution parallÃ¨le
function Optimize-ParallelExecution {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [object[]]$InputData,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$ChunkSize = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$Measure
    )
    
    Write-Log "Optimisation de l'exÃ©cution parallÃ¨le..." -Level "TITLE"
    Write-Log "Script: $ScriptPath"
    Write-Log "Nombre d'Ã©lÃ©ments: $($InputData.Count)"
    
    # VÃ©rifier si le script existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Log "Le script n'existe pas: $ScriptPath" -Level "ERROR"
        return $null
    }
    
    # DÃ©terminer le nombre de threads
    if ($MaxThreads -le 0) {
        $MaxThreads = [Environment]::ProcessorCount
    }
    
    Write-Log "Nombre de processeurs: $([Environment]::ProcessorCount)"
    Write-Log "Nombre maximum de threads: $MaxThreads"
    
    # Mesurer les performances des diffÃ©rentes mÃ©thodes
    $results = @{}
    
    if ($Measure) {
        # ExÃ©cution sÃ©quentielle
        $sequentialResult = Invoke-SequentialExecution -ScriptPath $ScriptPath -InputData $InputData
        $results.Sequential = $sequentialResult
        
        # ExÃ©cution parallÃ¨le avec ForEach-Object -Parallel (PowerShell 7+)
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $foreachResult = Invoke-ParallelForeach -ScriptPath $ScriptPath -InputData $InputData -MaxThreads $MaxThreads
            $results.ForEachParallel = $foreachResult
        }
        
        # ExÃ©cution parallÃ¨le avec Runspace Pools
        $runspaceResult = Invoke-RunspacePoolExecution -ScriptPath $ScriptPath -InputData $InputData -MaxThreads $MaxThreads
        $results.RunspacePool = $runspaceResult
        
        # ExÃ©cution parallÃ¨le avec traitement par lots
        $batchResult = Invoke-BatchParallelExecution -ScriptPath $ScriptPath -InputData $InputData -MaxThreads $MaxThreads -ChunkSize $ChunkSize
        $results.BatchParallel = $batchResult
        
        # Comparer les performances
        Write-Log "Comparaison des performances:" -Level "TITLE"
        Write-Log "SÃ©quentiel: $($sequentialResult.ExecutionTime.TotalSeconds) secondes" -Level "INFO"
        
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            Write-Log "ForEach-Object -Parallel: $($foreachResult.ExecutionTime.TotalSeconds) secondes" -Level "INFO"
        }
        
        Write-Log "Runspace Pool: $($runspaceResult.ExecutionTime.TotalSeconds) secondes" -Level "INFO"
        Write-Log "Traitement par lots: $($batchResult.ExecutionTime.TotalSeconds) secondes" -Level "INFO"
        
        # DÃ©terminer la mÃ©thode la plus rapide
        $fastestMethod = "Sequential"
        $fastestTime = $sequentialResult.ExecutionTime.TotalSeconds
        
        if ($PSVersionTable.PSVersion.Major -ge 7 -and $foreachResult.ExecutionTime.TotalSeconds -lt $fastestTime) {
            $fastestMethod = "ForEachParallel"
            $fastestTime = $foreachResult.ExecutionTime.TotalSeconds
        }
        
        if ($runspaceResult.ExecutionTime.TotalSeconds -lt $fastestTime) {
            $fastestMethod = "RunspacePool"
            $fastestTime = $runspaceResult.ExecutionTime.TotalSeconds
        }
        
        if ($batchResult.ExecutionTime.TotalSeconds -lt $fastestTime) {
            $fastestMethod = "BatchParallel"
            $fastestTime = $batchResult.ExecutionTime.TotalSeconds
        }
        
        Write-Log "MÃ©thode la plus rapide: $fastestMethod ($fastestTime secondes)" -Level "SUCCESS"
        
        # Calculer les accÃ©lÃ©rations
        $speedupRunspace = $sequentialResult.ExecutionTime.TotalSeconds / $runspaceResult.ExecutionTime.TotalSeconds
        $speedupBatch = $sequentialResult.ExecutionTime.TotalSeconds / $batchResult.ExecutionTime.TotalSeconds
        
        Write-Log "AccÃ©lÃ©ration avec Runspace Pool: $([Math]::Round($speedupRunspace, 2))x" -Level "INFO"
        Write-Log "AccÃ©lÃ©ration avec traitement par lots: $([Math]::Round($speedupBatch, 2))x" -Level "INFO"
        
        # Recommandations
        Write-Log "Recommandations:" -Level "TITLE"
        
        if ($fastestMethod -eq "Sequential") {
            Write-Log "L'exÃ©cution sÃ©quentielle est la plus rapide pour ce script et ces donnÃ©es." -Level "INFO"
            Write-Log "Cela peut Ãªtre dÃ» Ã  la faible quantitÃ© de donnÃ©es ou Ã  la nature du script." -Level "INFO"
        }
        elseif ($fastestMethod -eq "ForEachParallel") {
            Write-Log "Utilisez ForEach-Object -Parallel pour ce script (nÃ©cessite PowerShell 7+):" -Level "SUCCESS"
            Write-Log "`$results = `$inputData | ForEach-Object -ThrottleLimit $MaxThreads -Parallel { & '$ScriptPath' `$_ }" -Level "INFO"
        }
        elseif ($fastestMethod -eq "RunspacePool") {
            Write-Log "Utilisez Runspace Pool pour ce script:" -Level "SUCCESS"
            Write-Log "Voir la fonction Invoke-RunspacePoolExecution pour l'implÃ©mentation" -Level "INFO"
        }
        elseif ($fastestMethod -eq "BatchParallel") {
            Write-Log "Utilisez le traitement par lots parallÃ¨le pour ce script:" -Level "SUCCESS"
            Write-Log "Taille de lot optimale: $($batchResult.ChunkSize)" -Level "INFO"
            Write-Log "Voir la fonction Invoke-BatchParallelExecution pour l'implÃ©mentation" -Level "INFO"
        }
        
        # CrÃ©er le rapport d'optimisation
        $optimizationReport = [PSCustomObject]@{
            ScriptPath = $ScriptPath
            InputDataCount = $InputData.Count
            MaxThreads = $MaxThreads
            ChunkSize = $ChunkSize
            FastestMethod = $fastestMethod
            FastestTime = $fastestTime
            SpeedupRunspace = $speedupRunspace
            SpeedupBatch = $speedupBatch
            Recommendations = [PSCustomObject]@{
                Method = $fastestMethod
                MaxThreads = $MaxThreads
                ChunkSize = if ($fastestMethod -eq "BatchParallel") { $batchResult.ChunkSize } else { $null }
            }
            Results = $results
        }
    }
    else {
        # ExÃ©cuter directement avec la mÃ©thode optimale (traitement par lots)
        $result = Invoke-BatchParallelExecution -ScriptPath $ScriptPath -InputData $InputData -MaxThreads $MaxThreads -ChunkSize $ChunkSize
        
        # CrÃ©er le rapport d'optimisation
        $optimizationReport = [PSCustomObject]@{
            ScriptPath = $ScriptPath
            InputDataCount = $InputData.Count
            MaxThreads = $MaxThreads
            ChunkSize = $result.ChunkSize
            BatchCount = $result.BatchCount
            ExecutionTime = $result.ExecutionTime.TotalSeconds
            Results = $result.Results
        }
    }
    
    return $optimizationReport
}

# Fonction principale
function Start-ParallelOptimization {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [object[]]$InputData,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$ChunkSize = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$Measure
    )
    
    # Optimiser l'exÃ©cution parallÃ¨le
    $report = Optimize-ParallelExecution -ScriptPath $ScriptPath -InputData $InputData -MaxThreads $MaxThreads -ChunkSize $ChunkSize -Measure:$Measure
    
    # Enregistrer les rÃ©sultats si demandÃ©
    if ($OutputPath -and $report) {
        try {
            # CrÃ©er le dossier de sortie s'il n'existe pas
            $outputDir = [System.IO.Path]::GetDirectoryName($OutputPath)
            
            if (-not (Test-Path -Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }
            
            # Enregistrer les rÃ©sultats
            $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
            
            Write-Log "RÃ©sultats enregistrÃ©s: $OutputPath" -Level "SUCCESS"
        }
        catch {
            Write-Log "Erreur lors de l'enregistrement des rÃ©sultats: $_" -Level "ERROR"
        }
    }
    
    return $report
}

# ExÃ©cuter la fonction principale
Start-ParallelOptimization -ScriptPath $ScriptPath -InputData $InputData -MaxThreads $MaxThreads -ChunkSize $ChunkSize -OutputPath $OutputPath -Measure:$Measure
