# Tests unitaires pour la fonction Invoke-UnifiedParallel
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

Describe "Invoke-UnifiedParallel" {
    It "Exécute des tâches en parallèle avec UseRunspacePool" {
        $testData = 1..3
        $results = Invoke-UnifiedParallel -ScriptBlock { param($item) "Test $item" } -InputObject $testData -UseRunspacePool -NoProgress

        $results.Count | Should -Be 3
        $results[0].Value | Should -BeLike "Test *"
        $results[1].Value | Should -BeLike "Test *"
        $results[2].Value | Should -BeLike "Test *"
    }

    It "Gère correctement les erreurs dans les tâches" {
        $testData = 1..3
        $results = Invoke-UnifiedParallel -ScriptBlock {
            param($item)
            if ($item -eq 2) { throw "Erreur test" }
            "Test $item"
        } -InputObject $testData -UseRunspacePool -NoProgress -IgnoreErrors

        $results.Count | Should -Be 3
        ($results | Where-Object { -not $_.Success }).Count | Should -Be 1
        ($results | Where-Object { $_.Success }).Count | Should -Be 2

        $successValues = $results | Where-Object { $_.Success } | ForEach-Object { $_.Value }
        $successValues | Should -Contain "Test 1"
        $successValues | Should -Contain "Test 3"

        $errorItems = $results | Where-Object { -not $_.Success } | ForEach-Object { $_.Item }
        $errorItems | Should -Contain 2
    }

    It "Retourne des métriques détaillées avec PassThru" {
        $testData = 1..3
        $results = Invoke-UnifiedParallel -ScriptBlock { param($item) "Test $item" } -InputObject $testData -UseRunspacePool -NoProgress -PassThru

        $results.Results | Should -Not -BeNullOrEmpty
        $results.TotalItems | Should -Be 3
        $results.ProcessedItems | Should -Be 3
        $results.Duration | Should -BeOfType [timespan]
        $results.StartTime | Should -BeOfType [datetime]
        $results.EndTime | Should -BeOfType [datetime]
    }

    It "Respecte la limite de threads spécifiée" {
        $testData = 1..10
        $maxThreads = 2

        $results = Invoke-UnifiedParallel -ScriptBlock {
            param($item)
            $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
            [PSCustomObject]@{
                Item     = $item
                ThreadId = $threadId
            }
        } -InputObject $testData -MaxThreads $maxThreads -UseRunspacePool -NoProgress

        $uniqueThreadIds = $results.Value.ThreadId | Select-Object -Unique
        $uniqueThreadIds.Count | Should -BeLessThanOrEqual ($maxThreads + 1) # +1 pour le thread principal
    }

    It "Utilise le type de tâche spécifié pour déterminer le nombre de threads" {
        $testData = 1..5

        $resultsCPU = Invoke-UnifiedParallel -ScriptBlock { param($item) "Test $item" } -InputObject $testData -TaskType 'CPU' -UseRunspacePool -NoProgress -PassThru
        $resultsIO = Invoke-UnifiedParallel -ScriptBlock { param($item) "Test $item" } -InputObject $testData -TaskType 'IO' -UseRunspacePool -NoProgress -PassThru

        # Les tâches IO devraient avoir plus de threads que les tâches CPU
        $resultsCPU.MaxThreadsUsed | Should -BeLessThanOrEqual $resultsIO.MaxThreadsUsed
    }

    It "Transmet correctement les variables partagées" {
        $testData = 1..3
        $sharedVar = "Variable partagée"

        $results = Invoke-UnifiedParallel -ScriptBlock {
            param($item)
            "$item - $using:sharedVar"
        } -InputObject $testData -UseRunspacePool -NoProgress

        $results[0].Value | Should -BeLike "* - Variable partagée"
        $results[1].Value | Should -BeLike "* - Variable partagée"
        $results[2].Value | Should -BeLike "* - Variable partagée"
    }

    It "Gère correctement les timeouts" {
        $testData = 1..3
        $scriptBlock = {
            param($item)
            Start-Sleep -Seconds ($item * 2) # Élément 3 prendra 6 secondes
            return "Test $item"
        }

        # Avec un timeout de 3 secondes, l'élément 3 ne devrait pas être complété
        $results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $testData -UseRunspacePool -NoProgress -TimeoutSeconds 3 -IgnoreErrors

        # Nous devrions avoir des résultats pour les éléments 1 et 2, mais pas pour l'élément 3
        $completedItems = $results | Where-Object { $_.Success } | ForEach-Object { $_.Item }
        $completedItems | Should -Contain 1
        $completedItems | Should -Contain 2

        $errorItems = $results | Where-Object { -not $_.Success } | ForEach-Object { $_.Item }
        $errorItems | Should -Contain 3
    }

    It "Utilise ForEach-Object -Parallel si spécifié" {
        # Vérifier si PowerShell 7+ est disponible
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $testData = 1..3
            $results = Invoke-UnifiedParallel -ScriptBlock { param($item) "Test $item" } -InputObject $testData -UseForeachParallel -NoProgress

            $results.Count | Should -Be 3
            $results[0].Value | Should -BeLike "Test *"
            $results[1].Value | Should -BeLike "Test *"
            $results[2].Value | Should -BeLike "Test *"
        } else {
            Set-ItResult -Skipped -Because "ForEach-Object -Parallel n'est disponible qu'à partir de PowerShell 7"
        }
    }

    It "Utilise le délai d'attente spécifié" {
        # Créer un script block rapide
        $scriptBlock = {
            param($item)
            Start-Sleep -Milliseconds 100
            return "Test $item"
        }

        # Mesurer le temps d'exécution avec un SleepMilliseconds élevé
        $startTime = [datetime]::Now
        $results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject @(1) -NoProgress -SleepMilliseconds 200 -UseRunspacePool -PassThru
        $duration = [datetime]::Now - $startTime

        # Vérifier que les résultats sont corrects
        $results | Should -Not -BeNullOrEmpty
        $results.Results.Count | Should -Be 1
        $results.Results[0].Value | Should -Be "Test 1"

        # La durée devrait être d'au moins 200ms (un cycle de vérification)
        $duration.TotalMilliseconds | Should -BeGreaterThan 150
    }

    It "Nettoie les ressources en cas de timeout avec CleanupOnTimeout" {
        # Créer un script block qui prend du temps
        $scriptBlock = {
            param($item)
            Start-Sleep -Seconds 10
            return "Test $item"
        }

        # Exécuter avec un timeout court et CleanupOnTimeout
        $results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject @(1, 2) -TimeoutSeconds 1 -NoProgress -CleanupOnTimeout -UseRunspacePool -PassThru

        # Vérifier que le timeout a été respecté
        $results.Duration.TotalSeconds | Should -BeLessThan 3
    }
}

AfterAll {
    # Nettoyer après tous les tests
    Clear-UnifiedParallel
}
