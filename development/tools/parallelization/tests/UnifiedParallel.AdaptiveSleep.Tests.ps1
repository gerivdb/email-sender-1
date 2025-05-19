# Tests unitaires pour la fonction Wait-ForCompletedRunspace avec délai adaptatif
# Ce script teste l'optimisation de la vérification de l'état des runspaces

BeforeAll {
    # Importer le module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel -Verbose

    # Fonction utilitaire pour créer des runspaces de test avec délais variés
    function New-TestRunspacesWithVariableDelays {
        param(
            [int]$Count = 5,
            [int[]]$DelaysMilliseconds = @(100, 200, 300, 400, 500)
        )

        # Créer un pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
        $runspacePool.Open()

        # Créer une liste pour stocker les runspaces
        $runspaces = [System.Collections.Generic.List[object]]::new()

        # Créer les runspaces avec des délais différents
        for ($i = 0; $i -lt $Count; $i++) {
            $delay = $DelaysMilliseconds[$i % $DelaysMilliseconds.Length]
            
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool

            # Ajouter un script simple avec délai variable
            [void]$powershell.AddScript({
                    param($Item, $DelayMilliseconds)
                    Start-Sleep -Milliseconds $DelayMilliseconds
                    return [PSCustomObject]@{
                        Item = $Item
                        Delay = $DelayMilliseconds
                        ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                        StartTime = Get-Date
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
            Pool = $runspacePool
        }
    }
}

AfterAll {
    # Nettoyer le module
    Clear-UnifiedParallel -Verbose
}

Describe "Wait-ForCompletedRunspace avec délai adaptatif" {
    It "Devrait traiter tous les runspaces avec des délais variables" {
        # Créer des runspaces de test avec des délais variables
        $testData = New-TestRunspacesWithVariableDelays -Count 10 -DelaysMilliseconds @(50, 100, 150, 200, 250)
        $runspaces = $testData.Runspaces
        $pool = $testData.Pool

        # Mesurer le temps d'exécution
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Attendre que tous les runspaces soient complétés
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10 -Verbose

        $stopwatch.Stop()
        $elapsedMs = $stopwatch.ElapsedMilliseconds

        # Vérifier les résultats
        $completedRunspaces | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results | Should -Not -BeNullOrEmpty
        $completedRunspaces.Count | Should -Be 10

        # Traiter les résultats
        $results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

        # Vérifier que tous les runspaces ont été traités correctement
        $results.TotalProcessed | Should -Be 10
        $results.SuccessCount | Should -Be 10
        $results.ErrorCount | Should -Be 0

        # Afficher les statistiques
        Write-Host "Temps d'exécution total: $elapsedMs ms"
        
        # Nettoyer
        $pool.Close()
        $pool.Dispose()
    }

    It "Devrait traiter efficacement un grand nombre de runspaces" {
        # Créer un grand nombre de runspaces avec des délais variables
        $testData = New-TestRunspacesWithVariableDelays -Count 20 -DelaysMilliseconds @(10, 20, 30, 40, 50, 100, 150, 200)
        $runspaces = $testData.Runspaces
        $pool = $testData.Pool

        # Mesurer le temps d'exécution
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Attendre que tous les runspaces soient complétés
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10 -Verbose

        $stopwatch.Stop()
        $elapsedMs = $stopwatch.ElapsedMilliseconds

        # Vérifier les résultats
        $completedRunspaces | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results | Should -Not -BeNullOrEmpty
        $completedRunspaces.Count | Should -Be 20

        # Traiter les résultats
        $results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

        # Vérifier que tous les runspaces ont été traités correctement
        $results.TotalProcessed | Should -Be 20
        $results.SuccessCount | Should -Be 20
        $results.ErrorCount | Should -Be 0

        # Afficher les statistiques
        Write-Host "Temps d'exécution total pour 20 runspaces: $elapsedMs ms"
        
        # Nettoyer
        $pool.Close()
        $pool.Dispose()
    }
}
