<#
.SYNOPSIS
    Tests Pester pour la fonction Wait-ForCompletedRunspace avec délai adaptatif.
.DESCRIPTION
    Ce script contient des tests Pester formels pour vérifier les aspects critiques
    de l'implémentation de Wait-ForCompletedRunspace avec délai adaptatif.
.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2023-05-19
    Encoding:       UTF-8 with BOM
#>

BeforeAll {
    # Fonction pour créer des runspaces de test
    function script:New-TestRunspaces {
        param(
            [int]$Count = 5,
            [int]$DelayMilliseconds = 100
        )

        # Créer un pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
        $runspacePool.Open()

        # Créer une liste pour stocker les runspaces
        $runspaces = New-Object System.Collections.Generic.List[object]

        # Créer les runspaces
        for ($i = 0; $i -lt $Count; $i++) {
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool

            # Ajouter un script simple
            [void]$powershell.AddScript({
                    param($Item, $DelayMilliseconds)
                    Start-Sleep -Milliseconds $DelayMilliseconds
                    return [PSCustomObject]@{
                        Item      = $Item
                        Delay     = $DelayMilliseconds
                        ThreadId  = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                        StartTime = Get-Date
                    }
                })

            # Ajouter les paramètres
            [void]$powershell.AddParameter('Item', $i)
            [void]$powershell.AddParameter('DelayMilliseconds', $DelayMilliseconds)

            # Démarrer l'exécution asynchrone
            $handle = $powershell.BeginInvoke()

            # Ajouter à la liste des runspaces
            $runspaces.Add([PSCustomObject]@{
                    PowerShell = $powershell
                    Handle     = $handle
                    Item       = $i
                    StartTime  = [datetime]::Now
                })
        }

        return @{
            Runspaces = $runspaces
            Pool      = $runspacePool
        }
    }
    # Importer le module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel -Verbose
}

AfterAll {
    # Nettoyer
    Clear-UnifiedParallel -Verbose
}

Describe "Tests critiques pour Wait-ForCompletedRunspace avec delai adaptatif" {
    Context "Comportement avec un nombre normal de runspaces" {
        BeforeAll {
            $test = New-TestRunspaces -Count 10 -DelayMilliseconds 100
            $runspaces = $test.Runspaces
            $pool = $test.Pool

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10 -Verbose
            $stopwatch.Stop()

            $results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress
        }

        AfterAll {
            $pool.Close()
            $pool.Dispose()
        }

        It "Devrait compléter tous les runspaces" {
            $completedRunspaces.Count | Should -Be 10
        }

        It "Devrait traiter tous les runspaces avec succès" {
            $results.SuccessCount | Should -Be 10
            $results.ErrorCount | Should -Be 0
        }

        It "Devrait s'exécuter dans un délai raisonnable" {
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 2000
        }
    }

    Context "Comportement avec un timeout" {
        BeforeAll {
            $test = New-TestRunspaces -Count 5 -DelayMilliseconds 1000
            $runspaces = $test.Runspaces
            $pool = $test.Pool

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 1 -Verbose
            $stopwatch.Stop()
        }

        AfterAll {
            $pool.Close()
            $pool.Dispose()
        }

        It "Devrait respecter le timeout" {
            # Tolérance de 20% pour le timeout
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 1200
            $stopwatch.ElapsedMilliseconds | Should -BeGreaterThan 800
        }

        It "Ne devrait pas compléter tous les runspaces" {
            $completedRunspaces.Count | Should -BeLessThan 5
        }
    }

    Context "Comportement avec des delais tres courts" {
        BeforeAll {
            $test = New-TestRunspaces -Count 20 -DelayMilliseconds 5
            $runspaces = $test.Runspaces
            $pool = $test.Pool

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10 -Verbose
            $stopwatch.Stop()

            $results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress
        }

        AfterAll {
            $pool.Close()
            $pool.Dispose()
        }

        It "Devrait compléter tous les runspaces" {
            $completedRunspaces.Count | Should -Be 20
        }

        It "Devrait traiter tous les runspaces avec succès" {
            $results.SuccessCount | Should -Be 20
            $results.ErrorCount | Should -Be 0
        }

        It "Devrait s'exécuter rapidement" {
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 1000
        }
    }

    Context "Comportement avec des delais tres longs" {
        BeforeAll {
            $test = New-TestRunspaces -Count 5 -DelayMilliseconds 500
            $runspaces = $test.Runspaces
            $pool = $test.Pool

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10 -Verbose
            $stopwatch.Stop()

            $results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress
        }

        AfterAll {
            $pool.Close()
            $pool.Dispose()
        }

        It "Devrait compléter tous les runspaces" {
            $completedRunspaces.Count | Should -Be 5
        }

        It "Devrait traiter tous les runspaces avec succès" {
            $results.SuccessCount | Should -Be 5
            $results.ErrorCount | Should -Be 0
        }

        It "Devrait s'exécuter dans un délai proportionnel" {
            $stopwatch.ElapsedMilliseconds | Should -BeGreaterThan 500
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 3000
        }
    }
}
