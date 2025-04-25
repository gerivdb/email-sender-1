#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'optimisation du traitement parallèle.
.DESCRIPTION
    Ce script démontre comment optimiser le traitement parallèle
    en utilisant différentes méthodes (Runspace Pools, traitement par lots).
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-17
#>

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

# Fonction pour générer des données de test
function New-TestData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Count = 1000
    )
    
    Write-Log "Génération de $Count éléments de test..." -Level "INFO"
    
    $data = @()
    
    for ($i = 1; $i -le $Count; $i++) {
        $data += [PSCustomObject]@{
            Id = $i
            Name = "Item $i"
            Value = Get-Random -Minimum 1 -Maximum 1000
            CreatedAt = (Get-Date).AddDays(-1 * (Get-Random -Minimum 1 -Maximum 365))
        }
    }
    
    return $data
}

# Fonction de traitement à optimiser
function Process-Item {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Item
    )
    
    # Simuler un traitement qui prend du temps
    Start-Sleep -Milliseconds 50
    
    # Effectuer un calcul
    $result = [PSCustomObject]@{
        Id = $Item.Id
        Name = $Item.Name
        ProcessedValue = $Item.Value * 2
        Age = ((Get-Date) - $Item.CreatedAt).Days
        Category = if ($Item.Value -lt 250) { "Low" } elseif ($Item.Value -lt 750) { "Medium" } else { "High" }
    }
    
    return $result
}

# Fonction pour exécuter le traitement en séquentiel
function Invoke-SequentialProcessing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Data
    )
    
    Write-Log "Exécution du traitement séquentiel..." -Level "INFO"
    
    $results = @()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    foreach ($item in $Data) {
        $result = Process-Item -Item $item
        $results += $result
    }
    
    $stopwatch.Stop()
    $executionTime = $stopwatch.Elapsed
    
    Write-Log "Traitement séquentiel terminé en $($executionTime.TotalSeconds) secondes" -Level "SUCCESS"
    
    return [PSCustomObject]@{
        Results = $results
        ExecutionTime = $executionTime
        ItemsProcessed = $Data.Count
    }
}

# Fonction pour exécuter le traitement en parallèle avec Runspace Pools
function Invoke-RunspacePoolProcessing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Data,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0
    )
    
    # Déterminer le nombre de threads
    if ($MaxThreads -le 0) {
        $MaxThreads = [Environment]::ProcessorCount
    }
    
    Write-Log "Exécution du traitement parallèle avec Runspace Pool (MaxThreads: $MaxThreads)..." -Level "INFO"
    
    $results = @()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Créer le pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxThreads, $sessionState, $Host)
        $pool.Open()
        
        # Créer les runspaces
        $runspaces = @()
        
        foreach ($item in $Data) {
            $powershell = [System.Management.Automation.PowerShell]::Create()
            $powershell.RunspacePool = $pool
            
            # Ajouter le script et les paramètres
            [void]$powershell.AddScript({
                param($item)
                
                # Simuler un traitement qui prend du temps
                Start-Sleep -Milliseconds 50
                
                # Effectuer un calcul
                $result = [PSCustomObject]@{
                    Id = $item.Id
                    Name = $item.Name
                    ProcessedValue = $item.Value * 2
                    Age = ((Get-Date) - $item.CreatedAt).Days
                    Category = if ($item.Value -lt 250) { "Low" } elseif ($item.Value -lt 750) { "Medium" } else { "High" }
                }
                
                return $result
            })
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
    
    Write-Log "Traitement parallèle avec Runspace Pool terminé en $($executionTime.TotalSeconds) secondes" -Level "SUCCESS"
    
    return [PSCustomObject]@{
        Results = $results
        ExecutionTime = $executionTime
        ItemsProcessed = $Data.Count
        MaxThreads = $MaxThreads
    }
}

# Fonction pour exécuter le traitement en parallèle avec traitement par lots
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
    
    # Déterminer le nombre de threads
    if ($MaxThreads -le 0) {
        $MaxThreads = [Environment]::ProcessorCount
    }
    
    # Déterminer la taille des lots
    if ($ChunkSize -le 0) {
        # Calculer une taille de lot optimale
        $itemCount = $Data.Count
        $ChunkSize = [Math]::Max(1, [Math]::Ceiling($itemCount / ($MaxThreads * 2)))
    }
    
    Write-Log "Exécution du traitement parallèle par lots (MaxThreads: $MaxThreads, ChunkSize: $ChunkSize)..." -Level "INFO"
    
    $results = @()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Créer le pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxThreads, $sessionState, $Host)
        $pool.Open()
        
        # Diviser les données en lots
        $batches = @()
        $batchCount = [Math]::Ceiling($Data.Count / $ChunkSize)
        
        for ($i = 0; $i -lt $batchCount; $i++) {
            $start = $i * $ChunkSize
            $end = [Math]::Min(($i + 1) * $ChunkSize - 1, $Data.Count - 1)
            $batch = $Data[$start..$end]
            $batches += ,$batch
        }
        
        Write-Log "Données divisées en $($batches.Count) lots" -Level "INFO"
        
        # Créer les runspaces
        $runspaces = @()
        
        foreach ($batch in $batches) {
            $powershell = [System.Management.Automation.PowerShell]::Create()
            $powershell.RunspacePool = $pool
            
            # Ajouter le script et les paramètres
            [void]$powershell.AddScript({
                param($batch)
                
                $batchResults = @()
                
                foreach ($item in $batch) {
                    # Simuler un traitement qui prend du temps
                    Start-Sleep -Milliseconds 50
                    
                    # Effectuer un calcul
                    $result = [PSCustomObject]@{
                        Id = $item.Id
                        Name = $item.Name
                        ProcessedValue = $item.Value * 2
                        Age = ((Get-Date) - $item.CreatedAt).Days
                        Category = if ($item.Value -lt 250) { "Low" } elseif ($item.Value -lt 750) { "Medium" } else { "High" }
                    }
                    
                    $batchResults += $result
                }
                
                return $batchResults
            })
            [void]$powershell.AddArgument($batch)
            
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
    
    Write-Log "Traitement parallèle par lots terminé en $($executionTime.TotalSeconds) secondes" -Level "SUCCESS"
    
    return [PSCustomObject]@{
        Results = $results
        ExecutionTime = $executionTime
        ItemsProcessed = $Data.Count
        MaxThreads = $MaxThreads
        ChunkSize = $ChunkSize
        BatchCount = $batches.Count
    }
}

# Fonction pour exécuter le traitement en parallèle avec ForEach-Object -Parallel (PowerShell 7+)
function Invoke-ForEachParallelProcessing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Data,
        
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
    
    Write-Log "Exécution du traitement parallèle avec ForEach-Object -Parallel (MaxThreads: $MaxThreads)..." -Level "INFO"
    
    $results = @()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $results = $Data | ForEach-Object -ThrottleLimit $MaxThreads -Parallel {
            # Simuler un traitement qui prend du temps
            Start-Sleep -Milliseconds 50
            
            # Effectuer un calcul
            $result = [PSCustomObject]@{
                Id = $_.Id
                Name = $_.Name
                ProcessedValue = $_.Value * 2
                Age = ((Get-Date) - $_.CreatedAt).Days
                Category = if ($_.Value -lt 250) { "Low" } elseif ($_.Value -lt 750) { "Medium" } else { "High" }
            }
            
            return $result
        }
    }
    catch {
        Write-Log "Erreur lors de l'exécution parallèle avec ForEach-Object: $_" -Level "ERROR"
    }
    
    $stopwatch.Stop()
    $executionTime = $stopwatch.Elapsed
    
    Write-Log "Traitement parallèle avec ForEach-Object terminé en $($executionTime.TotalSeconds) secondes" -Level "SUCCESS"
    
    return [PSCustomObject]@{
        Results = $results
        ExecutionTime = $executionTime
        ItemsProcessed = $Data.Count
        MaxThreads = $MaxThreads
    }
}

# Fonction pour comparer les performances des différentes méthodes
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
    
    Write-Log "Comparaison des méthodes de traitement..." -Level "TITLE"
    Write-Log "Nombre d'éléments: $DataCount"
    
    # Déterminer le nombre de threads
    if ($MaxThreads -le 0) {
        $MaxThreads = [Environment]::ProcessorCount
    }
    
    Write-Log "Nombre de processeurs: $([Environment]::ProcessorCount)"
    Write-Log "Nombre maximum de threads: $MaxThreads"
    
    # Générer les données de test
    $data = New-TestData -Count $DataCount
    
    # Exécuter le traitement séquentiel
    $sequentialResult = Invoke-SequentialProcessing -Data $data
    
    # Exécuter le traitement parallèle avec Runspace Pools
    $runspaceResult = Invoke-RunspacePoolProcessing -Data $data -MaxThreads $MaxThreads
    
    # Exécuter le traitement parallèle avec traitement par lots
    $batchResult = Invoke-BatchParallelProcessing -Data $data -MaxThreads $MaxThreads -ChunkSize $ChunkSize
    
    # Exécuter le traitement parallèle avec ForEach-Object -Parallel (PowerShell 7+)
    $foreachResult = $null
    
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $foreachResult = Invoke-ForEachParallelProcessing -Data $data -MaxThreads $MaxThreads
    }
    
    # Comparer les performances
    Write-Log "Résultats de la comparaison:" -Level "TITLE"
    Write-Log "Séquentiel: $($sequentialResult.ExecutionTime.TotalSeconds) secondes" -Level "INFO"
    Write-Log "Runspace Pool: $($runspaceResult.ExecutionTime.TotalSeconds) secondes" -Level "INFO"
    Write-Log "Traitement par lots: $($batchResult.ExecutionTime.TotalSeconds) secondes" -Level "INFO"
    
    if ($foreachResult) {
        Write-Log "ForEach-Object -Parallel: $($foreachResult.ExecutionTime.TotalSeconds) secondes" -Level "INFO"
    }
    
    # Calculer les accélérations
    $speedupRunspace = $sequentialResult.ExecutionTime.TotalSeconds / $runspaceResult.ExecutionTime.TotalSeconds
    $speedupBatch = $sequentialResult.ExecutionTime.TotalSeconds / $batchResult.ExecutionTime.TotalSeconds
    $speedupForeach = if ($foreachResult) { $sequentialResult.ExecutionTime.TotalSeconds / $foreachResult.ExecutionTime.TotalSeconds } else { 0 }
    
    Write-Log "Accélération avec Runspace Pool: $([Math]::Round($speedupRunspace, 2))x" -Level "SUCCESS"
    Write-Log "Accélération avec traitement par lots: $([Math]::Round($speedupBatch, 2))x" -Level "SUCCESS"
    
    if ($foreachResult) {
        Write-Log "Accélération avec ForEach-Object -Parallel: $([Math]::Round($speedupForeach, 2))x" -Level "SUCCESS"
    }
    
    # Déterminer la méthode la plus rapide
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
    
    Write-Log "Méthode la plus rapide: $fastestMethod ($fastestTime secondes)" -Level "SUCCESS"
    
    # Recommandations
    Write-Log "Recommandations:" -Level "TITLE"
    
    if ($fastestMethod -eq "Sequential") {
        Write-Log "L'exécution séquentielle est la plus rapide pour ce traitement et ces données." -Level "INFO"
        Write-Log "Cela peut être dû à la faible quantité de données ou à la nature du traitement." -Level "INFO"
    }
    elseif ($fastestMethod -eq "RunspacePool") {
        Write-Log "Utilisez Runspace Pool pour ce traitement:" -Level "SUCCESS"
        Write-Log "Nombre optimal de threads: $MaxThreads" -Level "INFO"
    }
    elseif ($fastestMethod -eq "BatchParallel") {
        Write-Log "Utilisez le traitement par lots parallèle pour ce traitement:" -Level "SUCCESS"
        Write-Log "Nombre optimal de threads: $MaxThreads" -Level "INFO"
        Write-Log "Taille de lot optimale: $($batchResult.ChunkSize)" -Level "INFO"
    }
    elseif ($fastestMethod -eq "ForEachParallel") {
        Write-Log "Utilisez ForEach-Object -Parallel pour ce traitement (nécessite PowerShell 7+):" -Level "SUCCESS"
        Write-Log "Nombre optimal de threads: $MaxThreads" -Level "INFO"
    }
    
    # Créer le rapport de comparaison
    $comparisonReport = [PSCustomObject]@{
        DataCount = $DataCount
        MaxThreads = $MaxThreads
        ChunkSize = $ChunkSize
        Sequential = [PSCustomObject]@{
            ExecutionTime = $sequentialResult.ExecutionTime.TotalSeconds
            ItemsProcessed = $sequentialResult.ItemsProcessed
        }
        RunspacePool = [PSCustomObject]@{
            ExecutionTime = $runspaceResult.ExecutionTime.TotalSeconds
            ItemsProcessed = $runspaceResult.ItemsProcessed
            MaxThreads = $runspaceResult.MaxThreads
            Speedup = $speedupRunspace
        }
        BatchParallel = [PSCustomObject]@{
            ExecutionTime = $batchResult.ExecutionTime.TotalSeconds
            ItemsProcessed = $batchResult.ItemsProcessed
            MaxThreads = $batchResult.MaxThreads
            ChunkSize = $batchResult.ChunkSize
            BatchCount = $batchResult.BatchCount
            Speedup = $speedupBatch
        }
        ForEachParallel = if ($foreachResult) {
            [PSCustomObject]@{
                ExecutionTime = $foreachResult.ExecutionTime.TotalSeconds
                ItemsProcessed = $foreachResult.ItemsProcessed
                MaxThreads = $foreachResult.MaxThreads
                Speedup = $speedupForeach
            }
        } else { $null }
        FastestMethod = $fastestMethod
        FastestTime = $fastestTime
        ProcessorCount = [Environment]::ProcessorCount
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    }
    
    return $comparisonReport
}

# Exécuter la comparaison avec différentes tailles de données
$smallDataReport = Compare-ProcessingMethods -DataCount 100
$mediumDataReport = Compare-ProcessingMethods -DataCount 500
$largeDataReport = Compare-ProcessingMethods -DataCount 1000

# Afficher un résumé global
Write-Log "Résumé global:" -Level "TITLE"
Write-Log "Petite quantité de données (100 éléments):" -Level "INFO"
Write-Log "- Méthode la plus rapide: $($smallDataReport.FastestMethod)" -Level "INFO"
Write-Log "- Accélération: $([Math]::Round($smallDataReport."$($smallDataReport.FastestMethod)".Speedup, 2))x" -Level "INFO"

Write-Log "Quantité moyenne de données (500 éléments):" -Level "INFO"
Write-Log "- Méthode la plus rapide: $($mediumDataReport.FastestMethod)" -Level "INFO"
Write-Log "- Accélération: $([Math]::Round($mediumDataReport."$($mediumDataReport.FastestMethod)".Speedup, 2))x" -Level "INFO"

Write-Log "Grande quantité de données (1000 éléments):" -Level "INFO"
Write-Log "- Méthode la plus rapide: $($largeDataReport.FastestMethod)" -Level "INFO"
Write-Log "- Accélération: $([Math]::Round($largeDataReport."$($largeDataReport.FastestMethod)".Speedup, 2))x" -Level "INFO"

# Recommandation finale
Write-Log "Recommandation finale:" -Level "TITLE"

if ($largeDataReport.FastestMethod -eq "BatchParallel") {
    Write-Log "Pour des performances optimales avec de grandes quantités de données, utilisez le traitement par lots parallèle:" -Level "SUCCESS"
    Write-Log "- Nombre de threads: $($largeDataReport.MaxThreads)" -Level "INFO"
    Write-Log "- Taille de lot: $($largeDataReport.BatchParallel.ChunkSize)" -Level "INFO"
    
    Write-Log "Exemple de code:" -Level "INFO"
    Write-Log 'Invoke-BatchParallelProcessing -Data $data -MaxThreads $([Environment]::ProcessorCount) -ChunkSize $($largeDataReport.BatchParallel.ChunkSize)' -Level "INFO"
}
elseif ($largeDataReport.FastestMethod -eq "RunspacePool") {
    Write-Log "Pour des performances optimales avec de grandes quantités de données, utilisez Runspace Pool:" -Level "SUCCESS"
    Write-Log "- Nombre de threads: $($largeDataReport.MaxThreads)" -Level "INFO"
    
    Write-Log "Exemple de code:" -Level "INFO"
    Write-Log 'Invoke-RunspacePoolProcessing -Data $data -MaxThreads $([Environment]::ProcessorCount)' -Level "INFO"
}
elseif ($largeDataReport.FastestMethod -eq "ForEachParallel") {
    Write-Log "Pour des performances optimales avec de grandes quantités de données, utilisez ForEach-Object -Parallel (nécessite PowerShell 7+):" -Level "SUCCESS"
    Write-Log "- Nombre de threads: $($largeDataReport.MaxThreads)" -Level "INFO"
    
    Write-Log "Exemple de code:" -Level "INFO"
    Write-Log '$results = $data | ForEach-Object -ThrottleLimit $([Environment]::ProcessorCount) -Parallel { Process-Item -Item $_ }' -Level "INFO"
}
else {
    Write-Log "Pour ce type de traitement, l'exécution séquentielle est la plus efficace." -Level "INFO"
    Write-Log "Cela peut être dû à la nature du traitement ou aux frais généraux de parallélisation." -Level "INFO"
    
    Write-Log "Exemple de code:" -Level "INFO"
    Write-Log 'foreach ($item in $data) { Process-Item -Item $item }' -Level "INFO"
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

Write-Log "Rapports enregistrés dans $reportsPath" -Level "SUCCESS"
