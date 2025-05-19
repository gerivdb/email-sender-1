# Tests unitaires pour la fonction Wait-ForCompletedRunspace et Invoke-RunspaceProcessor
# avec les optimisations de List<T>

BeforeAll {
    # Importer le module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel -Verbose

    # Fonction utilitaire pour créer des runspaces de test
    function New-TestRunspaces {
        param(
            [int]$Count = 3,
            [int]$SleepMilliseconds = 100
        )

        # Créer un pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
        $runspacePool.Open()

        # Créer une liste pour stocker les runspaces
        $runspaces = [System.Collections.Generic.List[object]]::new()

        # Créer les runspaces
        for ($i = 1; $i -le $Count; $i++) {
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool

            # Ajouter un script simple
            [void]$powershell.AddScript({
                    param($Item, $SleepMilliseconds)
                    Start-Sleep -Milliseconds $SleepMilliseconds
                    return "Test $Item"
                })

            # Ajouter les paramètres
            [void]$powershell.AddParameter('Item', $i)
            [void]$powershell.AddParameter('SleepMilliseconds', $SleepMilliseconds)

            # Démarrer l'exécution asynchrone
            $handle = $powershell.BeginInvoke()

            # Ajouter à la liste des runspaces
            $runspaces.Add([PSCustomObject]@{
                    PowerShell = $powershell
                    Handle     = $handle
                    Item       = $i
                })
        }

        return @{
            Runspaces = $runspaces
            Pool      = $runspacePool
        }
    }
}

AfterAll {
    # Nettoyer le module
    Clear-UnifiedParallel -Verbose
}

Describe "Wait-ForCompletedRunspace avec List<T>" {
    It "Devrait retourner une List<object> encapsulée dans un PSCustomObject" {
        # Créer des runspaces de test
        $testData = New-TestRunspaces -Count 3 -SleepMilliseconds 100
        $runspaces = $testData.Runspaces
        $pool = $testData.Pool

        # Attendre que tous les runspaces soient complétés
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10

        # Vérifier le type de retour
        $completedRunspaces | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results.GetType().FullName | Should -Match "System.Collections.Generic.List``1\[\[System.Object, System.Private.CoreLib"
        $completedRunspaces.Count | Should -Be 3

        # Nettoyer
        $pool.Close()
        $pool.Dispose()
    }

    It "Devrait fonctionner avec WaitForAll=`$false" {
        # Créer des runspaces de test
        $testData = New-TestRunspaces -Count 3 -SleepMilliseconds 100
        $runspaces = $testData.Runspaces
        $pool = $testData.Pool

        # Attendre qu'un seul runspace soit complété
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll:$false -NoProgress -TimeoutSeconds 10

        # Vérifier le type de retour
        $completedRunspaces | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results.GetType().FullName | Should -Match "System.Collections.Generic.List``1\[\[System.Object, System.Private.CoreLib"
        $completedRunspaces.Count | Should -Be 1

        # Nettoyer
        $pool.Close()
        $pool.Dispose()
    }
}

Describe "Invoke-RunspaceProcessor avec List<T>" {
    It "Devrait accepter une List<object> en entrée" {
        # Créer des runspaces de test
        $testData = New-TestRunspaces -Count 3 -SleepMilliseconds 100
        $runspaces = $testData.Runspaces
        $pool = $testData.Pool

        # Attendre que tous les runspaces soient complétés
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10

        # Traiter les runspaces complétés
        $results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

        # Vérifier les résultats
        $results | Should -Not -BeNullOrEmpty
        $results.Results | Should -Not -BeNullOrEmpty
        $results.Results.GetType().FullName | Should -Match "System.Collections.Generic.List``1\[\[System.Object, System.Private.CoreLib"
        $results.Results.Count | Should -Be 3
        $results.TotalProcessed | Should -Be 3
        $results.SuccessCount | Should -Be 3
        $results.ErrorCount | Should -Be 0

        # Nettoyer
        $pool.Close()
        $pool.Dispose()
    }

    It "Devrait accepter un tableau en entrée" {
        # Créer des runspaces de test
        $testData = New-TestRunspaces -Count 3 -SleepMilliseconds 100
        $runspaces = $testData.Runspaces
        $pool = $testData.Pool

        # Attendre que tous les runspaces soient complétés
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10

        # Convertir en tableau
        $arrayRunspaces = @($completedRunspaces.Results)

        # Traiter les runspaces complétés
        $results = Invoke-RunspaceProcessor -CompletedRunspaces $arrayRunspaces -NoProgress

        # Vérifier les résultats
        $results | Should -Not -BeNullOrEmpty
        $results.Results | Should -Not -BeNullOrEmpty
        $results.Results.GetType().FullName | Should -Match "System.Collections.Generic.List``1\[\[System.Object, System.Private.CoreLib"
        $results.Results.Count | Should -Be 3
        $results.TotalProcessed | Should -Be 3
        $results.SuccessCount | Should -Be 3
        $results.ErrorCount | Should -Be 0

        # Nettoyer
        $pool.Close()
        $pool.Dispose()
    }
}
