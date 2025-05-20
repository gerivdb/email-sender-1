# Tests pour la fonction Wait-ForCompletedRunspace avec focus sur le mécanisme de timeout interne
# Ces tests vérifient le bon fonctionnement du mécanisme de timeout interne pour éviter les blocages indéfinis

# Importer le module UnifiedParallel
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Fonction utilitaire pour créer des runspaces de test
# Cette fonction est définie directement dans ce fichier pour éviter les problèmes de portée
function New-TestRunspaces {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Count = 5,

        [Parameter(Mandatory = $false)]
        [int[]]$DelaysMilliseconds = @(100, 200, 300, 400, 500),

        [Parameter(Mandatory = $false)]
        [switch]$WithErrors,

        [Parameter(Mandatory = $false)]
        [switch]$WithInfiniteLoop
    )

    # Créer un pool de runspaces
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $pool = [runspacefactory]::CreateRunspacePool(1, [Math]::Min(4, $Count))
    $pool.Open()

    $runspaces = [System.Collections.Generic.List[PSObject]]::new()

    for ($i = 0; $i -lt $Count; $i++) {
        $delayIndex = $i % $DelaysMilliseconds.Length
        $delay = $DelaysMilliseconds[$delayIndex]

        $scriptBlock = {
            param($index, $delay, $withError, $withInfiniteLoop)

            # Simuler un traitement
            if ($withInfiniteLoop -and $index % 2 -eq 0) {
                # Simuler un blocage indéfini pour les runspaces pairs
                while ($true) {
                    Start-Sleep -Milliseconds 100
                }
            } else {
                Start-Sleep -Milliseconds $delay
            }

            # Générer une erreur si demandé
            if ($withError -and ($index % 3 -eq 0)) {
                throw "Erreur simulée pour le runspace $index"
            }

            # Retourner un résultat
            return "Résultat du runspace $index (délai: $delay ms)"
        }

        $powershell = [powershell]::Create().AddScript($scriptBlock).AddParameters(@{
                index            = $i
                delay            = $delay
                withError        = $WithErrors.IsPresent
                withInfiniteLoop = $WithInfiniteLoop.IsPresent
            })

        $powershell.RunspacePool = $pool

        $runspaces.Add([PSCustomObject]@{
                PowerShell = $powershell
                Handle     = $powershell.BeginInvoke()
                Index      = $i
                Delay      = $delay
            })
    }

    return @{
        Runspaces = $runspaces
        Pool      = $pool
    }
}

# Tests pour le mécanisme de timeout interne
Describe "Wait-ForCompletedRunspace - Mécanisme de timeout interne" {
    Context "Avec des runspaces bloqués indéfiniment" {
        BeforeEach {
            # Créer des runspaces de test dont certains sont bloqués indéfiniment
            $testData = New-TestRunspaces -Count 6 -DelaysMilliseconds @(100, 200, 300) -WithInfiniteLoop
            $runspaces = $testData.Runspaces
            $pool = $testData.Pool
        }

        AfterEach {
            # Nettoyer les ressources
            if ($pool) {
                $pool.Close()
                $pool.Dispose()
            }
        }

        It "Détecte et arrête les runspaces bloqués avec RunspaceTimeoutSeconds" {
            # Créer une copie de la collection de runspaces pour le test
            $runspacesCopy = [System.Collections.Generic.List[PSObject]]::new($runspaces)

            # Attendre avec un timeout individuel court pour les runspaces
            $result = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -WaitForAll -RunspaceTimeoutSeconds 2 -TimeoutSeconds 5 -NoProgress

            # Vérifier que la fonction a détecté des timeouts
            $result.TimeoutOccurred | Should -BeTrue

            # Vérifier que des runspaces ont été arrêtés
            $result.StoppedRunspaces.Count | Should -BeGreaterThan 0

            # Vérifier que les runspaces arrêtés ont le statut "TimedOut"
            $result.StoppedRunspaces | ForEach-Object {
                $_.Status | Should -Be "TimedOut"
            }

            # Vérifier que certains runspaces ont été complétés normalement
            $result.Results.Count | Should -BeGreaterThan 0
        }

        It "Respecte le timeout global même avec des runspaces bloqués" {
            # Créer une copie de la collection de runspaces pour le test
            $runspacesCopy = [System.Collections.Generic.List[PSObject]]::new($runspaces)

            # Attendre avec un timeout global court
            $result = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -WaitForAll -TimeoutSeconds 3 -NoProgress

            # Vérifier que la fonction a détecté un timeout
            $result.TimeoutOccurred | Should -BeTrue

            # Vérifier que tous les runspaces ont été traités (complétés ou arrêtés)
            $runspacesCopy.Count | Should -Be 0
        }
    }

    Context "Avec détection de deadlock" {
        BeforeEach {
            # Créer des runspaces de test dont certains sont bloqués indéfiniment
            $testData = New-TestRunspaces -Count 4 -DelaysMilliseconds @(100, 200) -WithInfiniteLoop
            $runspaces = $testData.Runspaces
            $pool = $testData.Pool
        }

        AfterEach {
            # Nettoyer les ressources
            if ($pool) {
                $pool.Close()
                $pool.Dispose()
            }
        }

        It "Détecte et résout les deadlocks" {
            # Créer une copie de la collection de runspaces pour le test
            $runspacesCopy = [System.Collections.Generic.List[PSObject]]::new($runspaces)

            # Attendre avec détection de deadlock activée
            $result = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -WaitForAll -DeadlockDetectionSeconds 3 -NoProgress

            # Vérifier que la fonction a détecté un deadlock
            $result.DeadlockDetected | Should -BeTrue

            # Vérifier que des runspaces ont été arrêtés
            $result.StoppedRunspaces.Count | Should -BeGreaterThan 0

            # Vérifier que les runspaces arrêtés ont le statut "Deadlocked"
            $result.StoppedRunspaces | Where-Object { $_.Status -eq "Deadlocked" } | Should -Not -BeNullOrEmpty
        }
    }
}
