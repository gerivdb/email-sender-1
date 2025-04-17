#Requires -Version 5.1
<#
.SYNOPSIS
    Test de charge pour les modules du projet.
.DESCRIPTION
    Ce script exécute des tests de charge pour les différents modules du projet.
.PARAMETER ModulesToTest
    Liste des modules à tester.
.PARAMETER Duration
    Durée du test de charge en secondes.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour les résultats.
.EXAMPLE
    .\LoadTest.ps1 -ModulesToTest @("CycleDetector", "InputSegmentation", "PredictiveCache", "ParallelProcessing") -Duration 60
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-19
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string[]]$ModulesToTest = @("CycleDetector", "InputSegmentation", "PredictiveCache", "ParallelProcessing"),
    
    [Parameter(Mandatory = $false)]
    [int]$Duration = 30,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\performance\load_test_results.json"
)

# Fonction pour exécuter un test de charge
function Start-LoadTest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $true)]
        [int]$Duration,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 4
    )
    
    $results = @()
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($Duration)
    $iteration = 0
    $successCount = 0
    $failureCount = 0
    
    # Créer un runspace pool
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads, $sessionState, $Host)
    $runspacePool.Open()
    
    $runspaces = @()
    
    try {
        while ((Get-Date) -lt $endTime) {
            $iteration++
            
            # Créer un nouveau runspace
            $powershell = [powershell]::Create().AddScript($ScriptBlock)
            $powershell.RunspacePool = $runspacePool
            
            # Démarrer l'exécution de manière asynchrone
            $handle = $powershell.BeginInvoke()
            
            $runspaces += [PSCustomObject]@{
                PowerShell = $powershell
                Handle = $handle
                StartTime = Get-Date
            }
            
            # Vérifier les runspaces terminés
            $completedRunspaces = @($runspaces | Where-Object { $_.Handle.IsCompleted })
            
            foreach ($runspace in $completedRunspaces) {
                try {
                    $result = $runspace.PowerShell.EndInvoke($runspace.Handle)
                    $endTime = Get-Date
                    $executionTime = ($endTime - $runspace.StartTime).TotalMilliseconds
                    
                    $results += [PSCustomObject]@{
                        Iteration = $iteration
                        StartTime = $runspace.StartTime
                        EndTime = $endTime
                        ExecutionTimeMs = $executionTime
                        Success = $true
                        Result = $result
                    }
                    
                    $successCount++
                }
                catch {
                    $results += [PSCustomObject]@{
                        Iteration = $iteration
                        StartTime = $runspace.StartTime
                        EndTime = Get-Date
                        ExecutionTimeMs = ((Get-Date) - $runspace.StartTime).TotalMilliseconds
                        Success = $false
                        Error = $_.Exception.Message
                    }
                    
                    $failureCount++
                }
                finally {
                    $runspace.PowerShell.Dispose()
                }
            }
            
            # Mettre à jour la liste des runspaces
            $runspaces = @($runspaces | Where-Object { -not $_.Handle.IsCompleted })
            
            # Petite pause pour éviter de surcharger le CPU
            Start-Sleep -Milliseconds 100
        }
        
        # Attendre que tous les runspaces se terminent
        while ($runspaces.Count -gt 0) {
            $completedRunspaces = @($runspaces | Where-Object { $_.Handle.IsCompleted })
            
            foreach ($runspace in $completedRunspaces) {
                try {
                    $result = $runspace.PowerShell.EndInvoke($runspace.Handle)
                    $endTime = Get-Date
                    $executionTime = ($endTime - $runspace.StartTime).TotalMilliseconds
                    
                    $results += [PSCustomObject]@{
                        Iteration = $iteration
                        StartTime = $runspace.StartTime
                        EndTime = $endTime
                        ExecutionTimeMs = $executionTime
                        Success = $true
                        Result = $result
                    }
                    
                    $successCount++
                }
                catch {
                    $results += [PSCustomObject]@{
                        Iteration = $iteration
                        StartTime = $runspace.StartTime
                        EndTime = Get-Date
                        ExecutionTimeMs = ((Get-Date) - $runspace.StartTime).TotalMilliseconds
                        Success = $false
                        Error = $_.Exception.Message
                    }
                    
                    $failureCount++
                }
                finally {
                    $runspace.PowerShell.Dispose()
                }
            }
            
            # Mettre à jour la liste des runspaces
            $runspaces = @($runspaces | Where-Object { -not $_.Handle.IsCompleted })
            
            # Petite pause pour éviter de surcharger le CPU
            Start-Sleep -Milliseconds 100
        }
    }
    finally {
        # Fermer le runspace pool
        $runspacePool.Close()
        $runspacePool.Dispose()
    }
    
    # Calculer les statistiques
    $totalExecutions = $successCount + $failureCount
    $successRate = if ($totalExecutions -gt 0) { ($successCount / $totalExecutions) * 100 } else { 0 }
    
    $executionTimes = $results | Where-Object { $_.Success } | Select-Object -ExpandProperty ExecutionTimeMs
    $avgExecutionTime = if ($executionTimes.Count -gt 0) { ($executionTimes | Measure-Object -Average).Average } else { 0 }
    $minExecutionTime = if ($executionTimes.Count -gt 0) { ($executionTimes | Measure-Object -Minimum).Minimum } else { 0 }
    $maxExecutionTime = if ($executionTimes.Count -gt 0) { ($executionTimes | Measure-Object -Maximum).Maximum } else { 0 }
    
    $totalDuration = ((Get-Date) - $startTime).TotalSeconds
    $executionsPerSecond = if ($totalDuration -gt 0) { $totalExecutions / $totalDuration } else { 0 }
    
    return [PSCustomObject]@{
        Duration = $totalDuration
        TotalExecutions = $totalExecutions
        SuccessCount = $successCount
        FailureCount = $failureCount
        SuccessRate = $successRate
        AvgExecutionTimeMs = $avgExecutionTime
        MinExecutionTimeMs = $minExecutionTime
        MaxExecutionTimeMs = $maxExecutionTime
        ExecutionsPerSecond = $executionsPerSecond
        Results = $results
    }
}

# Créer le dossier de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Résultats globaux
$loadTestResults = @{}

# Tests pour CycleDetector
if ($ModulesToTest -contains "CycleDetector") {
    Write-Host "Exécution du test de charge pour CycleDetector..." -ForegroundColor Cyan
    
    # Importer le module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\CycleDetector.psm1"
    Import-Module $modulePath -Force
    
    # Test de charge pour la détection de cycles
    $cycleDetectorTest = Start-LoadTest -ScriptBlock {
        # Créer un graphe aléatoire
        $graphSize = Get-Random -Minimum 10 -Maximum 100
        $graph = @{}
        
        for ($i = 0; $i -lt $graphSize; $i++) {
            $connections = @()
            $connectionCount = Get-Random -Minimum 1 -Maximum 5
            
            for ($j = 0; $j -lt $connectionCount; $j++) {
                $connections += "Node$((Get-Random -Minimum 0 -Maximum $graphSize))"
            }
            
            $graph["Node$i"] = $connections
        }
        
        # Détecter les cycles
        Detect-Cycle -Graph $graph
    } -Duration $Duration
    
    $loadTestResults.CycleDetector = $cycleDetectorTest
}

# Tests pour InputSegmentation
if ($ModulesToTest -contains "InputSegmentation") {
    Write-Host "Exécution du test de charge pour InputSegmentation..." -ForegroundColor Cyan
    
    # Importer le module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\InputSegmentation.psm1"
    Import-Module $modulePath -Force
    
    # Initialiser le module
    Initialize-InputSegmentation -MaxInputSizeKB 10 -DefaultChunkSizeKB 5
    
    # Test de charge pour la segmentation de texte
    $inputSegmentationTest = Start-LoadTest -ScriptBlock {
        # Créer un texte aléatoire
        $textSize = Get-Random -Minimum 5 -Maximum 50
        $text = "A" * ($textSize * 1KB)
        
        # Segmenter le texte
        Split-TextInput -Text $text -ChunkSizeKB 5
    } -Duration $Duration
    
    $loadTestResults.InputSegmentation = $inputSegmentationTest
}

# Tests pour PredictiveCache
if ($ModulesToTest -contains "PredictiveCache") {
    Write-Host "Exécution du test de charge pour PredictiveCache..." -ForegroundColor Cyan
    
    # Importer le module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\PredictiveCache.psm1"
    Import-Module $modulePath -Force
    
    # Créer des dossiers temporaires
    $tempCachePath = Join-Path -Path $env:TEMP -ChildPath "cache_load_test"
    $tempModelPath = Join-Path -Path $env:TEMP -ChildPath "model_load_test"
    
    if (-not (Test-Path -Path $tempCachePath)) {
        New-Item -Path $tempCachePath -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-Path -Path $tempModelPath)) {
        New-Item -Path $tempModelPath -ItemType Directory -Force | Out-Null
    }
    
    # Initialiser le module
    Initialize-PredictiveCache -Enabled $true -CachePath $tempCachePath -ModelPath $tempModelPath -MaxCacheSize 10MB -DefaultTTL 3600
    
    # Test de charge pour le cache prédictif
    $predictiveCacheTest = Start-LoadTest -ScriptBlock {
        # Opération aléatoire
        $operation = Get-Random -InputObject @("Get", "Set", "Remove")
        $key = "key-$(Get-Random -Minimum 1 -Maximum 1000)"
        
        switch ($operation) {
            "Get" {
                Get-PredictiveCache -Key $key
            }
            "Set" {
                $value = "value-$(Get-Random -Minimum 1 -Maximum 1000)"
                Set-PredictiveCache -Key $key -Value $value
            }
            "Remove" {
                Remove-PredictiveCache -Key $key
            }
        }
    } -Duration $Duration
    
    $loadTestResults.PredictiveCache = $predictiveCacheTest
}

# Tests pour ParallelProcessing
if ($ModulesToTest -contains "ParallelProcessing") {
    Write-Host "Exécution du test de charge pour ParallelProcessing..." -ForegroundColor Cyan
    
    # Importer le script
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\scripts\performance\Optimize-ParallelExecution.ps1"
    . $scriptPath
    
    # Test de charge pour le traitement parallèle
    $parallelProcessingTest = Start-LoadTest -ScriptBlock {
        # Créer des données aléatoires
        $dataSize = Get-Random -Minimum 10 -Maximum 100
        $data = 1..$dataSize
        
        # Fonction de test
        function Test-Function {
            param($item)
            Start-Sleep -Milliseconds 1
            return $item * 2
        }
        
        # Exécuter le traitement parallèle
        Invoke-RunspacePoolProcessing -Data $data -ScriptBlock ${function:Test-Function} -MaxThreads 4
    } -Duration $Duration
    
    $loadTestResults.ParallelProcessing = $parallelProcessingTest
}

# Enregistrer les résultats
$loadTestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Tests de charge terminés. Résultats enregistrés dans $OutputPath" -ForegroundColor Green

# Afficher un résumé
Write-Host "`nRésumé des tests de charge:" -ForegroundColor Cyan

foreach ($module in $loadTestResults.Keys) {
    Write-Host "`n$module:" -ForegroundColor Yellow
    
    $testResult = $loadTestResults.$module
    
    Write-Host "  Durée: $($testResult.Duration) secondes" -ForegroundColor White
    Write-Host "  Exécutions totales: $($testResult.TotalExecutions)" -ForegroundColor White
    Write-Host "  Taux de succès: $([Math]::Round($testResult.SuccessRate, 2))%" -ForegroundColor White
    Write-Host "  Temps d'exécution moyen: $([Math]::Round($testResult.AvgExecutionTimeMs, 2)) ms" -ForegroundColor White
    Write-Host "  Exécutions par seconde: $([Math]::Round($testResult.ExecutionsPerSecond, 2))" -ForegroundColor White
}
