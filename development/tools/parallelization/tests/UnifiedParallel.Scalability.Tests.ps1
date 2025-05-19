# Tests unitaires pour la fonction Wait-ForCompletedRunspace avec un grand nombre de runspaces
# Ce script teste la scalabilité de l'implémentation avec délai adaptatif

BeforeAll {
    # Importer le module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel -Verbose

    # Fonction utilitaire pour créer un grand nombre de runspaces de test
    function New-TestRunspacesLarge {
        param(
            [int]$Count = 50,
            [int[]]$DelaysMilliseconds = @(10, 20, 30, 40, 50)
        )

        # Créer un pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 8, $sessionState, $Host)
        $runspacePool.Open()

        # Créer une liste pour stocker les runspaces
        $runspaces = [System.Collections.Generic.List[object]]::new($Count)

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

Describe "Wait-ForCompletedRunspace avec un grand nombre de runspaces" {
    It "Devrait traiter 50 runspaces correctement" {
        # Créer 50 runspaces de test
        $testData = New-TestRunspacesLarge -Count 50 -DelaysMilliseconds @(10, 20, 30, 40, 50)
        $runspaces = $testData.Runspaces
        $pool = $testData.Pool

        # Mesurer le temps d'exécution
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Attendre que tous les runspaces soient complétés
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 30 -Verbose

        $stopwatch.Stop()
        $elapsedMs = $stopwatch.ElapsedMilliseconds

        # Vérifier les résultats
        $completedRunspaces | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results | Should -Not -BeNullOrEmpty
        $completedRunspaces.Count | Should -Be 50

        # Traiter les résultats
        $results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

        # Vérifier que tous les runspaces ont été traités correctement
        $results.TotalProcessed | Should -Be 50
        $results.SuccessCount | Should -Be 50
        $results.ErrorCount | Should -Be 0

        # Afficher les statistiques
        Write-Host "Temps d'exécution pour 50 runspaces: $elapsedMs ms"
        
        # Nettoyer
        $pool.Close()
        $pool.Dispose()
    }

    It "Devrait traiter 100 runspaces correctement" {
        # Créer 100 runspaces de test
        $testData = New-TestRunspacesLarge -Count 100 -DelaysMilliseconds @(10, 20, 30, 40, 50)
        $runspaces = $testData.Runspaces
        $pool = $testData.Pool

        # Mesurer le temps d'exécution
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Attendre que tous les runspaces soient complétés
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 60 -Verbose

        $stopwatch.Stop()
        $elapsedMs = $stopwatch.ElapsedMilliseconds

        # Vérifier les résultats
        $completedRunspaces | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results | Should -Not -BeNullOrEmpty
        $completedRunspaces.Count | Should -Be 100

        # Traiter les résultats
        $results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

        # Vérifier que tous les runspaces ont été traités correctement
        $results.TotalProcessed | Should -Be 100
        $results.SuccessCount | Should -Be 100
        $results.ErrorCount | Should -Be 0

        # Afficher les statistiques
        Write-Host "Temps d'exécution pour 100 runspaces: $elapsedMs ms"
        
        # Nettoyer
        $pool.Close()
        $pool.Dispose()
    }

    It "Devrait gérer efficacement la taille des lots avec un grand nombre de runspaces" {
        # Créer 75 runspaces de test avec des délais variés
        $testData = New-TestRunspacesLarge -Count 75 -DelaysMilliseconds @(5, 10, 15, 20, 25, 30)
        $runspaces = $testData.Runspaces
        $pool = $testData.Pool

        # Mesurer le temps d'exécution
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Attendre que tous les runspaces soient complétés
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 45 -Verbose

        $stopwatch.Stop()
        $elapsedMs = $stopwatch.ElapsedMilliseconds

        # Vérifier les résultats
        $completedRunspaces | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results | Should -Not -BeNullOrEmpty
        $completedRunspaces.Count | Should -Be 75

        # Traiter les résultats
        $results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

        # Vérifier que tous les runspaces ont été traités correctement
        $results.TotalProcessed | Should -Be 75
        $results.SuccessCount | Should -Be 75
        $results.ErrorCount | Should -Be 0

        # Afficher les statistiques
        Write-Host "Temps d'exécution pour 75 runspaces avec délais variés: $elapsedMs ms"
        
        # Nettoyer
        $pool.Close()
        $pool.Dispose()
    }
}
