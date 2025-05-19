# Tests de performance pour le cache de pools de runspaces
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Importer le module UnifiedParallel
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel -Verbose

    # Fonction pour créer un pool de runspaces sans utiliser le cache
    function New-StandardRunspacePool {
        param(
            [Parameter(Mandatory = $false)]
            [int]$MinRunspaces = 1,

            [Parameter(Mandatory = $false)]
            [int]$MaxRunspaces = 4
        )

        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $pool = [runspacefactory]::CreateRunspacePool($MinRunspaces, $MaxRunspaces, $sessionState, $Host)
        $pool.Open()
        return $pool
    }

    # Fonction pour mesurer les performances
    function Measure-RunspacePoolPerformance {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Method,

            [Parameter(Mandatory = $true)]
            [int]$PoolCount,

            [Parameter(Mandatory = $false)]
            [int]$MinRunspaces = 1,

            [Parameter(Mandatory = $false)]
            [int]$MaxRunspaces = 4,

            [Parameter(Mandatory = $false)]
            [int]$Iterations = 3
        )

        $totalTime = 0
        $totalCPU = 0
        $totalMemory = 0

        for ($iter = 1; $iter -le $Iterations; $iter++) {
            # Nettoyer le cache avant chaque itération
            Clear-RunspacePoolCache -Force

            # Mesurer les performances
            $process = Get-Process -Id $PID
            $startCPU = $process.TotalProcessorTime
            $startMemory = $process.WorkingSet64

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Créer les pools de runspaces selon la méthode spécifiée
            $pools = @()
            for ($i = 1; $i -le $PoolCount; $i++) {
                $pool = if ($Method -eq 'Cache') {
                    # Utiliser le cache pour les pools avec les mêmes paramètres
                    if ($i % 2 -eq 0) {
                        # Pour la moitié des pools, utiliser les mêmes paramètres (réutilisation)
                        Get-RunspacePoolFromCache -MinRunspaces $MinRunspaces -MaxRunspaces $MaxRunspaces
                    } else {
                        # Pour l'autre moitié, utiliser des paramètres différents (nouveaux pools)
                        Get-RunspacePoolFromCache -MinRunspaces $MinRunspaces -MaxRunspaces ($MaxRunspaces + $i)
                    }
                } else {
                    # Créer un nouveau pool à chaque fois
                    New-StandardRunspacePool -MinRunspaces $MinRunspaces -MaxRunspaces $MaxRunspaces
                }
                $pools += $pool
            }

            $stopwatch.Stop()
            $elapsedMs = $stopwatch.ElapsedMilliseconds

            # Mesurer l'utilisation CPU et mémoire
            $process = Get-Process -Id $PID
            $endCPU = $process.TotalProcessorTime
            $endMemory = $process.WorkingSet64

            $cpuTime = ($endCPU - $startCPU).TotalMilliseconds
            $memoryUsage = ($endMemory - $startMemory) / 1MB

            # Ajouter aux totaux
            $totalTime += $elapsedMs
            $totalCPU += $cpuTime
            $totalMemory += $memoryUsage

            # Nettoyer les pools créés sans le cache
            if ($Method -eq 'Standard') {
                foreach ($pool in $pools) {
                    $pool.Close()
                    $pool.Dispose()
                }
            }
        }

        # Calculer les moyennes
        $avgTime = $totalTime / $Iterations
        $avgCPU = $totalCPU / $Iterations
        $avgMemory = $totalMemory / $Iterations

        return [PSCustomObject]@{
            Method      = $Method
            PoolCount   = $PoolCount
            AvgTime     = $avgTime
            AvgCPU      = $avgCPU
            AvgMemory   = $avgMemory
            TimePerPool = $avgTime / $PoolCount
        }
    }
}

AfterAll {
    # Nettoyer après tous les tests
    Clear-UnifiedParallel -Verbose
}

Describe "Performance du cache de pools de runspaces" {
    Context "Comparaison cache vs standard avec 10 pools" {
        BeforeAll {
            $standardResult = Measure-RunspacePoolPerformance -Method 'Standard' -PoolCount 10 -Iterations 3
            $cacheResult = Measure-RunspacePoolPerformance -Method 'Cache' -PoolCount 10 -Iterations 3

            Write-Host "Résultats de performance pour 10 pools:" -ForegroundColor Cyan
            Write-Host "Méthode standard: $($standardResult.AvgTime) ms, $($standardResult.TimePerPool) ms/pool" -ForegroundColor Yellow
            Write-Host "Méthode avec cache: $($cacheResult.AvgTime) ms, $($cacheResult.TimePerPool) ms/pool" -ForegroundColor Yellow
            Write-Host "Amélioration: $([Math]::Round(($standardResult.AvgTime - $cacheResult.AvgTime) / $standardResult.AvgTime * 100, 2))%" -ForegroundColor Green
        }

        It "La méthode avec cache devrait être plus rapide que la méthode standard" {
            $cacheResult.AvgTime | Should -BeLessThan $standardResult.AvgTime
        }

        It "Le temps par pool devrait être inférieur avec la méthode cache" {
            $cacheResult.TimePerPool | Should -BeLessThan $standardResult.TimePerPool
        }
    }

    Context "Comparaison cache vs standard avec 50 pools" {
        BeforeAll {
            $standardResult = Measure-RunspacePoolPerformance -Method 'Standard' -PoolCount 50 -Iterations 2
            $cacheResult = Measure-RunspacePoolPerformance -Method 'Cache' -PoolCount 50 -Iterations 2

            Write-Host "Résultats de performance pour 50 pools:" -ForegroundColor Cyan
            Write-Host "Méthode standard: $($standardResult.AvgTime) ms, $($standardResult.TimePerPool) ms/pool" -ForegroundColor Yellow
            Write-Host "Méthode avec cache: $($cacheResult.AvgTime) ms, $($cacheResult.TimePerPool) ms/pool" -ForegroundColor Yellow
            Write-Host "Amélioration: $([Math]::Round(($standardResult.AvgTime - $cacheResult.AvgTime) / $standardResult.AvgTime * 100, 2))%" -ForegroundColor Green
        }

        It "La méthode avec cache devrait être plus rapide que la méthode standard" {
            $cacheResult.AvgTime | Should -BeLessThan $standardResult.AvgTime
        }

        It "Le temps par pool devrait être inférieur avec la méthode cache" {
            $cacheResult.TimePerPool | Should -BeLessThan $standardResult.TimePerPool
        }
    }

    Context "Analyse de l'utilisation de la mémoire" {
        BeforeAll {
            $standardResult = Measure-RunspacePoolPerformance -Method 'Standard' -PoolCount 20 -Iterations 2
            $cacheResult = Measure-RunspacePoolPerformance -Method 'Cache' -PoolCount 20 -Iterations 2

            Write-Host "Utilisation de la mémoire pour 20 pools:" -ForegroundColor Cyan
            Write-Host "Méthode standard: $($standardResult.AvgMemory) MB" -ForegroundColor Yellow
            Write-Host "Méthode avec cache: $($cacheResult.AvgMemory) MB" -ForegroundColor Yellow
            Write-Host "Différence: $([Math]::Round($standardResult.AvgMemory - $cacheResult.AvgMemory, 2)) MB" -ForegroundColor Green
        }

        It "L'utilisation de la mémoire devrait être raisonnable" {
            # Le cache peut utiliser plus de mémoire que la méthode standard car il conserve les pools
            # Mais l'avantage en performance compense largement ce léger surcoût
            $cacheResult.AvgMemory | Should -BeLessThan 10  # Moins de 10 MB est raisonnable
        }
    }
}
