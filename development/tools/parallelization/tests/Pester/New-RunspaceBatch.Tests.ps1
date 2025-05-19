# Tests unitaires pour la fonction New-RunspaceBatch
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Chemin du module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"

    # Importer le module
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel
}

Describe "New-RunspaceBatch" {
    BeforeEach {
        # Créer un pool de runspaces pour les tests
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $script:runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
        $script:runspacePool.Open()
    }

    AfterEach {
        # Nettoyer après chaque test
        if ($script:runspacePool) {
            $script:runspacePool.Close()
            $script:runspacePool.Dispose()
        }
    }

    It "Crée correctement un lot de runspaces avec ScriptBlock" {
        # Préparer les données de test
        $scriptBlock = { param($item) "Test $item" }
        $inputObjects = 1..10

        # Créer les runspaces en batch
        $runspaces = New-RunspaceBatch -RunspacePool $script:runspacePool -ScriptBlock $scriptBlock -InputObjects $inputObjects -BatchSize 5

        # Vérifier les résultats
        $runspaces | Should -Not -BeNullOrEmpty
        $runspaces.Count | Should -Be 10
        $runspaces | Should -BeOfType [PSCustomObject]
        $runspaces[0].PowerShell | Should -Not -BeNullOrEmpty
        $runspaces[0].Handle | Should -Not -BeNullOrEmpty
        $runspaces[0].Item | Should -Be 1
        $runspaces[0].BatchIndex | Should -Be 0
        $runspaces[5].BatchIndex | Should -Be 1

        # Attendre que tous les runspaces soient terminés
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress

        # Vérifier que tous les runspaces sont complétés
        $completedRunspaces.Count | Should -Be 10

        # Récupérer les résultats
        foreach ($runspace in $completedRunspaces.Results) {
            $result = $runspace.PowerShell.EndInvoke($runspace.Handle)
            $result | Should -Not -BeNullOrEmpty
            if ($runspace.Item -eq 1) {
                $result | Should -Be "Test 1"
            }
        }
    }

    It "Crée correctement un lot de runspaces avec Command" {
        # Préparer les données de test
        $command = "Write-Output"  # Utiliser une commande plus simple et prévisible
        $inputObjects = @("test1", "test2")

        # Créer les runspaces en batch
        $runspaces = New-RunspaceBatch -RunspacePool $script:runspacePool -Command $command -InputObjects $inputObjects -BatchSize 2

        # Vérifier les résultats
        $runspaces | Should -Not -BeNullOrEmpty
        $runspaces.Count | Should -Be 2
        $runspaces | Should -BeOfType [PSCustomObject]
        $runspaces[0].PowerShell | Should -Not -BeNullOrEmpty
        $runspaces[0].Handle | Should -Not -BeNullOrEmpty
        $runspaces[0].Item | Should -Be "test1"
        $runspaces[0].BatchIndex | Should -Be 0

        # Attendre que tous les runspaces soient terminés
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress

        # Vérifier que tous les runspaces sont complétés
        $completedRunspaces.Count | Should -Be 2

        # Récupérer les résultats
        foreach ($runspace in $completedRunspaces.Results) {
            $result = $runspace.PowerShell.EndInvoke($runspace.Handle)
            $result | Should -Not -BeNullOrEmpty

            # Vérifier que le résultat correspond à l'entrée (maintenant en utilisant AddArgument)
            if ($runspace.Item -eq "test1") {
                $result | Should -BeExactly "test1"
            } elseif ($runspace.Item -eq "test2") {
                $result | Should -BeExactly "test2"
            }
        }
    }

    It "Respecte la taille de batch spécifiée" {
        # Préparer les données de test
        $scriptBlock = { param($item) "Test $item" }
        $inputObjects = 1..20
        $batchSize = 4

        # Créer les runspaces en batch
        $runspaces = New-RunspaceBatch -RunspacePool $script:runspacePool -ScriptBlock $scriptBlock -InputObjects $inputObjects -BatchSize $batchSize

        # Vérifier les résultats
        $runspaces | Should -Not -BeNullOrEmpty
        $runspaces.Count | Should -Be 20

        # Vérifier les indices de batch
        $batchIndices = $runspaces | Group-Object -Property BatchIndex | Sort-Object -Property Name
        $batchIndices.Count | Should -Be 5  # 20 éléments / 4 par batch = 5 batches
        $batchIndices[0].Count | Should -Be 4
        $batchIndices[1].Count | Should -Be 4
        $batchIndices[2].Count | Should -Be 4
        $batchIndices[3].Count | Should -Be 4
        $batchIndices[4].Count | Should -Be 4
    }

    It "Applique correctement la limite de throttling" {
        # Préparer les données de test
        $scriptBlock = { param($item) "Test $item" }
        $inputObjects = 1..50
        $throttleLimit = 10

        # Créer les runspaces en batch avec throttling
        $runspaces = New-RunspaceBatch -RunspacePool $script:runspacePool -ScriptBlock $scriptBlock -InputObjects $inputObjects -ThrottleLimit $throttleLimit -BatchSize 5

        # Vérifier les résultats
        $runspaces | Should -Not -BeNullOrEmpty
        $runspaces.Count | Should -Be $throttleLimit
    }

    It "Gère correctement les erreurs de pool de runspaces" {
        # Créer un pool fermé
        $closedPool = [runspacefactory]::CreateRunspacePool(1, 2, $sessionState, $Host)
        # Ne pas ouvrir le pool

        # Tenter de créer des runspaces avec un pool fermé
        { New-RunspaceBatch -RunspacePool $closedPool -ScriptBlock { "Test" } -InputObjects @(1) } | Should -Throw
    }
}

AfterAll {
    # Nettoyer après tous les tests
    Clear-UnifiedParallel
}
