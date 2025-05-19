# Tests unitaires pour la gestion optimisée de la progression
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

Describe "ProgressOptimization" {
    Context "Invoke-UnifiedParallel avec progression optimisée" {
        It "Traite correctement les éléments avec la progression optimisée" {
            # Créer des éléments de test
            $items = 1..10

            # Exécuter le traitement parallèle avec progression optimisée
            $params = @{
                InputObject     = $items
                ScriptBlock     = {
                    param($item)
                    # Simuler un traitement qui prend du temps
                    Start-Sleep -Milliseconds 50
                    return $item * 2
                }
                MaxThreads      = 4
                ActivityName    = "Test de progression optimisée"
                UseRunspacePool = $true
            }
            $results = Invoke-UnifiedParallel @params

            # Vérifier les résultats
            $results.Count | Should -Be 10
            $results[0].Value | Should -Be 2
            $results[9].Value | Should -Be 20
        }

        It "Traite correctement les éléments sans progression" {
            # Créer des éléments de test
            $items = 1..10

            # Exécuter le traitement parallèle sans progression
            $params = @{
                InputObject     = $items
                ScriptBlock     = {
                    param($item)
                    # Simuler un traitement qui prend du temps
                    Start-Sleep -Milliseconds 50
                    return $item * 2
                }
                MaxThreads      = 4
                NoProgress      = $true
                ActivityName    = "Test sans progression"
                UseRunspacePool = $true
            }
            $results = Invoke-UnifiedParallel @params

            # Vérifier les résultats
            $results.Count | Should -Be 10
            $results[0].Value | Should -Be 2
            $results[9].Value | Should -Be 20
        }
    }

    Context "Wait-ForCompletedRunspace avec progression optimisée" {
        It "Attend correctement les runspaces avec la progression optimisée" {
            # Créer des runspaces de test
            $runspaces = @()
            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
            $runspacePool.Open()

            for ($i = 0; $i -lt 5; $i++) {
                $powershell = [powershell]::Create()
                $powershell.RunspacePool = $runspacePool

                # Ajouter un script qui prend du temps
                $null = $powershell.AddScript({
                        param($seconds)
                        Start-Sleep -Seconds $seconds
                        return "Completed after $seconds seconds"
                    }).AddArgument(1)

                # Démarrer le runspace
                $handle = $powershell.BeginInvoke()

                # Ajouter à la liste des runspaces
                $runspaces += [PSCustomObject]@{
                    PowerShell = $powershell
                    Handle     = $handle
                }
            }

            # Faire une copie de la liste des runspaces pour le test
            $runspacesCopy = New-Object System.Collections.ArrayList
            foreach ($r in $runspaces) {
                $runspacesCopy.Add($r) | Out-Null
            }

            # Attendre les runspaces avec la progression optimisée
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -WaitForAll -ActivityName "Test d'attente optimisée"

            # Vérifier les résultats
            $completedRunspaces.Count | Should -Be 5
            $runspacesCopy.Count | Should -Be 0

            # Nettoyer
            $runspacePool.Close()
            $runspacePool.Dispose()
        }

        It "Attend correctement les runspaces sans progression" {
            # Créer des runspaces de test
            $runspaces = @()
            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
            $runspacePool.Open()

            for ($i = 0; $i -lt 5; $i++) {
                $powershell = [powershell]::Create()
                $powershell.RunspacePool = $runspacePool

                # Ajouter un script qui prend du temps
                $null = $powershell.AddScript({
                        param($seconds)
                        Start-Sleep -Seconds $seconds
                        return "Completed after $seconds seconds"
                    }).AddArgument(1)

                # Démarrer le runspace
                $handle = $powershell.BeginInvoke()

                # Ajouter à la liste des runspaces
                $runspaces += [PSCustomObject]@{
                    PowerShell = $powershell
                    Handle     = $handle
                }
            }

            # Faire une copie de la liste des runspaces pour le test
            $runspacesCopy = New-Object System.Collections.ArrayList
            foreach ($r in $runspaces) {
                $runspacesCopy.Add($r) | Out-Null
            }

            # Attendre les runspaces sans progression
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -WaitForAll -NoProgress

            # Vérifier les résultats
            $completedRunspaces.Count | Should -Be 5
            $runspacesCopy.Count | Should -Be 0

            # Nettoyer
            $runspacePool.Close()
            $runspacePool.Dispose()
        }
    }
}

AfterAll {
    # Nettoyer après tous les tests
    Clear-UnifiedParallel
}
