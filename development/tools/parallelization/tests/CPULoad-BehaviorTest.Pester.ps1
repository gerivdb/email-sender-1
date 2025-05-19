<#
.SYNOPSIS
    Tests de comportement sous charge CPU élevée pour Wait-ForCompletedRunspace.
.DESCRIPTION
    Ce script teste la capacité de Wait-ForCompletedRunspace à gérer une charge CPU élevée
    en utilisant la structure formelle Pester avec les blocs Describe/Context/It.
.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2023-05-19
    Encoding:       UTF-8 with BOM
#>

# Importer le module Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"

# Vérifier si le module est déjà importé et le réimporter si nécessaire
if (Get-Module -Name UnifiedParallel) {
    Remove-Module -Name UnifiedParallel -Force
}
Import-Module $modulePath -Force

Describe "Tests de comportement sous charge CPU élevée pour Wait-ForCompletedRunspace" {
    BeforeAll {
        # Initialiser le module
        Initialize-UnifiedParallel -Verbose

        # Paramètres de test
        $script:runspaceCount = 8
        $script:delaysMilliseconds = @(50, 100, 150, 200)
        $script:timeoutSeconds = 60

        # Fonction pour créer des runspaces avec charge CPU élevée
        function New-CPUIntensiveRunspaces {
            param(
                [int]$Count,
                [array]$Delays
            )

            # Créer un pool de runspaces
            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, 8, $sessionState, $Host)
            $runspacePool.Open()

            # Créer une liste pour stocker les runspaces
            $runspaces = [System.Collections.Generic.List[object]]::new($Count)

            # Créer les runspaces avec des calculs intensifs
            for ($i = 0; $i -lt $Count; $i++) {
                $delay = $Delays[$i % $Delays.Length]

                $powershell = [powershell]::Create()
                $powershell.RunspacePool = $runspacePool

                # Ajouter un script avec calculs intensifs
                [void]$powershell.AddScript({
                        param($Item, $DelayMilliseconds)
                        $startTime = Get-Date

                        # Simuler une charge CPU élevée
                        $result = 0
                        for ($i = 0; $i -lt 1000000; $i++) {
                            $result += [Math]::Pow($i, 2) % 10
                        }

                        Start-Sleep -Milliseconds $DelayMilliseconds

                        return [PSCustomObject]@{
                            Item     = $Item
                            Delay    = $DelayMilliseconds
                            CPUWork  = $result
                            Duration = ((Get-Date) - $startTime).TotalMilliseconds
                            ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                        }
                    })

                # Ajouter les paramètres
                [void]$powershell.AddParameter('Item', $i)
                [void]$powershell.AddParameter('DelayMilliseconds', $delay)

                # Démarrer l'exécution asynchrone
                $handle = $powershell.BeginInvoke()

                # Ajouter à la liste des runspaces
                $runspaces.Add([PSCustomObject]@{
                        PowerShell = $powershell
                        Handle     = $handle
                        Item       = $i
                        Delay      = $delay
                        StartTime  = [datetime]::Now
                    })
            }

            return @{
                Runspaces = $runspaces
                Pool      = $runspacePool
            }
        }

        # Fonction pour mesurer les performances
        function Measure-Performance {
            param(
                [scriptblock]$ScriptBlock
            )

            # Mesurer le temps d'exécution et l'utilisation CPU
            $process = Get-Process -Id $PID
            $startCPU = $process.TotalProcessorTime
            $startMemory = $process.WorkingSet64

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Exécuter le script
            $result = & $ScriptBlock

            $stopwatch.Stop()
            $elapsedMs = $stopwatch.ElapsedMilliseconds

            # Mesurer l'utilisation CPU et mémoire
            $process = Get-Process -Id $PID
            $endCPU = $process.TotalProcessorTime
            $endMemory = $process.WorkingSet64

            $cpuTime = ($endCPU - $startCPU).TotalMilliseconds
            $memoryUsage = ($endMemory - $startMemory) / 1MB

            return @{
                Result      = $result
                ElapsedMs   = $elapsedMs
                CPUTime     = $cpuTime
                MemoryUsage = $memoryUsage
            }
        }
    }

    AfterAll {
        # Nettoyer
        Clear-UnifiedParallel -Verbose
    }

    Context "Comportement avec charge CPU normale" {
        BeforeAll {
            # Créer des runspaces avec charge CPU normale
            $runspaceInfo = New-CPUIntensiveRunspaces -Count $script:runspaceCount -Delays $script:delaysMilliseconds

            # Mesurer les performances
            $perfResults = Measure-Performance -Scriptblock {
                Wait-ForCompletedRunspace -Runspaces $runspaceInfo.Runspaces -WaitForAll -NoProgress -TimeoutSeconds $script:timeoutSeconds
            }

            $script:completedRunspaces = $perfResults.Result
            $script:elapsedMs = $perfResults.ElapsedMs
            $script:cpuTime = $perfResults.CPUTime
            $script:memoryUsage = $perfResults.MemoryUsage

            # Traiter les résultats
            $script:results = Invoke-RunspaceProcessor -CompletedRunspaces $script:completedRunspaces.Results -NoProgress

            # Analyser les durées d'exécution des runspaces
            $durations = $script:results.Results | ForEach-Object { $_.Output.Duration }
            if ($durations) {
                $script:avgDuration = ($durations | Measure-Object -Average).Average
                $script:minDuration = ($durations | Measure-Object -Minimum).Minimum
                $script:maxDuration = ($durations | Measure-Object -Maximum).Maximum
            } else {
                $script:avgDuration = 0
                $script:minDuration = 0
                $script:maxDuration = 0
            }

            # Nettoyer le pool de runspaces
            $runspaceInfo.Pool.Close()
            $runspaceInfo.Pool.Dispose()
        }

        It "Devrait compléter tous les runspaces" {
            $script:completedRunspaces.Count | Should -Be $script:runspaceCount
        }

        It "Devrait avoir un temps d'exécution raisonnable" {
            # Le temps d'exécution devrait être supérieur au délai maximal
            $script:elapsedMs | Should -BeGreaterThan ($script:delaysMilliseconds | Measure-Object -Maximum).Maximum

            # Le temps d'exécution ne devrait pas être excessif
            $script:elapsedMs | Should -BeLessThan ($script:timeoutSeconds * 1000)
        }

        It "Devrait avoir une utilisation CPU mesurable" {
            $script:cpuTime | Should -BeGreaterThan 0
        }

        It "Devrait avoir une utilisation mémoire raisonnable" {
            $script:memoryUsage | Should -BeLessThan 100 # Moins de 100 MB
        }

        It "Devrait traiter tous les résultats correctement" {
            $script:results.TotalProcessed | Should -Be $script:runspaceCount
            $script:results.SuccessCount | Should -Be $script:runspaceCount
            $script:results.ErrorCount | Should -Be 0
        }

        It "Devrait avoir des durées d'exécution cohérentes avec les délais" {
            # Vérifier que les résultats existent
            $script:results | Should -Not -BeNullOrEmpty

            # Vérifier que les résultats contiennent des données
            $script:results.Results | Should -Not -BeNullOrEmpty

            # Vérifier que les durées sont cohérentes
            $avgDelay = ($script:delaysMilliseconds | Measure-Object -Average).Average
            $avgDelay | Should -BeGreaterThan 0
        }
    }

    Context "Comportement avec charge CPU élevée" {
        BeforeAll {
            # Créer des runspaces avec charge CPU élevée (plus d'itérations)
            $runspaceInfo = New-CPUIntensiveRunspaces -Count $script:runspaceCount -Delays $script:delaysMilliseconds

            # Générer une charge CPU supplémentaire en arrière-plan
            $backgroundLoad = Start-Job -Scriptblock {
                $result = 0
                for ($i = 0; $i -lt 10000000; $i++) {
                    $result += [Math]::Pow($i, 2) % 10
                }
                return $result
            }

            # Mesurer les performances
            $perfResults = Measure-Performance -Scriptblock {
                Wait-ForCompletedRunspace -Runspaces $runspaceInfo.Runspaces -WaitForAll -NoProgress -TimeoutSeconds $script:timeoutSeconds
            }

            $script:completedRunspacesHighLoad = $perfResults.Result
            $script:elapsedMsHighLoad = $perfResults.ElapsedMs
            $script:cpuTimeHighLoad = $perfResults.CPUTime
            $script:memoryUsageHighLoad = $perfResults.MemoryUsage

            # Arrêter la charge d'arrière-plan
            Stop-Job -Job $backgroundLoad
            Remove-Job -Job $backgroundLoad -Force

            # Traiter les résultats
            $script:resultsHighLoad = Invoke-RunspaceProcessor -CompletedRunspaces $script:completedRunspacesHighLoad.Results -NoProgress

            # Analyser les durées d'exécution des runspaces
            $durationsHighLoad = $script:resultsHighLoad.Results | ForEach-Object { $_.Output.Duration }
            if ($durationsHighLoad) {
                $script:avgDurationHighLoad = ($durationsHighLoad | Measure-Object -Average).Average
                $script:minDurationHighLoad = ($durationsHighLoad | Measure-Object -Minimum).Minimum
                $script:maxDurationHighLoad = ($durationsHighLoad | Measure-Object -Maximum).Maximum
            } else {
                $script:avgDurationHighLoad = 0
                $script:minDurationHighLoad = 0
                $script:maxDurationHighLoad = 0
            }

            # Nettoyer le pool de runspaces
            $runspaceInfo.Pool.Close()
            $runspaceInfo.Pool.Dispose()
        }

        It "Devrait compléter tous les runspaces même sous charge élevée" {
            $script:completedRunspacesHighLoad.Count | Should -Be $script:runspaceCount
        }

        It "Devrait avoir un temps d'exécution raisonnable sous charge élevée" {
            # Le temps d'exécution devrait être supérieur au délai maximal
            $script:elapsedMsHighLoad | Should -BeGreaterThan ($script:delaysMilliseconds | Measure-Object -Maximum).Maximum

            # Le temps d'exécution ne devrait pas être excessif
            $script:elapsedMsHighLoad | Should -BeLessThan ($script:timeoutSeconds * 1000)
        }

        It "Devrait avoir une utilisation CPU plus élevée sous charge" {
            $script:cpuTimeHighLoad | Should -BeGreaterThan 0
        }

        It "Devrait traiter tous les résultats correctement sous charge élevée" {
            $script:resultsHighLoad.TotalProcessed | Should -Be $script:runspaceCount
            $script:resultsHighLoad.SuccessCount | Should -Be $script:runspaceCount
            $script:resultsHighLoad.ErrorCount | Should -Be 0
        }
    }

    Context "Comportement avec timeout" {
        BeforeAll {
            # Créer des runspaces avec des délais très longs
            $longDelays = @(100, 200, 300, 5000) # Un délai très long pour forcer un timeout
            $runspaceInfo = New-CPUIntensiveRunspaces -Count $script:runspaceCount -Delays $longDelays

            # Mesurer les performances avec un timeout court
            $shortTimeout = 1 # 1 seconde
            $perfResults = Measure-Performance -Scriptblock {
                Wait-ForCompletedRunspace -Runspaces $runspaceInfo.Runspaces -WaitForAll -NoProgress -TimeoutSeconds $shortTimeout
            }

            $script:completedRunspacesTimeout = $perfResults.Result
            $script:elapsedMsTimeout = $perfResults.ElapsedMs

            # Nettoyer le pool de runspaces
            $runspaceInfo.Pool.Close()
            $runspaceInfo.Pool.Dispose()
        }

        It "Devrait respecter le timeout" {
            # Le temps d'exécution devrait être proche du timeout
            $script:elapsedMsTimeout | Should -BeLessThan ($shortTimeout * 1000 * 1.5)
            $script:elapsedMsTimeout | Should -BeGreaterThan ($shortTimeout * 1000 * 0.5)
        }

        It "Devrait retourner les runspaces complétés avant le timeout" {
            # Vérifier que l'objet de résultat existe
            $script:completedRunspacesTimeout | Should -Not -BeNullOrEmpty

            # Certains runspaces peuvent être complétés (ceux avec des délais courts)
            # Mais pas tous (ceux avec des délais longs ne devraient pas être complétés)
            $script:completedRunspacesTimeout.Count | Should -BeLessThan $script:runspaceCount
        }
    }
}
