#Requires -Version 5.1
<#
.SYNOPSIS
    Optimise l'exécution parallèle des scripts PowerShell.
.DESCRIPTION
    Ce script analyse et optimise l'exécution parallèle des scripts PowerShell
    en utilisant les Runspace Pools pour maximiser les performances.
.PARAMETER ScriptPath
    Chemin du script à optimiser.
.PARAMETER InputData
    Données d'entrée pour le script (tableau d'objets).
.PARAMETER MaxThreads
    Nombre maximum de threads à utiliser (0 = nombre de processeurs).
.PARAMETER ChunkSize
    Taille des lots pour le traitement par lots (0 = automatique).
.PARAMETER OutputPath
    Chemin du fichier de sortie pour les résultats.
.PARAMETER Measure
    Mesure les performances avant et après l'optimisation.
.EXAMPLE
    .\Optimize-ParallelExecution.ps1 -ScriptPath ".\scripts\process-data.ps1" -InputData $data -MaxThreads 8 -OutputPath ".\output\results.json"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-17
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

# Fonction pour écrire dans le journal
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

# Fonction pour exécuter un script en séquentiel
function Invoke-SequentialExecution {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [object[]]$InputData
    )
    
    Write-Log "Exécution séquentielle..." -Level "INFO"
    
    $results = @()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    foreach ($item in $InputData) {
        try {
            $result = & $ScriptPath $item
            $results += $result
        }
        catch {
            Write-Log "Erreur lors de l'exécution séquentielle: $_" -Level "ERROR"
        }
    }
    
    $stopwatch.Stop()
    $executionTime = $stopwatch.Elapsed
    
    Write-Log "Exécution séquentielle terminée en $($executionTime.TotalSeconds) secondes" -Level "SUCCESS"
    
    return [PSCustomObject]@{
        Results = $results
        ExecutionTime = $executionTime
        ItemsProcessed = $InputData.Count
    }
}

# Fonction pour exécuter un script en parallèle avec ForEach-Object -Parallel (PowerShell 7+)
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
    
    # Vérifier si PowerShell 7+ est disponible
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Log "ForEach-Object -Parallel nécessite PowerShell 7+. Version actuelle: $($PSVersionTable.PSVersion)" -Level "ERROR"
        return $null
    }
    
    # Déterminer le nombre de threads
    if ($MaxThreads -le 0) {
        $MaxThreads = [Environment]::ProcessorCount
    }
    
    Write-Log "Exécution parallèle avec ForEach-Object -Parallel (MaxThreads: $MaxThreads)..." -Level "INFO"
    
    $results = @()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $results = $InputData | ForEach-Object -ThrottleLimit $MaxThreads -Parallel {
            & $using:ScriptPath $_
        }
    }
    catch {
        Write-Log "Erreur lors de l'exécution parallèle avec ForEach-Object: $_" -Level "ERROR"
    }
    
    $stopwatch.Stop()
    $executionTime = $stopwatch.Elapsed
    
    Write-Log "Exécution parallèle avec ForEach-Object terminée en $($executionTime.TotalSeconds) secondes" -Level "SUCCESS"
    
    return [PSCustomObject]@{
        Results = $results
        ExecutionTime = $executionTime
        ItemsProcessed = $InputData.Count
        MaxThreads = $MaxThreads
    }
}

# Fonction pour exécuter un script en parallèle avec Runspace Pools
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
    
    # Déterminer le nombre de threads
    if ($MaxThreads -le 0) {
        $MaxThreads = [Environment]::ProcessorCount
    }
    
    Write-Log "Exécution parallèle avec Runspace Pool (MaxThreads: $MaxThreads)..." -Level "INFO"
    
    $results = @()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Créer le pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxThreads, $sessionState, $Host)
        $pool.Open()
        
        # Créer les runspaces
        $runspaces = @()
        
        foreach ($item in $InputData) {
            $powershell = [System.Management.Automation.PowerShell]::Create()
            $powershell.RunspacePool = $pool
            
            # Ajouter le script et les paramètres
            [void]$powershell.AddScript("param(`$item) & '$ScriptPath' `$item")
            [void]$powershell.AddArgument($item)
            
            # Démarrer l'exécution asynchrone
            $runspaces += [PSCustomObject]@{
                PowerShell = $powershell
                AsyncResult = $powershell.BeginInvoke()
                Item = $item
            }
        }
        
        # Récupérer les résultats
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
        Write-Log "Erreur lors de l'exécution parallèle avec Runspace Pool: $_" -Level "ERROR"
    }
    
    $stopwatch.Stop()
    $executionTime = $stopwatch.Elapsed
    
    Write-Log "Exécution parallèle avec Runspace Pool terminée en $($executionTime.TotalSeconds) secondes" -Level "SUCCESS"
    
    return [PSCustomObject]@{
        Results = $results
        ExecutionTime = $executionTime
        ItemsProcessed = $InputData.Count
        MaxThreads = $MaxThreads
    }
}

# Fonction pour exécuter un script en parallèle avec traitement par lots
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
    
    # Déterminer le nombre de threads
    if ($MaxThreads -le 0) {
        $MaxThreads = [Environment]::ProcessorCount
    }
    
    # Déterminer la taille des lots
    if ($ChunkSize -le 0) {
        # Calculer une taille de lot optimale
        $itemCount = $InputData.Count
        $ChunkSize = [Math]::Max(1, [Math]::Ceiling($itemCount / ($MaxThreads * 2)))
    }
    
    Write-Log "Exécution parallèle par lots (MaxThreads: $MaxThreads, ChunkSize: $ChunkSize)..." -Level "INFO"
    
    $results = @()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Créer le pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxThreads, $sessionState, $Host)
        $pool.Open()
        
        # Diviser les données en lots
        $batches = @()
        $batchCount = [Math]::Ceiling($InputData.Count / $ChunkSize)
        
        for ($i = 0; $i -lt $batchCount; $i++) {
            $start = $i * $ChunkSize
            $end = [Math]::Min(($i + 1) * $ChunkSize - 1, $InputData.Count - 1)
            $batch = $InputData[$start..$end]
            $batches += ,$batch
        }
        
        Write-Log "Données divisées en $($batches.Count) lots" -Level "INFO"
        
        # Créer les runspaces
        $runspaces = @()
        
        foreach ($batch in $batches) {
            $powershell = [System.Management.Automation.PowerShell]::Create()
            $powershell.RunspacePool = $pool
            
            # Ajouter le script et les paramètres
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
            
            # Démarrer l'exécution asynchrone
            $runspaces += [PSCustomObject]@{
                PowerShell = $powershell
                AsyncResult = $powershell.BeginInvoke()
                BatchSize = $batch.Count
            }
        }
        
        # Récupérer les résultats
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
        Write-Log "Erreur lors de l'exécution parallèle par lots: $_" -Level "ERROR"
    }
    
    $stopwatch.Stop()
    $executionTime = $stopwatch.Elapsed
    
    Write-Log "Exécution parallèle par lots terminée en $($executionTime.TotalSeconds) secondes" -Level "SUCCESS"
    
    return [PSCustomObject]@{
        Results = $results
        ExecutionTime = $executionTime
        ItemsProcessed = $InputData.Count
        MaxThreads = $MaxThreads
        ChunkSize = $ChunkSize
        BatchCount = $batches.Count
    }
}

# Fonction pour analyser et optimiser l'exécution parallèle
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
    
    Write-Log "Optimisation de l'exécution parallèle..." -Level "TITLE"
    Write-Log "Script: $ScriptPath"
    Write-Log "Nombre d'éléments: $($InputData.Count)"
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Log "Le script n'existe pas: $ScriptPath" -Level "ERROR"
        return $null
    }
    
    # Déterminer le nombre de threads
    if ($MaxThreads -le 0) {
        $MaxThreads = [Environment]::ProcessorCount
    }
    
    Write-Log "Nombre de processeurs: $([Environment]::ProcessorCount)"
    Write-Log "Nombre maximum de threads: $MaxThreads"
    
    # Mesurer les performances des différentes méthodes
    $results = @{}
    
    if ($Measure) {
        # Exécution séquentielle
        $sequentialResult = Invoke-SequentialExecution -ScriptPath $ScriptPath -InputData $InputData
        $results.Sequential = $sequentialResult
        
        # Exécution parallèle avec ForEach-Object -Parallel (PowerShell 7+)
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $foreachResult = Invoke-ParallelForeach -ScriptPath $ScriptPath -InputData $InputData -MaxThreads $MaxThreads
            $results.ForEachParallel = $foreachResult
        }
        
        # Exécution parallèle avec Runspace Pools
        $runspaceResult = Invoke-RunspacePoolExecution -ScriptPath $ScriptPath -InputData $InputData -MaxThreads $MaxThreads
        $results.RunspacePool = $runspaceResult
        
        # Exécution parallèle avec traitement par lots
        $batchResult = Invoke-BatchParallelExecution -ScriptPath $ScriptPath -InputData $InputData -MaxThreads $MaxThreads -ChunkSize $ChunkSize
        $results.BatchParallel = $batchResult
        
        # Comparer les performances
        Write-Log "Comparaison des performances:" -Level "TITLE"
        Write-Log "Séquentiel: $($sequentialResult.ExecutionTime.TotalSeconds) secondes" -Level "INFO"
        
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            Write-Log "ForEach-Object -Parallel: $($foreachResult.ExecutionTime.TotalSeconds) secondes" -Level "INFO"
        }
        
        Write-Log "Runspace Pool: $($runspaceResult.ExecutionTime.TotalSeconds) secondes" -Level "INFO"
        Write-Log "Traitement par lots: $($batchResult.ExecutionTime.TotalSeconds) secondes" -Level "INFO"
        
        # Déterminer la méthode la plus rapide
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
        
        Write-Log "Méthode la plus rapide: $fastestMethod ($fastestTime secondes)" -Level "SUCCESS"
        
        # Calculer les accélérations
        $speedupRunspace = $sequentialResult.ExecutionTime.TotalSeconds / $runspaceResult.ExecutionTime.TotalSeconds
        $speedupBatch = $sequentialResult.ExecutionTime.TotalSeconds / $batchResult.ExecutionTime.TotalSeconds
        
        Write-Log "Accélération avec Runspace Pool: $([Math]::Round($speedupRunspace, 2))x" -Level "INFO"
        Write-Log "Accélération avec traitement par lots: $([Math]::Round($speedupBatch, 2))x" -Level "INFO"
        
        # Recommandations
        Write-Log "Recommandations:" -Level "TITLE"
        
        if ($fastestMethod -eq "Sequential") {
            Write-Log "L'exécution séquentielle est la plus rapide pour ce script et ces données." -Level "INFO"
            Write-Log "Cela peut être dû à la faible quantité de données ou à la nature du script." -Level "INFO"
        }
        elseif ($fastestMethod -eq "ForEachParallel") {
            Write-Log "Utilisez ForEach-Object -Parallel pour ce script (nécessite PowerShell 7+):" -Level "SUCCESS"
            Write-Log "`$results = `$inputData | ForEach-Object -ThrottleLimit $MaxThreads -Parallel { & '$ScriptPath' `$_ }" -Level "INFO"
        }
        elseif ($fastestMethod -eq "RunspacePool") {
            Write-Log "Utilisez Runspace Pool pour ce script:" -Level "SUCCESS"
            Write-Log "Voir la fonction Invoke-RunspacePoolExecution pour l'implémentation" -Level "INFO"
        }
        elseif ($fastestMethod -eq "BatchParallel") {
            Write-Log "Utilisez le traitement par lots parallèle pour ce script:" -Level "SUCCESS"
            Write-Log "Taille de lot optimale: $($batchResult.ChunkSize)" -Level "INFO"
            Write-Log "Voir la fonction Invoke-BatchParallelExecution pour l'implémentation" -Level "INFO"
        }
        
        # Créer le rapport d'optimisation
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
        # Exécuter directement avec la méthode optimale (traitement par lots)
        $result = Invoke-BatchParallelExecution -ScriptPath $ScriptPath -InputData $InputData -MaxThreads $MaxThreads -ChunkSize $ChunkSize
        
        # Créer le rapport d'optimisation
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
    
    # Optimiser l'exécution parallèle
    $report = Optimize-ParallelExecution -ScriptPath $ScriptPath -InputData $InputData -MaxThreads $MaxThreads -ChunkSize $ChunkSize -Measure:$Measure
    
    # Enregistrer les résultats si demandé
    if ($OutputPath -and $report) {
        try {
            # Créer le dossier de sortie s'il n'existe pas
            $outputDir = [System.IO.Path]::GetDirectoryName($OutputPath)
            
            if (-not (Test-Path -Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            }
            
            # Enregistrer les résultats
            $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
            
            Write-Log "Résultats enregistrés: $OutputPath" -Level "SUCCESS"
        }
        catch {
            Write-Log "Erreur lors de l'enregistrement des résultats: $_" -Level "ERROR"
        }
    }
    
    return $report
}

# Exécuter la fonction principale
Start-ParallelOptimization -ScriptPath $ScriptPath -InputData $InputData -MaxThreads $MaxThreads -ChunkSize $ChunkSize -OutputPath $OutputPath -Measure:$Measure
