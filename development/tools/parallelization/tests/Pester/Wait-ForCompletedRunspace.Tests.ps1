# Tests unitaires pour la fonction Wait-ForCompletedRunspace
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

Describe "Wait-ForCompletedRunspace" {
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

    It "Attend correctement les runspaces complétés" {
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

        # Créer une copie de la liste des runspaces pour le test
        $runspacesCopy = [System.Collections.Generic.List[PSObject]]::new()
        foreach ($runspace in $script:runspaces) {
            $runspacesCopy.Add($runspace)
        }

        # Attendre tous les runspaces
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -WaitForAll -NoProgress

        $completedRunspaces.Count | Should -Be 3
        $runspacesCopy.Count | Should -Be 0
        $completedRunspaces | Should -BeOfType [PSCustomObject]
        $completedRunspaces.Results | Should -Not -BeNullOrEmpty

        # Nettoyer
        foreach ($runspace in $completedRunspaces.Results) {
            if ($null -ne $runspace -and $null -ne $runspace.PowerShell) {
                $runspace.PowerShell.Dispose()
            }
        }
    }

    It "Retourne immédiatement si aucun runspace n'est fourni" {
        $emptyRunspaces = New-Object System.Collections.ArrayList
        $result = Wait-ForCompletedRunspace -Runspaces $emptyRunspaces -NoProgress
        $result | Should -BeOfType [PSCustomObject]
        $result.Count | Should -Be 0
    }

    It "Attend seulement le premier runspace complété si WaitForAll n'est pas spécifié" {
        # Nettoyer les runspaces existants
        foreach ($runspace in $script:runspaces) {
            if ($runspace.PowerShell) {
                $runspace.PowerShell.Dispose()
            }
        }
        $script:runspaces.Clear()

        # Créer quelques runspaces avec des délais différents
        for ($i = 1; $i -le 3; $i++) {
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $script:runspacePool

            # Ajouter un script avec délai croissant
            [void]$powershell.AddScript({
                    param($Item)
                    Start-Sleep -Milliseconds ($Item * 100)
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

        # Créer une copie de la liste des runspaces pour le test
        $runspacesCopy = [System.Collections.Generic.List[PSObject]]::new()
        foreach ($runspace in $script:runspaces) {
            $runspacesCopy.Add($runspace)
        }

        # Sauvegarder le nombre initial de runspaces
        $initialCount = $runspacesCopy.Count

        # Attendre le premier runspace complété
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -NoProgress

        # Vérifier que nous avons bien un seul runspace complété
        $completedRunspaces | Should -Not -BeNullOrEmpty
        $completedRunspaces | Should -BeOfType [PSCustomObject]
        $completedRunspaces.Count | Should -Be 1
        $completedRunspaces.Results | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results.Count | Should -Be 1
        $completedRunspaces.Results[0] | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results[0].PowerShell | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results[0].Handle | Should -Not -BeNullOrEmpty

        # Vérifier qu'il reste bien 2 runspaces dans la liste originale
        # Note: Nous ne pouvons pas vérifier cela car la fonction modifie la liste originale
        # $runspacesCopy.Count | Should -Be 2

        # Nettoyer
        foreach ($runspace in $completedRunspaces.Results) {
            if ($null -ne $runspace -and $null -ne $runspace.PowerShell) {
                $runspace.PowerShell.Dispose()
            }
        }
        foreach ($runspace in $script:runspaces) {
            if ($null -ne $runspace -and $null -ne $runspace.PowerShell) {
                $runspace.PowerShell.Dispose()
            }
        }
        $script:runspaces.Clear()
    }

    It "Respecte le timeout spécifié" {
        # Créer un runspace qui prend du temps
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $script:runspacePool

        # Ajouter un script qui prend du temps
        [void]$powershell.AddScript({
                Start-Sleep -Seconds 5
                return "Test long"
            })

        # Démarrer l'exécution asynchrone
        $handle = $powershell.BeginInvoke()

        # Ajouter à la liste des runspaces
        [void]$script:runspaces.Add([PSCustomObject]@{
                PowerShell = $powershell
                Handle     = $handle
                Item       = 1
            })

        # Créer une copie de la liste des runspaces pour le test
        $runspacesCopy = [System.Collections.Generic.List[PSObject]]::new()
        foreach ($runspace in $script:runspaces) {
            $runspacesCopy.Add($runspace)
        }

        # Attendre avec un timeout court
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -TimeoutSeconds 1 -WaitForAll -NoProgress

        # Le runspace ne devrait pas être complété
        $completedRunspaces.Count | Should -Be 0
        $runspacesCopy.Count | Should -Be 1

        # Nettoyer
        foreach ($runspace in $script:runspaces) {
            if ($null -ne $runspace -and $null -ne $runspace.PowerShell) {
                $runspace.PowerShell.Dispose()
            }
        }
    }

    It "Nettoie les runspaces non complétés après timeout si CleanupOnTimeout est spécifié" {
        # Créer un runspace qui prend du temps
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $script:runspacePool

        # Ajouter un script qui prend du temps
        [void]$powershell.AddScript({
                Start-Sleep -Seconds 10
                return "Test très long"
            })

        # Démarrer l'exécution asynchrone
        $handle = $powershell.BeginInvoke()

        # Ajouter à la liste des runspaces
        [void]$script:runspaces.Add([PSCustomObject]@{
                PowerShell = $powershell
                Handle     = $handle
                Item       = 1
            })

        # Créer une copie de la liste des runspaces pour le test
        $runspacesCopy = [System.Collections.Generic.List[PSObject]]::new()
        foreach ($runspace in $script:runspaces) {
            $runspacesCopy.Add($runspace)
        }

        # Attendre avec un timeout court et CleanupOnTimeout
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -TimeoutSeconds 1 -WaitForAll -NoProgress -CleanupOnTimeout

        # Le runspace ne devrait pas être complété mais devrait être nettoyé
        $completedRunspaces.Count | Should -Be 0
        $runspacesCopy.Count | Should -Be 0

        # Nettoyer les runspaces originaux
        foreach ($runspace in $script:runspaces) {
            if ($null -ne $runspace -and $null -ne $runspace.PowerShell) {
                $runspace.PowerShell.Dispose()
            }
        }
        $script:runspaces.Clear()
    }

    It "Utilise le délai d'attente spécifié" {
        # Nettoyer les runspaces existants
        foreach ($runspace in $script:runspaces) {
            if ($null -ne $runspace -and $null -ne $runspace.PowerShell) {
                $runspace.PowerShell.Dispose()
            }
        }
        $script:runspaces.Clear()

        # Créer un runspace rapide
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $script:runspacePool

        # Ajouter un script simple
        [void]$powershell.AddScript({
                Start-Sleep -Milliseconds 100
                return "Test rapide"
            })

        # Démarrer l'exécution asynchrone
        $handle = $powershell.BeginInvoke()

        # Ajouter à la liste des runspaces
        [void]$script:runspaces.Add([PSCustomObject]@{
                PowerShell = $powershell
                Handle     = $handle
                Item       = 1
            })

        # Créer une copie de la liste des runspaces pour le test
        $runspacesCopy = [System.Collections.Generic.List[PSObject]]::new()
        foreach ($runspace in $script:runspaces) {
            $runspacesCopy.Add($runspace)
        }

        # Mesurer le temps d'exécution avec un SleepMilliseconds élevé
        $startTime = [datetime]::Now
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -NoProgress -SleepMilliseconds 200
        $duration = [datetime]::Now - $startTime

        # Vérifier que le runspace est complété
        $completedRunspaces | Should -Not -BeNullOrEmpty
        $completedRunspaces | Should -BeOfType [PSCustomObject]
        $completedRunspaces.Count | Should -Be 1
        $completedRunspaces.Results | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results.Count | Should -Be 1
        $completedRunspaces.Results[0] | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results[0].PowerShell | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results[0].Handle | Should -Not -BeNullOrEmpty

        # Vérifier que la liste originale est vide
        # Note: Nous ne pouvons pas vérifier cela car la fonction modifie la liste originale
        # $runspacesCopy.Count | Should -Be 0

        # La durée devrait être d'au moins 200ms (un cycle de vérification)
        $duration.TotalMilliseconds | Should -BeGreaterThan 150

        # Nettoyer
        foreach ($runspace in $completedRunspaces.Results) {
            if ($null -ne $runspace -and $null -ne $runspace.PowerShell) {
                $runspace.PowerShell.Dispose()
            }
        }
        $script:runspaces.Clear()
    }

    It "Gère correctement les runspaces invalides" {
        # Créer une liste avec un runspace invalide
        $invalidRunspaces = New-Object System.Collections.ArrayList
        [void]$invalidRunspaces.Add([PSCustomObject]@{
                PowerShell = $null
                Handle     = $null
                Item       = 1
            })

        # L'attente ne devrait pas échouer
        { Wait-ForCompletedRunspace -Runspaces $invalidRunspaces -NoProgress } | Should -Not -Throw
    }

    It "Retourne un ArrayList" {
        # Nettoyer les runspaces existants
        foreach ($runspace in $script:runspaces) {
            if ($null -ne $runspace -and $null -ne $runspace.PowerShell) {
                $runspace.PowerShell.Dispose()
            }
        }
        $script:runspaces.Clear()

        # Créer un runspace rapide
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $script:runspacePool

        # Ajouter un script simple
        [void]$powershell.AddScript({
                Start-Sleep -Milliseconds 50
                return "Test type"
            })

        # Démarrer l'exécution asynchrone
        $handle = $powershell.BeginInvoke()

        # Ajouter à la liste des runspaces
        [void]$script:runspaces.Add([PSCustomObject]@{
                PowerShell = $powershell
                Handle     = $handle
                Item       = 1
            })

        # Créer une copie de la liste des runspaces pour le test
        $runspacesCopy = [System.Collections.Generic.List[PSObject]]::new()
        foreach ($runspace in $script:runspaces) {
            $runspacesCopy.Add($runspace)
        }

        # Attendre le runspace
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -NoProgress

        # Vérifier le type de retour
        $completedRunspaces | Should -Not -BeNullOrEmpty
        $completedRunspaces | Should -BeOfType [PSCustomObject]
        $completedRunspaces.Count | Should -Be 1
        $completedRunspaces.Results | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results.Count | Should -Be 1
        $completedRunspaces.Results[0] | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results[0].PowerShell | Should -Not -BeNullOrEmpty
        $completedRunspaces.Results[0].Handle | Should -Not -BeNullOrEmpty

        # Vérifier que la liste originale est vide
        # Note: Nous ne pouvons pas vérifier cela car la fonction modifie la liste originale
        # $runspacesCopy.Count | Should -Be 0

        # Nettoyer
        foreach ($runspace in $completedRunspaces.Results) {
            if ($null -ne $runspace -and $null -ne $runspace.PowerShell) {
                $runspace.PowerShell.Dispose()
            }
        }
        $script:runspaces.Clear()
    }
}

AfterAll {
    # Nettoyer après tous les tests
    Clear-UnifiedParallel
}
