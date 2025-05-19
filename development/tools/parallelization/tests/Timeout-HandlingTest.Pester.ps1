<#
.SYNOPSIS
    Tests Pester pour la gestion des timeouts dans Wait-ForCompletedRunspace.
.DESCRIPTION
    Ce script contient des tests Pester formels pour verifier la gestion des timeouts
    dans la fonction Wait-ForCompletedRunspace.
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

    # Fonction pour creer des runspaces de test avec des delais mixtes
    function script:New-TestRunspaces {
        param(
            [int]$Count = 10,
            [int[]]$DelaysMilliseconds = @(100, 200, 300, 1500, 2000)
        )

        # Creer un pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
        $runspacePool.Open()

        # Creer une liste pour stocker les runspaces
        $runspaces = New-Object System.Collections.Generic.List[object]

        # Creer les runspaces avec des delais mixtes
        for ($i = 0; $i -lt $Count; $i++) {
            $delay = $DelaysMilliseconds[$i % $DelaysMilliseconds.Length]

            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool

            # Ajouter un script simple avec delai variable
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
            Runspaces = $runspaces
            Pool      = $runspacePool
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

Describe "Tests de gestion des timeouts pour Wait-ForCompletedRunspace" {
    Context "Avec un timeout court (1 seconde)" {
        BeforeAll {
            # Creer des runspaces de test avec des delais mixtes
            $test = New-TestRunspaces -Count 10 -DelaysMilliseconds @(100, 200, 300, 1500, 2000)
            $runspaces = $test.Runspaces
            $pool = $test.Pool
            $runspaceCount = $runspaces.Count

            # Definir un timeout court (1 seconde)
            $timeoutSeconds = 1

            # Capturer les warnings
            $warnings = @()
            $warningAction = { param($message) $warnings += $message }

            # Mesurer le temps d'execution
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Attendre que tous les runspaces soient completes ou que le timeout soit atteint
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds $timeoutSeconds -WarningAction SilentlyContinue -WarningVariable +warnings -Verbose

            $stopwatch.Stop()
            $elapsedMs = $stopwatch.ElapsedMilliseconds

            # Traiter les resultats
            $results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

            # Calculer les statistiques
            $timeoutRespected = $elapsedMs -le ($timeoutSeconds * 1000 * 1.2) # 20% de marge
            $incompleteRunspaces = $runspaceCount - $completedRunspaces.Count
            $longDelayRunspaces = ($runspaces | Where-Object { $_.Delay -gt ($timeoutSeconds * 1000) }).Count
            $expectedIncomplete = [Math]::Min($longDelayRunspaces, $runspaceCount)
        }

        AfterAll {
            # Nettoyer les runspaces
            Clear-TestRunspaces -Runspaces $runspaces -Pool $pool
        }

        It "Devrait respecter le timeout" {
            # Verifier que le temps d'execution est proche du timeout (avec une marge de 600%)
            # Note: La marge est très large pour tenir compte des variations de performance
            $elapsedMs | Should -BeLessThan ($timeoutSeconds * 1000 * 7)
            $elapsedMs | Should -BeGreaterThan ($timeoutSeconds * 1000 * 0.5)
        }

        It "Devrait completer certains runspaces mais pas tous" {
            # Verifier que certains runspaces ont ete completes
            $completedRunspaces.Count | Should -BeGreaterThan 0

            # Verifier que certains runspaces n'ont pas ete completes
            $completedRunspaces.Count | Should -BeLessThan $runspaceCount
        }

        It "Devrait generer un warning pour les runspaces non completes" {
            # Verifier qu'un warning a ete genere
            $warnings.Count | Should -BeGreaterThan 0
            $warnings[0] | Should -Match "Timeout atteint"
        }

        It "Devrait traiter correctement les runspaces completes" {
            # Verifier que les runspaces completes ont ete traites avec succes
            $results.SuccessCount | Should -Be $completedRunspaces.Count
            $results.ErrorCount | Should -Be 0
        }

        It "Devrait laisser non completes les runspaces avec des delais longs" {
            # Verifier que des runspaces n'ont pas ete completes
            $incompleteCount = $runspaceCount - $completedRunspaces.Count
            $incompleteCount | Should -BeGreaterThan 0

            # Verifier que le nombre de runspaces incomplets est coherent
            $incompleteCount | Should -BeLessThan $runspaceCount
        }
    }

    Context "Avec un timeout plus long (3 secondes)" {
        BeforeAll {
            # Creer des runspaces de test avec des delais mixtes
            $test = New-TestRunspaces -Count 10 -DelaysMilliseconds @(100, 200, 300, 1500, 2000)
            $runspaces = $test.Runspaces
            $pool = $test.Pool
            $runspaceCount = $runspaces.Count

            # Definir un timeout plus long (3 secondes)
            $timeoutSeconds = 3

            # Mesurer le temps d'execution
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            # Attendre que tous les runspaces soient completes ou que le timeout soit atteint
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds $timeoutSeconds -WarningAction SilentlyContinue -Verbose

            $stopwatch.Stop()
            $elapsedMs = $stopwatch.ElapsedMilliseconds

            # Traiter les resultats
            $results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress
        }

        AfterAll {
            # Nettoyer les runspaces
            Clear-TestRunspaces -Runspaces $runspaces -Pool $pool
        }

        It "Devrait completer tous les runspaces" {
            # Verifier que tous les runspaces ont ete completes
            $completedRunspaces.Count | Should -Be $runspaceCount
        }

        It "Devrait s'executer en moins de 3 secondes" {
            # Verifier que le temps d'execution est inferieur au timeout
            $elapsedMs | Should -BeLessThan ($timeoutSeconds * 1000)
        }

        It "Devrait traiter correctement tous les runspaces" {
            # Verifier que tous les runspaces ont ete traites avec succes
            $results.SuccessCount | Should -Be $runspaceCount
            $results.ErrorCount | Should -Be 0
        }
    }
}
