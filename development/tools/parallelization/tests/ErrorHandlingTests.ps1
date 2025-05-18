# Tests unitaires pour la gestion des erreurs du module UnifiedParallel
# Utilise Pester pour les tests unitaires

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".."
$modulePath = Join-Path -Path $modulePath -ChildPath "UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Définir les tests
Describe "Gestion des erreurs du module UnifiedParallel" {
    BeforeAll {
        # Initialiser le module avant tous les tests
        Initialize-UnifiedParallel
    }

    AfterAll {
        # Nettoyer après tous les tests
        Clear-UnifiedParallel
    }

    Context "Invoke-UnifiedParallel - Gestion des erreurs" {
        It "Gère correctement les erreurs dans les tâches" {
            $testData = 1..5
            $results = Invoke-UnifiedParallel -ScriptBlock {
                param($item)
                if ($item % 2 -eq 0) {
                    throw "Erreur test pour l'élément $item"
                }
                return "Test $item"
            } -InputObject $testData -MaxThreads 2 -UseRunspacePool -NoProgress -IgnoreErrors

            $successResults = $results | Where-Object { $_.Success }
            $errorResults = $results | Where-Object { -not $_.Success }

            $successResults.Count | Should -Be 3 # Éléments 1, 3, 5
            $errorResults.Count | Should -Be 2 # Éléments 2, 4
            $errorResults[0].Error.Exception.Message | Should -BeLike "*Erreur test pour l'élément*"
        }

        It "Propage les erreurs si IgnoreErrors n'est pas spécifié" {
            $testData = 1..3
            $scriptBlock = {
                param($item)
                if ($item -eq 2) {
                    throw "Erreur critique"
                }
                return "Test $item"
            }

            # L'exécution devrait échouer sans IgnoreErrors
            { Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $testData -MaxThreads 2 -UseRunspacePool -NoProgress -ErrorAction Stop } | Should -Throw "*Erreur critique*"
        }

        It "Gère correctement les timeouts" {
            $testData = 1..3
            $scriptBlock = {
                param($item)
                Start-Sleep -Seconds ($item * 2) # Élément 3 prendra 6 secondes
                return "Test $item"
            }

            # Avec un timeout de 3 secondes, l'élément 3 ne devrait pas être complété
            $results = Invoke-UnifiedParallel -ScriptBlock $scriptBlock -InputObject $testData -MaxThreads 2 -UseRunspacePool -NoProgress -TimeoutSeconds 3 -IgnoreErrors

            # Nous devrions avoir des résultats pour les éléments 1 et 2, mais pas pour l'élément 3
            $completedItems = $results | Where-Object { $_.Success } | ForEach-Object { $_.Value }
            $completedItems | Should -Contain "Test 1"
            $completedItems | Should -Contain "Test 2"
            $completedItems | Should -Not -Contain "Test 3"
        }
    }

    Context "Wait-ForCompletedRunspace - Gestion des erreurs" {
        It "Gère correctement les timeouts" {
            # Créer un pool de runspaces
            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, 2, $sessionState, $Host)
            $runspacePool.Open()

            # Créer une liste pour stocker les runspaces
            $runspaces = New-Object System.Collections.ArrayList

            # Créer un runspace qui prend du temps
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool

            # Ajouter un script qui prend du temps
            [void]$powershell.AddScript({
                Start-Sleep -Seconds 5
                return "Test long"
            })

            # Démarrer l'exécution asynchrone
            $handle = $powershell.BeginInvoke()

            # Ajouter à la liste des runspaces
            [void]$runspaces.Add([PSCustomObject]@{
                PowerShell = $powershell
                Handle = $handle
                Item = 1
            })

            # Attendre avec un timeout court
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -TimeoutSeconds 1 -WaitForAll -NoProgress

            # Le runspace ne devrait pas être complété
            $completedRunspaces.Count | Should -Be 0
            $runspaces.Count | Should -Be 1

            # Nettoyer
            $powershell.Dispose()
            $runspacePool.Close()
            $runspacePool.Dispose()
        }

        It "Gère correctement les runspaces invalides" {
            # Créer une liste avec un runspace invalide
            $runspaces = New-Object System.Collections.ArrayList
            [void]$runspaces.Add([PSCustomObject]@{
                PowerShell = $null
                Handle = $null
                Item = 1
            })

            # L'attente ne devrait pas échouer
            { Wait-ForCompletedRunspace -Runspaces $runspaces -NoProgress } | Should -Not -Throw
        }
    }

    Context "Invoke-RunspaceProcessor - Gestion des erreurs" {
        It "Gère correctement les runspaces invalides" {
            # Créer une liste avec un runspace invalide
            $runspaces = New-Object System.Collections.ArrayList
            [void]$runspaces.Add([PSCustomObject]@{
                PowerShell = $null
                Handle = $null
                Item = 1
            })

            # Le traitement ne devrait pas échouer
            { Invoke-RunspaceProcessor -CompletedRunspaces $runspaces -NoProgress } | Should -Not -Throw
        }

        It "Gère correctement les erreurs lors du traitement" {
            # Créer un pool de runspaces
            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, 2, $sessionState, $Host)
            $runspacePool.Open()

            # Créer une liste pour stocker les runspaces
            $runspaces = New-Object System.Collections.ArrayList

            # Créer quelques runspaces avec des erreurs
            for ($i = 1; $i -le 3; $i++) {
                $powershell = [powershell]::Create()
                $powershell.RunspacePool = $runspacePool

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
                [void]$runspaces.Add([PSCustomObject]@{
                    PowerShell = $powershell
                    Handle = $handle
                    Item = $i
                })
            }

            # Attendre tous les runspaces
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress

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

            # Nettoyer
            $runspacePool.Close()
            $runspacePool.Dispose()
        }
    }
}

# Exécuter les tests
Invoke-Pester -Output Detailed
