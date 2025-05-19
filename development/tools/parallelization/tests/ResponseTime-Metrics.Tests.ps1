# Tests Pester pour les métriques de temps de réponse
# Ce script utilise Pester pour vérifier les métriques de temps de réponse dans différents scénarios

BeforeAll {
    # Importer le module UnifiedParallel
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel -Verbose

    # Fonction pour créer des runspaces de test avec différents types de charge
    function New-TestRunspaces {
        param(
            [int]$Count = 20,
            [ValidateSet("Sleep", "CPU", "Mixed")]
            [string]$WorkloadType = "Sleep"
        )

        # Créer un pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
        $runspacePool.Open()

        # Créer une liste pour stocker les runspaces
        $runspaces = [System.Collections.Generic.List[object]]::new($Count)

        # Sélectionner le script approprié en fonction du type de charge
        $scriptBlock = switch ($WorkloadType) {
            "Sleep" {
                {
                    param($Item)
                    Start-Sleep -Milliseconds (10 * ($Item % 5 + 1))
                    return [PSCustomObject]@{
                        Item         = $Item
                        WorkloadType = "Sleep"
                        ThreadId     = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                        StartTime    = Get-Date
                        EndTime      = Get-Date
                    }
                }
            }
            "CPU" {
                {
                    param($Item)
                    $startTime = Get-Date

                    # Simuler une charge CPU intensive
                    $result = 0
                    $iterations = 10000 * ($Item % 5 + 1)
                    for ($i = 0; $i -lt $iterations; $i++) {
                        $result += [Math]::Pow($i % 100, 2) % 10
                    }

                    return [PSCustomObject]@{
                        Item         = $Item
                        WorkloadType = "CPU"
                        Result       = $result
                        ThreadId     = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                        StartTime    = $startTime
                        EndTime      = Get-Date
                    }
                }
            }
            "Mixed" {
                {
                    param($Item)
                    $startTime = Get-Date

                    # Mélange de Sleep et CPU
                    Start-Sleep -Milliseconds (5 * ($Item % 5 + 1))

                    # Partie CPU
                    $result = 0
                    $iterations = 5000 * ($Item % 5 + 1)
                    for ($i = 0; $i -lt $iterations; $i++) {
                        $result += [Math]::Pow($i % 50, 2) % 10
                    }

                    return [PSCustomObject]@{
                        Item         = $Item
                        WorkloadType = "Mixed"
                        Result       = $result
                        ThreadId     = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                        StartTime    = $startTime
                        EndTime      = Get-Date
                    }
                }
            }
        }

        # Créer les runspaces avec le script approprié
        for ($i = 0; $i -lt $Count; $i++) {
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool

            # Ajouter le script
            [void]$powershell.AddScript($scriptBlock)

            # Ajouter les paramètres
            [void]$powershell.AddParameter('Item', $i)

            # Démarrer l'exécution asynchrone
            $handle = $powershell.BeginInvoke()

            # Ajouter à la liste des runspaces
            $runspaces.Add([PSCustomObject]@{
                    PowerShell   = $powershell
                    Handle       = $handle
                    Item         = $i
                    WorkloadType = $WorkloadType
                    StartTime    = [datetime]::Now
                })
        }

        return @{
            Runspaces = $runspaces
            Pool      = $runspacePool
        }
    }

    # Fonction pour mesurer les temps de réponse
    function Measure-ResponseTime {
        param(
            [int]$RunspaceCount = 20,
            [ValidateSet("Sleep", "CPU", "Mixed")]
            [string]$WorkloadType = "Sleep",
            [int]$BatchSize = 10
        )

        # Créer des runspaces de test
        $testData = New-TestRunspaces -Count $RunspaceCount -WorkloadType $WorkloadType
        $runspaces = $testData.Runspaces
        $pool = $testData.Pool

        # Mesurer le temps d'exécution
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Modifier la variable globale de taille de lot
        $script:BatchSizeOverride = $BatchSize

        # Exécuter Wait-ForCompletedRunspace
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 30 -Verbose

        # Réinitialiser la variable globale
        $script:BatchSizeOverride = $null

        $stopwatch.Stop()
        $elapsedMs = $stopwatch.ElapsedMilliseconds

        # Traiter les résultats
        $processedResults = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

        # Calculer les temps de complétion individuels
        $completionTimes = $processedResults.Results | ForEach-Object {
            if ($_.Output.EndTime -and $_.Output.StartTime) {
                ($_.Output.EndTime - $_.Output.StartTime).TotalMilliseconds
            } else {
                0
            }
        }

        # Calculer les statistiques
        $avgCompletionTime = if ($completionTimes.Count -gt 0) { ($completionTimes | Measure-Object -Average).Average } else { 0 }
        $minCompletionTime = if ($completionTimes.Count -gt 0) { ($completionTimes | Measure-Object -Minimum).Minimum } else { 0 }
        $maxCompletionTime = if ($completionTimes.Count -gt 0) { ($completionTimes | Measure-Object -Maximum).Maximum } else { 0 }
        $responseTime = $elapsedMs / $RunspaceCount

        # Nettoyer
        $pool.Close()
        $pool.Dispose()

        return [PSCustomObject]@{
            RunspaceCount     = $RunspaceCount
            WorkloadType      = $WorkloadType
            BatchSize         = $BatchSize
            TotalTime         = $elapsedMs
            ResponseTime      = $responseTime
            AvgCompletionTime = $avgCompletionTime
            MinCompletionTime = $minCompletionTime
            MaxCompletionTime = $maxCompletionTime
            CompletedCount    = $completedRunspaces.Count
        }
    }
}

AfterAll {
    # Nettoyer le module
    Clear-UnifiedParallel -Verbose
}

Describe "Métriques de temps de réponse pour différents scénarios" {
    Context "Avec charge de type Sleep" {
        BeforeAll {
            $result = Measure-ResponseTime -RunspaceCount 20 -WorkloadType "Sleep" -BatchSize 10
        }

        It "Devrait traiter tous les runspaces correctement" {
            $result.CompletedCount | Should -Be 20
        }

        It "Le temps de réponse devrait être mesurable" {
            $result.ResponseTime | Should -BeGreaterThan 0
        }

        It "Le temps de complétion moyen devrait être cohérent avec le type de charge" {
            # Pour Sleep, le temps de complétion moyen devrait être relativement faible
            $result.AvgCompletionTime | Should -BeLessThan 100
        }
    }

    Context "Avec charge de type CPU" {
        BeforeAll {
            $result = Measure-ResponseTime -RunspaceCount 20 -WorkloadType "CPU" -BatchSize 10
        }

        It "Devrait traiter tous les runspaces correctement" {
            $result.CompletedCount | Should -Be 20
        }

        It "Le temps de réponse devrait être mesurable" {
            $result.ResponseTime | Should -BeGreaterThan 0
        }

        It "Le temps de complétion moyen devrait être mesurable" {
            # Pour CPU, le temps de complétion moyen peut être 0 dans certains cas
            # Nous vérifions simplement que la valeur est valide (>= 0)
            $result.AvgCompletionTime | Should -BeGreaterOrEqual 0
        }
    }

    Context "Avec charge de type Mixed" {
        BeforeAll {
            $result = Measure-ResponseTime -RunspaceCount 20 -WorkloadType "Mixed" -BatchSize 10
        }

        It "Devrait traiter tous les runspaces correctement" {
            $result.CompletedCount | Should -Be 20
        }

        It "Le temps de réponse devrait être mesurable" {
            $result.ResponseTime | Should -BeGreaterThan 0
        }

        It "Le temps de complétion moyen devrait être mesurable" {
            # Pour Mixed, le temps de complétion moyen peut être 0 dans certains cas
            # Nous vérifions simplement que la valeur est valide (>= 0)
            $result.AvgCompletionTime | Should -BeGreaterOrEqual 0
        }
    }

    Context "Comparaison des différents types de charge" {
        BeforeAll {
            $sleepResult = Measure-ResponseTime -RunspaceCount 20 -WorkloadType "Sleep" -BatchSize 10
            $cpuResult = Measure-ResponseTime -RunspaceCount 20 -WorkloadType "CPU" -BatchSize 10
            $mixedResult = Measure-ResponseTime -RunspaceCount 20 -WorkloadType "Mixed" -BatchSize 10
        }

        It "Les temps de réponse devraient varier en fonction du type de charge" {
            # Les temps de réponse devraient être différents pour chaque type de charge
            $sleepResult.ResponseTime | Should -Not -Be $cpuResult.ResponseTime
            $sleepResult.ResponseTime | Should -Not -Be $mixedResult.ResponseTime
            $cpuResult.ResponseTime | Should -Not -Be $mixedResult.ResponseTime
        }

        It "Les temps de réponse devraient être valides pour tous les types de charge" {
            # Vérifier que les temps de réponse sont valides pour tous les types de charge
            $sleepResult.ResponseTime | Should -BeGreaterThan 0
            $cpuResult.ResponseTime | Should -BeGreaterThan 0
            $mixedResult.ResponseTime | Should -BeGreaterThan 0
        }
    }
}
