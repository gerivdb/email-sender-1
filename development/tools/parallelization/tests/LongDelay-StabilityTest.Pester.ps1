<#
.SYNOPSIS
    Tests Pester pour la stabilite de Wait-ForCompletedRunspace avec des delais tres longs.
.DESCRIPTION
    Ce script contient des tests Pester formels pour verifier la stabilite
    de Wait-ForCompletedRunspace avec des delais tres longs (>500ms).
.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2023-05-19
    Encoding:       UTF-8 with BOM
#>

BeforeAll {
    # Importer le module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel -Verbose

    # Fonction pour creer des runspaces de test avec des delais longs
    function script:New-TestRunspaces {
        param(
            [int]$Count = 10,
            [int[]]$DelaysMilliseconds = @(500, 600, 700, 800, 900)
        )

        # Creer un pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 8, $sessionState, $Host)
        $runspacePool.Open()

        # Creer une liste pour stocker les runspaces
        $runspaces = New-Object System.Collections.Generic.List[object]

        # Creer les runspaces avec des delais longs
        for ($i = 0; $i -lt $Count; $i++) {
            $delay = $DelaysMilliseconds[$i % $DelaysMilliseconds.Length]

            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool

            # Ajouter un script simple avec delai long
            [void]$powershell.AddScript({
                    param($Item, $DelayMilliseconds)
                    Start-Sleep -Milliseconds $DelayMilliseconds
                    return [PSCustomObject]@{
                        Item      = $Item
                        Delay     = $DelayMilliseconds
                        ThreadId  = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                        StartTime = Get-Date
                        EndTime   = Get-Date
                    }
                })

            # Ajouter les parametres
            [void]$powershell.AddParameter('Item', $i)
            [void]$powershell.AddParameter('DelayMilliseconds', $delay)

            # Demarrer l'execution asynchrone
            $handle = $powershell.BeginInvoke()

            # Ajouter a la liste des runspaces
            $runspaces.Add([PSCustomObject]@{
                    PowerShell = $powershell
                    Handle     = $handle
                    Item       = $i
                    Delay      = $delay
                    StartTime  = [datetime]::Now
                })
        }

        return @{
            Runspaces          = $runspaces
            Pool               = $runspacePool
            DelaysMilliseconds = $DelaysMilliseconds
        }
    }

    # Fonction pour nettoyer les runspaces
    function script:Clear-TestRunspaces {
        param(
            [object[]]$Runspaces,
            [System.Management.Automation.Runspaces.RunspacePool]$Pool
        )

        # Nettoyer les runspaces restants
        foreach ($runspace in $Runspaces) {
            if (-not $runspace.Handle.IsCompleted) {
                try {
                    $runspace.PowerShell.Stop()
                    $runspace.PowerShell.Dispose()
                } catch {
                    Write-Warning "Erreur lors du nettoyage d'un runspace: $_"
                }
            }
        }

        # Fermer et disposer le pool
        if ($Pool) {
            $Pool.Close()
            $Pool.Dispose()
        }
    }
}

AfterAll {
    # Nettoyer le module
    Clear-UnifiedParallel -Verbose
}

Describe "Tests de stabilite pour Wait-ForCompletedRunspace avec delais longs" {
    Context "Avec des delais tres longs (>500ms)" {
        BeforeAll {
            # Creer des runspaces de test avec des delais longs
            $test = New-TestRunspaces -Count 10 -DelaysMilliseconds @(500, 600, 700, 800, 900)
            $runspaces = $test.Runspaces
            $pool = $test.Pool
            $delaysMilliseconds = $test.DelaysMilliseconds
            $runspaceCount = $runspaces.Count

            # Mesurer le temps d'execution
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Attendre que tous les runspaces soient completes
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 30 -Verbose

            $stopwatch.Stop()
            $elapsedMs = $stopwatch.ElapsedMilliseconds

            # Traiter les resultats
            $results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

            # Calculer les statistiques
            $avgTimePerRunspace = $elapsedMs / $runspaceCount
            $avgDelay = ($delaysMilliseconds | Measure-Object -Average).Average
            $overhead = $avgTimePerRunspace - $avgDelay
        }

        AfterAll {
            # Nettoyer les runspaces
            Clear-TestRunspaces -Runspaces $runspaces -Pool $pool
        }

        It "Devrait completer tous les runspaces" {
            # Verifier que tous les runspaces ont ete completes
            $completedRunspaces.Count | Should -Be $runspaceCount
        }

        It "Devrait traiter tous les runspaces avec succes" {
            # Verifier que tous les runspaces ont ete traites avec succes
            $results.SuccessCount | Should -Be $runspaceCount
            $results.ErrorCount | Should -Be 0
        }

        It "Devrait avoir un temps d'execution raisonnable" {
            # Verifier que le temps d'execution est raisonnable
            # Le temps d'execution devrait etre proche de la somme des delais divise par le nombre de threads
            $maxThreads = 8 # Nombre de threads dans le pool
            $totalDelay = ($delaysMilliseconds | Measure-Object -Sum).Sum
            $expectedMaxTime = ($totalDelay / $maxThreads) * 5.0 # 400% de marge pour tenir compte de l'overhead et de la variabilite

            $elapsedMs | Should -BeLessThan $expectedMaxTime
        }

        It "Devrait avoir un overhead raisonnable" {
            # Verifier que l'overhead est raisonnable
            # L'overhead ne devrait pas depasser 50% du delai moyen
            $overhead | Should -BeLessThan ($avgDelay * 0.5)
        }
    }

    Context "Avec des delais tres longs et un timeout" {
        BeforeAll {
            # Creer des runspaces de test avec des delais tres longs
            $test = New-TestRunspaces -Count 5 -DelaysMilliseconds @(1000, 1500, 2000, 2500, 3000)
            $runspaces = $test.Runspaces
            $pool = $test.Pool
            $runspaceCount = $runspaces.Count

            # Mesurer le temps d'execution
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Attendre que tous les runspaces soient completes avec un timeout court
            $timeoutSeconds = 2
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds $timeoutSeconds -WarningAction SilentlyContinue -Verbose

            $stopwatch.Stop()
            $elapsedMs = $stopwatch.ElapsedMilliseconds
        }

        AfterAll {
            # Nettoyer les runspaces
            Clear-TestRunspaces -Runspaces $runspaces -Pool $pool
        }

        It "Devrait respecter le timeout" {
            # Verifier que le temps d'execution est proche du timeout
            $elapsedMs | Should -BeLessThan ($timeoutSeconds * 1000 * 1.2)
            $elapsedMs | Should -BeGreaterThan ($timeoutSeconds * 1000 * 0.8)
        }

        It "Ne devrait pas completer tous les runspaces" {
            # Verifier que tous les runspaces n'ont pas ete completes
            $completedRunspaces.Count | Should -BeLessThan $runspaceCount
        }
    }
}
