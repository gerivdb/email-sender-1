# Tests de performance pour la gestion optimisée de la progression
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Importer le module UnifiedParallel
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel -Verbose

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
            [int]$Iterations = 3,

            [Parameter(Mandatory = $false)]
            [int]$MaxThreads = 4
        )

        $totalTime = 0
        $totalCPU = 0

        for ($iter = 1; $iter -le $Iterations; $iter++) {
            # Créer des éléments de test (utiliser une liste pour éviter les problèmes de collection de taille fixe)
            $items = [System.Collections.Generic.List[int]]::new($ItemCount)
            for ($i = 1; $i -le $ItemCount; $i++) {
                $items.Add($i)
            }

            # Mesurer les performances
            $process = Get-Process -Id $PID
            $startCPU = $process.TotalProcessorTime

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Exécuter le traitement parallèle
            # Utiliser UseRunspacePool pour éviter les problèmes avec ForEach-Object -Parallel
            $params = @{
                InputObject     = $items
                ScriptBlock     = {
                    param($item)
                    # Simuler un traitement qui prend du temps
                    Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 50)
                    return $item * 2
                }
                MaxThreads      = $MaxThreads
                NoProgress      = $NoProgress
                ActivityName    = "Test de progression: $TestName"
                UseRunspacePool = $true  # Forcer l'utilisation des runspaces
            }

            $null = Invoke-UnifiedParallel @params

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
            TestName    = $TestName
            ItemCount   = $ItemCount
            NoProgress  = $NoProgress
            AvgTime     = $avgTime
            AvgCPU      = $avgCPU
            TimePerItem = $avgTime / $ItemCount
            CPUPerItem  = $avgCPU / $ItemCount
        }
    }
}

AfterAll {
    # Nettoyer après tous les tests
    Clear-UnifiedParallel -Verbose
}

Describe "Performance de la gestion de la progression" {
    Context "Comparaison avec et sans barre de progression" {
        BeforeAll {
            $withProgressResult = Measure-ProgressPerformance -TestName "Avec progression" -ItemCount 50 -Iterations 3
            $noProgressResult = Measure-ProgressPerformance -TestName "Sans progression" -ItemCount 50 -Iterations 3 -NoProgress

            Write-Host "Résultats de performance pour 50 éléments:" -ForegroundColor Cyan
            Write-Host "Avec barre de progression: $($withProgressResult.AvgTime) ms, $($withProgressResult.TimePerItem) ms/item" -ForegroundColor Yellow
            Write-Host "Sans barre de progression: $($noProgressResult.AvgTime) ms, $($noProgressResult.TimePerItem) ms/item" -ForegroundColor Yellow
            Write-Host "Surcoût de la barre de progression: $([Math]::Round(($withProgressResult.AvgTime - $noProgressResult.AvgTime) / $noProgressResult.AvgTime * 100, 2))%" -ForegroundColor Green
        }

        It "Le surcoût de la barre de progression devrait être raisonnable (<30%)" {
            $overhead = ($withProgressResult.AvgTime - $noProgressResult.AvgTime) / $noProgressResult.AvgTime * 100
            $overhead | Should -BeLessThan 30
        }

        It "L'utilisation CPU avec barre de progression devrait être raisonnable" {
            $cpuOverhead = ($withProgressResult.AvgCPU - $noProgressResult.AvgCPU) / $noProgressResult.AvgCPU * 100
            $cpuOverhead | Should -BeLessThan 50
        }
    }

    Context "Performance avec un grand nombre d'éléments" {
        BeforeAll {
            $largeWithProgressResult = Measure-ProgressPerformance -TestName "Grand lot avec progression" -ItemCount 100 -Iterations 2
            $largeNoProgressResult = Measure-ProgressPerformance -TestName "Grand lot sans progression" -ItemCount 100 -Iterations 2 -NoProgress

            Write-Host "Résultats de performance pour 100 éléments:" -ForegroundColor Cyan
            Write-Host "Avec barre de progression: $($largeWithProgressResult.AvgTime) ms, $($largeWithProgressResult.TimePerItem) ms/item" -ForegroundColor Yellow
            Write-Host "Sans barre de progression: $($largeNoProgressResult.AvgTime) ms, $($largeNoProgressResult.TimePerItem) ms/item" -ForegroundColor Yellow
            Write-Host "Surcoût de la barre de progression: $([Math]::Round(($largeWithProgressResult.AvgTime - $largeNoProgressResult.AvgTime) / $largeNoProgressResult.AvgTime * 100, 2))%" -ForegroundColor Green
        }

        It "Le surcoût de la barre de progression devrait diminuer avec un grand nombre d'éléments" {
            $overhead = ($largeWithProgressResult.AvgTime - $largeNoProgressResult.AvgTime) / $largeNoProgressResult.AvgTime * 100
            $overhead | Should -BeLessThan 25
        }

        It "Le temps par élément devrait être similaire avec ou sans barre de progression" {
            $timeDifference = [Math]::Abs($largeWithProgressResult.TimePerItem - $largeNoProgressResult.TimePerItem)
            $timeDifference | Should -BeLessThan 5
        }
    }
}
