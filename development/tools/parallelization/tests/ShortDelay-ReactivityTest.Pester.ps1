<#
.SYNOPSIS
    Tests Pester pour la reactivite de Wait-ForCompletedRunspace avec des delais tres courts.
.DESCRIPTION
    Ce script contient des tests Pester formels pour verifier la reactivite
    de Wait-ForCompletedRunspace avec des delais tres courts (<10ms).
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

    # Fonction pour creer des runspaces de test avec des delais tres courts
    function script:New-TestRunspaces {
        param(
            [int]$Count = 20,
            [int[]]$DelaysMilliseconds = @(1, 2, 3, 5, 8)
        )

        # Creer un pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 8, $sessionState, $Host)
        $runspacePool.Open()

        # Creer une liste pour stocker les runspaces
        $runspaces = New-Object System.Collections.Generic.List[object]

        # Creer les runspaces avec des delais tres courts
        for ($i = 0; $i -lt $Count; $i++) {
            $delay = $DelaysMilliseconds[$i % $DelaysMilliseconds.Length]
            
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool

            # Ajouter un script simple avec delai tres court
            [void]$powershell.AddScript({
                    param($Item, $DelayMilliseconds)
                    Start-Sleep -Milliseconds $DelayMilliseconds
                    return [PSCustomObject]@{
                        Item = $Item
                        Delay = $DelayMilliseconds
                        ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                        StartTime = Get-Date
                        EndTime = Get-Date
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
            Runspaces = $runspaces
            Pool = $runspacePool
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
                }
                catch {
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

Describe "Tests de reactivite pour Wait-ForCompletedRunspace avec delais courts" {
    Context "Avec des delais tres courts (<10ms)" {
        BeforeAll {
            # Creer des runspaces de test avec des delais tres courts
            $test = New-TestRunspaces -Count 20 -DelaysMilliseconds @(1, 2, 3, 5, 8)
            $runspaces = $test.Runspaces
            $pool = $test.Pool
            $delaysMilliseconds = $test.DelaysMilliseconds
            $runspaceCount = $runspaces.Count

            # Mesurer le temps d'execution
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Attendre que tous les runspaces soient completes
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10 -Verbose

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

        It "Devrait s'executer rapidement" {
            # Verifier que le temps d'execution est raisonnable
            # Pour des delais tres courts, le temps d'execution devrait etre inferieur a 500ms
            $elapsedMs | Should -BeLessThan 500
        }

        It "Devrait avoir un overhead raisonnable" {
            # Verifier que l'overhead est raisonnable
            # L'overhead ne devrait pas depasser 20ms par runspace pour des delais tres courts
            $overhead | Should -BeLessThan 20
        }
    }

    Context "Avec un grand nombre de runspaces a delais courts" {
        BeforeAll {
            # Creer un grand nombre de runspaces de test avec des delais tres courts
            $test = New-TestRunspaces -Count 50 -DelaysMilliseconds @(1, 2, 3, 5, 8)
            $runspaces = $test.Runspaces
            $pool = $test.Pool
            $runspaceCount = $runspaces.Count

            # Mesurer le temps d'execution
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Attendre que tous les runspaces soient completes
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10 -Verbose

            $stopwatch.Stop()
            $elapsedMs = $stopwatch.ElapsedMilliseconds
        }

        AfterAll {
            # Nettoyer les runspaces
            Clear-TestRunspaces -Runspaces $runspaces -Pool $pool
        }

        It "Devrait completer tous les runspaces" {
            # Verifier que tous les runspaces ont ete completes
            $completedRunspaces.Count | Should -Be $runspaceCount
        }

        It "Devrait s'executer dans un temps raisonnable" {
            # Verifier que le temps d'execution est raisonnable
            # Pour un grand nombre de runspaces a delais courts, le temps d'execution devrait etre inferieur a 1000ms
            $elapsedMs | Should -BeLessThan 1000
        }
    }
}
