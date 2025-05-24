#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'optimisation du traitement parallÃ¨le.
.DESCRIPTION
    Ce script dÃ©montre comment optimiser le traitement parallÃ¨le
    en utilisant diffÃ©rentes mÃ©thodes (Runspace Pools, traitement par lots).
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-17
#>

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

# Fonction pour gÃ©nÃ©rer des donnÃ©es de test
function New-TestData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Count = 1000
    )

    Write-Log "GÃ©nÃ©ration de $Count Ã©lÃ©ments de test..." -Level "INFO"

    # Utiliser List<T> au lieu d'un tableau standard pour de meilleures performances
    $data = [System.Collections.Generic.List[PSCustomObject]]::new($Count)

    for ($i = 1; $i -le $Count; $i++) {
        $data.Add([PSCustomObject]@{
                Id        = $i
                Name      = "Item $i"
                Value     = Get-Random -Minimum 1 -Maximum 1000
                CreatedAt = (Get-Date).AddDays(-1 * (Get-Random -Minimum 1 -Maximum 365))
            })
    }

    return $data
}

# Fonction de traitement Ã  optimiser
function Invoke-Item {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Item
    )

    # Simuler un traitement qui prend du temps
    Start-Sleep -Milliseconds 50

    # Effectuer un calcul
    $result = [PSCustomObject]@{
        Id             = $Item.Id
        Name           = $Item.Name
        ProcessedValue = $Item.Value * 2
        Age            = ((Get-Date) - $Item.CreatedAt).Days
        Category       = if ($Item.Value -lt 250) { "Low" } elseif ($Item.Value -lt 750) { "Medium" } else { "High" }
    }

    return $result
}

# Fonction pour exÃ©cuter le traitement en sÃ©quentiel
function Invoke-SequentialProcessing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Data
    )

    Write-Log "ExÃ©cution du traitement sÃ©quentiel..." -Level "INFO"

    # Utiliser List<T> au lieu d'un tableau standard pour de meilleures performances
    $results = [System.Collections.Generic.List[PSCustomObject]]::new($Data.Count)
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Utiliser for au lieu de foreach pour de meilleures performances
    for ($i = 0; $i -lt $Data.Count; $i++) {
        $result = Invoke-Item -Item $Data[$i]
        $results.Add($result)
    }

    $stopwatch.Stop()
    $executionTime = $stopwatch.Elapsed

    Write-Log "Traitement sÃ©quentiel terminÃ© en $($executionTime.TotalSeconds) secondes" -Level "SUCCESS"

    return [PSCustomObject]@{
        Results        = $results
        ExecutionTime  = $executionTime
        ItemsProcessed = $Data.Count
    }
}

# Fonction pour exÃ©cuter le traitement en parallÃ¨le avec Runspace Pools
function Invoke-RunspacePoolProcessing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Data,

        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0
    )

    # DÃ©terminer le nombre de threads
    if ($MaxThreads -le 0) {
        $MaxThreads = [Environment]::ProcessorCount
    }

    Write-Log "ExÃ©cution du traitement parallÃ¨le avec Runspace Pool (MaxThreads: $MaxThreads)..." -Level "INFO"

    # Utiliser List<T> au lieu d'un tableau standard pour de meilleures performances
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        # CrÃ©er le pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxThreads, $sessionState, $Host)
        $pool.Open()

        # CrÃ©er les runspaces avec une collection optimisée
        $runspaces = [System.Collections.Generic.List[PSCustomObject]]::new($Data.Count)

        foreach ($item in $Data) {
            $powershell = [System.Management.Automation.PowerShell]::Create()
            $powershell.RunspacePool = $pool

            # Ajouter le script et les paramÃ¨tres
            [void]$powershell.AddScript({
                    param($item)

                    # Simuler un traitement qui prend du temps
                    Start-Sleep -Milliseconds 50

                    # Effectuer un calcul
                    $result = [PSCustomObject]@{
                        Id             = $item.Id
                        Name           = $item.Name
                        ProcessedValue = $item.Value * 2
                        Age            = ((Get-Date) - $item.CreatedAt).Days
                        Category       = if ($item.Value -lt 250) { "Low" } elseif ($item.Value -lt 750) { "Medium" } else { "High" }
                    }

                    return $result
                })
            [void]$powershell.AddArgument($item)

            # DÃ©marrer l'exÃ©cution asynchrone
            $runspaces.Add([PSCustomObject]@{
                    PowerShell  = $powershell
                    AsyncResult = $powershell.BeginInvoke()
                    Item        = $item
                })
        }

        # RÃ©cupÃ©rer les rÃ©sultats
        foreach ($runspace in $runspaces) {
            $result = $runspace.PowerShell.EndInvoke($runspace.AsyncResult)
            $results.Add($result)
            $runspace.PowerShell.Dispose()
        }

        # Fermer le pool
        $pool.Close()
        $pool.Dispose()
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution parallÃ¨le avec Runspace Pool: $_" -Level "ERROR"
    }

    $stopwatch.Stop()
    $executionTime = $stopwatch.Elapsed

    Write-Log "Traitement parallÃ¨le avec Runspace Pool terminÃ© en $($executionTime.TotalSeconds) secondes" -Level "SUCCESS"

    return [PSCustomObject]@{
        Results        = $results
        ExecutionTime  = $executionTime
        ItemsProcessed = $Data.Count
        MaxThreads     = $MaxThreads
    }
}

# Fonction pour exÃ©cuter le traitement en parallÃ¨le avec traitement par lots
function Invoke-BatchParallelProcessing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Data,

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
        $itemCount = $Data.Count
        $ChunkSize = [Math]::Max(1, [Math]::Ceiling($itemCount / ($MaxThreads * 2)))
    }

    Write-Log "ExÃ©cution du traitement parallÃ¨le par lots (MaxThreads: $MaxThreads, ChunkSize: $ChunkSize)..." -Level "INFO"

    # Utiliser List<T> au lieu d'un tableau standard pour de meilleures performances
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        # CrÃ©er le pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxThreads, $sessionState, $Host)
        $pool.Open()

        # Diviser les donnÃ©es en lots avec une collection optimisée
        $batches = [System.Collections.Generic.List[object[]]]::new([Math]::Ceiling($Data.Count / $ChunkSize))
        $batchCount = [Math]::Ceiling($Data.Count / $ChunkSize)

        for ($i = 0; $i -lt $batchCount; $i++) {
            $start = $i * $ChunkSize
            $end = [Math]::Min(($i + 1) * $ChunkSize - 1, $Data.Count - 1)
            $batch = $Data[$start..$end]
            $batches.Add($batch)
        }

        Write-Log "DonnÃ©es divisÃ©es en $($batches.Count) lots" -Level "INFO"

        # CrÃ©er les runspaces avec une collection optimisée
        $runspaces = [System.Collections.Generic.List[PSCustomObject]]::new($batches.Count)

        # Utiliser for au lieu de foreach pour de meilleures performances
        for ($batchIndex = 0; $batchIndex -lt $batches.Count; $batchIndex++) {
            $batch = $batches[$batchIndex]
            $powershell = [System.Management.Automation.PowerShell]::Create()
            $powershell.RunspacePool = $pool

            # Ajouter le script et les paramÃ¨tres
            [void]$powershell.AddScript({
                    param($batch)

                    # Utiliser List<T> au lieu d'un tableau standard pour de meilleures performances
                    $batchResults = [System.Collections.Generic.List[PSCustomObject]]::new($batch.Count)

                    # Utiliser for au lieu de foreach pour de meilleures performances
                    for ($i = 0; $i -lt $batch.Count; $i++) {
                        $item = $batch[$i]
                        # Simuler un traitement qui prend du temps
                        Start-Sleep -Milliseconds 50

                        # Effectuer un calcul
                        $result = [PSCustomObject]@{
                            Id             = $item.Id
                            Name           = $item.Name
                            ProcessedValue = $item.Value * 2
                            Age            = ((Get-Date) - $item.CreatedAt).Days
                            Category       = if ($item.Value -lt 250) { "Low" } elseif ($item.Value -lt 750) { "Medium" } else { "High" }
                        }

                        $batchResults.Add($result)
                    }

                    return $batchResults
                })
            [void]$powershell.AddArgument($batch)

            # DÃ©marrer l'exÃ©cution asynchrone
            $runspaces.Add([PSCustomObject]@{
                    PowerShell  = $powershell
                    AsyncResult = $powershell.BeginInvoke()
                    BatchSize   = $batch.Count
                })
        }

        # RÃ©cupÃ©rer les rÃ©sultats
        # Utiliser for au lieu de foreach pour de meilleures performances
        for ($i = 0; $i -lt $runspaces.Count; $i++) {
            $runspace = $runspaces[$i]
            $batchResults = $runspace.PowerShell.EndInvoke($runspace.AsyncResult)
            # Ajouter tous les résultats du lot à la collection principale
            for ($j = 0; $j -lt $batchResults.Count; $j++) {
                $results.Add($batchResults[$j])
            }
            $runspace.PowerShell.Dispose()
        }

        # Fermer le pool
        $pool.Close()
        $pool.Dispose()
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution parallÃ¨le par lots: $_" -Level "ERROR"
    }

    $stopwatch.Stop()
    $executionTime = $stopwatch.Elapsed

    Write-Log "Traitement parallÃ¨le par lots terminÃ© en $($executionTime.TotalSeconds) secondes" -Level "SUCCESS"

    return [PSCustomObject]@{
        Results        = $results
        ExecutionTime  = $executionTime
        ItemsProcessed = $Data.Count
        MaxThreads     = $MaxThreads
        ChunkSize      = $ChunkSize
        BatchCount     = $batches.Count
    }
}

# Fonction pour exÃ©cuter le traitement en parallÃ¨le avec ForEach-Object -Parallel (PowerShell 7+)
function Invoke-ForEachParallelProcessing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Data,

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

    Write-Log "ExÃ©cution du traitement parallÃ¨le avec ForEach-Object -Parallel (MaxThreads: $MaxThreads)..." -Level "INFO"

    # Utiliser List<T> au lieu d'un tableau standard pour de meilleures performances
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        # ForEach-Object -Parallel retourne déjà un tableau, nous le stockons dans une variable temporaire
        $tempResults = $Data | ForEach-Object -ThrottleLimit $MaxThreads -Parallel {
            # Simuler un traitement qui prend du temps
            Start-Sleep -Milliseconds 50

            # Effectuer un calcul
            $result = [PSCustomObject]@{
                Id             = $_.Id
                Name           = $_.Name
                ProcessedValue = $_.Value * 2
                Age            = ((Get-Date) - $_.CreatedAt).Days
                Category       = if ($_.Value -lt 250) { "Low" } elseif ($_.Value -lt 750) { "Medium" } else { "High" }
            }

            return $result
        }

        # Ajouter les résultats à notre collection optimisée
        # Utiliser for au lieu de foreach pour de meilleures performances
        for ($i = 0; $i -lt $tempResults.Count; $i++) {
            $results.Add($tempResults[$i])
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution parallÃ¨le avec ForEach-Object: $_" -Level "ERROR"
    }

    $stopwatch.Stop()
    $executionTime = $stopwatch.Elapsed

    Write-Log "Traitement parallÃ¨le avec ForEach-Object terminÃ© en $($executionTime.TotalSeconds) secondes" -Level "SUCCESS"

    return [PSCustomObject]@{
        Results        = $results
        ExecutionTime  = $executionTime
        ItemsProcessed = $Data.Count
        MaxThreads     = $MaxThreads
    }
}

# Fonction pour comparer les performances des diffÃ©rentes mÃ©thodes
function Compare-ProcessingMethods {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$DataCount = 100,

        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0,

        [Parameter(Mandatory = $false)]
        [int]$ChunkSize = 0
    )

    Write-Log "Comparaison des mÃ©thodes de traitement..." -Level "TITLE"
    Write-Log "Nombre d'Ã©lÃ©ments: $DataCount"

    # DÃ©terminer le nombre de threads
    if ($MaxThreads -le 0) {
        $MaxThreads = [Environment]::ProcessorCount
    }

    Write-Log "Nombre de processeurs: $([Environment]::ProcessorCount)"
    Write-Log "Nombre maximum de threads: $MaxThreads"

    # GÃ©nÃ©rer les donnÃ©es de test
    $data = New-TestData -Count $DataCount

    # ExÃ©cuter le traitement sÃ©quentiel
    $sequentialResult = Invoke-SequentialProcessing -Data $data

    # ExÃ©cuter le traitement parallÃ¨le avec Runspace Pools
    $runspaceResult = Invoke-RunspacePoolProcessing -Data $data -MaxThreads $MaxThreads

    # ExÃ©cuter le traitement parallÃ¨le avec traitement par lots
    $batchResult = Invoke-BatchParallelProcessing -Data $data -MaxThreads $MaxThreads -ChunkSize $ChunkSize

    # ExÃ©cuter le traitement parallÃ¨le avec ForEach-Object -Parallel (PowerShell 7+)
    $foreachResult = $null

    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $foreachResult = Invoke-ForEachParallelProcessing -Data $data -MaxThreads $MaxThreads
    }

    # Comparer les performances
    Write-Log "RÃ©sultats de la comparaison:" -Level "TITLE"
    Write-Log "SÃ©quentiel: $($sequentialResult.ExecutionTime.TotalSeconds) secondes" -Level "INFO"
    Write-Log "Runspace Pool: $($runspaceResult.ExecutionTime.TotalSeconds) secondes" -Level "INFO"
    Write-Log "Traitement par lots: $($batchResult.ExecutionTime.TotalSeconds) secondes" -Level "INFO"

    if ($foreachResult) {
        Write-Log "ForEach-Object -Parallel: $($foreachResult.ExecutionTime.TotalSeconds) secondes" -Level "INFO"
    }

    # Calculer les accÃ©lÃ©rations
    $speedupRunspace = $sequentialResult.ExecutionTime.TotalSeconds / $runspaceResult.ExecutionTime.TotalSeconds
    $speedupBatch = $sequentialResult.ExecutionTime.TotalSeconds / $batchResult.ExecutionTime.TotalSeconds
    $speedupForeach = if ($foreachResult) { $sequentialResult.ExecutionTime.TotalSeconds / $foreachResult.ExecutionTime.TotalSeconds } else { 0 }

    Write-Log "AccÃ©lÃ©ration avec Runspace Pool: $([Math]::Round($speedupRunspace, 2))x" -Level "SUCCESS"
    Write-Log "AccÃ©lÃ©ration avec traitement par lots: $([Math]::Round($speedupBatch, 2))x" -Level "SUCCESS"

    if ($foreachResult) {
        Write-Log "AccÃ©lÃ©ration avec ForEach-Object -Parallel: $([Math]::Round($speedupForeach, 2))x" -Level "SUCCESS"
    }

    # DÃ©terminer la mÃ©thode la plus rapide
    $fastestMethod = "Sequential"
    $fastestTime = $sequentialResult.ExecutionTime.TotalSeconds

    if ($runspaceResult.ExecutionTime.TotalSeconds -lt $fastestTime) {
        $fastestMethod = "RunspacePool"
        $fastestTime = $runspaceResult.ExecutionTime.TotalSeconds
    }

    if ($batchResult.ExecutionTime.TotalSeconds -lt $fastestTime) {
        $fastestMethod = "BatchParallel"
        $fastestTime = $batchResult.ExecutionTime.TotalSeconds
    }

    if ($foreachResult -and $foreachResult.ExecutionTime.TotalSeconds -lt $fastestTime) {
        $fastestMethod = "ForEachParallel"
        $fastestTime = $foreachResult.ExecutionTime.TotalSeconds
    }

    Write-Log "MÃ©thode la plus rapide: $fastestMethod ($fastestTime secondes)" -Level "SUCCESS"

    # Recommandations
    Write-Log "Recommandations:" -Level "TITLE"

    if ($fastestMethod -eq "Sequential") {
        Write-Log "L'exÃ©cution sÃ©quentielle est la plus rapide pour ce traitement et ces donnÃ©es." -Level "INFO"
        Write-Log "Cela peut Ãªtre dÃ» Ã  la faible quantitÃ© de donnÃ©es ou Ã  la nature du traitement." -Level "INFO"
    } elseif ($fastestMethod -eq "RunspacePool") {
        Write-Log "Utilisez Runspace Pool pour ce traitement:" -Level "SUCCESS"
        Write-Log "Nombre optimal de threads: $MaxThreads" -Level "INFO"
    } elseif ($fastestMethod -eq "BatchParallel") {
        Write-Log "Utilisez le traitement par lots parallÃ¨le pour ce traitement:" -Level "SUCCESS"
        Write-Log "Nombre optimal de threads: $MaxThreads" -Level "INFO"
        Write-Log "Taille de lot optimale: $($batchResult.ChunkSize)" -Level "INFO"
    } elseif ($fastestMethod -eq "ForEachParallel") {
        Write-Log "Utilisez ForEach-Object -Parallel pour ce traitement (nÃ©cessite PowerShell 7+):" -Level "SUCCESS"
        Write-Log "Nombre optimal de threads: $MaxThreads" -Level "INFO"
    }

    # CrÃ©er le rapport de comparaison
    $comparisonReport = [PSCustomObject]@{
        DataCount         = $DataCount
        MaxThreads        = $MaxThreads
        ChunkSize         = $ChunkSize
        Sequential        = [PSCustomObject]@{
            ExecutionTime  = $sequentialResult.ExecutionTime.TotalSeconds
            ItemsProcessed = $sequentialResult.ItemsProcessed
        }
        RunspacePool      = [PSCustomObject]@{
            ExecutionTime  = $runspaceResult.ExecutionTime.TotalSeconds
            ItemsProcessed = $runspaceResult.ItemsProcessed
            MaxThreads     = $runspaceResult.MaxThreads
            Speedup        = $speedupRunspace
        }
        BatchParallel     = [PSCustomObject]@{
            ExecutionTime  = $batchResult.ExecutionTime.TotalSeconds
            ItemsProcessed = $batchResult.ItemsProcessed
            MaxThreads     = $batchResult.MaxThreads
            ChunkSize      = $batchResult.ChunkSize
            BatchCount     = $batchResult.BatchCount
            Speedup        = $speedupBatch
        }
        ForEachParallel   = if ($foreachResult) {
            [PSCustomObject]@{
                ExecutionTime  = $foreachResult.ExecutionTime.TotalSeconds
                ItemsProcessed = $foreachResult.ItemsProcessed
                MaxThreads     = $foreachResult.MaxThreads
                Speedup        = $speedupForeach
            }
        } else { $null }
        FastestMethod     = $fastestMethod
        FastestTime       = $fastestTime
        ProcessorCount    = [Environment]::ProcessorCount
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    }

    return $comparisonReport
}

# ExÃ©cuter la comparaison avec diffÃ©rentes tailles de donnÃ©es
$smallDataReport = Compare-ProcessingMethods -DataCount 100
$mediumDataReport = Compare-ProcessingMethods -DataCount 500
$largeDataReport = Compare-ProcessingMethods -DataCount 1000

# Afficher un rÃ©sumÃ© global
Write-Log "RÃ©sumÃ© global:" -Level "TITLE"
Write-Log "Petite quantitÃ© de donnÃ©es (100 Ã©lÃ©ments):" -Level "INFO"
Write-Log "- MÃ©thode la plus rapide: $($smallDataReport.FastestMethod)" -Level "INFO"
Write-Log "- AccÃ©lÃ©ration: $([Math]::Round($smallDataReport."$($smallDataReport.FastestMethod)".Speedup, 2))x" -Level "INFO"

Write-Log "QuantitÃ© moyenne de donnÃ©es (500 Ã©lÃ©ments):" -Level "INFO"
Write-Log "- MÃ©thode la plus rapide: $($mediumDataReport.FastestMethod)" -Level "INFO"
Write-Log "- AccÃ©lÃ©ration: $([Math]::Round($mediumDataReport."$($mediumDataReport.FastestMethod)".Speedup, 2))x" -Level "INFO"

Write-Log "Grande quantitÃ© de donnÃ©es (1000 Ã©lÃ©ments):" -Level "INFO"
Write-Log "- MÃ©thode la plus rapide: $($largeDataReport.FastestMethod)" -Level "INFO"
Write-Log "- AccÃ©lÃ©ration: $([Math]::Round($largeDataReport."$($largeDataReport.FastestMethod)".Speedup, 2))x" -Level "INFO"

# Recommandation finale
Write-Log "Recommandation finale:" -Level "TITLE"

if ($largeDataReport.FastestMethod -eq "BatchParallel") {
    Write-Log "Pour des performances optimales avec de grandes quantitÃ©s de donnÃ©es, utilisez le traitement par lots parallÃ¨le:" -Level "SUCCESS"
    Write-Log "- Nombre de threads: $($largeDataReport.MaxThreads)" -Level "INFO"
    Write-Log "- Taille de lot: $($largeDataReport.BatchParallel.ChunkSize)" -Level "INFO"

    Write-Log "Exemple de code:" -Level "INFO"
    Write-Log 'Invoke-BatchParallelProcessing -Data $data -MaxThreads $([Environment]::ProcessorCount) -ChunkSize $($largeDataReport.BatchParallel.ChunkSize)' -Level "INFO"
} elseif ($largeDataReport.FastestMethod -eq "RunspacePool") {
    Write-Log "Pour des performances optimales avec de grandes quantitÃ©s de donnÃ©es, utilisez Runspace Pool:" -Level "SUCCESS"
    Write-Log "- Nombre de threads: $($largeDataReport.MaxThreads)" -Level "INFO"

    Write-Log "Exemple de code:" -Level "INFO"
    Write-Log 'Invoke-RunspacePoolProcessing -Data $data -MaxThreads $([Environment]::ProcessorCount)' -Level "INFO"
} elseif ($largeDataReport.FastestMethod -eq "ForEachParallel") {
    Write-Log "Pour des performances optimales avec de grandes quantitÃ©s de donnÃ©es, utilisez ForEach-Object -Parallel (nÃ©cessite PowerShell 7+):" -Level "SUCCESS"
    Write-Log "- Nombre de threads: $($largeDataReport.MaxThreads)" -Level "INFO"

    Write-Log "Exemple de code:" -Level "INFO"
    Write-Log '$results = $data | ForEach-Object -ThrottleLimit $([Environment]::ProcessorCount) -Parallel { Invoke-Item -Item $_ }' -Level "INFO"
} else {
    Write-Log "Pour ce type de traitement, l'exÃ©cution sÃ©quentielle est la plus efficace." -Level "INFO"
    Write-Log "Cela peut Ãªtre dÃ» Ã  la nature du traitement ou aux frais gÃ©nÃ©raux de parallÃ©lisation." -Level "INFO"

    Write-Log "Exemple de code:" -Level "INFO"
    Write-Log 'foreach ($item in $data) { Invoke-Item -Item $item }' -Level "INFO"
}

# Enregistrer les rapports
$reportsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\reports\performance"

if (-not (Test-Path -Path $reportsPath)) {
    New-Item -Path $reportsPath -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$smallDataReport | ConvertTo-Json -Depth 10 | Out-File -FilePath "$reportsPath\small_data_report_$timestamp.json" -Encoding utf8
$mediumDataReport | ConvertTo-Json -Depth 10 | Out-File -FilePath "$reportsPath\medium_data_report_$timestamp.json" -Encoding utf8
$largeDataReport | ConvertTo-Json -Depth 10 | Out-File -FilePath "$reportsPath\large_data_report_$timestamp.json" -Encoding utf8

Write-Log "Rapports enregistrÃ©s dans $reportsPath" -Level "SUCCESS"

