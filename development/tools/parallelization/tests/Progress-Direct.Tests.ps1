# Tests de performance pour la gestion optimisée de la progression (test direct)
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Fonction pour mesurer les performances avec différentes configurations de progression
    function Measure-ProgressPerformance {
        param(
            [Parameter(Mandatory = $true)]
            [string]$TestName,

            [Parameter(Mandatory = $true)]
            [int]$ItemCount,

            [Parameter(Mandatory = $false)]
            [switch]$NoProgress,

            [Parameter(Mandatory = $false)]
            [switch]$OptimizedProgress,

            [Parameter(Mandatory = $false)]
            [int]$Iterations = 3
        )

        $totalTime = 0
        $totalCPU = 0

        for ($iter = 1; $iter -le $Iterations; $iter++) {
            # Créer des éléments de test
            $items = 1..$ItemCount

            # Mesurer les performances
            $process = Get-Process -Id $PID
            $startCPU = $process.TotalProcessorTime

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Traiter les éléments un par un
            $results = @()

            # Préparer la barre de progression
            if (-not $NoProgress) {
                $progressParams = @{
                    Activity        = "Test de progression: $TestName"
                    Status          = "Préparation..."
                    PercentComplete = 0
                }
                Write-Progress @progressParams
            }

            # Variables pour la progression optimisée
            $lastProgressUpdate = 0
            $progressCounter = 0

            # Traiter chaque élément
            for ($i = 0; $i -lt $items.Count; $i++) {
                $item = $items[$i]

                # Simuler un traitement qui prend du temps
                Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 30)
                $result = $item * 2
                $results += $result

                # Mettre à jour la barre de progression
                if (-not $NoProgress) {
                    $percentComplete = [Math]::Min(100, [Math]::Floor(($i + 1) / $items.Count * 100))

                    if ($OptimizedProgress) {
                        # Optimisation : mettre à jour seulement tous les 5 éléments ou à la fin
                        $progressCounter++
                        $updateProgress = $false

                        # Mettre à jour si des éléments ont été traités ou toutes les 5 itérations
                        if (($i + 1) -gt $lastProgressUpdate -or $progressCounter % 5 -eq 0) {
                            $updateProgress = $true
                            $lastProgressUpdate = $i + 1
                        }

                        if ($updateProgress) {
                            $progressParams = @{
                                Activity        = "Test de progression: $TestName"
                                Status          = "Traitement de l'élément $($i + 1) sur $($items.Count)"
                                PercentComplete = $percentComplete
                            }
                            Write-Progress @progressParams
                        }
                    } else {
                        # Mise à jour standard à chaque itération
                        $progressParams = @{
                            Activity        = "Test de progression: $TestName"
                            Status          = "Traitement de l'élément $($i + 1) sur $($items.Count)"
                            PercentComplete = $percentComplete
                        }
                        Write-Progress @progressParams
                    }
                }
            }

            # Terminer la barre de progression
            if (-not $NoProgress) {
                Write-Progress -Activity "Test de progression: $TestName" -Completed
            }

            $stopwatch.Stop()
            $elapsedMs = $stopwatch.ElapsedMilliseconds

            # Mesurer l'utilisation CPU
            $process = Get-Process -Id $PID
            $endCPU = $process.TotalProcessorTime
            $cpuTime = ($endCPU - $startCPU).TotalMilliseconds

            # Ajouter aux totaux
            $totalTime += $elapsedMs
            $totalCPU += $cpuTime
        }

        # Calculer les moyennes
        $avgTime = $totalTime / $Iterations
        $avgCPU = $totalCPU / $Iterations

        return [PSCustomObject]@{
            TestName          = $TestName
            ItemCount         = $ItemCount
            NoProgress        = $NoProgress
            OptimizedProgress = $OptimizedProgress
            AvgTime           = $avgTime
            AvgCPU            = $avgCPU
            TimePerItem       = $avgTime / $ItemCount
            CPUPerItem        = $avgCPU / $ItemCount
        }
    }
}

Describe "Performance de la gestion de la progression (test direct)" {
    Context "Comparaison des différentes méthodes de progression" {
        BeforeAll {
            $noProgressResult = Measure-ProgressPerformance -TestName "Sans progression" -ItemCount 50 -Iterations 3 -NoProgress
            $standardProgressResult = Measure-ProgressPerformance -TestName "Progression standard" -ItemCount 50 -Iterations 3
            $optimizedProgressResult = Measure-ProgressPerformance -TestName "Progression optimisée" -ItemCount 50 -Iterations 3 -OptimizedProgress

            Write-Host "Résultats de performance pour 50 éléments:" -ForegroundColor Cyan
            Write-Host "Sans barre de progression: $($noProgressResult.AvgTime) ms, $($noProgressResult.TimePerItem) ms/item" -ForegroundColor Yellow
            Write-Host "Avec progression standard: $($standardProgressResult.AvgTime) ms, $($standardProgressResult.TimePerItem) ms/item" -ForegroundColor Yellow
            Write-Host "Avec progression optimisée: $($optimizedProgressResult.AvgTime) ms, $($optimizedProgressResult.TimePerItem) ms/item" -ForegroundColor Yellow

            $standardOverhead = ($standardProgressResult.AvgTime - $noProgressResult.AvgTime) / $noProgressResult.AvgTime * 100
            $optimizedOverhead = ($optimizedProgressResult.AvgTime - $noProgressResult.AvgTime) / $noProgressResult.AvgTime * 100

            Write-Host "Surcoût de la progression standard: $([Math]::Round($standardOverhead, 2))%" -ForegroundColor Green
            Write-Host "Surcoût de la progression optimisée: $([Math]::Round($optimizedOverhead, 2))%" -ForegroundColor Green
            Write-Host "Amélioration par l'optimisation: $([Math]::Round(($standardProgressResult.AvgTime - $optimizedProgressResult.AvgTime) / $standardProgressResult.AvgTime * 100, 2))%" -ForegroundColor Green
        }

        It "La progression optimisée devrait être plus rapide que la progression standard" {
            $standardProgressResult.AvgTime | Should -BeGreaterThan $optimizedProgressResult.AvgTime
        }

        It "Le surcoût de la progression optimisée devrait être raisonnable (<20%)" {
            $overhead = ($optimizedProgressResult.AvgTime - $noProgressResult.AvgTime) / $noProgressResult.AvgTime * 100
            $overhead | Should -BeLessThan 20
        }

        It "L'utilisation CPU avec progression optimisée devrait être raisonnable" {
            $cpuOverhead = ($optimizedProgressResult.AvgCPU - $noProgressResult.AvgCPU) / $noProgressResult.AvgCPU * 100
            $cpuOverhead | Should -BeLessThan 30
        }
    }

    Context "Performance avec un grand nombre d'éléments" {
        BeforeAll {
            $largeNoProgressResult = Measure-ProgressPerformance -TestName "Grand lot sans progression" -ItemCount 100 -Iterations 2 -NoProgress
            $largeStandardProgressResult = Measure-ProgressPerformance -TestName "Grand lot avec progression standard" -ItemCount 100 -Iterations 2
            $largeOptimizedProgressResult = Measure-ProgressPerformance -TestName "Grand lot avec progression optimisée" -ItemCount 100 -Iterations 2 -OptimizedProgress

            Write-Host "Résultats de performance pour 100 éléments:" -ForegroundColor Cyan
            Write-Host "Sans barre de progression: $($largeNoProgressResult.AvgTime) ms, $($largeNoProgressResult.TimePerItem) ms/item" -ForegroundColor Yellow
            Write-Host "Avec progression standard: $($largeStandardProgressResult.AvgTime) ms, $($largeStandardProgressResult.TimePerItem) ms/item" -ForegroundColor Yellow
            Write-Host "Avec progression optimisée: $($largeOptimizedProgressResult.AvgTime) ms, $($largeOptimizedProgressResult.TimePerItem) ms/item" -ForegroundColor Yellow

            $standardOverhead = ($largeStandardProgressResult.AvgTime - $largeNoProgressResult.AvgTime) / $largeNoProgressResult.AvgTime * 100
            $optimizedOverhead = ($largeOptimizedProgressResult.AvgTime - $largeNoProgressResult.AvgTime) / $largeNoProgressResult.AvgTime * 100

            Write-Host "Surcoût de la progression standard: $([Math]::Round($standardOverhead, 2))%" -ForegroundColor Green
            Write-Host "Surcoût de la progression optimisée: $([Math]::Round($optimizedOverhead, 2))%" -ForegroundColor Green
            Write-Host "Amélioration par l'optimisation: $([Math]::Round(($largeStandardProgressResult.AvgTime - $largeOptimizedProgressResult.AvgTime) / $largeStandardProgressResult.AvgTime * 100, 2))%" -ForegroundColor Green
        }

        It "Le temps par élément devrait être similaire avec ou sans barre de progression" {
            $timeDifference = [Math]::Abs($largeOptimizedProgressResult.TimePerItem - $largeNoProgressResult.TimePerItem)
            $timeDifference | Should -BeLessThan 5
        }
    }
}
