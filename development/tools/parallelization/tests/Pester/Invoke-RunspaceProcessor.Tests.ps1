# Tests unitaires pour la fonction Invoke-RunspaceProcessor
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

Describe "Invoke-RunspaceProcessor" {
    BeforeEach {
        # Créer un pool de runspaces pour les tests
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $script:runspacePool = [runspacefactory]::CreateRunspacePool(1, 2, $sessionState, $Host)
        $script:runspacePool.Open()

        # Créer une liste pour stocker les runspaces
        $script:runspaces = New-Object System.Collections.ArrayList
    }

    AfterEach {
        # Nettoyer après chaque test
        if ($script:runspacePool) {
            $script:runspacePool.Close()
            $script:runspacePool.Dispose()
        }
    }

    It "Traite correctement les runspaces complétés" {
        # Créer quelques runspaces
        for ($i = 1; $i -le 3; $i++) {
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $script:runspacePool

            # Ajouter un script simple
            [void]$powershell.AddScript({
                    param($Item)
                    Start-Sleep -Milliseconds 100
                    return "Test $Item"
                })

            # Ajouter le paramètre
            [void]$powershell.AddParameter('Item', $i)

            # Démarrer l'exécution asynchrone
            $handle = $powershell.BeginInvoke()

            # Ajouter à la liste des runspaces
            [void]$script:runspaces.Add([PSCustomObject]@{
                    PowerShell = $powershell
                    Handle     = $handle
                    Item       = $i
                })
        }

        # Attendre tous les runspaces
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $script:runspaces -WaitForAll -NoProgress

        # Créer une copie des runspaces complétés
        $runspacesToProcess = New-Object System.Collections.ArrayList
        foreach ($runspace in $completedRunspaces) {
            [void]$runspacesToProcess.Add($runspace)
        }

        # Traiter les runspaces
        $processorResults = Invoke-RunspaceProcessor -CompletedRunspaces $runspacesToProcess -NoProgress

        $processorResults.Results.Count | Should -Be 3
        $processorResults.Errors.Count | Should -Be 0
        $processorResults.TotalProcessed | Should -Be 3
        $processorResults.SuccessCount | Should -Be 3

        # Vérifier les résultats
        $values = $processorResults.Results | ForEach-Object { $_.Value }
        $values | Should -Contain "Test 1"
        $values | Should -Contain "Test 2"
        $values | Should -Contain "Test 3"
    }

    It "Gère correctement les erreurs dans les runspaces" {
        # Créer quelques runspaces avec des erreurs
        for ($i = 1; $i -le 3; $i++) {
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $script:runspacePool

            # Ajouter un script avec une erreur
            [void]$powershell.AddScript({
                    param($Item)
                    if ($Item -eq 2) {
                        throw "Erreur test pour l'élément $Item"
                    }
                    return "Test $Item"
                })

            # Ajouter le paramètre
            [void]$powershell.AddParameter('Item', $i)

            # Démarrer l'exécution asynchrone
            $handle = $powershell.BeginInvoke()

            # Ajouter à la liste des runspaces
            [void]$script:runspaces.Add([PSCustomObject]@{
                    PowerShell = $powershell
                    Handle     = $handle
                    Item       = $i
                })
        }

        # Attendre tous les runspaces
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $script:runspaces -WaitForAll -NoProgress

        # Créer une copie des runspaces complétés
        $runspacesToProcess = New-Object System.Collections.ArrayList
        foreach ($runspace in $completedRunspaces) {
            [void]$runspacesToProcess.Add($runspace)
        }

        # Traiter les runspaces
        $processorResults = Invoke-RunspaceProcessor -CompletedRunspaces $runspacesToProcess -NoProgress -IgnoreErrors

        $processorResults.Results.Count | Should -Be 3
        $processorResults.Errors.Count | Should -Be 1
        $processorResults.SuccessCount | Should -Be 2

        # Vérifier les résultats
        $successValues = $processorResults.Results | Where-Object { $_.Success } | ForEach-Object { $_.Value }
        $successValues | Should -Contain "Test 1"
        $successValues | Should -Contain "Test 3"

        $errorItems = $processorResults.Results | Where-Object { -not $_.Success } | ForEach-Object { $_.Item }
        $errorItems | Should -Contain 2
    }

    It "Gère correctement les runspaces invalides" {
        # Créer une liste avec un runspace invalide
        $invalidRunspaces = New-Object System.Collections.ArrayList
        [void]$invalidRunspaces.Add([PSCustomObject]@{
                PowerShell = $null
                Handle     = $null
                Item       = 1
            })

        # Le traitement ne devrait pas échouer
        { Invoke-RunspaceProcessor -CompletedRunspaces $invalidRunspaces -NoProgress } | Should -Not -Throw
    }

    It "Retourne un résultat vide si aucun runspace n'est fourni" {
        $emptyRunspaces = New-Object System.Collections.ArrayList
        $result = Invoke-RunspaceProcessor -CompletedRunspaces $emptyRunspaces -NoProgress

        $result.Results.Count | Should -Be 0
        $result.Errors.Count | Should -Be 0
        $result.TotalProcessed | Should -Be 0
        $result.SuccessCount | Should -Be 0
        $result.ErrorCount | Should -Be 0
    }

    It "Retourne uniquement la liste des résultats avec le paramètre SimpleResults" {
        # Créer quelques runspaces
        for ($i = 1; $i -le 3; $i++) {
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $script:runspacePool

            # Ajouter un script simple
            [void]$powershell.AddScript({
                    param($Item)
                    Start-Sleep -Milliseconds 100
                    return "Test $Item"
                })

            # Ajouter le paramètre
            [void]$powershell.AddParameter('Item', $i)

            # Démarrer l'exécution asynchrone
            $handle = $powershell.BeginInvoke()

            # Ajouter à la liste des runspaces
            [void]$script:runspaces.Add([PSCustomObject]@{
                    PowerShell = $powershell
                    Handle     = $handle
                    Item       = $i
                })
        }

        # Attendre tous les runspaces
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $script:runspaces -WaitForAll -NoProgress

        # Créer une copie des runspaces complétés
        $runspacesToProcess = New-Object System.Collections.ArrayList
        foreach ($runspace in $completedRunspaces) {
            [void]$runspacesToProcess.Add($runspace)
        }

        # Traiter les runspaces avec SimpleResults
        $simpleResults = Invoke-RunspaceProcessor -CompletedRunspaces $runspacesToProcess -NoProgress -SimpleResults

        # Vérifier que le résultat est une liste simple
        $simpleResults | Should -BeOfType [System.Collections.ArrayList]
        $simpleResults.Count | Should -Be 3

        # Vérifier les valeurs
        $values = $simpleResults | ForEach-Object { $_.Value }
        $values | Should -Contain "Test 1"
        $values | Should -Contain "Test 2"
        $values | Should -Contain "Test 3"
    }

    It "Gère correctement différents types de collections" {
        # Créer un runspace simple pour le test
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $script:runspacePool

        # Ajouter un script simple
        [void]$powershell.AddScript({
                return "Test Collection"
            })

        # Démarrer l'exécution asynchrone
        $handle = $powershell.BeginInvoke()

        # Créer un objet runspace
        $testRunspace = [PSCustomObject]@{
            PowerShell = $powershell
            Handle     = $handle
            Item       = "TestItem"
        }

        # Tester avec différents types de collections

        # 1. ArrayList
        $arrayList = New-Object System.Collections.ArrayList
        [void]$arrayList.Add($testRunspace)
        $result1 = Invoke-RunspaceProcessor -CompletedRunspaces $arrayList -NoProgress
        $result1.Results.Count | Should -Be 1
        $result1.Results[0].Value | Should -Be "Test Collection"

        # 2. List<PSObject>
        $list = [System.Collections.Generic.List[PSObject]]::new()
        $list.Add($testRunspace)
        $result2 = Invoke-RunspaceProcessor -CompletedRunspaces $list -NoProgress
        $result2.Results.Count | Should -Be 1
        $result2.Results[0].Value | Should -Be "Test Collection"

        # 3. Array
        $array = @($testRunspace)
        $result3 = Invoke-RunspaceProcessor -CompletedRunspaces $array -NoProgress
        $result3.Results.Count | Should -Be 1
        $result3.Results[0].Value | Should -Be "Test Collection"

        # 4. Objet unique
        $result4 = Invoke-RunspaceProcessor -CompletedRunspaces $testRunspace -NoProgress
        $result4.Results.Count | Should -Be 1
        $result4.Results[0].Value | Should -Be "Test Collection"

        # Nettoyer le runspace
        $powershell.Dispose()
    }
}

AfterAll {
    # Nettoyer après tous les tests
    Clear-UnifiedParallel
}
